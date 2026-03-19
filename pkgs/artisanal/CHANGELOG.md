# Changelog

## Unreleased

### Added

- Added `ColorPaletteMsg` and `Cmd.requestColorPalette()` so OSC 4 palette replies are exposed through the TUI runtime instead of staying UV-internal.
- Added `CursorPositionMsg` and `Cmd.requestCursorPositionReport()` so cursor-position reports are exposed through the TUI runtime instead of staying UV-internal.
- Added `Cmd.requestPrimaryDeviceAttributesReport()` so DA1 capability queries have an explicit TUI command helper instead of requiring raw escape writes.
- Added `Cmd.requestKeyboardEnhancementsReport()` so kitty keyboard support queries have an explicit TUI command helper instead of requiring raw escape writes.
- Added `Cmd.requestSecondaryDeviceAttributesReport()` so DA2 capability queries have an explicit TUI command helper instead of requiring raw escape writes.
- Added `Cmd.requestTertiaryDeviceAttributesReport()` so DA3 capability queries have an explicit TUI command helper instead of requiring raw escape writes.
- Added `Cmd.requestTerminalVersionReport()` and `Cmd.requestTermcapStrings()` so XTVERSION and XTGETTCAP queries have explicit TUI command helpers instead of requiring raw escape writes.
- Added `Cmd.requestColorSchemeReport()` so terminal light/dark scheme queries have an explicit TUI command helper instead of requiring raw escape writes.
- Added `ModifyOtherKeysMsg` plus device-attribute report messages so UV capability/startup reports no longer fall back to raw UV events in the TUI runtime.
- Added `ModeReportMsg`, `ColorSchemeMsg`, and `Cmd.requestModeReport()` so UV mode-status replies and light/dark color-scheme reports are exposed through the TUI runtime instead of falling back to raw UV events.
- Added `WindowPixelSizeMsg`, `CellSizeMsg`, and matching `Cmd` request helpers so UV pixel-size and cell-size reports are exposed through the TUI runtime instead of staying UV-internal.
- Added `ProgramOptions.startupProbes` / `withStartupProbes(...)` so custom terminals can explicitly opt into or out of UV startup probing.
- Added `ProgramOptions.sendSuspendSignal` / `withoutSuspendSignal()` so `SuspendMsg` can exercise the full terminal release/restore lifecycle without sending `SIGTSTP`.
- Added stable `package:artisanal/runtime.dart` and `package:artisanal/hosts.dart` entrypoints for the focused TEA runtime and host/backend surfaces.
- Added stable `package:artisanal/app.dart`, `package:artisanal/editors.dart`, `package:artisanal/selection.dart`, and `package:artisanal/testing.dart` re-exports for the supported widget modules.

### Changed

- Prevented late external-process completion from restoring the terminal or delivering completion messages after the program has already quit, been killed, or lost its backend host session.
- Made direct `Program.kill()` abort active startup probes immediately, so kill behaves like quit/backend shutdown during pre-render and emoji probing.
- Deferred renders and stateful terminal control writes while `Program` temporarily releases the terminal for exec/suspend, then reapplied deferred titles and inline alt-screen/mode state on restore.
- Paused frame-tick and metrics timers while `Program` temporarily releases the terminal for exec/suspend, then resumed them cleanly on restore so background timers do not run against a released terminal.
- Reapplied `startupTitle` when restoring the terminal after exec/suspend when no view-scoped title override is active.
- `package:artisanal/widgets.dart` now re-exports the stabilized `package:artisanal_widgets/widgets.dart` surface instead of the broader experimental compatibility entrypoint.
- Made `Program` treat view-scoped terminal metadata declaratively, resetting colors, progress bars, focus reporting, bracketed paste, mouse mode, and kitty keyboard enhancements when later frames stop requesting them.
- Made `Program` reset view-scoped window titles and cursor styling declaratively, falling back to `startupTitle` when later frames drop a title override and restoring the default cursor shape when cursor metadata clears.
- Moved UV capability probing behind the first frame so pre-render startup probing only blocks on theme detection, not DA2/kitty capability replies.

