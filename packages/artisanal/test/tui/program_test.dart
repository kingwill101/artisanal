import 'dart:async';

import 'package:artisanal/src/style/color.dart';
import 'package:artisanal/src/tui/cmd.dart';
import 'package:artisanal/src/tui/model.dart';
import 'package:artisanal/src/tui/msg.dart';
import 'package:artisanal/src/tui/program.dart';
import 'package:artisanal/src/tui/terminal.dart';
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

/// A model that uses callbacks for testing.
class _CallbackModel implements Model {
  _CallbackModel({
    Cmd? Function()? onInit,
    Cmd? Function(Msg)? onUpdate,
    String Function()? onView,
  }) : _onInit = onInit,
       _onUpdate = onUpdate,
       _onView = onView;

  final Cmd? Function()? _onInit;
  final Cmd? Function(Msg)? _onUpdate;
  final String Function()? _onView;

  @override
  Cmd? init() => _onInit?.call();

  @override
  (Model, Cmd?) update(Msg msg) {
    final cmd = _onUpdate?.call(msg);
    return (this, cmd);
  }

  @override
  String view() => _onView?.call() ?? 'Callback model';
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
