import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import 'package:flutter_animator/flutter_animator.dart';

import '../chat/admin_chat_detail_screen.dart';

class AdminDashboardHome extends StatelessWidget {
  const AdminDashboardHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Admin Control Center',
            style: GoogleFonts.poppins(color: AppTheme.textDark, fontWeight: FontWeight.bold)
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textDark),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildStatCard("Total Users", "1,240", AppTheme.primary),
                const SizedBox(width: 16),
                _buildStatCard("Active Issues", "12", AppTheme.error),
                const SizedBox(width: 16),
                _buildStatCard("Sessions Today", "24", AppTheme.secondary),
              ],
            ),
            const SizedBox(height: 32),

            Text(
              "Feedback Inbox",
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
            ),
            const SizedBox(height: 16),

            _buildFeedbackCard(
              context,
              name: "Dr. Anjali Sharma",
              role: "Counselor",
              message: "The video call disconnected twice during my session with Vikram.",
              time: "10 mins ago",
              isUrgent: true,
            ),
            _buildFeedbackCard(
              context,
              name: "Riya Singh",
              role: "Student",
              message: "I found the session very helpful, but the booking UI is confusing.",
              time: "2 hours ago",
              isUrgent: false,
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildStatCard(String title, String count, Color color) {
  return Expanded(
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(count, style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
          Text(title, style: GoogleFonts.lato(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    ),
  );
}

Widget _buildFeedbackCard(BuildContext context,{
  required String name,
  required String role,
  required String message,
  required String time,
  bool isUrgent = false
}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey[200]!),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [

            Expanded(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: role == "Counselor"
                        ? AppTheme.secondary.withOpacity(0.2)
                        : Colors.blue[50],
                    child: Icon(
                      role == "Counselor"
                          ? Icons.medical_services
                          : Icons.school,
                      size: 16,
                      color: role == "Counselor"
                          ? AppTheme.primary
                          : Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),

                  Flexible(
                    child: Text(
                      name,
                      style: GoogleFonts.lato(
                          fontWeight: FontWeight.bold, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Role Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      role,
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  )
                ],
              ),
            ),

            if (isUrgent) const SizedBox(width: 8),

            if (isUrgent)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                    color: AppTheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4)),
                child: Text(
                  "Needs Action",
                  style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.error,
                      fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(message,
            style: GoogleFonts.lato(color: AppTheme.textDark, fontSize: 14)),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(time,
                style: TextStyle(color: Colors.grey[400], fontSize: 12)),
            Row(
              children: [
                TextButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => AdminChatDetailScreen(
                        otherUserName: name,
                        otherUserRole: role,
                      )));
                    },
                    child: const Text("Chat")
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    showResolveSheet(context);
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 0),
                      minimumSize: const Size(0, 32)),
                  child: const Text("Resolve"),
                ),
              ],
            )
          ],
        )
      ],
    ),
  );
}

void showResolveSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return FadeInUp(
        child: Container(
          padding: EdgeInsets.only(
              left: 24, right: 24, top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24 // Handle keyboard
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Resolve Ticket", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 16),
              const Text("Resolution Note", style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: "Enter details about how this was resolved...",
                  filled: true,
                  fillColor: AppTheme.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Dismiss", style: TextStyle(color: Colors.grey)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Submit Logic
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Mark Resolved", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
