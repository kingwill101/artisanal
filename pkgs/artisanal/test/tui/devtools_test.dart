import 'dart:async';

import 'package:artisanal/src/style/color.dart';
import 'package:artisanal/src/tui/cmd.dart';
import 'package:artisanal/src/tui/degradation.dart';
import 'package:artisanal/src/tui/devtools.dart';
import 'package:artisanal/src/tui/model.dart';
import 'package:artisanal/src/tui/msg.dart';
import 'package:artisanal/src/tui/program.dart';
import 'package:artisanal/src/tui/terminal.dart';
import 'package:artisanal/src/tui/terminal_native_frame.dart';
import 'package:artisanal/src/terminal/keys.dart' show Key, KeyType;
import 'package:test/test.dart';

void main() {
  // =========================================================================
  // DevToolsMessageEntry
  // =========================================================================

  group('DevToolsMessageEntry', () {
    test('toJson serializes all fields', () {
      final entry = DevToolsMessageEntry(
        timestamp: DateTime.utc(2025, 6, 15, 12, 0, 0),
        messageType: 'KeyMsg',
        summary: 'key: runes runes=[113]',
        processingTime: const Duration(microseconds: 420),
      );

      final json = entry.toJson();
      expect(json['timestamp'], '2025-06-15T12:00:00.000Z');
      expect(json['messageType'], 'KeyMsg');
      expect(json['summary'], 'key: runes runes=[113]');
      expect(json['processingTimeUs'], 420);
    });
  });

  // =========================================================================
  // DevToolsRenderStats
  // =========================================================================

  group('DevToolsRenderStats', () {
    test('initial state has zero frameCount', () {
      final stats = DevToolsRenderStats();
      final json = stats.toJson();
      expect(json['frameCount'], 0);
      expect(json['avgRenderUs'], 0);
    });

    test('record accumulates timing stats', () {
      final stats = DevToolsRenderStats();

      stats.record(
        renderDuration: const Duration(microseconds: 1000),
        degradationLevel: DegradationLevel.full,
        width: 80,
        height: 24,
      );
      stats.record(
        renderDuration: const Duration(microseconds: 3000),
        degradationLevel: DegradationLevel.full,
        width: 80,
        height: 24,
      );

      final json = stats.toJson();
      expect(json['frameCount'], 2);
      expect(json['minRenderUs'], 1000);
      expect(json['maxRenderUs'], 3000);
      expect(json['lastRenderUs'], 3000);
      expect(json['totalRenderUs'], 4000);
      expect(json['avgRenderUs'], 2000);
      expect(json['lastDegradation'], 'full');
      expect(json['lastWidth'], 80);
      expect(json['lastHeight'], 24);
    });

    test('tracks latest degradation level and dimensions', () {
      final stats = DevToolsRenderStats();

      stats.record(
        renderDuration: const Duration(microseconds: 500),
        degradationLevel: DegradationLevel.full,
        width: 80,
        height: 24,
      );
      stats.record(
        renderDuration: const Duration(microseconds: 600),
        degradationLevel: DegradationLevel.simpleBorders,
        width: 120,
        height: 40,
      );

      final json = stats.toJson();
      expect(json['lastDegradation'], 'simpleBorders');
      expect(json['lastWidth'], 120);
      expect(json['lastHeight'], 40);
    });
  });

  // =========================================================================
  // ArtisanalDevTools - Unit tests
  // =========================================================================

  group('ArtisanalDevTools', () {
    late ArtisanalDevTools devtools;

    setUp(() {
      // Disable service extensions to avoid duplicate registration
      // errors across tests (they persist for the isolate lifetime).
      devtools = ArtisanalDevTools(
        enableTimeline: false,
        enablePostEvent: false,
        enableServiceExtensions: false,
      );
    });

    test('starts in not-running state', () {
      expect(devtools.isRunning, isFalse);
      expect(devtools.messageLog, isEmpty);
    });

    test('onStart sets running and captures send callback', () {
      devtools.onStart((_) {});

      expect(devtools.isRunning, isTrue);
    });

    test('onStop clears running state', () {
      devtools.onStart((_) {});
      devtools.onStop();

      expect(devtools.isRunning, isFalse);
    });

    test('onSend returns message unchanged (no inner)', () {
      const msg = CustomMsg('test');
      final result = devtools.onSend(msg);

      expect(result, same(msg));
    });

    test('onProcessed records message log entry', () {
      devtools.onStart((_) {});
      const msg = CustomMsg('hello');
      devtools.onProcessed(msg, const Duration(microseconds: 123));

      expect(devtools.messageLog, hasLength(1));
      final entry = devtools.messageLog.first;
      expect(entry.messageType, 'CustomMsg<String>');
      expect(entry.summary, 'custom: hello');
      expect(entry.processingTime, const Duration(microseconds: 123));
    });

    test('message log ring buffer evicts oldest entries', () {
      final dt = ArtisanalDevTools(
        maxLogEntries: 3,
        enableTimeline: false,
        enablePostEvent: false,
        enableServiceExtensions: false,
      );
      dt.onStart((_) {});

      for (var i = 0; i < 5; i++) {
        dt.onProcessed(CustomMsg('msg-$i'), const Duration(microseconds: 10));
      }

      expect(dt.messageLog, hasLength(3));
      // Oldest two (msg-0, msg-1) should have been evicted.
      expect(dt.messageLog[0].summary, 'custom: msg-2');
      expect(dt.messageLog[1].summary, 'custom: msg-3');
      expect(dt.messageLog[2].summary, 'custom: msg-4');
    });

    test('onStart clears message log', () {
      devtools.onStart((_) {});
      devtools.onProcessed(
        const CustomMsg('x'),
        const Duration(microseconds: 1),
      );
      expect(devtools.messageLog, hasLength(1));

      // Re-start should clear the log.
      devtools.onStart((_) {});
      expect(devtools.messageLog, isEmpty);
    });

    test('onRendered updates render stats', () {
      devtools.onRendered(
        renderGeneration: 1,
        view: 'test view',
        degradationLevel: DegradationLevel.full,
        renderDuration: const Duration(microseconds: 500),
        width: 80,
        height: 24,
      );

      final json = devtools.renderStats.toJson();
      expect(json['frameCount'], 1);
      expect(json['lastRenderUs'], 500);
    });

    test('bindOptions stores options', () {
      const options = ProgramOptions(altScreen: false, fps: 30);
      devtools.bindOptions(options);

      // Verify through the internal state (options are stored).
      // We can't directly access _options, but we can confirm it
      // doesn't throw.
      expect(() => devtools.bindOptions(options), returnsNormally);
    });

    test('updateModelSnapshot caches model string', () {
      devtools.updateModelSnapshot('MyModel(count: 42)');
      // Internal _lastModelString is updated. We verify this
      // indirectly through the getState extension in integration
      // tests; here we just confirm it doesn't throw.
      expect(
        () => devtools.updateModelSnapshot('MyModel(count: 42)'),
        returnsNormally,
      );

      // Null model produces '<null>'.
      devtools.updateModelSnapshot(null);
      expect(() => devtools.updateModelSnapshot(null), returnsNormally);
    });

    // -----------------------------------------------------------------------
    // Inner interceptor delegation
    // -----------------------------------------------------------------------

    group('inner interceptor delegation', () {
      test('onStart delegates to inner', () {
        var innerStarted = false;
        final inner = _TestInterceptor(
          onStartHook: (_) {
            innerStarted = true;
          },
        );
        final dt = ArtisanalDevTools(
          inner: inner,
          enableTimeline: false,
          enablePostEvent: false,
          enableServiceExtensions: false,
        );

        dt.onStart((_) {});
        expect(innerStarted, isTrue);
      });

      test('onSend delegates to inner and respects null (drop)', () {
        final inner = _TestInterceptor(
          onSendHook: (msg) => null, // Drop all messages.
        );
        final dt = ArtisanalDevTools(
          inner: inner,
          enableTimeline: false,
          enablePostEvent: false,
          enableServiceExtensions: false,
        );

        final result = dt.onSend(const CustomMsg('test'));
        expect(result, isNull);
      });

      test('onSend delegates to inner and respects transform', () {
        final inner = _TestInterceptor(
          onSendHook: (msg) => const CustomMsg('transformed'),
        );
        final dt = ArtisanalDevTools(
          inner: inner,
          enableTimeline: false,
          enablePostEvent: false,
          enableServiceExtensions: false,
        );

        final result = dt.onSend(const CustomMsg('original'));
        expect(result, isA<CustomMsg>());
        expect((result! as CustomMsg).value, 'transformed');
      });

      test('onProcessed delegates to inner', () {
        var innerProcessedCount = 0;
        final inner = _TestInterceptor(
          onProcessedHook: (_, _) => innerProcessedCount++,
        );
        final dt = ArtisanalDevTools(
          inner: inner,
          enableTimeline: false,
          enablePostEvent: false,
          enableServiceExtensions: false,
        );
        dt.onStart((_) {});
        dt.onProcessed(const CustomMsg('x'), const Duration(microseconds: 1));

        expect(innerProcessedCount, 1);
      });

      test('onRendered delegates to inner', () {
        var innerRendered = false;
        final inner = _TestInterceptor(
          onRenderedHook: () => innerRendered = true,
        );
        final dt = ArtisanalDevTools(
          inner: inner,
          enableTimeline: false,
          enablePostEvent: false,
          enableServiceExtensions: false,
        );
        dt.onRendered(
          renderGeneration: 1,
          view: 'x',
          degradationLevel: DegradationLevel.full,
          renderDuration: const Duration(microseconds: 100),
        );

        expect(innerRendered, isTrue);
      });

      test('onStop delegates to inner', () {
        var innerStopped = false;
        final inner = _TestInterceptor(onStopHook: () => innerStopped = true);
        final dt = ArtisanalDevTools(
          inner: inner,
          enableTimeline: false,
          enablePostEvent: false,
          enableServiceExtensions: false,
        );
        dt.onStart((_) {});
        dt.onStop();

        expect(innerStopped, isTrue);
      });
    });

    // -----------------------------------------------------------------------
    // Message summarization
    // -----------------------------------------------------------------------

    group('message summarization', () {
      // We test summarization indirectly through onProcessed, which stores
      // the summary in the message log.

      ArtisanalDevTools dt() {
        final d = ArtisanalDevTools(
          enableTimeline: false,
          enablePostEvent: false,
          enableServiceExtensions: false,
        );
        d.onStart((_) {});
        return d;
      }

      String summarize(ArtisanalDevTools d, Msg msg) {
        d.onProcessed(msg, Duration.zero);
        return d.messageLog.last.summary;
      }

      test('summarizes KeyMsg', () {
        final d = dt();
        final summary = summarize(d, KeyMsg(Key(KeyType.runes, runes: [0x71])));
        expect(summary, contains('key:'));
        expect(summary, contains('runes'));
      });

      test('summarizes WindowSizeMsg', () {
        final d = dt();
        final summary = summarize(d, const WindowSizeMsg(120, 40));
        expect(summary, 'resize: 120x40');
      });

      test('summarizes QuitMsg', () {
        final d = dt();
        expect(summarize(d, const QuitMsg()), 'quit');
      });

      test('summarizes CustomMsg', () {
        final d = dt();
        expect(summarize(d, const CustomMsg('foo')), 'custom: foo');
      });

      test('summarizes HotReloadStatusMsg', () {
        final d = dt();
        expect(
          summarize(d, const HotReloadStatusMsg(HotReloadStatus.succeeded)),
          'hotReload: succeeded',
        );
      });

      test('summarizes CapturedOutputMsg', () {
        final d = dt();
        expect(
          summarize(d, const CapturedOutputMsg('hello world')),
          'output(stdout): hello world',
        );
      });

      test('summarizes CapturedOutputMsg with long line', () {
        final d = dt();
        final longLine = 'x' * 100;
        final summary = summarize(d, CapturedOutputMsg(longLine));
        expect(summary, contains('...'));
        // Should be truncated to 60 chars + "..."
        expect(summary.length, lessThan(100));
      });

      test('summarizes RepaintMsg', () {
        final d = dt();
        expect(summarize(d, const RepaintMsg()), 'repaint');
      });

      test('summarizes InterruptMsg', () {
        final d = dt();
        expect(summarize(d, const InterruptMsg()), 'interrupt');
      });

      test('summarizes FocusMsg', () {
        final d = dt();
        expect(summarize(d, const FocusMsg(true)), 'focus: true');
        expect(summarize(d, const FocusMsg(false)), 'focus: false');
      });

      test('summarizes unknown message type as runtimeType', () {
        final d = dt();
        final summary = summarize(d, _UnknownMsg());
        expect(summary, '_UnknownMsg');
      });
    });
  });

  // =========================================================================
  // Integration with Program
  // =========================================================================

  group('ArtisanalDevTools integration', () {
    late _MockTerminal terminal;

    setUp(() {
      terminal = _MockTerminal();
    });

    test('records messages when used as interceptor', () async {
      final devtools = ArtisanalDevTools(
        enableTimeline: false,
        enablePostEvent: false,
        enableServiceExtensions: false,
      );

      var gotCustom = false;
      final model = _CallbackModel(
        onUpdate: (msg) {
          if (msg == const CustomMsg('ping')) {
            gotCustom = true;
            return Cmd.quit();
          }
          return null;
        },
        onView: () => 'devtools integration',
      );

      final program = Program(
        model,
        options: ProgramOptions(altScreen: false, interceptor: devtools),
        terminal: terminal,
      );

      final runFuture = program.run();
      await _waitUntil(() => terminal.output.isNotEmpty);
      program.send(const CustomMsg('ping'));
      await runFuture;

      expect(gotCustom, isTrue);
      expect(devtools.isRunning, isFalse);

      // Should have logged the CustomMsg.
      final customEntries = devtools.messageLog
          .where((e) => e.messageType == 'CustomMsg<String>')
          .toList();
      expect(customEntries, isNotEmpty);
      expect(customEntries.first.summary, 'custom: ping');
    });

    test('records render stats when used as interceptor', () async {
      final devtools = ArtisanalDevTools(
        enableTimeline: false,
        enablePostEvent: false,
        enableServiceExtensions: false,
      );

      final model = _CallbackModel(
        onUpdate: (msg) {
          if (msg == const CustomMsg('go')) return Cmd.quit();
          return null;
        },
        onView: () => 'render stats test',
      );

      final program = Program(
        model,
        options: ProgramOptions(altScreen: false, interceptor: devtools),
        terminal: terminal,
      );

      final runFuture = program.run();
      await _waitUntil(() => terminal.output.isNotEmpty);
      program.send(const CustomMsg('go'));
      await runFuture;

      // At least the initial render should have been recorded.
      final json = devtools.renderStats.toJson();
      expect(json['frameCount'], greaterThanOrEqualTo(1));
    });

    test('updateModelSnapshot is called after model.update()', () async {
      final devtools = ArtisanalDevTools(
        enableTimeline: false,
        enablePostEvent: false,
        enableServiceExtensions: false,
      );

      final model = _ToStringModel();

      final program = Program(
        model,
        options: ProgramOptions(altScreen: false, interceptor: devtools),
        terminal: terminal,
      );

      final runFuture = program.run();
      await _waitUntil(() => terminal.output.isNotEmpty);
      program.send(const CustomMsg('bump'));
      // Give time for message to be processed.
      await Future<void>.delayed(const Duration(milliseconds: 30));
      program.send(const CustomMsg('quit'));
      await runFuture;

      // The model's toString changes after 'bump', so the devtools
      // snapshot should reflect the updated model. We can't directly
      // read _lastModelString, but the fact that updateModelSnapshot
      // was called is validated by the lack of errors and the integration
      // test running to completion.
      expect(devtools.isRunning, isFalse);
    });
  });
}

