import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yomou/core/theme/colors.dart';
import 'package:yomou/features/settings/providers/appearance_provider.dart';

class AppearanceSettingsScreen extends ConsumerWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appearanceSettingsProvider);
    final notifier = ref.read(appearanceSettingsProvider.notifier);

    return Scaffold(
      backgroundColor: settings.pureBlackAmoled ? Colors.black : Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Appearance',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // Color Scheme Carousel
          _SectionHeader(title: 'Color Scheme'),
          SizedBox(
            height: 80,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _SchemePreset(
                  name: 'Totoro',
                  palette: schemePalettes[AppColorScheme.totoro]!,
                  isActive: settings.colorScheme == 'Totoro',
                  onTap: () => notifier.setColorScheme('Totoro'),
                ),
                _SchemePreset(
                  name: 'Dynamic',
                  palette: schemePalettes[AppColorScheme.dynamic]!,
                  isActive: settings.colorScheme == 'Dynamic',
                  onTap: () => notifier.setColorScheme('Dynamic'),
                ),
                _SchemePreset(
                  name: 'Expressive',
                  palette: schemePalettes[AppColorScheme.expressive]!,
                  isActive: settings.colorScheme == 'Expressive',
                  onTap: () => notifier.setColorScheme('Expressive'),
                ),
                _SchemePreset(
                  name: 'Miku',
                  palette: schemePalettes[AppColorScheme.miku]!,
                  isActive: settings.colorScheme == 'Miku',
                  onTap: () => notifier.setColorScheme('Miku'),
                ),
              ],
            ),
          ),

          // Theme Options
          _SectionHeader(title: 'Theme Options'),
          ListTile(
            title: const Text('Theme', style: TextStyle(color: Colors.white)),
            subtitle: Text(
              settings.themeMode.name.capitalize(),
              style: const TextStyle(color: Colors.white54),
            ),
            onTap: () => _showThemeModeSelector(context, ref, settings, notifier),
          ),
          SwitchListTile(
            title: const Text('Black', style: TextStyle(color: Colors.white)),
            subtitle: const Text(
              'Uses less power on AMOLED screens',
              style: TextStyle(color: Colors.white54),
            ),
            value: settings.pureBlackAmoled,
            onChanged: (_) => notifier.toggleBool('pureBlackAmoled'),
            activeThumbColor: kAccentColor,
          ),
          ListTile(
            title: const Text('Language', style: TextStyle(color: Colors.white)),
            subtitle: Text(
              settings.language == 'system' ? 'Follow system' : settings.language,
              style: const TextStyle(color: Colors.white54),
            ),
            onTap: () => _showLanguageSelector(context, ref, settings, notifier),
          ),

          // Manga List Section
          _SectionHeader(title: 'Manga List'),
          ListTile(
            title: const Text('List mode', style: TextStyle(color: Colors.white)),
            subtitle: Text(
              settings.listMode,
              style: const TextStyle(color: Colors.white54),
            ),
            onTap: () => _showListModeSelector(context, ref, settings, notifier),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Grid size: ${settings.gridSize.round()}%',
                  style: const TextStyle(color: Colors.white),
                ),
                Slider(
                  value: settings.gridSize,
                  min: 50,
                  max: 150,
                  onChanged: (v) => notifier.setGridSize(v),
                  activeColor: kAccentColor,
                ),
              ],
            ),
          ),
          SwitchListTile(
            title: const Text('Show quick filters', style: TextStyle(color: Colors.white)),
            value: settings.showQuickFilters,
            onChanged: (_) => notifier.toggleBool('showQuickFilters'),
            activeThumbColor: kAccentColor,
          ),
          SwitchListTile(
            title: const Text('Show reading progress', style: TextStyle(color: Colors.white)),
            value: settings.showReadingProgress,
            onChanged: (_) => notifier.toggleBool('showReadingProgress'),
            activeThumbColor: kAccentColor,
          ),
          SwitchListTile(
            title: const Text('Badges in lists', style: TextStyle(color: Colors.white)),
            value: settings.showListBadges,
            onChanged: (_) => notifier.toggleBool('showListBadges'),
            activeThumbColor: kAccentColor,
          ),

          // Details Section
          _SectionHeader(title: 'Details'),
          SwitchListTile(
            title: const Text('Collapse long description', style: TextStyle(color: Colors.white)),
            value: settings.collapseDescription,
            onChanged: (_) => notifier.toggleBool('collapseDescription'),
            activeThumbColor: kAccentColor,
          ),
          SwitchListTile(
            title: const Text('Show pages thumbnails', style: TextStyle(color: Colors.white)),
            value: settings.showPagesThumbnails,
            onChanged: (_) => notifier.toggleBool('showPagesThumbnails'),
            activeThumbColor: kAccentColor,
          ),
          ListTile(
            title: const Text('Default tab', style: TextStyle(color: Colors.white)),
            subtitle: Text(
              settings.defaultTab,
              style: const TextStyle(color: Colors.white54),
            ),
            onTap: () => _showDefaultTabSelector(context, ref, settings, notifier),
          ),

          // Main Screen Section
          _SectionHeader(title: 'Main Screen'),
          ListTile(
            title: const Text('Search suggestions', style: TextStyle(color: Colors.white)),
            subtitle: Text(
              _suggestionSummary(settings),
              style: const TextStyle(color: Colors.white54),
            ),
            onTap: () => _showSearchSuggestionsSheet(context, ref, settings, notifier),
          ),
          ListTile(
            title: const Text('Main screen sections', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Categories to show in the main screen', style: TextStyle(color: Colors.white54)),
            onTap: () => _showMainSectionsSheet(context, ref, settings, notifier),
          ),
          SwitchListTile(
            title: const Text('Show floating Continue button', style: TextStyle(color: Colors.white)),
            value: settings.showFloatingContinueButton,
            onChanged: (_) => notifier.toggleBool('showFloatingContinueButton'),
            activeThumbColor: kAccentColor,
          ),
          SwitchListTile(
            title: const Text('Show labels in navigation bar', style: TextStyle(color: Colors.white)),
            value: settings.showNavLabels,
            onChanged: (_) => notifier.toggleBool('showNavLabels'),
            activeThumbColor: kAccentColor,
          ),
          SwitchListTile(
            title: const Text('Floating navigation bar', style: TextStyle(color: Colors.white)),
            value: settings.useFloatingNavBar,
            onChanged: (_) => notifier.toggleBool('useFloatingNavBar'),
            activeThumbColor: kAccentColor,
          ),
          SwitchListTile(
            title: const Text('Pin navigation UI', style: TextStyle(color: Colors.white)),
            subtitle: const Text(
              'Do not hide navigation bar and search view on scroll',
              style: TextStyle(color: Colors.white54),
            ),
            value: settings.pinNavUiOnScroll,
            onChanged: (_) => notifier.toggleBool('pinNavUiOnScroll'),
            activeThumbColor: kAccentColor,
          ),
          SwitchListTile(
            title: const Text('Exit confirmation', style: TextStyle(color: Colors.white)),
            subtitle: const Text(
              'Press Back twice to exit the app',
              style: TextStyle(color: Colors.white54),
            ),
            value: settings.exitConfirmation,
            onChanged: (_) => notifier.toggleBool('exitConfirmation'),
            activeThumbColor: kAccentColor,
          ),
          SwitchListTile(
            title: const Text('Show recent manga shortcuts', style: TextStyle(color: Colors.white)),
            value: settings.showRecentShortcuts,
            onChanged: (_) => notifier.toggleBool('showRecentShortcuts'),
            activeThumbColor: kAccentColor,
          ),
          SwitchListTile(
            title: const Text('Hide NSFW from shortcuts', style: TextStyle(color: Colors.white)),
            value: settings.hideNsfwFromShortcuts,
            onChanged: (_) => notifier.toggleBool('hideNsfwFromShortcuts'),
            activeThumbColor: kAccentColor,
          ),

          // Privacy Section
          _SectionHeader(title: 'Privacy'),
          SwitchListTile(
            title: const Text('Protect the app', style: TextStyle(color: Colors.white)),
            subtitle: const Text(
              'Require authentication to open Yomou',
              style: TextStyle(color: Colors.white54),
            ),
            value: settings.protectApp,
            onChanged: (v) => notifier.setProtectApp(v),
            activeThumbColor: kAccentColor,
          ),
          ListTile(
            title: const Text('Screenshot policy', style: TextStyle(color: Colors.white)),
            subtitle: Text(
              settings.screenshotPolicy,
              style: const TextStyle(color: Colors.white54),
            ),
            onTap: () => _showScreenshotPolicySheet(context, ref, settings, notifier),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showThemeModeSelector(
    BuildContext context,
    WidgetRef ref,
    AppearanceSettings settings,
    AppearanceSettingsNotifier notifier,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2E2E33),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white38,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Theme',
                style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ),
            _buildThemeOption(ctx, 'System', ThemeMode.system, settings.themeMode, notifier),
            _buildThemeOption(ctx, 'Light', ThemeMode.light, settings.themeMode, notifier),
            _buildThemeOption(ctx, 'Dark', ThemeMode.dark, settings.themeMode, notifier),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    String label,
    ThemeMode mode,
    ThemeMode current,
    AppearanceSettingsNotifier notifier,
  ) {
    return ListTile(
      title: Text(label, style: const TextStyle(color: Colors.white)),
      trailing: mode == current
          ? Icon(Icons.check, color: kAccentColor)
          : null,
      onTap: () {
        notifier.setThemeMode(mode);
        Navigator.pop(context);
      },
    );
  }

  void _showLanguageSelector(
    BuildContext context,
    WidgetRef ref,
    AppearanceSettings settings,
    AppearanceSettingsNotifier notifier,
  ) {
    final languages = ['system', 'en', 'ja', 'ko', 'zh', 'ru'];
    final labels = ['Follow system', 'English', 'Japanese', 'Korean', 'Chinese', 'Russian'];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2E2E33),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white38,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Language',
                style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ),
            for (var i = 0; i < languages.length; i++)
              ListTile(
                title: Text(labels[i], style: const TextStyle(color: Colors.white)),
                trailing: languages[i] == settings.language
                    ? Icon(Icons.check, color: kAccentColor)
                    : null,
                onTap: () {
                  notifier.setLanguage(languages[i]);
                  Navigator.pop(ctx);
                },
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showListModeSelector(
    BuildContext context,
    WidgetRef ref,
    AppearanceSettings settings,
    AppearanceSettingsNotifier notifier,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2E2E33),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white38,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'List mode',
                style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ),
            _buildListModeOption(ctx, 'Grid', settings.listMode, notifier),
            _buildListModeOption(ctx, 'List', settings.listMode, notifier),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildListModeOption(
    BuildContext context,
    String mode,
    String current,
    AppearanceSettingsNotifier notifier,
  ) {
    return ListTile(
      title: Text(mode, style: const TextStyle(color: Colors.white)),
      trailing: mode == current
          ? Icon(Icons.check, color: kAccentColor)
          : null,
      onTap: () {
        notifier.setListMode(mode);
        Navigator.pop(context);
      },
    );
  }

  void _showDefaultTabSelector(
    BuildContext context,
    WidgetRef ref,
    AppearanceSettings settings,
    AppearanceSettingsNotifier notifier,
  ) {
    final tabs = ['Last used', 'History', 'Favorites', 'Suggestions', 'Explore', 'Updates'];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2E2E33),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white38,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Default tab',
                style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ),
            for (final tab in tabs)
              ListTile(
                title: Text(tab, style: const TextStyle(color: Colors.white)),
                trailing: tab == settings.defaultTab
                    ? Icon(Icons.check, color: kAccentColor)
                    : null,
                onTap: () {
                  notifier.setDefaultTab(tab);
                  Navigator.pop(ctx);
                },
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _suggestionSummary(AppearanceSettings settings) {
    final enabled = settings.searchSuggestions.entries
        .where((e) => e.value)
        .map((e) => e.key.capitalize())
        .toList();
    return enabled.isEmpty ? 'None' : enabled.join(', ');
  }

  void _showSearchSuggestionsSheet(
    BuildContext context,
    WidgetRef ref,
    AppearanceSettings settings,
    AppearanceSettingsNotifier notifier,
  ) {
    const options = {'history': 'History', 'trending': 'Trending', 'new': 'New', 'popular': 'Popular'};

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2E2E33),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white38,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Search suggestions',
                style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ),
            for (final entry in options.entries)
              SwitchListTile(
                title: Text(entry.value, style: const TextStyle(color: Colors.white)),
                value: settings.searchSuggestions[entry.key] ?? true,
                activeThumbColor: kAccentColor,
                onChanged: (_) => notifier.toggleSearchSuggestion(entry.key),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showMainSectionsSheet(
    BuildContext context,
    WidgetRef ref,
    AppearanceSettings settings,
    AppearanceSettingsNotifier notifier,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2E2E33),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white38,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Main screen sections',
                style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ),
            for (final entry in settings.mainScreenSections.entries)
              SwitchListTile(
                title: Text(entry.key, style: const TextStyle(color: Colors.white)),
                value: entry.value,
                activeThumbColor: kAccentColor,
                onChanged: (_) => notifier.toggleMainSection(entry.key),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showScreenshotPolicySheet(
    BuildContext context,
    WidgetRef ref,
    AppearanceSettings settings,
    AppearanceSettingsNotifier notifier,
  ) {
    const policies = ['Allow', 'Block'];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2E2E33),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white38,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Screenshot policy',
                style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ),
            for (final policy in policies)
              ListTile(
                title: Text(policy, style: const TextStyle(color: Colors.white)),
                trailing: policy == settings.screenshotPolicy
                    ? Icon(Icons.check, color: kAccentColor)
                    : null,
                onTap: () {
                  notifier.setScreenshotPolicy(policy);
                  Navigator.pop(ctx);
                },
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// Helper widget for section headers
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.5),
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// Helper widget for color scheme presets
class _SchemePreset extends StatelessWidget {
  const _SchemePreset({
    required this.name,
    required this.palette,
    required this.isActive,
    required this.onTap,
  });

  final String name;
  final SchemePalette palette;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: isActive ? palette.accent : const Color(0xFF2E2E33),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? palette.accent : Colors.white24,
            width: isActive ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? Icons.check_circle : Icons.circle,
              color: Colors.white,
              size: 32,
            ),
            const SizedBox(height: 4),
            Text(
              name,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Extension for capitalizing strings
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}