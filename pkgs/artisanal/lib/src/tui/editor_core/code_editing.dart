library;

import 'package:characters/characters.dart';

import 'code_edit_policy.dart';
import 'code_language_profile.dart';
import 'editor_state.dart';
import 'state_bridge.dart';
import 'text_change.dart';
import 'text_edit_ops.dart' as edit_ops;
import 'text_commands.dart';
import 'text_document.dart';
import 'text_editing.dart';

TextCommandResult _unchangedCodeResultFromDocument(
  TextDocument document,
  TextOffsetStateSnapshot state,
) {
  return _codeResultFromDocument(
    document,
    cursorOffset: state.cursorOffset,
    selectionBaseOffset: state.selectionBaseOffset,
    selectionExtentOffset: state.selectionExtentOffset,
    changed: false,
  );
}

TextCommandResult _codeResultFromDocument(
  TextDocument document, {
  required int cursorOffset,
  int? selectionBaseOffset,
  int? selectionExtentOffset,
  TextDocumentChange? documentChange,
  bool changed = true,
}) {
  return TextCommandResult(
    cursorOffset: cursorOffset,
    selectionBaseOffset: selectionBaseOffset,
    selectionExtentOffset: selectionExtentOffset,
    document: document,
    documentChange: documentChange,
    changed: changed,
  );
}

bool _listStringEquals(List<String> left, List<String> right) {
  if (identical(left, right)) {
    return true;
  }
  if (left.length != right.length) {
    return false;
  }
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) {
      return false;
    }
  }
  return true;
}

bool _isWhitespaceGrapheme(String grapheme) {
  return grapheme == ' ' ||
      grapheme == '\t' ||
      grapheme == '\n' ||
      grapheme == '\r';
}

int _leadingWhitespaceCount(List<String> graphemes) {
  var count = 0;
  while (count < graphemes.length && _isWhitespaceGrapheme(graphemes[count])) {
    count++;
  }
  return count;
}

int _trailingWhitespaceCount(List<String> graphemes) {
  var count = 0;
  while (count < graphemes.length &&
      _isWhitespaceGrapheme(graphemes[graphemes.length - 1 - count])) {
    count++;
  }
  return count;
}

bool _startsWithGraphemeSequence(List<String> text, List<String> prefix) {
  if (prefix.length > text.length) {
    return false;
  }
  for (var index = 0; index < prefix.length; index++) {
    if (text[index] != prefix[index]) {
      return false;
    }
  }
  return true;
}

bool _endsWithGraphemeSequence(List<String> text, List<String> suffix) {
  if (suffix.length > text.length) {
    return false;
  }
  final offset = text.length - suffix.length;
  for (var index = 0; index < suffix.length; index++) {
    if (text[offset + index] != suffix[index]) {
      return false;
    }
  }
  return true;
}

TextCommandResult codeHandleClosingDelimiterAlignment({
  required TextDocument document,
  required TextOffsetStateSnapshot state,
  required CodeLanguageProfile profile,
  required String typed,
  required int indentWidth,
}) {
  if (state.hasSelection || !profile.closingToOpening.containsKey(typed)) {
    return _unchangedCodeResultFromDocument(document, state);
  }

  final cursor = document.positionForOffset(state.cursorOffset);
  final lineIndex = cursor.line.clamp(0, document.lineCount - 1);
  final lineGraphemes = document.lineGraphemesAt(lineIndex);
  final beforeCursor = lineGraphemes.take(cursor.column).join();
  final line = lineGraphemes.join();
  if (beforeCursor.trim().isNotEmpty || line.trim().isNotEmpty) {
    return _unchangedCodeResultFromDocument(document, state);
  }

  final nextIndent = codeOutdentedIndent(beforeCursor, indentWidth);
  return textTransformSelectionOrLine(
    document: document,
    state: state,
    transform: (_) => '$nextIndent$typed',
  );
}

TextCommandResult codeHandlePairBackspace({
  required TextDocument document,
  required TextOffsetStateSnapshot state,
  required CodeLanguageProfile profile,
}) {
  if (state.hasSelection) {
    return _unchangedCodeResultFromDocument(document, state);
  }
  final cursorOffset = state.cursorOffset;
  if (cursorOffset <= 0 || cursorOffset >= document.length) {
    return _unchangedCodeResultFromDocument(document, state);
  }

  final opening = document.graphemeAt(cursorOffset - 1);
  final closing = document.graphemeAt(cursorOffset);
  if (profile.autoPairs[opening] != closing) {
    return _unchangedCodeResultFromDocument(document, state);
  }

  final working = document.copy();
  final result = edit_ops.removeDocumentRange(
    working,
    start: cursorOffset - 1,
    end: cursorOffset + 1,
    cursorOffset: cursorOffset - 1,
  );
  return _codeResultFromDocument(
    working,
    cursorOffset: result.cursorOffset,
    documentChange: result.change,
    changed: result.changed,
  );
}

