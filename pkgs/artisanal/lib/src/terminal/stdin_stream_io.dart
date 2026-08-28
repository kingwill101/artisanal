import 'dart:async';
import 'dart:io';

import 'package:ultraviolet/ultraviolet.dart' show NativeWindowsInputStream;

import 'stdin_stream_shared.dart';

/// The byte source for [sharedStdinStream]. On Windows, the native CONIN$
/// reader (bypasses Dart's stdin so Ctrl+Z does not latch the stream into
/// EOF when ENABLE_VIRTUAL_TERMINAL_INPUT is active). On other platforms,
/// plain [stdin].
final Stream<List<int>> _stdinSource = Platform.isWindows
    ? _NativeSource()
    : stdin;

class _NativeSource extends Stream<List<int>> {
  final NativeWindowsInputStream _stream = NativeWindowsInputStream();

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return _stream.start().listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

final SharedInputStream _sharedStdin = SharedInputStream(_stdinSource);

Stream<List<int>> get sharedStdinStream => _sharedStdin.stream;

bool get isSharedStdinStreamStarted => _sharedStdin.isStarted;

/// Shuts down the shared stdin stream so the process can exit cleanly.
///
/// This cancels the underlying subscription to the source. After this is
/// called, [sharedStdinStream] should not be used again within the same
/// process. On Windows this also closes the native CONIN$ reader.
Future<void> shutdownSharedStdinStream() => _sharedStdin.shutdown();
