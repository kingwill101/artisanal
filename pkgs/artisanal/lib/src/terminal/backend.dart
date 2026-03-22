import 'dart:async';
import 'dart:io' as io;
import 'dart:convert';

import '../colorprofile/detect.dart' as cp_detect;
import '../style/color.dart';
import 'ansi.dart';
import 'stdin_stream.dart';
import 'terminal_base.dart';

/// Terminal dimensions expressed in cells.
typedef TerminalDimensions = ({int width, int height});

/// Low-level I/O backend for a terminal host.
///
/// Backends own raw bytes, input streams, resize/shutdown notifications, and
/// raw-mode lifecycle. High-level terminal semantics such as alt-screen,
/// cursor visibility, mouse escape sequences, and OSC title/color handling
/// stay in [BackendTerminal].
abstract interface class TerminalBackend {
  /// Writes raw terminal data immediately.
  void writeRaw(String data);

  /// Flushes any buffered backend output.
  Future<void> flush();

  /// Current terminal dimensions.
  TerminalDimensions get size;

  /// Whether the backend can interpret ANSI escape sequences.
  bool get supportsAnsi;

  /// Whether the backend is connected to a real terminal-like surface.
  bool get isTerminal;

  /// The color capability profile of the target surface.
  ColorProfile get colorProfile;

  /// Stream of raw input bytes, if the backend accepts input.
  Stream<List<int>>? get inputStream;

  /// Stream of terminal resize events, if the backend can emit them.
  Stream<TerminalDimensions>? get resizeStream;

  /// Stream of shutdown/interrupt events, if the backend can emit them.
  Stream<void>? get shutdownStream;

  /// Enables raw input mode.
  RawModeGuard enableRawMode();

  /// Disables raw input mode.
  void disableRawMode();

  /// Whether raw mode is currently enabled.
  bool get isRawMode;

  /// Host-specific movement optimization hints.
  ({bool useTabs, bool useBackspace}) optimizeMovements();

  /// Disposes backend resources.
  void dispose();
}

/// Terminal implementation that layers ANSI/OSC semantics over a [TerminalBackend].
class BackendTerminal implements Terminal {
  /// Creates a terminal backed by [backend].
  BackendTerminal(this.backend) {
    final inputStream = backend.inputStream;
    if (inputStream != null) {
      _inputSubscription = inputStream.listen(
        (data) {
          _inputQueue.addAll(data);
          _inputController.add(data);
        },
        onError: (error, stackTrace) {
          _inputController.addError(error, stackTrace);
        },
        cancelOnError: false,
      );
    }
  }

  /// The low-level host/backend.
  final TerminalBackend backend;

  final StreamController<List<int>> _inputController =
      StreamController<List<int>>.broadcast();
  final List<int> _inputQueue = <int>[];
  StreamSubscription<List<int>>? _inputSubscription;

  bool _cursorVisible = true;
  bool _altScreenEnabled = false;
  bool _mouseEnabled = false;
  bool _bracketedPasteEnabled = false;

  /// Resize notifications exposed by the backend, if available.
  Stream<TerminalDimensions>? get resizeStream => backend.resizeStream;

  /// Shutdown notifications exposed by the backend, if available.
  Stream<void>? get shutdownStream => backend.shutdownStream;

  @override
  int get width => backend.size.width;

  @override
  int get height => backend.size.height;

  @override
  TerminalDimensions get size => backend.size;

  @override
  bool get supportsAnsi => backend.supportsAnsi;

  @override
  bool get isTerminal => backend.isTerminal;

  @override
  ColorProfile get colorProfile => backend.colorProfile;

  @override
  void write(String text) {
    if (text.isEmpty) return;
    backend.writeRaw(text);
  }

  @override
  void writeln([String text = '']) =>
      write('$text${io.Platform.lineTerminator}');

  @override
  Future<void> flush() => backend.flush();

