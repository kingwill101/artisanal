import 'dart:convert';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Encodes images using the iTerm2 Inline Images Protocol.
///
/// This protocol is supported by:
/// - iTerm2 (native)
/// - WezTerm
/// - Warp (may need workarounds)
///
/// The escape sequence format is:
/// ```
/// ESC ] 1337 ; File = [arguments] : base64-data BEL
/// ```
///
/// Arguments are semicolon-separated key=value pairs:
/// - `name=base64-filename` - Base64 encoded filename (optional)
/// - `size=N` - File size in bytes (optional, for progress)
/// - `width=N` - Width: N (cells), Npx (pixels), N% (percent), or "auto"
/// - `height=N` - Height: same format as width
/// - `preserveAspectRatio=0|1` - Default 1
/// - `inline=1` - Must be 1 to display inline (otherwise downloads)
///
/// Reference: https://iterm2.com/documentation-images.html
class ITerm2Encoder {
  /// OSC 1337 escape sequence start
  static const String _oscStart = '\x1b]1337;File=';

  /// String terminator (BEL)
  static const String _bel = '\x07';

  /// Alternative string terminator (ST)
  static const String _st = '\x1b\\';

  /// Encode PNG/JPEG/GIF image bytes to iTerm2 escape sequence.
  ///
  /// [imageBytes] - Encoded image data (PNG, JPEG, GIF, etc.)
  /// [width] - Display width (cells, or "auto", "Npx", "N%")
  /// [height] - Display height (cells, or "auto", "Npx", "N%")
  /// [preserveAspectRatio] - Whether to preserve aspect ratio (default true)
  /// [filename] - Optional filename for the image
  /// [useST] - Use ST terminator instead of BEL (default false)
  ///
  /// Returns a complete iTerm2 escape sequence ready to be written to terminal.
  static String encode({
    required Uint8List imageBytes,
    String? width,
    String? height,
    bool preserveAspectRatio = true,
    String? filename,
    bool useST = false,
  }) {
    final buffer = StringBuffer();

    // Start OSC 1337
    buffer.write(_oscStart);

    // Arguments
    final args = <String>['inline=1'];

    if (filename != null) {
      args.add('name=${base64Encode(utf8.encode(filename))}');
    }

    args.add('size=${imageBytes.length}');

    if (width != null) {
      args.add('width=$width');
    }

    if (height != null) {
      args.add('height=$height');
    }

    if (!preserveAspectRatio) {
      args.add('preserveAspectRatio=0');
    }

    buffer.write(args.join(';'));
    buffer.write(':');

    // Base64 encoded image data (no line breaks)
    buffer.write(base64Encode(imageBytes));

    // Terminator
    buffer.write(useST ? _st : _bel);

    return buffer.toString();
  }

  /// Encode raw RGBA pixels to iTerm2 format.
  ///
  /// This first encodes the pixels as PNG, then wraps in iTerm2 protocol.
  ///
  /// [rgbaPixels] - Raw RGBA pixel data (4 bytes per pixel, row-major order)
  /// [width] - Image width in pixels
  /// [height] - Image height in pixels
  /// [displayWidth] - Display width (cells, or "auto", "Npx", "N%")
  /// [displayHeight] - Display height (cells, or "auto", "Npx", "N%")
  /// [preserveAspectRatio] - Whether to preserve aspect ratio (default true)
  ///
  /// Returns a complete iTerm2 escape sequence ready to be written to terminal.
  static String encodeRgba({
    required Uint8List rgbaPixels,
    required int width,
    required int height,
    String? displayWidth,
    String? displayHeight,
    bool preserveAspectRatio = true,
  }) {
    if (width <= 0 || height <= 0) {
      return '';
    }

    if (rgbaPixels.length != width * height * 4) {
      throw ArgumentError(
        'rgbaPixels length (${rgbaPixels.length}) must match '
        'width * height * 4 ($width * $height * 4 = ${width * height * 4})',
      );
    }

    // Create image and copy pixels
    final image = img.Image(width: width, height: height, numChannels: 4);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final i = (y * width + x) * 4;
        image.setPixelRgba(
          x,
          y,
          rgbaPixels[i], // R
          rgbaPixels[i + 1], // G
          rgbaPixels[i + 2], // B
          rgbaPixels[i + 3], // A
        );
      }
    }

    // Encode as PNG
    final pngBytes = Uint8List.fromList(img.encodePng(image));

    return encode(
      imageBytes: pngBytes,
      width: displayWidth,
      height: displayHeight,
      preserveAspectRatio: preserveAspectRatio,
    );
  }
}
