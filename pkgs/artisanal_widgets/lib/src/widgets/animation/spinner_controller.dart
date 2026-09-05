/// Bridges the TUI spinner infrastructure with the widget framework.
///
/// [SpinnerController] is a [ValueNotifier] that cycles through a
/// [Spinner]'s frames on a timer and notifies listeners on each tick.
///
/// Use with [ValueListenableBuilder] or [ListenableBuilder] to render
/// animated spinners in the widget tree.
library;

import 'dart:async';

import 'package:artisanal/runtime.dart' show Spinner;

import 'package:listen/listen.dart' show ValueNotifier;

/// A [ValueNotifier] that cycles through [Spinner.frames] on a periodic timer.
///
/// ```dart
/// final controller = SpinnerController(Spinners.scanner());
///
/// // In build:
/// ValueListenableBuilder<String>(
///   valueListenable: controller,
///   builder: (context, frame, _) => Text(frame),
/// )
/// ```
class SpinnerController extends ValueNotifier<String> {
  /// Creates a controller that animates [spinner].
  ///
  /// If [autoStart] is true (default), the animation starts immediately.
  SpinnerController(this.spinner, {bool autoStart = true})
    : super(spinner.frames.first) {
    if (autoStart) _start();
  }

  /// The spinner animation being driven.
  final Spinner spinner;

  int _frame = 0;
  Timer? _timer;

  /// Whether the animation is currently running.
  bool get isRunning => _timer != null;

  /// Starts or restarts the animation from the first frame.
  void start() {
    _frame = 0;
    value = spinner.frames.first;
    _start();
  }

  /// Stops the animation.
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void _start() {
    _timer?.cancel();
    _timer = Timer.periodic(spinner.fps, (_) => _advance());
  }

  void _advance() {
    _frame = (_frame + 1) % spinner.frames.length;
    value = spinner.frames[_frame];
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
