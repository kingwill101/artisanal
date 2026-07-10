/// Text input example ported from Bubble Tea.
library;

import 'package:artisanal/bubbles.dart'
    hide
        CodeBlockCommentDelimiters,
        CodeLanguageProfile,
        Column,
        CommonKeyBindings,
        EditBuffer,
        EditHistoryCoalescePredicate,
        EditHistoryController,
        EditHistoryMarkerBuilder,
        EditHistoryStateEquals,
        EditorCoreConfig,
        EditorState,
        GraphemePredicate,
        GraphemeReader,
        Help,
        KeyBinding,
        KeyMap,
        PasteMsg,
        Row,
        Spinner,
        SpinnerModel,
        SpinnerTickMsg,
        Spinners,
        Text,
        TextCommandResult,
        TextCursorCommandResult,
        TextDecorationLayerKey,
        TextDecorationRange,
        TextDiagnosticRange,
        TextDiagnosticSeverity,
        TextDocument,
        TextDocumentChange,
        TextDocumentEditResult,
        TextEditResult,
        TextExtmark,
        TextExtmarkOptions,
        TextExtmarkPositionRange,
        TextExtmarksController,
        TextHighlightRange,
        TextHitResult,
        TextLineCommandResult,
        TextLineDecoration,
        TextLineStateCommandExtensions,
        TextLineStateSnapshot,
        TextOffsetStateCommandExtensions,
        TextOffsetStateDocumentEditingExtensions,
        TextOffsetStateSnapshot,
        TextPasteChunk,
        TextPasteChunkStep,
        TextPasteController,
        TextPasteMode,
        TextPastePlan,
        TextPasteReference,
        TextPasteReferenceStore,
        TextPasteSession,
        TextPatternDiagnosticRule,
        TextPosition,
        TextPositionDiagnosticRange,
        TextSelection,
        TextSyntaxBuildResult,
        TextSyntaxChangeWindow,
        TextSyntaxDecorationPatch,
        TextSyntaxLineWindow,
        TextSyntaxProvider,
        TextSyntaxSession,
        TextSyntaxSnapshot,
        TextView,
        TextViewLine,
        TextViewport,
        TextVisualCursorPosition,
        UndoCommandDecoder,
        UndoCommandJournalEntry,
        UndoManager,
        UndoableCommand;

import 'package:artisanal/tui.dart';

// #region text_input_usage
class TextInputExampleModel implements Model {
  TextInputExampleModel({TextInputModel? input})
    : input = input ?? _buildInput();

  final TextInputModel input;

  TextInputExampleModel copyWith({TextInputModel? input}) {
    return TextInputExampleModel(input: input ?? this.input);
  }

  static TextInputModel _buildInput() {
    final ti = TextInputModel(
      placeholder: 'Pikachu',
      charLimit: 156,
      width: 20,
    );
    return ti;
  }

  @override
  Cmd? init() => input.focus();

  @override
  (Model, Cmd?) update(Msg msg) {
    switch (msg) {
      case KeyMsg(key: Key(type: KeyType.enter)):
      case KeyMsg(key: Key(ctrl: true, runes: [0x63])): // Ctrl+C
      case KeyMsg(key: Key(type: KeyType.escape)):
        return (this, Cmd.quit());

      default:
        final (newInput, cmd) = input.update(msg);
        return (copyWith(input: newInput), cmd);
    }
  }

  @override
  String view() {
    return "What's your favorite Pokemon?\n\n"
        '${input.view()}\n\n'
        '(esc to quit)\n';
  }
}
// #endregion

Future<void> main() async {
  await runProgram(
    TextInputExampleModel(),
    options: const ProgramOptions(
      altScreen: false,
      hideCursor: false,
      useUltravioletInputDecoder: true,
      useUltravioletRenderer: true,
    ),
  );
}
