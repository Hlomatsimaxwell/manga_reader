import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:manga_reader/core/database/source_cache.dart';
import 'package:manga_reader/features/library/screens/manga_detail_screen.dart';
import 'package:manga_reader/features/library/widgets/downloaded_badge.dart';
import 'package:manga_reader/data/models/manga.dart';
import 'package:manga_reader/data/providers/sources_provider.dart';

class MangaGridScreen extends StatefulWidget {
  final String sourceName;

  const MangaGridScreen({super.key, required this.sourceName});

  @override
  State<MangaGridScreen> createState() => _MangaGridScreenState();
}

class _MangaGridScreenState extends State<MangaGridScreen> {
  int _selectedFilterIndex = -1;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';

  List<Manga> _mangaList = [];
  bool _isLoading = true;
  String? _error;

  final List<String> _filters = [
    'Genres',
    'Web Comic',
    'Reincarnation',
    'Martial Arts',
    'Action',
    'Romance',
  ];

  @override
  void initState() {
    super.initState();
    _loadManga();
  }

  Future<void> _loadManga({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final source = getSourceByName(widget.sourceName);
      final manga = await SourceCache.mangaList(
        sourceId: source.id,
        kind: 'popular',
        page: 1,
        forceRefresh: forceRefresh,
        fetch: source.getPopularManga,
      );
      setState(() {
        _mangaList = manga;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _refresh() async {
    final source = getSourceByName(widget.sourceName);
    SourceCache.invalidatePrefix('${source.id}/list/popular/');
    await _loadManga(forceRefresh: true);
  }

  void _openRandomManga() {
    if (_mangaList.isEmpty) return;

    final random = Random();
    final randomManga = _mangaList[random.nextInt(_mangaList.length)];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MangaDetailScreen(
          mangaId: randomManga.id,
          title: randomManga.title,
          imageUrl: randomManga.coverUrl,
          sourceId: randomManga.sourceId,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayedManga = _mangaList.where((item) {
      if (_searchQuery.isEmpty) return true;
      return item.title.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 18),
                cursorColor: Colors.white,
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: const InputDecoration(
                  hintText: 'Search catalog...',
                  hintStyle: TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                ),
              )
            : null,
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _searchController.clear();
                  _searchQuery = '';
                }
                _isSearching = !_isSearching;
              });
            },
          ),
          // Updated dice button tap handler
          IconButton(
            icon: const Icon(Icons.casino_outlined, color: Colors.white),
            onPressed: _openRandomManga,
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        color: Colors.white,
        backgroundColor: const Color(0xFF2C2C2E),
        onRefresh: _refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.sourceName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: const [
                        Icon(
                          Icons.filter_list,
                          color: Colors.white70,
                          size: 18,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Updated',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _buildFilterChips(),
              const SizedBox(height: 16),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.white70),
                  ),
                )
              else if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 60),
                  child: Center(
                    child: Column(
                      children: [
                        const Text(
                          'Failed to load manga',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: _loadManga,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white38),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                _buildMangaGrid(displayedManga),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedFilterIndex == index;
          final isGenresButton = index == 0;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedFilterIndex = isSelected ? -1 : index;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.white38,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isGenresButton) ...[
                      Icon(
                        Icons.segment,
                        size: 16,
                        color: isSelected ? Colors.black : Colors.white,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      _filters[index],
                      style: TextStyle(
                        color: isSelected ? Colors.black : Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMangaGrid(List<Manga> items) {
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(
          child: Text(
            'No manga found',
            style: TextStyle(color: Colors.white54, fontSize: 16),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.50,
          crossAxisSpacing: 10,
          mainAxisSpacing: 12,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return _buildMangaCard(context, item);
        },
      ),
    );
  }

  Widget _buildMangaCard(BuildContext context, Manga item) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MangaDetailScreen(
              mangaId: item.id,
              title: item.title,
              imageUrl: item.coverUrl,
              sourceId: item.sourceId,
            ),
          ),
        );
      },
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
                  child: CachedNetworkImage(
                    imageUrl: item.coverUrl,
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
                DownloadedMangaBadge(mangaId: item.id),
              ],
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
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
