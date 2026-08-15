# AGENTS.md — ultraviolet

Guidance for AI agents and contributors working in `pkgs/ultraviolet`.

## What this package is

`ultraviolet` is a high-performance terminal rendering/runtime package for
Dart. It is the low-level rendering layer of the Artisanal workspace: cell and
buffer primitives, a diff-based terminal renderer, typed input decoding,
terminal capability detection, and image protocols (Kitty, iTerm2, Sixel,
half-block fallback). Keep renderer concerns (diff, sync output, frame
behavior) in this package and out of `artisanal` / `artisanal_widgets`.

Part of a Dart workspace (`resolution: workspace` in the root `pubspec.yaml`).
SDK: `>=3.10.0 <4.0.0`.

## Commands

Run from the package directory (`pkgs/ultraviolet`) unless noted:

```sh
dart pub get            # workspace: run once from repo root is also fine
dart analyze            # lint (root analysis_options.yaml: package:lints/recommended.yaml)
dart test               # full test suite
dart test test/foo_test.dart   # single file
dart run benchmark/     # run all microbenchmarks (also `task benchmark-uv` from root)
dart run example/layout.dart   # run an example (most are interactive/demo apps)
```

Root `Taskfile.yml` shortcuts: `task test-uv`, `task run-uv-layout`,
`task benchmark-uv`.

CI (`.github/workflows/ci.yaml`) runs `dart test pkgs/ultraviolet -r compact`
on Ubuntu and Windows (Windows uses `--concurrency=1`). Tests must pass on both
platforms — Windows has different ANSI/wrap expectations (see tests like
`terminal_renderer_output_parity_test.dart` that branch on `Platform.isWindows`).

## Layout

```
lib/
  ultraviolet.dart       # main public entry point (exports everything)
  web.dart               # web-only APIs (CanvasTerminalRenderer)
  colorprofile.dart      # color-profile APIs
  src/
    uv/                  # core: cells, buffers, renderer, terminal, events
      terminal.dart      # Terminal: lifecycle, capabilities, draw, events
      terminal_io.dart / terminal_web.dart / terminal_stub.dart  # platform split
      buffer.dart        # Buffer, Line, LineData (2D grid of cells)
      cell.dart          # Cell, UvStyle, UvColor, CellDiffOption, Link, Attr
      terminal_renderer.dart      # UvTerminalRenderer (diff-based ANSI renderer)
      renderer/renderer.dart      # abstract TerminalRenderer base
      renderer/uv_renderer.dart   # UvTerminalRenderer implementation
      decoder.dart / event.dart / key.dart / key_table.dart / mouse.dart
      screen.dart / screen_ops.dart / canvas.dart / layout.dart / layer.dart
      styled_string.dart / style_ops.dart / wrap.dart / ansi_slice.dart
      geometry.dart / cursor.dart / border.dart / tabstop.dart / progress_bar.dart
      capabilities.dart / environ.dart / winch*.dart / stdin_stream*.dart
      terminal_reader.dart / cancelreader.dart / event_stream.dart / logger.dart
      drawable.dart                # Drawable base
      kitty_drawable.dart / sixel_drawable.dart / iterm2_drawable.dart /
      halfblock_drawable.dart / terminal_graphics.dart   # image protocols
      filters.dart / effects.dart  # post-processing buffer filters
    colorprofile/      # profile.dart, detect.dart, convert.dart, downsample.dart, environ.dart
    unicode/           # width.dart (wcwidth), grapheme.dart (grapheme pooling)
    web/               # web.dart, canvas_renderer.dart
  (entry points above export only; no logic lives here)
test/                  # 50+ files; see Testing conventions
benchmark/             # renderer_diff, string_width, style_ops, event_decoder,
                       # color_ops, full_stack (+ profiles/ session artifacts)
example/               # demo apps (raycast_maze, conway_life, metaballs, ...)
```

## Key concepts

- **Cell** — one glyph + `UvStyle` + optional `Link`. Cells are performance
  critical: complex graphemes are pooled with refcounts, styles/links are
  interned, and a `PackedCell` 4-word tuple drives fast equality/diffing.
  Cells have `dispose()` semantics for pooled content — be careful with
  ownership (see `OwnedCellScreen.setCellOwned`).
- **CellDiffOption** — per-cell diff policy: `normal` (fast path, default),
  `skip` (cell owned by an external renderer), `alwaysUpdate`, and
  `forcedWidth(width)` for escape-sequence-backed content whose display width
  can't be inferred. Don't change default-cell semantics casually.
