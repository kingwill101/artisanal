// Windows-native console input reader using ReadConsoleInputW.
// Bypasses Dart's stdin (which uses ReadFile) to avoid the Ctrl+Z → EOF
// conversion that occurs when ENABLE_VIRTUAL_TERMINAL_INPUT is active.
import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:isolate';
import 'dart:typed_data';

// Win32 GENERIC_* / OPEN_EXISTING / LMEM_ZEROINIT constants used by the
// CreateFileW + LocalAlloc calls below.
const int _genericRead = 0x80000000;
const int _genericWrite = 0x40000000;
const int _fileShareRead = 0x00000001;
const int _fileShareWrite = 0x00000002;
const int _openExisting = 3;
const int _lmemZeroInit = 0x0040;
const int _invalidHandleValue = -1;

// Windows INPUT_RECORD event types.
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

// INPUT_RECORD structures (matches Win32 on x64: 4 bytes padding at the
// end of KeyEventRecord brings the union to 20 bytes).
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

// Typed messages between the main isolate and the worker isolate.
sealed class _WorkerMessage {}
final class _WorkerReady extends _WorkerMessage {
  final SendPort replyPort;
  _WorkerReady(this.replyPort);
}
final class _WorkerBytes extends _WorkerMessage {
  final Uint8List bytes;
  _WorkerBytes(this.bytes);
}
final class _WorkerStopped extends _WorkerMessage {}
final class _WorkerError extends _WorkerMessage {
  final String message;
  _WorkerError(this.message);
}
final class _StopReading extends _WorkerMessage {}

/// A Windows-native input stream that reads directly from CONIN$ using
/// [ReadConsoleInputW] and forwards each record's `unicodeChar` as UTF-8
/// to the [EventDecoder] downstream. The FFI work runs in a worker isolate
/// so the main isolate never blocks.
///
/// Process-singleton: creating more than one instance returns the same
/// underlying stream. Windows delivers each input record to exactly one
/// handle, so a second open of CONIN$ would split the input stream and
/// drop keys.
NativeWindowsInputStream? _shared;
NativeWindowsInputStream get sharedWindowsInputStream =>
    _shared ??= NativeWindowsInputStream._();

class NativeWindowsInputStream {
  NativeWindowsInputStream._();

  Isolate? _isolate;
  ReceivePort? _receivePort;
  SendPort? _sendPort;
  StreamController<List<int>>? _controller;
  bool _closed = false;
  bool _stopRequested = false;

  /// Returns the broadcast stream of bytes read from CONIN$.
  ///
  /// The first call spawns the worker isolate; subsequent calls return
  /// the same stream. The worker stays alive until [close] is called
  /// (e.g. from [Terminal.stop] via [shutdownInput]).
  Stream<List<int>> start() {
    if (_closed) {
      throw StateError('NativeWindowsInputStream has been closed');
    }
    final controller = _controller ??= StreamController<List<int>>.broadcast(
      onListen: _ensureIsolate,
      onCancel: () {},
    );
    return controller.stream;
  }

  void _ensureIsolate() async {
    if (_isolate != null) return;

    final receivePort = _receivePort = ReceivePort();
    try {
      _isolate = await Isolate.spawn<_StartReading>(
        _readerIsolateEntry,
        _StartReading(receivePort.sendPort),
      );
    } catch (err, st) {
      _controller?.addError(err, st);
      await close();
      return;
    }

    receivePort.listen((message) {
      if (_stopRequested) return;
      if (message is _WorkerReady) {
        _sendPort = message.replyPort;
        if (_stopRequested) {
          // close() ran before the worker was ready — send the stop now.
          _sendPort?.send(_StopReading());
        }
      } else if (message is _WorkerBytes) {
        _controller?.add(message.bytes);
      } else if (message is _WorkerError) {
        _controller?.addError(StateError('Native CONIN reader: ${message.message}'));
      } else if (message is _WorkerStopped) {
        _controller?.close();
      }
    }, onError: (err) {
      _controller?.addError(err);
    }, onDone: () {
      _controller?.close();
    });
  }

  /// Stops the native input reader. Cooperative: sends a stop message
  /// and lets the worker exit cleanly. Safe to call multiple times.
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _stopRequested = true;

    _sendPort?.send(_StopReading());
    final isolate = _isolate;
    if (isolate != null) {
      // Give the worker a short window to exit on its own. If it doesn't,
      // fall back to killing the isolate (deprecated, but only as a last
      // resort — a stuck worker would otherwise pin the FFI handle).
      try {
        await Future<void>.delayed(const Duration(milliseconds: 200));
      } catch (_) {}
      if (isolate != _isolate) return;
      isolate.kill(priority: Isolate.beforeNextEvent);
    }
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
    port.send(_WorkerReady(receivePort.sendPort));

    receivePort.listen((message) {
      if (message is _StopReading) {
        receivePort.close();
        port.send(_WorkerStopped());
      }
    });

