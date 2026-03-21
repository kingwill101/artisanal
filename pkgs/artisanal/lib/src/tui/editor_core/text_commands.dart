library;

import 'package:characters/characters.dart';

import 'editor_state.dart';
import 'state_bridge.dart';
import 'text_change.dart';
import 'text_document.dart';
import 'text_edit_ops.dart' as edit_ops;
import 'text_navigation.dart' as nav;
import 'text_view.dart';

final class TextCommandResult {
  const TextCommandResult({
    List<String>? graphemes,
    required this.cursorOffset,
    this.selectionBaseOffset,
    this.selectionExtentOffset,
    this.document,
    this.documentChange,
    this.changed = true,
  }) : _graphemes = graphemes;

  final List<String>? _graphemes;
  final int cursorOffset;
  final int? selectionBaseOffset;
  final int? selectionExtentOffset;
  final TextDocument? document;
  final TextDocumentChange? documentChange;
  final bool changed;

  List<String> get graphemes =>
      _graphemes ?? document?.flattenWithNewlines() ?? const <String>[];
}

final class TextCursorCommandResult {
  const TextCursorCommandResult({
    required this.cursorOffset,
    this.selectionBaseOffset,
    this.selectionExtentOffset,
    this.changed = true,
  });

  final int cursorOffset;
  final int? selectionBaseOffset;
  final int? selectionExtentOffset;
  final bool changed;
}

final class TextLineCommandResult {
  const TextLineCommandResult({
    required this.lines,
    required this.cursor,
    this.selectionBase,
    this.selectionExtent,
    this.changed = true,
  });

  final List<String> lines;
  final TextPosition cursor;
  final TextPosition? selectionBase;
  final TextPosition? selectionExtent;
  final bool changed;
}

({int start, int end})? normalizedSelectionRange(
  int? baseOffset,
  int? extentOffset,
) {
  if (baseOffset == null || extentOffset == null) {
    return null;
  }
  return (
    start: baseOffset <= extentOffset ? baseOffset : extentOffset,
    end: baseOffset >= extentOffset ? baseOffset : extentOffset,
  );
}

TextCommandResult _unchangedResult(
  List<String> graphemes, {
  required int cursorOffset,
  int? selectionBaseOffset,
  int? selectionExtentOffset,
}) {
  return TextCommandResult(
    graphemes: List<String>.from(graphemes),
    cursorOffset: cursorOffset,
    selectionBaseOffset: selectionBaseOffset,
    selectionExtentOffset: selectionExtentOffset,
    changed: false,
  );
}

TextLineCommandResult _unchangedLineResult(
  List<String> lines, {
  required TextPosition cursor,
  TextPosition? selectionBase,
  TextPosition? selectionExtent,
}) {
  return TextLineCommandResult(
    lines: List<String>.from(lines),
    cursor: cursor,
    selectionBase: selectionBase,
    selectionExtent: selectionExtent,
    changed: false,
  );
}

TextCursorCommandResult _unchangedCursorResult({
  required int cursorOffset,
  int? selectionBaseOffset,
  int? selectionExtentOffset,
}) {
  return TextCursorCommandResult(
    cursorOffset: cursorOffset,
    selectionBaseOffset: selectionBaseOffset,
    selectionExtentOffset: selectionExtentOffset,
    changed: false,
  );
}

TextPosition _clampPositionToLines(TextPosition position, List<String> lines) {
  final line = position.line.clamp(0, lines.length - 1);
  final column = position.column.clamp(0, lines[line].length);
  return TextPosition(line: line, column: column);
}

({int startLine, int endLine}) _selectedLineSpan(
  TextPosition cursor, {
  TextPosition? selectionBase,
  TextPosition? selectionExtent,
}) {
  final selection = selectionBase != null && selectionExtent != null
      ? TextSelection(base: selectionBase, extent: selectionExtent)
      : null;
  if (selection == null || selection.isCollapsed) {
    return (startLine: cursor.line, endLine: cursor.line);
  }
  return (startLine: selection.start.line, endLine: selection.end.line);
}

TextLineCommandResult _lineResultFromSnapshot(
  List<String> lines,
  TextLineStateSnapshot snapshot, {
  bool changed = true,
}) {
  return TextLineCommandResult(
    lines: lines,
    cursor: snapshot.cursor,
    selectionBase: snapshot.selectionBase,
    selectionExtent: snapshot.selectionExtent,
    changed: changed,
  );
}

TextPosition _duplicateAbovePosition(
  TextPosition position, {
  required int startLine,
  required int endLine,
  required int delta,
  required List<String> lines,
}) {
  if (position.line < startLine) {
    return _clampPositionToLines(position, lines);
  }
  if (position.line > endLine) {
    return _clampPositionToLines(
      TextPosition(line: position.line + delta, column: position.column),
      lines,
    );
  }
  return _clampPositionToLines(position, lines);
}

extension TextOffsetStateCommandExtensions on TextOffsetStateSnapshot {
  TextCommandResult replaceSelectionOrInsertCommand(
    List<String> graphemes, {
    List<String> replacement = const <String>[],
    bool replaceSelection = true,
  }) {
    return replaceSelectionOrInsert(
      graphemes,
      cursorOffset: cursorOffset,
      selectionBaseOffset: selectionBaseOffset,
      selectionExtentOffset: selectionExtentOffset,
      replacement: replacement,
      replaceSelection: replaceSelection,
    );
  }

  TextCommandResult deleteSelectionCommand(List<String> graphemes) {
    return deleteSelection(
      graphemes,
      cursorOffset: cursorOffset,
      selectionBaseOffset: selectionBaseOffset,
      selectionExtentOffset: selectionExtentOffset,
    );
  }

  TextCommandResult deletePreviousOrSelectionCommand(List<String> graphemes) {
    return deletePreviousOrSelection(
      graphemes,
      cursorOffset: cursorOffset,
      selectionBaseOffset: selectionBaseOffset,
      selectionExtentOffset: selectionExtentOffset,
    );
  }

  TextCommandResult deleteNextOrSelectionCommand(List<String> graphemes) {
    return deleteNextOrSelection(
      graphemes,
      cursorOffset: cursorOffset,
      selectionBaseOffset: selectionBaseOffset,
      selectionExtentOffset: selectionExtentOffset,
    );
  }

  TextCommandResult deletePreviousCommand(List<String> graphemes) {
    return deletePrevious(
      graphemes,
      cursorOffset: cursorOffset,
      selectionBaseOffset: selectionBaseOffset,
      selectionExtentOffset: selectionExtentOffset,
    );
  }

  TextCommandResult deleteNextCommand(List<String> graphemes) {
    return deleteNext(
      graphemes,
      cursorOffset: cursorOffset,
      selectionBaseOffset: selectionBaseOffset,
      selectionExtentOffset: selectionExtentOffset,
    );
  }

  TextCommandResult deleteWordBackwardCommand(
    List<String> graphemes, {
    required nav.GraphemePredicate isWord,
  }) {
    return deleteWordBackward(
      graphemes,
      cursorOffset: cursorOffset,
      selectionBaseOffset: selectionBaseOffset,
      selectionExtentOffset: selectionExtentOffset,
      isWord: isWord,
    );
  }

  TextCommandResult deleteWordForwardCommand(
    List<String> graphemes, {
    required nav.GraphemePredicate isWord,
  }) {
    return deleteWordForward(
      graphemes,
      cursorOffset: cursorOffset,
      selectionBaseOffset: selectionBaseOffset,
      selectionExtentOffset: selectionExtentOffset,
      isWord: isWord,
    );
  }

  TextCommandResult deleteToLineStartCommand(
    List<String> graphemes, {
    required int lineStartOffset,
  }) {
    return deleteToLineStart(
      graphemes,
      cursorOffset: cursorOffset,
      selectionBaseOffset: selectionBaseOffset,
      selectionExtentOffset: selectionExtentOffset,
      lineStartOffset: lineStartOffset,
    );
  }

  TextCommandResult deleteToLineEndCommand(
    List<String> graphemes, {
    required int lineEndOffset,
  }) {
    return deleteToLineEnd(
      graphemes,
      cursorOffset: cursorOffset,
      selectionBaseOffset: selectionBaseOffset,
      selectionExtentOffset: selectionExtentOffset,
      lineEndOffset: lineEndOffset,
    );
  }

  TextCommandResult transformSelectionOrLineCommand(
    List<String> graphemes, {
    required int lineStartOffset,
    required int lineEndOffset,
    required String Function(String text) transform,
  }) {
    return transformSelectionOrLine(
      graphemes,
      cursorOffset: cursorOffset,
      lineStartOffset: lineStartOffset,
      lineEndOffset: lineEndOffset,
      selectionBaseOffset: selectionBaseOffset,
      selectionExtentOffset: selectionExtentOffset,
      transform: transform,
    );
  }

  TextCommandResult wrapSelectionCommand(
    List<String> graphemes, {
    required List<String> before,
    List<String>? after,
  }) {
    return wrapSelection(
      graphemes,
      cursorOffset: cursorOffset,
      selectionBaseOffset: selectionBaseOffset,
      selectionExtentOffset: selectionExtentOffset,
      before: before,
      after: after,
    );
  }

  TextCommandResult unwrapSelectionCommand(
    List<String> graphemes, {
    required Map<String, String> surroundPairs,
  }) {
    return unwrapSelection(
      graphemes,
      cursorOffset: cursorOffset,
      selectionBaseOffset: selectionBaseOffset,
      selectionExtentOffset: selectionExtentOffset,
      surroundPairs: surroundPairs,
    );
  }

  TextCommandResult insertAutoPairCommand(
    List<String> graphemes, {
    required List<String> opening,
    required List<String> closing,
  }) {
    return insertAutoPair(
      graphemes,
      cursorOffset: cursorOffset,
      selectionBaseOffset: selectionBaseOffset,
      selectionExtentOffset: selectionExtentOffset,
      opening: opening,
      closing: closing,
    );
  }

