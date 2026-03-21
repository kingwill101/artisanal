library;

import 'dart:math' as math;

import 'package:characters/characters.dart';

import '../../unicode/grapheme.dart' as uni;
import 'editor_state.dart';
import 'state_bridge.dart';
import 'text_commands.dart';
import 'text_document.dart';
import 'text_edit_ops.dart' as edit_ops;
import 'text_navigation.dart' as nav;

bool _isWordGrapheme(String grapheme) {
  if (grapheme.isEmpty || grapheme == '\n') return false;
  return RegExp(r'[A-Za-z0-9_]').hasMatch(grapheme.characters.first);
}

bool _isControlRune(int rune) {
  if (rune >= 0x00 && rune <= 0x1F) return true;
  if (rune >= 0x7F && rune <= 0x9F) return true;
  return false;
}

List<int> textSanitizeRunes(List<int> runes, {required bool multiline}) {
  final tabRunes = multiline
      ? const <int>[0x20, 0x20, 0x20, 0x20]
      : const <int>[0x20];
  final newlineRunes = multiline ? const <int>[0x0A] : const <int>[0x20];
  final result = <int>[];

  for (final rune in runes) {
    if (rune == 0xFFFD) {
      continue;
    } else if (rune == 0x0D || rune == 0x0A) {
      result.addAll(newlineRunes);
    } else if (rune == 0x09) {
      result.addAll(tabRunes);
    } else if (_isControlRune(rune)) {
      continue;
    } else {
      result.add(rune);
    }
  }

  return result;
}

List<int> textSanitizeRunesLimited(
  List<int> runes, {
  required bool multiline,
  required int maxOutputCodepoints,
}) {
  if (maxOutputCodepoints <= 0) return const [];

  final tabRunes = multiline
      ? const <int>[0x20, 0x20, 0x20, 0x20]
      : const <int>[0x20];
  final newlineRunes = multiline ? const <int>[0x0A] : const <int>[0x20];
  final result = <int>[];

  for (final rune in runes) {
    if (result.length >= maxOutputCodepoints) break;

    if (rune == 0xFFFD) {
      continue;
    } else if (rune == 0x0D || rune == 0x0A) {
      for (final codepoint in newlineRunes) {
        if (result.length >= maxOutputCodepoints) break;
        result.add(codepoint);
      }
    } else if (rune == 0x09) {
      for (final codepoint in tabRunes) {
        if (result.length >= maxOutputCodepoints) break;
        result.add(codepoint);
      }
    } else if (_isControlRune(rune)) {
      continue;
    } else {
      result.add(rune);
    }
  }

  return result;
}

List<String> textPrepareInsertedGraphemes(
  List<int> runes, {
  required bool multiline,
  int? maxGraphemes,
}) {
  if (maxGraphemes != null && maxGraphemes <= 0) {
    return const <String>[];
  }

  final maxOutputCodepoints = maxGraphemes;
  if (maxOutputCodepoints != null && runes.length > maxOutputCodepoints * 4) {
    final limitedRunes = textSanitizeRunesLimited(
      runes,
      multiline: multiline,
      maxOutputCodepoints: maxOutputCodepoints,
    );
    if (limitedRunes.isEmpty) return const <String>[];
    return limitedRunes.isEmpty
        ? const <String>[]
        : uni
              .graphemes(String.fromCharCodes(limitedRunes))
              .take(maxOutputCodepoints)
              .toList(growable: false);
  }

  final sanitizedRunes = textSanitizeRunes(runes, multiline: multiline);
  final graphemes = uni
      .graphemes(String.fromCharCodes(sanitizedRunes))
      .toList(growable: false);
  if (maxOutputCodepoints == null || graphemes.length <= maxOutputCodepoints) {
    return graphemes;
  }
  return graphemes.sublist(0, maxOutputCodepoints).toList(growable: false);
}

String textCapitalizeWords(String text) {
  final graphemes = text.characters.toList(growable: false);
  final buffer = StringBuffer();
  var capitalizeNext = true;
  for (final grapheme in graphemes) {
    if (_isWordGrapheme(grapheme)) {
      buffer.write(
        capitalizeNext ? grapheme.toUpperCase() : grapheme.toLowerCase(),
      );
      capitalizeNext = false;
    } else {
      buffer.write(grapheme);
      capitalizeNext = true;
    }
  }
  return buffer.toString();
}

TextLineStateSnapshot _clampLineStateSnapshot(
  TextLineStateSnapshot snapshot,
  List<String> lines, {
  bool preserveCollapsedSelection = true,
}) {
  final safeLines = lines.isEmpty ? const <String>[''] : lines;
  return snapshot.clamp(
    lineCount: safeLines.length,
    lineLength: (line) => safeLines[line].length,
    preserveCollapsedSelection: preserveCollapsedSelection,
  );
}

