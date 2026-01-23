import 'package:artisanal/uv.dart';

// #region uv_basic_usage
void main() async {
  final terminal = Terminal();

  await terminal.start();
  terminal.enterAltScreen();
  terminal.hideCursor();

  final fixed = rect(10, 10, 40, 20);

  void display() {
    // Fill area with red spaces (as in Go example)
    // Note: We need to make sure terminal.buffer can be used where Screen is expected,
    // or use terminal.buffer.fillArea if available.
    terminal.buffer.fillArea(
      Cell(
        content: ' ',
        style: const UvStyle(fg: UvColor.rgb(255, 0, 0)),
      ), // Red
      fixed,
    );

    final ss = StyledString('Hello, World!');
    final carea = rect(
      (fixed.maxX / 2).toInt() - 6,
      (fixed.maxY / 2).toInt() - 1,
      12,
      1,
    );

    ss.draw(terminal, carea);

    terminal.draw();
  }

  try {
    display();

    await for (final event in terminal.events) {
      if (event is WindowSizeEvent) {
        terminal.resize(event.width, event.height);
        terminal.clearScreen();
        display();
      } else if (event is KeyEvent) {
        if (event.matchString('q', 'ctrl+c')) {
          break;
        }
      }
      display();
    }
  } finally {
    await terminal.stop();
  }
}

// #endregion
