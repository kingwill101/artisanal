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
  final tempDir = Platform.environment['TEMP'] ?? Platform.environment['TMP'] ?? '';
  return '$tempDir\\uv_native_reader.log';
}

void _logNativeReader(String msg) {
  try {
    File(_nativeReaderLogPath()).writeAsStringSync('$msg\n', mode: FileMode.append);
  } catch (_) {}
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

// Key event flags
const int _leftAltPressed = 0x0002;
const int _leftCtrlPressed = 0x0008;
const int _rightAltPressed = 0x0001;
const int _rightCtrlPressed = 0x0004;
const int _shiftPressed = 0x0010;

// Virtual key codes
const int _vkEscape = 0x1B;
const int _vkTab = 0x09;
const int _vkEnter = 0x0D;
const int _vkBackspace = 0x08;
const int _vkDelete = 0x2E;
const int _vkInsert = 0x2D;
const int _vkHome = 0x24;
const int _vkEnd = 0x23;
const int _vkPageUp = 0x21;
const int _vkPageDown = 0x22;
const int _vkLeft = 0x25;
const int _vkUp = 0x26;
const int _vkRight = 0x27;
const int _vkDown = 0x28;
const int _vkF1 = 0x70;
const int _vkF2 = 0x71;
const int _vkF3 = 0x72;
const int _vkF4 = 0x73;
const int _vkF5 = 0x74;
const int _vkF6 = 0x75;
const int _vkF7 = 0x76;
const int _vkF8 = 0x77;
const int _vkF9 = 0x78;
const int _vkF10 = 0x79;
const int _vkF11 = 0x7A;
const int _vkF12 = 0x7B;

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
    if (_closed) {
      throw StateError('NativeWindowsInputStream has been closed');
    }
    _controller ??= StreamController<List<int>>.broadcast(
      onListen: _ensureIsolate,
      onCancel: () {},
    );
    return _controller!.stream;
  }

  void _ensureIsolate() async {
    if (_isolate != null) return;

    _receivePort = ReceivePort();
    _isolate = await Isolate.spawn<_StartReading>(
      _readerIsolateEntry,
      _StartReading(_receivePort!.sendPort),
    );

    _receivePort!.listen((message) {
      if (message is SendPort) {
        _sendPort = message;
      } else if (message is Uint8List) {
        _controller?.add(message);
      } else if (message is String) {
        _controller?.addError(Exception(message));
      } else if (message == 'closed') {
        _controller?.close();
      }
    }, onError: (err) {
      _controller?.addError(err);
    }, onDone: () {
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
      port.send('Failed to allocate memory for CONIN\$ name');
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
      port.send('CreateFileW(CONIN\$) failed');
      return;
    }

    // Allocate buffer for INPUT_RECORDs (read up to 64 at a time)
    const recordCount = 64;
    const recordSize = 20; // sizeof(INPUT_RECORD) on x64
    final recBuf = localAlloc(_lmemZeroInit, recordCount * recordSize);
    if (recBuf == 0) {
      closeHandle(hConIn);
      _logNativeReader('[_runReaderLoop] Failed to allocate record buffer');
      port.send('Failed to allocate INPUT_RECORD buffer');
      return;
    }
    final recPtr = Pointer<_InputRecord>.fromAddress(recBuf);
    final readBuf = localAlloc(_lmemZeroInit, 4);
    final readPtr = Pointer<Uint32>.fromAddress(readBuf);
    _logNativeReader('[_runReaderLoop] Buffers allocated, entering read loop');

    while (true) {
      final result = readConsoleInputW(hConIn, recPtr.cast<Void>(), recordCount, readPtr);
      _logNativeReader('[_runReaderLoop] ReadConsoleInputW returned result=$result');
      if (result == 0) {
        // Read failed - likely handle closed
        _logNativeReader('[_runReaderLoop] Read failed, breaking');
        break;
      }
      final count = readPtr.value;
      _logNativeReader('[_runReaderLoop] count=$count');
      if (count == 0) continue;

      final bytes = <int>[];
      for (var i = 0; i < count; i++) {
        final rec = recPtr[i];
        _translateRecord(rec, bytes);
      }

      if (bytes.isNotEmpty) {
        _logNativeReader('[_runReaderLoop] Sending ${bytes.length} bytes: ${bytes.map((b) => '0x${b.toRadixString(16)}').join(' ')}');
        port.send(Uint8List.fromList(bytes));
      }
    }

    _logNativeReader('[_runReaderLoop] Cleaning up');
    localFree(recBuf);
    localFree(readBuf);
    closeHandle(hConIn);
  }

  /// Translates a single INPUT_RECORD into VT escape sequence bytes.
  static void _translateRecord(_InputRecord rec, List<int> out) {
    if (rec.eventType != _keyEvent) return;
    // Ignore mouse, focus, menu, window events for now

    final keyDown = rec.event.keyDown != 0;
    if (!keyDown) return; // Only translate key-down events

    final vk = rec.event.virtualKeyCode;
    final unicodeChar = rec.event.unicodeChar;
    final ctrlState = rec.event.controlKeyState;

    final shift = (ctrlState & _shiftPressed) != 0;
    final ctrl = (ctrlState & (_leftCtrlPressed | _rightCtrlPressed)) != 0;
    final alt = (ctrlState & (_leftAltPressed | _rightAltPressed)) != 0;

    // Handle printable characters (including with modifiers)
    if (unicodeChar != 0 && unicodeChar != 0x1B && unicodeChar != 0x00 && unicodeChar != 0x03 && unicodeChar != 0x1A) {
      // Printable character - send as UTF-8
      if (alt) {
        // Alt+char: ESC + char (VT convention)
        out.add(0x1B);
      }
      _writeUtf8(unicodeChar, out);
      return;
    }

    // Handle control characters (Ctrl+A through Ctrl+Z, etc.)
    if (ctrl && unicodeChar != 0 && unicodeChar <= 0x1A) {
      // Ctrl+letter produces 0x01-0x1A
      out.add(unicodeChar);
      return;
    }

    // Handle special keys that produce escape sequences
    String? seq;
    switch (vk) {
      case _vkEscape:
        seq = '\x1B';
        break;
      case _vkTab:
        if (shift) {
          seq = '\x1B[Z'; // Shift+Tab
        } else {
          seq = '\t'; // Tab
        }
        break;
      case _vkEnter:
        seq = '\r'; // Enter = CR
        break;
      case _vkBackspace:
        seq = ctrl ? '\x1B[3~' : '\x7F'; // Ctrl+Backspace = Delete, else Backspace
        break;
      case _vkDelete:
        seq = '\x1B[3~';
        break;
      case _vkInsert:
        seq = '\x1B[2~';
        break;
      case _vkHome:
        seq = ctrl ? '\x1B[1;5H' : (alt ? '\x1B[1;3H' : '\x1B[H');
        break;
      case _vkEnd:
        seq = ctrl ? '\x1B[1;5F' : (alt ? '\x1B[1;3F' : '\x1B[F');
        break;
      case _vkPageUp:
        seq = '\x1B[5~';
        break;
      case _vkPageDown:
        seq = '\x1B[6~';
        break;
      case _vkLeft:
        seq = ctrl ? '\x1B[1;5D' : (alt ? '\x1B[1;3D' : '\x1B[D');
        break;
      case _vkRight:
        seq = ctrl ? '\x1B[1;5C' : (alt ? '\x1B[1;3C' : '\x1B[C');
        break;
      case _vkUp:
        seq = ctrl ? '\x1B[1;5A' : (alt ? '\x1B[1;3A' : '\x1B[A');
        break;
      case _vkDown:
        seq = ctrl ? '\x1B[1;5B' : (alt ? '\x1B[1;3B' : '\x1B[B');
        break;
      case _vkF1:
        seq = shift ? '\x1B[1;2P' : (ctrl ? '\x1B[1;5P' : (alt ? '\x1B[1;3P' : '\x1B[P'));
        break;
      case _vkF2:
        seq = shift ? '\x1B[1;2Q' : (ctrl ? '\x1B[1;5Q' : (alt ? '\x1B[1;3Q' : '\x1B[Q'));
        break;
      case _vkF3:
        seq = shift ? '\x1B[1;2R' : (ctrl ? '\x1B[1;5R' : (alt ? '\x1B[1;3R' : '\x1B[R'));
        break;
      case _vkF4:
        seq = shift ? '\x1B[1;2S' : (ctrl ? '\x1B[1;5S' : (alt ? '\x1B[1;3S' : '\x1B[S'));
        break;
      case _vkF5:
        seq = '\x1B[15~';
        break;
      case _vkF6:
        seq = '\x1B[17~';
        break;
      case _vkF7:
        seq = '\x1B[18~';
        break;
      case _vkF8:
        seq = '\x1B[19~';
        break;
      case _vkF9:
        seq = '\x1B[20~';
        break;
      case _vkF10:
        seq = '\x1B[21~';
        break;
      case _vkF11:
        seq = '\x1B[23~';
        break;
      case _vkF12:
        seq = '\x1B[24~';
        break;
      default:
        // Unhandled key
        return;
    }

    for (final codeUnit in seq.codeUnits) {
      out.add(codeUnit);
    }
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