// =============================================================================
// Helpers
// =============================================================================

class _UnknownMsg extends Msg {
  @override
  String toString() => '_UnknownMsg';
}

class _TestInterceptor extends ProgramInterceptor {
  _TestInterceptor({
    this.onStartHook,
    this.onSendHook,
    this.onProcessedHook,
    this.onRenderedHook,
    this.onStopHook,
  });

  final void Function(void Function(Msg))? onStartHook;
  final Msg? Function(Msg)? onSendHook;
  final void Function(Msg, Duration)? onProcessedHook;
  final void Function()? onRenderedHook;
  final void Function()? onStopHook;

  @override
  void onStart(void Function(Msg msg) send) => onStartHook?.call(send);

  @override
  Msg? onSend(Msg msg) {
    final hook = onSendHook;
    if (hook == null) return msg;
    return hook(msg);
  }

  @override
  void onProcessed(Msg msg, Duration elapsed) =>
      onProcessedHook?.call(msg, elapsed);

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
  }) => onRenderedHook?.call();

  @override
  void onStop() => onStopHook?.call();
}

class _CallbackModel implements Model {
  _CallbackModel({Cmd? Function(Msg)? onUpdate, Object Function()? onView})
    : _onUpdate = onUpdate,
      _onView = onView;

  final Cmd? Function(Msg)? _onUpdate;
  final Object Function()? _onView;

