# Changelog

## Unreleased

### Added

- Added `DiffReviewController` and `DiffReviewViewport` over the core TEA review
  model, with one composed code/comment scroll extent, lazy expanded thread
  widgets, sparse height indexing, source-anchored selection, and shared
  split-panel geometry. Measured thread size changes preserve the visible
  content anchor. The legacy `GitDiffViewer` remains available unchanged.
- Added a GitHub demo source-thread adapter preserving multiline ranges,
  root/reply identity, renamed old-side paths, and outdated positions, ready for
  the review viewport migration.
- Migrated the GitHub single-PR screen to the TEA review controller and lazy
  viewport, retaining rich Markdown/avatar cards, source-range submission, and
  comment-inclusive paging. Restored the Review tab and rejected stale diff
  comment responses. The dashboard and standalone dialog remain on the legacy
  viewer.
- Added `DiffReviewController.firstVisibleSource` for source lookup in composed
  viewport coordinates without treating comment rows as diff rows.
- Migrated the GitHub dashboard to the same review session as the single-PR
  screen, replacing its rendered-anchor selection and diff-only scroll offsets.

## 0.4.0

### Added

- Added `example/text_style`, a runnable catalog covering immutable updates,
  `Style` composition, span inheritance and resets, selectable text,
  decorations, and the separate ASCII-art font model.

### Changed

- Moved command-palette item and scored-match primitives plus deterministic
  matching, selection, and visible-window calculation into `artisanal`; the
  widget keeps compatibility aliases, mouse/focus/theme chrome, and
  delegates ranking plus scrolling to the shared controller.
- Forwarded `RenderMetricsInjector` custom entries to Artisanal's universal
  program developer tools overlay while preserving the existing widget-local
  metrics stream.
- Removed `WidgetApp`'s separate built-in metrics overlay and F12 handler.
  Widget hosts now enable program diagnostics by default; configure visibility,
  position, and shortcuts with `ProgramDiagnosticsOptions`.
- Routed framework internals through Artisanal's narrow runtime entrypoint so
  widget app imports do not load unrelated native Markdown dependencies.
- Kept both `app.dart` and the complete `widgets.dart` public surface
  JavaScript-compilable, including Markdown text rendering with browser image
  placeholders.
- Reduced the published package archive by excluding repository-hosted demo
  media and generated GitHub CLI web artifacts.
- Moved `runWidgetApp`, `serveWidgetApp`, `Transport`, and widget-oriented
  program defaults into the package-owned `app.dart` entrypoint.
- Moved the lower-level chart-painter grid demo into this package because its
  application shell uses the widget framework.
- Switched the observer primitives (`Listenable`, `ValueListenable`,
  `ChangeNotifier`, `ValueNotifier`, `VoidCallback`) to `package:listen`
  (`listen: ^1.0.1`). `src/widgets/animation/listenable.dart` is now a
  scoped compatibility re-export of those types; new code should import
  `package:listen/listen.dart` directly. Public API via
  `package:artisanal_widgets/widgets.dart` keeps the same names.
- Aligned `ChangeNotifier` semantics with `package:listen`/Flutter: `hasListeners`
  and `notifyListeners` are `@protected` (`notifyListeners` remains
  `@visibleForTesting`). Subclasses calling them internally are unaffected;
  only direct external callers must route through a subclass wrapper.
  Listener exceptions route through `Listenable.onError`, and `dispose()`
  during notification is rejected by `package:listen` (asserts in debug).

### Removed

- Removed the unused slot registry, plugin mounting, mixed slot region, and
  remote plugin surface widget APIs and examples.

### Fixed

- Fixed a startup panic (`Unsupported operation: Infinity or NaN toInt`)
  when a scroll viewport had unbounded height: `RenderSingleChildViewport`
  now shrink-wraps to its content height instead of reporting an infinite
  size, and the `scrollbar` example bounds its `Scrollbar` with an explicit
  height like the `scroll` example does.
- Fixed a reentrant-publish crash (`Bad state: Cannot fire new event`) in
  `RenderMetricsInjector`: publishes made from inside dispatch (e.g. the
  metrics listener synchronously triggering another render) are deferred
  one microtask instead of throwing.
- Ensured `ReloadFileWatcher.watch` waits for native watcher installation before
  returning, so immediate file changes are not missed.
