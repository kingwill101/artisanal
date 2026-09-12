import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:pure_ui/pure_ui.dart' as ui;

import '../uv/buffer.dart';
import '../uv/cell.dart';
import '../uv/renderer/renderer.dart';

part 'glyph_mask.dart';
part 'font_validation.dart';

/// A fidelity problem encountered while rasterizing a terminal buffer.
///
/// {@category Ultraviolet}
final class RasterDiagnostic {
  /// Describes an unsupported feature or invalid glyph at a cell location.
  const RasterDiagnostic(this.message, {this.x, this.y, this.code});

  /// Human-readable explanation.
  final String message;

  /// Zero-based terminal column, when applicable.
  final int? x;

  /// Zero-based terminal row, when applicable.
  final int? y;

  /// Machine-readable diagnostic category.
  final String? code;

  @override
  String toString() =>
      '${code ?? 'raster'}: $message'
      '${x == null ? '' : ' (column $x, row $y)'}';
}

/// Static TrueType font faces for native terminal captures.
///
/// Bytes are copied. Fonts need TrueType outlines, a Unicode cmap, and
/// fixed-width printable ASCII metrics. CFF, variable fonts, and color-font
/// tables are not supported. Missing style variants are diagnosed when used;
/// regular faces are never silently substituted.
///
/// {@category Ultraviolet}
final class RasterFont {
  RasterFont._(this._regular, this._bold, this._italic, this._boldItalic);

  /// Parses caller-supplied static TrueType faces without filesystem access.
  factory RasterFont.fromTtf(
    Uint8List regular, {
    Uint8List? bold,
    Uint8List? italic,
    Uint8List? boldItalic,
  }) {
    ui.TtfFont parse(Uint8List source) {
      try {
        final bytes = Uint8List.fromList(source);
        _validateFontDirectory(bytes);
        final font = ui.TtfFont.load(bytes);
        final metrics = font.metrics;
        if (metrics.unitsPerEm < 16 ||
            metrics.unitsPerEm > 16384 ||
            metrics.lineHeightAt(1) <= 0 ||
            !metrics.lineHeightAt(1).isFinite) {
          throw const FormatException('Invalid font metrics');
        }
        final space = font.getGlyphId(32);
        if (space == null || font.getAdvanceWidth(space, 1) <= 0) {
          throw const FormatException('Font needs a positive-width space');
        }
        final advance = font.getAdvanceWidth(space, 1);
        for (var rune = 33; rune <= 126; rune++) {
          final id = font.getGlyphId(rune);
          if (id != null &&
              (font.getAdvanceWidth(id, 1) - advance).abs() > 0.00001) {
            throw const FormatException(
              'Font must have fixed-width ASCII metrics',
            );
          }
        }
        return font;
      } on Exception catch (error) {
        throw ArgumentError('Invalid static monospace TrueType font: $error');
      } on Error catch (error) {
        throw ArgumentError('Invalid static monospace TrueType font: $error');
      }
    }

    final result = RasterFont._(
      parse(regular),
      bold == null ? null : parse(bold),
      italic == null ? null : parse(italic),
      boldItalic == null ? null : parse(boldItalic),
    );
    final reference = result._regular;
    for (final face in [result._bold, result._italic, result._boldItalic]) {
      if (face == null) continue;
      final sameAdvance =
          (face.getAdvanceWidth(face.getGlyphId(32)!, 1) -
                  reference.getAdvanceWidth(reference.getGlyphId(32)!, 1))
              .abs() <
          0.00001;
      final sameBaseline =
          (face.metrics.baselineOffsetAt(1) -
                  reference.metrics.baselineOffsetAt(1))
              .abs() <
          0.00001;
      final sameHeight =
          (face.metrics.lineHeightAt(1) - reference.metrics.lineHeightAt(1))
              .abs() <
          0.00001;
      if (!sameAdvance || !sameBaseline || !sameHeight) {
        throw ArgumentError(
          'Font variants must share the regular face cell metrics',
        );
      }
    }
    return result;
  }

  final ui.TtfFont _regular;
  final ui.TtfFont? _bold;
  final ui.TtfFont? _italic;
  final ui.TtfFont? _boldItalic;
}

/// Pixel geometry, terminal colors, and fidelity policy.
///
/// Glyph coverage uses four samples per axis: deterministic software
/// antialiasing, not platform font hinting or LCD subpixel rendering.
///
/// {@category Ultraviolet}
final class RasterRenderOptions {
  /// Creates a native terminal rendering profile.
  const RasterRenderOptions({
    this.fontSize = 14,
    this.cellWidth,
    this.cellHeight,
    this.padding = 0,
    this.foreground = const UvRgb(204, 204, 204),
    this.background = const UvRgb(0, 0, 0),
    this.palette,
    this.strict = true,
  });

