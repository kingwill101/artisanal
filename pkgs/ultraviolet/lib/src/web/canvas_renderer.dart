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
  int _cols = 0;
  int _rows = 0;
  final String _lastOutput = '';

  /// Measure font metrics so cells are sized correctly.
  void measureFont() {
    context.font = '${fontSize}px $fontFamily';
    final m = context.measureText('M');
    _cellWidth = m.width;
    _cellHeight = fontSize * 1.2;
    _baseline = fontSize * 0.85;
  }

  @override
  int width() => _cols;

  @override
  int height() => _rows;

  double get cellWidth => _cellWidth;
  double get cellHeight => _cellHeight;

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
    final canvasW = _cols * _cellWidth;
    final canvasH = _rows * _cellHeight;

    context.save();

      context.fillStyle = '#000'.toJS;
    context.fillRect(0, 0, canvasW, canvasH);

    for (var y = 0; y < h; y++) {
      final line = buf.line(y);
      if (line == null) continue;

      for (var x = 0; x < w; x++) {
        final cell = line.at(x);
        if (cell == null) continue;

        final c = cell.content;
        final style = cell.style;
        if (style.isZero && (c.isEmpty || c == ' ')) continue;

        final px = x * _cellWidth;
        final py = y * _cellHeight;

        final bg = style.bg;
        final fg = style.fg ?? const UvRgb(204, 204, 204);
        final attrs = style.attrs;
        final isReversed = (attrs & Attr.reverse) != 0;

        final drawBg = isReversed ? fg : bg;
        final drawFg = isReversed ? (bg ?? const UvRgb(0, 0, 0)) : fg;

        if (drawBg != null) {
          context.fillStyle = _colorToCss(drawBg).toJS;
          context.fillRect(px, py, _cellWidth, _cellHeight);
        }

        if (c.isNotEmpty && c != ' ') {
          final isBold = (attrs & Attr.bold) != 0;
          final isItalic = (attrs & Attr.italic) != 0;
          final isFaint = (attrs & Attr.faint) != 0;

          var fontStr = '${fontSize}px $fontFamily';
          if (isItalic) fontStr = 'italic $fontStr';
          if (isBold) fontStr = 'bold $fontStr';
          context.font = fontStr;

          context.fillStyle = _colorToCss(drawFg).toJS;
          if (isFaint) {
            context.globalAlpha = 0.5;
          }
          context.fillText(c, px, py + _baseline);
          if (isFaint) {
            context.globalAlpha = 1.0;
          }

          if (style.underline != UnderlineStyle.none) {
            context.strokeStyle = (style.underlineColor != null
                    ? _colorToCss(style.underlineColor!)
                    : _colorToCss(drawFg)).toJS;
            context.beginPath();
            context.moveTo(px, py + _cellHeight - 1);
            context.lineTo(px + _cellWidth, py + _cellHeight - 1);
            context.stroke();
          }

          if ((attrs & Attr.strikethrough) != 0) {
            context.beginPath();
            context.moveTo(px, py + _cellHeight * 0.45);
            context.lineTo(px + _cellWidth, py + _cellHeight * 0.45);
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
