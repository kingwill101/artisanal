import 'dart:async';

import '../style/color.dart';

/// Abstract terminal interface for all terminal operations.
///
/// This interface provides a unified API for terminal control used by both
/// static components and the TUI runtime. Implementations can target different
/// platforms or provide testing capabilities.
///
/// {@category Terminal}
///
/// {@macro artisanal_terminal_overview}
/// {@macro artisanal_terminal_raw_mode}
///
/// ```dart
/// // Use the standard implementation
/// final terminal = StdioTerminal();
///
/// // Basic operations
/// terminal.write('Hello');
/// terminal.writeln(' World');
/// ```
abstract class Terminal {
  // ─────────────────────────────────────────────────────────────────────────────
  // Terminal Information
  // ─────────────────────────────────────────────────────────────────────────────

  /// The terminal width in columns.
  int get width;

  /// The terminal height in rows.
  int get height;

  /// The terminal size as a record of (width, height).
  ({int width, int height}) get size => (width: width, height: height);

  /// Whether the terminal supports ANSI escape sequences.
  bool get supportsAnsi;

  /// Whether output is connected to a real terminal (vs piped/redirected).
  bool get isTerminal;

  /// The detected color profile of the terminal.
  ColorProfile get colorProfile;

  // ─────────────────────────────────────────────────────────────────────────────
  // Output Operations
  // ─────────────────────────────────────────────────────────────────────────────

  /// Writes text to the terminal without a trailing newline.
  void write(String text);

  /// Writes text to the terminal followed by a newline.
  void writeln([String text = '']);

  /// Flushes any buffered output.
  Future<void> flush();

  /// Queries the terminal for information by writing [query] and waiting for a response.
  ///
  /// Returns the response string, or `null` if the query timed out.
  ///
  /// This is intended for non-TUI use cases. In a TUI, use the message loop.
  Future<String?> query(
    String query, {
    Duration timeout = const Duration(seconds: 2),
  });

  // ─────────────────────────────────────────────────────────────────────────────
  // Cursor Visibility
  // ─────────────────────────────────────────────────────────────────────────────

  /// Hides the terminal cursor.
  void hideCursor();

  /// Shows the terminal cursor.
  void showCursor();

  /// Saves the current cursor position.
  void saveCursor();

  /// Restores the previously saved cursor position.
  void restoreCursor();

  // ─────────────────────────────────────────────────────────────────────────────
  // Cursor Movement
  // ─────────────────────────────────────────────────────────────────────────────

  /// Moves the cursor to the specified [row] and [col] (1-based).
  void moveCursor(int row, int col);

  /// Moves the cursor to home position (1, 1).
  void cursorHome();

  /// Moves the cursor up by [lines] rows.
  void cursorUp([int lines = 1]);

  /// Moves the cursor down by [lines] rows.
  void cursorDown([int lines = 1]);

  /// Moves the cursor right by [cols] columns.
  void cursorRight([int cols = 1]);

  /// Moves the cursor left by [cols] columns.
  void cursorLeft([int cols = 1]);

  /// Moves the cursor to the specified [col] on the current line (1-based).
  void cursorToColumn(int col);

  // ─────────────────────────────────────────────────────────────────────────────
  // Screen Control
  // ─────────────────────────────────────────────────────────────────────────────

  /// Clears the entire screen.
  void clearScreen();

  /// Clears from the cursor to the end of the screen.
  void clearToEnd();

  /// Clears from the cursor to the beginning of the screen.
  void clearToStart();

  /// Clears the current line.
  void clearLine();

  /// Clears from the cursor to the end of the line.
  void clearLineToEnd();

  /// Clears from the cursor to the beginning of the line.
  void clearLineToStart();

  /// Clears the specified number of lines above the cursor.
  void clearPreviousLines(int lines);

  /// Scrolls the screen up by [lines] rows.
  void scrollUp([int lines = 1]);

  /// Scrolls the screen down by [lines] rows.
  void scrollDown([int lines = 1]);

  // ─────────────────────────────────────────────────────────────────────────────
  // Alternate Screen Buffer
  // ─────────────────────────────────────────────────────────────────────────────

  /// Enters the alternate screen buffer (fullscreen mode).
  void enterAltScreen();

