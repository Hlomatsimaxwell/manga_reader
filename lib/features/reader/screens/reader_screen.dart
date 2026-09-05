import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/database/source_cache.dart';
import 'package:manga_reader/data/providers/sources_provider.dart';
import 'package:manga_reader/data/models/chapter.dart';
import 'package:manga_reader/data/models/manga_source.dart';
import 'package:manga_reader/features/history/providers/history_provider.dart';
import 'package:manga_reader/features/library/providers/downloads_provider.dart';
import 'package:manga_reader/features/settings/screens/settings_screen.dart';
import '../services/chapter_downloader.dart';

// Reading modes (Kotatsu-style).
enum ReadingMode { standard, rightToLeft, vertical, webtoon }

class ReaderScreen extends ConsumerStatefulWidget {
  final List<Chapter> allChapters;
  final int initialChapterIndex;
  final int initialPageIndex;
  final String mangaId;
  final String? sourceId;
  final String? mangaTitle;
  final String? mangaCoverUrl;
  final int totalChapters;

  const ReaderScreen({
    super.key,
    required this.allChapters,
    required this.initialChapterIndex,
    this.initialPageIndex = 0,
    required this.mangaId,
    this.sourceId,
    this.mangaTitle,
    this.mangaCoverUrl,
    this.totalChapters = 0,
  });

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  final ScrollController _scrollController = ScrollController();
  PageController _pageController = PageController();
  final List<String> _pages = [];
  final List<int> _loadedChapterIndices = [];

  int _currentChapterIndex = 0;
  bool _isLoadingNextChapter = false;
  bool _hasMoreChapters = true;
  bool _showControls = true;
  bool _isSaving = false;
  bool _needsRestore = false;
  int? _pendingJumpPage;
  final Set<String> _bookmarkedKeys = {};

  String _bookmarkKey(String chapterId, int pageIndex) =>
      '$chapterId:$pageIndex';

  bool get _isCurrentPageBookmarked {
    if (_currentChapterIndex < 0) return false;
    return _bookmarkedKeys.contains(
      _bookmarkKey(
        widget.allChapters[_currentChapterIndex].id,
        _currentPageIndex,
      ),
    );
  }

  ReadingMode _readingMode = ReadingMode.vertical;

  // Settings state.
  bool _useTwoPagesLayout = false;
  bool _autoScroll = false;
  bool _rotateScreen = false;
  Timer? _autoScrollTimer;

  // Color correction.
  double _brightness = 100;
  double _contrast = 100;
  double _sepia = 0;

  // Chapter downloads.
  final Set<String> _downloadedChapters = {};
  final Map<String, _ChapterDownloadTask> _activeDownloads = {};

  // Per-page bookkeeping: pages belong to a chapter index, and each page may
  // have a local file path when its chapter has been downloaded.
  final List<int> _pagesChapters = [];
  final List<String?> _pageFiles = [];

  // Refresh callback for the open chapter tray sheet.
  bool _trayOpen = false;
  VoidCallback? _trayRefresh;

  void _refreshTray() {
    if (_trayOpen) _trayRefresh?.call();
  }

  bool get _isHorizontal =>
      _readingMode == ReadingMode.standard ||
      _readingMode == ReadingMode.rightToLeft;

