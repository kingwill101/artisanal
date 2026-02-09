import 'package:image/image.dart' as img;

/// Utilities for Sixel Graphics.
///
/// Sixel is a bitmap graphics format for terminals that encodes images
/// in 6-pixel high horizontal strips. Each column of 6 vertical pixels
/// is represented as a single ASCII character (value 63–126, where bits
/// 0–5 map to top-to-bottom pixels).
///
/// The format uses:
/// - Color definitions: `#<index>;2;<r>;<g>;<b>` (r, g, b are 0–100)
/// - Sixel data: ASCII characters 63–126 where bits 0–5 represent pixels
/// - RLE compression: `!<count><char>` for repeated characters
/// - Navigation: `$` returns to start of strip, `-` moves to next strip
///
/// See: https://en.wikipedia.org/wiki/Sixel
class SixelImage {
  /// Maximum number of colors allowed in a Sixel palette.
  static const int maxPaletteSize = 256;

  /// Encodes an image into Sixel escape sequences.
  ///
  /// The image is first quantized to at most [maxColors] colors using the
  /// `image` package's built-in quantizer, producing a high-quality palette
  /// via octree quantization. This avoids the naive first-come-first-served
  /// palette allocation that silently degrades color accuracy when an image
  /// has more than 256 unique colors.
  ///
  /// [image] is the image to encode.
  /// [maxColors] is the maximum palette size (1–256, default 256).
  ///
  /// Returns a string containing the complete Sixel escape sequence.
  static String encode(img.Image image, {int maxColors = maxPaletteSize}) {
    if (maxColors < 1 || maxColors > maxPaletteSize) {
      throw ArgumentError('maxColors must be between 1 and $maxPaletteSize');
    }

    final width = image.width;
    final height = image.height;
    if (width <= 0 || height <= 0) return '';

    // Quantize the image to a limited palette. This uses octree quantization
    // which produces much better results than the previous first-come-first-
    // served approach that silently mapped overflow colors to register 0.
    final quantized = img.quantize(
      image,
      numberOfColors: maxColors,
      method: img.QuantizeMethod.octree,
    );

    // Build the palette and per-pixel index map from the quantized image.
    final palette = <int, _RgbColor>{};
    final indexedPixels = List<int>.filled(width * height, 0);

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final pixel = quantized.getPixel(x, y);
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();

        // Pack RGB into a single int for palette lookup.
        final packed = (r << 16) | (g << 8) | b;

        if (!palette.containsKey(packed)) {
          palette[packed] = _RgbColor(r, g, b);
        }

        indexedPixels[y * width + x] = packed;
      }
    }

    // Assign sequential register indices to each unique color.
    final registerMap = <int, int>{};
    var nextRegister = 0;
    for (final packed in palette.keys) {
      registerMap[packed] = nextRegister++;
    }

    // Map each pixel to its register index.
    final pixelRegisters = List<int>.filled(width * height, 0);
    for (var i = 0; i < indexedPixels.length; i++) {
      pixelRegisters[i] = registerMap[indexedPixels[i]] ?? 0;
    }

    final buffer = StringBuffer();

    // DCS (Device Control String) start with Sixel introducer.
    buffer.write('\x1bPq');

    // Write color definitions: #<register>;2;<r%>;<g%>;<b%>
    // RGB values are scaled from 0–255 to 0–100 percentages.
    for (final entry in palette.entries) {
      final reg = registerMap[entry.key]!;
      final color = entry.value;
      final rPct = (color.r * 100 / 255).round();
      final gPct = (color.g * 100 / 255).round();
      final bPct = (color.b * 100 / 255).round();
      buffer.write('#$reg;2;$rPct;$gPct;$bPct');
    }

    // Encode image data in 6-row strips (bands).
    _encodeImageData(buffer, pixelRegisters, width, height, nextRegister);

    // String Terminator.
    buffer.write('\x1b\\');

    return buffer.toString();
  }

  /// Encodes an image with resizing to fit the given cell dimensions.
  ///
  /// [image] is the source image.
  /// [columns] is the target width in terminal columns (each column ≈ 1 pixel
  ///   width in Sixel, but the caller should account for cell pixel size).
  /// [rows] is the target height in terminal rows.
  /// [cellPixelWidth] is the pixel width of a single terminal cell (default 8).
  /// [cellPixelHeight] is the pixel height of a single terminal cell (default 16).
  /// [maxColors] is the maximum palette size (default 256).
  ///
  /// Returns a string containing the complete Sixel escape sequence.
  static String encodeResized(
    img.Image image, {
    required int columns,
    required int rows,
    int cellPixelWidth = 8,
    int cellPixelHeight = 16,
    int maxColors = maxPaletteSize,
  }) {
    final targetWidth = columns * cellPixelWidth;
    // Round target height up to the next multiple of 6 for clean Sixel bands.
    final rawHeight = rows * cellPixelHeight;
    final targetHeight = ((rawHeight + 5) ~/ 6) * 6;

    final resized = img.copyResize(
      image,
      width: targetWidth,
      height: targetHeight,
      interpolation: img.Interpolation.average,
    );

    return encode(resized, maxColors: maxColors);
  }

  /// Encodes the image data as Sixel graphics bands.
  ///
  /// For each 6-row band, iterates over every active color register, builds
  /// the sixel character row (where each character encodes a column of 6
  /// vertical pixels as a 6-bit value + 63), and writes it with RLE
  /// compression.
  static void _encodeImageData(
    StringBuffer buffer,
    List<int> pixelRegisters,
    int width,
    int height,
    int paletteSize,
  ) {
    final numBands = (height + 5) ~/ 6;

    for (var band = 0; band < numBands; band++) {
      final bandStartY = band * 6;
      var firstColorInBand = true;

      for (var colorIndex = 0; colorIndex < paletteSize; colorIndex++) {
        // Skip colors that don't appear in this band.
        if (!_colorAppearsInBand(
          pixelRegisters,
          width,
          height,
          bandStartY,
          colorIndex,
        )) {
          continue;
        }

        // Carriage return to start of band for second and subsequent colors.
        if (!firstColorInBand) {
          buffer.write('\$');
        }
        firstColorInBand = false;

        // Select color register.
        buffer.write('#$colorIndex');

        // Build the sixel character row for this color.
        final sixelRow = _buildSixelRow(
          pixelRegisters,
          width,
          height,
          bandStartY,
          colorIndex,
        );

        // Write with RLE compression.
        _writeRleCompressed(buffer, sixelRow);
      }

      // Graphics New Line — advance to the next 6-row band.
      if (band < numBands - 1) {
        buffer.write('-');
      }
    }
  }

  /// Checks whether a specific color register appears anywhere in a 6-row band.
  static bool _colorAppearsInBand(
    List<int> pixelRegisters,
    int width,
    int height,
    int bandStartY,
    int colorIndex,
  ) {
    for (var row = 0; row < 6; row++) {
      final y = bandStartY + row;
      if (y >= height) break;
      final rowOffset = y * width;
      for (var x = 0; x < width; x++) {
        if (pixelRegisters[rowOffset + x] == colorIndex) {
          return true;
        }
      }
    }
    return false;
  }

  /// Builds a row of sixel characters for a specific color register.
  ///
  /// Each sixel character represents a column of 6 pixels. Bit 0 is the top
  /// pixel, bit 5 is the bottom pixel. The character value is the 6-bit
  /// pattern + 63 (ASCII '?').
  static List<int> _buildSixelRow(
    List<int> pixelRegisters,
    int width,
    int height,
    int bandStartY,
    int colorIndex,
  ) {
    final result = List<int>.filled(width, 0);

    for (var x = 0; x < width; x++) {
      var sixelValue = 0;

      for (var bit = 0; bit < 6; bit++) {
        final y = bandStartY + bit;
        if (y >= height) break;

        if (pixelRegisters[y * width + x] == colorIndex) {
          sixelValue |= (1 << bit);
        }
      }

      result[x] = sixelValue + 63;
    }

    return result;
  }

  /// Writes sixel characters with RLE compression.
  ///
  /// RLE format: `!<count><char>` repeats `<char>` `<count>` times.
  /// Only used when count > 3 (otherwise direct output is more compact).
  static void _writeRleCompressed(StringBuffer buffer, List<int> sixelChars) {
    if (sixelChars.isEmpty) return;

    var i = 0;
    while (i < sixelChars.length) {
      final char = sixelChars[i];
      var count = 1;

      while (i + count < sixelChars.length && sixelChars[i + count] == char) {
        count++;
      }

      if (count > 3) {
        buffer.write('!$count');
        buffer.writeCharCode(char);
      } else {
        for (var j = 0; j < count; j++) {
          buffer.writeCharCode(char);
        }
      }

      i += count;
    }
  }
}

/// Simple RGB color holder used internally for palette construction.
class _RgbColor {
  final int r;
  final int g;
  final int b;

  const _RgbColor(this.r, this.g, this.b);
}