  /// Exits the alternate screen buffer.
  void exitAltScreen();

  /// Whether the terminal is currently in alternate screen mode.
  bool get isAltScreen;

  // ─────────────────────────────────────────────────────────────────────────────
  // Input Mode Control
  // ─────────────────────────────────────────────────────────────────────────────

  /// Enables raw mode (character-by-character input, no echo).
  ///
  /// Returns a [RawModeGuard] that can be used to restore the original mode.
  RawModeGuard enableRawMode();

  /// Disables raw mode and restores original terminal settings.
  void disableRawMode();

  /// Whether raw mode is currently enabled.
  bool get isRawMode;

  // ─────────────────────────────────────────────────────────────────────────────
  // Mouse Tracking
  // ─────────────────────────────────────────────────────────────────────────────

  /// Enables mouse tracking.
  ///
  /// When enabled, mouse events (clicks, motion, wheel) are reported as
  /// escape sequences that can be parsed from input.
  void enableMouse();

  /// Enables mouse cell motion tracking (clicks, wheel, drag).
  void enableMouseCellMotion();

  /// Enables mouse all motion tracking (includes hover events).
  void enableMouseAllMotion();

  /// Disables mouse tracking.
  void disableMouse();

  /// Whether mouse tracking is currently enabled.
  bool get isMouseEnabled;

  // ─────────────────────────────────────────────────────────────────────────────
  // Bracketed Paste Mode
  // ─────────────────────────────────────────────────────────────────────────────

  /// Enables bracketed paste mode.
  ///
  /// When enabled, pasted content is wrapped in escape sequences, allowing
  /// it to be distinguished from typed input.
  void enableBracketedPaste();

  /// Disables bracketed paste mode.
  void disableBracketedPaste();

  /// Whether bracketed paste mode is currently enabled.
  bool get isBracketedPasteEnabled;

  // ─────────────────────────────────────────────────────────────────────────────
  // Focus Reporting
  // ─────────────────────────────────────────────────────────────────────────────

  /// Enables focus reporting.
  ///
  /// When enabled, focus gain/loss events are reported as escape sequences.
  void enableFocusReporting();

  /// Disables focus reporting.
  void disableFocusReporting();

  // ─────────────────────────────────────────────────────────────────────────────
  // Window/Terminal Control
  // ─────────────────────────────────────────────────────────────────────────────

  /// Sets the terminal window title.
  void setTitle(String title);

  /// Sets the terminal progress bar (OSC 9;4).
  ///
  /// [state]: 0=none, 1=default, 2=error, 3=indeterminate, 4=warning
  /// [value]: 0-100
  void setProgressBar(int state, int value);

  /// Rings the terminal bell.
  void bell();

  /// Detects terminal capabilities for movement optimizations (e.g. hard tabs).
  ///
  /// Returns a record of (useTabs, useBackspace).
  ({bool useTabs, bool useBackspace}) optimizeMovements();

  // ─────────────────────────────────────────────────────────────────────────────
  // Input Stream (for TUI mode)
  // ─────────────────────────────────────────────────────────────────────────────

  /// Stream of raw input bytes from the terminal.
  ///
  /// This is primarily used by the TUI runtime for async input handling.
  /// For synchronous input, use [readByte] or [readLine].
  Stream<List<int>> get input;

  /// Reads a single byte from input (blocking).
  ///
  /// Returns -1 on EOF.
  int readByte();

  /// Reads a line of input (blocking).
  ///
  /// Returns null on EOF.
  String? readLine();

  // ─────────────────────────────────────────────────────────────────────────────
  // Lifecycle
  // ─────────────────────────────────────────────────────────────────────────────

  /// Disposes of terminal resources and restores original state.
  ///
  /// This should restore:
  /// - Cursor visibility
  /// - Raw mode
  /// - Alt screen
  /// - Mouse tracking
  /// - Bracketed paste
  void dispose();
}

/// A terminal that splits "control/input" from "display/output".
///
/// This is primarily used to support the Ultraviolet-style `(in/out)` vs
/// `(inTty/outTty)` split:
/// - **control**: raw mode, input stream, and input-reporting toggles (mouse,
///   bracketed paste, focus) + size probing
/// - **output**: screen drawing operations (cursor movement, clears, alt-screen,
///   etc.) and general writes
///
/// This enables workflows where stdin is redirected but `/dev/tty` is still
/// available for interactive input, while keeping output on the configured
/// output stream.
final class SplitTerminal implements Terminal {
  /// Creates a split terminal with separate [control] and [output] streams.
  SplitTerminal({required Terminal control, required Terminal output})
    : _control = control,
      _output = output;

