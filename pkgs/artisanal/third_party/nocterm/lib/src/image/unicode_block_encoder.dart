import 'dart:typed_data';
import '../style.dart';

/// Encodes images using Unicode half-block characters for universal terminal support.
///
/// Uses ▀ (upper half block, U+2580) and ▄ (lower half block, U+2584) with
/// 24-bit foreground/background colors to display 2 vertical pixels per cell.
///
/// This works in ANY terminal with Unicode and 24-bit color support, including
/// macOS Terminal.app, Warp, and others that don't support Sixel/iTerm2/Kitty.
class UnicodeBlockEncoder {
  /// Upper half block character - fills top half of cell
  static const String upperHalf = '▀'; // U+2580

  /// Lower half block character - fills bottom half of cell
  static const String lowerHalf = '▄'; // U+2584

  /// Full block character - fills entire cell
  static const String fullBlock = '█'; // U+2588

  /// Space character - shows only background color
  static const String space = ' ';

  /// Default color to use for transparent pixels.
  /// If null, uses the terminal's default background.
  final Color? transparentColor;

  /// Alpha threshold below which a pixel is considered transparent.
  /// Default is 128 (50% opacity).
  final int alphaThreshold;

  /// Creates a new UnicodeBlockEncoder.
  ///
  /// [transparentColor] - Color to use for transparent pixels. If null, uses
  /// the terminal's default background color.
  /// [alphaThreshold] - Alpha value below which pixels are treated as transparent.
  /// Default is 128.
  const UnicodeBlockEncoder({
    this.transparentColor,
    this.alphaThreshold = 128,
  });

  /// Encode an RGBA image to a list of rows, where each row contains
  /// cells with character + foreground + background colors.
  ///
  /// Returns a 2D list: result[row][col] = BlockCell(char, fgColor, bgColor)
  ///
  /// Each output row represents 2 pixel rows from the source image.
  /// - Top pixel color becomes foreground (for ▀)
  /// - Bottom pixel color becomes background (for ▀)
  ///
  /// [pixels] - RGBA pixel data (4 bytes per pixel, row-major)
  /// [width] - Image width in pixels
  /// [height] - Image height in pixels
  ///
  /// Output dimensions: width = image width, height = ceil(image height / 2)
  List<List<BlockCell>> encode({
    required Uint8List pixels,
    required int width,
    required int height,
  }) {
    if (width <= 0 || height <= 0) {
      return [];
    }

    // Output height is ceil(height / 2)
    final outputHeight = (height + 1) ~/ 2;
    final result = <List<BlockCell>>[];

    for (int row = 0; row < outputHeight; row++) {
      final rowCells = <BlockCell>[];
      final topPixelY = row * 2;
      final bottomPixelY = topPixelY + 1;

      for (int x = 0; x < width; x++) {
        // Get top pixel color
        final topColor = _getPixelColor(pixels, width, height, x, topPixelY);

        // Get bottom pixel color (or use top if we're at the bottom edge)
        final bottomColor = bottomPixelY < height
            ? _getPixelColor(pixels, width, height, x, bottomPixelY)
            : topColor;

        // Determine which character and colors to use
        final cell = _createCell(topColor, bottomColor);
        rowCells.add(cell);
      }

      result.add(rowCells);
    }

    return result;
  }

  /// Convenience method that returns ANSI escape sequences for each row.
  /// Can be written directly to terminal.
  ///
  /// Each string in the returned list represents one row of output.
  /// Rows are terminated with a reset sequence but NOT with newlines.
  List<String> encodeToAnsi({
    required Uint8List pixels,
    required int width,
    required int height,
  }) {
    final cells = encode(pixels: pixels, width: width, height: height);
    return cells.map(_rowToAnsi).toList();
  }

  /// Get the color of a pixel at (x, y) from RGBA pixel data.
  Color _getPixelColor(Uint8List pixels, int width, int height, int x, int y) {
    if (x < 0 || x >= width || y < 0 || y >= height) {
      return transparentColor ?? Color.defaultColor;
    }

    final offset = (y * width + x) * 4;
    final r = pixels[offset];
    final g = pixels[offset + 1];
    final b = pixels[offset + 2];
    final a = pixels[offset + 3];

    // Handle transparency
    if (a < alphaThreshold) {
      return transparentColor ?? Color.defaultColor;
    }

    return Color.fromARGB(a, r, g, b);
  }

