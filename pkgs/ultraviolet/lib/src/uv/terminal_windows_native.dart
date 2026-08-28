// Windows-native console input reader using ReadConsoleInputW.
// Bypasses Dart's stdin (which uses ReadFile) to avoid the Ctrl+Z → EOF
// conversion that occurs when ENABLE_VIRTUAL_TERMINAL_INPUT is active.
import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

/// Debug log file path for the native reader.
String _nativeReaderLogPath() {
  final tempDir = Platform.environment['TEMP'] ?? Platform.environment['TMP'] ?? 'C:\\Temp';
  return '$tempDir\\uv_native_reader.log';
}

void _logNativeReader(String msg) {
  // Two paths: the %TEMP% one, and a C:\Temp fallback. The C:\Temp write
  // also tells us whether the first path failed.
  final primary = _nativeReaderLogPath();
  final fallback = 'C:\\Temp\\uv_native_reader.log';
  String? wrotePath;
  try {
    File(primary).writeAsStringSync('$msg\n', mode: FileMode.append);
    wrotePath = primary;
  } catch (_) {
    try {
      File(fallback).writeAsStringSync('$msg\n', mode: FileMode.append);
      wrotePath = fallback;
    } catch (_) {
      wrotePath = null;
    }
  }
  if (wrotePath != null && wrotePath != primary) {
    // First write to fallback — make it discoverable.
    try {
      File(fallback).writeAsStringSync(
        'LOG-NOTE: primary log path failed, falling back here\n',
        mode: FileMode.append,
      );
    } catch (_) {}
  }
}

// Win32 constants
const int _genericRead = 0x80000000;
const int _genericWrite = 0x40000000;
const int _fileShareRead = 0x00000001;
const int _fileShareWrite = 0x00000002;
const int _openExisting = 3;
const int _lmemZeroInit = 0x0040;
const int _invalidHandleValue = -1;

// Console input event types
const int _keyEvent = 0x0001;

typedef _CreateFileWC = IntPtr Function(Pointer<Uint16>, Uint32, Uint32, IntPtr, Uint32, Uint32, IntPtr);
typedef _CreateFileWD = int Function(Pointer<Uint16>, int, int, int, int, int, int);
typedef _ReadConsoleInputWC = Int32 Function(IntPtr, Pointer<Void>, Uint32, Pointer<Uint32>);
typedef _ReadConsoleInputWD = int Function(int, Pointer<Void>, int, Pointer<Uint32>);
typedef _CloseHandleC = Int32 Function(IntPtr);
typedef _CloseHandleD = int Function(int);
typedef _LocalAllocC = IntPtr Function(Uint32, IntPtr);
typedef _LocalAllocD = int Function(int, int);
typedef _LocalFreeC = IntPtr Function(IntPtr);
typedef _LocalFreeD = int Function(int);

// INPUT_RECORD structure (matches Win32 on x64)
final class _KeyEventRecord extends Struct {
  @Int32()
  external int keyDown;
  @Uint16()
  external int repeatCount;
  @Uint16()
  external int virtualKeyCode;
  @Uint16()
  external int virtualScanCode;
  @Uint16()
  external int unicodeChar;
  @Uint32()
  external int controlKeyState;
}

final class _InputRecord extends Struct {
  @Uint16()
  external int eventType;
  external _KeyEventRecord event;
}

// Message types for isolate communication
sealed class _NativeInputMessage {}
final class _StartReading extends _NativeInputMessage {
  final SendPort replyPort;
  _StartReading(this.replyPort);
}
final class _StopReading extends _NativeInputMessage {}

/// A Windows-native input stream that reads directly from CONIN$ using
/// ReadConsoleInputW, translating INPUT_RECORDs into the VT escape sequences
/// the decoder expects. Runs in a worker isolate to avoid blocking the main isolate.
class NativeWindowsInputStream {
  NativeWindowsInputStream();

  Isolate? _isolate;
  ReceivePort? _receivePort;
  SendPort? _sendPort;
  StreamController<List<int>>? _controller;
  bool _closed = false;

  /// Starts the native input reader and returns a broadcast stream of bytes.
  Stream<List<int>> start() {
    _logNativeReader('[main] NativeWindowsInputStream.start() called');
    if (_closed) {
      _logNativeReader('[main] start() rejected: stream already closed');
      throw StateError('NativeWindowsInputStream has been closed');
    }
    _controller ??= StreamController<List<int>>.broadcast(
      onListen: _ensureIsolate,
      onCancel: () {},
    );
    _logNativeReader('[main] start() returning broadcast stream');
    return _controller!.stream;
  }