TextLineCommandResult _lineResultFromSnapshot(
  List<String> lines,
  TextLineStateSnapshot snapshot, {
  bool changed = true,
}) {
  final safeLines = lines.isEmpty ? const <String>[''] : lines;
  final clamped = _clampLineStateSnapshot(snapshot, safeLines);
  return TextLineCommandResult(
    lines: safeLines,
    cursor: clamped.cursor,
    selectionBase: clamped.selectionBase,
    selectionExtent: clamped.selectionExtent,
    changed: changed,
  );
}

({int startLine, int endLine}) _selectedLineSpan(TextLineStateSnapshot state) {
  final selection = state.selection;
  if (selection == null || selection.isCollapsed) {
    return (startLine: state.cursor.line, endLine: state.cursor.line);
  }
  return (startLine: selection.start.line, endLine: selection.end.line);
}

int _leadingIndentRemovalCount(String line, int width) {
  if (line.isEmpty || width < 1) return 0;
  if (line.startsWith('\t')) return 1;

  var removed = 0;
  while (removed < width && removed < line.length && line[removed] == ' ') {
    removed++;
  }
  return removed;
}

int _trailingHorizontalTrimLength(String line) {
  var end = line.length;
  while (end > 0 && (line[end - 1] == ' ' || line[end - 1] == '\t')) {
    end--;
  }
  return end;
}

bool _isHorizontalWhitespace(String grapheme) {
  return grapheme == ' ' || grapheme == '\t';
}

String _trimLeadingHorizontalWhitespace(String line) {
  var start = 0;
  while (start < line.length && _isHorizontalWhitespace(line[start])) {
    start++;
  }
  return line.substring(start);
}

bool _suppressesLineJoinSpaceBefore(String grapheme) {
  return grapheme == '(' ||
      grapheme == '[' ||
      grapheme == '{' ||
      grapheme == '<';
}

bool _suppressesLineJoinSpaceAfter(String grapheme) {
  return grapheme == ')' ||
      grapheme == ']' ||
      grapheme == '}' ||
      grapheme == '>' ||
      grapheme == ',' ||
      grapheme == ';' ||
      grapheme == ':' ||
      grapheme == '.';
}

String _lineJoinSeparator(String left, String right) {
  if (left.isEmpty || right.isEmpty) return '';
  final last = left.characters.last;
  final first = right.characters.first;
  if (_isHorizontalWhitespace(last) || _isHorizontalWhitespace(first)) {
    return '';
  }
  if (_suppressesLineJoinSpaceBefore(last) ||
      _suppressesLineJoinSpaceAfter(first)) {
    return '';
  }
  return ' ';
}

int _compareLineContent(
  String a,
  String b, {
  required bool descending,
  required bool caseSensitive,
}) {
  final lhs = caseSensitive ? a : a.toLowerCase();
  final rhs = caseSensitive ? b : b.toLowerCase();
  final base = lhs.compareTo(rhs);
  final resolved = base != 0 ? base : a.compareTo(b);
  return descending ? -resolved : resolved;
}

bool _listStringEquals(List<String> a, List<String> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var index = 0; index < a.length; index++) {
    if (a[index] != b[index]) return false;
  }
  return true;
}

TextCommandResult textSplitLine({
  required TextDocument document,
  required TextOffsetStateSnapshot state,
}) {
  return textInsertGraphemes(
    document: document,
    state: state,
    graphemes: const ['\n'],
  );
}

TextCommandResult textTransformSelectionOrLine({
  required TextDocument document,
  required TextOffsetStateSnapshot state,
  required String Function(String text) transform,
}) {
  final cursor = document.positionForOffset(state.cursorOffset);
  final graphemes = document.flattenWithNewlines();
  final selection = normalizedSelectionRange(
    state.selectionBaseOffset,
    state.selectionExtentOffset,
  );
  final hasSelection = selection != null && selection.start != selection.end;
  final start = hasSelection
      ? selection.start
      : document.offsetForPosition(TextPosition(line: cursor.line, column: 0));
  final end = hasSelection
      ? selection.end
      : document.offsetForPosition(
          TextPosition(line: cursor.line, column: document.lineLength(cursor.line)),
        );

  if (start == end) {
    return TextCommandResult(
      graphemes: graphemes,
      cursorOffset: state.cursorOffset,
      selectionBaseOffset: state.selectionBaseOffset,
      selectionExtentOffset: state.selectionExtentOffset,
      changed: false,
    );
  }

  final original = document.graphemesInRange(
    startOffset: start,
    endOffset: end,
  ).join();
  final transformed = transform(original);
  if (transformed == original) {
    return TextCommandResult(
      graphemes: graphemes,
      cursorOffset: state.cursorOffset,
      selectionBaseOffset: state.selectionBaseOffset,
      selectionExtentOffset: state.selectionExtentOffset,
      changed: false,
    );
  }

  final replacement = transformed.characters.toList(growable: false);
  final working = document.copy();
  final result = edit_ops.replaceDocumentRange(
    working,
    start: start,
    end: end,
    replacement: replacement,
  );
  final nextExtent = start + replacement.length;

  if (hasSelection) {
    return TextCommandResult(
      graphemes: working.flattenWithNewlines(),
      cursorOffset: nextExtent,
      selectionBaseOffset: start,
      selectionExtentOffset: nextExtent,
      changed: result.changed,
    );
  }

  final relativeCursor = (state.cursorOffset - start).clamp(0, replacement.length);
  return TextCommandResult(
    graphemes: working.flattenWithNewlines(),
    cursorOffset: start + relativeCursor,
    changed: result.changed,
  );
}

