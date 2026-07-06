/// Bottom-pinned inline build dashboard with streaming logs.
///
/// This example stays on the primary screen and streams log lines above a
/// fixed dashboard. It is intentionally close to long-running CLIs such as
/// `flutter run`, where logs must remain scrollable while the live status UI
/// stays pinned.
///
/// Run: dart run example/tui/examples/inline/pinned_build_dashboard.dart
///
/// Press q to quit, space to pause/resume.
library;
import 'package:artisanal/bubbles.dart' as tui hide CodeBlockCommentDelimiters, CodeLanguageProfile, Column, CommonKeyBindings, EditBuffer, EditHistoryCoalescePredicate, EditHistoryController, EditHistoryMarkerBuilder, EditHistoryStateEquals, EditorCoreConfig, EditorState, GraphemePredicate, GraphemeReader, Help, KeyBinding, KeyMap, PasteMsg, Row, Spinner, SpinnerModel, SpinnerTickMsg, Spinners, Text, TextCommandResult, TextCursorCommandResult, TextDecorationLayerKey, TextDecorationRange, TextDiagnosticRange, TextDiagnosticSeverity, TextDocument, TextDocumentChange, TextDocumentEditResult, TextEditResult, TextExtmark, TextExtmarkOptions, TextExtmarkPositionRange, TextExtmarksController, TextHighlightRange, TextHitResult, TextLineCommandResult, TextLineDecoration, TextLineStateCommandExtensions, TextLineStateSnapshot, TextOffsetStateCommandExtensions, TextOffsetStateDocumentEditingExtensions, TextOffsetStateSnapshot, TextPasteChunk, TextPasteChunkStep, TextPasteController, TextPasteMode, TextPastePlan, TextPasteReference, TextPasteReferenceStore, TextPasteSession, TextPatternDiagnosticRule, TextPosition, TextPositionDiagnosticRange, TextSelection, TextSyntaxBuildResult, TextSyntaxChangeWindow, TextSyntaxDecorationPatch, TextSyntaxLineWindow, TextSyntaxProvider, TextSyntaxSession, TextSyntaxSnapshot, TextView, TextViewLine, TextViewport, TextVisualCursorPosition, UndoCommandDecoder, UndoCommandJournalEntry, UndoManager, UndoableCommand;

// tui:allow-stdout — standalone inline CLI utility used for diagnostics.
import 'dart:math';
import 'dart:io';

import 'package:artisanal/tui.dart';
import 'package:artisanal/style.dart';

Random _rng = Random();

const _phases = [
  'resolve packages',
  'compile kernel',
  'sync assets',
  'launch app',
  'attach vm service',
  'hot reload ready',
];

const _logTemplates = [
  'Resolving dependencies in example...',
  'Compiling lib/main.dart for linux-x64...',
  'Syncing shader warmup bundle...',
  'Copying assets and generated fonts...',
  'Connecting Dart VM service...',
  'Rebuilt widget tree in {ms}ms.',
  'Frame raster={ms}ms ui={ui}ms',
  'Device linux reports {fps}fps',
];

class PinnedBuildDashboard implements Model {
  PinnedBuildDashboard({
    this.tick = 0,
    this.running = true,
    this.progress = 0,
    this.tickInterval = const Duration(milliseconds: 450),
    tui.ProgressModel? progressBar,
  }) : progressBar =
           progressBar ??
           tui.ProgressModel(
             width: 36,
             showPercentage: false,
             useGradient: true,
           );

  factory PinnedBuildDashboard.initial({Duration? tickInterval}) =>
      PinnedBuildDashboard(
        tickInterval: tickInterval ?? const Duration(milliseconds: 450),
      );

  final int tick;
  final bool running;
  final int progress;
  final Duration tickInterval;
  final tui.ProgressModel progressBar;

  @override
  Cmd? init() {
    _traceEvent(
      'example.init',
      fields: {'tickIntervalMs': tickInterval.inMilliseconds},
    );
    return every(tickInterval, (_) => const _BuildTick());
  }