  @override
  Future<String?> query(
    String query, {
    Duration timeout = const Duration(seconds: 2),
  }) async {
    if (backend.inputStream == null) return null;

    final wasRaw = backend.isRawMode;
    if (!wasRaw) {
      backend.enableRawMode();
    }

    try {
      write(query);
      await flush();

      final completer = Completer<String?>();
      final buffer = StringBuffer();

      final timer = Timer(timeout, () {
        if (!completer.isCompleted) completer.complete(null);
      });

      late final StreamSubscription<List<int>> sub;
      sub = input.listen((data) {
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
      if (!wasRaw) {
        backend.disableRawMode();
      }
    }
  }

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
  RawModeGuard enableRawMode() => backend.enableRawMode();

  @override
  void disableRawMode() => backend.disableRawMode();

  @override
  bool get isRawMode => backend.isRawMode;

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
  ({bool useTabs, bool useBackspace}) optimizeMovements() =>
      backend.optimizeMovements();

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
    final lineEnd = _inputQueue.indexOf(10);
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
    if (_bracketedPasteEnabled) disableBracketedPaste();
    if (_mouseEnabled) disableMouse();
    if (!_cursorVisible) showCursor();
    if (_altScreenEnabled) exitAltScreen();
    if (isRawMode) disableRawMode();

    _inputSubscription?.cancel();
    _inputSubscription = null;
    _inputController.close();
    backend.dispose();
  }
}

/// Native stdio backend for [BackendTerminal].
class StdioTerminalBackend implements TerminalBackend {
  /// Creates a backend using standard I/O streams.
  StdioTerminalBackend({io.Stdout? stdout, io.Stdin? stdin})
    : _stdout = stdout ?? io.stdout,
      _stdin = stdin ?? io.stdin {
    _initializeSignalHandling();
  }

  final io.Stdout _stdout;
  final io.Stdin _stdin;

  Future<void>? _stdoutFlushInFlight;
  final StringBuffer _stdoutPending = StringBuffer();
  int _stdoutPendingLen = 0;

  bool _rawModeEnabled = false;
  bool? _originalEchoMode;
  bool? _originalLineMode;

  StreamController<List<int>>? _inputController;
  StreamSubscription<List<int>>? _inputSubscription;

  StreamController<TerminalDimensions>? _resizeController;
  StreamSubscription<io.ProcessSignal>? _sigwinchSubscription;
  StreamController<void>? _shutdownController;
  StreamSubscription<io.ProcessSignal>? _sigintSubscription;

  @override
  TerminalDimensions get size => (width: width, height: height);

  int get width {
    try {
      return _stdout.hasTerminal ? _stdout.terminalColumns : 80;
    } catch (_) {
      return 80;
    }
  }

  int get height {
    try {
      return _stdout.hasTerminal ? _stdout.terminalLines : 24;
    } catch (_) {
      return 24;
    }
  }

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
  void writeRaw(String data) {
    if (data.isEmpty) return;
    if (_stdoutFlushInFlight != null) {
      _stdoutPending.write(data);
      _stdoutPendingLen += data.length;
      return;
    }
    try {
      _stdout.write(data);
    } on StateError catch (e) {
      if (_isStdoutBoundToStream(e)) {
        _stdoutPending.write(data);
        _stdoutPendingLen += data.length;
        unawaited(flush());
        return;
      }
      rethrow;
    }
  }

  @override
  Future<void> flush() {
    final existing = _stdoutFlushInFlight;
    if (existing != null) return existing;
    final future = _flushStdoutAll();
    _stdoutFlushInFlight = future.whenComplete(() {
      _stdoutFlushInFlight = null;
    });
    return _stdoutFlushInFlight!;
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

  void _initializeSignalHandling() {
    if (!(io.Platform.isLinux || io.Platform.isMacOS)) return;

    _resizeController = StreamController<TerminalDimensions>.broadcast();
    try {
      _sigwinchSubscription = io.ProcessSignal.sigwinch.watch().listen((_) {
        if (_resizeController?.isClosed ?? true) return;
        _resizeController?.add(size);
      });
    } catch (_) {
      _sigwinchSubscription = null;
    }

    _shutdownController = StreamController<void>.broadcast();
    try {
      _sigintSubscription = io.ProcessSignal.sigint.watch().listen((_) {
        if (_shutdownController?.isClosed ?? true) return;
        _shutdownController?.add(null);
      });
    } catch (_) {
      _sigintSubscription = null;
    }
  }

  @override
  Stream<List<int>>? get inputStream {
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
      onError: (error, stackTrace) =>
          _inputController?.addError(error, stackTrace),
      cancelOnError: false,
    );
  }

  void _stopInputListener() {
    _inputSubscription?.cancel();
    _inputSubscription = null;
  }

  @override
  Stream<TerminalDimensions>? get resizeStream => _resizeController?.stream;

  @override
  Stream<void>? get shutdownStream => _shutdownController?.stream;

  @override
  RawModeGuard enableRawMode() {
    var wasEchoMode = true;
    var wasLineMode = true;

    if (!_rawModeEnabled) {
      try {
        _originalEchoMode = _stdin.echoMode;
        _originalLineMode = _stdin.lineMode;
        wasEchoMode = _originalEchoMode ?? true;
        wasLineMode = _originalLineMode ?? true;
        _stdin.echoMode = false;
        _stdin.lineMode = false;
        _rawModeEnabled = true;
      } catch (_) {}
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
    } catch (_) {}
  }