TextCommandResult textWrapSelection({
  required TextDocument document,
  required TextOffsetStateSnapshot state,
  required String before,
  String? after,
}) {
  final graphemes = document.flattenWithNewlines();
  final selection = normalizedSelectionRange(
    state.selectionBaseOffset,
    state.selectionExtentOffset,
  );
  if (selection == null || selection.start == selection.end) {
    return TextCommandResult(
      graphemes: graphemes,
      cursorOffset: state.cursorOffset,
      selectionBaseOffset: state.selectionBaseOffset,
      selectionExtentOffset: state.selectionExtentOffset,
      changed: false,
    );
  }

  final beforeGraphemes = before.characters.toList(growable: false);
  final afterGraphemes = (after ?? before).characters.toList(growable: false);
  if (beforeGraphemes.isEmpty && afterGraphemes.isEmpty) {
    return TextCommandResult(
      graphemes: graphemes,
      cursorOffset: state.cursorOffset,
      selectionBaseOffset: state.selectionBaseOffset,
      selectionExtentOffset: state.selectionExtentOffset,
      changed: false,
    );
  }

  final selected = document.graphemesInRange(
    startOffset: selection.start,
    endOffset: selection.end,
  );
  final replacement = <String>[...beforeGraphemes, ...selected, ...afterGraphemes];
  final working = document.copy();
  final result = edit_ops.replaceDocumentRange(
    working,
    start: selection.start,
    end: selection.end,
    replacement: replacement,
  );
  final nextSelectionStart = selection.start + beforeGraphemes.length;
  final nextSelectionEnd = nextSelectionStart + selected.length;

  return TextCommandResult(
    graphemes: working.flattenWithNewlines(),
    cursorOffset: nextSelectionEnd,
    selectionBaseOffset: nextSelectionStart,
    selectionExtentOffset: nextSelectionEnd,
    changed: result.changed,
  );
}

TextCommandResult textUnwrapSelection({
  required TextDocument document,
  required TextOffsetStateSnapshot state,
  required Map<String, String> surroundPairs,
}) {
  final graphemes = document.flattenWithNewlines();
  final selection = normalizedSelectionRange(
    state.selectionBaseOffset,
    state.selectionExtentOffset,
  );
  if (selection == null || selection.start == selection.end) {
    return TextCommandResult(
      graphemes: graphemes,
      cursorOffset: state.cursorOffset,
      selectionBaseOffset: state.selectionBaseOffset,
      selectionExtentOffset: state.selectionExtentOffset,
      changed: false,
    );
  }

  if (selection.start < 1 || selection.end >= document.length) {
    return TextCommandResult(
      graphemes: graphemes,
      cursorOffset: state.cursorOffset,
      selectionBaseOffset: state.selectionBaseOffset,
      selectionExtentOffset: state.selectionExtentOffset,
      changed: false,
    );
  }

  final leading = document.graphemeAt(selection.start - 1);
  final trailing = document.graphemeAt(selection.end);
  if (surroundPairs[leading] != trailing) {
    return TextCommandResult(
      graphemes: graphemes,
      cursorOffset: state.cursorOffset,
      selectionBaseOffset: state.selectionBaseOffset,
      selectionExtentOffset: state.selectionExtentOffset,
      changed: false,
    );
  }

  final selected = document.graphemesInRange(
    startOffset: selection.start,
    endOffset: selection.end,
  );
  final working = document.copy();
  final result = edit_ops.replaceDocumentRange(
    working,
    start: selection.start - 1,
    end: selection.end + 1,
    replacement: selected,
  );
  final nextSelectionStart = selection.start - 1;
  final nextSelectionEnd = nextSelectionStart + selected.length;

  return TextCommandResult(
    graphemes: working.flattenWithNewlines(),
    cursorOffset: nextSelectionEnd,
    selectionBaseOffset: nextSelectionStart,
    selectionExtentOffset: nextSelectionEnd,
    changed: result.changed,
  );
}