  void _ensureIsolate() async {
    if (_isolate != null) {
      _logNativeReader('[main] _ensureIsolate: isolate already running');
      return;
    }

    _logNativeReader('[main] _ensureIsolate: opening ReceivePort');
    _receivePort = ReceivePort();

    _logNativeReader('[main] _ensureIsolate: calling Isolate.spawn');
    try {
      _isolate = await Isolate.spawn<_StartReading>(
        _readerIsolateEntry,
        _StartReading(_receivePort!.sendPort),
      );
      _logNativeReader('[main] _ensureIsolate: Isolate.spawn resolved');
    } catch (e, st) {
      _logNativeReader('[main] _ensureIsolate: Isolate.spawn threw: $e\n$st');
      rethrow;
    }

    _receivePort!.listen((message) {
      if (message is SendPort) {
        _logNativeReader('[main] receivePort: got worker SendPort');
        _sendPort = message;
      } else if (message is Uint8List) {
        _logNativeReader('[main] receivePort: got ${message.length} bytes');
        _controller?.add(message);
      } else if (message is String) {
        // Diagnostic / shutdown signalling from the worker. Logged to file
        // and dropped, never converted to an Exception — earlier versions
        // called addError here, which crashed the TUI on the very first
        // port message before the reader could deliver a single byte.
        _logNativeReader('[main] receivePort: string msg: $message');
        if (message == 'closed') {
          _logNativeReader('[main] receivePort: closed');
          _controller?.close();
        }
      } else {
        _logNativeReader('[main] receivePort: unknown message type ${message.runtimeType}');
      }
    }, onError: (err) {
      _logNativeReader('[main] receivePort.onError: $err');
      _controller?.addError(err);
    }, onDone: () {
      _logNativeReader('[main] receivePort.onDone fired');
      _controller?.close();
    });
  }

