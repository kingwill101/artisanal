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

  @override
  void paint(Canvas canvas, Size size) {
    final rows = screen.height();
    final cols = screen.width();
    final bgPaint = Paint();

    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < cols; x++) {
        final cell = screen.cellAt(x, y);
        if (cell == null) continue;
        if (cell.isZero) continue;

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

        final cellRect = Rect.fromLTWH(
          x * cellWidth,
          y * cellHeight,
          cellWidth * cell.width,
          cellHeight,
        );
        bgPaint.color = bg;
        canvas.drawRect(cellRect, bgPaint);

        final content = cell.content;
        if (content.isEmpty || content == ' ') continue;

        if ((style.attrs & uv.Attr.conceal) != 0) continue;

        final isBold = (style.attrs & uv.Attr.bold) != 0;
        final isItalic = (style.attrs & uv.Attr.italic) != 0;

        final textStyle = ui.TextStyle(
          color: fg,
          fontSize: fontSize,
          fontFamily: fontFamily,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
          height: 1.0,
        );

        final builder =
            ui.ParagraphBuilder(
                ui.ParagraphStyle(
                  textDirection: TextDirection.ltr,
                  maxLines: 1,
                ),
              )
              ..pushStyle(textStyle)
              ..addText(content);

        final paragraph = builder.build()
          ..layout(ui.ParagraphConstraints(width: cellWidth * cell.width));

        final textY = y * cellHeight + (cellHeight - paragraph.height) / 2;
        canvas.drawParagraph(paragraph, Offset(x * cellWidth, textY));

        if (style.underline != uv.UnderlineStyle.none) {
          final ulColor = uvColorToFlutter(style.underlineColor, fg);
          final ulPaint = Paint()
            ..color = ulColor
            ..strokeWidth = 1.0
            ..style = PaintingStyle.stroke;
          final ulY = (y + 1) * cellHeight - 1.5;
          canvas.drawLine(
            Offset(x * cellWidth, ulY),
            Offset((x + cell.width) * cellWidth, ulY),
            ulPaint,
          );
        }

        if ((style.attrs & uv.Attr.strikethrough) != 0) {
          final stPaint = Paint()
            ..color = fg
            ..strokeWidth = 1.0;
          final stY = y * cellHeight + cellHeight / 2;
          canvas.drawLine(
            Offset(x * cellWidth, stY),
            Offset((x + cell.width) * cellWidth, stY),
            stPaint,
          );
        }
      }
    }

    if (cursorVisible && cursorX >= 0 && cursorY >= 0) {
      final cx = cursorX;
      final cy = cursorY;
      if (cx < cols && cy < rows) {
        final cursorRect = Rect.fromLTWH(
          cx * cellWidth,
          cy * cellHeight,
          cellWidth,
          cellHeight,
        );
        final cursorPaint = Paint()
          ..color = cursorColor.withAlpha(180)
          ..style = PaintingStyle.fill;
        canvas.drawRect(cursorRect, cursorPaint);
      }
    }
  }

  @override
  bool shouldRepaint(TerminalPainter oldDelegate) => true;
}
