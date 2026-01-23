import 'dart:async';
import 'dart:io' as io;

import '../colorprofile/detect.dart' as cp_detect;
import '../style/color.dart';
import 'ansi.dart';
import 'stdin_stream.dart';

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
  SplitTerminal({required Terminal control, required Terminal output})
    : _control = control,
      _output = output;

  final Terminal _control;
  final Terminal _output;

  Terminal get control => _control;
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

/// Standard terminal implementation using dart:io.
///
/// Works on Unix-like systems (Linux, macOS) and Windows.
class StdioTerminal implements Terminal {
  /// Creates a terminal using the standard I/O streams.
  ///
  /// If [stdout] or [stdin] are not provided, uses the process's
  /// standard streams.
  StdioTerminal({io.Stdout? stdout, io.Stdin? stdin})
    : _stdout = stdout ?? io.stdout,
      _stdin = stdin ?? io.stdin;

  final io.Stdout _stdout;
  final io.Stdin _stdin;

  // Stdout flush in Dart binds the underlying StreamSink; any concurrent write
  // while a flush is in flight will throw:
  //   StateError: Bad state: StreamSink is bound to a stream
  //
  // We coalesce and serialize flushes, and buffer writes that happen while a
  // flush is in progress so TUI control messages (e.g. resize handlers) cannot
  // crash the program.
  Future<void>? _stdoutFlushInFlight;
  final StringBuffer _stdoutPending = StringBuffer();
  int _stdoutPendingLen = 0;

  // State tracking
  bool _rawModeEnabled = false;
  bool _altScreenEnabled = false;
  bool _mouseEnabled = false;
  bool _bracketedPasteEnabled = false;

  // Original terminal settings
  bool? _originalEchoMode;
  bool? _originalLineMode;

  // Input stream management
  StreamController<List<int>>? _inputController;
  StreamSubscription<List<int>>? _inputSubscription;

  // ─────────────────────────────────────────────────────────────────────────────
  // Terminal Information
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  int get width {
    try {
      return _stdout.hasTerminal ? _stdout.terminalColumns : 80;
    } catch (_) {
      // Fallback when stdout is not available (e.g., piped output).
      return 80;
    }
  }

  @override
  int get height {
    try {
      return _stdout.hasTerminal ? _stdout.terminalLines : 24;
    } catch (_) {
      // Fallback when stdout is not available.
      return 24;
    }
  }

  @override
  ({int width, int height}) get size => (width: width, height: height);

  @override
  bool get supportsAnsi {
    try {
      return _stdout.supportsAnsiEscapes;
    } catch (_) {
      // Assume no ANSI support when stdout is not available.
      return false;
    }
  }

  @override
  bool get isTerminal {
    try {
      return _stdout.hasTerminal;
    } catch (_) {
      // Not a terminal when stdout is not available.
      return false;
    }
  }

  @override
  ColorProfile get colorProfile =>
      ColorProfileConverter.fromProfile(cp_detect.detectForSink(_stdout));

  // ─────────────────────────────────────────────────────────────────────────────
  // Output Operations
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  void write(String text) {
    if (text.isEmpty) return;
    if (_stdoutFlushInFlight != null) {
      _stdoutPending.write(text);
      _stdoutPendingLen += text.length;
      return;
    }
    try {
      _stdout.write(text);
    } on StateError catch (e) {
      if (_isStdoutBoundToStream(e)) {
        _stdoutPending.write(text);
        _stdoutPendingLen += text.length;
        unawaited(flush());
        return;
      }
      rethrow;
    }
  }

  @override
  void writeln([String text = '']) =>
      write('$text${io.Platform.lineTerminator}');

  @override
  Future<void> flush() {
    final existing = _stdoutFlushInFlight;
    if (existing != null) return existing;

    final f = _flushStdoutAll();
    _stdoutFlushInFlight = f.whenComplete(() {
      _stdoutFlushInFlight = null;
    });
    return _stdoutFlushInFlight!;
  }

