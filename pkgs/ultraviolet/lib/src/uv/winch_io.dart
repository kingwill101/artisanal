import 'dart:async';
import 'dart:io';

/// Listens for terminal resize signals (SIGWINCH) and provides the current
/// terminal dimensions.
class SizeNotifier {
  SizeNotifier();

  StreamSubscription<ProcessSignal>? _subscription;
  final _controller = StreamController<void>.broadcast();

  /// Stream that receives terminal size change notifications.
  Stream<void> get stream => _controller.stream;

  /// Starts listening for window size changes.
  void start() {
    if (Platform.isWindows) {
      return;
    }

    _subscription = ProcessSignal.sigwinch.watch().listen((_) {
      _controller.add(null);
    });
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
    if (stdout.hasTerminal) {
      return (stdout.terminalColumns, stdout.terminalLines);
    }
    return (80, 24);
  }

  /// Returns the current size of the terminal window in cells and pixels.
  ({({int width, int height}) cells, ({int width, int height}) pixels})
  getWindowSize() {
    final (w, h) = getSize();
    return (cells: (width: w, height: h), pixels: (width: 0, height: 0));
  }
}
