import 'dart:async';
import 'package:artisanal/src/uv/terminal.dart';

void main() async {
  final terminal = Terminal();

  print('Starting UV Terminal Demo...');
  print('Press "q" or Ctrl-C to exit.');
  print('Press "m" to toggle mouse tracking.');
  print('Press "c" to clear screen.');

  await Future.delayed(Duration(seconds: 1));

  await terminal.start();

  terminal.enterAltScreen();
  terminal.hideCursor();

  bool mouseEnabled = false;
  String lastEvent = 'None';
  int mouseX = -1;
  int mouseY = -1;

  void draw() {
    final buf = terminal.buffer;
    buf.fill(Cell(content: ' '));

    // Draw border
    for (int x = 0; x < buf.width(); x++) {
      buf.setCell(x, 0, Cell(content: '─'));
      buf.setCell(x, buf.height() - 1, Cell(content: '─'));
    }
    for (int y = 0; y < buf.height(); y++) {
      buf.setCell(0, y, Cell(content: '│'));
      buf.setCell(buf.width() - 1, y, Cell(content: '│'));
    }
    buf.setCell(0, 0, Cell(content: '┌'));
    buf.setCell(buf.width() - 1, 0, Cell(content: '┐'));
    buf.setCell(0, buf.height() - 1, Cell(content: '└'));
    buf.setCell(buf.width() - 1, buf.height() - 1, Cell(content: '┘'));

    // Draw info
    _write(buf, 2, 2, 'Last Event: $lastEvent');
    _write(buf, 2, 3, 'Size: ${buf.width()}x${buf.height()}');
    _write(
      buf,
      2,
      4,
      'Mouse Tracking: ${mouseEnabled ? "ON" : "OFF"} (Press "m" to toggle)',
    );
    _write(buf, 2, 6, 'Press "q" to quit');
    _write(buf, 2, 7, 'Press "c" to force clear/redraw');

    // Draw mouse cursor if enabled
    if (mouseEnabled && mouseX >= 0 && mouseY >= 0) {
      if (mouseX < buf.width() && mouseY < buf.height()) {
        buf.setCell(mouseX, mouseY, Cell(content: 'X'));
      }
    }

    terminal.draw();
  }

  try {
    draw();

    await for (final event in terminal.events) {
      lastEvent = event.toString();

      if (event is KeyEvent) {
        if (event.key().text == 'q' || event.matchString('ctrl+c')) {
          break;
        }
        if (event.key().text == 'm') {
          mouseEnabled = !mouseEnabled;
          if (mouseEnabled) {
            terminal.enableMouse();
          } else {
            terminal.disableMouse();
            mouseX = -1;
            mouseY = -1;
          }
        }
        if (event.key().text == 'c') {
          terminal.clearScreen();
          lastEvent = 'Screen Cleared';
        }
      } else if (event is MouseEvent) {
        mouseX = event.mouse().x;
        mouseY = event.mouse().y;
      } else if (event is WindowSizeEvent) {
        lastEvent = 'Resized to ${event.width}x${event.height}';
      }

      draw();
    }
  } finally {
    await terminal.stop();
    print('Demo finished.');
  }
}

void _write(dynamic buf, int x, int y, String text) {
  for (int i = 0; i < text.length && (x + i) < buf.width() - 1; i++) {
    buf.setCell(x + i, y, Cell(content: text[i]));
  }
}
