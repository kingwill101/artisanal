/// Drag gesture recognizer.
///
/// [DragGestureRecognizer] detects drag gestures: pointer-down followed
/// by movement beyond the drag slop threshold.
library;

import 'package:artisanal/runtime.dart' show MouseMsg, MouseButton;

import '../layout/geometry.dart' show Offset;
import 'events.dart';
import 'recognizer.dart';

/// Recognizes drag gestures.
///
/// A drag starts when the pointer moves beyond [kDragSlop] cells from
/// the initial down position. Once started, [onDragStart] fires,
/// followed by [onDragUpdate] for each subsequent movement, and
/// [onDragEnd] on pointer release.
class DragGestureRecognizer extends GestureRecognizer {
  /// Callback fired when the drag begins (pointer moved beyond slop).
  GestureDragStartCallback? onDragStart;

  /// Callback fired for each pointer movement during the drag.
  GestureDragUpdateCallback? onDragUpdate;

  /// Callback fired when the drag ends (pointer released).
  GestureDragEndCallback? onDragEnd;

  /// Minimum distance in cells before a drag is recognized.
  static const double kDragSlop = 1.0;

  bool _dragStarted = false;
  Offset? _lastPosition;
  Offset? _downGlobal;
  MouseButton _downButton = MouseButton.left;

  @override
  void handlePointerDown(MouseMsg event, Offset localPosition) {
    super.handlePointerDown(event, localPosition);
    _dragStarted = false;
    _lastPosition = localPosition;
    _downGlobal = Offset(event.x.toDouble(), event.y.toDouble());
    _downButton = event.button;
  }

  @override
  void handlePointerMove(MouseMsg event, Offset localPosition) {
    if (state == GestureRecognizerState.defunct) return;
    if (initialPosition == null) return; // No prior pointer-down.

    final globalPos = Offset(event.x.toDouble(), event.y.toDouble());

    if (!_dragStarted) {
      // Check if we've moved beyond the drag slop.
      final delta = localPosition - initialPosition!;
      final distance = delta.dx * delta.dx + delta.dy * delta.dy;
      if (distance > kDragSlop * kDragSlop) {
        _dragStarted = true;
        resolve(GestureDisposition.accepted);

        addCmd(
          onDragStart?.call(
            DragStartDetails(
              globalPosition: _downGlobal ?? globalPos,
              localPosition: initialPosition!,
              button: _downButton,
            ),
          ),
        );

        // Also fire the first update with the delta from start to current.
        addCmd(
          onDragUpdate?.call(
            DragUpdateDetails(
              globalPosition: globalPos,
              localPosition: localPosition,
              delta: localPosition - initialPosition!,
            ),
          ),
        );
        _lastPosition = localPosition;
      }
    } else {
      // Already dragging — fire update with delta.
      final delta = localPosition - _lastPosition!;
      addCmd(
        onDragUpdate?.call(
          DragUpdateDetails(
            globalPosition: globalPos,
            localPosition: localPosition,
            delta: delta,
          ),
        ),
      );
      _lastPosition = localPosition;
    }
  }

  @override
  void handlePointerUp(MouseMsg event, Offset localPosition) {
    if (_dragStarted) {
      final globalPos = Offset(event.x.toDouble(), event.y.toDouble());
      addCmd(
        onDragEnd?.call(
          DragEndDetails(
            globalPosition: globalPos,
            localPosition: localPosition,
          ),
        ),
      );
    }
    state = GestureRecognizerState.defunct;
  }

  @override
  void acceptGesture() {
    state = GestureRecognizerState.accepted;
  }

  @override
  void rejectGesture() {
    _dragStarted = false;
    state = GestureRecognizerState.defunct;
  }

  @override
  void reset() {
    _dragStarted = false;
    _lastPosition = null;
    _downGlobal = null;
    _downButton = MouseButton.left;
    super.reset();
  }
}