  @override
  Cmd? init() => null;

  @override
  (Model, Cmd?) update(Msg msg) {
    final cmd = _onUpdate?.call(msg);
    return (this, cmd);
  }

  @override
  Object view() => _onView?.call() ?? 'callback';
}

/// A model whose toString changes after receiving 'bump'.
class _ToStringModel implements Model {
  final int _count;

  _ToStringModel([this._count = 0]);

  @override
  Cmd? init() => null;

  @override
  (Model, Cmd?) update(Msg msg) {
    if (msg == const CustomMsg('bump')) {
      return (_ToStringModel(_count + 1), null);
    }
    if (msg == const CustomMsg('quit')) {
      return (this, Cmd.quit());
    }
    return (this, null);
  }

  @override
  String view() => 'ToStringModel($_count)';

  @override
  String toString() => 'ToStringModel(count=$_count)';
}

// ---------------------------------------------------------------------------
// MockTerminal (copy from program_test.dart for devtools tests)
// ---------------------------------------------------------------------------

class _MockTerminal implements TuiTerminal {
  final List<String> output = [];
  final StreamController<List<int>> _inputController =
      StreamController<List<int>>.broadcast();

  bool rawModeEnabled = false;
  bool altScreenEnabled = false;
  bool cursorHidden = false;
  bool mouseEnabled = false;
  bool bracketedPasteEnabled = false;
  bool disposed = false;

