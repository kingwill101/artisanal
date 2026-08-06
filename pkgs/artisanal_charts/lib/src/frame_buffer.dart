/// Frame-buffer abstraction matching OpenTUI's chart drawing surface.
library;

import 'package:ultraviolet/ultraviolet.dart';

/// Minimal drawing surface used by chart renderers.
abstract interface class ChartFrameBuffer {
  /// Sets a single cell character with foreground and background styles.
  void setCell(int x, int y, String char, UvStyle fg, UvStyle bg);

  /// Paints a solid cell using [fill] as the background (space glyph).
  ///
  /// Prefer this for heatmaps and solid bars so color ramps are visible.
  void setSolid(int x, int y, UvStyle fill);

  /// Draws [text] starting at ([x], [y]).
  void drawText(String text, int x, int y, UvStyle fg, [UvStyle? bg]);

  /// Fills a rectangle with [color] as background (space cells).
  void fillRect(int x, int y, int width, int height, UvStyle color);
}

/// [ChartFrameBuffer] backed by an Ultraviolet [Canvas].
final class CanvasFrameBuffer implements ChartFrameBuffer {
  CanvasFrameBuffer(this.canvas);

  final Canvas canvas;

  int get width => canvas.width();
  int get height => canvas.height();

  UvColor? _asColor(UvStyle s) => s.fg ?? s.bg;

  @override
  void setCell(int x, int y, String char, UvStyle fg, UvStyle bg) {
    if (x < 0 || y < 0 || x >= width || y >= height) return;
    final style = UvStyle(
      fg: _asColor(fg),
      bg: _asColor(bg),
    );
    canvas.setCell(x, y, Cell(content: char, style: style));
  }

  @override
  void setSolid(int x, int y, UvStyle fill) {
    if (x < 0 || y < 0 || x >= width || y >= height) return;
    final c = _asColor(fill);
    canvas.setCell(
      x,
      y,
      Cell(content: ' ', style: UvStyle(fg: c, bg: c)),
    );
  }

  @override
  void drawText(String text, int x, int y, UvStyle fg, [UvStyle? bg]) {
    if (y < 0 || y >= height) return;
    var cx = x;
    for (final rune in text.runes) {
      if (cx >= width) break;
      if (cx >= 0) {
        setCell(cx, y, String.fromCharCode(rune), fg, bg ?? const UvStyle());
      }
      cx++;
    }
  }

  @override
  void fillRect(int x, int y, int w, int h, UvStyle color) {
    final c = _asColor(color);
    final fill = UvStyle(bg: c, fg: c);
    final maxX = (x + w).clamp(0, width);
    final maxY = (y + h).clamp(0, height);
    final startX = x.clamp(0, width);
    final startY = y.clamp(0, height);
    for (var py = startY; py < maxY; py++) {
      for (var px = startX; px < maxX; px++) {
        canvas.setCell(px, py, Cell(content: ' ', style: fill));
      }
    }
  }
}
