# Renderer Abstraction

Renderers control how styled output is generated and where it goes. Artisanal provides multiple renderer types for terminals, strings, and no-op output.

## Quick Start

```dart
import 'package:artisanal/artisanal.dart';

void main() {
  final renderer = TerminalRenderer(forceProfile: ColorProfile.ansi256);
  renderer.writeln('Hello from TerminalRenderer');
  print(renderer.colorProfile);
}
```

## Renderer Types

### TUI Renderer Modes

The TUI runtime can drive renderers in either full-screen or inline mode.

```dart
await runProgram(
  const MyModel(),
  options: const ProgramOptions(
    screenMode: ScreenMode.inline,
    inlineHeight: 4,
    uiAnchor: UiAnchor.bottom,
  ),
);
```

Inline mode keeps the terminal on the primary screen, captures UV renderer
output, and remaps absolute row-addressing sequences into the anchored inline
region. Full-screen mode continues to use the alternate screen buffer.

For application-level guidance, including log streaming and native scrollback
expectations, see [inline_tui.md](inline_tui.md).

### TerminalRenderer

Auto-detects terminal capabilities and applies ANSI styling.

```dart
import 'package:artisanal/artisanal.dart';

void main() {
  final renderer = TerminalRenderer();
  renderer.writeln('Auto-detected colors');
}
```

### StringRenderer

Captures output as strings, useful for tests.

```dart
import 'package:artisanal/artisanal.dart';

void main() {
  final renderer = StringRenderer();
  renderer.write('hello');
  renderer.writeln(' world');
  print(renderer.stringOutput);
}
```

### NullRenderer

Silences output entirely.

```dart
import 'package:artisanal/artisanal.dart';

void main() {
  final renderer = NullRenderer();
  renderer.writeln('This will not appear');
}
```

## Default Renderer

The global `defaultRenderer` is used by Console unless overridden.

```dart
import 'package:artisanal/artisanal.dart';

void main() {
  defaultRenderer = StringRenderer();
  defaultRenderer.writeln('captured');

  final out = (defaultRenderer as StringRenderer).flush();
  print(out);

  resetDefaultRenderer();
}
```

## Color Profiles

Renderer color profiles map to terminal capability levels.

```dart
import 'package:artisanal/artisanal.dart';

void main() {
  final renderer = TerminalRenderer(forceProfile: ColorProfile.ascii);
  print(renderer.colorProfile); // ascii
}
```

## Gotchas

- `TerminalRenderer` strips ANSI when `forceNoAnsi` is true or output is not a TTY.
- `StringRenderer` writes to `stringOutput`; `output` is null.
- `defaultRenderer` is global; always reset it in tests.

## Color Matrix and Post-Processing Effects

The UV system exposes a `BufferFilter` pipeline that can transform terminal
cell colors and apply spatial/temporal effects. Filters operate on a
`Buffer` (rather than raw ANSI) and compose cleanly with the renderer.

### Color Matrix Effects

`ColorMatrixFilter` applies a 4×5 RGBA transform to cell style colors
(foreground, background, and underline color). Built-in presets cover the
most common transformations:

```dart
import 'package:ultraviolet/ultraviolet.dart';

final sink = BufferRenderSink(width: 80, height: 24);

// Desaturate the entire frame
final gray = ColorMatrixFilter.grayscale();
final result = sink.render(sourceBuffer, [gray], dt: 1 / 60);
renderer.render(result);
```

See [uv.md → Color Matrix Effects](uv.md#color-matrix-effects) for the full
`ColorMatrix` API, chaining examples, and per-channel control.

### Post-Processing Filters

`filters.dart` provides spatial and temporal effects including `LiquifyFilter`,
`VignetteFilter`, `ScanlineFilter`, `WaveDistortionFilter`, and `GhostingFilter`.
High-level presets (`CrtFilter`, `AmberTerminalFilter`, `PhosphorFilter`) compose
these into ready-to-use retro display effects.

```dart
// CRT-style preset
final crt = CrtFilter(distortion: 0.22, vignette: 0.16);
final result = sink.render(sourceBuffer, [crt], dt: elapsedSeconds);
renderer.render(result);
```

See [uv.md → Post-Processing Filters](uv.md#post-processing-filters) for the
full filter catalog and `BufferRenderSink` usage.

## Related Docs

- [docs_index.md](docs_index.md) - Full documentation index
- [terminal.md](terminal.md)
- [style.md](style.md)
- [colorprofile.md](colorprofile.md)
- [uv.md](uv.md) - UV system and buffer filter pipeline
