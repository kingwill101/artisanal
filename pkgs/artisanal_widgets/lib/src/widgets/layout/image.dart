part of 'layout_widgets.dart';

/// Data class holding a decoded image.
class ImageData {
  ImageData(this.image);

  /// The decoded image.
  final img.Image image;

  /// Width of the image in pixels.
  int get width => image.width;

  /// Height of the image in pixels.
  int get height => image.height;
}

/// Abstract base class for providing images to the [Image] widget.
///
/// Subclasses must implement [resolve] to asynchronously produce an
/// [ImageData] instance.
abstract class ImageProvider {
  const ImageProvider();

  /// Resolves and returns the image data.
  Future<ImageData> resolve();
}

/// An [ImageProvider] that loads an image from a file path.
///
/// ```dart
/// Image(image: FileImage('/path/to/photo.png'))
/// ```
class FileImage extends ImageProvider {
  const FileImage(this.path);

  /// The file system path to the image.
  final String path;

  @override
  Future<ImageData> resolve() async {
    final bytes = await File(path).readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw Exception('Failed to decode image: $path');
    }
    return ImageData(decoded);
  }
}

/// An [ImageProvider] that loads an image from raw bytes.
///
/// ```dart
/// Image(image: MemoryImage(myPngBytes))
/// ```
class MemoryImage extends ImageProvider {
  const MemoryImage(this.bytes);

  /// The raw image bytes (PNG, JPEG, etc.).
  final Uint8List bytes;

  @override
  Future<ImageData> resolve() async {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw Exception('Failed to decode image from bytes');
    }
    return ImageData(decoded);
  }
}

/// An [ImageProvider] that loads an image from an HTTP(S) URL.
///
/// ```dart
/// Image(image: NetworkImage('https://example.com/photo.png'))
/// ```
class NetworkImage extends ImageProvider {
  const NetworkImage(this.url, {this.headers = const {}});

  /// The URL to fetch.
  final String url;

  /// Optional request headers.
  final Map<String, String> headers;

  @override
  Future<ImageData> resolve() async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(url));
      headers.forEach((name, value) => request.headers.add(name, value));
      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Failed to load image: HTTP ${response.statusCode}');
      }

      final builder = BytesBuilder(copy: false);
      await for (final chunk in response) {
        builder.add(chunk);
      }
      final bytes = builder.takeBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        throw Exception('Failed to decode image: $url');
      }
      return ImageData(decoded);
    } finally {
      client.close(force: true);
    }
  }
}

/// How an image should be inscribed into a box.
enum BoxFit {
  /// Fill the target box by distorting the aspect ratio.
  fill,

  /// As large as possible while fully contained in the box (letterboxed).
  contain,

  /// As small as possible while covering the entire box (cropped).
  cover,

  /// Scale to match the box width, height may overflow or be smaller.
  fitWidth,

  /// Scale to match the box height, width may overflow or be smaller.
  fitHeight,

  /// No scaling; display at natural size.
  none,
}

/// Preferred rendering backend for the [Image] widget.
enum ImageRenderMode {
  /// Pick the best available protocol using UV's terminal capability hints.
  auto,

  /// Force Kitty graphics protocol output.
  kitty,

  /// Force iTerm2 inline image protocol output.
  iterm2,

  /// Force Sixel graphics output.
  sixel,

  /// Force portable half-block / unicode rendering.
  unicodeBlocks,
}

/// A widget that displays an image in the terminal.
///
/// By default, [renderMode] preserves the current half-block rendering path for
/// deterministic output across tests and basic terminals. Set it to
/// [ImageRenderMode.auto] to let UV select the best protocol for the current
/// terminal (Kitty, iTerm2, Sixel, or half-block fallback).
///
/// The [image] parameter provides the image data asynchronously. While loading,
/// [placeholder] is displayed. If loading fails, [errorWidget] is shown.
///
/// ```dart
/// Image(
///   image: FileImage('photo.png'),
///   width: 40,
///   height: 20,
///   fit: BoxFit.contain,
/// )
/// ```
class Image extends StatefulWidget {
  Image({
    required this.image,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.renderMode = ImageRenderMode.unicodeBlocks,
    this.placeholder,
    this.errorWidget,
    super.key,
  });

