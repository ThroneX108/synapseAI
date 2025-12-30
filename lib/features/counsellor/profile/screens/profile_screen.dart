import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:synapse/features/counsellor/profile/screens/edit_profile_screen.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  // Helper method to extract initials
  String _getInitials(String name) {
    if (name.isEmpty) return "";
    List<String> nameParts = name.trim().split(RegExp(r'\s+'));

    if (nameParts.isEmpty) return "";

    String firstInitial = nameParts.first[0].toUpperCase();

    // If there is more than one name, take the first letter of the last name
    if (nameParts.length > 1) {
      String lastInitial = nameParts.last[0].toUpperCase();
      return "$firstInitial$lastInitial";
    }

    return firstInitial;
  }

  @override
  Widget build(BuildContext context) {
    // Define the data here (In a real app, this comes from your User Model/Provider)
    const String title = "Dr.";
    const String fullName = "Yashendra Sharma";

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
              child: Row(
                children: [
                  // Dynamic Circle Avatar
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: const Color(0xFF3b5998),
                    child: Text(
                      _getInitials(fullName), // Generates "AS"
                      style: const TextStyle(
                          fontSize: 24,
                          color: Colors.white,
                          fontWeight: FontWeight.bold
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "$title $fullName", // Displays "Dr. Anjali Sharma"
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "Clinical Psychologist",
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          "Verified Profile",
                          style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Settings List
            _buildSettingsSection(
              "Account Settings",
              [
                _buildListTile(Icons.person_outline, "Edit Profile", () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const EditProfileScreen())
                  );
                }),
                _buildListTile(Icons.notifications_outlined, "Notifications", () {}),
                _buildListTile(Icons.lock_outline, "Privacy & Security", () {}),
              ],
            ),

            _buildSettingsSection(
              "Support",
              [
                _buildListTile(Icons.help_outline, "Help & Support", () {}),
                _buildListTile(Icons.info_outline, "Terms & Conditions", () {}),
              ],
            ),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ElevatedButton(
                onPressed: () async {
                  await Amplify.Auth.signOut();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[50],
                  foregroundColor: Colors.red,
                  elevation: 0,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Log Out", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> tiles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.grey[500],
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          color: Colors.white,
          child: Column(children: tiles),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildListTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: Colors.grey[700], size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }
}
