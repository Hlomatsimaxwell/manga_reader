import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yomou/data/models/manga.dart';
import 'package:yomou/features/library/providers/favorites_provider.dart';
import 'package:yomou/features/library/widgets/downloaded_badge.dart';
import 'package:yomou/features/library/screens/manga_detail_screen.dart';
import 'package:yomou/core/theme/layout.dart';
import 'package:yomou/core/widgets/empty_state.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final favoritesAsync = ref.watch(favoritesProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: bottomBarClearance(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              _buildSearchBar(),
              const SizedBox(height: 16),
              favoritesAsync.when(
                loading: () => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 80),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 60),
                  child: Center(
                    child: Text(
                      'Could not load favorites',
                      style: TextStyle(
                        color:
                            Theme.of(context).brightness == Brightness.dark
                                ? Colors.white54
                                : const Color(0xFF49454F),
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                data: (items) {
                  List<Manga> displayed = items;
                  if (_searchQuery.isNotEmpty) {
                    displayed = items
                        .where(
                          (m) => m.title.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          ),
                        )
                        .toList();
                  }
                  return _buildMangaGrid(displayed);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fieldColor = dark ? Colors.white : const Color(0xFF1C1B1F);
    final iconColor = dark ? Colors.white70 : Colors.black54;
    final hintColor = dark ? Colors.white54 : Colors.black54;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF2C2C2E) : const Color(0xFFEBEFEF),
        borderRadius: BorderRadius.circular(28),
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: fieldColor, fontSize: 16),
        cursorColor: fieldColor,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          icon: Icon(Icons.search, color: iconColor, size: 22),
          hintText: 'Search favorites',
          hintStyle: TextStyle(color: hintColor, fontSize: 16),
          border: InputBorder.none,
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: iconColor,
                    size: 20,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : Icon(Icons.more_vert, color: iconColor, size: 22),
        ),
      ),
    );
  }

  Widget _buildMangaGrid(List<Manga> items) {
    if (items.isEmpty) {
      return EmptyState(
        icon: Icons.favorite_border,
        title: _searchQuery.isNotEmpty
            ? 'No favorites match your search'
            : 'No favorites yet',
        subtitle: 'Tap the heart on any manga to add it here.',
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = dark
        ? Colors.white
        : Theme.of(context).colorScheme.onSurface;
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
          // Strict 2:3 Aspect Ratio for Cover Image
          AspectRatio(
            aspectRatio: 2 / 3,
            child: Stack(
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
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite,
                      color: Colors.white,
                      size: 13,
                    ),
                  ),
                ),
                DownloadedMangaBadge(
                  mangaId: item.id,
                  position: const EdgeInsets.only(top: 6, left: 6),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: titleColor,
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