### Fixed

- Reset cursor color overrides during terminal restore/cleanup paths and hardened startup background probing so the first rendered frame can reflect the probed terminal background.
- Hardened the pre-render theme probe so the first rendered frame can also follow an explicit terminal light/dark color-scheme reply when OSC 11 background color is unavailable.
- Added end-to-end runtime coverage for foreground and cursor color requests through the `Program` message path.
- Fixed inline-mode dynamic alt-screen handling so command-driven and view-driven alt-screen toggles reset cleanly on later frames, suspend/restore, and shutdown, and so inline printing is suppressed while the alternate screen is active.
- Hardened `Program` resize dispatch so passive backend/SIGWINCH resize notifications are deduplicated while explicit `Cmd.windowSize()` requests still flow through filters and interceptors.
- Hardened `Program` resize dispatch so repeated passive UV window-size reports are deduplicated before reaching the model.
- Added end-to-end `Program` coverage for focus and bracketed-paste delivery across both the UV decoder path and the legacy key parser path.
- Added end-to-end `Program` coverage for live mouse press, wheel, and `View.onMouse` command delivery across both parser paths.
- Added end-to-end `Program` coverage for UV mouse motion delivery plus parser-driven standard and in-band resize reports.
- Fixed first-frame rendering on injected custom terminals by skipping automatic UV startup probes unless the terminal explicitly opts in.
- Fixed delayed `init()` commands such as `Cmd.tick(...)` so they no longer block the first render.
- Added UV-to-TUI adapter parity coverage for focus, paste, mouse, and resize report translation.
- Added end-to-end `Program` and UV-to-TUI adapter coverage for mode-status replies and light/dark color-scheme reports.
- Added end-to-end `Program` and UV-to-TUI adapter coverage for ModifyOtherKeys and primary/secondary/tertiary device-attribute reports.
- Added end-to-end `Program` and UV-to-TUI adapter coverage for cursor-position reports.
- Added end-to-end `Program` coverage for terminal-version and XTGETTCAP capability reports.
- Added end-to-end `Program` coverage for kitty keyboard enhancement reports.
- Added end-to-end `Program` coverage for secondary device-attribute reports.
- Added end-to-end `Program` coverage for tertiary device-attribute reports.
- Added end-to-end `Program` coverage for clipboard read replies.
- Added direct `Program` coverage for startup `ColorProfileMsg` delivery.
- Added pre-render `Program` startup coverage for UV DA2 and kitty keyboard capability replies.
- Suppressed xterm pixel-size and cell-size report queries on non-terminal hosts alongside the existing terminal-report guards.
- Suppressed xterm mode-status report queries on non-terminal hosts alongside the existing terminal-report guards.
- Suppressed cursor-position report queries on non-terminal hosts alongside the existing terminal-report guards.
- Suppressed kitty keyboard enhancement report queries on non-terminal hosts alongside the existing terminal-report guards.
- Suppressed terminal color-scheme report queries on non-terminal hosts alongside the existing terminal-report guards.
- Suppressed DA2 capability queries on non-terminal hosts alongside the existing terminal-report guards.
- Suppressed DA3 capability queries on non-terminal hosts alongside the existing terminal-report guards.
- Suppressed XTVERSION and XTGETTCAP report queries on non-terminal hosts alongside the existing terminal-report guards.
- Suppressed batched OSC color, palette, and clipboard report queries on non-terminal hosts instead of only handling clipboard reads as a trailing special case.
- Made `SocketTerminalHostServer.close(force: true)` wait for in-flight session cleanup after tearing down active client sockets, matching the browser host lifecycle contract.
- Fixed `SuspendMsg` terminal release so fullscreen suspend/restore no longer double-exits alt screen, and added direct suspend lifecycle coverage for metadata, fullscreen state, and startup-title restore.

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