  TextCursorCommandResult skipClosingDelimiterCommand(
    List<String> graphemes, {
    required List<String> closing,
    bool clearSelection = false,
  }) {
    return skipClosingDelimiter(
      graphemes,
      cursorOffset: cursorOffset,
      selectionBaseOffset: selectionBaseOffset,
      selectionExtentOffset: selectionExtentOffset,
      closing: closing,
      clearSelection: clearSelection,
    );
  }

  TextCommandResult deleteSurroundingPairCommand(
    List<String> graphemes, {
    required Map<String, String> surroundPairs,
  }) {
    return deleteSurroundingPair(
      graphemes,
      cursorOffset: cursorOffset,
      selectionBaseOffset: selectionBaseOffset,
      selectionExtentOffset: selectionExtentOffset,
      surroundPairs: surroundPairs,
    );
  }

  TextCommandResult transformWordOrAdjacentCommand(
    List<String> graphemes, {
    required nav.GraphemePredicate isWord,
    required String Function(String text) transform,
  }) {
    return transformWordOrAdjacent(
      graphemes,
      cursorOffset: cursorOffset,
      isWord: isWord,
      transform: transform,
    );
  }

  TextCommandResult toggleDelimitedSegmentCommand(
    List<String> graphemes, {
    required int rangeStartOffset,
    required int rangeEndOffset,
    required String startDelimiter,
    required String endDelimiter,
  }) {
    return toggleDelimitedSegment(
      graphemes,
      cursorOffset: cursorOffset,
      selectionBaseOffset: selectionBaseOffset,
      selectionExtentOffset: selectionExtentOffset,
      rangeStartOffset: rangeStartOffset,
      rangeEndOffset: rangeEndOffset,
      startDelimiter: startDelimiter,
      endDelimiter: endDelimiter,
    );
  }

  TextCommandResult insertIndentedNewlineCommand(
    List<String> graphemes, {
    required List<String> baseIndent,
    List<String> additionalIndent = const <String>[],
    List<String> trailingSuffix = const <String>[],
    int trailingSuffixReplaceCount = 0,
  }) {
    return insertIndentedNewline(
      graphemes,
      cursorOffset: cursorOffset,
      selectionBaseOffset: selectionBaseOffset,
      selectionExtentOffset: selectionExtentOffset,
      baseIndent: baseIndent,
      additionalIndent: additionalIndent,
      trailingSuffix: trailingSuffix,
      trailingSuffixReplaceCount: trailingSuffixReplaceCount,
    );
  }

  TextCursorCommandResult moveByCharacterCommand(
    List<String> graphemes, {
    required bool forward,
    bool extendSelection = false,
    bool clearSelection = true,
    bool preserveCollapsedSelection = false,
  }) {
    return moveCursorByCharacter(
      graphemes,
      cursorOffset: cursorOffset,
      selectionBaseOffset: selectionBaseOffset,
      selectionExtentOffset: selectionExtentOffset,
      forward: forward,
      extendSelection: extendSelection,
      clearSelection: clearSelection,
      preserveCollapsedSelection: preserveCollapsedSelection,
    );
  }

  TextCursorCommandResult moveByWordCommand(
    List<String> graphemes, {
    required bool forward,
    required nav.GraphemePredicate isWord,
    bool extendSelection = false,
    bool clearSelection = true,
    bool preserveCollapsedSelection = false,
  }) {
    return moveCursorByWord(
      graphemes,
      cursorOffset: cursorOffset,
      selectionBaseOffset: selectionBaseOffset,
      selectionExtentOffset: selectionExtentOffset,
      forward: forward,
      isWord: isWord,
      extendSelection: extendSelection,
      clearSelection: clearSelection,
      preserveCollapsedSelection: preserveCollapsedSelection,
    );
  }

  TextCursorCommandResult moveToDocumentBoundaryCommand(
    List<String> graphemes, {
    required bool forward,
    bool extendSelection = false,
    bool clearSelection = true,
    bool preserveCollapsedSelection = false,
  }) {
    return moveCursorToDocumentBoundary(
      graphemes,
      cursorOffset: cursorOffset,
      selectionBaseOffset: selectionBaseOffset,
      selectionExtentOffset: selectionExtentOffset,
      forward: forward,
      extendSelection: extendSelection,
      clearSelection: clearSelection,
      preserveCollapsedSelection: preserveCollapsedSelection,
    );
  }

  TextCursorCommandResult moveByVisualLineCommand(
    TextDocument document,
    EditorState state,
    TextView view, {
    required int lineDelta,
    int desiredDisplayColumn = -1,
    bool extendSelection = false,
    bool clearSelection = true,
    bool preserveCollapsedSelection = false,
  }) {
    return moveCursorByVisualLine(
      document,
      state,
      view,
      cursorOffset: cursorOffset,
      selectionBaseOffset: selectionBaseOffset,
      selectionExtentOffset: selectionExtentOffset,
      lineDelta: lineDelta,
      desiredDisplayColumn: desiredDisplayColumn,
      extendSelection: extendSelection,
      clearSelection: clearSelection,
      preserveCollapsedSelection: preserveCollapsedSelection,
    );
  }

  TextCursorCommandResult moveToVisualLineBoundaryCommand(
    TextDocument document,
    EditorState state,
    TextView view, {
    required bool end,
    bool extendSelection = false,
    bool clearSelection = true,
    bool preserveCollapsedSelection = false,
  }) {
    return moveCursorToVisualLineBoundary(
      document,
      state,
      view,
      cursorOffset: cursorOffset,
      selectionBaseOffset: selectionBaseOffset,
      selectionExtentOffset: selectionExtentOffset,
      end: end,
      extendSelection: extendSelection,
      clearSelection: clearSelection,
      preserveCollapsedSelection: preserveCollapsedSelection,
    );
  }
}

extension TextLineStateCommandExtensions on TextLineStateSnapshot {
  TextLineCommandResult moveSelectedLinesCommand(
    List<String> lines, {
    required int direction,
  }) {
    return moveSelectedLines(
      lines,
      cursor: cursor,
      selectionBase: selectionBase,
      selectionExtent: selectionExtent,
      direction: direction,
    );
  }

  TextLineCommandResult duplicateSelectedLinesAboveCommand(List<String> lines) {
    return duplicateSelectedLinesAbove(
      lines,
      cursor: cursor,
      selectionBase: selectionBase,
      selectionExtent: selectionExtent,
    );
  }

  TextLineCommandResult duplicateSelectedLinesBelowCommand(List<String> lines) {
    return duplicateSelectedLinesBelow(
      lines,
      cursor: cursor,
      selectionBase: selectionBase,
      selectionExtent: selectionExtent,
    );
  }

  TextLineCommandResult toggleLinePrefixCommand(
    List<String> lines, {
    required String prefix,
    bool addSpaceWhenNonEmpty = true,
    bool skipBlankLinesWhenChecking = true,
  }) {
    return toggleLinePrefix(
      lines,
      cursor: cursor,
      selectionBase: selectionBase,
      selectionExtent: selectionExtent,
      prefix: prefix,
      addSpaceWhenNonEmpty: addSpaceWhenNonEmpty,
      skipBlankLinesWhenChecking: skipBlankLinesWhenChecking,
    );
  }

  TextLineCommandResult toggleNumberedListCommand(
    List<String> lines, {
    int startAt = 1,
  }) {
    return toggleNumberedList(
      lines,
      cursor: cursor,
      selectionBase: selectionBase,
      selectionExtent: selectionExtent,
      startAt: startAt,
    );
  }

  TextLineCommandResult renumberNumberedListCommand(
    List<String> lines, {
    int startAt = 1,
  }) {
    return renumberNumberedList(
      lines,
      cursor: cursor,
      selectionBase: selectionBase,
      selectionExtent: selectionExtent,
      startAt: startAt,
    );
  }

  TextLineCommandResult toggleHeadingPrefixCommand(
    List<String> lines, {
    int level = 1,
  }) {
    return toggleHeadingPrefix(
      lines,
      cursor: cursor,
      selectionBase: selectionBase,
      selectionExtent: selectionExtent,
      level: level,
    );
  }

  TextLineCommandResult toggleChecklistStateCommand(
    List<String> lines, {
    String checkedMarker = 'x',
  }) {
    return toggleChecklistState(
      lines,
      cursor: cursor,
      selectionBase: selectionBase,
      selectionExtent: selectionExtent,
      checkedMarker: checkedMarker,
    );
  }
}

TextCursorCommandResult moveCursorToOffset({
  required int textLength,
  required int cursorOffset,
  int? selectionBaseOffset,
  int? selectionExtentOffset,
  required int targetOffset,
  bool extendSelection = false,
  bool clearSelection = true,
  bool preserveCollapsedSelection = false,
}) {
  final clampedCursor = cursorOffset.clamp(0, textLength);
  final clampedBase = selectionBaseOffset?.clamp(0, textLength);
  final clampedExtent = selectionExtentOffset?.clamp(0, textLength);
  final clampedTarget = targetOffset.clamp(0, textLength);

  if (!extendSelection) {
    final nextBase = clearSelection ? null : clampedBase;
    final nextExtent = clearSelection ? null : clampedExtent;
    if (clampedTarget == clampedCursor &&
        nextBase == clampedBase &&
        nextExtent == clampedExtent) {
      return _unchangedCursorResult(
        cursorOffset: clampedCursor,
        selectionBaseOffset: clampedBase,
        selectionExtentOffset: clampedExtent,
      );
    }
    return TextCursorCommandResult(
      cursorOffset: clampedTarget,
      selectionBaseOffset: nextBase,
      selectionExtentOffset: nextExtent,
    );
  }

  final anchor = clampedBase ?? clampedCursor;
  if (anchor == clampedTarget && !preserveCollapsedSelection) {
    final selectionChanged = clampedBase != null || clampedExtent != null;
    if (clampedTarget == clampedCursor && !selectionChanged) {
      return _unchangedCursorResult(cursorOffset: clampedCursor);
    }
    return TextCursorCommandResult(cursorOffset: clampedTarget);
  }

  if (clampedTarget == clampedCursor &&
      clampedBase == anchor &&
      clampedExtent == clampedTarget) {
    return _unchangedCursorResult(
      cursorOffset: clampedCursor,
      selectionBaseOffset: clampedBase,
      selectionExtentOffset: clampedExtent,
    );
  }

  return TextCursorCommandResult(
    cursorOffset: clampedTarget,
    selectionBaseOffset: anchor,
    selectionExtentOffset: clampedTarget,
  );
}

