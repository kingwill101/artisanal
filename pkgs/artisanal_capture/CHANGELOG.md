# Changelog

## 0.1.0

- Bound CLI reads before decoding and reject nonregular inputs and output aliases
  of the source, including symlinks and hardlinks.
- Index gallery end markers once per scenario while preserving substring
  matching, with bounded index sizes and deduplicated markers.
- Release temporary cells and buffers throughout capture conversion and export,
  including partial failures.
- Add an attributed, checksum-pinned snapshot of Dart SDK issue 64170 as a
  real-world Markdown bench, including exact status-cell preservation and
  hidden-comment checks at 32/64/80/96/120 columns.
- Add detached, versioned terminal cell captures with validated JSON round trips.
- Capture UV buffers, ANSI-styled views, and widgets at deterministic dimensions.
- Export PNGs using Ultraviolet's native software raster backend and
  `package:image`, with explicit TrueType font faces and fidelity diagnostics.
- Add an Artisanal-based CLI for Markdown, styled ANSI, and saved captures.
- Export script-free HTML previews containing the exact rendered PNG.
- Add a multi-width `gallery` command with an HTML index, render manifest,
  source/ANSI/cell evidence, overflow diagnostics, and end-marker checks.
- Add 18 focused Markdown scenarios alongside the original nested quote case.
- Accept both standard BEL and ST OSC 8 terminators; wrapped hyperlinks no
  longer fail capture validation. Raw BEL and unsafe hyperlink payloads remain
  rejected.
- Consolidate widget and runtime capture on detached UV cell buffers:
  `captureWidget` supports `WidgetCaptureMode.renderedFrame`, and
  `captureProgramFrame` requires a recorded `nativeFrame` instead of treating
  diagnostic snapshot JSON as lossless.
- Reject native-frame captures containing drawable payloads rather than
  silently replacing terminal graphics with text.
