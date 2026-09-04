import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:manga_reader/data/models/manga.dart';
import 'package:manga_reader/features/library/screens/manga_detail_screen.dart';

class SourceSearchResultsScreen extends StatelessWidget {
  final String sourceName;
  final String query;
  final List<Manga> manga;

  const SourceSearchResultsScreen({
    super.key,
    required this.sourceName,
    required this.query,
    required this.manga,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              sourceName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '"$query" (${manga.length})',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.50,
          crossAxisSpacing: 10,
          mainAxisSpacing: 12,
        ),
        itemCount: manga.length,
        itemBuilder: (context, index) => _buildCard(context, manga[index]),
      ),
    );
  }

  Widget _buildCard(BuildContext context, Manga item) {
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
          AspectRatio(
            aspectRatio: 2 / 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
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
          const SizedBox(height: 6),
          Text(
            item.title,
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