- Preserved `TextStyle` decoration colors through text rendering copies.
- Preserved `TextStyle` presentation across soft-wrapped continuation lines
  and made plain and rich `Text` wrap content before resizing `Style` borders
  and padding.
- Made the text-style ASCII-font comparison compact and responsive.
- Kept dividers as single-row structural elements when their requested width
  exceeds the available layout width.

## 0.3.0

### Added

- Added optional immutable `textStyle` overlays to `Text`, `TextSpan`,
  `SelectableText`, and `SelectableRichText`, with nested inheritance and
  explicit attribute disabling while retaining the complete `Style` API.
- Added `MonthlyCalendar` with selected, today, adjacent-month, and marker
  styling.
- Added `Shadow` presets and `CellFilter` for applying UV buffer effects to a
  widget subtree.
- Added structured `DataTableCell` content with column spans, alignment, and
  per-cell styles through `DataTable.cells`.
- Added `example/widget_features` demonstrating fixed viewports, shadows,
  calendars, table spans, filters, and canvas shapes together.
- Added `example/uv_effects` demonstrating single and composed UV effects on
  ordinary widget subtrees through `CellFilter`.
- Added `example/inline_build_monitor`, a responsive bottom-pinned build
  dashboard with staged progress, streaming logs, native scrollback, and
  interactive pause, rebuild, and failure controls.

### Changed

- Updated the feature examples and package constraints for `artisanal` 0.5.x
  and the new UV rendering surface.

## 0.2.2

### Changed

- Refactored library exports across all widget modules to simplify import
  paths and reduce the public API surface to stable, documented types.
- Reorganized `git_diff.dart` with streamlined imports and cleaner
  comment-anchor rendering.
- Cleaned up unused imports, trailing whitespace, and formatting across
  the entire widget library (176 files touched).

### Fixed

- Fixed various lint warnings and type annotations across layout utilities,
  gesture handling, and animation tests.

## 0.2.1

### Added

- Added a widget-based `flutter_cli_port` example that ports the Rust
  `flutter-cli` dashboard onto Artisanal Widgets and the Artisanal command
  runner.
- Added an inline widget dashboard example for bottom-pinned non-alt-screen
  status panels with streaming logs.
- Added review-comment mapping support for the GitHub CLI diff pane so inline
  review comments can be highlighted beside rendered diffs.

### Changed

- Moved terminal image decoding off the main TUI isolate and cached rendered
  image output to reduce scroll-time stalls in image-heavy views.
- Improved large scroll/list rendering by preserving scrollbars beside OSC 8
  and terminal-graphics content and avoiding unnecessary render-tree hit-test
  descents.
- Updated workspace dependency constraints for the current `artisanal` release.

### Fixed

- Kept non-overlay scrollbars visible when content includes Kitty graphics or
  OSC 8 hyperlinks.
- Preserved styled foreground spaces in canvas/layout rendering instead of
  treating every space as transparent.
- Reset virtual-list measurement caches correctly after invalidation so scroll
  metrics do not collapse after resize or content changes.
- Updated the flutter-cli port to delegate unknown commands through
  `CommandRunner.unknownCommandFallback`, keeping built-in completion automatic
  while still forwarding non-dashboard Flutter commands.
- Disabled mouse capture in the flutter-cli port inline dashboard so native
  terminal scrollback remains available by default.

## 0.2.0

### Added

- Added a stable `package:artisanal_widgets/widgets.dart` entrypoint for the high-level widget framework surface.
- Added stable `package:artisanal_widgets/charting.dart` and `package:artisanal_widgets/selection.dart` entrypoints for the supported charting and text-selection surfaces.
- Added `ImageAutoMode.sessionCapabilities` so `Image(renderMode: auto)` can follow terminal version and device-attribute reports from the active session instead of only using the local process environment.
- Added a dedicated `example/tooltip_trace` demo with `TuiTrace` instrumentation and built-in replay/trace conversion flags so tooltip hover behavior can be recorded, converted, and replayed during debugging.
- Added external diagnostics sources and listenable diagnostics bindings for editor widgets, so demos and downstream apps can drive diagnostics without custom text-pattern glue.
- Added per-widget selection highlight overrides for the shared read-only selection surfaces, so mixed documents can use different selection palettes within one `SelectionArea`.
- Added span-level selection highlight overrides for `SelectableRichText`, so one shared rich-text selection can mix palettes within a single widget.

### Changed

