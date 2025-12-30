import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';

// --- DATA MODEL ---
class ChatMessage {
  final String id;
  final String text;
  final DateTime time;
  final bool isMe;

  ChatMessage({
    required this.id,
    required this.text,
    required this.time,
    required this.isMe,
  });
}

class ChatDetailScreen extends StatefulWidget {
  final String otherUserName;
  final String otherUserId; // 🔑 Vital: We need the ID to talk to them
  final String? existingChatRoomId; // Optional: If we already know the room

  const ChatDetailScreen({
    super.key,
    required this.otherUserName,
    required this.otherUserId,
    this.existingChatRoomId,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<ChatMessage> _messages = [];
  String? _chatRoomId;
  String? _myUserId;
  bool _isLoading = true;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  @override
  void dispose() {
    _subscription?.cancel(); // 🛑 Always cancel subscriptions!
    _messageController.dispose();
    super.dispose();
  }

  // --- 1. INITIALIZATION SEQUENCE ---
  Future<void> _initializeChat() async {
    try {
      // A. Who am I?
      final user = await Amplify.Auth.getCurrentUser();
      _myUserId = user.userId;

      // B. Do we have a room?
      if (widget.existingChatRoomId != null) {
        _chatRoomId = widget.existingChatRoomId;
      } else {
        // C. Find or Create Room Logic
        _chatRoomId = await _findOrCreateChatRoom();
      }

      // D. Load History & Subscribe
      if (_chatRoomId != null) {
        await _fetchMessageHistory();
        _subscribeToMessages();
      }

      setState(() => _isLoading = false);
    } catch (e) {
      safePrint("Chat Init Error: $e");
      setState(() => _isLoading = false);
    }
  }

  // --- 2. FIND OR CREATE ROOM ---
  Future<String?> _findOrCreateChatRoom() async {
    // For Hackathon speed: We will just CREATE a new room if we don't have an ID.
    // Ideally, you query listChatRoomUsers to find a match, but that is complex.
    // ⚠️ Strategy: We assume if the user clicked "Message", they want a connection.
    try {
      // 1. Create the Room
      const createRoomMutation = 'mutation CreateRoom { createChatRoom(input: {}) { id } }';
      final roomRes = await Amplify.API.mutate(
          request: GraphQLRequest<String>(
            authorizationMode: APIAuthorizationType.userPools,
              document: createRoomMutation)).response;
      final roomId = jsonDecode(roomRes.data!)['createChatRoom']['id'];

      // 2. Add ME to the Room
      const linkUserMutation = '''mutation LinkUser(\$roomId: ID!, \$userId: ID!) {
        createChatRoomUser(input: {chatRoomID: \$roomId, userID: \$userId}) { id }
      }''';

      await Amplify.API.mutate(request: GraphQLRequest<String>(
        authorizationMode: APIAuthorizationType.userPools,
          document: linkUserMutation,
          variables: {'roomId': roomId, 'userId': _myUserId}
      )).response;

      // 3. Add THEM to the Room
      await Amplify.API.mutate(request: GraphQLRequest<String>(
        authorizationMode: APIAuthorizationType.userPools,
          document: linkUserMutation,
          variables: {'roomId': roomId, 'userId': widget.otherUserId}
      )).response;

      safePrint("✅ Created new Chat Room: $roomId");
      return roomId;
    } catch (e) {
      safePrint("Error creating room: $e");
      return null;
    }
  }

  // --- 3. FETCH HISTORY ---
  Future<void> _fetchMessageHistory() async {
    try {
      const listMsgs = '''query ListMsgs(\$roomId: ID!) {
        listMessages(filter: {chatRoomID: {eq: \$roomId}}) {
          items {
            id
            content
            senderID
            createdAt
          }
        }
      }''';

      final res = await Amplify.API.query(request: GraphQLRequest<String>(
        authorizationMode: APIAuthorizationType.userPools,
          document: listMsgs,
          variables: {'roomId': _chatRoomId}
      )).response;

      final data = jsonDecode(res.data!);
      final List items = data['listMessages']['items'];

      // Sort by Time (Oldest first for ListView)
      items.sort((a, b) => a['createdAt'].compareTo(b['createdAt']));

      setState(() {
        _messages = items.map((item) {
          return ChatMessage(
            id: item['id'],
            text: item['content'],
            time: DateTime.parse(item['createdAt']).toLocal(),
            isMe: item['senderID'] == _myUserId,
          );
        }).toList();
      });

      // Scroll to bottom
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });

    } catch (e) {
      safePrint("Error fetching history: $e");
    }
  }

