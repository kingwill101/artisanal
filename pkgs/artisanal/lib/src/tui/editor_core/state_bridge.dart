library;

import 'editor_state.dart';
import 'text_document.dart';

final class TextOffsetStateSnapshot {
  const TextOffsetStateSnapshot({
    required this.cursorOffset,
    this.selectionBaseOffset,
    this.selectionExtentOffset,
  });

  factory TextOffsetStateSnapshot.collapsed({required int cursorOffset}) {
    return TextOffsetStateSnapshot(cursorOffset: cursorOffset);
  }

  factory TextOffsetStateSnapshot.selection({
    required int baseOffset,
    required int extentOffset,
    int? cursorOffset,
    bool preserveCollapsedSelection = false,
  }) {
    if (baseOffset == extentOffset && !preserveCollapsedSelection) {
      return TextOffsetStateSnapshot.collapsed(
        cursorOffset: cursorOffset ?? extentOffset,
      );
    }

    return TextOffsetStateSnapshot(
      cursorOffset: cursorOffset ?? extentOffset,
      selectionBaseOffset: baseOffset,
      selectionExtentOffset: extentOffset,
    );
  }

  final int cursorOffset;
  final int? selectionBaseOffset;
  final int? selectionExtentOffset;

  bool get hasSelection =>
      selectionBaseOffset != null &&
      selectionExtentOffset != null &&
      selectionBaseOffset != selectionExtentOffset;

  ({int start, int end})? get normalizedSelectionRange {
    if (selectionBaseOffset == null || selectionExtentOffset == null) {
      return null;
    }

    final start = selectionBaseOffset! <= selectionExtentOffset!
        ? selectionBaseOffset!
        : selectionExtentOffset!;
    final end = selectionBaseOffset! >= selectionExtentOffset!
        ? selectionBaseOffset!
        : selectionExtentOffset!;
    return (start: start, end: end);
  }

  TextOffsetStateSnapshot clearSelection({int? cursorOffset}) {
    return TextOffsetStateSnapshot.collapsed(
      cursorOffset: cursorOffset ?? this.cursorOffset,
    );
  }

  TextOffsetStateSnapshot clamp(
    int textLength, {
    bool preserveCollapsedSelection = false,
  }) {
    final clampedCursor = cursorOffset.clamp(0, textLength);
    final clampedBase = selectionBaseOffset?.clamp(0, textLength);
    final clampedExtent = selectionExtentOffset?.clamp(0, textLength);

    if (clampedBase == null || clampedExtent == null) {
      return TextOffsetStateSnapshot.collapsed(cursorOffset: clampedCursor);
    }
    if (clampedBase == clampedExtent && !preserveCollapsedSelection) {
      return TextOffsetStateSnapshot.collapsed(cursorOffset: clampedCursor);
    }

    return TextOffsetStateSnapshot(
      cursorOffset: clampedCursor,
      selectionBaseOffset: clampedBase,
      selectionExtentOffset: clampedExtent,
    );
  }
}

final class TextLineStateSnapshot {
  const TextLineStateSnapshot({
    required this.cursor,
    this.selectionBase,
    this.selectionExtent,
  });

  factory TextLineStateSnapshot.collapsed({required TextPosition cursor}) {
    return TextLineStateSnapshot(cursor: cursor);
  }

  factory TextLineStateSnapshot.selection({
    required TextPosition base,
    required TextPosition extent,
    TextPosition? cursor,
    bool preserveCollapsedSelection = false,
  }) {
    if (base == extent && !preserveCollapsedSelection) {
      return TextLineStateSnapshot.collapsed(cursor: cursor ?? extent);
    }

    return TextLineStateSnapshot(
      cursor: cursor ?? extent,
      selectionBase: base,
      selectionExtent: extent,
    );
  }

  final TextPosition cursor;
  final TextPosition? selectionBase;
  final TextPosition? selectionExtent;

  bool get hasSelection =>
      selectionBase != null &&
      selectionExtent != null &&
      selectionBase != selectionExtent;

  TextSelection? get selection {
    if (selectionBase == null || selectionExtent == null) {
      return null;
    }
    return TextSelection(base: selectionBase!, extent: selectionExtent!);
  }

  TextLineStateSnapshot clearSelection({TextPosition? cursor}) {
    return TextLineStateSnapshot.collapsed(cursor: cursor ?? this.cursor);
  }