  /// Stops the native input reader.
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _sendPort?.send(_StopReading());
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _receivePort?.close();
    _receivePort = null;
    _sendPort = null;
    await _controller?.close();
    _controller = null;
  }

  /// Entry point for the worker isolate.
  static void _readerIsolateEntry(_StartReading msg) {
    final port = msg.replyPort;
    final receivePort = ReceivePort();
    port.send(receivePort.sendPort);

    receivePort.listen((message) {
      if (message is _StopReading) {
        port.send('closed');
        receivePort.close();
        return;
      }
    });

    _logNativeReader('[_readerIsolateEntry] Starting reader loop');
    _runReaderLoop(port);
  }

  static void _runReaderLoop(SendPort port) {
    _logNativeReader('[_runReaderLoop] Starting');

    final k32 = DynamicLibrary.open('kernel32.dll');
    _logNativeReader('[_runReaderLoop] kernel32 loaded');

    final createFileW = k32.lookupFunction<_CreateFileWC, _CreateFileWD>('CreateFileW');
    final readConsoleInputW = k32.lookupFunction<_ReadConsoleInputWC, _ReadConsoleInputWD>('ReadConsoleInputW');
    final closeHandle = k32.lookupFunction<_CloseHandleC, _CloseHandleD>('CloseHandle');
    final localAlloc = k32.lookupFunction<_LocalAllocC, _LocalAllocD>('LocalAlloc');
    final localFree = k32.lookupFunction<_LocalFreeC, _LocalFreeD>('LocalFree');
    _logNativeReader('[_runReaderLoop] FFI functions loaded');

    // Open CONIN$ directly
    final name = 'CONIN\$'.codeUnits;
    final nameBuf = localAlloc(_lmemZeroInit, (name.length + 1) * 2);
    if (nameBuf == 0) {
      _logNativeReader('[_runReaderLoop] Failed to allocate name buffer');
      return;
    }
    final namePtr = Pointer<Uint16>.fromAddress(nameBuf);
    for (var i = 0; i < name.length; i++) {
      namePtr[i] = name[i];
    }
    namePtr[name.length] = 0;

    final hConIn = createFileW(namePtr, _genericRead | _genericWrite, _fileShareRead | _fileShareWrite, 0, _openExisting, 0, 0);
    localFree(nameBuf);
    _logNativeReader('[_runReaderLoop] CreateFileW returned hConIn=$hConIn');

    if (hConIn == -1 || hConIn == 0 || hConIn == _invalidHandleValue) {
      _logNativeReader('[_runReaderLoop] CreateFileW failed');
      return;
    }

    // Allocate buffer for INPUT_RECORDs (read up to 64 at a time)
    const recordCount = 64;
    const recordSize = 20; // sizeof(INPUT_RECORD) on x64
    final recBuf = localAlloc(_lmemZeroInit, recordCount * recordSize);
    if (recBuf == 0) {
      closeHandle(hConIn);
      _logNativeReader('[_runReaderLoop] Failed to allocate record buffer');
      return;
    }
    final recPtr = Pointer<_InputRecord>.fromAddress(recBuf);
    final readBuf = localAlloc(_lmemZeroInit, 4);
    final readPtr = Pointer<Uint32>.fromAddress(readBuf);
    _logNativeReader('[_runReaderLoop] Buffers allocated, entering read loop');

    while (true) {
      final result = readConsoleInputW(hConIn, recPtr.cast<Void>(), recordCount, readPtr);
      if (result == 0) {
        // Read failed - likely handle closed
        _logNativeReader('[_runReaderLoop] ReadConsoleInputW returned 0, breaking');
        break;
      }
      final count = readPtr.value;
      if (count == 0) continue;

      final bytes = <int>[];
      for (var i = 0; i < count; i++) {
        final rec = recPtr[i];
        _translateRecord(rec, bytes);
      }

      if (bytes.isNotEmpty) {
        _logNativeReader('[_runReaderLoop] sending ${bytes.length} bytes: ${bytes.map((b) => '0x${b.toRadixString(16)}').join(' ')}');
        port.send(Uint8List.fromList(bytes));
      }
    }

    _logNativeReader('[_runReaderLoop] Cleaning up');
    localFree(recBuf);
    localFree(readBuf);
    closeHandle(hConIn);
  }

  /// Concatenates the unicodeChar of each key-down record in a batch into a
  /// single byte stream. With ENABLE_VIRTUAL_TERMINAL_INPUT set, Windows
  /// pre-translates each key into the VT sequence it would have produced on
  /// the wire (ESC+A for arrow up across two records as 0x1B then 0x5B 0x41,
  /// '\x1B[15~' for F5 across four records, etc.) and delivers them as one
  /// INPUT_RECORD per byte. The EventDecoder downstream of this stream
  /// already knows how to parse those sequences, so we just forward them
  /// verbatim — no per-VK translation here.
  ///
  /// The previous per-VK switch interleaved its own translations on top of
  /// the printable branch and leaked `[A` / `[B` into text fields when an
  /// arrow key's `[` and `A` records hit the printable path.
  static void _translateRecord(_InputRecord rec, List<int> out) {
    if (rec.eventType != _keyEvent) return;
    if (rec.event.keyDown == 0) return; // key-up only

    final unicodeChar = rec.event.unicodeChar;
    if (unicodeChar == 0) return; // no byte to forward (modifier-only record)

    // Alt+char: VT convention is ESC + char. The standalone ESC record
    // Windows emits for the prefix is the same byte we'd send; if unicodeChar
    // is already 0x1B here it came from a real ESC keypress, not a sequence
    // prefix — forward as-is.
    _writeUtf8(unicodeChar, out);
  }

  /// Writes a Unicode code point as UTF-8 bytes.
  static void _writeUtf8(int codePoint, List<int> out) {
    if (codePoint <= 0x7F) {
      out.add(codePoint);
    } else if (codePoint <= 0x7FF) {
      out.add(0xC0 | (codePoint >> 6));
      out.add(0x80 | (codePoint & 0x3F));
    } else if (codePoint <= 0xFFFF) {
      out.add(0xE0 | (codePoint >> 12));
      out.add(0x80 | ((codePoint >> 6) & 0x3F));
      out.add(0x80 | (codePoint & 0x3F));
    } else {
      out.add(0xF0 | (codePoint >> 18));
      out.add(0x80 | ((codePoint >> 12) & 0x3F));
      out.add(0x80 | ((codePoint >> 6) & 0x3F));
      out.add(0x80 | (codePoint & 0x3F));
    }
  }
}