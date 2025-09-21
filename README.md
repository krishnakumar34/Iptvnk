# IPTV Flutter Starter (downloadable)

This is a minimal starter template for an IPTV player built with Flutter.
It uses `better_player` for HLS/DASH/MP4 playback, fetches a sample M3U,
allows searching channels, adding custom URLs, and marking favorites.

## What's included
- `lib/main.dart` : Main app with channel list, search, favorites, and player.
- `pubspec.yaml` : dependencies.

## How to use
1. Install Flutter SDK: https://docs.flutter.dev/get-started/install
2. Create a new Flutter project (or use an existing one):
   ```
   flutter create my_iptv_app
   ```
3. Replace the contents of `lib/main.dart` with the `lib/main.dart` from this template.
4. Replace `pubspec.yaml` dependencies section with the contents of this template's `pubspec.yaml`.
5. Run:
   ```
   flutter pub get
   flutter run   # to run on a connected device or emulator
   ```
6. To build a release APK (Android):
   ```
   flutter build apk --release
   ```
   See Flutter docs for signing the APK: https://docs.flutter.dev/deployment/android#signing-the-app

## Notes
- The sample M3U in main.dart points to a public GitHub-hosted playlist. Replace it with your own playlist URL.
- For Android TV layout adjustments, adapt the UI (Grid/Leanback).
- For advanced features (EPG, playlist import/export, parental controls), we'll add more code.

## Limitations
- I cannot build the final APK in this environment. You must run the Flutter build on your machine (or a cloud CI) following the steps above.

## Need help?
If you want, I can:
- Add EPG support (XMLTV parsing).
- Add category parsing for M3U groups.
- Add download/recording support (requires native plugins).
- Provide a CI config (GitHub Actions) to build APKs automatically.
