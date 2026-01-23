import 'dart:convert';
import 'package:image/image.dart' as img;
import 'ansi.dart';

/// Utilities for the Kitty Graphics Protocol.
///
/// See: https://sw.kovidgoyal.net/kitty/graphics-protocol/
class KittyImage {
  /// Encodes an image into Kitty Graphics Protocol escape sequences.
  ///
  /// [image] is the image to encode.
  /// [id] is an optional ID for the image.
  /// [chunkSize] is the maximum size of each data chunk (default 4096).
  /// [columns] is the number of terminal columns the image should occupy.
  /// [rows] is the number of terminal rows the image should occupy.
  ///
  /// Returns a string containing the escape sequences to display the image.
  static String encode(
    img.Image image, {
    int? id,
    int chunkSize = 4096,
    int? columns,
    int? rows,
  }) {
    final buffer = StringBuffer();

    // Convert to RGBA if not already in a compatible format
    final rgbaImage =
        (image.numChannels == 4 && image.format == img.Format.uint8)
        ? image
        : image.convert(format: img.Format.uint8, numChannels: 4);

    final bytes = rgbaImage.toUint8List();
    final base64Data = base64Encode(bytes);

    final width = rgbaImage.width;
    final height = rgbaImage.height;

    // Control data for the first chunk
    // a=T: action is transmit and display
    // f=32: format is RGBA
    // s: width, v: height
    // i: id (optional)
    // c: columns (optional)
    // r: rows (optional)
    final control = StringBuffer('a=T,f=32,s=$width,v=$height');
    if (id != null) {
      control.write(',i=$id');
    }
    if (columns != null) {
      control.write(',c=$columns');
    }
    if (rows != null) {
      control.write(',r=$rows');
    }

    int offset = 0;
    while (offset < base64Data.length) {
      final end = (offset + chunkSize < base64Data.length)
          ? offset + chunkSize
          : base64Data.length;
      final chunk = base64Data.substring(offset, end);
      final isLast = end == base64Data.length;

      // m=1 if more chunks follow, m=0 if last chunk
      final m = isLast ? 0 : 1;

      if (offset == 0) {
        // First chunk includes full control data
        buffer.write('${Ansi.apc}G$control,m=$m;$chunk${Ansi.st}');
      } else {
        // Subsequent chunks only need m
        buffer.write('${Ansi.apc}Gm=$m;$chunk${Ansi.st}');
      }

      offset = end;
    }

    return buffer.toString();
  }
}