  /// The image provider that resolves to image data.
  final ImageProvider image;

  /// Desired width in terminal columns. Defaults to image width.
  final int? width;

  /// Desired height in terminal rows. Defaults to half the image height
  /// (since each row encodes 2 pixel rows via half-blocks).
  final int? height;

  /// How the image should be fitted into the available space.
  final BoxFit fit;

  /// Which rendering backend to use for the resolved image.
  final ImageRenderMode renderMode;

  /// Widget to display while the image is loading.
  final Widget? placeholder;

  /// Widget to display if loading fails.
  final Widget? errorWidget;

  @override
  State<Image> createState() => _ImageState();
}

class _ImageState extends State<Image> {
  ImageData? _imageData;
  Object? _error;
  bool _loading = true;

  @override
  Cmd? handleInit() {
    return Cmd(() async {
      try {
        final data = await widget.image.resolve();
        setState(() {
          _imageData = data;
          _loading = false;
        });
      } catch (e) {
        setState(() {
          _error = e;
          _loading = false;
        });
      }
      return null;
    });
  }

  @override
  Cmd? didUpdateWidget(Image oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.image != oldWidget.image) {
      setState(() {
        _imageData = null;
        _error = null;
        _loading = true;
      });
      return handleInit();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return widget.placeholder ?? Text('Loading...');
    }
    if (_error != null || _imageData == null) {
      return widget.errorWidget ?? Text('Error: ${_error ?? "unknown"}');
    }
    return _RawImage(
      imageData: _imageData!,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      renderMode: widget.renderMode,
    );
  }
}

/// Internal leaf widget that renders an [ImageData] using a UV drawable.
class _RawImage extends LeafRenderObjectWidget {
  _RawImage({
    required this.imageData,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.renderMode = ImageRenderMode.unicodeBlocks,
  });

  final ImageData imageData;
  final int? width;
  final int? height;
  final BoxFit fit;
  final ImageRenderMode renderMode;

  @override
  RenderObject createRenderObject() {
    return _RenderImage(
      imageData: imageData,
      targetWidth: width,
      targetHeight: height,
      fit: fit,
      renderMode: renderMode,
    );
  }

  @override
  void updateRenderObject(RenderObject renderObject) {
    final r = renderObject as _RenderImage;
    r
      ..imageData = imageData
      ..targetWidth = width
      ..targetHeight = height
      ..fit = fit
      ..renderMode = renderMode;
  }

  @override
  Object view() => _renderImage(imageData, width, height, fit, renderMode);
}

class _RenderImage extends RenderBox {
  _RenderImage({
    required this.imageData,
    this.targetWidth,
    this.targetHeight,
    required this.fit,
    required this.renderMode,
  });

  ImageData imageData;
  int? targetWidth;
  int? targetHeight;
  BoxFit fit;
  ImageRenderMode renderMode;
  String? _lastPaint;

  @override
  void layout(BoxConstraints constraints) {
    super.layout(constraints);
    _lastPaint = _renderImage(
      imageData,
      targetWidth,
      targetHeight,
      fit,
      renderMode,
    );
    size = constraints.constrain(
      Size(
        Layout.getWidth(_lastPaint!).toDouble(),
        Layout.getHeight(_lastPaint!).toDouble(),
      ),
    );
  }

  @override
  String paint() => _lastPaint ?? '';
}

