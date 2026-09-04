import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manga_reader/data/models/manga.dart';
import 'package:manga_reader/features/explore/providers/search_provider.dart';
import 'package:manga_reader/features/explore/screens/source_search_results_screen.dart';
import 'package:manga_reader/features/library/screens/manga_detail_screen.dart';

class GlobalSearchResultsScreen extends ConsumerStatefulWidget {
  final String searchQuery;

  const GlobalSearchResultsScreen({
    super.key,
    required this.searchQuery,
  });

  @override
  ConsumerState<GlobalSearchResultsScreen> createState() =>
      _GlobalSearchResultsScreenState();
}

class _GlobalSearchResultsScreenState
    extends ConsumerState<GlobalSearchResultsScreen> {
  late TextEditingController _searchController;
  late String _activeQuery;
  bool _showFailedSources = false;

  @override
  void initState() {
    super.initState();
    _activeQuery = widget.searchQuery;
    _searchController = TextEditingController(text: _activeQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _submitSearch() {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    setState(() => _activeQuery = query);
  }

  void _openManga(Manga manga) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MangaDetailScreen(
          mangaId: manga.id,
          title: manga.title,
          imageUrl: manga.coverUrl,
          sourceId: manga.sourceId,
        ),
      ),
    );
  }

  void _openShowAll(SourceSearchResult result) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SourceSearchResultsScreen(
          sourceName: result.sourceName,
          query: _activeQuery,
          manga: result.manga,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final resultsAsync = ref.watch(globalSearchProvider(_activeQuery));

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
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          cursorColor: Colors.white,
          textInputAction: TextInputAction.search,
          onSubmitted: (value) => _submitSearch(),
          decoration: InputDecoration(
            hintText: 'Search...',
            hintStyle: const TextStyle(color: Colors.white54, fontSize: 16),
            border: InputBorder.none,
            suffixIcon: IconButton(
              icon: const Icon(Icons.close, color: Colors.white70),
              onPressed: () {
                _searchController.clear();
                _submitSearch();
              },
            ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: _showFailedSources
                ? 'Hide failed sources'
                : 'Show failed sources',
            icon: Icon(
              _showFailedSources ? Icons.public : Icons.public_off,
              color: _showFailedSources ? Colors.orange : Colors.white,
            ),
            onPressed: () {
              setState(() => _showFailedSources = !_showFailedSources);
            },
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: _submitSearch,
          ),
        ],
      ),
      body: resultsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Colors.white70),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Failed to search',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  e.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        data: (results) => _buildResults(results),
      ),
    );
  }

  Widget _buildResults(List<SourceSearchResult> results) {
    // Default: hide empty and failed sources.
    final visible = _showFailedSources
        ? results
        : results.where((r) => r.hasResults && !r.hasError).toList();

    if (visible.isEmpty) {
      return const Center(
        child: Text(
          'No results found',
          style: TextStyle(color: Colors.white54, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 16, bottom: 40),
      itemCount: visible.length,
      itemBuilder: (context, index) =>
          _buildSourceSection(visible[index]),
    );
  }

  Widget _buildSourceSection(SourceSearchResult result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                result.sourceName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (result.hasResults)
                TextButton(
                  onPressed: () => _openShowAll(result),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Show all (${result.manga.length})',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right,
                          color: Colors.white70, size: 18),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (result.hasResults)
          _buildResultRow(result.manga)
        else
          _buildFailedRow(result),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildResultRow(List<Manga> manga) {
    return SizedBox(
      height: 190,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: manga.length,
        itemBuilder: (context, index) {
          final item = manga[index];
          return GestureDetector(
            onTap: () => _openManga(item),
            child: Container(
              width: 100,
              margin: const EdgeInsets.only(right: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: item.coverUrl,
                      height: 140,
                      width: 100,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Container(
                        color: const Color(0xFF2C2C2E),
                        height: 140,
                        width: 100,
                        child: const Icon(
                          Icons.menu_book,
                          color: Colors.white38,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFailedRow(SourceSearchResult result) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              result.hasError ? Icons.error_outline : Icons.search_off,
              color: Colors.white38,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                result.hasError
                    ? (result.errorMessage ?? 'Source failed')
                    : 'Content not found or removed',
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}