  @override
  (Model, Cmd?) update(Msg msg) {
    if (msg is _BuildTick && !running) return (this, null);

    return switch (msg) {
      _BuildTick() => _nextTick(),
      WindowSizeMsg(:final width, :final height) => _windowSize(width, height),
      KeyMsg(key: Key(type: KeyType.runes, runes: [0x20])) => (
        copyWith(running: !running),
        Cmd.println(running ? '[dashboard] paused' : '[dashboard] resumed'),
      ),
      tui.ProgressFrameMsg() => _updateProgress(msg),
      KeyMsg(key: Key(type: KeyType.runes, runes: [0x71])) ||
      KeyMsg(key: Key(type: KeyType.escape)) ||
      KeyMsg(key: Key(ctrl: true, runes: [0x63])) => (this, Cmd.quit()),
      _ => (this, null),
    };
  }

  (Model, Cmd?) _nextTick() {
    final nextProgress = (progress + 3 + _rng.nextInt(9)) % 101;
    final (nextProgressBar, progressCmd) = progressBar.setPercent(
      nextProgress / 100,
      animate: false,
    );
    final next = copyWith(
      tick: tick + 1,
      progress: nextProgress,
      progressBar: nextProgressBar,
    );
    final logLine = next._logLine();
    _traceEvent(
      'example.tick',
      fields: {
        'tick': next.tick,
        'progress': next.progress,
        'running': next.running,
        'logLine': logLine,
      },
    );
    final logCmd = Cmd.println(logLine);
    return (
      next,
      progressCmd == null ? logCmd : Cmd.batch([progressCmd, logCmd]),
    );
  }

  (Model, Cmd?) _windowSize(int width, int height) {
    _traceEvent(
      'example.window_size',
      fields: {'width': width, 'height': height, 'tick': tick},
    );
    return (this, null);
  }

  (Model, Cmd?) _updateProgress(tui.ProgressFrameMsg msg) {
    final (nextProgressBar, cmd) = progressBar.update(msg);
    return (copyWith(progressBar: nextProgressBar), cmd);
  }

  PinnedBuildDashboard copyWith({
    int? tick,
    bool? running,
    int? progress,
    tui.ProgressModel? progressBar,
  }) {
    return PinnedBuildDashboard(
      tick: tick ?? this.tick,
      running: running ?? this.running,
      progress: progress ?? this.progress,
      tickInterval: tickInterval,
      progressBar: progressBar ?? this.progressBar,
    );
  }

  String _logLine() {
    final template = _logTemplates[tick % _logTemplates.length];
    final line = template
        .replaceAll('{ms}', '${12 + _rng.nextInt(90)}')
        .replaceAll('{ui}', '${2 + _rng.nextInt(14)}')
        .replaceAll('{fps}', '${58 + _rng.nextInt(63)}');
    return '[${tick.toString().padLeft(4, '0')}] $line';
  }

  @override
  View view() {
    final phase = _phases[tick % _phases.length];
    final status = running ? 'RUNNING' : 'PAUSED ';
    final fps = 58 + (tick * 7) % 63;
    final mem = 210 + (tick * 5) % 64;
    final deviceState = tick % 17 == 0 ? 'usb reconnecting' : 'linux ready';
    final statusStyle = running ? _runningStyle : _pausedStyle;
    final content = [
      _row([
        statusStyle.render(status),
        'phase: ${_padRightCells(phase, 18)}',
        'progress: ${progress.toString().padLeft(3)}%',
      ]),
      progressBar.view(),
      _row([
        'perf: ${fps.toString().padLeft(3)}fps',
        'memory: ${mem}MB',
        'device: $deviceState',
      ]),
      _helpStyle.render('keys: space pause/resume   q quit'),
    ];

    _traceEvent(
      'example.view',
      fields: {
        'tick': tick,
        'progress': progress,
        'running': running,
        'phase': phase,
        'deviceState': deviceState,
        'rows': content.length,
      },
    );

    return View(
      content: tui.Panel()
          .title('flutter build dashboard')
          .titleStyle(_titleStyle)
          .border(Border.rounded)
          .borderStyle(_panelBorderStyle)
          .padding(0, 1)
          .width(72)
          .lines(content)
          .render(),
    );
  }
}

