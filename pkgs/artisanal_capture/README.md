# Artisanal Capture

Capture real terminal cells and export styled images using native Dart.
No Chromium, browser automation, Flutter engine, or native font library is
required. `package:image` produces PNGs; Ultraviolet owns the raster backend.

Use it to investigate Markdown/layout defects, capture reproducible widget
scenarios, and generate documentation images from actual application views.

## CLI

Run from this workspace:

```sh
dart run pkgs/artisanal_capture/bin/artisanal_capture.dart --help
```

Capture the included complex Markdown fixture as lossless cell JSON:

```sh
dart run pkgs/artisanal_capture/bin/artisanal_capture.dart render \
  pkgs/artisanal_capture/example/scenarios/nested_quotes.md \
  --columns 66 --format capture --output nested-quotes.json
```

Export an image with explicit, static monospace TrueType fonts:

```sh
dart run pkgs/artisanal_capture/bin/artisanal_capture.dart render \
  nested-quotes.json --input-format capture \
  --font /path/to/DejaVuSansMono.ttf \
  --font-bold /path/to/DejaVuSansMono-Bold.ttf \
  --font-italic /path/to/DejaVuSansMono-Oblique.ttf \
  --font-bold-italic /path/to/DejaVuSansMono-BoldOblique.ttf \
  --font-size 16 --padding 16 --output nested-quotes.png
```

The paths above are placeholders: supply fonts you are licensed to use. Fonts
are not discovered, downloaded, or substituted automatically. DejaVu Sans Mono
is a useful choice for Latin text, bullets, box drawing, and block characters.

Use `--format html --output preview.html` for a self-contained preview of the
**same PNG**, at native dimensions. HTML output requires no web font or script.
Markdown can be rendered directly to PNG/HTML without the intermediate JSON.

Other options:

- `--input-format ansi`: capture SGR/OSC 8 styled text, not a terminal session.
- `--rows`: crop to an explicit viewport; otherwise keep all source lines.
- `--cell-width`, `--cell-height`: override font-derived cell dimensions.
- `--foreground '#cccccc'`, `--background '#000000'`: terminal default colors.
- `--no-strict`: produce an incomplete image with explicit diagnostics for
  unsupported content. Strict mode is the default.
- `--force`: explicitly replace an existing destination.

Compile a standalone native executable:

```sh
dart compile exe pkgs/artisanal_capture/bin/artisanal_capture.dart \
  -o artisanal_capture
```

The compiled executable still needs the chosen font files, not the Dart SDK.

## Markdown scenario gallery

Generate a whole directory at multiple widths using the same raster profile
as `render`:

```sh
dart run pkgs/artisanal_capture/bin/artisanal_capture.dart gallery \
  pkgs/artisanal_capture/example/scenarios \
  --output build/captures/markdown-gallery --widths 32,64,96 \
  --font /path/to/DejaVuSansMono.ttf \
  --font-bold /path/to/DejaVuSansMono-Bold.ttf \
  --font-italic /path/to/DejaVuSansMono-Oblique.ttf \
  --font-bold-italic /path/to/DejaVuSansMono-BoldOblique.ttf \
  --font-size 16 --padding 16 --no-strict
```

Open `build/captures/markdown-gallery/index.html`. Each scenario has
side-by-side native-sized images, full previews, original Markdown, raw ANSI,
and cell JSON. `manifest.json` records the widths, font paths, render profile,
diagnostics, and artifact filenames. Keep the selected fonts with the scenario
for repeatable pixels; the manifest records paths, not font binaries.

- The directory scan is non-recursive and excludes `README.md`.
- Output must be empty unless `--force` is supplied. Other files are not deleted.
- Overflowing rendered rows are flagged before viewport clipping.
- Fixtures may include a visible `END_NAME` line to detect lost end markers.
- `--no-strict` keeps images with unsupported glyphs/shaping **and labels
  their diagnostics**. Omit it to require full raster support.
- A failed case does not stop the remaining cases; it is recorded in the
  index/manifest, and the command exits nonzero if any case failed.
