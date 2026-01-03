/// Support for the iTerm2 Image Protocol.
///
/// {@category Ultraviolet}
/// {@subCategory Graphics}
library;

import 'package:image/image.dart' as img;
import 'cell.dart';
import 'drawable.dart';
import 'geometry.dart';
import 'screen.dart';
import '../terminal/iterm2.dart';

/// A [Drawable] that renders an image using the iTerm2 Image Protocol.
///
/// This drawable uses the iTerm2 inline image protocol to display high-resolution
/// images in compatible terminals. It supports scaling to a specific number of
/// [columns] and [rows].
final class ITerm2ImageDrawable implements Drawable {
  ITerm2ImageDrawable(this.image, {this.name, this.columns, this.rows});

  final img.Image image;
  final String? name;
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

    final sequence = ITerm2Image.encode(
      image,
      name: name,
      columns: cols,
      rows: rws,
    );

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
