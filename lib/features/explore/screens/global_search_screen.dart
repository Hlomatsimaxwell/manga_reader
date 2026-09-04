import 'dart:async';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:manga_reader/data/models/manga.dart';
import 'package:manga_reader/features/explore/providers/search_provider.dart';
import 'package:manga_reader/features/explore/screens/global_search_results_screen.dart';
import 'package:manga_reader/features/library/screens/manga_detail_screen.dart';
import 'package:manga_reader/features/suggestions/providers/suggestions_provider.dart';

class GlobalSearchScreen extends ConsumerStatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  ConsumerState<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends ConsumerState<GlobalSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  static const String _historyKey = 'user_search_history';

  String _currentQuery = '';
  String _debouncedQuery = '';
  Timer? _debounce;
  List<String> _searchHistory = [];

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedHistory = prefs.getString(_historyKey);
    if (savedHistory != null) {
      final List<dynamic> decoded = jsonDecode(savedHistory);
      if (mounted) {
        setState(() {
          _searchHistory = decoded.cast<String>();
        });
      }
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

  void _onQueryChanged(String value) {
    setState(() => _currentQuery = value);
    _debounce?.cancel();
    final query = value.trim();
    if (query.isEmpty) {
      setState(() => _debouncedQuery = '');
      return;
    }
    // Debounce live search as the user types.
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() => _debouncedQuery = query);
    });
  }

  void _openManga(Manga manga) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MangaDetailScreen(
          mangaId: manga.id,
          title: manga.title,
          imageUrl: manga.coverUrl,
        ),
      ),
    );
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
          onChanged: _onQueryChanged,
          onSubmitted: (value) => _addQueryToHistoryAndSearch(value),
          decoration: InputDecoration(
            hintText: 'Enter manga title or genre',
            hintStyle: const TextStyle(color: Colors.white54, fontSize: 15),
            border: InputBorder.none,
            suffixIcon: _currentQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () {
                      _searchController.clear();
                      _onQueryChanged('');
                    },
                  )
                : null,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () => _addQueryToHistoryAndSearch(_searchController.text),
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

  // Displayed before the user starts typing.
  Widget _buildInitialView() {
    final genreTagsAsync = ref.watch(genreTagsProvider);
    final trendingAsync = ref.watch(trendingMangaProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Genre chips (real tags from the source).
        genreTagsAsync.when(
          data: (tags) => SizedBox(
            height: 38,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: tags.length,
              itemBuilder: (context, index) {
                final genre = tags[index];
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
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 16),
        // Trending (real popular manga).
        trendingAsync.when(
          data: (trending) => trending.isEmpty
              ? const SizedBox.shrink()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionLabel('Trending'),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 180,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: trending.length,
                        itemBuilder: (context, index) {
                          final manga = trending[index];
                          return _buildTrendingCard(manga);
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        // Search history.
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
      ],
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTrendingCard(Manga manga) {
    return GestureDetector(
      onTap: () => _openManga(manga),
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: manga.coverUrl,
                height: 140,
                width: 100,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => Container(
                  color: const Color(0xFF2C2C2E),
                  height: 140,
                  width: 100,
                  child: const Icon(Icons.menu_book, color: Colors.white38),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              manga.title,
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
  }

  // Live search results while the user is typing.
  Widget _buildTypingSuggestionsView() {
    final queryLower = _currentQuery.toLowerCase();
    final filteredHistory = _searchHistory
        .where((q) => q.toLowerCase().contains(queryLower))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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

        if (_debouncedQuery.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white54,
                    strokeWidth: 2,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Searching "$_currentQuery"...',
                  style: const TextStyle(color: Colors.white54, fontSize: 14),
                ),
              ],
            ),
          )
        else
          _buildLiveResults(_debouncedQuery),
      ],
    );
  }

  Widget _buildLiveResults(String query) {
    final resultsAsync = ref.watch(searchResultsProvider(query));

    return resultsAsync.when(
      data: (results) {
        if (results.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'No results found',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
          );
        }
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.50,
            crossAxisSpacing: 10,
            mainAxisSpacing: 12,
          ),
          itemCount: results.length,
          itemBuilder: (context, index) {
            final manga = results[index];
            return GestureDetector(
              onTap: () {
                _addQueryToHistoryAndSearch(query);
                _openManga(manga);
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AspectRatio(
                    aspectRatio: 2 / 3,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: CachedNetworkImage(
                        imageUrl: manga.coverUrl,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => Container(
                          color: const Color(0xFF2C2C2E),
                          child: const Icon(
                            Icons.menu_book,
                            color: Colors.white38,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    manga.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: CircularProgressIndicator(color: Colors.white54),
        ),
      ),
      error: (e, _) => const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Failed to search',
          style: TextStyle(color: Colors.white54, fontSize: 14),
        ),
      ),
    );
  }
}