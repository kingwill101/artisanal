import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// Maximum source and font sizes accepted by the CLI.
const maxCaptureSourceBytes = 16 * 1024 * 1024;
const maxCaptureFontBytes = 32 * 1024 * 1024;

/// Reads a regular file without allowing the stream to grow beyond [limit].
///
/// `stat` follows a symlink, so symlinks to regular files remain supported,
/// while FIFOs and devices are rejected before `openRead` can block.
Future<Uint8List> readBoundedBytes(
  File file,
  int limit,
  String description,
) async {
  RangeError.checkNotNegative(limit, 'limit');
  if ((await file.stat()).type != FileSystemEntityType.file) {
    throw FormatException('$description must be a regular file.');
  }
  final bytes = BytesBuilder(copy: false);
  var length = 0;
  await for (final chunk in file.openRead(0, limit + 1)) {
    length += chunk.length;
    if (length > limit) {
      final size = limit % (1024 * 1024) == 0
          ? '${limit ~/ (1024 * 1024)} MiB'
          : '$limit bytes';
      throw FormatException('$description exceeds the $size limit.');
    }
    bytes.add(chunk);
  }
  return bytes.takeBytes();
}

Future<String> readBoundedString(
  File file,
  int limit,
  String description,
) async {
  return utf8.decode(await readBoundedBytes(file, limit, description));
}
