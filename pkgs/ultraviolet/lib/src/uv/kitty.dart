import 'dart:convert';
import 'package:image/image.dart' as img;
import '../ansi.dart';

/// Utilities for the Kitty Graphics Protocol.
///
/// See: https://sw.kovidgoyal.net/kitty/graphics-protocol/
class KittyImage {
  /// Maximum chunk size for base64 data (must be multiple of 4).
  static const int _maxChunkSize = 4096;

  /// Global counter for generating unique image IDs.
  static int _nextImageId = 1;

  /// Returns the next unique image ID.
  static int getNextImageId() => _nextImageId++;

  /// Encodes an image into Kitty Graphics Protocol escape sequences.
  ///
  /// The image is first encoded as PNG for efficient transmission (format 100),
  /// which is dramatically smaller than raw RGBA (format 32). For example, a
  /// 100×100 image is ~5 KB as PNG vs ~40 KB as raw RGBA.
  ///
  /// [image] is the image to encode.
  /// [id] is an optional ID for the image (useful for later deletion/replacement).
  /// [chunkSize] is the maximum size of each base64 data chunk (default 4096).
  /// [columns] is the number of terminal columns the image should occupy.
  /// [rows] is the number of terminal rows the image should occupy.
  /// [quiet] suppresses terminal responses: 0 = no suppression,
  ///   1 = suppress OK responses, 2 = suppress all responses (default).
  /// [suppressCursorMovement] asks the terminal not to advance after drawing
  /// (default false); retained renderers can then move the cursor explicitly
  /// and keep their logical cursor state aligned with the terminal.
  ///
  /// Returns a string containing the escape sequences to display the image.
  static String encode(
    img.Image image, {
    int? id,
    int chunkSize = _maxChunkSize,
    int? columns,
    int? rows,
    int quiet = 2,
    bool suppressCursorMovement = false,
  }) {
    // Encode as PNG for efficient transmission.
    final pngBytes = img.encodePng(image);
    return encodePng(
      pngBytes,
      id: id,
      chunkSize: chunkSize,
      columns: columns,
      rows: rows,
      quiet: quiet,
      suppressCursorMovement: suppressCursorMovement,
    );
  }

  /// Encodes pre-encoded PNG bytes into Kitty Graphics Protocol escape sequences.
  ///
  /// Use this when you already have PNG data and want to avoid re-encoding.
  ///
  /// [pngBytes] is the PNG-encoded image data.
  /// [id] is an optional image identifier for reuse/deletion.
  /// [chunkSize] is the maximum size of each base64 data chunk (default 4096).
  /// [columns] is the number of terminal columns the image should occupy.
  /// [rows] is the number of terminal rows the image should occupy.
  /// [quiet] suppresses terminal responses (default 2 = suppress all).
  /// [suppressCursorMovement] emits Kitty `C=1` (default false), preventing the
  /// terminal from moving the cursor while a retained renderer advances it
  /// explicitly.
  ///
  /// Returns a string containing the escape sequences to display the image.
  static String encodePng(
    List<int> pngBytes, {
    int? id,
    int chunkSize = _maxChunkSize,
    int? columns,
    int? rows,
    int quiet = 2,
    bool suppressCursorMovement = false,
  }) {
    final base64Data = base64Encode(pngBytes);

    // Build control parameters for the first chunk.
    // a=T: transmit and display
    // f=100: PNG format
    // q: quiet mode
    final params = StringBuffer('a=T,f=100');
    if (id != null) {
      params.write(',i=$id');
    }
    if (columns != null) {
      params.write(',c=$columns');
    }
    if (rows != null) {
      params.write(',r=$rows');
    }
    if (suppressCursorMovement) {
      params.write(',C=1');
    }
    if (quiet > 0) {
      params.write(',q=$quiet');
    }

    return _encodeWithChunking(base64Data, params.toString(), chunkSize);
  }

  /// Deletes a previously displayed image by its [imageId].
  ///
  /// If [imageId] is null, deletes all images.
  /// [quiet] suppresses terminal responses (default 2 = suppress all).
  ///
  /// Returns an escape sequence that performs the deletion.
  static String delete({int? imageId, int quiet = 2}) {
    final params = StringBuffer('a=d');
    if (imageId != null) {
      params.write(',d=I,i=$imageId');
    } else {
      params.write(',d=a');
    }
    if (quiet > 0) {
      params.write(',q=$quiet');
    }
    return '${Ansi.apc}G$params${Ansi.st}';
  }

  /// Deletes all images from the terminal.
  ///
  /// [quiet] suppresses terminal responses (default 2 = suppress all).
  ///
  /// Returns an escape sequence that deletes all images.
  static String deleteAll({int quiet = 2}) => delete(quiet: quiet);

  /// Encode base64 data with chunking according to Kitty protocol rules.
  ///
  /// The first chunk includes all control parameters. Continuation chunks
  /// only carry `m=1` (more data) or `m=0` (final). Each chunk except the
  /// last must be a multiple of 4 bytes in length.
  static String _encodeWithChunking(
    String base64Data,
    String controlParams,
    int chunkSize,
  ) {
    final buffer = StringBuffer();
    int offset = 0;
    bool isFirst = true;

    while (offset < base64Data.length) {
      final remaining = base64Data.length - offset;
      int size = remaining > chunkSize ? chunkSize : remaining;

      // Ensure chunk is a multiple of 4 (except possibly the last).
      if (offset + size < base64Data.length) {
        size = (size ~/ 4) * 4;
        if (size == 0) size = 4; // Ensure progress.
      }

      final chunk = base64Data.substring(offset, offset + size);
      final isLast = (offset + size >= base64Data.length);

      buffer.write(Ansi.apc);
      buffer.write('G');

      if (isFirst) {
        buffer.write(controlParams);
        buffer.write(',');
        isFirst = false;
      }

      buffer.write('m=${isLast ? 0 : 1}');
      buffer.write(';');
      buffer.write(chunk);
      buffer.write(Ansi.st);

      offset += size;
    }

    // Handle empty data case.
    if (base64Data.isEmpty) {
      buffer.write(Ansi.apc);
      buffer.write('G');
      buffer.write(controlParams);
      buffer.write(',m=0;');
      buffer.write(Ansi.st);
    }

    return buffer.toString();
  }
}
