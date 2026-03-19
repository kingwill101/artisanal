import 'dart:async';
import 'dart:io' as io;

import 'package:artisanal/src/style/color.dart';
import 'package:artisanal/src/tui/cmd.dart';
import 'package:artisanal/src/tui/key.dart' show Key, KeyType;
import 'package:artisanal/src/tui/model.dart';
import 'package:artisanal/src/tui/msg.dart';
import 'package:artisanal/src/tui/program.dart';
import 'package:artisanal/src/tui/terminal.dart';
import 'package:artisanal/src/tui/view.dart';
import 'package:artisanal/src/uv/uv.dart' show Cursor, CursorShape;
import 'package:test/test.dart';

// Import ExecResult for testing
export 'package:artisanal/src/tui/cmd.dart' show ExecResult, ExecProcessMsg;

// =============================================================================
// Test Models
// =============================================================================

/// A simple model that counts and can quit.
class CounterModel implements Model {
  const CounterModel([this.count = 0]);

  final int count;

  @override
  Cmd? init() => null;

  @override
  (Model, Cmd?) update(Msg msg) {
    if (msg is KeyMsg && msg.key.runes.isNotEmpty && msg.key.runes[0] == 0x71) {
      // 'q' to quit
      return (this, Cmd.quit());
    }
    if (msg is IncrementMsg) {
      return (CounterModel(count + 1), null);
    }
    return (this, null);
  }

  @override
  String view() => 'Count: $count';
}

/// Custom message for incrementing.
class IncrementMsg extends Msg {
  const IncrementMsg();
}

/// A model that throws during init.
class InitPanicModel implements Model {
  @override
  Cmd? init() {
    throw StateError('Init panic!');
  }

  @override
  (Model, Cmd?) update(Msg msg) => (this, null);

  @override
  String view() => 'Should not see this';
}

/// A model that throws during update.
class UpdatePanicModel implements Model {
  const UpdatePanicModel([this.updated = false]);

  final bool updated;

  @override
  Cmd? init() => null;

  @override
  (Model, Cmd?) update(Msg msg) {
    if (msg is TriggerPanicMsg) {
      throw ArgumentError('Update panic!');
    }
    return (const UpdatePanicModel(true), null);
  }

  @override
  String view() => 'Updated: $updated';
}

/// Message to trigger a panic.
class TriggerPanicMsg extends Msg {
  const TriggerPanicMsg();
}

/// A model that throws during view.
class ViewPanicModel implements Model {
  const ViewPanicModel([this.shouldPanic = false]);

  final bool shouldPanic;

  @override
  Cmd? init() => null;

  @override
  (Model, Cmd?) update(Msg msg) {
    if (msg is TriggerPanicMsg) {
      return (const ViewPanicModel(true), null);
    }
    return (this, null);
  }

  @override
  String view() {
    if (shouldPanic) {
      throw FormatException('View panic!');
    }
    return 'OK';
  }
}

/// A model that returns a command that throws.
class CommandPanicModel implements Model {
  @override
  Cmd? init() => Cmd.perform<void>(() async {
    throw UnsupportedError('Command panic!');
  }, onSuccess: (_) => const IncrementMsg());

  @override
  (Model, Cmd?) update(Msg msg) => (this, null);

  @override
  String view() => 'Command test';
}

/// A model that quits immediately after init.
class ImmediateQuitModel implements Model {
  @override
  Cmd? init() => Cmd.quit();

  @override
  (Model, Cmd?) update(Msg msg) => (this, null);

  @override
  String view() => 'Quitting...';
}

/// A model that returns a different model type from update() - for testing type checking.
class WrongTypeModel implements Model {
  const WrongTypeModel();

  @override
  Cmd? init() => null;

  @override
  (Model, Cmd?) update(Msg msg) {
    if (msg is TriggerPanicMsg) {
      // Returns a CounterModel instead of WrongTypeModel - this is the bug we're testing
      return (const CounterModel(), null);
    }
    return (this, null);
  }

  @override
  String view() => 'Wrong type test';
}

// =============================================================================
// Mock Terminal
// =============================================================================

/// A mock terminal for testing.
class MockTerminal implements TuiTerminal {
  final List<String> operations = [];
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

  void sendInput(List<int> bytes) {
    _inputController.add(bytes);
  }

  void sendError(Object error) {
    _inputController.addError(error);
  }

  void sendKey(int byte) {
    sendInput([byte]);
  }

  @override
  void write(String data) {
    output.add(data);
    operations.add('write: $data');
  }

  @override
  void writeln([String data = '']) {
    output.add('$data\n');
    operations.add('writeln: $data');
  }

  @override
  Future<void> flush() async {
    operations.add('flush');
  }

  @override
  RawModeGuard enableRawMode() {
    rawModeEnabled = true;
    operations.add('enableRawMode');
    return RawModeGuard(
      wasEchoMode: true,
      wasLineMode: true,
      restore: disableRawMode,
    );
  }

  @override
  void disableRawMode() {
    rawModeEnabled = false;
    operations.add('disableRawMode');
  }

  @override
  Future<String?> query(
    String query, {
    Duration timeout = const Duration(seconds: 2),
  }) async {
    operations.add('query: $query');
    return null;
  }

  @override
  bool get isRawMode => rawModeEnabled;

  @override
  void enterAltScreen() {
    altScreenEnabled = true;
    operations.add('enterAltScreen');
  }

  @override
  void exitAltScreen() {
    altScreenEnabled = false;
    operations.add('exitAltScreen');
  }

  @override
  void hideCursor() {
    cursorHidden = true;
    operations.add('hideCursor');
  }

  @override
  void showCursor() {
    cursorHidden = false;
    operations.add('showCursor');
  }

  @override
  void enableMouse() {
    mouseEnabled = true;
    operations.add('enableMouse');
  }

  @override
  void enableMouseCellMotion() {
    mouseEnabled = true;
    operations.add('enableMouseCellMotion');
  }

  @override
  void enableMouseAllMotion() {
    mouseEnabled = true;
    operations.add('enableMouseAllMotion');
  }

  @override
  void disableMouse() {
    mouseEnabled = false;
    operations.add('disableMouse');
  }

  @override
  void enableBracketedPaste() {
    bracketedPasteEnabled = true;
    operations.add('enableBracketedPaste');
  }

  @override
  void disableBracketedPaste() {
    bracketedPasteEnabled = false;
    operations.add('disableBracketedPaste');
  }

  @override
  void enableFocusReporting() {
    operations.add('enableFocusReporting');
  }

  @override
  void disableFocusReporting() {
    operations.add('disableFocusReporting');
  }

  @override
  void setTitle(String title) {
    operations.add('setTitle($title)');
  }

  @override
  void setProgressBar(int state, int value) {
    operations.add('setProgressBar($state, $value)');
  }

  @override
  void bell() {
    operations.add('bell');
  }

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
  void clearScreen() {
    operations.add('clearScreen');
  }

  @override
  void clearToEnd() {
    operations.add('clearToEnd');
  }

  @override
  void clearToStart() {
    operations.add('clearToStart');
  }

  @override
  void clearLine() {
    operations.add('clearLine');
  }

  @override
  void clearLineToEnd() {
    operations.add('clearLineToEnd');
  }

  @override
  void clearLineToStart() {
    operations.add('clearLineToStart');
  }

  @override
  void clearPreviousLines(int lines) {
    operations.add('clearPreviousLines($lines)');
  }

  @override
  void scrollUp([int lines = 1]) {
    operations.add('scrollUp($lines)');
  }

  @override
  void scrollDown([int lines = 1]) {
    operations.add('scrollDown($lines)');
  }

  @override
  void moveCursor(int row, int col) {
    operations.add('moveCursor($row, $col)');
  }

  @override
  void cursorHome() {
    operations.add('cursorHome');
  }

  @override
  void cursorUp([int lines = 1]) {
    operations.add('cursorUp($lines)');
  }

  @override
  void cursorDown([int lines = 1]) {
    operations.add('cursorDown($lines)');
  }

  @override
  void cursorRight([int cols = 1]) {
    operations.add('cursorRight($cols)');
  }

  @override
  void cursorLeft([int cols = 1]) {
    operations.add('cursorLeft($cols)');
  }

  @override
  void cursorToColumn(int col) {
    operations.add('cursorToColumn($col)');
  }

  @override
  int readByte() => -1;

  @override
  String? readLine() => null;

  @override
  void dispose() {
    disposed = true;
    operations.add('dispose');
    _inputController.close();
  }

  /// Checks if terminal was properly restored after a panic.
  bool get isProperlyRestored {
    return !rawModeEnabled &&
        !altScreenEnabled &&
        !cursorHidden &&
        !mouseEnabled &&
        !bracketedPasteEnabled;
  }

  /// Clears recorded operations (useful between test phases).
  void clearOperations() {
    operations.clear();
    output.clear();
  }

  @override
  void restoreCursor() {
    // TODO: implement restoreCursor
  }

  @override
  void saveCursor() {
    // TODO: implement saveCursor
  }
}

final class _NonTerminalMockTerminal extends MockTerminal {
  @override
  bool get isTerminal => false;
}

final class _ProbeAwareMockTerminal extends MockTerminal {
  _ProbeAwareMockTerminal({required this.onWrite});

  final void Function(String data, _ProbeAwareMockTerminal terminal) onWrite;

  @override
  void write(String data) {
    super.write(data);
    onWrite(data, this);
  }
}

final class _ProfileMockTerminal extends MockTerminal {
  _ProfileMockTerminal(this._profile);

  final ColorProfile _profile;

  @override
  ColorProfile get colorProfile => _profile;
}

// =============================================================================
// Tests
// =============================================================================

