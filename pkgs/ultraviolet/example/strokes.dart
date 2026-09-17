import 'package:ultraviolet/ultraviolet.dart';

/// Use-case example for ultraviolet stroke and buffer composition features.
///
/// Demonstrates:
/// - `drawHorizontal`, `drawVertical`, `drawStroke` for generic glyph strokes
/// - `Buffer.draw` with `clip: true` for out-of-bounds-safe composition
/// - `Buffer.draw` with `skipEmpty: true` for non-wiping fragments
/// - `Buffer.render` / `Canvas.render` with `trimTrailing: false`
void main() async {
  final terminal = Terminal();
  await terminal.start();
  terminal.enterAltScreen();
  terminal.hideCursor();

  try {
    await for (final event in terminal.events) {
      if (event is WindowSizeEvent) {
        terminal.resize(event.width, event.height);
      }
      if (event is KeyEvent && event.matchString('q', 'ctrl+c')) break;

      _render(terminal);
      terminal.draw();
    }
  } finally {
    terminal.showCursor();
    terminal.exitAltScreen();
    await terminal.stop();
  }
}

void _render(Terminal terminal) {
  final buf = terminal.buffer;
  buf.fill(Cell(content: ' '));

  // --- Title ---
  _write(
    terminal,
    2,
    0,
    'Stroke & Buffer Composition Demo (q to exit)',
    const UvStyle(fg: UvColor.rgb(214, 230, 255), attrs: Attr.bold),
  );

  // --- 1. Stroke primitives: box border ---
  _write(
    terminal,
    2,
    2,
    '1. Stroke primitives (drawHorizontal / drawVertical / drawStroke)',
    const UvStyle(fg: UvColor.rgb(77, 154, 255)),
  );

  final boxX = 2;
  final boxY = 4;
  final boxW = 40;
  final boxH = 8;

  // Top and bottom edges with drawHorizontal
  drawHorizontal(
    terminal,
    boxX,
    boxY,
    boxW,
    glyph: '─',
    style: const UvStyle(fg: UvColor.rgb(77, 154, 255)),
  );
  drawHorizontal(
    terminal,
    boxX,
    boxY + boxH,
    boxW,
    glyph: '─',
    style: const UvStyle(fg: UvColor.rgb(77, 154, 255)),
  );

  // Left and right edges with drawVertical
  drawVertical(
    terminal,
    boxX,
    boxY,
    boxH,
    glyph: '│',
    style: const UvStyle(fg: UvColor.rgb(77, 154, 255)),
  );
  drawVertical(
    terminal,
    boxX + boxW,
    boxY,
    boxH,
    glyph: '│',
    style: const UvStyle(fg: UvColor.rgb(77, 154, 255)),
  );

  // Diagonal cross with drawStroke
  drawStroke(
    terminal,
    boxX,
    boxY,
    boxX + boxW,
    boxY + boxH,
    glyph: '\\',
    style: const UvStyle(fg: UvColor.rgb(128, 222, 234)),
  );
  drawStroke(
    terminal,
    boxX + boxW,
    boxY,
    boxX,
    boxY + boxH,
    glyph: '/',
    style: const UvStyle(fg: UvColor.rgb(128, 222, 234)),
  );

  // --- 2. Clipped draw ---
  _write(
    terminal,
    boxX + boxW + 4,
    4,
    '2. Clipped draw (clip: true)',
    const UvStyle(fg: UvColor.rgb(77, 154, 255)),
  );

  final clipSrc = Buffer.create(5, 2);
  clipSrc.setCell(0, 0, Cell(content: 'A', width: 1));
  clipSrc.setCell(1, 0, Cell(content: 'B', width: 1));
  clipSrc.setCell(2, 0, Cell(content: 'C', width: 1));
  clipSrc.setCell(3, 0, Cell(content: 'D', width: 1));
  clipSrc.setCell(4, 0, Cell(content: 'E', width: 1));
  clipSrc.setCell(0, 1, Cell(content: 'F', width: 1));
  clipSrc.setCell(1, 1, Cell(content: 'G', width: 1));
  clipSrc.setCell(2, 1, Cell(content: 'H', width: 1));
  clipSrc.setCell(3, 1, Cell(content: 'I', width: 1));
  clipSrc.setCell(4, 1, Cell(content: 'J', width: 1));

  // Draw partially out-of-bounds — clipped draw writes only the overlap
  clipSrc.draw(terminal, rect(boxX + boxW + 4, 6, 7, 3), clip: true);

  // --- 3. Skip-empty draw ---
  _write(
    terminal,
    boxX + boxW + 4,
    10,
    '3. Skip-empty draw (skipEmpty: true)',
    const UvStyle(fg: UvColor.rgb(77, 154, 255)),
  );

  final frag = Buffer.create(3, 1);
  frag.setCell(1, 0, Cell(content: 'X', width: 1));

  final fragDest = Canvas(8, 1);
  fragDest.setCell(0, 0, Cell(content: 'O', width: 1));
  fragDest.setCell(2, 0, Cell(content: 'Y', width: 1));
  fragDest.setCell(4, 0, Cell(content: 'Z', width: 1));

  // skipEmpty: true — existing glyphs at cells 0, 2, 4 are preserved
  frag.draw(fragDest, rect(0, 0, 3, 1), skipEmpty: true);

  // Render with trimTrailing: false to show preserved spaces
  final fragResult = fragDest.render(trimTrailing: false);
  _write(
    terminal,
    boxX + boxW + 4,
    12,
    fragResult,
    const UvStyle(fg: UvColor.rgb(255, 255, 255)),
  );

  // --- 4. Untrimmed render ---
  _write(
    terminal,
    2,
    boxH + 6,
    '4. Untrimmed render (trimTrailing: false)',
    const UvStyle(fg: UvColor.rgb(77, 154, 255)),
  );

  final trimBuf = Buffer.create(5, 1);
  trimBuf.setCell(0, 0, Cell(content: 'Hi', width: 2));
  final trimResult = trimBuf.render(trimTrailing: false);
  _write(
    terminal,
    2,
    boxH + 8,
    'trimTrailing: true → "${trimBuf.render()}"',
    const UvStyle(fg: UvColor.rgb(200, 200, 200)),
  );
  _write(
    terminal,
    2,
    boxH + 9,
    'trimTrailing: false → "$trimResult"',
    const UvStyle(fg: UvColor.rgb(200, 200, 200)),
  );
}

void _write(Terminal terminal, int x, int y, String text, UvStyle style) {
  final bounds = terminal.bounds();
  for (var i = 0; i < text.length; i++) {
    final px = x + i;
    if (px < bounds.minX ||
        px >= bounds.maxX ||
        y < bounds.minY ||
        y >= bounds.maxY) {
      break;
    }
    terminal.setCell(px, y, Cell(content: text[i], style: style));
  }
}
