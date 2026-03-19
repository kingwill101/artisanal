# Changelog

## Unreleased

### Fixed

- Added lifecycle coverage for kitty keyboard enhancement enable/disable behavior and shutdown cleanup in `Terminal`.

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