void main() {
  group('ProgramOptions', () {
    test('has sensible defaults', () {
      const options = ProgramOptions();
      expect(options.altScreen, isTrue);
      expect(options.mouse, isFalse);
      expect(options.fps, 60);
      expect(options.hideCursor, isTrue);
      expect(options.bracketedPaste, isFalse);
      expect(options.catchPanics, isTrue);
      expect(options.sendSuspendSignal, isTrue);
      expect(options.maxStackFrames, 10);
    });

    test('copyWith creates modified copy', () {
      const original = ProgramOptions();
      final modified = original.copyWith(
        altScreen: false,
        mouse: true,
        fps: 30,
        catchPanics: false,
        maxStackFrames: 5,
      );

      expect(modified.altScreen, isFalse);
      expect(modified.mouse, isTrue);
      expect(modified.fps, 30);
      expect(modified.catchPanics, isFalse);
      expect(modified.maxStackFrames, 5);

      // Original unchanged
      expect(original.altScreen, isTrue);
      expect(original.mouse, isFalse);
    });

    test('withoutCatchPanics disables panic catching', () {
      const options = ProgramOptions();
      final debug = options.withoutCatchPanics();

      expect(debug.catchPanics, isFalse);
      // Other options unchanged
      expect(debug.altScreen, options.altScreen);
      expect(debug.mouse, options.mouse);
    });

    test('withoutSuspendSignal skips OS-level suspend signaling', () {
      const options = ProgramOptions();
      final modified = options.withoutSuspendSignal();

      expect(modified.sendSuspendSignal, isFalse);
      expect(modified.sendInterrupt, options.sendInterrupt);
      expect(modified.altScreen, options.altScreen);
    });
  });

  group('ProgramHost', () {
    test('stdio host can prefer inputTTY', () {
      final binding = ProgramHost.stdio(
        inputTTY: true,
      ).resolve(const ProgramOptions());

      expect(binding.terminal, isNull);
      expect(binding.options.inputTTY, isTrue);
    });

    test('terminal host injects terminal and disables inputTTY override', () {
      final terminal = MockTerminal();
      final binding = ProgramHost.terminal(
        terminal,
      ).resolve(const ProgramOptions(inputTTY: true));

      expect(binding.terminal, same(terminal));
      expect(binding.options.inputTTY, isFalse);
    });

    test('split host creates a split terminal', () {
      final control = MockTerminal();
      final output = MockTerminal();
      final binding = ProgramHost.split(
        control: control,
        output: output,
      ).resolve(const ProgramOptions(inputTTY: true));

      expect(binding.terminal, isA<SplitTerminal>());
      expect(binding.options.inputTTY, isFalse);
    });

    test('custom host can override options and terminal', () {
      final terminal = MockTerminal();
      final binding = ProgramHost.custom((options) {
        return ProgramHostBinding(
          options: options.copyWith(startupTitle: 'Custom Host'),
          terminal: terminal,
        );
      }).resolve(const ProgramOptions());

      expect(binding.terminal, same(terminal));
      expect(binding.options.startupTitle, 'Custom Host');
    });

    test('backend host resolves to a BackendTerminal', () {
      final backend = EmbeddedTerminalBackend(output: (_) {});
      final binding = ProgramHost.backend(backend).resolve(
        const ProgramOptions(),
      );

      expect(binding.terminal, isA<BackendTerminal>());
      expect(binding.options.inputTTY, isFalse);
      binding.terminal?.dispose();
    });

    test('bridge host resolves to a BackendTerminal', () {
      final bridge = TerminalBridge();
      final binding = ProgramHost.bridge(bridge).resolve(
        const ProgramOptions(),
      );

      expect(binding.terminal, isA<BackendTerminal>());
      expect(binding.options.inputTTY, isFalse);
      bridge.dispose();
    });

    test('jsonChannel host resolves to a BackendTerminal', () async {
      final inbound = StreamController<Object?>();
      final binding = ProgramHost.jsonChannel(
        sendMessage: (_) {},
        inboundMessages: inbound.stream,
      ).resolve(const ProgramOptions());

      expect(binding.terminal, isA<BackendTerminal>());
      expect(binding.options.inputTTY, isFalse);

      binding.terminal?.dispose();
      await inbound.close();
    });

    test('webSocket host resolves to a BackendTerminal', () async {
      final server = await io.HttpServer.bind(
        io.InternetAddress.loopbackIPv4,
        0,
      );
      final acceptedSocket = server.transform(io.WebSocketTransformer()).first;
      final client = await io.WebSocket.connect(
        'ws://${server.address.address}:${server.port}',
      );
      final serverSocket = await acceptedSocket;

      final binding = ProgramHost.webSocket(serverSocket).resolve(
        const ProgramOptions(),
      );

      expect(binding.terminal, isA<BackendTerminal>());
      expect(binding.options.inputTTY, isFalse);

      binding.terminal?.dispose();
      await client.close();
      await server.close(force: true);
    });

    test('socket host resolves to a BackendTerminal', () async {
      final server = await io.ServerSocket.bind(
        io.InternetAddress.loopbackIPv4,
        0,
      );
      final accepted = server.first;
      final client = await io.Socket.connect(
        io.InternetAddress.loopbackIPv4,
        server.port,
      );
      final serverSocket = await accepted;

      final binding = ProgramHost.socket(serverSocket).resolve(
        const ProgramOptions(),
      );

      expect(binding.terminal, isA<BackendTerminal>());
      expect(binding.options.inputTTY, isFalse);

      binding.terminal?.dispose();
      await client.close();
      await server.close();
    });
  });

  group('Program helpers', () {
    test('runProgram can use a host terminal', () async {
      final terminal = MockTerminal();

      await runProgram(
        ImmediateQuitModel(),
        options: const ProgramOptions(altScreen: false),
        host: ProgramHost.terminal(terminal),
      );

      expect(terminal.operations, contains('enableRawMode'));
      expect(terminal.disposed, isTrue);
    });

    test('runProgramWithResult can use an explicit terminal', () async {
      final terminal = MockTerminal();

      final result = await runProgramWithResult<ImmediateQuitModel>(
        ImmediateQuitModel(),
        options: const ProgramOptions(altScreen: false),
        terminal: terminal,
      );

      expect(result, isA<ImmediateQuitModel>());
      expect(terminal.disposed, isTrue);
    });

    test('runProgramDebug keeps panic catching disabled after host resolution', () async {
      final terminal = MockTerminal();
      final host = ProgramHost.custom((options) {
        return ProgramHostBinding(
          options: options.copyWith(catchPanics: true),
          terminal: terminal,
        );
      });

      await expectLater(
        runProgramDebug(
          InitPanicModel(),
          options: const ProgramOptions(altScreen: false),
          host: host,
        ),
        throwsStateError,
      );
    });

    test('backend host forwards resize and shutdown events', () async {
      final backend = EmbeddedTerminalBackend(output: (_) {});
      final received = <Msg>[];

      final model = _CallbackModel(
        onUpdate: (msg) {
          received.add(msg);
          if (msg is InterruptMsg) {
            return Cmd.quit();
          }
          return null;
        },
      );

      final runFuture = runProgram(
        model,
        options: const ProgramOptions(altScreen: false, frameTick: false),
        host: ProgramHost.backend(backend),
      );

      await _waitUntil(() => backend.isRawMode);
      backend.notifySizeChanged((width: 120, height: 33));
      await _waitUntil(
        () => received.any(
          (msg) => msg is WindowSizeMsg && msg.width == 120 && msg.height == 33,
        ),
      );

      backend.requestShutdown();
      await runFuture;

      expect(received.whereType<InterruptMsg>(), isNotEmpty);
    });

    test('backend host ignores duplicate resize events with the same size', () async {
      final backend = EmbeddedTerminalBackend(output: (_) {});
      final received = <Msg>[];

      final model = _CallbackModel(
        onUpdate: (msg) {
          received.add(msg);
          if (msg is InterruptMsg) {
            return Cmd.quit();
          }
          return null;
        },
      );

      final runFuture = runProgram(
        model,
        options: const ProgramOptions(altScreen: false, frameTick: false),
        host: ProgramHost.backend(backend),
      );

      await _waitUntil(() => backend.isRawMode);
      backend.notifySizeChanged((width: 120, height: 33));
      await _waitUntil(
        () => received.whereType<WindowSizeMsg>().any(
          (msg) => msg.width == 120 && msg.height == 33,
        ),
      );

      backend.notifySizeChanged((width: 120, height: 33));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(
        received
            .whereType<WindowSizeMsg>()
            .where((msg) => msg.width == 120 && msg.height == 33),
        hasLength(1),
      );

      backend.requestShutdown();
      await runFuture;
    });

    test(
      'backend shutdown still quits when the model ignores InterruptMsg',
      () async {
        final backend = EmbeddedTerminalBackend(output: (_) {});
        final received = <Msg>[];

        final runFuture = runProgram(
          _CallbackModel(
            onUpdate: (msg) {
              received.add(msg);
              return null;
            },
          ),
          options: const ProgramOptions(altScreen: false, frameTick: false),
          host: ProgramHost.backend(backend),
        );

        await _waitUntil(() => backend.isRawMode);
        backend.requestShutdown();
        await runFuture.timeout(const Duration(seconds: 2));

        expect(received.whereType<InterruptMsg>(), isNotEmpty);
      },
    );

    test('bridge host can drive a program end to end', () async {
      final bridge = TerminalBridge();

      final runFuture = runProgram(
        const CounterModel(),
        options: const ProgramOptions(
          altScreen: false,
          frameTick: false,
          signalHandlers: false,
        ),
        host: ProgramHost.bridge(bridge),
      );

      await _waitUntil(() => bridge.bufferedOutput.contains('Count: 0'));
      bridge.addInputString('q');
      await runFuture;

      expect(bridge.bufferedOutput, contains('Count: 0'));
      bridge.dispose();
    });
  });

  group('Program basic lifecycle', () {
    late MockTerminal terminal;

    setUp(() {
      terminal = MockTerminal();
    });

    test('initializes terminal on run', () async {
      final model = _CallbackModel(
        onInit: () =>
            Cmd.tick(const Duration(milliseconds: 10), (_) => const QuitMsg()),
      );
      final program = Program(
        model,
        options: const ProgramOptions(altScreen: true, hideCursor: true),
        terminal: terminal,
      );

      await program.run();

      expect(terminal.operations, contains('enableRawMode'));
      expect(terminal.operations, contains('enterAltScreen'));
      expect(terminal.operations, contains('hideCursor'));
    });

    test('restores terminal on normal exit', () async {
      final program = Program(
        ImmediateQuitModel(),
        options: const ProgramOptions(altScreen: true, hideCursor: true),
        terminal: terminal,
      );

      await program.run();

      // Terminal should be restored
      expect(terminal.disposed, isTrue);
    });

    test('restores dynamic alt screen entered at runtime on exit', () async {
      final program = Program(
        _CallbackModel(
          onInit: () => Cmd.batch([
            Cmd.enterAltScreen(),
            Cmd.tick(const Duration(milliseconds: 1), (_) => const QuitMsg()),
          ]),
        ),
        options: const ProgramOptions(altScreen: false),
        terminal: terminal,
      );

      await program.run();

      expect(terminal.operations, contains('enterAltScreen'));
      expect(terminal.operations, contains('exitAltScreen'));
      expect(terminal.isAltScreen, isFalse);
    });

    test('sends initial WindowSizeMsg', () async {
      var receivedWindowSize = false;

      final model = _CallbackModel(
        onUpdate: (msg) {
          if (msg is WindowSizeMsg) {
            receivedWindowSize = true;
            expect(msg.width, 80);
            expect(msg.height, 24);
            return Cmd.quit();
          }
          return null;
        },
      );

      final program = Program(
        model,
        options: const ProgramOptions(altScreen: false),
        terminal: terminal,
      );

      await program.run();

      expect(receivedWindowSize, isTrue);
    });

    test('calls model.init on start', () async {
      var initCalled = false;

      final model = _CallbackModel(
        onInit: () {
          initCalled = true;
          return Cmd.quit();
        },
      );

      final program = Program(
        model,
        options: const ProgramOptions(altScreen: false),
        terminal: terminal,
      );

      await program.run();

      expect(initCalled, isTrue);
    });

    test('init command completion routes through send interceptor', () async {
      var sawIncrementInOnSend = false;
      final interceptor = _RecordingProgramInterceptor(
        onSendHook: (msg) {
          if (msg is IncrementMsg) {
            sawIncrementInOnSend = true;
          }
          return msg;
        },
      );

      final model = _CallbackModel(
        onInit: () => Cmd.message(const IncrementMsg()),
        onUpdate: (msg) {
          if (msg is IncrementMsg) return Cmd.quit();
          return null;
        },
      );

      final program = Program(
        model,
        options: ProgramOptions(altScreen: false, interceptor: interceptor),
        terminal: terminal,
      );

      await program.run();

      expect(sawIncrementInOnSend, isTrue);
    });

    test('immediate init messages land before the first rendered frame', () async {
      var initialized = false;
      final model = _CallbackModel(
        onInit: () => Cmd.message(const IncrementMsg()),
        onUpdate: (msg) {
          if (msg is IncrementMsg) {
            initialized = true;
            return Cmd.tick(
              const Duration(milliseconds: 10),
              (_) => const QuitMsg(),
            );
          }
          return null;
        },
        onView: () => initialized
            ? 'initialized first frame'
            : 'uninitialized first frame',
      );

      final program = Program(
        model,
        options: const ProgramOptions(
          altScreen: false,
          useUltravioletRenderer: false,
        ),
        terminal: terminal,
      );

      await program.run();

      final allOutput = terminal.output.join();
      expect(allOutput, contains('initialized first frame'));
      expect(allOutput, isNot(contains('uninitialized first frame')));
    });

    test('slow init commands do not block the first rendered frame', () async {
      var delayedQuitScheduled = false;
      final model = _CallbackModel(
        onInit: () => Cmd.delayed(const Duration(milliseconds: 40), () {
          delayedQuitScheduled = true;
          return const QuitMsg();
        }),
        onView: () => 'rendered before init completion',
      );

      final program = Program(
        model,
        options: const ProgramOptions(
          altScreen: false,
          useUltravioletRenderer: false,
        ),
        terminal: terminal,
      );

      final runFuture = program.run();

      await _waitUntil(
        () => terminal.output.join().contains('rendered before init completion'),
      );
      expect(delayedQuitScheduled, isFalse);
      expect(program.isRunning, isTrue);

      await runFuture;
      expect(delayedQuitScheduled, isTrue);
    });

    test('renders initial view', () async {
      final program = Program(
        const CounterModel(42),
        options: const ProgramOptions(
          altScreen: false,
          useUltravioletRenderer: false,
        ),
        terminal: terminal,
      );

      // Start program and let it render
      final runFuture = program.run();

      // Give it time to render
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Quit
      program.quit();
      await runFuture;

      // Check that view was rendered
      final allOutput = terminal.output.join();
      expect(allOutput, contains('Count: 42'));
    });

    test('init-triggered quit still renders the initialized first frame', () async {
      final program = Program(
        ImmediateQuitModel(),
        options: const ProgramOptions(
          altScreen: false,
          useUltravioletRenderer: false,
        ),
        terminal: terminal,
      );

      await program.run();

      final allOutput = terminal.output.join();
      expect(allOutput, contains('Quitting...'));
    });

    test(
      'init-triggered quit initializes and restores fullscreen renderer state',
      () async {
        final program = Program(
          ImmediateQuitModel(),
          options: const ProgramOptions(
            altScreen: true,
            useUltravioletRenderer: false,
          ),
          terminal: terminal,
        );

        await program.run();

        expect(terminal.operations, contains('enterAltScreen'));
        expect(terminal.operations, contains('exitAltScreen'));
        expect(terminal.isAltScreen, isFalse);
      },
    );

    test(
      'init-triggered quit initializes and restores ultraviolet fullscreen state',
      () async {
        final program = Program(
          ImmediateQuitModel(),
          options: const ProgramOptions(
            altScreen: true,
            useUltravioletRenderer: true,
            startupProbes: false,
          ),
          terminal: terminal,
        );

        await program.run();

        expect(terminal.operations, contains('enterAltScreen'));
        expect(terminal.operations, contains('exitAltScreen'));
        expect(terminal.isAltScreen, isFalse);
      },
    );

    test('send() injects messages', () async {
      final program = Program(
        const CounterModel(0),
        options: const ProgramOptions(altScreen: false),
        terminal: terminal,
      );

      final runFuture = program.run();

      // Give it time to start
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Send increment messages
      program.send(const IncrementMsg());
      program.send(const IncrementMsg());
      program.send(const IncrementMsg());

      // Give it time to process
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Check model was updated
      final currentModel = program.currentModel as CounterModel;
      expect(currentModel.count, 3);

      program.quit();
      await runFuture;
    });

    test('quit() triggers shutdown', () async {
      final program = Program(
        const CounterModel(),
        options: const ProgramOptions(altScreen: false),
        terminal: terminal,
      );

      final runFuture = program.run();

      await Future<void>.delayed(const Duration(milliseconds: 50));

      program.quit();

      // Should complete without hanging
      await runFuture.timeout(
        const Duration(seconds: 1),
        onTimeout: () => fail('Program did not quit'),
      );
    });

    test('throws if run() called while already running', () async {
      final program = Program(
        const CounterModel(),
        options: const ProgramOptions(altScreen: false),
        terminal: terminal,
      );

      final runFuture = program.run();

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(() => program.run(), throwsStateError);

      program.quit();
      await runFuture;
    });

    test(
      'does not print directly on input stream error (routes via PrintLineMsg)',
      () async {
        final model = _CallbackModel(
          onInit: () {
            return Cmd.perform<void>(() async {
              // Trigger a stream error after the program has started listening.
              terminal.sendError(StateError('boom'));

              // Give the microtask in Program.onError a chance to run before quit.
              await Future<void>.delayed(Duration.zero);
              await Future<void>.delayed(Duration.zero);
            }, onSuccess: (_) => const QuitMsg());
          },
        );

        final program = Program(
          model,
          options: const ProgramOptions(
            altScreen: false,
            disableRenderer: true,
            signalHandlers: false,
          ),
          terminal: terminal,
        );

        await program.run();

        expect(
          terminal.output.join(),
          contains('Input error: Bad state: boom'),
        );
      },
    );
  });

  group('Panic recovery', () {
    late MockTerminal terminal;

    setUp(() {
      terminal = MockTerminal();
    });

    test('restores terminal on init panic', () async {
      final program = Program(
        InitPanicModel(),
        options: const ProgramOptions(
          altScreen: true,
          hideCursor: true,
          catchPanics: true,
        ),
        terminal: terminal,
      );

      // Should not throw
      await program.run();

      // Terminal should be restored
      expect(terminal.disposed, isTrue);
    });

    test('restores terminal on command panic', () async {
      final program = Program(
        CommandPanicModel(),
        options: const ProgramOptions(
          altScreen: true,
          hideCursor: true,
          mouse: true,
          bracketedPaste: true,
          catchPanics: true,
        ),
        terminal: terminal,
      );

      await program.run();

      // Terminal should be restored
      expect(terminal.disposed, isTrue);
    });

    test('rethrows when catchPanics is false', () async {
      final program = Program(
        InitPanicModel(),
        options: const ProgramOptions(altScreen: false, catchPanics: false),
        terminal: terminal,
      );

      expect(() => program.run(), throwsStateError);
    });

    test('cleanup is robust against failures', () async {
      // Create a terminal that throws during some cleanup operations
      final fragileTerminal = _FragileTerminal();

      final program = Program(
        ImmediateQuitModel(),
        options: const ProgramOptions(
          altScreen: true,
          mouse: true,
          bracketedPaste: true,
          catchPanics: true,
        ),
        terminal: fragileTerminal,
      );

      // Should complete without throwing
      await program.run();

      // Dispose should still have been attempted
      expect(fragileTerminal.disposeAttempted, isTrue);
    });

    test('Model returning wrong type gives clear error', () async {
      final program = Program<WrongTypeModel>(
        const WrongTypeModel(),
        options: const ProgramOptions(altScreen: false, catchPanics: false),
        terminal: terminal,
      );

      // Start program
      final runFuture = program.run();

      // Give time for init to complete
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Send message that triggers the wrong type return
      // The error is thrown synchronously from send()
      expect(
        () => program.send(const TriggerPanicMsg()),
        throwsA(
          allOf(
            isA<StateError>(),
            predicate<StateError>(
              (e) =>
                  e.message.contains('Model.update()') &&
                  e.message.contains('CounterModel') &&
                  e.message.contains('WrongTypeModel'),
              'error message mentions Model.update(), actual type, and expected type',
            ),
          ),
        ),
      );

      // Clean up - kill the program since it didn't quit normally
      program.kill();
      await runFuture;
    });

    test('double cleanup does not cause errors', () async {
      // Use a terminal that tracks dispose calls
      var disposeCount = 0;
      final trackingTerminal = _DisposeTrackingTerminal(
        onDispose: () => disposeCount++,
      );

      final program = Program(
        ImmediateQuitModel(),
        options: const ProgramOptions(altScreen: false),
        terminal: trackingTerminal,
      );

      await program.run();

      // Dispose should have been called exactly once
      expect(disposeCount, 1, reason: 'Cleanup should only happen once');
    });

    test('cleanup errors are collected', () async {
      // Use the fragile terminal that throws during cleanup
      final fragileTerminal = _FragileTerminal();

      final program = Program(
        ImmediateQuitModel(),
        options: const ProgramOptions(altScreen: true, catchPanics: true),
        terminal: fragileTerminal,
      );

      // Should complete without throwing (errors are caught)
      await program.run();

      // Cleanup errors should be collected
      expect(
        program.cleanupErrors,
        isNotEmpty,
        reason: 'Cleanup errors should be collected',
      );
      expect(
        program.cleanupErrors.whereType<StateError>(),
        isNotEmpty,
        reason: 'Should contain the StateError from _FragileTerminal',
      );
    });
  });

  group('Terminal control messages', () {
    late MockTerminal terminal;

    setUp(() {
      terminal = MockTerminal();
    });

    test('SetWindowTitleMsg sets terminal title', () async {
      var windowSizeReceived = false;

      final model = _CallbackModel(
        onInit: () => Cmd.batch([
          Cmd.setWindowTitle('My App'),
          Cmd.tick(const Duration(milliseconds: 10), (_) => const QuitMsg()),
        ]),
        onUpdate: (msg) {
          if (msg is WindowSizeMsg) {
            windowSizeReceived = true;
            return null;
          }
          return null;
        },
      );

      final program = Program(
        model,
        options: const ProgramOptions(altScreen: false),
        terminal: terminal,
      );

      await program.run();

      expect(terminal.operations, contains('setTitle(My App)'));
      expect(windowSizeReceived, isTrue);
    });

    test('ClearScreenMsg clears screen', () async {
      final model = _CallbackModel(
        onInit: () => Cmd.batch([
          Cmd.clearScreen(),
          Cmd.tick(const Duration(milliseconds: 10), (_) => const QuitMsg()),
        ]),
        onUpdate: (msg) => null,
      );

      final program = Program(
        model,
        options: const ProgramOptions(altScreen: false),
        terminal: terminal,
      );

      await program.run();

      expect(terminal.operations, contains('clearScreen'));
    });

    test('WriteRawMsg writes directly to terminal', () async {
      final model = _CallbackModel(
        onInit: () => Cmd.batch([
          Cmd.writeRaw('XYZ'),
          Cmd.tick(const Duration(milliseconds: 10), (_) => const QuitMsg()),
        ]),
        onUpdate: (msg) => null,
      );

      final program = Program(
        model,
        options: const ProgramOptions(altScreen: false),
        terminal: terminal,
      );

      await program.run();

      expect(terminal.output.any((s) => s.contains('XYZ')), isTrue);
      expect(terminal.operations.any((s) => s.startsWith('write: ')), isTrue);
    });

    test('RequestWindowSizeMsg still delivers the current size explicitly', () async {
      var repeatedWindowSizeCount = 0;

      final model = _CallbackModel(
        onUpdate: (msg) {
          if (msg is WindowSizeMsg && msg.width == 80 && msg.height == 24) {
            repeatedWindowSizeCount++;
            if (repeatedWindowSizeCount == 1) {
              return Cmd.windowSize();
            }
            return Cmd.quit();
          }
          return null;
        },
      );

      final program = Program(
        model,
        options: const ProgramOptions(altScreen: false),
        terminal: terminal,
      );

      await program.run();

      expect(repeatedWindowSizeCount, 2);
    });

    test('window and cell size request commands write raw xterm queries', () async {
      final model = _CallbackModel(
        onInit: () => Cmd.batch([
          Cmd.requestPrimaryDeviceAttributesReport(),
          Cmd.requestSecondaryDeviceAttributesReport(),
          Cmd.requestTertiaryDeviceAttributesReport(),
          Cmd.requestTerminalVersionReport(),
          Cmd.requestTermcapStrings(['RGB', 'TN']),
          Cmd.requestCursorPositionReport(),
          Cmd.requestWindowPixelSizeReport(),
          Cmd.requestCellSizeReport(),
          Cmd.tick(const Duration(milliseconds: 10), (_) => const QuitMsg()),
        ]),
      );

      final program = Program(
        model,
        options: const ProgramOptions(altScreen: false),
        terminal: terminal,
      );

      await program.run();

      final output = terminal.output.join();
      expect(output, contains('\x1b[?c'));
      expect(output, contains('\x1b[>c'));
      expect(output, contains('\x1b[=c'));
      expect(output, contains('\x1b[>0q'));
      expect(output, contains('\x1bP+q524742;544e\x1b\\'));
      expect(output, contains('\x1b[6n'));
      expect(output, contains('\x1b[14t'));
      expect(output, contains('\x1b[16t'));
    });

    test('mode report request commands write raw DECRQM queries', () async {
      final model = _CallbackModel(
        onInit: () => Cmd.batch([
          Cmd.requestKeyboardEnhancementsReport(),
          Cmd.requestModeReport(2004),
          Cmd.requestModeReport(2, private: false),
          Cmd.tick(const Duration(milliseconds: 10), (_) => const QuitMsg()),
        ]),
      );

      final program = Program(
        model,
        options: const ProgramOptions(altScreen: false),
        terminal: terminal,
      );

      await program.run();

      final output = terminal.output.join();
      expect(output, contains('\x1b[?u'));
      expect(output, contains('\x1b[?2004\$p'));
      expect(output, contains('\x1b[2\$p'));
    });

    test('color scheme request commands write raw xterm queries', () async {
      final model = _CallbackModel(
        onInit: () => Cmd.batch([
          Cmd.requestColorSchemeReport(),
          Cmd.tick(const Duration(milliseconds: 10), (_) => const QuitMsg()),
        ]),
      );

      final program = Program(
        model,
        options: const ProgramOptions(altScreen: false),
        terminal: terminal,
      );

      await program.run();

      expect(terminal.output.join(), contains(Ansi.requestColorScheme));
    });

    test('color, palette, and clipboard request commands write raw OSC queries', () async {
      final model = _CallbackModel(
        onInit: () => Cmd.batch([
          Cmd.requestForegroundColor(),
          Cmd.requestBackgroundColor(),
          Cmd.requestCursorColor(),
          Cmd.requestColorPalette(42),
          Cmd.requestClipboard(),
          Cmd.tick(const Duration(milliseconds: 10), (_) => const QuitMsg()),
        ]),
      );

      final program = Program(
        model,
        options: const ProgramOptions(altScreen: false),
        terminal: terminal,
      );

      await program.run();

      final output = terminal.output.join();
      expect(output, contains(Ansi.requestForegroundColor));
      expect(output, contains(Ansi.requestBackgroundColor));
      expect(output, contains(Ansi.requestCursorColor));
      expect(output, contains('\x1b]4;42;?\x07'));
      expect(output, contains('\x1b]52;c;?\x07'));
    });

    test('non-terminal hosts suppress window and cell size report queries', () async {
      final terminal = _NonTerminalMockTerminal();
      final model = _CallbackModel(
        onInit: () => Cmd.batch([
          Cmd.requestPrimaryDeviceAttributesReport(),
          Cmd.requestSecondaryDeviceAttributesReport(),
          Cmd.requestTertiaryDeviceAttributesReport(),
          Cmd.requestTerminalVersionReport(),
          Cmd.requestTermcapStrings(['RGB', 'TN']),
          Cmd.requestCursorPositionReport(),
          Cmd.requestWindowPixelSizeReport(),
          Cmd.requestCellSizeReport(),
          Cmd.requestWindowSizeReport(),
          Cmd.tick(const Duration(milliseconds: 10), (_) => const QuitMsg()),
        ]),
      );

      final program = Program(
        model,
        options: const ProgramOptions(altScreen: false),
        terminal: terminal,
      );

      await program.run();

      final output = terminal.output.join();
      expect(output, isNot(contains('\x1b[?c')));
      expect(output, isNot(contains('\x1b[>c')));
      expect(output, isNot(contains('\x1b[=c')));
      expect(output, isNot(contains('\x1b[>0q')));
      expect(output, isNot(contains('\x1bP+q524742;544e\x1b\\')));
      expect(output, isNot(contains('\x1b[6n')));
      expect(output, isNot(contains('\x1b[14t')));
      expect(output, isNot(contains('\x1b[16t')));
      expect(output, isNot(contains('\x1b[18t')));
    });

    test('non-terminal hosts suppress mode report queries', () async {
      final terminal = _NonTerminalMockTerminal();
      final model = _CallbackModel(
        onInit: () => Cmd.batch([
          Cmd.requestKeyboardEnhancementsReport(),
          Cmd.requestModeReport(2004),
          Cmd.requestModeReport(1004),
          Cmd.requestColorSchemeReport(),
          Cmd.tick(const Duration(milliseconds: 10), (_) => const QuitMsg()),
        ]),
      );

      final program = Program(
        model,
        options: const ProgramOptions(altScreen: false),
        terminal: terminal,
      );

      await program.run();

      final output = terminal.output.join();
      expect(output, isNot(contains('\x1b[?u')));
      expect(output, isNot(contains('\x1b[?2004\$p')));
      expect(output, isNot(contains('\x1b[?1004\$p')));
      expect(output, isNot(contains(Ansi.requestColorScheme)));
    });

    test('non-terminal hosts suppress color, palette, and clipboard report queries', () async {
      final terminal = _NonTerminalMockTerminal();
      final model = _CallbackModel(
        onInit: () => Cmd.batch([
          Cmd.requestForegroundColor(),
          Cmd.requestBackgroundColor(),
          Cmd.requestCursorColor(),
          Cmd.requestColorPalette(42),
          Cmd.requestClipboard(),
          Cmd.tick(const Duration(milliseconds: 10), (_) => const QuitMsg()),
        ]),
      );

      final program = Program(
        model,
        options: const ProgramOptions(altScreen: false),
        terminal: terminal,
      );

      await program.run();

      final output = terminal.output.join();
      expect(output, isNot(contains(Ansi.requestForegroundColor)));
      expect(output, isNot(contains(Ansi.requestBackgroundColor)));
      expect(output, isNot(contains(Ansi.requestCursorColor)));
      expect(output, isNot(contains('\x1b]4;42;?\x07')));
      expect(output, isNot(contains('\x1b]52;c;?\x07')));
    });

    test('ShowCursorMsg and HideCursorMsg control cursor', () async {
      var phase = 0;

      final model = _CallbackModel(
        onInit: () => Cmd.hideCursor(),
        onUpdate: (msg) {
          if (msg is WindowSizeMsg) return null;
          phase++;
          if (phase == 1) return Cmd.showCursor();
          return Cmd.quit();
        },
      );

      final program = Program(
        model,
        options: const ProgramOptions(altScreen: false, hideCursor: false),
        terminal: terminal,
      );

      final runFuture = program.run();

      await Future<void>.delayed(const Duration(milliseconds: 50));
      program.send(const CustomMsg('trigger'));

      await Future<void>.delayed(const Duration(milliseconds: 50));
      program.send(const CustomMsg('trigger'));

      await runFuture;

      expect(terminal.operations, contains('hideCursor'));
      expect(terminal.operations, contains('showCursor'));
    });
  });

  group('Mouse and input modes', () {
    late MockTerminal terminal;

    setUp(() {
      terminal = MockTerminal();
    });

    test('enables mouse when option is set', () async {
      final program = Program(
        ImmediateQuitModel(),
        options: const ProgramOptions(altScreen: false, mouse: true),
        terminal: terminal,
      );

      await program.run();

      expect(terminal.operations, contains('enableMouseCellMotion'));
      expect(terminal.operations, contains('disableMouse'));
    });

    test('enables bracketed paste when option is set', () async {
      final program = Program(
        ImmediateQuitModel(),
        options: const ProgramOptions(altScreen: false, bracketedPaste: true),
        terminal: terminal,
      );

      await program.run();

      expect(terminal.operations, contains('enableBracketedPaste'));
      expect(terminal.operations, contains('disableBracketedPaste'));
    });

    test('delivers focus messages end to end (UV parser)', () async {
      final received = <FocusMsg>[];

      final program = Program(
        _CallbackModel(
          onUpdate: (msg) {
            if (msg is FocusMsg) {
              received.add(msg);
              if (received.length >= 2) return Cmd.quit();
            }
            return null;
          },
          onView: () => const View(content: 'focus', reportFocus: true),
        ),
        options: const ProgramOptions(
          altScreen: false,
          useUltravioletInputDecoder: true,
        ),
        terminal: terminal,
      );

      final runFuture = program.run();
      await _waitUntil(() => terminal.operations.contains('enableFocusReporting'));
      terminal.sendInput('\x1b[I'.codeUnits);
      terminal.sendInput('\x1b[O'.codeUnits);
      await runFuture;

      expect(received, [const FocusMsg(true), const FocusMsg(false)]);
    });

    test('delivers color scheme messages end to end (UV parser)', () async {
      final received = <ColorSchemeMsg>[];

      final program = Program(
        _CallbackModel(
          onUpdate: (msg) {
            if (msg is ColorSchemeMsg) {
              received.add(msg);
              if (received.length >= 2) return Cmd.quit();
            }
            return null;
          },
          onView: () => const View(content: 'color scheme'),
        ),
        options: const ProgramOptions(
          altScreen: false,
          useUltravioletInputDecoder: true,
        ),
        terminal: terminal,
      );

      final runFuture = program.run();
      await _waitUntil(() => terminal.output.join().contains('color scheme'));
      terminal.sendInput('\x1b[?997;1n\x1b[?997;2n'.codeUnits);
      await runFuture;

      expect(
        received,
        const [ColorSchemeMsg(dark: true), ColorSchemeMsg(dark: false)],
      );
    });

    test('delivers focus messages end to end (key parser)', () async {
      final received = <FocusMsg>[];

      final program = Program(
        _CallbackModel(
          onUpdate: (msg) {
            if (msg is FocusMsg) {
              received.add(msg);
              if (received.length >= 2) return Cmd.quit();
            }
            return null;
          },
          onView: () => const View(content: 'focus', reportFocus: true),
        ),
        options: const ProgramOptions(
          altScreen: false,
          useUltravioletInputDecoder: false,
        ),
        terminal: terminal,
      );

      final runFuture = program.run();
      await _waitUntil(() => terminal.operations.contains('enableFocusReporting'));
      terminal.sendInput('\x1b[I'.codeUnits);
      terminal.sendInput('\x1b[O'.codeUnits);
      await runFuture;

      expect(received, [const FocusMsg(true), const FocusMsg(false)]);
    });

    test('delivers bracketed paste messages end to end (UV parser)', () async {
      PasteMsg? received;

      final program = Program(
        _CallbackModel(
          onUpdate: (msg) {
            if (msg is PasteMsg) {
              received = msg;
              return Cmd.quit();
            }
            return null;
          },
          onView: () => const View(content: 'paste', bracketedPaste: true),
        ),
        options: const ProgramOptions(
          altScreen: false,
          useUltravioletInputDecoder: true,
        ),
        terminal: terminal,
      );

      final runFuture = program.run();
      await _waitUntil(() => terminal.operations.contains('enableBracketedPaste'));
      terminal.sendInput('\x1b[200~hello\nworld\x1b[201~'.codeUnits);
      await runFuture;

      expect(received, const PasteMsg('hello\nworld'));
    });

    test('delivers bracketed paste messages end to end (key parser)', () async {
      PasteMsg? received;

      final program = Program(
        _CallbackModel(
          onUpdate: (msg) {
            if (msg is PasteMsg) {
              received = msg;
              return Cmd.quit();
            }
            return null;
          },
          onView: () => const View(content: 'paste', bracketedPaste: true),
        ),
        options: const ProgramOptions(
          altScreen: false,
          useUltravioletInputDecoder: false,
        ),
        terminal: terminal,
      );

      final runFuture = program.run();
      await _waitUntil(() => terminal.operations.contains('enableBracketedPaste'));
      terminal.sendInput('\x1b[200~hello\nworld\x1b[201~'.codeUnits);
      await runFuture;

      expect(received, const PasteMsg('hello\nworld'));
    });

    test('delivers mouse press messages end to end (UV parser)', () async {
      MouseMsg? received;

      final program = Program(
        _CallbackModel(
          onUpdate: (msg) {
            if (msg is MouseMsg) {
              received = msg;
              return Cmd.quit();
            }
            return null;
          },
          onView: () => const View(content: 'mouse'),
        ),
        options: const ProgramOptions(
          altScreen: false,
          useUltravioletInputDecoder: true,
        ),
        terminal: terminal,
      );

      final runFuture = program.run();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      terminal.sendInput('\x1b[<0;5;3M'.codeUnits);
      await runFuture;

      expect(
        received,
        const MouseMsg(
          x: 4,
          y: 2,
          button: MouseButton.left,
          action: MouseAction.press,
        ),
      );
    });

    test('delivers mouse press messages end to end (key parser)', () async {
      MouseMsg? received;

      final program = Program(
        _CallbackModel(
          onUpdate: (msg) {
            if (msg is MouseMsg) {
              received = msg;
              return Cmd.quit();
            }
            return null;
          },
          onView: () => const View(content: 'mouse'),
        ),
        options: const ProgramOptions(
          altScreen: false,
          useUltravioletInputDecoder: false,
        ),
        terminal: terminal,
      );

      final runFuture = program.run();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      terminal.sendInput('\x1b[<0;5;3M'.codeUnits);
      await runFuture;

      expect(
        received,
        const MouseMsg(
          x: 4,
          y: 2,
          button: MouseButton.left,
          action: MouseAction.press,
        ),
      );
    });

    test('view onMouse hook executes commands for live mouse input', () async {
      var hookCalled = false;
      final received = <MouseMsg>[];

      final program = Program(
        _CallbackModel(
          onUpdate: (msg) {
            if (msg is MouseMsg) {
              received.add(msg);
              return Cmd.quit();
            }
            return null;
          },
          onView: () => View(
            content: 'mouse hook',
            onMouse: (msg) {
              hookCalled = true;
              return null;
            },
          ),
        ),
        options: const ProgramOptions(
          altScreen: false,
          useUltravioletInputDecoder: true,
        ),
        terminal: terminal,
      );

      final runFuture = program.run();
      await _waitUntil(() => terminal.output.join().contains('mouse hook'));
      terminal.sendInput('\x1b[<64;7;4M'.codeUnits);
      await runFuture;

      expect(hookCalled, isTrue);
      expect(
        received,
        [
          const MouseMsg(
            x: 6,
            y: 3,
            button: MouseButton.wheelUp,
            action: MouseAction.wheel,
          ),
        ],
      );
    });

    test('delivers window size messages from UV input reports', () async {
      WindowSizeMsg? received;

      final program = Program(
        _CallbackModel(
          onUpdate: (msg) {
            if (msg is WindowSizeMsg && msg.width == 120 && msg.height == 33) {
              received = msg;
              return Cmd.quit();
            }
            return null;
          },
          onView: () => const View(content: 'resize'),
        ),
        options: const ProgramOptions(
          altScreen: false,
          useUltravioletInputDecoder: true,
        ),
        terminal: terminal,
      );

      final runFuture = program.run();
      await _waitUntil(() => terminal.output.join().contains('resize'));
      terminal.sendInput('\x1b[8;33;120t'.codeUnits);
      await runFuture;

      expect(received, const WindowSizeMsg(120, 33));
    });

    test('deduplicates repeated window size messages from UV input reports', () async {
      var count = 0;

      final program = Program(
        _CallbackModel(
          onUpdate: (msg) {
            if (msg is WindowSizeMsg && msg.width == 120 && msg.height == 33) {
              count++;
              return Cmd.tick(
                const Duration(milliseconds: 10),
                (_) => const QuitMsg(),
              );
            }
            return null;
          },
          onView: () => const View(content: 'duplicate resize'),
        ),
        options: const ProgramOptions(
          altScreen: false,
          useUltravioletInputDecoder: true,
        ),
        terminal: terminal,
      );

      final runFuture = program.run();
      await _waitUntil(() => terminal.output.join().contains('duplicate resize'));
      terminal.sendInput('\x1b[8;33;120t\x1b[8;33;120t'.codeUnits);
      await runFuture;

      expect(count, 1);
    });

    test('delivers window size messages from UV in-band size reports', () async {
      WindowSizeMsg? received;

      final program = Program(
        _CallbackModel(
          onUpdate: (msg) {
            if (msg is WindowSizeMsg && msg.width == 120 && msg.height == 33) {
              received = msg;
              return Cmd.quit();
            }
            return null;
          },
          onView: () => const View(content: 'in-band resize'),
        ),
        options: const ProgramOptions(
          altScreen: false,
          useUltravioletInputDecoder: true,
        ),
        terminal: terminal,
      );

      final runFuture = program.run();
      await _waitUntil(() => terminal.output.join().contains('in-band resize'));
      terminal.sendInput('\x1b[48;33;120;660;2400t'.codeUnits);
      await runFuture;

      expect(received, const WindowSizeMsg(120, 33));
    });

    test('delivers cursor position messages from UV reports', () async {
      CursorPositionMsg? received;

      final program = Program(
        _CallbackModel(
          onUpdate: (msg) {
            if (msg is CursorPositionMsg && msg.x == 33 && msg.y == 11) {
              received = msg;
              return Cmd.quit();
            }
            return null;
          },
          onView: () => const View(content: 'cursor position'),
        ),
        options: const ProgramOptions(
          altScreen: false,
          useUltravioletInputDecoder: true,
        ),
        terminal: terminal,
      );

      final runFuture = program.run();
      await _waitUntil(
        () => terminal.output.join().contains('cursor position'),
      );
      terminal.sendInput('\x1b[12;34R'.codeUnits);
      await runFuture;

      expect(received, const CursorPositionMsg(33, 11));
    });

    test('delivers window pixel size messages from UV reports', () async {
      WindowPixelSizeMsg? received;

      final program = Program(
        _CallbackModel(
          onUpdate: (msg) {
            if (msg is WindowPixelSizeMsg &&
                msg.width == 2400 &&
                msg.height == 660) {
              received = msg;
              return Cmd.quit();
            }
            return null;
          },
          onView: () => const View(content: 'pixel resize'),
        ),
        options: const ProgramOptions(
          altScreen: false,
          useUltravioletInputDecoder: true,
        ),
        terminal: terminal,
      );

      final runFuture = program.run();
      await _waitUntil(() => terminal.output.join().contains('pixel resize'));
      terminal.sendInput('\x1b[4;660;2400t'.codeUnits);
      await runFuture;

      expect(received, const WindowPixelSizeMsg(2400, 660));
    });

    test('delivers cell size messages from UV reports', () async {
      CellSizeMsg? received;

      final program = Program(
        _CallbackModel(
          onUpdate: (msg) {
            if (msg is CellSizeMsg && msg.width == 7 && msg.height == 13) {
              received = msg;
              return Cmd.quit();
            }
            return null;
          },
          onView: () => const View(content: 'cell size'),
        ),
        options: const ProgramOptions(
          altScreen: false,
          useUltravioletInputDecoder: true,
        ),
        terminal: terminal,
      );

      final runFuture = program.run();
      await _waitUntil(() => terminal.output.join().contains('cell size'));
      terminal.sendInput('\x1b[6;13;7t'.codeUnits);
      await runFuture;

      expect(received, const CellSizeMsg(7, 13));
    });

    test('delivers mode report messages from UV reports', () async {
      ModeReportMsg? received;

      final program = Program(
        _CallbackModel(
          onUpdate: (msg) {
            if (msg is ModeReportMsg &&
                msg.mode == 2004 &&
                msg.value == ModeReportValue.set) {
              received = msg;
              return Cmd.quit();
            }
            return null;
          },
          onView: () => const View(content: 'mode report'),
        ),
        options: const ProgramOptions(
          altScreen: false,
          useUltravioletInputDecoder: true,
        ),
        terminal: terminal,
      );

      final runFuture = program.run();
      await _waitUntil(() => terminal.output.join().contains('mode report'));
      terminal.sendInput('\x1b[?2004;1\$y'.codeUnits);
      await runFuture;

      expect(
        received,
        const ModeReportMsg(mode: 2004, value: ModeReportValue.set),
      );
    });

    test('delivers primary device attributes messages from UV reports', () async {
      PrimaryDeviceAttributesMsg? received;

      final program = Program(
        _CallbackModel(
          onUpdate: (msg) {
            if (msg is PrimaryDeviceAttributesMsg &&
                msg.attrs.length == 3 &&
                msg.attrs[0] == 1 &&
                msg.attrs[1] == 2 &&
                msg.attrs[2] == 4) {
              received = msg;
              return Cmd.quit();
            }
            return null;
          },
          onView: () => const View(content: 'primary attrs'),
        ),
        options: const ProgramOptions(
          altScreen: false,
          useUltravioletInputDecoder: true,
        ),
        terminal: terminal,
      );

      final runFuture = program.run();
      await _waitUntil(() => terminal.output.join().contains('primary attrs'));
      terminal.sendInput('\x1b[?1;2;4c'.codeUnits);
      await runFuture;

      expect(received, const PrimaryDeviceAttributesMsg([1, 2, 4]));
    });

    test(
      'delivers secondary device attributes messages from UV reports',
      () async {
        SecondaryDeviceAttributesMsg? received;

        final program = Program(
          _CallbackModel(
            onUpdate: (msg) {
              if (msg is SecondaryDeviceAttributesMsg &&
                  msg.attrs.length == 3 &&
                  msg.attrs[0] == 1 &&
                  msg.attrs[1] == 2 &&
                  msg.attrs[2] == 3) {
                received = msg;
                return Cmd.quit();
              }
              return null;
            },
            onView: () => const View(content: 'secondary attrs'),
          ),
          options: const ProgramOptions(
            altScreen: false,
            useUltravioletInputDecoder: true,
          ),
          terminal: terminal,
        );

        final runFuture = program.run();
        await _waitUntil(
          () => terminal.output.join().contains('secondary attrs'),
        );
        terminal.sendInput('\x1b[>1;2;3c'.codeUnits);
        await runFuture;

        expect(received, const SecondaryDeviceAttributesMsg([1, 2, 3]));
      },
    );

    test('delivers tertiary device attributes messages from UV reports', () async {
      TertiaryDeviceAttributesMsg? received;

      final program = Program(
        _CallbackModel(
          onUpdate: (msg) {
            if (msg is TertiaryDeviceAttributesMsg && msg.value == 'Chrm') {
              received = msg;
              return Cmd.quit();
            }
            return null;
          },
          onView: () => const View(content: 'tertiary attrs'),
        ),
        options: const ProgramOptions(
          altScreen: false,
          useUltravioletInputDecoder: true,
        ),
        terminal: terminal,
      );

      final runFuture = program.run();
      await _waitUntil(
        () => terminal.output.join().contains('tertiary attrs'),
      );
      terminal.sendInput('\x1bP!|4368726d\x1b\\'.codeUnits);
      await runFuture;

      expect(received, const TertiaryDeviceAttributesMsg('Chrm'));
    });

    test('delivers terminal version messages from UV reports', () async {
      TerminalVersionMsg? received;

      final program = Program(
        _CallbackModel(
          onUpdate: (msg) {
            if (msg is TerminalVersionMsg && msg.version == 'Ultraviolet') {
              received = msg;
              return Cmd.quit();
            }
            return null;
          },
          onView: () => const View(content: 'terminal version'),
        ),
        options: const ProgramOptions(
          altScreen: false,
          useUltravioletInputDecoder: true,
        ),
        terminal: terminal,
      );

      final runFuture = program.run();
      await _waitUntil(
        () => terminal.output.join().contains('terminal version'),
      );
      terminal.sendInput('\x1bP>|Ultraviolet\x1b\\'.codeUnits);
      await runFuture;

      expect(received, const TerminalVersionMsg('Ultraviolet'));
    });

    test('delivers XTGETTCAP capability messages from UV reports', () async {
      CapabilityMsg? received;

      final program = Program(
        _CallbackModel(
          onUpdate: (msg) {
            if (msg is CapabilityMsg && msg.content == 'RGB;TN=xterm-256color') {
              received = msg;
              return Cmd.quit();
            }
            return null;
          },
          onView: () => const View(content: 'termcap capability'),
        ),
        options: const ProgramOptions(
          altScreen: false,
          useUltravioletInputDecoder: true,
        ),
        terminal: terminal,
      );

      final runFuture = program.run();
      await _waitUntil(
        () => terminal.output.join().contains('termcap capability'),
      );
      terminal.sendInput(
        '\x1bP1+r524742;544e=787465726d2d323536636f6c6f72\x1b\\'.codeUnits,
      );
      await runFuture;

      expect(received, const CapabilityMsg('RGB;TN=xterm-256color'));
    });

    test('delivers ModifyOtherKeys messages from UV reports', () async {
      ModifyOtherKeysMsg? received;

      final program = Program(
        _CallbackModel(
          onUpdate: (msg) {
            if (msg is ModifyOtherKeysMsg && msg.mode == 1) {
              received = msg;
              return Cmd.quit();
            }
            return null;
          },
          onView: () => const View(content: 'modify other keys'),
        ),
        options: const ProgramOptions(
          altScreen: false,
          useUltravioletInputDecoder: true,
        ),
        terminal: terminal,
      );

      final runFuture = program.run();
      await _waitUntil(
        () => terminal.output.join().contains('modify other keys'),
      );
      terminal.sendInput('\x1b[>4;1m'.codeUnits);
      await runFuture;

      expect(received, const ModifyOtherKeysMsg(1));
    });

    test('delivers keyboard enhancement messages from UV reports', () async {
      KeyboardEnhancementsMsg? received;

      final program = Program(
        _CallbackModel(
          onUpdate: (msg) {
            if (msg is KeyboardEnhancementsMsg && msg.reportEventTypes) {
              received = msg;
              return Cmd.quit();
            }
            return null;
          },
          onView: () => const View(content: 'keyboard enhancements'),
        ),
        options: const ProgramOptions(
          altScreen: false,
          useUltravioletInputDecoder: true,
        ),
        terminal: terminal,
      );

      final runFuture = program.run();
      await _waitUntil(
        () => terminal.output.join().contains('keyboard enhancements'),
      );
      terminal.sendInput('\x1b[?2u'.codeUnits);
      await runFuture;

      expect(
        received,
        const KeyboardEnhancementsMsg(reportEventTypes: true),
      );
    });

    test('delivers mouse motion messages end to end (UV parser)', () async {
      MouseMsg? received;

      final program = Program(
        _CallbackModel(
          onUpdate: (msg) {
            if (msg is MouseMsg && msg.action == MouseAction.motion) {
              received = msg;
              return Cmd.quit();
            }
            return null;
          },
          onView: () => const View(content: 'mouse motion'),
        ),
        options: const ProgramOptions(
          altScreen: false,
          useUltravioletInputDecoder: true,
        ),
        terminal: terminal,
      );

      final runFuture = program.run();
      await _waitUntil(() => terminal.output.join().contains('mouse motion'));
      terminal.sendInput('\x1b[<32;9;6M'.codeUnits);
      await runFuture;

      expect(
        received,
        const MouseMsg(
          x: 8,
          y: 5,
          button: MouseButton.left,
          action: MouseAction.motion,
        ),
      );
    });

    test('cleans up view-driven focus, paste, and all-motion mouse on exit', () async {
      final program = Program(
        _CallbackModel(
          onInit: () => Cmd.tick(
            const Duration(milliseconds: 10),
            (_) => const QuitMsg(),
          ),
          onView: () => const View(
            content: 'runtime hardening',
            reportFocus: true,
            bracketedPaste: true,
            mouseMode: MouseMode.allMotion,
          ),
        ),
        options: const ProgramOptions(altScreen: false),
        terminal: terminal,
      );

      await program.run();

      expect(terminal.operations, contains('enableFocusReporting'));
      expect(terminal.operations, contains('enableBracketedPaste'));
      expect(terminal.operations, contains('enableMouseAllMotion'));
      expect(terminal.operations, contains('disableFocusReporting'));
      expect(terminal.operations, contains('disableBracketedPaste'));
      expect(terminal.operations, contains('disableMouse'));
    });

    test('switches mouse modes by disabling before re-enabling', () async {
      var currentMode = MouseMode.cellMotion;
      final program = Program(
        _CallbackModel(
          onUpdate: (msg) {
            if (msg == const CustomMsg('switch')) {
              currentMode = MouseMode.allMotion;
              return Cmd.quit();
            }
            return null;
          },
          onView: () => View(content: 'mouse mode', mouseMode: currentMode),
        ),
        options: const ProgramOptions(altScreen: false),
        terminal: terminal,
      );

      final runFuture = program.run();
      await _waitUntil(
        () => terminal.operations.contains('enableMouseCellMotion'),
      );
      program.send(const CustomMsg('switch'));
      await runFuture;

      final enableCellIndex = terminal.operations.indexOf('enableMouseCellMotion');
      final disableIndex = terminal.operations.indexOf('disableMouse');
      final enableAllIndex = terminal.operations.indexOf('enableMouseAllMotion');

      expect(enableCellIndex, isNonNegative);
      expect(disableIndex, greaterThan(enableCellIndex));
      expect(enableAllIndex, greaterThan(disableIndex));
    });

    test(
      'collapses large multiline key burst into PasteTextMsg (UV parser)',
      () async {
        final receivedMessages = <Msg>[];
        final payload = List.generate(
          700,
          (i) => i % 37 == 0 ? '\n' : String.fromCharCode(0x61 + (i % 26)),
        ).join();

        final model = _CallbackModel(
          onInit: () => Cmd.tick(
            const Duration(milliseconds: 200),
            (_) => const QuitMsg(),
          ),
          onUpdate: (msg) {
            receivedMessages.add(msg);
            if (msg is PasteTextMsg) return Cmd.quit();
            return null;
          },
        );

        final program = Program(
          model,
          options: const ProgramOptions(
            altScreen: false,
            useUltravioletInputDecoder: true,
          ),
          terminal: terminal,
        );

        final runFuture = program.run();
        await Future<void>.delayed(const Duration(milliseconds: 40));
        terminal.sendInput(payload.codeUnits);
        await runFuture;

        final pasted = receivedMessages.whereType<PasteTextMsg>().toList();
        expect(pasted, hasLength(1));
        expect(pasted.single.content, payload);
      },
    );

    test(
      'collapses large multiline key burst into PasteTextMsg (key parser)',
      () async {
        final receivedMessages = <Msg>[];
        final payload = List.generate(
          700,
          (i) => i % 41 == 0 ? '\n' : String.fromCharCode(0x61 + (i % 26)),
        ).join();

        final model = _CallbackModel(
          onInit: () => Cmd.tick(
            const Duration(milliseconds: 200),
            (_) => const QuitMsg(),
          ),
          onUpdate: (msg) {
            receivedMessages.add(msg);
            if (msg is PasteTextMsg) return Cmd.quit();
            return null;
          },
        );

        final program = Program(
          model,
          options: const ProgramOptions(
            altScreen: false,
            useUltravioletInputDecoder: false,
          ),
          terminal: terminal,
        );

        final runFuture = program.run();
        await Future<void>.delayed(const Duration(milliseconds: 40));
        terminal.sendInput(payload.codeUnits);
        await runFuture;

        final pasted = receivedMessages.whereType<PasteTextMsg>().toList();
        expect(pasted, hasLength(1));
        expect(pasted.single.content, payload);
      },
    );

    test(
      'collapses medium multiline key burst to avoid Enter side effects (UV parser)',
      () async {
        final receivedMessages = <Msg>[];
        final payload = List.generate(
          220,
          (i) => i % 19 == 0 ? '\n' : String.fromCharCode(0x61 + (i % 26)),
        ).join();

        final model = _CallbackModel(
          onInit: () => Cmd.tick(
            const Duration(milliseconds: 200),
            (_) => const QuitMsg(),
          ),
          onUpdate: (msg) {
            receivedMessages.add(msg);
            if (msg is PasteTextMsg) return Cmd.quit();
            return null;
          },
        );

        final program = Program(
          model,
          options: const ProgramOptions(
            altScreen: false,
            useUltravioletInputDecoder: true,
          ),
          terminal: terminal,
        );

        final runFuture = program.run();
        await Future<void>.delayed(const Duration(milliseconds: 40));
        terminal.sendInput(payload.codeUnits);
        await runFuture;

        expect(receivedMessages.whereType<PasteTextMsg>(), hasLength(1));
      },
    );

    test(
      'collapses medium multiline key burst to avoid Enter side effects (key parser)',
      () async {
        final receivedMessages = <Msg>[];
        final payload = List.generate(
          220,
          (i) => i % 17 == 0 ? '\n' : String.fromCharCode(0x61 + (i % 26)),
        ).join();

        final model = _CallbackModel(
          onInit: () => Cmd.tick(
            const Duration(milliseconds: 200),
            (_) => const QuitMsg(),
          ),
          onUpdate: (msg) {
            receivedMessages.add(msg);
            if (msg is PasteTextMsg) return Cmd.quit();
            return null;
          },
        );

        final program = Program(
          model,
          options: const ProgramOptions(
            altScreen: false,
            useUltravioletInputDecoder: false,
          ),
          terminal: terminal,
        );

        final runFuture = program.run();
        await Future<void>.delayed(const Duration(milliseconds: 40));
        terminal.sendInput(payload.codeUnits);
        await runFuture;

        expect(receivedMessages.whereType<PasteTextMsg>(), hasLength(1));
      },
    );

    test('key send drops queued frame ticks in same drain cycle', () async {
      final received = <Msg>[];
      late Program program;
      var queued = false;

      final model = _CallbackModel(
        onUpdate: (msg) {
          received.add(msg);

          if (msg is CustomMsg && msg.value == 'start' && !queued) {
            queued = true;
            final now = DateTime.now();
            program.send(
              FrameTickMsg(
                time: now,
                frameNumber: 1,
                delta: const Duration(milliseconds: 16),
              ),
            );
            program.send(
              FrameTickMsg(
                time: now,
                frameNumber: 2,
                delta: const Duration(milliseconds: 16),
              ),
            );
            program.send(const KeyMsg(Key(KeyType.runes, runes: [0x6b])));
            program.send(
              FrameTickMsg(
                time: now,
                frameNumber: 3,
                delta: const Duration(milliseconds: 16),
              ),
            );
            return null;
          }

          if (msg is FrameTickMsg && msg.frameNumber == 3) {
            return Cmd.quit();
          }

          return null;
        },
      );

      program = Program(
        model,
        options: const ProgramOptions(altScreen: false, frameTick: false),
        terminal: terminal,
      );

      final runFuture = program.run();
      await Future<void>.delayed(const Duration(milliseconds: 40));
      program.send(const CustomMsg('start'));
      await runFuture;

      final frameNumbers = received
          .whereType<FrameTickMsg>()
          .map((m) => m.frameNumber)
          .toList(growable: false);
      expect(frameNumbers, [3]);
      expect(received.whereType<KeyMsg>(), hasLength(1));
      expect(received.whereType<KeyMsg>().single.key.char, equals('k'));
    });

    test('queued consecutive keys defer intermediate renders', () async {
      var viewCalls = 0;
      var keyUpdates = 0;
      late Program program;

      final model = _CallbackModel(
        onView: () {
          viewCalls++;
          return 'keys=$keyUpdates';
        },
        onUpdate: (msg) {
          if (msg is CustomMsg && msg.value == 'start') {
            program.send(const KeyMsg(Key(KeyType.runes, runes: [0x61])));
            program.send(const KeyMsg(Key(KeyType.runes, runes: [0x62])));
            program.send(const KeyMsg(Key(KeyType.runes, runes: [0x63])));
            return null;
          }

          if (msg is KeyMsg) {
            keyUpdates++;
            if (keyUpdates >= 3) return Cmd.quit();
          }
          return null;
        },
      );

      program = Program(
        model,
        options: const ProgramOptions(altScreen: false, frameTick: false),
        terminal: terminal,
      );

      final runFuture = program.run();
      await _waitUntil(() => viewCalls > 0);
      final before = viewCalls;
      program.send(const CustomMsg('start'));
      await runFuture;

      expect(keyUpdates, 3);
      // One render for the trigger message + one for the final key state.
      expect(viewCalls - before, 2);
    });

    test('drag motion events are not coalesced away', () async {
      final motionY = <int>[];
      late Program program;
      var queued = false;

      final model = _CallbackModel(
        onUpdate: (msg) {
          if (msg is CustomMsg && msg.value == 'start' && !queued) {
            queued = true;
            program.send(
              const MouseMsg(
                action: MouseAction.motion,
                button: MouseButton.left,
                x: 8,
                y: 5,
              ),
            );
            program.send(
              const MouseMsg(
                action: MouseAction.motion,
                button: MouseButton.left,
                x: 8,
                y: 7,
              ),
            );
            return null;
          }

          if (msg is MouseMsg &&
              msg.action == MouseAction.motion &&
              msg.button == MouseButton.left) {
            motionY.add(msg.y);
            if (motionY.length >= 2) return Cmd.quit();
          }
          return null;
        },
      );

      program = Program(
        model,
        options: const ProgramOptions(altScreen: false, frameTick: false),
        terminal: terminal,
      );

      final runFuture = program.run();
      await Future<void>.delayed(const Duration(milliseconds: 40));
      program.send(const CustomMsg('start'));
      await runFuture;

      expect(motionY, [5, 7]);
    });
  });

  group('External process execution', () {
    late MockTerminal terminal;

    setUp(() {
      terminal = MockTerminal();
    });

    test('ExecResult has correct properties', () {
      const result = ExecResult(exitCode: 0, stdout: 'hello', stderr: '');

      expect(result.exitCode, 0);
      expect(result.stdout, 'hello');
      expect(result.stderr, '');
      expect(result.success, isTrue);
    });

    test('ExecResult.success is false for non-zero exit code', () {
      const result = ExecResult(exitCode: 1, stdout: '', stderr: 'error');

      expect(result.success, isFalse);
    });

    test('Cmd.exec creates ExecProcessMsg', () async {
      Msg? capturedMsg;

      final cmd = Cmd.exec('echo', [
        'hello',
      ], onComplete: (result) => CustomMsg(result));

      // Execute the command to get the message
      capturedMsg = await cmd.execute();

      expect(capturedMsg, isA<ExecProcessMsg>());
      final execMsg = capturedMsg as ExecProcessMsg;
      expect(execMsg.executable, 'echo');
      expect(execMsg.arguments, ['hello']);
    });

    test('Cmd.exec with workingDirectory and environment', () async {
      final cmd = Cmd.exec(
        'pwd',
        [],
        onComplete: (result) => CustomMsg(result),
        workingDirectory: '/tmp',
        environment: {'FOO': 'bar'},
      );

      final msg = await cmd.execute() as ExecProcessMsg;
      expect(msg.workingDirectory, '/tmp');
      expect(msg.environment, {'FOO': 'bar'});
    });

    test('Cmd.openEditor uses EDITOR env var', () async {
      // This test verifies the command is created correctly
      final cmd = Cmd.openEditor(
        '/path/to/file.txt',
        onComplete: (result) => CustomMsg(result),
      );

      final msg = await cmd.execute() as ExecProcessMsg;
      expect(msg.arguments, ['/path/to/file.txt']);
      // The executable depends on environment, so we just check it's set
      expect(msg.executable, isNotEmpty);
    });

    test('Cmd.openUrl creates platform-appropriate command', () async {
      final cmd = Cmd.openUrl(
        'https://example.com',
        onComplete: (result) => CustomMsg(result),
      );

      final msg = await cmd.execute() as ExecProcessMsg;
      // Command varies by platform
      expect(msg.executable, isNotEmpty);
    });

    test('ExecProcessMsg releases and restores terminal', () async {
      var execCompleted = false;
      ExecResult? receivedResult;

      final model = _CallbackModel(
        onInit: () => Cmd.exec(
          'echo',
          ['test output'],
          onComplete: (result) {
            execCompleted = true;
            receivedResult = result;
            return const QuitMsg();
          },
        ),
        onUpdate: (msg) => null,
      );

      final program = Program(
        model,
        options: const ProgramOptions(altScreen: false, mouse: false),
        terminal: terminal,
      );

      await program.run();

      // Verify terminal was released (disableRawMode called during exec)
      // and restored (enableRawMode called after exec)
      final disableIndex = terminal.operations.indexOf('disableRawMode');
      final enableIndices = <int>[];
      for (var i = 0; i < terminal.operations.length; i++) {
        if (terminal.operations[i] == 'enableRawMode') {
          enableIndices.add(i);
        }
      }

      expect(disableIndex, isNonNegative);
      expect(execCompleted, isTrue);
      expect(receivedResult, isNotNull);

      // Should have at least initial enableRawMode and one after exec restore
      expect(enableIndices, isNotEmpty);
    });

    test('ExecProcess pauses frame ticks while released and restarts them after restore', () async {
      final tempDir = await io.Directory.systemTemp.createTemp(
        'artisanal_exec_frame_ticks_',
      );
      addTearDown(() => tempDir.delete(recursive: true));

      final script = io.File('${tempDir.path}/delay.dart');
      await script.writeAsString('''
import 'dart:async';

Future<void> main() async {
  await Future<void>.delayed(const Duration(milliseconds: 120));
}
''');

      late Program program;
      var execActive = false;
      var execDone = false;
      var ticksBeforeExec = 0;
      var ticksDuringExec = 0;
      var ticksAfterExec = 0;

      final model = _FrameTickCallbackModel(
        onUpdate: (msg) {
          if (msg == const CustomMsg('start')) {
            execActive = true;
            return Cmd.exec(
              io.Platform.resolvedExecutable,
              [script.path],
              onComplete: (_) => const CustomMsg('exec-done'),
            );
          }

          if (msg == const CustomMsg('exec-done')) {
            execActive = false;
            execDone = true;
            return Cmd.tick(
              const Duration(milliseconds: 250),
              (_) => const QuitMsg(),
            );
          }

          if (msg is FrameTickMsg) {
            if (execActive) {
              ticksDuringExec++;
            } else if (execDone) {
              ticksAfterExec++;
              if (ticksAfterExec >= 1) return Cmd.quit();
            } else {
              ticksBeforeExec++;
            }
          }
          return null;
        },
        onView: () => 'frame ticks around exec',
      );

      program = Program(
        model,
        options: const ProgramOptions(
          altScreen: false,
          frameTick: true,
          fps: 60,
        ),
        terminal: terminal,
      );

      final runFuture = program.run();
      await _waitUntil(() => ticksBeforeExec > 0);
      program.send(const CustomMsg('start'));
      await runFuture;

      expect(ticksBeforeExec, greaterThan(0));
      expect(ticksDuringExec, 0);
      expect(ticksAfterExec, greaterThanOrEqualTo(1));
    });

    test('ExecProcess suppresses renders triggered during terminal release', () async {
      final tempDir = await io.Directory.systemTemp.createTemp(
        'artisanal_exec_render_release_',
      );
      addTearDown(() => tempDir.delete(recursive: true));

      final script = io.File('${tempDir.path}/delay.dart');
      await script.writeAsString('''
import 'dart:async';

Future<void> main() async {
  await Future<void>.delayed(const Duration(milliseconds: 120));
}
''');

      late Program program;
      var counter = 0;
      var outputCountAtRelease = -1;
      var outputCountDuringRelease = -1;

      final model = _CallbackModel(
        onUpdate: (msg) {
          if (msg == const CustomMsg('start')) {
            Timer(
              const Duration(milliseconds: 30),
              () => program.send(const CustomMsg('bump')),
            );
            Timer(
              const Duration(milliseconds: 60),
              () => outputCountDuringRelease = terminal.output.length,
            );
            return Cmd.exec(
              io.Platform.resolvedExecutable,
              [script.path],
              onComplete: (_) => const CustomMsg('exec-done'),
            );
          }

          if (msg == const CustomMsg('bump')) {
            counter++;
            return null;
          }

          if (msg == const CustomMsg('exec-done')) {
            return Cmd.tick(
              const Duration(milliseconds: 40),
              (_) => const QuitMsg(),
            );
          }

          return null;
        },
        onView: () => 'counter=$counter',
      );

      program = Program(
        model,
        options: const ProgramOptions(altScreen: false),
        terminal: terminal,
      );

      final runFuture = program.run();
      await _waitUntil(() => terminal.output.isNotEmpty);
      program.send(const CustomMsg('start'));
      await _waitUntil(() => terminal.operations.contains('disableRawMode'));
      outputCountAtRelease = terminal.output.length;
      await runFuture;

      expect(counter, 1);
      expect(outputCountDuringRelease, outputCountAtRelease);
      expect(terminal.output.length, greaterThan(outputCountAtRelease));
    });

    test('ExecProcess defers window title writes until terminal restore', () async {
      final tempDir = await io.Directory.systemTemp.createTemp(
        'artisanal_exec_title_release_',
      );
      addTearDown(() => tempDir.delete(recursive: true));

      final script = io.File('${tempDir.path}/delay.dart');
      await script.writeAsString('''
import 'dart:async';

Future<void> main() async {
  await Future<void>.delayed(const Duration(milliseconds: 120));
}
''');

      late Program program;
      var execActive = false;

      final model = _CallbackModel(
        onUpdate: (msg) {
          if (msg == const CustomMsg('start')) {
            execActive = true;
            Timer(
              const Duration(milliseconds: 30),
              () => program.send(const CustomMsg('title')),
            );
            return Cmd.exec(
              io.Platform.resolvedExecutable,
              [script.path],
              onComplete: (_) => const CustomMsg('exec-done'),
            );
          }

          if (msg == const CustomMsg('title')) {
            return Cmd.setWindowTitle('Deferred Title');
          }

          if (msg == const CustomMsg('exec-done')) {
            execActive = false;
            return Cmd.tick(
              const Duration(milliseconds: 40),
              (_) => const QuitMsg(),
            );
          }

          return null;
        },
        onView: () => execActive ? 'exec active' : 'exec idle',
      );

      program = Program(
        model,
        options: const ProgramOptions(altScreen: false),
        terminal: terminal,
      );

      final runFuture = program.run();
      await Future<void>.delayed(const Duration(milliseconds: 40));
      program.send(const CustomMsg('start'));
      await runFuture;

      final disableIndex = terminal.operations.indexOf('disableRawMode');
      final restoreIndex = terminal.operations.lastIndexOf('enableRawMode');
      final deferredTitleIndex = terminal.operations.indexOf(
        'setTitle(Deferred Title)',
      );

      expect(disableIndex, isNonNegative);
      expect(restoreIndex, greaterThan(disableIndex));
      expect(deferredTitleIndex, greaterThan(restoreIndex));
    });

    test('ExecProcess defers stateful terminal control writes until restore', () async {
      final tempDir = await io.Directory.systemTemp.createTemp(
        'artisanal_exec_modes_release_',
      );
      addTearDown(() => tempDir.delete(recursive: true));

      final script = io.File('${tempDir.path}/delay.dart');
      await script.writeAsString('''
import 'dart:async';

Future<void> main() async {
  await Future<void>.delayed(const Duration(milliseconds: 120));
}
''');

      late Program program;
      var execActive = false;

      final model = _CallbackModel(
        onUpdate: (msg) {
          if (msg == const CustomMsg('start')) {
            execActive = true;
            Timer(
              const Duration(milliseconds: 30),
              () => program.send(const CustomMsg('modes')),
            );
            return Cmd.exec(
              io.Platform.resolvedExecutable,
              [script.path],
              onComplete: (_) => const CustomMsg('exec-done'),
            );
          }

          if (msg == const CustomMsg('modes')) {
            return Cmd.batch([
              Cmd.enableMouseAllMotion(),
              Cmd.enableBracketedPaste(),
              Cmd.enableReportFocus(),
              Cmd.enterAltScreen(),
            ]);
          }

          if (msg == const CustomMsg('exec-done')) {
            execActive = false;
            return Cmd.tick(
              const Duration(milliseconds: 40),
              (_) => const QuitMsg(),
            );
          }

          return null;
        },
        onView: () => execActive ? 'exec active' : 'exec idle',
      );

      program = Program(
        model,
        options: const ProgramOptions(altScreen: false),
        terminal: terminal,
      );

      final runFuture = program.run();
      await Future<void>.delayed(const Duration(milliseconds: 40));
      program.send(const CustomMsg('start'));
      await runFuture;

      final disableIndex = terminal.operations.indexOf('disableRawMode');
      final restoreIndex = terminal.operations.lastIndexOf('enableRawMode');
      final mouseIndex = terminal.operations.indexOf('enableMouseAllMotion');
      final pasteIndex = terminal.operations.indexOf('enableBracketedPaste');
      final focusIndex = terminal.operations.indexOf('enableFocusReporting');
      final altScreenIndex = terminal.operations.indexOf('enterAltScreen');

      expect(disableIndex, isNonNegative);
      expect(restoreIndex, greaterThan(disableIndex));
      expect(mouseIndex, greaterThan(restoreIndex));
      expect(pasteIndex, greaterThan(restoreIndex));
      expect(focusIndex, greaterThan(restoreIndex));
      expect(altScreenIndex, greaterThan(restoreIndex));
    });

    test('kill during exec does not restore the terminal after process exit', () async {
      final tempDir = await io.Directory.systemTemp.createTemp(
        'artisanal_exec_kill_release_',
      );
      addTearDown(() => tempDir.delete(recursive: true));

      final script = io.File('${tempDir.path}/delay.dart');
      await script.writeAsString('''
import 'dart:async';

Future<void> main() async {
  await Future<void>.delayed(const Duration(milliseconds: 120));
}
''');

      late Program program;
      var completionDelivered = false;

      final model = _CallbackModel(
        onUpdate: (msg) {
          if (msg == const CustomMsg('start')) {
            Timer(const Duration(milliseconds: 30), program.kill);
            return Cmd.exec(
              io.Platform.resolvedExecutable,
              [script.path],
              onComplete: (_) {
                completionDelivered = true;
                return const CustomMsg('exec-done');
              },
            );
          }
          return null;
        },
        onView: () => 'kill during exec',
      );

      program = Program(
        model,
        options: const ProgramOptions(altScreen: false),
        terminal: terminal,
      );

      final runFuture = program.run();
      await Future<void>.delayed(const Duration(milliseconds: 40));
      program.send(const CustomMsg('start'));
      await runFuture;
      await Future<void>.delayed(const Duration(milliseconds: 180));

      expect(program.wasKilled, isTrue);
      expect(completionDelivered, isFalse);
      expect(
        terminal.operations.where((op) => op == 'enableRawMode').length,
        1,
      );
    });

    test('quit during exec does not restore the terminal after process exit', () async {
      final tempDir = await io.Directory.systemTemp.createTemp(
        'artisanal_exec_quit_release_',
      );
      addTearDown(() => tempDir.delete(recursive: true));

      final script = io.File('${tempDir.path}/delay.dart');
      await script.writeAsString('''
import 'dart:async';

Future<void> main() async {
  await Future<void>.delayed(const Duration(milliseconds: 120));
}
''');

      late Program program;
      var completionDelivered = false;

      final model = _CallbackModel(
        onUpdate: (msg) {
          if (msg == const CustomMsg('start')) {
            Timer(
              const Duration(milliseconds: 30),
              () => program.send(const QuitMsg()),
            );
            return Cmd.exec(
              io.Platform.resolvedExecutable,
              [script.path],
              onComplete: (_) {
                completionDelivered = true;
                return const CustomMsg('exec-done');
              },
            );
          }
          return null;
        },
        onView: () => 'quit during exec',
      );

      program = Program(
        model,
        options: const ProgramOptions(altScreen: false),
        terminal: terminal,
      );

      final runFuture = program.run();
      await Future<void>.delayed(const Duration(milliseconds: 40));
      program.send(const CustomMsg('start'));
      await runFuture;
      await Future<void>.delayed(const Duration(milliseconds: 180));

      expect(program.wasKilled, isFalse);
      expect(completionDelivered, isFalse);
      expect(
        terminal.operations.where((op) => op == 'enableRawMode').length,
        1,
      );
    });

    test('backend shutdown during exec does not restore the terminal after process exit', () async {
      final tempDir = await io.Directory.systemTemp.createTemp(
        'artisanal_exec_backend_shutdown_release_',
      );
      addTearDown(() => tempDir.delete(recursive: true));

      final script = io.File('${tempDir.path}/delay.dart');
      await script.writeAsString('''
import 'dart:async';

Future<void> main() async {
  await Future<void>.delayed(const Duration(milliseconds: 120));
}
''');

      final writes = <String>[];
      final backend = EmbeddedTerminalBackend(output: writes.add);
      final terminal = BackendTerminal(backend);

      late Program program;
      var completionDelivered = false;

      final model = _CallbackModel(
        onUpdate: (msg) {
          if (msg == const CustomMsg('start')) {
            Timer(const Duration(milliseconds: 30), backend.requestShutdown);
            return Cmd.exec(
              io.Platform.resolvedExecutable,
              [script.path],
              onComplete: (_) {
                completionDelivered = true;
                return const CustomMsg('exec-done');
              },
            );
          }
          return null;
        },
        onView: () => 'backend shutdown during exec',
      );

      program = Program(
        model,
        options: const ProgramOptions(altScreen: false),
        terminal: terminal,
      );

      final runFuture = program.run();
      await Future<void>.delayed(const Duration(milliseconds: 40));
      program.send(const CustomMsg('start'));
      await runFuture;
      await Future<void>.delayed(const Duration(milliseconds: 180));

      expect(completionDelivered, isFalse);
      expect(backend.isRawMode, isFalse);
    });

    test('terminal write control messages are suppressed while released', () async {
      final tempDir = await io.Directory.systemTemp.createTemp(
        'artisanal_exec_control_release_',
      );
      addTearDown(() => tempDir.delete(recursive: true));

      final script = io.File('${tempDir.path}/delay.dart');
      await script.writeAsString('''
import 'dart:async';

Future<void> main() async {
  await Future<void>.delayed(const Duration(milliseconds: 120));
}
''');

      late Program program;
      var outputCountAtRelease = -1;
      var outputCountDuringRelease = -1;

      final model = _CallbackModel(
        onUpdate: (msg) {
          if (msg == const CustomMsg('start')) {
            Timer(const Duration(milliseconds: 30), () {
              program.println('suppressed while released');
              program.forceRepaint();
              program.send(const WriteRawMsg('RAW-SHOULD-NOT-WRITE'));
            });
            Timer(
              const Duration(milliseconds: 60),
              () => outputCountDuringRelease = terminal.output.length,
            );
            return Cmd.exec(
              io.Platform.resolvedExecutable,
              [script.path],
              onComplete: (_) => const CustomMsg('exec-done'),
            );
          }

          if (msg == const CustomMsg('exec-done')) {
            return Cmd.tick(
              const Duration(milliseconds: 40),
              (_) => const QuitMsg(),
            );
          }

          return null;
        },
        onView: () => 'release control messages',
      );

      program = Program(
        model,
        options: const ProgramOptions(altScreen: false),
        terminal: terminal,
      );

      final runFuture = program.run();
      await Future<void>.delayed(const Duration(milliseconds: 40));
      program.send(const CustomMsg('start'));
      await _waitUntil(() => terminal.operations.contains('disableRawMode'));
      outputCountAtRelease = terminal.output.length;
      await runFuture;

      expect(outputCountDuringRelease, outputCountAtRelease);
      expect(terminal.output.join(), isNot(contains('suppressed while released')));
      expect(terminal.output.join(), isNot(contains('RAW-SHOULD-NOT-WRITE')));
    });

    test('ExecProcess restore reapplies identical view terminal metadata', () async {
      final view = View(
        content: 'sticky metadata',
        reportFocus: true,
        bracketedPaste: true,
        mouseMode: MouseMode.allMotion,
        keyboardEnhancements: const KeyboardEnhancements(reportEventTypes: true),
        backgroundColor: const BasicColor('#112233'),
        foregroundColor: const BasicColor('#eeddcc'),
        cursor: (Cursor.at(0, 0)
          ..shape = CursorShape.bar
          ..blink = false
          ..color = const BasicColor('#445566')),
      );

      final model = _CallbackModel(
        onUpdate: (msg) {
          if (msg == const CustomMsg('exec')) {
            return Cmd.exec(
              'echo',
              ['restored'],
              onComplete: (_) => const QuitMsg(),
            );
          }
          return null;
        },
        onView: () => view,
      );

      final program = Program(
        model,
        options: const ProgramOptions(altScreen: false),
        terminal: terminal,
      );

      final runFuture = program.run();
      await _waitUntil(
        () => terminal.operations.contains('enableFocusReporting'),
      );
      program.send(const CustomMsg('exec'));
      await runFuture;

      expect(
        terminal.operations.where((op) => op == 'enableFocusReporting').length,
        greaterThanOrEqualTo(2),
      );
      expect(
        terminal.operations.where((op) => op == 'enableBracketedPaste').length,
        greaterThanOrEqualTo(2),
      );
      expect(
        terminal.operations.where((op) => op == 'enableMouseAllMotion').length,
        greaterThanOrEqualTo(2),
      );

      final joinedOutput = terminal.output.join();
      expect(
        RegExp(RegExp.escape(Ansi.kittyKeyboard(
          Ansi.kittyDisambiguateEscapeCodes | Ansi.kittyReportEventTypes,
          mode: 1,
        ))).allMatches(joinedOutput).length,
        greaterThanOrEqualTo(2),
      );
      expect(
        RegExp(RegExp.escape(Ansi.requestKittyKeyboard)).allMatches(joinedOutput).length,
        greaterThanOrEqualTo(2),
      );
      expect(
        RegExp(r'\x1b]11;#112233\x07').allMatches(joinedOutput).length,
        greaterThanOrEqualTo(2),
      );
      expect(
        RegExp(r'\x1b]10;#eeddcc\x07').allMatches(joinedOutput).length,
        greaterThanOrEqualTo(2),
      );
      expect(
        RegExp(r'\x1b]12;#445566\x07').allMatches(joinedOutput).length,
        greaterThanOrEqualTo(2),
      );
      expect(
        RegExp(r'\x1b\[6 q').allMatches(joinedOutput).length,
        greaterThanOrEqualTo(2),
      );
      expect(joinedOutput, contains('\x1b]111\x07'));
      expect(joinedOutput, contains('\x1b]110\x07'));
      expect(joinedOutput, contains('\x1b]112\x07'));
      expect(joinedOutput, contains('\x1b[1 q'));
      expect(joinedOutput, contains(Ansi.resetKittyKeyboard));
    });

    test('ExecProcess restore reapplies fullscreen terminal state only once', () async {
      final model = _CallbackModel(
        onUpdate: (msg) {
          if (msg == const CustomMsg('exec')) {
            return Cmd.exec(
              'echo',
              ['restored'],
              onComplete: (_) => const QuitMsg(),
            );
          }
          return null;
        },
        onView: () => 'fullscreen restore',
      );

      final program = Program(
        model,
        options: const ProgramOptions(
          altScreen: true,
          hideCursor: true,
        ),
        terminal: terminal,
      );

      final runFuture = program.run();
      await _waitUntil(() => terminal.operations.contains('enterAltScreen'));
      program.send(const CustomMsg('exec'));
      await runFuture;

      expect(
        terminal.operations.where((op) => op == 'enterAltScreen').length,
        2,
      );
      expect(
        terminal.operations.where((op) => op == 'hideCursor').length,
        2,
      );
      expect(
        terminal.operations.where((op) => op == 'exitAltScreen').length,
        2,
      );
      expect(
        terminal.operations.where((op) => op == 'showCursor').length,
        2,
      );
    });

    test('ExecProcess restore reapplies explicit hide cursor override', () async {
      var restored = false;

      final model = _CallbackModel(
        onInit: () => Cmd.hideCursor(),
        onUpdate: (msg) {
          if (msg == const CustomMsg('exec')) {
            return Cmd.exec(
              'echo',
              ['restored'],
              onComplete: (_) => const CustomMsg('restored'),
            );
          }
          if (msg == const CustomMsg('restored')) {
            restored = true;
          }
          return null;
        },
        onView: () => restored ? 'restored' : 'running',
      );

      final program = Program(
        model,
        options: const ProgramOptions(
          altScreen: false,
          hideCursor: false,
        ),
        terminal: terminal,
      );

      final runFuture = program.run();
      await _waitUntil(() => terminal.output.join().contains('running'));
      program.send(const CustomMsg('exec'));
      await _waitUntil(() => restored);

      expect(terminal.cursorHidden, isTrue);

      program.quit();
      await runFuture;
    });

    test('ExecProcess restore reapplies explicit show cursor override', () async {
      var restored = false;

      final model = _CallbackModel(
        onInit: () => Cmd.showCursor(),
        onUpdate: (msg) {
          if (msg == const CustomMsg('exec')) {
            return Cmd.exec(
              'echo',
              ['restored'],
              onComplete: (_) => const CustomMsg('restored'),
            );
          }
          if (msg == const CustomMsg('restored')) {
            restored = true;
          }
          return null;
        },
        onView: () => restored ? 'restored' : 'running',
      );

      final program = Program(
        model,
        options: const ProgramOptions(
          altScreen: true,
          hideCursor: true,
        ),
        terminal: terminal,
      );

      final runFuture = program.run();
      await _waitUntil(() => terminal.operations.contains('enterAltScreen'));
      program.send(const CustomMsg('exec'));
      await _waitUntil(() => restored);

      expect(terminal.cursorHidden, isFalse);

      program.quit();
      await runFuture;
    });

    test('ExecProcess restore reapplies startup title when no view override exists', () async {
      final model = _CallbackModel(
        onUpdate: (msg) {
          if (msg == const CustomMsg('exec')) {
            return Cmd.exec(
              'echo',
              ['restored'],
              onComplete: (_) => const QuitMsg(),
            );
          }
          return null;
        },
        onView: () => 'plain view',
      );

      final program = Program(
        model,
        options: const ProgramOptions(
          altScreen: false,
          startupTitle: 'Base Title',
        ),
        terminal: terminal,
      );

      final runFuture = program.run();
      await _waitUntil(() => terminal.output.join().contains('\x1b]0;Base Title\x07'));
      program.send(const CustomMsg('exec'));
      await runFuture;

      expect(terminal.output.join(), contains('\x1b]0;Base Title\x07'));
      expect(
        terminal.operations.where((op) => op == 'setTitle(Base Title)').length,
        greaterThanOrEqualTo(1),
      );
    });
  });

  group('Suspend lifecycle', () {
    late MockTerminal terminal;

    setUp(() {
      terminal = MockTerminal();
    });

    test('SuspendMsg restore reapplies stateful terminal control writes', () async {
      var resumed = false;
      final view = View(
        content: 'sticky metadata',
        reportFocus: true,
        bracketedPaste: true,
        mouseMode: MouseMode.allMotion,
        altScreen: true,
      );

      final model = _CallbackModel(
        onUpdate: (msg) {
          if (msg is ResumeMsg) {
            resumed = true;
            return Cmd.tick(
              const Duration(milliseconds: 1),
              (_) => const QuitMsg(),
            );
          }
          return null;
        },
        onView: () => resumed ? 'resumed' : view,
      );

      final program = Program(
        model,
        options: const ProgramOptions(
          altScreen: false,
          sendSuspendSignal: false,
        ),
        terminal: terminal,
      );

      final runFuture = program.run();
      await _waitUntil(() => terminal.operations.contains('enableFocusReporting'));
      program.send(const SuspendMsg());
      await runFuture;

      final disableIndex = terminal.operations.indexOf('disableRawMode');
      final restoreIndex = terminal.operations.lastIndexOf('enableRawMode');

      expect(disableIndex, isNonNegative);
      expect(restoreIndex, greaterThan(disableIndex));
      expect(
        terminal.operations.where((op) => op == 'enableMouseAllMotion').length,
        2,
      );
      expect(
        terminal.operations.where((op) => op == 'enableBracketedPaste').length,
        2,
      );
      expect(
        terminal.operations.where((op) => op == 'enableFocusReporting').length,
        2,
      );
      expect(
        terminal.operations.where((op) => op == 'enterAltScreen').length,
        2,
      );
    });

    test('SuspendMsg restore reapplies fullscreen terminal state only once', () async {
      final model = _CallbackModel(
        onUpdate: (msg) {
          if (msg is ResumeMsg) {
            return Cmd.tick(
              const Duration(milliseconds: 1),
              (_) => const QuitMsg(),
            );
          }
          return null;
        },
        onView: () => 'suspend fullscreen restore',
      );

      final program = Program(
        model,
        options: const ProgramOptions(
          altScreen: true,
          hideCursor: true,
          sendSuspendSignal: false,
        ),
        terminal: terminal,
      );

      final runFuture = program.run();
      await _waitUntil(() => terminal.operations.contains('enterAltScreen'));
      program.send(const SuspendMsg());
      await runFuture;

      expect(
        terminal.operations.where((op) => op == 'enterAltScreen').length,
        2,
      );
      expect(
        terminal.operations.where((op) => op == 'hideCursor').length,
        2,
      );
      expect(
        terminal.operations.where((op) => op == 'exitAltScreen').length,
        2,
      );
      expect(
        terminal.operations.where((op) => op == 'showCursor').length,
        2,
      );
    });

    test('SuspendMsg restore reapplies startup title when no view override exists', () async {
      final model = _CallbackModel(
        onUpdate: (msg) {
          if (msg is ResumeMsg) {
            return Cmd.tick(
              const Duration(milliseconds: 1),
              (_) => const QuitMsg(),
            );
          }
          return null;
        },
        onView: () => 'plain view',
      );

      final program = Program(
        model,
        options: const ProgramOptions(
          altScreen: false,
          startupTitle: 'Base Title',
          sendSuspendSignal: false,
        ),
        terminal: terminal,
      );

      final runFuture = program.run();
      await _waitUntil(
        () => terminal.output.join().contains('\x1b]0;Base Title\x07'),
      );
      program.send(const SuspendMsg());
      await runFuture;

      expect(terminal.output.join(), contains('\x1b]0;Base Title\x07'));
      expect(
        terminal.operations.where((op) => op == 'setTitle(Base Title)').length,
        1,
      );
    });
  });

  group('View metadata', () {
    late MockTerminal terminal;

    setUp(() {
      terminal = MockTerminal();
    });

    test('falling back to plain text resets view-scoped terminal metadata', () async {
      var plainTextPhase = false;

      final model = _CallbackModel(
        onUpdate: (msg) {
          if (msg == const CustomMsg('clear')) {
            plainTextPhase = true;
            return Cmd.tick(
              const Duration(milliseconds: 1),
              (_) => const QuitMsg(),
            );
          }
          return null;
        },
        onView: () => plainTextPhase
            ? 'plain terminal view'
            : View(
                content: 'scoped metadata',
                reportFocus: true,
                bracketedPaste: true,
                mouseMode: MouseMode.allMotion,
                keyboardEnhancements: const KeyboardEnhancements(
                  reportEventTypes: true,
                ),
                backgroundColor: const BasicColor('#112233'),
                foregroundColor: const BasicColor('#eeddcc'),
                progressBar: const TerminalProgressBar(
                  state: TerminalProgressBarState.defaultState,
                  value: 42,
                ),
                cursor: (Cursor.at(0, 0)
                  ..shape = CursorShape.bar
                  ..blink = false
                  ..color = const BasicColor('#445566')),
              ),
      );

      final program = Program(
        model,
        options: const ProgramOptions(altScreen: false),
        terminal: terminal,
      );

      final runFuture = program.run();
      await _waitUntil(() => terminal.operations.contains('enableFocusReporting'));
      program.send(const CustomMsg('clear'));
      await runFuture;

      final joinedOutput = terminal.output.join();
      expect(terminal.operations, contains('enableFocusReporting'));
      expect(terminal.operations, contains('disableFocusReporting'));
      expect(terminal.operations, contains('enableBracketedPaste'));
      expect(terminal.operations, contains('disableBracketedPaste'));
      expect(terminal.operations, contains('enableMouseAllMotion'));
      expect(terminal.operations, contains('disableMouse'));
      expect(
        terminal.operations.where((op) => op == 'setProgressBar(1, 42)').length,
        1,
      );
      expect(
        terminal.operations.where((op) => op == 'setProgressBar(0, 0)').length,
        1,
      );
      expect(joinedOutput, contains(Ansi.resetKittyKeyboard));
      expect(
        RegExp(r'\x1b]11;#112233\x07').allMatches(joinedOutput).length,
        1,
      );
      expect(RegExp(r'\x1b]111\x07').allMatches(joinedOutput).length, 1);
      expect(
        RegExp(r'\x1b]10;#eeddcc\x07').allMatches(joinedOutput).length,
        1,
      );
      expect(RegExp(r'\x1b]110\x07').allMatches(joinedOutput).length, 1);
      expect(
        RegExp(r'\x1b]12;#445566\x07').allMatches(joinedOutput).length,
        1,
      );
      expect(RegExp(r'\x1b]112\x07').allMatches(joinedOutput).length, 1);
      expect(RegExp(r'\x1b\[6 q').allMatches(joinedOutput).length, 1);
      expect(RegExp(r'\x1b\[1 q').allMatches(joinedOutput).length, 1);
    });

    test('null view metadata fields reset previous terminal overrides', () async {
      var cleared = false;

      final model = _CallbackModel(
        onUpdate: (msg) {
          if (msg == const CustomMsg('clear')) {
            cleared = true;
            return Cmd.tick(
              const Duration(milliseconds: 1),
              (_) => const QuitMsg(),
            );
          }
          return null;
        },
        onView: () => cleared
            ? const View(content: 'metadata cleared')
            : View(
                content: 'metadata set',
                reportFocus: true,
                bracketedPaste: true,
                mouseMode: MouseMode.allMotion,
                keyboardEnhancements: const KeyboardEnhancements(
                  reportEventTypes: true,
                ),
                backgroundColor: const BasicColor('#223344'),
                foregroundColor: const BasicColor('#ddeeff'),
                progressBar: const TerminalProgressBar(
                  state: TerminalProgressBarState.defaultState,
                  value: 80,
                ),
                cursor: (Cursor.at(1, 1)
                  ..shape = CursorShape.underline
                  ..blink = false
                  ..color = const BasicColor('#556677')),
              ),
      );

      final program = Program(
        model,
        options: const ProgramOptions(altScreen: false),
        terminal: terminal,
      );

      final runFuture = program.run();
      await _waitUntil(() => terminal.operations.contains('enableFocusReporting'));
      program.send(const CustomMsg('clear'));
      await runFuture;

      final joinedOutput = terminal.output.join();
      expect(terminal.operations, contains('disableFocusReporting'));
      expect(terminal.operations, contains('disableBracketedPaste'));
      expect(terminal.operations, contains('disableMouse'));
      expect(
        terminal.operations.where((op) => op == 'setProgressBar(0, 0)').length,
        1,
      );
      expect(joinedOutput, contains(Ansi.resetKittyKeyboard));
      expect(RegExp(r'\x1b]111\x07').allMatches(joinedOutput).length, 1);
      expect(RegExp(r'\x1b]110\x07').allMatches(joinedOutput).length, 1);
      expect(RegExp(r'\x1b]112\x07').allMatches(joinedOutput).length, 1);
      expect(RegExp(r'\x1b\[4 q').allMatches(joinedOutput).length, 1);
      expect(RegExp(r'\x1b\[1 q').allMatches(joinedOutput).length, 1);
    });

    test('window title falls back to startup title when override clears', () async {
      var cleared = false;

      final model = _CallbackModel(
        onUpdate: (msg) {
          if (msg == const CustomMsg('clear')) {
            cleared = true;
            return Cmd.tick(
              const Duration(milliseconds: 1),
              (_) => const QuitMsg(),
            );
          }
          return null;
        },
        onView: () => cleared
            ? const View(content: 'title cleared')
            : const View(content: 'title set', windowTitle: 'Scoped Title'),
      );

      final program = Program(
        model,
        options: const ProgramOptions(
          altScreen: false,
          startupTitle: 'Base Title',
        ),
        terminal: terminal,
      );

      final runFuture = program.run();
      await _waitUntil(() => terminal.operations.contains('setTitle(Scoped Title)'));
      program.send(const CustomMsg('clear'));
      await runFuture;

      final scopedIndex = terminal.operations.indexOf('setTitle(Scoped Title)');
      final fallbackIndex = terminal.operations.lastIndexOf('setTitle(Base Title)');

      expect(terminal.output.join(), contains('\x1b]0;Base Title\x07'));
      expect(scopedIndex, isNonNegative);
      expect(fallbackIndex, greaterThan(scopedIndex));
    });

    test('view alt-screen override resets when falling back to plain text', () async {
      var plainTextPhase = false;

      final model = _CallbackModel(
        onUpdate: (msg) {
          if (msg == const CustomMsg('clear')) {
            plainTextPhase = true;
            return Cmd.tick(
              const Duration(milliseconds: 1),
              (_) => const QuitMsg(),
            );
          }
          return null;
        },
        onView: () => plainTextPhase
            ? 'plain view'
            : const View(content: 'dynamic alt', altScreen: true),
      );

      final program = Program(
        model,
        options: const ProgramOptions(altScreen: false),
        terminal: terminal,
      );

      final runFuture = program.run();
      await _waitUntil(() => terminal.operations.contains('enterAltScreen'));
      program.send(const CustomMsg('clear'));
      await runFuture;

      expect(terminal.operations, contains('enterAltScreen'));
      expect(terminal.operations, contains('exitAltScreen'));
      expect(terminal.isAltScreen, isFalse);
    });

    test('null alt-screen view field resets previous alt-screen override', () async {
      var cleared = false;

      final model = _CallbackModel(
        onUpdate: (msg) {
          if (msg == const CustomMsg('clear')) {
            cleared = true;
            return Cmd.tick(
              const Duration(milliseconds: 1),
              (_) => const QuitMsg(),
            );
          }
          return null;
        },
        onView: () => cleared
            ? const View(content: 'metadata cleared')
            : const View(content: 'metadata set', altScreen: true),
      );

      final program = Program(
        model,
        options: const ProgramOptions(altScreen: false),
        terminal: terminal,
      );

      final runFuture = program.run();
      await _waitUntil(() => terminal.operations.contains('enterAltScreen'));
      program.send(const CustomMsg('clear'));
      await runFuture;

      expect(
        terminal.operations.where((op) => op == 'enterAltScreen').length,
        1,
      );
      expect(
        terminal.operations.where((op) => op == 'exitAltScreen').length,
        1,
      );
      expect(terminal.isAltScreen, isFalse);
    });
  });

  group('Message filtering', () {
    late MockTerminal terminal;

    setUp(() {
      terminal = MockTerminal();
    });

    test('filter can block messages', () async {
      final receivedMessages = <Msg>[];

      final model = _TrackingModel(
        onUpdate: (msg) {
          receivedMessages.add(msg);
          return null;
        },
      );

      final program = Program(
        model,
        options: ProgramOptions(
          altScreen: false,
          // Block all IncrementMsg
          filter: (m, msg) => msg is IncrementMsg ? null : msg,
        ),
        terminal: terminal,
      );

      final runFuture = program.run();

      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Send messages - IncrementMsg should be blocked
      program.send(const IncrementMsg());
      program.send(const CustomMsg('allowed'));
      program.send(const IncrementMsg());

      await Future<void>.delayed(const Duration(milliseconds: 50));

      program.quit();
      await runFuture;

      // Should have received WindowSizeMsg and CustomMsg, but not IncrementMsg
      expect(receivedMessages.whereType<IncrementMsg>(), isEmpty);
      expect(receivedMessages.whereType<CustomMsg>(), hasLength(1));
    });

    test('filter can transform messages', () async {
      final receivedMessages = <Msg>[];

      final model = _TrackingModel(
        onUpdate: (msg) {
          receivedMessages.add(msg);
          return null;
        },
      );

      final program = Program(
        model,
        options: ProgramOptions(
          altScreen: false,
          // Transform IncrementMsg to CustomMsg
          filter: (m, msg) =>
              msg is IncrementMsg ? const CustomMsg('transformed') : msg,
        ),
        terminal: terminal,
      );

      final runFuture = program.run();

      await Future<void>.delayed(const Duration(milliseconds: 50));

      program.send(const IncrementMsg());

      await Future<void>.delayed(const Duration(milliseconds: 50));

      program.quit();
      await runFuture;

      // Should have transformed message
      final customMessages = receivedMessages.whereType<CustomMsg>().toList();
      expect(customMessages, isNotEmpty);
      expect(customMessages.any((m) => m.value == 'transformed'), isTrue);
    });

    test('filter receives current model state', () async {
      Model? modelInFilter;

      final program = Program(
        const CounterModel(42),
        options: ProgramOptions(
          altScreen: false,
          filter: (model, msg) {
            modelInFilter = model;
            return msg;
          },
        ),
        terminal: terminal,
      );

      final runFuture = program.run();

      await Future<void>.delayed(const Duration(milliseconds: 50));

      program.send(const CustomMsg('test'));

      await Future<void>.delayed(const Duration(milliseconds: 50));

      program.quit();
      await runFuture;

      expect(modelInFilter, isA<CounterModel>());
      expect((modelInFilter as CounterModel).count, 42);
    });

    test('filter also applies to explicit window size requests', () async {
      final receivedMessages = <Msg>[];
      var filteredWindowSizeCount = 0;

      final model = _TrackingModel(
        onUpdate: (msg) {
          receivedMessages.add(msg);
          return null;
        },
      );

      final program = Program(
        model,
        options: ProgramOptions(
          altScreen: false,
          filter: (m, msg) {
            if (msg is WindowSizeMsg) {
              filteredWindowSizeCount++;
              return null;
            }
            return msg;
          },
        ),
        terminal: terminal,
      );

      final runFuture = program.run();

      await Future<void>.delayed(const Duration(milliseconds: 20));
      program.send(const CustomMsg('test'));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      program.send(const RequestWindowSizeMsg());
      await Future<void>.delayed(const Duration(milliseconds: 20));

      program.quit();
      await runFuture;

      expect(filteredWindowSizeCount, 2);
      expect(receivedMessages.whereType<WindowSizeMsg>(), isEmpty);
      expect(receivedMessages.whereType<CustomMsg>(), hasLength(1));
    });

    test('filter can prevent quit', () async {
      var quitAttempts = 0;
      var allowQuit = false;

      final program = Program(
        const CounterModel(),
        options: ProgramOptions(
          altScreen: false,
          filter: (model, msg) {
            if (msg is QuitMsg) {
              quitAttempts++;
              if (!allowQuit) {
                return null; // Block quit
              }
            }
            return msg;
          },
        ),
        terminal: terminal,
      );

      final runFuture = program.run();

      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Try to quit - should be blocked
      program.send(const QuitMsg());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(quitAttempts, 1);
      expect(program.isRunning, isTrue);

      // Allow quit
      allowQuit = true;
      program.quit();

      await runFuture;

      expect(quitAttempts, 2);
    });

    test('withFilter creates options with filter', () {
      Msg? testFilter(Model m, Msg msg) => msg;

      final options = ProgramOptions().withFilter(testFilter);

      expect(options.filter, equals(testFilter));
      // Other options unchanged
      expect(options.altScreen, isTrue);
    });

    test('withoutFilter removes filter', () {
      Msg? testFilter(Model m, Msg msg) => msg;

      final options = ProgramOptions().withFilter(testFilter).withoutFilter();

      expect(options.filter, isNull);
    });
  });

  group('Program interception and replay', () {
    late MockTerminal terminal;

    setUp(() {
      terminal = MockTerminal();
    });

    test('replay script injects messages automatically', () async {
      final received = <String>[];

      final model = _CallbackModel(
        onUpdate: (msg) {
          if (msg is CustomMsg) {
            received.add(msg.value);
            if (msg.value == 'quit') return Cmd.quit();
          }
          return null;
        },
      );

      final replay = ProgramReplay.script([
        const ProgramReplayStep(
          after: Duration(milliseconds: 10),
          msg: CustomMsg('hello'),
        ),
        const ProgramReplayStep(
          after: Duration(milliseconds: 10),
          msg: CustomMsg('quit'),
        ),
      ]);

      final program = Program(
        model,
        options: ProgramOptions(altScreen: false, replay: replay),
        terminal: terminal,
      );

      await program.run();

      expect(received, containsAllInOrder(['hello', 'quit']));
    });

    test('interceptor can inject, transform, and drop messages', () async {
      final received = <Msg>[];
      final interceptor = _RecordingProgramInterceptor(
        onStartSend: (send) => send(const CustomMsg('boot')),
        onSendHook: (msg) {
          if (msg is IncrementMsg) return null;
          if (msg is CustomMsg && msg.value == 'raw') {
            return const CustomMsg('transformed');
          }
          return msg;
        },
      );

      final model = _CallbackModel(
        onUpdate: (msg) {
          received.add(msg);
          if (msg is CustomMsg && msg.value == 'quit') return Cmd.quit();
          return null;
        },
      );

      final program = Program(
        model,
        options: ProgramOptions(altScreen: false, interceptor: interceptor),
        terminal: terminal,
      );

      final runFuture = program.run();
      await _waitUntil(
        () => received.whereType<CustomMsg>().any((m) => m.value == 'boot'),
      );

      program.send(const IncrementMsg());
      program.send(const CustomMsg('raw'));
      program.send(const CustomMsg('quit'));
      await runFuture;

      expect(received.whereType<IncrementMsg>(), isEmpty);
      expect(
        received.whereType<CustomMsg>().any((m) => m.value == 'boot'),
        isTrue,
      );
      expect(
        received.whereType<CustomMsg>().any((m) => m.value == 'transformed'),
        isTrue,
      );
      expect(interceptor.stopped, isTrue);
      expect(interceptor.processedCount, greaterThan(0));
    });

    test(
      'blockInputWhileReplay drops terminal input while replay active',
      () async {
        final received = <Msg>[];

        final model = _CallbackModel(
          onUpdate: (msg) {
            received.add(msg);
            if (msg is CustomMsg && msg.value == 'quit') return Cmd.quit();
            return null;
          },
        );

        final replay = ProgramReplay.script([
          const ProgramReplayStep(
            after: Duration(milliseconds: 120),
            msg: CustomMsg('quit'),
          ),
        ]);

        final program = Program(
          model,
          options: ProgramOptions(
            altScreen: false,
            useUltravioletInputDecoder: false,
            replay: replay,
            blockInputWhileReplay: true,
          ),
          terminal: terminal,
        );

        final runFuture = program.run();
        await Future<void>.delayed(const Duration(milliseconds: 30));
        terminal.sendInput(const [0x61]); // 'a'
        await runFuture;

        expect(received.whereType<KeyMsg>(), isEmpty);
        expect(
          received.whereType<CustomMsg>().any((m) => m.value == 'quit'),
          isTrue,
        );
      },
    );
  });

  group('ProgramOptions new features', () {
    test('fps validates range with assert', () {
      // Test valid values work
      const validFps = ProgramOptions(fps: 60);
      expect(validFps.fps, 60);

      // Test edge cases
      const minFps = ProgramOptions(fps: 1);
      expect(minFps.fps, 1);

      const maxFps = ProgramOptions(fps: 120);
      expect(maxFps.fps, 120);

      // Invalid values throw AssertionError in debug mode
      // We can't easily test this without running in debug mode
      // but the assert is in place for development
    });

    test('signalHandlers defaults to true', () {
      const options = ProgramOptions();
      expect(options.signalHandlers, isTrue);
    });

    test('withoutSignalHandlers disables signal handlers', () {
      final options = ProgramOptions().withoutSignalHandlers();
      expect(options.signalHandlers, isFalse);
    });

    test('sendInterrupt defaults to true', () {
      const options = ProgramOptions();
      expect(options.sendInterrupt, isTrue);
    });

    test('withoutInterruptMsg disables interrupt messages', () {
      final options = ProgramOptions().withoutInterruptMsg();
      expect(options.sendInterrupt, isFalse);
    });

    test('startupTitle can be set', () {
      final options = ProgramOptions().withStartupTitle('Test App');
      expect(options.startupTitle, 'Test App');
    });

    test('startupProbes defaults to auto', () {
      const options = ProgramOptions();
      expect(options.startupProbes, isNull);
    });

    test('withStartupProbes sets explicit startup probe behavior', () {
      final enabled = ProgramOptions().withStartupProbes(true);
      final disabled = ProgramOptions().withStartupProbes(false);
      expect(enabled.startupProbes, isTrue);
      expect(disabled.startupProbes, isFalse);
    });

    test('custom input stream can be set', () {
      final stream = Stream<List<int>>.empty();
      final options = ProgramOptions().withInput(stream);
      expect(options.input, stream);
    });

    test('custom output function can be set', () {
      void customOutput(String s) {}
      final options = ProgramOptions().withOutput(customOutput);
      expect(options.output, customOutput);
    });

    test('withInterceptor sets interceptor', () {
      final interceptor = _RecordingProgramInterceptor();
      final options = ProgramOptions().withInterceptor(interceptor);
      expect(options.interceptor, same(interceptor));
    });

    test('withReplay sets replay script', () {
      final replay = ProgramReplay.script(const [
        ProgramReplayStep(after: Duration.zero, msg: CustomMsg('x')),
      ]);
      final options = ProgramOptions().withReplay(replay);
      expect(options.replay, same(replay));
    });

    test('withoutReplay clears replay', () {
      final replay = ProgramReplay.script(const [
        ProgramReplayStep(after: Duration.zero, msg: CustomMsg('x')),
      ]);
      final options = ProgramOptions(replay: replay).withoutReplay();
      expect(options.replay, isNull);
    });

    test('withoutInterceptor clears interceptor', () {
      final interceptor = _RecordingProgramInterceptor();
      final options = ProgramOptions(
        interceptor: interceptor,
      ).withoutInterceptor();
      expect(options.interceptor, isNull);
    });

    test('withReplayInputBlocking toggles replay input blocking', () {
      final options = ProgramOptions().withReplayInputBlocking(true);
      expect(options.blockInputWhileReplay, isTrue);
    });
  });

  group('InterruptMsg', () {
    test('InterruptMsg toString works', () {
      const msg = InterruptMsg();
      expect(msg.toString(), 'InterruptMsg()');
    });

    test('model can handle InterruptMsg', () async {
      final terminal = MockTerminal();
      var interruptReceived = false;

      final program = Program(
        _InterruptHandlerModel(onInterrupt: () => interruptReceived = true),
        options: const ProgramOptions(altScreen: false),
        terminal: terminal,
      );

      final runFuture = program.run();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Send interrupt message
      program.send(const InterruptMsg());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(interruptReceived, isTrue);

      // Quit the program
      program.quit();
      await runFuture;
    });
  });

  group('Program kill() method', () {
    late MockTerminal terminal;

    setUp(() {
      terminal = MockTerminal();
    });

    test('kill immediately stops the program', () async {
      final program = Program(
        CounterModel(),
        options: const ProgramOptions(altScreen: false),
        terminal: terminal,
      );

      final runFuture = program.run();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(program.isRunning, isTrue);

      program.kill();

      await runFuture;

      expect(program.isRunning, isFalse);
    });

    test('wasKilled is true after kill()', () async {
      final program = Program(
        CounterModel(),
        options: const ProgramOptions(altScreen: false),
        terminal: terminal,
      );

      final runFuture = program.run();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(program.wasKilled, isFalse);

      program.kill();

      await runFuture;

      expect(program.wasKilled, isTrue);
    });

    test('wasKilled is false after quit()', () async {
      final program = Program(
        CounterModel(),
        options: const ProgramOptions(altScreen: false),
        terminal: terminal,
      );

      final runFuture = program.run();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      program.quit();

      await runFuture;

      expect(program.wasKilled, isFalse);
    });
  });

  group('Program wait() method', () {
    late MockTerminal terminal;

    setUp(() {
      terminal = MockTerminal();
    });

    test('wait returns immediately when not running', () async {
      final program = Program(
        CounterModel(),
        options: const ProgramOptions(altScreen: false),
        terminal: terminal,
      );

      // Should not block when program is not running
      await program.wait();
    });

    test('wait completes when program exits', () async {
      final program = Program(
        CounterModel(),
        options: const ProgramOptions(altScreen: false),
        terminal: terminal,
      );

      final runFuture = program.run();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Start wait before quit
      final waitFuture = program.wait();

      // Quit
      program.quit();

      // Both should complete
      await Future.wait([runFuture, waitFuture]);

      expect(program.isRunning, isFalse);
    });
  });

  group('Program println() and printf()', () {
    late MockTerminal terminal;

    setUp(() {
      terminal = MockTerminal();
    });

    test('println does nothing in alt screen mode', () async {
      final program = Program(
        CounterModel(),
        options: ProgramOptions(altScreen: true),
        terminal: terminal,
      );

      final runFuture = program.run();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      terminal.clearOperations();
      program.println('test message');

      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Should not have printed the message directly
      expect(terminal.output.join(), isNot(contains('test message\n')));

      program.quit();
      await runFuture;
    });

    test('println works in inline mode', () async {
      final program = Program(
        CounterModel(),
        options: const ProgramOptions(altScreen: false),
        terminal: terminal,
      );

      final runFuture = program.run();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      terminal.clearOperations();
      program.println('test message');

      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Should have printed the message
      expect(terminal.output.join(), contains('test message'));

      program.quit();
      await runFuture;
    });

    test('printf formats arguments', () async {
      final program = Program(
        const CounterModel(),
        options: const ProgramOptions(
          altScreen: false,
          useUltravioletRenderer: false,
        ),
        terminal: terminal,
      );

      final runFuture = program.run();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      terminal.clearOperations();
      program.printf('Count: %d items', [42]);

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(terminal.output.join(), contains('Count: 42 items'));

      program.quit();
      await runFuture;
    });

    test('println does nothing when dynamic alt screen is active', () async {
      final program = Program(
        _CallbackModel(onInit: () => Cmd.enterAltScreen()),
        options: const ProgramOptions(altScreen: false),
        terminal: terminal,
      );

      final runFuture = program.run();
      await _waitUntil(() => terminal.operations.contains('enterAltScreen'));

      terminal.clearOperations();
      terminal.output.clear();
      program.println('test message');

      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(terminal.output.join(), isNot(contains('test message')));

      program.quit();
      await runFuture;
    });
  });

  group('RepaintMsg and Cmd.repaint()', () {
    test('RepaintMsg toString works', () {
      const msg = RepaintMsg();
      expect(msg.toString(), 'RepaintMsg()');
    });

    test('Cmd.repaint creates repaint command', () async {
      final cmd = Cmd.repaint();
      final msg = await cmd.execute();
      expect(msg, isA<RepaintRequestMsg>());
      expect((msg as RepaintRequestMsg).force, isTrue);
    });

    test('Cmd.repaint with force=false', () async {
      final cmd = Cmd.repaint(force: false);
      final msg = await cmd.execute();
      expect(msg, isA<RepaintRequestMsg>());
      expect((msg as RepaintRequestMsg).force, isFalse);
    });
  });

  group('Program forceRepaint()', () {
    late MockTerminal terminal;

    setUp(() {
      terminal = MockTerminal();
    });

    test('forceRepaint triggers re-render', () async {
      final program = Program(
        CounterModel(),
        options: const ProgramOptions(altScreen: false),
        terminal: terminal,
      );

      final runFuture = program.run();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final outputBefore = terminal.output.length;
      program.forceRepaint();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Should have more output after repaint
      expect(terminal.output.length, greaterThan(outputBefore));

      program.quit();
      await runFuture;
    });
  });

  group('Startup title', () {
    late MockTerminal terminal;

    setUp(() {
      terminal = MockTerminal();
    });

    test('startup title is set when provided', () async {
      final program = Program(
        ImmediateQuitModel(),
        options: const ProgramOptions(
          altScreen: false,
          startupTitle: 'My Test App',
        ),
        terminal: terminal,
      );

      await program.run();

      // Check that title escape sequence was written
      expect(terminal.output.join(), contains('\x1b]0;My Test App\x07'));
    });
  });

  group('Startup probes', () {
    test('initial color profile is delivered as a startup message', () async {
      final terminal = _ProfileMockTerminal(ColorProfile.ansi256);
      ColorProfileMsg? received;

      final model = _CallbackModel(
        onUpdate: (msg) {
          if (msg is ColorProfileMsg) {
            received = msg;
            return Cmd.quit();
          }
          return null;
        },
        onView: () => 'color profile startup',
      );

      final program = Program(
        model,
        options: const ProgramOptions(
          altScreen: false,
          hideCursor: false,
        ),
        terminal: terminal,
      );

      await program.run();

      expect(received, const ColorProfileMsg(ColorProfile.ansi256));
    });

    test('custom injected terminals skip auto startup probes by default', () async {
      final terminal = MockTerminal();
      final model = _CallbackModel(
        onInit: () => Cmd.tick(
          const Duration(milliseconds: 10),
          (_) => const QuitMsg(),
        ),
        onView: () => 'first frame without auto probes',
      );

      final program = Program(
        model,
        options: const ProgramOptions(
          altScreen: false,
          hideCursor: false,
          useUltravioletRenderer: true,
          useUltravioletInputDecoder: true,
        ),
        terminal: terminal,
      );

      await program.run();

      final joinedOutput = terminal.output.join();
      expect(joinedOutput, contains('first frame without auto probes'));
      expect(joinedOutput, isNot(contains(Ansi.requestBackgroundColor)));
      expect(joinedOutput, isNot(contains(Ansi.requestColorScheme)));
      expect(joinedOutput, isNot(contains(Ansi.requestSecondaryDeviceAttributes)));
      expect(joinedOutput, isNot(contains(Ansi.requestKittyKeyboard)));
    });

    test('startupProbes false disables startup probes for backend terminals', () async {
      final writes = <String>[];
      final backend = EmbeddedTerminalBackend(output: writes.add);
      final terminal = BackendTerminal(backend);
      final model = _CallbackModel(
        onInit: () => Cmd.tick(
          const Duration(milliseconds: 10),
          (_) => const QuitMsg(),
        ),
        onView: () => 'built-in backend without probes',
      );

      final program = Program(
        model,
        options: const ProgramOptions(
          altScreen: false,
          hideCursor: false,
          useUltravioletRenderer: true,
          useUltravioletInputDecoder: true,
          startupProbes: false,
        ),
        terminal: terminal,
      );

      await program.run();

      final joinedOutput = writes.join();
      expect(joinedOutput, contains('built-in backend without probes'));
      expect(joinedOutput, isNot(contains(Ansi.requestBackgroundColor)));
      expect(joinedOutput, isNot(contains(Ansi.requestColorScheme)));
      expect(joinedOutput, isNot(contains(Ansi.requestSecondaryDeviceAttributes)));
      expect(joinedOutput, isNot(contains(Ansi.requestKittyKeyboard)));
    });

    test('startup UV capability replies are delivered during initialization', () async {
      final terminal = _ProbeAwareMockTerminal(
        onWrite: (data, terminal) {
          if (data == Ansi.requestBackgroundColor) {
            scheduleMicrotask(() {
              terminal.sendInput('\x1b]11;rgb:1111/1111/1111\x07'.codeUnits);
            });
          }
          if (data == Ansi.requestSecondaryDeviceAttributes) {
            scheduleMicrotask(() {
              terminal.sendInput('\x1b[>1;2;3c'.codeUnits);
            });
          }
          if (data == Ansi.requestKittyKeyboard) {
            scheduleMicrotask(() {
              terminal.sendInput('\x1b[?2u'.codeUnits);
            });
          }
        },
      );

      SecondaryDeviceAttributesMsg? secondary;
      KeyboardEnhancementsMsg? keyboard;
      final model = _CallbackModel(
        onUpdate: (msg) {
          switch (msg) {
            case SecondaryDeviceAttributesMsg():
              secondary = msg;
            case KeyboardEnhancementsMsg():
              keyboard = msg;
            default:
              break;
          }
          if (secondary != null && keyboard != null) {
            return Cmd.tick(
              const Duration(milliseconds: 10),
              (_) => const QuitMsg(),
            );
          }
          return null;
        },
        onView: () => secondary != null && keyboard != null
            ? 'startup capabilities ready'
            : 'waiting for startup capabilities',
      );

      final program = Program(
        model,
        options: const ProgramOptions(
          altScreen: false,
          hideCursor: false,
          useUltravioletRenderer: true,
          useUltravioletInputDecoder: true,
          startupProbes: true,
        ),
        terminal: terminal,
      );

      await program.run();

      expect(secondary, const SecondaryDeviceAttributesMsg([1, 2, 3]));
      expect(
        keyboard,
        const KeyboardEnhancementsMsg(reportEventTypes: true),
      );
      expect(terminal.output.join(), contains('startup capabilities ready'));
    });

    test('background probe updates the first rendered frame before paint', () async {
      final terminal = _ProbeAwareMockTerminal(
        onWrite: (data, terminal) {
          if (data == Ansi.requestBackgroundColor) {
            scheduleMicrotask(() {
              terminal.sendInput('\x1b]11;rgb:ffff/ffff/ffff\x07'.codeUnits);
            });
          }
        },
      );

      var sawLightBackground = false;
      final model = _CallbackModel(
        onUpdate: (msg) {
          if (msg is BackgroundColorMsg) {
            sawLightBackground = true;
            return Cmd.tick(
              const Duration(milliseconds: 10),
              (_) => const QuitMsg(),
            );
          }
          return null;
        },
        onView: () => sawLightBackground ? 'light first frame' : 'dark first frame',
      );

      final program = Program(
        model,
        options: const ProgramOptions(
          altScreen: false,
          hideCursor: false,
          useUltravioletRenderer: true,
          useUltravioletInputDecoder: true,
          startupProbes: true,
        ),
        terminal: terminal,
      );

      await program.run();

      final joinedOutput = terminal.output.join();
      expect(joinedOutput, contains(Ansi.requestBackgroundColor));
      expect(joinedOutput, contains(Ansi.requestColorScheme));
      expect(joinedOutput, contains('light first frame'));
      expect(joinedOutput, isNot(contains('dark first frame')));
    });

    test('color scheme probe updates the first rendered frame before paint', () async {
      final terminal = _ProbeAwareMockTerminal(
        onWrite: (data, terminal) {
          if (data == Ansi.requestColorScheme) {
            scheduleMicrotask(() {
              terminal.sendInput('\x1b[?997;2n'.codeUnits);
            });
          }
        },
      );

      var sawLightBackground = false;
      final model = _CallbackModel(
        onUpdate: (msg) {
          if (msg case ColorSchemeMsg(dark: false)) {
            sawLightBackground = true;
            return Cmd.tick(
              const Duration(milliseconds: 10),
              (_) => const QuitMsg(),
            );
          }
          return null;
        },
        onView: () => sawLightBackground ? 'light first frame' : 'dark first frame',
      );

      final program = Program(
        model,
        options: const ProgramOptions(
          altScreen: false,
          hideCursor: false,
          useUltravioletRenderer: true,
          useUltravioletInputDecoder: true,
          startupProbes: true,
        ),
        terminal: terminal,
      );

      await program.run();

      final joinedOutput = terminal.output.join();
      expect(joinedOutput, contains(Ansi.requestColorScheme));
      expect(joinedOutput, contains('light first frame'));
      expect(joinedOutput, isNot(contains('dark first frame')));
    });

    test(
      'quit during pre-render startup probing aborts later probes and skips first render',
      () async {
        late Program<_CallbackModel> program;
        final terminal = _ProbeAwareMockTerminal(
          onWrite: (data, terminal) {
            if (data == Ansi.requestBackgroundColor) {
              scheduleMicrotask(() {
                program.send(const QuitMsg());
              });
            }
          },
        );

        var rendered = false;
        final model = _CallbackModel(
          onView: () {
            rendered = true;
            return 'should not render';
          },
        );

        program = Program(
          model,
          options: const ProgramOptions(
            altScreen: false,
            hideCursor: false,
            useUltravioletRenderer: true,
            useUltravioletInputDecoder: true,
            startupProbes: true,
          ),
          terminal: terminal,
        );

        await program.run();

        final joinedOutput = terminal.output.join();
        expect(joinedOutput, contains(Ansi.requestBackgroundColor));
        expect(joinedOutput, contains(Ansi.requestColorScheme));
        expect(joinedOutput, isNot(contains(Ansi.requestSecondaryDeviceAttributes)));
        expect(joinedOutput, isNot(contains(Ansi.requestKittyKeyboard)));
        expect(joinedOutput, isNot(contains('should not render')));
        expect(rendered, isFalse);
      },
    );

    test(
      'quit during post-render emoji probing skips the forced repaint',
      () async {
        late Program<_CallbackModel> program;
        var renderCount = 0;
        var quitScheduled = false;
        final terminal = _ProbeAwareMockTerminal(
          onWrite: (data, terminal) {
            if (!quitScheduled && data == Ansi.requestExtendedCursorPosition) {
              quitScheduled = true;
              scheduleMicrotask(() {
                program.send(const QuitMsg());
              });
            }
          },
        );

        final model = _CallbackModel(
          onView: () {
            renderCount++;
            return 'render #$renderCount';
          },
        );

        program = Program(
          model,
          options: const ProgramOptions(
            altScreen: true,
            hideCursor: false,
            useUltravioletRenderer: true,
            useUltravioletInputDecoder: true,
            startupProbes: true,
          ),
          terminal: terminal,
        );

        await program.run();

        expect(quitScheduled, isTrue);
        expect(renderCount, 1);
      },
    );

    test(
      'backend shutdown during pre-render probing aborts later probes and skips first render',
      () async {
        late final EmbeddedTerminalBackend backend;
        final writes = <String>[];
        backend = EmbeddedTerminalBackend(
          output: (data) {
            writes.add(data);
            if (data == Ansi.requestBackgroundColor) {
              scheduleMicrotask(backend.requestShutdown);
            }
          },
        );

        var rendered = false;
        final program = Program(
          _CallbackModel(
            onView: () {
              rendered = true;
              return 'should not render';
            },
          ),
          options: const ProgramOptions(
            altScreen: false,
            hideCursor: false,
            useUltravioletRenderer: true,
            useUltravioletInputDecoder: true,
            startupProbes: true,
          ),
          terminal: BackendTerminal(backend),
        );

        await program.run();

        final joinedOutput = writes.join();
        expect(joinedOutput, contains(Ansi.requestBackgroundColor));
        expect(joinedOutput, contains(Ansi.requestColorScheme));
        expect(joinedOutput, isNot(contains(Ansi.requestSecondaryDeviceAttributes)));
        expect(joinedOutput, isNot(contains(Ansi.requestKittyKeyboard)));
        expect(rendered, isFalse);
      },
    );

    test(
      'kill during pre-render startup probing aborts later probes and skips first render',
      () async {
        late Program<_CallbackModel> program;
        final terminal = _ProbeAwareMockTerminal(
          onWrite: (data, terminal) {
            if (data == Ansi.requestBackgroundColor) {
              scheduleMicrotask(program.kill);
            }
          },
        );

        var rendered = false;
        final model = _CallbackModel(
          onView: () {
            rendered = true;
            return 'should not render';
          },
        );

        program = Program(
          model,
          options: const ProgramOptions(
            altScreen: false,
            hideCursor: false,
            useUltravioletRenderer: true,
            useUltravioletInputDecoder: true,
            startupProbes: true,
          ),
          terminal: terminal,
        );

        await program.run();

        final joinedOutput = terminal.output.join();
        expect(joinedOutput, contains(Ansi.requestBackgroundColor));
        expect(joinedOutput, contains(Ansi.requestColorScheme));
        expect(joinedOutput, isNot(contains(Ansi.requestSecondaryDeviceAttributes)));
        expect(joinedOutput, isNot(contains(Ansi.requestKittyKeyboard)));
        expect(rendered, isFalse);
        expect(program.wasKilled, isTrue);
      },
    );

    test(
      'cancel signal during pre-render startup probing aborts later probes and skips first render',
      () async {
        final cancelCompleter = Completer<void>();
        final terminal = _ProbeAwareMockTerminal(
          onWrite: (data, terminal) {
            if (data == Ansi.requestBackgroundColor) {
              scheduleMicrotask(cancelCompleter.complete);
            }
          },
        );

        var rendered = false;
        final program = Program(
          _CallbackModel(
            onView: () {
              rendered = true;
              return 'should not render';
            },
          ),
          options: ProgramOptions(
            altScreen: false,
            hideCursor: false,
            useUltravioletRenderer: true,
            useUltravioletInputDecoder: true,
            startupProbes: true,
            cancelSignal: cancelCompleter.future,
          ),
          terminal: terminal,
        );

        await expectLater(program.run(), throwsA(isA<ProgramCancelledError>()));

        final joinedOutput = terminal.output.join();
        expect(joinedOutput, contains(Ansi.requestBackgroundColor));
        expect(joinedOutput, contains(Ansi.requestColorScheme));
        expect(joinedOutput, isNot(contains(Ansi.requestSecondaryDeviceAttributes)));
        expect(joinedOutput, isNot(contains(Ansi.requestKittyKeyboard)));
        expect(rendered, isFalse);
      },
    );

    test(
      'backend shutdown during post-render emoji probing skips the forced repaint',
      () async {
        late final EmbeddedTerminalBackend backend;
        var renderCount = 0;
        var shutdownRequested = false;
        backend = EmbeddedTerminalBackend(
          output: (data) {
            if (!shutdownRequested && data == Ansi.requestExtendedCursorPosition) {
              shutdownRequested = true;
              scheduleMicrotask(backend.requestShutdown);
            }
          },
        );

        final program = Program(
          _CallbackModel(
            onView: () {
              renderCount++;
              return 'render #$renderCount';
            },
          ),
          options: const ProgramOptions(
            altScreen: true,
            hideCursor: false,
            useUltravioletRenderer: true,
            useUltravioletInputDecoder: true,
          ),
          terminal: BackendTerminal(backend),
        );

        await program.run();

        expect(shutdownRequested, isTrue);
        expect(renderCount, 1);
      },
    );

    test(
      'kill during post-render emoji probing skips the forced repaint',
      () async {
        late Program<_CallbackModel> program;
        var renderCount = 0;
        var killScheduled = false;
        final terminal = _ProbeAwareMockTerminal(
          onWrite: (data, terminal) {
            if (!killScheduled && data == Ansi.requestExtendedCursorPosition) {
              killScheduled = true;
              scheduleMicrotask(program.kill);
            }
          },
        );

        final model = _CallbackModel(
          onView: () {
            renderCount++;
            return 'render #$renderCount';
          },
        );

        program = Program(
          model,
          options: const ProgramOptions(
            altScreen: true,
            hideCursor: false,
            useUltravioletRenderer: true,
            useUltravioletInputDecoder: true,
            startupProbes: true,
          ),
          terminal: terminal,
        );

        await program.run();

        expect(killScheduled, isTrue);
        expect(renderCount, 1);
        expect(program.wasKilled, isTrue);
      },
    );

    test(
      'cancel signal during post-render emoji probing skips the forced repaint',
      () async {
        final cancelCompleter = Completer<void>();
        var renderCount = 0;
        var cancelScheduled = false;
        final terminal = _ProbeAwareMockTerminal(
          onWrite: (data, terminal) {
            if (!cancelScheduled && data == Ansi.requestExtendedCursorPosition) {
              cancelScheduled = true;
              scheduleMicrotask(cancelCompleter.complete);
            }
          },
        );

        final program = Program(
          _CallbackModel(
            onView: () {
              renderCount++;
              return 'render #$renderCount';
            },
          ),
          options: ProgramOptions(
            altScreen: true,
            hideCursor: false,
            useUltravioletRenderer: true,
            useUltravioletInputDecoder: true,
            startupProbes: true,
            cancelSignal: cancelCompleter.future,
          ),
          terminal: terminal,
        );

        await expectLater(program.run(), throwsA(isA<ProgramCancelledError>()));

        expect(cancelScheduled, isTrue);
        expect(renderCount, 1);
      },
    );
  });

  group('Terminal color requests', () {
    test('foreground and cursor color replies are delivered as messages', () async {
      final terminal = _ProbeAwareMockTerminal(
        onWrite: (data, terminal) {
          if (data == Ansi.requestBackgroundColor) {
            scheduleMicrotask(() {
              terminal.sendInput('\x1b]11;rgb:1111/1111/1111\x07'.codeUnits);
            });
          }
          if (data == Ansi.requestForegroundColor) {
            scheduleMicrotask(() {
              terminal.sendInput('\x1b]10;rgb:aaaa/bbbb/cccc\x07'.codeUnits);
            });
          }
          if (data == Ansi.requestCursorColor) {
            scheduleMicrotask(() {
              terminal.sendInput('\x1b]12;rgb:1234/5678/9abc\x07'.codeUnits);
            });
          }
        },
      );

      String? foregroundHex;
      String? cursorHex;
      final model = _CallbackModel(
        onInit: () => Cmd.batch([
          Cmd.requestForegroundColor(),
          Cmd.requestCursorColor(),
        ]),
        onUpdate: (msg) {
          switch (msg) {
            case ForegroundColorMsg(hex: final hex):
              foregroundHex = hex;
            case CursorColorMsg(hex: final hex):
              cursorHex = hex;
            default:
              break;
          }
          if (foregroundHex != null && cursorHex != null) {
            return Cmd.message(const QuitMsg());
          }
          return null;
        },
        onView: () => 'color request runtime',
      );

      final program = Program(
        model,
        options: const ProgramOptions(
          altScreen: false,
          hideCursor: false,
          useUltravioletRenderer: true,
          useUltravioletInputDecoder: true,
          startupProbes: true,
        ),
        terminal: terminal,
      );

      await program.run();

      expect(foregroundHex, '#aabbcc');
      expect(cursorHex, '#12569a');
      final joinedOutput = terminal.output.join();
      expect(joinedOutput, contains(Ansi.requestForegroundColor));
      expect(joinedOutput, contains(Ansi.requestCursorColor));
    });

    test('palette color replies are delivered as messages', () async {
      const paletteRequest = '\x1b]4;42;?\x07';
      final terminal = _ProbeAwareMockTerminal(
        onWrite: (data, terminal) {
          if (data == Ansi.requestBackgroundColor) {
            scheduleMicrotask(() {
              terminal.sendInput('\x1b]11;rgb:1111/1111/1111\x07'.codeUnits);
            });
          }
          if (data == paletteRequest) {
            scheduleMicrotask(() {
              terminal.sendInput('\x1b]4;42;rgb:0f0f/1a1a/2b2b\x07'.codeUnits);
            });
          }
        },
      );

      int? paletteIndex;
      String? paletteHex;
      final model = _CallbackModel(
        onInit: () => Cmd.requestColorPalette(42),
        onUpdate: (msg) {
          switch (msg) {
            case ColorPaletteMsg(index: final index, hex: final hex):
              paletteIndex = index;
              paletteHex = hex;
              return Cmd.message(const QuitMsg());
            default:
              return null;
          }
        },
        onView: () => 'palette request runtime',
      );

      final program = Program(
        model,
        options: const ProgramOptions(
          altScreen: false,
          hideCursor: false,
          useUltravioletRenderer: true,
          useUltravioletInputDecoder: true,
          startupProbes: true,
        ),
        terminal: terminal,
      );

      await program.run();

      expect(paletteIndex, 42);
      expect(paletteHex, '#0f1a2b');
      expect(terminal.output.join(), contains(paletteRequest));
    });

    test('clipboard replies are delivered as messages', () async {
      const clipboardRequest = '\x1b]52;c;?\x07';
      final terminal = _ProbeAwareMockTerminal(
        onWrite: (data, terminal) {
          if (data == Ansi.requestBackgroundColor) {
            scheduleMicrotask(() {
              terminal.sendInput('\x1b]11;rgb:1111/1111/1111\x07'.codeUnits);
            });
          }
          if (data == clipboardRequest) {
            scheduleMicrotask(() {
              terminal.sendInput('\x1b]52;c;SGVsbG8=\x07'.codeUnits);
            });
          }
        },
      );

      ClipboardSelection? selection;
      String? content;
      final model = _CallbackModel(
        onInit: () => Cmd.requestClipboard(),
        onUpdate: (msg) {
          switch (msg) {
            case ClipboardMsg(selection: final sel, content: final text):
              selection = sel;
              content = text;
              return Cmd.message(const QuitMsg());
            default:
              return null;
          }
        },
        onView: () => 'clipboard request runtime',
      );

      final program = Program(
        model,
        options: const ProgramOptions(
          altScreen: false,
          hideCursor: false,
          useUltravioletRenderer: true,
          useUltravioletInputDecoder: true,
          startupProbes: true,
        ),
        terminal: terminal,
      );

      await program.run();

      expect(selection, ClipboardSelection.system);
      expect(content, 'Hello');
      expect(terminal.output.join(), contains(clipboardRequest));
    });
  });

  group('StreamCmd and EveryCmd after quit', () {
    late MockTerminal terminal;

    setUp(() {
      terminal = MockTerminal();
    });

    test('StreamCmd stops sending after quit', () async {
      final messagesReceived = <Msg>[];
      final streamController = StreamController<int>();

      final model = _CallbackModel(
        onInit: () => Cmd.listen<int>(
          streamController.stream,
          onData: (data) => _StreamDataMsg(data),
        ),
        onUpdate: (msg) {
          messagesReceived.add(msg);
          // Quit after first stream message
          if (msg is _StreamDataMsg && msg.value == 1) {
            return Cmd.quit();
          }
          return null;
        },
      );

      final program = Program(
        model,
        options: const ProgramOptions(altScreen: false),
        terminal: terminal,
      );

      // Start the program
      final runFuture = program.run();

      // Send first value - this will trigger quit
      streamController.add(1);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Wait for program to quit
      await runFuture;

      // Record message count after quit
      final countAfterQuit = messagesReceived
          .whereType<_StreamDataMsg>()
          .length;

      // Send more values after quit
      streamController.add(2);
      streamController.add(3);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Should not have received messages after quit
      final countAfterMoreData = messagesReceived
          .whereType<_StreamDataMsg>()
          .length;
      expect(
        countAfterMoreData,
        countAfterQuit,
        reason: 'StreamCmd should stop sending after quit',
      );

      await streamController.close();
    });

    test('EveryCmd stops sending after quit', () async {
      var tickCount = 0;

      final model = _CallbackModel(
        onInit: () =>
            every(const Duration(milliseconds: 20), (time) => const _TickMsg()),
        onUpdate: (msg) {
          if (msg is _TickMsg) {
            tickCount++;
            // Quit after 2 ticks
            if (tickCount >= 2) {
              return Cmd.quit();
            }
          }
          return null;
        },
      );

      final program = Program(
        model,
        options: const ProgramOptions(altScreen: false),
        terminal: terminal,
      );

      await program.run();

      // Record tick count after quit
      final ticksAtQuit = tickCount;

      // Wait to see if more ticks arrive
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Should not have received more ticks after quit
      expect(
        tickCount,
        ticksAtQuit,
        reason: 'EveryCmd should stop sending after quit',
      );
    });

    test('send() is ignored after program quit', () async {
      late Program<_SimpleQuitModel> program;

      final model = _SimpleQuitModel();

      program = Program(
        model,
        options: const ProgramOptions(altScreen: false),
        terminal: terminal,
      );

      await program.run();

      // Program has quit, now try to send a message
      // This should be silently ignored, not throw or process
      expect(() => program.send(const IncrementMsg()), returnsNormally);
    });

    test('send() is ignored after program kill', () async {
      late Program<CounterModel> program;

      program = Program(
        const CounterModel(),
        options: const ProgramOptions(altScreen: false),
        terminal: terminal,
      );

      // Start program but don't wait
      final runFuture = program.run();

      // Give it time to start
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Kill it
      program.kill();
      await runFuture;

      // Try to send after kill - should be ignored
      expect(() => program.send(const IncrementMsg()), returnsNormally);
    });

    test('deeply nested BatchMsg does not cause stack overflow', () async {
      var messageCount = 0;

      final model = _CallbackModel(
        onInit: () =>
            Cmd.tick(const Duration(milliseconds: 100), (_) => const QuitMsg()),
        onUpdate: (msg) {
          if (msg is IncrementMsg) {
            messageCount++;
          }
          return null;
        },
      );

      final program = Program(
        model,
        options: const ProgramOptions(altScreen: false),
        terminal: terminal,
      );

      // Start the program
      final runFuture = program.run();

      // Give it time to start
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Create a deeply nested BatchMsg structure (1000 levels deep)
      // This would cause stack overflow with recursive implementation
      Msg nested = const IncrementMsg();
      for (var i = 0; i < 1000; i++) {
        nested = BatchMsg([nested, const IncrementMsg()]);
      }

      // Send the deeply nested batch - should not cause stack overflow
      program.send(nested);

      await runFuture;

      // Should have received all the increment messages
      // Each level of nesting adds 2 IncrementMsg (one nested, one direct)
      // Total = 1001 from nesting + 1 original = 2001 messages
      expect(
        messageCount,
        greaterThan(1000),
        reason: 'Should process all messages from deeply nested batch',
      );
    });
  });
}

