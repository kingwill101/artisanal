import 'dart:io';

import 'terminal_windows_native.dart' show sharedWindowsInputStream;

import 'stdin_stream_shared.dart';

/// The byte source for [sharedStdinStream]. On Windows, the shared native
/// CONIN$ reader (bypasses Dart's stdin so Ctrl+Z does not latch the
/// stream into EOF when ENABLE_VIRTUAL_TERMINAL_INPUT is active). On other
/// platforms, plain [stdin].
///
/// [sharedWindowsInputStream] is process-singleton, so even if ultraviolet's
/// `defaultInput` and ultraviolet's `sharedStdinStream` both subscribe,
/// the input record stream is not split.
final Stream<List<int>> _stdinSource = Platform.isWindows
    ? sharedWindowsInputStream.start()
    : stdin;

final SharedInputStream _sharedStdin = SharedInputStream(_stdinSource);

Stream<List<int>> get sharedStdinStream => _sharedStdin.stream;

bool get isSharedStdinStreamStarted => _sharedStdin.isStarted;

Future<void> shutdownSharedStdinStream() => _sharedStdin.shutdown();
