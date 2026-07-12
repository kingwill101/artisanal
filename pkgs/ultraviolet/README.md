# Ultraviolet

[![Dart SDK](https://img.shields.io/badge/Dart-3.10%2B-0175C2?logo=dart&logoColor=white)](https://dart.dev/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](../../LICENSE)
[![Package](https://img.shields.io/badge/package-ultraviolet-0A1F44)](./)

`ultraviolet` is a high-performance terminal rendering/runtime package for Dart.
It provides the low-level primitives you need to build interactive terminal
applications: screen buffers, styled cells, diff-based rendering, typed input
events, and terminal capability handling.

## Features

- Cell/buffer-based rendering model
- High-performance diff renderer (`UvTerminalRenderer`)
- Typed keyboard/mouse/focus/resize events
- Style + color primitives (`UvStyle`, `UvColor`)
- ANSI helpers (`Ansi`) and renderer-level ANSI sequences (`UvAnsi`)
- Terminal capability detection
- Image protocol support (Kitty, iTerm2, Sixel, fallback drawables)

## Installation

This package is currently configured as workspace/private (`publish_to: none`).

Workspace usage:

```yaml
dependencies:
  ultraviolet:
```

Git dependency usage:

```yaml
dependencies:
  ultraviolet:
    git:
      url: https://github.com/kingwill101/artisanal.git
      path: pkgs/ultraviolet
```

## Quick Start

```dart
import 'package:ultraviolet/ultraviolet.dart';

Future<void> main() async {
  final terminal = Terminal();
  await terminal.start();
  try {
    terminal.enterAltScreen();
    terminal.hideCursor();

    terminal.setCell(2, 1, Cell(content: 'U'));
    terminal.setCell(3, 1, Cell(content: 'V'));
    terminal.draw();

    await for (final event in terminal.events) {
      if (event is KeyEvent && event.matchString('q', 'esc', 'ctrl+c')) {
        break;
      }
    }
  } finally {
    terminal.showCursor();
    terminal.exitAltScreen();
    await terminal.stop();
  }
}
```

## Demo Captures

Raycast maze:

![Raycast maze demo](https://github.com/kingwill101/artisanal/raw/artisanal/pkgs/ultraviolet/assets/raycast.gif)

Conway's Game of Life:

![Conway demo](https://github.com/kingwill101/artisanal/raw/artisanal/pkgs/ultraviolet/assets/conway.gif)

Metaballs / marching squares:

![Metaballs demo](https://github.com/kingwill101/artisanal/raw/artisanal/pkgs/ultraviolet/assets/metaballs.gif)

Layout example (`example/layout.dart`):

![Layout demo](https://github.com/kingwill101/artisanal/raw/artisanal/pkgs/ultraviolet/assets/layout.png)

## Performance Tips

- Prefer incremental updates over full-screen redraws.
- For resize-heavy or animation-heavy apps, consider:
  - `terminal.setScrollOptim(false)`
  - `terminal.setSynchronizedOutput(true)`

## API Surface

- `Terminal`  
  Runtime entrypoint: lifecycle, event stream, capability queries, and drawing.
- `Buffer`  
  2D grid of cells representing screen state for a frame.
- `Cell`  
  A single rendered glyph plus style/link metadata.
- `UvStyle` / `UvColor`  
  Text attributes and color model for foreground/background styling.
- `UvTerminalRenderer`  
  Diff-based renderer that minimizes terminal output between frames.
- `Ansi` / `UvAnsi`  
  ANSI escape sequence helpers (`Ansi`) and UV renderer ANSI controls (`UvAnsi`).
- `Event` types (`KeyEvent`, `MouseEvent`, `WindowSizeEvent`, etc.)  
  Typed input and terminal-state events from `terminal.events`.

## Small How-Tos

Write ANSI sequences directly:

```dart
import 'dart:io';
import 'package:ultraviolet/ultraviolet.dart';

stdout.write(Ansi.clearScreen);
stdout.write(Ansi.cursorTo(1, 1));
stdout.write('${Ansi.bold}Ultraviolet${Ansi.reset}');
```

Draw a styled label:

```dart
terminal.setCell(
  2,
  2,
  Cell(
    content: 'H',
    style: const UvStyle(
      fg: UvColor.rgb(255, 210, 120),
      attrs: Attr.bold,
    ),
  ),
);
terminal.setCell(3, 2, Cell(content: 'i'));
terminal.draw();
```

Fill an area:

```dart
final panel = rect(0, 0, 20, 6);
terminal.fillArea(
  Cell(content: ' ', style: const UvStyle(bg: UvColor.rgb(24, 32, 48))),
  panel,
);
terminal.draw();
```

Handle resize safely:

```dart
await for (final event in terminal.events) {
  if (event is WindowSizeEvent) {
    terminal.resize(event.width, event.height);
    terminal.clearScreen();
    terminal.draw();
  }
}
```

Run a simple animation loop:

```dart
final timer = Timer.periodic(const Duration(milliseconds: 33), (_) {
  // update state
  terminal.clear();
  // redraw frame
  terminal.draw();
});
```

Pick best image protocol automatically:

```dart
final drawable = terminal.bestImageDrawableForTerminal(
  image,
  columns: 40,
  rows: 20,
);
drawable.draw(terminal, rect(2, 2, 40, 20));
terminal.draw();
```

Use synchronized output for heavy redraws:

```dart
terminal.setScrollOptim(false);
terminal.setSynchronizedOutput(true);
```

## Examples

See:

- `pkgs/ultraviolet/example/`
