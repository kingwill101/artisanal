library;

import 'package:characters/characters.dart';

import 'code_edit_policy.dart';
import 'code_language_profile.dart';
import 'editor_state.dart';
import 'state_bridge.dart';
import 'text_edit_ops.dart' as edit_ops;
import 'text_commands.dart';
import 'text_document.dart';
import 'text_editing.dart';

TextCommandResult _unchangedCodeResult(
  List<String> graphemes,
  TextOffsetStateSnapshot state,
) {
  return TextCommandResult(
    graphemes: List<String>.from(graphemes),
    cursorOffset: state.cursorOffset,
    selectionBaseOffset: state.selectionBaseOffset,
    selectionExtentOffset: state.selectionExtentOffset,
    changed: false,
  );
}

TextCommandResult _textResultFromCursorResult(
  List<String> graphemes,
  TextCursorCommandResult result,
) {
  return TextCommandResult(
    graphemes: List<String>.from(graphemes),
    cursorOffset: result.cursorOffset,
    selectionBaseOffset: result.selectionBaseOffset,
    selectionExtentOffset: result.selectionExtentOffset,
    changed: result.changed,
  );
}

TextCommandResult codeHandleClosingDelimiterAlignment({
  required TextDocument document,
  required TextOffsetStateSnapshot state,
  required CodeLanguageProfile profile,
  required String typed,
  required int indentWidth,
}) {
  final graphemes = document.flattenWithNewlines();
  if (state.hasSelection || !profile.closingToOpening.containsKey(typed)) {
    return _unchangedCodeResult(graphemes, state);
  }

  final cursor = document.positionForOffset(state.cursorOffset);
  final lineIndex = cursor.line.clamp(0, document.lineCount - 1);
  final lineGraphemes = document.lines[lineIndex];
  final beforeCursor = lineGraphemes.take(cursor.column).join();
  final line = lineGraphemes.join();
  if (beforeCursor.trim().isNotEmpty || line.trim().isNotEmpty) {
    return _unchangedCodeResult(graphemes, state);
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
  final graphemes = document.flattenWithNewlines();
  if (state.hasSelection) {
    return _unchangedCodeResult(graphemes, state);
  }
  final cursorOffset = state.cursorOffset;
  if (cursorOffset <= 0 || cursorOffset >= graphemes.length) {
    return _unchangedCodeResult(graphemes, state);
  }

  final opening = graphemes[cursorOffset - 1];
  final closing = graphemes[cursorOffset];
  if (profile.autoPairs[opening] != closing) {
    return _unchangedCodeResult(graphemes, state);
  }

  final working = document.copy();
  final result = edit_ops.removeDocumentRange(
    working,
    start: cursorOffset - 1,
    end: cursorOffset + 1,
    cursorOffset: cursorOffset - 1,
  );
  return TextCommandResult(
    graphemes: working.flattenWithNewlines(),
    cursorOffset: result.cursorOffset,
    changed: result.changed,
  );
}

TextCommandResult codeHandleAutoPair({
  required TextDocument document,
  required TextOffsetStateSnapshot state,
  required CodeLanguageProfile profile,
  required String typed,
}) {
  final graphemes = document.flattenWithNewlines();
  final matching = profile.autoPairs[typed];
  if (matching != null) {
    if (typed == matching &&
        !codeShouldAutoPairSymmetricDelimiter(
          document.text,
          state.cursorOffset,
          hasSelection: state.hasSelection,
        )) {
      return _unchangedCodeResult(graphemes, state);
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
    return TextCommandResult(
      graphemes: working.flattenWithNewlines(),
      cursorOffset: state.cursorOffset.clamp(0, document.length) + 1,
      changed: result.changed,
    );
  }

  if (!profile.autoPairs.containsValue(typed) || state.hasSelection) {
    return _unchangedCodeResult(graphemes, state);
  }

  final offset = state.cursorOffset;
  if (offset < graphemes.length && graphemes[offset] == typed) {
    final result = state.skipClosingDelimiterCommand(
      graphemes,
      closing: [typed],
    );
    return _textResultFromCursorResult(graphemes, result);
  }

  return _unchangedCodeResult(graphemes, state);
}

TextCommandResult codeInsertIndentedNewline({
  required TextDocument document,
  required TextOffsetStateSnapshot state,
  required int indentWidth,
  String? language,
}) {
  final graphemes = document.flattenWithNewlines();
  final cursor = document.positionForOffset(state.cursorOffset);
  final lineGraphemes = document.lines[cursor.line];
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
  final replacement = <String>[
    ...cursorInsertion,
    ...trailingSuffix,
  ];

  final start = state.hasSelection ? normalizedSelectionRange(
    state.selectionBaseOffset,
    state.selectionExtentOffset,
  )?.start ?? state.cursorOffset : state.cursorOffset;
  final endBase = state.hasSelection ? normalizedSelectionRange(
    state.selectionBaseOffset,
    state.selectionExtentOffset,
  )?.end ?? state.cursorOffset : state.cursorOffset;
  final end = state.hasSelection
      ? endBase
      : (endBase + trailingSuffixReplaceCount).clamp(endBase, graphemes.length);

  final working = document.copy();
  final result = edit_ops.replaceDocumentRange(
    working,
    start: start,
    end: end,
    replacement: replacement,
    cursorOffset: start + cursorInsertion.length,
  );
  return TextCommandResult(
    graphemes: working.flattenWithNewlines(),
    cursorOffset: result.cursorOffset,
    changed: result.changed,
  );
}

TextCommandResult codeToggleBlockComments({
  required TextDocument document,
  required TextOffsetStateSnapshot state,
  required CodeLanguageProfile profile,
}) {
  final graphemes = document.flattenWithNewlines();
  final delimiters = profile.blockCommentDelimiters;
  if (delimiters == null || document.text.isEmpty) {
    return _unchangedCodeResult(graphemes, state);
  }

  final cursor = document.positionForOffset(state.cursorOffset);
  final line = cursor.line.clamp(0, document.lineCount - 1);
  return state.toggleDelimitedSegmentCommand(
    graphemes,
    rangeStartOffset: document.offsetForPosition(
      TextPosition(line: line, column: 0),
    ),
    rangeEndOffset: document.offsetForPosition(
      TextPosition(line: line, column: document.lineLength(line)),
    ),
    startDelimiter: delimiters.start,
    endDelimiter: delimiters.end,
  );
}