TextCursorCommandResult moveCursorByCharacter(
  List<String> graphemes, {
  required int cursorOffset,
  int? selectionBaseOffset,
  int? selectionExtentOffset,
  required bool forward,
  bool extendSelection = false,
  bool clearSelection = true,
  bool preserveCollapsedSelection = false,
}) {
  final targetOffset = forward
      ? (cursorOffset + 1).clamp(0, graphemes.length)
      : (cursorOffset - 1).clamp(0, graphemes.length);
  return moveCursorToOffset(
    textLength: graphemes.length,
    cursorOffset: cursorOffset,
    selectionBaseOffset: selectionBaseOffset,
    selectionExtentOffset: selectionExtentOffset,
    targetOffset: targetOffset,
    extendSelection: extendSelection,
    clearSelection: clearSelection,
    preserveCollapsedSelection: preserveCollapsedSelection,
  );
}

TextCursorCommandResult moveCursorByWord(
  List<String> graphemes, {
  required int cursorOffset,
  int? selectionBaseOffset,
  int? selectionExtentOffset,
  required bool forward,
  required nav.GraphemePredicate isWord,
  bool extendSelection = false,
  bool clearSelection = true,
  bool preserveCollapsedSelection = false,
}) {
  final targetOffset = forward
      ? nav.moveWordForward(graphemes, cursorOffset, isWord: isWord)
      : nav.moveWordBackward(graphemes, cursorOffset, isWord: isWord);
  return moveCursorToOffset(
    textLength: graphemes.length,
    cursorOffset: cursorOffset,
    selectionBaseOffset: selectionBaseOffset,
    selectionExtentOffset: selectionExtentOffset,
    targetOffset: targetOffset,
    extendSelection: extendSelection,
    clearSelection: clearSelection,
    preserveCollapsedSelection: preserveCollapsedSelection,
  );
}

TextCursorCommandResult moveCursorToDocumentBoundary(
  List<String> graphemes, {
  required int cursorOffset,
  int? selectionBaseOffset,
  int? selectionExtentOffset,
  required bool forward,
  bool extendSelection = false,
  bool clearSelection = true,
  bool preserveCollapsedSelection = false,
}) {
  return moveCursorToOffset(
    textLength: graphemes.length,
    cursorOffset: cursorOffset,
    selectionBaseOffset: selectionBaseOffset,
    selectionExtentOffset: selectionExtentOffset,
    targetOffset: forward ? graphemes.length : 0,
    extendSelection: extendSelection,
    clearSelection: clearSelection,
    preserveCollapsedSelection: preserveCollapsedSelection,
  );
}

TextCursorCommandResult moveCursorByVisualLine(
  TextDocument document,
  EditorState state,
  TextView view, {
  required int cursorOffset,
  int? selectionBaseOffset,
  int? selectionExtentOffset,
  required int lineDelta,
  int desiredDisplayColumn = -1,
  bool extendSelection = false,
  bool clearSelection = true,
  bool preserveCollapsedSelection = false,
}) {
  final cursor = document.positionForOffset(
    cursorOffset.clamp(0, document.length),
  );
  final targetOffset = view.cursorOffsetForVisualLineMove(
    document,
    state,
    lineDelta: lineDelta,
    desiredDisplayColumn: desiredDisplayColumn,
    cursor: cursor,
  );

  return moveCursorToOffset(
    textLength: document.length,
    cursorOffset: cursorOffset,
    selectionBaseOffset: selectionBaseOffset,
    selectionExtentOffset: selectionExtentOffset,
    targetOffset: targetOffset,
    extendSelection: extendSelection,
    clearSelection: clearSelection,
    preserveCollapsedSelection: preserveCollapsedSelection,
  );
}

TextCursorCommandResult moveCursorToVisualLineBoundary(
  TextDocument document,
  EditorState state,
  TextView view, {
  required int cursorOffset,
  int? selectionBaseOffset,
  int? selectionExtentOffset,
  required bool end,
  bool extendSelection = false,
  bool clearSelection = true,
  bool preserveCollapsedSelection = false,
}) {
  final cursor = document.positionForOffset(
    cursorOffset.clamp(0, document.length),
  );
  final targetOffset = view.cursorOffsetForVisualLineBoundary(
    document,
    state,
    end: end,
    cursor: cursor,
  );

  return moveCursorToOffset(
    textLength: document.length,
    cursorOffset: cursorOffset,
    selectionBaseOffset: selectionBaseOffset,
    selectionExtentOffset: selectionExtentOffset,
    targetOffset: targetOffset,
    extendSelection: extendSelection,
    clearSelection: clearSelection,
    preserveCollapsedSelection: preserveCollapsedSelection,
  );
}

TextPosition? _adjustLinePrefixPosition(
  TextPosition? position, {
  required int line,
  required int leadingWhitespace,
  required int delta,
  required bool remove,
}) {
  if (position == null || position.line != line) {
    return position;
  }

  return TextPosition(
    line: position.line,
    column: _adjustLinePrefixColumn(
      column: position.column,
      leadingWhitespace: leadingWhitespace,
      delta: delta,
      remove: remove,
    ),
  );
}

TextPosition? _adjustLinePrefixPositionDelta(
  TextPosition? position, {
  required int line,
  required int leadingWhitespace,
  required int delta,
}) {
  if (position == null || position.line != line || delta == 0) {
    return position;
  }

  return TextPosition(
    line: position.line,
    column: _adjustLinePrefixColumnDelta(
      column: position.column,
      leadingWhitespace: leadingWhitespace,
      delta: delta,
    ),
  );
}

int _adjustLinePrefixColumn({
  required int column,
  required int leadingWhitespace,
  required int delta,
  required bool remove,
}) {
  if (column <= leadingWhitespace) {
    return column;
  }
  if (!remove) {
    return column + delta;
  }
  return (column - delta).clamp(leadingWhitespace, column);
}

int _adjustLinePrefixColumnDelta({
  required int column,
  required int leadingWhitespace,
  required int delta,
}) {
  if (delta == 0 || column <= leadingWhitespace) {
    return column;
  }
  if (delta > 0) {
    return column + delta;
  }
  return (column + delta).clamp(leadingWhitespace, column);
}

bool _listStringEquals(List<String> a, List<String> b) {
  if (identical(a, b)) {
    return true;
  }
  if (a.length != b.length) {
    return false;
  }
  for (var index = 0; index < a.length; index++) {
    if (a[index] != b[index]) {
      return false;
    }
  }
  return true;
}

int? _leadingNumberedPrefixLength(String text) {
  final match = RegExp(r'^\d+\.\s?').firstMatch(text);
  return match?.group(0)?.length;
}

({int level, int length})? _leadingHeadingPrefix(String text) {
  final match = RegExp(r'^(#{1,6})(?:\s+|$)').firstMatch(text);
  final hashes = match?.group(1);
  final length = match?.group(0)?.length;
  if (hashes == null || length == null) {
    return null;
  }
  return (level: hashes.length, length: length);
}

int? _leadingChecklistPrefixLength(String text) {
  final match = RegExp(r'^-\s\[(?:\s|x|X)\]\s?').firstMatch(text);
  return match?.group(0)?.length;
}

bool _startsWithGraphemeSequence(List<String> graphemes, List<String> prefix) {
  if (prefix.length > graphemes.length) {
    return false;
  }
  for (var index = 0; index < prefix.length; index++) {
    if (graphemes[index] != prefix[index]) {
      return false;
    }
  }
  return true;
}

bool _endsWithGraphemeSequence(List<String> graphemes, List<String> suffix) {
  if (suffix.length > graphemes.length) {
    return false;
  }
  final offset = graphemes.length - suffix.length;
  for (var index = 0; index < suffix.length; index++) {
    if (graphemes[offset + index] != suffix[index]) {
      return false;
    }
  }
  return true;
}

int _leadingWhitespaceCount(List<String> graphemes) {
  var count = 0;
  while (count < graphemes.length && graphemes[count].trim().isEmpty) {
    count++;
  }
  return count;
}

int _trailingWhitespaceCount(List<String> graphemes) {
  var count = 0;
  while (count < graphemes.length &&
      graphemes[graphemes.length - 1 - count].trim().isEmpty) {
    count++;
  }
  return count;
}

bool _isChecklistChecked(String text) {
  final match = RegExp(r'^-\s\[(.)\]').firstMatch(text);
  if (match == null) {
    return false;
  }
  final marker = match.group(1);
  return marker != null && marker.trim().isNotEmpty;
}

