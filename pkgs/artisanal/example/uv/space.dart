import 'package:artisanal/uv.dart';
import 'dart:async';
import 'dart:math';

List<List<UvColor>> setupColors(int width, int height) {
  final doubleHeight = height * 2;
  final colors = List.generate(
    doubleHeight,
    (y) => List.generate(width, (x) {
      final randomnessFactor = (doubleHeight - y) / doubleHeight;
      final randomOffset = (Random().nextDouble() * 0.2) - 0.1;
      final value =
          (randomnessFactor * ((doubleHeight - y) / doubleHeight) +
                  randomOffset)
              .clamp(0.0, 1.0);
      final gray = (value * 255).toInt();
      return UvColor.rgb(gray, gray, gray);
    }),
  );
  return colors;
}

void main() async {
  final terminal = Terminal();

  await terminal.start();
  terminal.enterAltScreen();
  terminal.hideCursor();

  final size = await terminal.getSize();
  int width = size.width;
  int height = size.height;

  var colors = setupColors(width, height);
  var lastWidth = width;
  var lastHeight = height;

  void display() {
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final topColor = colors[y * 2][x];
        final bottomColor = colors[y * 2 + 1][x];
        terminal.setCell(
          x,
          y,
          Cell(
            content: '▄',
            style: UvStyle(fg: bottomColor, bg: topColor),
          ),
        );
      }
    }
    terminal.draw();
  }

  Timer? timer;
  void startTicker() {
    timer?.cancel();
    timer = Timer.periodic(const Duration(milliseconds: 50), (t) {
      // Shift colors to simulate movement
      final firstRow = colors.removeAt(0);
      colors.add(firstRow);
      display();
    });
  }

  startTicker();

  try {
    await for (final event in terminal.events) {
      if (event is WindowSizeEvent) {
        width = event.width;
        height = event.height;
        if (width != lastWidth || height != lastHeight) {
          colors = setupColors(width, height);
          lastWidth = width;
          lastHeight = height;
          terminal.resize(width, height);
          terminal.clearScreen();
        }
      } else if (event is KeyEvent) {
        if (event.matchString('q', 'ctrl+c')) {
          break;
        }
      }
    }
  } finally {
    timer?.cancel();
    await terminal.stop();
  }
}