  @override
  bool get isRawMode => _rawModeEnabled;

  @override
  ({bool useTabs, bool useBackspace}) optimizeMovements() {
    return (useTabs: false, useBackspace: true);
  }

  @override
  void dispose() {
    if (_rawModeEnabled) {
      disableRawMode();
    }
    _stopInputListener();
    _inputController?.close();
    _inputController = null;
    _sigwinchSubscription?.cancel();
    _sigwinchSubscription = null;
    _resizeController?.close();
    _resizeController = null;
    _sigintSubscription?.cancel();
    _sigintSubscription = null;
    _shutdownController?.close();
    _shutdownController = null;
  }
}

/// Generic embedded backend backed by callbacks and externally supplied streams.
class EmbeddedTerminalBackend implements TerminalBackend {
  /// Creates an embedded backend.
  ///
  /// Use [addInput], [notifySizeChanged], and [requestShutdown] to drive it
  /// from an external host, or provide external streams up front.
  EmbeddedTerminalBackend({
    required void Function(String data) output,
    Future<void> Function()? flushOutput,
    Stream<List<int>>? inputStream,
    Stream<TerminalDimensions>? resizeStream,
    Stream<void>? shutdownStream,
    TerminalDimensions initialSize = const (width: 80, height: 24),
    this.supportsAnsi = true,
    this.isTerminal = true,
    this.colorProfile = ColorProfile.trueColor,
    this.movementCaps = const (useTabs: false, useBackspace: true),
  }) : _output = output,
       _flushOutput = flushOutput,
       _size = initialSize {
    _inputStreamSubscription = inputStream?.listen(_inputController.add);
    _resizeStreamSubscription = resizeStream?.listen(_resizeController.add);
    _shutdownStreamSubscription = shutdownStream?.listen(
      (_) => _shutdownController.add(null),
    );
  }

  final void Function(String data) _output;
  final Future<void> Function()? _flushOutput;
  TerminalDimensions _size;

  @override
  final bool supportsAnsi;

  @override
  final bool isTerminal;

  @override
  final ColorProfile colorProfile;

  final ({bool useTabs, bool useBackspace}) movementCaps;

  bool _rawModeEnabled = false;
  bool _disposed = false;

  final StreamController<List<int>> _inputController =
      StreamController<List<int>>.broadcast();
  final StreamController<TerminalDimensions> _resizeController =
      StreamController<TerminalDimensions>.broadcast();
  final StreamController<void> _shutdownController =
      StreamController<void>.broadcast(sync: true);

  StreamSubscription<List<int>>? _inputStreamSubscription;
  StreamSubscription<TerminalDimensions>? _resizeStreamSubscription;
  StreamSubscription<void>? _shutdownStreamSubscription;

  @override
  void writeRaw(String data) {
    if (_disposed) return;
    _output(data);
  }

  @override
  Future<void> flush() async {
    if (_disposed) return;
    final flushOutput = _flushOutput;
    if (flushOutput != null) {
      await flushOutput();
    }
  }

  @override
  TerminalDimensions get size => _size;

  /// Pushes input into the backend.
  void addInput(List<int> bytes) {
    if (_disposed) return;
    _inputController.add(bytes);
  }

  /// Pushes an input-side error into the backend stream.
  void addInputError(Object error, [StackTrace? stackTrace]) {
    if (_disposed) return;
    _inputController.addError(error, stackTrace);
  }

  /// Pushes a resize event into the backend and updates [size].
  void notifySizeChanged(TerminalDimensions size) {
    if (_disposed) return;
    _size = size;
    _resizeController.add(size);
  }

  /// Pushes a shutdown event into the backend.
  void requestShutdown() {
    if (_disposed) return;
    _shutdownController.add(null);
  }

  @override
  Stream<List<int>>? get inputStream => _inputController.stream;

  @override
  Stream<TerminalDimensions>? get resizeStream => _resizeController.stream;

  @override
  Stream<void>? get shutdownStream => _shutdownController.stream;

  @override
  RawModeGuard enableRawMode() {
    final wasRawMode = _rawModeEnabled;
    _rawModeEnabled = true;
    return RawModeGuard(
      wasEchoMode: !wasRawMode,
      wasLineMode: !wasRawMode,
      restore: disableRawMode,
    );
  }

  @override
  void disableRawMode() {
    _rawModeEnabled = false;
  }

  @override
  bool get isRawMode => _rawModeEnabled;

