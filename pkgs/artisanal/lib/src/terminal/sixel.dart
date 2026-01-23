import 'package:image/image.dart' as img;

/// Utilities for Sixel Graphics.
///
/// See: https://en.wikipedia.org/wiki/Sixel
class SixelImage {
  /// Encodes an image into Sixel escape sequences.
  ///
  /// This is a simplified encoder that defines colors as needed.
  static String encode(img.Image image) {
    final buffer = StringBuffer();

    // Start Sixel: ESC P q
    buffer.write('\x1bPq');

    // Set pixel aspect ratio (1:1)
    buffer.write('"1;1');

    final width = image.width;
    final height = image.height;

    // Simple color mapping: Map each unique color to a Sixel color register.
    final palette = <int, int>{};
    var nextRegister = 0;

    // Sixel processes 6 vertical pixels at a time.
    for (var y = 0; y < height; y += 6) {
      // For each color register used in this 6-pixel row, we store the bitmasks.
      final rowMasks = <int, List<int>>{};

      for (var x = 0; x < width; x++) {
        for (var dy = 0; dy < 6; dy++) {
          if (y + dy >= height) break;

          final pixel = image.getPixel(x, y + dy);
          if (pixel.a == 0) continue; // Skip transparent

          final colorValue =
              (pixel.r.toInt() << 16) |
              (pixel.g.toInt() << 8) |
              pixel.b.toInt();

          if (!palette.containsKey(colorValue)) {
            if (nextRegister < 256) {
              palette[colorValue] = nextRegister;
              // Define color: #n;2;r;g;b (r,g,b are 0-100)
              final r = (pixel.r * 100 / 255).round();
              final g = (pixel.g * 100 / 255).round();
              final b = (pixel.b * 100 / 255).round();
              buffer.write('#$nextRegister;2;$r;$g;$b');
              nextRegister++;
            } else {
              // Fallback to closest or just use register 0
              palette[colorValue] = 0;
            }
          }

          final reg = palette[colorValue]!;
          rowMasks.putIfAbsent(reg, () => List<int>.filled(width, 0));
          rowMasks[reg]![x] |= (1 << dy);
        }
      }

      // Output each color's bitmasks for this row.
      var firstColor = true;
      for (final entry in rowMasks.entries) {
        final reg = entry.key;
        final masks = entry.value;

        if (!firstColor) {
          buffer.write('\$'); // Carriage return to start of row
        }
        buffer.write('#$reg');

        var lastMask = -1;
        var repeatCount = 0;

        for (var x = 0; x < width; x++) {
          final mask = masks[x];
          final char = String.fromCharCode(mask + 63);

          if (mask == lastMask) {
            repeatCount++;
          } else {
            if (repeatCount > 3) {
              buffer.write(
                '!$repeatCount${String.fromCharCode(lastMask + 63)}',
              );
            } else if (repeatCount > 0) {
              for (var i = 0; i < repeatCount; i++) {
                buffer.write(String.fromCharCode(lastMask + 63));
              }
            }
            buffer.write(char);
            lastMask = mask;
            repeatCount = 0;
          }
        }
        // Flush remaining repeats
        if (repeatCount > 3) {
          buffer.write('!$repeatCount${String.fromCharCode(lastMask + 63)}');
        } else if (repeatCount > 0) {
          for (var i = 0; i < repeatCount; i++) {
            buffer.write(String.fromCharCode(lastMask + 63));
          }
        }

        firstColor = false;
      }

      buffer.write('-'); // New line (6 pixels down)
    }

    // End Sixel: ESC \
    buffer.write('\x1b\\');

    return buffer.toString();
  }
}
