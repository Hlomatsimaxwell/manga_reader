import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:manga_reader/core/database/database_helper.dart';
import 'package:manga_reader/features/library/screens/related_manga_screen.dart';
import 'package:manga_reader/features/reader/screens/reader_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:manga_reader/data/models/chapter.dart';
import 'package:manga_reader/data/models/manga_source.dart';
import 'package:manga_reader/data/models/manga_details.dart';
import 'package:manga_reader/data/models/bookmark.dart';
import 'package:manga_reader/data/providers/sources_provider.dart';


class MangaDetailScreen extends StatefulWidget {
  final String mangaId;
  final String title;
  final String imageUrl;
  final String? sourceId;

  const MangaDetailScreen({
    super.key,
    required this.mangaId,
    required this.title,
    required this.imageUrl,
    this.sourceId,
  });

  @override
  State<MangaDetailScreen> createState() => _MangaDetailScreenState();
}

class _MangaDetailScreenState extends State<MangaDetailScreen> {
  int _currentReadingChapterIndex = 0;
  int _activeTab = 0; // 0: Chapter List, 1: Pages Grid, 2: Bookmarks

  // Read later state & persistence
  bool _isReadLaterSelected = false;
  bool _isLoadingPreferences = true;

  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  bool _isExpanded = false;
  bool _showSheetContent = false;

  String? _sourceName;

  List<Chapter> _chapters = [];
  bool _isLoadingChapters = true;
  String? _chapterError;
  MangaSource? _source;

  MangaDetails? _details;

  // Real reading progress from the database.
  Map<String, dynamic>? _progressRow;
  double _progressPercent = 0;
  double _lastReadChapter = -1;
  Set<double> _readChapters = {};

  // Real bookmarks for this manga.
  List<Bookmark> _bookmarks = [];

  // Captures the DraggableScrollableSheet's scroll controller so we can
  // programmatically scroll the chapter list to the oldest chapter.
  ScrollController? _sheetContentController;
  bool _isLoadingBookmarks = true;

  // Pages grid: page URLs for the preview chapter.
  List<String> _previewPages = [];
  bool _isLoadingPages = false;

  @override
  void initState() {
    super.initState();
    _loadReadLaterStatus();
    _loadChapters();
    _loadProgress();
    _loadBookmarks();

    _sheetController.addListener(() {
      final currentSize = _sheetController.size;
      final isTop = currentSize > 0.8;
      if (isTop != _isExpanded) {
        setState(() => _isExpanded = isTop);
      }

      final shouldShowContent = currentSize > 0.12;
      if (shouldShowContent != _showSheetContent) {
        setState(() => _showSheetContent = shouldShowContent);
      }
    });
  }

