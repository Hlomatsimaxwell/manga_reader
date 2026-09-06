import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:yomou/core/database/database_helper.dart';
import 'package:yomou/core/theme/colors.dart';
import 'package:yomou/core/widgets/ios/ios_press.dart';
import 'package:yomou/core/database/source_cache.dart';
import 'package:yomou/features/library/providers/favorites_provider.dart';
import 'package:yomou/features/library/providers/downloads_provider.dart';
import 'package:yomou/features/library/widgets/downloaded_badge.dart';
import 'package:yomou/features/library/screens/related_manga_screen.dart';
import 'package:yomou/features/reader/screens/reader_screen.dart';
import 'package:yomou/features/reader/services/chapter_downloader.dart';
import 'package:yomou/data/models/chapter.dart';
import 'package:yomou/data/models/manga.dart';
import 'package:yomou/data/models/manga_source.dart';
import 'package:yomou/data/models/manga_details.dart';
import 'package:yomou/data/models/bookmark.dart';
import 'package:yomou/data/providers/sources_provider.dart';

class MangaDetailScreen extends ConsumerStatefulWidget {
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
  ConsumerState<MangaDetailScreen> createState() => _MangaDetailScreenState();
}

class _MangaDetailScreenState extends ConsumerState<MangaDetailScreen> {
  int _activeTab = 0; // 0: Chapter List, 1: Pages Grid, 2: Bookmarks

  // Chapter multi-selection state (chapter ids currently selected).
  final Set<String> _selectedIds = <String>{};
  bool _selectionMode = false;

  // Favorite state & persistence (backed by the manga database table).
  bool _isFavorite = false;
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

  // The source's authoritative chapter count (-1 until loaded).
  int _realTotalChapters = -1;

  // Real related manga loaded from the source (excluding the current one).
  List<Manga> _relatedManga = [];

  // Real reading progress from the database.
  double _progressPercent = 0;
  double _lastReadChapter = -1;

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
    _loadFavoriteStatus();
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

