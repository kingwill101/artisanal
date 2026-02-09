import 'dart:typed_data';

import 'package:nocterm/src/image/color_quantizer.dart';
import 'package:nocterm/src/style.dart';

/// Encodes image data to Sixel format escape sequences.
///
/// Sixel is a bitmap graphics format for terminals that encodes images
/// in 6-pixel high horizontal strips. Each column of 6 vertical pixels
/// is represented as a single ASCII character.
///
/// The format uses:
/// - Color definitions: `#<index>;2;<r>;<g>;<b>` (r,g,b are 0-100)
/// - Sixel data: ASCII characters (63-126) where bits 0-5 represent pixels
/// - RLE compression: `!<count><char>` for repeated characters
/// - Navigation: `$` returns to start of strip, `-` moves to next strip
class SixelEncoder {
  // Sixel escape sequence markers
  static const _dcsStart = '\x1bPq'; // Device Control String start with sixel
  static const _st = '\x1b\\'; // String Terminator

  /// Encodes image data to a sixel escape sequence.
  ///
  /// Parameters:
  /// - [pixels]: RGBA pixel data (4 bytes per pixel, row-major order)
  /// - [width]: Image width in pixels
  /// - [height]: Image height in pixels
  /// - [palette]: Color palette (max 256 colors)
  /// - [indexedPixels]: Palette index for each pixel (width * height bytes)
  ///
  /// Returns a complete sixel escape sequence ready to be written to terminal.
  static String encode({
    required Uint8List pixels,
    required int width,
    required int height,
    required List<Color> palette,
    required Uint8List indexedPixels,
  }) {
    if (width <= 0 || height <= 0) {
      return '';
    }

    if (palette.isEmpty || palette.length > 256) {
      throw ArgumentError('Palette must have 1-256 colors');
    }

    if (indexedPixels.length != width * height) {
      throw ArgumentError(
        'indexedPixels length (${indexedPixels.length}) must match '
        'width * height ($width * $height = ${width * height})',
      );
    }

    final buffer = StringBuffer();

    // Output DCS header
    buffer.write(_dcsStart);

    // Output color definitions
    _writeColorDefinitions(buffer, palette);

    // Encode image data in 6-row strips
    _encodeImageData(buffer, indexedPixels, width, height, palette.length);

    // Output string terminator
    buffer.write(_st);

    return buffer.toString();
  }

  /// Writes color palette definitions to the buffer.
  ///
  /// Format: `#<index>;2;<r>;<g>;<b>`
  /// where r, g, b are percentages (0-100), not 0-255 values.
  static void _writeColorDefinitions(StringBuffer buffer, List<Color> palette) {
    for (int i = 0; i < palette.length; i++) {
      final color = palette[i];
      // Convert 0-255 RGB to 0-100 percentage
      final r = (color.red * 100 / 255).round();
      final g = (color.green * 100 / 255).round();
      final b = (color.blue * 100 / 255).round();
      buffer.write('#$i;2;$r;$g;$b');
    }
  }

  /// Encodes the image data as sixel graphics.
  ///
  /// Process:
  /// 1. For each 6-row strip (band)
  /// 2. For each color in the palette
  /// 3. Build sixel characters for columns where that color appears
  /// 4. Apply RLE compression
  /// 5. Move to next color or next strip
  static void _encodeImageData(
    StringBuffer buffer,
    Uint8List indexedPixels,
    int width,
    int height,
    int paletteSize,
  ) {
    // Process image in 6-row strips (bands)
    final numBands = (height + 5) ~/ 6;

    for (int band = 0; band < numBands; band++) {
      final bandStartY = band * 6;
      bool firstColorInBand = true;

      // For each color in the palette
      for (int colorIndex = 0; colorIndex < paletteSize; colorIndex++) {
        // Check if this color appears in this band
        if (!_colorAppearsInBand(
          indexedPixels,
          width,
          height,
          bandStartY,
          colorIndex,
        )) {
          continue;
        }

        // Select color
        buffer.write('#$colorIndex');

        // Generate sixel row for this color
        final sixelRow = _buildSixelRow(
          indexedPixels,
          width,
          height,
          bandStartY,
          colorIndex,
        );

        // Apply RLE compression and write
        _writeRleCompressed(buffer, sixelRow);

        // Return to start of band for next color (or end of band marker)
        if (!firstColorInBand) {
          // We've already written a $, this is continuation
        }
        buffer.write('\$'); // Carriage return (back to start of this band)
        firstColorInBand = false;
      }

      // Move to next band (Graphics New Line)
      if (band < numBands - 1) {
        buffer.write('-');
      }
    }
  }

  /// Checks if a specific color appears in a 6-row band.
  static bool _colorAppearsInBand(
    Uint8List indexedPixels,
    int width,
    int height,
    int bandStartY,
    int colorIndex,
  ) {
    for (int row = 0; row < 6; row++) {
      final y = bandStartY + row;
      if (y >= height) break;

      for (int x = 0; x < width; x++) {
        if (indexedPixels[y * width + x] == colorIndex) {
          return true;
        }
      }
    }
    return false;
  }

  /// Builds a row of sixel characters for a specific color.
  ///
  /// Each sixel character represents a column of 6 pixels.
  /// Bit 0 = top pixel, bit 5 = bottom pixel.
  /// The character value is the bit pattern + 63 (ASCII offset).
  static List<int> _buildSixelRow(
    Uint8List indexedPixels,
    int width,
    int height,
    int bandStartY,
    int colorIndex,
  ) {
    final result = List<int>.filled(width, 0);

    for (int x = 0; x < width; x++) {
      int sixelValue = 0;

      for (int bit = 0; bit < 6; bit++) {
        final y = bandStartY + bit;
        if (y >= height) break;

        if (indexedPixels[y * width + x] == colorIndex) {
          sixelValue |= (1 << bit);
        }
      }

      // Convert to sixel character (add 63 = '?')
      result[x] = sixelValue + 63;
    }

    return result;
  }

  /// Writes sixel data with RLE compression.
  ///
  /// RLE format: `!<count><char>` repeats `<char>` `<count>` times.
  /// Only used when count > 3 (otherwise direct output is smaller).
  static void _writeRleCompressed(StringBuffer buffer, List<int> sixelChars) {
    if (sixelChars.isEmpty) return;

    int i = 0;
    while (i < sixelChars.length) {
      final char = sixelChars[i];
      int count = 1;

      // Count consecutive identical characters
      while (i + count < sixelChars.length && sixelChars[i + count] == char) {
        count++;
      }

      // Use RLE if count > 3 (shorter than repeating character)
      if (count > 3) {
        buffer.write('!$count');
        buffer.writeCharCode(char);
      } else {
        // Write characters directly
        for (int j = 0; j < count; j++) {
          buffer.writeCharCode(char);
        }
      }

      i += count;
    }
  }

  /// Convenience method to encode an RGBA image with automatic quantization.
  ///
  /// This is a higher-level method that handles color quantization internally
  /// using the [ColorQuantizer] class.
  ///
  /// For more control over quantization, use [encode] directly with
  /// pre-quantized data from [ColorQuantizer.quantize].
  static String encodeRgba({
    required Uint8List rgbaPixels,
    required int width,
    required int height,
    int maxColors = 256,
  }) {
    final (palette, indexedPixels) = ColorQuantizer.quantize(
      rgbaPixels: rgbaPixels,
      width: width,
      height: height,
      maxColors: maxColors,
    );

    return encode(
      pixels: rgbaPixels,
      width: width,
      height: height,
      palette: palette,
      indexedPixels: indexedPixels,
    );
  }
}
