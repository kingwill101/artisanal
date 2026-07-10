import 'dart:async' as dart_async;
import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;
import 'dart:typed_data' show BytesBuilder, Uint8List;

import 'package:artisanal/tui.dart';
import 'package:artisanal/uv.dart'
    show
        Canvas,
        Drawable,
        TerminalCapabilities,
        KittyImageDrawable,
        ITerm2ImageDrawable,
        SixelImageDrawable,
        HalfBlockImageDrawable;
import 'package:image/image.dart' as img;

import 'package:artisanal/compat.dart';
import '../core/widget.dart';
import '../framework.dart';
import '../render_object.dart';
import 'geometry.dart';
import 'text.dart';

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

int _nextWidgetKittyImageId = 1;

int _allocateWidgetKittyImageId() => _nextWidgetKittyImageId++;

final _imageDataCache = _ImageDataCache(maximumEntries: 64);
final _renderedImageCache = _RenderedImageCache(maximumEntries: 128);

class _ImageDataCache {
  _ImageDataCache({required this.maximumEntries});

  final int maximumEntries;
  final LinkedHashMap<Object, ImageData> _completed = LinkedHashMap();
  final Map<Object, Future<ImageData>> _inFlight =
      <Object, Future<ImageData>>{};

  Future<ImageData> resolve(Object key, Future<ImageData> Function() loader) {
    final completed = _completed.remove(key);
    if (completed != null) {
      _completed[key] = completed;
      return Future<ImageData>.value(completed);
    }

    final inFlight = _inFlight[key];
    if (inFlight != null) {
      return inFlight;
    }

    final future = Future<ImageData>.sync(loader);
    _inFlight[key] = future;
    future.then(
      (data) {
        if (!identical(_inFlight[key], future)) return;
        _inFlight.remove(key);
        _completed[key] = data;
        while (_completed.length > maximumEntries) {
          _completed.remove(_completed.keys.first);
        }
      },
      onError: (Object _, StackTrace _) {
        if (identical(_inFlight[key], future)) {
          _inFlight.remove(key);
        }
      },
    );
    return future;
  }
}

class _RenderedImageCache {
  _RenderedImageCache({required this.maximumEntries});

  final int maximumEntries;
  final LinkedHashMap<_RenderedImageCacheKey, _RenderedImageResult> _completed =
      LinkedHashMap();

  _RenderedImageResult? get(_RenderedImageCacheKey key) {
    final completed = _completed.remove(key);
    if (completed == null) return null;
    _completed[key] = completed;
    return completed;
  }

  void put(_RenderedImageCacheKey key, _RenderedImageResult rendered) {
    _completed.remove(key);
    _completed[key] = rendered;
    while (_completed.length > maximumEntries) {
      _completed.remove(_completed.keys.first);
    }
  }
}

class _NetworkImageCacheKey {
  _NetworkImageCacheKey(
    this.url,
    Map<String, String> headers, {
    required this.maximumBytes,
    required this.decodeFrame,
    required Set<String> allowedContentTypes,
    required Set<String> blockedContentTypes,
  }) : _headers = Map<String, String>.unmodifiable(headers),
       _allowedContentTypes = Set<String>.unmodifiable(allowedContentTypes),
       _blockedContentTypes = Set<String>.unmodifiable(blockedContentTypes);

  final String url;
  final int? maximumBytes;
  final int? decodeFrame;
  final Map<String, String> _headers;
  final Set<String> _allowedContentTypes;
  final Set<String> _blockedContentTypes;

  @override
  bool operator ==(Object other) {
    return other is _NetworkImageCacheKey &&
        other.url == url &&
        other.maximumBytes == maximumBytes &&
        other.decodeFrame == decodeFrame &&
        _stringMapEquals(other._headers, _headers) &&
        _stringSetEquals(other._allowedContentTypes, _allowedContentTypes) &&
        _stringSetEquals(other._blockedContentTypes, _blockedContentTypes);
  }

  @override
  int get hashCode => Object.hash(
    _NetworkImageCacheKey,
    url,
    maximumBytes,
    decodeFrame,
    _stringMapHash(_headers),
    _stringSetHash(_allowedContentTypes),
    _stringSetHash(_blockedContentTypes),
  );
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
  const FileImage(this.path, {this.decodeFrame});

