# Changelog

## 0.5.1

### Changed

- Added focused, browser-safe `core.dart`, `input.dart`, `rendering.dart`,
  `terminal.dart`, and `unicode.dart` entrypoints for consumers that do not
  need the full package surface.
- Removed the unused direct `meta` dependency and excluded generated DevTools
  profiler sessions from the published package archive.

### Fixed

- Kept the main `ultraviolet.dart` entrypoint browser-compatible by loading
  the Windows native console reader only on `dart:io` platforms.
- Preserved SGR attributes, underline variants and colors (including explicit
  color-space slots), and complete grapheme widths across ANSI-aware wrapped
  lines; oversized graphemes now make progress at narrower wrap widths.
- Prevented style-cache fingerprint collisions from leaking underline and
  other decorations into later text with the same foreground color.

## 0.5.0

### Added

- Added per-cell diff policies for always-redrawn cells, externally owned
  skipped cells, and content with an explicitly forced terminal width.

### Changed

- Added row-level routing for cells that require explicit diff semantics while
  preserving the tile-based fast path for ordinary dirty rows.

### Performance

- Reused dirty-span and dirty-tracking storage, consolidated renderer Sixel
  and stale-cell scans, cached attribute-rich SGR transitions, and removed
  per-frame renderer metrics timing allocations.
- Replaced CSI parameter substring/split parsing with direct byte parsing and
  a compact flattened parameter representation.
- Added repeatable JIT/AOT benchmarks with named DevTools CPU/memory regions.
- Added DevTools-backed allocation bytes and instances per operation to the
  benchmark JSON report.
- Retained exact truecolor style-transition pairs to eliminate repeated SGR
  construction during dense styled rendering.
- Combined adjacent truecolor foreground/background changes into one SGR
  emission for dense RGB rendering.

### Fixed

- Fixed wide-cell trailing cleanup in the line-oriented diff traversal,
  including styled wide-glyph shrink handling.
- Prevented cursor movement optimizations from overwriting cells marked as
  externally owned or crossing the trailing region of a wide glyph.

## 0.4.0

### Performance

- **Renderer hot path**: added per-buffer sixel display cache to avoid
  re-scanning every cell for terminal graphics on every frame. Added
  ASCII-only fast-path to `mayContainTerminalGraphics` for short cell
  content (≤3 chars). Combined improvement: **23.9% → 5.4% self time**
  (4.4× reduction on this hotspot). Overall renderer throughput up
  **2.1×** for full-buffer writes.
- **styleToSgr / styleDiff**: replaced `List<String>` + `join()` with
  `StringBuffer` to eliminate intermediate list allocations. Added
  64-entry LRU cache keyed by `style.packedKey` for repeated style
  emission.
- **Event decoder**: replaced `buf.sublist()` allocations with index-based
  access via `parseUtf8At()` and `decodeOneRuneAt()`. Optimized `_to7Bit`
  with pre-allocated output list. Event throughput improved **33-57%**
  across all input types.
- **Alpha compositing** (`sourceOver`): replaced `(x + 127) ~/ 255` with
  `(x + 127) * 257 >> 16` to eliminate slow integer division.
  `sourceOver` throughput improved **+61%**.
- **Float32x4 SIMD color ops**: added `batchTransformRgba()` that processes
  4 RGBA pixels in parallel using SoA (Structure of Arrays) Float32x4
  layout with pre-splatted matrix coefficients. Single-pixel path
  `_transformRgbaF64` uses shuffle-based horizontal sum for dot products.
  Color matrix ops improved **+37%**, `rgbToHsl` **+100%**.
- `consumeEscapeSequence` converted from linear if/else cascade to
  switch-on-int (Dart VM jump table dispatch).
- String width cache refactored into `_cachedStringWidth` / `_cacheStringWidth`
  helpers with same eviction strategy (no regression).

### Added

- Comprehensive benchmark suite (`benchmark/`) with 6 focused benchmarks
  stress-testing renderer diff, string width, style ops, event decoder,
  color ops, and full-stack end-to-end scenarios.
- Profiler baseline and optimized session artifacts in `benchmark/profiles/`.

### Changed

- All optimizations are internal refactors with zero public API changes.

## 0.3.0

### Added

- New `terminal_graphics.dart` module exposes shared helpers for Kitty APC
  and Sixel DCS protocols: `TerminalGraphicsControl`, `TerminalGraphicsFrame`,
  `TerminalGraphicsProtocol`, `parseTerminalGraphicsControls`,
  `mayContainTerminalGraphics`, `containsRetainedTerminalGraphics`,
  `containsSixelDisplay`, `suppressOverflowingTerminalGraphics`,
  `deleteAllRetainedGraphics`, and `deleteRetainedGraphic`.
