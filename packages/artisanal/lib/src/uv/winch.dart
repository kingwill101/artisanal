/// Window change (SIGWINCH) notification handling.
///
/// Listens for terminal resize signals and provides updates on the current
/// terminal dimensions.
///
/// {@category Ultraviolet}
/// {@subCategory Input}
library;

import 'dart:async';
import 'dart:io';

/// SizeNotifier represents a notifier that listens for window size
/// changes using the SIGWINCH signal and notifies the given stream.
///
/// Upstream: `third_party/ultraviolet/winch.go`.
class SizeNotifier {
  SizeNotifier();

  StreamSubscription<ProcessSignal>? _subscription;
  final _controller = StreamController<ProcessSignal>.broadcast();

  /// Stream that receives terminal size change notifications.
  Stream<ProcessSignal> get stream => _controller.stream;

  /// Starts listening for window size changes.
  void start() {
    if (Platform.isWindows) {
      // Windows handles size changes via the console input buffer,
      // which is typically handled by the TerminalReader/EventDecoder.
      return;
    }

    _subscription = ProcessSignal.sigwinch.watch().listen((signal) {
      _controller.add(signal);
    });
  }

  /// Stops the notifier and cleans up resources.
  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  /// Returns the current cell size of the terminal window.
  ///
  /// Returns (width, height).
  (int, int) getSize() {
    if (stdout.hasTerminal) {
      return (stdout.terminalColumns, stdout.terminalLines);
    }
    return (80, 24);
  }

  /// Returns the current size of the terminal window in cells and pixels.
  ///
  /// Note: Pixel size is currently not supported in Dart's dart:io and will return (0, 0).
  ({({int width, int height}) cells, ({int width, int height}) pixels})
  getWindowSize() {
    final (w, h) = getSize();
    return (cells: (width: w, height: h), pixels: (width: 0, height: 0));
  }
}