  final Terminal _control;
  final Terminal _output;

  /// The terminal used for control sequences (cursor, mode switching, size).
  Terminal get control => _control;

  /// The terminal used for content output (screen drawing, writes).
  Terminal get output => _output;

  // ─────────────────────────────────────────────────────────────────────────────
  // Terminal Information
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  int get width => _control.width;

  @override
  int get height => _control.height;

  @override
  ({int width, int height}) get size => _control.size;

  @override
  bool get supportsAnsi => _output.supportsAnsi;

  @override
  bool get isTerminal => _output.isTerminal;

  @override
  ColorProfile get colorProfile => _output.colorProfile;

  // ─────────────────────────────────────────────────────────────────────────────
  // Output Operations
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  void write(String text) => _output.write(text);

  @override
  void writeln([String text = '']) => _output.writeln(text);

  @override
  Future<void> flush() => _output.flush();

  @override
  Future<String?> query(
    String query, {
    Duration timeout = const Duration(seconds: 2),
  }) => _control.query(query, timeout: timeout);

  // ─────────────────────────────────────────────────────────────────────────────
  // Cursor Visibility
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  void hideCursor() => _output.hideCursor();

  @override
  void showCursor() => _output.showCursor();

  @override
  void saveCursor() => _output.saveCursor();

  @override
  void restoreCursor() => _output.restoreCursor();

  // ─────────────────────────────────────────────────────────────────────────────
  // Cursor Movement
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  void moveCursor(int row, int col) => _output.moveCursor(row, col);

  @override
  void cursorHome() => _output.cursorHome();

  @override
  void cursorUp([int lines = 1]) => _output.cursorUp(lines);

  @override
  void cursorDown([int lines = 1]) => _output.cursorDown(lines);

  @override
  void cursorRight([int cols = 1]) => _output.cursorRight(cols);

  @override
  void cursorLeft([int cols = 1]) => _output.cursorLeft(cols);

  @override
  void cursorToColumn(int col) => _output.cursorToColumn(col);

  // ─────────────────────────────────────────────────────────────────────────────
  // Screen Control
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  void clearScreen() => _output.clearScreen();

  @override
  void clearToEnd() => _output.clearToEnd();

  @override
  void clearToStart() => _output.clearToStart();

  @override
  void clearLine() => _output.clearLine();

  @override
  void clearLineToEnd() => _output.clearLineToEnd();

  @override
  void clearLineToStart() => _output.clearLineToStart();

  @override
  void clearPreviousLines(int lines) => _output.clearPreviousLines(lines);

  @override
  void scrollUp([int lines = 1]) => _output.scrollUp(lines);

  @override
  void scrollDown([int lines = 1]) => _output.scrollDown(lines);

  // ─────────────────────────────────────────────────────────────────────────────
  // Alternate Screen Buffer
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  void enterAltScreen() => _output.enterAltScreen();

  @override
  void exitAltScreen() => _output.exitAltScreen();

  @override
  bool get isAltScreen => _output.isAltScreen;

  // ─────────────────────────────────────────────────────────────────────────────
  // Input Mode Control
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  RawModeGuard enableRawMode() => _control.enableRawMode();

  @override
  void disableRawMode() => _control.disableRawMode();

  @override
  bool get isRawMode => _control.isRawMode;

  // ─────────────────────────────────────────────────────────────────────────────
  // Mouse Tracking
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  void enableMouse() => _control.enableMouse();

  @override
  void enableMouseCellMotion() => _control.enableMouseCellMotion();

  @override
  void enableMouseAllMotion() => _control.enableMouseAllMotion();

  @override
  void disableMouse() => _control.disableMouse();

  @override
  bool get isMouseEnabled => _control.isMouseEnabled;

  // ─────────────────────────────────────────────────────────────────────────────
  // Bracketed Paste Mode
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  void enableBracketedPaste() => _control.enableBracketedPaste();

