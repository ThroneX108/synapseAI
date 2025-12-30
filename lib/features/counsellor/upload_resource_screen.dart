import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_animator/flutter_animator.dart';

import '../../../core/theme/app_theme.dart';
class UploadResourceWizard extends StatefulWidget {
  const UploadResourceWizard({super.key});

  @override
  State<UploadResourceWizard> createState() => _UploadResourceWizardState();
}

class _UploadResourceWizardState extends State<UploadResourceWizard> {
  int _currentStep = 0;
  String _selectedType = "Article";

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  String? _fileName;
  PlatformFile? _pickedFile;
  bool _isUploading = false;

  // --- LOGIC: FILE PICKER ---
  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video, // Restrict to videos if type is Video
      allowMultiple: false,
    );

    if (result != null) {
      setState(() {
        _pickedFile = result.files.first;
        _fileName = result.files.first.name;
      });
    }
  }

  // --- LOGIC: UPLOAD ---
  Future<void> _handleUpload() async {
    setState(() => _isUploading = true);

    // Simulate Network Delay
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _isUploading = false);
      // Show Success Dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Icon(Icons.check_circle, color: Colors.green, size: 48),
          content: Text(
            "Resource Uploaded Successfully!",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close Dialog
                Navigator.pop(context); // Close Screen
              },
              child: const Text("Done"),
            )
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text("Upload Resource", style: GoogleFonts.poppins(color: AppTheme.textDark, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: Column(
        children: [
          // 1. PROGRESS INDICATOR
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStepIndicator(0, "Type"),
                _buildConnector(0),
                _buildStepIndicator(1, "Details"),
                _buildConnector(1),
                _buildStepIndicator(2, "Upload"),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 2. WIZARD CONTENT AREA
          Expanded(
            child: FadeInUp(
              key: ValueKey(_currentStep), // Animates when step changes
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: _buildStepContent(),
              ),
            ),
          ),

          // 3. NAVIGATION BUTTONS
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0,-2))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentStep > 0)
                  OutlinedButton(
                    onPressed: _isUploading ? null : () => setState(() => _currentStep--),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Back", style: TextStyle(color: Colors.grey)),
                  )
                else
                  const SizedBox(), // Spacer

                ElevatedButton(
                  onPressed: _isUploading
                      ? null
                      : () {
                    if (_currentStep < 2) {
                      setState(() => _currentStep++);
                    } else {
                      _handleUpload();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isUploading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(_currentStep == 2 ? "Publish Now" : "Next Step", style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0: // SELECT TYPE
        return Column(
          children: [
            Text("What are you sharing?", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
            const SizedBox(height: 24),
            _buildTypeCard("Article", Icons.article_outlined, "Share knowledge via text"),
            const SizedBox(height: 16),
            _buildTypeCard("Video", Icons.play_circle_outline, "Upload a video session"),
          ],
        );

      case 1: // ENTER DETAILS
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Resource Details", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
            const SizedBox(height: 24),
            _buildLabel("Title"),
            TextField(
              controller: _titleController,
              decoration: _inputDecor("e.g. Coping with Anxiety"),
            ),
            const SizedBox(height: 20),

            if (_selectedType == "Article") ...[
              _buildLabel("Article Content"),
              TextField(
                controller: _contentController,
                maxLines: 10,
                decoration: _inputDecor("Write or paste your article here..."),
              ),
            ] else ...[
              _buildLabel("Video File"),
              GestureDetector(
                onTap: _pickFile,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.primary.withOpacity(0.5), style: BorderStyle.solid),
                  ),
                  child: Column(
                    children: [
                      Icon(_pickedFile == null ? Icons.cloud_upload_outlined : Icons.check_circle, size: 48, color: AppTheme.primary),
                      const SizedBox(height: 12),
                      Text(
                        _pickedFile == null ? "Tap to select video" : _fileName!,
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ]
          ],
        );

      case 2: // REVIEW & UPLOAD
        return Column(
          children: [
            Icon(Icons.rocket_launch, size: 80, color: AppTheme.secondary),
            const SizedBox(height: 24),
            Text("Ready to Publish?", style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text("Review your details below before publishing.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 32),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[200]!)),
              child: Column(
                children: [
                  _buildSummaryRow("Type", _selectedType),
                  const Divider(height: 24),
                  _buildSummaryRow("Title", _titleController.text.isEmpty ? "Untitled" : _titleController.text),
                  const Divider(height: 24),
                  _buildSummaryRow("Content", _selectedType == "Article" ? "${_contentController.text.length} characters" : _fileName ?? "No file selected"),
                ],
              ),
            )
          ],
        );

      default:
        return const SizedBox();
    }
  }

  // --- HELPER WIDGETS ---

  Widget _buildStepIndicator(int stepIndex, String label) {
    bool isActive = _currentStep >= stepIndex;
    return Column(
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primary : Colors.grey[200],
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text("${stepIndex + 1}", style: TextStyle(color: isActive ? Colors.white : Colors.grey, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, color: isActive ? AppTheme.primary : Colors.grey, fontWeight: FontWeight.bold))
      ],
    );
  }

  Widget _buildConnector(int index) {
    return Container(
      width: 40, height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 14), // Align with circle center
      color: _currentStep > index ? AppTheme.primary : Colors.grey[200],
    );
  }

  Widget _buildTypeCard(String type, IconData icon, String subtext) {
    bool isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? AppTheme.primary : Colors.grey[200]!, width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: isSelected ? AppTheme.primary : Colors.grey[100], borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: isSelected ? Colors.white : Colors.grey),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(type, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: isSelected ? AppTheme.primary : Colors.black)),
                Text(subtext, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            const Spacer(),
            if (isSelected) const Icon(Icons.check_circle, color: AppTheme.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  InputDecoration _inputDecor(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.all(16),
    );
  }
}