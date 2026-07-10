/// DevTools demo — a counter with ArtisanalDevTools, CapturedOutputModel,
/// and the enhanced DebugOverlayModel wired together.
///
/// Run with VM service enabled so the CLI inspector (or Dart DevTools)
/// can connect:
///
///   dart run --enable-vm-service example/devtools_demo.dart
///
/// Then in another terminal:
///
///   dart run example/artisanal_inspector.dart ws://127.0.0.1:8181/AUTH/ws
///
/// Keys:
///   ↑ / +     increment (also prints a line to test captured output)
///   ↓ / -     decrement
///   d         toggle debug overlay
///   m         cycle overlay mode (metrics → messages → output → all)
///   q / Esc   quit
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
import 'package:artisanal/src/tui/bubbles/debug_overlay.dart';

// Keep a top-level reference so the model can feed messageLog data
// into the overlay. In a real app you might pass this through a
// different mechanism.
final devtools = ArtisanalDevTools();

void main() async {
  await runProgram(
    DemoModel.initial(),
    options: ProgramOptions(
      altScreen: true,
      captureOutput: true,
      interceptor: devtools,
      // Enable render metrics so the overlay has data.
      frameTick: false,
    ),
  );
}

class DemoModel implements Model, CapturedOutputModel, RenderMetricsModel {
  const DemoModel({
    required this.count,
    required this.outputLog,
    required this.debugOverlay,
  });

  factory DemoModel.initial() => DemoModel(
    count: 0,
    outputLog: const OutputLog(maxEntries: 50),
    debugOverlay: DebugOverlayModel.initial(
      terminalWidth: 80,
      terminalHeight: 24,
      enabled: true,
    ),
  );

  final int count;

  @override
  final OutputLog outputLog;

  final DebugOverlayModel debugOverlay;

  @override
  bool get wantsRenderMetrics => true;

  DemoModel copyWith({
    int? count,
    OutputLog? outputLog,
    DebugOverlayModel? debugOverlay,
  }) => DemoModel(
    count: count ?? this.count,
    outputLog: outputLog ?? this.outputLog,
    debugOverlay: debugOverlay ?? this.debugOverlay,
  );

  @override
  Model withOutputLog(OutputLog log) => copyWith(outputLog: log);

  @override
  Cmd? init() => null;

  @override
  (Model, Cmd?) update(Msg msg) {
    // Feed latest devtools data into the overlay.
    var nextDebug = debugOverlay.copyWith(
      messageEntries: devtools.messageLog.reversed.take(10).toList(),
      outputEntries: outputLog.entries.reversed.take(10).toList(),
    );

    // Let the overlay handle its messages (metrics, mouse, resize).
    final debugUpdate = nextDebug.update(msg);
    nextDebug = debugUpdate.model;
    if (debugUpdate.consumed) {
      return (copyWith(debugOverlay: nextDebug), debugUpdate.cmd);
    }

    return switch (msg) {
      // Increment.
      KeyMsg(key: Key(type: KeyType.up)) ||
      KeyMsg(key: Key(type: KeyType.runes, runes: [0x2b])) => () {
        final next = count + 1;
        // This print() will be captured by CapturedOutputModel.
        print('Counter incremented to $next');
        return (copyWith(count: next, debugOverlay: nextDebug), null as Cmd?);
      }(),

      // Decrement.
      KeyMsg(key: Key(type: KeyType.down)) ||
      KeyMsg(
        key: Key(type: KeyType.runes, runes: [0x2d]),
      ) => (copyWith(count: count - 1, debugOverlay: nextDebug), null),

      // Toggle debug overlay.
      KeyMsg(key: Key(type: KeyType.runes, runes: [0x64])) => (
        // 'd'
        copyWith(debugOverlay: nextDebug.toggle()),
        null,
      ),

      // Cycle overlay mode.
      KeyMsg(key: Key(type: KeyType.runes, runes: [0x6d])) => (
        // 'm'
        copyWith(debugOverlay: nextDebug.cycleMode()),
        null,
      ),

      // Quit.
      KeyMsg(key: Key(type: KeyType.runes, runes: [0x71])) || // 'q'
      KeyMsg(
        key: Key(type: KeyType.escape),
      ) => (copyWith(debugOverlay: nextDebug), Cmd.quit()),

      // Default — just update the overlay state.
      _ => (copyWith(debugOverlay: nextDebug), null),
    };
  }

  @override
  String view() {
    final bar = _bar(count);
    final modeName = debugOverlay.mode.name;

    final base =
        '''

  ╔══════════════════════════════════════╗
  ║        DevTools Demo Counter         ║
  ╚══════════════════════════════════════╝

  Count: $count

  $bar

  Output log: ${outputLog.length} entries

  Controls:
    ↑ / +   Increment (also prints a line)
    ↓ / -   Decrement
    d       Toggle debug overlay
    m       Cycle overlay mode (current: $modeName)
    q       Quit

''';

    return debugOverlay.compose(base);
  }

  String _bar(int value) {
    const maxWidth = 30;
    final abs = value.abs().clamp(0, maxWidth);
    if (value == 0) return '  [${'─' * maxWidth}]';
    if (value > 0) {
      return '  [\x1b[32m${'█' * abs}\x1b[0m${'─' * (maxWidth - abs)}]';
    }
    return '  [${'─' * (maxWidth - abs)}\x1b[31m${'█' * abs}\x1b[0m]';
  }

  @override
  String toString() => 'DemoModel(count=$count, output=${outputLog.length})';
}
