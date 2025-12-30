import 'dart:convert';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // --- State Variables ---
  String _userId = "";
  String _email = "Loading...";
  String _name = "Loading...";
  String _phoneNumber = "";
  String _role = "";
  String? _imageUrl; // Nullable to handle default avatar logic
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAllProfileData();
  }

  // ==========================================
  // 🚀 BACKEND LOGIC
  // ==========================================

  Future<void> _fetchAllProfileData() async {
    try {
      // 1. Get Auth User (ID) & Attributes (Email)
      final user = await Amplify.Auth.getCurrentUser();
      final attributes = await Amplify.Auth.fetchUserAttributes();

      String fetchedEmail = "No email found";
      for (final element in attributes) {
        if (element.userAttributeKey == AuthUserAttributeKey.email) {
          fetchedEmail = element.value;
        }
      }

      // 2. Query Database for Business Data (Name, Phone, Role)
      // We use the Auth User ID to find the correct profile
      const String graphQLDocument = '''
        query GetUserProfile(\$id: ID!) {
          getUserProfile(id: \$id) {
            id
            name
            phoneNumber
            role
            imageUrl
          }
        }
      ''';

      final request = GraphQLRequest<String>(
        document: graphQLDocument,
        variables: {'id': user.userId},
        authorizationMode: APIAuthorizationType.userPools,
      );

      final response = await Amplify.API.query(request: request).response;

      if (response.data != null) {
        final data = jsonDecode(response.data!);
        final userProfile = data['getUserProfile'];

        if (userProfile != null) {
          if (mounted) {
            setState(() {
              _userId = user.userId;
              _email = fetchedEmail;
              _name = userProfile['name'] ?? "User";
              _phoneNumber = userProfile['phoneNumber'] ?? "";
              _role = userProfile['role'] ?? "STUDENT";
              _imageUrl = userProfile['imageUrl'];
              _isLoading = false;
            });
          }
        } else {
          // Profile ID mismatch or doesn't exist yet
          if (mounted) setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      safePrint("Error fetching profile: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfile(String newName, String newPhone) async {
    // Optimistic UI Update
    setState(() {
      _name = newName;
      _phoneNumber = newPhone;
    });

    try {
      const String mutation = '''
        mutation UpdateProfile(\$id: ID!, \$name: String, \$phoneNumber: String) {
          updateUserProfile(input: {id: \$id, name: \$name, phoneNumber: \$phoneNumber}) {
            id
            name
            phoneNumber
          }
        }
      ''';

      final request = GraphQLRequest<String>(
        document: mutation,
        variables: {
          'id': _userId,
          'name': newName,
          'phoneNumber': newPhone,
        },
        authorizationMode: APIAuthorizationType.userPools,
      );

      final response = await Amplify.API.mutate(request: request).response;

      if (response.hasErrors) {
        safePrint("Update Errors: ${response.errors}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to save: ${response.errors.first.message}")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully! ✅")),
        );
      }
    } catch (e) {
      safePrint("Error updating profile: $e");
    }
  }

  Future<void> _signOut() async {
    try {
      await Amplify.Auth.signOut();
    } catch (e) {
      safePrint('Error signing out: $e');
    }
  }

  // ==========================================
  // ✏️ EDIT UI (Bottom Sheet)
  // ==========================================

  void _showEditProfileSheet() {
    final nameController = TextEditingController(text: _name);
    final phoneController = TextEditingController(text: _phoneNumber);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allow full height for keyboard
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24 // Keyboard padding
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Edit Profile",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: "Full Name",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: "Phone Number",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _updateProfile(nameController.text, phoneController.text);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E293B),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Save Changes", style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // 🎨 MAIN BUILD
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "My Profile",
          style: GoogleFonts.plusJakartaSans(
            color: const Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 32),

            // Account Section
            _buildSectionTitle("Account"),
            const SizedBox(height: 12),
            _buildProfileOption(
              icon: FontAwesomeIcons.userPen,
              title: "Personal Information",
              onTap: _showEditProfileSheet, // Opens Edit Sheet
            ),
            _buildProfileOption(
              icon: FontAwesomeIcons.bell,
              title: "Notifications",
              onTap: () {},
            ),
            _buildProfileOption(
              icon: FontAwesomeIcons.lock,
              title: "Privacy & Security",
              onTap: () {},
            ),

            const SizedBox(height: 24),

            // Support Section
            _buildSectionTitle("Support"),
            const SizedBox(height: 12),
            _buildProfileOption(
              icon: FontAwesomeIcons.circleQuestion,
              title: "Help Center",
              onTap: () {},
            ),
            _buildProfileOption(
              icon: FontAwesomeIcons.fileContract,
              title: "Terms & Conditions",
              onTap: () {},
            ),

            const SizedBox(height: 40),

            // Log Out
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _signOut,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.red.shade100),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.logout_rounded, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      "Log Out",
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 🧩 WIDGETS
  // ==========================================

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: const Color(0xFFA1C4FD),
                // Show Image if valid, else Initials
                backgroundImage: (_imageUrl != null && _imageUrl!.isNotEmpty)
                    ? NetworkImage(_imageUrl!)
                    : null,
                child: (_imageUrl == null || _imageUrl!.isEmpty)
                    ? Text(
                  _name.isNotEmpty ? _name[0].toUpperCase() : "U",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                )
                    : null,
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _showEditProfileSheet,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.blueAccent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit, size: 16, color: Colors.white),
                ),
              ),
            )
          ],
        ),
        const SizedBox(height: 16),
        Text(
          _name,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "$_email  •  $_role",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: Colors.grey[500],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey[400],
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF1E293B)),
        ),
        title: Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
        subtitle: subtitle != null
            ? Text(subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey))
            : null,
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      ),
    );
  }
}
