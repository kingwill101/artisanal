import 'dart:convert';
import 'package:image/image.dart' as img;
import '../ansi.dart';

/// Utilities for the iTerm2 Image Protocol.
///
/// The escape sequence format is:
/// ```
/// ESC ] 1337 ; File = [arguments] : base64-data ST
/// ```
///
/// Arguments are semicolon-separated key=value pairs:
/// - `name=<base64>` — Base64 encoded filename (optional)
/// - `size=N` — File size in bytes (helps the terminal show progress)
/// - `width=N` — Display width: N (cells), Npx (pixels), N% (percent), or "auto"
/// - `height=N` — Display height: same format as width
/// - `preserveAspectRatio=0|1` — Default 1
/// - `inline=1` — Must be 1 to display inline (otherwise downloads)
///
/// See: https://iterm2.com/documentation-images.html
class ITerm2Image {
  /// Encodes an image into iTerm2 Image Protocol escape sequences.
  ///
  /// The image is first encoded as PNG internally.
  ///
  /// [image] is the image to encode.
  /// [name] is an optional filename for the image.
  /// [columns] is the number of terminal columns the image should occupy.
  /// [rows] is the number of terminal rows the image should occupy.
  /// [preserveAspectRatio] whether to preserve aspect ratio (default true).
  ///
  /// Returns a string containing the escape sequences to display the image.
  static String encode(
    img.Image image, {
    String? name,
    int? columns,
    int? rows,
    bool preserveAspectRatio = true,
  }) {
    // iTerm2 expects a standard image format (like PNG) base64 encoded.
    final pngBytes = img.encodePng(image);
    return encodePng(
      pngBytes,
      name: name,
      columns: columns,
      rows: rows,
      preserveAspectRatio: preserveAspectRatio,
    );
  }

  /// Encodes pre-encoded PNG bytes into iTerm2 Image Protocol escape sequences.
  ///
  /// Use this when you already have PNG data and want to avoid re-encoding.
  ///
  /// [pngBytes] is the PNG-encoded image data.
  /// [name] is an optional filename for the image.
  /// [columns] is the display width in terminal columns (or use string
  ///   values like "auto", "Npx", "N%" via the protocol directly).
  /// [rows] is the display height in terminal rows.
  /// [preserveAspectRatio] whether to preserve aspect ratio (default true).
  ///
  /// Returns a string containing the escape sequences to display the image.
  static String encodePng(
    List<int> pngBytes, {
    String? name,
    int? columns,
    int? rows,
    bool preserveAspectRatio = true,
  }) {
    final base64Data = base64Encode(pngBytes);

    final args = StringBuffer('inline=1');
    if (name != null) {
      args.write(';name=${base64Encode(utf8.encode(name))}');
    }
    // Include file size so the terminal can show transfer progress.
    args.write(';size=${pngBytes.length}');
    if (columns != null) {
      args.write(';width=$columns');
    }
    if (rows != null) {
      args.write(';height=$rows');
    }
    if (!preserveAspectRatio) {
      args.write(';preserveAspectRatio=0');
    }

    return '${Ansi.osc}1337;File=$args:$base64Data${Ansi.st}';
  }
}
