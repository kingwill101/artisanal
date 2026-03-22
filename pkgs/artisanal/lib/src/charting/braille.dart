library;

import '../uv/cell.dart';
import '../uv/geometry.dart';
import '../uv/screen.dart';
import 'core.dart';

/// A 2x4 sub-cell braille canvas for plotting terminal-native 2D graphics.
///
/// Coordinates passed to [point] and [rect] are in braille-dot space,
/// not cell space. A canvas of `width=40, height=10` has a dot-space size of
/// `80 x 40`.
final class BrailleCanvas {
  BrailleCanvas(this.cellWidth, this.cellHeight)
    : _dots = List<List<UvStyle?>>.generate(
        cellHeight * 4,
        (_) => List<UvStyle?>.filled(cellWidth * 2, null),
      );

  final int cellWidth;
  final int cellHeight;
  final List<List<UvStyle?>> _dots;

  int get dotWidth => cellWidth * 2;
  int get dotHeight => cellHeight * 4;

  /// Plot a single braille dot.
  void point(int x, int y, {UvStyle style = const UvStyle()}) {
    if (x < 0 || y < 0 || x >= dotWidth || y >= dotHeight) return;
    _dots[y][x] = style;
  }

  /// Draw a rectangle outline in braille-dot space.
  void rect(int x0, int y0, int x1, int y1, {UvStyle style = const UvStyle()}) {
    for (var x = x0; x <= x1; x++) {
      point(x, y0, style: style);
      point(x, y1, style: style);
    }
    for (var y = y0; y <= y1; y++) {
      point(x0, y, style: style);
      point(x1, y, style: style);
    }
  }

  /// Render this braille canvas into [screen] within [area].
  void renderTo(
    Screen screen,
    Rectangle area, {
    UvStyle fallbackStyle = const UvStyle(),
  }) {
    final bh = _dots.length;
    final bw = bh == 0 ? 0 : _dots[0].length;

    for (var cy = 0; cy < cellHeight && area.minY + cy < area.maxY; cy++) {
      for (var cx = 0; cx < cellWidth && area.minX + cx < area.maxX; cx++) {
        var codePoint = 0;
        UvStyle? style;
        final bx = cx * 2;
        final by = cy * 4;

        void sample(int dx, int dy, int bit) {
          final x = bx + dx;
          final y = by + dy;
          if (y >= 0 && y < bh && x >= 0 && x < bw) {
            final dotStyle = _dots[y][x];
            if (dotStyle != null) {
              codePoint |= bit;
              style ??= dotStyle;
            }
          }
        }

        sample(0, 0, 0x01);
        sample(0, 1, 0x02);
        sample(0, 2, 0x04);
        sample(0, 3, 0x40);
        sample(1, 0, 0x08);
        sample(1, 1, 0x10);
        sample(1, 2, 0x20);
        sample(1, 3, 0x80);

        if (codePoint != 0) {
          putCell(
            screen,
            area.minX + cx,
            area.minY + cy,
            String.fromCharCode(0x2800 + codePoint),
            style ?? fallbackStyle,
          );
        }
      }
    }
  }
}
