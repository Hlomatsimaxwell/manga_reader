import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manga_reader/core/database/database_helper.dart';
import 'package:manga_reader/features/library/providers/downloads_provider.dart';
import 'package:manga_reader/features/library/screens/manga_detail_screen.dart';
import 'package:manga_reader/features/reader/services/chapter_downloader.dart';

/// All chapters downloaded to local storage across every manga.
class DownloadsScreen extends ConsumerStatefulWidget {
  const DownloadsScreen({super.key});

  @override
  ConsumerState<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends ConsumerState<DownloadsScreen> {
  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
    // Refresh when a download is added/removed elsewhere.
    ref.listenManual<int>(downloadsRevisionProvider, (prev, next) {
      if (next != prev) _reload();
    });
  }

  Future<void> _reload() async {
    final rows = await DatabaseHelper.instance.getAllDownloads();
    if (!mounted) return;
    setState(() {
      _rows = rows;
      _loading = false;
    });
  }

  Future<void> _confirmRemove(Map<String, dynamic> row) async {
    final mangaId = row['mangaId'] as String? ?? '';
    final chapterId = row['chapterId'] as String? ?? '';
    final title =
        row['chapterTitle'] as String? ??
        'Chapter ${_formatChapterNumber(((row['chapterNumber'] as num?) ?? 0).toDouble())}';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2E),
        title: const Text(
          'Remove download?',
          style: TextStyle(color: Colors.white, fontSize: 17),
        ),
        content: Text(
          '"$title" will be deleted from your device.',
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Remove',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await ChapterDownloader.removeChapterFiles(mangaId, chapterId);
    await DatabaseHelper.instance.removeDownload(mangaId, chapterId);
    bumpDownloadsRevision(ref);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Downloads',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white38),
            )
          : _rows.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.download_for_offline_outlined,
                    color: Colors.white24,
                    size: 56,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'No downloaded chapters yet',
                    style: TextStyle(color: Colors.white54, fontSize: 15),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Download chapters in the reader to read offline',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: _rows.length,
              separatorBuilder: (context, index) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final row = _rows[index];
                return _DownloadTile(row: row, onDelete: _confirmRemove);
              },
            ),
    );
  }

  String _formatChapterNumber(double number) {
    if (number == number.roundToDouble()) {
      return number.toInt().toString();
    }
    return number.toStringAsFixed(number == number.truncateToDouble() ? 0 : 1);
  }
}

class _DownloadTile extends StatelessWidget {
  final Map<String, dynamic> row;
  final ValueChanged<Map<String, dynamic>> onDelete;

  const _DownloadTile({required this.row, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final mangaId = row['mangaId'] as String? ?? '';
    final mangaTitle = row['mangaTitle'] as String? ?? mangaId;
    final mangaCover = row['mangaCover'] as String? ?? '';
    final sourceId = row['mangaSource'] as String?;
    final title = row['chapterTitle'] as String? ?? '';
    final chapterNumber = ((row['chapterNumber'] as num?) ?? 0).toDouble();
    final pageCount = (row['pageCount'] as int?) ?? 0;
    final downloadedAt = row['downloadedAt'] as String? ?? '';

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MangaDetailScreen(
              mangaId: mangaId,
              title: mangaTitle,
              imageUrl: mangaCover,
              sourceId: sourceId,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: mangaCover,
                width: 48,
                height: 64,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => Container(
                  width: 48,
                  height: 64,
                  color: const Color(0xFF2C2C2E),
                  child: const Icon(Icons.menu_book, color: Colors.white38),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mangaTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    title.isEmpty ? 'Chapter ${_fmtNum(chapterNumber)}' : title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$pageCount pages • ${_fmtDate(downloadedAt)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.white38,
                size: 20,
              ),
              tooltip: 'Remove download',
              onPressed: () => onDelete(row),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtNum(double number) {
    if (number == number.roundToDouble()) {
      return number.toInt().toString();
    }
    return number.toStringAsFixed(1);
  }

  String _fmtDate(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final local = dt.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(local.year, local.month, local.day);
    final diff = today.difference(that).inDays;
    if (diff == 0) return 'today';
    if (diff == 1) return 'yesterday';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[local.month - 1]} ${local.day}, ${local.year}';
  }
}
