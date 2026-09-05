import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manga_reader/core/database/database_helper.dart';
import 'package:manga_reader/features/library/screens/manga_detail_screen.dart';

/// Every bookmarked page across all manga, most recent first.
class BookmarksScreen extends ConsumerStatefulWidget {
  const BookmarksScreen({super.key});

  @override
  ConsumerState<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends ConsumerState<BookmarksScreen> {
  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reload();
  }

  Future<void> _reload() async {
    final rows = await DatabaseHelper.instance.getAllBookmarks();
    if (!mounted) return;
    setState(() {
      _rows = rows;
      _loading = false;
    });
  }

  Future<void> _confirmDelete(Map<String, dynamic> row) async {
    final pageIndex = (row['pageIndex'] as int?) ?? 0;
    final title = row['chapterTitle'] as String? ?? '';
    final id = row['id'] as int;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2E),
        title: const Text(
          'Delete bookmark?',
          style: TextStyle(color: Colors.white, fontSize: 17),
        ),
        content: Text(
          title.isEmpty
              ? 'Page ${pageIndex + 1}'
              : '"$title" • page ${pageIndex + 1}',
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
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await DatabaseHelper.instance.deleteBookmark(id);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Bookmarks',
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
                  Icon(Icons.bookmark_outline, color: Colors.white24, size: 56),
                  SizedBox(height: 12),
                  Text(
                    'No bookmarks yet',
                    style: TextStyle(color: Colors.white54, fontSize: 15),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Bookmark pages while reading to save them here',
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
                return _BookmarkTile(row: row, onDelete: _confirmDelete);
              },
            ),
    );
  }
}

class _BookmarkTile extends StatelessWidget {
  final Map<String, dynamic> row;
  final ValueChanged<Map<String, dynamic>> onDelete;

  const _BookmarkTile({required this.row, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final mangaId = row['mangaId'] as String? ?? '';
    final mangaTitle = row['mangaTitle'] as String? ?? mangaId;
    final mangaCover = row['mangaCover'] as String? ?? '';
    final sourceId = row['mangaSource'] as String?;
    final chapterTitle = row['chapterTitle'] as String? ?? '';
    final pageIndex = (row['pageIndex'] as int?) ?? 0;
    final createdAt = row['createdAt'] as String? ?? '';

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
                    chapterTitle.isEmpty
                        ? 'Page ${pageIndex + 1}'
                        : '$chapterTitle • page ${pageIndex + 1}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _fmtDate(createdAt),
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
              tooltip: 'Delete bookmark',
              onPressed: () => onDelete(row),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtDate(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final local = dt.toLocal();
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
