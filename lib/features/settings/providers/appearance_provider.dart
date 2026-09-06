import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Named color schemes matching Kotatsu's preset themes.
enum AppColorScheme { totoro, dynamic, expressive, miku }

/// Palettes for each named scheme: (accent, accentLight, accentDark, surface).
class SchemePalette {
  const SchemePalette(
      {required this.accent,
      required this.accentLight,
      required this.accentDark,
      required this.surface});

  final Color accent;
  final Color accentLight;
  final Color accentDark;
  final Color surface;
}

const Map<AppColorScheme, SchemePalette> schemePalettes = {
  AppColorScheme.totoro: SchemePalette(
    accent: Color(0xFF4C8DFF),
    accentLight: Color(0xFFA5C8FF),
    accentDark: Color(0xFF2B5CE6),
    surface: Color(0xFF22304D),
  ),
  AppColorScheme.dynamic: SchemePalette(
    accent: Color(0xFF7C5AFF),
    accentLight: Color(0xFFB8A9FF),
    accentDark: Color(0xFF5435CC),
    surface: Color(0xFF2D2542),
  ),
  AppColorScheme.expressive: SchemePalette(
    accent: Color(0xFFFF7043),
    accentLight: Color(0xFFFFAB91),
    accentDark: Color(0xFFE64A19),
    surface: Color(0xFF3E2620),
  ),
  AppColorScheme.miku: SchemePalette(
    accent: Color(0xFF3DDC84),
    accentLight: Color(0xFF8AF4B0),
    accentDark: Color(0xFF1BA25A),
    surface: Color(0xFF1A3326),
  ),
};

/// Returns the palette for the current scheme name.
SchemePalette paletteForScheme(String name) {
  final scheme = AppColorScheme.values.firstWhere(
    (s) => s.name == name,
    orElse: () => AppColorScheme.totoro,
  );
  return schemePalettes[scheme]!;
}

// ---------------------------------------------------------------------------
// Settings model
// ---------------------------------------------------------------------------

class AppearanceSettings {
  const AppearanceSettings({
    required this.colorScheme,
    required this.themeMode,
    required this.pureBlackAmoled,
    required this.listMode,
    required this.gridSize,
    required this.showQuickFilters,
    required this.showReadingProgress,
    required this.showListBadges,
    required this.collapseDescription,
    required this.showPagesThumbnails,
    required this.showFloatingContinueButton,
    required this.showNavLabels,
    required this.useFloatingNavBar,
    required this.pinNavUiOnScroll,
    required this.exitConfirmation,
    required this.showRecentShortcuts,
    required this.hideNsfwFromShortcuts,
    required this.language,
    required this.defaultTab,
    required this.searchSuggestions,
    required this.mainScreenSections,
    required this.protectApp,
    required this.screenshotPolicy,
  });

  // All requested defaults from spec
  factory AppearanceSettings.defaults() => const AppearanceSettings(
        colorScheme: 'Totoro',
        themeMode: ThemeMode.system,
        pureBlackAmoled: true,
        listMode: 'Grid',
        gridSize: 100,
        showQuickFilters: true,
        showReadingProgress: true,
        showListBadges: true,
        collapseDescription: true,
        showPagesThumbnails: true,
        showFloatingContinueButton: true,
        showNavLabels: true,
        useFloatingNavBar: true,
        pinNavUiOnScroll: false,
        exitConfirmation: true,
        showRecentShortcuts: true,
        hideNsfwFromShortcuts: true,
        language: 'system',
        defaultTab: 'Last used',
        searchSuggestions: {
          'history': true,
          'trending': true,
          'new': true,
          'popular': true,
        },
        mainScreenSections: {
          'History': true,
          'Favorites': true,
          'Suggestions': true,
          'Explore': true,
          'Updates': true,
        },
        protectApp: false,
        screenshotPolicy: 'Allow',
      );

  final String colorScheme;
  final ThemeMode themeMode;
  final bool pureBlackAmoled;
  final String listMode;
  final double gridSize; // 50-150 (% of normal)
  final bool showQuickFilters;
  final bool showReadingProgress;
  final bool showListBadges;
  final bool collapseDescription;
  final bool showPagesThumbnails;
  final bool showFloatingContinueButton;
  final bool showNavLabels;
  final bool useFloatingNavBar;
  final bool pinNavUiOnScroll;
  final bool exitConfirmation;
  final bool showRecentShortcuts;
  final bool hideNsfwFromShortcuts;
  final String language;
  final String defaultTab;
  final Map<String, bool> searchSuggestions;
  final Map<String, bool> mainScreenSections;
  final bool protectApp;
  final String screenshotPolicy;