  /// Font size in pixels, between 1 and 256.
  final double fontSize;

  /// Cell width; defaults to the rounded-up regular-face space advance.
  final int? cellWidth;

  /// Cell height; defaults to the rounded-up regular-face line height.
  final int? cellHeight;

  /// Padding on all four image edges, in pixels.
  final int padding;

  /// Default terminal foreground.
  final UvRgb foreground;

  /// Default terminal background and image padding color.
  final UvRgb background;

  /// Optional complete 16- or 256-color terminal palette.
  ///
  /// With 16 entries, higher indexes use the xterm cube and gray ramp.
  /// The renderer takes a detached copy on construction.
  final List<UvRgb>? palette;

  /// Reject captures with fidelity diagnostics rather than approximating them.
  final bool strict;
}

/// Native cell-to-image backend with exact grid placement and explicit fonts.
///
/// Two rendering passes prevent continuation-cell backgrounds from erasing
/// wide glyphs. `pure_ui` parses font outlines; Dart software coverage and
/// `package:image` produce the pixels. No browser, Flutter engine, or native
/// font library is required. No backgrounds are inferred from adjacent cells.
///
/// Blink is captured in its visible phase. Multi-codepoint graphemes, external
/// graphics, and missing glyphs or font variants produce diagnostics.
///
/// {@category Ultraviolet}
final class RasterTerminalRenderer extends TerminalRenderer {
  /// Creates an offscreen renderer with fixed font and color policy.
  RasterTerminalRenderer({
    required this.font,
    this.options = const RasterRenderOptions(),
  }) : _palette = options.palette == null
           ? null
           : List.unmodifiable(options.palette!) {
    _validateOptions();
    _cellWidth =
        options.cellWidth ??
        font._regular
            .getAdvanceWidth(font._regular.getGlyphId(32)!, options.fontSize)
            .ceil();
    _cellHeight =
        options.cellHeight ??
        font._regular.metrics.lineHeightAt(options.fontSize).ceil();
    _baseline = font._regular.metrics
        .baselineOffsetAt(options.fontSize)
        .round();
    if (_cellWidth <= 0 || _cellHeight <= 0) {
      throw ArgumentError('Font metrics produce an empty cell');
    }
  }

  /// Font faces used for glyph coverage.
  final RasterFont font;

  /// Rendering options; palette data is copied internally.
  final RasterRenderOptions options;

  final List<UvRgb>? _palette;
  late final int _cellWidth;
  late final int _cellHeight;
  late final int _baseline;
  int _width = 0;
  int _height = 0;
  img.Image? _image;
  final _diagnostics = <RasterDiagnostic>[];
  final _masks = <(ui.TtfFont, int), _GlyphMask>{};
  int _omittedDiagnostics = 0;

  /// Last rendered pixels, or null before rendering/after a strict failure.
  img.Image? get image => _image;

  /// Actual horizontal cell advance in pixels.
  int get cellWidth => _cellWidth;

  /// Actual vertical cell advance in pixels.
  int get cellHeight => _cellHeight;

  /// Fidelity diagnostics from the last render.
  List<RasterDiagnostic> get diagnostics => List.unmodifiable(_diagnostics);

  @override
  int width() => _width;

  @override
  int height() => _height;

  @override
  void resize(int width, int height) {
    final w = width * _cellWidth + options.padding * 2;
    final h = height * _cellHeight + options.padding * 2;
    if (width <= 0 ||
        height <= 0 ||
        w > 16000 ||
        h > 16000 ||
        w * h > 16000000) {
      throw ArgumentError(
        'Raster viewport must be positive and fit within '
        '16 megapixels and 16000 pixels per axis',
      );
    }
    _width = width;
    _height = height;
    _image = null;
  }

