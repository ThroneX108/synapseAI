import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http; // ✅ Added for API calls

// --- IMPORTS FOR NAVIGATION ---
import 'article_reading_screen.dart';
import 'video_player_screen.dart';

// --- DATA MODEL ---
class ResourceItem {
  final String id;
  final String title;
  final String type; // 'video' or 'article'
  final String category;
  final String duration;
  final String url;
  final String description;
  final String thumbnailUrl;

  ResourceItem({
    required this.id,
    required this.title,
    required this.type,
    required this.category,
    required this.duration,
    required this.url,
    required this.description,
    this.thumbnailUrl = '',
  });
}

class ResourcesScreen extends StatefulWidget {
  const ResourcesScreen({super.key});

  @override
  State<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen> {
  int _selectedIndex = 0;
  final List<String> _categories = ["All", "Anxiety", "Sleep", "Depression", "Focus"];
  bool _isLoadingRecommendations = true; // Loading state

  // --- MOCK DATA (Ideally this comes from AWS DynamoDB) ---
  final List<ResourceItem> _allVideos = [
    ResourceItem(
      id: 'v1',
      title: "Feeling UGLY? It’s Not You — It’s SOCIAL MEDIA",
      type: "video",
      category: "Depression",
      duration: "5 min",
      url: "https://www.youtube.com/watch?v=NiELZ38O1CM",
      description: "Don't let social media distort your self-image.",
    ),
    ResourceItem(
      id: 'v2',
      title: "Grounding for Panic Attacks",
      type: "video",
      category: "Anxiety",
      duration: "5 min",
      url: "https://www.youtube.com/watch?v=qQML3_k-yDw",
      description: "Physiological techniques to stop panic instantly.",
    ),
    ResourceItem(
      id: 'v3',
      title: "Sleep Music: Delta Waves",
      type: "video",
      category: "Sleep",
      duration: "60 min",
      url: "https://www.youtube.com/watch?v=M2FwUj93oDo",
      description: "Deep sleep music to help you fall asleep fast.",
    ),
  ];

  final List<ResourceItem> _allArticles = [
    ResourceItem(
      id: 'a1',
      title: "Why do I feel lonely?",
      type: "article",
      category: "Depression",
      duration: "4 min read",
      url: "",
      description: "Exploring the psychology behind loneliness.",
    ),
    ResourceItem(
      id: 'a2',
      title: "The Science of Dopamine",
      type: "article",
      category: "Focus",
      duration: "6 min read",
      url: "",
      description: "Manage dopamine for better study sessions.",
    ),
    ResourceItem(
      id: 'a3',
      title: "Cognitive Distortions 101",
      type: "article",
      category: "Anxiety",
      duration: "5 min read",
      url: "",
      description: "Identifying the lies your brain tells you.",
    ),
  ];

  // 3. RECOMMENDED ITEMS (Populated by AI)
  List<ResourceItem> _recommendedItems = [];

  @override
  void initState() {
    super.initState();
    // Fetch AI recommendations on startup
    // In a real app, you would pass the user's latest mood log or journal entry here.
    _fetchAIRecommendations("I have been feeling anxious and unable to sleep lately.");
  }

  // --- 🧠 AI INTEGRATION LOGIC ---
  Future<void> _fetchAIRecommendations(String userQuery) async {
    const String apiUrl =
        "https://recommandation-backend-2.onrender.com/query";

    try {
      final response = await http
          .post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"question": userQuery}),
      )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final answer = data['answer'];
        final List<dynamic> identifiedCauses =
        (answer is Map && answer['cause'] is List)
            ? answer['cause']
            : [];

        final allResources = [..._allVideos, ..._allArticles];
        final List<ResourceItem> matches = [];

        for (var resource in allResources) {
          for (var cause in identifiedCauses) {
            if (resource.category
                .toLowerCase()
                .contains(cause.toString().toLowerCase()) ||
                cause
                    .toString()
                    .toLowerCase()
                    .contains(resource.category.toLowerCase())) {
              if (!matches.contains(resource)) {
                matches.add(resource);
              }
            }
          }
        }

