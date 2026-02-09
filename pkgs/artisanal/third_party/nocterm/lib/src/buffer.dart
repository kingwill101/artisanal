import 'package:characters/characters.dart';
import 'package:nocterm/src/rectangle.dart';

import 'style.dart';
import 'utils/unicode_width.dart';

class Cell {
  String char;
  TextStyle style;

  /// Cached display width of the character.
  /// Computed lazily on first access to avoid expensive width calculations.
  int? _cachedWidth;

  /// Whether this cell is a placeholder for a sixel image.
  ///
  /// When true, the cell should not be rendered as text - instead, the
  /// corresponding sixel data will be written to the terminal at this position.
  bool isImagePlaceholder;

  Cell({
    this.char = ' ',
    TextStyle? style,
    this.isImagePlaceholder = false,
  }) : style = style ?? TextStyle();

  /// Returns the display width of this cell's character.
  /// The width is cached after the first computation for performance.
  int get width {
    _cachedWidth ??= UnicodeWidth.graphemeWidth(char);
    return _cachedWidth!;
  }

  Cell copyWith({String? char, TextStyle? style, bool? isImagePlaceholder}) {
    return Cell(
      char: char ?? this.char,
      style: style ?? this.style,
      isImagePlaceholder: isImagePlaceholder ?? this.isImagePlaceholder,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    return other is Cell &&
        other.char == char &&
        other.style == style &&
        other.isImagePlaceholder == isImagePlaceholder;
  }

  @override
  int get hashCode => Object.hash(char, style, isImagePlaceholder);
}

/// Represents a sixel image pending to be rendered.
///
/// Stores the position and encoded sixel data for an image that will
/// be written to the terminal during the flush phase.
class PendingImage {
  /// The X position in cells where the image starts.
  final int x;

  /// The Y position in cells where the image starts.
  final int y;

  /// The width of the image in cells.
  final int width;

  /// The height of the image in cells.
  final int height;

  /// The pre-encoded sixel escape sequence.
  final String sixelData;

  const PendingImage({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.sixelData,
  });
}

class Buffer {
  final int width;
  final int height;
  final List<List<Cell>> cells;

  /// List of sixel images to be rendered during the terminal flush phase.
  ///
  /// Images are added via [markImageRegion] and should be processed and
  /// cleared by the terminal renderer after each frame.
  final List<PendingImage> pendingImages = [];

  Buffer(this.width, this.height)
      : cells = List.generate(
          height,
          (_) => List.generate(width, (_) => Cell()),
        );

  Cell getCell(int x, int y) {
    if (x < 0 || x >= width || y < 0 || y >= height) {
      return Cell();
    }
    return cells[y][x];
  }

  void setCell(int x, int y, Cell cell) {
    if (x >= 0 && x < width && y >= 0 && y < height) {
      cells[y][x] = cell;
    }
  }

  void setString(int x, int y, String text, {TextStyle? style}) {
    int currentX = x;

    // Use grapheme clusters for proper Unicode handling (emojis, ZWJ sequences, etc.)
    for (final grapheme in text.characters) {
      if (currentX >= width) break;

      final charWidth = UnicodeWidth.graphemeWidth(grapheme);

      // Skip zero-width characters
      if (charWidth == 0) continue;

      // Check if we have enough space for wide characters
      if (charWidth == 2 && currentX + 1 >= width) break;

      if (y >= 0 && y < height && currentX >= 0) {
        cells[y][currentX] = Cell(char: grapheme, style: style);

        // For wide characters, mark the next cell as occupied
        if (charWidth == 2 && currentX + 1 < width) {
          cells[y][currentX + 1] =
              Cell(char: '\u200B', style: style); // Zero-width space marker
        }
      }

      currentX += charWidth;
    }
  }

  void clear() {
    for (var row in cells) {
      for (int i = 0; i < row.length; i++) {
        row[i] = Cell();
      }
    }
    pendingImages.clear();
  }

  void fillArea(Rect area, String char, {TextStyle? style}) {
    for (double y = area.top; y < area.bottom && y < height; y++) {
      for (double x = area.left; x < area.right && x < width; x++) {
        if (x >= 0 && y >= 0) {
          setCell(x.toInt(), y.toInt(), Cell(char: char, style: style));
        }
      }
    }
  }

  /// Marks a rectangular region as containing a sixel image.
  ///
  /// This method:
  /// 1. Marks all cells in the region as image placeholders (prevents text rendering)
  /// 2. Adds the sixel data to [pendingImages] for rendering during terminal flush
  ///
  /// [x], [y] - Top-left position of the image in cells.
  /// [imageWidth], [imageHeight] - Size of the image region in cells.
  /// [sixelData] - Pre-encoded sixel escape sequence to render.
  void markImageRegion(
    int x,
    int y,
    int imageWidth,
    int imageHeight,
    String sixelData,
  ) {
    // Bounds checking
    if (x < 0 || y < 0 || x >= width || y >= height) {
      return;
    }

    // Clamp dimensions to buffer bounds
    final clampedWidth = (x + imageWidth > width) ? width - x : imageWidth;
    final clampedHeight = (y + imageHeight > height) ? height - y : imageHeight;

    if (clampedWidth <= 0 || clampedHeight <= 0) {
      return;
    }

    // Mark cells as image placeholders
    for (int cy = y; cy < y + clampedHeight; cy++) {
      for (int cx = x; cx < x + clampedWidth; cx++) {
        cells[cy][cx] = Cell(
          char: ' ',
          isImagePlaceholder: true,
        );
      }
    }

    // Queue the sixel data for rendering
    pendingImages.add(PendingImage(
      x: x,
      y: y,
      width: clampedWidth,
      height: clampedHeight,
      sixelData: sixelData,
    ));
  }

  /// Clears all pending images without clearing the cell buffer.
  ///
  /// Called by the terminal renderer after images have been written.
  void clearPendingImages() {
    pendingImages.clear();
  }
}
