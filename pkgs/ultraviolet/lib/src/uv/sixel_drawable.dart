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
import 'sixel.dart';

/// A [Drawable] that renders an image using Sixel Graphics.
///
/// Sixel is a legacy but widely supported bitmap graphics protocol for terminals.
/// This drawable encodes the [image] into Sixel format and renders it within
/// the specified [columns] and [rows].
///
/// The image is automatically resized to fit the target cell dimensions before
/// encoding, using the estimated cell pixel size to compute the appropriate
/// Sixel pixel dimensions. Color quantization is applied to reduce the palette
/// to at most [maxColors] entries.
final class SixelImageDrawable implements Drawable {
  /// Creates a Sixel protocol image drawable.
  ///
  /// The [image] is resized to fit [columns]×[rows] cells before Sixel
  /// encoding. Use [maxColors] to limit the palette, and [cellPixelWidth] /
  /// [cellPixelHeight] to match the terminal's cell pixel dimensions.
  SixelImageDrawable(
    this.image, {
    this.columns,
    this.rows,
    this.maxColors = SixelImage.maxPaletteSize,
    this.cellPixelWidth = 8,
    this.cellPixelHeight = 16,
    this.allowUpscale = true,
  });

  /// The raw RGBA image data.
  final img.Image image;

  /// Width of the drawable in terminal columns.
  final int? columns;

  /// Height of the drawable in terminal rows.
  final int? rows;

  /// Maximum number of colors in the Sixel palette (1–256).
  final int maxColors;

  /// Estimated pixel width of a single terminal cell.
  final int cellPixelWidth;

  /// Estimated pixel height of a single terminal cell.
  final int cellPixelHeight;

  /// Whether the drawable may enlarge the source raster beyond its native size.
  final bool allowUpscale;

  @override
  Rectangle bounds() {
    return Rectangle(minX: 0, minY: 0, maxX: columns ?? 0, maxY: rows ?? 0);
  }

  @override
  void draw(Screen screen, Rectangle area) {
    final cols = columns ?? area.width;
    final rws = rows ?? area.height;

    if (cols <= 0 || rws <= 0) return;

    final resized = _resizeForTarget(cols, rws);

    final sequence = SixelImage.encode(resized, maxColors: maxColors);

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

  img.Image _resizeForTarget(int cols, int rows) {
    // Each cell is cellPixelWidth x cellPixelHeight pixels, so the Sixel
    // output wants cols*cellPixelWidth by rows*cellPixelHeight pixels.
    final targetWidth = cols * cellPixelWidth;
    final rawHeight = rows * cellPixelHeight;
    final targetHeight = ((rawHeight + 5) ~/ 6) * 6;

    if (allowUpscale) {
      return img.copyResize(
        image,
        width: targetWidth,
        height: targetHeight,
        interpolation: img.Interpolation.average,
      );
    }

    final scale = [
      targetWidth / image.width,
      targetHeight / image.height,
      1.0,
    ].reduce((a, b) => a < b ? a : b);

    if (scale >= 1.0) return image;

    return img.copyResize(
      image,
      width: (image.width * scale).round().clamp(1, image.width),
      height: (image.height * scale).round().clamp(1, image.height),
      interpolation: img.Interpolation.average,
    );
  }
}
