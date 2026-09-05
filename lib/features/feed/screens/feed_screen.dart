import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manga_reader/features/explore/screens/global_search_screen.dart';
import 'package:manga_reader/features/feed/providers/updates_provider.dart';
import 'package:manga_reader/features/library/screens/manga_detail_screen.dart';
import 'package:manga_reader/features/library/widgets/downloaded_badge.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updatesAsync = ref.watch(updatesProvider);

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
              const SizedBox(height: 12),
              _buildSectionHeader(context, ref),
              const SizedBox(height: 12),
              updatesAsync.when(
                data: (updates) {
                  if (updates.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(
                        child: Text(
                          'No new updates yet.\nManga you read will show here\nwhen new chapters are released.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white54, fontSize: 14),
                        ),
                      ),
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildUpdatesCarousel(context, updates),
                      const SizedBox(height: 20),
                      ..._groupByDate(context, updates),
                    ],
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.white54),
                  ),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 60),
                  child: Center(
                    child: Text(
                      'Failed to load updates',
                      style: TextStyle(color: Colors.white54, fontSize: 16),
                    ),
                  ),
                ),
              ),
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
            MaterialPageRoute(builder: (context) => const GlobalSearchScreen()),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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

  Widget _buildSectionHeader(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Updates',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          GestureDetector(
            onTap: () => ref.invalidate(updatesProvider),
            child: const Row(
              children: [
                Icon(Icons.refresh, color: Colors.white70, size: 15),
                SizedBox(width: 4),
                Text(
                  'Refresh',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdatesCarousel(
    BuildContext context,
    List<MangaUpdate> updates,
  ) {
    final previews = updates.take(6).toList();

    return SizedBox(
      height: 185,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: previews.length,
        itemBuilder: (context, index) {
          final update = previews[index];

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MangaDetailScreen(
                    mangaId: update.mangaId,
                    title: update.title,
                    imageUrl: update.coverUrl,
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
                            imageUrl: update.coverUrl,
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
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8B1B1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '+${update.newCount}',
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black45,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              update.isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: Colors.white,
                              size: 10,
                            ),
                          ),
                        ),
                        DownloadedMangaBadge(
                          mangaId: update.mangaId,
                          position: const EdgeInsets.only(bottom: 6, right: 6),
                          size: 20,
                          iconSize: 12,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    update.title,
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

  // Groups updates (already sorted by date desc) into date-grouped sections.
  List<Widget> _groupByDate(BuildContext context, List<MangaUpdate> updates) {
    final groups = <String, List<MangaUpdate>>{};
    for (final u in updates) {
      groups.putIfAbsent(u.dateGroup, () => []).add(u);
    }

    return [
      for (final entry in groups.entries)
        _buildDateGroupSection(context, entry.key, entry.value),
    ];
  }

  Widget _buildDateGroupSection(
    BuildContext context,
    String dateGroup,
    List<MangaUpdate> items,
  ) {
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
        ...items.map((update) {
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MangaDetailScreen(
                    mangaId: update.mangaId,
                    title: update.title,
                    imageUrl: update.coverUrl,
                  ),
                ),
              );
            },
            leading: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: update.coverUrl,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => Container(
                      color: const Color(0xFF2C2C2E),
                      child: const Icon(Icons.menu_book, color: Colors.white38),
                    ),
                  ),
                ),
                DownloadedMangaBadge(
                  mangaId: update.mangaId,
                  size: 16,
                  iconSize: 10,
                ),
              ],
            ),
            title: Text(
              update.title,
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
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8B1B1),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${update.newCount} new · ${update.latestChapterTitle}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
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