// =============================================================================
// Helper Classes
// =============================================================================

/// A model that tracks received messages for testing.
class _TrackingModel implements Model {
  _TrackingModel({this.onUpdate});

  final Cmd? Function(Msg)? onUpdate;

  @override
  Cmd? init() => null;

  @override
  (Model, Cmd?) update(Msg msg) {
    final cmd = onUpdate?.call(msg);
    return (this, cmd);
  }

  @override
  String view() => 'Tracking model';
}

class _RecordingProgramInterceptor extends ProgramInterceptor {
  _RecordingProgramInterceptor({this.onStartSend, this.onSendHook});

  final void Function(void Function(Msg msg) send)? onStartSend;
  final Msg? Function(Msg msg)? onSendHook;

  bool stopped = false;
  int processedCount = 0;

  @override
  void onStart(void Function(Msg msg) send) {
    onStartSend?.call(send);
  }

  @override
  Msg? onSend(Msg msg) {
    final hook = onSendHook;
    if (hook == null) return msg;
    return hook(msg);
  }

  @override
  void onProcessed(Msg msg, Duration elapsed) {
    processedCount++;
  }

  @override
  void onStop() {
    stopped = true;
  }
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

/// A model that uses callbacks for testing.
class _CallbackModel implements Model {
  _CallbackModel({
    Cmd? Function()? onInit,
    Cmd? Function(Msg)? onUpdate,
    Object Function()? onView,
  }) : _onInit = onInit,
       _onUpdate = onUpdate,
       _onView = onView;