/// Renders an image to a terminal string using half-block characters.
String _renderImage(
  ImageData imageData,
  int? targetWidth,
  int? targetHeight,
  BoxFit fit,
  ImageRenderMode renderMode,
) {
  final srcW = imageData.width;
  final srcH = imageData.height;

  // Default: 1 column per pixel width, 1 row per 2 pixel rows
  var cols = targetWidth ?? srcW;
  var rows = targetHeight ?? (srcH ~/ 2).clamp(1, srcH);

  // Apply BoxFit scaling
  final scaledSize = _applyBoxFit(fit, srcW, srcH, cols, rows);
  cols = scaledSize.$1;
  rows = scaledSize.$2;

  if (cols <= 0 || rows <= 0) return '';

  final drawable = _resolveDrawable(
    imageData.image,
    columns: cols,
    rows: rows,
    renderMode: renderMode,
  );

  final canvas = Canvas(cols, rows);
  drawable.draw(canvas, canvas.bounds());
  return canvas.render();
}

Drawable _resolveDrawable(
  img.Image image, {
  required int columns,
  required int rows,
  required ImageRenderMode renderMode,
}) {
  return switch (renderMode) {
    ImageRenderMode.auto => _bestDrawableFromCapabilities(
      image,
      columns: columns,
      rows: rows,
    ),
    ImageRenderMode.kitty => KittyImageDrawable(
      image,
      columns: columns,
      rows: rows,
    ),
    ImageRenderMode.iterm2 => ITerm2ImageDrawable(
      image,
      columns: columns,
      rows: rows,
    ),
    ImageRenderMode.sixel => SixelImageDrawable(
      image,
      columns: columns,
      rows: rows,
    ),
    ImageRenderMode.unicodeBlocks => HalfBlockImageDrawable(
      image,
      columns: columns,
      rows: rows,
    ),
  };
}

Drawable _bestDrawableFromCapabilities(
  img.Image image, {
  required int columns,
  required int rows,
}) {
  return switch (_widgetImageCapabilities) {
    TerminalCapabilities(:final hasKittyGraphics) when hasKittyGraphics =>
      KittyImageDrawable(image, columns: columns, rows: rows),
    TerminalCapabilities(:final hasITerm2) when hasITerm2 =>
      ITerm2ImageDrawable(image, columns: columns, rows: rows),
    TerminalCapabilities(:final hasSixel) when hasSixel =>
      SixelImageDrawable(image, columns: columns, rows: rows),
    _ => HalfBlockImageDrawable(image, columns: columns, rows: rows),
  };
}

final TerminalCapabilities _widgetImageCapabilities = TerminalCapabilities(
  env: Platform.environment.entries
      .map((entry) => '${entry.key}=${entry.value}')
      .toList(growable: false),
);

/// Applies [BoxFit] logic, returning (columns, rows).
(int, int) _applyBoxFit(
  BoxFit fit,
  int srcWidth,
  int srcHeight,
  int targetCols,
  int targetRows,
) {
  if (srcWidth <= 0 || srcHeight <= 0) return (targetCols, targetRows);

  // Aspect ratio in terminal space: each row = 2 pixel rows
  final srcCols = srcWidth.toDouble();
  final srcRows = (srcHeight / 2.0);

  switch (fit) {
    case BoxFit.fill:
      return (targetCols, targetRows);
    case BoxFit.contain:
      final scaleX = targetCols / srcCols;
      final scaleY = targetRows / srcRows;
      final scale = math.min(scaleX, scaleY);
      return (
        math.max(1, (srcCols * scale).round()),
        math.max(1, (srcRows * scale).round()),
      );
    case BoxFit.cover:
      final scaleX = targetCols / srcCols;
      final scaleY = targetRows / srcRows;
      final scale = math.max(scaleX, scaleY);
      return (
        math.max(1, (srcCols * scale).round()),
        math.max(1, (srcRows * scale).round()),
      );
    case BoxFit.fitWidth:
      final scale = targetCols / srcCols;
      return (targetCols, math.max(1, (srcRows * scale).round()));
    case BoxFit.fitHeight:
      final scale = targetRows / srcRows;
      return (math.max(1, (srcCols * scale).round()), targetRows);
    case BoxFit.none:
      return (srcCols.round(), srcRows.round().clamp(1, srcHeight));
  }
}