- “Rendered” means generation succeeded, not that the Markdown is correct.
  Inspect the images and source together.

The included [scenario index](example/scenarios/README.md) describes the corpus
and findings from visual inspection. Generated galleries belong in ignored
build output, not in the source package.

## Library

### Capture and save cells

```dart
import 'dart:convert';
import 'package:artisanal_capture/artisanal_capture.dart';

final capture = TerminalCapture.fromAnsi(
  '\x1b[31mHello\x1b[0m',
  columns: 20,
  rows: 2,
);
final json = jsonEncode(capture.toJson());
final restored = TerminalCapture.fromJson(jsonDecode(json));
final buffer = restored.toBuffer(); // Detached, mutable UV buffer.
```

Use `TerminalCapture.fromBuffer(buffer)` when you already have the native UV
buffer. Neither subsequent source mutations nor changes to a returned buffer
affect a saved capture. Cell content, widths, colors, attributes, underline
styles/colors, hyperlinks, and diff options survive JSON round trips.

The capture-only entrypoint is free of `dart:io`. Native image APIs are in the
separate `rendering.dart` entrypoint.

### Export an image

```dart
import 'dart:io';
import 'package:artisanal_capture/rendering.dart';

final font = RasterFont.fromTtf(
  await File('Mono-Regular.ttf').readAsBytes(),
  bold: await File('Mono-Bold.ttf').readAsBytes(),
  italic: await File('Mono-Italic.ttf').readAsBytes(),
  boldItalic: await File('Mono-BoldItalic.ttf').readAsBytes(),
);
final image = CaptureRasterizer(
  font: font,
  options: const RasterRenderOptions(fontSize: 16, padding: 12),
).render(capture);

await File('capture.png').writeAsBytes(image.png);
await File('capture.html').writeAsString(image.toHtml(title: 'My component'));
```

### Capture a widget scenario

```dart
import 'package:artisanal_capture/widgets.dart';
import 'package:artisanal_widgets/widgets.dart';

final capture = await captureWidget(
  Column(children: [Text('Status'), Text('Ready')]),
  columns: 40,
  rows: 6,
  arrange: (tester) {
    // Drive keys/mouse or advance a manual clock before the final capture.
    tester.pump();
  },
);
```

This uses the real widget/TEA layout pipeline, not an HTML representation.
Async state should be awaited explicitly in `arrange`; capture does not guess
when an app is ready using sleeps.

`example/widget_capture.dart` is a runnable consumer that writes a cell capture
for later export with the CLI.

## Fidelity contract

- Cell positions and terminal color/style data are authoritative. Empty cells
  retain their own backgrounds; adjacent colors are never inferred.
- Glyphs use the supplied font files, quantized cell metrics, and deterministic
  4×4 software antialiasing. Native terminal font hinting and subpixel rendering
  may differ. This is **not a promise of pixel identity across all terminals**.
- Supply actual bold, italic, and bold-italic faces when the view uses them.
- Wide single-codepoint glyphs occupy their declared cell span. Glyphs are
  clipped to that span and row.
- RGB, basic/indexed palettes, reverse, conceal, faint, underline variants, and
  strikethrough are rendered. Blink is frozen in its visible phase.
- Missing glyphs/faces, multi-codepoint graphemes requiring shaping, color
  fonts, variable/CFF fonts, and external terminal graphics are not silently
  approximated. Strict exports fail; non-strict exports report diagnostics.
- The initial capture format stores cells, not cursor state, font binaries, or
  the raster profile. Keep the font files and export options with a scenario
  when reproducible pixel comparisons are required.
- ANSI capture accepts styled views only. Cursor commands, OSC terminal
  settings, and graphics sequences are rejected. It is not a PTY emulator or
  subprocess recorder.

## Validation

```sh
dart analyze pkgs/artisanal_capture
dart test pkgs/artisanal_capture
dart test pkgs/ultraviolet/test/raster_test.dart
```

Cell limits are public constants in the capture API. Image export is bounded to
16 megapixels and 16000 pixels per axis. Tests use an original synthetic
TrueType fixture, avoiding system-font or network dependencies.
