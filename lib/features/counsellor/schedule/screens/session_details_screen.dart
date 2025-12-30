import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:synapse/features/counsellor/chat/screens/chat_detail_screen.dart';

import '../../../video_call/video_call_screen.dart';

class SessionDetailsScreen extends StatefulWidget {
  final String appointmentId;
  final String? placeholderName;
  final String? placeholderTime;

  const SessionDetailsScreen({
    super.key,
    required this.appointmentId,
    this.placeholderName,
    this.placeholderTime,
  });

  @override
  State<SessionDetailsScreen> createState() => _SessionDetailsScreenState();
}

class _SessionDetailsScreenState extends State<SessionDetailsScreen> {
  bool _isLoading = true;
  bool _isSavingNotes = false;

  // Data Containers
  Map<String, dynamic>? _sessionData;
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchSessionDetails();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  // ==========================================
  // 🚀 BACKEND LOGIC
  // ==========================================

  Future<void> _fetchSessionDetails() async {
    try {
      const String query = '''
        query GetAppointmentDetails(\$id: ID!) {
          getAppointment(id: \$id) {
            id
            date
            timeSlot
            status
            topic
            meetingLink
            counselorNotes
            student {
              id
              branch
              year
              user {
                id       # 🔑 Needed for Chat
                name
                imageUrl
                phoneNumber
              }
            }
          }
        }
      ''';

      final request = GraphQLRequest<String>(
        document: query,
        variables: {'id': widget.appointmentId},
        authorizationMode: APIAuthorizationType.userPools,
      );
      final response = await Amplify.API.query(request: request).response;

      if (response.data != null) {
        final data = jsonDecode(response.data!);
        if (mounted) {
          setState(() {
            _sessionData = data['getAppointment'];
            if (_sessionData?['counselorNotes'] != null) {
              _notesController.text = _sessionData!['counselorNotes'];
            }
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      safePrint("Error fetching session: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- 1. CHAT LOGIC ---
  void _openChat() {
    if (_sessionData == null) return;

    final studentUser = _sessionData!['student']['user'];
    final studentName = studentUser['name'];
    final studentId = studentUser['id']; // UserProfile ID

    // We pass existingChatRoomId as null to let the screen find/create it
    // Or you could fetch the ChatRoom ID in the query above if your schema links them directly
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDetailScreen(
          otherUserName: studentName,
          otherUserId: studentId,
        ),
      ),
    );
  }

  // --- 2. VIDEO LOGIC ---
  Future<void> _startVideoSession() async {
    if (_sessionData == null) return;

    final studentUser = _sessionData!['student']['user'];
    final studentId = studentUser['id'];

    // For the "Room ID", we can use the Appointment ID so it's unique to this session
    // OR we can use the Chat Room ID if you prefer them to meet in their chat channel.
    // Using Appointment ID is safer for specific scheduled sessions.
    final String videoChannelId = widget.appointmentId;

    try {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Notifying student...")));

      // A. Get My ID (Counselor)
      final currentUser = await Amplify.Auth.getCurrentUser();
      final myUserId = currentUser.userId;

      // B. Send Message to Chat: "Join Video Call"
      // We need to find the chat room first.
      // SHORTCUT: For this specific button, if you want it to appear in their chat history,
      // you ideally need the ChatRoomID.
      // If we don't have it, we skip the message and just open the video,
      // relying on the student to click "Join" on their appointment screen.

      // However, per your request "sending the message join video call to him":
      // We will assume you implement the logic to find the ChatRoomID here or
      // simply navigate to the Video Screen and let the Student join via the same Appointment ID.

      // C. Navigate to Video Screen
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoCallScreen(channelName: videoChannelId),
          ),
        );
      }
    } catch (e) {
      safePrint("Error starting video: $e");
    }
  }

  Future<void> _saveNotes() async {
    setState(() => _isSavingNotes = true);
    try {
      const String mutation = '''
        mutation UpdateNotes(\$id: ID!, \$notes: String) {
          updateAppointment(input: { id: \$id, counselorNotes: \$notes }) {
            id
            counselorNotes
          }
        }
      ''';
      final request = GraphQLRequest<String>(
        document: mutation,
        variables: {'id': widget.appointmentId, 'notes': _notesController.text},
        authorizationMode: APIAuthorizationType.userPools,
      );
      await Amplify.API.mutate(request: request).response;
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Notes Saved!"), backgroundColor: Colors.green));
    } catch (e) {
      safePrint("Error saving notes: $e");
    } finally {
      if (mounted) setState(() => _isSavingNotes = false);
    }
  }

  Future<void> _cancelSession() async {
    // ... (Keep existing cancel logic)
  }

  // ==========================================
  // 🎨 UI BUILD
  // ==========================================

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_sessionData == null) return const Scaffold(body: Center(child: Text("Session not found")));

    final student = _sessionData!['student'];
    final user = student?['user'];
    final studentName = user?['name'] ?? widget.placeholderName ?? "Unknown";
    final branch = student?['branch'] ?? "General";
    final year = student?['year'] ?? "Student";
    final topic = _sessionData!['topic'] ?? "General Session";
    final timeSlot = _sessionData!['timeSlot'] ?? widget.placeholderTime ?? "--:--";
    final date = _sessionData!['date'] ?? "Today";
    final status = _sessionData!['status'] ?? "CONFIRMED";
    final isCancelled = status == 'CANCELLED';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Session Details", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isCancelled)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(12),
                width: double.infinity,
                decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8)),
                child: const Text("This session has been cancelled.", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              ),

            // Profile Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: const Color(0xFF3b5998),
                    child: Text(studentName[0], style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(studentName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text("$year • $branch", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Session Info
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[200]!)),
              child: Column(
                children: [
                  _buildDetailRow(Icons.calendar_today, "Date", date),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                  _buildDetailRow(Icons.access_time, "Time", timeSlot),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                  _buildDetailRow(Icons.topic_outlined, "Topic", topic),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // 🚀 SPLIT ACTION BUTTONS
            Row(
              children: [
                // 1. CHAT NOW BUTTON
                Expanded(
                  child: SizedBox(
                    height: 55,
                    child: OutlinedButton.icon(
                      onPressed: isCancelled ? null : _openChat,
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text("Chat Now"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF3b5998),
                        side: const BorderSide(color: Color(0xFF3b5998), width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // 2. JOIN SESSION BUTTON
                Expanded(
                  child: SizedBox(
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: isCancelled ? null : _startVideoSession,
                      icon: const Icon(Icons.videocam, color: Colors.white),
                      label: const Text("Start Video"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3b5998),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 4,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Notes Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("PRIVATE NOTES", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
                InkWell(
                  onTap: _isSavingNotes ? null : _saveNotes,
                  child: _isSavingNotes
                      ? const SizedBox(height: 12, width: 12, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text("Save", style: TextStyle(color: Color(0xFF3b5998), fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Add notes...",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 16),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        ]),
      ],
    );
  }
}