import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:pure_svg/svg.dart' show SvgStringLoader, renderSvgToPng;

import '../../style/color.dart';
import '../../style/style.dart';
import '../../terminal/kitty.dart';
import '../../terminal/iterm2.dart';
import '../../terminal/sixel.dart';

/// Terminal image protocol for rendering images inline.
enum ImageProtocol {
  /// Kitty Graphics Protocol — fastest, PNG-compressed native protocol.
  kitty,

  /// iTerm2 Image Protocol — used by iTerm2 on macOS.
  iterm2,

  /// Sixel graphics — used by xterm, mlterm, foot, WezTerm, etc.
  sixel,

  /// Half-block characters (▀) with true-color ANSI escapes.
  ///
  /// Works in any terminal that supports 24-bit color — no special
  /// graphics protocol required. Each cell renders two vertical pixels
  /// using foreground (top) and background (bottom) colors.
  halfblock,

  /// No image protocol — fall back to text placeholder.
  none,
}

/// Auto-detect the best available terminal image protocol.
ImageProtocol detectImageProtocol() {
  final termProgram = Platform.environment['TERM_PROGRAM'] ?? '';
  final term = Platform.environment['TERM'] ?? '';
  final termEmulator = Platform.environment['TERMINAL_EMULATOR'] ?? '';
  final kittyWindowId = Platform.environment['KITTY_WINDOW_ID'] ?? '';

  if (kittyWindowId.isNotEmpty || termProgram == 'Kitty') {
    return ImageProtocol.kitty;
  }
  if (termProgram == 'iTerm.app' || termProgram == 'iTerm2') {
    return ImageProtocol.iterm2;
  }
  if (term.contains('sixel') ||
      term.contains('foot') ||
      term.contains('mlterm')) {
    return ImageProtocol.sixel;
  }
  if (termProgram == 'WezTerm') {
    return ImageProtocol.sixel;
  }
  if (termProgram == 'ghostty') {
    // Ghostty natively supports the Kitty graphics protocol (AOT,
    // PNG-compressed). Sixel support is limited/experimental.
    return ImageProtocol.kitty;
  }
  if (termProgram == 'vscode' || termEmulator == 'vscode') {
    return ImageProtocol.sixel;
  }
  if (termProgram == 'Windows Terminal' ||
      Platform.environment.containsKey('WT_SESSION')) {
    return ImageProtocol.sixel;
  }
  // Fall back to none — _renderTerminalImage will try Kitty anyway.
  return ImageProtocol.none;
}

/// Downloads an image from a URL and returns decoded [img.Image] and the MIME type.
///
/// Returns `null` if the image could not be downloaded or decoded.
Future<(img.Image image, String mimeType)?> downloadImage(String url) async {
  try {
    final uri = Uri.parse(url);
    final client = HttpClient();
    final request = await client.getUrl(uri);
    final response = await request.close();

    if (response.statusCode != 200) {
      client.close();
      return null;
    }

    final bytes = await response.fold<Uint8List>(
      Uint8List(0),
      (prev, chunk) {
        final combined = Uint8List(prev.length + chunk.length);
        combined.setRange(0, prev.length, prev);
        combined.setRange(prev.length, combined.length, chunk);
        return combined;
      },
    );
    client.close();

    final mimeType = response.headers.value('content-type') ?? '';

    // Check for SVG
    if (mimeType.contains('svg') || url.toLowerCase().endsWith('.svg')) {
      final svgContent = utf8.decode(bytes);
      final loader = SvgStringLoader(svgContent);
      final pngBytes = await renderSvgToPng(loader, width: 200, height: 200);
      if (pngBytes.isEmpty) return null;
      final image = img.decodeImage(pngBytes);
      if (image == null) return null;
      return (image, mimeType);
    }

    final image = img.decodeImage(bytes);
    if (image == null) return null;

    return (image, mimeType);
  } catch (_) {
    return null;
  }
}

