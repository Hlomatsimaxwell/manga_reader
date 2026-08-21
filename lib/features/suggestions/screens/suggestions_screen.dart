import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:manga_reader/features/library/screens/manga_detail_screen.dart';

class SuggestionsScreen extends StatefulWidget {
  const SuggestionsScreen({super.key});

  @override
  State<SuggestionsScreen> createState() => _SuggestionsScreenState();
}

class _SuggestionsScreenState extends State<SuggestionsScreen> {
  int _selectedGenreIndex = -1; // -1: none selected
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<String> _genres = [
    'Comedy',
    'Fantasy',
    'Reincarnation',
    'Action',
    'Romance',
    'Drama',
    'Isekai',
  ];

  final List<Map<String, dynamic>> _suggestions = [
    {
      'mangaId': 'sugg_1',
      'title': 'The Ultimate of All Ages',
      'coverUrl': 'https://picsum.photos/seed/sugg1/300/450',
      'genre': 'Action',
    },
    {
      'mangaId': 'sugg_2',
      'title': 'Why She Lives as a Villainess',
      'coverUrl': 'https://picsum.photos/seed/sugg2/300/450',
      'genre': 'Reincarnation',
    },
    {
      'mangaId': 'sugg_3',
      'title': 'Marquis of Marron',
      'coverUrl': 'https://picsum.photos/seed/sugg3/300/450',
      'genre': 'Fantasy',
    },
    {
      'mangaId': 'sugg_4',
      'title': 'The Reason Why That Villainess ...',
      'coverUrl': 'https://picsum.photos/seed/sugg4/300/450',
      'genre': 'Reincarnation',
    },
    {
      'mangaId': 'sugg_5',
      'title': 'The Villainess Refuses to Flirt ...',
      'coverUrl': 'https://picsum.photos/seed/sugg5/300/450',
      'genre': 'Comedy',
    },
    {
      'mangaId': 'sugg_6',
      'title': 'The Strongest Level 0 Absolut...',
      'coverUrl': 'https://picsum.photos/seed/sugg6/300/450',
      'genre': 'Action',
    },
    {
      'mangaId': 'sugg_7',
      'title': 'Path of the Shaman',
      'coverUrl': 'https://picsum.photos/seed/sugg7/300/450',
      'genre': 'Fantasy',
    },
    {
      'mangaId': 'sugg_8',
      'title': 'The Dark Magician Trans...',
      'coverUrl': 'https://picsum.photos/seed/sugg8/300/450',
      'genre': 'Fantasy',
    },
    {
      'mangaId': 'sugg_9',
      'title': 'Black Killer Whale Baby',
      'coverUrl': 'https://picsum.photos/seed/sugg9/300/450',
      'genre': 'Comedy',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Filter items by search query and active genre tag
    final displayedItems = _suggestions.where((item) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          item['title'].toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );

      final matchesGenre =
          _selectedGenreIndex == -1 ||
          item['genre'] == _genres[_selectedGenreIndex];

      return matchesSearch && matchesGenre;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              _buildSearchBar(),
              const SizedBox(height: 12),
              _buildGenreChips(),
              const SizedBox(height: 16),
              _buildMangaGrid(displayedItems),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(28),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        cursorColor: Colors.white,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          icon: const Icon(Icons.search, color: Colors.white70, size: 22),
          hintText: 'Search manga',
          hintStyle: const TextStyle(color: Colors.white54, fontSize: 16),
          border: InputBorder.none,
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.clear,
                    color: Colors.white70,
                    size: 20,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : const Icon(Icons.more_vert, color: Colors.white70, size: 22),
        ),
      ),
    );
  }

  Widget _buildGenreChips() {
    final filters = [
      'Comedy',
      'Fantasy',
      'Reincarnation',
      'Action',
      'Romance',
      'Drama',
      'Isekai',
      'Slice of Life',
      'Sci-Fi',
      'Supernatural',
    ];

    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics:
            const BouncingScrollPhysics(), // Enables smooth horizontal flicking
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedGenreIndex == index;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedGenreIndex = isSelected ? -1 : index;
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
                    Icon(
                      Icons.sell_outlined,
                      size: 16,
                      color: isSelected ? Colors.black : Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      filters[index],
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
            'No suggestions found',
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
          childAspectRatio: 0.50, // Headroom for 2:3 cover + 2-line title
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
          // Strict 2:3 Aspect Ratio Cover Container
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
