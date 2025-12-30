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
  final bool isAvailableNow;
  final List<String> languages;
  final String imageUrl;

  Counsellor({
    required this.id,
    required this.name,
    required this.specialization,
    required this.experience,
    required this.rating,
    required this.isAvailableNow,
    required this.languages,
    required this.imageUrl,
  });
}

// --- Main Screen ---

class TalkToCounsellorScreen extends StatefulWidget {
  const TalkToCounsellorScreen({super.key});

  @override
  State<TalkToCounsellorScreen> createState() => _TalkToCounsellorScreenState();
}

class _TalkToCounsellorScreenState extends State<TalkToCounsellorScreen> {
  // State Variables
  List<Counsellor> _counsellors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCounsellors();
  }

  // ✅ FIXED FETCH FUNCTION
  Future<void> _fetchCounsellors() async {
    try {
      // 1. Updated Query (Removed 'details' which caused the crash)
      const graphQLDocument = '''query ListCounselors {
        listUserProfiles(filter: { role: { eq: COUNSELOR } }) {
          items {
            id
            name
            imageUrl
            # You can add phoneNumber here if needed
          }
        }
      }''';

      final request = GraphQLRequest<String>(
        authorizationMode: APIAuthorizationType.userPools,
          document: graphQLDocument);
      final response = await Amplify.API.query(request: request).response;

      // 2. Safety Check: Handle Errors gracefully
      if (response.hasErrors) {
        safePrint("GraphQL Errors: ${response.errors}");
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      if (response.data != null) {
        final Map<String, dynamic> data = jsonDecode(response.data!);
        final List items = data['listUserProfiles']['items'];

        if (mounted) {
          setState(() {
            _counsellors = items.map((item) {
              return Counsellor(
                id: item['id'],
                name: item['name'] ?? "Unknown Expert",
                // Mocking these for now as they aren't in UserProfile
                // To fix this permanently, you should fetch from 'CounselorProfile' table
                specialization: "General Therapy",
                experience: "5+ Years",
                rating: 4.8,
                isAvailableNow: true,
                languages: ['English', 'Hindi'],
                imageUrl: item['imageUrl'] ?? 'assets/images/doc1.png',
              );
            }).toList();
            _isLoading = false;
          });
        }
      } else {
        // Data is null but no errors? Stop loading anyway.
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      safePrint("Error fetching counselors: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Method to launch phone dialer
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not launch dialer')));
      }
    }
  }

  void _showBookingSheet(BuildContext context, Counsellor counsellor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => BookingBottomSheet(counsellor: counsellor),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Talk to an Expert',
          style: TextStyle(color: Colors.black87),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _counsellors.isEmpty
          ? const Center(child: Text("No counselors found."))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. SOS / Helpline Section
            _buildHelplineCard(),

            const SizedBox(height: 24),

            // 2. Filter/Header Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Available Counsellors',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: () {
                    // Implement filtering logic
                  },
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 3. Counsellor List (REAL DATA)
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _counsellors.length,
              itemBuilder: (context, index) {
                return CounsellorCard(
                  counsellor: _counsellors[index],
                  onBookTap: () => _showBookingSheet(
                      context, _counsellors[index]),
                );
              },
            ),
          ],
        ),
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
            decoration: const BoxDecoration(
              color: Colors.redAccent,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.sos, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Need immediate help?',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFFD32F2F),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '24/7 Student Suicide Prevention Helpline',
                  style: TextStyle(fontSize: 12, color: Colors.black87),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _makePhoneCall('1800-555-000'),
            style: TextButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
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

  const CounsellorCard({
    super.key,
    required this.counsellor,
    required this.onBookTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.teal.shade100,
                  child: Text(
                    counsellor.name.isNotEmpty ? counsellor.name[0] : "D",
                    style: TextStyle(fontSize: 24, color: Colors.teal.shade800),
                  ),
                ),
                const SizedBox(width: 16),
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        counsellor.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        counsellor.specialization,
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.star, size: 16, color: Colors.amber[700]),
                          const SizedBox(width: 4),
                          Text(
                            counsellor.rating.toString(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.work, size: 16, color: Colors.grey[400]),
                          const SizedBox(width: 4),
                          Text(
                            counsellor.experience,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: counsellor.languages
                          .map(
                            (lang) => Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              lang,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        ),
                      )
                          .toList(),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: onBookTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                  ),
                  child: const Text(
                    'Book Session',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class BookingBottomSheet extends StatefulWidget {
  final Counsellor counsellor;

  const BookingBottomSheet({super.key, required this.counsellor});

  @override
  State<BookingBottomSheet> createState() => _BookingBottomSheetState();
}

class _BookingBottomSheetState extends State<BookingBottomSheet> {
  int selectedDateIndex = 0;
  int selectedSlotIndex = -1;
  bool _isBooking = false;

  final List<String> timeSlots = [
    '10:00 AM',
    '11:00 AM',
    '02:00 PM',
    '04:30 PM',
  ];

  // ✅ REAL BOOKING MUTATION
  Future<void> _confirmBooking() async {
    setState(() => _isBooking = true);

    // Get current user ID logic would go here ideally
    // For now we rely on the backend seeing the 'owner' in the Auth token

    final dateStr = DateTime.now().add(Duration(days: selectedDateIndex)).toString();
    final timeStr = timeSlots[selectedSlotIndex];

    try {
      // Note: Your Appointment schema expects 'date' as AWSDate (YYYY-MM-DD)
      // and 'studentID' and 'counselorID'.
      // We will assume the backend handles studentID via auth or we fetch it.
      // For this simplified version, we just send basic data.

      const graphQLDocument = '''mutation CreateAppt(\$cid: ID!, \$time: String!, \$date: AWSDate!) {
        createAppointment(input: { 
          counselorID: \$cid, 
          timeSlot: \$time,
          date: \$date,
          status: PENDING 
        }) {
          id
        }
      }''';

      // Format Date properly for AWSDate
      final dateObj = DateTime.now().add(Duration(days: selectedDateIndex));
      final awsDate = DateFormat('yyyy-MM-dd').format(dateObj);

      final request = GraphQLRequest<String>(
        authorizationMode: APIAuthorizationType.userPools,
        document: graphQLDocument,
        variables: {
          "cid": widget.counsellor.id,
          "time": timeStr,
          "date": awsDate,
        },
      );

      final response = await Amplify.API.mutate(request: request).response;

      if (!mounted) return;
      setState(() => _isBooking = false);

      if (response.hasErrors) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: ${response.errors.first.message}")));
      } else {
        Navigator.pop(context); // Close sheet
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking Request Sent to AWS! ☁️'),
            backgroundColor: Colors.teal,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      safePrint("Error booking: $e");
      if(mounted) setState(() => _isBooking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Book Appointment',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock, size: 14, color: Colors.green),
                    SizedBox(width: 4),
                    Text(
                      'Confidential',
                      style: TextStyle(fontSize: 12, color: Colors.green),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'with ${widget.counsellor.name}',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          const Text(
            'Select Date',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 70,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 7,
              itemBuilder: (context, index) {
                final date = DateTime.now().add(Duration(days: index));
                final isSelected = selectedDateIndex == index;
                return GestureDetector(
                  onTap: () => setState(() => selectedDateIndex = index),
                  child: Container(
                    width: 60,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.teal : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.teal : Colors.grey.shade300,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('d').format(date),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                        Text(
                          DateFormat('E').format(date),
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Select Time',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: List.generate(timeSlots.length, (index) {
              final isSelected = selectedSlotIndex == index;
              return ChoiceChip(
                label: Text(timeSlots[index]),
                selected: isSelected,
                selectedColor: Colors.teal.shade100,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.teal.shade900 : Colors.black87,
                ),
                onSelected: (selected) =>
                    setState(() => selectedSlotIndex = selected ? index : -1),
              );
            }),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (selectedSlotIndex != -1 && !_isBooking)
                  ? _confirmBooking
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isBooking
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text(
                'Confirm Booking',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}