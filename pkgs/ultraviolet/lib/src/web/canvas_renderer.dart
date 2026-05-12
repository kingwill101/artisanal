import 'dart:js_interop';
import 'dart:math' as math;

import 'package:web/web.dart' as web;

import '../uv/buffer.dart';
import '../uv/cell.dart';
import '../uv/renderer/renderer.dart';

/// Renders a UV [Buffer] to an HTML5 Canvas 2D context.
///
/// Each cell in the buffer is drawn as a filled background rectangle plus
/// a text glyph. Supports foreground/background colors (16-color, 256-color,
/// true color), bold, italic, faint, underline, and strikethrough.
final class CanvasTerminalRenderer extends TerminalRenderer {
  CanvasTerminalRenderer(this.context,
      {this.fontSize = 14, this.fontFamily = 'monospace'});

  final web.CanvasRenderingContext2D context;
  final double fontSize;
  final String fontFamily;

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
    context.fillStyle = '#000'.toJS;
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

        final bg = style.bg;
        final fg = style.fg ?? const UvRgb(204, 204, 204);
        final attrs = style.attrs;
        final isReversed = (attrs & Attr.reverse) != 0;

        final drawFg = isReversed ? (bg ?? const UvRgb(0, 0, 0)) : fg;

        if (c.isNotEmpty && c != ' ') {
          final isBold = (attrs & Attr.bold) != 0;
          final isItalic = (attrs & Attr.italic) != 0;
          final isFaint = (attrs & Attr.faint) != 0;
          final alpha = isFaint ? 0.7 : 1.0;
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
            context.strokeStyle = (style.underlineColor != null
                    ? _colorToCss(style.underlineColor!)
                    : _colorToCss(drawFg)).toJS;
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
    // Track the dominant (first non-null) background seen on each row so that
    // an entirely-default-background row (e.g. the blank separator line inside
    // a selected queue item) can inherit the colour from its neighbours.
    // We keep a small look-ahead cache: dominant[y] is the first non-null
    // effective background on row y, or null when the row is all-default.
    // dominant[y] = the background CSS of the first non-space cell on row y,
    // or null when the row contains only spaces / empty cells.
    //
    // We deliberately look at non-space cells because:
    //  - Content rows (title, meta, separator lines) have at least one glyph
    //    cell whose bg is explicitly set to the row highlight colour.
    //  - Pure-space padding rows carry only the terminal default background on
    //    every cell; those are the rows that need vertical inheritance.
    //  - Using _cellBackgroundCss (direct, no bridge) avoids picking up the
    //    explicit rgba(10,10,10,1) default that space cells carry, which would
    //    falsely mark a padding row as "has a real colour".
    final dominant = List<String?>.filled(height, null);
    for (var y = 0; y < height; y++) {
      final line = buf.line(y);
      if (line == null) continue;
      for (var x = 0; x < width; x++) {
        final cell = line.at(x);
        if (cell == null) continue;
        if (cell.content == ' ' || cell.content.isEmpty) continue;
        final c = _cellBackgroundCss(cell);
        if (c != null) {
          dominant[y] = c;
          break;
        }
      }
    }

    for (var y = 0; y < height; y++) {
      final line = buf.line(y);
      if (line == null) continue;

      // If this row has no non-default background of its own, check whether
      // the nearest non-empty row above and below agree on a colour. If they
      // do, fill the entire row with that colour so the selected-row highlight
      // covers padding/separator lines that only carry the terminal default bg.
      if (dominant[y] == null) {
        String? above;
        for (var a = y - 1; a >= 0; a--) {
          if (dominant[a] != null) { above = dominant[a]; break; }
        }
        String? below;
        for (var b = y + 1; b < height; b++) {
          if (dominant[b] != null) { below = dominant[b]; break; }
        }
        if (above != null && above == below) {
          final top = (y * _cellHeight * scale).roundToDouble();
          final bottom = ((y + 1) * _cellHeight * scale).roundToDouble();
          final rowW = (width * _cellWidth * scale).roundToDouble();
          context.fillStyle = above.toJS;
          context.fillRect(0, top, math.max(1, rowW).toDouble(),
              math.max(1, bottom - top).toDouble());
          continue; // no per-cell run needed for this row
        }
      }

      String? runColorCss;
      var runStart = 0;
      for (var x = 0; x <= width; x++) {
        final colorCss = x < width
            ? _effectiveCellBackgroundCss(line, x, width)
            : null;
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

  String? _effectiveCellBackgroundCss(Line line, int x, int width) {
    final cell = line.at(x);
    final direct = _cellBackgroundCss(cell);
    if (cell == null || !_isBackgroundBridgeSpace(cell)) {
      return direct;
    }

    var start = x;
    while (start > 0 && _isBackgroundBridgeSpace(line.at(start - 1))) {
      start--;
    }

    var end = x;
    while (end + 1 < width && _isBackgroundBridgeSpace(line.at(end + 1))) {
      end++;
    }

    final left = start > 0 ? _cellBackgroundCss(line.at(start - 1)) : null;
    final right = end + 1 < width ? _cellBackgroundCss(line.at(end + 1)) : null;
    if (left != null && right != null) {
      return left == right ? left : direct;
    }
    return left ?? right ?? direct;
  }

  bool _isBackgroundBridgeSpace(Cell? cell) {
    if (cell == null) return false;
    return cell.content == ' ' && cell.width == 1;
  }

  String? _cellBackgroundCss(Cell? cell) {
    if (cell == null) return null;
    final style = cell.style;
    final fg = style.fg ?? const UvRgb(204, 204, 204);
    final bg = style.bg;
    final isReversed = (style.attrs & Attr.reverse) != 0;
    final drawBg = isReversed ? fg : bg;
    return drawBg == null ? null : _colorToCss(drawBg);
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
    '#000000', '#cc0000', '#00cc00', '#cccc00',
    '#0000cc', '#cc00cc', '#00cccc', '#cccccc',
  ];

  static const _brightColors = [
    '#555555', '#ff5555', '#55ff55', '#ffff55',
    '#5555ff', '#ff55ff', '#55ffff', '#ffffff',
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
