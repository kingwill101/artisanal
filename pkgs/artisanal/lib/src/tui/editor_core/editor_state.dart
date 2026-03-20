library;

import 'dart:math' as math;

final class TextPosition {
  const TextPosition({required this.line, required this.column});

  final int line;
  final int column;

  @override
  bool operator ==(Object other) {
    return other is TextPosition &&
        other.line == line &&
        other.column == column;
  }

  @override
  int get hashCode => Object.hash(line, column);
}

final class TextSelection {
  const TextSelection({required this.base, required this.extent});

  final TextPosition base;
  final TextPosition extent;

  bool get isCollapsed => base == extent;

  TextPosition get start {
    if (base.line < extent.line) return base;
    if (base.line > extent.line) return extent;
    return base.column <= extent.column ? base : extent;
  }

  TextPosition get end {
    if (base.line > extent.line) return base;
    if (base.line < extent.line) return extent;
    return base.column >= extent.column ? base : extent;
  }
}

final class EditorState {
  EditorState({int line = 0, int column = 0})
    : _cursor = TextPosition(line: line, column: column);

  TextPosition _cursor;
  TextSelection? _selection;

  int get line => _cursor.line;
  int get column => _cursor.column;
  TextPosition get cursor => _cursor;
  TextSelection? get selection => _selection;
  bool get hasSelection => _selection != null && !_selection!.isCollapsed;

  void setCursor({required int line, required int column}) {
    _cursor = TextPosition(line: line, column: column);
  }

  void setSelection({
    required TextPosition base,
    required TextPosition extent,
    TextPosition? cursor,
  }) {
    _selection = TextSelection(base: base, extent: extent);
    _cursor = cursor ?? extent;
  }

  void clearSelection() {
    _selection = null;
  }

  void collapseSelection() {
    final currentSelection = _selection;
    if (currentSelection != null) {
      _cursor = currentSelection.extent;
    }
    _selection = null;
  }

  void selectRange({
    required TextPosition base,
    required TextPosition extent,
    TextPosition? cursor,
  }) {
    _selection = TextSelection(base: base, extent: extent);
    _cursor = cursor ?? extent;
  }

  void beginSelection() {
    _selection ??= TextSelection(base: _cursor, extent: _cursor);
  }

  void extendSelectionTo(TextPosition extent) {
    final base = _selection?.base ?? _cursor;
    _selection = TextSelection(base: base, extent: extent);
    _cursor = extent;
  }

  void moveCursorTo(TextPosition position, {bool clearSelection = true}) {
    _cursor = position;
    if (clearSelection) {
      _selection = null;
    }
  }

  ({int startLine, int endLine}) selectedLineRange() {
    final currentSelection = _selection;
    if (currentSelection == null || currentSelection.isCollapsed) {
      return (startLine: _cursor.line, endLine: _cursor.line);
    }

    return (
      startLine: math.min(
        currentSelection.start.line,
        currentSelection.end.line,
      ),
      endLine: math.max(currentSelection.start.line, currentSelection.end.line),
    );
  }

  void applyColumnDeltas(
    Map<int, int> deltas, {
    required int Function(int line) lineLength,
  }) {
    if (deltas.isEmpty) {
      return;
    }

    final cursorDelta = deltas[_cursor.line];
    if (cursorDelta != null) {
      _cursor = TextPosition(
        line: _cursor.line,
        column: (_cursor.column + cursorDelta).clamp(
          0,
          lineLength(_cursor.line),
        ),
      );
    }

    final currentSelection = _selection;
    if (currentSelection == null) {
      return;
    }

    _selection = TextSelection(
      base: _shiftPositionByColumnDelta(
        currentSelection.base,
        deltas,
        lineLength: lineLength,
      ),
      extent: _shiftPositionByColumnDelta(
        currentSelection.extent,
        deltas,
        lineLength: lineLength,
      ),
    );
  }

  void shiftRowsInRange({
    required int startLine,
    required int endLine,
    required int delta,
    required int maxLine,
    required int Function(int line) lineLength,
  }) {
    if (_cursor.line >= startLine && _cursor.line <= endLine) {
      final nextLine = (_cursor.line + delta).clamp(0, maxLine);
      _cursor = TextPosition(
        line: nextLine,
        column: _cursor.column.clamp(0, lineLength(nextLine)),
      );
    }

    final currentSelection = _selection;
    if (currentSelection == null) {
      return;
    }

    _selection = TextSelection(
      base: _shiftPositionRowRange(
        currentSelection.base,
        startLine: startLine,
        endLine: endLine,
        delta: delta,
        maxLine: maxLine,
        lineLength: lineLength,
      ),
      extent: _shiftPositionRowRange(
        currentSelection.extent,
        startLine: startLine,
        endLine: endLine,
        delta: delta,
        maxLine: maxLine,
        lineLength: lineLength,
      ),
    );
  }

  TextPosition _shiftPositionByColumnDelta(
    TextPosition position,
    Map<int, int> deltas, {
    required int Function(int line) lineLength,
  }) {
    final delta = deltas[position.line];
    if (delta == null) {
      return position;
    }
    return TextPosition(
      line: position.line,
      column: (position.column + delta).clamp(0, lineLength(position.line)),
    );
  }

  TextPosition _shiftPositionRowRange(
    TextPosition position, {
    required int startLine,
    required int endLine,
    required int delta,
    required int maxLine,
    required int Function(int line) lineLength,
  }) {
    if (position.line < startLine || position.line > endLine) {
      return position;
    }

    final nextLine = (position.line + delta).clamp(0, maxLine);
    return TextPosition(
      line: nextLine,
      column: position.column.clamp(0, lineLength(nextLine)),
    );
  }
}