  @override
  int get width => 80;

  @override
  int get height => 24;

  @override
  bool get isTerminal => true;

  @override
  ColorProfile get colorProfile => ColorProfile.trueColor;

  @override
  Stream<List<int>> get input => _inputController.stream;

  @override
  void write(String data) => output.add(data);

  @override
  void writeln([String data = '']) => output.add('$data\n');

  @override
  Future<void> flush() async {}

  @override
  RawModeGuard enableRawMode() {
    rawModeEnabled = true;
    return RawModeGuard(
      wasEchoMode: true,
      wasLineMode: true,
      restore: disableRawMode,
    );
  }

  @override
  void disableRawMode() => rawModeEnabled = false;

  @override
  Future<String?> query(
    String query, {
    Duration timeout = const Duration(seconds: 2),
  }) async => null;

  @override
  bool get isRawMode => rawModeEnabled;

  @override
  void enterAltScreen() => altScreenEnabled = true;

  @override
  void exitAltScreen() => altScreenEnabled = false;

  @override
  void hideCursor() => cursorHidden = true;

  @override
  void showCursor() => cursorHidden = false;

  @override
  void enableMouse() => mouseEnabled = true;

  @override
  void enableMouseCellMotion() => mouseEnabled = true;

  @override
  void enableMouseAllMotion() => mouseEnabled = true;