  final Cmd? Function()? _onInit;
  final Cmd? Function(Msg)? _onUpdate;
  final Object Function()? _onView;

  @override
  Cmd? init() => _onInit?.call();

  @override
  (Model, Cmd?) update(Msg msg) {
    final cmd = _onUpdate?.call(msg);
    return (this, cmd);
  }

  @override
  Object view() => _onView?.call() ?? 'Callback model';
}

class _FrameTickCallbackModel extends _CallbackModel implements FrameTickModel {
  _FrameTickCallbackModel({
    super.onUpdate,
    super.onView,
  });

  @override
  bool get wantsFrameTicks => true;
}

/// A terminal that throws during some operations (for testing robust cleanup).
/// A model that handles InterruptMsg for testing.
class _InterruptHandlerModel implements Model {
  _InterruptHandlerModel({required this.onInterrupt});

  final void Function() onInterrupt;
  bool interrupted = false;

  @override
  Cmd? init() => null;

  @override
  (Model, Cmd?) update(Msg msg) {
    if (msg is InterruptMsg) {
      onInterrupt();
      return (
        _InterruptHandlerModel(onInterrupt: onInterrupt)..interrupted = true,
        null,
      );
    }
    return (this, null);
  }

  @override
  String view() => 'Interrupted: $interrupted';
}

/// Message for stream data in tests.
class _StreamDataMsg extends Msg {
  const _StreamDataMsg(this.value);
  final int value;
}

/// Message for tick events in tests.
class _TickMsg extends Msg {
  const _TickMsg();
}

/// A model that immediately quits (simpler than ImmediateQuitModel).
class _SimpleQuitModel implements Model {
  @override
  Cmd? init() => Cmd.quit();

