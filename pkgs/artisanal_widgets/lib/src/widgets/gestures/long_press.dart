/// Long-press gesture recognizer.
///
/// [LongPressGestureRecognizer] detects when a pointer is held down
/// for a configurable duration without moving beyond the touch slop.
library;

import 'dart:async' show Timer;

import 'package:artisanal/tui.dart' show MouseMsg;

import '../layout/geometry.dart' show Offset;
import 'events.dart';
import 'recognizer.dart';

/// Recognizes long-press gestures.
///
/// A long-press is a pointer-down held for [duration] without moving
/// beyond [kTouchSlop] cells. On timer expiry the gesture is accepted
/// and [onLongPressStart] / [onLongPress] fire. On pointer-up after
/// acceptance, [onLongPressEnd] fires.
class LongPressGestureRecognizer extends GestureRecognizer {
  /// Callback fired when the long-press is first recognized.
  GestureLongPressCallback? onLongPress;

  /// Callback fired with position details when the long-press starts.
  GestureLongPressStartCallback? onLongPressStart;

  /// Callback fired when the pointer is released after a long-press.
  GestureLongPressEndCallback? onLongPressEnd;

  /// How long the pointer must be held before the long-press triggers.
  Duration duration = const Duration(milliseconds: 500);

  /// Maximum distance in cells the pointer can move before cancelling.
  static const double kTouchSlop = 2.0;

  Timer? _timer;
  bool _longPressAccepted = false;
  Offset? _downGlobal;
  Offset? _downLocal;

  @override
  void handlePointerDown(MouseMsg event, Offset localPosition) {
    super.handlePointerDown(event, localPosition);
    _downGlobal = Offset(event.x.toDouble(), event.y.toDouble());
    _downLocal = localPosition;
    _longPressAccepted = false;

    _timer = Timer(duration, () {
      _longPressAccepted = true;
      resolve(GestureDisposition.accepted);
    });
  }

  @override
  void handlePointerMove(MouseMsg event, Offset localPosition) {
    if (state != GestureRecognizerState.possible || _longPressAccepted) return;

    final delta = localPosition - initialPosition!;
    final distance = delta.dx * delta.dx + delta.dy * delta.dy;
    if (distance > kTouchSlop * kTouchSlop) {
      // Moved too far — cancel the timer and reject.
      _timer?.cancel();
      _timer = null;
      resolve(GestureDisposition.rejected);
    }
  }

  @override
  void handlePointerUp(MouseMsg event, Offset localPosition) {
    if (_longPressAccepted) {
      final globalPos = Offset(event.x.toDouble(), event.y.toDouble());
      addCmd(
        onLongPressEnd?.call(
          LongPressEndDetails(
            globalPosition: globalPos,
            localPosition: localPosition,
          ),
        ),
      );
      state = GestureRecognizerState.defunct;
    } else {
      // Released before the timer fired — not a long-press.
      _timer?.cancel();
      _timer = null;
      resolve(GestureDisposition.rejected);
    }
  }

  @override
  void acceptGesture() {
    state = GestureRecognizerState.accepted;
    _longPressAccepted = true;

    addCmd(
      onLongPressStart?.call(
        LongPressStartDetails(
          globalPosition: _downGlobal ?? Offset.zero,
          localPosition: _downLocal ?? Offset.zero,
        ),
      ),
    );
    addCmd(onLongPress?.call());
  }

  @override
  void rejectGesture() {
    _timer?.cancel();
    _timer = null;
    state = GestureRecognizerState.defunct;
  }

  @override
  void reset() {
    _timer?.cancel();
    _timer = null;
    _longPressAccepted = false;
    _downGlobal = null;
    _downLocal = null;
    super.reset();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }
}
