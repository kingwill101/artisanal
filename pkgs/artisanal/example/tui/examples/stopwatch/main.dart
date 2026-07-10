/// Stopwatch example ported from Bubble Tea.
library;

import 'package:artisanal/bubbles.dart'
    as tui
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

import 'package:artisanal/tui.dart' as tui;

const _interval = Duration(milliseconds: 100);

class StopwatchKeys extends tui.KeyMap {
  StopwatchKeys()
    : start = tui.KeyBinding.withHelp(['s'], 's', 'start/stop'),
      stop = tui.KeyBinding.withHelp(['s'], 's', 'start/stop'),
      reset = tui.KeyBinding.withHelp(['r'], 'r', 'reset'),
      quit = tui.KeyBinding.withHelp(['q', 'ctrl+c'], 'q', 'quit') {
    shortHelp = [start, reset, quit];
    fullHelp = [
      [start, reset, quit],
    ];
  }

  final tui.KeyBinding start;
  final tui.KeyBinding stop;
  final tui.KeyBinding reset;
  final tui.KeyBinding quit;
}

class StopwatchExampleModel implements tui.Model {
  StopwatchExampleModel({
    required this.stopwatch,
    required this.keys,
    required this.help,
    this.quitting = false,
  });

  factory StopwatchExampleModel.initial() => StopwatchExampleModel(
    stopwatch: tui.StopwatchModel(interval: _interval),
    keys: StopwatchKeys(),
    help: tui.HelpModel(),
  );

  final tui.StopwatchModel stopwatch;
  final StopwatchKeys keys;
  final tui.HelpModel help;
  final bool quitting;

  @override
  tui.Cmd? init() => stopwatch.start();

  @override
  (tui.Model, tui.Cmd?) update(tui.Msg msg) {
    switch (msg) {
      case tui.KeyMsg(key: final key):
        if (_matches(key, [keys.quit])) {
          return (copyWith(quitting: true), tui.Cmd.quit());
        }
        if (_matches(key, [keys.reset])) {
          return (this, stopwatch.reset());
        }
        if (_matches(key, [keys.start, keys.stop])) {
          return (this, stopwatch.toggle());
        }
      case tui.StopwatchTickMsg():
      case tui.StopwatchStartStopMsg():
      case tui.StopwatchResetMsg():
        final (newStopwatch, cmd) = stopwatch.update(msg);
        return (copyWith(stopwatch: newStopwatch), cmd);
    }
    return (this, null);
  }

  StopwatchExampleModel copyWith({
    tui.StopwatchModel? stopwatch,
    StopwatchKeys? keys,
    tui.HelpModel? help,
    bool? quitting,
  }) {
    return StopwatchExampleModel(
      stopwatch: stopwatch ?? this.stopwatch,
      keys: keys ?? this.keys,
      help: help ?? this.help,
      quitting: quitting ?? this.quitting,
    );
  }

  @override
  String view() {
    var s = stopwatch.view();
    if (!quitting) {
      s = 'Elapsed: $s\n${help.shortHelpView([keys.start, keys.reset, keys.quit])}';
    }
    return '$s\n';
  }
}

bool _matches(tui.Key key, List<tui.KeyBinding> bindings) =>
    tui.keyMatches(key, bindings);

Future<void> main() async {
  await tui.runProgram(
    StopwatchExampleModel.initial(),
    options: const tui.ProgramOptions(altScreen: false, hideCursor: false),
  );
}
