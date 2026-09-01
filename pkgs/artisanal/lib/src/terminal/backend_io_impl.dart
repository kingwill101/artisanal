import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import '../colorprofile/detect_impl.dart' as cp_detect;
import '../style/color.dart';
import 'package:ultraviolet/terminal.dart'
    show enableWindowsVtInput, restoreWindowsVtInput;
import 'backend.dart';
import 'stdin_stream.dart';
import 'terminal_base.dart';

/// Native stdio backend for [BackendTerminal].
class StdioTerminalBackend implements TerminalBackend {
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
        if (identical(_stdin, io.stdin)) enableWindowsVtInput();
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
      if (identical(_stdin, io.stdin)) restoreWindowsVtInput();
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

/// Socket-backed backend for remote/shell-mode terminal hosts.
class SocketTerminalBackend implements TerminalBackend {
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

  final io.Socket socket;

  TerminalDimensions _size;
  final StreamController<List<int>> _inputController =
      StreamController<List<int>>.broadcast();
  final StreamController<TerminalDimensions> _resizeController =
      StreamController<TerminalDimensions>.broadcast();
  final StreamController<void> _shutdownController =
      StreamController<void>.broadcast();
  StreamSubscription<List<int>>? _socketSubscription;
  Future<void> _socketWriteQueue = Future<void>.value();

  @override
  final bool supportsAnsi;

  @override
  final bool isTerminal;

  @override
  final ColorProfile colorProfile;

  final bool closeSocketOnDispose;

  bool _disposed = false;

  @override
  void writeRaw(String data) {
    if (_disposed) return;
    _socketWriteQueue = _socketWriteQueue
        .then<void>((_) {
          if (!_disposed) {
            socket.add(utf8.encode(data));
          }
        })
        .catchError((_) {});
  }

  @override
  Future<void> flush() {
    if (_disposed) return Future<void>.value();
    final operation = _socketWriteQueue.then<void>((_) async {
      if (!_disposed) {
        try {
          await socket.flush();
        } on StateError {
          // Ignore flushes racing with socket shutdown.
        }
      }
    });
    // Keep the queue usable after an unexpected I/O failure, but return the
    // original operation so callers can observe that flush did not complete.
    _socketWriteQueue = operation.catchError((_) {});
    return operation;
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
