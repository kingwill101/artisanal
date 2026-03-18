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
      final program = Program(
        ImmediateQuitModel(),
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

      final titleOutput = terminal.output.where(
        (s) => s.contains('\x1b]0;My App\x07'),
      );
      expect(titleOutput, isNotEmpty);
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

    test('ExecProcess restore reapplies identical view terminal metadata', () async {
      final view = View(
        content: 'sticky metadata',
        reportFocus: true,
        bracketedPaste: true,
        mouseMode: MouseMode.allMotion,
        backgroundColor: const BasicColor('#112233'),
        foregroundColor: const BasicColor('#eeddcc'),
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
        RegExp(r'\x1b]11;#112233\x07').allMatches(joinedOutput).length,
        greaterThanOrEqualTo(2),
      );
      expect(
        RegExp(r'\x1b]10;#eeddcc\x07').allMatches(joinedOutput).length,
        greaterThanOrEqualTo(2),
      );
      expect(joinedOutput, contains('\x1b]111\x07'));
      expect(joinedOutput, contains('\x1b]110\x07'));
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
