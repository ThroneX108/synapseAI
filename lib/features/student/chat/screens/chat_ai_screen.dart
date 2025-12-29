import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:amplify_flutter/amplify_flutter.dart'; // ✅ AWS Import

import '../widgets/chat_background.dart';
import '../widgets/empathy_avatar.dart';

// ✅ 1. Simple Model to distinguish User vs AI
class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}

class ChatAIScreen extends StatefulWidget {
  const ChatAIScreen({super.key});

  @override
  State<ChatAIScreen> createState() => _ChatAIScreenState();
}

class _ChatAIScreenState extends State<ChatAIScreen> {
  final TextEditingController _controller = TextEditingController();

  // ✅ 2. Use List<ChatMessage> instead of String
  final List<ChatMessage> _messages = [];
  bool _isTyping = false; // To show loading state

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildGlassAppBar(),
      body: Stack(
        children: [
          const EtherealBackground(),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: _messages.isEmpty
                      ? _buildEmptyState()
                      : _buildChatList(),
                ),
                if (_isTyping) _buildTypingIndicator(), // Show when waiting
                _buildInputArea(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- LOGIC ---

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _controller.clear();
      _isTyping = true;
    });

    try {
      final body = jsonEncode({'question': text});

      final restOperation = Amplify.API.post(
        '/chat',
        apiName: 'synapseAI',
        body: HttpPayload.string(body),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      final response = await restOperation.response;
      final responseBody = await response.decodeBody();
      final jsonResponse = jsonDecode(responseBody);


      final aiResponseText =
          jsonResponse['answer'] ?? "No response received.";

      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(text: aiResponseText, isUser: false));
          _isTyping = false;
        });
      }
    } catch (e) {
      safePrint("Connection Error: $e");
      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessage(
              text: "Error: Could not reach server.",
              isUser: false,
            ),
          );
          _isTyping = false;
        });
      }
    }
  }

  // --- WIDGET BUILDERS ---

  PreferredSizeWidget _buildGlassAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16.0),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: CircleAvatar(
            backgroundColor: Colors.white.withOpacity(0.5),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.black87),
          ),
        ),
      ),
      title: Text(
        "Chat with Synapse AI",
        style: GoogleFonts.plusJakartaSans(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w600),
      ),
      centerTitle: true,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const EmpathyAvatar(),
          const SizedBox(height: 40),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.plusJakartaSans(fontSize: 24, height: 1.3, color: const Color(0xFF2B2D42)),
              children: [
                TextSpan(text: "Myra", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: const Color(0xFF7B61FF))),
                const TextSpan(text: " is here to listen,\n"),
                TextSpan(text: "How are you feeling?", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w400, color: Colors.black54, fontSize: 18)),
              ],
            ),
          ).animate().fadeIn(duration: 800.ms).moveY(begin: 20, end: 0),
        ],
      ),
    );
  }

  Widget _buildChatList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        return Align(
          alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: _buildMessageBubble(msg),
        );
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    // 🎨 Different Styles for User vs AI
    final isUser = msg.isUser;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
      decoration: BoxDecoration(
        gradient: isUser
            ? const LinearGradient(
            colors: [Color(0xFFA1C4FD), Color(0xFFC2E9FB)],
            begin: Alignment.topLeft, end: Alignment.bottomRight
        )
            : const LinearGradient(
          colors: [Colors.white, Colors.white], // White for AI
        ),
        color: isUser ? null : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(24),
          topRight: const Radius.circular(24),
          bottomLeft: Radius.circular(isUser ? 24 : 4),
          bottomRight: Radius.circular(isUser ? 4 : 24),
        ),
      ),
      child: Text(
        msg.text,
        style: TextStyle(
          color: const Color(0xFF1E293B),
          fontSize: 15,
          height: 1.4,
          fontWeight: FontWeight.w500,
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildTypingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          const CircleAvatar(
              radius: 4,
              backgroundColor: Color(0xFF7B61FF)
          ).animate(onPlay: (c) => c.repeat()).scale(duration: 600.ms),
          const SizedBox(width: 4),
          const CircleAvatar(
              radius: 4,
              backgroundColor: Color(0xFF7B61FF)
          ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(delay: 200.ms, duration: 600.ms),
          const SizedBox(width: 4),
          const CircleAvatar(
              radius: 4,
              backgroundColor: Color(0xFF7B61FF)
          ).animate(onPlay: (c) => c.repeat()).scale(delay: 400.ms, duration: 600.ms),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: "Tell me what's on your mind...",
                hintStyle: GoogleFonts.plusJakartaSans(color: Colors.grey[500], fontSize: 14),
                border: InputBorder.none,
                isDense: true,
              ),
              onSubmitted: _sendMessage,
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => _sendMessage(_controller.text),
            child: const CircleAvatar(
              radius: 20,
              backgroundColor: Color(0xFF7B61FF),
              child: Icon(FontAwesomeIcons.paperPlane, color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}