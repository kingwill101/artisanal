import 'dart:async';
import 'dart:io';

import 'package:ultraviolet/ultraviolet.dart';

final class _Panels {
  const _Panels({
    required this.left,
    required this.right,
    required this.footer,
  });

  final Rectangle left;
  final Rectangle right;
  final Rectangle footer;
}

_Panels _computePanels(Rectangle bounds, {required bool compact}) {
  if (compact) {
    final topBottom = splitVertical(bounds, const Percent(68));
    final leftRight = splitHorizontal(topBottom.top, const Percent(50));
    return _Panels(
      left: leftRight.left,
      right: leftRight.right,
      footer: topBottom.bottom,
    );
  }

  final leftRight = splitHorizontal(bounds, const Percent(65));
  final rightColumn = splitVertical(leftRight.right, const Percent(60));
  return _Panels(
    left: leftRight.left,
    right: rightColumn.top,
    footer: rightColumn.bottom,
  );
}

void _writeLine(
  Screen screen,
  int x,
  int y,
  String text, {
  UvStyle style = const UvStyle(),
  int? maxWidth,
}) {
  final limit = maxWidth == null
      ? text.length
      : (text.length < maxWidth ? text.length : maxWidth);
  for (var i = 0; i < limit; i++) {
    screen.setCell(x + i, y, Cell(content: text[i], style: style));
  }
}

void _drawPanel(
  Screen screen,
  Rectangle panel, {
  required String title,
  required List<String> lines,
  required UvStyle fillStyle,
  required bool active,
}) {
  if (panel.width < 4 || panel.height < 3) return;

  for (var y = panel.minY; y < panel.maxY; y++) {
    for (var x = panel.minX; x < panel.maxX; x++) {
      screen.setCell(x, y, Cell(content: ' ', style: fillStyle));
    }
  }

  final borderStyle = active
      ? fillStyle.copyWith(fg: UvColor.rgb(255, 220, 120), attrs: Attr.bold)
      : fillStyle.copyWith(fg: UvColor.rgb(130, 145, 165));

  final minX = panel.minX;
  final maxX = panel.maxX - 1;
  final minY = panel.minY;
  final maxY = panel.maxY - 1;

  for (var x = minX + 1; x < maxX; x++) {
    screen.setCell(x, minY, Cell(content: '─', style: borderStyle));
    screen.setCell(x, maxY, Cell(content: '─', style: borderStyle));
  }
  for (var y = minY + 1; y < maxY; y++) {
    screen.setCell(minX, y, Cell(content: '│', style: borderStyle));
    screen.setCell(maxX, y, Cell(content: '│', style: borderStyle));
  }

  screen.setCell(minX, minY, Cell(content: '┌', style: borderStyle));
  screen.setCell(maxX, minY, Cell(content: '┐', style: borderStyle));
  screen.setCell(minX, maxY, Cell(content: '└', style: borderStyle));
  screen.setCell(maxX, maxY, Cell(content: '┘', style: borderStyle));

  final titleLine = ' $title ';
  _writeLine(
    screen,
    minX + 2,
    minY,
    titleLine,
    style: borderStyle.copyWith(attrs: Attr.bold | Attr.italic),
    maxWidth: panel.width - 4,
  );

  final textStyle = fillStyle.copyWith(fg: UvColor.rgb(232, 237, 247));
  final maxLines = panel.height - 2;
  final maxTextWidth = panel.width - 2;
  for (var i = 0; i < lines.length && i < maxLines; i++) {
    _writeLine(
      screen,
      minX + 1,
      minY + 1 + i,
      lines[i],
      style: textStyle,
      maxWidth: maxTextWidth,
    );
  }
}

void main() async {
  if (!stdin.hasTerminal) {
    print('This example needs a TTY terminal.');
    return;
  }

  final terminal = Terminal();
  await terminal.start();
  terminal.enterAltScreen();
  terminal.hideCursor();
  terminal.setScrollOptim(false);
  terminal.setSynchronizedOutput(true);

  var compact = false;
  var focus = 0;
  var frame = 0;
  var needsHardClear = true;

  void render() {
    final bounds = terminal.bounds();
    final panels = _computePanels(bounds, compact: compact);
    terminal.clear();
    if (needsHardClear) {
      terminal.clearScreen();
      needsHardClear = false;
    }

    final leftStyle = const UvStyle(bg: UvColor.rgb(25, 36, 58));
    final rightStyle = const UvStyle(bg: UvColor.rgb(26, 52, 52));
    final footerStyle = const UvStyle(bg: UvColor.rgb(57, 33, 47));

    _drawPanel(
      terminal,
      panels.left,
      title: 'Main',
      lines: [
        'Ultraviolet layout demo',
        '',
        'tab         cycle focus',
        'space       toggle compact mode',
        'q / ctrl+c  quit',
        '',
        'Frame: $frame',
      ],
      fillStyle: leftStyle,
      active: focus == 0,
    );

    _drawPanel(
      terminal,
      panels.right,
      title: 'Inspector',
      lines: [
        'Terminal: ${bounds.width}x${bounds.height}',
        'Main: ${panels.left.width}x${panels.left.height}',
        'Right: ${panels.right.width}x${panels.right.height}',
        'Footer: ${panels.footer.width}x${panels.footer.height}',
      ],
      fillStyle: rightStyle,
      active: focus == 1,
    );

    _drawPanel(
      terminal,
      panels.footer,
      title: compact ? 'Compact Mode' : 'Wide Mode',
      lines: [
        compact
            ? 'Top area split 50/50, footer stacked under it.'
            : 'Main panel on left, inspector/footer stacked on right.',
      ],
      fillStyle: footerStyle,
      active: focus == 2,
    );

    terminal.draw();
  }

  final ticker = Timer.periodic(const Duration(milliseconds: 150), (_) {
    frame++;
    render();
  });

  try {
    render();
    await for (final event in terminal.events) {
      if (event is WindowSizeEvent) {
        terminal.resize(event.width, event.height);
        needsHardClear = true;
        render();
        continue;
      }

      if (event is! KeyEvent) continue;

      if (event.matchString('q', 'ctrl+c')) {
        break;
      }
      if (event.matchString('tab')) {
        focus = (focus + 1) % 3;
      } else if (event.matchString('shift+tab')) {
        focus = (focus + 2) % 3;
      } else if (event.matchString(' ')) {
        compact = !compact;
      }
      render();
    }
  } finally {
    ticker.cancel();
    terminal.showCursor();
    terminal.exitAltScreen();
    await terminal.stop();
  }
}