/// Converts an SVG string to a raster [img.Image] using pure_svg.
Future<img.Image?> svgToImage(String svgContent, {int width = 200, int height = 200}) async {
  try {
    final loader = SvgStringLoader(svgContent);
    final pngBytes = await renderSvgToPng(loader, width: width, height: height);
    if (pngBytes.isEmpty) return null;
    return img.decodeImage(pngBytes);
  } catch (_) {
    return null;
  }
}

/// Determines the approximate cell dimensions for displaying an image.
(int columns, int rows) imageCellDimensions(img.Image image,
    {int? maxColumns, int? maxRows}) {
  // Assume a cell is roughly 2:1 pixel ratio (e.g., 8×18 font).
  const double cellAspect = 0.45; // width/height per cell
  final imageAspect = image.width / image.height;
  var columns = (image.height * cellAspect * imageAspect).ceil();
  var rows = image.height ~/ 18 + 1; // ~18px per row

  if (maxColumns != null && columns > maxColumns) {
    final scale = maxColumns / columns;
    columns = maxColumns;
    rows = (rows * scale).ceil();
  }
  if (maxRows != null && rows > maxRows) {
    final scale = maxRows / rows;
    rows = maxRows;
    columns = (columns * scale).ceil();
  }

  return (columns.clamp(1, 200), rows.clamp(1, 100));
}

/// Renders an image to ANSI terminal escape sequences using the best available
/// image protocol.
///
/// Returns the escape sequence string, or `null` if rendering failed.
String? renderImageToAnsi(img.Image image, ImageProtocol protocol,
    {int? columns, int? rows}) {
  switch (protocol) {
    case ImageProtocol.kitty:
      return KittyImage.encode(image, columns: columns, rows: rows);
    case ImageProtocol.iterm2:
      return ITerm2Image.encode(image, columns: columns, rows: rows);
    case ImageProtocol.sixel:
      return SixelImage.encode(image);
    case ImageProtocol.halfblock:
      return _renderHalfBlock(image, columns: columns ?? 40, rows: rows ?? 20);
    case ImageProtocol.none:
      return null;
  }
}

/// Renders an image using Unicode half-block characters (▀) with true-color
/// ANSI styles. Works in any terminal that supports 24-bit color — no
/// special graphics protocol required.
///
/// Each character cell represents two vertical pixels:
///   foreground = top pixel, background = bottom pixel
String _renderHalfBlock(img.Image image, {int columns = 40, int rows = 20}) {
  final resized = img.copyResize(
    image,
    width: columns,
    height: rows * 2,
    interpolation: img.Interpolation.average,
  );

  String rgb(int r, int g, int b) =>
      '#${r.toRadixString(16).padLeft(2, '0')}'
      '${g.toRadixString(16).padLeft(2, '0')}'
      '${b.toRadixString(16).padLeft(2, '0')}';

  final buffer = StringBuffer();
  for (var y = 0; y < rows; y++) {
    for (var x = 0; x < columns; x++) {
      final top = resized.getPixel(x, y * 2);
      final bot = resized.getPixel(x, y * 2 + 1);
      final cell = Style()
          .foreground(Color.complete(trueColor: rgb(top.r.toInt(), top.g.toInt(), top.b.toInt())))
          .background(Color.complete(trueColor: rgb(bot.r.toInt(), bot.g.toInt(), bot.b.toInt())))
          .render('▀');
      buffer.write(cell);
    }
    buffer.write('\n');
  }
  return buffer.toString();
}

/// Downloads and renders an image from a URL, returning escape sequences or null.
Future<String?> downloadAndRenderImage(
  String url, {
  required ImageProtocol protocol,
  int? maxColumns,
  int? maxRows,
}) async {
  final result = await downloadImage(url);
  if (result == null) return null;

  final (image, _) = result;
  final (cols, rows) =
      imageCellDimensions(image, maxColumns: maxColumns, maxRows: maxRows);
  return renderImageToAnsi(image, protocol, columns: cols, rows: rows);
}