  /// The file system path to the image.
  final String path;

  /// Optional frame index to decode for animated image formats.
  final int? decodeFrame;

  @override
  Future<ImageData> resolve() async {
    final bytes = await File(path).readAsBytes();
    return _decodeImageData(bytes, 'image: $path', frame: decodeFrame);
  }

  @override
  bool operator ==(Object other) =>
      other is FileImage &&
      other.path == path &&
      other.decodeFrame == decodeFrame;

  @override
  int get hashCode => Object.hash(FileImage, path, decodeFrame);
}

/// An [ImageProvider] that loads an image from raw bytes.
///
/// ```dart
/// Image(image: MemoryImage(myPngBytes))
/// ```
class MemoryImage extends ImageProvider {
  const MemoryImage(this.bytes, {this.decodeFrame});

  /// The raw image bytes (PNG, JPEG, etc.).
  final Uint8List bytes;

  /// Optional frame index to decode for animated image formats.
  final int? decodeFrame;

  @override
  Future<ImageData> resolve() async {
    return _decodeImageData(bytes, 'image from bytes', frame: decodeFrame);
  }

  @override
  bool operator ==(Object other) =>
      other is MemoryImage &&
      identical(other.bytes, bytes) &&
      other.decodeFrame == decodeFrame;

  @override
  int get hashCode =>
      Object.hash(MemoryImage, identityHashCode(bytes), decodeFrame);
}

/// An [ImageProvider] that loads an image from an HTTP(S) URL.
///
/// ```dart
/// Image(image: NetworkImage('https://example.com/photo.png'))
/// ```
class NetworkImage extends ImageProvider {
  const NetworkImage(
    this.url, {
    this.headers = const {},
    this.maximumBytes,
    this.decodeFrame,
    this.allowedContentTypes = const <String>{},
    this.blockedContentTypes = const <String>{},
  });

  static const String _defaultUserAgent = 'artisanal-widgets-image/0.1';

  /// The URL to fetch.
  final String url;

  /// Optional request headers.
  final Map<String, String> headers;

  /// Optional maximum response size in bytes.
  ///
  /// When set, responses with a known larger `Content-Length` are rejected
  /// before reading the body. Chunked responses are rejected once the streamed
  /// byte count exceeds this value.
  final int? maximumBytes;

  /// Optional frame index to decode for animated image formats.
  ///
  /// Passing `0` lets callers render an animated GIF/WebP as a static preview
  /// without decoding every frame.
  final int? decodeFrame;

  /// Optional allow-list of MIME types such as `image/png` or `image/*`.
  ///
  /// Empty means any content type is allowed unless it matches
  /// [blockedContentTypes].
  final Set<String> allowedContentTypes;

  /// Optional deny-list of MIME types such as `image/gif`.
  final Set<String> blockedContentTypes;

  @override
  Future<ImageData> resolve() {
    return _imageDataCache.resolve(
      _NetworkImageCacheKey(
        url,
        headers,
        maximumBytes: maximumBytes,
        decodeFrame: decodeFrame,
        allowedContentTypes: allowedContentTypes,
        blockedContentTypes: blockedContentTypes,
      ),
      _load,
    );
  }