TextCommandResult textTransformWordOrAdjacent({
  required TextDocument document,
  required TextOffsetStateSnapshot state,
  required String Function(String text) transform,
}) {
  final range = nav.wordRangeForTransformFromReader(
    document.length,
    state.cursorOffset,
    isWord: _isWordGrapheme,
    graphemeAt: document.graphemeAt,
  );
  if (range == null || range.start == range.end) {
    return TextCommandResult(
      graphemes: document.flattenWithNewlines(),
      cursorOffset: state.cursorOffset,
      changed: false,
    );
  }

  final original = document.graphemesInRange(
    startOffset: range.start,
    endOffset: range.end,
  ).join();
  final transformed = transform(original);
  if (transformed == original) {
    return TextCommandResult(
      graphemes: document.flattenWithNewlines(),
      cursorOffset: state.cursorOffset,
      changed: false,
    );
  }

  final replacement = transformed.characters.toList(growable: false);
  final working = document.copy();
  final result = edit_ops.replaceDocumentRange(
    working,
    start: range.start,
    end: range.end,
    replacement: replacement,
  );
  return TextCommandResult(
    graphemes: working.flattenWithNewlines(),
    cursorOffset: range.start + replacement.length,
    changed: result.changed,
  );
}

TextCommandResult textInsertGraphemes({
  required TextDocument document,
  required TextOffsetStateSnapshot state,
  required List<String> graphemes,
  bool replaceSelection = true,
}) {
  if (graphemes.isEmpty) {
    return TextCommandResult(
      graphemes: document.flattenWithNewlines(),
      cursorOffset: state.cursorOffset,
      selectionBaseOffset: state.selectionBaseOffset,
      selectionExtentOffset: state.selectionExtentOffset,
      changed: false,
    );
  }

  final working = document.copy();
  final selection = normalizedSelectionRange(
    state.selectionBaseOffset,
    state.selectionExtentOffset,
  );
  final hasSelection = selection != null && selection.start != selection.end;

  final result = replaceSelection && hasSelection
      ? edit_ops.replaceDocumentRange(
          working,
          start: selection.start,
          end: selection.end,
          replacement: graphemes,
        )
      : edit_ops.insertIntoDocument(
          working,
          state.cursorOffset,
          graphemes,
        );

  return TextCommandResult(
    graphemes: working.flattenWithNewlines(),
    cursorOffset: result.cursorOffset,
    changed: result.changed,
  );
}

TextCommandResult textInsertText({
  required TextDocument document,
  required TextOffsetStateSnapshot state,
  required String text,
  bool replaceSelection = true,
}) {
  return textInsertGraphemes(
    document: document,
    state: state,
    graphemes: text.characters.toList(growable: false),
    replaceSelection: replaceSelection,
  );
}

TextCommandResult textDeleteSelection({
  required TextDocument document,
  required TextOffsetStateSnapshot state,
}) {
  final selection = normalizedSelectionRange(
    state.selectionBaseOffset,
    state.selectionExtentOffset,
  );
  if (selection == null || selection.start == selection.end) {
    return TextCommandResult(
      graphemes: document.flattenWithNewlines(),
      cursorOffset: state.cursorOffset,
      selectionBaseOffset: state.selectionBaseOffset,
      selectionExtentOffset: state.selectionExtentOffset,
      changed: false,
    );
  }

  final working = document.copy();
  final result = edit_ops.removeDocumentRange(
    working,
    start: selection.start,
    end: selection.end,
  );
  return TextCommandResult(
    graphemes: working.flattenWithNewlines(),
    cursorOffset: result.cursorOffset,
    changed: result.changed,
  );
}

TextCommandResult textDeletePrevious({
  required TextDocument document,
  required TextOffsetStateSnapshot state,
}) {
  if (state.cursorOffset <= 0) {
    return TextCommandResult(
      graphemes: document.flattenWithNewlines(),
      cursorOffset: state.cursorOffset,
      selectionBaseOffset: state.selectionBaseOffset,
      selectionExtentOffset: state.selectionExtentOffset,
      changed: false,
    );
  }

  final working = document.copy();
  final result = edit_ops.deletePreviousDocumentGrapheme(
    working,
    state.cursorOffset,
  );
  return TextCommandResult(
    graphemes: working.flattenWithNewlines(),
    cursorOffset: result.cursorOffset,
    changed: result.changed,
  );
}

TextCommandResult textDeleteNext({
  required TextDocument document,
  required TextOffsetStateSnapshot state,
}) {
  if (state.cursorOffset >= document.length) {
    return TextCommandResult(
      graphemes: document.flattenWithNewlines(),
      cursorOffset: state.cursorOffset,
      selectionBaseOffset: state.selectionBaseOffset,
      selectionExtentOffset: state.selectionExtentOffset,
      changed: false,
    );
  }

  final working = document.copy();
  final result = edit_ops.deleteNextDocumentGrapheme(
    working,
    state.cursorOffset,
  );
  return TextCommandResult(
    graphemes: working.flattenWithNewlines(),
    cursorOffset: result.cursorOffset,
    changed: result.changed,
  );
}

