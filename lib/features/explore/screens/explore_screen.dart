import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manga_reader/core/database/source_cache.dart';
import 'package:manga_reader/features/explore/screens/global_search_screen.dart';
import 'package:manga_reader/features/library/screens/bookmarks_screen.dart';
import 'package:manga_reader/features/library/screens/downloads_screen.dart';
import 'package:manga_reader/features/library/screens/manga_detail_screen.dart';
import 'package:manga_reader/features/settings/screens/settings_screen.dart';
import 'package:manga_reader/features/source_management/screens/manga_grid_screen.dart';
import 'package:manga_reader/features/source_management/screens/manga_sources_screen.dart';
import 'package:manga_reader/features/suggestions/providers/suggestions_provider.dart';
import 'package:manga_reader/features/suggestions/screens/suggestions_screen.dart';
import 'package:manga_reader/data/models/manga.dart';
import 'package:manga_reader/data/providers/sources_provider.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final PageController _suggestionPageController = PageController();
  int _currentSuggestionIndex = 0;
  bool _incognitoMode = false;
  bool _loadingRandom = false;

  final List<Map<String, dynamic>> _quickButtons = [
    {
      'icon': Icons.sd_card_outlined,
      'label': 'Local storage',
      'type': 'downloads',
    },
    {'icon': Icons.bookmark_outline, 'label': 'Bookmarks', 'type': 'bookmarks'},
    {'icon': Icons.casino_outlined, 'label': 'Random', 'type': 'random'},
    {
      'icon': Icons.download_outlined,
      'label': 'Downloads',
      'type': 'downloads',
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
    final suggestions = ref.watch(suggestionsProvider(null));

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
              _buildSectionHeader(
                'Suggestions',
                onMorePressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SuggestionsScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildSuggestionCard(suggestions),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
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
                    horizontal: 16,
                    vertical: 14,
                  ),
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
              icon: const Icon(
                Icons.more_vert,
                color: Colors.white70,
                size: 22,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              onSelected: (value) {
                if (value == 'presets') {
                  _showSourcePicker();
                } else if (value == 'manage') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ManageSourcesScreen(),
                    ),
                  );
                } else if (value == 'settings') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                }
              },
              itemBuilder: (BuildContext context) {
                return [
                  const PopupMenuItem<String>(
                    value: 'presets',
                    child: Text(
                      'Source presets',
                      style: TextStyle(color: Colors.white, fontSize: 15),
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'manage',
                    child: Text(
                      'Manage sources',
                      style: TextStyle(color: Colors.white, fontSize: 15),
                    ),
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
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                ),
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
                    child: Text(
                      'Settings',
                      style: TextStyle(color: Colors.white, fontSize: 15),
                    ),
                  ),
                ];
              },
            ),
            const SizedBox(width: 6),
          ],
        ),
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
          final isRandom = btn['type'] == 'random';
          return Material(
            color: const Color(0xFF2C2C2E),
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              onTap: () => _handleQuickButton(btn['type'] as String),
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    if (isRandom && _loadingRandom)
                      const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white38,
                          strokeWidth: 2,
                        ),
                      )
                    else
                      Icon(
                        btn['icon'] as IconData,
                        color: Colors.white,
                        size: 22,
                      ),
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
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleQuickButton(String type) async {
    switch (type) {
      case 'downloads':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const DownloadsScreen()),
        );
        break;
      case 'bookmarks':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const BookmarksScreen()),
        );
        break;
      case 'random':
        await _openRandomManga();
        break;
    }
  }

  Future<void> _openRandomManga() async {
    if (_loadingRandom) return;
    setState(() => _loadingRandom = true);
    try {
      final source = ref.read(currentSourceProvider);
      final pool = await SourceCache.mangaList(
        sourceId: source.id,
        kind: 'popular',
        page: 1,
        fetch: () => source.getPopularManga(page: 1),
      );
      if (pool.isEmpty || !mounted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No manga available for Random right now'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }
      final index = DateTime.now().millisecondsSinceEpoch % pool.length;
      final manga = pool[index];
      if (!mounted) return;
      await Navigator.push(
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
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not find a random manga'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingRandom = false);
    }
  }

  Widget _buildSourcePresetsDropdown() {
    final currentName = ref.watch(currentSourceProvider).name;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: _showSourcePicker,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                const Icon(Icons.segment, color: Colors.white, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Source: $currentName',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(
                  Icons.arrow_drop_down,
                  color: Colors.white70,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showSourcePicker() async {
    final sources = ref.read(sourcesProvider);
    final current = ref.read(currentSourceProvider);
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Active source',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final source in sources)
                      ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: source['bgColor'] as Color,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              source['text'] as String,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          source['name'] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Text(
                          source['language'] as String? ?? '',
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 12,
                          ),
                        ),
                        trailing: current.name == (source['name'] as String)
                            ? const Icon(
                                Icons.check_circle,
                                color: Colors.white70,
                                size: 22,
                              )
                            : null,
                        onTap: () => Navigator.pop(
                          sheetContext,
                          source['name'] as String,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (selected == null || !mounted) return;
    final currentName = ref.read(currentSourceProvider).name;
    if (selected == currentName) return;

    ref.read(currentSourceProvider.notifier).state = getSourceByName(selected);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Switched to $selected'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Widget _buildSectionHeader(
    String title, {
    String actionLabel = 'More',
    required VoidCallback onMorePressed,
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

  Widget _buildSuggestionCard(AsyncValue<List<Manga>> suggestions) {
    return SizedBox(
      height: 64,
      child: suggestions.when(
        loading: () => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.white38,
                strokeWidth: 2,
              ),
            ),
          ),
        ),
        error: (error, stackTrace) => _buildEmptySuggestionCard(),
        data: (mangas) {
          final items = mangas.take(8).toList();
          if (items.isEmpty) return _buildEmptySuggestionCard();

          return PageView.builder(
            controller: _suggestionPageController,
            itemCount: items.length,
            onPageChanged: (index) {
              setState(() {
                _currentSuggestionIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final manga = items[index];
              return GestureDetector(
                onTap: () {
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
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: manga.coverUrl,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => Container(
                            width: 56,
                            height: 56,
                            color: const Color(0xFF2C2C2E),
                            child: const Icon(
                              Icons.menu_book,
                              color: Colors.white38,
                            ),
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
                              manga.title,
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
                              'For you • ${manga.sourceId}',
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
          );
        },
      ),
    );
  }

  Widget _buildEmptySuggestionCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Text(
            'No suggestions yet — read a few chapters or switch source',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
        ),
      ),
    );
  }

  Widget _buildPageIndicator() {
    final total = ref
        .watch(suggestionsProvider(null))
        .maybeWhen(data: (mangas) => mangas.take(8).length, orElse: () => 0);
    if (total <= 1) return const SizedBox.shrink();
    final activeIndex = _currentSuggestionIndex.clamp(0, total - 1);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (index) {
        final isActive = index == activeIndex;
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
                  builder: (context) =>
                      MangaGridScreen(sourceName: source['name'] as String),
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
                      const Icon(Icons.push_pin, color: Colors.white, size: 11),
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
