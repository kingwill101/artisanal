import 'dart:async';
import 'dart:io' as io;

import '../colorprofile/detect_impl.dart' as cp_detect;
import '../style/color.dart';
import 'ansi.dart';
import 'stdin_stream.dart';
import 'terminal_base.dart';

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

  @override
  int get width {
    try {
      return _stdout.hasTerminal ? _stdout.terminalColumns : 80;
    } catch (_) {
      return 80;
    }
  }

  @override
  int get height {
    try {
      return _stdout.hasTerminal ? _stdout.terminalLines : 24;
    } catch (_) {
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
      return false;
    }
  }

  @override
  bool get isTerminal {
    try {
      return _stdout.hasTerminal;
    } catch (_) {
      return false;
    }
  }

  @override
  ColorProfile get colorProfile =>
      ColorProfileConverter.fromProfile(cp_detect.detectForSink(_stdout));

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

  @override
  void enableMouse() {
    if (_mouseEnabled || !supportsAnsi) return;
    write(Ansi.mouseEnableNormal);
    write(Ansi.mouseEnableSgr);
    _mouseEnabled = true;
  }

  @override
  void enableMouseCellMotion() {
    if (!supportsAnsi) return;
    enableMouse();
    write(Ansi.mouseEnableButton);
  }

  @override
  void enableMouseAllMotion() {
    if (!supportsAnsi) return;
    enableMouse();
    write(Ansi.mouseEnableButton);
    write(Ansi.mouseEnableAny);
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

  @override
  void enableFocusReporting() {
    if (supportsAnsi) write(Ansi.focusEnable);
  }

  @override
  void disableFocusReporting() {
    if (supportsAnsi) write(Ansi.focusDisable);
  }

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
    return (useTabs: false, useBackspace: true);
  }

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

  @override
  void dispose() {
    if (_bracketedPasteEnabled) disableBracketedPaste();
    if (_mouseEnabled) disableMouse();
    if (!_cursorVisible) showCursor();
    if (_altScreenEnabled) exitAltScreen();
    if (_rawModeEnabled) disableRawMode();

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
  void cursorLeft([int lines = 1]) {
    if (!supportsAnsi) return;
    if (lines <= 1) return write(Ansi.cursorLeft);
    write(Ansi.cursorLeftBy(lines));
  }

  @override
  void cursorToColumn(int col) {
    if (supportsAnsi) write(Ansi.cursorToColumn(col));
  }

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

  @override
  void enableFocusReporting() {
    if (supportsAnsi) write(Ansi.focusEnable);
  }

  @override
  void disableFocusReporting() {
    if (supportsAnsi) write(Ansi.focusDisable);
  }

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
    final useTabs = s.contains('tab0') || s.contains(' tabs');
    final useBackspace = s.contains('bs0') || !s.contains('-echoe');

    return (useTabs: useTabs, useBackspace: useBackspace);
  }

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
    try {
      while (true) {
        final b = readByte();
        if (b < 0) {
          if (_lineBuf.isEmpty) return null;
          final s = io.systemEncoding.decode(_lineBuf);
          _lineBuf.clear();
          return s;
        }
        if (b == 0x0a) {
          final s = io.systemEncoding.decode(_lineBuf);
          _lineBuf.clear();
          return s;
        }
        if (b != 0x0d) _lineBuf.add(b);
      }
    } catch (_) {
      return null;
    }
  }

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
