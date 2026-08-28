// Windows-native console input reader using ReadConsoleInputW.
// Bypasses Dart's stdin (which uses ReadFile) to avoid the Ctrl+Z → EOF
// conversion that occurs when ENABLE_VIRTUAL_TERMINAL_INPUT is active.
import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:isolate';
import 'dart:typed_data';

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
/// ReadConsoleInputW, forwarding each record's unicodeChar as UTF-8 to
/// the [EventDecoder] downstream. Runs in a worker isolate to avoid
/// blocking the main isolate.
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

    _runReaderLoop(port);
  }

  static void _runReaderLoop(SendPort port) {
    final k32 = DynamicLibrary.open('kernel32.dll');

    final createFileW = k32.lookupFunction<_CreateFileWC, _CreateFileWD>('CreateFileW');
    final readConsoleInputW = k32.lookupFunction<_ReadConsoleInputWC, _ReadConsoleInputWD>('ReadConsoleInputW');
    final closeHandle = k32.lookupFunction<_CloseHandleC, _CloseHandleD>('CloseHandle');
    final localAlloc = k32.lookupFunction<_LocalAllocC, _LocalAllocD>('LocalAlloc');
    final localFree = k32.lookupFunction<_LocalFreeC, _LocalFreeD>('LocalFree');

    // Open CONIN$ directly
    final name = 'CONIN\$'.codeUnits;
    final nameBuf = localAlloc(_lmemZeroInit, (name.length + 1) * 2);
    if (nameBuf == 0) return;
    final namePtr = Pointer<Uint16>.fromAddress(nameBuf);
    for (var i = 0; i < name.length; i++) {
      namePtr[i] = name[i];
    }
    namePtr[name.length] = 0;

    final hConIn = createFileW(namePtr, _genericRead | _genericWrite, _fileShareRead | _fileShareWrite, 0, _openExisting, 0, 0);
    localFree(nameBuf);

    if (hConIn == -1 || hConIn == 0 || hConIn == _invalidHandleValue) {
      return;
    }

    // Allocate buffer for INPUT_RECORDs (read up to 64 at a time)
    const recordCount = 64;
    const recordSize = 20; // sizeof(INPUT_RECORD) on x64
    final recBuf = localAlloc(_lmemZeroInit, recordCount * recordSize);
    if (recBuf == 0) {
      closeHandle(hConIn);
      return;
    }
    final recPtr = Pointer<_InputRecord>.fromAddress(recBuf);
    final readBuf = localAlloc(_lmemZeroInit, 4);
    final readPtr = Pointer<Uint32>.fromAddress(readBuf);

    while (true) {
      final result = readConsoleInputW(hConIn, recPtr.cast<Void>(), recordCount, readPtr);
      if (result == 0) {
        // Read failed - likely handle closed
        break;
      }
      final count = readPtr.value;
      if (count == 0) continue;

      final bytes = <int>[];
      for (var i = 0; i < count; i++) {
        final rec = recPtr[i];
        _forwardRecord(rec, bytes);
      }

      if (bytes.isNotEmpty) {
        port.send(Uint8List.fromList(bytes));
      }
    }

    localFree(recBuf);
    localFree(readBuf);
    closeHandle(hConIn);
  }

  /// Forwards the unicodeChar of a single key-down record as UTF-8.
  ///
  /// With [ENABLE_VIRTUAL_TERMINAL_INPUT] set, Windows already translates
  /// each key into the VT sequence it would have produced on the wire
  /// (e.g. arrow up -> 0x1B, '[', 'A' across three records) and delivers
  /// them as one INPUT_RECORD per byte. The EventDecoder downstream of
  /// this stream already knows how to parse the resulting byte stream,
  /// so we just forward it verbatim.
  ///
  /// [KeyEventRecord.unicodeChar] is a 16-bit code unit (BMP only), so
  /// [String.fromCharCode] — and not `String.fromCharCodes` with surrogate
  /// pairing — is the right input to [utf8.encode].
  static void _forwardRecord(_InputRecord rec, List<int> out) {
    if (rec.eventType != _keyEvent) return;
    if (rec.event.keyDown == 0) return; // key-up only
    final codePoint = rec.event.unicodeChar;
    if (codePoint == 0) return; // modifier-only record
    out.addAll(utf8.encode(String.fromCharCode(codePoint)));
  }
}