  AppearanceSettings copyWith({
    String? colorScheme,
    ThemeMode? themeMode,
    bool? pureBlackAmoled,
    String? listMode,
    double? gridSize,
    bool? showQuickFilters,
    bool? showReadingProgress,
    bool? showListBadges,
    bool? collapseDescription,
    bool? showPagesThumbnails,
    bool? showFloatingContinueButton,
    bool? showNavLabels,
    bool? useFloatingNavBar,
    bool? pinNavUiOnScroll,
    bool? exitConfirmation,
    bool? showRecentShortcuts,
    bool? hideNsfwFromShortcuts,
    String? language,
    String? defaultTab,
    Map<String, bool>? searchSuggestions,
    Map<String, bool>? mainScreenSections,
    bool? protectApp,
    String? screenshotPolicy,
  }) =>
      AppearanceSettings(
        colorScheme: colorScheme ?? this.colorScheme,
        themeMode: themeMode ?? this.themeMode,
        pureBlackAmoled: pureBlackAmoled ?? this.pureBlackAmoled,
        listMode: listMode ?? this.listMode,
        gridSize: gridSize ?? this.gridSize,
        showQuickFilters: showQuickFilters ?? this.showQuickFilters,
        showReadingProgress: showReadingProgress ?? this.showReadingProgress,
        showListBadges: showListBadges ?? this.showListBadges,
        collapseDescription: collapseDescription ?? this.collapseDescription,
        showPagesThumbnails:
            showPagesThumbnails ?? this.showPagesThumbnails,
        showFloatingContinueButton:
            showFloatingContinueButton ?? this.showFloatingContinueButton,
        showNavLabels: showNavLabels ?? this.showNavLabels,
        useFloatingNavBar: useFloatingNavBar ?? this.useFloatingNavBar,
        pinNavUiOnScroll: pinNavUiOnScroll ?? this.pinNavUiOnScroll,
        exitConfirmation: exitConfirmation ?? this.exitConfirmation,
        showRecentShortcuts:
            showRecentShortcuts ?? this.showRecentShortcuts,
        hideNsfwFromShortcuts:
            hideNsfwFromShortcuts ?? this.hideNsfwFromShortcuts,
        language: language ?? this.language,
        defaultTab: defaultTab ?? this.defaultTab,
        searchSuggestions:
            searchSuggestions ?? this.searchSuggestions,
        mainScreenSections:
            mainScreenSections ?? this.mainScreenSections,
        protectApp: protectApp ?? this.protectApp,
        screenshotPolicy: screenshotPolicy ?? this.screenshotPolicy,
      );
}

// ---------------------------------------------------------------------------
// Persistence helpers
// ---------------------------------------------------------------------------

class _AppearancePersistence {
  static const _prefix = 'appearance.';
  static const _colorScheme = '${_prefix}colorScheme';
  static const _themeMode = '${_prefix}themeMode';
  static const _pureBlack = '${_prefix}pureBlack';
  static const _listMode = '${_prefix}listMode';
  static const _gridSize = '${_prefix}gridSize';
  static const _showQuickFilters = '${_prefix}showQuickFilters';
  static const _showReadingProgress = '${_prefix}showReadingProgress';
  static const _showListBadges = '${_prefix}showListBadges';
  static const _collapseDescription = '${_prefix}collapseDescription';
  static const _showPagesThumbnails = '${_prefix}showPagesThumbnails';
  static const _showFab = '${_prefix}showFab';
  static const _showLabels = '${_prefix}showLabels';
  static const _floatingBar = '${_prefix}floatingBar';
  static const _pinScroll = '${_prefix}pinScroll';
  static const _exitConfirm = '${_prefix}exitConfirm';
  static const _recentShortcuts = '${_prefix}recentShortcuts';
  static const _hideNsfwShortcuts = '${_prefix}hideNsfwShortcuts';
  static const _language = '${_prefix}language';
  static const _defaultTab = '${_prefix}defaultTab';
  static const _searchSuggestions = '${_prefix}searchSuggestions';
  static const _mainSections = '${_prefix}mainSections';
  static const _protectApp = '${_prefix}protectApp';
  static const _screenshotPolicy = '${_prefix}screenshotPolicy';

