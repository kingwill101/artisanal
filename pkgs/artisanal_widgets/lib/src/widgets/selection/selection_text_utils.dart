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

/// Returns `(startX, endX)` for the full line at the given row.
(int, int) findLineAt(List<String> lines, int y) {
  if (y < 0 || y >= lines.length) return (0, 0);
  final line = Style.stripAnsi(lines[y]).replaceFirst(RegExp(r'[ \t]+$'), '');
  return (0, Style.visibleLength(line));
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
  if (lines.isEmpty) return '';
  if (endY < 0 || startY >= lines.length) return '';

  final sb = StringBuffer();
  final clampedStartY = startY.clamp(0, lines.length - 1);
  final clampedEndY = endY.clamp(0, lines.length - 1);
  for (var y = clampedStartY; y <= clampedEndY; y++) {
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
    if (y < clampedEndY) {
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
  List<int>? lineWidths,
  List<bool>? lineHasAnsi,
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

    final maxX = lineWidths != null && i < lineWidths.length
        ? lineWidths[i]
        : Style.visibleLength(line);

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

    final hasAnsi = lineHasAnsi != null && i < lineHasAnsi.length
        ? lineHasAnsi[i]
        : line.contains('\x1b');
    line = !hasAnsi
        ? styleRanges(line, [StyleRange(startX, endX, style)])
        : overlayBackgroundRangesPreservingAnsi(line, [
            StyleRange(startX, endX, style),
          ]);
    result.add(line);
  }

  return result;
}

/// Applies selection highlighting to [lines], allowing per-line style
/// overrides within the selected region.
List<String> applySelectionHighlightingWithRanges(
  List<String> lines, {
  required int offset,
  required SelectionPoint? selectionStart,
  required SelectionPoint? selectionEnd,
  required List<List<StyleRange>> lineHighlightRanges,
  Style? highlightStyle,
  List<int>? lineWidths,
  List<bool>? lineHasAnsi,
}) {
  if (selectionStart == null || selectionEnd == null) return lines;

  final s = selectionStart;
  final e = selectionEnd;
  final startY = math.min(s.y, e.y);
  final endY = math.max(s.y, e.y);

  if (endY < offset) return lines;
  if (startY >= offset + lines.length) return lines;

  final result = <String>[];
  final defaultStyle = highlightStyle ?? selectionHighlightStyle;

  for (var i = 0; i < lines.length; i++) {
    final lineIdx = i + offset;
    var line = lines[i];

    if (lineIdx < startY || lineIdx > endY) {
      result.add(line);
      continue;
    }

    final maxX = lineWidths != null && i < lineWidths.length
        ? lineWidths[i]
        : Style.visibleLength(line);

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

    final overrides = i < lineHighlightRanges.length
        ? lineHighlightRanges[i]
        : const <StyleRange>[];
    final hasAnsi = lineHasAnsi != null && i < lineHasAnsi.length
        ? lineHasAnsi[i]
        : line.contains('\x1b');
    line = !hasAnsi
        ? styleRanges(line, [StyleRange(startX, endX, defaultStyle)])
        : overlayBackgroundRangesPreservingAnsi(line, [
            StyleRange(startX, endX, defaultStyle),
          ]);

    final clippedOverrides = <StyleRange>[
      for (final range in overrides)
        if (math.min(endX, range.end) > math.max(startX, range.start))
          StyleRange(
            math.max(startX, range.start),
            math.min(endX, range.end),
            range.style,
          ),
    ];
    if (clippedOverrides.isNotEmpty) {
      line = styleRanges(line, clippedOverrides);
    }
    result.add(line);
  }

  return result;
}

bool _isWhitespaceChar(String char) {
  return char == ' ' || char == '\t' || char == '\n' || char == '\r';
}
