import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
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
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
          left: 12,
          right: 12,
          bottom: 24 + MediaQuery.paddingOf(context).bottom,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Bottom nav pill. Compact (icon-only) on History so the Continue
            // FAB sits beside it; full-width on every other tab with the
            // active item rendered as a filled icon+label badge.
            AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              height: 64,
              width: _currentIndex == 0
                  ? MediaQuery.sizeOf(context).width - 24 - 72
                  : MediaQuery.sizeOf(context).width - 24,
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: const Color(0xFF2C2C30)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(0, updatesCount),
                  _buildNavItem(1, updatesCount),
                  _buildNavItem(2, updatesCount),
                  _buildNavItem(3, updatesCount),
                  _buildNavItem(4, updatesCount),
                ],
              ),
            ),
            // Continue Reading FAB: only alongside the compact pill on the
            // History tab. Cross-fades/scales out on every other tab.
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(scale: animation, child: child),
              ),
              child: _currentIndex == 0
                  ? Padding(
                      key: const ValueKey('continue-fab'),
                      padding: const EdgeInsets.only(left: 12),
                      child: _buildContinueFab(),
                    )
                  : const SizedBox.shrink(key: ValueKey('fab-hidden')),
            ),
          ],
        ),
      ),
    );
  }

  // Updates icon with its unread-count badge.
  Widget _buildUpdatesIcon(int badgeCount, Color color, {double size = 24}) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Icon(Icons.rss_feed_rounded, size: size, color: color),
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

  // Single icon slot in the solid pill nav. Each item is a tappable circle
  // that highlights its icon when the tab is active.
  static const List<String> _navLabels = [
    'History',
    'Favorites',
    'Suggestions',
    'Explore',
    'Updates',
  ];

  // Accent used for the active tab's filled icon+label badge (Kotatsu style).
  static const Color _navAccent = Color(0xFF4C8DFF);

  // A single slot in the pill nav.
  //  - History (compact pill): all items are icon-only.
  //  - Other tabs (full-width pill): the active item becomes a filled
  //    icon+label badge; inactive items stay icon-only. Each item
  //    cross-fades between its icon and badge states.
  Widget _buildNavItem(int index, int updatesCount) {
    final selected = _currentIndex == index;
    final compact = _currentIndex == 0;
    final color = selected ? Colors.white : Colors.white54;

    final Widget iconSlot = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected
            ? Colors.white.withValues(alpha: 0.12)
            : Colors.transparent,
      ),
      child: Center(
        child: _buildIcon(index, updatesCount, color, 24),
      ),
    );

    // Active badge sizes itself to its content (icon + full label), so the
    // label never truncates. spaceEvenly on the pill Row then distributes
    // the five natural-width items evenly across the pill.
    final Widget badge = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _navAccent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildIcon(index, updatesCount, Colors.white, 20),
          const SizedBox(width: 4),
          Text(
            _navLabels[index],
            maxLines: 1,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );

    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      customBorder: const CircleBorder(),
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(scale: animation, child: child),
          ),
          child: !compact && selected
              ? KeyedSubtree(
                  key: const ValueKey('nav-badge'),
                  child: badge,
                )
              : KeyedSubtree(
                  key: const ValueKey('nav-icon'),
                  child: iconSlot,
                ),
        ),
      ),
    );
  }

  Widget _buildIcon(int index, int updatesCount, Color color, double size) {
    return switch (index) {
      0 => Icon(Icons.history_rounded, size: size, color: color),
      1 => Icon(Icons.favorite_border_rounded, size: size, color: color),
      2 => Icon(Icons.lightbulb_outline_rounded, size: size, color: color),
      3 => Icon(Icons.explore_outlined, size: size, color: color),
      _ => _buildUpdatesIcon(updatesCount, color, size: size),
    };
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