  // --- 4. REAL-TIME SUBSCRIPTION ---
  void _subscribeToMessages() {
    const subDoc = '''subscription OnCreateMsg(\$roomId: ID!) {
      onCreateMessage(filter: {chatRoomID: {eq: \$roomId}}) {
        id
        content
        senderID
        createdAt
      }
    }''';

    final operation = Amplify.API.subscribe(
      GraphQLRequest<String>(
        authorizationMode: APIAuthorizationType.userPools,
          document: subDoc, variables: {'roomId': _chatRoomId}),
      onEstablished: () => safePrint("✅ Subscribed to Room $_chatRoomId"),
    );

    _subscription = operation.listen((event) {
      final data = jsonDecode(event.data!);
      final newItem = data['onCreateMessage'];

      // Prevent duplicates if my own message comes back via sub
      if (_messages.any((m) => m.id == newItem['id'])) return;

      final newMsg = ChatMessage(
        id: newItem['id'],
        text: newItem['content'],
        time: DateTime.parse(newItem['createdAt']).toLocal(),
        isMe: newItem['senderID'] == _myUserId,
      );

      setState(() {
        _messages.add(newMsg);
      });

      // Auto-scroll
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 60,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }, onError: (e) => safePrint("Subscription Error: $e"));
  }

  // --- 5. SEND MESSAGE ---
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _chatRoomId == null) return;

    _messageController.clear();

    try {
      const sendDoc = '''mutation SendMsg(\$roomId: ID!, \$content: String!, \$sender: ID!) {
        createMessage(input: {
          chatRoomID: \$roomId, 
          content: \$content, 
          senderID: \$sender
        }) {
          id
          createdAt
        }
      }''';

      final req = GraphQLRequest<String>(
        authorizationMode: APIAuthorizationType.userPools,
        document: sendDoc,
        variables: {
          'roomId': _chatRoomId,
          'content': text,
          'sender': _myUserId,
        },
      );

      final res = await Amplify.API.mutate(request: req).response;
      if (res.hasErrors) {
        safePrint("Send Error: ${res.errors.first.message}");
      } else {
        // Optimistic UI update is optional here because Subscription will handle it,
        // but adding it makes it feel faster.
        final data = jsonDecode(res.data!);
        final created = data['createMessage'];

        setState(() {
          _messages.add(ChatMessage(
            id: created['id'],
            text: text,
            time: DateTime.parse(created['createdAt']).toLocal(),
            isMe: true,
          ));
        });
      }
    } catch (e) {
      safePrint("Send Failed: $e");
    }
  }

  // --- UI BUILD ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFE7DE),
      appBar: AppBar(
        title: Text(widget.otherUserName, style: const TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildBubble(msg);
              },
            ),
          ),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildBubble(ChatMessage msg) {
    return Align(
      alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: msg.isMe ? const Color(0xFF3b5998) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2, offset: const Offset(0,1))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              msg.text,
              style: TextStyle(color: msg.isMe ? Colors.white : Colors.black87, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('hh:mm a').format(msg.time),
              style: TextStyle(color: msg.isMe ? Colors.white70 : Colors.grey, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: "Type a message...",
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: const Color(0xFF3b5998),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}