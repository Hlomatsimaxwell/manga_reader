import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:manga_reader/features/explore/screens/global_search_results_screen.dart';
import 'package:manga_reader/features/source_management/screens/manga_grid_screen.dart';

class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  static const String _historyKey = 'user_search_history';

  String _currentQuery = '';
  List<String> _searchHistory = [];

  // Extended Database of Manga Titles for dynamic hint generation
  final List<String> _mangaTitleDatabase = [
    'Only Hope',
    'Omniscient Reader\'s Viewpoint',
    'One Piece',
    'One Punch Man',
    'Onmyoji',
    'Onani Master Kurosawa',
    'Onward to Victory',
    'The White Mage Who Was Banished from the Party',
    'The Tyrant\'s Only Perfumer',
    'The Villainess Refuses to Flirt with the Male Lead',
    'The Masters Are Subscribing To Me',
    'Solo Leveling',
    'Tower of God',
    'Fire Force',
    'Enen no Shouboutai',
    'Dandadan',
  ];

  final List<String> _genres = [
    'Action',
    'Martial Arts',
    'Fantasy',
    'Drama',
    'Romance',
    'Comedy',
    'Sci-Fi',
  ];

  final List<Map<String, String>> _trendingManga = [
    {
      'id': 'tr_1',
      'title': 'Only Hope',
      'coverUrl': 'https://picsum.photos/seed/oh1/300/450',
    },
    {
      'id': 'tr_2',
      'title': 'Marquis of ...',
      'coverUrl': 'https://picsum.photos/seed/mo2/300/450',
    },
    {
      'id': 'tr_3',
      'title': 'Path of the S...',
      'coverUrl': 'https://picsum.photos/seed/ps3/300/450',
    },
    {
      'id': 'tr_4',
      'title': 'Black Killer ...',
      'coverUrl': 'https://picsum.photos/seed/bk4/300/450',
    },
  ];

  final List<Map<String, dynamic>> _sourceList = [
    {
      'name': 'ComicK',
      'language': 'Manga, Various languages',
      'bgColor': const Color(0xFF2C2C2E),
      'text': '🦄',
      'isEnabled': true,
    },
    {
      'name': 'SummerToon',
      'language': 'Manga, Türkçe',
      'bgColor': const Color(0xFF1B2E1D),
      'text': 'S',
      'textColor': Colors.lightGreen,
      'isEnabled': true,
    },
    {
      'name': 'Beyond The Ataraxia',
      'language': 'Manga, Italiano',
      'bgColor': const Color(0xFF2C2C2E),
      'text': 'BTA',
      'isEnabled': true,
    },
    {
      'name': 'PantheonScan.com',
      'language': 'Manga, Français',
      'bgColor': const Color(0xFF2C2C2E),
      'text': '🏛️',
      'isEnabled': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
  }

  Future<void> _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedHistory = prefs.getString(_historyKey);
    if (savedHistory != null) {
      final List<dynamic> decoded = jsonDecode(savedHistory);
      setState(() {
        _searchHistory = decoded.cast<String>();
      });
    }
  }

  Future<void> _addQueryToHistoryAndSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _searchHistory.remove(trimmed);
      _searchHistory.insert(0, trimmed);
    });
    await prefs.setString(_historyKey, jsonEncode(_searchHistory));

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GlobalSearchResultsScreen(searchQuery: trimmed),
      ),
    );
  }

  Future<void> _clearSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
    setState(() {
      _searchHistory.clear();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          cursorColor: Colors.white,
          textInputAction: TextInputAction.search,
          onChanged: (val) => setState(() => _currentQuery = val),
          onSubmitted: (value) => _addQueryToHistoryAndSearch(value),
          decoration: InputDecoration(
            hintText: 'Enter manga title, genre or source na...',
            hintStyle: const TextStyle(color: Colors.white54, fontSize: 15),
            border: InputBorder.none,
            suffixIcon: _currentQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _currentQuery = '');
                    },
                  )
                : null,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.mic, color: Colors.white),
            onPressed: () {},
          ),
          PopupMenuButton<String>(
            color: const Color(0xFF2C2C2E),
            icon: const Icon(Icons.more_vert, color: Colors.white),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) {
              if (value == 'clear_history') {
                _clearSearchHistory();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'clear_history',
                child: Text(
                  'Clear search history',
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 12),
            _currentQuery.isEmpty
                ? _buildInitialView()
                : _buildTypingSuggestionsView(),
          ],
        ),
      ),
    );
  }

  // Displayed before user starts typing
  Widget _buildInitialView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Horizontal Genre Chips
        SizedBox(
          height: 38,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _genres.length,
            itemBuilder: (context, index) {
              final genre = _genres[index];
              return GestureDetector(
                onTap: () {
                  _searchController.text = genre;
                  _addQueryToHistoryAndSearch(genre);
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white38),
                  ),
                  child: Text(
                    genre,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _trendingManga.length,
            itemBuilder: (context, index) {
              final item = _trendingManga[index];
              return GestureDetector(
                onTap: () {
                  _addQueryToHistoryAndSearch(item['title']!);
                },
                child: Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          item['coverUrl']!,
                          height: 140,
                          width: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item['title']!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        ..._searchHistory.map(
          (query) => ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            leading: const Icon(Icons.history, color: Colors.white70),
            title: Text(
              query,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            trailing: const Icon(Icons.north_west, color: Colors.white54),
            onTap: () {
              _searchController.text = query;
              _addQueryToHistoryAndSearch(query);
            },
          ),
        ),
        const SizedBox(height: 12),
        ..._sourceList
            .take(2)
            .map(
              (source) => ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: source['bgColor'] as Color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      source['text'] as String,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: source['textColor'] as Color? ?? Colors.white,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  source['name'] as String,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  source['language'] as String,
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          MangaGridScreen(sourceName: source['name'] as String),
                    ),
                  );
                },
              ),
            ),
      ],
    );
  }

  // Dynamically filters titles based on what the user types
  Widget _buildTypingSuggestionsView() {
    final queryLower = _currentQuery.toLowerCase();

    // 1. Filtered Search History
    final filteredHistory = _searchHistory
        .where((q) => q.toLowerCase().contains(queryLower))
        .toList();

    // 2. Dynamic Manga Title Hints matching input
    final dynamicTitleHints = _mangaTitleDatabase
        .where((title) => title.toLowerCase().contains(queryLower))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filtered Search History
        ...filteredHistory.map(
          (query) => ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            leading: const Icon(Icons.history, color: Colors.white70),
            title: Text(
              query,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            trailing: const Icon(Icons.north_west, color: Colors.white54),
            onTap: () {
              _searchController.text = query;
              _addQueryToHistoryAndSearch(query);
            },
          ),
        ),

        // Live Dynamic Manga Title Hints
        ...dynamicTitleHints.map(
          (hint) => ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            leading: const Icon(Icons.lightbulb_outline, color: Colors.white70),
            title: Text(
              hint,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () {
              _searchController.text = hint;
              _addQueryToHistoryAndSearch(hint);
            },
          ),
        ),

        const SizedBox(height: 12),

        // Matching Sources List
        ..._sourceList.map(
          (source) => ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 2,
            ),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: source['bgColor'] as Color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  source['text'] as String,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: source['textColor'] as Color? ?? Colors.white,
                  ),
                ),
              ),
            ),
            title: Text(
              source['name'] as String,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              source['language'] as String,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
            trailing: Switch(
              value: source['isEnabled'] as bool,
              activeThumbColor: Colors.white,
              activeTrackColor: Colors.lightGreen,
              onChanged: (val) {
                setState(() {
                  source['isEnabled'] = val;
                });
              },
            ),
          ),
        ),
      ],
    );
  }
}