TextCommandResult textDeleteWordBackward({
  required TextDocument document,
  required TextOffsetStateSnapshot state,
  nav.GraphemePredicate isWord = _isWordGrapheme,
}) {
  if (state.cursorOffset <= 0) {
    return TextCommandResult(
      graphemes: document.flattenWithNewlines(),
      cursorOffset: state.cursorOffset,
      selectionBaseOffset: state.selectionBaseOffset,
      selectionExtentOffset: state.selectionExtentOffset,
      changed: false,
    );
  }

  final range = nav.deleteWordBackwardRangeFromReader(
    document.length,
    state.cursorOffset,
    isWord: isWord,
    graphemeAt: document.graphemeAt,
  );
  if (range.start >= state.cursorOffset) {
    return TextCommandResult(
      graphemes: document.flattenWithNewlines(),
      cursorOffset: state.cursorOffset,
      selectionBaseOffset: state.selectionBaseOffset,
      selectionExtentOffset: state.selectionExtentOffset,
      changed: false,
    );
  }

  final working = document.copy();
  final result = edit_ops.removeDocumentRange(
    working,
    start: range.start,
    end: state.cursorOffset,
  );
  return TextCommandResult(
    graphemes: working.flattenWithNewlines(),
    cursorOffset: result.cursorOffset,
    changed: result.changed,
  );
}

TextCommandResult textDeleteWordForward({
  required TextDocument document,
  required TextOffsetStateSnapshot state,
  nav.GraphemePredicate isWord = _isWordGrapheme,
}) {
  if (state.cursorOffset >= document.length) {
    return TextCommandResult(
      graphemes: document.flattenWithNewlines(),
      cursorOffset: state.cursorOffset,
      selectionBaseOffset: state.selectionBaseOffset,
      selectionExtentOffset: state.selectionExtentOffset,
      changed: false,
    );
  }

  final range = nav.deleteWordForwardRangeFromReader(
    document.length,
    state.cursorOffset,
    isWord: isWord,
    graphemeAt: document.graphemeAt,
  );
  if (range.end <= state.cursorOffset) {
    return TextCommandResult(
      graphemes: document.flattenWithNewlines(),
      cursorOffset: state.cursorOffset,
      selectionBaseOffset: state.selectionBaseOffset,
      selectionExtentOffset: state.selectionExtentOffset,
      changed: false,
    );
  }

  final working = document.copy();
  final result = edit_ops.removeDocumentRange(
    working,
    start: state.cursorOffset,
    end: range.end,
    cursorOffset: state.cursorOffset,
  );
  return TextCommandResult(
    graphemes: working.flattenWithNewlines(),
    cursorOffset: result.cursorOffset,
    changed: result.changed,
  );
}

TextCommandResult textDeleteToLineStart({
  required TextDocument document,
  required TextOffsetStateSnapshot state,
}) {
  final graphemes = document.flattenWithNewlines();
  final cursor = document.positionForOffset(state.cursorOffset);
  final start = document.offsetForPosition(
    TextPosition(line: cursor.line, column: 0),
  );
  final end = state.cursorOffset.clamp(0, graphemes.length);
  if (start >= end) {
    return TextCommandResult(
      graphemes: graphemes,
      cursorOffset: state.cursorOffset,
      selectionBaseOffset: state.selectionBaseOffset,
      selectionExtentOffset: state.selectionExtentOffset,
      changed: false,
    );
  }

  final working = document.copy();
  final result = edit_ops.removeDocumentRange(
    working,
    start: start,
    end: end,
    cursorOffset: start,
  );
  return TextCommandResult(
    graphemes: working.flattenWithNewlines(),
    cursorOffset: result.cursorOffset,
    changed: result.changed,
  );
}

TextCommandResult textDeleteToLineEnd({
  required TextDocument document,
  required TextOffsetStateSnapshot state,
}) {
  final graphemes = document.flattenWithNewlines();
  final cursor = document.positionForOffset(state.cursorOffset);
  final start = state.cursorOffset.clamp(0, graphemes.length);
  final end = document.offsetForPosition(
    TextPosition(line: cursor.line, column: document.lineLength(cursor.line)),
  );
  if (start >= end) {
    return TextCommandResult(
      graphemes: graphemes,
      cursorOffset: state.cursorOffset,
      selectionBaseOffset: state.selectionBaseOffset,
      selectionExtentOffset: state.selectionExtentOffset,
      changed: false,
    );
  }

  final working = document.copy();
  final result = edit_ops.removeDocumentRange(
    working,
    start: start,
    end: end,
    cursorOffset: start,
  );
  return TextCommandResult(
    graphemes: working.flattenWithNewlines(),
    cursorOffset: result.cursorOffset,
    changed: result.changed,
  );
}

TextCursorCommandResult textMoveByCharacter({
  required TextDocument document,
  required TextOffsetStateSnapshot state,
  required bool forward,
  bool extendSelection = false,
  bool clearSelection = false,
}) {
  final targetOffset = forward
      ? (state.cursorOffset + 1).clamp(0, document.length)
      : (state.cursorOffset - 1).clamp(0, document.length);
  return moveCursorToOffset(
    textLength: document.length,
    cursorOffset: state.cursorOffset,
    selectionBaseOffset: state.selectionBaseOffset,
    selectionExtentOffset: state.selectionExtentOffset,
    targetOffset: targetOffset,
    extendSelection: extendSelection,
    clearSelection: clearSelection,
  );
}

