import 'dart:js_interop';
import 'dart:math' as math;

import 'package:web/web.dart' as web;

import '../uv/buffer.dart';
import '../uv/cell.dart';
import '../uv/cell_paint.dart';
import '../uv/renderer/renderer.dart';

/// Renders a UV [Buffer] to an HTML5 Canvas 2D context.
///
/// Each cell in the buffer is drawn as a filled background rectangle plus
/// a text glyph. Supports foreground/background colors (16-color, 256-color,
/// true color), bold, italic, faint, underline, and strikethrough.
final class CanvasTerminalRenderer extends TerminalRenderer {
  CanvasTerminalRenderer(
    this.context, {
    this.fontSize = 14,
    this.fontFamily = 'monospace',
    UvPaintPolicy? paintPolicy,
  }) : _paintPolicy = paintPolicy ?? UvPaintPolicy();

  final web.CanvasRenderingContext2D context;
  final double fontSize;
  final String fontFamily;
  final UvPaintPolicy _paintPolicy;

  double _cellWidth = 0;
  double _cellHeight = 0;
  double _baseline = 0;
  double _viewportWidth = 0;
  double _viewportHeight = 0;
  double _devicePixelRatio = 1.0;
  int _cols = 0;
  int _rows = 0;
  final String _lastOutput = '';

  /// Measure font metrics so cells are sized correctly.
  void measureFont() {
    context.font = '${fontSize}px $fontFamily';
    final m = context.measureText('M');
    _cellWidth = m.width;
    if (_cellWidth <= 0) _cellWidth = 8;
    _cellWidth = _cellWidth.ceilToDouble();
    _cellHeight = (fontSize * 1.2).ceilToDouble();
    _baseline = (fontSize * 0.85).ceilToDouble();
  }

  @override
  int width() => _cols;

  @override
  int height() => _rows;

  double get cellWidth => _cellWidth;
  double get cellHeight => _cellHeight;

  /// Configures the logical viewport size and backing-store scale.
  void configureViewport({
    required double width,
    required double height,
    double devicePixelRatio = 1.0,
  }) {
    _viewportWidth = width > 0 ? width : 1;
    _viewportHeight = height > 0 ? height : 1;
    _devicePixelRatio = devicePixelRatio > 0 ? devicePixelRatio : 1.0;
  }

  @override
  void resize(int cols, int rows) {
    _cols = cols > 0 ? cols : 1;
    _rows = rows > 0 ? rows : 1;
  }

  @override
  void render(Buffer buf) {
    measureFont();

    final w = math.min(buf.width(), _cols);
    final h = math.min(buf.height(), _rows);
    final scale = _devicePixelRatio;
    final canvasW =
        (_viewportWidth > 0 ? _viewportWidth : _cols * _cellWidth) * scale;
    final canvasH =
        (_viewportHeight > 0 ? _viewportHeight : _rows * _cellHeight) * scale;

    context.save();

    context.imageSmoothingEnabled = false;
    context.textAlign = 'left';
    context.textBaseline = 'alphabetic';
    context.fillStyle = _colorToCss(_paintPolicy.background).toJS;
    context.fillRect(0, 0, canvasW, canvasH);

    _paintBackgroundRuns(buf, w, h, scale);

    for (var y = 0; y < h; y++) {
      final line = buf.line(y);
      if (line == null) continue;

      for (var x = 0; x < w; x++) {
        final cell = line.at(x);
        if (cell == null) continue;

        final c = cell.content;
        final style = cell.style;
        if (style.isZero && (c.isEmpty || c == ' ')) continue;

        final bounds = _cellBounds(x, y, scale);
        final px = bounds.left;
        final py = bounds.top;
        final cellWidth = bounds.right - bounds.left;
        final cellHeight = bounds.bottom - bounds.top;
        final baseline = (py + (_baseline * scale)).roundToDouble();

        final paint = _paintPolicy.resolve(style);
        final fg = paint.foreground;
        final attrs = style.attrs;
        final drawFg = fg;

        if (c.isNotEmpty && c != ' ' && (attrs & Attr.conceal) == 0) {
          final isBold = (attrs & Attr.bold) != 0;
          final isItalic = (attrs & Attr.italic) != 0;
          final alpha = 1.0;
          final drawFgCss = _colorToCss(drawFg);

          if (_paintShapeGlyph(
            c,
            px: px,
            py: py,
            cellWidth: cellWidth,
            cellHeight: cellHeight,
            colorCss: drawFgCss,
            alpha: alpha,
          )) {
            continue;
          }

          var fontStr = '${_scaledFontSize(scale)}px $fontFamily';
          if (isItalic) fontStr = 'italic $fontStr';
          if (isBold) fontStr = 'bold $fontStr';
          context.font = fontStr;

          context.fillStyle = drawFgCss.toJS;
          context.globalAlpha = alpha;
          context.fillText(c, px, baseline);
          if (isBold) {
            final boldOffset = math.min(1.0, math.max(0.5, scale * 0.12));
            context.fillText(c, px + boldOffset, baseline);
          }
          context.globalAlpha = 1.0;

          if (style.underline != UnderlineStyle.none) {
            context.lineWidth = math.max(1.0, scale);
            context.strokeStyle =
                (style.underlineColor != null
                        ? _colorToCss(paint.underlineColor)
                        : _colorToCss(drawFg))
                    .toJS;
            context.beginPath();
            context.moveTo(px, py + cellHeight - scale);
            context.lineTo(px + cellWidth, py + cellHeight - scale);
            context.stroke();
          }

          if ((attrs & Attr.strikethrough) != 0) {
            context.lineWidth = math.max(1.0, scale);
            context.beginPath();
            context.moveTo(px, py + cellHeight * 0.45);
            context.lineTo(px + cellWidth, py + cellHeight * 0.45);
            context.stroke();
          }
        }
      }
    }

    context.restore();
  }

