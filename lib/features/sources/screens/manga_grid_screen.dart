import 'dart:math'; // 1. Add this import at the top of manga_grid_screen.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:manga_reader/features/library/screens/manga_detail_screen.dart';

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

  final List<String> _filters = [
    'Genres',
    'Web Comic',
    'Reincarnation',
    'Martial Arts',
    'Action',
    'Romance',
  ];

  final List<Map<String, dynamic>> _mangaList = [
    {
      'mangaId': 'mg_1',
      'title': 'Worst Generation',
      'coverUrl': 'https://picsum.photos/seed/mg1/300/450',
    },
    {
      'mangaId': 'mg_2',
      'title': 'High School Baseball Tycoon',
      'coverUrl': 'https://picsum.photos/seed/mg2/300/450',
    },
    {
      'mangaId': 'mg_3',
      'title': 'May Sleep Befall Death',
      'coverUrl': 'https://picsum.photos/seed/mg3/300/450',
    },
    {
      'mangaId': 'mg_4',
      'title': 'Marika-chan no Koukando wa B...',
      'coverUrl': 'https://picsum.photos/seed/mg4/300/450',
    },
    {
      'mangaId': 'mg_5',
      'title': 'My Fiance Is a Former Assassi...',
      'coverUrl': 'https://picsum.photos/seed/mg5/300/450',
    },
    {
      'mangaId': 'mg_6',
      'title': "There's No Way This Is Love",
      'coverUrl': 'https://picsum.photos/seed/mg6/300/450',
    },
    {
      'mangaId': 'mg_7',
      'title': 'The Tyrant Brother is a Bon...',
      'coverUrl': 'https://picsum.photos/seed/mg7/300/450',
    },
    {
      'mangaId': 'mg_8',
      'title': "I Said I'd Do Science Pop...",
      'coverUrl': 'https://picsum.photos/seed/mg8/300/450',
    },
    {
      'mangaId': 'mg_9',
      'title': 'Rise Shoulder',
      'coverUrl': 'https://picsum.photos/seed/mg9/300/450',
    },
  ];

  // Helper method to pick and open a random manga
  void _openRandomManga() {
    if (_mangaList.isEmpty) return;

    final random = Random();
    final randomIndex = random.nextInt(_mangaList.length);
    final randomManga = _mangaList[randomIndex];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MangaDetailScreen(
          mangaId: randomManga['mangaId'],
          title: randomManga['title'],
          imageUrl: randomManga['coverUrl'],
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
      return item['title'].toString().toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                      Icon(Icons.filter_list, color: Colors.white70, size: 18),
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
            _buildMangaGrid(displayedManga),
          ],
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

  Widget _buildMangaGrid(List<Map<String, dynamic>> items) {
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

  Widget _buildMangaCard(BuildContext context, Map<String, dynamic> item) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MangaDetailScreen(
              mangaId: item['mangaId'],
              title: item['title'],
              imageUrl: item['coverUrl'],
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CachedNetworkImage(
                imageUrl: item['coverUrl'],
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
            item['title'],
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
