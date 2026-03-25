// Tests that every _*PromptModel wrapper in prompt.dart handles [InterruptMsg]
// by completing its controller with null (or throwing [ProgramCancelledError]
// for the spinner) and returning [Cmd.quit()].
//
// Strategy: each [runXxxPrompt] helper accepts an optional `options:` parameter.
// We use a [ProgramOptions.withFilter] that converts any incoming Ctrl+C
// [KeyMsg] (byte 0x03 → Key(runes: [0x63], ctrl: true)) to [InterruptMsg],
// then inject those bytes via the mock terminal. This cleanly exercises the
// [InterruptMsg] handling path in each wrapper without needing real signals.

import 'dart:async';

import 'package:artisanal/src/tui/bubbles/anticipate.dart';
import 'package:artisanal/src/tui/bubbles/confirm.dart';
import 'package:artisanal/src/tui/bubbles/data_table.dart';
import 'package:artisanal/src/tui/bubbles/number_input.dart';
import 'package:artisanal/src/tui/bubbles/password.dart';
import 'package:artisanal/src/tui/bubbles/prompt.dart';
import 'package:artisanal/src/tui/bubbles/search.dart';
import 'package:artisanal/src/tui/bubbles/select.dart';
import 'package:artisanal/src/tui/bubbles/suggest.dart';
import 'package:artisanal/src/tui/bubbles/table.dart' show Column;
import 'package:artisanal/src/tui/bubbles/textinput.dart';
import 'package:artisanal/src/tui/bubbles/textarea.dart';
import 'package:artisanal/src/tui/bubbles/wizard.dart';
import 'package:artisanal/src/tui/msg.dart' show InterruptMsg, KeyMsg;
import 'package:artisanal/src/tui/program.dart'
    show ProgramCancelledError, ProgramOptions;
import 'package:artisanal/src/tui/terminal.dart';
import 'package:artisanal/src/style/color.dart';
import 'package:test/test.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Minimal mock terminal (same pattern as program_test.dart).
// ─────────────────────────────────────────────────────────────────────────────

class _MockTerminal implements TuiTerminal {
  final StreamController<List<int>> _input =
      StreamController<List<int>>.broadcast();

  void sendInput(List<int> bytes) => _input.add(bytes);

  /// Simulate Ctrl+C (byte 0x03).
  void sendCtrlC() => sendInput([0x03]);