- Fixed `FadeModalBarrier` so content-backed barriers dim the child in place instead of painting an opaque black layer over the full view, while keeping the standalone overlay fallback for empty-child route barriers.
- Improved `Tint` blending so `FadeTint` and content-backed `FadeModalBarrier` widgets fade proportionally toward the target color instead of snapping between no effect and a full tint.
- Updated `AnimatedTint` to use the shared `blendColor()` helper so animated widget tinting follows the same color interpolation path as the rest of the style system.
- Fixed `Drawer` backdrops so open drawers dim the background content in place instead of blacking out the full terminal view.
- Made `Modal` and `Drawer` honor `backdropColor` through the shared tint path instead of ignoring the configured color while dimming the background.
- Clarified the package guidance so `artisanal_widgets` remains the primary widget dependency, while the `package:artisanal/...` widget entrypoints are documented as optional umbrella convenience re-exports.
- Hosted browser/socket runner helpers now default `Image(renderMode: auto)` to `ImageAutoMode.sessionCapabilities` instead of forcing the portable fallback, so remote terminals can upgrade image rendering from live session capability reports.
- Added hosted-runner regression coverage for session-capability image probing by default and for portable-fallback mode suppressing those extra image capability requests.
- Improved shared read-only selection in scrollable mixed views, including upward and downward edge auto-scroll, mouse-wheel scrolling during drag selection, and row-wide drag starts from surrounding whitespace.
- Kept `package:artisanal_widgets/artisanal_widgets.dart` as the broader experimental compatibility surface while stabilizing the primary widget/app/layout/input/navigation APIs.
- Updated the widget docs to prefer the stable `package:artisanal_widgets/widgets.dart` import path.
- Updated the package README and focused examples to prefer the stable top-level entrypoints over the broad compatibility import.
- Updated the remaining widget examples and tooling to import the stable `package:artisanal_widgets/widgets.dart` entrypoint instead of the broad compatibility surface.
- Made `Tooltip` float from an `Overlay` ancestor instead of reflowing surrounding layout, and updated the gallery example to host its overlay demos through a root overlay so hover tooltips behave like anchored popups.
- Made floating `Tooltip` fall back to the latest hover pointer position when anchor geometry is not ready yet, avoiding delayed tooltip popups in live sessions.
- Made floating `Tooltip` request an immediate repaint on hover enter and exit so overlay tooltips appear and disappear without waiting for a later event.
- Made floating `Tooltip` hit-test transparent so it no longer blocks later mouse hover and click interaction underneath.
- Fixed `GestureDetector` hover handling so commands returned from `onEnter` and `onExit` are dispatched through the widget pipeline, allowing overlay-backed hover widgets like `Tooltip` to repaint immediately in live sessions.
- Fixed `Stack` hit-testing so positioned children use their painted offsets during hit testing, which restores immediate hover interaction for anchored overlays like `Tooltip`.
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
- Updated the main widget gallery example to enable passive all-motion mouse tracking so hover-driven overlays like the tooltip preview work in real terminals.
- Clarified the widget docs and tooltip API docs so passive hover behavior explicitly points callers to `MouseMode.allMotion` and the widget runners that already default to it.
- Updated the widget-friendly runner defaults to disable core startup probes so early hover-driven UI feedback, such as tooltips in the gallery example, is not delayed behind terminal capability probing.
- Added shared `Tooltip` lifecycle trace events for hover transitions, overlay insert/remove, and overlay visible/hidden timing so tooltip traces can measure when the popup is actually requested and rendered.
- Fixed hit-test motion bubbling so nested hover handlers all see the first in-bounds mouse move, which restores immediate `Tooltip` show timing when the tooltip target contains its own `MouseRegion`.
- Stopped floating `Tooltip` from invalidating its overlay entry during every build while hovered, which eliminates repaint churn that could delay later mouse motion and hide updates.
- Stopped `Tooltip.didUpdateWidget()` from resyncing the floating overlay on unrelated parent rebuilds, so hovered tooltips no longer trigger periodic overlay rebuilds from app-shell updates.

## 0.1.0+1
- Documentation + assets
## 0.1.0

### Added

- Initial release of `artisanal_widgets`.
- Flutter-style terminal widget system built on top of `artisanal`.
- Core widget framework, layout primitives, focus/gesture/input systems, and component library.
- Charting widgets, scroll/selection support, and testing harnesses for TUI widget behavior.
