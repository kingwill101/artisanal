import 'package:artisanal/uv.dart';
import 'dart:async';

class Layout {
  Layout({required this.main, required this.footer, required this.sidebar});
  final Rectangle main;
  final Rectangle footer;
  final Rectangle sidebar;
}

Layout makeLayout(Rectangle r) {
  final h = splitHorizontal(r, const Percent(80));
  final v = splitVertical(h.left, Fixed(h.left.height - 7));
  return Layout(main: v.top, footer: v.bottom, sidebar: h.right);
}

void main() async {
  final terminal = Terminal();

  await terminal.start();
  terminal.enterAltScreen();
  terminal.hideCursor();

  var area = terminal.bounds();

  final blue = Cell(
    content: ' ',
    style: const UvStyle(bg: UvColor.basic16(4)),
  ); // Blue
  final red = Cell(
    content: ' ',
    style: const UvStyle(bg: UvColor.basic16(1)),
  ); // Red
  final green = Cell(
    content: ' ',
    style: const UvStyle(bg: UvColor.basic16(2)),
  ); // Green

  void display() {
    final l = makeLayout(area);
    terminal.fillArea(blue, l.main);
    terminal.fillArea(red, l.footer);
    terminal.fillArea(green, l.sidebar);
    terminal.draw();
  }

  Timer? timer;
  timer = Timer.periodic(const Duration(milliseconds: 16), (t) {
    display();
  });

  try {
    await for (final event in terminal.events) {
      if (event is WindowSizeEvent) {
        area = event.bounds();
        terminal.resize(event.width, event.height);
        terminal.clearScreen();
      } else if (event is KeyEvent) {
        if (event.matchString('ctrl+c', 'q')) {
          break;
        }
      }
    }
  } finally {
    timer.cancel();
    await terminal.stop();
  }
}
