import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remixicon/remixicon.dart';
import 'package:yomou/features/settings/providers/appearance_provider.dart';
import 'package:yomou/l10n/generated/app_localizations.dart';

class AppearanceSettingsScreen extends ConsumerWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appearanceSettingsProvider);
    final notifier = ref.read(appearanceSettingsProvider.notifier);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final l = AppLocalizations.of(context);
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
          icon: Icon(RemixIcons.arrow_left_line, color: appBarContentColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l.appearanceTitle,
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
          _SectionHeader(title: l.appearanceColorScheme),
          SizedBox(
            height: 90,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
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
                _SchemePreset(
                  name: 'Monochrome',
                  palette: schemePalettes[AppColorScheme.monochrome]!,
                  isActive: settings.colorScheme == 'Monochrome',
                  onTap: () => notifier.setColorScheme('Monochrome'),
                ),
              ],
            ),
          ),

          // Theme Options
          _SectionHeader(title: l.appearanceSectionThemeOptions),
          ListTile(
            title: Text(l.appearanceThemeTitle, style: TextStyle(color: titleColor)),
            subtitle: Text(
              _themeModeLabel(l, settings.themeMode),
              style: TextStyle(color: subtitleColor),
            ),
            onTap: () => _showThemeModeSelector(context, ref, settings, notifier),
          ),
          ListTile(
            title: Text(l.appearanceLanguageTitle, style: TextStyle(color: titleColor)),
            subtitle: Text(
              _languageLabel(l, settings.language),
              style: TextStyle(color: subtitleColor),
            ),
            onTap: () => _showLanguageSelector(context, ref, settings, notifier),
          ),

          // Manga List Section
          _SectionHeader(title: l.appearanceSectionMangaList),
          ListTile(
            title: Text(l.appearanceListModeTitle, style: TextStyle(color: titleColor)),
            subtitle: Text(
              _listModeLabel(l, settings.listMode),
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
                  l.appearanceGridSize(settings.gridSize.round()),
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
            title: Text(l.appearanceQuickFilters, style: TextStyle(color: titleColor)),
            value: settings.showQuickFilters,
            onChanged: (_) => notifier.toggleBool('showQuickFilters'),
            activeThumbColor: Theme.of(context).colorScheme.primary,
          ),
          SwitchListTile(
            title: Text(l.appearanceReadingProgress, style: TextStyle(color: titleColor)),
            value: settings.showReadingProgress,
            onChanged: (_) => notifier.toggleBool('showReadingProgress'),
            activeThumbColor: Theme.of(context).colorScheme.primary,
          ),
          SwitchListTile(
            title: Text(l.appearanceBadges, style: TextStyle(color: titleColor)),
            value: settings.showListBadges,
            onChanged: (_) => notifier.toggleBool('showListBadges'),
            activeThumbColor: Theme.of(context).colorScheme.primary,
          ),

          // Details Section
          _SectionHeader(title: l.appearanceDetails),
          SwitchListTile(
            title: Text(l.appearanceCollapseDescription, style: TextStyle(color: titleColor)),
            value: settings.collapseDescription,
            onChanged: (_) => notifier.toggleBool('collapseDescription'),
            activeThumbColor: Theme.of(context).colorScheme.primary,
          ),
          SwitchListTile(
            title: Text(l.appearancePagesThumbnails, style: TextStyle(color: titleColor)),
            value: settings.showPagesThumbnails,
            onChanged: (_) => notifier.toggleBool('showPagesThumbnails'),
            activeThumbColor: Theme.of(context).colorScheme.primary,
          ),
          ListTile(
            title: Text(l.appearanceDefaultTabTitle, style: TextStyle(color: titleColor)),
            subtitle: Text(
              _tabLabel(l, settings.defaultTab),
              style: TextStyle(color: subtitleColor),
            ),
            onTap: () => _showDefaultTabSelector(context, ref, settings, notifier),
          ),

          // Main Screen Section
          _SectionHeader(title: l.appearanceSectionMainScreen),
          ListTile(
            title: Text(l.appearanceSearchSuggestionsTitle, style: TextStyle(color: titleColor)),
            subtitle: Text(
              _suggestionSummary(context, settings),
              style: TextStyle(color: subtitleColor),
            ),
            onTap: () => _showSearchSuggestionsSheet(context, ref, settings, notifier),
          ),
          ListTile(
            title: Text(l.appearanceMainSectionsTitle, style: TextStyle(color: titleColor)),
            subtitle: Text(l.appearanceMainSectionsSubtitle, style: TextStyle(color: subtitleColor)),
            onTap: () => _showMainSectionsSheet(context, ref, settings, notifier),
          ),
          SwitchListTile(
            title: Text(l.appearanceFloatingContinue, style: TextStyle(color: titleColor)),
            value: settings.showFloatingContinueButton,
            onChanged: (_) => notifier.toggleBool('showFloatingContinueButton'),
            activeThumbColor: Theme.of(context).colorScheme.primary,
          ),
          SwitchListTile(
            title: Text(l.appearanceNavLabels, style: TextStyle(color: titleColor)),
            value: settings.showNavLabels,
            onChanged: (_) => notifier.toggleBool('showNavLabels'),
            activeThumbColor: Theme.of(context).colorScheme.primary,
          ),
          SwitchListTile(
            title: Text(l.appearanceFloatingNav, style: TextStyle(color: titleColor)),
            value: settings.useFloatingNavBar,
            onChanged: (_) => notifier.toggleBool('useFloatingNavBar'),
            activeThumbColor: Theme.of(context).colorScheme.primary,
          ),
          SwitchListTile(
            title: Text(l.appearancePinNav, style: TextStyle(color: titleColor)),
            subtitle: Text(
              l.appearancePinNavSubtitle,
              style: TextStyle(color: subtitleColor),
            ),
            value: settings.pinNavUiOnScroll,
            onChanged: (_) => notifier.toggleBool('pinNavUiOnScroll'),
            activeThumbColor: Theme.of(context).colorScheme.primary,
          ),
          SwitchListTile(
            title: Text(l.appearanceExitConfirmation, style: TextStyle(color: titleColor)),
            subtitle: Text(
              l.appearanceExitConfirmationSubtitle,
              style: TextStyle(color: subtitleColor),
            ),
            value: settings.exitConfirmation,
            onChanged: (_) => notifier.toggleBool('exitConfirmation'),
            activeThumbColor: Theme.of(context).colorScheme.primary,
          ),
          SwitchListTile(
            title: Text(l.appearanceRecentShortcuts, style: TextStyle(color: titleColor)),
            value: settings.showRecentShortcuts,
            onChanged: (_) => notifier.toggleBool('showRecentShortcuts'),
            activeThumbColor: Theme.of(context).colorScheme.primary,
          ),
          SwitchListTile(
            title: Text(l.appearanceHideNsfwShortcuts, style: TextStyle(color: titleColor)),
            value: settings.hideNsfwFromShortcuts,
            onChanged: (_) => notifier.toggleBool('hideNsfwFromShortcuts'),
            activeThumbColor: Theme.of(context).colorScheme.primary,
          ),

          // Privacy Section
          _SectionHeader(title: l.appearancePrivacy),
          SwitchListTile(
            title: Text(l.appearanceProtectApp, style: TextStyle(color: titleColor)),
            subtitle: Text(
              l.appearanceProtectAppSubtitle,
              style: TextStyle(color: subtitleColor),
            ),
            value: settings.protectApp,
            onChanged: (v) => notifier.setProtectApp(v),
            activeThumbColor: Theme.of(context).colorScheme.primary,
          ),
          ListTile(
            title: Text(l.appearanceScreenshotPolicyTitle, style: TextStyle(color: titleColor)),
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
                AppLocalizations.of(context).appearanceThemeTitle,
                style: TextStyle(color: sheetTitleColor, fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ),
            _buildThemeOption(context, AppLocalizations.of(context).appearanceThemeSystem, ThemeMode.system, settings.themeMode, notifier),
            _buildThemeOption(context, AppLocalizations.of(context).appearanceThemeLight, ThemeMode.light, settings.themeMode, notifier),
            _buildThemeOption(context, AppLocalizations.of(context).appearanceThemeDark, ThemeMode.dark, settings.themeMode, notifier),
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
          ? Icon(RemixIcons.check_line, color: Theme.of(context).colorScheme.primary)
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
    final l = AppLocalizations.of(context);
    final languages = [
      'system', 'en', 'es', 'fr', 'de', 'pt', 'it', 'ru', 'ja', 'ko', 'zh', 'ar', 'hi',
    ];
    final labels = [
      l.languageFollowSystem, l.languageEn, l.languageEs, l.languageFr, l.languageDe,
      l.languagePt, l.languageIt, l.languageRu, l.languageJa, l.languageKo, l.languageZh,
      l.languageAr, l.languageHi,
    ];
    final dark = Theme.of(context).brightness == Brightness.dark;
    final sheetTitleColor =
        dark ? Colors.white : Theme.of(context).colorScheme.onSurface;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
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
                AppLocalizations.of(context).appearanceLanguageTitle,
                style: TextStyle(color: sheetTitleColor, fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ),
            Flexible(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(ctx).height * 0.5,
                ),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (var i = 0; i < languages.length; i++)
                      ListTile(
                        title: Text(labels[i], style: TextStyle(color: dark ? Colors.white : Theme.of(context).colorScheme.onSurface)),
                        trailing: languages[i] == settings.language
                            ? Icon(RemixIcons.check_line, color: Theme.of(context).colorScheme.primary)
                            : null,
                        onTap: () {
                          notifier.setLanguage(languages[i]);
                          Navigator.pop(ctx);
                        },
                      ),
                  ],
                ),
              ),
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
                AppLocalizations.of(context).appearanceListModeTitle,
                style: TextStyle(color: sheetTitleColor, fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ),
            _buildListModeOption(context, AppLocalizations.of(context).listModeGrid, 'Grid', settings.listMode, notifier),
            _buildListModeOption(context, AppLocalizations.of(context).listModeList, 'List', settings.listMode, notifier),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildListModeOption(
    BuildContext context,
    String label,
    String mode,
    String current,
    AppearanceSettingsNotifier notifier,
  ) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      title: Text(label, style: TextStyle(color: dark ? Colors.white : Theme.of(context).colorScheme.onSurface)),
      trailing: mode == current
          ? Icon(RemixIcons.check_line, color: Theme.of(context).colorScheme.primary)
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
    final l = AppLocalizations.of(context);
    final tabs = [
      ('Last used', l.defaultTabLastUsed),
      ('History', l.defaultTabHistory),
      ('Favorites', l.defaultTabFavorites),
      ('Suggestions', l.defaultTabSuggestions),
      ('Explore', l.defaultTabExplore),
      ('Updates', l.defaultTabUpdates),
    ];
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
                l.appearanceDefaultTabTitle,
                style: TextStyle(color: sheetTitleColor, fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ),
            for (final tab in tabs)
              ListTile(
                title: Text(tab.$2, style: TextStyle(color: dark ? Colors.white : Theme.of(context).colorScheme.onSurface)),
                trailing: tab.$1 == settings.defaultTab
                    ? Icon(RemixIcons.check_line, color: Theme.of(context).colorScheme.primary)
                    : null,
                onTap: () {
                  notifier.setDefaultTab(tab.$1);
                  Navigator.pop(ctx);
                },
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _themeModeLabel(AppLocalizations l, ThemeMode mode) => switch (mode) {
        ThemeMode.system => l.appearanceThemeSystem,
        ThemeMode.light => l.appearanceThemeLight,
        ThemeMode.dark => l.appearanceThemeDark,
      };

  String _languageLabel(AppLocalizations l, String code) {
    if (code == 'system') return l.languageFollowSystem;
    return switch (code) {
      'en' => l.languageEn,
      'es' => l.languageEs,
      'fr' => l.languageFr,
      'de' => l.languageDe,
      'pt' => l.languagePt,
      'it' => l.languageIt,
      'ru' => l.languageRu,
      'ja' => l.languageJa,
      'ko' => l.languageKo,
      'zh' => l.languageZh,
      'ar' => l.languageAr,
      'hi' => l.languageHi,
      _ => code,
    };
  }

  String _listModeLabel(AppLocalizations l, String mode) =>
      mode == 'Grid' ? l.listModeGrid : l.listModeList;

  String _tabLabel(AppLocalizations l, String tab) => switch (tab) {
        'Last used' => l.defaultTabLastUsed,
        'History' => l.defaultTabHistory,
        'Favorites' => l.defaultTabFavorites,
        'Suggestions' => l.defaultTabSuggestions,
        'Explore' => l.defaultTabExplore,
        'Updates' => l.defaultTabUpdates,
        _ => tab,
      };

  String _suggestionSummary(BuildContext context, AppearanceSettings settings) {
    final l = AppLocalizations.of(context);
    final codeToLabel = {
      'history': l.suggestionHistory,
      'trending': l.suggestionTrending,
      'new': l.suggestionNew,
      'popular': l.suggestionPopular,
    };
    final enabled = settings.searchSuggestions.entries
        .where((e) => e.value)
        .map((e) => codeToLabel[e.key] ?? e.key.capitalize())
        .toList();
    return enabled.isEmpty ? AppLocalizations.of(context).appearanceNone : enabled.join(', ');
  }

  void _showSearchSuggestionsSheet(
    BuildContext context,
    WidgetRef ref,
    AppearanceSettings settings,
    AppearanceSettingsNotifier notifier,
  ) {
    final l = AppLocalizations.of(context);
    const optionKeys = ['history', 'trending', 'new', 'popular'];
    final optionLabels = [
      l.suggestionHistory,
      l.suggestionTrending,
      l.suggestionNew,
      l.suggestionPopular,
    ];
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
                l.appearanceSearchSuggestionsTitle,
                style: TextStyle(color: sheetTitleColor, fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ),
            for (var i = 0; i < optionKeys.length; i++)
              SwitchListTile(
                title: Text(optionLabels[i], style: TextStyle(color: dark ? Colors.white : Theme.of(context).colorScheme.onSurface)),
                value: settings.searchSuggestions[optionKeys[i]] ?? true,
                activeThumbColor: Theme.of(context).colorScheme.primary,
                onChanged: (_) => notifier.toggleSearchSuggestion(optionKeys[i]),
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
    final l = AppLocalizations.of(context);
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
                AppLocalizations.of(context).appearanceMainSectionsTitle,
                style: TextStyle(color: sheetTitleColor, fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ),
            for (final entry in settings.mainScreenSections.entries)
              SwitchListTile(
                title: Text(
                  _tabLabel(l, entry.key),
                  style: TextStyle(
                    color: dark
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
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
    final l = AppLocalizations.of(context);
    const policyCodes = ['Allow', 'Block'];
    final policyLabels = [l.screenshotPolicyAllow, l.screenshotPolicyBlock];
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
                l.appearanceScreenshotPolicyTitle,
                style: TextStyle(color: sheetTitleColor, fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ),
            for (var i = 0; i < policyCodes.length; i++)
              ListTile(
                title: Text(policyLabels[i], style: TextStyle(color: dark ? Colors.white : Theme.of(context).colorScheme.onSurface)),
                trailing: policyCodes[i] == settings.screenshotPolicy
                    ? Icon(RemixIcons.check_line, color: Theme.of(context).colorScheme.primary)
                    : null,
                onTap: () {
                  notifier.setScreenshotPolicy(policyCodes[i]);
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
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    final isMonochrome = name == 'Monochrome';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 82,
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
                child: Icon(
                  RemixIcons.check_line,
                  size: 18,
                  color: onPrimary,
                ),
              )
            else
              _TwoToneBadge(
                // Monochrome's two-tone pair flips with brightness:
                // white/gray on dark, black/gray on light.
                primary: isMonochrome
                    ? (dark ? Colors.white : Colors.black)
                    : palette.accent,
                secondary: isMonochrome
                    ? (dark ? const Color(0xFF888888) : const Color(0xFF666666))
                    : (palette.secondary ?? palette.accentLight),
              ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  name,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: dark
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurface,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
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