TextCommandResult replaceSelectionOrInsert(
  List<String> graphemes, {
  required int cursorOffset,
  int? selectionBaseOffset,
  int? selectionExtentOffset,
  List<String> replacement = const <String>[],
  bool replaceSelection = true,
}) {
  final selection = normalizedSelectionRange(
    selectionBaseOffset,
    selectionExtentOffset,
  );
  final hasSelection = selection != null && selection.start != selection.end;

  if (replaceSelection && hasSelection) {
    final result = edit_ops.replaceRange(
      graphemes,
      start: selection.start,
      end: selection.end,
      replacement: replacement,
    );
    return TextCommandResult(
      graphemes: result.graphemes,
      cursorOffset: result.cursorOffset,
      changed: selection.start != selection.end || replacement.isNotEmpty,
    );
  }

  final result = edit_ops.insertAtCursor(graphemes, cursorOffset, replacement);
  return TextCommandResult(
    graphemes: result.graphemes,
    cursorOffset: result.cursorOffset,
    changed: replacement.isNotEmpty,
  );
}

TextLineCommandResult toggleLinePrefix(
  List<String> lines, {
  required TextPosition cursor,
  TextPosition? selectionBase,
  TextPosition? selectionExtent,
  required String prefix,
  bool addSpaceWhenNonEmpty = true,
  bool skipBlankLinesWhenChecking = true,
}) {
  if (prefix.isEmpty) {
    return _unchangedLineResult(
      lines,
      cursor: cursor,
      selectionBase: selectionBase,
      selectionExtent: selectionExtent,
    );
  }

  final lineTexts = lines.isEmpty ? <String>[''] : List<String>.from(lines);
  final clampedCursor = _clampPositionToLines(cursor, lineTexts);
  final selection = selectionBase != null && selectionExtent != null
      ? TextSelection(base: selectionBase, extent: selectionExtent)
      : null;
  final hasSelection = selection != null && !selection.isCollapsed;
  final startLine = hasSelection ? selection.start.line : clampedCursor.line;
  final endLine = hasSelection ? selection.end.line : clampedCursor.line;

  var hasRelevantLine = false;
  var allPrefixed = true;
  for (var lineIndex = startLine; lineIndex <= endLine; lineIndex++) {
    final line = lineTexts[lineIndex];
    final leadingWhitespace = line.length - line.trimLeft().length;
    final body = line.substring(leadingWhitespace);
    if (skipBlankLinesWhenChecking && body.trim().isEmpty) {
      continue;
    }
    hasRelevantLine = true;
    if (!body.startsWith(prefix)) {
      allPrefixed = false;
      break;
    }
  }
  if (!hasRelevantLine) {
    allPrefixed = false;
  }

  var adjustedBase = selectionBase;
  var adjustedExtent = selectionExtent;
  var nextCursor = clampedCursor;

  for (var lineIndex = startLine; lineIndex <= endLine; lineIndex++) {
    final line = lineTexts[lineIndex];
    final leadingWhitespace = line.length - line.trimLeft().length;
    final indent = line.substring(0, leadingWhitespace);
    final body = line.substring(leadingWhitespace);
    final wasPrefixed = body.startsWith(prefix);
    final hadTrailingSpace = wasPrefixed && body.length > prefix.length
        ? body.substring(prefix.length).startsWith(' ')
        : false;
    final removeCount = prefix.length + (hadTrailingSpace ? 1 : 0);
    final addCount =
        prefix.length + (addSpaceWhenNonEmpty && body.isNotEmpty ? 1 : 0);

    lineTexts[lineIndex] = allPrefixed && wasPrefixed
        ? '$indent${body.substring(removeCount)}'
        : '$indent$prefix${addSpaceWhenNonEmpty && body.isNotEmpty ? ' ' : ''}$body';

    if (!allPrefixed) {
      if (lineIndex == nextCursor.line) {
        nextCursor = TextPosition(
          line: nextCursor.line,
          column: _adjustLinePrefixColumn(
            column: nextCursor.column,
            leadingWhitespace: leadingWhitespace,
            delta: addCount,
            remove: false,
          ),
        );
      }
      adjustedBase = _adjustLinePrefixPosition(
        adjustedBase,
        line: lineIndex,
        leadingWhitespace: leadingWhitespace,
        delta: addCount,
        remove: false,
      );
      adjustedExtent = _adjustLinePrefixPosition(
        adjustedExtent,
        line: lineIndex,
        leadingWhitespace: leadingWhitespace,
        delta: addCount,
        remove: false,
      );
      continue;
    }

    if (lineIndex == nextCursor.line) {
      nextCursor = TextPosition(
        line: nextCursor.line,
        column: _adjustLinePrefixColumn(
          column: nextCursor.column,
          leadingWhitespace: leadingWhitespace,
          delta: removeCount,
          remove: true,
        ),
      );
    }
    adjustedBase = _adjustLinePrefixPosition(
      adjustedBase,
      line: lineIndex,
      leadingWhitespace: leadingWhitespace,
      delta: removeCount,
      remove: true,
    );
    adjustedExtent = _adjustLinePrefixPosition(
      adjustedExtent,
      line: lineIndex,
      leadingWhitespace: leadingWhitespace,
      delta: removeCount,
      remove: true,
    );
  }

  if (_listStringEquals(lineTexts, lines)) {
    return _unchangedLineResult(
      lineTexts,
      cursor: clampedCursor,
      selectionBase: selectionBase,
      selectionExtent: selectionExtent,
    );
  }

  if (hasSelection && adjustedBase != null && adjustedExtent != null) {
    final clampedBase = _clampPositionToLines(adjustedBase, lineTexts);
    final clampedExtent = _clampPositionToLines(adjustedExtent, lineTexts);
    return TextLineCommandResult(
      lines: lineTexts,
      cursor: clampedExtent,
      selectionBase: clampedBase,
      selectionExtent: clampedExtent,
    );
  }

  return TextLineCommandResult(
    lines: lineTexts,
    cursor: _clampPositionToLines(nextCursor, lineTexts),
  );
}

TextLineCommandResult toggleNumberedList(
  List<String> lines, {
  required TextPosition cursor,
  TextPosition? selectionBase,
  TextPosition? selectionExtent,
  int startAt = 1,
}) {
  final lineTexts = lines.isEmpty ? <String>[''] : List<String>.from(lines);
  final clampedCursor = _clampPositionToLines(cursor, lineTexts);
  final selection = selectionBase != null && selectionExtent != null
      ? TextSelection(base: selectionBase, extent: selectionExtent)
      : null;
  final hasSelection = selection != null && !selection.isCollapsed;
  final startLine = hasSelection ? selection.start.line : clampedCursor.line;
  final endLine = hasSelection ? selection.end.line : clampedCursor.line;
  final initialNumber = startAt < 1 ? 1 : startAt;

  var hasRelevantLine = false;
  var allNumbered = true;
  for (var lineIndex = startLine; lineIndex <= endLine; lineIndex++) {
    final line = lineTexts[lineIndex];
    final leadingWhitespace = line.length - line.trimLeft().length;
    final body = line.substring(leadingWhitespace);
    if (body.trim().isEmpty) {
      continue;
    }
    hasRelevantLine = true;
    if (_leadingNumberedPrefixLength(body) == null) {
      allNumbered = false;
      break;
    }
  }

  var adjustedBase = selectionBase;
  var adjustedExtent = selectionExtent;
  var nextCursor = clampedCursor;
  var nextNumber = initialNumber;

  for (var lineIndex = startLine; lineIndex <= endLine; lineIndex++) {
    final line = lineTexts[lineIndex];
    final leadingWhitespace = line.length - line.trimLeft().length;
    final indent = line.substring(0, leadingWhitespace);
    final body = line.substring(leadingWhitespace);
    final numberedPrefixLength = _leadingNumberedPrefixLength(body);
    final isBlank = body.trim().isEmpty;
    if (isBlank && hasRelevantLine) {
      continue;
    }

    final addPrefix = '${nextNumber++}. ';
    final removeCount = numberedPrefixLength ?? 0;
    final addCount = addPrefix.length;

    lineTexts[lineIndex] = allNumbered && removeCount > 0
        ? '$indent${body.substring(removeCount)}'
        : '$indent$addPrefix$body';

    if (!allNumbered) {
      if (lineIndex == nextCursor.line) {
        nextCursor = TextPosition(
          line: nextCursor.line,
          column: _adjustLinePrefixColumn(
            column: nextCursor.column,
            leadingWhitespace: leadingWhitespace,
            delta: addCount,
            remove: false,
          ),
        );
      }
      adjustedBase = _adjustLinePrefixPosition(
        adjustedBase,
        line: lineIndex,
        leadingWhitespace: leadingWhitespace,
        delta: addCount,
        remove: false,
      );
      adjustedExtent = _adjustLinePrefixPosition(
        adjustedExtent,
        line: lineIndex,
        leadingWhitespace: leadingWhitespace,
        delta: addCount,
        remove: false,
      );
      continue;
    }

    if (lineIndex == nextCursor.line) {
      nextCursor = TextPosition(
        line: nextCursor.line,
        column: _adjustLinePrefixColumn(
          column: nextCursor.column,
          leadingWhitespace: leadingWhitespace,
          delta: removeCount,
          remove: true,
        ),
      );
    }
    adjustedBase = _adjustLinePrefixPosition(
      adjustedBase,
      line: lineIndex,
      leadingWhitespace: leadingWhitespace,
      delta: removeCount,
      remove: true,
    );
    adjustedExtent = _adjustLinePrefixPosition(
      adjustedExtent,
      line: lineIndex,
      leadingWhitespace: leadingWhitespace,
      delta: removeCount,
      remove: true,
    );
  }

  if (_listStringEquals(lineTexts, lines)) {
    return _unchangedLineResult(
      lineTexts,
      cursor: clampedCursor,
      selectionBase: selectionBase,
      selectionExtent: selectionExtent,
    );
  }

  if (hasSelection && adjustedBase != null && adjustedExtent != null) {
    final clampedBase = _clampPositionToLines(adjustedBase, lineTexts);
    final clampedExtent = _clampPositionToLines(adjustedExtent, lineTexts);
    return TextLineCommandResult(
      lines: lineTexts,
      cursor: clampedExtent,
      selectionBase: clampedBase,
      selectionExtent: clampedExtent,
    );
  }

  return TextLineCommandResult(
    lines: lineTexts,
    cursor: _clampPositionToLines(nextCursor, lineTexts),
  );
}

