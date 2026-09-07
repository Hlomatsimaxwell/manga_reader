import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:yomou/features/suggestions/screens/suggestions_screen.dart';
import 'features/history/screens/history_screen.dart';
import 'features/library/screens/favorites_screen.dart';
import 'package:yomou/features/explore/screens/explore_screen.dart';
import 'package:yomou/features/feed/screens/feed_screen.dart';
import 'package:yomou/features/feed/providers/updates_provider.dart';
import 'package:yomou/core/theme/layout.dart';
import 'package:yomou/features/reader/screens/reader_screen.dart';
import 'package:yomou/core/database/database_helper.dart';
import 'package:yomou/core/database/source_cache.dart';
import 'package:yomou/data/providers/sources_provider.dart';
import 'package:yomou/features/settings/providers/appearance_provider.dart';
import 'package:remixicon/remixicon.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Fix the Database Crash for Linux/Windows/MacOS
  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // 2. Run the app.
  runApp(const ProviderScope(child: YomouApp()));
}

class YomouApp extends ConsumerWidget {
  const YomouApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeNotifierProvider);

    return MaterialApp(
      title: 'Yomou',
      debugShowCheckedModeBanner: false,
      themeMode: theme.mode,
      theme: theme.lightTheme,
      darkTheme: theme.darkTheme,
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

  // Scroll-hide state for the nav bar + FAB (used when pinNavUiOnScroll is off).
  bool _navHiddenOnScroll = false;

  // Double-back-to-exit tracking (only active when exitConfirmation is on).
  DateTime? _lastBackPress;

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
    final accent = ref.watch(accentProvider);
    final settings = ref.watch(appearanceSettingsProvider);

    final showFab =
        settings.showFloatingContinueButton && _currentIndex == 0;

    return PopScope(
      canPop: !settings.exitConfirmation,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final now = DateTime.now();
        final recent = _lastBackPress != null &&
            now.difference(_lastBackPress!) < const Duration(seconds: 2);
        if (recent) {
          SystemNavigator.pop();
          return;
        }
        _lastBackPress = now;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Press back again to exit'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        extendBody: true,
        body: NotificationListener<ScrollNotification>(
          onNotification: _onScrollNotification,
          child: Stack(
            children: [
              // Main body content — placed first so lists/grids extend
              // edge-to-edge and scroll underneath the floating bar.
              Positioned.fill(
                child: IndexedStack(index: _currentIndex, children: _screens),
              ),
              // Continue Reading FAB (History tab only, opt-in). Sits above the
              // bar: 12px past the bar's top edge. Cross-fades/scales away on
              // every other tab or when scrolling down (unless pinned).
              Positioned(
                right: 16,
                bottom: bottomBarClearance(context),
                child: AnimatedSlide(
                  offset: Offset(0, _navHiddenOnScroll ? 1.5 : 0),
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(scale: animation, child: child),
                    ),
                    child: showFab
                        ? KeyedSubtree(
                            key: const ValueKey('continue-fab'),
                            child: _buildContinueFab(accent),
                          )
                        : const SizedBox(
                            key: ValueKey('fab-hidden'),
                            width: 60,
                            height: 60,
                          ),
                  ),
                ),
              ),
              // Bottom navigation bar overlay (floating or solid).
              AnimatedSlide(
                offset: Offset(0, _navHiddenOnScroll ? 1.5 : 0),
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: settings.useFloatingNavBar
                    ? _buildFloatingNav(
                        context, updatesCount, accent, settings)
                    : _buildSolidNav(
                        context, updatesCount, accent, settings),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Hides the nav bar + FAB on downward scroll unless pinNavUiOnScroll is on.
  bool _onScrollNotification(ScrollNotification notification) {
    final pinned = ref.read(appearanceSettingsProvider).pinNavUiOnScroll;
    if (notification is ScrollUpdateNotification) {
      final delta = notification.scrollDelta ?? 0;
      final pixels = notification.metrics.pixels;
      final scrollingDown = delta > 0;
      final enoughScrolled = pixels > 40;

      if (!pinned) {
        if (scrollingDown && enoughScrolled && !_navHiddenOnScroll) {
          setState(() => _navHiddenOnScroll = true);
        } else if (!scrollingDown && _navHiddenOnScroll) {
          setState(() => _navHiddenOnScroll = false);
        }
      }
    }
    return false;
  }

  Widget _buildFloatingNav(
    BuildContext context,
    int updatesCount,
    Color accent,
    AppearanceSettings settings,
  ) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.only(
          left: kBottomBarSideMargin,
          right: kBottomBarSideMargin,
          bottom:
              kBottomBarBottomMargin + MediaQuery.paddingOf(context).bottom,
        ),
        child: Container(
          height: kBottomBarHeight,
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1C1C1E)
                : Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF2C2C30)
                  : Colors.black12,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha:
                      Theme.of(context).brightness == Brightness.dark ? 0.08 : 0.12,
                ),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: _buildNavRow(updatesCount, accent, settings),
        ),
      ),
    );
  }

  Widget _buildSolidNav(
    BuildContext context,
    int updatesCount,
    Color accent,
    AppearanceSettings settings,
  ) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: double.infinity,
        height: kBottomBarHeight + MediaQuery.paddingOf(context).bottom,
        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1C1C1E)
            : Colors.white,
        child: _buildNavRow(updatesCount, accent, settings),
      ),
    );
  }

  Widget _buildNavRow(
    int updatesCount,
    Color accent,
    AppearanceSettings settings,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildNavItem(0, updatesCount, accent, settings),
        _buildNavItem(1, updatesCount, accent, settings),
        _buildNavItem(2, updatesCount, accent, settings),
        _buildNavItem(3, updatesCount, accent, settings),
        _buildNavItem(4, updatesCount, accent, settings),
      ],
    );
  }

  // Updates icon with its unread-count badge.
  Widget _buildUpdatesIcon(int badgeCount, IconData icon, Color color, Color accent,
      {double size = 22}) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Icon(icon, size: size, color: color),
        if (badgeCount > 0)
          Positioned(
            top: -4,
            right: -6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$badgeCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  static const List<String> _navLabels = [
    'History',
    'Favorites',
    'Suggestions',
    'Explore',
    'Updates',
  ];

  // Icon + label slot (friend's iOS-style bar, Remix icons). Every tab shows
  // icon + small label; the active tab swaps to the fill glyph, tints with the
  // accent and scales up 5%. Each item is Expanded so the 5 tabs share the
  // available width evenly; the label is wrapped in FittedBox so it scales down
  // instead of overflowing on narrow screens.
  Widget _buildNavItem(
      int index, int updatesCount, Color accent, AppearanceSettings settings) {
    final active = _currentIndex == index;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final color = active
        ? accent
        : dark
            ? const Color(0xFF8E8E93)
            : const Color(0xFF49454F);
    final showLabels = settings.showNavLabels;

    final (IconData line, IconData fill) = switch (index) {
      0 => (RemixIcons.history_line, RemixIcons.history_fill),
      1 => (RemixIcons.heart_3_line, RemixIcons.heart_3_fill),
      2 => (RemixIcons.lightbulb_line, RemixIcons.lightbulb_fill),
      3 => (RemixIcons.compass_3_line, RemixIcons.compass_3_fill),
      _ => (RemixIcons.rss_line, RemixIcons.rss_fill),
    };

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedScale(
          scale: active ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  switchInCurve: Curves.easeInOut,
                  switchOutCurve: Curves.easeInOut,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(scale: animation, child: child),
                  ),
                  child: index == 4
                      ? KeyedSubtree(
                          key: ValueKey<bool>(active),
                          child: _buildUpdatesIcon(
                              updatesCount, active ? fill : line, color, accent),
                        )
                      : Icon(
                          active ? fill : line,
                          key: ValueKey<bool>(active),
                          size: 22,
                          color: color,
                        ),
                ),
                if (showLabels) ...[
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _navLabels[index],
                      softWrap: false,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContinueFab(Color accent) {
    return GestureDetector(
      onTap: _isContinuing ? null : _continueReading,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _isContinuing ? const Color(0xFF2A2A2E) : accent,
          border: _isContinuing
              ? Border.all(color: const Color(0xFF3A3A40))
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
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
