import 'package:ultraviolet/ultraviolet.dart';

Future<void> main() async {
  final terminal = Terminal();

  await terminal.start();
  terminal.enterAltScreen();
  terminal.hideCursor();

  final panel = rect(8, 4, 50, 12);

  void render() {
    terminal.buffer.fill(Cell(content: ' '));
    terminal.buffer.fillArea(
      Cell(
        content: ' ',
        style: const UvStyle(bg: UvColor.rgb(14, 24, 43)),
      ),
      panel,
    );

    roundedBorder()
        .style(const UvStyle(fg: UvColor.rgb(77, 154, 255)))
        .draw(terminal, panel);

    _writeText(
      terminal,
      panel.minX + 2,
      panel.minY + 1,
      'Ultraviolet',
      const UvStyle(fg: UvColor.rgb(214, 230, 255), attrs: Attr.bold),
    );

    _writeText(
      terminal,
      panel.minX + 2,
      panel.minY + 3,
      'Press q to exit',
      const UvStyle(fg: UvColor.rgb(156, 176, 208)),
    );

    terminal.draw();
  }

  try {
    render();

    await for (final event in terminal.events) {
      if (event is WindowSizeEvent) {
        terminal.resize(event.width, event.height);
        terminal.clearScreen();
      } else if (event is KeyEvent && event.matchString('q', 'ctrl+c')) {
        break;
      }

      render();
    }
  } finally {
    await terminal.stop();
  }
}

void _writeText(Screen screen, int x, int y, String text, UvStyle style) {
  final bounds = screen.bounds();
  for (var i = 0; i < text.length; i++) {
    final px = x + i;
    if (px < bounds.minX ||
        px >= bounds.maxX ||
        y < bounds.minY ||
        y >= bounds.maxY) {
      break;
    }
    screen.setCell(px, y, Cell(content: text[i], style: style));
  }
}
