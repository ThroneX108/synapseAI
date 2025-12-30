import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import 'session_detail_screen.dart';

class SessionLogScreen extends StatelessWidget {
  const SessionLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Session Registry', style: GoogleFonts.poppins(color: AppTheme.textDark, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: 4,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("STUDENT", style: TextStyle(fontSize: 10, color: Colors.grey[500], letterSpacing: 1)),
                          const SizedBox(height: 4),
                          Text("Vikram M.", style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward, color: Colors.grey[300], size: 16),
                    const SizedBox(width: 16),
                    // Counselor
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text("COUNSELOR", style: TextStyle(fontSize: 10, color: Colors.grey[500], letterSpacing: 1)),
                          const SizedBox(height: 4),
                          Text("Dr. Anjali S.", style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primary)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text("Oct 24, 10:00 AM", style: GoogleFonts.lato(fontSize: 13, color: Colors.grey[600])),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(20)),
                      child: Text("Completed", style: TextStyle(fontSize: 12, color: Colors.green[700], fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: (){
                      Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SessionDetailScreen(
                            studentName: "Vikram M.",
                            counselorName: "Dr. Anjali S.",
                            date: "Oct 24, 10:00 AM",
                          ))
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text("View Session Notes & Feedback", style: TextStyle(color: AppTheme.textDark)),
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}