  Future<void> _loadChapters() async {
    setState(() {
      _isLoadingChapters = true;
      _chapterError = null;
    });
    try {
      final source = widget.sourceId != null
          ? getSourceBySourceId(widget.sourceId!)
          : null;
      if (source == null) {
        setState(() {
          _chapters = [];
          _isLoadingChapters = false;
        });
        return;
      }
      final chapters = await source.getChapters(widget.mangaId);
      if (mounted) {
        setState(() {
          _source = source;
          _sourceName = source.name;
          _chapters = chapters;
          _isLoadingChapters = false;
        });
      }

      // Fetch real manga details + preview pages (best-effort, don't block UI).
      final details = await source.getMangaDetails(widget.mangaId);
      if (details != null && mounted) {
        setState(() => _details = details);
      }
      if (chapters.isNotEmpty && mounted) {
        _loadPreviewPages();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _chapterError = e.toString();
          _isLoadingChapters = false;
        });
      }
    }
  }

  // Load the real saved reading progress for this manga from the database.
  Future<void> _loadProgress() async {
    final row = await DatabaseHelper.instance.getManga(widget.mangaId);
    final read = await DatabaseHelper.instance.getReadChapterNumbers(widget.mangaId);
    if (!mounted) return;
    setState(() {
      _progressRow = row;
      _readChapters = read;
      _lastReadChapter = row?['lastReadChapter'] is num
          ? (row!['lastReadChapter'] as num).toDouble()
          : -1;
      final total = (row?['totalChapters'] as int? ?? 0);
      if (_lastReadChapter >= 0 && total > 0) {
        final clamped = _lastReadChapter.clamp(0, total.toDouble());
        _progressPercent = (clamped / total) * 100;
      }
    });
  }

  // Load saved bookmarks for this manga.
  Future<void> _loadBookmarks() async {
    final rows = await DatabaseHelper.instance.getBookmarks(widget.mangaId);
    if (!mounted) return;
    setState(() {
      _bookmarks = rows.map(Bookmark.fromMap).toList();
      _isLoadingBookmarks = false;
    });
  }

  // Load the first chapter's page URLs to populate the Pages Grid tab.
  Future<void> _loadPreviewPages() async {
    if (_chapters.isEmpty || _isLoadingPages) return;
    setState(() => _isLoadingPages = true);
    try {
      final source = getSourceBySourceId(widget.sourceId ?? '');
      final pages = source == null
          ? <String>[]
          : await source.getPageUrls(_chapters.first.id);
      if (mounted) {
        setState(() {
          _previewPages = pages;
          _isLoadingPages = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingPages = false);
    }
  }

  // Key unique to this specific manga for permanent storage
  String get _readLaterKey => 'read_later_${widget.mangaId}';

  // Load saved preference from SharedPreferences
  Future<void> _loadReadLaterStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isReadLaterSelected = prefs.getBool(_readLaterKey) ?? false;
      _isLoadingPreferences = false;
    });
  }

  // Toggle and save read later status permanently
  Future<void> _toggleReadLater(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_readLaterKey, value);
    setState(() {
      _isReadLaterSelected = value;
    });
  }

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  void _animateSheetTo(double targetSize) {
    _sheetController.animateTo(
      targetSize,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  // Scroll the chapter list to the oldest (last) chapter.
  void _scrollToOldestChapter() {
    final sc = _sheetContentController;
    if (sc == null) return;
    if (sc.hasClients) {
      sc.animateTo(
        sc.position.maxScrollExtent,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      // Retry on the next frame once the list is laid out.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (sc.hasClients) {
          sc.animateTo(
            sc.position.maxScrollExtent,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }
  }

  // Collapse the sheet back to its small bar.
  void _dismissSheet() {
    _animateSheetTo(0.08);
  }

  // Navigate to Reader Screen
  void _openReader({int? chapterIndex}) {
    if (_chapters.isEmpty) return;
    final indexToOpen = chapterIndex ?? _resumeChapterIndex;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReaderScreen(
          allChapters: _chapters,
          initialChapterIndex: indexToOpen,
          mangaId: widget.mangaId,
          sourceId: _source?.id,
          mangaTitle: widget.title,
          mangaCoverUrl: widget.imageUrl,
          totalChapters: _chapters.length,
        ),
      ),
    );
  }

  // Index of the chapter to resume from, based on last-read progress.
  int get _resumeChapterIndex {
    if (_chapters.isEmpty) return 0;
    if (_lastReadChapter <= 0) return _currentReadingChapterIndex;

    // Chapters are ordered newest-first; find the last-read chapter number.
    final lastReadInt = _lastReadChapter.round();
    for (var i = 0; i < _chapters.length; i++) {
      final numParsed = double.tryParse(
        RegExp(r'(\d+(\.\d+)?)')
            .firstMatch(_chapters[i].chapterNumber)
            ?.group(1) ??
            '',
      );
      if (numParsed != null && numParsed.round() == lastReadInt) {
        return i;
      }
    }
    return _currentReadingChapterIndex;
  }

  // Read Later / Category Dialog
  void _showCategoryDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: const Color(0xFF2C2C2E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: widget.imageUrl,
                            width: 50,
                            height: 70,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) => Container(
                              color: Colors.black26,
                              child: const Icon(
                                Icons.menu_book,
                                color: Colors.white38,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            widget.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      activeColor: Colors.white,
                      checkColor: Colors.black,
                      side: const BorderSide(color: Colors.white70, width: 2),
                      value: _isReadLaterSelected,
                      title: const Row(
                        children: [
                          Text(
                            'Read later',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(
                            Icons.notifications_none,
                            color: Colors.white70,
                            size: 18,
                          ),
                        ],
                      ),
                      onChanged: (bool? val) async {
                        final newValue = val ?? false;
                        setDialogState(() {
                          _isReadLaterSelected = newValue;
                        });
                        await _toggleReadLater(newValue);
                      },
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () {},
                          child: const Text(
                            'Manage',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Done',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Tag Search Options Dialog
  void _showTagSearchDialog(String tagName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: const Color(0xFF2C2C2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.local_offer_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      tagName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Searching "$tagName" on $_sourceName...',
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        Text(
                          'Search on $_sourceName',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Searching "$tagName" everywhere...'),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        Text(
                          'Search everywhere',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                // Tapping the content background dismisses the open sheet.
                if (_sheetController.size > 0.12) _dismissSheet();
              },
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 90),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTopAppBar(context),
                      _buildHeaderSection(),
                      const SizedBox(height: 16),
                      _buildSourceCard(),
                      const SizedBox(height: 16),
                      _buildDescriptionSection(),
                      const SizedBox(height: 12),
                      _buildTagChips(),
                      const SizedBox(height: 20),
                      _buildRelatedMangaSection(),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SizedBox.expand(
            child: DraggableScrollableSheet(
              controller: _sheetController,
              initialChildSize: 0.08,
              minChildSize: 0.08,
              maxChildSize: 1.0,
              snap: true,
              snapSizes: const [0.08, 0.5, 1.0],
              builder: (context, scrollController) {
                _sheetContentController = scrollController;
                return Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E20),
                    borderRadius: _isExpanded
                        ? BorderRadius.zero
                        : const BorderRadius.vertical(top: Radius.circular(28)),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black87,
                        blurRadius: 20,
                        offset: Offset(0, -6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: _isExpanded
                        ? BorderRadius.zero
                        : const BorderRadius.vertical(top: Radius.circular(28)),
                    child: CustomScrollView(
                      controller: scrollController,
                      slivers: [
                        SliverPersistentHeader(
                          pinned: true,
                          delegate: _SheetHeaderDelegate(
                            isExpanded: _isExpanded,
                            activeTab: _activeTab,
                            topPadding: MediaQuery.of(context).padding.top,
                            onContinuePressed: () => _openReader(),
                            onBarTap: () {
                              final current = _sheetController.size;
                              if (current < 0.2) {
                                _animateSheetTo(0.5);
                                _scrollToOldestChapter();
                              } else if (current >= 0.4 && current <= 0.6) {
                                _animateSheetTo(0.08);
                              }
                            },
                            onTabSelected: (index) {
                              setState(() => _activeTab = index);
                              if (_sheetController.size < 0.2) {
                                _animateSheetTo(0.5);
                              }
                            },
                          ),
                        ),
                        if (_showSheetContent) ...[
                          if (_activeTab == 0)
                            _buildChapterListSliver()
                          else if (_activeTab == 1)
                            _buildPagesGridSliver()
                          else
                            _buildBookmarksSliver(),
                          const SliverToBoxAdapter(child: SizedBox(height: 40)),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChapterListSliver() {
    if (_isLoadingChapters) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 80),
          child: Center(child: CircularProgressIndicator(color: Colors.white54)),
        ),
      );
    }

    if (_chapterError != null || _source == null) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
          child: Column(
            children: [
              const Text(
                'No chapters available',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                _source == null
                    ? 'This source is not supported from here.'
                    : _chapterError!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final ch = _chapters[index];
          final numParsed = double.tryParse(
            RegExp(r'(\d+(\.\d+)?)').firstMatch(ch.chapterNumber)?.group(1) ??
                '',
          );
          final isRead = numParsed != null && _readChapters.contains(numParsed);
          final isCurrent = index == _currentDisplayIndex;

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 2),
            title: Row(
              children: [
                if (isCurrent)
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.greenAccent,
                      size: 20,
                    ),
                  ),
                Expanded(
                  child: Text(
                    ch.chapterNumber == 'Chapter'
                        ? ch.title
                        : ch.chapterNumber,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isRead ? Colors.grey : Colors.white,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Text(
              isRead ? 'Read' : (ch.releaseDate?.isNotEmpty ?? false ? ch.releaseDate! : ''),
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            trailing: isRead
                ? const Icon(Icons.check_circle, color: Colors.greenAccent, size: 18)
                : null,
            onTap: () {
              setState(() => _currentReadingChapterIndex = index);
              _openReader(chapterIndex: index);
            },
          );
        }, childCount: _chapters.length),
      ),
    );
  }

  // The chapter index shown as "current" (green play icon). Uses the last-read
  // chapter from the DB when available; no icon when nothing has been read.
  int get _currentDisplayIndex {
    if (_lastReadChapter <= 0) return -1;
    final lastInt = _lastReadChapter.round();
    for (var i = 0; i < _chapters.length; i++) {
      final n = double.tryParse(
        RegExp(r'(\d+(\.\d+)?)')
            .firstMatch(_chapters[i].chapterNumber)
            ?.group(1) ??
            '',
      );
      if (n != null && n.round() == lastInt) return i;
    }
    return -1;
  }

  Widget _buildPagesGridSliver() {
    if (_isLoadingPages) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 80),
          child: Center(child: CircularProgressIndicator(color: Colors.white54)),
        ),
      );
    }

    if (_previewPages.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
          child: Center(
            child: Text(
              _chapters.isEmpty ? 'Start reading to see pages' : 'No pages available',
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.7,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: _previewPages[index],
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: const Color(0xFF2C2C2E),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white24,
                    strokeWidth: 2,
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: const Color(0xFF2C2C2E),
                child: const Center(
                  child: Icon(Icons.broken_image, color: Colors.white38, size: 24),
                ),
              ),
            ),
          );
        }, childCount: _previewPages.length),
      ),
    );
  }

  Widget _buildBookmarksSliver() {
    if (_isLoadingBookmarks) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 80),
          child: Center(child: CircularProgressIndicator(color: Colors.white54)),
        ),
      );
    }

    if (_bookmarks.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 80),
          child: Column(
            children: [
              Text(
                'No bookmarks yet',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'You can create bookmark while reading manga',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final bm = _bookmarks[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 4),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: bm.pageUrl,
                width: 48,
                height: 64,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => Container(
                  width: 48,
                  height: 64,
                  color: const Color(0xFF2C2C2E),
                  child: const Icon(Icons.broken_image, color: Colors.white38),
                ),
              ),
            ),
            title: Text(
              '${bm.chapterTitle} • Page ${bm.pageIndex + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: bm.note != null && bm.note!.isNotEmpty
                ? Text(bm.note!, style: const TextStyle(color: Colors.grey, fontSize: 13))
                : const Text('No note', style: TextStyle(color: Colors.grey, fontSize: 13)),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white54),
              onPressed: () async {
                await DatabaseHelper.instance.deleteBookmark(bm.id);
                await _loadBookmarks();
              },
            ),
          );
        }, childCount: _bookmarks.length),
      ),
    );
  }

  Widget _buildTopAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.file_download_outlined, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: CachedNetworkImage(
              imageUrl: widget.imageUrl,
              width: 125,
              height: 175,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  maxLines: 3,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _isLoadingPreferences
                    ? const SizedBox(
                        height: 36,
                        width: 36,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : GestureDetector(
                        onTap: _showCategoryDialog,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _isReadLaterSelected
                                ? const Color(0xFF3A3A3C)
                                : const Color(0xFF1E1E22),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _isReadLaterSelected
                                  ? Colors.white70
                                  : Colors.white24,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isReadLaterSelected
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isReadLaterSelected
                                    ? 'Read later'
                                    : 'Favorite this',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.arrow_drop_down,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceCard() {
    final totalChapters = _details?.totalChapters ?? _chapters.length;
    final chaptersText = _lastReadChapter >= 0
        ? 'Chapter ${_lastReadChapter.floor()} of $totalChapters'
        : '$totalChapters chapters';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _buildCardRow(
            'Source',
            _details?.sourceId == 'mock' ? 'Mock Source' : (_sourceName ?? 'Unknown'),
            icon: Icons.pets,
          ),
          _buildCardRow('Author', _details?.author.isEmpty ?? true ? 'Unknown' : _details!.author),
          _buildCardRow('Year', _details?.year.isEmpty ?? true ? '—' : _details!.year),
          if ((_details?.status.isEmpty ?? true) == false)
            _buildCardRow('State', _details!.status),
          _buildCardRow('Chapters', chaptersText),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text(
                'Progress',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _lastReadChapter >= 0
                        ? (_progressPercent / 100).clamp(0.0, 1.0)
                        : 0,
                    backgroundColor: Colors.white12,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _lastReadChapter >= 0 ? '${_progressPercent.round()}%' : '0%',
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardRow(String label, String value, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: Colors.white),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
    final description = _details?.description.isEmpty ?? true
        ? 'No description available.'
        : _details!.description;
    final canExpand = description.length > 280;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Description',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            canExpand ? '${description.substring(0, 280)}…' : description,
            style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildTagChips() {
    final tags = (_details?.tags.isNotEmpty ?? false)
        ? _details!.tags
        : const <String>[];
    if (tags.isEmpty) return const SizedBox.shrink();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: tags.map((tag) {
          return GestureDetector(
            onTap: () => _showTagSearchDialog(tag),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white30),
              ),
              child: Text(
                tag,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRelatedMangaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Related manga',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const RelatedMangaScreen(title: 'Related manga'),
                    ),
                  );
                },
                child: const Text(
                  'Show all',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildRelatedCard(
                'Vengeance of the Doctress',
                'https://picsum.photos/seed/detail_rel1/300/450',
              ),
              _buildRelatedCard(
                'Necromancer of a Prestigo...',
                'https://picsum.photos/seed/detail_rel2/300/450',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRelatedCard(String title, String imageUrl) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              height: 120,
              width: 100,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _SheetHeaderDelegate extends SliverPersistentHeaderDelegate {
  final bool isExpanded;
  final int activeTab;
  final double topPadding;
  final VoidCallback onContinuePressed;
  final VoidCallback onBarTap;
  final ValueChanged<int> onTabSelected;

  _SheetHeaderDelegate({
    required this.isExpanded,
    required this.activeTab,
    required this.topPadding,
    required this.onContinuePressed,
    required this.onBarTap,
    required this.onTabSelected,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onBarTap,
      child: Container(
        color: const Color(0xFF1E1E20),
        padding: EdgeInsets.only(
          left: 12,
          right: 12,
          top: isExpanded ? topPadding : 0,
        ),
        alignment: Alignment.center,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => onTabSelected(0),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: activeTab == 0
                          ? const Color(0xFF2C2C2E)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.format_list_bulleted,
                      color: activeTab == 0 ? Colors.white : Colors.grey,
                      size: 18,
                    ),
                  ),
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF0A8A8),
                        shape: BoxShape.circle,
                      ),
                      child: const Text(
                        '1',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(
                Icons.grid_view_rounded,
                color: activeTab == 1 ? Colors.white : Colors.grey,
                size: 18,
              ),
              onPressed: () => onTabSelected(1),
            ),
            const SizedBox(width: 8),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(
                activeTab == 2
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                color: activeTab == 2 ? Colors.white : Colors.grey,
                size: 18,
              ),
              onPressed: () => onTabSelected(2),
            ),
            const Spacer(),
            if (isExpanded) ...[
              IconButton(
                icon: const Icon(Icons.search, color: Colors.white, size: 20),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(
                  Icons.more_vert,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () {},
              ),
            ] else ...[
              GestureDetector(
                onTap: onContinuePressed,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onContinuePressed,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2C2E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  double get maxExtent => 56 + (isExpanded ? topPadding : 0);

  @override
  double get minExtent => 56 + (isExpanded ? topPadding : 0);

  @override
  bool shouldRebuild(covariant _SheetHeaderDelegate oldDelegate) {
    return oldDelegate.isExpanded != isExpanded ||
        oldDelegate.activeTab != activeTab ||
        oldDelegate.topPadding != topPadding;
  }
}