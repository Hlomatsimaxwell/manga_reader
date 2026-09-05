import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manga_reader/core/database/database_helper.dart';

// Holds a revision counter. Bumped whenever a chapter download is added or
// removed, so every card/tray that watches these providers refreshes and the
// "downloaded" signs stay in sync app-wide.
final downloadsRevisionProvider = StateProvider<int>((ref) => 0);

// Manga ids that have at least one downloaded chapter.
final downloadedMangasProvider = FutureProvider<Set<String>>((ref) async {
  ref.watch(downloadsRevisionProvider);
  return DatabaseHelper.instance.getMangaIdsWithDownloads();
});

// Chapter ids downloaded within a specific manga (used by the detail tray).
final downloadedChaptersForMangaProvider =
    FutureProvider.family<Set<String>, String>((ref, mangaId) async {
  ref.watch(downloadsRevisionProvider);
  return DatabaseHelper.instance.getDownloadedChapterIds(mangaId);
});

// Call this after a download finishes or is removed to refresh badges
// everywhere.
void bumpDownloadsRevision(dynamic ref) {
  ref.read(downloadsRevisionProvider.notifier).state++;
}