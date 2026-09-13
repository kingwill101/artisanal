# Native terminal captures

`artisanal_capture` turns actual terminal cells into reusable snapshots and
native PNG images. Use it for documentation figures, visual bug reports, and
deterministic Markdown/widget scenarios.

The capture layer owns snapshot validation, JSON serialization, and the CLI.
Ultraviolet owns cell-to-pixel rendering. The native path uses `package:image`
and software TrueType parsing/rasterization; no Chromium or Flutter engine is
required.

## Quick start

From the repository root, save the nested Markdown fixture:

```sh
dart run pkgs/artisanal_capture/bin/artisanal_capture.dart render \
  pkgs/artisanal_capture/example/scenarios/nested_quotes.md \
  --columns 66 --format capture --output nested-quotes.json
```

Then export it using fonts available on your machine:

```sh
dart run pkgs/artisanal_capture/bin/artisanal_capture.dart render \
  nested-quotes.json --input-format capture \
  --font /path/to/Mono-Regular.ttf \
  --font-bold /path/to/Mono-Bold.ttf \
  --font-italic /path/to/Mono-Italic.ttf \
  --font-bold-italic /path/to/Mono-BoldItalic.ttf \
  --font-size 16 --padding 16 --output nested-quotes.png
```

`--format html` embeds the exact PNG in a self-contained, script-free preview.
It does not rerender Markdown in the browser.

For batch review, use `gallery <scenario-directory> --widths 32,64,96
--output <gallery-directory>` with the same font/profile flags. The gallery
includes an HTML index, native PNGs, full previews, Markdown/ANSI/cell evidence,
and a JSON manifest. Overflow and unsupported raster features are visible
diagnostics rather than silently successful screenshots. See the
[gallery instructions](https://github.com/kingwill101/artisanal/blob/artisanal/pkgs/artisanal_capture/README.md#markdown-scenario-gallery).

## Choose the right input

- **UV buffer:** `TerminalCapture.fromBuffer` preserves the actual cells.
- **Styled view:** `TerminalCapture.fromAnsi` draws SGR/OSC 8 text through
  Ultraviolet's styled-string path at fixed dimensions.
- **Widget scenario:** `captureWidget` runs the real widget layout/update
  pipeline, supports deterministic setup interactions, then captures the view.
- **Live PTY/transport:** not implemented by this package's initial CLI. A
  stream of cursor-control sequences is not equivalent to a styled view and is
  rejected rather than captured incorrectly.

Use cell JSON for structural assertions; use PNGs for visual inspection.
For repeatable pixel comparisons, retain the same font files, font size,
cell dimensions, palette, and renderer version. The initial JSON schema stores
cell data; it does not bundle the raster profile or font assets.

See the [package guide](https://github.com/kingwill101/artisanal/blob/artisanal/pkgs/artisanal_capture/README.md) for complete API
examples, supported styles, strict diagnostics, and current limitations.
