import 'package:artisanal/uv.dart';

final gray = UvColor.rgb(104, 104, 104);
final white = UvColor.rgb(180, 180, 180);
final yellow = UvColor.rgb(180, 180, 16);
final cyan = UvColor.rgb(16, 180, 180);
final green = UvColor.rgb(16, 180, 16);
final magenta = UvColor.rgb(180, 16, 180);
final red = UvColor.rgb(180, 16, 16);
final blue = UvColor.rgb(16, 16, 180);
final black = UvColor.rgb(16, 16, 16);
final fullWhite = UvColor.rgb(235, 235, 235);
final fullBlack = UvColor.rgb(0, 0, 0);
final lightBlack = UvColor.rgb(26, 26, 26);
final purple = UvColor.rgb(72, 16, 116);
final brown = UvColor.rgb(106, 52, 16);
final navy = UvColor.rgb(16, 70, 106);

void main() async {
  final terminal = Terminal();

  await terminal.start();
  terminal.enterAltScreen();
  terminal.hideCursor();

  final size = await terminal.getSize();
  int width = size.width;
  int height = size.height;

  final rowColors = [
    [white, yellow, cyan, green, magenta, red, blue],
    [blue, black, magenta, black, cyan, black, white],
    [navy, fullWhite, purple, black, black, black],
  ];

  void display() {
    terminal.clear();
    final topRowHeight = (height * 66) ~/ 100;
    final midRowHeight = (height * 8) ~/ 100;
    final botRowHeight = height - topRowHeight - midRowHeight;

    final barWidth = width ~/ 7;

    // Top Row
    for (var j = 0; j < 7; j++) {
      final bar = rect(
        j * barWidth,
        0,
        (j == 6) ? width - j * barWidth : barWidth,
        topRowHeight,
      );
      terminal.fillArea(
        Cell(
          content: ' ',
          style: UvStyle(bg: rowColors[0][j]),
        ),
        bar,
      );
    }

    // Mid Row
    for (var j = 0; j < 7; j++) {
      final bar = rect(
        j * barWidth,
        topRowHeight,
        (j == 6) ? width - j * barWidth : barWidth,
        midRowHeight,
      );
      terminal.fillArea(
        Cell(
          content: ' ',
          style: UvStyle(bg: rowColors[1][j]),
        ),
        bar,
      );
    }

    // Bot Row
    final botBarWidth = width ~/ 6;
    for (var j = 0; j < 6; j++) {
      final bar = rect(
        j * botBarWidth,
        topRowHeight + midRowHeight,
        (j == 5) ? width - j * botBarWidth : botBarWidth,
        botRowHeight,
      );
      terminal.fillArea(
        Cell(
          content: ' ',
          style: UvStyle(bg: rowColors[2][j]),
        ),
        bar,
      );
    }

    terminal.draw();
  }

  try {
    display();

    await for (final event in terminal.events) {
      if (event is WindowSizeEvent) {
        width = event.width;
        height = event.height;
        terminal.resize(width, height);
        terminal.clearScreen();
        display();
      } else if (event is KeyEvent) {
        if (event.matchString('q', 'ctrl+c')) {
          break;
        }
      }
    }
  } finally {
    await terminal.stop();
  }
}
