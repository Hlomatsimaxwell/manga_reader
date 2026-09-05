import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:liquid_glass_bar/liquid_glass_bar.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:manga_reader/features/suggestions/screens/suggestions_screen.dart';
import 'features/history/screens/history_screen.dart';
import 'features/library/screens/favorites_screen.dart';
import 'package:manga_reader/features/explore/screens/explore_screen.dart';
import 'package:manga_reader/features/feed/screens/feed_screen.dart';
import 'package:manga_reader/features/feed/providers/updates_provider.dart';
import 'package:manga_reader/features/reader/screens/reader_screen.dart';
import 'package:manga_reader/core/database/database_helper.dart';
import 'package:manga_reader/core/database/source_cache.dart';
import 'package:manga_reader/data/providers/sources_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Fix the Database Crash for Linux/Windows/MacOS
  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // 2. Run the app.
  runApp(const ProviderScope(child: MangaReaderApp()));
}

class MangaReaderApp extends StatelessWidget {
  const MangaReaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Manga Reader',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        focusColor: Colors.transparent,
        dividerColor: Colors.transparent,
        visualDensity: VisualDensity.standard,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
          toolbarHeight: 44,
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF2E2E33),
          contentTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 40,
            vertical: 20,
          ),
          elevation: 0,
          showCloseIcon: false,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  bool _isContinuing = false;

  final List<Widget> _screens = [
    const HistoryScreen(),
    const FavoritesScreen(),
    const SuggestionsScreen(),
    const ExploreScreen(),
    const FeedScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final updatesCount = ref.watch(updatesCountProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      extendBody: true,
      body: Stack(
        children: [
          IndexedStack(index: _currentIndex, children: _screens),
          // Continue Reading contextual FAB (History tab only).
          // Rendered above the tab content; the body extends behind the nav
          // bar (extendBody: true), and 112 keeps it floating clear of the
          // glass pill's top edge with a little breathing room.
          if (_currentIndex == 0)
            Positioned(
              right: 16,
              bottom: 112,
              child: _buildContinueFab(),
            ),
        ],
      ),
      bottomNavigationBar: Stack(
        children: [
          LiquidGlassBar(
            items: [
              const LiquidGlassBarItem(
                iconData: Icons.history_rounded,
                label: 'History',
              ),
              const LiquidGlassBarItem(
                iconData: Icons.favorite_border_rounded,
                label: 'Favorites',
              ),
              const LiquidGlassBarItem(
                iconData: Icons.lightbulb_outline_rounded,
                label: 'Suggestions',
              ),
              const LiquidGlassBarItem(
                iconData: Icons.explore_outlined,
                label: 'Explore',
              ),
              LiquidGlassBarItem(
                iconWidget: _buildUpdatesIcon(updatesCount),
                label: 'Updates',
              ),
            ],
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            style: LiquidGlassBarStyle(
              activeColor: Colors.white,
              inactiveColor: Colors.white54,
              liquidGlassSettings: const LiquidGlassSettings(
                thickness: 20,
                blur: 18,
                glassColor: Color(0x8CFFFFFF),
                lightIntensity: 0.65,
                refractiveIndex: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Updates icon with its unread-count badge. LiquidGlassBar animates color
  // only for plain iconData items; this iconWidget carries its own color.
  Widget _buildUpdatesIcon(int badgeCount) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        const Icon(Icons.rss_feed_rounded, size: 24, color: Colors.white),
        if (badgeCount > 0)
          Positioned(
            top: -4,
            right: -6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFFF0A8A8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$badgeCount',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildContinueFab() {
    return GestureDetector(
      onTap: _isContinuing ? null : _continueReading,
      child: LiquidGlass.withOwnLayer(
        shape: const LiquidOval(),
        settings: LiquidGlassSettings(
          thickness: 18,
          blur: 16,
          glassColor: _isContinuing
              ? const Color(0x668A8A93)
              : const Color(0x8CFFFFFF),
          lightIntensity: 0.65,
          refractiveIndex: 1.4,
        ),
        child: SizedBox(
          width: 60,
          height: 60,
          child: Center(
            child: _isContinuing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Icon(
                    Icons.auto_stories_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _continueReading() async {
    if (_isContinuing) return;
    setState(() => _isContinuing = true);

    try {
      final rows = await DatabaseHelper.instance.getHistory();
      if (rows.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No reading history yet'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      final last = rows.first;
      final mangaId = last['mangaId'] as String;
      final sourceId = last['sourceId'] as String?;
      final title = last['title'] as String;
      final coverUrl = last['coverUrl'] as String?;
      final lastReadChapter =
          (last['lastReadChapter'] as num?)?.toDouble() ?? 0;
      final lastReadPage = (last['lastReadPage'] as int?) ?? 0;
      final totalChaptersDb = (last['totalChapters'] as int?) ?? 0;

      final source = sourceId != null
          ? getSourceBySourceId(sourceId) ?? ref.read(currentSourceProvider)
          : ref.read(currentSourceProvider);
      if (source == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No source available'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      final chapters = await SourceCache.chapters(
        sourceId: source.id,
        mangaId: mangaId,
        fetch: () => source.getChapters(mangaId),
      );
      if (chapters.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No chapters available'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      // Compute chapter index from position (total - position).
      final total = totalChaptersDb > 0 ? totalChaptersDb : chapters.length;
      final lastReadInt = lastReadChapter.round();
      int chapterIndex = (total - lastReadInt).clamp(0, chapters.length - 1);

      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReaderScreen(
            allChapters: chapters,
            initialChapterIndex: chapterIndex,
            initialPageIndex: lastReadPage,
            mangaId: mangaId,
            sourceId: sourceId,
            mangaTitle: title,
            mangaCoverUrl: coverUrl,
            totalChapters: total,
          ),
        ),
      );

      // After closing the reader, return to the History tab.
      if (mounted) setState(() => _currentIndex = 0);
    } catch (e) {
      debugPrint('Continue reading error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to continue reading: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isContinuing = false);
    }
  }
}
