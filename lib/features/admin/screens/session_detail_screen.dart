import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import 'package:flutter_animator/flutter_animator.dart';

class SessionDetailScreen extends StatelessWidget {
  final String studentName;
  final String counselorName;
  final String date;

  const SessionDetailScreen({
    super.key,
    required this.studentName,
    required this.counselorName,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: Text("Session Details", style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header Card
            FadeInDown(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Completed Session", style: GoogleFonts.lato(color: Colors.white70, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(date, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.check_circle, color: Colors.white),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Participants
            ZoomIn(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    _buildParticipant(studentName, "Student", Icons.person_outline),
                    const Expanded(child: Divider(indent: 10, endIndent: 10)),
                    _buildParticipant(counselorName, "Counselor", Icons.medical_services_outlined),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Session Notes
            FadeInUp(
              child: _buildSection(
                title: "Session Notes",
                icon: Icons.description,
                content: "The student showed signs of improvement regarding academic stress. We discussed time management techniques (Pomodoro) and set a follow-up goal for next week. Student seemed receptive.",
              ),
            ),
            const SizedBox(height: 20),

            // Feedback
            FadeInUp(
              preferences: const AnimationPreferences(
                offset: Duration(milliseconds: 200),
              ),
              child: _buildSection(
                title: "Student Feedback",
                icon: Icons.star_border,
                content: "Dr. Anjali was very understanding. I feel much better about my upcoming exams.",
                rating: 5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipant(String name, String role, IconData icon) {
    return Column(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: AppTheme.background,
          child: Icon(icon, color: AppTheme.primary),
        ),
        const SizedBox(height: 8),
        Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        Text(role, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildSection({required String title, required IconData icon, required String content, int? rating}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppTheme.primary),
              const SizedBox(width: 8),
              Text(title, style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 16)),
              if (rating != null) ...[
                const Spacer(),
                const Icon(Icons.star, color: Colors.amber, size: 18),
                Text(" $rating.0", style: const TextStyle(fontWeight: FontWeight.bold)),
              ]
            ],
          ),
          const Divider(height: 24),
          Text(content, style: GoogleFonts.lato(fontSize: 14, color: AppTheme.textDark, height: 1.5)),
        ],
      ),
    );
  }
}