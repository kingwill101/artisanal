import 'dart:async';

/// Stub [SizeNotifier] for platforms without SIGWINCH.
class SizeNotifier {
  SizeNotifier();

  StreamSubscription? _subscription;
  final _controller = StreamController<void>.broadcast();

  /// Stream that receives terminal size change notifications.
  Stream<void> get stream => _controller.stream;

  /// Starts listening for window size changes.
  void start() {
  }

  /// Stops the notifier and cleans up resources.
  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    if (!_controller.isClosed) {
      await _controller.close();
    }
  }

  /// Returns the current cell size of the terminal window.
  (int, int) getSize() {
    return (80, 24);
  }

  /// Returns the current size of the terminal window in cells and pixels.
  ({({int width, int height}) cells, ({int width, int height}) pixels})
  getWindowSize() {
    final (w, h) = getSize();
    return (cells: (width: w, height: h), pixels: (width: 0, height: 0));
  }
}
