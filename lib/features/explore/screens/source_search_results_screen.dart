import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:yomou/core/database/source_cache.dart';
import 'package:yomou/data/models/manga.dart';
import 'package:yomou/data/models/manga_source.dart';
import 'package:yomou/features/library/screens/manga_detail_screen.dart';
import 'package:yomou/core/widgets/empty_state.dart';
import 'package:yomou/features/library/widgets/downloaded_badge.dart';
import 'package:yomou/core/widgets/ios/ios_menu.dart';

class SourceSearchResultsScreen extends StatefulWidget {
  final MangaSource source;
  final String query;
  final String? genre;

  const SourceSearchResultsScreen({
    super.key,
    required this.source,
    required this.query,
    this.genre,
  });

  @override
  State<SourceSearchResultsScreen> createState() =>
      _SourceSearchResultsScreenState();
}

class _SourceSearchResultsScreenState extends State<SourceSearchResultsScreen> {
  static const int _pageSize = 20;

  late final MangaSource _source = widget.source;
  String _filterQuery = '';
  List<String> _genres = [];
  String? _selectedGenre;
  bool _genrePrefixSelected = false;

  final List<Manga> _mangaList = [];
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearching = false;
  int _page = 1;
  bool _hasMore = false;
  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _filterQuery = widget.query;
    _selectedGenre = widget.genre;
    _scrollController.addListener(_onScroll);
    _loadGenres();
    _runSearch();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadGenres() async {
    final tags = await SourceCache.tags(
      sourceId: _source.id,
      fetch: _source.getAvailableTags,
    );
    if (mounted) {
      setState(() => _genres = tags);
    }
  }

  Future<List<Manga>> _fetchPage(int page, {bool forceRefresh = false}) async {
    if (_selectedGenre != null) {
      return SourceCache.mangaList(
        sourceId: _source.id,
        kind: 'tags',
        arg: _selectedGenre!.toLowerCase(),
        page: page,
        forceRefresh: forceRefresh,
        fetch: () => _source.searchMangaByTags([_selectedGenre!], page: page),
      );
    }
    if (_filterQuery.isNotEmpty) {
      return SourceCache.mangaList(
        sourceId: _source.id,
        kind: 'title',
        arg: _filterQuery.toLowerCase(),
        page: page,
        forceRefresh: forceRefresh,
        fetch: () => _source.searchByTitle(_filterQuery, page: page),
      );
    }
    return SourceCache.mangaList(
      sourceId: _source.id,
      kind: 'popular',
      page: page,
      forceRefresh: forceRefresh,
      fetch: () => _source.getPopularManga(page: page),
    );
  }

  Future<void> _refresh() async {
    final kind = _selectedGenre != null
        ? 'tags'
        : (_filterQuery.isNotEmpty ? 'title' : 'popular');
    SourceCache.invalidatePrefix('${_source.id}/list/$kind/');
    await _loadGenres();
    await _runSearch(forceRefresh: true);
  }

  Future<void> _runSearch({bool forceRefresh = false}) async {
    setState(() {
      _page = 1;
      _mangaList.clear();
      _hasMore = false;
      _isInitialLoading = true;
      _isLoadingMore = false;
      _error = null;
    });

    try {
      final results = await _fetchPage(_page, forceRefresh: forceRefresh);
      if (!mounted) return;
      setState(() {
        _mangaList.addAll(results);
        _hasMore = results.length >= _pageSize;
        _isInitialLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isInitialLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || _isInitialLoading || !_hasMore) return;

    setState(() => _isLoadingMore = true);
    try {
      final nextPage = _page + 1;
      final results = await _fetchPage(nextPage);
      if (!mounted) return;

      final existingIds = _mangaList.map((m) => m.id).toSet();
      final fresh = results.where((m) => !existingIds.contains(m.id)).toList();

      setState(() {
        _page = nextPage;
        if (fresh.isEmpty) {
          // Nothing new: the source has no further pages (e.g. Manganato's
          // single-page search). Stop paginating to avoid infinite duplicates.
          _hasMore = false;
        } else {
          _mangaList.addAll(fresh);
          _hasMore = results.length >= _pageSize;
        }
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 400) {
      _loadMore();
    }
  }

  void _clearSearchQuery() {
    setState(() => _filterQuery = '');
    _runSearch();
  }

  void _selectGenre(String? genre) {
    setState(() => _selectedGenre = genre);
    _runSearch();
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

  void _openRandomManga() {
    if (_mangaList.isEmpty) return;
    final random = Random();
    final randomManga = _mangaList[random.nextInt(_mangaList.length)];
    _openManga(randomManga);
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      _searchController.text = _filterQuery;
      if (!_isSearching) {
        _searchController.clear();
      }
    });
    if (_isSearching) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FocusScope.of(context).requestFocus(_searchFocusNode);
      });
    }
  }