  TextLineStateSnapshot clamp({
    required int lineCount,
    required int Function(int line) lineLength,
    bool preserveCollapsedSelection = false,
  }) {
    final clampedCursor = _clampPositionToLines(
      cursor,
      lineCount: lineCount,
      lineLength: lineLength,
    );
    final clampedBase = selectionBase == null
        ? null
        : _clampPositionToLines(
            selectionBase!,
            lineCount: lineCount,
            lineLength: lineLength,
          );
    final clampedExtent = selectionExtent == null
        ? null
        : _clampPositionToLines(
            selectionExtent!,
            lineCount: lineCount,
            lineLength: lineLength,
          );

    if (clampedBase == null || clampedExtent == null) {
      return TextLineStateSnapshot.collapsed(cursor: clampedCursor);
    }
    if (clampedBase == clampedExtent && !preserveCollapsedSelection) {
      return TextLineStateSnapshot.collapsed(cursor: clampedCursor);
    }

    return TextLineStateSnapshot(
      cursor: clampedCursor,
      selectionBase: clampedBase,
      selectionExtent: clampedExtent,
    );
  }
}

void syncEditorStateFromOffsets(
  TextDocument document,
  EditorState editorState, {
  required int cursorOffset,
  int? selectionBaseOffset,
  int? selectionExtentOffset,
}) {
  final cursor = document.positionForOffset(
    cursorOffset.clamp(0, document.length),
  );
  editorState.setCursor(line: cursor.line, column: cursor.column);

  if (selectionBaseOffset == null || selectionExtentOffset == null) {
    editorState.clearSelection();
    return;
  }

  editorState.setSelection(
    base: document.positionForOffset(
      selectionBaseOffset.clamp(0, document.length),
    ),
    extent: document.positionForOffset(
      selectionExtentOffset.clamp(0, document.length),
    ),
    cursor: cursor,
  );
}

void syncEditorStateFromLineSnapshot(
  EditorState editorState,
  TextLineStateSnapshot snapshot, {
  required int lineCount,
  required int Function(int line) lineLength,
}) {
  final clamped = snapshot.clamp(lineCount: lineCount, lineLength: lineLength);
  editorState.setCursor(
    line: clamped.cursor.line,
    column: clamped.cursor.column,
  );

  if (clamped.selectionBase == null || clamped.selectionExtent == null) {
    editorState.clearSelection();
    return;
  }

  editorState.setSelection(
    base: clamped.selectionBase!,
    extent: clamped.selectionExtent!,
    cursor: clamped.cursor,
  );
}

TextOffsetStateSnapshot offsetSnapshotFromEditorState(
  TextDocument document,
  EditorState editorState, {
  required int textLength,
  bool preserveCollapsedSelection = false,
}) {
  final cursorOffset = document
      .offsetForPosition(editorState.cursor)
      .clamp(0, textLength);
  final selection = editorState.selection;
  if (selection == null ||
      (selection.isCollapsed && !preserveCollapsedSelection)) {
    return TextOffsetStateSnapshot(cursorOffset: cursorOffset);
  }

  return TextOffsetStateSnapshot(
    cursorOffset: cursorOffset,
    selectionBaseOffset: document
        .offsetForPosition(selection.base)
        .clamp(0, textLength),
    selectionExtentOffset: document
        .offsetForPosition(selection.extent)
        .clamp(0, textLength),
  );
}

TextLineStateSnapshot lineSnapshotFromEditorState(
  EditorState editorState, {
  required int lineCount,
  required int Function(int line) lineLength,
  bool preserveCollapsedSelection = false,
}) {
  final cursor = _clampPositionToLines(
    editorState.cursor,
    lineCount: lineCount,
    lineLength: lineLength,
  );
  final selection = editorState.selection;
  if (selection == null ||
      (selection.isCollapsed && !preserveCollapsedSelection)) {
    return TextLineStateSnapshot.collapsed(cursor: cursor);
  }

  return TextLineStateSnapshot.selection(
    base: _clampPositionToLines(
      selection.base,
      lineCount: lineCount,
      lineLength: lineLength,
    ),
    extent: _clampPositionToLines(
      selection.extent,
      lineCount: lineCount,
      lineLength: lineLength,
    ),
    cursor: cursor,
    preserveCollapsedSelection: preserveCollapsedSelection,
  );
}

TextLineStateSnapshot lineSnapshotFromOffsets(
  TextDocument document, {
  required int cursorOffset,
  int? selectionBaseOffset,
  int? selectionExtentOffset,
}) {
  final cursor = document.positionForOffset(
    cursorOffset.clamp(0, document.length),
  );
  if (selectionBaseOffset == null || selectionExtentOffset == null) {
    return TextLineStateSnapshot.collapsed(cursor: cursor);
  }

  return TextLineStateSnapshot.selection(
    base: document.positionForOffset(
      selectionBaseOffset.clamp(0, document.length),
    ),
    extent: document.positionForOffset(
      selectionExtentOffset.clamp(0, document.length),
    ),
    cursor: cursor,
  );
}

TextPosition _clampPositionToLines(
  TextPosition position, {
  required int lineCount,
  required int Function(int line) lineLength,
}) {
  final clampedLineCount = lineCount < 1 ? 1 : lineCount;
  final line = position.line.clamp(0, clampedLineCount - 1);
  final column = position.column.clamp(0, lineLength(line));
  return TextPosition(line: line, column: column);
}