  Future<ImageData> _load() async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(url));
      if (!_containsHeader(HttpHeaders.userAgentHeader)) {
        request.headers.set(HttpHeaders.userAgentHeader, _defaultUserAgent);
      }
      if (!_containsHeader(HttpHeaders.acceptHeader)) {
        request.headers.set(HttpHeaders.acceptHeader, 'image/*,*/*;q=0.8');
      }
      headers.forEach((name, value) => request.headers.set(name, value));
      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Failed to load image: HTTP ${response.statusCode}');
      }

      final contentType = response.headers.contentType?.mimeType?.toLowerCase();
      _checkContentType(contentType);
      final maximumBytes = this.maximumBytes;
      final contentLength = response.contentLength;
      if (maximumBytes != null &&
          contentLength >= 0 &&
          contentLength > maximumBytes) {
        throw Exception(
          'Image response is too large: $contentLength bytes '
          '(limit $maximumBytes)',
        );
      }

      final builder = BytesBuilder(copy: false);
      var receivedBytes = 0;
      await for (final chunk in response) {
        receivedBytes += chunk.length;
        if (maximumBytes != null && receivedBytes > maximumBytes) {
          throw Exception(
            'Image response is too large: $receivedBytes bytes '
            '(limit $maximumBytes)',
          );
        }
        builder.add(chunk);
      }
      final bytes = builder.takeBytes();
      return _decodeImageData(bytes, 'image: $url', frame: decodeFrame);
    } finally {
      client.close(force: true);
    }
  }

  bool _containsHeader(String name) {
    final lowerName = name.toLowerCase();
    return headers.keys.any((header) => header.toLowerCase() == lowerName);
  }

  void _checkContentType(String? contentType) {
    if (contentType == null || contentType.isEmpty) return;
    if (_matchesContentType(blockedContentTypes, contentType)) {
      throw Exception('Image content type is blocked: $contentType');
    }
    if (allowedContentTypes.isNotEmpty &&
        !_matchesContentType(allowedContentTypes, contentType)) {
      throw Exception('Image content type is not allowed: $contentType');
    }
  }

  @override
  bool operator ==(Object other) {
    return other is NetworkImage &&
        other.url == url &&
        other.maximumBytes == maximumBytes &&
        other.decodeFrame == decodeFrame &&
        _stringMapEquals(other.headers, headers) &&
        _stringSetEquals(other.allowedContentTypes, allowedContentTypes) &&
        _stringSetEquals(other.blockedContentTypes, blockedContentTypes);
  }

  @override
  int get hashCode => Object.hash(
    NetworkImage,
    url,
    maximumBytes,
    decodeFrame,
    _stringMapHash(headers),
    _stringSetHash(allowedContentTypes),
    _stringSetHash(blockedContentTypes),
  );
}

Future<ImageData> _decodeImageData(
  Uint8List bytes,
  String source, {
  int? frame,
}) async {
  final decoded = await Isolate.run(() => img.decodeImage(bytes, frame: frame));
  if (decoded == null) {
    throw Exception('Failed to decode $source');
  }
  return ImageData(decoded);
}

bool _stringMapEquals(Map<String, String> a, Map<String, String> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (!b.containsKey(entry.key) || b[entry.key] != entry.value) {
      return false;
    }
  }
  return true;
}

int _stringMapHash(Map<String, String> map) {
  var hash = Object.hash('StringMap', map.length);
  final keys = map.keys.toList()..sort();
  for (final key in keys) {
    hash = Object.hash(hash, key, map[key]);
  }
  return hash;
}

bool _stringSetEquals(Set<String> a, Set<String> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (final value in a) {
    if (!b.contains(value)) return false;
  }
  return true;
}

int _stringSetHash(Set<String> set) {
  var hash = Object.hash('StringSet', set.length);
  final values = set.toList()..sort();
  for (final value in values) {
    hash = Object.hash(hash, value);
  }
  return hash;
}

bool _matchesContentType(Set<String> filters, String contentType) {
  final normalizedContentType = _normalizeContentType(contentType);
  for (final filter in filters) {
    final normalizedFilter = _normalizeContentType(filter);
    if (normalizedFilter.isEmpty) continue;
    if (normalizedFilter.endsWith('/*')) {
      final prefix = normalizedFilter.substring(0, normalizedFilter.length - 1);
      if (normalizedContentType.startsWith(prefix)) return true;
    } else if (normalizedContentType == normalizedFilter) {
      return true;
    }
  }
  return false;
}

