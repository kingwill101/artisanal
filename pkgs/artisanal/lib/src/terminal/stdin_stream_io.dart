import 'dart:async';
import 'dart:io';

import 'package:ultraviolet/ultraviolet.dart' show NativeWindowsInputStream;

import 'stdin_stream_shared.dart';

/// The byte source for [sharedStdinStream]. On Windows, the native CONIN$
/// reader (bypasses Dart's stdin so Ctrl+Z does not latch the stream into
/// EOF when ENABLE_VIRTUAL_TERMINAL_INPUT is active). On other platforms,
/// plain [stdin].
///
/// [NativeWindowsInputStream.start] only builds a [StreamController] — the
/// worker isolate is spawned from the controller's `onListen` callback, so
/// no side effect occurs before the first subscriber.
final Stream<List<int>> _stdinSource = Platform.isWindows
    ? NativeWindowsInputStream().start()
    : stdin;

final SharedInputStream _sharedStdin = SharedInputStream(_stdinSource);

Stream<List<int>> get sharedStdinStream => _sharedStdin.stream;

bool get isSharedStdinStreamStarted => _sharedStdin.isStarted;

/// Shuts down the shared stdin stream so the process can exit cleanly.
///
/// This cancels the underlying subscription to the source. After this is
/// called, [sharedStdinStream] should not be used again within the same
/// process. On Windows this also closes the native CONIN$ reader.
Future<void> shutdownSharedStdinStream() => _sharedStdin.shutdown();
