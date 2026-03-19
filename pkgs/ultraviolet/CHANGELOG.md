# Changelog

## Unreleased

### Changed

- `TerminalCapabilities` now tracks exact kitty keyboard enhancement flags plus foreground, background, cursor, and palette color reports with idempotent updates.
- `Terminal` startup capability probing now queries foreground and cursor colors in addition to the existing background, keyboard, device-attribute, and kitty-graphics probes.

### Fixed

- Added lifecycle coverage for kitty keyboard enhancement enable/disable behavior and shutdown cleanup in `Terminal`.
- Fixed capability state tracking so primary device attribute changes are detected even when Sixel support does not change, and repeated identical color/capability reports no longer churn state.
- Added direct `Terminal` coverage for focus/blur events, bracketed paste events, and startup foreground/cursor color capability updates.

## 0.1.1+1
- fix documentation + missing assets
## 0.1.1

### Fixed

- Updated package screenshots/readme media setup for pub.dev rendering.
- Added `pubspec.yaml` screenshot metadata (`assets/layout.png`) for package page preview.

## 0.1.0

### Added

- Initial release of `ultraviolet`.
- Core terminal rendering primitives: cells, buffers, styles, ANSI handling, and terminal renderer.
- Layout/rendering helpers and example suite for advanced terminal graphics.

### Fixed

- Synchronized-output skipped-frame behavior in `UvTerminalRenderer` dirty-line handling.