- `OwnedCellScreen` interface with `setCellOwned` allows callers to transfer
  ownership of freshly created cells without an extra clone.
- `Buffer.create` and `ScreenBuffer` accept `tracksDirty: false` for offscreen
  composition buffers that do not need per-frame dirty-tracking bookkeeping.
- `Canvas` now opts out of dirty tracking in its internal `ScreenBuffer`.
- `KittyImage.encode` / `encodePng` accept `suppressCursorMovement` (default
  `true`), emitting `C=1` so retained-mode renderers control cursor state.
- `KittyImageDrawable` accepts `clearBeforeDraw: true` to emit a Kitty
  delete-placement sequence before drawing, preventing stale placements after
  a resize or move.
- `SixelImageDrawable` accepts `allowUpscale: false` to cap the Sixel raster
  at its native resolution instead of stretching to fill the cell area.
- `SixelImage.encode` prefixes a raster-attributes header to declare a 1:1
  pixel aspect ratio and encoded dimensions for correct rendering in foot and
  similar terminals.
- `clampRgbChannel` in `color_utils.dart` clamps a color component to [0, 255].
- Added `CanvasTerminalRenderer` for browser/wasm rendering on an HTML canvas.
- Added a web canvas example and demo page for exercising UV rendering outside
  native terminals.

### Changed

- `UvTerminalRenderer` defers retained-graphics cells (Kitty `C=1`) and Sixel
  display payloads to end-of-frame to avoid cursor-position conflicts with
  normal cell output. Retained cells are repositioned via cursor-movement
  sequences; Sixel payloads use absolute cursor positioning.
- `UvTerminalRenderer` wraps graphics payloads in a tmux DCS passthrough when
  `TMUX` is set or `TERM` starts with `tmux`, allowing Kitty and Sixel
  sequences to pass through a tmux multiplexer.
- `UvTerminalRenderer` calls `erase()` before rendering any frame that
  contains a Sixel display to prevent stale data from bleeding through.
- `StyledString.draw` now treats Kitty APC (`ESC _ G ... ESC \`) and Sixel
  DCS (`ESC P q ... ESC \`) control strings as terminal-graphics payload cells
  with the correct display-column width derived from the `c=` parameter.
- `Ansi.visibleLength` now accounts for Kitty (`c=`) and Sixel (1 cell)
  display width instead of stripping them to zero.
- `Ansi.expandTabs` and CRLF normalization use early-exit fast paths when the
  input contains no tab or CR characters.
- Truecolor SGR parameters are now clamped to [0, 255] across `style_ops`,
  `styled_string`, `ansi_slice`, `wrap`, and `terminal_renderer` to prevent
  invalid CSI sequences from oversized or 16-bit color components.
- `emojiPresentationWidth` is now a settable property; updates also clear the
  unicode string-width cache to keep cached values consistent.
- Unicode string widths are cached (up to 2048 entries, strings up to 4096
  chars) to reduce repeated grapheme-cluster traversal on the same strings.
- `Rectangle.isEmpty` now checks precomputed edges directly in hot render
  paths.
- Split terminal, stdin, and window-size helpers across IO, web, and stub
  implementations so UV can be used from browser targets.
- Extracted the common terminal renderer abstraction from `UvTerminalRenderer`
  for reuse by native and canvas-backed renderers.

### Performance

- Optimized packed cell construction for styled text and printable ASCII cells.
- Cached repeated style ids and ASCII scalar strings so Markdown-heavy render
  paths avoid repeated packed-style encoding and `String.fromCharCode` churn.
- Reduced offscreen composition overhead by using non-dirty-tracked buffers and
  updating line cells in place.

### Fixed

- `Cell._setStyle` short-circuits immediately for the zero style, skipping a
  redundant packed-key encode.
- `_LinkRegistry.intern` caches the last interned link to avoid a map lookup
  on repeated calls with the same `Link` value.
- `_containsControl` now iterates code units instead of runes.
- `_widthBits` widened from 3 to 16 to support large terminal-graphics cell
  widths (e.g. an 80-column Kitty image) without overflow in pooled ids.
- `Buffer.setCell` skips compositing when the new cell is fully opaque.
- `Buffer.fillArea` clips to the buffer bounds before iterating, preventing
  out-of-bounds dirty touches.
- `Buffer.replaceWithClone` copies in-place via `copyFrom` and updates the
  render hash incrementally.
- `Ansi.requestPrimaryDeviceAttributes` corrected from `ESC[?c` to `ESC[c`.
- Fixed web canvas background inheritance so selected rows, dominant
  backgrounds, default-background rows, and non-background cells bridge
  consistently during canvas rendering.

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
