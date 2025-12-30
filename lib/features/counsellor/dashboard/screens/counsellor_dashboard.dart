import 'dart:convert';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:synapse/features/counsellor/dashboard/screens/all_requests_screen.dart';

import '../../schedule/screens/session_details_screen.dart';


class CounsellorDashboard extends StatefulWidget {
  final Function(int) onSwitchTab;

  const CounsellorDashboard({super.key, required this.onSwitchTab});

  @override
  State<CounsellorDashboard> createState() => _CounsellorDashboardState();
}

class _CounsellorDashboardState extends State<CounsellorDashboard> {
  // ... (Keep existing State Variables & initState) ...
  bool _isLoading = true;
  bool _isOnline = false;
  String _counselorProfileId = "";
  String _counselorName = "Dr. Expert";
  String _specialization = "Psychologist";
  int _pendingCount = 0;
  int _todayCount = 0;
  int _totalCount = 0;
  List<dynamic> _upcomingSessions = [];
  List<dynamic> _pendingRequests = [];

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  // ... (Keep existing _fetchDashboardData, _updateRequestStatus, _toggleOnlineStatus logic) ...

  // For brevity, I am not repeating the huge backend logic block here as it remains unchanged.
  // Just ensure _fetchDashboardData, _updateRequestStatus, etc. are still in your class.