  void _submitSearchFromAppBar(String value) {
    final query = value.trim();
    setState(() {
      _isSearching = false;
      _searchController.clear();
      if (query.isNotEmpty) _filterQuery = query;
    });
    _runSearch();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: dark ? Colors.white : const Color(0xFF1C1B1F),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                autofocus: true,
                style: TextStyle(
                  color: dark ? Colors.white : const Color(0xFF1C1B1F),
                  fontSize: 17,
                ),
                cursorColor: dark ? Colors.white : const Color(0xFF1C1B1F),
                textInputAction: TextInputAction.search,
                onSubmitted: _submitSearchFromAppBar,
                decoration: InputDecoration(
                  hintText: 'Search this source...',
                  hintStyle: TextStyle(
                    color: dark ? Colors.white54 : Colors.black54,
                    fontSize: 16,
                  ),
                  border: InputBorder.none,
                ),
              )
            : Text(
                widget.source.name,
                style: TextStyle(
                  color: dark ? Colors.white : const Color(0xFF1C1B1F),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
        actions: [
          if (_isSearching)
            IconButton(
              icon: Icon(
                Icons.close,
                color: dark ? Colors.white : const Color(0xFF1C1B1F),
              ),
              onPressed: _toggleSearch,
            )
          else ...[
            IconButton(
              icon: Icon(
                Icons.search,
                color: dark ? Colors.white : const Color(0xFF1C1B1F),
              ),
              onPressed: _toggleSearch,
            ),
            IconButton(
              tooltip: 'Random manga',
              icon: Icon(
                Icons.casino_outlined,
                color: dark ? Colors.white : const Color(0xFF1C1B1F),
              ),
              onPressed: _openRandomManga,
            ),
            IosMenuButton<String>(
              items: const [
                IosMenuItem(
                  value: 'refresh',
                  label: 'Refresh results',
                  icon: Icons.refresh_rounded,
                ),
                IosMenuItem(
                  value: 'clear_query',
                  label: 'Clear search query',
                  icon: Icons.close_rounded,
                ),
              ],
              onSelected: (value) {
                switch (value) {
                  case 'refresh':
                    _refresh();
                  case 'clear_query':
                    _clearSearchQuery();
                }
              },
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          const SizedBox(height: 8),
          Expanded(child: _buildResults()),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final chips = <Widget>[];

    // Active search query chip (tap X to clear).
    if (_filterQuery.isNotEmpty) {
      final query = _filterQuery;
      chips.add(
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: _clearSearchQuery,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 240),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: dark ? const Color(0xFF2C2C2E) : const Color(0xFFEBEFEF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: dark ? Colors.white38 : Colors.black12,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.search,
                    size: 16,
                    color: dark
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      query,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: dark
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.close,
                    size: 16,
                    color: dark ? Colors.white70 : const Color(0xFF49454F),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // 'Genres' prefix chip.
    chips.add(
      Padding(
        padding: const EdgeInsets.only(right: 8),
        child: GestureDetector(
          onTap: () {
            setState(() => _genrePrefixSelected = !_genrePrefixSelected);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _genrePrefixSelected
                  ? (dark
                      ? Colors.white
                      : Theme.of(context).colorScheme.primary)
                  : (dark ? Colors.transparent : const Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(12),
              border: dark
                  ? Border.all(
                      color: _genrePrefixSelected
                          ? Colors.white
                          : Colors.white38,
                    )
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.segment,
                  size: 16,
                  color: _genrePrefixSelected
                      ? (dark ? Colors.black : Colors.white)
                      : (dark ? Colors.white : const Color(0xFF334155)),
                ),
                const SizedBox(width: 6),
                Text(
                  'Genres',
                  style: TextStyle(
                    color: _genrePrefixSelected
                        ? (dark ? Colors.black : Colors.white)
                        : (dark ? Colors.white : const Color(0xFF334155)),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Genre tag chips.
    for (final genre in _genres) {
      final isSelected = _selectedGenre == genre;
      chips.add(
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => _selectGenre(isSelected ? null : genre),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? (dark
                        ? Colors.white
                        : Theme.of(context).colorScheme.primary)
                    : (dark ? Colors.transparent : const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(12),
                border: dark
                    ? Border.all(
                        color: isSelected ? Colors.white : Colors.white38,
                      )
                    : null,
              ),
              child: Text(
                genre,
                style: TextStyle(
                  color: isSelected
                      ? (dark ? Colors.black : Colors.white)
                      : (dark ? Colors.white : const Color(0xFF334155)),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: chips,
      ),
    );
  }

  Widget _buildResults() {
    final dark = Theme.of(context).brightness == Brightness.dark;
    if (_isInitialLoading && _mangaList.isEmpty) {
      return Center(
        child: CircularProgressIndicator(
          color: dark ? Colors.white70 : const Color(0xFF49454F),
        ),
      );
    }

    if (_error != null && _mangaList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Failed to load results',
              style: TextStyle(
                color: dark ? Colors.white70 : const Color(0xFF49454F),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: dark ? Colors.white38 : Colors.black38,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _runSearch,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: OutlinedButton.styleFrom(
                foregroundColor: dark
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface,
                side: dark
                    ? const BorderSide(color: Colors.white38)
                    : const BorderSide(color: Colors.black38),
              ),
            ),
          ],
        ),
      );
    }

    if (_mangaList.isEmpty) {
      return const EmptyState(
        icon: Icons.search_off,
        title: 'No manga found',
        subtitle: 'Try a different search query.',
      );
    }

    return RefreshIndicator(
      color: dark ? Colors.white : Theme.of(context).colorScheme.onSurface,
      backgroundColor: dark ? const Color(0xFF2C2C2E) : Colors.white,
      onRefresh: _refresh,
      child: Column(
        children: [
          Expanded(
            child: GridView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.50,
                crossAxisSpacing: 10,
                mainAxisSpacing: 12,
              ),
              itemCount: _mangaList.length,
              itemBuilder: (context, index) {
                final manga = _mangaList[index];
                return _buildCard(context, manga);
              },
            ),
          ),
          if (_isLoadingMore)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: dark ? Colors.white54 : Colors.black54,
                  strokeWidth: 2,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, Manga item) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => _openManga(item),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: 2 / 3,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: dark ? null : Border.all(color: Colors.black12),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: item.coverUrl,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Container(
                        color: dark ? const Color(0xFF2C2C2E) : Colors.black12,
                        child: Icon(
                          Icons.menu_book,
                          color: dark ? Colors.white38 : Colors.black38,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ),
                DownloadedMangaBadge(mangaId: item.id),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: dark
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurface,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
