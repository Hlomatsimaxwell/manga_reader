import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database_helper.dart';
import 'package:manga_reader/data/providers/sources_provider.dart';
import 'package:manga_reader/data/models/chapter.dart';
import 'package:manga_reader/data/models/manga_source.dart';
import 'package:manga_reader/features/history/providers/history_provider.dart';

// 1. Define the Reading Modes
enum ReadingMode { vertical, horizontal }

class ReaderScreen extends ConsumerStatefulWidget {
  final List<Chapter> allChapters;
  final int initialChapterIndex;
  final String mangaId;
  final String? sourceId;
  final String? mangaTitle;
  final String? mangaCoverUrl;
  final int totalChapters;

  const ReaderScreen({
    super.key,
    required this.allChapters,
    required this.initialChapterIndex,
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
  final PageController _pageController = PageController();
  final List<String> _pages = [];
  final List<int> _loadedChapterIndices = [];

  int _currentChapterIndex = 0;
  bool _isLoadingNextChapter = false;
  bool _hasMoreChapters = true;
  bool _showControls = true;
  bool _isSaving = false;
  
  // The mode state
  ReadingMode _readingMode = ReadingMode.vertical;

  @override
  void initState() {
    super.initState();
    _currentChapterIndex = widget.initialChapterIndex;
    _loadChapter(_currentChapterIndex);

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 800 &&
          !_isLoadingNextChapter &&
          _hasMoreChapters) {
        _loadNextChapter();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  void _showReadingModeDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Reading Mode',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.unfold_more, color: Colors.white54),
                title: const Text('Vertical (Webtoon)', style: TextStyle(color: Colors.white)),
                trailing: _readingMode == ReadingMode.vertical 
                    ? const Icon(Icons.check_circle, color: Colors.blue) 
                    : null,
                onTap: () {
                  setState(() => _readingMode = ReadingMode.vertical);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.swap_horiz, color: Colors.white54),
                title: const Text('Horizontal (Manga)', style: TextStyle(color: Colors.white)),
                trailing: _readingMode == ReadingMode.horizontal 
                    ? const Icon(Icons.check_circle, color: Colors.blue) 
                    : null,
                onTap: () {
                  setState(() => _readingMode = ReadingMode.horizontal);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
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

    try {
      final newPages = await source.getPageUrls(chapter.id);
      if (mounted) {
        setState(() {
          _pages.addAll(newPages);
          _loadedChapterIndices.add(chapterIndex);
        });
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

    double maxChapterNumRead = -1.0;
    String? targetChapterId;

    for (final index in _loadedChapterIndices) {
      final chapter = widget.allChapters[index];
      final regExp = RegExp(r'(\d+(\.\d+)?)');
      final match = regExp.firstMatch(chapter.title);
      if (match != null) {
        final num = double.tryParse(match.group(1)!) ?? -1.0;
        if (num > maxChapterNumRead) {
          maxChapterNumRead = num;
          targetChapterId = chapter.id;
        }
      }
    }

    if (maxChapterNumRead >= 0 && targetChapterId != null) {
      await DatabaseHelper.instance.markChapterAsRead(
        widget.mangaId,
        targetChapterId,
        maxChapterNumRead,
      );

      await DatabaseHelper.instance.saveMangaProgress(
        mangaId: widget.mangaId,
        title: widget.mangaTitle ?? 'Unknown',
        coverUrl: widget.mangaCoverUrl,
        sourceId: widget.sourceId,
        totalChapters: widget.totalChapters,
        lastReadChapter: maxChapterNumRead,
      );

      bumpHistoryRevision(ref);
    }
    _isSaving = false;
  }

  Future<void> _addBookmark() async {
    if (_pages.isEmpty || _currentChapterIndex < 0) return;

    // Determine the current page index based on reading mode.
    int pageIndex = 0;
    if (_readingMode == ReadingMode.horizontal && _pageController.hasClients) {
      pageIndex = _pageController.page?.round() ?? 0;
    } else if (_readingMode == ReadingMode.vertical &&
        _scrollController.hasClients) {
      final perPage = 600.0;
      pageIndex =
          (_scrollController.offset / perPage).floor().clamp(0, _pages.length - 1);
    }
    pageIndex = pageIndex.clamp(0, _pages.length - 1);

    final chapter = widget.allChapters[_currentChapterIndex];
    final pageUrl = _pages[pageIndex];
    final note = 'Saved from ${chapter.title}';

    await DatabaseHelper.instance.addBookmark(
      mangaId: widget.mangaId,
      chapterId: chapter.id,
      chapterTitle: chapter.title,
      pageIndex: pageIndex,
      pageUrl: pageUrl,
      note: note,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bookmarked ${chapter.title} • Page ${pageIndex + 1}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _changeChapterExplicitly(int newIndex) {
    setState(() {
      _currentChapterIndex = newIndex;
      _pages.clear();
      _loadedChapterIndices.clear();
      _hasMoreChapters = true;
    });
    _loadChapter(_currentChapterIndex);
  }

  @override
  Widget build(BuildContext context) {
    final currentChapter = widget.allChapters[_currentChapterIndex];
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
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : _readingMode == ReadingMode.vertical 
                      ? _buildVerticalReader(activeHeaders) 
                      : _buildHorizontalReader(activeHeaders),

              // --- TOP HEADER ---
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
                        child: Text(
                          currentChapter.title,
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // --- BOTTOM NAVIGATION ---
              AnimatedPositioned(
                duration: const Duration(milliseconds: 200),
                bottom: _showControls ? 0 : -100,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom + 8,
                    top: 12,
                    left: 16,
                    right: 16,
                  ),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Colors.black87],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          8, (index) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            width: index == 1 ? 6 : 4,
                            height: index == 1 ? 6 : 4,
                            decoration: BoxDecoration(
                              color: index == 1 ? Colors.white : Colors.white38,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.skip_previous_outlined, color: Colors.white),
                            onPressed: _currentChapterIndex < widget.allChapters.length - 1
                                ? () => _changeChapterExplicitly(_currentChapterIndex + 1)
                                : null,
                          ),
                          IconButton(
                            icon: const Icon(Icons.swap_vert, color: Colors.white),
                            onPressed: _showReadingModeDialog,
                          ),
                          IconButton(
                            icon: const Icon(Icons.skip_next_outlined, color: Colors.white),
                            onPressed: _currentChapterIndex > 0
                                ? () => _changeChapterExplicitly(_currentChapterIndex - 1)
                                : null,
                          ),
                          IconButton(
                            icon: const Icon(Icons.bookmark_add_outlined, color: Colors.white),
                            onPressed: _addBookmark,
                          ),
                          IconButton(
                            icon: const Icon(Icons.more_vert, color: Colors.white),
                            onPressed: () {},
                          ),
                        ],
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

  // --- VERTICAL READER BUILDER ---
  Widget _buildVerticalReader(Map<String, String>? headers) {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: ListView.builder(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        itemCount: _pages.length + 1,
        itemBuilder: (context, index) {
          if (index < _pages.length) {
            return _buildPageImage(_pages[index], headers);
          }
          return _buildLoadingIndicator();
        },
      ),
    );
  }

  // --- HORIZONTAL READER BUILDER ---
  Widget _buildHorizontalReader(Map<String, String>? headers) {
    return PageView.builder(
      controller: _pageController,
      itemCount: _pages.length,
      itemBuilder: (context, index) {
        return _buildPageImage(_pages[index], headers);
      },
    );
  }

  // --- REUSABLE IMAGE WIDGET ---
  Widget _buildPageImage(String url, Map<String, String>? headers) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.fitWidth,
      httpHeaders: headers,
      placeholder: (context, url) => Container(
        height: 500,
        color: Colors.black,
        child: const Center(child: CircularProgressIndicator(color: Colors.white24)),
      ),
      errorWidget: (context, url, error) => Container(
        height: 200,
        color: const Color(0xFF1E1E20),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image, color: Colors.white54, size: 32),
            SizedBox(height: 8),
            Text('Failed to load page', style: TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
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
                Text('Loading next chapter...', style: TextStyle(color: Colors.white70)),
              ],
            )
          : const Text('You have reached the latest chapter!',
              style: TextStyle(color: Colors.white54, fontSize: 14)),
    );
  }
}
