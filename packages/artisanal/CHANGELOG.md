# Changelog

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
- **Documented**: Extended keys (F21-F63, media keys) map to `KeyType.unknown` - use `UvEventMsg` for full access.

### Tests

- Added comprehensive tests for C0 code handling, modifier preservation, wide character cloning,
  ANSI color preservation through wrap, and program lifecycle edge cases.
- Added tests for extended function keys (F21+) and media keys mapping behavior.
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