  static Future<AppearanceSettings> load() async {
    final p = await SharedPreferences.getInstance();
    final themeModeStr = p.getString(_themeMode) ?? '';
    final themeMode = ThemeMode.values.asNameMap()[themeModeStr] ?? ThemeMode.system;

    return AppearanceSettings(
      colorScheme: p.getString(_colorScheme) ?? 'Totoro',
      themeMode: themeMode,
      pureBlackAmoled: p.getBool(_pureBlack) ?? true,
      listMode: p.getString(_listMode) ?? 'Grid',
      gridSize: p.getDouble(_gridSize) ?? 100,
      showQuickFilters: p.getBool(_showQuickFilters) ?? true,
      showReadingProgress: p.getBool(_showReadingProgress) ?? true,
      showListBadges: p.getBool(_showListBadges) ?? true,
      collapseDescription: p.getBool(_collapseDescription) ?? true,
      showPagesThumbnails: p.getBool(_showPagesThumbnails) ?? true,
      showFloatingContinueButton: p.getBool(_showFab) ?? true,
      showNavLabels: p.getBool(_showLabels) ?? true,
      useFloatingNavBar: p.getBool(_floatingBar) ?? true,
      pinNavUiOnScroll: p.getBool(_pinScroll) ?? false,
      exitConfirmation: p.getBool(_exitConfirm) ?? true,
      showRecentShortcuts: p.getBool(_recentShortcuts) ?? true,
      hideNsfwFromShortcuts: p.getBool(_hideNsfwShortcuts) ?? true,
      language: p.getString(_language) ?? 'system',
      defaultTab: p.getString(_defaultTab) ?? 'Last used',
      searchSuggestions: _decodeMap(p.getString(_searchSuggestions)) ??
          AppearanceSettings.defaults().searchSuggestions,
      mainScreenSections: _decodeMap(p.getString(_mainSections)) ??
          AppearanceSettings.defaults().mainScreenSections,
      protectApp: p.getBool(_protectApp) ?? false,
      screenshotPolicy: p.getString(_screenshotPolicy) ?? 'Allow',
    );
  }

