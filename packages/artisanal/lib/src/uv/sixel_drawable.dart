/// Support for Sixel Graphics.
///
/// {@category Ultraviolet}
/// {@subCategory Graphics}
library;

import 'package:image/image.dart' as img;
import 'cell.dart';
import 'drawable.dart';
import 'geometry.dart';
import 'screen.dart';
import '../terminal/sixel.dart';

/// A [Drawable] that renders an image using Sixel Graphics.
///
/// Sixel is a legacy but widely supported bitmap graphics protocol for terminals.
/// This drawable encodes the [image] into Sixel format and renders it within
/// the specified [columns] and [rows].
final class SixelImageDrawable implements Drawable {
  SixelImageDrawable(this.image, {this.columns, this.rows});

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

    // Sixel doesn't support scaling natively in the sequence as easily as Kitty/iTerm2
    // without complex math, so we assume the image is already sized or we just
    // emit it.
    final sequence = SixelImage.encode(image);

    for (var y = area.minY; y < area.minY + rws && y < area.maxY; y++) {
      for (var x = area.minX; x < area.minX + cols && x < area.maxX; x++) {
        if (x == area.minX && y == area.minY) {
          screen.setCell(x, y, Cell(content: sequence, width: 1));
        } else {
          screen.setCell(x, y, Cell(content: '', width: 0));
        }
      }
    }
  }
}
