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
import 'kitty.dart';

/// A [Drawable] that renders an image using the Kitty Graphics Protocol.
///
/// This drawable uses the advanced Kitty graphics protocol to display
/// high-resolution images. The image is transmitted as PNG for efficient
/// bandwidth usage (dramatically smaller than raw RGBA).
///
/// It supports unique image [id]s for caching and cleanup — if no [id] is
/// provided, one is auto-assigned via [KittyImage.getNextImageId]. The image
/// can be scaled to fit specific [columns] and [rows] using the protocol's
/// native cell-based sizing.
///
/// Quiet mode is enabled by default to suppress terminal response sequences
/// that would otherwise pollute the input stream.
final class KittyImageDrawable implements Drawable {
  /// Creates a Kitty protocol image drawable.
  ///
  /// The [image] is transmitted as PNG data. An optional [id] can be specified
  /// for caching; if omitted, one is auto-assigned. Use [columns] and [rows]
  /// to control cell-based sizing.
  KittyImageDrawable(
    this.image, {
    int? id,
    this.columns,
    this.rows,
    this.quiet = 2,
    this.clearBeforeDraw = false,
  }) : id = id ?? KittyImage.getNextImageId();

  /// The raw PNG-encoded image data.
  final img.Image image;

  /// Unique image identifier used for caching and later deletion.
  ///
  /// Auto-assigned if not provided at construction time.
  final int id;

  /// Width of the drawable in terminal columns.
  final int? columns;

  /// Height of the drawable in terminal rows.
  final int? rows;

  /// Quiet mode level for suppressing terminal responses.
  ///
  /// - 0: no suppression
  /// - 1: suppress OK responses
  /// - 2: suppress all responses (default)
  final int quiet;

  /// Whether drawing should first delete existing placements for [id].
  ///
  /// This is useful for retained-mode renderers that repaint a stable image ID:
  /// it prevents stale Kitty placements from surviving after a resize or move.
  final bool clearBeforeDraw;

  @override
  Rectangle bounds() {
    return Rectangle(minX: 0, minY: 0, maxX: columns ?? 0, maxY: rows ?? 0);
  }

  @override
  void draw(Screen screen, Rectangle area) {
    final cols = columns ?? area.width;
    final rws = rows ?? area.height;

    if (cols <= 0 || rws <= 0) return;

    final imageSequence = KittyImage.encode(
      image,
      id: id,
      columns: cols,
      rows: rws,
      quiet: quiet,
      suppressCursorMovement: true,
    );
    final sequence = clearBeforeDraw
        ? '${deleteSequence()}$imageSequence'
        : imageSequence;

    // Place the escape sequence in the top-left cell and give that cell the
    // same width Kitty will advance the real cursor by. `Line.set` marks the
    // rest of that row as zero-width placeholders; writing those placeholders
    // manually would clear the wide origin cell again.
    screen.setCell(area.minX, area.minY, Cell(content: sequence, width: cols));

    // Reserve the remaining image rows without emitting text cells. Real
    // spaces would be drawn after the Kitty placement and can cover the image
    // with the terminal background in Ghostty/Kitty-compatible renderers.
    for (var y = area.minY + 1; y < area.minY + rws && y < area.maxY; y++) {
      for (var x = area.minX; x < area.minX + cols && x < area.maxX; x++) {
        screen.setCell(x, y, Cell.zeroCell());
      }
    }
  }

  /// Returns an escape sequence that deletes this image from the terminal.
  ///
  /// Call this when the drawable is no longer needed to free terminal resources.
  String deleteSequence() => KittyImage.delete(imageId: id, quiet: quiet);
}
