# Changelog

## Unreleased

### Features

- **Charting library** (`package:artisanal/charting.dart`): terminal-native chart renderers — sparkline, histogram, heatmap, line chart, pie/donut chart, and stacked ribbon/area chart, all rendering into UV buffers.
- **Liquid template library** (`package:artisanal/liquid.dart`): custom Liquid tag adapters (`panel`, `frame`, `hstack`, `vstack`, `grid`, `spark`, `rule`, `text`, `table`, `progress`, `line`, `histogram`, `pie`) for building terminal UIs from templates. Includes `UvBufferTarget` and `StringRenderTarget`.
- **Physics library** (`package:artisanal/physics.dart`): lightweight forge2d wrappers (`PhysicsWorld`, `PhysicsSettings`) and convenience type aliases for integrating physics into UV/TUI demos.
- **Terminal image protocol rewrite**: iTerm2 (`encodePng()`), Kitty (PNG-format payloads, auto-IDs, quiet mode), and Sixel (octree color quantization, auto-resize) encoders rewritten for correctness and performance.
- **UV renderer improvements**: render metrics with idle timeout, `metricsOnlyFrame()`, overlay filters, drawable exports, and width utilities re-exported from `uv.dart` barrel.
- **TUI core enhancements**: `TuiTrace` debug tracing system, input event coalescing, startup probe reorder, `FrameTickModel` and `RenderMetricsModel` additions.
- **ConsoleTagParser**: style-tagged output methods for `Console` (e.g. `<red>text</red>`), with delegating output methods on `Command`.
- **Text selection in bubble components**: click-drag text selection with highlighting and Ctrl+C copy support in `TextInput` and `Viewport` bubbles.
- **Barrel export updates**: new top-level exports for charting, liquid, physics, and widgets; `tui.dart` now hides `Row`/`Column`/`Text` from bubbles to avoid widget-system collisions.

### Bug Fixes

- **Fixed**: scroll flicker eliminated via synchronized output (DEC mode 2026) — terminal buffers output atomically during `flush()`.
- **Fixed**: Unicode width calculations — corrected `_isEmojiPresentation()` to match Unicode 15.1 `Emoji_Presentation=Yes` only; expanded supplementary emoji ranges (Mahjong/Playing Cards, Enclosed Alphanumerics, Enclosed Ideographic Supplement, Geometric Shapes Extended).
- **Fixed**: `Layout.truncate()` now uses grapheme-cluster iteration instead of code-unit counting, preventing CJK and emoji characters from being split mid-character.
- **Fixed**: `Layout.truncate()` accounts for U+FE0F variation selector — emoji like `☀️` are now correctly measured as width 2 during truncation.
- **Fixed**: mouse sequence parsing in `SplitTerminal`.
- **Fixed**: CR+LF newline mapping for alt-screen rendering.

### Refactoring

- Cleaned up style/glamour modules (`GlamourRenderer`, `GlamourBlockContext` dartdoc).
- Runner command delegation for output methods.
- Migrated widget system files (`layout_widgets.dart`, `theme.dart`, `widget.dart`, `widgets.dart`) to the `artisanal_widgets` package; added `package:artisanal/widgets.dart` shim that re-exports `artisanal_widgets`.

### Documentation

- Removed legacy docs directory; updated README.
- Full `///` dartdoc coverage on all new and changed public API across ~25 source files.

### Tests

- Added comprehensive tests for charting, text selection, Unicode width edge cases, grapheme-based truncation, variation selector handling, and image encoder correctness.

## 0.1.3

### Bug Fixes

- **Fixed**: LF (0x0A) incorrectly decoded as Ctrl+J instead of Enter in UV decoder.
- **Fixed**: key_table LF inconsistency - added `lfKey` variable respecting legacy flag.
- **Fixed**: Meta/Hyper/Super modifiers dropped when converting UV keys to TUI keys.
- **Fixed**: 0x08 (Backspace/Ctrl+H) inconsistency between TUI parser and UV decoder.
- **Fixed**: Race condition in `Program.send()` - added message queue for sequential processing.
- **Fixed**: Type cast without validation when model returns wrong type from `update()`.
- **Fixed**: `init()` called after first render causing visual flash.
- **Fixed**: `wrapAnsiPreserving` didn't preserve truecolor (38;2;r;g;b) and 256-color (38;5;n) sequences.
- **Fixed**: StreamCmd/EveryCmd continued sending after quit.
- **Fixed**: BatchMsg could cause stack overflow with deeply nested batches.
- **Fixed**: Double cleanup possible - added guard flag.
- **Fixed**: Frame timing drift - changed renderers to use `Stopwatch` instead of `DateTime.now()`.
- **Fixed**: Unicode width for Variation Selectors (VS1-VS256) now correctly returns 0.
- **Fixed**: Regional Indicator Symbols for flags now return correct emoji width.
- **Fixed**: Expanded emoji width ranges to cover Miscellaneous Symbols, Dingbats, and Extended-A.
- **Fixed**: `EveryCmd.isActive` now correctly returns `true` during initial delay period.

### Improvements

- **Improved**: Cleanup errors are now collected and accessible via `program.cleanupErrors` for debugging.
- **Added**: `meta`, `hyper`, `superKey` fields to TUI Key class for extended modifier support.
- **Added**: Full extended key support in TUI `KeyType` enum:
  - Function keys F21-F63
  - Lock keys: `capsLock`, `scrollLock`, `numLock`, `printScreen`, `pause`, `menu`
  - Media keys: `mediaPlay`, `mediaPause`, `mediaPlayPause`, `mediaReverse`, `mediaStop`,
    `mediaFastForward`, `mediaRewind`, `mediaNext`, `mediaPrev`, `mediaRecord`
  - Volume keys: `volumeDown`, `volumeUp`, `mute`
  - Modifier keys as standalone presses: `leftShift`, `leftAlt`, `leftCtrl`, `leftSuper`,
    `leftHyper`, `leftMeta`, `rightShift`, `rightAlt`, `rightCtrl`, `rightSuper`,
    `rightHyper`, `rightMeta`, `isoLevel3Shift`, `isoLevel5Shift`

### Tests

- Added comprehensive tests for C0 code handling, modifier preservation, wide character cloning,
  ANSI color preservation through wrap, and program lifecycle edge cases.
- Added tests for extended function keys (F21-F35) and media keys mapping.
- Added tests for lock keys, volume keys, and modifier keys as standalone presses.
- Added comprehensive Unicode width edge case tests (ZWJ emoji, flags, variation selectors, CJK).
- Added tests for `EveryCmd.isActive` behavior during initial delay period.
- **Documented**: key_table C0 entries purpose (consistency/documentation, not actively used).

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