TextLineCommandResult renumberNumberedList(
  List<String> lines, {
  required TextPosition cursor,
  TextPosition? selectionBase,
  TextPosition? selectionExtent,
  int startAt = 1,
}) {
  final lineTexts = lines.isEmpty ? <String>[''] : List<String>.from(lines);
  final clampedCursor = _clampPositionToLines(cursor, lineTexts);
  final selection = selectionBase != null && selectionExtent != null
      ? TextSelection(base: selectionBase, extent: selectionExtent)
      : null;
  final hasSelection = selection != null && !selection.isCollapsed;
  final startLine = hasSelection ? selection.start.line : clampedCursor.line;
  final endLine = hasSelection ? selection.end.line : clampedCursor.line;
  final initialNumber = startAt < 1 ? 1 : startAt;

  var hasNumberedLine = false;
  var adjustedBase = selectionBase;
  var adjustedExtent = selectionExtent;
  var nextCursor = clampedCursor;
  var nextNumber = initialNumber;

  for (var lineIndex = startLine; lineIndex <= endLine; lineIndex++) {
    final line = lineTexts[lineIndex];
    final leadingWhitespace = line.length - line.trimLeft().length;
    final indent = line.substring(0, leadingWhitespace);
    final body = line.substring(leadingWhitespace);
    final numberedPrefixLength = _leadingNumberedPrefixLength(body);
    if (numberedPrefixLength == null) {
      continue;
    }

    hasNumberedLine = true;
    final nextPrefix = '${nextNumber++}. ';
    lineTexts[lineIndex] =
        '$indent$nextPrefix${body.substring(numberedPrefixLength)}';
    final delta = nextPrefix.length - numberedPrefixLength;

    if (delta == 0) {
      continue;
    }

    if (lineIndex == nextCursor.line) {
      nextCursor = TextPosition(
        line: nextCursor.line,
        column: _adjustLinePrefixColumnDelta(
          column: nextCursor.column,
          leadingWhitespace: leadingWhitespace,
          delta: delta,
        ),
      );
    }
    adjustedBase = _adjustLinePrefixPositionDelta(
      adjustedBase,
      line: lineIndex,
      leadingWhitespace: leadingWhitespace,
      delta: delta,
    );
    adjustedExtent = _adjustLinePrefixPositionDelta(
      adjustedExtent,
      line: lineIndex,
      leadingWhitespace: leadingWhitespace,
      delta: delta,
    );
  }

  if (!hasNumberedLine || _listStringEquals(lineTexts, lines)) {
    return _unchangedLineResult(
      lineTexts,
      cursor: clampedCursor,
      selectionBase: selectionBase,
      selectionExtent: selectionExtent,
    );
  }

  if (hasSelection && adjustedBase != null && adjustedExtent != null) {
    final clampedBase = _clampPositionToLines(adjustedBase, lineTexts);
    final clampedExtent = _clampPositionToLines(adjustedExtent, lineTexts);
    return TextLineCommandResult(
      lines: lineTexts,
      cursor: clampedExtent,
      selectionBase: clampedBase,
      selectionExtent: clampedExtent,
    );
  }

  return TextLineCommandResult(
    lines: lineTexts,
    cursor: _clampPositionToLines(nextCursor, lineTexts),
  );
}

TextLineCommandResult toggleHeadingPrefix(
  List<String> lines, {
  required TextPosition cursor,
  TextPosition? selectionBase,
  TextPosition? selectionExtent,
  int level = 1,
}) {
  final lineTexts = lines.isEmpty ? <String>[''] : List<String>.from(lines);
  final clampedCursor = _clampPositionToLines(cursor, lineTexts);
  final selection = selectionBase != null && selectionExtent != null
      ? TextSelection(base: selectionBase, extent: selectionExtent)
      : null;
  final hasSelection = selection != null && !selection.isCollapsed;
  final startLine = hasSelection ? selection.start.line : clampedCursor.line;
  final endLine = hasSelection ? selection.end.line : clampedCursor.line;
  final targetLevel = level.clamp(1, 6);
  final targetPrefix = '${'#' * targetLevel} ';

  var hasRelevantLine = false;
  var allAtTargetLevel = true;
  for (var lineIndex = startLine; lineIndex <= endLine; lineIndex++) {
    final line = lineTexts[lineIndex];
    final leadingWhitespace = line.length - line.trimLeft().length;
    final body = line.substring(leadingWhitespace);
    final headingPrefix = _leadingHeadingPrefix(body);
    if (body.trim().isEmpty && headingPrefix == null) {
      continue;
    }
    hasRelevantLine = true;
    if (headingPrefix == null || headingPrefix.level != targetLevel) {
      allAtTargetLevel = false;
      break;
    }
  }
  if (!hasRelevantLine) {
    return _unchangedLineResult(
      lineTexts,
      cursor: clampedCursor,
      selectionBase: selectionBase,
      selectionExtent: selectionExtent,
    );
  }

  var adjustedBase = selectionBase;
  var adjustedExtent = selectionExtent;
  var nextCursor = clampedCursor;

  for (var lineIndex = startLine; lineIndex <= endLine; lineIndex++) {
    final line = lineTexts[lineIndex];
    final leadingWhitespace = line.length - line.trimLeft().length;
    final indent = line.substring(0, leadingWhitespace);
    final body = line.substring(leadingWhitespace);
    final headingPrefix = _leadingHeadingPrefix(body);
    if (body.trim().isEmpty && headingPrefix == null) {
      continue;
    }

    final removeCount = headingPrefix?.length ?? 0;
    final nextBody = removeCount > 0 ? body.substring(removeCount) : body;
    final delta = allAtTargetLevel
        ? -removeCount
        : targetPrefix.length - removeCount;
    lineTexts[lineIndex] = allAtTargetLevel
        ? '$indent$nextBody'
        : '$indent$targetPrefix$nextBody';

    if (delta == 0) {
      continue;
    }

    if (lineIndex == nextCursor.line) {
      nextCursor = TextPosition(
        line: nextCursor.line,
        column: _adjustLinePrefixColumnDelta(
          column: nextCursor.column,
          leadingWhitespace: leadingWhitespace,
          delta: delta,
        ),
      );
    }
    adjustedBase = _adjustLinePrefixPositionDelta(
      adjustedBase,
      line: lineIndex,
      leadingWhitespace: leadingWhitespace,
      delta: delta,
    );
    adjustedExtent = _adjustLinePrefixPositionDelta(
      adjustedExtent,
      line: lineIndex,
      leadingWhitespace: leadingWhitespace,
      delta: delta,
    );
  }

  if (_listStringEquals(lineTexts, lines)) {
    return _unchangedLineResult(
      lineTexts,
      cursor: clampedCursor,
      selectionBase: selectionBase,
      selectionExtent: selectionExtent,
    );
  }

  if (hasSelection && adjustedBase != null && adjustedExtent != null) {
    final clampedBase = _clampPositionToLines(adjustedBase, lineTexts);
    final clampedExtent = _clampPositionToLines(adjustedExtent, lineTexts);
    return TextLineCommandResult(
      lines: lineTexts,
      cursor: clampedExtent,
      selectionBase: clampedBase,
      selectionExtent: clampedExtent,
    );
  }

  return TextLineCommandResult(
    lines: lineTexts,
    cursor: _clampPositionToLines(nextCursor, lineTexts),
  );
}

TextLineCommandResult toggleChecklistState(
  List<String> lines, {
  required TextPosition cursor,
  TextPosition? selectionBase,
  TextPosition? selectionExtent,
  String checkedMarker = 'x',
}) {
  final lineTexts = lines.isEmpty ? <String>[''] : List<String>.from(lines);
  final clampedCursor = _clampPositionToLines(cursor, lineTexts);
  final selection = selectionBase != null && selectionExtent != null
      ? TextSelection(base: selectionBase, extent: selectionExtent)
      : null;
  final hasSelection = selection != null && !selection.isCollapsed;
  final startLine = hasSelection ? selection.start.line : clampedCursor.line;
  final endLine = hasSelection ? selection.end.line : clampedCursor.line;
  final marker = checkedMarker.isEmpty ? 'x' : checkedMarker[0];

  var hasChecklist = false;
  var allChecked = true;
  for (var lineIndex = startLine; lineIndex <= endLine; lineIndex++) {
    final line = lineTexts[lineIndex];
    final leadingWhitespace = line.length - line.trimLeft().length;
    final body = line.substring(leadingWhitespace);
    final prefixLength = _leadingChecklistPrefixLength(body);
    if (prefixLength == null) {
      continue;
    }
    hasChecklist = true;
    if (!_isChecklistChecked(body)) {
      allChecked = false;
      break;
    }
  }
  if (!hasChecklist) {
    return _unchangedLineResult(
      lineTexts,
      cursor: clampedCursor,
      selectionBase: selectionBase,
      selectionExtent: selectionExtent,
    );
  }

  for (var lineIndex = startLine; lineIndex <= endLine; lineIndex++) {
    final line = lineTexts[lineIndex];
    final leadingWhitespace = line.length - line.trimLeft().length;
    final indent = line.substring(0, leadingWhitespace);
    final body = line.substring(leadingWhitespace);
    final prefixLength = _leadingChecklistPrefixLength(body);
    if (prefixLength == null) {
      continue;
    }

    final rest = body.substring(prefixLength);
    final hasBody = rest.isNotEmpty;
    final nextPrefix = allChecked ? '- [ ]' : '- [$marker]';
    lineTexts[lineIndex] = '$indent$nextPrefix${hasBody ? ' ' : ''}$rest';
  }

  if (_listStringEquals(lineTexts, lines)) {
    return _unchangedLineResult(
      lineTexts,
      cursor: clampedCursor,
      selectionBase: selectionBase,
      selectionExtent: selectionExtent,
    );
  }

  return TextLineCommandResult(
    lines: lineTexts,
    cursor: _clampPositionToLines(clampedCursor, lineTexts),
    selectionBase: selectionBase == null
        ? null
        : _clampPositionToLines(selectionBase, lineTexts),
    selectionExtent: selectionExtent == null
        ? null
        : _clampPositionToLines(selectionExtent, lineTexts),
  );
}

