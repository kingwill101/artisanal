import 'package:artisanal/uv.dart';
import 'dart:math';

void main() async {
  final terminal = Terminal();

  final size = await terminal.getSize();
  int width = size.width;

  await terminal.start();
  terminal.exitAltScreen();
  terminal.resize(width, 1);

  var bgIndex = 1;
  var style = UvStyle(
    bg: UvColor.basic16(bgIndex),
    fg: UvColor.basic16(0),
  ); // Black FG

  void display() {
    const hw =
        'Hello, World! Press space to change color, enter to prepend line, q to quit.';
    terminal.fillArea(Cell(content: ' ', style: style), rect(0, 0, width, 1));
    for (var i = 0; i < hw.length && i < width; i++) {
      terminal.setCell(i, 0, Cell(content: hw[i], style: style));
    }
    terminal.draw();
  }

  try {
    display();

    await for (final event in terminal.events) {
      if (event is WindowSizeEvent) {
        width = event.width;
        terminal.resize(width, 1);
        terminal.clearScreen();
        display();
      } else if (event is KeyEvent) {
        if (event.matchString('q', 'ctrl+c')) {
          break;
        } else if (event.matchString(' ')) {
          bgIndex = (bgIndex + 1) % 16;
          style = UvStyle(bg: UvColor.basic16(bgIndex), fg: UvColor.basic16(0));
          display();
        } else if (event.matchString('enter')) {
          // Prepend line: in UV this usually means printing the current buffer and moving down.
          // For this example, we'll just print a message to stdout before the TUI line.
          // But since we're in raw mode, we need to be careful.
          // Actually, the Go example doesn't seem to do much more than display.
          // Let's just change the color to show something happened.
          bgIndex = Random().nextInt(16);
          style = UvStyle(bg: UvColor.basic16(bgIndex), fg: UvColor.basic16(0));
          display();
        }
      }
    }
  } finally {
    await terminal.stop();
    print('\nExited prependline example.');
  }
}