String _normalizeContentType(String value) {
  return value.split(';').first.trim().toLowerCase();
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

/// Controls how [ImageRenderMode.auto] chooses a rendering backend.
enum ImageAutoMode {
  /// Use UV terminal capability hints derived from the local environment.
  environment,

  /// Use capability hints reported by the active terminal session.
  ///
  /// This is useful for embedded, socket, or browser-backed hosts that can
  /// forward device/version reports from the actual remote client instead of
  /// relying on the server process environment.
  sessionCapabilities,

  /// Force the portable half-block fallback for remote or embedded hosts.
  portableFallback,
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
  final int _kittyImageId = _allocateWidgetKittyImageId();
  ImageData? _imageData;
  Object? _error;
  bool _loading = true;
  int _resolveGeneration = 0;
  Future<void>? _resolveFuture;

  @override
  void initState() {
    super.initState();
    _resolveImage(reset: false);
  }

  @override
  Cmd? handleInit() => _repaintWhenResolved();

  Cmd _repaintWhenResolved() {
    final future = _resolveFuture;
    return Cmd(() async {
      if (future != null) {
        await future;
      }
      return await Cmd.repaint(force: false).execute();
    });
  }

  @override
  Cmd? didUpdateWidget(Image oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.image != oldWidget.image) {
      _resolveImage(reset: true);
      return _repaintWhenResolved();
    }
    return null;
  }

  void _resolveImage({required bool reset}) {
    final image = widget.image;
    final generation = ++_resolveGeneration;
    if (reset) {
      setState(() {
        _imageData = null;
        _error = null;
        _loading = true;
      });
    }
    _resolveFuture = () async {
      try {
        final data = await image.resolve();
        if (!mounted || generation != _resolveGeneration) return;
        setState(() {
          _imageData = data;
          _error = null;
          _loading = false;
        });
      } catch (e) {
        if (!mounted || generation != _resolveGeneration) return;
        setState(() {
          _imageData = null;
          _error = e;
          _loading = false;
        });
      }
    }();
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
      kittyImageId: _kittyImageId,
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
    this.kittyImageId,
  });

  final ImageData imageData;
  final int? width;
  final int? height;
  final BoxFit fit;
  final ImageRenderMode renderMode;
  final int? kittyImageId;

  @override
  RenderObject createRenderObject() {
    return _RenderImage(
      imageData: imageData,
      targetWidth: width,
      targetHeight: height,
      fit: fit,
      renderMode: renderMode,
      kittyImageId: kittyImageId,
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
      ..renderMode = renderMode
      ..kittyImageId = kittyImageId;
  }

  @override
  Object view() => _renderImage(
    imageData,
    width,
    height,
    fit,
    renderMode,
    kittyImageId: kittyImageId,
  );
}

class _RenderImage extends RenderBox {
  _RenderImage({
    required this.imageData,
    this.targetWidth,
    this.targetHeight,
    required this.fit,
    required this.renderMode,
    this.kittyImageId,
  });

  ImageData imageData;
  int? targetWidth;
  int? targetHeight;
  BoxFit fit;
  ImageRenderMode renderMode;
  int? kittyImageId;
  _RenderedImageCacheKey? _lastRenderedKey;
  _RenderedImageResult? _lastRendered;

  @override
  void layout(BoxConstraints constraints) {
    super.layout(constraints);
    final rendered = _resolveRenderedImage();
    final imageSize = rendered.size;
    size = constraints.constrain(
      Size(imageSize.$1.toDouble(), imageSize.$2.toDouble()),
    );
  }

  @override
  String paint() => _resolveRenderedImage().text;

  _RenderedImageResult _resolveRenderedImage() {
    final key = _RenderedImageCacheKey.capture(
      imageData: imageData,
      targetWidth: targetWidth,
      targetHeight: targetHeight,
      fit: fit,
      renderMode: renderMode,
      kittyImageId: kittyImageId,
    );
    final rendered = _lastRendered;
    if (rendered != null && _lastRenderedKey == key) {
      return rendered;
    }

    final nextRendered = _renderImageResult(
      imageData,
      targetWidth,
      targetHeight,
      fit,
      renderMode,
      kittyImageId: kittyImageId,
      cacheKey: key,
    );
    _lastRenderedKey = key;
    _lastRendered = nextRendered;
    return nextRendered;
  }
}

final class _RenderedImageResult {
  const _RenderedImageResult({required this.text, required this.size});

  final String text;
  final (int, int) size;
}

