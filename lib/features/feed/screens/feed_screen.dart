import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:manga_reader/features/explore/screens/global_search_screen.dart';
import 'package:manga_reader/features/library/screens/manga_detail_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  // Mock Data for Updates Carousel
  final List<Map<String, dynamic>> _updatesList = [
    {
      'id': 'up_1',
      'title': 'Initializing the Sect System',
      'coverUrl': 'https://picsum.photos/seed/sect1/300/450',
      'unreadBadge': 1,
      'progressPercentage': null,
      'isFavorite': true,
    },
    {
      'id': 'up_2',
      'title': 'Return of the Mount Hua S...',
      'coverUrl': 'https://picsum.photos/seed/mthua/300/450',
      'unreadBadge': 4,
      'progressPercentage': '0%',
      'isFavorite': true,
    },
    {
      'id': 'up_3',
      'title': 'Return Of The Flowery ...',
      'coverUrl': 'https://picsum.photos/seed/flowery/300/450',
      'unreadBadge': 2,
      'progressPercentage': null,
      'isFavorite': true,
    },
    {
      'id': 'up_4',
      'title': 'The Supreme Demon',
      'coverUrl': 'https://picsum.photos/seed/supdemon/300/450',
      'unreadBadge': 15,
      'progressPercentage': null,
      'isFavorite': true,
    },
  ];

  // Mock Chronological Feed Data
  final List<Map<String, dynamic>> _feedGroupedByDate = [
    {
      'dateGroup': 'Today',
      'items': [
        {
          'id': 'up_1',
          'title': 'Initializing the Sect System',
          'coverUrl': 'https://picsum.photos/seed/sect1/300/450',
          'subtitle': '1 new chapter',
          'hasDot': true,
        },
      ],
    },
    {
      'dateGroup': 'Yesterday',
      'items': [
        {
          'id': 'up_2',
          'title': 'Return of the Mount Hua Sect',
          'coverUrl': 'https://picsum.photos/seed/mthua/300/450',
          'subtitle': '1 new chapter',
          'hasDot': false,
        },
        {
          'id': 'up_3',
          'title': 'Return Of The Flowery Mountain Sect',
          'coverUrl': 'https://picsum.photos/seed/flowery/300/450',
          'subtitle': '1 new chapter',
          'hasDot': false,
        },
      ],
    },
    {
      'dateGroup': '2 days ago',
      'items': [
        {
          'id': 'up_4',
          'title': 'The Supreme Demon',
          'coverUrl': 'https://picsum.photos/seed/supdemon/300/450',
          'subtitle': '3 new chapters',
          'hasDot': false,
        },
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              _buildSearchBar(context),
              const SizedBox(height: 16),
              _buildSectionHeader('Updates', actionLabel: 'More', onTap: () {}),
              const SizedBox(height: 12),
              _buildUpdatesCarousel(),
              const SizedBox(height: 20),
              ..._feedGroupedByDate.map((group) {
                return _buildDateGroupSection(group);
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(28),
      ),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const GlobalSearchScreen(),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          color: Colors.transparent,
          child: const Row(
            children: [
              Icon(Icons.search, color: Colors.white70, size: 22),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Search manga',
                  style: TextStyle(color: Colors.white54, fontSize: 16),
                ),
              ),
              Icon(Icons.more_vert, color: Colors.white70, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    String title, {
    required String actionLabel,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          GestureDetector(
            onTap: onTap,
            child: Text(
              actionLabel,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdatesCarousel() {
    return SizedBox(
      height: 185,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _updatesList.length,
        itemBuilder: (context, index) {
          final item = _updatesList[index];
          final unreadBadge = item['unreadBadge'] as int?;
          final progress = item['progressPercentage'] as String?;

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MangaDetailScreen(
                    mangaId: item['id'],
                    title: item['title'],
                    imageUrl: item['coverUrl'],
                  ),
                ),
              );
            },
            child: Container(
              width: 100,
              margin: const EdgeInsets.only(right: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: 2 / 3,
                    child: Stack(
                      children: [
                        ClipRRect(
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
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 6,
                          left: 6,
                          right: 6,
                          child: Row(
                            children: [
                              if (unreadBadge != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8B1B1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '$unreadBadge',
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.black45,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.favorite,
                                  color: Colors.white,
                                  size: 10,
                                ),
                              ),
                              const Spacer(),
                              if (progress != null)
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    progress,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
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
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateGroupSection(Map<String, dynamic> group) {
    final String dateGroup = group['dateGroup'];
    final List items = group['items'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            dateGroup,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...items.map((item) {
          final bool hasDot = item['hasDot'] == true;

          return ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MangaDetailScreen(
                    mangaId: item['id'],
                    title: item['title'],
                    imageUrl: item['coverUrl'],
                  ),
                ),
              );
            },
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: item['coverUrl'],
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => Container(
                  color: const Color(0xFF2C2C2E),
                  child: const Icon(Icons.menu_book, color: Colors.white38),
                ),
              ),
            ),
            title: Text(
              item['title'],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Row(
              children: [
                if (hasDot) ...[
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8B1B1),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  item['subtitle'],
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 8),
      ],
    );
  }
}