  @override
  int get width => 80;
  @override
  int get height => 24;
  @override
  bool get isTerminal => true;
  @override
  ColorProfile get colorProfile => ColorProfile.trueColor;
  @override
  Stream<List<int>> get input => _input.stream;
  @override
  void write(String data) {}
  @override
  void writeln([String data = '']) {}
  @override
  Future<void> flush() async {}
  @override
  RawModeGuard enableRawMode() => RawModeGuard(
    wasEchoMode: true,
    wasLineMode: true,
    restore: disableRawMode,
  );
  @override
  void disableRawMode() {}
  @override
  Future<String?> query(
    String q, {
    Duration timeout = const Duration(seconds: 2),
  }) async => null;
  @override
  bool get isRawMode => false;
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
  void enableBracketedPaste() {}
  @override
  void disableBracketedPaste() {}
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
  bool get isAltScreen => false;
  @override
  bool get isMouseEnabled => false;
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
  int readByte() => -1;
  @override
  String? readLine() => null;
  @override
  void saveCursor() {}
  @override
  void restoreCursor() {}
  @override
  void dispose() {
    if (!_input.isClosed) _input.close();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper — options with a filter that converts Ctrl+C KeyMsg → InterruptMsg.
//
// Byte 0x03 from stdin is decoded as Key(KeyType.runes, runes: [0x63], ctrl).
// The programs under test have `sendInterrupt: false` so this key is normally
// passed to the model as a KeyMsg. Our filter intercepts it and replaces it
// with InterruptMsg, exercising the exact code path that SIGINT would trigger
// in production.
// ─────────────────────────────────────────────────────────────────────────────

bool _isCtrlC(KeyMsg msg) =>
    msg.key.ctrl && msg.key.runes.length == 1 && msg.key.runes.first == 0x63;

/// Returns base [ProgramOptions] (inline, no alt-screen) with the Ctrl+C →
/// InterruptMsg filter applied.
ProgramOptions get _opts =>
    const ProgramOptions(
      altScreen: false,
      hideCursor: false,
      fps: 20,
      mouse: false,
      bracketedPaste: false,
      signalHandlers: false,
      sendInterrupt: false,
      useUltravioletRenderer: false,
      useUltravioletInputDecoder: false,
      shutdownSharedStdinOnExit: false,
    ).withFilter(
      (_, msg) => msg is KeyMsg && _isCtrlC(msg) ? const InterruptMsg() : msg,
    );

/// Alt-screen variant for TextArea.
ProgramOptions get _optsAltScreen =>
    const ProgramOptions(
      altScreen: true,
      hideCursor: true,
      fps: 60,
      mouse: false,
      bracketedPaste: true,
      signalHandlers: false,
      sendInterrupt: false,
      useUltravioletRenderer: true,
      useUltravioletInputDecoder: true,
      shutdownSharedStdinOnExit: false,
    ).withFilter(
      (_, msg) => msg is KeyMsg && _isCtrlC(msg) ? const InterruptMsg() : msg,
    );

/// Waits [startupMs] for the program to start, sends Ctrl+C via [terminal],
/// then awaits [promptFuture] with a [timeoutSecs] deadline.
Future<T> _runWithInterrupt<T>(
  _MockTerminal terminal,
  Future<T> promptFuture, {
  int startupMs = 50,
  int timeoutSecs = 2,
}) async {
  await Future<void>.delayed(Duration(milliseconds: startupMs));
  terminal.sendCtrlC();
  return promptFuture.timeout(Duration(seconds: timeoutSecs));
}

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('prompt interrupt handling', () {
    // ── PasswordModel ────────────────────────────────────────────────────────

    test('runPasswordPrompt returns null on Ctrl+C', () async {
      final terminal = _MockTerminal();
      final future = runPasswordPrompt(
        PasswordModel(prompt: 'Password: '),
        terminal,
        options: _opts,
      );
      final result = await _runWithInterrupt(terminal, future);
      expect(result, isNull);
    });

    // ── PasswordConfirmModel ─────────────────────────────────────────────────

    test('runPasswordConfirmPrompt returns null on Ctrl+C', () async {
      final terminal = _MockTerminal();
      final future = runPasswordConfirmPrompt(
        PasswordConfirmModel(prompt: 'Password: ', confirmPrompt: 'Confirm: '),
        terminal,
        options: _opts,
      );
      final result = await _runWithInterrupt(terminal, future);
      expect(result, isNull);
    });

    // ── ConfirmModel ─────────────────────────────────────────────────────────

    test('runConfirmPrompt returns null on Ctrl+C', () async {
      final terminal = _MockTerminal();
      final future = runConfirmPrompt(
        ConfirmModel(prompt: 'Are you sure?'),
        terminal,
        options: _opts,
      );
      final result = await _runWithInterrupt(terminal, future);
      expect(result, isNull);
    });

    // ── SelectModel ──────────────────────────────────────────────────────────

    test('runSelectPrompt returns null on Ctrl+C', () async {
      final terminal = _MockTerminal();
      final future = runSelectPrompt<String>(
        SelectModel<String>(items: ['a', 'b']),
        terminal,
        options: _opts,
      );
      final result = await _runWithInterrupt(terminal, future);
      expect(result, isNull);
    });

    // ── MultiSelectModel ─────────────────────────────────────────────────────

    test('runMultiSelectPrompt returns null on Ctrl+C', () async {
      final terminal = _MockTerminal();
      final future = runMultiSelectPrompt<String>(
        MultiSelectModel<String>(items: ['a', 'b']),
        terminal,
        options: _opts,
      );
      final result = await _runWithInterrupt(terminal, future);
      expect(result, isNull);
    });

    // ── SearchModel ──────────────────────────────────────────────────────────

    test('runSearchPrompt returns null on Ctrl+C', () async {
      final terminal = _MockTerminal();
      final future = runSearchPrompt<String>(
        SearchModel<String>(items: ['alpha', 'beta']),
        terminal,
        options: _opts,
      );
      final result = await _runWithInterrupt(terminal, future);
      expect(result, isNull);
    });

    // ── MultiSearchModel ─────────────────────────────────────────────────────

    test('runMultiSearchPrompt returns null on Ctrl+C', () async {
      final terminal = _MockTerminal();
      final future = runMultiSearchPrompt<String>(
        MultiSearchModel<String>(items: ['alpha', 'beta']),
        terminal,
        options: _opts,
      );
      final result = await _runWithInterrupt(terminal, future);
      expect(result, isNull);
    });

    // ── AnticipateModel ──────────────────────────────────────────────────────

    test('runAnticipatePrompt returns null on Ctrl+C', () async {
      final terminal = _MockTerminal();
      final future = runAnticipatePrompt(
        AnticipateModel(prompt: 'Input: ', suggestions: ['foo', 'bar']),
        terminal,
        options: _opts,
      );
      final result = await _runWithInterrupt(terminal, future);
      expect(result, isNull);
    });

    // ── TextInputModel ───────────────────────────────────────────────────────

    test('runTextInputPrompt returns null on Ctrl+C', () async {
      final terminal = _MockTerminal();
      final future = runTextInputPrompt(
        TextInputModel(prompt: 'Input: '),
        terminal,
        options: _opts,
      );
      final result = await _runWithInterrupt(terminal, future);
      expect(result, isNull);
    });

    // ── TextAreaModel ────────────────────────────────────────────────────────

    test('runTextAreaPrompt returns null on Ctrl+C', () async {
      final terminal = _MockTerminal();
      final future = runTextAreaPrompt(
        TextAreaModel(),
        terminal,
        options: _optsAltScreen,
      );
      final result = await _runWithInterrupt(terminal, future);
      expect(result, isNull);
    });

    // ── WizardModel ──────────────────────────────────────────────────────────

    test('runWizardPrompt returns null on Ctrl+C', () async {
      final terminal = _MockTerminal();
      final future = runWizardPrompt(
        WizardModel(
          steps: [WizardStep.textInput(key: 'name', prompt: 'Name: ')],
        ),
        terminal,
        options: _opts,
      );
      final result = await _runWithInterrupt(terminal, future);
      expect(result, isNull);
    });

    // ── DataTableModel ───────────────────────────────────────────────────────

    test('runDataTablePrompt returns null on Ctrl+C', () async {
      final terminal = _MockTerminal();
      final future = runDataTablePrompt<String>(
        DataTableModel<String>(
          items: ['Alice', 'Bob'],
          columns: [Column(title: 'Name', width: 20)],
          rowBuilder: (s) => [s],
        ),
        terminal,
        options: _opts.copyWith(mouse: true),
      );
      final result = await _runWithInterrupt(terminal, future);
      expect(result, isNull);
    });

    // ── NumberInputModel ─────────────────────────────────────────────────────

    test('runNumberInputPrompt returns null on Ctrl+C', () async {
      final terminal = _MockTerminal();
      final future = runNumberInputPrompt(
        NumberInputModel(prompt: 'Number: '),
        terminal,
        options: _opts,
      );
      final result = await _runWithInterrupt(terminal, future);
      expect(result, isNull);
    });

    // ── SuggestModel ─────────────────────────────────────────────────────────

    test('runSuggestPrompt returns null on Ctrl+C', () async {
      final terminal = _MockTerminal();
      final future = runSuggestPrompt(
        SuggestModel(prompt: 'Input: ', options: ['foo', 'bar', 'baz']),
        terminal,
        options: _opts,
      );
      final result = await _runWithInterrupt(terminal, future);
      expect(result, isNull);
    });

    // ── SpinnerTask ──────────────────────────────────────────────────────────
    // The spinner wraps a non-nullable T; interrupt completes with
    // [ProgramCancelledError] rather than null.

    test('runSpinnerTask throws ProgramCancelledError on Ctrl+C', () async {
      final terminal = _MockTerminal();
      // Long-running task — still pending when Ctrl+C fires.
      final neverCompletes = Completer<String>();
      final future = runSpinnerTask<String>(
        message: 'Working…',
        task: () => neverCompletes.future,
        terminal: terminal,
        options: _opts,
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      terminal.sendCtrlC();
      await expectLater(
        future.timeout(const Duration(seconds: 2)),
        throwsA(isA<ProgramCancelledError>()),
      );
    });
  });
}
