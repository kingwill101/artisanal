part of 'selection_widgets.dart';

/// Selection highlight style: white background, black foreground.
final Style _selectionStyle = Style()
    .background(const AnsiColor(7))
    .foreground(const AnsiColor(0));

/// Returns `(startX, endX)` for the word at the given position.
(int, int) _findWordAt(List<String> lines, int x, int y) {
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
  } else {
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
}

bool _isWhitespaceChar(String char) {
  return char == ' ' || char == '\t' || char == '\n' || char == '\r';
}

/// Applies selection highlighting to [lines].
///
/// [offset] is the content-line index of the first line in the list
/// (used for scroll views where only visible lines are provided).
/// For non-scrolled widgets, pass 0.
///
/// [ctrl] is the [SelectionController] holding selection state.
List<String> _applySelectionHighlighting(
  List<String> lines,
  int offset,
  SelectionController ctrl,
) {
  if (!ctrl.hasSelection) return lines;

  final s = ctrl.selectionStart!;
  final e = ctrl.selectionEnd!;

  final startY = math.min(s.y, e.y);
  final endY = math.max(s.y, e.y);

  // If the selection is entirely outside the visible range, return as-is.
  if (endY < offset) return lines;
  if (startY >= offset + lines.length) return lines;

  final result = <String>[];

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

    line = styleRanges(line, [StyleRange(startX, endX, _selectionStyle)]);
    result.add(line);
  }

  return result;
}
