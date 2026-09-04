import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manga_reader/core/database/database_helper.dart';
import 'package:manga_reader/data/models/manga.dart';

List<Manga> mapFavoritesRows(List<Map<String, dynamic>> rows) {
  return rows.map((row) {
    return Manga(
      id: row['mangaId'] as String,
      title: row['title'] as String,
      coverUrl: row['coverUrl']?.toString() ?? '',
      sourceId: row['sourceId']?.toString() ?? '0',
    );
  }).toList();
}

// Holds a revision counter. Bumped whenever a manga is added to/removed from
// favorites, so the favorites provider knows to refetch from the database.
final favoritesRevisionProvider = StateProvider<int>((ref) => 0);

// Fetches + maps favorites from the database. Depends on the revision so it
// automatically refreshes whenever a favorite is toggled.
final favoritesProvider =
    FutureProvider<List<Manga>>((ref) async {
  ref.watch(favoritesRevisionProvider);
  final rows = await DatabaseHelper.instance.getFavorites();
  return mapFavoritesRows(rows);
});

// Call this after toggling a favorite to make the favorites screen refresh.
void bumpFavoritesRevision(dynamic ref) {
  ref.read(favoritesRevisionProvider.notifier).state++;
}
