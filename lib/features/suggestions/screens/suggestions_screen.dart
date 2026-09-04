import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manga_reader/data/models/manga.dart';
import 'package:manga_reader/features/library/screens/manga_detail_screen.dart';
import 'package:manga_reader/features/suggestions/providers/suggestions_provider.dart';

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
                      'Failed to load suggestions',
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

  Widget _buildGenreChips(List<String> tags) {
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
                      tag,
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

  Widget _buildMangaGrid(List<Manga> allManga) {
    final items = allManga.where((m) {
      return _searchQuery.isEmpty ||
          m.title.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CachedNetworkImage(
                imageUrl: manga.coverUrl,
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
            manga.title,
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