final class _RenderedImageCacheKey {
  _RenderedImageCacheKey({
    required this.imageData,
    required this.targetWidth,
    required this.targetHeight,
    required this.fit,
    required this.renderMode,
    required this.kittyImageId,
    required this.autoMode,
    required this.hasKittyGraphics,
    required this.hasITerm2,
    required this.hasSixel,
    required this.cellPixelWidth,
    required this.cellPixelHeight,
    required this.hasConfiguredCellPixelSize,
  });

  factory _RenderedImageCacheKey.capture({
    required ImageData imageData,
    required int? targetWidth,
    required int? targetHeight,
    required BoxFit fit,
    required ImageRenderMode renderMode,
    required int? kittyImageId,
  }) {
    final autoMode = _currentImageAutoMode;
    final capabilities = _currentImageCapabilities;
    return _RenderedImageCacheKey(
      imageData: imageData,
      targetWidth: targetWidth,
      targetHeight: targetHeight,
      fit: fit,
      renderMode: renderMode,
      kittyImageId:
          _renderedImageUsesKittyId(
            renderMode: renderMode,
            autoMode: autoMode,
            capabilities: capabilities,
          )
          ? kittyImageId
          : null,
      autoMode: autoMode,
      hasKittyGraphics: capabilities.hasKittyGraphics,
      hasITerm2: capabilities.hasITerm2,
      hasSixel: capabilities.hasSixel,
      cellPixelWidth: _currentImageCellPixelWidth,
      cellPixelHeight: _currentImageCellPixelHeight,
      hasConfiguredCellPixelSize: _hasConfiguredImageCellPixelSize,
    );
  }

  final ImageData imageData;
  final int? targetWidth;
  final int? targetHeight;
  final BoxFit fit;
  final ImageRenderMode renderMode;
  final int? kittyImageId;
  final ImageAutoMode autoMode;
  final bool hasKittyGraphics;
  final bool hasITerm2;
  final bool hasSixel;
  final int cellPixelWidth;
  final int cellPixelHeight;
  final bool hasConfiguredCellPixelSize;

  @override
  bool operator ==(Object other) {
    return other is _RenderedImageCacheKey &&
        identical(other.imageData, imageData) &&
        other.targetWidth == targetWidth &&
        other.targetHeight == targetHeight &&
        other.fit == fit &&
        other.renderMode == renderMode &&
        other.kittyImageId == kittyImageId &&
        other.autoMode == autoMode &&
        other.hasKittyGraphics == hasKittyGraphics &&
        other.hasITerm2 == hasITerm2 &&
        other.hasSixel == hasSixel &&
        other.cellPixelWidth == cellPixelWidth &&
        other.cellPixelHeight == cellPixelHeight &&
        other.hasConfiguredCellPixelSize == hasConfiguredCellPixelSize;
  }

  @override
  int get hashCode => Object.hash(
    identityHashCode(imageData),
    targetWidth,
    targetHeight,
    fit,
    renderMode,
    kittyImageId,
    autoMode,
    hasKittyGraphics,
    hasITerm2,
    hasSixel,
    cellPixelWidth,
    cellPixelHeight,
    hasConfiguredCellPixelSize,
  );
}

bool _renderedImageUsesKittyId({
  required ImageRenderMode renderMode,
  required ImageAutoMode autoMode,
  required TerminalCapabilities capabilities,
}) {
  return switch (renderMode) {
    ImageRenderMode.kitty => true,
    ImageRenderMode.auto => switch (autoMode) {
      ImageAutoMode.portableFallback => false,
      ImageAutoMode.environment => _widgetImageCapabilities.hasKittyGraphics,
      ImageAutoMode.sessionCapabilities => capabilities.hasKittyGraphics,
    },
    _ => false,
  };
}

/// Renders an image to a terminal string using half-block characters.
String _renderImage(
  ImageData imageData,
  int? targetWidth,
  int? targetHeight,
  BoxFit fit,
  ImageRenderMode renderMode, {
  int? kittyImageId,
}) => _renderImageResult(
  imageData,
  targetWidth,
  targetHeight,
  fit,
  renderMode,
  kittyImageId: kittyImageId,
).text;

