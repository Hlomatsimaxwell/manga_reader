import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yomou/features/settings/providers/appearance_provider.dart';

class AppearanceSettingsScreen extends ConsumerWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appearanceSettingsProvider);
    final notifier = ref.read(appearanceSettingsProvider.notifier);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final titleColor =
        dark ? Colors.white : Theme.of(context).colorScheme.onSurface;
    final subtitleColor = dark ? Colors.white54 : Colors.black54;
    final appBarContentColor = dark ? Colors.white : const Color(0xFF1C1B1F);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: appBarContentColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Appearance',
          style: TextStyle(
            color: appBarContentColor,
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
            height: 90,
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
            title: Text('Theme', style: TextStyle(color: titleColor)),
            subtitle: Text(
              settings.themeMode.name.capitalize(),
              style: TextStyle(color: subtitleColor),
            ),
            onTap: () => _showThemeModeSelector(context, ref, settings, notifier),
          ),
          ListTile(
            title: Text('Language', style: TextStyle(color: titleColor)),
            subtitle: Text(
              settings.language == 'system' ? 'Follow system' : settings.language,
              style: TextStyle(color: subtitleColor),
            ),
            onTap: () => _showLanguageSelector(context, ref, settings, notifier),
          ),

          // Manga List Section
          _SectionHeader(title: 'Manga List'),
          ListTile(
            title: Text('List mode', style: TextStyle(color: titleColor)),
            subtitle: Text(
              settings.listMode,
              style: TextStyle(color: subtitleColor),
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
                  style: TextStyle(color: titleColor),
                ),
                Slider(
                  value: settings.gridSize,
                  min: 50,
                  max: 150,
                  onChanged: (v) => notifier.setGridSize(v),
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ),
          SwitchListTile(
            title: Text('Show quick filters', style: TextStyle(color: titleColor)),
            value: settings.showQuickFilters,
            onChanged: (_) => notifier.toggleBool('showQuickFilters'),
            activeThumbColor: Theme.of(context).colorScheme.primary,
          ),
          SwitchListTile(
            title: Text('Show reading progress', style: TextStyle(color: titleColor)),
            value: settings.showReadingProgress,
            onChanged: (_) => notifier.toggleBool('showReadingProgress'),
            activeThumbColor: Theme.of(context).colorScheme.primary,
          ),
          SwitchListTile(
            title: Text('Badges in lists', style: TextStyle(color: titleColor)),
            value: settings.showListBadges,
            onChanged: (_) => notifier.toggleBool('showListBadges'),
            activeThumbColor: Theme.of(context).colorScheme.primary,
          ),

          // Details Section
          _SectionHeader(title: 'Details'),
          SwitchListTile(
            title: Text('Collapse long description', style: TextStyle(color: titleColor)),
            value: settings.collapseDescription,
            onChanged: (_) => notifier.toggleBool('collapseDescription'),
            activeThumbColor: Theme.of(context).colorScheme.primary,
          ),
          SwitchListTile(
            title: Text('Show pages thumbnails', style: TextStyle(color: titleColor)),
            value: settings.showPagesThumbnails,
            onChanged: (_) => notifier.toggleBool('showPagesThumbnails'),
            activeThumbColor: Theme.of(context).colorScheme.primary,
          ),
          ListTile(
            title: Text('Default tab', style: TextStyle(color: titleColor)),
            subtitle: Text(
              settings.defaultTab,
              style: TextStyle(color: subtitleColor),
            ),
            onTap: () => _showDefaultTabSelector(context, ref, settings, notifier),
          ),

          // Main Screen Section
          _SectionHeader(title: 'Main Screen'),
          ListTile(
            title: Text('Search suggestions', style: TextStyle(color: titleColor)),
            subtitle: Text(
              _suggestionSummary(settings),
              style: TextStyle(color: subtitleColor),
            ),
            onTap: () => _showSearchSuggestionsSheet(context, ref, settings, notifier),
          ),
          ListTile(
            title: Text('Main screen sections', style: TextStyle(color: titleColor)),
            subtitle: Text('Categories to show in the main screen', style: TextStyle(color: Colors.white54)),
            onTap: () => _showMainSectionsSheet(context, ref, settings, notifier),
          ),
          SwitchListTile(
            title: Text('Show floating Continue button', style: TextStyle(color: titleColor)),
            value: settings.showFloatingContinueButton,
            onChanged: (_) => notifier.toggleBool('showFloatingContinueButton'),
            activeThumbColor: Theme.of(context).colorScheme.primary,
          ),
          SwitchListTile(
            title: Text('Show labels in navigation bar', style: TextStyle(color: titleColor)),
            value: settings.showNavLabels,
            onChanged: (_) => notifier.toggleBool('showNavLabels'),
            activeThumbColor: Theme.of(context).colorScheme.primary,
          ),
          SwitchListTile(
            title: Text('Floating navigation bar', style: TextStyle(color: titleColor)),
            value: settings.useFloatingNavBar,
            onChanged: (_) => notifier.toggleBool('useFloatingNavBar'),
            activeThumbColor: Theme.of(context).colorScheme.primary,
          ),
          SwitchListTile(
            title: Text('Pin navigation UI', style: TextStyle(color: titleColor)),
            subtitle: Text(
              'Do not hide navigation bar and search view on scroll',
              style: TextStyle(color: subtitleColor),
            ),
            value: settings.pinNavUiOnScroll,
            onChanged: (_) => notifier.toggleBool('pinNavUiOnScroll'),
            activeThumbColor: Theme.of(context).colorScheme.primary,
          ),
          SwitchListTile(
            title: Text('Exit confirmation', style: TextStyle(color: titleColor)),
            subtitle: Text(
              'Press Back twice to exit the app',
              style: TextStyle(color: subtitleColor),
            ),
            value: settings.exitConfirmation,
            onChanged: (_) => notifier.toggleBool('exitConfirmation'),
            activeThumbColor: Theme.of(context).colorScheme.primary,
          ),
          SwitchListTile(
            title: Text('Show recent manga shortcuts', style: TextStyle(color: titleColor)),
            value: settings.showRecentShortcuts,
            onChanged: (_) => notifier.toggleBool('showRecentShortcuts'),
            activeThumbColor: Theme.of(context).colorScheme.primary,
          ),
          SwitchListTile(
            title: Text('Hide NSFW from shortcuts', style: TextStyle(color: titleColor)),
            value: settings.hideNsfwFromShortcuts,
            onChanged: (_) => notifier.toggleBool('hideNsfwFromShortcuts'),
            activeThumbColor: Theme.of(context).colorScheme.primary,
          ),

          // Privacy Section
          _SectionHeader(title: 'Privacy'),
          SwitchListTile(
            title: Text('Protect the app', style: TextStyle(color: titleColor)),
            subtitle: Text(
              'Require authentication to open Yomou',
              style: TextStyle(color: subtitleColor),
            ),
            value: settings.protectApp,
            onChanged: (v) => notifier.setProtectApp(v),
            activeThumbColor: Theme.of(context).colorScheme.primary,
          ),
          ListTile(
            title: Text('Screenshot policy', style: TextStyle(color: titleColor)),
            subtitle: Text(
              settings.screenshotPolicy,
              style: TextStyle(color: subtitleColor),
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    final sheetTitleColor =
        dark ? Colors.white : Theme.of(context).colorScheme.onSurface;
    showModalBottomSheet(
      context: context,
      backgroundColor: dark ? const Color(0xFF2E2E33) : Colors.white,
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
                color: dark ? Colors.white38 : Colors.black26,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Theme',
                style: TextStyle(color: sheetTitleColor, fontSize: 17, fontWeight: FontWeight.w600),
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      title: Text(label, style: TextStyle(color: dark ? Colors.white : Theme.of(context).colorScheme.onSurface)),
      trailing: mode == current
          ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    final sheetTitleColor =
        dark ? Colors.white : Theme.of(context).colorScheme.onSurface;

    showModalBottomSheet(
      context: context,
      backgroundColor: dark ? const Color(0xFF2E2E33) : Colors.white,
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
                color: dark ? Colors.white38 : Colors.black26,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Language',
                style: TextStyle(color: sheetTitleColor, fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ),
            for (var i = 0; i < languages.length; i++)
              ListTile(
                title: Text(labels[i], style: TextStyle(color: dark ? Colors.white : Theme.of(context).colorScheme.onSurface)),
                trailing: languages[i] == settings.language
                    ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    final sheetTitleColor =
        dark ? Colors.white : Theme.of(context).colorScheme.onSurface;
    showModalBottomSheet(
      context: context,
      backgroundColor: dark ? const Color(0xFF2E2E33) : Colors.white,
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
                color: dark ? Colors.white38 : Colors.black26,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'List mode',
                style: TextStyle(color: sheetTitleColor, fontSize: 17, fontWeight: FontWeight.w600),
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      title: Text(mode, style: TextStyle(color: dark ? Colors.white : Theme.of(context).colorScheme.onSurface)),
      trailing: mode == current
          ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    final sheetTitleColor =
        dark ? Colors.white : Theme.of(context).colorScheme.onSurface;

    showModalBottomSheet(
      context: context,
      backgroundColor: dark ? const Color(0xFF2E2E33) : Colors.white,
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
                color: dark ? Colors.white38 : Colors.black26,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Default tab',
                style: TextStyle(color: sheetTitleColor, fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ),
            for (final tab in tabs)
              ListTile(
                title: Text(tab, style: TextStyle(color: dark ? Colors.white : Theme.of(context).colorScheme.onSurface)),
                trailing: tab == settings.defaultTab
                    ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    final sheetTitleColor =
        dark ? Colors.white : Theme.of(context).colorScheme.onSurface;

    showModalBottomSheet(
      context: context,
      backgroundColor: dark ? const Color(0xFF2E2E33) : Colors.white,
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
                color: dark ? Colors.white38 : Colors.black26,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Search suggestions',
                style: TextStyle(color: sheetTitleColor, fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ),
            for (final entry in options.entries)
              SwitchListTile(
                title: Text(entry.value, style: TextStyle(color: dark ? Colors.white : Theme.of(context).colorScheme.onSurface)),
                value: settings.searchSuggestions[entry.key] ?? true,
                activeThumbColor: Theme.of(context).colorScheme.primary,
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    final sheetTitleColor =
        dark ? Colors.white : Theme.of(context).colorScheme.onSurface;
    showModalBottomSheet(
      context: context,
      backgroundColor: dark ? const Color(0xFF2E2E33) : Colors.white,
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
                color: dark ? Colors.white38 : Colors.black26,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Main screen sections',
                style: TextStyle(color: sheetTitleColor, fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ),
            for (final entry in settings.mainScreenSections.entries)
              SwitchListTile(
                title: Text(entry.key, style: TextStyle(color: dark ? Colors.white : Theme.of(context).colorScheme.onSurface)),
                value: entry.value,
                activeThumbColor: Theme.of(context).colorScheme.primary,
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    final sheetTitleColor =
        dark ? Colors.white : Theme.of(context).colorScheme.onSurface;

    showModalBottomSheet(
      context: context,
      backgroundColor: dark ? const Color(0xFF2E2E33) : Colors.white,
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
                color: dark ? Colors.white38 : Colors.black26,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Screenshot policy',
                style: TextStyle(color: sheetTitleColor, fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ),
            for (final policy in policies)
              ListTile(
                title: Text(policy, style: TextStyle(color: dark ? Colors.white : Theme.of(context).colorScheme.onSurface)),
                trailing: policy == settings.screenshotPolicy
                    ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: dark ? Colors.white.withValues(alpha: 0.5) : Colors.black54,
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 76,
        height: 90,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: isActive
              ? primary.withValues(alpha: 0.2)
              : dark ? const Color(0xFF2B2B2B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? primary : (dark ? Colors.white12 : Colors.black12),
            width: isActive ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isActive)
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primary,
                ),
                child: const Icon(
                  Icons.check,
                  size: 18,
                  color: Colors.white,
                ),
              )
            else
              _TwoToneBadge(
                primary: palette.accent,
                secondary: palette.secondary ?? palette.accentLight,
              ),
            const SizedBox(height: 6),
            Text(
              name,
              style: TextStyle(
                color: dark
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface,
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

/// A 28px circular badge split vertically into the preset's primary and
/// secondary/container colors.
class _TwoToneBadge extends StatelessWidget {
  const _TwoToneBadge({required this.primary, required this.secondary});

  final Color primary;
  final Color secondary;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: const BoxDecoration(shape: BoxShape.circle),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Expanded(child: Container(color: primary)),
          Expanded(child: Container(color: secondary)),
        ],
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