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

/// A widget that displays an image in the terminal.
///
/// Uses [HalfBlockImageDrawable] for cross-terminal compatibility, rendering
/// images using half-block characters (`▀`) with foreground/background colors.
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
    );
  }
}

/// Internal leaf widget that renders an [ImageData] using [HalfBlockImageDrawable].
class _RawImage extends LeafRenderObjectWidget {
  _RawImage({
    required this.imageData,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });

  final ImageData imageData;
  final int? width;
  final int? height;
  final BoxFit fit;

  @override
  RenderObject createRenderObject() {
    return _RenderImage(
      imageData: imageData,
      targetWidth: width,
      targetHeight: height,
      fit: fit,
    );
  }

  @override
  void updateRenderObject(RenderObject renderObject) {
    final r = renderObject as _RenderImage;
    r
      ..imageData = imageData
      ..targetWidth = width
      ..targetHeight = height
      ..fit = fit;
  }

  @override
  Object view() => _renderImage(imageData, width, height, fit);
}

class _RenderImage extends RenderBox {
  _RenderImage({
    required this.imageData,
    this.targetWidth,
    this.targetHeight,
    required this.fit,
  });

  ImageData imageData;
  int? targetWidth;
  int? targetHeight;
  BoxFit fit;
  String? _lastPaint;

  @override
  void layout(BoxConstraints constraints) {
    super.layout(constraints);
    _lastPaint = _renderImage(imageData, targetWidth, targetHeight, fit);
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

  final drawable = HalfBlockImageDrawable(
    imageData.image,
    columns: cols,
    rows: rows,
  );

  final canvas = Canvas(cols, rows);
  drawable.draw(canvas, canvas.bounds());
  return canvas.render();
}

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
