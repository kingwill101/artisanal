/// Support for the Kitty Graphics Protocol.
///
/// {@category Ultraviolet}
/// {@subCategory Graphics}
library;

import 'package:image/image.dart' as img;
import 'cell.dart';
import 'drawable.dart';
import 'geometry.dart';
import 'screen.dart';
import '../terminal/kitty.dart';

/// A [Drawable] that renders an image using the Kitty Graphics Protocol.
///
/// This drawable uses the advanced Kitty graphics protocol to display
/// high-resolution images. It supports unique image [id]s for caching and
/// can be scaled to fit specific [columns] and [rows].
final class KittyImageDrawable implements Drawable {
  KittyImageDrawable(this.image, {this.id, this.columns, this.rows});

  final img.Image image;
  final int? id;
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

    final sequence = KittyImage.encode(image, id: id, columns: cols, rows: rws);

    // We place the sequence in the top-left cell of the area.
    // We also mark the other cells in the area as "occupied" by setting them
    // to empty cells with width 0, so the renderer doesn't overwrite them.
    // Note: This is a simplified approach.
    for (var y = area.minY; y < area.minY + rws && y < area.maxY; y++) {
      for (var x = area.minX; x < area.minX + cols && x < area.maxX; x++) {
        if (x == area.minX && y == area.minY) {
          screen.setCell(x, y, Cell(content: sequence, width: 1));
        } else {
          // Mark as occupied. Width 0 means it doesn't advance the cursor.
          screen.setCell(x, y, Cell(content: '', width: 0));
        }
      }
    }
  }
}
