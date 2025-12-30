import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:google_fonts/google_fonts.dart';

// Imports for navigation (ensure these paths match your project)
import 'package:synapse/features/counsellor/dashboard/screens/counsellor_dashboard.dart';
import 'package:synapse/features/counsellor/home/main_screen.dart';

import '../student/home/main_screen.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  final _nameController = TextEditingController();

  // Backend value must match GraphQL Enum exactly: 'STUDENT' or 'COUNSELOR'
  String? _selectedRole;
  bool _isSaving = false;

  final Color _brandColor = const Color(0xFF3b5998);
  final Color _accentColor = const Color(0xFF1E293B);

  Future<void> _saveProfile() async {
    if (_selectedRole == null || _nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Please enter your name and select a role",
            style: GoogleFonts.plusJakartaSans(),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = await Amplify.Auth.getCurrentUser();

      // Define the mutation
      const graphQLDocument = '''
        mutation CreateUserProfile(\$input: CreateUserProfileInput!) {
          createUserProfile(input: \$input) {
            id
            name
            role
          }
        }
      ''';

      final request = GraphQLRequest<String>(
        document: graphQLDocument,
        // FIX 1: Explicitly use User Pools to ensure the token is sent
        authorizationMode: APIAuthorizationType.userPools,
        variables: {
          'input': {
            'id': user.userId,
            'name': _nameController.text.trim(),
            'role': _selectedRole,
            // 'phoneNumber': ... // Add if you captured it
          }
        },
      );

      final response = await Amplify.API.mutate(request: request).response;

      if (response.errors.isNotEmpty) {
        // Log the specific error from AppSync
        safePrint("AppSync Error: ${response.errors.first.message}");
        throw Exception(response.errors.first.message);
      }

      if (!mounted) return;
      _redirectByRole(_selectedRole!);

    } catch (e) {
      safePrint("Profile creation error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _redirectByRole(String role) {
    late final Widget next;
    // Switch case to handle redirection
    switch (role) {
      case 'COUNSELOR':
      // Ensure you are navigating to the Dashboard wrapper that handles tabs
        next = CounsellorMainScreen();
        break;
      case 'STUDENT':
      default:
        next = const MainScreen();
    }

    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => next),
            (route) => false // Clears the back stack so they can't go back to Role Selection
    );
  }

  // ... (Rest of your build method and _buildRoleCard remain the same)
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                "Welcome to Synapse",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: _accentColor,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Let's personalize your experience. Are you seeking help or offering guidance?",
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.grey[600],
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              Text(
                "What should we call you?",
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: _accentColor, fontSize: 14),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: "Enter your full name",
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                "I am a...",
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: _accentColor, fontSize: 14),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildRoleCard(
                      label: "Student",
                      backendValue: "STUDENT",
                      icon: Icons.school_rounded,
                      description: "I need support",
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildRoleCard(
                      label: "Counselor",
                      backendValue: "COUNSELOR",
                      icon: Icons.health_and_safety_rounded,
                      description: "I provide guidance",
                    ),
                  ),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _brandColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text("Continue", style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({required String label, required String backendValue, required IconData icon, required String description}) {
    final isSelected = _selectedRole == backendValue;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = backendValue),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 160,
        decoration: BoxDecoration(
          color: isSelected ? _brandColor.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? _brandColor : Colors.grey.shade200, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: isSelected ? _brandColor : Colors.grey[400]),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? _brandColor : Colors.black87)),
            Text(description, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }
}
