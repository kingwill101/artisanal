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
- Per-cell diff policies (`normal`, `skip`, `alwaysUpdate`, `forcedWidth`)
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

Every example in [`pkgs/ultraviolet/example/`](example/) has a VHS recording
regenerated from the tapes in [`pkgs/ultraviolet/example/.vhs/`](example/.vhs/README.md):

```sh
task uv-demos   # compiles each example, then records all GIFs into assets/
```

### 3D & raytracing

**Raycast maze** (`example/raycast_maze.dart`):

![Raycast maze demo](https://github.com/kingwill101/artisanal/raw/artisanal/pkgs/ultraviolet/assets/raycast_maze.gif)

**SDF raymarcher** (`example/sdf_raymarcher.dart`):

![SDF raymarcher demo](https://github.com/kingwill101/artisanal/raw/artisanal/pkgs/ultraviolet/assets/sdf_raymarcher.gif)

**Path tracer** (`example/path_tracer.dart`):

![Path tracer demo](https://github.com/kingwill101/artisanal/raw/artisanal/pkgs/ultraviolet/assets/path_tracer.gif)

### Simulations

**Conway's Game of Life** (`example/conway_life.dart`):

![Conway demo](https://github.com/kingwill101/artisanal/raw/artisanal/pkgs/ultraviolet/assets/conway_life.gif)

**Metaballs / marching squares** (`example/metaballs_marching_squares.dart`):

![Metaballs demo](https://github.com/kingwill101/artisanal/raw/artisanal/pkgs/ultraviolet/assets/metaballs_marching_squares.gif)

**Boids swarm** (`example/boids_swarm.dart`):

![Boids swarm demo](https://github.com/kingwill101/artisanal/raw/artisanal/pkgs/ultraviolet/assets/boids_swarm.gif)

**N-body gravity** (`example/nbody_gravity.dart`):

![N-body gravity demo](https://github.com/kingwill101/artisanal/raw/artisanal/pkgs/ultraviolet/assets/nbody_gravity.gif)

**Network topology** (`example/network_topology_sim.dart`):

![Network topology demo](https://github.com/kingwill101/artisanal/raw/artisanal/pkgs/ultraviolet/assets/network_topology_sim.gif)

**Wave function collapse** (`example/wave_function_collapse.dart`):

![Wave function collapse demo](https://github.com/kingwill101/artisanal/raw/artisanal/pkgs/ultraviolet/assets/wave_function_collapse.gif)

### Games & interactive

**Pong** (`example/pong.dart`):

![Pong demo](https://github.com/kingwill101/artisanal/raw/artisanal/pkgs/ultraviolet/assets/pong.gif)

**Mouse drawing** (`example/draw.dart`):

![Draw demo](https://github.com/kingwill101/artisanal/raw/artisanal/pkgs/ultraviolet/assets/draw.gif)

### Effects & shaders

**Shader toy** (`example/terminal_shader_toy.dart`):

![Shader toy demo](https://github.com/kingwill101/artisanal/raw/artisanal/pkgs/ultraviolet/assets/terminal_shader_toy.gif)

**Post effects** (`example/effects.dart`):

![Effects demo](https://github.com/kingwill101/artisanal/raw/artisanal/pkgs/ultraviolet/assets/effects.gif)

**TV test pattern** (`example/tv.dart`):

![TV demo](https://github.com/kingwill101/artisanal/raw/artisanal/pkgs/ultraviolet/assets/tv.gif)

### Layout & UI

**Layout** (`example/layout.dart`):

![Layout demo](https://github.com/kingwill101/artisanal/raw/artisanal/pkgs/ultraviolet/assets/layout.gif)

**Splits** (`example/splits.dart`):

![Splits demo](https://github.com/kingwill101/artisanal/raw/artisanal/pkgs/ultraviolet/assets/splits.gif)

**Hello world** (`example/main.dart`, `example/helloworld.dart`):

![Main demo](https://github.com/kingwill101/artisanal/raw/artisanal/pkgs/ultraviolet/assets/main.gif)

![Hello world demo](https://github.com/kingwill101/artisanal/raw/artisanal/pkgs/ultraviolet/assets/helloworld.gif)

**Alternate screen toggle** (`example/altscreen.dart`):

![Alt screen demo](https://github.com/kingwill101/artisanal/raw/artisanal/pkgs/ultraviolet/assets/altscreen.gif)

**Space** (`example/space.dart`):

![Space demo](https://github.com/kingwill101/artisanal/raw/artisanal/pkgs/ultraviolet/assets/space.gif)

**Terminal demo** (`example/uv_demo.dart`):

![UV demo](https://github.com/kingwill101/artisanal/raw/artisanal/pkgs/ultraviolet/assets/uv_demo.gif)

**Image protocols** (`example/image.dart`, `example/uv_graphics_parity.dart`):

![Image demo](https://github.com/kingwill101/artisanal/raw/artisanal/pkgs/ultraviolet/assets/image.gif)

![Graphics parity demo](https://github.com/kingwill101/artisanal/raw/artisanal/pkgs/ultraviolet/assets/uv_graphics_parity.gif)

**File pager** (`example/bat.dart`):

![Bat demo](https://github.com/kingwill101/artisanal/raw/artisanal/pkgs/ultraviolet/assets/bat.gif)

**Panic recovery** (`example/panic.dart`):

![Panic demo](https://github.com/kingwill101/artisanal/raw/artisanal/pkgs/ultraviolet/assets/panic.gif)

**Prepend line** (`example/prependline.dart`):

![Prepend line demo](https://github.com/kingwill101/artisanal/raw/artisanal/pkgs/ultraviolet/assets/prependline.gif)

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

For a narrower dependency surface, import the focused entrypoint matching the
layer you use:

```dart
import 'package:ultraviolet/core.dart';      // cells, buffers, layout
import 'package:ultraviolet/input.dart';     // events and decoding
import 'package:ultraviolet/rendering.dart'; // diff renderer and effects
import 'package:ultraviolet/terminal.dart';  // terminal lifecycle
import 'package:ultraviolet/unicode.dart';   // graphemes and cell widths
```

All five entrypoints are browser-safe. The umbrella
`package:ultraviolet/ultraviolet.dart` remains available when an application
needs APIs from several layers.

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

Control exceptional diff behavior on a cell:

```dart
terminal.setCell(
  0,
  0,
  Cell(content: '•', diffOption: CellDiffOption.alwaysUpdate),
);
```

Use `CellDiffOption.skip` for terminal cells owned by an external renderer and
`CellDiffOption.forcedWidth(width)` for escape-sequence-backed content whose
display width cannot be inferred from its text. Ordinary cells should keep the
default `CellDiffOption.normal` fast path.

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