  @override
  (Model, Cmd?) update(Msg msg) => (this, null);

  @override
  String view() => 'Simple quit model';
}

class _FragileTerminal implements TuiTerminal {
  bool disposeAttempted = false;

  final StreamController<List<int>> _inputController =
      StreamController<List<int>>.broadcast();

  bool rawModeEnabled = false;
  bool altScreenEnabled = false;
  bool mouseEnabled = false;
  bool bracketedPasteEnabled = false;
  bool cursorHidden = false;

  @override
  bool get isAltScreen => altScreenEnabled;

  @override
  Stream<List<int>> get input => _inputController.stream;

  @override
  int get width => 80;

  @override
  int get height => 24;

  @override
  bool get supportsAnsi => true;

  @override
  bool get isTerminal => true;

  @override
  ColorProfile get colorProfile => ColorProfile.trueColor;

  @override
  ({int width, int height}) get size => (width: width, height: height);

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
  void disableRawMode() {
    rawModeEnabled = false;
    throw StateError('Simulated cleanup failure');
  }

  @override
  bool get isRawMode => rawModeEnabled;

  @override
  void write(String data) {}

  @override
  void writeln([String data = '']) {}

  @override
  Future<String?> query(
    String query, {
    Duration timeout = const Duration(seconds: 2),
  }) async => null;