TextLineCommandResult moveSelectedLines(
  List<String> lines, {
  required TextPosition cursor,
  TextPosition? selectionBase,
  TextPosition? selectionExtent,
  required int direction,
}) {
  if (direction != -1 && direction != 1) {
    return _unchangedLineResult(
      lines,
      cursor: cursor,
      selectionBase: selectionBase,
      selectionExtent: selectionExtent,
    );
  }

  final lineTexts = lines.isEmpty ? <String>[''] : List<String>.from(lines);
  final clampedCursor = _clampPositionToLines(cursor, lineTexts);
  final clampedBase = selectionBase == null
      ? null
      : _clampPositionToLines(selectionBase, lineTexts);
  final clampedExtent = selectionExtent == null
      ? null
      : _clampPositionToLines(selectionExtent, lineTexts);
  final span = _selectedLineSpan(
    clampedCursor,
    selectionBase: clampedBase,
    selectionExtent: clampedExtent,
  );
  final startLine = span.startLine;
  final endLine = span.endLine;

  if (direction < 0 && startLine == 0) {
    return _unchangedLineResult(
      lineTexts,
      cursor: clampedCursor,
      selectionBase: selectionBase,
      selectionExtent: selectionExtent,
    );
  }
  if (direction > 0 && endLine >= lineTexts.length - 1) {
    return _unchangedLineResult(
      lineTexts,
      cursor: clampedCursor,
      selectionBase: selectionBase,
      selectionExtent: selectionExtent,
    );
  }

  final movedLines = lineTexts
      .sublist(startLine, endLine + 1)
      .map((line) => line)
      .toList(growable: false);
  lineTexts.removeRange(startLine, endLine + 1);
  final insertionLine = direction < 0 ? startLine - 1 : startLine + 1;
  lineTexts.insertAll(insertionLine, movedLines);

  final state = EditorState(
    line: clampedCursor.line,
    column: clampedCursor.column,
  );
  if (clampedBase != null && clampedExtent != null) {
    state.setSelection(
      base: clampedBase,
      extent: clampedExtent,
      cursor: clampedCursor,
    );
  }
  state.shiftRowsInRange(
    startLine: startLine,
    endLine: endLine,
    delta: direction,
    maxLine: lineTexts.length - 1,
    lineLength: (line) => lineTexts[line].length,
  );

  return _lineResultFromSnapshot(
    lineTexts,
    lineSnapshotFromEditorState(
      state,
      lineCount: lineTexts.length,
      lineLength: (line) => lineTexts[line].length,
    ),
  );
}

TextLineCommandResult duplicateSelectedLinesAbove(
  List<String> lines, {
  required TextPosition cursor,
  TextPosition? selectionBase,
  TextPosition? selectionExtent,
}) {
  final lineTexts = lines.isEmpty ? <String>[''] : List<String>.from(lines);
  final clampedCursor = _clampPositionToLines(cursor, lineTexts);
  final clampedBase = selectionBase == null
      ? null
      : _clampPositionToLines(selectionBase, lineTexts);
  final clampedExtent = selectionExtent == null
      ? null
      : _clampPositionToLines(selectionExtent, lineTexts);
  final span = _selectedLineSpan(
    clampedCursor,
    selectionBase: clampedBase,
    selectionExtent: clampedExtent,
  );
  final startLine = span.startLine;
  final endLine = span.endLine;
  final blockHeight = endLine - startLine + 1;
  final duplicatedLines = lineTexts
      .sublist(startLine, endLine + 1)
      .map((line) => line)
      .toList(growable: false);
  lineTexts.insertAll(startLine, duplicatedLines);

  final nextCursor = _duplicateAbovePosition(
    clampedCursor,
    startLine: startLine,
    endLine: endLine,
    delta: blockHeight,
    lines: lineTexts,
  );
  final nextBase = selectionBase == null
      ? null
      : _duplicateAbovePosition(
          clampedBase!,
          startLine: startLine,
          endLine: endLine,
          delta: blockHeight,
          lines: lineTexts,
        );
  final nextExtent = selectionExtent == null
      ? null
      : _duplicateAbovePosition(
          clampedExtent!,
          startLine: startLine,
          endLine: endLine,
          delta: blockHeight,
          lines: lineTexts,
        );

  return _lineResultFromSnapshot(
    lineTexts,
    TextLineStateSnapshot(
      cursor: nextCursor,
      selectionBase: nextBase,
      selectionExtent: nextExtent,
    ),
  );
}

TextLineCommandResult duplicateSelectedLinesBelow(
  List<String> lines, {
  required TextPosition cursor,
  TextPosition? selectionBase,
  TextPosition? selectionExtent,
}) {
  final lineTexts = lines.isEmpty ? <String>[''] : List<String>.from(lines);
  final clampedCursor = _clampPositionToLines(cursor, lineTexts);
  final clampedBase = selectionBase == null
      ? null
      : _clampPositionToLines(selectionBase, lineTexts);
  final clampedExtent = selectionExtent == null
      ? null
      : _clampPositionToLines(selectionExtent, lineTexts);
  final span = _selectedLineSpan(
    clampedCursor,
    selectionBase: clampedBase,
    selectionExtent: clampedExtent,
  );
  final startLine = span.startLine;
  final endLine = span.endLine;
  final blockHeight = endLine - startLine + 1;
  final duplicatedLines = lineTexts
      .sublist(startLine, endLine + 1)
      .map((line) => line)
      .toList(growable: false);
  lineTexts.insertAll(endLine + 1, duplicatedLines);

  final state = EditorState(
    line: clampedCursor.line,
    column: clampedCursor.column,
  );
  if (clampedBase != null && clampedExtent != null) {
    state.setSelection(
      base: clampedBase,
      extent: clampedExtent,
      cursor: clampedCursor,
    );
  }
  state.shiftRowsInRange(
    startLine: startLine,
    endLine: endLine,
    delta: blockHeight,
    maxLine: lineTexts.length - 1,
    lineLength: (line) => lineTexts[line].length,
  );

  return _lineResultFromSnapshot(
    lineTexts,
    lineSnapshotFromEditorState(
      state,
      lineCount: lineTexts.length,
      lineLength: (line) => lineTexts[line].length,
    ),
  );
}

TextCommandResult deleteSelection(
  List<String> graphemes, {
  int? selectionBaseOffset,
  int? selectionExtentOffset,
  required int cursorOffset,
}) {
  final selection = normalizedSelectionRange(
    selectionBaseOffset,
    selectionExtentOffset,
  );
  if (selection == null || selection.start == selection.end) {
    return _unchangedResult(
      graphemes,
      cursorOffset: cursorOffset,
      selectionBaseOffset: selectionBaseOffset,
      selectionExtentOffset: selectionExtentOffset,
    );
  }

  final result = edit_ops.removeRange(
    graphemes,
    start: selection.start,
    end: selection.end,
  );
  return TextCommandResult(
    graphemes: result.graphemes,
    cursorOffset: result.cursorOffset,
  );
}

TextCommandResult transformSelectionOrLine(
  List<String> graphemes, {
  required int cursorOffset,
  required int lineStartOffset,
  required int lineEndOffset,
  int? selectionBaseOffset,
  int? selectionExtentOffset,
  required String Function(String text) transform,
}) {
  final selection = normalizedSelectionRange(
    selectionBaseOffset,
    selectionExtentOffset,
  );
  final hasSelection = selection != null && selection.start != selection.end;
  final start = hasSelection
      ? selection.start
      : lineStartOffset.clamp(0, graphemes.length);
  final end = hasSelection
      ? selection.end
      : lineEndOffset.clamp(start, graphemes.length);

  if (start == end) {
    return _unchangedResult(
      graphemes,
      cursorOffset: cursorOffset,
      selectionBaseOffset: selectionBaseOffset,
      selectionExtentOffset: selectionExtentOffset,
    );
  }

  final original = graphemes.sublist(start, end).join();
  final transformed = transform(original);
  if (transformed == original) {
    return _unchangedResult(
      graphemes,
      cursorOffset: cursorOffset,
      selectionBaseOffset: selectionBaseOffset,
      selectionExtentOffset: selectionExtentOffset,
    );
  }

  final replacement = transformed.characters.toList(growable: false);
  final result = edit_ops.replaceRange(
    graphemes,
    start: start,
    end: end,
    replacement: replacement,
  );
  final nextExtent = start + replacement.length;

  if (hasSelection) {
    return TextCommandResult(
      graphemes: result.graphemes,
      cursorOffset: nextExtent,
      selectionBaseOffset: start,
      selectionExtentOffset: nextExtent,
    );
  }

  final relativeCursor = (cursorOffset - start).clamp(0, replacement.length);
  return TextCommandResult(
    graphemes: result.graphemes,
    cursorOffset: start + relativeCursor,
  );
}

