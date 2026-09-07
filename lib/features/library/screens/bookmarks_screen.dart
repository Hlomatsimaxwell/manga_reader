import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yomou/core/database/database_helper.dart';
import 'package:yomou/core/widgets/empty_state.dart';
import 'package:yomou/core/widgets/ios/ios_press.dart';
import 'package:yomou/features/library/screens/manga_detail_screen.dart';

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
      builder: (context) {
        final dark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: dark ? const Color(0xFF2C2C2E) : Colors.white,
          title: Text(
            'Delete bookmark?',
            style: TextStyle(
              color: dark
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurface,
              fontSize: 17,
            ),
          ),
          content: Text(
            title.isEmpty
                ? 'Page ${pageIndex + 1}'
                : '"$title" • page ${pageIndex + 1}',
            style: TextStyle(
              color: dark ? Colors.white70 : const Color(0xFF49454F),
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: dark ? Colors.white70 : const Color(0xFF49454F),
                ),
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
        );
      },
    );
    if (confirmed != true || !mounted) return;

    await DatabaseHelper.instance.deleteBookmark(id);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text(
          'Bookmarks',
          style: TextStyle(
            color: dark ? Colors.white : const Color(0xFF1C1B1F),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(
                color: dark
                    ? Colors.white38
                    : Theme.of(context).colorScheme.primary,
              ),
            )
          : _rows.isEmpty
          ? EmptyState(
              icon: Icons.bookmark_outline,
              title: 'No bookmarks yet',
              subtitle: 'Bookmark pages while reading to save them here',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final mangaId = row['mangaId'] as String? ?? '';
    final mangaTitle = row['mangaTitle'] as String? ?? mangaId;
    final mangaCover = row['mangaCover'] as String? ?? '';
    final sourceId = row['mangaSource'] as String?;
    final chapterTitle = row['chapterTitle'] as String? ?? '';
    final pageIndex = (row['pageIndex'] as int?) ?? 0;
    final createdAt = row['createdAt'] as String? ?? '';

    return AppPress(
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
      child: Container(
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: dark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: dark
                  ? CachedNetworkImage(
                      imageUrl: mangaCover,
                      width: 48,
                      height: 64,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Container(
                        width: 48,
                        height: 64,
                        color: const Color(0xFF2C2C2E),
                        child: const Icon(
                          Icons.menu_book,
                          color: Colors.white38,
                        ),
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: mangaCover,
                        width: 48,
                        height: 64,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => Container(
                          width: 48,
                          height: 64,
                          color: Colors.black12,
                          child: const Icon(
                            Icons.menu_book,
                            color: Colors.black38,
                          ),
                        ),
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
                    style: TextStyle(
                      color: dark ? Colors.white : onSurface,
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
                    style: TextStyle(
                      color: dark ? Colors.white70 : const Color(0xFF49454F),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _fmtDate(createdAt),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: dark ? Colors.white38 : Colors.black38,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                color: dark ? Colors.white38 : Colors.black38,
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
