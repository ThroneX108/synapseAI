import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';

// ✅ Import your updated ChatDetailScreen
import 'chat_detail_screen.dart';

class ChatsTab extends StatefulWidget {
  const ChatsTab({super.key});

  @override
  State<ChatsTab> createState() => _ChatsTabState();
}

class _ChatsTabState extends State<ChatsTab> {
  List<Map<String, dynamic>> _chatRooms = [];
  bool _isLoading = true;
  String? _myUserId;

  @override
  void initState() {
    super.initState();
    _fetchChatRooms();
  }

  Future<void> _fetchChatRooms() async {
    try {
      // 1. Get My ID
      final user = await Amplify.Auth.getCurrentUser();
      _myUserId = user.userId;

      // 2. Query: "Give me all ChatRooms where I am a participant"
      // We query ChatRoomUser because that links Users <-> Rooms
      const graphQLDocument = '''query GetMyRooms(\$myId: ID!) {
        listChatRoomUsers(filter: {userID: {eq: \$myId}}) {
          items {
            chatRoom {
              id
              lastMessageContent
              lastMessageTime
              users {
                items {
                  user {
                    id
                    name
                    imageUrl
                  }
                }
              }
            }
          }
        }
      }''';

      final request = GraphQLRequest<String>(
        authorizationMode: APIAuthorizationType.userPools,
        document: graphQLDocument,
        variables: {'myId': _myUserId},
      );

      final response = await Amplify.API.query(request: request).response;

      if (response.data != null) {
        final data = jsonDecode(response.data!);
        final List items = data['listChatRoomUsers']['items'];

        final List<Map<String, dynamic>> parsedRooms = [];

        for (var item in items) {
          final room = item['chatRoom'];
          // ⚠️ Handle case where room was deleted but link remains
          if (room == null) continue;

          // 3. Find the "Other" User
          // The room has a list of users. We need the one that isn't ME.
          final List participants = room['users']['items'];
          final otherParticipant = participants.firstWhere(
                (p) => p['user']['id'] != _myUserId,
            orElse: () => null,
          );

          if (otherParticipant != null) {
            parsedRooms.add({
              'roomId': room['id'],
              'lastMessage': room['lastMessageContent'] ?? "Start chatting",
              'time': room['lastMessageTime'],
              'otherUserId': otherParticipant['user']['id'],
              'otherUserName': otherParticipant['user']['name'] ?? "Unknown",
              'otherUserImage': otherParticipant['user']['imageUrl'],
            });
          }
        }

        // Sort by newest first
        parsedRooms.sort((a, b) {
          final t1 = a['time'] ?? "";
          final t2 = b['time'] ?? "";
          return t2.compareTo(t1);
        });

        if (mounted) {
          setState(() {
            _chatRooms = parsedRooms;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      safePrint("Error fetching chats: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Messages",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: () {
              setState(() => _isLoading = true);
              _fetchChatRooms();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _chatRooms.isEmpty
          ? const Center(child: Text("No chats yet."))
          : ListView.separated(
        itemCount: _chatRooms.length,
        separatorBuilder: (context, index) => const Divider(height: 1, indent: 80),
        itemBuilder: (context, index) {
          final room = _chatRooms[index];

          // Format timestamp
          String timeDisplay = "";
          if (room['time'] != null) {
            final date = DateTime.parse(room['time']).toLocal();
            timeDisplay = DateFormat('hh:mm a').format(date);
          }

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            onTap: () {
              // ✅ NAVIGATE CORRECTLY
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatDetailScreen(
                    otherUserName: room['otherUserName'],
                    otherUserId: room['otherUserId'], // 🔑 Vital!
                    existingChatRoomId: room['roomId'], // Load history faster
                  ),
                ),
              ).then((_) => _fetchChatRooms()); // Refresh on return
            },
            leading: CircleAvatar(
              radius: 28,
              backgroundColor: Colors.blueGrey[50],
              child: Text(
                room['otherUserName'][0].toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
              ),
            ),
            title: Text(
              room['otherUserName'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              room['lastMessage'],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[600]),
            ),
            trailing: Text(
              timeDisplay,
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          );
        },
      ),
    );
  }
}
