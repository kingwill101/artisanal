/// Support for half-block character graphics.
///
/// {@category Ultraviolet}
/// {@subCategory Graphics}
library;

import 'package:image/image.dart' as img;
import 'cell.dart';
import 'drawable.dart';
import 'geometry.dart';
import 'screen.dart';

/// A [Drawable] that renders an image using half-block characters.
///
/// This is a fallback for terminals that do not support any graphics protocol.
/// It uses the upper and lower half-block characters (▀, ▄) to simulate pixels,
/// effectively doubling the vertical resolution of the terminal.
final class HalfBlockImageDrawable implements Drawable {
  HalfBlockImageDrawable(this.image, {this.columns, this.rows});

  final img.Image image;
  final int? columns;
  final int? rows;

  @override
  Rectangle bounds() {
    return Rectangle(minX: 0, minY: 0, maxX: columns ?? 0, maxY: rows ?? 0);
  }

  @override
  void draw(Screen screen, Rectangle area) {
    final cols = columns ?? area.width;
    final rws = rows ?? area.height;

    if (cols <= 0 || rws <= 0) return;

    // Resize image to match the target columns and 2x rows (since each cell is 2 pixels high).
    final resized = img.copyResize(
      image,
      width: cols,
      height: rws * 2,
      interpolation: img.Interpolation.average,
    );

    for (var y = 0; y < rws; y++) {
      for (var x = 0; x < cols; x++) {
        final topPixel = resized.getPixel(x, y * 2);
        final bottomPixel = resized.getPixel(x, y * 2 + 1);

        final topColor = UvRgb(
          topPixel.r.toInt(),
          topPixel.g.toInt(),
          topPixel.b.toInt(),
        );
        final bottomColor = UvRgb(
          bottomPixel.r.toInt(),
          bottomPixel.g.toInt(),
          bottomPixel.b.toInt(),
        );

        final cell = Cell(
          content: '▀',
          style: UvStyle(fg: topColor, bg: bottomColor),
        );

        if (area.minX + x < area.maxX && area.minY + y < area.maxY) {
          screen.setCell(area.minX + x, area.minY + y, cell);
        }
      }
    }
  }
}
