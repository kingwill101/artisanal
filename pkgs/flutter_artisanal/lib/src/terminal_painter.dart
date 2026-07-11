import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:ultraviolet/ultraviolet.dart' as uv;

import 'terminal_colors.dart';

class TerminalPainter extends CustomPainter {
  TerminalPainter({
    required this.screen,
    required this.cellWidth,
    required this.cellHeight,
    required this.fontFamily,
    required this.fontSize,
    required this.defaultFg,
    required this.defaultBg,
    required this.cursorColor,
    this.cursorX = -1,
    this.cursorY = -1,
    this.cursorVisible = false,
    this.devicePixelRatio = 1.0,
    this.customBlockGlyphs = true,
    this.customBrailleGlyphs = true,
    this.brailleDotScale = 0.78,
    super.repaint,
  });

  final uv.Buffer screen;
  final double cellWidth;
  final double cellHeight;
  final String fontFamily;
  final double fontSize;
  final Color defaultFg;
  final Color defaultBg;
  final Color cursorColor;
  final int cursorX;
  final int cursorY;
  final bool cursorVisible;
  final double devicePixelRatio;

  /// Paint Unicode block elements as geometry instead of font glyphs.
  final bool customBlockGlyphs;

  /// Paint Braille patterns as an exact 2x4 dot grid instead of font glyphs.
  final bool customBrailleGlyphs;

  /// Relative dot size for custom Braille rendering.
  final double brailleDotScale;

  double _snap(double value) {
    final dpr = devicePixelRatio <= 0 ? 1.0 : devicePixelRatio;
    return (value * dpr).roundToDouble() / dpr;
  }

