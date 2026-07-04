# flutter_artisanal

Flutter rendering, input bridge, and app shell for [Ultraviolet](https://github.com/anomalousco/artisanal) terminal buffers.

Runs TUI programs built with the [artisanal](https://github.com/anomalousco/artisanal) Elm-architecture framework inside a normal Flutter app or Flutter Web app. No `dart:js_interop`, no HTML canvas manipulation, no extra platform dependencies beyond Flutter itself.

## Features

- **`TerminalWidget`** — pure Flutter `CustomPaint` renderer for UV `Buffer`s
- **`TuiController`** — runs a TUI `Model` in-process and exposes a repaint `Listenable`
- **Keyboard input** — Flutter `Focus`/raw-key events translated to terminal byte sequences
- **Desktop + Web** — works with `flutter run` on Linux/macOS/Windows and `flutter run -d chrome`

## Getting started

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_artisanal: ^0.1.0
```

Because `flutter_artisanal` depends on `artisanal` and `ultraviolet`, add those to your workspace `pubspec.yaml` or use path overrides in your example app.

## Usage

Wrap a `TerminalWidget` in a widget tree and drive it with a `TuiController`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_artisanal/flutter_artisanal.dart' as uv;

class CounterModel implements uv.Model {
  const CounterModel([this.count = 0]);

  final int count;

  @override
  uv.Cmd? init() => null;

  @override
  (uv.Model, uv.Cmd?) update(uv.Msg msg) {
    return switch (msg) {
      uv.KeyMsg(key: uv.Key(type: uv.KeyType.up)) ||
      uv.KeyMsg(key: uv.Key(type: uv.KeyType.runes, runes: [0x2b])) =>
        (CounterModel(count + 1), null),
      uv.KeyMsg(key: uv.Key(type: uv.KeyType.down)) ||
      uv.KeyMsg(key: uv.Key(type: uv.KeyType.runes, runes: [0x2d])) =>
        (CounterModel(count - 1), null),
      _ => (this, null),
    };
  }

  @override
  String view() => 'Count: $count\n\nControls: +/-';
}

class TuiExample extends StatefulWidget {
  const TuiExample({super.key});

  @override
  State<TuiExample> createState() => _TuiExampleState();
}

class _TuiExampleState extends State<TuiExample> {
  late final uv.TuiController<CounterModel> _controller;

  @override
  void initState() {
    super.initState();
    _controller = uv.TuiController<CounterModel>(
      model: const CounterModel(),
      options: const uv.ProgramOptions(altScreen: true, hotReload: false),
    );
    _controller.start();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return uv.TerminalWidget(
      buffer: _controller.buffer,
      repaint: _controller.repaint,
      onKey: _controller.addInput,
    );
  }
}

void main() => uv.runFlutterApp(const TuiExample());
```

### Key input

`TerminalWidget.onKey` receives raw terminal byte sequences. Pass `controller.addInput` to forward keystrokes into the TUI runtime. Supported keys include:

- Printable characters (UTF-8)
- Enter, Backspace, Tab, Escape
- Arrow keys, Home, End, Delete, Insert, PageUp, PageDown
- F1–F4

### Repaint loop

`TuiController.repaint` is a `Listenable` that fires every time the UV renderer flushes a new frame. `TerminalWidget` rebuilds automatically when it fires, so the screen stays in sync with the TUI state.

## Running the example

```bash
flutter run -d linux   # or -d macos, -d windows, -d chrome
```

## Architecture

```
Flutter app
  └── TuiExample (StatefulWidget)
        ├── TuiController (artisanal runtime host)
        │     ├── EmbeddedTerminalBackend
        │     ├── FlutterTerminalRenderer (UltravioletTuiRenderer)
        │     └── runProgram(model, host, renderer)
        └── TerminalWidget (CustomPaint)
              ├── Focus (raw key → bytes)
              └── TerminalPainter (dart:ui Paragraphs + Rects)
```

## Constraints

- **No extra Python dependencies** — this is a pure Flutter package.
- **No `dart:js_interop`** — web support uses standard Flutter widgets only.
- **Windows 10+** keyboard input uses `LogicalKeyboardKey` ANSI sequences.