TextCommandResult transformWordOrAdjacent(
  List<String> graphemes, {
  required int cursorOffset,
  required nav.GraphemePredicate isWord,
  required String Function(String text) transform,
}) {
  final range = nav.wordRangeForTransform(
    graphemes,
    cursorOffset,
    isWord: isWord,
  );
  if (range == null || range.start == range.end) {
    return _unchangedResult(graphemes, cursorOffset: cursorOffset);
  }

  final original = graphemes.sublist(range.start, range.end).join();
  final transformed = transform(original);
  if (transformed == original) {
    return _unchangedResult(graphemes, cursorOffset: cursorOffset);
  }

  final replacement = transformed.characters.toList(growable: false);
  final result = edit_ops.replaceRange(
    graphemes,
    start: range.start,
    end: range.end,
    replacement: replacement,
  );
  return TextCommandResult(
    graphemes: result.graphemes,
    cursorOffset: range.start + replacement.length,
  );
}

TextCommandResult insertAutoPair(
  List<String> graphemes, {
  required int cursorOffset,
  int? selectionBaseOffset,
  int? selectionExtentOffset,
  required List<String> opening,
  required List<String> closing,
}) {
  final selection = normalizedSelectionRange(
    selectionBaseOffset,
    selectionExtentOffset,
  );
  final hasSelection = selection != null && selection.start != selection.end;
  if (hasSelection) {
    return wrapSelection(
      graphemes,
      cursorOffset: cursorOffset,
      selectionBaseOffset: selectionBaseOffset,
      selectionExtentOffset: selectionExtentOffset,
      before: opening,
      after: closing,
    );
  }

  final inserted = <String>[...opening, ...closing];
  if (inserted.isEmpty) {
    return _unchangedResult(
      graphemes,
      cursorOffset: cursorOffset,
      selectionBaseOffset: selectionBaseOffset,
      selectionExtentOffset: selectionExtentOffset,
    );
  }

  final result = edit_ops.insertAtCursor(graphemes, cursorOffset, inserted);
  final nextCursor = cursorOffset.clamp(0, graphemes.length) + opening.length;
  return TextCommandResult(
    graphemes: result.graphemes,
    cursorOffset: nextCursor,
  );
}

TextCursorCommandResult skipClosingDelimiter(
  List<String> graphemes, {
  required int cursorOffset,
  int? selectionBaseOffset,
  int? selectionExtentOffset,
  required List<String> closing,
  bool clearSelection = false,
}) {
  if (closing.isEmpty) {
    return _unchangedCursorResult(
      cursorOffset: cursorOffset,
      selectionBaseOffset: selectionBaseOffset,
      selectionExtentOffset: selectionExtentOffset,
    );
  }

  final start = cursorOffset.clamp(0, graphemes.length);
  final end = start + closing.length;
  if (end > graphemes.length ||
      !_startsWithGraphemeSequence(graphemes.sublist(start, end), closing)) {
    return _unchangedCursorResult(
      cursorOffset: cursorOffset,
      selectionBaseOffset: selectionBaseOffset,
      selectionExtentOffset: selectionExtentOffset,
    );
  }

  return moveCursorToOffset(
    textLength: graphemes.length,
    cursorOffset: cursorOffset,
    selectionBaseOffset: selectionBaseOffset,
    selectionExtentOffset: selectionExtentOffset,
    targetOffset: end,
    clearSelection: clearSelection,
  );
}

TextCommandResult deleteSurroundingPair(
  List<String> graphemes, {
  required int cursorOffset,
  int? selectionBaseOffset,
  int? selectionExtentOffset,
  required Map<String, String> surroundPairs,
}) {
  final selection = normalizedSelectionRange(
    selectionBaseOffset,
    selectionExtentOffset,
  );
  if (selection != null && selection.start != selection.end) {
    return _unchangedResult(
      graphemes,
      cursorOffset: cursorOffset,
      selectionBaseOffset: selectionBaseOffset,
      selectionExtentOffset: selectionExtentOffset,
    );
  }

  if (cursorOffset <= 0 || cursorOffset >= graphemes.length) {
    return _unchangedResult(
      graphemes,
      cursorOffset: cursorOffset,
      selectionBaseOffset: selectionBaseOffset,
      selectionExtentOffset: selectionExtentOffset,
    );
  }

  final opening = graphemes[cursorOffset - 1];
  final closing = graphemes[cursorOffset];
  if (surroundPairs[opening] != closing) {
    return _unchangedResult(
      graphemes,
      cursorOffset: cursorOffset,
      selectionBaseOffset: selectionBaseOffset,
      selectionExtentOffset: selectionExtentOffset,
    );
  }

  final result = edit_ops.removeRange(
    graphemes,
    start: cursorOffset - 1,
    end: cursorOffset + 1,
    cursorOffset: cursorOffset - 1,
  );
  return TextCommandResult(
    graphemes: result.graphemes,
    cursorOffset: result.cursorOffset,
  );
}

TextCommandResult toggleDelimitedSegment(
  List<String> graphemes, {
  required int cursorOffset,
  int? selectionBaseOffset,
  int? selectionExtentOffset,
  required int rangeStartOffset,
  required int rangeEndOffset,
  required String startDelimiter,
  required String endDelimiter,
}) {
  final selection = normalizedSelectionRange(
    selectionBaseOffset,
    selectionExtentOffset,
  );
  final hasSelection = selection != null && selection.start != selection.end;
  final start = hasSelection ? selection.start : rangeStartOffset;
  final end = hasSelection ? selection.end : rangeEndOffset;
  if (start >= end) {
    return _unchangedResult(
      graphemes,
      cursorOffset: cursorOffset,
      selectionBaseOffset: selectionBaseOffset,
      selectionExtentOffset: selectionExtentOffset,
    );
  }

  final clampedStart = start.clamp(0, graphemes.length);
  final clampedEnd = end.clamp(0, graphemes.length);
  if (clampedStart >= clampedEnd) {
    return _unchangedResult(
      graphemes,
      cursorOffset: cursorOffset,
      selectionBaseOffset: selectionBaseOffset,
      selectionExtentOffset: selectionExtentOffset,
    );
  }

  final startGraphemes = startDelimiter.characters.toList(growable: false);
  final endGraphemes = endDelimiter.characters.toList(growable: false);
  final segment = graphemes.sublist(clampedStart, clampedEnd);
  final leadingWhitespace = _leadingWhitespaceCount(segment);
  final trailingWhitespace = _trailingWhitespaceCount(segment);
  final coreEnd = segment.length - trailingWhitespace;
  final core = segment.sublist(leadingWhitespace, coreEnd);

  List<String> replacement;
  var selectionStart = leadingWhitespace;
  late int selectionEnd;

  if (_startsWithGraphemeSequence(core, startGraphemes) &&
      _endsWithGraphemeSequence(core, endGraphemes)) {
    var innerStart = leadingWhitespace + startGraphemes.length;
    var innerEnd = coreEnd - endGraphemes.length;
    if (innerStart < innerEnd && segment[innerStart] == ' ') {
      innerStart++;
    }
    if (innerStart < innerEnd && segment[innerEnd - 1] == ' ') {
      innerEnd--;
    }

    replacement = <String>[
      ...segment.sublist(0, leadingWhitespace),
      ...segment.sublist(innerStart, innerEnd),
      ...segment.sublist(coreEnd),
    ];
    selectionEnd = selectionStart + (innerEnd - innerStart);
  } else {
    final separator = core.isEmpty ? const <String>[] : const <String>[' '];
    replacement = <String>[
      ...segment.sublist(0, leadingWhitespace),
      ...startGraphemes,
      ...separator,
      ...core,
      ...separator,
      ...endGraphemes,
      ...segment.sublist(coreEnd),
    ];
    selectionEnd =
        selectionStart +
        startGraphemes.length +
        separator.length +
        core.length +
        separator.length +
        endGraphemes.length;
  }

  if (_listStringEquals(replacement, segment)) {
    return _unchangedResult(
      graphemes,
      cursorOffset: cursorOffset,
      selectionBaseOffset: selectionBaseOffset,
      selectionExtentOffset: selectionExtentOffset,
    );
  }

  final result = edit_ops.replaceRange(
    graphemes,
    start: clampedStart,
    end: clampedEnd,
    replacement: replacement,
  );
  final nextSelectionStart = clampedStart + selectionStart;
  final nextSelectionEnd = clampedStart + selectionEnd;

  if (hasSelection) {
    return TextCommandResult(
      graphemes: result.graphemes,
      cursorOffset: nextSelectionEnd,
      selectionBaseOffset: nextSelectionStart,
      selectionExtentOffset: nextSelectionEnd,
    );
  }

  return TextCommandResult(
    graphemes: result.graphemes,
    cursorOffset: nextSelectionEnd,
  );
}

TextCommandResult insertIndentedNewline(
  List<String> graphemes, {
  required int cursorOffset,
  int? selectionBaseOffset,
  int? selectionExtentOffset,
  required List<String> baseIndent,
  List<String> additionalIndent = const <String>[],
  List<String> trailingSuffix = const <String>[],
  int trailingSuffixReplaceCount = 0,
}) {
  final selection = normalizedSelectionRange(
    selectionBaseOffset,
    selectionExtentOffset,
  );
  final hasSelection = selection != null && selection.start != selection.end;
  final start = hasSelection ? selection.start : cursorOffset;
  final end = hasSelection ? selection.end : cursorOffset;
  final clampedStart = start.clamp(0, graphemes.length);
  var clampedEnd = end.clamp(clampedStart, graphemes.length);
  if (!hasSelection && trailingSuffixReplaceCount > 0) {
    clampedEnd = (clampedEnd + trailingSuffixReplaceCount).clamp(
      clampedStart,
      graphemes.length,
    );
  }

  final cursorInsertion = <String>['\n', ...baseIndent, ...additionalIndent];
  final replacement = <String>[...cursorInsertion, ...trailingSuffix];
  final result = edit_ops.replaceRange(
    graphemes,
    start: clampedStart,
    end: clampedEnd,
    replacement: replacement,
  );

  return TextCommandResult(
    graphemes: result.graphemes,
    cursorOffset: clampedStart + cursorInsertion.length,
  );
}