        if (mounted) {
          setState(() {
            _recommendedItems = matches.isNotEmpty
                ? matches
                : [_allVideos[1], _allArticles[2]];
            _isLoadingRecommendations = false;
          });
        }
      } else {
        throw Exception("Server error");
      }
    } catch (e) {
      debugPrint("AI recommendation error: $e");
      if (mounted) {
        setState(() {
          _recommendedItems = [_allVideos[2], _allArticles[0]];
          _isLoadingRecommendations = false;
        });
      }
    }
  }


  // Helper to filter based on category chips
  List<ResourceItem> _getFilteredList(List<ResourceItem> list) {
    if (_selectedIndex == 0) return list;
    return list.where((item) => item.category == _categories[_selectedIndex]).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredVideos = _getFilteredList(_allVideos);
    final filteredArticles = _getFilteredList(_allArticles);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // --- 1. App Bar ---
          SliverAppBar(
            expandedHeight: 100,
            floating: true,
            pinned: true,
            backgroundColor: const Color(0xFFF8FAFC),
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Text(
                "Wellness Library",
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF1E293B),
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ),
          ),

          // --- 2. Search Bar ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: TextField(
                  // Optional: You could allow users to type here to trigger new recommendations!
                  onSubmitted: (value) {
                    setState(() => _isLoadingRecommendations = true);
                    _fetchAIRecommendations(value);
                  },
                  decoration: InputDecoration(
                    hintText: "How are you feeling? (Press Enter)",
                    hintStyle: GoogleFonts.plusJakartaSans(color: Colors.grey[400]),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFFA1C4FD)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ).animate().fadeIn().slideY(begin: 0.2, end: 0),
          ),

          // --- 3. Category Chips ---
          SliverToBoxAdapter(
            child: Container(
              height: 60,
              margin: const EdgeInsets.symmetric(vertical: 16),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final isSelected = _selectedIndex == index;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIndex = index),
                    child: AnimatedContainer(
                      duration: 300.ms,
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFA1C4FD) : Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: isSelected ? Colors.transparent : Colors.grey.withOpacity(0.2),
                        ),
                        boxShadow: isSelected
                            ? [BoxShadow(color: const Color(0xFFA1C4FD).withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))]
                            : [],
                      ),
                      child: Text(
                        _categories[index],
                        style: GoogleFonts.plusJakartaSans(
                          color: isSelected ? Colors.white : Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // --- 4. SECTION: RECOMMENDED FOR YOU (AI Powered) ---
          if (_selectedIndex == 0) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: Colors.orangeAccent, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      "Recommended for You",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                height: 220,
                margin: const EdgeInsets.only(bottom: 24),
                child: _isLoadingRecommendations
                    ? Center(child: CircularProgressIndicator(color: const Color(0xFFA1C4FD)))
                    : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  itemCount: _recommendedItems.length,
                  itemBuilder: (context, index) {
                    return RecommendedResourceCard(item: _recommendedItems[index]);
                  },
                ),
              ),
            ),
          ],

          // --- 5. SECTION: ALL VIDEOS ---
          if (filteredVideos.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Text(
                  "Browse Videos",
                  style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: ResourceListItem(item: filteredVideos[index], index: index),
                    );
                  },
                  childCount: filteredVideos.length,
                ),
              ),
            ),
          ],

          // --- 6. SECTION: ALL ARTICLES ---
          if (filteredArticles.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Text(
                  "Browse Articles",
                  style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: ResourceListItem(item: filteredArticles[index], index: index),
                    );
                  },
                  childCount: filteredArticles.length,
                ),
              ),
            ),
          ],

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}

// --- WIDGETS (Unchanged) ---

class RecommendedResourceCard extends StatelessWidget {
  final ResourceItem item;

  const RecommendedResourceCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final isVideo = item.type == 'video';

    return GestureDetector(
      onTap: () {
        if (isVideo) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => VideoPlayerScreen(videoUrl: item.url, title: item.title, description: item.description)));
        } else {
          Navigator.push(context, MaterialPageRoute(builder: (context) => ArticleDetailScreen(title: item.title, category: item.category, readTime: item.duration)));
        }
      },
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isVideo ? const Color(0xFFFFF1F1) : const Color(0xFFF0F9FF),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    item.category,
                    style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54),
                  ),
                ),
                Icon(
                  isVideo ? FontAwesomeIcons.youtube : FontAwesomeIcons.newspaper,
                  size: 16,
                  color: Colors.black45,
                )
              ],
            ),
            const Spacer(),
            Text(
              item.title,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time_rounded, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  item.duration,
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().scale(duration: 300.ms);
  }
}

class ResourceListItem extends StatelessWidget {
  final ResourceItem item;
  final int index;

  const ResourceListItem({super.key, required this.item, required this.index});

  @override
  Widget build(BuildContext context) {
    final isVideo = item.type == 'video';

    return GestureDetector(
      onTap: () {
        if (isVideo) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => VideoPlayerScreen(videoUrl: item.url, title: item.title, description: item.description)));
        } else {
          Navigator.push(context, MaterialPageRoute(builder: (context) => ArticleDetailScreen(title: item.title, category: item.category, readTime: item.duration)));
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isVideo ? Colors.red.shade50 : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isVideo ? FontAwesomeIcons.play : FontAwesomeIcons.bookOpen,
                color: isVideo ? Colors.redAccent : const Color(0xFFA1C4FD),
                size: 18,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        "${item.category} • ${item.duration}",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[300]),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (50 * index).ms).slideX();
  }
}