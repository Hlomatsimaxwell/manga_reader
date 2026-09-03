import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manga_reader/core/database/database_helper.dart';

List<Map<String, dynamic>> mapHistoryRows(List<Map<String, dynamic>> rows) {
  return rows.map((row) {
    final lastReadChapter = (row['lastReadChapter'] as num? ?? -1).toDouble();
    final total = (row['totalChapters'] as int? ?? 0);
    final progress = total > 0
        ? ((lastReadChapter.clamp(0, total.toDouble()) / total) * 100)
            .round()
            .clamp(0, 100)
            .toInt()
        : 0;
    final maxChapter = total > 0 ? total : 0;
    final unread = (maxChapter - lastReadChapter)
        .clamp(0.0, maxChapter.toDouble())
        .toInt();

    return <String, dynamic>{
      'mangaId': row['mangaId'],
      'title': row['title'],
      'coverUrl': row['coverUrl'] ?? '',
      'sourceId': row['sourceId'],
      'lastReadChapter': lastReadChapter.floor(),
      'totalReleasedChapters': total,
      'lastReadAt': row['lastReadAt'] ?? DateTime.now().toIso8601String(),
      'progress': progress,
      'unreadCount': unread,
      'hasDownloadedChapters': false,
    };
  }).toList();
}

// Holds a revision counter. Bumped whenever reading progress changes,
// so the history provider knows to refetch from the database.
final historyRevisionProvider = StateProvider<int>((ref) => 0);

// Fetches + maps history from the database. Depends on the revision so it
// automatically refreshes whenever progress is saved.
final historyProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(historyRevisionProvider);
  final rows = await DatabaseHelper.instance.getHistory();
  return mapHistoryRows(rows);
});

// Call this after the reader saves progress to make history refresh.
void bumpHistoryRevision(dynamic ref) {
  ref.read(historyRevisionProvider.notifier).state++;
}
