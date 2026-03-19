# Changelog

## Unreleased

### Added

- Added `ColorPaletteMsg` and `Cmd.requestColorPalette()` so OSC 4 palette replies are exposed through the TUI runtime instead of staying UV-internal.

### Changed

- Made `Program` treat view-scoped terminal metadata declaratively, resetting colors, progress bars, focus reporting, bracketed paste, mouse mode, and kitty keyboard enhancements when later frames stop requesting them.
- Made `Program` reset view-scoped window titles and cursor styling declaratively, falling back to `startupTitle` when later frames drop a title override and restoring the default cursor shape when cursor metadata clears.

### Fixed

- Reset cursor color overrides during terminal restore/cleanup paths and hardened startup background probing so the first rendered frame can reflect the probed terminal background.
- Added end-to-end runtime coverage for foreground and cursor color requests through the `Program` message path.
- Fixed inline-mode dynamic alt-screen handling so command-driven and view-driven alt-screen toggles reset cleanly on later frames, suspend/restore, and shutdown, and so inline printing is suppressed while the alternate screen is active.
- Hardened `Program` resize dispatch so passive backend/SIGWINCH resize notifications are deduplicated while explicit `Cmd.windowSize()` requests still flow through filters and interceptors.
- Added end-to-end `Program` coverage for focus and bracketed-paste delivery across both the UV decoder path and the legacy key parser path.
- Added end-to-end `Program` coverage for live mouse press, wheel, and `View.onMouse` command delivery across both parser paths.
- Added end-to-end `Program` coverage for UV mouse motion delivery plus parser-driven standard and in-band resize reports.
- Added UV-to-TUI adapter parity coverage for focus, paste, mouse, and resize report translation.

## 0.2.0+1

- documentation + assets

## 0.2.0

### Added

- New charting module (`package:artisanal/charting.dart`) with sparkline, histogram, heatmap, line, pie/donut, and ribbon renderers.
- Console tag parser support for style-tagged output (for example `<red>...</red>`).
- Structured TUI tracing and replay hooks for improved debugging and deterministic replay workflows.

### Changed

- Migrated widget-system implementation to `artisanal_widgets`; `package:artisanal/widgets.dart` now re-exports the widgets package.
- Split and aligned low-level UV rendering APIs with the standalone `ultraviolet` package.
- Reworked terminal image protocol handling for iTerm2, Kitty, and Sixel paths.

### Breaking

- Widget APIs are now sourced from the separate `artisanal_widgets` package; consumers should include `artisanal_widgets` in dependency resolution for hosted usage.

### Fixed

- Eliminated scroll flicker with synchronized terminal output.
- Corrected Unicode/emoji width handling and grapheme-safe truncation behavior (including variation-selector edge cases).
- Fixed style/renderer edge cases including hex color parsing and related rendering correctness issues.
- Improved input/trace runtime stability in TUI flows (including replay/capture and stream handling paths).

## 0.1.2

- **Fixed**: CI deadlocks when reading `stdin` multiple times by introducing `SharedInputStream`.
- **Fixed**: Resolved UV renderer regressions and TUI input normalization issues.
- **Improved**: Guarded `startupProbes` against `disableRenderer` configuration.

## 0.1.1

- **Updated**: Synced release with ORMed dev+7.

## 0.1.0

- **Release**: Promote Artisanal to a stable 0.1.0 release.
- **Changed**: Console labeled logs no longer append an extra blank line.

## 0.1.0-dev+5

- export args classes

## 0.1.0-dev+4

- **Improved**: Aligned with core ormed releases for advanced ORM features.
- **Updated**: Dependencies bumped to latest stable versions.

## 0.1.0-dev+3

- Synchronized release.

## 0.1.0-dev+2

- Synchronized release with ormed_cli rebranding.

## 0.1.0-dev+1

- Internal version bump to align with ORMed release.

## 0.1.0-dev

- Initial release.
