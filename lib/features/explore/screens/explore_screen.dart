import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yomou/core/database/source_cache.dart';
import 'package:yomou/core/widgets/ios/ios_menu.dart';
import 'package:yomou/core/widgets/ios/ios_press.dart';
import 'package:yomou/features/explore/screens/global_search_screen.dart';
import 'package:yomou/features/library/screens/bookmarks_screen.dart';
import 'package:yomou/features/library/screens/downloads_screen.dart';
import 'package:yomou/features/library/screens/manga_detail_screen.dart';
import 'package:yomou/features/settings/screens/settings_screen.dart';
import 'package:yomou/features/source_management/screens/manga_grid_screen.dart';
import 'package:yomou/features/source_management/screens/manga_sources_screen.dart';
import 'package:yomou/data/providers/sources_provider.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
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
  Widget build(BuildContext context) {
    final sources = ref.watch(sourcesProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              _buildSearchBar(),
              const SizedBox(height: 16),
              _buildQuickButtonsGrid(),
              const SizedBox(height: 24),
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
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  color: Colors.transparent,
                  alignment: Alignment.centerLeft,
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
            AppSheetPress(
              onTap: () async {
                final action = await showIosMenuPanel<String>(
                  context,
                  children: [
                    IosMenuRow(
                      icon: Icons.tune_rounded,
                      label: 'Manage sources',
                      onTap: () => Navigator.pop(context, 'manage'),
                    ),
                    const IosMenuDivider(),
                    MenuToggleRow(
                      label: 'Incognito mode',
                      value: _incognitoMode,
                      onChanged: (v) => setState(() => _incognitoMode = v),
                    ),
                    const IosMenuDivider(),
                    IosMenuRow(
                      icon: Icons.settings_rounded,
                      label: 'Settings',
                      onTap: () => Navigator.pop(context, 'settings'),
                    ),
                  ],
                );
                if (action == 'manage') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ManageSourcesScreen(),
                    ),
                  );
                } else if (action == 'settings') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                }
              },
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(
                  Icons.more_horiz_rounded,
                  color: Colors.white70,
                  size: 22,
                ),
              ),
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
          return AppPress(
            onTap: () => _handleQuickButton(btn['type'] as String),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2E),
                borderRadius: BorderRadius.circular(24),
              ),
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
          TextButton(
            onPressed: onMorePressed,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white70,
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }

  Widget _buildSourcesGrid(List<Map<String, dynamic>> sources) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 0.82,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: sources.length,
        itemBuilder: (context, index) {
          final source = sources[index];
          final isPinned = source['isPinned'] == true;
          final name = source['name'] as String;
          final iconUrl = source['iconUrl'] as String? ?? '';
          final fallbackLetter = name.isEmpty ? '?' : name[0];
          final fallbackColor = _deterministicColor(name);

          Widget fallbackTile() => Center(
            child: Text(
              fallbackLetter,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          );

          Widget tileIcon;
          if (iconUrl.isNotEmpty) {
            tileIcon = ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: ColoredBox(
                color: fallbackColor,
                child: Image.network(
                  iconUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (context, error, stackTrace) => fallbackTile(),
                ),
              ),
            );
          } else {
            tileIcon = fallbackTile();
          }

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MangaGridScreen(sourceName: name),
                ),
              );
            },
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: iconUrl.isNotEmpty
                            ? const Color(0xFF242424)
                            : fallbackColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                          width: 1,
                        ),
                      ),
                      child: tileIcon,
                    ),
                    if (isPinned)
                      Positioned(
                        left: 6,
                        bottom: 6,
                        child: Transform.rotate(
                          angle: -0.785398,
                          child: const Icon(
                            Icons.push_pin,
                            size: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  name,
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
          );
        },
      ),
    );
  }

  Color _deterministicColor(String name) {
    int hash = 0;
    for (final codeUnit in name.codeUnits) {
      hash = (hash * 31 + codeUnit) & 0x7FFFFFFF;
    }
    final hue = (hash % 360).toDouble();
    return HSLColor.fromAHSL(1, hue, 0.35, 0.35).toColor();
  }
}
