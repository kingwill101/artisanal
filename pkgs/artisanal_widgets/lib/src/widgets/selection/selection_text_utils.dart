import 'dart:math' as math;

import 'package:artisanal/style.dart';
import '../theme/theme.dart' show Theme, currentTheme;

typedef SelectionPoint = ({int x, int y});

/// Resolves the selection highlight style for the given [theme].
Style selectionHighlightStyleForTheme(Theme theme) {
  return Style()
      .background(theme.resolvedHighlight)
      .foreground(theme.resolvedOnHighlight);
}

/// Default selection highlight style using the current global theme.
Style get selectionHighlightStyle =>
    selectionHighlightStyleForTheme(currentTheme);

/// Returns `(startX, endX)` for the word at the given position.
(int, int) findWordAt(List<String> lines, int x, int y) {
  if (y < 0 || y >= lines.length) return (x, x);
  final line = Style.stripAnsi(lines[y]);
  if (x < 0 || x >= line.length) return (x, x);

  if (_isWhitespaceChar(line[x])) {
    var start = x;
    while (start > 0 && _isWhitespaceChar(line[start - 1])) {
      start--;
    }
    var end = x;
    while (end < line.length && _isWhitespaceChar(line[end])) {
      end++;
    }
    return (start, end);
  }

  var start = x;
  while (start > 0 && !_isWhitespaceChar(line[start - 1])) {
    start--;
  }
  var end = x;
  while (end < line.length && !_isWhitespaceChar(line[end])) {
    end++;
  }
  return (start, end);
}

/// Extracts the selected text from [lines].
String extractSelectedText(
  List<String> lines, {
  required SelectionPoint? selectionStart,
  required SelectionPoint? selectionEnd,
}) {
  if (selectionStart == null || selectionEnd == null) return '';

  final s = selectionStart;
  final e = selectionEnd;
  final startY = math.min(s.y, e.y);
  final endY = math.max(s.y, e.y);

  if (startY < 0 || endY >= lines.length) return '';

  final sb = StringBuffer();
  for (var y = startY; y <= endY; y++) {
    final line = lines[y];
    final plain = Style.stripAnsi(line);

    int startX;
    int endX;
    if (startY == endY) {
      startX = math.min(s.x, e.x);
      endX = math.max(s.x, e.x);
    } else if (y == startY) {
      startX = s.y < e.y ? s.x : e.x;
      endX = Style.visibleLength(plain);
    } else if (y == endY) {
      startX = 0;
      endX = s.y < e.y ? e.x : s.x;
    } else {
      startX = 0;
      endX = Style.visibleLength(plain);
    }

    final maxX = Style.visibleLength(plain);
    startX = startX.clamp(0, maxX);
    endX = endX.clamp(0, maxX);

    if (startX < endX) {
      sb.write(cutAnsiByCells(plain, startX, endX));
    }
    if (y < endY) {
      sb.write('\n');
    }
  }

  return sb.toString();
}

/// Applies selection highlighting to [lines].
///
/// [offset] is the content-line index of the first line in the list.
List<String> applySelectionHighlighting(
  List<String> lines, {
  required int offset,
  required SelectionPoint? selectionStart,
  required SelectionPoint? selectionEnd,
  Style? highlightStyle,
}) {
  if (selectionStart == null || selectionEnd == null) return lines;

  final s = selectionStart;
  final e = selectionEnd;
  final startY = math.min(s.y, e.y);
  final endY = math.max(s.y, e.y);

  if (endY < offset) return lines;
  if (startY >= offset + lines.length) return lines;

  final result = <String>[];
  final style = highlightStyle ?? selectionHighlightStyle;

  for (var i = 0; i < lines.length; i++) {
    final lineIdx = i + offset;
    var line = lines[i];

    if (lineIdx < startY || lineIdx > endY) {
      result.add(line);
      continue;
    }

    final maxX = Style.visibleLength(line);

    int startX;
    int endX;
    if (startY == endY) {
      startX = math.min(s.x, e.x);
      endX = math.max(s.x, e.x);
    } else if (lineIdx == startY) {
      startX = s.y < e.y ? s.x : e.x;
      endX = maxX;
    } else if (lineIdx == endY) {
      startX = 0;
      endX = s.y < e.y ? e.x : s.x;
    } else {
      startX = 0;
      endX = maxX;
    }

    startX = startX.clamp(0, maxX);
    endX = endX.clamp(0, maxX);
    if (startX >= endX) {
      result.add(line);
      continue;
    }

    line = styleRanges(line, [StyleRange(startX, endX, style)]);
    result.add(line);
  }

  return result;
}

bool _isWhitespaceChar(String char) {
  return char == ' ' || char == '\t' || char == '\n' || char == '\r';
}
