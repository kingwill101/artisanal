# Work with the terminal

Most applications should start with `Console`, the TUI runtime, or widgets.
Use the terminal API directly when you need cursor control, raw mode, input
events, ANSI helpers, or access to the underlying terminal dimensions.

## Quick Start

```dart
import 'package:artisanal/terminal.dart';

void main() {
  final terminal = StdioTerminal();
  try {
    terminal.clearScreen();
    terminal.hideCursor();
    terminal.moveCursor(1, 1);
    terminal.writeln('Hello, terminal!');
    terminal.showCursor();
    terminal.flush();
  } finally {
    terminal.dispose();
  }
}
```

## Terminal Surface

Use the `Terminal` interface for cursor movement, screen control, and writing:

```dart
import 'package:artisanal/terminal.dart';

void main() {
  final terminal = StdioTerminal();
  terminal.hideCursor();
  terminal.cursorToColumn(1);
  terminal.write('Working...');
  terminal.clearLine();
  terminal.write('Done');
  terminal.showCursor();
  terminal.flush();
  terminal.dispose();
}
```

## Raw Mode and Input

Raw mode is needed for interactive input (character-by-character, no local echo).

```dart
import 'package:artisanal/terminal.dart';

void main() {
  final terminal = StdioTerminal();
  final guard = terminal.enableRawMode();
  try {
    terminal.writeln('Press q to quit');
    while (true) {
      final byte = terminal.readByte();
      if (byte == -1) break;
      if (byte == 'q'.codeUnitAt(0)) break;
      if (Keys.isPrintable(byte)) {
        terminal.write(String.fromCharCode(byte));
      }
    }
  } finally {
    guard.restore();
    terminal.dispose();
  }
}
```

## ANSI Helpers

Use `Ansi` constants directly for simple styling:

```dart
import 'package:artisanal/terminal.dart';
import 'dart:io';

void main() {
  stdout.write(Ansi.bold);
  stdout.write('Bold');
  stdout.write(Ansi.reset);
  stdout.writeln(' normal');
}
```

## Shared stdin stream

Some interactive workflows use the shared stdin stream. Remember to shut it down if you started it.

```dart
import 'package:artisanal/terminal.dart';

Future<void> main() async {
  final sub = sharedStdinStream.listen((data) {
    // handle bytes
  });

  await Future<void>.delayed(const Duration(milliseconds: 200));
  await sub.cancel();
  await shutdownSharedStdinStream();
}
```

## Image Protocols (Kitty / iTerm2 / Sixel)

Artisanal includes helpers for terminal image protocols.

```dart
import 'package:artisanal/terminal.dart';
import 'package:image/image.dart' as img;

void main() {
  final image = img.Image(width: 2, height: 1);
  image.setPixelRgba(0, 0, 255, 0, 0, 255);
  image.setPixelRgba(1, 0, 0, 255, 0, 255);

  final seq = KittyImage.encode(image, columns: 2, rows: 1);
  final terminal = StdioTerminal();
  terminal.write(seq);
  terminal.flush();
  terminal.dispose();
}
```

## Testing with StringTerminal

Use `StringTerminal` to capture output and simulate input in tests.

```dart
import 'package:artisanal/terminal.dart';

void main() {
  final terminal = StringTerminal();
  terminal.writeln('testing');
  terminal.simulateTyping('abc');

  print(terminal.output);
  print(terminal.operations);
}
```

## Things to keep in mind

- Always call `dispose()` to restore cursor, raw mode, and input state.
- `enableRawMode()` is a no-op when stdin is not a TTY.
- `moveCursor()` and `cursorToColumn()` use 1-based coordinates.
- Shared stdin keeps the event loop alive; call `shutdownSharedStdinStream()` when done.

## Where to go next

- [docs_index.md](docs_index.md) - Full documentation index
- [renderer.md](renderer.md)
- [uv.md](uv.md)
- [tui.md](tui.md)