  @override
  ({bool useTabs, bool useBackspace}) optimizeMovements() => movementCaps;

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _rawModeEnabled = false;
    _inputStreamSubscription?.cancel();
    _resizeStreamSubscription?.cancel();
    _shutdownStreamSubscription?.cancel();
    _inputController.close();
    _resizeController.close();
    scheduleMicrotask(() {
      if (!_shutdownController.isClosed) {
        _shutdownController.close();
      }
    });
  }
}

/// Bridge controller for embedded terminal hosts such as xterm.js, sockets,
/// or custom UI surfaces.
///
/// [TerminalBridge] wraps an [EmbeddedTerminalBackend] and exposes:
/// - [output] for terminal bytes emitted by the TUI runtime
/// - [addInput] / [addInputString] for forwarding host input to the runtime
/// - [resize] for reporting host viewport changes
/// - [requestShutdown] for forwarding close/interrupt events
///
/// This sits one level above [EmbeddedTerminalBackend] and provides the
/// ergonomic surface most host integrations actually need.
final class TerminalBridge {
  /// Creates a bridge backed by an [EmbeddedTerminalBackend].
  TerminalBridge({
    TerminalDimensions initialSize = const (width: 80, height: 24),
    this.supportsAnsi = true,
    this.isTerminal = true,
    this.colorProfile = ColorProfile.trueColor,
    this.movementCaps = const (useTabs: false, useBackspace: true),
    Encoding inputEncoding = utf8,
  }) : _inputEncoding = inputEncoding {
    backend = EmbeddedTerminalBackend(
      output: _handleOutput,
      initialSize: initialSize,
      supportsAnsi: supportsAnsi,
      isTerminal: isTerminal,
      colorProfile: colorProfile,
      movementCaps: movementCaps,
    );
    terminal = BackendTerminal(backend);
  }

  final StreamController<String> _outputController =
      StreamController<String>.broadcast();
  final StringBuffer _outputBuffer = StringBuffer();
  final Encoding _inputEncoding;
  bool _disposed = false;

  /// Whether ANSI/OSC sequences are supported on the bridged surface.
  final bool supportsAnsi;

  /// Whether the bridged surface should be treated as terminal-like.
  final bool isTerminal;

  /// The color capability profile of the bridged surface.
  final ColorProfile colorProfile;

  /// Host-specific movement optimization hints.
  final ({bool useTabs, bool useBackspace}) movementCaps;

  /// The underlying embedded backend.
  late final EmbeddedTerminalBackend backend;

  /// Terminal wrapper layered on top of [backend].
  late final BackendTerminal terminal;

  /// Stream of raw terminal output emitted by the program.
  Stream<String> get output => _outputController.stream;

  /// Buffered terminal output emitted so far.
  String get bufferedOutput => _outputBuffer.toString();

  /// Current bridged viewport size in cells.
  TerminalDimensions get size => backend.size;

  void _handleOutput(String data) {
    if (_disposed) return;
    _outputBuffer.write(data);
    _outputController.add(data);
  }

  /// Clears the accumulated [bufferedOutput].
  void clearBufferedOutput() {
    if (_disposed) return;
    _outputBuffer.clear();
  }

  /// Forwards raw input bytes from the host into the runtime.
  void addInput(List<int> bytes) {
    if (_disposed) return;
    backend.addInput(bytes);
  }

  /// Encodes and forwards host input text into the runtime.
  void addInputString(String text, {Encoding? encoding}) {
    if (_disposed || text.isEmpty) return;
    addInput((encoding ?? _inputEncoding).encode(text));
  }

  /// Reports a host resize event to the runtime.
  void resize({required int width, required int height}) {
    if (_disposed) return;
    backend.notifySizeChanged((width: width, height: height));
  }

  /// Forwards a host shutdown/interrupt event to the runtime.
  void requestShutdown() {
    if (_disposed) return;
    backend.requestShutdown();
  }

  /// Disposes the bridge, closing the output stream and backend.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    backend.dispose();
    _outputController.close();
  }
}

/// Socket-backed backend for remote/shell-mode terminal hosts.
///
/// This backend treats `OSC 9999;<cols>;<rows>` as an out-of-band size update,
/// updates [size], emits on [resizeStream], and removes that control sequence
/// from the normal input stream before the TUI parser sees it.
class SocketTerminalBackend implements TerminalBackend {
  /// Creates a socket-backed backend.
  SocketTerminalBackend(
    this.socket, {
    TerminalDimensions initialSize = const (width: 80, height: 24),
    this.supportsAnsi = true,
    this.isTerminal = false,
    this.colorProfile = ColorProfile.trueColor,
    this.closeSocketOnDispose = true,
  }) : _size = initialSize {
    _socketSubscription = socket.listen(
      _handleSocketData,
      onDone: () {
        if (!_shutdownController.isClosed) {
          _shutdownController.add(null);
        }
      },
      onError: (error, stackTrace) {
        if (!_inputController.isClosed) {
          _inputController.addError(error, stackTrace);
        }
      },
      cancelOnError: false,
    );
  }