final _panelBorderStyle = Style().foreground(const AnsiColor(111));
final _titleStyle = Style().bold().foreground(const AnsiColor(111));
final _runningStyle = Style().bold().foreground(const AnsiColor(42));
final _pausedStyle = Style().bold().foreground(const AnsiColor(214));
final _helpStyle = Style().foreground(const AnsiColor(244));

String _row(List<String> columns) => columns.join('  ');

String _padRightCells(String value, int width) {
  final pad = width - Layout.visibleLength(value);
  if (pad <= 0) return value;
  return '$value${' ' * pad}';
}

class _BuildTick extends Msg {
  const _BuildTick();
}

void main(List<String> args) async {
  final config = _ExampleConfig.parse(args);
  if (config.help) {
    print(_usage);
    return;
  }

  if (config.seed != null) {
    _rng = Random(config.seed);
  }

  if (config.tracePath != null) {
    final traceFile = File(config.tracePath!);
    traceFile.parent.createSync(recursive: true);
    if (traceFile.existsSync()) {
      traceFile.deleteSync();
    }
    TuiTrace.configureForTest(
      enabled: true,
      path: traceFile.path,
      captureEnabled: config.traceCapture,
      tagsRaw: config.traceTags,
    );
  }

  print('Starting inline build dashboard...');
  print('Logs stream above the pinned panel and remain in native scrollback.');
  if (config.tracePath != null) {
    print('Trace: ${config.tracePath}');
    print(
      'Trace tags: ${config.traceTags ?? 'all'}; capture=${config.traceCapture}',
    );
  }
  print('');

  try {
    await runProgram(
      PinnedBuildDashboard.initial(tickInterval: config.tickInterval),
      options: ProgramOptions(
        screenMode: ScreenMode.inline,
        inlineHeight: 6,
        uiAnchor: UiAnchor.bottom,
        mouseMode: MouseMode.none,
        fps: 30,
        startupProbes: false,
        interceptor: config.tracePath == null
            ? null
            : _InlineTraceInterceptor(),
      ),
    );
  } finally {
    _traceEvent('example.exit');
    TuiTrace.clearTestOverrides();
  }

  print('');
  print('Inline build dashboard exited.');
  if (config.tracePath != null) {
    print('Trace written to ${config.tracePath}');
  }
}

final class _InlineTraceInterceptor extends ProgramInterceptor {
  final ProgramRenderRecorder _recorder = ProgramRenderRecorder();

  @override
  bool get wantsNativeFrames => true;

  @override
  Msg? onSend(Msg msg) {
    _traceEvent(
      'example.msg.send',
      tag: TraceTag.queue,
      fields: _messageFields(msg),
    );
    return msg;
  }

  @override
  void onProcessed(Msg msg, Duration elapsed) {
    _traceEvent(
      'example.msg.processed',
      tag: TraceTag.dispatch,
      fields: {..._messageFields(msg), 'elapsedUs': elapsed.inMicroseconds},
    );
  }

  @override
  void onRendered({
    required int renderGeneration,
    required Object view,
    required DegradationLevel degradationLevel,
    required Duration renderDuration,
    int? width,
    int? height,
    TerminalNativeFrame? nativeFrame,
    TerminalNativeDeltaFrame? nativeDelta,
    TerminalNativeCellDeltaFrame? nativeCellDelta,
    List<TerminalNativeSpanDelta>? nativeSpanDelta,
  }) {
    _recorder.onRendered(
      renderGeneration: renderGeneration,
      view: view,
      degradationLevel: degradationLevel,
      renderDuration: renderDuration,
      width: width,
      height: height,
      nativeFrame: nativeFrame,
      nativeDelta: nativeDelta,
      nativeCellDelta: nativeCellDelta,
      nativeSpanDelta: nativeSpanDelta,
    );
    final snapshot = _recorder.lastSnapshot;
    _traceEvent(
      'example.rendered',
      tag: TraceTag.render,
      fields: {
        'generation': renderGeneration,
        'width': width,
        'height': height,
        'durationUs': renderDuration.inMicroseconds,
        'degradation': degradationLevel.name,
        if (snapshot != null) 'lines': snapshot.lines,
        if (snapshot != null) 'changeSummary': snapshot.changeSummary.toJson(),
      },
    );
  }