  Future<void> _loadChapters({bool forceRefresh = false}) async {
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
      final chapters = await SourceCache.chapters(
        sourceId: source.id,
        mangaId: widget.mangaId,
        forceRefresh: forceRefresh,
        fetch: () => source.getChapters(widget.mangaId),
      );
      if (mounted) {
        setState(() {
          _source = source;
          _sourceName = source.name;
          _chapters = chapters;
          _isLoadingChapters = false;
        });
      }

      // Fetch real manga details + preview pages (best-effort, don't block UI).
      final details = await SourceCache.mangaDetails(
        sourceId: source.id,
        mangaId: widget.mangaId,
        forceRefresh: forceRefresh,
        fetch: () => source.getMangaDetails(widget.mangaId),
      );
      if (details != null && mounted) {
        setState(() => _details = details);
        // Cache tags in the database for the suggestions engine.
        if (details.tags.isNotEmpty) {
          DatabaseHelper.instance.saveMangaTags(widget.mangaId, details.tags);
        }
      }
      if (chapters.isNotEmpty && mounted) {
        _loadPreviewPages();
      }
      _loadRelatedManga(source);
      _loadTotalChapters(source);
    } catch (e) {
      if (mounted) {
        setState(() {
          _chapterError = e.toString();
          _isLoadingChapters = false;
        });
      }
    }
  }

  // Load the source's authoritative chapter count (best-effort).
  Future<void> _loadTotalChapters(MangaSource source) async {
    try {
      final total = await source.getTotalChapters(widget.mangaId);
      if (total > 0 && mounted) {
        setState(() => _realTotalChapters = total);
      }
    } catch (e) {
      _realTotalChapters = -1;
    }
  }

  // Load the real saved reading progress for this manga from the database.
  Future<void> _loadProgress() async {
    final row = await DatabaseHelper.instance.getManga(widget.mangaId);
    if (!mounted) return;
    setState(() {
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
          : await SourceCache.pageUrls(
              sourceId: source.id,
              chapterId: _chapters.first.id,
              fetch: () => source.getPageUrls(_chapters.first.id),
            );
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

  // Load manga with similar tags from the same source (excluding current).
  Future<void> _loadRelatedManga(MangaSource source) async {
    try {
      final myTags = (_details?.tags ?? const <String>[])
          .map((t) => t.toLowerCase())
          .toSet();

      final popular = await SourceCache.mangaList(
        sourceId: source.id,
        kind: 'popular',
        page: 1,
        fetch: () => source.getPopularManga(page: 1),
      );
      final candidates = popular
          .where((m) => m.id != widget.mangaId)
          .take(16)
          .toList();

      // Fetch each candidate's tags in parallel and rank by overlap.
      final scored = <(int, Manga)>[];
      final results = await Future.wait(
        candidates.map((m) async {
          try {
            final details = await SourceCache.mangaDetails(
              sourceId: source.id,
              mangaId: m.id,
              fetch: () => source.getMangaDetails(m.id),
            );
            return (m, details);
          } catch (_) {
            return (m, null);
          }
        }),
      );
      for (final (m, d) in results) {
        if (d == null) continue;
        final matches = (d.tags)
            .map((t) => t.toLowerCase())
            .where(myTags.contains)
            .length;
        if (matches > 0) scored.add((matches, m));
        // Cache tags for suggestions engine.
        if (d.tags.isNotEmpty) {
          DatabaseHelper.instance.saveMangaTags(m.id, d.tags);
        }
      }

      // Sort by tag overlap desc, then by title for stability.
      scored.sort((a, b) {
        final byTags = b.$1.compareTo(a.$1);
        return byTags != 0 ? byTags : a.$2.title.compareTo(b.$2.title);
      });

      final related = scored.take(6).map((s) => s.$2).toList();
      if (mounted) {
        setState(() => _relatedManga = related);
      }
    } catch (e) {
      // Ignore; the section simply shows nothing on failure.
    }
  }

  // Load the saved favorite status from the database.
  Future<void> _loadFavoriteStatus() async {
    final isFav = await DatabaseHelper.instance.getIsFavorite(widget.mangaId);
    if (!mounted) return;
    setState(() {
      _isFavorite = isFav;
      _isLoadingPreferences = false;
    });
  }

  // Toggle favorite status in the database and refresh the favorites tab.
  Future<void> _toggleFavorite() async {
    final newValue = !_isFavorite;
    await DatabaseHelper.instance.setFavorite(
      mangaId: widget.mangaId,
      title: widget.title,
      coverUrl: widget.imageUrl,
      sourceId: widget.sourceId,
      isFavorite: newValue,
    );
    if (!mounted) return;
    setState(() {
      _isFavorite = newValue;
    });
    bumpFavoritesRevision(ref);
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

  // Scroll the chapter list to the chapter you were last reading (or the
  // first chapter for a fresh manga).
  void _scrollToResumeChapter() {
    final sc = _sheetContentController;
    if (sc == null) return;
    final fraction = _chapters.length <= 1
        ? 1.0
        : (_resumeChapterIndex / (_chapters.length - 1)).clamp(0.0, 1.0);
    void animate() {
      if (sc.hasClients) {
        sc.animateTo(
          sc.position.maxScrollExtent * fraction,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      }
    }

    if (sc.hasClients) {
      animate();
    } else {
      // Retry on the next frame once the list is laid out.
      WidgetsBinding.instance.addPostFrameCallback((_) => animate());
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
          totalChapters: _resolvedTotalChapters,
        ),
      ),
    ).then((_) {
      // Reload real progress/bookmarks after returning from the reader.
      _loadProgress();
      _loadBookmarks();
    });
  }

  // The source's authoritative chapter count, falling back to the detail info
  // and finally to the loaded list length.
  int get _resolvedTotalChapters {
    if (_realTotalChapters > 0) return _realTotalChapters;
    if ((_details?.totalChapters ?? 0) > 0) return _details!.totalChapters;
    return _chapters.length;
  }

  // Number of chapters not yet read (based on last-read position).
  int get _unreadCount {
    if (_chapters.isEmpty) return 0;
    if (_lastReadChapter <= 0) return _chapters.length;
    final total = _resolvedTotalChapters;
    if (total <= 0) return 0;
    return (total - _lastReadChapter.round())
        .clamp(0, _chapters.length)
        .toInt();
  }

  // Index of the chapter to resume from, based on last-read position.
  // Fresh manga (no progress) opens the very first (oldest) chapter.
  int get _resumeChapterIndex {
    if (_chapters.isEmpty) return 0;
    if (_lastReadChapter <= 0) return _chapters.length - 1;

    // Chapters are ordered newest-first, so position = (total - index).
    final total = _resolvedTotalChapters;
    final lastReadInt = _lastReadChapter.round();
    final byPosition = total - lastReadInt;
    if (byPosition >= 0 && byPosition < _chapters.length) {
      return byPosition;
    }

    // Fallback: match by the chapter's name number.
    for (var i = 0; i < _chapters.length; i++) {
      final numParsed = double.tryParse(
        RegExp(
              r'(\d+(\.\d+)?)',
            ).firstMatch(_chapters[i].chapterNumber)?.group(1) ??
            '',
      );
      if (numParsed != null && numParsed.round() == lastReadInt) {
        return i;
      }
    }
    return _chapters.length - 1;
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
                AppPress(
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
                AppPress(
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Searching "$tagName" everywhere...'),
                      ),
                    );
                  },
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
                            unreadCount: _unreadCount,
                            showContinueButton:
                                _activeTab == 0 && _chapters.isNotEmpty,
                            hasRead: _lastReadChapter >= 0,
                            onContinuePressed: _openReader,
                            onBarTap: () {
                              final current = _sheetController.size;
                              if (current < 0.2) {
                                _animateSheetTo(0.5);
                                _scrollToResumeChapter();
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
                          const SliverToBoxAdapter(
                            child: SizedBox(height: 24),
                          ),
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
    final downloadedChapterIds =
        ref
            .watch(downloadedChaptersForMangaProvider(widget.mangaId))
            .valueOrNull ??
        const <String>{};

    if (_isLoadingChapters) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 80),
          child: Center(
            child: CircularProgressIndicator(color: Colors.white54),
          ),
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
          final isRead =
              _lastReadChapter >= 0 &&
              (_resolvedTotalChapters - index) <= _lastReadChapter;
          final isCurrent = index == _currentDisplayIndex;
          final downloaded = downloadedChapterIds.contains(ch.id);
          final isSelected = _selectedIds.contains(ch.id);

          return ListTile(
            key: ValueKey(ch.id),
            contentPadding: const EdgeInsets.symmetric(vertical: 2),
            shape: isSelected
                ? RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Colors.white, width: 1.5),
                  )
                : null,
            tileColor: isSelected ? const Color(0xFF2C2C2C) : null,
            title: Row(
              children: [
                if (isCurrent)
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: kAccentColor,
                      size: 20,
                    ),
                  ),
                Expanded(
                  child: Text(
                    ch.chapterNumber == 'Chapter'
                        ? ch.title
                        : 'Chapter ${ch.chapterNumber}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isRead ? Colors.grey : Colors.white,
                      fontWeight: isCurrent
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Text(
              isRead && downloaded
                  ? 'Read • Downloaded'
                  : isRead
                  ? 'Read'
                  : downloaded
                  ? 'Downloaded'
                  : (ch.releaseDate?.isNotEmpty ?? false
                        ? _formatChapterDate(ch.releaseDate!)
                        : ''),
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (downloaded)
                  const Padding(
                    padding: EdgeInsets.only(right: 10),
                    child: Icon(
                      Icons.sd_card_outlined,
                      color: Colors.white70,
                      size: 18,
                    ),
                  ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 18,
                  )
                else if (isRead)
                  const Icon(
                    Icons.check_circle_outline,
                    color: Colors.white70,
                    size: 18,
                  ),
              ],
            ),
            onTap: () {
              if (_selectionMode) {
                _toggleSelection(ch.id);
              } else {
                _openReader(chapterIndex: index);
              }
            },
            onLongPress: () => _enterSelection(ch.id),
          );
        }, childCount: _chapters.length),
      ),
    );
  }

  // The chapter index shown as "current" (green play icon). Uses the last-read
  // position from the DB when available; no icon when nothing has been read.
  int get _currentDisplayIndex {
    if (_lastReadChapter <= 0) return -1;
    final index = _resolvedTotalChapters - _lastReadChapter.round();
    return (index >= 0 && index < _chapters.length) ? index : -1;
  }

  // Formats an ISO chapter date as relative text for recent entries and a
  // human-readable date (e.g. "Aug 22, 2026") for older ones.
  String _formatChapterDate(String iso) {
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return '';
    final now = DateTime.now();
    final days = now.difference(DateTime(dt.year, dt.month, dt.day)).inDays;
    if (days == 0) return 'Today';
    if (days == 1) return 'Yesterday';
    if (days < 7) return '$days days ago';
    return DateFormat.yMMMd().format(dt);
  }

  void _enterSelection(String id) {
    setState(() {
      _selectionMode = true;
      _selectedIds.add(id);
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (!_selectedIds.add(id)) {
        _selectedIds.remove(id);
      }
      if (_selectedIds.isEmpty) _selectionMode = false;
    });
  }

  void _exitSelection() {
    setState(() {
      _selectedIds.clear();
      _selectionMode = false;
    });
  }

  // Adds every chapter between the min and max indices of the current
  // selection, then keeps just that contiguous range selected.
  void _selectChapterRange() {
    if (_chapters.isEmpty || _selectedIds.isEmpty) return;
    final indices = <int>[
      for (var i = 0; i < _chapters.length; i++)
        if (_selectedIds.contains(_chapters[i].id)) i,
    ];
    final minIndex = indices.reduce((a, b) => a < b ? a : b);
    final maxIndex = indices.reduce((a, b) => a > b ? a : b);
    setState(() {
      _selectedIds
        ..clear()
        ..addAll(
          _chapters
              .sublist(minIndex, maxIndex + 1)
              .map((c) => c.id),
        );
    });
  }

  // True when every selected chapter is in the "read" range.
  bool get _isAllSelectedRead {
    if (_selectedIds.isEmpty) return false;
    for (var i = 0; i < _chapters.length; i++) {
      if (!_selectedIds.contains(_chapters[i].id)) continue;
      final isRead =
          _lastReadChapter >= 0 &&
          (_resolvedTotalChapters - i) <= _lastReadChapter;
      if (!isRead) return false;
    }
    return true;
  }

  bool get _isSelectedDownloaded {
    final downloadedIds =
        ref.read(downloadedChaptersForMangaProvider(widget.mangaId)).valueOrNull;
    if (downloadedIds == null) return false;
    return _selectedIds.any(downloadedIds.contains);
  }

  void _toggleSelectedRead() {
    // Batch read/unread toggle — flips the last-read threshold so all
    // selected chapters fall on the opposite side. Newest chapter = highest
    // number; a chapter index i is read when it maps to a chapter number
    // <= _lastReadChapter.
    final selectedIndices = <int>[
      for (var i = 0; i < _chapters.length; i++)
        if (_selectedIds.contains(_chapters[i].id)) i,
    ];
    if (selectedIndices.isEmpty) return;

    final targetChapterNumbers = selectedIndices
        .map((i) => _resolvedTotalChapters - i)
        .toList();
    final double newThreshold = _isAllSelectedRead
        // Mark unread: drop threshold below the lowest (oldest) selected.
        ? (targetChapterNumbers.reduce((a, b) => a < b ? a : b) - 1).toDouble()
        // Mark read: raise threshold to cover the highest (newest) selected.
        : targetChapterNumbers.reduce((a, b) => a > b ? a : b).toDouble();

    setState(() {
      _lastReadChapter = newThreshold;
      _progressPercent = (_lastReadChapter / _resolvedTotalChapters) * 100;
    });
    DatabaseHelper.instance.saveMangaProgress(
      mangaId: widget.mangaId,
      title: widget.title,
      coverUrl: widget.imageUrl,
      sourceId: widget.sourceId,
      lastReadChapter: newThreshold,
      lastTrayTotalChapters: _resolvedTotalChapters,
    );
  }

  Future<void> _downloadSelectedChapters() async {
    final source = _source;
    if (source == null) return;
    final chapters =
        _chapters.where((c) => _selectedIds.contains(c.id)).toList();
    var success = 0;
    for (final ch in chapters) {
      try {
        final pages = await source.getPageUrls(ch.id);
        if (pages.isEmpty) continue;
        final saved = await ChapterDownloader.downloadChapter(
          mangaId: widget.mangaId,
          chapterId: ch.id,
          pages: pages,
          headers: source.headers,
        );
        if (saved == null || saved.isEmpty) continue;
        final dir = await ChapterDownloader.chapterDir(
          widget.mangaId,
          ch.id,
        );
        await DatabaseHelper.instance.addDownload(
          mangaId: widget.mangaId,
          chapterId: ch.id,
          chapterNumber: double.tryParse(ch.chapterNumber) ?? 0,
          chapterTitle: ch.title,
          pageCount: saved.length,
          localDir: dir.path,
          pageUrls: jsonEncode(pages),
        );
        success++;
      } catch (_) {
        // skip failed chapter, continue with the rest
      }
    }
    if (!mounted) return;
    bumpDownloadsRevision(ref);
    await DatabaseHelper.instance.upsertManga(
      mangaId: widget.mangaId,
      title: widget.title,
      coverUrl: widget.imageUrl,
      sourceId: widget.sourceId,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Downloaded $success chapter(s)')),
    );
  }

  Future<void> _deleteSelectedDownloads() async {
    for (final ch in _chapters) {
      if (!_selectedIds.contains(ch.id)) continue;
      await ChapterDownloader.removeChapterFiles(widget.mangaId, ch.id);
      await DatabaseHelper.instance.removeDownload(widget.mangaId, ch.id);
    }
    if (!mounted) return;
    bumpDownloadsRevision(ref);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Deleted selected downloads')),
    );
  }

  Widget _buildPagesGridSliver() {
    if (_isLoadingPages) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 80),
          child: Center(
            child: CircularProgressIndicator(color: Colors.white54),
          ),
        ),
      );
    }

    if (_previewPages.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
          child: Center(
            child: Text(
              _chapters.isEmpty
                  ? 'Start reading to see pages'
                  : 'No pages available',
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
                  child: Icon(
                    Icons.broken_image,
                    color: Colors.white38,
                    size: 24,
                  ),
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
          child: Center(
            child: CircularProgressIndicator(color: Colors.white54),
          ),
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
                ? Text(
                    bm.note!,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  )
                : const Text(
                    'No note',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
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
    if (_selectedIds.isNotEmpty) {
      return _buildContextualAppBar(context);
    }
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
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => _loadChapters(forceRefresh: true),
          ),
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

  // Contextual app bar shown while chapters are selected in the chapter list.
  Widget _buildContextualAppBar(BuildContext context) {
    final hasDownloaded = _isSelectedDownloaded;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: _exitSelection,
          ),
          const SizedBox(width: 4),
          Text(
            '${_selectedIds.length}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.format_line_spacing, color: Colors.white),
            tooltip: 'Select range',
            onPressed: _selectChapterRange,
          ),
          IconButton(
            icon: Icon(
              _isAllSelectedRead
                  ? Icons.visibility_off
                  : Icons.visibility,
              color: Colors.white,
            ),
            tooltip: 'Toggle read',
            onPressed: _toggleSelectedRead,
          ),
          if (hasDownloaded)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white),
              tooltip: 'Delete download',
              onPressed: _deleteSelectedDownloads,
            )
          else
            IconButton(
              icon: const Icon(Icons.download_rounded, color: Colors.white),
              tooltip: 'Download',
              onPressed: _downloadSelectedChapters,
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
          Stack(
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
              DownloadedMangaBadge(mangaId: widget.mangaId),
            ],
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
                        onTap: _toggleFavorite,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _isFavorite
                                ? const Color(0xFF3A3A3C)
                                : const Color(0xFF1E1E22),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _isFavorite
                                  ? Colors.white70
                                  : Colors.white24,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: _isFavorite
                                    ? Colors.redAccent
                                    : Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isFavorite ? 'Favorited' : 'Favorite',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
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
    // Prefer the API-declared chapter count; fall back to the fetched list.
    final totalChapters = _resolvedTotalChapters;
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
            _details?.sourceId == 'mock'
                ? 'Mock Source'
                : (_sourceName ?? 'Unknown'),
            icon: Icons.pets,
          ),
          _buildCardRow(
            'Author',
            _details?.author.isEmpty ?? true ? 'Unknown' : _details!.author,
          ),
          _buildCardRow(
            'Year',
            _details?.year.isEmpty ?? true ? '—' : _details!.year,
          ),
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
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
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
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.4,
            ),
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
    if (_relatedManga.isEmpty) return const SizedBox.shrink();
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
                      builder: (context) => RelatedMangaScreen(
                        title: 'Related manga',
                        relatedManga: _relatedManga,
                      ),
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
            children: _relatedManga.map((m) {
              return _buildRelatedCard(m);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildRelatedCard(Manga manga) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MangaDetailScreen(
              mangaId: manga.id,
              title: manga.title,
              imageUrl: manga.coverUrl,
              sourceId: manga.sourceId,
            ),
          ),
        );
      },
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: manga.coverUrl,
                    height: 120,
                    width: 100,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => Container(
                      height: 120,
                      width: 100,
                      color: const Color(0xFF2C2C2E),
                      child: const Icon(Icons.menu_book, color: Colors.white38),
                    ),
                  ),
                ),
                DownloadedMangaBadge(mangaId: manga.id, size: 20, iconSize: 12),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              manga.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetHeaderDelegate extends SliverPersistentHeaderDelegate {
  final bool isExpanded;
  final int activeTab;
  final double topPadding;
  final int unreadCount;
  final bool showContinueButton;
  final bool hasRead;
  final VoidCallback onContinuePressed;
  final VoidCallback onBarTap;
  final ValueChanged<int> onTabSelected;

  _SheetHeaderDelegate({
    required this.isExpanded,
    required this.activeTab,
    required this.topPadding,
    this.unreadCount = 0,
    this.showContinueButton = false,
    this.hasRead = false,
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
          left: 10,
          right: 10,
          top: isExpanded ? topPadding : 0,
        ),
        alignment: Alignment.center,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Chapter list tab (shows unread count when there are unread chapters).
            _buildTabIcon(
              Icons.format_list_bulleted,
              activeTab == 0,
              onTap: () => onTabSelected(0),
              badge: unreadCount > 0 ? _badge(unreadCount) : null,
            ),
            const SizedBox(width: 2),
            _buildTabIcon(
              Icons.grid_view_rounded,
              activeTab == 1,
              onTap: () => onTabSelected(1),
            ),
            const SizedBox(width: 2),
            _buildTabIcon(
              activeTab == 2
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              activeTab == 2,
              onTap: () => onTabSelected(2),
            ),
            const Spacer(),
            // Continue/Read action, only for the chapter list tab.
            if (showContinueButton) ...[
              _buildPrimaryButton(),
              const SizedBox(width: 6),
            ],
            if (isExpanded) ...[
              _buildTabIcon(Icons.search_rounded, false, onTap: () {}),
              const SizedBox(width: 2),
              _buildTabIcon(Icons.more_vert_rounded, false, onTap: () {}),
            ] else ...[
              _buildExpandButton(),
            ],
          ],
        ),
      ),
    );
  }

  // A single consistent, tappable tab icon with a circular active highlight.
  Widget _buildTabIcon(
    IconData icon,
    bool active, {
    VoidCallback? onTap,
    Widget? badge,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF2C2C2E) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(icon, color: active ? Colors.white : Colors.grey, size: 18),
            if (badge != null) Positioned(top: -3, right: -3, child: badge),
          ],
        ),
      ),
    );
  }

  // Compact unread-count badge in the app's red accent.
  Widget _badge(int count) {
    return Container(
      padding: const EdgeInsets.all(3),
      constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Colors.redAccent,
        shape: BoxShape.circle,
      ),
      child: Text(
        count > 9 ? '9+' : '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Subtle chevron that expands the tray.
  Widget _buildExpandButton() {
    return GestureDetector(
      onTap: onBarTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2E),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(
          Icons.keyboard_arrow_up,
          color: Colors.white,
          size: 16,
        ),
      ),
    );
  }

  // Primary Continue/Read action pill that lives on the tray.
  Widget _buildPrimaryButton() {
    final label = hasRead ? 'Continue' : 'Read';
    final showUnread = unreadCount > 0 && hasRead;
    return GestureDetector(
      onTap: onContinuePressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white12, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (showUnread) ...[
              const SizedBox(width: 6),
              Text(
                '• $unreadCount',
                style: const TextStyle(
                  color: Color(0xFFE57373),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
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
        oldDelegate.topPadding != topPadding ||
        oldDelegate.unreadCount != unreadCount ||
        oldDelegate.showContinueButton != showContinueButton ||
        oldDelegate.hasRead != hasRead;
  }
}
