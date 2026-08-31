import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manga_reader/features/explore/screens/global_search_screen.dart';
import 'package:manga_reader/features/library/screens/manga_detail_screen.dart';
import 'package:manga_reader/data/providers/sources_provider.dart';
import 'package:manga_reader/features/source_management/screens/manga_grid_screen.dart';
import 'package:manga_reader/features/source_management/screens/manga_sources_screen.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final PageController _suggestionPageController = PageController();
  int _currentSuggestionIndex = 0;
  bool _incognitoMode = false;

  final List<Map<String, dynamic>> _quickButtons = [
    {'icon': Icons.sd_card_outlined, 'label': 'Local storage'},
    {'icon': Icons.bookmark_outline, 'label': 'Bookmarks'},
    {'icon': Icons.casino_outlined, 'label': 'Random'},
    {'icon': Icons.download_outlined, 'label': 'Downloads'},
  ];

  final List<Map<String, String>> _suggestionsList = [
    {
      'title': 'The White Mage Who Was Banished fro...',
      'tags': 'Fantasy, Shounen, Adventure, Action',
      'coverUrl': 'https://picsum.photos/seed/sugg_explore1/200/200',
    },
    {
      'title': 'Solo Leveling',
      'tags': 'Action, Fantasy, Superpowers, Webtoons, Adventure',
      'coverUrl': 'https://picsum.photos/seed/sugg_explore2/200/200',
    },
  ];

  @override
  void dispose() {
    _suggestionPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sources = ref.watch(sourcesProvider);

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
              const SizedBox(height: 16),
              _buildQuickButtonsGrid(),
              const SizedBox(height: 12),
              _buildSourcePresetsDropdown(),
              const SizedBox(height: 20),
              _buildSectionHeader('Suggestions', onMorePressed: () {}),
              const SizedBox(height: 12),
              _buildSuggestionCard(),
              const SizedBox(height: 12),
              _buildPageIndicator(),
              const SizedBox(height: 20),
              _buildSectionHeader(
                'Manga sources',
                actionLabel: 'Manage',
                onMorePressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ManageSourcesScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildSourcesGrid(sources),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Expanded(
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
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                color: Colors.transparent,
                child: const Row(
                  children: [
                    Icon(Icons.search, color: Colors.white70, size: 22),
                    SizedBox(width: 12),
                    Text(
                      'Search manga',
                      style: TextStyle(color: Colors.white54, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ),
          PopupMenuButton<String>(
            color: const Color(0xFF2C2C2E),
            icon: const Icon(Icons.more_vert, color: Colors.white70, size: 22),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            onSelected: (value) {
              if (value == 'manage') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ManageSourcesScreen(),
                  ),
                );
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  value: 'presets',
                  child: Text('Source presets',
                      style: TextStyle(color: Colors.white, fontSize: 15)),
                ),
                const PopupMenuItem<String>(
                  value: 'manage',
                  child: Text('Manage sources',
                      style: TextStyle(color: Colors.white, fontSize: 15)),
                ),
                PopupMenuItem<String>(
                  enabled: false,
                  child: StatefulBuilder(
                    builder: (context, setPopupState) {
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _incognitoMode = !_incognitoMode;
                          });
                          setPopupState(() {});
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Incognito mode',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 15),
                            ),
                            Checkbox(
                              value: _incognitoMode,
                              activeColor: Colors.white,
                              checkColor: Colors.black,
                              side: const BorderSide(color: Colors.white70),
                              onChanged: (val) {
                                setState(() {
                                  _incognitoMode = val ?? false;
                                });
                                setPopupState(() {});
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'settings',
                  child: Text('Settings',
                      style: TextStyle(color: Colors.white, fontSize: 15)),
                ),
              ];
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
    );
  }

  Widget _buildQuickButtonsGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 2.8,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _quickButtons.length,
        itemBuilder: (context, index) {
          final btn = _quickButtons[index];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2E),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Icon(btn['icon'] as IconData, color: Colors.white, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    btn['label'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSourcePresetsDropdown() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Row(
        children: [
          Icon(Icons.segment, color: Colors.white, size: 22),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Source presets',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Icon(Icons.arrow_drop_down, color: Colors.white70, size: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title,
      {String actionLabel = 'More', required VoidCallback onMorePressed}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          GestureDetector(
            onTap: onMorePressed,
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

  Widget _buildSuggestionCard() {
    return SizedBox(
      height: 64,
      child: PageView.builder(
        controller: _suggestionPageController,
        itemCount: _suggestionsList.length,
        onPageChanged: (index) {
          setState(() {
            _currentSuggestionIndex = index;
          });
        },
        itemBuilder: (context, index) {
          final item = _suggestionsList[index];

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MangaDetailScreen(
                    mangaId: 'sugg_$index',
                    title: item['title'] ?? '',
                    imageUrl: item['coverUrl'] ?? '',
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      item['coverUrl']!,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 56,
                        height: 56,
                        color: const Color(0xFF2C2C2E),
                        child:
                            const Icon(Icons.menu_book, color: Colors.white38),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item['title']!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item['tags']!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                            height: 1.3,
                          ),
                        ),
                      ],
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

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_suggestionsList.length, (index) {
        final isActive = index == _currentSuggestionIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 6 : 4,
          height: isActive ? 6 : 4,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? Colors.white : Colors.white24,
          ),
        );
      }),
    );
  }

  Widget _buildSourcesGrid(List<Map<String, dynamic>> sources) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.85,
          crossAxisSpacing: 12,
          mainAxisSpacing: 16,
        ),
        itemCount: sources.length,
        itemBuilder: (context, index) {
          final source = sources[index];
          final isPinned = source['isPinned'] == true;

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MangaGridScreen(
                    sourceName: source['name'] as String,
                  ),
                ),
              );
            },
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: source['bgColor'] as Color,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      source['text'] as String,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: source['textColor'] as Color? ?? Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isPinned) ...[
                      const Icon(
                        Icons.push_pin,
                        color: Colors.white,
                        size: 11,
                      ),
                      const SizedBox(width: 3),
                    ],
                    Flexible(
                      child: Text(
                        source['name'] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}