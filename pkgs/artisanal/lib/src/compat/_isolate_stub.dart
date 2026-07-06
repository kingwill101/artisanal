// Stub for dart:isolate on web/WASM platforms.
// On web, Isolate.run is not available; image decoding falls back to the main thread.

import 'dart:async';

/// Stub for [dart:isolate Isolate].
class Isolate {
  /// Web stub: runs [computation] directly on the current thread.
  static Future<R> run<R>(
    FutureOr<R> Function() computation, {
    String? debugName,
  }) async => computation();
}