TextCommandResult codeHandleAutoPair({
  required TextDocument document,
  required TextOffsetStateSnapshot state,
  required CodeLanguageProfile profile,
  required String typed,
}) {
  final matching = profile.autoPairs[typed];
  if (matching != null) {
    if (typed == matching &&
        !codeShouldAutoPairSymmetricDelimiter(
          document.text,
          state.cursorOffset,
          hasSelection: state.hasSelection,
        )) {
      return _unchangedCodeResultFromDocument(document, state);
    }

    if (state.hasSelection) {
      return textWrapSelection(
        document: document,
        state: state,
        before: typed,
        after: matching,
      );
    }

    final working = document.copy();
    final result = edit_ops.insertIntoDocument(
      working,
      state.cursorOffset,
      <String>[typed, matching],
    );
    return _codeResultFromDocument(
      working,
      cursorOffset: state.cursorOffset.clamp(0, document.length) + 1,
      documentChange: result.change,
      changed: result.changed,
    );
  }

  if (!profile.autoPairs.containsValue(typed) || state.hasSelection) {
    return _unchangedCodeResultFromDocument(document, state);
  }

  final offset = state.cursorOffset;
  if (document.matchesOffsetRange(
    startOffset: offset,
    graphemes: <String>[typed],
  )) {
    return _codeResultFromDocument(
      document,
      cursorOffset: offset + 1,
      selectionBaseOffset: state.selectionBaseOffset,
      selectionExtentOffset: state.selectionExtentOffset,
      changed: true,
    );
  }

  return _unchangedCodeResultFromDocument(document, state);
}

TextCommandResult codeInsertIndentedNewline({
  required TextDocument document,
  required TextOffsetStateSnapshot state,
  required int indentWidth,
  String? language,
}) {
  final cursor = document.positionForOffset(state.cursorOffset);
  final lineGraphemes = document.lineGraphemesAt(cursor.line);
  final beforeCursor = lineGraphemes.take(cursor.column).join();
  final afterCursor = lineGraphemes.skip(cursor.column).join();
  final currentLine = lineGraphemes.join();
  final baseIndent = codeLeadingIndent(currentLine);
  final trimmedBefore = beforeCursor.trimRight();
  final blockSuffix = state.hasSelection
      ? null
      : codeBlockNewlineSuffix(
          beforeCursor: trimmedBefore,
          afterCursor: afterCursor,
          baseIndent: baseIndent,
        );

  final baseIndentGraphemes = baseIndent.characters.toList(growable: false);
  final additionalIndent =
      codeShouldIncreaseIndentAfter(trimmedBefore, language: language)
      ? (' ' * (indentWidth < 1 ? 1 : indentWidth)).characters.toList(
          growable: false,
        )
      : const <String>[];
  final trailingSuffix =
      blockSuffix?.text.characters.toList(growable: false) ?? const <String>[];
  final trailingSuffixReplaceCount = blockSuffix?.consumedColumns ?? 0;
  final cursorInsertion = <String>[
    '\n',
    ...baseIndentGraphemes,
    ...additionalIndent,
  ];
  final replacement = <String>[...cursorInsertion, ...trailingSuffix];

  final start = state.hasSelection
      ? normalizedSelectionRange(
              state.selectionBaseOffset,
              state.selectionExtentOffset,
            )?.start ??
            state.cursorOffset
      : state.cursorOffset;
  final endBase = state.hasSelection
      ? normalizedSelectionRange(
              state.selectionBaseOffset,
              state.selectionExtentOffset,
            )?.end ??
            state.cursorOffset
      : state.cursorOffset;
  final end = state.hasSelection
      ? endBase
      : (endBase + trailingSuffixReplaceCount).clamp(endBase, document.length);

  final working = document.copy();
  final result = edit_ops.replaceDocumentRange(
    working,
    start: start,
    end: end,
    replacement: replacement,
    cursorOffset: start + cursorInsertion.length,
  );
  return _codeResultFromDocument(
    working,
    cursorOffset: result.cursorOffset,
    documentChange: result.change,
    changed: result.changed,
  );
}

TextCommandResult codeToggleBlockComments({
  required TextDocument document,
  required TextOffsetStateSnapshot state,
  required CodeLanguageProfile profile,
}) {
  final delimiters = profile.blockCommentDelimiters;
  if (delimiters == null || document.text.isEmpty) {
    return _unchangedCodeResultFromDocument(document, state);
  }

  final selection = normalizedSelectionRange(
    state.selectionBaseOffset,
    state.selectionExtentOffset,
  );
  final hasSelection = selection != null && selection.start != selection.end;
  final cursor = document.positionForOffset(state.cursorOffset);
  final line = cursor.line.clamp(0, document.lineCount - 1);
  final start = hasSelection
      ? selection.start
      : document.offsetForPosition(TextPosition(line: line, column: 0));
  final end = hasSelection
      ? selection.end
      : document.offsetForPosition(
          TextPosition(line: line, column: document.lineLength(line)),
        );
  if (start >= end) {
    return _unchangedCodeResultFromDocument(document, state);
  }

  final clampedStart = start < 0
      ? 0
      : (start > document.length ? document.length : start);
  final clampedEnd = end < clampedStart
      ? clampedStart
      : (end > document.length ? document.length : end);
  if (clampedStart >= clampedEnd) {
    return _unchangedCodeResultFromDocument(document, state);
  }

  final startGraphemes = delimiters.start.characters.toList(growable: false);
  final endGraphemes = delimiters.end.characters.toList(growable: false);
  final segment = document.graphemesInRange(
    startOffset: clampedStart,
    endOffset: clampedEnd,
  );
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
    return _unchangedCodeResultFromDocument(document, state);
  }

  final working = document.copy();
  edit_ops.replaceDocumentRange(
    working,
    start: clampedStart,
    end: clampedEnd,
    replacement: replacement,
  );
  final nextSelectionStart = clampedStart + selectionStart;
  final nextSelectionEnd = clampedStart + selectionEnd;

  if (hasSelection) {
    return _codeResultFromDocument(
      working,
      cursorOffset: nextSelectionEnd,
      selectionBaseOffset: nextSelectionStart,
      selectionExtentOffset: nextSelectionEnd,
    );
  }

  return _codeResultFromDocument(working, cursorOffset: nextSelectionEnd);
}
