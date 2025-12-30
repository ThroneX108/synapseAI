
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tts/flutter_tts.dart';

class ArticleDetailScreen extends StatefulWidget {
  final String title;
  final String category;
  final String readTime;
  final String imageUrl;

  const ArticleDetailScreen({
    super.key,
    required this.title,
    required this.category,
    required this.readTime,
    this.imageUrl = 'https://img.freepik.com/free-vector/organic-flat-people-meditating-illustration_23-2148906556.jpg',
  });

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  bool isBookmarked = false;
  bool isPlaying = false;
  final FlutterTts flutterTts = FlutterTts();

  // TRACKING POSITION: Store the index of the last spoken word
  int _lastCharacterIndex = 0;

  final String _articleContent = """
Anxiety often feels like a storm in your mind—loud, chaotic, and overwhelming. But just like a storm, it passes. The key is finding an anchor while you wait for the skies to clear.

Here are three science-backed grounding techniques you can use right now:

1. The 5-4-3-2-1 Technique. Look around you and identify: 5 things you can see. 4 things you can touch. 3 things you can hear. 2 things you can smell. 1 thing you can taste.

2. Box Breathing. Control your breath, control your nervous system. Inhale for 4 seconds. Hold for 4 seconds. Exhale for 4 seconds. Hold for 4 seconds. Repeat this cycle 4 times.

3. Cold Water Shock. Splash ice-cold water on your face. The intense sensation activates the Mammalian Dive Reflex, which instantly lowers your heart rate.
""";

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  void _initTts() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.4);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(0.6);


    if (Platform.isAndroid) {
      await flutterTts.setQueueMode(1);
    }

    // 1. PROGRESS HANDLER: This keeps track of where we are in the text
    flutterTts.setProgressHandler((String text, int start, int end, String word) {
      setState(() {
        _lastCharacterIndex = start;
      });
    });

    flutterTts.setStartHandler(() {
      setState(() => isPlaying = true);
    });

    // 2. COMPLETION HANDLER: Reset the index when article finishes
    flutterTts.setCompletionHandler(() {
      setState(() {
        isPlaying = false;
        _lastCharacterIndex = 0;
      });
    });

    flutterTts.setErrorHandler((msg) {
      setState(() => isPlaying = false);
      debugPrint("TTS Error: $msg");
    });
  }

  // 3. RESUME LOGIC: Speak from a substring if index > 0
  Future<void> _speak() async {
    String textToSpeak = _articleContent;

    // If we have a saved position, start from there
    if (_lastCharacterIndex > 0 && _lastCharacterIndex < _articleContent.length) {
      textToSpeak = _articleContent.substring(_lastCharacterIndex);
    }

    var result = await flutterTts.speak(textToSpeak);
    if (result == 1) setState(() => isPlaying = true);
  }

  // 4. PAUSE LOGIC: Stop the hardware, but the index is saved in _lastCharacterIndex
  Future<void> _pause() async {
    var result = await flutterTts.stop();
    if (result == 1) setState(() => isPlaying = false);
  }

  void _togglePlay() {
    if (isPlaying) {
      _pause();
    } else {
      _speak();
    }
  }

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), shape: BoxShape.circle),
                child: const Icon(Icons.arrow_back, color: Colors.black87, size: 20),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), shape: BoxShape.circle),
                  child: Icon(
                    isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color: isBookmarked ? Colors.teal : Colors.black87,
                    size: 20,
                  ),
                ),
                onPressed: () => setState(() => isBookmarked = !isBookmarked),
              ),
              const SizedBox(width: 16),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(widget.imageUrl, fit: BoxFit.cover),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              transform: Matrix4.translationValues(0, -20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFA1C4FD).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(widget.category.toUpperCase(),
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.access_time, size: 14, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text(widget.readTime, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey[500])),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(widget.title,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B), height: 1.2)),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const CircleAvatar(
                          radius: 16, backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=32')),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Dr. Sarah Jensen",
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B))),
                          Text("Clinical Psychologist",
                              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey[500])),
                        ],
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _togglePlay,
                        child: AnimatedContainer(
                          duration: 300.ms,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isPlaying ? const Color(0xFFA1C4FD) : const Color(0xFFF1F5F9),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isPlaying ? Icons.pause : Icons.play_arrow,
                            color: isPlaying ? Colors.white : const Color(0xFF1E293B),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(height: 1),
                  const SizedBox(height: 24),
                  Text(
                    _articleContent,
                    style: GoogleFonts.plusJakartaSans(fontSize: 16, height: 1.8, color: const Color(0xFF334155)),
                  ).animate().fadeIn(delay: 300.ms),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