  @override
  void disableBracketedPaste() => _control.disableBracketedPaste();

  @override
  bool get isBracketedPasteEnabled => _control.isBracketedPasteEnabled;

  // ─────────────────────────────────────────────────────────────────────────────
  // Focus Reporting
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  void enableFocusReporting() => _control.enableFocusReporting();

  @override
  void disableFocusReporting() => _control.disableFocusReporting();

  // ─────────────────────────────────────────────────────────────────────────────
  // Window/Terminal Control
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  void setTitle(String title) => _control.setTitle(title);

  @override
  void setProgressBar(int state, int value) =>
      _control.setProgressBar(state, value);

  @override
  void bell() => _control.bell();

  @override
  ({bool useTabs, bool useBackspace}) optimizeMovements() =>
      _control.optimizeMovements();

  // ─────────────────────────────────────────────────────────────────────────────
  // Input Stream
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  Stream<List<int>> get input => _control.input;

  @override
  int readByte() => _control.readByte();

  @override
  String? readLine() => _control.readLine();

  // ─────────────────────────────────────────────────────────────────────────────
  // Lifecycle
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  void dispose() {
    // Best-effort: restore output and control independently.
    try {
      _output.dispose();
    } catch (_) {
      // Output may already be closed.
    }
    try {
      _control.dispose();
    } catch (_) {
      // Control may already be closed.
    }
  }
}

/// Guard object returned by [Terminal.enableRawMode].
///
/// Can be used to restore the original terminal mode.
class RawModeGuard {
  /// Creates a raw mode guard.
  RawModeGuard({
    required this.wasEchoMode,
    required this.wasLineMode,
    required void Function() restore,
  }) : _restore = restore;

  /// The original echo mode setting.
  final bool wasEchoMode;

  /// The original line mode setting.
  final bool wasLineMode;

  final void Function() _restore;

  /// Restores the original terminal mode.
  void restore() => _restore();
}

/// A terminal that captures output to a string buffer (for testing).
///
/// This implementation does not interact with any real terminal and is
/// useful for unit testing components that use terminal operations.
class StringTerminal implements Terminal {
  /// Creates a string terminal with optional configuration.
  StringTerminal({
    this.terminalWidth = 80,
    this.terminalHeight = 24,
    this.ansiSupport = true,
  });

  /// The simulated terminal width.
  final int terminalWidth;

  /// The simulated terminal height.
  final int terminalHeight;

  /// Whether to simulate ANSI support.
  final bool ansiSupport;

  /// The captured output.
  final StringBuffer buffer = StringBuffer();

  /// List of operations performed (for testing).
  final List<String> operations = [];

  // State tracking
  bool _rawModeEnabled = false;
  bool _altScreenEnabled = false;
  bool _mouseEnabled = false;
  bool _bracketedPasteEnabled = false;

  // Input simulation
  final _inputController = StreamController<List<int>>.broadcast();
  final List<int> _inputQueue = [];

  /// Clears the output buffer and operation log.
  void clear() {
    buffer.clear();
    operations.clear();
  }

  /// The captured output as a string.
  String get output => buffer.toString();

  /// Simulates input by adding bytes to the input queue.
  void simulateInput(List<int> bytes) {
    _inputQueue.addAll(bytes);
    _inputController.add(bytes);
  }

  /// Simulates typing a string.
  void simulateTyping(String text) {
    simulateInput(text.codeUnits);
  }

  @override
  int get width => terminalWidth;

  @override
  int get height => terminalHeight;

  @override
  ({int width, int height}) get size => (width: width, height: height);

  @override
  bool get supportsAnsi => ansiSupport;

  @override
  bool get isTerminal => true;

  @override
  ColorProfile get colorProfile => ColorProfile.trueColor;

  @override
  void write(String text) {
    buffer.write(text);
    operations.add('write: $text');
  }

  @override
  void writeln([String text = '']) {
    buffer.writeln(text);
    operations.add('writeln: $text');
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
    operations.add('query: $query');
    return null;
  }

  @override
  void hideCursor() {
    operations.add('hideCursor');
  }

  @override
  void showCursor() {
    operations.add('showCursor');
  }

  @override
  void saveCursor() => operations.add('saveCursor');

  @override
  void restoreCursor() => operations.add('restoreCursor');