  @override
  void flush() {}

  @override
  String get lastFlushedOutput => _lastOutput;

  ({double left, double top, double right, double bottom}) _cellBounds(
    int x,
    int y,
    double scale,
  ) {
    final left = (x * _cellWidth * scale).roundToDouble();
    final top = (y * _cellHeight * scale).roundToDouble();
    final right = ((x + 1) * _cellWidth * scale).roundToDouble();
    final bottom = ((y + 1) * _cellHeight * scale).roundToDouble();
    return (
      left: left,
      top: top,
      right: math.max(left + 1, right),
      bottom: math.max(top + 1, bottom),
    );
  }

  double _scaledFontSize(double scale) {
    return math.max(1.0, (fontSize * scale).roundToDouble());
  }

  void _paintBackgroundRuns(Buffer buf, int width, int height, double scale) {
    for (var y = 0; y < height; y++) {
      final line = buf.line(y);
      if (line == null) continue;
      String? runColorCss;
      var runStart = 0;
      for (var x = 0; x <= width; x++) {
        final cell = x < width ? line.at(x) : null;
        final colorCss = cell == null
            ? null
            : _colorToCss(_paintPolicy.resolve(cell.style).background);
        if (colorCss == runColorCss) continue;

        if (runColorCss != null) {
          final top = (y * _cellHeight * scale).roundToDouble();
          final bottom = ((y + 1) * _cellHeight * scale).roundToDouble();
          final left = (runStart * _cellWidth * scale).roundToDouble();
          final right = (x * _cellWidth * scale).roundToDouble();
          context.fillStyle = runColorCss.toJS;
          context.fillRect(
            left,
            top,
            math.max(1, right - left).toDouble(),
            math.max(1, bottom - top).toDouble(),
          );
        }

        runColorCss = colorCss;
        runStart = x;
      }
    }
  }

  bool _paintShapeGlyph(
    String content, {
    required double px,
    required double py,
    required double cellWidth,
    required double cellHeight,
    required String colorCss,
    required double alpha,
  }) {
    if (content.length != 1) return false;

    final ch = content;
    final fullBlock = ch == '█';
    final vertical = ch == '│' || ch == '┃';
    if (!fullBlock && !vertical) {
      return false;
    }

    final previousAlpha = context.globalAlpha;
    context.globalAlpha = alpha;
    context.fillStyle = colorCss.toJS;

    if (fullBlock) {
      context.fillRect(px, py, cellWidth, cellHeight);
    } else if (vertical) {
      final factor = ch == '┃' ? 0.24 : 0.14;
      final barWidth = math.max(1.0, (cellWidth * factor).roundToDouble());
      final barX = px + ((cellWidth - barWidth) / 2).floorToDouble();
      context.fillRect(barX, py, barWidth, cellHeight);
    }

    context.globalAlpha = previousAlpha;
    return true;
  }

  String _colorToCss(UvColor color) => switch (color) {
    UvRgb(r: final r, g: final g, b: final b, a: final a) =>
      'rgba($r,$g,$b,${a / 255})',
    UvBasic16(:final index, :final bright) => _basic16(index, bright),
    UvIndexed256(:final index) => _indexed256(index),
  };

  static const _basicColors = [
    '#000000',
    '#cc0000',
    '#00cc00',
    '#cccc00',
    '#0000cc',
    '#cc00cc',
    '#00cccc',
    '#cccccc',
  ];

  static const _brightColors = [
    '#555555',
    '#ff5555',
    '#55ff55',
    '#ffff55',
    '#5555ff',
    '#ff55ff',
    '#55ffff',
    '#ffffff',
  ];

  String _basic16(int index, bool bright) {
    if (index < 0 || index > 7) return '#000000';
    return bright ? _brightColors[index] : _basicColors[index];
  }

  String _indexed256(int index) {
    if (index < 16) {
      if (index < 8) return _basicColors[index];
      return _brightColors[index - 8];
    }
    if (index < 232) {
      final n = index - 16;
      final r = (n ~/ 36) % 6;
      final g = (n ~/ 6) % 6;
      final b = n % 6;
      final rr = r == 0 ? 0 : r * 40 + 55;
      final gg = g == 0 ? 0 : g * 40 + 55;
      final bb = b == 0 ? 0 : b * 40 + 55;
      return 'rgb($rr,$gg,$bb)';
    }
    final gray = (index - 232) * 10 + 8;
    return 'rgb($gray,$gray,$gray)';
  }
}