_RenderedImageResult _renderImageResult(
  ImageData imageData,
  int? targetWidth,
  int? targetHeight,
  BoxFit fit,
  ImageRenderMode renderMode, {
  int? kittyImageId,
  _RenderedImageCacheKey? cacheKey,
}) {
  final key =
      cacheKey ??
      _RenderedImageCacheKey.capture(
        imageData: imageData,
        targetWidth: targetWidth,
        targetHeight: targetHeight,
        fit: fit,
        renderMode: renderMode,
        kittyImageId: kittyImageId,
      );
  final cached = _renderedImageCache.get(key);
  if (cached != null) return cached;

  final (cols, rows) = _resolveImageCellSize(
    imageData,
    targetWidth,
    targetHeight,
    fit,
    renderMode,
  );
  if (cols <= 0 || rows <= 0) {
    return const _RenderedImageResult(text: '', size: (0, 0));
  }

  final drawable = _resolveDrawable(
    imageData.image,
    columns: cols,
    rows: rows,
    renderMode: renderMode,
    kittyImageId: kittyImageId,
  );
  final canvas = Canvas(cols, rows);
  drawable.draw(canvas, canvas.bounds());
  final rendered = _RenderedImageResult(
    text: _normalizeRenderedImage(
      canvas.render(),
      columns: cols,
      renderMode: renderMode,
    ),
    size: (cols, rows),
  );
  _renderedImageCache.put(key, rendered);
  return rendered;
}

String _normalizeRenderedImage(
  String rendered, {
  required int columns,
  required ImageRenderMode renderMode,
}) {
  if (rendered.isEmpty || columns <= 1) return rendered;

  return switch (renderMode) {
    ImageRenderMode.sixel => _padTopRowRemainder(
      rendered,
      extraColumns: columns - 1,
    ),
    _ => rendered,
  };
}

String _padTopRowRemainder(String rendered, {required int extraColumns}) {
  if (extraColumns <= 0) return rendered;
  final lines = rendered.split('\n');
  if (lines.isEmpty) return rendered;
  lines[0] = '${lines[0]}${' ' * extraColumns}';
  return lines.join('\n');
}

(int, int) _resolveImageCellSize(
  ImageData imageData,
  int? targetWidth,
  int? targetHeight,
  BoxFit fit,
  ImageRenderMode renderMode,
) {
  final srcW = imageData.width;
  final srcH = imageData.height;

  // Default: 1 column per pixel width, 1 row per 2 pixel rows.
  var cols = targetWidth ?? srcW;
  var rows = targetHeight ?? (srcH ~/ 2).clamp(1, srcH);

  return _applyBoxFit(fit, srcW, srcH, cols, rows);
}

