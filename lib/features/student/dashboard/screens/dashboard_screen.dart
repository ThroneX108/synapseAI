import 'dart:convert';
import 'package:amplify_authenticator/amplify_authenticator.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';

// ✅ SCREEN IMPORTS
// Adjust these paths to match your actual project structure
import '../../../auth/role_selection_screen.dart';
import '../../../counsellor/home/main_screen.dart';
import '../../counselling/screens/talk_to_counsellor.dart';
import '../../profile/screens/profile_screen.dart'; // Import the Profile Screen

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // --- STATE VARIABLES ---
  String _userName = "Loading...";
  int _wellnessScore = 50; // Default to 50
  String _currentMood = "Neutral";

  // Chart & Lifestyle Data
  List<FlSpot> _moodSpots = const [FlSpot(0, 0)];
  String _avgSleep = "0h";
  double _sleepPercent = 0.0;
  String _avgFocus = "0h";
  double _focusPercent = 0.0;

  bool _isLoading = true;
  bool _profileExists = true;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  // ==========================================
  // 🚀 BACKEND LOGIC
  // ==========================================

  Future<void> _fetchDashboardData() async {
    try {
      final user = await Amplify.Auth.getCurrentUser();

      // 1. Query User Profile AND Linked Student Data
      const graphQLDocument = '''
        query GetUserAndStudentData(\$id: ID!) {
          getUserProfile(id: \$id) {
            id
            name
            role
            studentProfile {
              id
              wellnessScore
              currentMood
              moodLogs {
                items {
                  score
                  date
                  sleepHours
                  focusHours
                }
              }
            }
          }
        }
      ''';

      // 2. Request with Authorization Mode
      final request = GraphQLRequest<String>(
        document: graphQLDocument,
        variables: {'id': user.userId},
        authorizationMode: APIAuthorizationType.userPools,
      );

      final response = await Amplify.API.query(request: request).response;

      // Handle GraphQL Errors
      if (response.data == null || response.errors.isNotEmpty) {
        if (response.errors.isNotEmpty) {
          safePrint("Query Errors: ${response.errors}");
        }
        _handleMissingProfile();
        return;
      }

      final data = jsonDecode(response.data!);
      final userProfile = data['getUserProfile'];

      // If Profile doesn't exist in DB yet
      if (userProfile == null) {
        _handleMissingProfile();
        return;
      }

      // 3. Role Check & Redirection
      if (userProfile['role'] == 'COUNSELOR') {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CounsellorMainScreen()),
        );
        return;
      }

      // 4. Parse Student Data
      final studentData = userProfile['studentProfile'];

      // Process Mood Logs for Chart
      List<FlSpot> spots = [];
      double totalSleep = 0;
      double totalFocus = 0;
      int logCount = 0;

      if (studentData != null && studentData['moodLogs'] != null) {
        final logs = studentData['moodLogs']['items'] as List;

        // Sort logs by date (Oldest -> Newest)
        logs.sort((a, b) => a['date'].compareTo(b['date']));

        // Map last 7 logs to chart
        int startIndex = (logs.length > 7) ? logs.length - 7 : 0;

        for (int i = startIndex; i < logs.length; i++) {
          final log = logs[i];
          // X-axis is index (0 to 6), Y-axis is score
          spots.add(FlSpot((i - startIndex).toDouble(), (log['score'] as num).toDouble()));

          totalSleep += (log['sleepHours'] ?? 0);
          totalFocus += (log['focusHours'] ?? 0);
        }
        logCount = logs.length - startIndex;
      }

      // 5. Update UI State
      if (!mounted) return;
      setState(() {
        _userName = userProfile['name'] ?? "Friend";
        _profileExists = true;
        _isLoading = false;

        if (studentData != null) {
          _wellnessScore = studentData['wellnessScore'] ?? 50;
          _currentMood = studentData['currentMood'] ?? "Neutral";

          if (spots.isNotEmpty) {
            _moodSpots = spots;

            // Calculate Averages
            double avgS = logCount > 0 ? totalSleep / logCount : 0;
            _avgSleep = "${avgS.toStringAsFixed(1)}h";
            _sleepPercent = (avgS / 8).clamp(0.0, 1.0); // Assuming 8h goal

            double avgF = logCount > 0 ? totalFocus / logCount : 0;
            _avgFocus = "${avgF.toStringAsFixed(1)}h";
            _focusPercent = (avgF / 6).clamp(0.0, 1.0); // Assuming 6h goal
          }
        }
      });

    } catch (e) {
      safePrint("Dashboard fetch error: $e");
      _handleMissingProfile();
    }
  }

  void _handleMissingProfile() {
    if (!mounted) return;
    setState(() {
      _userName = "User";
      _profileExists = false;
      _isLoading = false;
    });
  }

  // ==========================================
  // 🎨 UI SCAFFOLD
  // ==========================================

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_profileExists) {
      return _buildMissingProfileScreen();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildMentalBatteryCard(),

              const SizedBox(height: 24),
              _buildCounsellorCard(),

              const SizedBox(height: 24),
              _buildSectionTitle("Weekly Trends"),
              const SizedBox(height: 16),
              _buildMoodChart(),

              const SizedBox(height: 24),
              _buildSectionTitle("Lifestyle Pulse"),
              const SizedBox(height: 16),
              _buildLifestyleGrid(),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 🧩 WIDGETS
  // ==========================================

  Widget _buildMissingProfileScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_circle_outlined, size: 80, color: Colors.orange),
            const SizedBox(height: 24),
            Text(
              "Profile Missing",
              style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              "You are logged in, but we don't know your name or role yet.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E293B),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Complete Setup", style: TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 16),
            const SignOutButton(), // Amplify Widget
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Good Morning,",
              style: GoogleFonts.plusJakartaSans(fontSize: 16, color: Colors.grey[600]),
            ),
            Text(
              _userName,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        // ✅ PROFILE NAVIGATION
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))],
            ),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: Colors.teal.shade100,
              child: Text(
                _userName.isNotEmpty ? _userName[0].toUpperCase() : "U",
                style: const TextStyle(fontSize: 20, color: Colors.teal),
              ),
            ),
          ),
        ),
      ],
    ).animate().fadeIn().slideY(begin: -0.2, end: 0);
  }

  Widget _buildMentalBatteryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFA1C4FD), Color(0xFFC2E9FB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFA1C4FD).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Mental Battery",
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF1E293B),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Current Mood: $_currentMood",
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF1E293B).withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              CircularPercentIndicator(
                radius: 30.0,
                lineWidth: 6.0,
                percent: (_wellnessScore / 100).clamp(0.0, 1.0),
                center: Text(
                  "$_wellnessScore%",
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                progressColor: Colors.white,
                backgroundColor: Colors.white.withOpacity(0.3),
                circularStrokeCap: CircularStrokeCap.round,
              ),
            ],
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Mood Logging Feature coming next update! 🚀"))
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(FontAwesomeIcons.penToSquare, size: 16, color: Color(0xFF1E293B)),
                  const SizedBox(width: 10),
                  Text(
                    "Log today's mood",
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF1E293B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF1E293B)),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).scale();
  }

  Widget _buildCounsellorCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const TalkToCounsellorScreen()),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.teal.withOpacity(0.1), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.teal.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.teal.shade50, shape: BoxShape.circle),
              child: Icon(FontAwesomeIcons.userDoctor, color: Colors.teal.shade700, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Need someone to talk to?",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Book a confidential session",
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 250.ms).slideX();
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF1E293B),
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildMoodChart() {
    // If no data, show a placeholder
    if (_moodSpots.length <= 1) {
      return Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Center(
          child: Text(
            "Log your mood to see trends",
            style: GoogleFonts.plusJakartaSans(color: Colors.grey),
          ),
        ),
      );
    }

    return Container(
      height: 220,
      padding: const EdgeInsets.only(right: 20, left: 20, top: 24, bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: 6, // 7 Days (0-6)
          minY: 0,
          maxY: 10,
          lineBarsData: [
            LineChartBarData(
              spots: _moodSpots,
              isCurved: true,
              color: const Color(0xFFA1C4FD),
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFA1C4FD).withOpacity(0.3),
                    const Color(0xFFA1C4FD).withOpacity(0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 400.ms).slideX();
  }

  Widget _buildLifestyleGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            "Sleep",
            _avgSleep,
            _sleepPercent,
            FontAwesomeIcons.moon,
            Colors.purpleAccent,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildInfoCard(
            "Focus",
            _avgFocus,
            _focusPercent,
            FontAwesomeIcons.brain,
            Colors.tealAccent,
          ),
        ),
      ],
    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildInfoCard(String title, String value, double percent, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, size: 16, color: color.withOpacity(0.8)),
              ),
              CircularPercentIndicator(
                radius: 18.0,
                lineWidth: 4.0,
                percent: percent,
                progressColor: color.withOpacity(0.8),
                backgroundColor: color.withOpacity(0.1),
                circularStrokeCap: CircularStrokeCap.round,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