  /// Create a BlockCell from top and bottom pixel colors.
  BlockCell _createCell(Color topColor, Color bottomColor) {
    final topIsDefault = topColor.isDefault;
    final bottomIsDefault = bottomColor.isDefault;

    // Both transparent: use space with default background
    if (topIsDefault && bottomIsDefault) {
      return BlockCell(
        char: space,
        foreground: Color.defaultColor,
        background: Color.defaultColor,
      );
    }

    // Colors are the same: use space with that background
    if (_colorsEqual(topColor, bottomColor)) {
      return BlockCell(
        char: space,
        foreground: topColor, // doesn't matter for space
        background: topColor,
      );
    }

    // Top is transparent: use lower half block
    // ▄ fills the bottom half, so foreground = bottom color, background = transparent
    if (topIsDefault) {
      return BlockCell(
        char: lowerHalf,
        foreground: bottomColor,
        background: Color.defaultColor,
      );
    }

    // Bottom is transparent: use upper half block
    // ▀ fills the top half, so foreground = top color, background = transparent
    if (bottomIsDefault) {
      return BlockCell(
        char: upperHalf,
        foreground: topColor,
        background: Color.defaultColor,
      );
    }

    // Different non-transparent colors: use upper half block
    // ▀ fills top half with foreground, bottom half shows background
    return BlockCell(
      char: upperHalf,
      foreground: topColor,
      background: bottomColor,
    );
  }

  /// Check if two colors are equal (ignoring alpha for non-default colors).
  bool _colorsEqual(Color a, Color b) {
    if (a.isDefault && b.isDefault) return true;
    if (a.isDefault || b.isDefault) return false;
    return a.red == b.red && a.green == b.green && a.blue == b.blue;
  }

  /// Convert a row of cells to an ANSI string.
  String _rowToAnsi(List<BlockCell> row) {
    if (row.isEmpty) return '';

    final buffer = StringBuffer();
    Color? lastFg;
    Color? lastBg;

    for (final cell in row) {
      // Only emit foreground color if it changed and we're not using space
      // (space only shows background, so foreground doesn't matter)
      if (cell.char != space && cell.foreground != lastFg) {
        buffer.write(cell.foreground.toAnsi(background: false));
        lastFg = cell.foreground;
      }

      // Only emit background color if it changed
      if (cell.background != lastBg) {
        buffer.write(cell.background.toAnsi(background: true));
        lastBg = cell.background;
      }

      buffer.write(cell.char);
    }

    // Reset at end of row
    buffer.write('\x1b[0m');

    return buffer.toString();
  }

  /// Encode a single-color test pattern for debugging.
  /// Creates a solid rectangle of the given color.
  static List<String> encodeSolidColor({
    required Color color,
    required int width,
    required int height,
  }) {
    // Create solid RGBA pixels
    final pixels = Uint8List(width * height * 4);
    for (int i = 0; i < width * height; i++) {
      pixels[i * 4] = color.red;
      pixels[i * 4 + 1] = color.green;
      pixels[i * 4 + 2] = color.blue;
      pixels[i * 4 + 3] = color.alpha;
    }

    const encoder = UnicodeBlockEncoder();
    return encoder.encodeToAnsi(pixels: pixels, width: width, height: height);
  }

  /// Encode a vertical gradient for testing.
  /// Creates a gradient from topColor to bottomColor.
  static List<String> encodeVerticalGradient({
    required Color topColor,
    required Color bottomColor,
    required int width,
    required int height,
  }) {
    final pixels = Uint8List(width * height * 4);

    for (int y = 0; y < height; y++) {
      final t = height > 1 ? y / (height - 1) : 0.0;
      final r = (topColor.red + (bottomColor.red - topColor.red) * t).round();
      final g =
          (topColor.green + (bottomColor.green - topColor.green) * t).round();
      final b =
          (topColor.blue + (bottomColor.blue - topColor.blue) * t).round();

      for (int x = 0; x < width; x++) {
        final offset = (y * width + x) * 4;
        pixels[offset] = r;
        pixels[offset + 1] = g;
        pixels[offset + 2] = b;
        pixels[offset + 3] = 255;
      }
    }

    const encoder = UnicodeBlockEncoder();
    return encoder.encodeToAnsi(pixels: pixels, width: width, height: height);
  }
}

/// A single cell in the unicode block output.
class BlockCell {
  /// The character to display ('▀', '▄', ' ', or '█')
  final String char;

  /// The foreground color (used for the half-block portion)
  final Color foreground;

  /// The background color (used for the other half or for spaces)
  final Color background;

  /// Creates a new BlockCell.
  const BlockCell({
    required this.char,
    required this.foreground,
    required this.background,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BlockCell &&
        other.char == char &&
        other.foreground == foreground &&
        other.background == background;
  }

  @override
  int get hashCode => Object.hash(char, foreground, background);

  @override
  String toString() =>
      'BlockCell(char: "$char", fg: $foreground, bg: $background)';
}
