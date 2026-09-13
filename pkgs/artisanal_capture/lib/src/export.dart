import 'dart:convert';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:ultraviolet/raster.dart';

import 'capture.dart';

/// Native image exporter for immutable terminal captures.
///
/// A caller supplies the font and rendering profile explicitly. The same
/// rendered PNG is used by [CaptureImage.toHtml], avoiding a second browser
/// rendering implementation.
///
/// {@category Capture}
final class CaptureRasterizer {
  /// Creates an exporter with a fixed font and render profile.
  const CaptureRasterizer({
    required this.font,
    this.options = const RasterRenderOptions(),
  });

  /// Terminal font faces used to draw glyphs.
  final RasterFont font;

  /// Pixel geometry, terminal colors, and fidelity policy.
  final RasterRenderOptions options;

  /// Renders [capture] through the Ultraviolet raster backend.
  ///
  /// Strict profiles reject unsupported content instead of silently replacing
  /// it. Non-strict profiles return diagnostics alongside their output.
  CaptureImage render(TerminalCapture capture) {
    final buffer = capture.toBuffer();
    try {
      final renderer = RasterTerminalRenderer(font: font, options: options)
        ..resize(capture.columns, capture.rows);
      renderer
        ..render(buffer)
        ..flush();
      final image = renderer.image!;
      return CaptureImage(
        png: Uint8List.fromList(img.encodePng(image)),
        width: image.width,
        height: image.height,
        columns: capture.columns,
        rows: capture.rows,
        diagnostics: renderer.diagnostics
            .map((item) => item.toString())
            .toList(),
      );
    } finally {
      buffer.dispose();
    }
  }
}

/// A rendered PNG and its frame metadata.
///
/// {@category Capture}
final class CaptureImage {
  /// Creates a rendered capture.
  CaptureImage({
    required Uint8List png,
    required this.width,
    required this.height,
    required this.columns,
    required this.rows,
    List<String> diagnostics = const [],
  }) : _png = Uint8List.fromList(png).asUnmodifiableView(),
       diagnostics = List.unmodifiable(diagnostics);

  final Uint8List _png;

  /// Read-only encoded PNG bytes.
  Uint8List get png => _png;

  /// Image width in pixels.
  final int width;

  /// Image height in pixels.
  final int height;

  /// Number of captured terminal columns.
  final int columns;

  /// Number of captured terminal rows.
  final int rows;

  /// Fidelity diagnostics emitted by a non-strict renderer.
  final List<String> diagnostics;

  /// Builds a self-contained, script-free preview of the exact PNG.
  ///
  /// The image retains its native pixel dimensions instead of being scaled to
  /// the browser viewport. No web fonts, JavaScript, or network access is used.
  String toHtml({String title = 'Artisanal capture'}) {
    const escape = HtmlEscape();
    final label = escape.convert(title);
    final warnings = diagnostics.isEmpty
        ? ''
        : '<section aria-label="Fidelity diagnostics"><h2>Diagnostics</h2>'
              '<ul>${diagnostics.map((item) => '<li>${escape.convert(item)}</li>').join()}</ul>'
              '</section>';
    return '''<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta http-equiv="Content-Security-Policy" content="default-src 'none'; img-src data:; style-src 'unsafe-inline'">
<title>$label</title>
<style>
:root { color-scheme: dark; }
body { margin: 0; background: #17191b; color: #e6e8e9; font: 14px/1.5 monospace; }
header, section { padding: 18px 24px; }
header { border-bottom: 1px solid #393d40; }
h1 { margin: 0 0 4px; font-size: 16px; font-weight: 600; }
p { margin: 0; color: #a9afb3; }
main { overflow: auto; padding: 24px; }
img { display: block; max-width: none; }
h2 { font-size: 14px; }
section { color: #f1c878; border-top: 1px solid #393d40; }
</style>
</head>
<body>
<header><h1>$label</h1><p>$columns × $rows cells · $width × $height pixels · native PNG</p></header>
<main><img src="data:image/png;base64,${base64Encode(_png)}" width="$width" height="$height" alt="$label"></main>
$warnings
</body>
</html>
''';
  }
}