Drawable _resolveDrawable(
  img.Image image, {
  required int columns,
  required int rows,
  required ImageRenderMode renderMode,
  int? kittyImageId,
}) {
  return switch (renderMode) {
    ImageRenderMode.auto => _bestDrawableFromCapabilities(
      image,
      columns: columns,
      rows: rows,
      kittyImageId: kittyImageId,
    ),
    ImageRenderMode.kitty => KittyImageDrawable(
      image,
      id: kittyImageId,
      columns: columns,
      rows: rows,
      clearBeforeDraw: kittyImageId != null,
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
      cellPixelWidth: _currentImageCellPixelWidth,
      cellPixelHeight: _currentImageCellPixelHeight,
      allowUpscale: _hasConfiguredImageCellPixelSize,
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
  int? kittyImageId,
}) {
  return switch (_currentImageAutoMode) {
    ImageAutoMode.portableFallback => HalfBlockImageDrawable(
      image,
      columns: columns,
      rows: rows,
    ),
    ImageAutoMode.environment => switch (_widgetImageCapabilities) {
      TerminalCapabilities(:final hasKittyGraphics) when hasKittyGraphics =>
        KittyImageDrawable(
          image,
          id: kittyImageId,
          columns: columns,
          rows: rows,
          clearBeforeDraw: kittyImageId != null,
        ),
      TerminalCapabilities(:final hasITerm2) when hasITerm2 =>
        ITerm2ImageDrawable(image, columns: columns, rows: rows),
      TerminalCapabilities(:final hasSixel) when hasSixel => SixelImageDrawable(
        image,
        columns: columns,
        rows: rows,
        cellPixelWidth: _currentImageCellPixelWidth,
        cellPixelHeight: _currentImageCellPixelHeight,
        allowUpscale: _hasConfiguredImageCellPixelSize,
      ),
      _ => HalfBlockImageDrawable(image, columns: columns, rows: rows),
    },
    ImageAutoMode.sessionCapabilities => switch (_currentImageCapabilities) {
      TerminalCapabilities(:final hasKittyGraphics) when hasKittyGraphics =>
        KittyImageDrawable(
          image,
          id: kittyImageId,
          columns: columns,
          rows: rows,
          clearBeforeDraw: kittyImageId != null,
        ),
      TerminalCapabilities(:final hasITerm2) when hasITerm2 =>
        ITerm2ImageDrawable(image, columns: columns, rows: rows),
      TerminalCapabilities(:final hasSixel) when hasSixel => SixelImageDrawable(
        image,
        columns: columns,
        rows: rows,
        cellPixelWidth: _currentImageCellPixelWidth,
        cellPixelHeight: _currentImageCellPixelHeight,
        allowUpscale: _hasConfiguredImageCellPixelSize,
      ),
      _ => HalfBlockImageDrawable(image, columns: columns, rows: rows),
    },
  };
}

T withImageAutoMode<T>(ImageAutoMode mode, T Function() callback) {
  return withImageAutoConfiguration(mode: mode, callback: callback);
}

T withImageAutoConfiguration<T>({
  required ImageAutoMode mode,
  TerminalCapabilities? capabilities,
  int? cellPixelWidth,
  int? cellPixelHeight,
  required T Function() callback,
}) {
  final sameMode = _currentImageAutoMode == mode;
  final sameCapabilities =
      capabilities == null ||
      identical(_currentImageCapabilities, capabilities);
  final sameCellPixelWidth =
      cellPixelWidth == null || cellPixelWidth == _currentImageCellPixelWidth;
  final sameCellPixelHeight =
      cellPixelHeight == null ||
      cellPixelHeight == _currentImageCellPixelHeight;
  if (sameMode &&
      sameCapabilities &&
      sameCellPixelWidth &&
      sameCellPixelHeight) {
    return callback();
  }
  return dart_async.runZoned(
    callback,
    zoneValues: <Object?, Object?>{
      _imageAutoModeZoneKey: mode,
      _imageCapabilitiesZoneKey: ?capabilities,
      ?_imageCellPixelWidthZoneKey: cellPixelWidth,
      ?_imageCellPixelHeightZoneKey: cellPixelHeight,
    },
  );
}

TerminalCapabilities get _currentImageCapabilities =>
    dart_async.Zone.current[_imageCapabilitiesZoneKey]
        as TerminalCapabilities? ??
    _widgetImageCapabilities;

const Symbol _imageCapabilitiesZoneKey = #artisanal_widgets_imageCapabilities;
const Symbol _imageCellPixelWidthZoneKey =
    #artisanal_widgets_imageCellPixelWidth;
const Symbol _imageCellPixelHeightZoneKey =
    #artisanal_widgets_imageCellPixelHeight;

int get _currentImageCellPixelWidth =>
    dart_async.Zone.current[_imageCellPixelWidthZoneKey] as int? ?? 8;

int get _currentImageCellPixelHeight =>
    dart_async.Zone.current[_imageCellPixelHeightZoneKey] as int? ?? 16;

bool get _hasConfiguredImageCellPixelSize =>
    dart_async.Zone.current[_imageCellPixelWidthZoneKey] is int &&
    dart_async.Zone.current[_imageCellPixelHeightZoneKey] is int;

T withImageAutoCapabilities<T>(
  TerminalCapabilities capabilities,
  T Function() callback,
) {
  return withImageAutoConfiguration(
    mode: _currentImageAutoMode,
    capabilities: capabilities,
    callback: callback,
  );
}

ImageAutoMode get _currentImageAutoMode =>
    dart_async.Zone.current[_imageAutoModeZoneKey] as ImageAutoMode? ??
    ImageAutoMode.environment;

const Symbol _imageAutoModeZoneKey = #artisanal_widgets_imageAutoMode;

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