  // ---------------------------------------------------------------------------
  // COPY PREVIOUS BACKEND LOGIC HERE (methods: _fetchDashboardData, etc.)
  // ---------------------------------------------------------------------------
  Future<void> _fetchDashboardData() async {
    // ... (Your existing fetch logic)
    // Same as provided in your prompt
    try {
      final user = await Amplify.Auth.getCurrentUser();

      // 1. FETCH PROFILE
      const String profileQuery = '''
        query GetMyCounselorProfile(\$uid: ID!) {
          listCounselorProfiles(filter: { userProfileID: { eq: \$uid } }) {
            items {
              id
              specialization
              isOnline
              user {
                name
                imageUrl
              }
            }
          }
        }
      ''';

      final profileReq = GraphQLRequest<String>(
        document: profileQuery,
        variables: {'uid': user.userId},
        authorizationMode: APIAuthorizationType.userPools,
      );
      final profileRes = await Amplify.API.query(request: profileReq).response;

      if (profileRes.data == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final profileData = jsonDecode(profileRes.data!);
      final items = profileData['listCounselorProfiles']['items'] as List;

      if (items.isEmpty) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final counselorProfile = items[0];
      final userProfile = counselorProfile['user'];
      _counselorProfileId = counselorProfile['id'];

      // 2. FETCH APPOINTMENTS
      const String apptQuery = '''
        query ListCounselorAppointments(\$cid: ID!) {
          listAppointments(filter: { counselorID: { eq: \$cid } }) {
            items {
              id
              date
              timeSlot
              status
              topic
              student {
                user {
                  name
                  imageUrl
                }
              }
            }
          }
        }
      ''';

      final apptReq = GraphQLRequest<String>(
        document: apptQuery,
        variables: {'cid': _counselorProfileId},
        authorizationMode: APIAuthorizationType.userPools,
      );
      final apptRes = await Amplify.API.query(request: apptReq).response;

      if (apptRes.data == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final apptData = jsonDecode(apptRes.data!);
      final List<dynamic> allAppts = apptData['listAppointments']['items'];

      // 3. PROCESS DATA
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      int pCount = 0;
      int tCount = 0;
      int totCount = 0;
      List<dynamic> upcoming = [];
      List<dynamic> requests = [];

      for (var appt in allAppts) {
        final status = appt['status'];
        final date = appt['date'];

        if (status == 'COMPLETED') totCount++;

        if (status == 'PENDING') {
          pCount++;
          requests.add(appt);
        }

        if (status == 'CONFIRMED') {
          if (date == todayStr) tCount++;
          if (date.compareTo(todayStr) >= 0) upcoming.add(appt);
        }
      }

      upcoming.sort((a, b) => a['date'].compareTo(b['date']));
      requests.sort((a, b) => a['date'].compareTo(b['date']));

      if (mounted) {
        setState(() {
          _counselorName = userProfile != null ? userProfile['name'] : "Doctor";
          _specialization = counselorProfile['specialization'] ?? "Specialist";
          _isOnline = counselorProfile['isOnline'] ?? false;
          _pendingCount = pCount;
          _todayCount = tCount;
          _totalCount = totCount;
          _upcomingSessions = upcoming;
          _pendingRequests = requests;
          _isLoading = false;
        });
      }

    } catch (e) {
      safePrint("Error fetching dashboard: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateRequestStatus(String appointmentId, bool isAccepted) async {
    // ... (Your existing status update logic)
    setState(() {
      _pendingRequests.removeWhere((appt) => appt['id'] == appointmentId);
      _pendingCount = _pendingRequests.length;
    });

    try {
      final newStatus = isAccepted ? "CONFIRMED" : "CANCELLED";

      const String mutation = '''
        mutation UpdateAppointmentStatus(\$id: ID!, \$status: AppointmentStatus!) {
          updateAppointment(input: { id: \$id, status: \$status }) {
            id
            status
          }
        }
      ''';

      final request = GraphQLRequest<String>(
        document: mutation,
        variables: {
          'id': appointmentId,
          'status': newStatus,
        },
        authorizationMode: APIAuthorizationType.userPools,
      );

      final response = await Amplify.API.mutate(request: request).response;

      if (response.hasErrors) {
        _fetchDashboardData(); // Revert on error
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${response.errors.first.message}")));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isAccepted ? "Session Confirmed" : "Request Declined"),
              backgroundColor: isAccepted ? Colors.green : Colors.red,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(milliseconds: 1500),
            ),
          );
          _fetchDashboardData(); // Refresh to update upcoming lists
        }
      }
    } catch (e) {
      safePrint("Error updating status: $e");
      _fetchDashboardData();
    }
  }

  Future<void> _toggleOnlineStatus(bool val) async {
    // ... (Your existing toggle logic)
    setState(() => _isOnline = val);
    try {
      const String mutation = '''
        mutation UpdateStatus(\$id: ID!, \$isOnline: Boolean!) {
          updateCounselorProfile(input: { id: \$id, isOnline: \$isOnline }) { id }
        }
      ''';
      final req = GraphQLRequest<String>(
        document: mutation,
        variables: {'id': _counselorProfileId, 'isOnline': val},
        authorizationMode: APIAuthorizationType.userPools,
      );
      await Amplify.API.mutate(request: req).response;
    } catch (e) {
      if (mounted) setState(() => _isOnline = !val);
    }
  }

  // ==========================================
  // 🎨 UI BUILD
  // ==========================================

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: _fetchDashboardData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Quick Stats
              Row(
                children: [
                  _buildStatCard(title: "Pending", count: "$_pendingCount", color: Colors.orange),
                  const SizedBox(width: 12),
                  _buildStatCard(title: "Today", count: "$_todayCount", color: const Color(0xFF3b5998)),
                  const SizedBox(width: 12),
                  _buildStatCard(title: "Total", count: "$_totalCount", color: Colors.blueGrey),
                ],
              ),
              const SizedBox(height: 30),

              // 2. Upcoming Sessions
              _buildSectionHeader(
                "Upcoming Sessions",
                onSeeAll: () => widget.onSwitchTab(1),
              ),
              const SizedBox(height: 16),

              if (_upcomingSessions.isEmpty)
                _buildEmptyState("No upcoming sessions today"),

              ..._upcomingSessions.take(3).map((appt) {
                final studentName = appt['student']?['user']?['name'] ?? "Unknown";
                final isToday = appt['date'] == DateFormat('yyyy-MM-dd').format(DateTime.now());

                return SessionCard(
                  appointmentId: appt['id'], // ✅ PASS ID HERE
                  name: studentName,
                  time: "${appt['timeSlot']} (${appt['date'].substring(5)})",
                  issue: appt['topic'] ?? "General",
                  isLive: isToday,
                );
              }),

              const SizedBox(height: 30),

              // 3. Pending Requests
              _buildSectionHeader(
                "New Requests",
                onSeeAll: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AllRequestsScreen())
                  );
                },
              ),
              const SizedBox(height: 16),

              if (_pendingRequests.isEmpty)
                _buildEmptyState("No pending requests"),

              ..._pendingRequests.take(3).map((appt) {
                final studentName = appt['student']?['user']?['name'] ?? "Unknown";

                return RequestCard(
                  name: studentName,
                  issue: appt['topic'] ?? "General",
                  timeRequested: "${appt['date']} @ ${appt['timeSlot']}",
                  onAccept: () => _updateRequestStatus(appt['id'], true),
                  onDecline: () => _updateRequestStatus(appt['id'], false),
                );
              }),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    // ... (Keep existing AppBar logic)
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _counselorName,
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
          ),
          Text(
            _specialization,
            style: TextStyle(color: Colors.grey[600], fontSize: 14, fontWeight: FontWeight.w400),
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: _isOnline ? Colors.green[50] : Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _isOnline ? Colors.green : Colors.grey[400]!),
          ),
          child: Row(
            children: [
              Text(
                _isOnline ? "Online" : "Offline",
                style: TextStyle(
                  color: _isOnline ? Colors.green[700] : Colors.grey[600],
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: _isOnline,
                  activeColor: Colors.green,
                  onChanged: _toggleOnlineStatus,
                ),
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildEmptyState(String text) {
    // ... (Keep existing empty state)
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!)
      ),
      child: Center(
        child: Text(text, style: TextStyle(color: Colors.grey[400], fontStyle: FontStyle.italic)),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {required VoidCallback onSeeAll}) {
    // ... (Keep existing header)
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
        InkWell(
          onTap: onSeeAll,
          child: const Padding(
            padding: EdgeInsets.all(4.0),
            child: Text("See All", style: TextStyle(color: Color(0xFF3b5998), fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({required String title, required String count, required Color color}) {
    // ... (Keep existing stat card)
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, spreadRadius: 2)],
        ),
        child: Column(
          children: [
            Text(count, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// --- UPDATED WIDGETS ---

class SessionCard extends StatelessWidget {
  final String appointmentId; // ✅ New Field
  final String name, time, issue;
  final bool isLive;

  const SessionCard({
    super.key,
    required this.appointmentId, // ✅ Require ID
    required this.name,
    required this.time,
    required this.issue,
    this.isLive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: Colors.grey[200],
                child: Text(name.isNotEmpty ? name[0] : "?", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(issue, style: const TextStyle(fontSize: 12, color: Color(0xFF3b5998), fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(time, style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w500)),

              if (isLive)
                InkWell( // ✅ WRAPPED IN INKWELL
                  onTap: () {
                    // ✅ NAVIGATE TO DETAILS
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SessionDetailsScreen(appointmentId: appointmentId),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(20)),
                    child: const Text("Join Now", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                )
            ],
          )
        ],
      ),
    );
  }
}

// ... (RequestCard remains unchanged) ...
class RequestCard extends StatelessWidget {
  final String name, issue, timeRequested;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const RequestCard({
    super.key,
    required this.name,
    required this.issue,
    required this.timeRequested,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[200]!)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text("$issue • $timeRequested", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(onPressed: onDecline, icon: const Icon(Icons.close, color: Colors.red)),
              IconButton(onPressed: onAccept, icon: const Icon(Icons.check, color: Colors.green)),
            ],
          )
        ],
      ),
    );
  }
}