  static Future<void> save(AppearanceSettings s) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_colorScheme, s.colorScheme);
    await p.setString(_themeMode, s.themeMode.name);
    await p.setBool(_pureBlack, s.pureBlackAmoled);
    await p.setString(_listMode, s.listMode);
    await p.setDouble(_gridSize, s.gridSize);
    await p.setBool(_showQuickFilters, s.showQuickFilters);
    await p.setBool(_showReadingProgress, s.showReadingProgress);
    await p.setBool(_showListBadges, s.showListBadges);
    await p.setBool(_collapseDescription, s.collapseDescription);
    await p.setBool(_showPagesThumbnails, s.showPagesThumbnails);
    await p.setBool(_showFab, s.showFloatingContinueButton);
    await p.setBool(_showLabels, s.showNavLabels);
    await p.setBool(_floatingBar, s.useFloatingNavBar);
    await p.setBool(_pinScroll, s.pinNavUiOnScroll);
    await p.setBool(_exitConfirm, s.exitConfirmation);
    await p.setBool(_recentShortcuts, s.showRecentShortcuts);
    await p.setBool(_hideNsfwShortcuts, s.hideNsfwFromShortcuts);
    await p.setString(_language, s.language);
    await p.setString(_defaultTab, s.defaultTab);
    await p.setString(_searchSuggestions, jsonEncode(s.searchSuggestions));
    await p.setString(_mainSections, jsonEncode(s.mainScreenSections));
    await p.setBool(_protectApp, s.protectApp);
    await p.setString(_screenshotPolicy, s.screenshotPolicy);
  }

  static Map<String, bool>? _decodeMap(String? json) {
    if (json == null) return null;
    try {
      return (jsonDecode(json) as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, v == true));
    } catch (_) {
      return null;
    }
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class AppearanceSettingsNotifier extends StateNotifier<AppearanceSettings> {
  AppearanceSettingsNotifier() : super(AppearanceSettings.defaults()) {
    _load();
  }

  Future<void> _load() async {
    state = await _AppearancePersistence.load();
  }

  Future<void> _persist() async => _AppearancePersistence.save(state);

  // Generic setter — mutate the settings from the current state, then persist.
  Future<void> set(
      AppearanceSettings Function(AppearanceSettings s) update) async {
    state = update(state);
    await _persist();
  }

  // Convenience setters for common types
  Future<void> setColorScheme(String name) async =>
      set((s) => s.copyWith(colorScheme: name));
  Future<void> setThemeMode(ThemeMode mode) async =>
      set((s) => s.copyWith(themeMode: mode));
  Future<void> toggleBool(String key) async {
    switch (key) {
      case 'pureBlackAmoled':
        set((s) => s.copyWith(pureBlackAmoled: !s.pureBlackAmoled));
      case 'showQuickFilters':
        set((s) => s.copyWith(showQuickFilters: !s.showQuickFilters));
      case 'showReadingProgress':
        set((s) => s.copyWith(showReadingProgress: !s.showReadingProgress));
      case 'showListBadges':
        set((s) => s.copyWith(showListBadges: !s.showListBadges));
      case 'collapseDescription':
        set((s) => s.copyWith(collapseDescription: !s.collapseDescription));
      case 'showPagesThumbnails':
        set((s) => s.copyWith(showPagesThumbnails: !s.showPagesThumbnails));
      case 'showFloatingContinueButton':
        set((s) => s.copyWith(
            showFloatingContinueButton: !s.showFloatingContinueButton));
      case 'showNavLabels':
        set((s) => s.copyWith(showNavLabels: !s.showNavLabels));
      case 'useFloatingNavBar':
        set((s) => s.copyWith(useFloatingNavBar: !s.useFloatingNavBar));
      case 'pinNavUiOnScroll':
        set((s) => s.copyWith(pinNavUiOnScroll: !s.pinNavUiOnScroll));
      case 'exitConfirmation':
        set((s) => s.copyWith(exitConfirmation: !s.exitConfirmation));
      case 'showRecentShortcuts':
        set((s) => s.copyWith(showRecentShortcuts: !s.showRecentShortcuts));
      case 'hideNsfwFromShortcuts':
        set(
            (s) => s.copyWith(hideNsfwFromShortcuts: !s.hideNsfwFromShortcuts));
    }
  }

  Future<void> setListMode(String mode) async =>
      set((s) => s.copyWith(listMode: mode));
  Future<void> setGridSize(double size) async =>
      set((s) => s.copyWith(gridSize: size));
  Future<void> setLanguage(String lang) async =>
      set((s) => s.copyWith(language: lang));
  Future<void> setDefaultTab(String tab) async =>
      set((s) => s.copyWith(defaultTab: tab));
  Future<void> toggleSearchSuggestion(String key) async {
    final map = Map<String, bool>.from(state.searchSuggestions);
    map[key] = !(map[key] ?? true);
    set((s) => s.copyWith(searchSuggestions: map));
  }

  Future<void> toggleMainSection(String key) async {
    final map = Map<String, bool>.from(state.mainScreenSections);
    map[key] = !(map[key] ?? true);
    set((s) => s.copyWith(mainScreenSections: map));
  }

  Future<void> setProtectApp(bool value) async =>
      set((s) => s.copyWith(protectApp: value));

  Future<void> setScreenshotPolicy(String policy) async =>
      set((s) => s.copyWith(screenshotPolicy: policy));
}

final appearanceSettingsProvider =
    StateNotifierProvider<AppearanceSettingsNotifier, AppearanceSettings>(
        (ref) => AppearanceSettingsNotifier());

/// Derived accent color for the app based on the active [appearanceSettingsProvider].
final accentProvider = Provider<Color>((ref) {
  final schemeName = ref.watch(appearanceSettingsProvider).colorScheme;
  return paletteForScheme(schemeName).accent;
});

final accentLightProvider = Provider<Color>((ref) {
  final schemeName = ref.watch(appearanceSettingsProvider).colorScheme;
  return paletteForScheme(schemeName).accentLight;
});

final accentDarkProvider = Provider<Color>((ref) {
  final schemeName = ref.watch(appearanceSettingsProvider).colorScheme;
  return paletteForScheme(schemeName).accentDark;
});

final accentSurfaceProvider = Provider<Color>((ref) {
  final schemeName = ref.watch(appearanceSettingsProvider).colorScheme;
  return paletteForScheme(schemeName).surface;
});