TextCursorCommandResult textMoveByWord({
  required TextDocument document,
  required TextOffsetStateSnapshot state,
  required bool forward,
  nav.GraphemePredicate isWord = _isWordGrapheme,
  bool extendSelection = false,
  bool clearSelection = false,
}) {
  final targetOffset = forward
      ? nav.moveWordForwardFromReader(
          document.length,
          state.cursorOffset,
          isWord: isWord,
          graphemeAt: document.graphemeAt,
        )
      : nav.moveWordBackwardFromReader(
          document.length,
          state.cursorOffset,
          isWord: isWord,
          graphemeAt: document.graphemeAt,
        );
  return moveCursorToOffset(
    textLength: document.length,
    cursorOffset: state.cursorOffset,
    selectionBaseOffset: state.selectionBaseOffset,
    selectionExtentOffset: state.selectionExtentOffset,
    targetOffset: targetOffset,
    extendSelection: extendSelection,
    clearSelection: clearSelection,
  );
}

TextCursorCommandResult textMoveToDocumentBoundary({
  required TextDocument document,
  required TextOffsetStateSnapshot state,
  required bool forward,
  bool extendSelection = false,
  bool clearSelection = false,
}) {
  return moveCursorToOffset(
    textLength: document.length,
    cursorOffset: state.cursorOffset,
    selectionBaseOffset: state.selectionBaseOffset,
    selectionExtentOffset: state.selectionExtentOffset,
    targetOffset: forward ? document.length : 0,
    extendSelection: extendSelection,
    clearSelection: clearSelection,
  );
}

TextCommandResult textTransposeBackward({
  required TextDocument document,
  required TextOffsetStateSnapshot state,
}) {
  final graphemes = document.flattenWithNewlines();
  final cursor = document.positionForOffset(state.cursorOffset);
  final lineLength = document.lineLength(cursor.line);
  if (lineLength == 0 || cursor.column == 0) {
    return TextCommandResult(
      graphemes: graphemes,
      cursorOffset: state.cursorOffset,
      selectionBaseOffset: state.selectionBaseOffset,
      selectionExtentOffset: state.selectionExtentOffset,
      changed: false,
    );
  }

  final atColumn = math.min(cursor.column, lineLength - 1);
  final beforeColumn = atColumn - 1;
  if (beforeColumn < 0) {
    return TextCommandResult(
      graphemes: graphemes,
      cursorOffset: state.cursorOffset,
      selectionBaseOffset: state.selectionBaseOffset,
      selectionExtentOffset: state.selectionExtentOffset,
      changed: false,
    );
  }

  final lineStartOffset = document.offsetForPosition(
    TextPosition(line: cursor.line, column: 0),
  );
  final beforeOffset = lineStartOffset + beforeColumn;
  final atOffset = lineStartOffset + atColumn;
  final nextGraphemes = List<String>.from(graphemes, growable: true);
  final tmp = nextGraphemes[beforeOffset];
  nextGraphemes[beforeOffset] = nextGraphemes[atOffset];
  nextGraphemes[atOffset] = tmp;

  return TextCommandResult(
    graphemes: nextGraphemes,
    cursorOffset: lineStartOffset + math.min(atColumn + 1, lineLength),
    selectionBaseOffset: state.selectionBaseOffset,
    selectionExtentOffset: state.selectionExtentOffset,
  );
}

TextLineCommandResult textMoveSelectedLines({
  required List<String> lines,
  required TextLineStateSnapshot state,
  required int direction,
}) {
  return state.moveSelectedLinesCommand(lines, direction: direction);
}

TextLineCommandResult textDuplicateSelectedLinesAbove({
  required List<String> lines,
  required TextLineStateSnapshot state,
}) {
  return state.duplicateSelectedLinesAboveCommand(lines);
}

TextLineCommandResult textDuplicateSelectedLinesBelow({
  required List<String> lines,
  required TextLineStateSnapshot state,
}) {
  return state.duplicateSelectedLinesBelowCommand(lines);
}

TextLineCommandResult textToggleLinePrefix({
  required List<String> lines,
  required TextLineStateSnapshot state,
  required String prefix,
  bool addSpaceWhenNonEmpty = true,
  bool skipBlankLinesWhenChecking = true,
}) {
  return state.toggleLinePrefixCommand(
    lines,
    prefix: prefix,
    addSpaceWhenNonEmpty: addSpaceWhenNonEmpty,
    skipBlankLinesWhenChecking: skipBlankLinesWhenChecking,
  );
}

TextLineCommandResult textToggleNumberedList({
  required List<String> lines,
  required TextLineStateSnapshot state,
  int startAt = 1,
}) {
  return state.toggleNumberedListCommand(lines, startAt: startAt);
}