  /// The connected socket.
  final io.Socket socket;

  TerminalDimensions _size;
  final StreamController<List<int>> _inputController =
      StreamController<List<int>>.broadcast();
  final StreamController<TerminalDimensions> _resizeController =
      StreamController<TerminalDimensions>.broadcast();
  final StreamController<void> _shutdownController =
      StreamController<void>.broadcast();
  StreamSubscription<List<int>>? _socketSubscription;

  /// Whether ANSI/OSC sequences are supported on the remote surface.
  @override
  final bool supportsAnsi;

  /// Whether the remote socket should be treated as a locally interrogable
  /// terminal surface.
  ///
  /// Raw TCP clients can render ANSI output, but they do not reliably support
  /// terminal report queries like OSC 10/11/12 or DA1. Keeping this `false`
  /// suppresses startup probing and other terminal-report requests.
  @override
  final bool isTerminal;

  /// Detected or assumed color profile for the remote surface.
  @override
  final ColorProfile colorProfile;

  /// Whether the socket should be closed when the backend is disposed.
  final bool closeSocketOnDispose;

  bool _disposed = false;

  @override
  void writeRaw(String data) {
    if (_disposed) return;
    socket.write(data);
  }

  @override
  Future<void> flush() async {
    if (_disposed) return;
    try {
      await socket.flush();
    } on StateError {
      // Raw TCP sockets do not always provide a meaningful flush boundary
      // once writes are in flight. Treat this as best-effort transport sync.
    }
  }

  @override
  TerminalDimensions get size => _size;

  @override
  Stream<List<int>>? get inputStream => _inputController.stream;

  @override
  Stream<TerminalDimensions>? get resizeStream => _resizeController.stream;

  @override
  Stream<void>? get shutdownStream => _shutdownController.stream;

  @override
  RawModeGuard enableRawMode() {
    return RawModeGuard(
      wasEchoMode: false,
      wasLineMode: false,
      restore: disableRawMode,
    );
  }

  @override
  void disableRawMode() {}

  @override
  bool get isRawMode => false;

  @override
  ({bool useTabs, bool useBackspace}) optimizeMovements() {
    return (useTabs: false, useBackspace: true);
  }

  void _handleSocketData(List<int> bytes) {
    if (_disposed) return;
    final filtered = _extractOscControlSequences(bytes);
    if (filtered.isNotEmpty && !_inputController.isClosed) {
      _inputController.add(filtered);
    }
  }

  List<int> _extractOscControlSequences(List<int> bytes) {
    final result = <int>[];
    var i = 0;

    while (i < bytes.length) {
      if (i + 2 < bytes.length && bytes[i] == 0x1b && bytes[i + 1] == 0x5d) {
        var end = i + 2;
        var foundTerminator = false;

        while (end < bytes.length) {
          if (bytes[end] == 0x07) {
            foundTerminator = true;
            break;
          }
          if (end + 1 < bytes.length &&
              bytes[end] == 0x1b &&
              bytes[end + 1] == 0x5c) {
            foundTerminator = true;
            end++;
            break;
          }
          end++;
        }

        if (foundTerminator && end < bytes.length) {
          final oscContent = utf8.decode(
            bytes.sublist(i + 2, end),
            allowMalformed: true,
          );
          if (_handleOscSequence(oscContent)) {
            i = end + 1;
            continue;
          }
        }
      }

      result.add(bytes[i]);
      i++;
    }

    return result;
  }

  bool _handleOscSequence(String oscContent) {
    final semicolonIndex = oscContent.indexOf(';');
    if (semicolonIndex == -1) return false;

    final command = oscContent.substring(0, semicolonIndex);
    final payload = oscContent.substring(semicolonIndex + 1);

    if (command != '9999') return false;

    final parts = payload.split(';');
    if (parts.length != 2) return true;

    final width = int.tryParse(parts[0]);
    final height = int.tryParse(parts[1]);
    if (width == null || height == null) return true;

    final newSize = (width: width, height: height);
    _size = newSize;
    if (!_resizeController.isClosed) {
      _resizeController.add(newSize);
    }
    return true;
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _socketSubscription?.cancel();
    _socketSubscription = null;
    _inputController.close();
    _resizeController.close();
    _shutdownController.close();
    if (closeSocketOnDispose) {
      socket.destroy();
    }
  }
}
