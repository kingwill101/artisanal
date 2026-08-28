import 'dart:async';
import 'dart:io';

import 'package:ultraviolet/ultraviolet.dart' show sharedWindowsInputStream;

import 'stdin_stream_shared.dart';

/// The byte source for [sharedStdinStream]. On Windows, the shared native
/// CONIN$ reader (bypasses Dart's stdin so Ctrl+Z does not latch the
/// stream into EOF when ENABLE_VIRTUAL_TERMINAL_INPUT is active). On other
/// platforms, plain [stdin].
///
/// [sharedWindowsInputStream] is process-singleton — repeated calls return
/// the same stream, so even if ultraviolet's `defaultInput` and artisanal's
/// `sharedStdinStream` both subscribe, the input record stream is not split.
final Stream<List<int>> _stdinSource = Platform.isWindows
    ? sharedWindowsInputStream.start()
    : stdin;

final SharedInputStream _sharedStdin = SharedInputStream(_stdinSource);

Stream<List<int>> get sharedStdinStream => _sharedStdin.stream;

bool get isSharedStdinStreamStarted => _sharedStdin.isStarted;

/// Shuts down the shared stdin stream so the process can exit cleanly.
///
/// This cancels the underlying subscription to the source. After this is
/// called, [sharedStdinStream] should not be used again within the same
/// process. On Windows this also closes the native CONIN$ reader (via
/// ultraviolet's [shutdownInput] from `Terminal.stop`).
Future<void> shutdownSharedStdinStream() => _sharedStdin.shutdown();
