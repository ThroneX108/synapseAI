import 'package:flutter/material.dart';
import 'package:flutter_animator/flutter_animator.dart';
import '../../../core/theme/app_theme.dart';

import 'admin_chat_detail_screen.dart';

class AdminChatScreen extends StatefulWidget {
  const AdminChatScreen({super.key});

  @override
  State<AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends State<AdminChatScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  List<Map<String, dynamic>> _filteredChats = [];

  final List<Map<String, dynamic>> _allChats = [
    {
      "name": "Dr. Anjali Sharma",
      "message": "I've uploaded the monthly report.",
      "time": "10:30 AM",
      "initial": "A",
      "isCounselor": true,
    },
    {
      "name": "Vikram Malhotra",
      "message": "When is the next available slot?",
      "time": "09:15 AM",
      "initial": "V",
      "isCounselor": false,
    },
    {
      "name": "Sanya Gupta",
      "message": "Thank you for the help!",
      "time": "Yesterday",
      "initial": "S",
      "isCounselor": false,
    },
    {
      "name": "Rahul Verma",
      "message": "Can I reschedule my session?",
      "time": "Yesterday",
      "initial": "R",
      "isCounselor": false,
    },
    {
      "name": "Dr. Peter Parker",
      "message": "Student attendance is low this week.",
      "time": "Mon",
      "initial": "P",
      "isCounselor": true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _filteredChats = _allChats;
  }

  void _filterChats(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredChats = _allChats;
      } else {
        _filteredChats = _allChats
            .where((chat) =>
        chat['name'].toLowerCase().contains(query.toLowerCase()) ||
            chat['message'].toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _filteredChats = _allChats;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: _isSearching
            ? TextField(
          controller: _searchController,
          autofocus: true,
          onChanged: _filterChats,
          style: const TextStyle(color: Colors.black),
          decoration: const InputDecoration(
            hintText: "Search user or message...",
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey),
          ),
        )
            : const Text(
          "Support Messages",
          style:
          TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search,
                color: Colors.black),
            onPressed: _toggleSearch,
          ),
        ],
      ),
      body: _filteredChats.isEmpty
          ? Center(
          child: Text("No results found.",
              style: TextStyle(color: Colors.grey[600])))
          : ListView.separated(
        itemCount: _filteredChats.length,
        separatorBuilder: (context, index) =>
        const Divider(height: 1, indent: 80),
        itemBuilder: (context, index) {
          final chat = _filteredChats[index];

          return FadeInUp(
            preferences: const AnimationPreferences(
                offset: Duration(milliseconds: 0),
                magnitude: 0.1
            ),
            child: ListTile(
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => AdminChatDetailScreen(
                          otherUserName: chat['name'],
                          otherUserRole: chat['isCounselor']
                              ? "Counselor"
                              : "Student",
                        )));
              },
              leading: CircleAvatar(
                radius: 28,
                backgroundColor: chat['isCounselor']
                    ? AppTheme.secondary.withOpacity(0.2)
                    : Colors.blueGrey[50],
                child: Text(
                  chat['initial'],
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: chat['isCounselor']
                          ? AppTheme.primary
                          : Colors.blueGrey),
                ),
              ),
              title: Text(
                chat['name'],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                chat['message'],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[600]),
              ),
              trailing: Text(
                chat['time'],
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ),
          );
        },
      ),
    );
  }
}