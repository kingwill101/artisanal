# Changelog

## 0.2.0

### Changed

- `Terminal` startup capability probing now queries DA2 as well as DA1, kitty keyboard, colors, and kitty graphics.
- `Terminal` startup capability probing now queries DA3 and terminal-version reports alongside the existing DA1/DA2, kitty keyboard, color, and kitty-graphics probes.
- `Terminal` startup capability probing now queries the terminal light/dark color-scheme report alongside the existing device, keyboard, graphics, and color probes.
- `TerminalCapabilities` now tracks exact kitty keyboard enhancement flags plus foreground, background, cursor, and palette color reports with idempotent updates.
- `TerminalCapabilities` now tracks `ModifyOtherKeys` mode reports and terminal dark/light color-scheme state instead of treating those reports as transient decode-only events.
- `Terminal` startup capability probing now queries foreground and cursor colors in addition to the existing background, keyboard, device-attribute, and kitty-graphics probes.
- `TerminalCapabilities` now infers Kitty and iTerm2 image-protocol support from terminal-version replies in addition to the existing environment and device-attribute hints.

### Fixed

- `Terminal` is now explicitly single-use after `stop()`, repeated mode toggles are idempotent, and changing kitty keyboard enhancement flags now resets the old mode before applying the new one.
- Added lifecycle coverage for kitty keyboard enhancement enable/disable behavior and shutdown cleanup in `Terminal`.
- Fixed capability state tracking so primary device attribute changes are detected even when Sixel support does not change, and repeated identical color/capability reports no longer churn state.
- `TerminalCapabilities` now stores and de-duplicates secondary device attributes instead of discarding DA2 reports after decode.
- `TerminalCapabilities` now stores and de-duplicates DA3 tertiary attributes and terminal-version reports instead of discarding them after decode.
- Added direct `Terminal` coverage for focus/blur events, bracketed paste events, and startup foreground/cursor color capability updates.
- Added direct `Terminal` coverage for mouse click, release, motion, and wheel events plus standard and in-band resize report handling.
- Added direct `Terminal` coverage for cursor-position, ModifyOtherKeys, and primary/secondary/tertiary device-attribute reports, including capability-state updates from DA1.
- Added direct `Terminal` coverage for clipboard, terminal-version, XTGETTCAP, background-color, and palette report handling.
- Fixed `UvTerminalRenderer` leading-blank overwrite fallback so it only emits blanks for truly blank old-line regions instead of using spaces to move across existing content.

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