  @override
  Future<void> flush() async {}

  @override
  void enterAltScreen() {
    altScreenEnabled = true;
  }

  @override
  void exitAltScreen() {
    altScreenEnabled = false;
    throw StateError('Simulated cleanup failure');
  }

  @override
  void hideCursor() {
    cursorHidden = true;
  }

  @override
  void showCursor() {
    cursorHidden = false;
    throw StateError('Simulated cleanup failure');
  }

  @override
  void enableMouse() {
    mouseEnabled = true;
  }

  @override
  void enableMouseCellMotion() {
    mouseEnabled = true;
  }

  @override
  void enableMouseAllMotion() {
    mouseEnabled = true;
  }

  @override
  void disableMouse() {
    mouseEnabled = false;
  }

  @override
  bool get isMouseEnabled => mouseEnabled;

  @override
  void enableBracketedPaste() {
    bracketedPasteEnabled = true;
  }

  @override
  void disableBracketedPaste() {
    bracketedPasteEnabled = false;
  }

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
  void saveCursor() {}

  @override
  void restoreCursor() {}

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
  int readByte() => -1;

  @override
  String? readLine() => null;

  @override
  void dispose() {
    disposeAttempted = true;
    _inputController.close();
    throw StateError('Simulated cleanup failure');
  }
}

/// A terminal that tracks dispose calls for testing double-cleanup prevention.
class _DisposeTrackingTerminal implements TuiTerminal {
  _DisposeTrackingTerminal({this.onDispose});

