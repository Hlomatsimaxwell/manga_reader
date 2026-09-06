# Changelog

All notable changes to Yomou are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- Removed unused `liquid_glass_bar` / `liquid_glass_renderer` dependencies.

## [1.0.0+1] - 2026-09-06

### Added
- **Yomou branding** — renamed *Manga Reader* → *Yomou* across the app, bundle IDs (`com.hlomatsi.yomou`) and package imports.
- **Kotatsu-inspired tab navigation** — floating rounded bottom bar (72px) with animated Remix icons:
  - Outline → filled glyph + 5% scale + accent label on the active tab (fade/scale swap via `AnimatedSwitcher`).
  - Always-visible labels on all five tabs (History, Favorites, Suggestions, Explore, Updates).
  - Updates tab keeps its live unread-new-chapters badge.
- **Continue Reading FAB** — floating circular accent button on the History tab that resumes the latest chapter at the exact last-read page; cross-fades away on other tabs; spinner state while resolving.
- **Global accent theme** — `lib/core/theme/colors.dart` with `kAccentColor`, `kAccentLight`, `kAccentDark`, `kAccentSurface`.
- **Remix Icon dependency** (`remixicon: ^4.9.3`) powering the new nav glyphs.

### Changed
- Navigation materials reworked over several iterations before settling on the final design (previous glass pill / compact pill / FAB designs removed).
- Accent color swept from pink/green tone to a consistent **blue** across the Updates badge, feed highlights, history counts, detail-page play button, reader marker/slider/gradient/chips, and iOS switch tracks. Red is retained only for destructive actions and the favorite heart.
- FAB styling: liquid glass → solid blue accent circle.
- History continue action now lives solely in the Continue FAB (was previously reachable via the old nav FAB).

### Fixed
- Bottom-bar overflow when the active pill expanded.
- Nav label truncation on narrow screens (Favo…/Expl… no longer clipped).
- Removed duplicate `remixicon` entry in `pubspec.yaml`.
- `_buildNavItem` referenced a non-existent `IconData.onlyOneGlyph()` placeholder — replaced with the correct line/fill swap; orphaned FAB/continue code from the refactor removed.

### Removed
- Liquid glass UI (dependency references cleaned up): nav bar and FAB no longer use glass rendering.
- Old nav variants (icon-only compact pill, Kotatsu pill+badge) superseded by the final bar.

## Footnote

Build & release tooling
- CI produces an unsigned `.ipa` via `.github/workflows/build_ios.yml` for personal sideloading (LiveContainer / SideStore).
- Android debug APK: `flutter build apk --debug`.