  @override
  void render(Buffer buffer) {
    resize(buffer.width(), buffer.height());
    _diagnostics.clear();
    _omittedDiagnostics = 0;
    final image = img.Image(
      width: _width * _cellWidth + options.padding * 2,
      height: _height * _cellHeight + options.padding * 2,
      numChannels: 4,
    );
    _fill(image, 0, 0, image.width, image.height, options.background);
    for (var y = 0; y < _height; y++) {
      for (var x = 0; x < _width; x++) {
        final style = buffer.cellAt(x, y)?.style ?? const UvStyle();
        _fill(
          image,
          _left(x),
          _top(y),
          _cellWidth,
          _cellHeight,
          _colors(style).$2,
        );
      }
    }
    for (var y = 0; y < _height; y++) {
      for (var x = 0; x < _width; x++) {
        final cell = buffer.cellAt(x, y);
        if (cell == null) continue;
        final style = cell.style;
        if (cell.width < 0 || cell.width > 5) {
          _diagnose(
            'Cell width is outside the supported 0–5 column range',
            x,
            y,
            'invalid-cell-width',
          );
          continue;
        }
        final span = math.min(math.max(1, cell.width), _width - x);
        if ((style.attrs & ~255) != 0) {
          _diagnose(
            'Unsupported attribute bits',
            x,
            y,
            'unsupported-attribute',
          );
        }
        if (cell.drawable != null ||
            cell.diffOption.isSkip ||
            cell.diffOption.isForcedWidth ||
            cell.content.contains('\x1b')) {
          _diagnose(
            'External graphics are not part of a raster cell capture',
            x,
            y,
            'unsupported-cell',
          );
          continue;
        }
        if ((style.attrs & Attr.conceal) != 0 || cell.width == 0) continue;
        final fg = _colors(style).$1;
        if (cell.content.isNotEmpty && cell.content != ' ') {
          final runes = cell.content.runes.toList();
          if (runes.length != 1) {
            _diagnose(
              'Multi-codepoint graphemes require a shaping backend',
              x,
              y,
              'unsupported-grapheme',
            );
          } else {
            final variant = _variant(style.attrs);
            if (variant == null) {
              _diagnose(
                'Requested bold/italic font face was not supplied',
                x,
                y,
                'missing-variant',
              );
            } else {
              final glyph = variant.getGlyphId(runes.single);
              if (glyph == null || glyph == 0) {
                _diagnose(
                  'Font has no glyph for U+${runes.single.toRadixString(16).toUpperCase()}',
                  x,
                  y,
                  'missing-glyph',
                );
              } else {
                final outline = variant.getGlyphOutline(glyph);
                if (outline == null) {
                  _diagnose(
                    'Cannot decode glyph outline',
                    x,
                    y,
                    'invalid-glyph',
                  );
                } else {
                  try {
                    if (_masks.length >= 512) _masks.clear();
                    final mask = _masks.putIfAbsent(
                      (variant, glyph),
                      () => _GlyphMask.rasterize(
                        outline,
                        options.fontSize / variant.metrics.unitsPerEm,
                      ),
                    );
                    _paintMask(
                      image,
                      mask,
                      _left(x),
                      _top(y) + _baseline,
                      span * _cellWidth,
                      _top(y),
                      fg,
                    );
                  } on FormatException catch (error) {
                    _diagnose(error.message, x, y, 'invalid-glyph');
                  }
                }
              }
            }
          }
        }
        _decorations(image, x, y, span, style, fg);
      }
    }
    if (_omittedDiagnostics > 0) {
      _diagnostics.add(
        RasterDiagnostic(
          '$_omittedDiagnostics additional cell diagnostics omitted',
          code: 'diagnostic-limit',
        ),
      );
    }
    if (options.strict && _diagnostics.isNotEmpty) {
      throw StateError(_diagnostics.first.toString());
    }
    _image = image;
  }

  @override
  void flush() {}

  int _left(int x) => options.padding + x * _cellWidth;
  int _top(int y) => options.padding + y * _cellHeight;

  void _validateOptions() {
    if (!options.fontSize.isFinite ||
        options.fontSize < 1 ||
        options.fontSize > 256 ||
        options.padding < 0 ||
        options.padding > 1024 ||
        (options.cellWidth != null &&
            (options.cellWidth! < 1 || options.cellWidth! > 1024)) ||
        (options.cellHeight != null &&
            (options.cellHeight! < 1 || options.cellHeight! > 1024))) {
      throw ArgumentError(
        'Invalid raster font size, padding, or cell dimensions',
      );
    }
    if (_palette != null && _palette.length != 16 && _palette.length != 256) {
      throw ArgumentError('A terminal palette must have 16 or 256 colors');
    }
    for (final c in [options.foreground, options.background, ...?_palette]) {
      _validateRgb(c);
    }
  }

  ui.TtfFont? _variant(int attrs) =>
      switch ((attrs & Attr.bold != 0, attrs & Attr.italic != 0)) {
        (true, true) => font._boldItalic,
        (true, false) => font._bold,
        (false, true) => font._italic,
        _ => font._regular,
      };

  (UvRgb, UvRgb) _colors(UvStyle style) {
    var fg = _color(style.fg, options.foreground);
    var bg = _color(style.bg, options.background);
    if ((style.attrs & Attr.reverse) != 0) (fg, bg) = (bg, fg);
    if ((style.attrs & Attr.faint) != 0) {
      fg = UvRgb(
        ((fg.r + bg.r) / 2).round(),
        ((fg.g + bg.g) / 2).round(),
        ((fg.b + bg.b) / 2).round(),
        a: fg.a,
      );
    }
    return (fg, bg);
  }

