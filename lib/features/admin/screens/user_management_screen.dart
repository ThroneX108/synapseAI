import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import 'package:flutter_animator/flutter_animator.dart';

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text("User Management", style: GoogleFonts.poppins(color: AppTheme.textDark, fontWeight: FontWeight.bold)),
          bottom: TabBar(
            labelColor: AppTheme.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppTheme.primary,
            tabs: const [
              Tab(text: "Counselors"),
              Tab(text: "Students"),
            ],
          ),
          actions: [
            IconButton(
                onPressed: () => showAddUserSheet(context),
                icon: const Icon(Icons.person_add, color: AppTheme.primary)
            )
          ],
        ),
        body: const TabBarView(
          children: [
            _UserList(type: "Counselor"),
            _UserList(type: "Student"),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            showAddUserSheet(context);
          },
          backgroundColor: AppTheme.primary,
          icon: const Icon(Icons.add),
          label: const Text("Add User"),
        ),
      ),
    );
  }
}

class _UserList extends StatelessWidget {
  final String type;
  const _UserList({required this.type});

  @override
  Widget build(BuildContext context) {
    final isCounselor = type == "Counselor";
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 5, // Mock count
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isCounselor ? AppTheme.secondary.withOpacity(0.3) : Colors.blue[50],
              child: Text(isCounselor ? "Dr" : "S", style: TextStyle(color: isCounselor ? AppTheme.primary : Colors.blue)),
            ),
            title: Text(isCounselor ? "Dr. Name ${index+1}" : "Student Name ${index+1}", style: GoogleFonts.lato(fontWeight: FontWeight.bold)),
            subtitle: Text(isCounselor ? "Psychologist • 12 Active Sessions" : "Year 3 • CSE Dept"),
            trailing: PopupMenuButton(
              onSelected: (value) {
                if (value == 'edit') {
                  showEditProfileSheet(context, isCounselor);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit Profile')),
                const PopupMenuItem(value: 'disable', child: Text('Disable Account')),
              ],
            ),
          ),
        );
      },
    );
  }
}

void showAddUserSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return FadeInUp(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Import Users", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text("Upload a CSV file to add multiple users at once.", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              const SizedBox(height: 24),

              // CSV Drop Zone Visual
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.3), width: 1, style: BorderStyle.solid), // Dashed border is complex in raw flutter, solid is fine or use package
                ),
                child: Column(
                  children: [
                    Icon(Icons.cloud_upload_outlined, size: 48, color: AppTheme.primary),
                    const SizedBox(height: 12),
                    const Text("Tap to select .csv file", style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Upload Logic
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Upload Details", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

void showEditProfileSheet(BuildContext context, bool isCounselor) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return FadeInUp(
        child: Container(
          padding: EdgeInsets.only(
              left: 24, right: 24, top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Edit Profile", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),

              _buildTextField("Full Name", "e.g. Vikram Malhotra"),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(child: _buildTextField(isCounselor ? "Speciality" : "Department", isCounselor ? "e.g. Psychologist" : "e.g. CSE")),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField(isCounselor ? "Experience" : "Year", isCounselor ? "e.g. 5 Years" : "e.g. 3rd Year")),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField("Age", "e.g. 21"),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Save Changes", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _buildTextField(String label, String hint) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
      const SizedBox(height: 6),
      TextField(
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: AppTheme.background,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
      ),
    ],
  );
}



