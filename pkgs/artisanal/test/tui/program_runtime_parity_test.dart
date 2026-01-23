import 'dart:async';

import 'package:artisanal/src/style/color.dart';
import 'package:artisanal/src/terminal/terminal_base.dart' show RawModeGuard;
import 'package:artisanal/tui.dart';
import 'package:test/test.dart';

class _QuitModel implements Model {
  @override
  Cmd? init() => Cmd.quit();

  @override
  (Model, Cmd?) update(Msg msg) => (this, null);

  @override
  String view() => 'quit';
}

class _MockTerminal implements TuiTerminal {
  final operations = <String>[];
  final output = <String>[];
  bool _raw = false;
  bool _alt = false;

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
  ({int width, int height}) get size => (width: 80, height: 24);

  @override
  Stream<List<int>> get input => const Stream.empty();

  @override
  void write(String data) {
    output.add(data);
    operations.add('write');
  }

  @override
  void writeln([String data = '']) {
    output.add('$data\n');
    operations.add('writeln');
  }

  @override
  Future<void> flush() async {
    operations.add('flush');
  }

  @override
  Future<String?> query(
    String query, {
    Duration timeout = const Duration(seconds: 2),
  }) async {
    operations.add('query');
    return null;
  }

  @override
  RawModeGuard enableRawMode() {
    _raw = true;
    operations.add('enableRaw');
    return RawModeGuard(
      wasEchoMode: true,
      wasLineMode: true,
      restore: disableRawMode,
    );
  }

  @override
  void disableRawMode() {
    _raw = false;
    operations.add('disableRaw');
  }

  @override
  bool get isRawMode => _raw;

  @override
  void enableMouse() => operations.add('enableMouse');

  @override
  void enableMouseCellMotion() => operations.add('enableMouseCellMotion');

  @override
  void enableMouseAllMotion() => operations.add('enableMouseAllMotion');

  @override
  void disableMouse() => operations.add('disableMouse');

  @override
  bool get isMouseEnabled => operations.contains('enableMouse');

  @override
  void enableBracketedPaste() => operations.add('enablePaste');

  @override
  void disableBracketedPaste() => operations.add('disablePaste');

  @override
  bool get isBracketedPasteEnabled =>
      operations.contains('enablePaste') &&
      !operations.contains('disablePaste');

  @override
  void clearScreen() => operations.add('clearScreen');

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
  void moveCursor(int row, int col) {}

  @override
  void saveCursor() {}

  @override
  void restoreCursor() {}

  @override
  void scrollUp([int lines = 1]) {}

  @override
  void scrollDown([int lines = 1]) {}

  @override
  void enterAltScreen() {
    _alt = true;
    operations.add('enterAlt');
  }

  @override
  void exitAltScreen() {
    _alt = false;
    operations.add('exitAlt');
  }

  @override
  bool get isAltScreen => _alt;

  @override
  void hideCursor() => operations.add('hideCursor');

  @override
  void showCursor() => operations.add('showCursor');

  @override
  void cursorHome() {}

  @override
  void cursorUp([int rows = 1]) {}

  @override
  void cursorDown([int rows = 1]) {}

  @override
  void cursorLeft([int cols = 1]) {}

  @override
  void cursorRight([int cols = 1]) {}

  @override
  void cursorToColumn(int col) {}

  @override
  void enableFocusReporting() => operations.add('enableFocus');

  @override
  void disableFocusReporting() => operations.add('disableFocus');

  @override
  void setTitle(String title) {}

  @override
  void setProgressBar(int state, int value) {}

  @override
  void bell() => operations.add('bell');

  @override
  int readByte() => -1;

  @override
  String? readLine() => null;

  @override
  void dispose() {
    operations.add('dispose');
  }

  @override
  ({bool useBackspace, bool useTabs}) optimizeMovements() {
    return (useTabs: false, useBackspace: true);
  }
}

void main() {
  group('mouse modes', () {
    test('cell motion enables correct terminal command', () async {
      final term = _MockTerminal();
      final program = Program(
        _QuitModel(),
        options: const ProgramOptions(mouseMode: MouseMode.cellMotion),
        terminal: term,
      );
      await program.run();
      expect(term.operations, contains('enableMouseCellMotion'));
      expect(term.operations, isNot(contains('enableMouseAllMotion')));
    });

    test('all motion enables correct terminal command', () async {
      final term = _MockTerminal();
      final program = Program(
        _QuitModel(),
        options: const ProgramOptions(mouseMode: MouseMode.allMotion),
        terminal: term,
      );
      await program.run();
      expect(term.operations, contains('enableMouseAllMotion'));
    });
  });

  group('disable renderer', () {
    test('does not enter alt screen or hide cursor', () async {
      final term = _MockTerminal();
      final program = Program(
        _QuitModel(),
        options: const ProgramOptions(
          disableRenderer: true,
          altScreen: true,
          hideCursor: true,
        ),
        terminal: term,
      );
      await program.run();
      expect(
        term.operations,
        isNot(anyOf(contains('enterAlt'), contains('enterAltScreen'))),
      );
      expect(term.operations, isNot(contains('hideCursor')));
    });
  });

  group('ansi compression', () {
    test('inline renderer compresses duplicate ansi codes', () {
      final term = _MockTerminal();
      final renderer = InlineTuiRenderer(
        terminal: term,
        options: const TuiRendererOptions(
          altScreen: false,
          hideCursor: false,
          ansiCompress: true,
          fps: 120,
        ),
      );
      renderer.render('\x1b[31mred\x1b[31mred');
      expect(term.output.join(), contains('\x1b[31mredred'));
    });
  });

  group('cancel signal', () {
    test('run throws ProgramCancelledError', () async {
      final term = _MockTerminal();
      final cancel = Completer<void>();
      final program = Program(
        _QuitModel(),
        options: ProgramOptions(cancelSignal: cancel.future),
        terminal: term,
      );
      final runFuture = program.run();
      cancel.complete();
      expect(runFuture, throwsA(isA<ProgramCancelledError>()));
    });
  });
}
