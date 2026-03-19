# Changelog

## Unreleased

### Added

- Added a stable `package:artisanal_widgets/widgets.dart` entrypoint for the high-level widget framework surface.
- Added stable `package:artisanal_widgets/charting.dart` and `package:artisanal_widgets/selection.dart` entrypoints for the supported charting and text-selection surfaces.
- Added `ImageAutoMode.sessionCapabilities` so `Image(renderMode: auto)` can follow terminal version and device-attribute reports from the active session instead of only using the local process environment.

### Changed

- Fixed `FadeModalBarrier` so content-backed barriers dim the child in place instead of painting an opaque black layer over the full view, while keeping the standalone overlay fallback for empty-child route barriers.
- Improved `Tint` blending so `FadeTint` and content-backed `FadeModalBarrier` widgets fade proportionally toward the target color instead of snapping between no effect and a full tint.
- Fixed `Drawer` backdrops so open drawers dim the background content in place instead of blacking out the full terminal view.
- Made `Modal` and `Drawer` honor `backdropColor` through the shared tint path instead of ignoring the configured color while dimming the background.
- Clarified the package guidance so `artisanal_widgets` remains the primary widget dependency, while the `package:artisanal/...` widget entrypoints are documented as optional umbrella convenience re-exports.
- Hosted browser/socket runner helpers now default `Image(renderMode: auto)` to `ImageAutoMode.sessionCapabilities` instead of forcing the portable fallback, so remote terminals can upgrade image rendering from live session capability reports.
- Added hosted-runner regression coverage for session-capability image probing by default and for portable-fallback mode suppressing those extra image capability requests.
- Kept `package:artisanal_widgets/artisanal_widgets.dart` as the broader experimental compatibility surface while stabilizing the primary widget/app/layout/input/navigation APIs.
- Updated the widget docs to prefer the stable `package:artisanal_widgets/widgets.dart` import path.
- Updated the package README and focused examples to prefer the stable top-level entrypoints over the broad compatibility import.
- Updated the remaining widget examples and tooling to import the stable `package:artisanal_widgets/widgets.dart` entrypoint instead of the broad compatibility surface.
- Updated the flagship widget app examples to use the stable umbrella imports from `package:artisanal/app.dart` and `package:artisanal/widgets.dart`.
- Updated the editor showcase examples to use the stable umbrella imports from `package:artisanal/app.dart`, `package:artisanal/editors.dart`, and `package:artisanal/widgets.dart`.
- Updated the shared text input test suites to use the stable `package:artisanal/widgets.dart` and `package:artisanal/testing.dart` entrypoints.
- Updated the flagship component and showcase tests to use the stable `package:artisanal/widgets.dart`, `package:artisanal/testing.dart`, and `package:artisanal/app.dart` entrypoints.
- Updated the editor showcase and HelpView regression tests to use the stable `package:artisanal/testing.dart` and `package:artisanal/widgets.dart` entrypoints.
- Updated the app-shell, reload, and core HelpView tests to use the stable `package:artisanal/app.dart`, `package:artisanal/widgets.dart`, and `package:artisanal/testing.dart` entrypoints.
- Updated the status, progress, metric, and key-hint component tests to use the stable `package:artisanal/widgets.dart` and `package:artisanal/testing.dart` entrypoints.
- Updated the button, toggle, slider, dropdown, and popup-menu component tests to use the stable `package:artisanal/widgets.dart` and `package:artisanal/testing.dart` entrypoints.
- Updated the tree, tab, split-view, scroll-area, and list-navigation component tests to use the stable `package:artisanal/widgets.dart` and `package:artisanal/testing.dart` entrypoints.
- Updated the accent-panel, chip, tooltip, accordion, expansion-tile, and hyperlink component tests to use the stable `package:artisanal/widgets.dart` and `package:artisanal/testing.dart` entrypoints.
- Updated the data-table, list-tile control, and select/pagination component tests to use the stable `package:artisanal/widgets.dart` and `package:artisanal/testing.dart` entrypoints.
- Updated the command palette, modal/drawer, and git-diff component tests to use the stable `package:artisanal/widgets.dart` and `package:artisanal/testing.dart` entrypoints.
- Updated the frame border regressions and the OpenCode home layout showcase test to use the stable `package:artisanal/widgets.dart` and `package:artisanal/testing.dart` entrypoints.
- Updated the remaining card/panel/frame regression test to use the stable `package:artisanal/widgets.dart` and `package:artisanal/testing.dart` entrypoints, and to accept stabilized truecolor card-surface rendering.
- Updated the foundational widget and basic layout tests to use the stable `package:artisanal/widgets.dart` and `package:artisanal/testing.dart` entrypoints.

## 0.1.0+1
- Documentation + assets
## 0.1.0

### Added

- Initial release of `artisanal_widgets`.
- Flutter-style terminal widget system built on top of `artisanal`.
- Core widget framework, layout primitives, focus/gesture/input systems, and component library.
- Charting widgets, scroll/selection support, and testing harnesses for TUI widget behavior.
