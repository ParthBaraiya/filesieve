# Changelog

All notable changes to this project are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow the `version` in `pubspec.yaml`.

## [1.0.1] - 2026-11-16

### Changed
- Renamed the app from FileSieve to Dedupe in all user-visible places (window titles, launcher labels, web manifest, MSIX display name, README). Bundle and application identifiers (`com.binatesolutions.filesieve`) and the Dart package name are unchanged.
- Replaced the local `fs_file` utilities with the `omnifile` package.
- Title bar now shows the app icon instead of the filter glyph.

### Updated
- Regenerated all platform icons (macOS, iOS, Android, web, Windows) from the new 1024px app icon.

## [1.0.0] - 2026-11-12

### Added
- Redesigned glass-style app shell and sidebar, with a Dedupe palette, dark theme and light, dark or system theme setting.
- Scan setup screen with folder selection, options to skip hidden files and ignore subfolders, and a restyled scan progress screen with phase cards and live counters.
- Scan results: duplicate groups list, side-by-side compare view with file preview, confirmation dialog and toast.
- File removal with OS trash, restore and permanent delete.
- Settings for removal mode, watched folders, appearance and reset.
- Lists every scanned file and shows per-folder file counts.
- Windows MSIX packaging and installer.
