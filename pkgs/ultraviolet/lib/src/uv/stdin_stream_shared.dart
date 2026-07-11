import 'dart:async';

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
class SharedInputStream {
  SharedInputStream(this._source);

  final Stream<List<int>> _source;

  StreamController<List<int>>? _controller;
  StreamSubscription<List<int>>? _subscription;
  bool _shutdown = false;

  bool get isStarted => _subscription != null;
  bool get isShutdown => _shutdown;

  Stream<List<int>> get stream {
    if (_shutdown) {
      throw StateError(
        'SharedInputStream is shut down (this usually means a previous TUI '
        'closed stdin for process exit).',
      );
    }
    _controller ??= StreamController<List<int>>.broadcast(
      onListen: _ensureStarted,
      onCancel: _onCancel,
    );
    return _controller!.stream;
  }

  void _ensureStarted() {
    if (_shutdown || _subscription != null) return;

    final controller = _controller;
    if (controller == null || controller.isClosed) return;

    _subscription = _source.listen(
      controller.add,
      onError: controller.addError,
      onDone: () {
        controller.close();
      },
      cancelOnError: false,
    );
  }

  Future<void>? _onCancel() {
    return null;
  }

  Future<void> shutdown() async {
    if (_shutdown) return;
    _shutdown = true;

    try {
      await _subscription?.cancel();
    } catch (_) {}
    _subscription = null;

    try {
      await _controller?.close();
    } catch (_) {}
    _controller = null;
  }
}