TextLineCommandResult textRenumberNumberedList({
  required List<String> lines,
  required TextLineStateSnapshot state,
  int startAt = 1,
}) {
  return state.renumberNumberedListCommand(lines, startAt: startAt);
}

TextLineCommandResult textToggleHeadingPrefix({
  required List<String> lines,
  required TextLineStateSnapshot state,
  int level = 1,
}) {
  return state.toggleHeadingPrefixCommand(lines, level: level);
}

TextLineCommandResult textToggleChecklistState({
  required List<String> lines,
  required TextLineStateSnapshot state,
  String checkedMarker = 'x',
}) {
  return state.toggleChecklistStateCommand(lines, checkedMarker: checkedMarker);
}

TextLineCommandResult textIndentLines({
  required List<String> lines,
  required TextLineStateSnapshot state,
  int width = 2,
}) {
  final nextLines = lines.isEmpty ? <String>[''] : List<String>.from(lines);
  final indentWidth = width < 1 ? 1 : width;
  final clampedState = _clampLineStateSnapshot(state, nextLines);
  final span = _selectedLineSpan(clampedState);
  final editorState = EditorState();
  syncEditorStateFromLineSnapshot(
    editorState,
    clampedState,
    lineCount: nextLines.length,
    lineLength: (line) => nextLines[line].length,
  );

  final deltas = <int, int>{};
  final indent = ' ' * indentWidth;
  for (var lineIndex = span.startLine; lineIndex <= span.endLine; lineIndex++) {
    nextLines[lineIndex] = '$indent${nextLines[lineIndex]}';
    deltas[lineIndex] = indentWidth;
  }

  editorState.applyColumnDeltas(
    deltas,
    lineLength: (line) => nextLines[line].length,
  );
  return _lineResultFromSnapshot(
    nextLines,
    lineSnapshotFromEditorState(
      editorState,
      lineCount: nextLines.length,
      lineLength: (line) => nextLines[line].length,
      preserveCollapsedSelection: true,
    ),
  );
}

TextLineCommandResult textOutdentLines({
  required List<String> lines,
  required TextLineStateSnapshot state,
  int width = 2,
}) {
  final nextLines = lines.isEmpty ? <String>[''] : List<String>.from(lines);
  final indentWidth = width < 1 ? 1 : width;
  final clampedState = _clampLineStateSnapshot(state, nextLines);
  final span = _selectedLineSpan(clampedState);
  final removalCounts = <int, int>{};
  var changed = false;

  for (var lineIndex = span.startLine; lineIndex <= span.endLine; lineIndex++) {
    final removalCount = _leadingIndentRemovalCount(
      nextLines[lineIndex],
      indentWidth,
    );
    removalCounts[lineIndex] = removalCount;
    changed = changed || removalCount > 0;
  }

  if (!changed) {
    return _lineResultFromSnapshot(nextLines, clampedState, changed: false);
  }

  final editorState = EditorState();
  syncEditorStateFromLineSnapshot(
    editorState,
    clampedState,
    lineCount: nextLines.length,
    lineLength: (line) => nextLines[line].length,
  );

  final deltas = <int, int>{};
  for (var lineIndex = span.startLine; lineIndex <= span.endLine; lineIndex++) {
    final removalCount = removalCounts[lineIndex]!;
    if (removalCount == 0) continue;
    nextLines[lineIndex] = nextLines[lineIndex].substring(removalCount);
    deltas[lineIndex] = -removalCount;
  }

  editorState.applyColumnDeltas(
    deltas,
    lineLength: (line) => nextLines[line].length,
  );
  return _lineResultFromSnapshot(
    nextLines,
    lineSnapshotFromEditorState(
      editorState,
      lineCount: nextLines.length,
      lineLength: (line) => nextLines[line].length,
      preserveCollapsedSelection: true,
    ),
  );
}

TextLineCommandResult textCleanupWhitespace({
  required List<String> lines,
  required TextLineStateSnapshot state,
  bool trimTrailingBlankLines = true,
}) {
  final nextLines = lines.isEmpty ? <String>[''] : List<String>.from(lines);
  final clampedState = _clampLineStateSnapshot(state, nextLines);
  final hasSelection = clampedState.hasSelection;
  final span = hasSelection
      ? _selectedLineSpan(clampedState)
      : (startLine: 0, endLine: nextLines.length - 1);
  final trimmedLengths = <int, int>{};
  var changed = false;

  for (var lineIndex = span.startLine; lineIndex <= span.endLine; lineIndex++) {
    final trimmedLength = _trailingHorizontalTrimLength(nextLines[lineIndex]);
    trimmedLengths[lineIndex] = trimmedLength;
    changed = changed || trimmedLength != nextLines[lineIndex].length;
  }

  var removedTrailingLines = 0;
  if (!hasSelection && trimTrailingBlankLines) {
    var lineIndex = nextLines.length - 1;
    while (lineIndex > 0 && trimmedLengths[lineIndex] == 0) {
      removedTrailingLines++;
      lineIndex--;
    }
    changed = changed || removedTrailingLines > 0;
  }

  if (!changed) {
    return _lineResultFromSnapshot(nextLines, clampedState, changed: false);
  }

  for (var lineIndex = span.startLine; lineIndex <= span.endLine; lineIndex++) {
    final trimmedLength = trimmedLengths[lineIndex]!;
    nextLines[lineIndex] = nextLines[lineIndex].substring(0, trimmedLength);
  }

  if (!hasSelection && removedTrailingLines > 0) {
    nextLines.removeRange(
      nextLines.length - removedTrailingLines,
      nextLines.length,
    );
  }

  final nextCursor = clampedState.cursor.line >= nextLines.length
      ? TextPosition(line: nextLines.length - 1, column: nextLines.last.length)
      : clampedState.cursor;
  final nextState = hasSelection
      ? TextLineStateSnapshot.selection(
          base: clampedState.selectionBase!,
          extent: clampedState.selectionExtent!,
          cursor: nextCursor,
          preserveCollapsedSelection: true,
        )
      : TextLineStateSnapshot.collapsed(cursor: nextCursor);
  return _lineResultFromSnapshot(nextLines, nextState);
}