    try {
      _runReaderLoop(port);
    } catch (err) {
      port.send(_WorkerError(err.toString()));
    }
    port.send(_WorkerStopped());
  }

  static void _runReaderLoop(SendPort port) {
    final k32 = DynamicLibrary.open('kernel32.dll');
    final createFileW =
        k32.lookupFunction<_CreateFileWC, _CreateFileWD>('CreateFileW');
    final readConsoleInputW =
        k32.lookupFunction<_ReadConsoleInputWC, _ReadConsoleInputWD>('ReadConsoleInputW');
    final closeHandle =
        k32.lookupFunction<_CloseHandleC, _CloseHandleD>('CloseHandle');
    final localAlloc =
        k32.lookupFunction<_LocalAllocC, _LocalAllocD>('LocalAlloc');
    final localFree =
        k32.lookupFunction<_LocalFreeC, _LocalFreeD>('LocalFree');

    // Open CONIN$ directly. CreateFileW requires a NUL-terminated UTF-16
    // path; we allocate it via LocalAlloc so the FFI side can write into it.
    final name = 'CONIN\$'.codeUnits;
    final nameBuf = localAlloc(_lmemZeroInit, (name.length + 1) * 2);
    if (nameBuf == 0) {
      throw StateError('LocalAlloc failed for CONIN\$ path');
    }
    final namePtr = Pointer<Uint16>.fromAddress(nameBuf);
    for (var i = 0; i < name.length; i++) {
      namePtr[i] = name[i];
    }
    namePtr[name.length] = 0;

    final hConIn = createFileW(
      namePtr,
      _genericRead | _genericWrite,
      _fileShareRead | _fileShareWrite,
      0,
      _openExisting,
      0,
      0,
    );
    localFree(nameBuf);

    if (hConIn == 0 || hConIn == _invalidHandleValue) {
      throw StateError(
        'CreateFileW("CONIN\$") failed: handle=$hConIn',
      );
    }

    try {
      // One allocation for the record buffer and the read-count word;
      // // both are reused across calls to ReadConsoleInputW.
      const recordCount = 64;
      const recordSize = 20; // sizeof(INPUT_RECORD) on x64
      const readCountSize = 4; // sizeof(UINT32)
      final buf = localAlloc(_lmemZeroInit, recordCount * recordSize + readCountSize);
      if (buf == 0) {
        throw StateError('LocalAlloc failed for INPUT_RECORD buffer');
      }
      final recPtr = Pointer<_InputRecord>.fromAddress(buf);
      final readPtr = Pointer<Uint32>.fromAddress(buf + recordCount * recordSize);

      while (true) {
        final ok = readConsoleInputW(
          hConIn,
          recPtr.cast<Void>(),
          recordCount,
          readPtr,
        );
        if (ok == 0) {
          // Read failed — likely the handle was closed by another path.
          break;
        }
        final count = readPtr.value;
        if (count == 0) continue;

        // 4 bytes per code unit in the worst case; size once and slice.
        final bytes = Uint8List(count * 4);
        var len = 0;
        for (var i = 0; i < count; i++) {
          final rec = recPtr[i];
          len += _appendUtf8(rec, bytes, len);
        }
        if (len > 0) {
          port.send(_WorkerBytes(Uint8List.sublistView(bytes, 0, len)));
        }
      }

      localFree(buf);
    } finally {
      closeHandle(hConIn);
    }
  }

  /// Appends the [KeyEventRecord.unicodeChar] of [rec] as UTF-8 to [bytes]
  /// starting at [offset]. Returns the number of bytes written.
  ///
  /// With `ENABLE_VIRTUAL_TERMINAL_INPUT` set, Windows already translates
  /// each key into the VT sequence it would have produced on the wire
  /// (e.g. arrow up -> 0x1B, '[', 'A' across three records) and delivers
  /// them as one INPUT_RECORD per byte. The EventDecoder downstream of
  /// this stream already knows how to parse the resulting byte stream,
  /// so we just forward it verbatim.
  ///
  /// `unicodeChar` is a 16-bit code unit (BMP only), so [String.fromCharCode]
  /// — not `String.fromCharCodes` with surrogate pairing — is the right
  /// input to [utf8.encode].
  static int _appendUtf8(_InputRecord rec, Uint8List bytes, int offset) {
    if (rec.eventType != _keyEvent) return 0;
    if (rec.event.keyDown == 0) return 0; // key-up only
    final codePoint = rec.event.unicodeChar;
    if (codePoint == 0) return 0; // modifier-only record
    final encoded = utf8.encode(String.fromCharCode(codePoint));
    bytes.setRange(offset, offset + encoded.length, encoded);
    return encoded.length;
  }
}

// Marker message used to hand the reply port to the worker.
final class _StartReading {
  final SendPort replyPort;
  _StartReading(this.replyPort);
}