- **Buffer** — 2D grid of cells with dirty-tracking (`tracksDirty: false` for
  offscreen composition buffers), hashing, and clone support.
- **UvTerminalRenderer** — diffs the previous frame against the current one to
  minimize emitted ANSI. Implements scroll/relative-cursor/synchronized-output
  optimizations, tab stops, wide-glyph trailing cleanup, and deferred
  end-of-frame output for retained-graphics cells and Sixel payloads.
- **Terminal** — orchestrates lifecycle (start/stop), raw mode, resize
  (winch), capability probing (DA1/DA2/DA3, kitty keyboard/graphics, colors,
  color scheme), and input decoding into typed `Event`s on `Terminal.events`.
  A `Terminal` is **single-use**: after `stop()`, create a new instance.
- **Capabilities** — `TerminalCapabilities` tracks kitty graphics, Sixel,
  iTerm2, keyboard-enhancement flags, and color reports; drives image-protocol
  selection via `bestImageDrawable`.

## Conventions

- **Imports**: public consumers import `package:ultraviolet/ultraviolet.dart`
  (or `package:ultraviolet/web.dart` / `colorprofile.dart`). Internal code uses
  relative imports within `lib/src`. Tests may import `src/...` directly to
  reach internals (e.g. `package:ultraviolet/src/uv/uv.dart`).
- **Platform splitting**: native/web/stub variants via conditional imports,
  e.g. `import 'terminal_stub.dart' if (dart.library.io) 'terminal_io.dart'
  if (dart.library.html) 'terminal_web.dart';`. Keep IO-specific behavior out
  of shared code; Windows output differs from POSIX (CRLF, wrap handling).
- **Doc comments**: public APIs get `///` docs; major types carry
  `{@category Ultraviolet}` / `{@subCategory ...}` tags and `{@macro ...}`
  references. Match that style for new public surface.
- **API stability**: package is versioned (`CHANGELOG.md` at 0.5.0) and
  depended on by `artisanal` and `flutter_artisanal`. Prefer additive,
  backwards-compatible changes; document behavior changes in CHANGELOG.
- **Performance**: this package is hot-path optimized. Before changing core
  primitives (cell, buffer, renderer diff, style emission, string width),
  check `benchmark/` and `research_findings.md`. Existing optimizations to
  respect: grapheme/`String.fromCharCode` caching, 64-entry style-SGR LRU,
  string-width cache (2048 entries / 4096 chars), dirty-bit and hash-based
  line caching, packed-cell SIMD-style color ops. Don't reintroduce
  allocations in hot loops (prefer `StringBuffer`, index-based access).
- **Truecolor safety**: clamp RGB channels to [0, 255] wherever SGR sequences
  are generated (style_ops, styled_string, ansi_slice, wrap,
  terminal_renderer).
- **Width correctness**: display width must be computed with the unicode width
  helpers (`stringWidth`, `runeWidth`), not string length — wide glyphs,
  combining marks, emoji, and terminal-graphics payload cells (Kitty `c=`,
  Sixel = 1 cell) all have special handling.

## Testing conventions

- All tests live in `test/` and use `package:test`. Name files `*_test.dart`.
- A large portion are **parity tests** (`*_parity_test.dart`) that pin exact
  behavior, often mirroring upstream (Go-based) expectations — e.g. exact ANSI
  byte sequences from `terminal_renderer_output_parity_test.dart`, SGR
  transitions from `cell_parity_test.dart`. When changing output behavior,
  these files are the contract; update them deliberately and run the full
  suite.
- **Regression tests** guard specific bugs (see
  `terminal_renderer_overlay_clear_regression_test.dart`,
  `scroll_emoji_corruption_test.dart`, `metaballs_density_regression_test.dart`).
  Add one when fixing a bug.
- Renderer tests capture output through a `StringSink` test double (see
  `_TestSink` in `terminal_renderer_output_parity_test.dart`).
- Windows and POSIX expectations differ; where output differs, branch on
  `Platform.isWindows`.

## Gotchas

- Don't run interactive examples expecting them to exit on their own; most are
  full-screen apps driven by key events (`q`/`esc`/`ctrl+c` typically quit).
- Benchmarks under `benchmark/profiles/` are generated session artifacts —
  don't treat them as source of truth for edits; regenerate if you touch
  profiling.
- `Ansi` (general escape helpers) and `UvAnsi` (renderer-level controls) are
  distinct; check which one a change belongs to.
- Web/canvas support exists (`CanvasTerminalRenderer`, `lib/web.dart`); changes
  to the renderer abstraction (`renderer/renderer.dart`) must keep the canvas
  renderer compiling.