TextCommandResult wrapSelection(
  List<String> graphemes, {
  required int cursorOffset,
  int? selectionBaseOffset,
  int? selectionExtentOffset,
  required List<String> before,
  List<String>? after,
}) {
  final selection = normalizedSelectionRange(
    selectionBaseOffset,
    selectionExtentOffset,
  );
  if (selection == null || selection.start == selection.end) {
    return _unchangedResult(
      graphemes,
      cursorOffset: cursorOffset,
      selectionBaseOffset: selectionBaseOffset,
      selectionExtentOffset: selectionExtentOffset,
    );
  }

  final suffix = after ?? before;
  if (before.isEmpty && suffix.isEmpty) {
    return _unchangedResult(
      graphemes,
      cursorOffset: cursorOffset,
      selectionBaseOffset: selectionBaseOffset,
      selectionExtentOffset: selectionExtentOffset,
    );
  }

  final selected = graphemes.sublist(selection.start, selection.end);
  final replacement = <String>[...before, ...selected, ...suffix];
  final result = edit_ops.replaceRange(
    graphemes,
    start: selection.start,
    end: selection.end,
    replacement: replacement,
  );
  final nextSelectionStart = selection.start + before.length;
  final nextSelectionEnd = nextSelectionStart + selected.length;

  return TextCommandResult(
    graphemes: result.graphemes,
    cursorOffset: nextSelectionEnd,
    selectionBaseOffset: nextSelectionStart,
    selectionExtentOffset: nextSelectionEnd,
  );
}

TextCommandResult unwrapSelection(
  List<String> graphemes, {
  required int cursorOffset,
  int? selectionBaseOffset,
  int? selectionExtentOffset,
  required Map<String, String> surroundPairs,
}) {
  final selection = normalizedSelectionRange(
    selectionBaseOffset,
    selectionExtentOffset,
  );
  if (selection == null || selection.start == selection.end) {
    return _unchangedResult(
      graphemes,
      cursorOffset: cursorOffset,
      selectionBaseOffset: selectionBaseOffset,
      selectionExtentOffset: selectionExtentOffset,
    );
  }

  if (selection.start < 1 || selection.end >= graphemes.length) {
    return _unchangedResult(
      graphemes,
      cursorOffset: cursorOffset,
      selectionBaseOffset: selectionBaseOffset,
      selectionExtentOffset: selectionExtentOffset,
    );
  }

  final before = graphemes[selection.start - 1];
  final after = graphemes[selection.end];
  if (surroundPairs[before] != after) {
    return _unchangedResult(
      graphemes,
      cursorOffset: cursorOffset,
      selectionBaseOffset: selectionBaseOffset,
      selectionExtentOffset: selectionExtentOffset,
    );
  }

  final selected = graphemes.sublist(selection.start, selection.end);
  final result = edit_ops.replaceRange(
    graphemes,
    start: selection.start - 1,
    end: selection.end + 1,
    replacement: selected,
  );
  final nextSelectionStart = selection.start - 1;
  final nextSelectionEnd = nextSelectionStart + selected.length;

  return TextCommandResult(
    graphemes: result.graphemes,
    cursorOffset: nextSelectionEnd,
    selectionBaseOffset: nextSelectionStart,
    selectionExtentOffset: nextSelectionEnd,
  );
}

TextCommandResult deletePreviousOrSelection(
  List<String> graphemes, {
  required int cursorOffset,
  int? selectionBaseOffset,
  int? selectionExtentOffset,
}) {
  final deletedSelection = deleteSelection(
    graphemes,
    selectionBaseOffset: selectionBaseOffset,
    selectionExtentOffset: selectionExtentOffset,
    cursorOffset: cursorOffset,
  );
  if (deletedSelection.changed) {
    return deletedSelection;
  }

  final result = edit_ops.deletePreviousGrapheme(graphemes, cursorOffset);
  return TextCommandResult(
    graphemes: result.graphemes,
    cursorOffset: result.cursorOffset,
    changed:
        result.cursorOffset != cursorOffset ||
        result.graphemes.length != graphemes.length,
  );
}

TextCommandResult deletePrevious(
  List<String> graphemes, {
  required int cursorOffset,
  int? selectionBaseOffset,
  int? selectionExtentOffset,
}) {
  if (cursorOffset <= 0) {
    return _unchangedResult(
      graphemes,
      cursorOffset: cursorOffset,
      selectionBaseOffset: selectionBaseOffset,
      selectionExtentOffset: selectionExtentOffset,
    );
  }

  final result = edit_ops.deletePreviousGrapheme(graphemes, cursorOffset);
  return TextCommandResult(
    graphemes: result.graphemes,
    cursorOffset: result.cursorOffset,
  );
}

TextCommandResult deleteNextOrSelection(
  List<String> graphemes, {
  required int cursorOffset,
  int? selectionBaseOffset,
  int? selectionExtentOffset,
}) {
  final deletedSelection = deleteSelection(
    graphemes,
    selectionBaseOffset: selectionBaseOffset,
    selectionExtentOffset: selectionExtentOffset,
    cursorOffset: cursorOffset,
  );
  if (deletedSelection.changed) {
    return deletedSelection;
  }

  final result = edit_ops.deleteNextGrapheme(graphemes, cursorOffset);
  return TextCommandResult(
    graphemes: result.graphemes,
    cursorOffset: result.cursorOffset,
    changed:
        result.cursorOffset != cursorOffset ||
        result.graphemes.length != graphemes.length,
  );
}

TextCommandResult deleteNext(
  List<String> graphemes, {
  required int cursorOffset,
  int? selectionBaseOffset,
  int? selectionExtentOffset,
}) {
  if (cursorOffset >= graphemes.length) {
    return _unchangedResult(
      graphemes,
      cursorOffset: cursorOffset,
      selectionBaseOffset: selectionBaseOffset,
      selectionExtentOffset: selectionExtentOffset,
    );
  }

  final result = edit_ops.deleteNextGrapheme(graphemes, cursorOffset);
  return TextCommandResult(
    graphemes: result.graphemes,
    cursorOffset: result.cursorOffset,
  );
}

TextCommandResult deleteWordBackward(
  List<String> graphemes, {
  required int cursorOffset,
  int? selectionBaseOffset,
  int? selectionExtentOffset,
  required nav.GraphemePredicate isWord,
}) {
  if (cursorOffset <= 0) {
    return _unchangedResult(
      graphemes,
      cursorOffset: cursorOffset,
      selectionBaseOffset: selectionBaseOffset,
      selectionExtentOffset: selectionExtentOffset,
    );
  }

  final range = nav.deleteWordBackwardRange(
    graphemes,
    cursorOffset,
    isWord: isWord,
  );
  if (range.start >= cursorOffset) {
    return _unchangedResult(
      graphemes,
      cursorOffset: cursorOffset,
      selectionBaseOffset: selectionBaseOffset,
      selectionExtentOffset: selectionExtentOffset,
    );
  }

  final result = edit_ops.removeRange(
    graphemes,
    start: range.start,
    end: cursorOffset,
  );
  return TextCommandResult(
    graphemes: result.graphemes,
    cursorOffset: result.cursorOffset,
  );
}

TextCommandResult deleteWordForward(
  List<String> graphemes, {
  required int cursorOffset,
  int? selectionBaseOffset,
  int? selectionExtentOffset,
  required nav.GraphemePredicate isWord,
}) {
  if (cursorOffset >= graphemes.length) {
    return _unchangedResult(
      graphemes,
      cursorOffset: cursorOffset,
      selectionBaseOffset: selectionBaseOffset,
      selectionExtentOffset: selectionExtentOffset,
    );
  }

  final range = nav.deleteWordForwardRange(
    graphemes,
    cursorOffset,
    isWord: isWord,
  );
  if (range.end <= cursorOffset) {
    return _unchangedResult(
      graphemes,
      cursorOffset: cursorOffset,
      selectionBaseOffset: selectionBaseOffset,
      selectionExtentOffset: selectionExtentOffset,
    );
  }

  final result = edit_ops.removeRange(
    graphemes,
    start: cursorOffset,
    end: range.end,
    cursorOffset: cursorOffset,
  );
  return TextCommandResult(
    graphemes: result.graphemes,
    cursorOffset: result.cursorOffset,
  );
}

TextCommandResult deleteToLineStart(
  List<String> graphemes, {
  required int cursorOffset,
  int? selectionBaseOffset,
  int? selectionExtentOffset,
  required int lineStartOffset,
}) {
  final start = lineStartOffset.clamp(0, graphemes.length);
  final end = cursorOffset.clamp(0, graphemes.length);
  if (start >= end) {
    return _unchangedResult(
      graphemes,
      cursorOffset: cursorOffset,
      selectionBaseOffset: selectionBaseOffset,
      selectionExtentOffset: selectionExtentOffset,
    );
  }

  final result = edit_ops.removeRange(
    graphemes,
    start: start,
    end: end,
    cursorOffset: start,
  );
  return TextCommandResult(
    graphemes: result.graphemes,
    cursorOffset: result.cursorOffset,
  );
}

TextCommandResult deleteToLineEnd(
  List<String> graphemes, {
  required int cursorOffset,
  int? selectionBaseOffset,
  int? selectionExtentOffset,
  required int lineEndOffset,
}) {
  final start = cursorOffset.clamp(0, graphemes.length);
  final end = lineEndOffset.clamp(0, graphemes.length);
  if (start >= end) {
    return _unchangedResult(
      graphemes,
      cursorOffset: cursorOffset,
      selectionBaseOffset: selectionBaseOffset,
      selectionExtentOffset: selectionExtentOffset,
    );
  }

  final result = edit_ops.removeRange(
    graphemes,
    start: start,
    end: end,
    cursorOffset: start,
  );
  return TextCommandResult(
    graphemes: result.graphemes,
    cursorOffset: result.cursorOffset,
  );
}
