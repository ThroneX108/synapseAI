import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';

// --- Models ---

class Counsellor {
  final String id;
  final String name;
  final String specialization;
  final String experience;
  final double rating;
  final String imageUrl;
  final bool isOnline;

  Counsellor({
    required this.id,
    required this.name,
    required this.specialization,
    required this.experience,
    required this.rating,
    required this.imageUrl,
    this.isOnline = false,
  });
}

class AvailableSlot {
  final String id;
  final String time;

  AvailableSlot({required this.id, required this.time});
}

// --- Main Screen ---

class TalkToCounsellorScreen extends StatefulWidget {
  const TalkToCounsellorScreen({super.key});

  @override
  State<TalkToCounsellorScreen> createState() => _TalkToCounsellorScreenState();
}

class _TalkToCounsellorScreenState extends State<TalkToCounsellorScreen> {
  List<Counsellor> _counsellors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCounsellors();
  }

  // ✅ FETCH REAL COUNSELORS
  Future<void> _fetchCounsellors() async {
    try {
      const graphQLDocument = '''query ListRealCounselors {
        listCounselorProfiles {
          items {
            id
            specialization
            experienceYears
            rating
            isOnline
            user {
              name
              imageUrl
            }
          }
        }
      }''';

      final request = GraphQLRequest<String>(
        authorizationMode: APIAuthorizationType.userPools,
        document: graphQLDocument,
      );
      final response = await Amplify.API.query(request: request).response;

      if (response.data != null) {
        final Map<String, dynamic> data = jsonDecode(response.data!);
        final List items = data['listCounselorProfiles']['items'];

        if (mounted) {
          setState(() {
            _counsellors = items.map((item) {
              final user = item['user'] ?? {};
              return Counsellor(
                id: item['id'],
                name: user['name'] ?? "Unknown Expert",
                specialization: item['specialization'] ?? "General",
                experience: "${item['experienceYears'] ?? 0} Years",
                rating: (item['rating'] ?? 0).toDouble(),
                isOnline: item['isOnline'] ?? false,
                imageUrl: user['imageUrl'] ?? '',
              );
            }).toList();
            _isLoading = false;
          });
        }
      } else {
        safePrint("Errors: ${response.errors}");
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      safePrint("Error fetching counselors: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  // ✅ Success Dialog Logic (Moved to Parent)
  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Icon(Icons.check_circle, color: Colors.green, size: 50),
        content: const Text(
          "Booking Request Sent!\n\nThe counselor will confirm your session shortly.",
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  void _showBookingSheet(BuildContext context, Counsellor counsellor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BookingBottomSheet(
        counsellor: counsellor,
        onSuccess: _showSuccessDialog, // ✅ Pass callback
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Talk to an Expert', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _counsellors.isEmpty
          ? _buildEmptyState()
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHelplineCard(),
            const SizedBox(height: 24),
            const Text('Available Counsellors', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _counsellors.length,
              itemBuilder: (context, index) {
                return CounsellorCard(
                  counsellor: _counsellors[index],
                  onBookTap: () => _showBookingSheet(context, _counsellors[index]),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off_outlined, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text("No counselors available yet.", style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildHelplineCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFCDD2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
            child: const Icon(Icons.sos, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Need immediate help?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFD32F2F))),
                SizedBox(height: 4),
                Text('24/7 Suicide Prevention Helpline', style: TextStyle(fontSize: 12, color: Colors.black87)),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _makePhoneCall('1800-599-0019'),
            style: TextButton.styleFrom(backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
            child: const Text('Call Now', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// --- Components ---

class CounsellorCard extends StatelessWidget {
  final Counsellor counsellor;
  final VoidCallback onBookTap;

  const CounsellorCard({super.key, required this.counsellor, required this.onBookTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.teal.shade50,
                      child: Text(counsellor.name.isNotEmpty ? counsellor.name[0] : "D", style: TextStyle(fontSize: 24, color: Colors.teal.shade800, fontWeight: FontWeight.bold)),
                    ),
                    if (counsellor.isOnline)
                      Positioned(bottom: 0, right: 0, child: Container(width: 14, height: 14, decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)))),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(counsellor.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(counsellor.specialization, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.star, size: 16, color: Colors.amber[700]),
                          const SizedBox(width: 4),
                          Text(counsellor.rating.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 12),
                          Icon(Icons.work, size: 16, color: Colors.grey[400]),
                          const SizedBox(width: 4),
                          Text(counsellor.experience, style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onBookTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3b5998),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                ),
                child: const Text('View Available Slots', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- BOOKING SHEET ---

class BookingBottomSheet extends StatefulWidget {
  final Counsellor counsellor;
  final VoidCallback onSuccess;

  const BookingBottomSheet({super.key, required this.counsellor, required this.onSuccess});

  @override
  State<BookingBottomSheet> createState() => _BookingBottomSheetState();
}

class _BookingBottomSheetState extends State<BookingBottomSheet> {
  int selectedDateIndex = 0;
  String? selectedSlotId;
  bool _isBooking = false;
  bool _isLoadingSlots = false;

  // ✅ 1. ADDED TOPIC CONTROLLER
  final TextEditingController _topicController = TextEditingController();

  List<AvailableSlot> _availableSlots = [];
  String _myStudentId = "";

  @override
  void initState() {
    super.initState();
    _fetchStudentId();
    _fetchSlotsForDate(0);
  }

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  // 1. Get MY Student ID (Keep existing logic)
  Future<void> _fetchStudentId() async {
    try {
      final user = await Amplify.Auth.getCurrentUser();
      const query = '''
        query FindMyStudentProfile(\$uid: ID!) {
          listStudentProfiles(filter: { userProfileID: { eq: \$uid } }) {
            items {
              id
            }
          }
        }
      ''';

      final req = GraphQLRequest<String>(
        document: query,
        variables: {'uid': user.userId},
        authorizationMode: APIAuthorizationType.userPools,
      );
      final res = await Amplify.API.query(request: req).response;

      if (res.data != null) {
        final data = jsonDecode(res.data!);
        final items = data['listStudentProfiles']['items'] as List;

        if (items.isNotEmpty) {
          setState(() {
            _myStudentId = items[0]['id'];
          });
        }
      }
    } catch (e) {
      safePrint("Error fetching student ID: $e");
    }
  }

  // 2. Fetch Slots (Keep existing logic)
  Future<void> _fetchSlotsForDate(int dayIndex) async {
    setState(() {
      selectedDateIndex = dayIndex;
      selectedSlotId = null;
      _isLoadingSlots = true;
      _availableSlots = [];
    });

    try {
      final dateObj = DateTime.now().add(Duration(days: dayIndex));
      final awsDate = DateFormat('yyyy-MM-dd').format(dateObj);

      const query = '''query GetSlots(\$cid: ID!, \$date: String!) {
        listAppointments(filter: { 
          counselorID: { eq: \$cid }, 
          date: { eq: \$date },
          status: { eq: AVAILABLE } 
        }) {
          items { id timeSlot }
        }
      }''';

      final req = GraphQLRequest<String>(
        document: query,
        variables: {'cid': widget.counsellor.id, 'date': awsDate},
        authorizationMode: APIAuthorizationType.userPools,
      );
      final res = await Amplify.API.query(request: req).response;

      if (res.data != null) {
        final data = jsonDecode(res.data!);
        final items = data['listAppointments']['items'] as List;

        items.sort((a, b) => a['timeSlot'].compareTo(b['timeSlot']));

        if (mounted) {
          setState(() {
            _availableSlots = items.map((e) => AvailableSlot(id: e['id'], time: e['timeSlot'])).toList();
            _isLoadingSlots = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingSlots = false);
      }
    } catch (e) {
      safePrint("Error slots: $e");
      if (mounted) setState(() => _isLoadingSlots = false);
    }
  }

  // 3. Confirm Booking (UPDATED to include Topic)
  Future<void> _confirmBooking() async {
    if (_myStudentId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error: Could not find your student profile.")));
      return;
    }

    // ✅ Get topic text
    final topic = _topicController.text.trim().isEmpty ? "General Session" : _topicController.text.trim();

    setState(() => _isBooking = true);

    try {
      // ✅ Added $topic to mutation
      const mutation = '''mutation BookSlot(\$id: ID!, \$sid: ID!, \$topic: String) {
        updateAppointment(input: { 
          id: \$id, 
          studentID: \$sid, 
          status: PENDING,
          topic: \$topic
        }) {
          id
        }
      }''';

      final request = GraphQLRequest<String>(
        document: mutation,
        variables: {
          "id": selectedSlotId,
          "sid": _myStudentId,
          "topic": topic, // ✅ Pass topic variable
        },
        authorizationMode: APIAuthorizationType.userPools,
      );

      final response = await Amplify.API.mutate(request: request).response;

      if (!mounted) return;
      setState(() => _isBooking = false);

      if (response.hasErrors) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Booking Failed: ${response.errors.first.message}")));
      } else {
        Navigator.pop(context); // Close sheet
        widget.onSuccess(); // ✅ Call parent callback
      }
    } catch (e) {
      safePrint("Error booking: $e");
      if (mounted) setState(() => _isBooking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView( // ✅ Added Scroll View to support keyboard
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text("Book Session", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueGrey[800])),
                const Spacer(),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
            Text("with ${widget.counsellor.name}", style: TextStyle(color: Colors.grey[500], fontSize: 14)),
            const SizedBox(height: 24),

            // Date Selector
            SizedBox(
              height: 75,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 7,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final date = DateTime.now().add(Duration(days: index));
                  final isSelected = selectedDateIndex == index;
                  return GestureDetector(
                    onTap: () => _fetchSlotsForDate(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 60,
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF3b5998) : Colors.grey[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isSelected ? Colors.transparent : Colors.grey[200]!),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(DateFormat('d').format(date), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black87)),
                          Text(DateFormat('E').format(date), style: TextStyle(fontSize: 12, color: isSelected ? Colors.white70 : Colors.grey)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Slots Grid
            const Text("Available Times", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),

            if (_isLoadingSlots)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
            else if (_availableSlots.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12)),
                child: const Text("No slots available for this date.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
              )
            else
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _availableSlots.map((slot) {
                  final isSelected = selectedSlotId == slot.id;
                  return ChoiceChip(
                    label: Text(slot.time),
                    selected: isSelected,
                    selectedColor: const Color(0xFF3b5998).withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: isSelected ? const Color(0xFF3b5998) : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (val) => setState(() => selectedSlotId = val ? slot.id : null),
                  );
                }).toList(),
              ),

            const SizedBox(height: 24),

            // ✅ 4. ADDED TEXT FIELD FOR TOPIC
            const Text("Session Topic", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: _topicController,
              decoration: InputDecoration(
                hintText: "e.g. Exam Stress, Relationship Issues...",
                hintStyle: TextStyle(color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),

            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: (selectedSlotId != null && !_isBooking) ? _confirmBooking : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3b5998),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  disabledBackgroundColor: Colors.grey[300],
                ),
                child: _isBooking
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Confirm Booking', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
