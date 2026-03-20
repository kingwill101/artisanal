library;

import 'package:characters/characters.dart';

import 'code_edit_policy.dart';
import 'code_language_profile.dart';
import 'editor_state.dart';
import 'state_bridge.dart';
import 'text_commands.dart';
import 'text_document.dart';

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
  return state.transformSelectionOrLineCommand(
    graphemes,
    lineStartOffset: document.offsetForPosition(
      TextPosition(line: lineIndex, column: 0),
    ),
    lineEndOffset: document.offsetForPosition(
      TextPosition(line: lineIndex, column: document.lineLength(lineIndex)),
    ),
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
  return state.deleteSurroundingPairCommand(
    graphemes,
    surroundPairs: profile.autoPairs,
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

    return state.insertAutoPairCommand(
      graphemes,
      opening: [typed],
      closing: [matching],
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

  return state.insertIndentedNewlineCommand(
    graphemes,
    baseIndent: baseIndent.characters.toList(growable: false),
    additionalIndent:
        codeShouldIncreaseIndentAfter(trimmedBefore, language: language)
        ? (' ' * (indentWidth < 1 ? 1 : indentWidth)).characters.toList(
            growable: false,
          )
        : const <String>[],
    trailingSuffix:
        blockSuffix?.text.characters.toList(growable: false) ??
        const <String>[],
    trailingSuffixReplaceCount: blockSuffix?.consumedColumns ?? 0,
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
