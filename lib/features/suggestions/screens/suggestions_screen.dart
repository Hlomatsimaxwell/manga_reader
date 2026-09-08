import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yomou/data/models/manga.dart';
import 'package:yomou/features/library/screens/manga_detail_screen.dart';
import 'package:yomou/features/library/widgets/downloaded_badge.dart';
import 'package:yomou/features/suggestions/providers/suggestions_provider.dart';
import 'package:yomou/core/theme/layout.dart';
import 'package:yomou/core/widgets/empty_state.dart';
import 'package:yomou/l10n/generated/app_localizations.dart';

class SuggestionsScreen extends ConsumerStatefulWidget {
  const SuggestionsScreen({super.key});

  @override
  ConsumerState<SuggestionsScreen> createState() => _SuggestionsScreenState();
}

class _SuggestionsScreenState extends ConsumerState<SuggestionsScreen> {
  String? _selectedGenre; // null: personalised, non-null: filter by genre
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Passing _selectedGenre as the family key; provider re-fetches when it changes.
    final suggestionsAsync = ref.watch(suggestionsProvider(_selectedGenre));
    final genreTagsAsync = ref.watch(genreTagsProvider);

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
              const SizedBox(height: 12),
              genreTagsAsync.when(
                data: (tags) => tags.isNotEmpty
                    ? _buildGenreChips(tags)
                    : const SizedBox.shrink(),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),
              suggestionsAsync.when(
                data: (mangaList) => _buildMangaGrid(mangaList),
                loading: () => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 60),
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
                      AppLocalizations.of(context).failedToLoadSuggestions,
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
          hintText: AppLocalizations.of(context).searchManga,
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

  Widget _buildGenreChips(List<String> tags) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: tags.length,
        itemBuilder: (context, index) {
          final tag = tags[index];
          final isSelected = _selectedGenre == tag;

          final Color bg = dark
              ? (isSelected ? Colors.white : Colors.transparent)
              : (isSelected ? primary : const Color(0xFFE2E8F0));
          final Color fg = dark
              ? (isSelected ? Colors.black : Colors.white)
              : (isSelected ? Colors.white : const Color(0xFF334155));

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedGenre = isSelected ? null : tag;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(12),
                  border: dark
                      ? Border.all(
                          color: isSelected ? Colors.white : Colors.white38,
                        )
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.sell_outlined,
                      size: 16,
                      color: fg,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tag,
                      style: TextStyle(
                        color: fg,
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

  Widget _buildMangaGrid(List<Manga> allManga) {
    final items = allManga.where((m) {
      return _searchQuery.isEmpty ||
          m.title.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    if (items.isEmpty) {
      return EmptyState(
        icon: Icons.lightbulb_outline,
        title: AppLocalizations.of(context).suggestionsNoResults,
        subtitle: AppLocalizations.of(context).tryDifferentSearch,
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
          final manga = items[index];
          return _buildMangaCard(context, manga);
        },
      ),
    );
  }

  Widget _buildMangaCard(BuildContext context, Manga manga) {
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
              mangaId: manga.id,
              title: manga.title,
              imageUrl: manga.coverUrl,
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
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: dark ? null : Border.all(color: Colors.black12),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: manga.coverUrl,
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
                DownloadedMangaBadge(mangaId: manga.id),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            manga.title,
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