  @override
  void moveCursor(int row, int col) => operations.add('moveCursor($row, $col)');

  @override
  void cursorHome() => operations.add('cursorHome');

  @override
  void cursorUp([int lines = 1]) => operations.add('cursorUp($lines)');

  @override
  void cursorDown([int lines = 1]) => operations.add('cursorDown($lines)');

  @override
  void cursorRight([int cols = 1]) => operations.add('cursorRight($cols)');

  @override
  void cursorLeft([int cols = 1]) => operations.add('cursorLeft($cols)');

  @override
  void cursorToColumn(int col) => operations.add('cursorToColumn($col)');

  @override
  void clearScreen() => operations.add('clearScreen');

  @override
  void clearToEnd() => operations.add('clearToEnd');

  @override
  void clearToStart() => operations.add('clearToStart');

  @override
  void clearLine() => operations.add('clearLine');

  @override
  void clearLineToEnd() => operations.add('clearLineToEnd');

  @override
  void clearLineToStart() => operations.add('clearLineToStart');

  @override
  void clearPreviousLines(int lines) =>
      operations.add('clearPreviousLines($lines)');

  @override
  void scrollUp([int lines = 1]) => operations.add('scrollUp($lines)');

  @override
  void scrollDown([int lines = 1]) => operations.add('scrollDown($lines)');

  @override
  void enterAltScreen() {
    _altScreenEnabled = true;
    operations.add('enterAltScreen');
  }

  @override
  void exitAltScreen() {
    _altScreenEnabled = false;
    operations.add('exitAltScreen');
  }

  @override
  bool get isAltScreen => _altScreenEnabled;

  @override
  RawModeGuard enableRawMode() {
    _rawModeEnabled = true;
    operations.add('enableRawMode');
    return RawModeGuard(
      wasEchoMode: true,
      wasLineMode: true,
      restore: disableRawMode,
    );
  }

  @override
  void disableRawMode() {
    _rawModeEnabled = false;
    operations.add('disableRawMode');
  }

  @override
  bool get isRawMode => _rawModeEnabled;

  @override
  void enableMouse() {
    _mouseEnabled = true;
    operations.add('enableMouse');
  }

  @override
  void enableMouseCellMotion() {
    _mouseEnabled = true;
    operations.add('enableMouseCellMotion');
  }

  @override
  void enableMouseAllMotion() {
    _mouseEnabled = true;
    operations.add('enableMouseAllMotion');
  }

  @override
  void disableMouse() {
    _mouseEnabled = false;
    operations.add('disableMouse');
  }

  @override
  bool get isMouseEnabled => _mouseEnabled;

  @override
  void enableBracketedPaste() {
    _bracketedPasteEnabled = true;
    operations.add('enableBracketedPaste');
  }

  @override
  void disableBracketedPaste() {
    _bracketedPasteEnabled = false;
    operations.add('disableBracketedPaste');
  }

  @override
  bool get isBracketedPasteEnabled => _bracketedPasteEnabled;

  @override
  void enableFocusReporting() => operations.add('enableFocusReporting');

  @override
  void disableFocusReporting() => operations.add('disableFocusReporting');

  @override
  void setTitle(String title) => operations.add('setTitle($title)');

  @override
  void setProgressBar(int state, int value) =>
      operations.add('setProgressBar($state, $value)');

  @override
  void bell() => operations.add('bell');

  @override
  ({bool useTabs, bool useBackspace}) optimizeMovements() {
    return (useTabs: false, useBackspace: true);
  }

  @override
  Stream<List<int>> get input => _inputController.stream;

  @override
  int readByte() {
    if (_inputQueue.isEmpty) return -1;
    return _inputQueue.removeAt(0);
  }

  @override
  String? readLine() {
    if (_inputQueue.isEmpty) return null;
    final lineEnd = _inputQueue.indexOf(10); // newline
    if (lineEnd == -1) {
      final result = String.fromCharCodes(_inputQueue);
      _inputQueue.clear();
      return result;
    }
    final result = String.fromCharCodes(_inputQueue.sublist(0, lineEnd));
    _inputQueue.removeRange(0, lineEnd + 1);
    return result;
  }

  @override
  void dispose() {
    operations.add('dispose');
    _inputController.close();
  }
}
