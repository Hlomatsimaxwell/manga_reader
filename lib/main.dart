import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io'; // REQUIRED for Platform.isLinux
import 'package:sqflite_common_ffi/sqflite_ffi.dart'; // REQUIRED for Linux DB

import 'package:manga_reader/features/suggestions/screens/suggestions_screen.dart';
import 'features/history/screens/history_screen.dart';
import 'features/library/screens/favorites_screen.dart';
import 'package:manga_reader/features/explore/screens/explore_screen.dart';
import 'package:manga_reader/features/feed/screens/feed_screen.dart';

void main() {
  // 1. Fix the Database Crash for Linux/Windows/MacOS
  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  
  // 2. Run the app with ProviderScope
  runApp(const ProviderScope(child: MangaReaderApp()));
}

class MangaReaderApp extends StatelessWidget {
  const MangaReaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Manga Reader',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0; // Default to History tab

  final List<Widget> _screens = [
    const HistoryScreen(),
    const FavoritesScreen(),
    const SuggestionsScreen(),
    const ExploreScreen(),
    const FeedScreen(),
  ];

  static const Color _activeColor = Color(0xFF9AA0A6); // Light gray active highlight

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Main pill capsule expands to fill available width.
              Expanded(
                child: Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF232428),
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                    _buildNavItem(index: 0, icon: Icons.history_rounded, label: 'History'),
                    _buildNavItem(index: 1, icon: Icons.favorite_border_rounded, label: 'Favorites'),
                    _buildNavItem(index: 2, icon: Icons.lightbulb_outline_rounded, label: 'Suggestions'),
                    _buildNavItem(index: 3, icon: Icons.explore_outlined, label: 'Explore'),
                    _buildNavItem(
                      index: 4,
                      icon: Icons.rss_feed_rounded,
                      label: 'Updates',
                      badgeCount: 25,
                    ),
                    ],
                  ),
                ),
              ),
              // Small gap between the capsule and the Continue button.
              const SizedBox(width: 8),
              // Continue Reading contextual FAB (History tab only).
              if (_currentIndex == 0) _buildContinueFab(),
            ],
          ),
        ),
      ),
    );
  }

  // Nav item. When the active tab is a non-History screen, the active
  // indicator expands into an elongated pill (icon + label); on the History
  // tab it stays icon-only to save room for the Continue Reading FAB.
  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    int? badgeCount,
  }) {
    final isSelected = _currentIndex == index;
    final _showLabel =
        isSelected && _currentIndex != 0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOutCubic,
        // On non-History screens the active tab expands into an elongated pill
        // showing its label; everywhere else it stays icon-only (circular).
        height: 44,
        padding: _showLabel
            ? const EdgeInsets.symmetric(horizontal: 14, vertical: 8)
            : const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? _activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: isSelected ? Colors.black : Colors.white70,
                  size: 24,
                ),
                if (_showLabel) ...[
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
            if (badgeCount != null && badgeCount > 0)
              Positioned(
                top: _showLabel ? -2 : -4,
                right: _showLabel ? -4 : -6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
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
        ),
      ),
    );
  }

  // Continue Reading circular FAB, to the right of the pill bar.
  Widget _buildContinueFab() {
    return GestureDetector(
      onTap: () {
        // Continue-reading: resume the most recently read manga.
        // TODO: load last-read manga and open its reader.
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: _activeColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.auto_stories_rounded,
            color: Colors.black,
            size: 30,
          ),
        ),
      ),
    );
  }
}
