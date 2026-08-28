/// Shared broadcast input stream wrapper.
///
/// Dart's `stdin` is a single-subscription stream: once listened to, it cannot
/// be listened to again (even if cancelled). This wrapper fans out input into
/// a broadcast stream so TUIs can temporarily stop/restart input listening
/// (e.g. suspend, exec) without triggering "Bad state: Stream has already been
/// listened to".
///
/// Important: By design, the underlying source subscription stays alive once
/// started. This enables re-listening within the same process, but it can also
/// keep the Dart event loop alive on real TTYs. Call [shutdownSharedStdinStream]
/// when the process should be allowed to exit cleanly.
///
/// The actual byte source is platform-conditional: on Windows it is the native
/// CONIN$ reader (so Ctrl+Z does not latch the stream into EOF when
/// ENABLE_VIRTUAL_TERMINAL_INPUT is active); on other platforms it is plain
/// [stdin].
library;

export 'stdin_stream_shared.dart' show SharedInputStream;

export 'stdin_stream_stub.dart'
    if (dart.library.io) 'stdin_stream_io.dart';
