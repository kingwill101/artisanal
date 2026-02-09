import 'dart:convert';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Encodes images using the Kitty Graphics Protocol.
///
/// This protocol is supported by:
/// - Kitty (native)
/// - WezTerm
/// - Konsole (partial)
///
/// The escape sequence format is:
/// ```
/// ESC_G<control data>;<payload>ESC\
/// ```
///
/// Control data is comma-separated key=value pairs:
/// - `a` (action): `T` = transmit and display, `t` = transmit only, `p` = display placed, `d` = delete
/// - `f` (format): `24` = RGB, `32` = RGBA (default), `100` = PNG
/// - `t` (transmission): `d` = direct (data in escape code), `f` = file path
/// - `s` (width): Image width in pixels (required for RGB/RGBA)
/// - `v` (height): Image height in pixels (required for RGB/RGBA)
/// - `o` (compression): `z` = zlib compressed
/// - `m` (more): `1` = more chunks coming, `0` = final chunk (default)
/// - `i` (image id): Optional image identifier for reuse
/// - `q` (quiet): `1` = suppress response, `2` = suppress errors too
///
/// Reference: https://sw.kovidgoyal.net/kitty/graphics-protocol/
class KittyEncoder {
  /// APC start sequence (ESC _ G)
  static const String _apcStart = '\x1b_G';

  /// String terminator (ESC \)
  static const String _st = '\x1b\\';

  /// Maximum chunk size for base64 data (must be multiple of 4)
  static const int _maxChunkSize = 4096;

  /// Global counter for generating unique image IDs
  static int _nextImageId = 1;

  /// Get the next unique image ID.
  static int getNextImageId() => _nextImageId++;

  /// Delete an image by its ID.
  ///
  /// [imageId] - The image ID to delete. If null, deletes all images.
  /// [quiet] - Suppress terminal response (0=no, 1=suppress OK, 2=suppress all)
  ///
  /// Returns an escape sequence that deletes the specified image.
  static String delete({int? imageId, int quiet = 2}) {
    final buffer = StringBuffer();
    buffer.write(_apcStart);
    buffer.write('a=d'); // Delete action

    if (imageId != null) {
      buffer.write(',i=$imageId');
    }

    buffer.write(',q=$quiet');
    buffer.write(_st);
    return buffer.toString();
  }

  /// Delete all images from the terminal.
  ///
  /// [quiet] - Suppress terminal response
  ///
  /// Returns an escape sequence that deletes all images.
  static String deleteAll({int quiet = 2}) => delete(quiet: quiet);

  /// Encode PNG image bytes using Kitty protocol.
  ///
  /// [imageBytes] - PNG encoded image data
  /// [quiet] - Suppress terminal response (0=no, 1=suppress OK, 2=suppress all)
  /// [imageId] - Optional image identifier for reuse
  /// [displayColumns] - Display width in terminal columns (cells)
  /// [displayRows] - Display height in terminal rows (cells)
  ///
  /// Returns a complete Kitty escape sequence ready to be written to terminal.
  static String encodePng({
    required Uint8List imageBytes,
    int quiet = 2,
    int? imageId,
    int? displayColumns,
    int? displayRows,
  }) {
    final params = <String, dynamic>{
      'a': 'T', // Transmit and display
      'f': 100, // PNG format
      'q': quiet,
    };

    if (imageId != null) {
      params['i'] = imageId;
    }

    // Display dimensions in cells (terminal will scale the image)
    if (displayColumns != null) {
      params['c'] = displayColumns;
    }
    if (displayRows != null) {
      params['r'] = displayRows;
    }

    final base64Data = base64Encode(imageBytes);
    return _encodeWithChunking(base64Data, params);
  }