  final void Function()? onDispose;
  final StreamController<List<int>> _inputController =
      StreamController<List<int>>.broadcast();

  @override
  bool get isAltScreen => false;

  @override
  Stream<List<int>> get input => _inputController.stream;

  @override
  int get width => 80;

  @override
  int get height => 24;

  @override
  bool get supportsAnsi => true;

  @override
  bool get isTerminal => true;

  @override
  ColorProfile get colorProfile => ColorProfile.trueColor;

  @override
  ({int width, int height}) get size => (width: width, height: height);

  @override
  RawModeGuard enableRawMode() {
    return RawModeGuard(
      wasEchoMode: true,
      wasLineMode: true,
      restore: disableRawMode,
    );
  }

  @override
  void disableRawMode() {}

  @override
  bool get isRawMode => false;

  @override
  void write(String data) {}

  @override
  void writeln([String data = '']) {}

  @override
  Future<String?> query(
    String query, {
    Duration timeout = const Duration(seconds: 2),
  }) async => null;

  @override
  Future<void> flush() async {}

  @override
  void enterAltScreen() {}

  @override
  void exitAltScreen() {}

  @override
  void hideCursor() {}

  @override
  void showCursor() {}

  @override
  void enableMouse() {}

  @override
  void enableMouseCellMotion() {}

  @override
  void enableMouseAllMotion() {}

  @override
  void disableMouse() {}

  @override
  bool get isMouseEnabled => false;

  @override
  void enableBracketedPaste() {}

  @override
  void disableBracketedPaste() {}

  @override
  bool get isBracketedPasteEnabled => false;

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
  void saveCursor() {}

  @override
  void restoreCursor() {}

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
  int readByte() => -1;

  @override
  String? readLine() => null;

  @override
  void dispose() {
    onDispose?.call();
    _inputController.close();
  }
}
