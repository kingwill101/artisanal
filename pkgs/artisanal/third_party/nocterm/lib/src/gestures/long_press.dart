import 'dart:async';
import '../keyboard/mouse_event.dart';
import '../framework/framework.dart';
import 'recognizer.dart';
import 'events.dart';

/// Recognizes long press gestures.
///
/// A long press is recognized when the pointer is held down in the same
/// location for a specified duration.
class LongPressGestureRecognizer extends GestureRecognizer {
  LongPressGestureRecognizer({
    this.onLongPress,
    this.onLongPressStart,
    this.onLongPressEnd,
    this.duration = const Duration(milliseconds: 500),
  });

  /// Called when a long press is detected.
  GestureLongPressCallback? onLongPress;

  /// Called when a long press starts.
  GestureLongPressStartCallback? onLongPressStart;

  /// Called when a long press ends.
  GestureLongPressEndCallback? onLongPressEnd;

  /// The duration required to trigger a long press.
  final Duration duration;

  Offset? _downPosition;
  Timer? _longPressTimer;
  bool _longPressAccepted = false;

  static const double _kTouchSlop = 2.0; // cells

  @override
  void handlePointerDown(MouseEvent event, Offset localPosition) {
    _downPosition = localPosition;
    _longPressAccepted = false;

    // Start timer for long press
    _longPressTimer?.cancel();
    _longPressTimer = Timer(duration, () {
      if (_downPosition != null) {
        _acceptLongPress(event, localPosition);
      }
    });
  }

  @override
  void handlePointerUp(MouseEvent event, Offset localPosition) {
    // Cancel the timer if pointer is released before long press
    _longPressTimer?.cancel();

    if (_longPressAccepted && onLongPressEnd != null) {
      final details = LongPressEndDetails(
        globalPosition: Offset(event.x.toDouble(), event.y.toDouble()),
        localPosition: localPosition,
      );
      onLongPressEnd?.call(details);
    }

    _reset();
  }

  @override
  void handlePointerMove(MouseEvent event, Offset localPosition) {
    if (_downPosition == null) {
      return;
    }

    // Check if moved too far from initial position
    final dx = (localPosition.dx - _downPosition!.dx).abs();
    final dy = (localPosition.dy - _downPosition!.dy).abs();

    if (dx > _kTouchSlop || dy > _kTouchSlop) {
      // Moved too far, cancel long press
      _longPressTimer?.cancel();
      if (!_longPressAccepted) {
        rejectGesture();
      }
    }
  }

  void _acceptLongPress(MouseEvent event, Offset localPosition) {
    _longPressAccepted = true;

    if (onLongPressStart != null) {
      final details = LongPressStartDetails(
        globalPosition: Offset(event.x.toDouble(), event.y.toDouble()),
        localPosition: localPosition,
      );
      onLongPressStart?.call(details);
    }

    onLongPress?.call();
  }

  @override
  void acceptGesture() {
    // No additional logic needed beyond base implementation
  }

  @override
  void rejectGesture() {
    super.rejectGesture();
    _reset();
  }

  @override
  void resolve(GestureDisposition disposition) {
    if (disposition == GestureDisposition.rejected) {
      _longPressTimer?.cancel();
    }
    _reset();
  }

  void _reset() {
    _downPosition = null;
    _longPressAccepted = false;
    _longPressTimer?.cancel();
    _longPressTimer = null;
    reset();
  }

  @override
  void dispose() {
    _longPressTimer?.cancel();
    super.dispose();
  }
}