  /// Encode raw RGBA pixels using Kitty protocol.
  ///
  /// This first encodes the pixels as PNG, then uses the PNG encoder.
  /// This is more efficient than raw pixel transmission for most use cases.
  ///
  /// [rgbaPixels] - Raw RGBA pixel data (4 bytes per pixel)
  /// [width] - Image width in pixels
  /// [height] - Image height in pixels
  /// [quiet] - Suppress terminal response
  /// [imageId] - Optional image identifier for reuse
  /// [displayColumns] - Display width in terminal columns (cells)
  /// [displayRows] - Display height in terminal rows (cells)
  ///
  /// Returns a complete Kitty escape sequence ready to be written to terminal.
  static String encodeRgba({
    required Uint8List rgbaPixels,
    required int width,
    required int height,
    int quiet = 2,
    int? imageId,
    int? displayColumns,
    int? displayRows,
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

    return encodePng(
      imageBytes: pngBytes,
      quiet: quiet,
      imageId: imageId,
      displayColumns: displayColumns,
      displayRows: displayRows,
    );
  }

  /// Encode raw RGB pixels (no alpha) using Kitty protocol.
  ///
  /// This first encodes the pixels as PNG, then uses the PNG encoder.
  ///
  /// [rgbPixels] - Raw RGB pixel data (3 bytes per pixel)
  /// [width] - Image width in pixels
  /// [height] - Image height in pixels
  /// [quiet] - Suppress terminal response
  /// [imageId] - Optional image identifier for reuse
  ///
  /// Returns a complete Kitty escape sequence ready to be written to terminal.
  static String encodeRgb({
    required Uint8List rgbPixels,
    required int width,
    required int height,
    int quiet = 2,
    int? imageId,
  }) {
    if (width <= 0 || height <= 0) {
      return '';
    }

    if (rgbPixels.length != width * height * 3) {
      throw ArgumentError(
        'rgbPixels length (${rgbPixels.length}) must match '
        'width * height * 3 ($width * $height * 3 = ${width * height * 3})',
      );
    }

    // Create image and copy pixels
    final image = img.Image(width: width, height: height, numChannels: 3);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final i = (y * width + x) * 3;
        image.setPixelRgb(
          x,
          y,
          rgbPixels[i], // R
          rgbPixels[i + 1], // G
          rgbPixels[i + 2], // B
        );
      }
    }

    // Encode as PNG
    final pngBytes = Uint8List.fromList(img.encodePng(image));

    return encodePng(
      imageBytes: pngBytes,
      quiet: quiet,
      imageId: imageId,
    );
  }

  /// Encode base64 data with chunking according to Kitty protocol rules.
  ///
  /// - First chunk includes all parameters
  /// - All chunks except final must be multiples of 4 bytes
  /// - Use m=1 for continuation, m=0 for final
  static String _encodeWithChunking(
    String base64Data,
    Map<String, dynamic> params,
  ) {
    final buffer = StringBuffer();
    int offset = 0;
    bool isFirst = true;

    while (offset < base64Data.length) {
      final remaining = base64Data.length - offset;
      int chunkSize = remaining > _maxChunkSize ? _maxChunkSize : remaining;

      // Ensure chunk is multiple of 4 (except last chunk)
      if (offset + chunkSize < base64Data.length) {
        chunkSize = (chunkSize ~/ 4) * 4;
      }

      final chunk = base64Data.substring(offset, offset + chunkSize);
      final isLast = (offset + chunkSize >= base64Data.length);

      buffer.write(_apcStart);

      if (isFirst) {
        // First chunk includes all parameters
        buffer.write(_formatParams(params));
        buffer.write(',');
        isFirst = false;
      }

      buffer.write('m=${isLast ? 0 : 1}');
      buffer.write(';');
      buffer.write(chunk);
      buffer.write(_st);

      offset += chunkSize;
    }

    // Handle empty data case
    if (base64Data.isEmpty) {
      buffer.write(_apcStart);
      buffer.write(_formatParams(params));
      buffer.write(',m=0;');
      buffer.write(_st);
    }

    return buffer.toString();
  }

  /// Format parameters as comma-separated key=value pairs.
  static String _formatParams(Map<String, dynamic> params) {
    return params.entries.map((e) => '${e.key}=${e.value}').join(',');
  }
}
