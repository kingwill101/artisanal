import 'dart:convert';
import 'package:image/image.dart' as img;
import 'ansi.dart';

/// Utilities for the iTerm2 Image Protocol.
///
/// See: https://iterm2.com/documentation-images.html
class ITerm2Image {
  /// Encodes an image into iTerm2 Image Protocol escape sequences.
  ///
  /// [image] is the image to encode.
  /// [name] is an optional name for the image.
  /// [columns] is the number of terminal columns the image should occupy.
  /// [rows] is the number of terminal rows the image should occupy.
  ///
  /// Returns a string containing the escape sequences to display the image.
  static String encode(
    img.Image image, {
    String? name,
    int? columns,
    int? rows,
    bool preserveAspectRatio = false,
  }) {
    // iTerm2 expects a standard image format (like PNG) base64 encoded.
    final pngBytes = img.encodePng(image);
    final base64Data = base64Encode(pngBytes);

    final args = StringBuffer('inline=1');
    if (name != null) {
      args.write(';name=${base64Encode(utf8.encode(name))}');
    }
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