  @override
  Future<String?> query(
    String query, {
    Duration timeout = const Duration(seconds: 2),
  }) async {
    if (!isTerminal) return null;

    final wasRaw = _rawModeEnabled;
    if (!wasRaw) enableRawMode();

    try {
      write(query);
      await flush();

      final completer = Completer<String?>();
      final buffer = StringBuffer();

      final timer = Timer(timeout, () {
        if (!completer.isCompleted) completer.complete(null);
      });

      final sub = input.listen((data) {
        buffer.write(String.fromCharCodes(data));
        final s = buffer.toString();

        // Common terminal response terminators:
        // - BEL (0x07)
        // - ST (ESC \)
        // - DA1 response ends with 'c' (e.g. ESC [ ? 62 ; 1 c)
        if (s.contains('\x07') || s.contains('\x1b\\') || s.endsWith('c')) {
          if (!completer.isCompleted) completer.complete(s);
        }
      });

      final result = await completer.future;
      timer.cancel();
      await sub.cancel();
      return result;
    } finally {
      if (!wasRaw) disableRawMode();
    }
  }

  static bool _isStdoutBoundToStream(StateError e) =>
      e.message.toString().contains('StreamSink is bound to a stream');

  Future<void> _flushStdoutAll() async {
    // Keep flushing until no more writes arrived during the previous flush.
    while (true) {
      if (_stdoutPendingLen != 0) {
        final pending = _stdoutPending.toString();
        _stdoutPending.clear();
        _stdoutPendingLen = 0;

        while (true) {
          try {
            _stdout.write(pending);
            break;
          } on StateError catch (e) {
            if (_isStdoutBoundToStream(e)) {
              await Future<void>.delayed(Duration.zero);
              continue;
            }
            rethrow;
          }
        }
      }

      while (true) {
        try {
          await _stdout.flush();
          break;
        } on StateError catch (e) {
          if (_isStdoutBoundToStream(e)) {
            await Future<void>.delayed(Duration.zero);
            continue;
          }
          rethrow;
        }
      }

      if (_stdoutPendingLen == 0) return;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Cursor Visibility
  // ─────────────────────────────────────────────────────────────────────────────

  // Cursor state tracking
  bool _cursorVisible = true;

  @override
  void hideCursor() {
    if (!_cursorVisible || !supportsAnsi) return;
    write(Ansi.cursorHide);
    _cursorVisible = false;
  }

  @override
  void showCursor() {
    if (_cursorVisible || !supportsAnsi) return;
    write(Ansi.cursorShow);
    _cursorVisible = true;
  }

  @override
  void saveCursor() {
    if (supportsAnsi) write(Ansi.cursorSave);
  }

  @override
  void restoreCursor() {
    if (supportsAnsi) write(Ansi.cursorRestore);
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Cursor Movement
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  void moveCursor(int row, int col) {
    if (supportsAnsi) write(Ansi.cursorTo(row, col));
  }

  @override
  void cursorHome() {
    if (supportsAnsi) write(Ansi.cursorHome);
  }

  @override
  void cursorUp([int lines = 1]) {
    if (supportsAnsi) write(Ansi.cursorUpBy(lines));
  }

  @override
  void cursorDown([int lines = 1]) {
    if (supportsAnsi) write(Ansi.cursorDownBy(lines));
  }

  @override
  void cursorRight([int cols = 1]) {
    if (supportsAnsi) write(Ansi.cursorRightBy(cols));
  }

  @override
  void cursorLeft([int cols = 1]) {
    if (supportsAnsi) write(Ansi.cursorLeftBy(cols));
  }

  @override
  void cursorToColumn(int col) {
    if (supportsAnsi) write(Ansi.cursorToColumn(col));
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Screen Control
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  void clearScreen() {
    if (!supportsAnsi) return;
    write(Ansi.clearScreen);
    cursorHome();
  }

  @override
  void clearToEnd() {
    if (supportsAnsi) write(Ansi.clearScreenToEnd);
  }

  @override
  void clearToStart() {
    if (supportsAnsi) write(Ansi.clearScreenToStart);
  }

  @override
  void clearLine() {
    if (supportsAnsi) write('${Ansi.clearLine}\r');
  }

  @override
  void clearLineToEnd() {
    if (supportsAnsi) write(Ansi.clearLineToEnd);
  }

  @override
  void clearLineToStart() {
    if (supportsAnsi) write(Ansi.clearLineToStart);
  }

  @override
  void clearPreviousLines(int lines) {
    if (!supportsAnsi) return;
    for (var i = 0; i < lines; i++) {
      cursorUp();
      clearLine();
    }
  }

  @override
  void scrollUp([int lines = 1]) {
    if (supportsAnsi) write(Ansi.scrollUpBy(lines));
  }

  @override
  void scrollDown([int lines = 1]) {
    if (supportsAnsi) write(Ansi.scrollDownBy(lines));
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Alternate Screen Buffer
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  void enterAltScreen() {
    if (_altScreenEnabled || !supportsAnsi) return;
    write(Ansi.altScreenEnter);
    _altScreenEnabled = true;
  }

  @override
  void exitAltScreen() {
    if (!_altScreenEnabled || !supportsAnsi) return;
    write(Ansi.altScreenExit);
    _altScreenEnabled = false;
  }

  @override
  bool get isAltScreen => _altScreenEnabled;

  // ─────────────────────────────────────────────────────────────────────────────
  // Input Mode Control
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  RawModeGuard enableRawMode() {
    bool wasEchoMode = true;
    bool wasLineMode = true;

    if (!_rawModeEnabled) {
      try {
        _originalEchoMode = _stdin.echoMode;
        _originalLineMode = _stdin.lineMode;
        wasEchoMode = _originalEchoMode ?? true;
        wasLineMode = _originalLineMode ?? true;
        _stdin.echoMode = false;
        _stdin.lineMode = false;
        _rawModeEnabled = true;
      } catch (_) {
        // Terminal doesn't support raw mode (e.g., piped input)
      }
    }

    return RawModeGuard(
      wasEchoMode: wasEchoMode,
      wasLineMode: wasLineMode,
      restore: disableRawMode,
    );
  }

  @override
  void disableRawMode() {
    if (!_rawModeEnabled) return;

    try {
      if (_originalEchoMode != null) {
        _stdin.echoMode = _originalEchoMode!;
      }
      if (_originalLineMode != null) {
        _stdin.lineMode = _originalLineMode!;
      }
      _rawModeEnabled = false;
    } catch (_) {
      // Ignore errors during restoration
    }
  }

  @override
  bool get isRawMode => _rawModeEnabled;

  // ─────────────────────────────────────────────────────────────────────────────
  // Mouse Tracking
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  void enableMouse() {
    if (_mouseEnabled || !supportsAnsi) return;
    // Enable normal mouse tracking + button events + SGR extended mode
    write(Ansi.mouseEnableNormal);
    write(Ansi.mouseEnableButton);
    write(Ansi.mouseEnableSgr);
    _mouseEnabled = true;
  }

  @override
  void enableMouseCellMotion() {
    enableMouse();
  }

  @override
  void enableMouseAllMotion() {
    if (!supportsAnsi) return;
    // All motion includes hover events
    write(Ansi.mouseEnableAny);
    enableMouse();
  }

  @override
  void disableMouse() {
    if (!_mouseEnabled || !supportsAnsi) return;
    write(Ansi.mouseDisableSgr);
    write(Ansi.mouseDisableButton);
    write(Ansi.mouseDisableNormal);
    write(Ansi.mouseDisableAny);
    _mouseEnabled = false;
  }

  @override
  bool get isMouseEnabled => _mouseEnabled;

  // ─────────────────────────────────────────────────────────────────────────────
  // Bracketed Paste Mode
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  void enableBracketedPaste() {
    if (_bracketedPasteEnabled || !supportsAnsi) return;
    write(Ansi.bracketedPasteEnable);
    _bracketedPasteEnabled = true;
  }

  @override
  void disableBracketedPaste() {
    if (!_bracketedPasteEnabled || !supportsAnsi) return;
    write(Ansi.bracketedPasteDisable);
    _bracketedPasteEnabled = false;
  }

  @override
  bool get isBracketedPasteEnabled => _bracketedPasteEnabled;

  // ─────────────────────────────────────────────────────────────────────────────
  // Focus Reporting
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  void enableFocusReporting() {
    if (supportsAnsi) write(Ansi.focusEnable);
  }

  @override
  void disableFocusReporting() {
    if (supportsAnsi) write(Ansi.focusDisable);
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Window/Terminal Control
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  void setTitle(String title) {
    if (supportsAnsi) write(Ansi.setTitle(title));
  }

  @override
  void setProgressBar(int state, int value) {
    if (supportsAnsi) write(Ansi.setProgressBar(state, value));
  }

  @override
  void bell() => write(Ansi.bell);

  @override
  ({bool useTabs, bool useBackspace}) optimizeMovements() {
    // StdioTerminal defaults to safe values.
    return (useTabs: false, useBackspace: true);
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Input Stream
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  Stream<List<int>> get input {
    _inputController ??= StreamController<List<int>>.broadcast(
      onListen: _startInputListener,
      onCancel: _stopInputListener,
    );
    return _inputController!.stream;
  }

  void _startInputListener() {
    final Stream<List<int>> stream;
    if (identical(_stdin, io.stdin)) {
      stream = sharedStdinStream;
    } else {
      stream = _stdin;
    }

    _inputSubscription ??= stream.listen(
      (data) => _inputController?.add(data),
      onError: (error) => _inputController?.addError(error),
      cancelOnError: false,
    );
  }

  void _stopInputListener() {
    _inputSubscription?.cancel();
    _inputSubscription = null;
  }

  @override
  int readByte() => _stdin.readByteSync();

  @override
  String? readLine() => _stdin.readLineSync();

  // ─────────────────────────────────────────────────────────────────────────────
  // Lifecycle
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  void dispose() {
    // Restore terminal state in reverse order of enabling
    if (_bracketedPasteEnabled) disableBracketedPaste();
    if (_mouseEnabled) disableMouse();
    if (!_cursorVisible) showCursor();
    if (_altScreenEnabled) exitAltScreen();
    if (_rawModeEnabled) disableRawMode();

    // Stop input listener
    _stopInputListener();
    _inputController?.close();
    _inputController = null;
  }
}

/// POSIX `/dev/tty` terminal implementation.
///
/// This is a best-effort port of Ultraviolet's `OpenTTY` behavior for cases
/// where stdin/stdout are redirected but the process still has access to a
/// controlling TTY.
///
/// Notes:
/// - Uses `/dev/tty` for input and output.
/// - Uses `stty` to toggle raw mode and query size.
/// - If any operation fails, it falls back to safe defaults (80x24, no-op raw).
final class TtyTerminal implements Terminal {
  TtyTerminal._(this._ttyPath, this._tty, {io.IOSink? output})
    : _out = output ?? _tty.openWrite(),
      _supportsAnsi = _envSupportsAnsi();

  static const String _defaultTtyPath = '/dev/tty';

  final String _ttyPath;
  final io.File _tty;
  final io.IOSink _out;
  final bool _supportsAnsi;

  // Output flush serialization.
  Future<void>? _flushInFlight;
  final StringBuffer _pending = StringBuffer();
  int _pendingLen = 0;

  // State tracking (mirrors StdioTerminal behavior).
  bool _rawModeEnabled = false;
  bool _altScreenEnabled = false;
  bool _mouseEnabled = false;
  bool _bracketedPasteEnabled = false;

  // stty-mode snapshot for raw mode restore.
  String? _sttySavedMode;

  // Input stream management
  StreamController<List<int>>? _inputController;
  StreamSubscription<List<int>>? _inputSubscription;

  // Blocking read support (best-effort).
  io.RandomAccessFile? _raf;
  final List<int> _lineBuf = <int>[];

  /// Attempts to open `/dev/tty` and returns a [TtyTerminal], or `null` if not
  /// available on this platform.
  static TtyTerminal? tryOpen({
    String path = _defaultTtyPath,
    io.IOSink? output,
  }) {
    try {
      if (io.Platform.isWindows) return null;
      final tty = io.File(path);
      if (!tty.existsSync()) return null;

      // If output is provided, we don't strictly need to be able to open tty
      // for write, but we usually want to verify it's a valid TTY we can
      // control. stty will fail if it's not a TTY.
      if (output == null) {
        final sink = tty.openWrite();
        sink.close();
      }

      return TtyTerminal._(path, tty, output: output);
    } catch (_) {
      return null;
    }
  }

  static bool _envSupportsAnsi() {
    final term = io.Platform.environment['TERM'] ?? '';
    if (term.isEmpty) return true;
    return term.toLowerCase() != 'dumb';
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Terminal Information
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  int get width {
    final s = _sttySize();
    return s?.$1 ?? 80;
  }

  @override
  int get height {
    final s = _sttySize();
    return s?.$2 ?? 24;
  }

  @override
  ({int width, int height}) get size => (width: width, height: height);

  @override
  bool get supportsAnsi => _supportsAnsi;

  @override
  bool get isTerminal => true;

  @override
  ColorProfile get colorProfile => ColorProfileConverter.fromProfile(
    cp_detect.detectForSink(_out, forceIsTty: true),
  );

  // ─────────────────────────────────────────────────────────────────────────────
  // Output Operations
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  void write(String text) {
    if (text.isEmpty) return;
    if (_flushInFlight != null) {
      _pending.write(text);
      _pendingLen += text.length;
      return;
    }
    try {
      _out.write(text);
    } on StateError catch (e) {
      if (_isSinkBoundToStream(e)) {
        _pending.write(text);
        _pendingLen += text.length;
        unawaited(flush());
        return;
      }
      rethrow;
    }
  }

  @override
  void writeln([String text = '']) =>
      write('$text${io.Platform.lineTerminator}');

  @override
  Future<void> flush() {
    final existing = _flushInFlight;
    if (existing != null) return existing;

    final f = _flushAll();
    _flushInFlight = f.whenComplete(() {
      _flushInFlight = null;
    });
    return _flushInFlight!;
  }

  @override
  Future<String?> query(
    String query, {
    Duration timeout = const Duration(seconds: 2),
  }) async {
    final wasRaw = _rawModeEnabled;
    if (!wasRaw) enableRawMode();

    try {
      write(query);
      await flush();

      final completer = Completer<String?>();
      final buffer = StringBuffer();

      final timer = Timer(timeout, () {
        if (!completer.isCompleted) completer.complete(null);
      });

      final sub = input.listen((data) {
        buffer.write(String.fromCharCodes(data));
        final s = buffer.toString();

        if (s.contains('\x07') || s.contains('\x1b\\') || s.endsWith('c')) {
          if (!completer.isCompleted) completer.complete(s);
        }
      });

      final result = await completer.future;
      timer.cancel();
      await sub.cancel();
      return result;
    } finally {
      if (!wasRaw) disableRawMode();
    }
  }

  static bool _isSinkBoundToStream(StateError e) =>
      e.message.toString().contains('StreamSink is bound to a stream');

  Future<void> _flushAll() async {
    // Keep flushing until no more writes arrived during the previous flush.
    while (true) {
      if (_pendingLen != 0) {
        final pending = _pending.toString();
        _pending.clear();
        _pendingLen = 0;

        while (true) {
          try {
            _out.write(pending);
            break;
          } on StateError catch (e) {
            if (_isSinkBoundToStream(e)) {
              await Future<void>.delayed(Duration.zero);
              continue;
            }
            rethrow;
          }
        }
      }

      while (true) {
        try {
          await _out.flush();
          break;
        } on StateError catch (e) {
          if (_isSinkBoundToStream(e)) {
            await Future<void>.delayed(Duration.zero);
            continue;
          }
          rethrow;
        }
      }

      if (_pendingLen == 0) return;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Cursor Visibility
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  void hideCursor() {
    if (supportsAnsi) write(Ansi.cursorHide);
  }

  @override
  void showCursor() {
    if (supportsAnsi) write(Ansi.cursorShow);
  }

  @override
  void saveCursor() {
    if (supportsAnsi) write(Ansi.cursorSave);
  }

  @override
  void restoreCursor() {
    if (supportsAnsi) write(Ansi.cursorRestore);
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Cursor Movement
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  void moveCursor(int row, int col) {
    if (supportsAnsi) write(Ansi.cursorTo(row, col));
  }

  @override
  void cursorHome() {
    if (supportsAnsi) write(Ansi.cursorHome);
  }

  @override
  void cursorUp([int lines = 1]) {
    if (!supportsAnsi) return;
    if (lines <= 1) return write(Ansi.cursorUp);
    write(Ansi.cursorUpBy(lines));
  }

  @override
  void cursorDown([int lines = 1]) {
    if (!supportsAnsi) return;
    if (lines <= 1) return write(Ansi.cursorDown);
    write(Ansi.cursorDownBy(lines));
  }

  @override
  void cursorRight([int cols = 1]) {
    if (!supportsAnsi) return;
    if (cols <= 1) return write(Ansi.cursorRight);
    write(Ansi.cursorRightBy(cols));
  }

  @override
  void cursorLeft([int cols = 1]) {
    if (!supportsAnsi) return;
    if (cols <= 1) return write(Ansi.cursorLeft);
    write(Ansi.cursorLeftBy(cols));
  }

  @override
  void cursorToColumn(int col) {
    if (supportsAnsi) write(Ansi.cursorToColumn(col));
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Screen Control
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  void clearScreen() {
    if (supportsAnsi) write(Ansi.clearScreen);
  }

  @override
  void clearToEnd() {
    if (supportsAnsi) write(Ansi.clearScreenToEnd);
  }

  @override
  void clearToStart() {
    if (supportsAnsi) write(Ansi.clearScreenToStart);
  }

  @override
  void clearLine() {
    if (supportsAnsi) write('${Ansi.clearLine}\r');
  }

  @override
  void clearLineToEnd() {
    if (supportsAnsi) write(Ansi.clearLineToEnd);
  }

  @override
  void clearLineToStart() {
    if (supportsAnsi) write(Ansi.clearLineToStart);
  }

  @override
  void clearPreviousLines(int lines) {
    if (!supportsAnsi) return;
    if (lines <= 0) return;
    for (var i = 0; i < lines; i++) {
      clearLine();
      if (i < lines - 1) write(Ansi.cursorUp);
    }
    cursorToColumn(1);
  }

  @override
  void scrollUp([int lines = 1]) {
    if (!supportsAnsi) return;
    if (lines <= 1) return write(Ansi.scrollUp);
    write(Ansi.scrollUpBy(lines));
  }

  @override
  void scrollDown([int lines = 1]) {
    if (!supportsAnsi) return;
    if (lines <= 1) return write(Ansi.scrollDown);
    write(Ansi.scrollDownBy(lines));
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Alternate Screen Buffer
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  void enterAltScreen() {
    if (_altScreenEnabled || !supportsAnsi) return;
    write(Ansi.altScreenEnter);
    _altScreenEnabled = true;
  }

  @override
  void exitAltScreen() {
    if (!_altScreenEnabled || !supportsAnsi) return;
    write(Ansi.altScreenExit);
    _altScreenEnabled = false;
  }

  @override
  bool get isAltScreen => _altScreenEnabled;

  // ─────────────────────────────────────────────────────────────────────────────
  // Input Mode Control
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  RawModeGuard enableRawMode() {
    if (_rawModeEnabled) {
      return RawModeGuard(
        wasEchoMode: false,
        wasLineMode: false,
        restore: () {},
      );
    }

    _sttySavedMode ??= _sttyGetMode();
    _sttySetRaw();
    _rawModeEnabled = true;

    return RawModeGuard(
      wasEchoMode: false,
      wasLineMode: false,
      restore: disableRawMode,
    );
  }

  @override
  void disableRawMode() {
    if (!_rawModeEnabled) return;
    _rawModeEnabled = false;
    final mode = _sttySavedMode;
    if (mode != null && mode.isNotEmpty) {
      _sttySetMode(mode);
    } else {
      _sttySane();
    }
  }

  @override
  bool get isRawMode => _rawModeEnabled;

  // ─────────────────────────────────────────────────────────────────────────────
  // Mouse Tracking
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  void enableMouse() => enableMouseCellMotion();

  @override
  void enableMouseCellMotion() {
    if (_mouseEnabled || !supportsAnsi) return;
    write(Ansi.mouseEnableNormal);
    write(Ansi.mouseEnableButton);
    write(Ansi.mouseEnableSgr);
    _mouseEnabled = true;
  }

  @override
  void enableMouseAllMotion() {
    if (_mouseEnabled || !supportsAnsi) return;
    write(Ansi.mouseEnableNormal);
    write(Ansi.mouseEnableAny);
    write(Ansi.mouseEnableSgr);
    _mouseEnabled = true;
  }

  @override
  void disableMouse() {
    if (!_mouseEnabled || !supportsAnsi) return;
    write(Ansi.mouseDisableNormal);
    write(Ansi.mouseDisableButton);
    write(Ansi.mouseDisableAny);
    write(Ansi.mouseDisableSgr);
    _mouseEnabled = false;
  }

  @override
  bool get isMouseEnabled => _mouseEnabled;

  // ─────────────────────────────────────────────────────────────────────────────
  // Bracketed Paste Mode
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  void enableBracketedPaste() {
    if (_bracketedPasteEnabled || !supportsAnsi) return;
    write(Ansi.bracketedPasteEnable);
    _bracketedPasteEnabled = true;
  }

  @override
  void disableBracketedPaste() {
    if (!_bracketedPasteEnabled || !supportsAnsi) return;
    write(Ansi.bracketedPasteDisable);
    _bracketedPasteEnabled = false;
  }

  @override
  bool get isBracketedPasteEnabled => _bracketedPasteEnabled;

  // ─────────────────────────────────────────────────────────────────────────────
  // Focus Reporting
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  void enableFocusReporting() {
    if (supportsAnsi) write(Ansi.focusEnable);
  }

  @override
  void disableFocusReporting() {
    if (supportsAnsi) write(Ansi.focusDisable);
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Window/Terminal Control
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  void setTitle(String title) {
    if (supportsAnsi) write(Ansi.setTitle(title));
  }

  @override
  void setProgressBar(int state, int value) {
    if (supportsAnsi) write(Ansi.setProgressBar(state, value));
  }

  @override
  void bell() => write(Ansi.bell);

  @override
  ({bool useTabs, bool useBackspace}) optimizeMovements() {
    final out = _runStty(['-a']);
    if (out == null || out.exitCode != 0) {
      return (useTabs: false, useBackspace: true);
    }

    final s = (out.stdout ?? '').toString();
    // tab0 means no tab expansion (hard tabs supported).
    // tabs is often an alias for tab0 on some systems.
    final useTabs = s.contains('tab0') || s.contains(' tabs');
    // bs0 means no backspace expansion.
    final useBackspace = s.contains('bs0') || !s.contains('-echoe');

    return (useTabs: useTabs, useBackspace: useBackspace);
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Input Stream
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  Stream<List<int>> get input {
    _inputController ??= StreamController<List<int>>.broadcast(
      onListen: _startInputListener,
      onCancel: _stopInputListener,
    );
    return _inputController!.stream;
  }

  void _startInputListener() {
    _inputSubscription ??= _tty.openRead().listen(
      (data) => _inputController?.add(data),
      onError: (error) => _inputController?.addError(error),
      cancelOnError: false,
    );
  }

  void _stopInputListener() {
    _inputSubscription?.cancel();
    _inputSubscription = null;
  }

  @override
  int readByte() {
    try {
      _raf ??= _tty.openSync(mode: io.FileMode.read);
      return _raf!.readByteSync();
    } catch (_) {
      return -1;
    }
  }

  @override
  String? readLine() {
    // Best-effort, blocking line read from the tty.
    try {
      while (true) {
        final b = readByte();
        if (b < 0) {
          if (_lineBuf.isEmpty) return null;
          final s = io.systemEncoding.decode(_lineBuf);
          _lineBuf.clear();
          return s;
        }
        if (b == 0x0a /* \\n */ ) {
          final s = io.systemEncoding.decode(_lineBuf);
          _lineBuf.clear();
          return s;
        }
        if (b != 0x0d /* \\r */ ) _lineBuf.add(b);
      }
    } catch (_) {
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Lifecycle
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  void dispose() {
    if (_bracketedPasteEnabled) disableBracketedPaste();
    if (_mouseEnabled) disableMouse();
    if (_altScreenEnabled) exitAltScreen();
    if (_rawModeEnabled) disableRawMode();

    _stopInputListener();
    _inputController?.close();
    _inputController = null;

    try {
      _raf?.closeSync();
    } catch (_) {
      // File handle may already be closed.
    }
    _raf = null;

    try {
      _out.close();
    } catch (_) {
      // Output sink may already be closed.
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // stty helpers (best-effort)
  // ─────────────────────────────────────────────────────────────────────────────

  (int width, int height)? _sttySize() {
    final out = _runStty(['size']);
    if (out == null || out.exitCode != 0) return null;
    final s = (out.stdout ?? '').toString().trim();
    final parts = s.split(RegExp(r'\\s+'));
    if (parts.length != 2) return null;
    final rows = int.tryParse(parts[0]);
    final cols = int.tryParse(parts[1]);
    if (rows == null || cols == null) return null;
    return (cols, rows);
  }

  String? _sttyGetMode() {
    final out = _runStty(['-g']);
    if (out == null || out.exitCode != 0) return null;
    return (out.stdout ?? '').toString().trim();
  }

  void _sttySetRaw() {
    _runStty(['raw', '-echo']);
  }

  void _sttySane() {
    _runStty(['sane']);
  }

  void _sttySetMode(String mode) {
    _runStty([mode]);
  }

  io.ProcessResult? _runStty(List<String> args) {
    try {
      final candidates = <List<String>>[
        ['-F', _ttyPath, ...args],
        ['-f', _ttyPath, ...args],
      ];
      io.ProcessResult? last;
      for (final c in candidates) {
        final r = io.Process.runSync('stty', c);
        last = r;
        if (r.exitCode == 0) return r;
      }
      return last;
    } catch (_) {
      return null;
    }
  }
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