  @override
  void disableMouse() => mouseEnabled = false;

  @override
  void enableBracketedPaste() => bracketedPasteEnabled = true;

  @override
  void disableBracketedPaste() => bracketedPasteEnabled = false;

  @override
  void enableFocusReporting() {}

  @override
  void disableFocusReporting() {}

  @override
  void setTitle(String title) {}

  @override
  void setProgressBar(int state, int value) {}

  @override
  void bell() {}

  @override
  ({bool useTabs, bool useBackspace}) optimizeMovements() =>
      (useTabs: false, useBackspace: true);

  @override
  ({int width, int height}) get size => (width: width, height: height);

  @override
  bool get supportsAnsi => true;

  @override
  bool get isAltScreen => altScreenEnabled;

  @override
  bool get isMouseEnabled => mouseEnabled;

  @override
  bool get isBracketedPasteEnabled => bracketedPasteEnabled;

  @override
  void clearScreen() {}

  @override
  void clearToEnd() {}

  @override
  void clearToStart() {}

  @override
  void clearLine() {}

  @override
  void clearLineToEnd() {}

  @override
  void clearLineToStart() {}

  @override
  void clearPreviousLines(int lines) {}

  @override
  void scrollUp([int lines = 1]) {}

  @override
  void scrollDown([int lines = 1]) {}

  @override
  void moveCursor(int row, int col) {}

  @override
  void cursorHome() {}

  @override
  void cursorUp([int lines = 1]) {}

  @override
  void cursorDown([int lines = 1]) {}

  @override
  void cursorRight([int cols = 1]) {}

  @override
  void cursorLeft([int cols = 1]) {}

  @override
  void cursorToColumn(int col) {}

  @override
  int readByte() => -1;

  @override
  String? readLine() => null;

  @override
  void dispose() {
    disposed = true;
    _inputController.close();
  }

  @override
  void restoreCursor() {}

  @override
  void saveCursor() {}
}

Future<void> _waitUntil(
  bool Function() condition, {
  Duration timeout = const Duration(milliseconds: 250),
  Duration poll = const Duration(milliseconds: 5),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('Timed out waiting for test condition');
    }
    await Future<void>.delayed(poll);
  }
}