  UvRgb _color(UvColor? color, UvRgb fallback) {
    if (color == null) return fallback;
    if (color is UvRgb) {
      _validateRgb(color);
      return color;
    }
    final index = switch (color) {
      UvBasic16 c when c.index >= 0 && c.index <= 7 =>
        c.index + (c.bright ? 8 : 0),
      UvIndexed256 c when c.index >= 0 && c.index <= 255 => c.index,
      _ => throw ArgumentError('Invalid terminal palette color'),
    };
    if (_palette != null && index < _palette.length) return _palette[index];
    if (index < 16) return _ansiPalette[index];
    if (index >= 232) {
      final v = 8 + (index - 232) * 10;
      return UvRgb(v, v, v);
    }
    final n = index - 16;
    int level(int v) => v == 0 ? 0 : 55 + v * 40;
    return UvRgb(level(n ~/ 36), level((n ~/ 6) % 6), level(n % 6));
  }

  void _diagnose(String message, int x, int y, String code) {
    if (_diagnostics.length >= 1024) {
      _omittedDiagnostics++;
    } else {
      _diagnostics.add(RasterDiagnostic(message, x: x, y: y, code: code));
    }
  }

  void _paintMask(
    img.Image image,
    _GlyphMask mask,
    int left,
    int baseline,
    int spanWidth,
    int top,
    UvRgb color,
  ) {
    for (var y = 0; y < mask.height; y++) {
      final py = baseline + mask.top + y;
      if (py < top || py >= top + _cellHeight || py >= image.height) continue;
      for (var x = 0; x < mask.width; x++) {
        final px = left + mask.left + x;
        if (px < left || px >= left + spanWidth || px >= image.width) continue;
        final coverage = mask.alpha[y * mask.width + x];
        if (coverage != 0) _blend(image, px, py, color, coverage / 255);
      }
    }
  }

  void _decorations(
    img.Image image,
    int x,
    int y,
    int span,
    UvStyle style,
    UvRgb fg,
  ) {
    final left = _left(x), top = _top(y);
    final length = span * _cellWidth, bottom = top + _cellHeight - 1;
    final ul = _color(style.underlineColor, fg);
    void pixel(int dx, int dy, UvRgb color) {
      final px = left + dx;
      if (px < image.width && dy >= top && dy <= bottom) {
        _blend(image, px, dy, color, 1);
      }
    }

    for (var i = 0; i < length; i++) {
      switch (style.underline) {
        case UnderlineStyle.none:
          break;
        case UnderlineStyle.single:
          pixel(i, bottom, ul);
        case UnderlineStyle.double:
          pixel(i, bottom, ul);
          pixel(i, bottom - 2, ul);
        case UnderlineStyle.dotted:
          if (i.isEven) pixel(i, bottom, ul);
        case UnderlineStyle.dashed:
          if (i % 6 < 4) pixel(i, bottom, ul);
        case UnderlineStyle.curly:
          pixel(i, bottom - const [0, 1, 2, 1][i % 4], ul);
      }
      if ((style.attrs & Attr.strikethrough) != 0) {
        pixel(i, top + _cellHeight ~/ 2, fg);
      }
    }
  }
}

void _validateRgb(UvRgb c) {
  if ([c.r, c.g, c.b, c.a].any((v) => v < 0 || v > 255)) {
    throw ArgumentError('RGBA components must be between 0 and 255');
  }
}

void _fill(img.Image image, int x, int y, int width, int height, UvRgb color) {
  img.fillRect(
    image,
    x1: x,
    y1: y,
    x2: x + width - 1,
    y2: y + height - 1,
    color: img.ColorRgba8(color.r, color.g, color.b, color.a),
    alphaBlend: false,
  );
}

void _blend(img.Image image, int x, int y, UvRgb color, double coverage) {
  final pixel = image.getPixel(x, y);
  final alpha = coverage * color.a / 255;
  final remaining = pixel.a / 255 * (1 - alpha);
  final outAlpha = alpha + remaining;
  if (outAlpha == 0) return;
  image.setPixelRgba(
    x,
    y,
    ((color.r * alpha + pixel.r * remaining) / outAlpha).round(),
    ((color.g * alpha + pixel.g * remaining) / outAlpha).round(),
    ((color.b * alpha + pixel.b * remaining) / outAlpha).round(),
    (outAlpha * 255).round(),
  );
}

const _ansiPalette = <UvRgb>[
  UvRgb(0, 0, 0),
  UvRgb(128, 0, 0),
  UvRgb(0, 128, 0),
  UvRgb(128, 128, 0),
  UvRgb(0, 0, 128),
  UvRgb(128, 0, 128),
  UvRgb(0, 128, 128),
  UvRgb(192, 192, 192),
  UvRgb(128, 128, 128),
  UvRgb(255, 0, 0),
  UvRgb(0, 255, 0),
  UvRgb(255, 255, 0),
  UvRgb(0, 0, 255),
  UvRgb(255, 0, 255),
  UvRgb(0, 255, 255),
  UvRgb(255, 255, 255),
];