  @override
  void onStop() {
    _traceEvent('example.program.stop');
  }
}

Map<String, Object?> _messageFields(Msg msg) {
  return switch (msg) {
    WindowSizeMsg(:final width, :final height) => {
      'type': 'WindowSizeMsg',
      'width': width,
      'height': height,
    },
    KeyMsg(:final key) => {
      'type': 'KeyMsg',
      'keyType': key.type.name,
      'runes': key.runes,
      'ctrl': key.ctrl,
      'alt': key.alt,
      'shift': key.shift,
    },
    tui.ProgressFrameMsg() => {'type': 'ProgressFrameMsg'},
    _BuildTick() => {'type': '_BuildTick'},
    QuitMsg() => {'type': 'QuitMsg'},
    _ => {'type': msg.runtimeType.toString()},
  };
}

void _traceEvent(
  String type, {
  TraceTag tag = TraceTag.general,
  Map<String, Object?> fields = const {},
}) {
  if (!TuiTrace.enabled) return;
  TuiTrace.event(type, tag: tag, fields: fields);
}

final class _ExampleConfig {
  const _ExampleConfig({
    required this.help,
    required this.tracePath,
    required this.traceTags,
    required this.traceCapture,
    required this.tickInterval,
    required this.seed,
  });

  final bool help;
  final String? tracePath;
  final String? traceTags;
  final bool traceCapture;
  final Duration tickInterval;
  final int? seed;

  static _ExampleConfig parse(List<String> args) {
    var help = false;
    var trace = false;
    String? tracePath;
    String? traceTags;
    var traceCapture = false;
    var tickMs = 450;
    int? seed;

    for (var i = 0; i < args.length; i++) {
      final arg = args[i];
      switch (arg) {
        case '-h':
        case '--help':
          help = true;
        case '--trace':
          trace = true;
        case '--trace-capture':
          traceCapture = true;
        case '--trace-path':
          trace = true;
          tracePath = args[++i];
        case '--trace-tags':
          traceTags = args[++i];
        case '--tick-ms':
          tickMs = int.parse(args[++i]);
        case '--seed':
          seed = int.parse(args[++i]);
        default:
          if (arg.startsWith('--trace-path=')) {
            trace = true;
            tracePath = arg.substring('--trace-path='.length);
          } else if (arg.startsWith('--trace-tags=')) {
            traceTags = arg.substring('--trace-tags='.length);
          } else if (arg.startsWith('--tick-ms=')) {
            tickMs = int.parse(arg.substring('--tick-ms='.length));
          } else if (arg.startsWith('--seed=')) {
            seed = int.parse(arg.substring('--seed='.length));
          } else {
            throw ArgumentError('Unknown argument: $arg\n\n$_usage');
          }
      }
    }

    if (trace && tracePath == null) {
      tracePath = _defaultTracePath();
    }

    return _ExampleConfig(
      help: help,
      tracePath: tracePath,
      traceTags: traceTags,
      traceCapture: traceCapture,
      tickInterval: Duration(milliseconds: tickMs),
      seed: seed,
    );
  }
}

String _defaultTracePath() {
  final now = DateTime.now().toIso8601String().replaceAll(':', '-');
  return 'build/inline-traces/pinned-build-dashboard-$now.log';
}

const _usage = '''
Bottom-pinned inline build dashboard with streaming logs.

Usage:
  dart run pinned_build_dashboard.dart [options]

Options:
  --trace                 Enable structured TUI trace logging.
  --trace-path <path>     Write trace to a specific path.
  --trace-tags <tags>     Comma-separated tags, e.g. render,flush,queue.
  --trace-capture         Enable dispatch-capture diagnostics.
  --tick-ms <ms>          Log/tick interval. Default: 450.
  --seed <int>            Deterministic random seed for log values.
  -h, --help              Print this help.
''';
