import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database_helper.dart';
import 'package:manga_reader/features/sources/providers/sources_provider.dart';
import 'package:manga_reader/features/sources/models/chapter.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  final List<Chapter> allChapters;
  final int initialChapterIndex;
  final String mangaId;

  const ReaderScreen({
    super.key,
    required this.allChapters,
    required this.initialChapterIndex,
    required this.mangaId,
  });

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<String> _pages = [];
  final List<int> _loadedChapterIndices = [];

  int _currentChapterIndex = 0;
  bool _isLoadingNextChapter = false;
  bool _hasMoreChapters = true;
  bool _showControls = true;

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
    super.dispose();
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  Future<void> _loadChapter(int chapterIndex) async {
    if (_loadedChapterIndices.contains(chapterIndex)) return;

    final source = ref.read(currentSourceProvider);
    final chapter = widget.allChapters[chapterIndex];

    try {
      final newPages = await source.getPageList(chapter);
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
    if (_loadedChapterIndices.isEmpty) return;

    double maxChapterNumRead = -1.0;

    for (final index in _loadedChapterIndices) {
      final chapter = widget.allChapters[index];
      final regExp = RegExp(r'(\d+(\.\d+)?)');
      final match = regExp.firstMatch(chapter.title);
      if (match != null) {
        final num = double.tryParse(match.group(1)!) ?? -1.0;
        if (num > maxChapterNumRead) maxChapterNumRead = num;
      }
    }

    if (maxChapterNumRead >= 0) {
      final chapter = widget.allChapters[_loadedChapterIndices.first];
      await DatabaseHelper.instance.markChapterAsRead(
        widget.mangaId,
        chapter.id,
        maxChapterNumRead,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentChapter = widget.allChapters[_currentChapterIndex];

    return PopScope(
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          await _saveCascadingReadProgress();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onTap: _toggleControls,
          child: Stack(
            children: [
              // Continuous Page ListView
              _pages.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : ScrollConfiguration(
                      behavior: ScrollConfiguration.of(context)
                          .copyWith(scrollbars: false),
                      child: ListView.builder(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        itemCount: _pages.length + 1,
                        itemBuilder: (context, index) {
                          if (index < _pages.length) {
                            return InteractiveViewer(
                              minScale: 1.0,
                              maxScale: 3.5,
                              child: CachedNetworkImage(
                                imageUrl: _pages[index],
                                fit: BoxFit.fitWidth,
                                httpHeaders: const {
                                  'Referer': 'https://manganato.com',
                                  'User-Agent':
                                      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                                },
                                placeholder: (context, url) => Container(
                                  height: 300,
                                  color: Colors.black,
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.white24,
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  height: 200,
                                  color: const Color(0xFF1E1E20),
                                  child: const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.broken_image,
                                        color: Colors.white54,
                                        size: 32,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Failed to load page',
                                        style: TextStyle(
                                            color: Colors.white54,
                                            fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }

                          return Container(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            alignment: Alignment.center,
                            child: _hasMoreChapters
                                ? const Column(
                                    children: [
                                      CircularProgressIndicator(
                                          color: Colors.white),
                                      SizedBox(height: 12),
                                      Text(
                                        'Loading next chapter...',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                    ],
                                  )
                                : const Text(
                                    'You have reached the latest chapter!',
                                    style: TextStyle(
                                        color: Colors.white54, fontSize: 14),
                                  ),
                          );
                        },
                      ),
                    ),

              // Kotatsu Top Header Bar
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
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              currentChapter.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
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

              // Kotatsu Bottom Navigation Overlay
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
                      // Scrub Dots Indicator
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          8,
                          (index) => Container(
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

                      // Controls Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.skip_previous_outlined,
                              color: Colors.white,
                            ),
                            onPressed: _currentChapterIndex <
                                    widget.allChapters.length - 1
                                ? () {
                                    setState(() {
                                      _currentChapterIndex++;
                                      _pages.clear();
                                      _loadChapter(_currentChapterIndex);
                                    });
                                  }
                                : null,
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.pause_outlined,
                              color: Colors.white,
                            ),
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.skip_next_outlined,
                              color: Colors.white,
                            ),
                            onPressed: _currentChapterIndex > 0
                                ? () {
                                    setState(() {
                                      _currentChapterIndex--;
                                      _pages.clear();
                                      _loadChapter(_currentChapterIndex);
                                    });
                                  }
                                : null,
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.format_list_bulleted,
                              color: Colors.white,
                            ),
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.more_vert,
                              color: Colors.white,
                            ),
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
}