TextLineCommandResult textDeleteLines({
  required List<String> lines,
  required TextLineStateSnapshot state,
}) {
  final nextLines = lines.isEmpty ? <String>[''] : List<String>.from(lines);
  final clampedState = _clampLineStateSnapshot(state, nextLines);
  final span = _selectedLineSpan(clampedState);
  final deletedCount = span.endLine - span.startLine + 1;

  if (deletedCount >= nextLines.length) {
    return const TextLineCommandResult(
      lines: [''],
      cursor: TextPosition(line: 0, column: 0),
    );
  }

  nextLines.removeRange(span.startLine, span.endLine + 1);
  final nextRow = clampedState.cursor.line > span.endLine
      ? clampedState.cursor.line - deletedCount
      : clampedState.cursor.line >= span.startLine
      ? span.startLine
      : clampedState.cursor.line;
  return _lineResultFromSnapshot(
    nextLines,
    TextLineStateSnapshot.collapsed(
      cursor: TextPosition(line: nextRow, column: clampedState.cursor.column),
    ),
  );
}

TextLineCommandResult textJoinLines({
  required List<String> lines,
  required TextLineStateSnapshot state,
}) {
  final nextLines = lines.isEmpty ? <String>[''] : List<String>.from(lines);
  final clampedState = _clampLineStateSnapshot(state, nextLines);
  final selectedSpan = _selectedLineSpan(clampedState);
  final endLine = clampedState.hasSelection
      ? selectedSpan.endLine
      : (selectedSpan.startLine + 1).clamp(0, nextLines.length - 1);
  if (selectedSpan.startLine >= endLine) {
    return _lineResultFromSnapshot(nextLines, clampedState, changed: false);
  }

  var joined = nextLines[selectedSpan.startLine];
  for (
    var lineIndex = selectedSpan.startLine + 1;
    lineIndex <= endLine;
    lineIndex++
  ) {
    final trimmed = _trimLeadingHorizontalWhitespace(nextLines[lineIndex]);
    final separator = _lineJoinSeparator(joined, trimmed);
    if (separator.isNotEmpty) {
      joined = '$joined$separator';
    }
    joined = '$joined$trimmed';
  }

  nextLines[selectedSpan.startLine] = joined;
  nextLines.removeRange(selectedSpan.startLine + 1, endLine + 1);
  return _lineResultFromSnapshot(
    nextLines,
    TextLineStateSnapshot.collapsed(
      cursor: TextPosition(line: selectedSpan.startLine, column: joined.length),
    ),
  );
}

TextLineCommandResult textSortSelectedLines({
  required List<String> lines,
  required TextLineStateSnapshot state,
  bool descending = false,
  bool caseSensitive = false,
}) {
  final nextLines = lines.isEmpty ? <String>[''] : List<String>.from(lines);
  final clampedState = _clampLineStateSnapshot(state, nextLines);
  final hasSelection = clampedState.hasSelection;
  final span = hasSelection
      ? _selectedLineSpan(clampedState)
      : (startLine: 0, endLine: nextLines.length - 1);
  if (span.startLine >= span.endLine) {
    return _lineResultFromSnapshot(nextLines, clampedState, changed: false);
  }

  final originalTexts = nextLines.sublist(span.startLine, span.endLine + 1);
  final sortedTexts = List<String>.from(originalTexts)
    ..sort(
      (a, b) => _compareLineContent(
        a,
        b,
        descending: descending,
        caseSensitive: caseSensitive,
      ),
    );
  if (_listStringEquals(originalTexts, sortedTexts)) {
    return _lineResultFromSnapshot(nextLines, clampedState, changed: false);
  }

  nextLines.replaceRange(span.startLine, span.endLine + 1, sortedTexts);
  return _lineResultFromSnapshot(nextLines, clampedState);
}