  @override
  void initState() {
    super.initState();
    _currentChapterIndex = widget.initialChapterIndex;
    _needsRestore = widget.initialPageIndex > 0;
    _loadPrefs();
    _loadBookmarks();
    _loadDownloads().then((_) => _loadChapter(_currentChapterIndex));

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 800 &&
          !_isLoadingNextChapter &&
          _hasMoreChapters) {
        _loadNextChapter();
      }
    });
  }

  // --- PERSISTED READER SETTINGS ---

  // Reader settings are stored per manga so changing them for one title never
  // affects another.
  String _prefKey(String suffix) => '${widget.mangaId}_$suffix';

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final modeName = prefs.getString(_prefKey('reader_mode'));
    final mode = ReadingMode.values.firstWhere(
      (m) => m.name == modeName,
      orElse: () => ReadingMode.vertical,
    );
    final rotateScreen =
        prefs.getBool(_prefKey('reader_rotate_screen')) ?? false;

    if (!mounted) return;
    setState(() {
      _readingMode = mode;
      _useTwoPagesLayout = prefs.getBool(_prefKey('reader_two_pages')) ?? false;
      _rotateScreen = rotateScreen;
      _brightness = prefs.getDouble(_prefKey('reader_brightness')) ?? 100;
      _contrast = prefs.getDouble(_prefKey('reader_contrast')) ?? 100;
      _sepia = prefs.getDouble(_prefKey('reader_sepia')) ?? 0;
    });

    if (_useTwoPagesLayout) {
      _recreatePageController();
    }

    if (rotateScreen) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  }

  void _saveReaderMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey('reader_mode'), _readingMode.name);
  }

  void _saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  void _saveColorCorrection() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_prefKey('reader_brightness'), _brightness);
    await prefs.setDouble(_prefKey('reader_contrast'), _contrast);
    await prefs.setDouble(_prefKey('reader_sepia'), _sepia);
  }

  void _recreatePageController() {
    _pageController.dispose();
    _pageController = PageController(
      viewportFraction: _useTwoPagesLayout ? 0.5 : 1.0,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pageController.dispose();
    _autoScrollTimer?.cancel();
    super.dispose();
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  int get _currentPageIndex {
    if (_pages.isEmpty) return 0;
    if (_isHorizontal && _pageController.hasClients) {
      return _pageController.page?.round().clamp(0, _pages.length - 1) ?? 0;
    } else if (!_isHorizontal && _scrollController.hasClients) {
      const perPage = 600.0;
      return (_scrollController.offset / perPage).floor().clamp(
        0,
        _pages.length - 1,
      );
    }
    return 0;
  }

  void _jumpToPage(int pageIndex) {
    if (_pages.isEmpty) return;
    final idx = pageIndex.clamp(0, _pages.length - 1);
    if (_isHorizontal) {
      if (_pageController.hasClients) _pageController.jumpToPage(idx);
    } else {
      if (_scrollController.hasClients) {
        final extent = _scrollController.position.maxScrollExtent;
        _scrollController.jumpTo((idx * 600.0).clamp(0.0, extent));
      }
    }
    setState(() {});
  }

  void _seekFromProgress(double fraction) {
    if (_pages.isEmpty) return;
    final clamped = fraction.clamp(0.0, 1.0);
    final page = (clamped * (_pages.length - 1)).round();
    _jumpToPage(page);
  }

  Widget _buildProgressTrack() {
    final total = _pages.isEmpty ? 1 : _pages.length;
    final current = (_currentPageIndex + 1).clamp(1, total);
    final progress = total > 1 ? (current - 1) / (total - 1) : 0.0;
    final dotCount = total.clamp(1, 12);

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) => _seekFromProgress(
            details.localPosition.dx / constraints.maxWidth,
          ),
          onHorizontalDragUpdate: (details) => _seekFromProgress(
            details.localPosition.dx / constraints.maxWidth,
          ),
          child: CustomPaint(
            size: Size(constraints.maxWidth, 36),
            painter: _DottedProgressPainter(
              progress: progress,
              dotCount: dotCount,
            ),
          ),
        );
      },
    );
  }

  void _restorePosition() {
    if (!_needsRestore || _pages.isEmpty) return;
    _needsRestore = false;
    _jumpToPage(widget.initialPageIndex);
  }

  void _setReadingMode(ReadingMode mode) {
    if (mode == _readingMode) return;
    final approxPage = _currentPageIndex;
    if (_autoScrollTimer != null) {
      _autoScrollTimer!.cancel();
      _autoScrollTimer = null;
    }
    setState(() {
      _readingMode = mode;
      _autoScroll = false;
    });
    _saveReaderMode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _jumpToPage(approxPage);
    });
  }

  // --- SETTINGS ACTIONS ---

  void _toggleTwoPages(bool value) {
    if (value == _useTwoPagesLayout) return;
    final lastApprox = _currentPageIndex;
    setState(() {
      _useTwoPagesLayout = value;
      _pageController.dispose();
      _pageController = PageController(viewportFraction: value ? 0.5 : 1.0);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_pageController.hasClients || _pages.isEmpty) return;
      _pageController.jumpToPage(lastApprox.clamp(0, _pages.length - 1));
    });
    _saveBool(_prefKey('reader_two_pages'), value);
  }

  void _toggleRotateScreen(bool value) {
    setState(() => _rotateScreen = value);
    if (value) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    }
    _saveBool(_prefKey('reader_rotate_screen'), value);
  }

  void _toggleAutoScroll(bool value) {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
    if (!value) {
      setState(() => _autoScroll = false);
      return;
    }
    // Auto-scroll only makes sense in a continuous (vertical) reading mode.
    if (_isHorizontal) {
      _setReadingMode(ReadingMode.webtoon);
    }
    setState(() => _autoScroll = true);
    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 33), (_) {
      if (!mounted || !_scrollController.hasClients) return;
      final position = _scrollController.position;
      if (position.pixels >= position.maxScrollExtent - 2) {
        _autoScrollTimer?.cancel();
        _autoScrollTimer = null;
        setState(() => _autoScroll = false);
        return;
      }
      _scrollController.jumpTo(position.pixels + 2);
    });
  }

  void _showColorCorrectionDialog() {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1C1C1E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'Color correction',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildFilterSlider(
                  'Brightness',
                  _brightness,
                  (v) => setDialogState(() => _brightness = v),
                ),
                _buildFilterSlider(
                  'Contrast',
                  _contrast,
                  (v) => setDialogState(() => _contrast = v),
                ),
                _buildFilterSlider(
                  'Sepia',
                  _sepia,
                  (v) => setDialogState(() => _sepia = v),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  setDialogState(() {
                    _brightness = 100;
                    _contrast = 100;
                    _sepia = 0;
                  });
                  if (mounted) setState(() {});
                  _saveColorCorrection();
                },
                child: const Text(
                  'Reset',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {});
                  _saveColorCorrection();
                  Navigator.pop(context);
                },
                child: const Text(
                  'Done',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterSlider(
    String label,
    double value,
    ValueChanged<double> onChanged,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              activeTrackColor: Colors.white,
              inactiveTrackColor: Colors.white12,
              thumbColor: Colors.white,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayColor: Colors.white.withValues(alpha: 0.12),
            ),
            child: Slider(min: 0, max: 200, value: value, onChanged: onChanged),
          ),
        ),
      ],
    );
  }

  Future<void> _saveCurrentPage() async {
    if (_pages.isEmpty) return;
    final pageIndex = _currentPageIndex.clamp(0, _pages.length - 1);
    final url = _pages[pageIndex];

    try {
      final headers = ref.read(currentSourceProvider).headers;
      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      Directory directory;
      try {
        directory =
            await getDownloadsDirectory() ??
            await getApplicationDocumentsDirectory();
      } catch (_) {
        directory = await getApplicationDocumentsDirectory();
      }

      final ext = _imageExtension(url, response.headers['content-type']);
      final file = File('${directory.path}/page_${pageIndex + 1}.$ext');
      await file.writeAsBytes(response.bodyBytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Page saved to ${file.path}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to save page')));
      }
    }
  }

  String _imageExtension(String url, String? contentType) {
    if (contentType != null) {
      if (contentType.contains('png')) return 'png';
      if (contentType.contains('jpeg')) return 'jpg';
      if (contentType.contains('webp')) return 'webp';
      if (contentType.contains('gif')) return 'gif';
    }
    final dotIndex = url.lastIndexOf('.');
    if (dotIndex != -1) {
      final ext = url.substring(dotIndex + 1).split('?').first.toLowerCase();
      if (RegExp(r'^[a-z0-9]{1,5}$').hasMatch(ext)) return ext;
    }
    return 'png';
  }

  // --- CHAPTER NAVIGATION ---

  void _changeChapterExplicitly(int newIndex) {
    setState(() {
      _currentChapterIndex = newIndex;
      _pages.clear();
      _pagesChapters.clear();
      _pageFiles.clear();
      _loadedChapterIndices.clear();
      _hasMoreChapters = true;
    });
    _loadChapter(_currentChapterIndex);
  }

  void _showChapterList() {
    final currentIndex = _currentChapterIndex;
    var listView = 'list';
    var didJump = false;

    MangaSource? source;
    if (widget.sourceId != null) {
      source = getSourceBySourceId(widget.sourceId!);
    }
    source ??= ref.read(currentSourceProvider);
    final headers = source?.headers;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          builder: (context, sheetController) {
            return StatefulBuilder(
              builder: (context, setSheetState) {
                _trayOpen = true;
                _trayRefresh = () => setSheetState(() {});
                if (!didJump) {
                  _jumpToCurrentInSheet(sheetController, currentIndex, 72, 0);
                  didJump = true;
                }

                return Column(
                  children: [
                    Center(
                      child: Container(
                        width: 32,
                        height: 4,
                        margin: const EdgeInsets.only(top: 12, bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.white38,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    _buildChapterSheetHeader(
                      listView,
                      setSheetState,
                      _jumpToCurrentInSheetFor(sheetController, currentIndex),
                    ),
                    Expanded(
                      child: switch (listView) {
                        'grid' => _buildPageGridView(
                          sheetController,
                          currentIndex,
                          headers,
                        ),
                        'bookmark' => _buildBookmarksView(
                          sheetController,
                          headers,
                          onRefresh: () => setSheetState(() {}),
                        ),
                        'download' => _buildDownloadsView(sheetController),
                        _ => _buildChapterListView(
                          sheetController,
                          currentIndex,
                        ),
                      },
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    ).then((_) {
      _trayOpen = false;
      _trayRefresh = null;
    });
  }

  // Retries until the sheet's scroll controller is attached, then centers the
  // active chapter.
  void _jumpToCurrentInSheet(
    ScrollController controller,
    int index,
    double itemExtent,
    int attempt,
  ) {
    if (attempt > 6) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!controller.hasClients) {
        _jumpToCurrentInSheet(controller, index, itemExtent, attempt + 1);
        return;
      }
      final viewDim = controller.position.viewportDimension;
      final target = (index * itemExtent - viewDim / 2).clamp(
        0.0,
        controller.position.maxScrollExtent,
      );
      controller.jumpTo(target);
    });
  }

  void Function() _jumpToCurrentInSheetFor(
    ScrollController controller,
    int index,
  ) {
    return () {
      if (!controller.hasClients) return;
      final viewDim = controller.position.viewportDimension;
      final target = (index * 72 - viewDim / 2).clamp(
        0.0,
        controller.position.maxScrollExtent,
      );
      controller.jumpTo(target);
    };
  }

  Widget _buildChapterSheetHeader(
    String listView,
    StateSetter setSheetState,
    VoidCallback scrollToCurrent,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          _buildViewToggle(
            icon: Icons.format_list_bulleted,
            selected: listView == 'list',
            onTap: () => setSheetState(() => listView = 'list'),
          ),
          const SizedBox(width: 10),
          _buildViewToggle(
            icon: Icons.grid_view,
            selected: listView == 'grid',
            onTap: () => setSheetState(() => listView = 'grid'),
          ),
          const SizedBox(width: 10),
          _buildViewToggle(
            icon: Icons.bookmark_outline,
            selected: listView == 'bookmark',
            onTap: () => setSheetState(() => listView = 'bookmark'),
          ),
          const SizedBox(width: 10),
          _buildViewToggle(
            icon: Icons.download_for_offline_outlined,
            selected: listView == 'download',
            onTap: () => setSheetState(() => listView = 'download'),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Current chapter',
            icon: const Icon(Icons.my_location, color: Colors.white54),
            onPressed: scrollToCurrent,
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggle({
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 20,
          color: selected ? Colors.black : Colors.white70,
        ),
      ),
    );
  }

  Widget _buildChapterListView(ScrollController controller, int currentIndex) {
    return ListView.builder(
      controller: controller,
      itemExtent: 72,
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: widget.allChapters.length,
      itemBuilder: (context, index) {
        final chapter = widget.allChapters[index];
        final isCurrent = index == currentIndex;
        return Container(
          color: isCurrent ? Colors.white10 : Colors.transparent,
          child: ListTile(
            dense: true,
            title: Row(
              children: [
                Icon(
                  Icons.play_arrow,
                  color: isCurrent ? Colors.green : Colors.transparent,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    chapter.title.isEmpty
                        ? 'Chapter ${chapter.chapterNumber}'
                        : chapter.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isCurrent ? Colors.white : Colors.white70,
                      fontSize: 14,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Text(
              _chapterSubtitle(chapter),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
            trailing: _buildChapterDownloadControl(chapter),
            onTap: () {
              Navigator.pop(context);
              _changeChapterExplicitly(index);
            },
          ),
        );
      },
    );
  }

  Widget _buildChapterDownloadControl(Chapter chapter) {
    final active = _activeDownloads[chapter.id];
    if (active != null) {
      final pct = active.total == 0
          ? 0
          : (active.done / active.total * 100).round();
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$pct%',
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white54, size: 18),
            tooltip: 'Cancel download',
            onPressed: active.cancel,
          ),
        ],
      );
    }
    final downloaded = _downloadedChapters.contains(chapter.id);
    return IconButton(
      tooltip: downloaded ? 'Remove download' : 'Download chapter',
      icon: Icon(
        downloaded ? Icons.cloud_done : Icons.download_for_offline_outlined,
        color: downloaded ? _activeGreen : Colors.white38,
        size: 22,
      ),
      onPressed: () => _toggleChapterDownload(chapter),
    );
  }

  Widget _buildPageGridView(
    ScrollController controller,
    int currentIndex,
    Map<String, String>? headers,
  ) {
    if (_pages.isEmpty) {
      return const Center(
        child: Text(
          'Pages loading...',
          style: TextStyle(color: Colors.white54, fontSize: 14),
        ),
      );
    }

    return GridView.builder(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.58,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _pages.length,
      itemBuilder: (context, index) {
        return _buildPageThumbCard(
          imageUrl: _pages[index],
          badgeText: '${index + 1}',
          headers: headers,
          localPath: _pageFiles[index],
          onTap: () => _openPage(index),
        );
      },
    );
  }

  void _openPage(int pageIndex) {
    Navigator.pop(context);
    _jumpToPage(pageIndex);
  }

  Widget _buildBookmarksView(
    ScrollController controller,
    Map<String, String>? headers, {
    required VoidCallback onRefresh,
  }) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DatabaseHelper.instance.getBookmarks(widget.mangaId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text(
              'Failed to load bookmarks',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
          );
        }
        final bookmarks = snapshot.data ?? const [];
        if (bookmarks.isEmpty) {
          return const Center(
            child: Text(
              'No bookmarks yet',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
          );
        }

        // Group bookmarks by chapter.
        final grouped = <String, List<Map<String, dynamic>>>{};
        String titleFor(Map<String, dynamic> bm) =>
            bm['chapterTitle'] as String? ?? '';
        for (final bm in bookmarks) {
          final key = (bm['chapterId'] as String?) ?? titleFor(bm);
          grouped.putIfAbsent(key, () => []).add(bm);
        }

        final totalPages = _pages.isEmpty ? 0 : _pages.length;

        return SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: grouped.entries.map((entry) {
              final isCurrentChapter =
                  entry.key == widget.allChapters[_currentChapterIndex].id;
              final chapterNum = entry.value.first['chapterTitle'] ?? '';
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                    child: Text(
                      'Chapter $chapterNum',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 0.58,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                    itemCount: entry.value.length,
                    itemBuilder: (context, index) {
                      final bm = entry.value[index];
                      final pageIndex = (bm['pageIndex'] as int?) ?? 0;
                      final percent = isCurrentChapter && totalPages > 1
                          ? ((pageIndex / totalPages) * 100).round()
                          : null;
                      return _buildPageThumbCard(
                        imageUrl: bm['pageUrl'] as String? ?? '',
                        badgeText: percent != null
                            ? '$percent%'
                            : '${pageIndex + 1}',
                        headers: headers,
                        onTap: () => _openBookmark(bm),
                        onLongPress: () => _removeBookmark(bm, onRefresh),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                ],
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildDownloadsView(ScrollController controller) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DatabaseHelper.instance.getDownloads(widget.mangaId),
      builder: (context, snapshot) {
        final rows = snapshot.data ?? const [];
        if (rows.isEmpty) {
          return const Center(
            child: Text(
              'No downloaded chapters yet',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
          );
        }
        return ListView.builder(
          controller: controller,
          padding: const EdgeInsets.only(bottom: 24),
          itemCount: rows.length,
          itemBuilder: (context, index) {
            final row = rows[index];
            final chapterId = row['chapterId'] as String? ?? '';
            final title = row['chapterTitle'] as String? ?? '';
            final chapterNumber = ((row['chapterNumber'] as num?) ?? 0)
                .toDouble();
            final pageCount = (row['pageCount'] as int?) ?? 0;
            final downloadedAt = row['downloadedAt'] as String? ?? '';
            return ListTile(
              dense: true,
              leading: const Icon(
                Icons.offline_pin,
                color: _activeGreen,
                size: 22,
              ),
              title: Text(
                title.isEmpty
                    ? 'Chapter ${_formatChapterNumber(chapterNumber)}'
                    : title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              subtitle: Text(
                '$pageCount pages • downloaded ${_formatChapterDate(downloadedAt)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
              trailing: IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.white38,
                  size: 20,
                ),
                tooltip: 'Remove download',
                onPressed: () => _confirmRemoveDownload(chapterId, title),
              ),
              onTap: () {
                Navigator.pop(context);
                final matched = widget.allChapters.indexWhere(
                  (c) => c.id == chapterId,
                );
                if (matched != -1) {
                  _pendingJumpPage = 0;
                  _changeChapterExplicitly(matched);
                }
              },
            );
          },
        );
      },
    );
  }

  String _formatChapterNumber(double number) {
    if (number == number.roundToDouble()) {
      return number.toInt().toString();
    }
    return number.toStringAsFixed(
      number == number.truncateToDouble() ? 0 : _decimalPlaces(number),
    );
  }

  int _decimalPlaces(double number) {
    final s = number.toString();
    final dot = s.indexOf('.');
    return dot == -1 ? 0 : s.length - dot - 1;
  }

  Widget _buildPageThumbCard({
    required String imageUrl,
    required String badgeText,
    required Map<String, String>? headers,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
    String? localPath,
  }) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: localPath != null && File(localPath).existsSync()
                  ? Image.file(
                      File(localPath),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) => Container(
                        color: const Color(0xFF2C2C2E),
                        child: const Icon(
                          Icons.menu_book,
                          color: Colors.white38,
                          size: 20,
                        ),
                      ),
                    )
                  : CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      httpHeaders: headers,
                      errorWidget: (context, url, error) => Container(
                        color: const Color(0xFF2C2C2E),
                        child: const Icon(
                          Icons.menu_book,
                          color: Colors.white38,
                          size: 20,
                        ),
                      ),
                    ),
            ),
          ),
          Positioned(
            bottom: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: const BoxDecoration(
                color: Colors.black87,
                shape: BoxShape.circle,
              ),
              child: Text(
                badgeText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _removeBookmark(
    Map<String, dynamic> bookmark,
    VoidCallback onRefresh,
  ) async {
    final id = bookmark['id'] as int?;
    if (id == null) return;

    final pageIndex = (bookmark['pageIndex'] as int?) ?? 0;
    final chapterTitle = bookmark['chapterTitle'] ?? '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2E),
        title: const Text(
          'Remove bookmark?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Chapter $chapterTitle • Page ${pageIndex + 1}',
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
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await DatabaseHelper.instance.deleteBookmark(id);
    final key = _bookmarkKey(bookmark['chapterId'] as String? ?? '', pageIndex);
    if (mounted) {
      setState(() => _bookmarkedKeys.remove(key));
    }
    onRefresh();
  }

  void _openBookmark(Map<String, dynamic> bookmark) {
    final chapterId = bookmark['chapterId'] as String?;
    final pageIndex = (bookmark['pageIndex'] as int?) ?? 0;
    final index = chapterId == null
        ? -1
        : widget.allChapters.indexWhere((c) => c.id == chapterId);

    Navigator.pop(context);
    if (index != -1) {
      _pendingJumpPage = pageIndex;
      _changeChapterExplicitly(index);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Chapter not found')));
    }
  }

  String _chapterSubtitle(Chapter chapter) {
    final num = chapter.chapterNumber.isNotEmpty
        ? '#${chapter.chapterNumber}'
        : '';
    final date = _formatChapterDate(chapter.releaseDate);
    final group = chapter.scanlator.isNotEmpty ? chapter.scanlator : '';
    return [num, date, group].where((p) => p.isNotEmpty).join(' • ');
  }

  String _formatChapterDate(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
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
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  // --- SETTINGS SHEET ---

  void _showSettingsSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF17171A),
      barrierColor: Colors.black54,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.88,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'More',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Color(0xFF232328),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white70,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Quick actions.
                      Row(
                        children: [
                          Expanded(
                            child: _buildQuickActionTile(
                              icon: Icons.download,
                              label: 'Save page',
                              onTap: _saveCurrentPage,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildQuickActionTile(
                              icon: _isCurrentPageBookmarked
                                  ? Icons.bookmark
                                  : Icons.bookmark_outline,
                              label: _isCurrentPageBookmarked
                                  ? 'Remove bookmark'
                                  : 'Add bookmark',
                              accent: _isCurrentPageBookmarked,
                              onTap: () async {
                                await _toggleBookmark();
                                if (context.mounted) setSheetState(() {});
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),

                      _buildSectionHeader('Reading mode'),
                      const SizedBox(height: 10),
                      _buildReadModeSelector(),
                      const SizedBox(height: 22),

                      _buildSectionHeader('Options'),
                      const SizedBox(height: 10),
                      _buildSettingsCard(
                        children: [
                          SwitchListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                            ),
                            activeTrackColor: _activeGreen,
                            activeThumbColor: Colors.white,
                            inactiveTrackColor: Colors.white12,
                            inactiveThumbColor: Colors.white54,
                            dense: true,
                            title: _tileText('Two pages on landscape'),
                            subtitle: _tileSubtext('Experimental'),
                            value: _useTwoPagesLayout,
                            onChanged: _toggleTwoPages,
                          ),
                          _cardDivider(),
                          SwitchListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                            ),
                            activeTrackColor: _activeGreen,
                            activeThumbColor: Colors.white,
                            inactiveTrackColor: Colors.white12,
                            inactiveThumbColor: Colors.white54,
                            dense: true,
                            title: _tileText('Rotate screen'),
                            subtitle: _tileSubtext(
                              _rotateScreen
                                  ? 'Landscape orientation'
                                  : 'Rotate to landscape',
                            ),
                            value: _rotateScreen,
                            onChanged: _toggleRotateScreen,
                          ),
                          _cardDivider(),
                          SwitchListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                            ),
                            activeTrackColor: _activeGreen,
                            activeThumbColor: Colors.white,
                            inactiveTrackColor: Colors.white12,
                            inactiveThumbColor: Colors.white54,
                            dense: true,
                            title: _tileText('Automatic scroll'),
                            subtitle: _tileSubtext(
                              'Continuous vertical scroll',
                            ),
                            value: _autoScroll,
                            onChanged: _toggleAutoScroll,
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),

                      _buildSectionHeader('Tools'),
                      const SizedBox(height: 10),
                      _buildSettingsCard(
                        children: [
                          _iconTile(
                            icon: Icons.palette_outlined,
                            title: 'Color correction',
                            subtitle: 'Brightness, contrast, sepia',
                            chevron: true,
                            onTap: _showColorCorrectionDialog,
                          ),
                          _cardDivider(),
                          _iconTile(
                            icon: Icons.settings_outlined,
                            title: 'Settings',
                            subtitle: 'App preferences',
                            chevron: true,
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SettingsScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildQuickActionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool accent = false,
  }) {
    final bgColor = accent ? const Color(0xFF2E4A2B) : const Color(0xFF232328);
    final fgColor = accent ? const Color(0xFF7CE38B) : Colors.white;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: accent
                ? _activeGreen.withValues(alpha: 0.4)
                : Colors.white10,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: fgColor, size: 26),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: fgColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadModeSelector() {
    const modes = [
      (ReadingMode.standard, Icons.menu_book, 'Standard'),
      (ReadingMode.rightToLeft, Icons.import_contacts, 'R-to-L'),
      (ReadingMode.vertical, Icons.phone_android, 'Vertical'),
      (ReadingMode.webtoon, Icons.view_stream, 'Webtoon'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.4,
          children: modes.map((mode) {
            final isSelected = _readingMode == mode.$1;
            return GestureDetector(
              onTap: () => _setReadingMode(mode.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [Color(0xFF4CAF50), Color(0xFF388E3C)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isSelected ? null : const Color(0xFF232328),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? Colors.transparent : Colors.white10,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      mode.$2,
                      color: isSelected ? Colors.white : Colors.white70,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        mode.$3,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (isSelected)
                      const Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 16,
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        const Text(
          'The chosen configuration will be remembered for this manga.',
          style: TextStyle(color: Colors.white38, fontSize: 11),
        ),
      ],
    );
  }

  static const Color _activeGreen = Color(0xFF4CAF50);

  Widget _buildSectionHeader(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: Colors.white54,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildSettingsCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF232328),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }

  Widget _cardDivider() => const Divider(height: 1, color: Color(0xFF3A3A40));

  Widget _tileText(String text) =>
      Text(text, style: const TextStyle(color: Colors.white, fontSize: 14));

  Widget _tileSubtext(String text) =>
      Text(text, style: const TextStyle(color: Colors.white38, fontSize: 12));

  Widget _iconTile({
    required IconData icon,
    required String title,
    String? subtitle,
    bool chevron = false,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      leading: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: Color(0xFF2F2F36),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white70, size: 20),
      ),
      title: _tileText(title),
      subtitle: subtitle == null ? null : _tileSubtext(subtitle),
      trailing: chevron
          ? const Icon(Icons.chevron_right, color: Colors.white38)
          : null,
      onTap: onTap,
    );
  }

  Future<void> _loadChapter(int chapterIndex) async {
    if (_loadedChapterIndices.contains(chapterIndex)) return;

    final chapter = widget.allChapters[chapterIndex];
    MangaSource? source;
    if (widget.sourceId != null) {
      source = getSourceBySourceId(widget.sourceId!);
    }
    source ??= ref.read(currentSourceProvider);

    if (source == null) return;
    final src = source;

    try {
      final List<String> newPages;
      if (_downloadedChapters.contains(chapter.id)) {
        // Offline-first: use the page URLs persisted when the chapter was
        // downloaded so no network is needed to open it.
        final download = await DatabaseHelper.instance.getDownload(
          widget.mangaId,
          chapter.id,
        );
        final stored = download?['pageUrls'];
        final storedList = stored is String && stored.isNotEmpty
            ? (jsonDecode(stored) as List).cast<String>()
            : null;
        if (storedList != null && storedList.isNotEmpty) {
          newPages = storedList;
        } else {
          // Legacy download (pre page-URL caching) -> network fallback.
          newPages = await SourceCache.pageUrls(
            sourceId: src.id,
            chapterId: chapter.id,
            fetch: () => src.getPageUrls(chapter.id),
          );
        }
      } else {
        newPages = await SourceCache.pageUrls(
          sourceId: src.id,
          chapterId: chapter.id,
          fetch: () => src.getPageUrls(chapter.id),
        );
      }
      if (!mounted) return;

      List<String?>? locals;
      if (_downloadedChapters.contains(chapter.id)) {
        locals = await ChapterDownloader.localPathsForChapter(
          mangaId: widget.mangaId,
          chapterId: chapter.id,
          pages: newPages,
        );
        if (!mounted) return;
      }

      setState(() {
        _pages.addAll(newPages);
        _pagesChapters.addAll(newPages.map((_) => chapterIndex));
        if (locals != null) {
          _pageFiles.addAll(locals);
        } else {
          _pageFiles.addAll(newPages.map((_) => null));
        }
        _loadedChapterIndices.add(chapterIndex);
      });
      if (_needsRestore) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _restorePosition());
      } else if (_pendingJumpPage != null) {
        final target = _pendingJumpPage!;
        _pendingJumpPage = null;
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _jumpToPage(target),
        );
      }
    } catch (e) {
      debugPrint('Error loading chapter: $e');
    }
  }

  Future<void> _loadNextChapter() async {
    final nextIndex = _currentChapterIndex - 1;
    if (nextIndex < 0) {
      setState(() => _hasMoreChapters = false);
      return;
    }
    setState(() => _isLoadingNextChapter = true);
    _currentChapterIndex = nextIndex;
    await _loadChapter(_currentChapterIndex);
    if (mounted) {
      setState(() => _isLoadingNextChapter = false);
    }
  }

  Future<void> _saveCascadingReadProgress() async {
    if (_loadedChapterIndices.isEmpty || _isSaving) return;
    _isSaving = true;

    final currentChapter = widget.allChapters[_currentChapterIndex];
    final currentIndex = _currentChapterIndex;

    final position = widget.totalChapters > 0
        ? (widget.totalChapters - currentIndex).toDouble()
        : null;
    final readValue = position;
    final markChapterNum =
        position ??
        (() {
          for (final s in [
            currentChapter.chapterNumber,
            currentChapter.title,
          ]) {
            final m = RegExp(r'(\d+(\.\d+)?)').firstMatch(s);
            if (m != null) {
              final n = double.tryParse(m.group(1)!);
              if (n != null) return n;
            }
          }
          return null;
        })();

    if (readValue != null && readValue >= 0) {
      await DatabaseHelper.instance.markChapterAsRead(
        widget.mangaId,
        currentChapter.id,
        markChapterNum!,
      );

      await DatabaseHelper.instance.saveMangaProgress(
        mangaId: widget.mangaId,
        title: widget.mangaTitle ?? 'Unknown',
        coverUrl: widget.mangaCoverUrl,
        sourceId: widget.sourceId,
        totalChapters: widget.totalChapters,
        lastReadChapter: readValue,
        lastReadPage: _pages.isEmpty ? 0 : _currentPageIndex,
      );

      bumpHistoryRevision(ref);
    }
    _isSaving = false;
  }

  // --- CHAPTER DOWNLOADS ---

  Future<void> _loadDownloads() async {
    final rows = await DatabaseHelper.instance.getDownloads(widget.mangaId);
    final ids = <String>{};
    for (final row in rows) {
      final chapterId = row['chapterId'] as String? ?? '';
      if (chapterId.isEmpty) continue;
      if (await ChapterDownloader.isDownloaded(widget.mangaId, chapterId)) {
        ids.add(chapterId);
      }
    }
    if (!mounted) return;
    setState(() {
      _downloadedChapters
        ..clear()
        ..addAll(ids);
    });
  }

  void _toggleChapterDownload(Chapter chapter) {
    if (_activeDownloads.containsKey(chapter.id)) {
      _activeDownloads[chapter.id]?.cancel();
      return;
    }
    if (_downloadedChapters.contains(chapter.id)) {
      _confirmRemoveDownload(chapter.id, chapter.title);
      return;
    }
    _downloadChapter(chapter);
  }

  Future<void> _downloadChapter(Chapter chapter) async {
    MangaSource? source;
    if (widget.sourceId != null) {
      source = getSourceBySourceId(widget.sourceId!);
    }
    source ??= ref.read(currentSourceProvider);
    if (source == null) return;
    final src = source;

    final List<String> pages;
    try {
      pages = await SourceCache.pageUrls(
        sourceId: src.id,
        chapterId: chapter.id,
        fetch: () => src.getPageUrls(chapter.id),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load chapter pages')),
        );
      }
      return;
    }
    if (!mounted) return;

    final task = _ChapterDownloadTask()..total = pages.length;
    setState(() => _activeDownloads[chapter.id] = task);
    _refreshTray();

    final saved = await ChapterDownloader.downloadChapter(
      mangaId: widget.mangaId,
      chapterId: chapter.id,
      pages: pages,
      headers: source.headers,
      isCancelled: () => task.cancelled,
      onProgress: (done, total) {
        task
          ..done = done
          ..total = total;
        if (mounted) setState(() {});
        _refreshTray();
      },
    );
    if (!mounted) return;

    if (saved == null) {
      setState(() => _activeDownloads.remove(chapter.id));
      _refreshTray();
      if (!task.cancelled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to download chapter')),
        );
      }
      return;
    }

    final dir = await ChapterDownloader.chapterDir(widget.mangaId, chapter.id);
    await DatabaseHelper.instance.addDownload(
      mangaId: widget.mangaId,
      chapterId: chapter.id,
      chapterNumber: double.tryParse(chapter.chapterNumber) ?? 0,
      chapterTitle: chapter.title,
      pageCount: saved.length,
      localDir: dir.path,
      pageUrls: jsonEncode(pages),
    );
    await DatabaseHelper.instance.upsertManga(
      mangaId: widget.mangaId,
      title: widget.mangaTitle ?? 'Unknown',
      coverUrl: widget.mangaCoverUrl,
      sourceId: widget.sourceId,
    );
    if (!mounted) return;

    setState(() {
      _activeDownloads.remove(chapter.id);
      _downloadedChapters.add(chapter.id);
    });
    bumpDownloadsRevision(ref);
    _refreshTray();

    final index = widget.allChapters.indexWhere((c) => c.id == chapter.id);
    if (index != -1) _refreshLoadedChapterFiles(index);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloaded ${chapter.title}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _confirmRemoveDownload(String chapterId, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2E),
        title: const Text(
          'Remove download?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          title.isEmpty ? 'This chapter' : title,
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
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ChapterDownloader.removeChapterFiles(widget.mangaId, chapterId);
    await DatabaseHelper.instance.removeDownload(widget.mangaId, chapterId);
    if (!mounted) return;

    setState(() => _downloadedChapters.remove(chapterId));
    bumpDownloadsRevision(ref);
    _refreshTray();

    final index = widget.allChapters.indexWhere((c) => c.id == chapterId);
    if (index != -1) _refreshLoadedChapterFiles(index);
  }

  // Point already-loaded pages of a chapter at their local files (or back at
  // the network when the download was removed).
  Future<void> _refreshLoadedChapterFiles(int chapterIndex) async {
    final start = _pagesChapters.indexOf(chapterIndex);
    if (start == -1) return;
    final end = _pagesChapters.lastIndexOf(chapterIndex);
    final chapter = widget.allChapters[chapterIndex];

    List<String>? locals;
    if (_downloadedChapters.contains(chapter.id)) {
      locals = await ChapterDownloader.localPathsForChapter(
        mangaId: widget.mangaId,
        chapterId: chapter.id,
        pages: _pages.sublist(start, end + 1),
      );
    }
    if (!mounted) return;
    setState(() {
      for (var i = start; i <= end; i++) {
        _pageFiles[i] = locals != null ? locals[i - start] : null;
      }
    });
  }

  Future<void> _loadBookmarks() async {
    final rows = await DatabaseHelper.instance.getBookmarks(widget.mangaId);
    if (!mounted) return;
    setState(() {
      _bookmarkedKeys
        ..clear()
        ..addAll(
          rows.map(
            (r) => _bookmarkKey(
              r['chapterId'] as String? ?? '',
              (r['pageIndex'] as int?) ?? 0,
            ),
          ),
        );
    });
  }

  Future<void> _toggleBookmark() async {
    if (_pages.isEmpty || _currentChapterIndex < 0) return;

    final pageIndex = _currentPageIndex.clamp(0, _pages.length - 1);

    final chapter = widget.allChapters[_currentChapterIndex];
    final pageUrl = _pages[pageIndex];
    final note = 'Saved from ${chapter.title}';

    final existing = await DatabaseHelper.instance.findBookmarkId(
      mangaId: widget.mangaId,
      chapterId: chapter.id,
      pageIndex: pageIndex,
    );
    if (existing != null) {
      await DatabaseHelper.instance.deleteBookmark(existing);
      if (mounted) {
        setState(() {
          _bookmarkedKeys.remove(_bookmarkKey(chapter.id, pageIndex));
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Bookmark removed — ${chapter.title} • Page ${pageIndex + 1}',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    await DatabaseHelper.instance.addBookmark(
      mangaId: widget.mangaId,
      chapterId: chapter.id,
      chapterTitle: chapter.title,
      pageIndex: pageIndex,
      pageUrl: pageUrl,
      note: note,
    );
    if (mounted) {
      setState(() {
        _bookmarkedKeys.add(_bookmarkKey(chapter.id, pageIndex));
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bookmarked ${chapter.title} • Page ${pageIndex + 1}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // --- COLOR CORRECTION FILTER ---

  List<double> _buildColorMatrix() {
    final contrast = _contrast / 100;
    final brightness = (_brightness - 100) * 255 / 100;
    final s = _sepia / 100;

    const sepia = [
      [0.393, 0.769, 0.189, 0.0, 0.0],
      [0.349, 0.686, 0.168, 0.0, 0.0],
      [0.272, 0.534, 0.131, 0.0, 0.0],
      [0.0, 0.0, 0.0, 1.0, 0.0],
    ];

    double m(int row, int col) {
      final identity = row == col ? 1.0 : 0.0;
      return identity * (1 - s) + sepia[row][col] * s;
    }

    return [
      m(0, 0) * contrast,
      m(0, 1) * contrast,
      m(0, 2) * contrast,
      0,
      brightness,
      m(1, 0) * contrast,
      m(1, 1) * contrast,
      m(1, 2) * contrast,
      0,
      brightness,
      m(2, 0) * contrast,
      m(2, 1) * contrast,
      m(2, 2) * contrast,
      0,
      brightness,
      0,
      0,
      0,
      1,
      0,
    ];
  }

  Widget _applyColorFilter(Widget child) {
    if (_brightness == 100 && _contrast == 100 && _sepia == 0) {
      return child;
    }
    return ColorFiltered(
      colorFilter: ColorFilter.matrix(_buildColorMatrix()),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentChapter = widget.allChapters[_currentChapterIndex];
    final chapterPosition = widget.totalChapters > 0
        ? (widget.totalChapters - _currentChapterIndex)
        : null;
    final chLabel = currentChapter.chapterNumber.isNotEmpty
        ? currentChapter.chapterNumber
        : (chapterPosition?.toString() ??
              '${widget.allChapters.length - _currentChapterIndex}');
    final activeSource = ref.watch(currentSourceProvider);
    final Map<String, String>? activeHeaders = activeSource.headers;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _saveCascadingReadProgress();
        if (context.mounted) Navigator.of(context).pop(result);
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onTap: _toggleControls,
          child: Stack(
            children: [
              // --- VIEWPORT AREA ---
              _pages.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : _isHorizontal
                  ? _buildHorizontalReader(activeHeaders)
                  : _buildVerticalReader(activeHeaders),

              // --- TOP APP BAR OVERLAY ---
              AnimatedPositioned(
                duration: const Duration(milliseconds: 200),
                top: _showControls ? 0 : -100,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 4,
                    bottom: 12,
                    left: 8,
                    right: 16,
                  ),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.black87, Colors.transparent],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () async {
                          await _saveCascadingReadProgress();
                          if (context.mounted) Navigator.pop(context);
                        },
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.mangaTitle ?? currentChapter.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Ch. $chLabel',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // --- BOTTOM CAPSULE BAR ---
              AnimatedPositioned(
                duration: const Duration(milliseconds: 200),
                bottom: _showControls ? 16 : -100,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xF228282A),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Previous chapter',
                        icon: const Icon(
                          Icons.skip_previous,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed:
                            _currentChapterIndex < widget.allChapters.length - 1
                            ? () => _changeChapterExplicitly(
                                _currentChapterIndex + 1,
                              )
                            : null,
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: _buildProgressTrack(),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Next chapter',
                        icon: const Icon(
                          Icons.skip_next,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: _currentChapterIndex > 0
                            ? () => _changeChapterExplicitly(
                                _currentChapterIndex - 1,
                              )
                            : null,
                      ),
                      const SizedBox(width: 4),
                      Container(width: 1, height: 26, color: Colors.white24),
                      IconButton(
                        tooltip: 'Chapters',
                        icon: const Icon(
                          Icons.format_list_bulleted,
                          color: Colors.white,
                          size: 24,
                        ),
                        onPressed: _showChapterList,
                      ),
                      IconButton(
                        tooltip: 'Settings',
                        icon: const Icon(
                          Icons.more_vert,
                          color: Colors.white,
                          size: 24,
                        ),
                        onPressed: _showSettingsSheet,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- VERTICAL READER BUILDER (Vertical / Webtoon) ---
  Widget _buildVerticalReader(Map<String, String>? headers) {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: ListView.builder(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        itemCount: _pages.length + 1,
        itemBuilder: (context, index) {
          if (index < _pages.length) {
            return _buildPageImage(
              _pages[index],
              headers,
              localPath: _pageFiles[index],
            );
          }
          return _buildLoadingIndicator();
        },
      ),
    );
  }

  // --- HORIZONTAL READER BUILDER (Standard / Right-to-left) ---
  Widget _buildHorizontalReader(Map<String, String>? headers) {
    final isRtl = _readingMode == ReadingMode.rightToLeft;

    Widget pageView = PageView.builder(
      controller: _pageController,
      itemCount: _pages.length,
      itemBuilder: (context, index) {
        final page = _buildPageImage(
          _pages[index],
          headers,
          localPath: _pageFiles[index],
        );
        // Un-mirror each page when the reader itself is mirrored for RTL.
        return isRtl ? Transform.scale(scaleX: -1, child: page) : page;
      },
    );

    // Mirror the whole viewport so swiping goes right-to-left naturally.
    if (isRtl) {
      pageView = Transform.scale(scaleX: -1, child: pageView);
    }
    return pageView;
  }

  // --- REUSABLE IMAGE WIDGET ---
  Widget _buildPageImage(
    String url,
    Map<String, String>? headers, {
    String? localPath,
  }) {
    final Widget image;
    if (localPath != null && File(localPath).existsSync()) {
      image = Image.file(
        File(localPath),
        fit: BoxFit.fitWidth,
        gaplessPlayback: true,
        errorBuilder: (context, error, stack) => _buildPageError(),
      );
    } else {
      image = CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.fitWidth,
        httpHeaders: headers,
        placeholder: (context, url) => Container(
          height: 500,
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white24),
          ),
        ),
        errorWidget: (context, url, error) => _buildPageError(),
      );
    }
    return _applyColorFilter(image);
  }

  Widget _buildPageError() {
    return Container(
      height: 200,
      color: const Color(0xFF1E1E20),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image, color: Colors.white54, size: 32),
          SizedBox(height: 8),
          Text(
            'Failed to load page',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // --- LOADING INDICATOR WIDGET ---
  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      alignment: Alignment.center,
      child: _hasMoreChapters
          ? const Column(
              children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 12),
                Text(
                  'Loading next chapter...',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            )
          : const Text(
              'You have reached the latest chapter!',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
    );
  }
}

class _DottedProgressPainter extends CustomPainter {
  final double progress;
  final int dotCount;

  _DottedProgressPainter({required this.progress, required this.dotCount});

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    const activeRadius = 2.2;
    const currentRadius = 3.8;
    const baseGap = 5.0;

    final occupied = dotCount * activeRadius * 2 + (dotCount - 1) * baseGap;
    final spacing = occupied >= size.width && dotCount > 1
        ? (size.width - dotCount * activeRadius * 2) / (dotCount - 1)
        : baseGap;
    final totalWidth = dotCount * activeRadius * 2 + (dotCount - 1) * spacing;
    final startX = (size.width - totalWidth) / 2;

    final currentIndex = dotCount > 1
        ? (progress * (dotCount - 1)).round().clamp(0, dotCount - 1)
        : 0;

    final activePaint = Paint()..color = Colors.white;
    final inactivePaint = Paint()..color = Colors.white24;

    for (var i = 0; i < dotCount; i++) {
      final x = startX + activeRadius + i * (activeRadius * 2 + spacing);
      final isCurrent = i == currentIndex;
      final isActive = i <= currentIndex;

      canvas.drawCircle(
        Offset(x, centerY),
        isCurrent ? currentRadius : activeRadius,
        isActive ? activePaint : inactivePaint,
      );
    }
  }

  @override
  bool shouldRepaint(_DottedProgressPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.dotCount != dotCount;
  }
}

class _ChapterDownloadTask {
  bool cancelled = false;
  int done = 0;
  int total = 0;

  void cancel() => cancelled = true;
}
