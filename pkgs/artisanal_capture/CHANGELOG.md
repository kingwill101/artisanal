# Changelog

## 0.1.0

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
