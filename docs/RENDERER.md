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

## Related Docs

- [DOCS_INDEX.md](DOCS_INDEX.md) - Full documentation index
- [TERMINAL.md](TERMINAL.md)
- [STYLE.md](STYLE.md)
- [COLORPROFILE.md](COLORPROFILE.md)