  Rect _snapCellRect(int x, int y, {double? width}) {
    final left = _snap(x * cellWidth);
    final top = _snap(y * cellHeight);
    final right = _snap((x + (width ?? 1)) * cellWidth);
    final bottom = _snap((y + 1) * cellHeight);
    return Rect.fromLTRB(left, top, right, bottom);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rows = screen.height();
    final cols = screen.width();

    // Always establish an opaque base. This prevents the parent/background
    // from showing through at fractional device-pixel boundaries.
    final basePaint = Paint()
      ..color = defaultBg
      ..style = PaintingStyle.fill
      ..isAntiAlias = false;
    canvas.drawRect(Offset.zero & size, basePaint);

    final bgPaint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = false;

    final foregroundCells = <_CellPaintInfo>[];
    final cursorInfo = <_CursorPaintInfo>[];

    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < cols; x++) {
        final cell = screen.cellAt(x, y);
        if (cell == null || cell.isZero) continue;

        final style = cell.style;
        final isReverse = (style.attrs & uv.Attr.reverse) != 0;

        var fg = uvColorToFlutter(style.fg, defaultFg);
        var bg = uvColorToFlutter(style.bg, defaultBg);
        if (isReverse) {
          final tmp = fg;
          fg = bg;
          bg = tmp;
        }

        if ((style.attrs & uv.Attr.faint) != 0) {
          fg = fg.withAlpha(128);
        }

        final content = cell.content;
        final hasContent = content.isNotEmpty && content != ' ';
        final isConcealed = (style.attrs & uv.Attr.conceal) != 0;

        if (hasContent && !isConcealed) {
          foregroundCells.add(
            _CellPaintInfo(
              x: x,
              y: y,
              cell: cell,
              fg: fg,
              bg: bg,
              content: content,
              style: style,
            ),
          );
        }

        if (cursorVisible && cursorX == x && cursorY == y) {
          cursorInfo.add(_CursorPaintInfo(x: x, y: y, bg: bg, fg: fg));
        }
      }
    }

    _paintMergedBackgrounds(canvas, cols, rows, bgPaint);

    for (final info in foregroundCells) {
      _paintCellGlyph(canvas, info);
    }

    for (final cursor in cursorInfo) {
      final cursorRect = _snapCellRect(cursor.x, cursor.y);
      final cursorPaint = Paint()
        ..color = cursorColor.withAlpha(180)
        ..style = PaintingStyle.fill
        ..isAntiAlias = false;
      canvas.drawRect(cursorRect, cursorPaint);
    }
  }

  void _paintMergedBackgrounds(
    Canvas canvas,
    int cols,
    int rows,
    Paint bgPaint,
  ) {
    for (var y = 0; y < rows; y++) {
      var x = 0;
      while (x < cols) {
        final cell = screen.cellAt(x, y);
        if (cell == null || cell.isZero) {
          x++;
          continue;
        }

        final runColor = _resolvedBackground(cell);
        var runEnd = x + 1;

        while (runEnd < cols) {
          final next = screen.cellAt(runEnd, y);
          if (next == null || next.isZero) break;
          if (_resolvedBackground(next) != runColor) break;
          runEnd++;
        }

        if (runColor != defaultBg) {
          final rect = _snapCellRect(
            x,
            y,
            width: (runEnd - x).toDouble(),
          );
          bgPaint.color = runColor;
          canvas.drawRect(rect, bgPaint);
        }

        x = runEnd;
      }
    }
  }

  Color _resolvedBackground(uv.Cell cell) {
    final style = cell.style;
    final isReverse = (style.attrs & uv.Attr.reverse) != 0;
    if (isReverse) {
      return uvColorToFlutter(style.fg, defaultFg);
    }
    return uvColorToFlutter(style.bg, defaultBg);
  }

  void _paintCellGlyph(Canvas canvas, _CellPaintInfo info) {
    final paintedAsPrimitive = _paintTerminalPrimitive(canvas, info);
    if (!paintedAsPrimitive) {
      _paintTextGlyph(canvas, info);
    }
    _paintDecorations(canvas, info);
  }

  bool _paintTerminalPrimitive(Canvas canvas, _CellPaintInfo info) {
    final iterator = info.content.runes.iterator;
    if (!iterator.moveNext()) return false;
    final rune = iterator.current;
    if (iterator.moveNext()) return false;

    if (customBlockGlyphs && rune >= 0x2580 && rune <= 0x259F) {
      return _paintBlockElement(canvas, info, rune);
    }

    if (customBrailleGlyphs && rune >= 0x2800 && rune <= 0x28FF) {
      _paintBraille(canvas, info, rune);
      return true;
    }

    return false;
  }

  bool _paintBlockElement(Canvas canvas, _CellPaintInfo info, int rune) {
    final rect = _snapCellRect(
      info.x,
      info.y,
      width: info.cell.width.toDouble(),
    );
    final paint = Paint()
      ..color = info.fg
      ..style = PaintingStyle.fill
      ..isAntiAlias = false;

    void fill(Rect value) {
      if (value.width > 0 && value.height > 0) {
        canvas.drawRect(value, paint);
      }
    }

    Rect lowerFraction(int eighths) {
      final top = _snap(rect.bottom - rect.height * eighths / 8.0);
      return Rect.fromLTRB(rect.left, top, rect.right, rect.bottom);
    }

    Rect upperFraction(int eighths) {
      final bottom = _snap(rect.top + rect.height * eighths / 8.0);
      return Rect.fromLTRB(rect.left, rect.top, rect.right, bottom);
    }

    Rect leftFraction(int eighths) {
      final right = _snap(rect.left + rect.width * eighths / 8.0);
      return Rect.fromLTRB(rect.left, rect.top, right, rect.bottom);
    }

    Rect rightFraction(int eighths) {
      final left = _snap(rect.right - rect.width * eighths / 8.0);
      return Rect.fromLTRB(left, rect.top, rect.right, rect.bottom);
    }

    switch (rune) {
      case 0x2580: // upper half block
        fill(upperFraction(4));
        return true;
      case >= 0x2581 && <= 0x2587: // lower 1/8 .. 7/8
        fill(lowerFraction(rune - 0x2580));
        return true;
      case 0x2588: // full block
        fill(rect);
        return true;
      case >= 0x2589 && <= 0x258F: // left 7/8 .. 1/8
        fill(leftFraction(0x2590 - rune));
        return true;
      case 0x2590: // right half block
        fill(rightFraction(4));
        return true;
      case 0x2594: // upper 1/8 block
        fill(upperFraction(1));
        return true;
      case 0x2595: // right 1/8 block
        fill(rightFraction(1));
        return true;
      case 0x2596:
        _paintQuadrants(canvas, rect, paint, 0x4); // lower-left
        return true;
      case 0x2597:
        _paintQuadrants(canvas, rect, paint, 0x8); // lower-right
        return true;
      case 0x2598:
        _paintQuadrants(canvas, rect, paint, 0x1); // upper-left
        return true;
      case 0x2599:
        _paintQuadrants(canvas, rect, paint, 0xD); // UL + LL + LR
        return true;
      case 0x259A:
        _paintQuadrants(canvas, rect, paint, 0x9); // UL + LR
        return true;
      case 0x259B:
        _paintQuadrants(canvas, rect, paint, 0x7); // UL + UR + LL
        return true;
      case 0x259C:
        _paintQuadrants(canvas, rect, paint, 0xB); // UL + UR + LR
        return true;
      case 0x259D:
        _paintQuadrants(canvas, rect, paint, 0x2); // upper-right
        return true;
      case 0x259E:
        _paintQuadrants(canvas, rect, paint, 0x6); // UR + LL
        return true;
      case 0x259F:
        _paintQuadrants(canvas, rect, paint, 0xE); // UR + LL + LR
        return true;
      default:
        // Keep shade characters U+2591..U+2593 on the normal font path.
        return false;
    }
  }

  void _paintQuadrants(Canvas canvas, Rect rect, Paint paint, int mask) {
    final midX = _snap((rect.left + rect.right) / 2.0);
    final midY = _snap((rect.top + rect.bottom) / 2.0);

    if ((mask & 0x1) != 0) {
      canvas.drawRect(
        Rect.fromLTRB(rect.left, rect.top, midX, midY),
        paint,
      );
    }
    if ((mask & 0x2) != 0) {
      canvas.drawRect(
        Rect.fromLTRB(midX, rect.top, rect.right, midY),
        paint,
      );
    }
    if ((mask & 0x4) != 0) {
      canvas.drawRect(
        Rect.fromLTRB(rect.left, midY, midX, rect.bottom),
        paint,
      );
    }
    if ((mask & 0x8) != 0) {
      canvas.drawRect(
        Rect.fromLTRB(midX, midY, rect.right, rect.bottom),
        paint,
      );
    }
  }

  void _paintBraille(Canvas canvas, _CellPaintInfo info, int rune) {
    final rect = _snapCellRect(
      info.x,
      info.y,
      width: info.cell.width.toDouble(),
    );
    final bits = rune - 0x2800;
    if (bits == 0) return;

    final paint = Paint()
      ..color = info.fg
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final xCenters = <double>[
      rect.left + rect.width * 0.25,
      rect.left + rect.width * 0.75,
    ];
    final yCenters = <double>[
      rect.top + rect.height * 0.125,
      rect.top + rect.height * 0.375,
      rect.top + rect.height * 0.625,
      rect.top + rect.height * 0.875,
    ];

    final radius = math.max(
      0.5 / math.max(1.0, devicePixelRatio),
      math.min(rect.width / 5.0, rect.height / 10.0) * brailleDotScale,
    );

    void dot(int bit, int column, int row) {
      if ((bits & bit) == 0) return;
      canvas.drawCircle(
        Offset(xCenters[column], yCenters[row]),
        radius,
        paint,
      );
    }

    dot(0x01, 0, 0); // dot 1
    dot(0x02, 0, 1); // dot 2
    dot(0x04, 0, 2); // dot 3
    dot(0x40, 0, 3); // dot 7
    dot(0x08, 1, 0); // dot 4
    dot(0x10, 1, 1); // dot 5
    dot(0x20, 1, 2); // dot 6
    dot(0x80, 1, 3); // dot 8
  }

  void _paintTextGlyph(Canvas canvas, _CellPaintInfo info) {
    final style = info.style;
    final isBold = (style.attrs & uv.Attr.bold) != 0;
    final isItalic = (style.attrs & uv.Attr.italic) != 0;

    final textStyle = ui.TextStyle(
      color: info.fg,
      fontSize: fontSize,
      fontFamily: fontFamily,
      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
      height: 1.0,
    );

    final builder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textDirection: TextDirection.ltr,
        maxLines: 1,
      ),
    )
      ..pushStyle(textStyle)
      ..addText(info.content);

    final width = cellWidth * info.cell.width;
    final paragraph = builder.build()
      ..layout(ui.ParagraphConstraints(width: width));

    final cellRect = _snapCellRect(
      info.x,
      info.y,
      width: info.cell.width.toDouble(),
    );
    final textY = cellRect.top + (cellRect.height - paragraph.height) / 2;
    canvas.drawParagraph(paragraph, Offset(cellRect.left, textY));
  }

  void _paintDecorations(Canvas canvas, _CellPaintInfo info) {
    final style = info.style;
    final rect = _snapCellRect(
      info.x,
      info.y,
      width: info.cell.width.toDouble(),
    );

    if (style.underline != uv.UnderlineStyle.none) {
      final ulColor = uvColorToFlutter(style.underlineColor, info.fg);
      final ulPaint = Paint()
        ..color = ulColor
        ..strokeWidth = math.max(1.0 / devicePixelRatio, 1.0)
        ..style = PaintingStyle.stroke
        ..isAntiAlias = false;
      final ulY = _snap(rect.bottom - 1.5);
      canvas.drawLine(
        Offset(rect.left, ulY),
        Offset(rect.right, ulY),
        ulPaint,
      );
    }

    if ((style.attrs & uv.Attr.strikethrough) != 0) {
      final stPaint = Paint()
        ..color = info.fg
        ..strokeWidth = math.max(1.0 / devicePixelRatio, 1.0)
        ..style = PaintingStyle.stroke
        ..isAntiAlias = false;
      final stY = _snap((rect.top + rect.bottom) / 2.0);
      canvas.drawLine(
        Offset(rect.left, stY),
        Offset(rect.right, stY),
        stPaint,
      );
    }
  }

  @override
  bool shouldRepaint(TerminalPainter oldDelegate) => true;
}

class _CellPaintInfo {
  _CellPaintInfo({
    required this.x,
    required this.y,
    required this.cell,
    required this.fg,
    required this.bg,
    required this.content,
    required this.style,
  });

  final int x;
  final int y;
  final uv.Cell cell;
  final Color fg;
  final Color bg;
  final String content;
  final uv.UvStyle style;
}

class _CursorPaintInfo {
  _CursorPaintInfo({
    required this.x,
    required this.y,
    required this.bg,
    required this.fg,
  });

  final int x;
  final int y;
  final Color bg;
  final Color fg;
}