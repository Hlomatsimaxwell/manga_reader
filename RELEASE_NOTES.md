# Release Notes — Yomou 1.0.0

**Kotatsu-style manga reading, now under its own name.** Yomou (formerly *Manga Reader*) brings a native-feeling reading experience to your phone.

<!-- TODO: add screenshots here -->

## What's New

- **A cleaner, animated bottom bar** — floating rounded bar with Remix icons that flip from outline to filled (with a fade + scale) on the active tab. Every tab keeps its label, and the active one glows in Yomou's accent blue.
- **Continue Reading FAB** — sitting above the bar on your History tab; one tap and you're back in the exact chapter/page you left off.
- **Live Updates badge** — the Updates tab shows a count of manga with unread new chapters.
- **A consistent blue accent** — swept through the Updates badge, feed highlights, history counts, the reader's progress marker, sliders, chips, and iOS-style switches. Red stays reserved for destructive actions and the favorite heart.
- **Now branded Yomou** — new name, new bundle ID (`com.hlomatsi.yomou`), same reading engine.

## Stay in Your Library

- Read across multiple sources — MangaDex, Manganato, Mangakatana, WeebCentral (+ a mock for offline dev).
- Track everything: favorites, reading history with search/filters/sorting/date groups, and per-title progress rings.
- Download chapters to read offline; we cache source data so reopening is instant.

## Install

**Android**
```
flutter build apk --release
```
or grab a debug APK from `build/app/outputs/flutter-apk/`.

**iOS (personal sideload only)**
1. From the repo's **Actions** tab, run the *Build iOS* workflow (or push to `main`).
2. Download `manga_reader_unsigned.ipa` from the run's artifacts.
3. Import it into **LiveContainer** (or sign & install with SideStore).

> The app pulls content from third-party sources — keep builds personal/dev-only.

## Known Issues

- Signed-up SideStore / in-app Apple-ID login can crash on current nightlies (upstream issue); use LiveContainer or the anisette workaround.
- Sources depend on third-party sites; a source going offline temporarily breaks its section.

## Thanks

Icons: [Remix Icon](https://remixicon.com/) · Design cues: [Kotatsu](https://github.com/KotatsuApp/Kotatsu) · Sideloading: [LiveContainer](https://github.com/kazeus/LiveContainer) & [SideStore](https://sidestore.io/)