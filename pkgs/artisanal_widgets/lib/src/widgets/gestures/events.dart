/// Gesture event detail classes and typed callback signatures.
///
/// Provides structured detail objects that carry position information
/// and modifier key state for gesture callbacks. All callbacks return
/// `Cmd?` to fit the TEA (The Elm Architecture) pattern.
library;

import 'package:artisanal/runtime.dart' show Cmd, MouseMsg, MouseButton;

import '../layout/geometry.dart' show Offset;

// ---------------------------------------------------------------------------
// Detail classes
// ---------------------------------------------------------------------------

/// Details for a tap-down event.
class TapDownDetails {
  const TapDownDetails({
    required this.globalPosition,
    required this.localPosition,
    this.button = MouseButton.left,
    this.ctrl = false,
    this.alt = false,
    this.shift = false,
  });

  /// Position in global (terminal) coordinates.
  final Offset globalPosition;

  /// Position in the gesture detector's local coordinate space.
  final Offset localPosition;

  /// Which mouse button was pressed.
  final MouseButton button;

  /// Whether the Ctrl modifier was held.
  final bool ctrl;

  /// Whether the Alt modifier was held.
  final bool alt;

  /// Whether the Shift modifier was held.
  final bool shift;

  /// Whether any modifier key is held.
  bool get hasModifier => ctrl || alt || shift;
}

/// Details for a tap-up event.
class TapUpDetails {
  const TapUpDetails({
    required this.globalPosition,
    required this.localPosition,
  });

  /// Position in global (terminal) coordinates.
  final Offset globalPosition;

  /// Position in the gesture detector's local coordinate space.
  final Offset localPosition;
}

/// Details for the start of a long-press gesture.
class LongPressStartDetails {
  const LongPressStartDetails({
    required this.globalPosition,
    required this.localPosition,
  });

  final Offset globalPosition;
  final Offset localPosition;
}

/// Details for the end of a long-press gesture.
class LongPressEndDetails {
  const LongPressEndDetails({
    required this.globalPosition,
    required this.localPosition,
  });

  final Offset globalPosition;
  final Offset localPosition;
}

/// Details for the start of a drag gesture.
class DragStartDetails {
  const DragStartDetails({
    required this.globalPosition,
    required this.localPosition,
    this.button = MouseButton.left,
  });

  final Offset globalPosition;
  final Offset localPosition;
  final MouseButton button;
}

/// Details for a drag update event.
class DragUpdateDetails {
  const DragUpdateDetails({
    required this.globalPosition,
    required this.localPosition,
    required this.delta,
  });

  /// Current position in global (terminal) coordinates.
  final Offset globalPosition;

  /// Current position in local coordinate space.
  final Offset localPosition;

  /// Change in position since the last drag event.
  final Offset delta;
}

/// Details for the end of a drag gesture.
class DragEndDetails {
  const DragEndDetails({
    required this.globalPosition,
    required this.localPosition,
  });

  final Offset globalPosition;
  final Offset localPosition;
}

// ---------------------------------------------------------------------------
// Typed callback signatures (TEA-compatible, returning Cmd?)
// ---------------------------------------------------------------------------

/// Callback for tap-down events with position and modifier details.
typedef GestureTapDownCallback = Cmd? Function(TapDownDetails details);

/// Callback for tap-up events with position details.
typedef GestureTapUpCallback = Cmd? Function(TapUpDetails details);

/// Callback for simple tap events (press + release within slop).
typedef GestureTapCallback = Cmd? Function();

/// Callback for tap cancellation (pointer moved beyond slop).
typedef GestureTapCancelCallback = Cmd? Function();

/// Callback for double-tap events.
typedef GestureDoubleTapCallback = Cmd? Function();

/// Callback for long-press events.
typedef GestureLongPressCallback = Cmd? Function();

/// Callback for the start of a long-press gesture.
typedef GestureLongPressStartCallback =
    Cmd? Function(LongPressStartDetails details);

/// Callback for the end of a long-press gesture.
typedef GestureLongPressEndCallback =
    Cmd? Function(LongPressEndDetails details);

/// Callback for the start of a drag gesture.
typedef GestureDragStartCallback = Cmd? Function(DragStartDetails details);

/// Callback for drag update events.
typedef GestureDragUpdateCallback = Cmd? Function(DragUpdateDetails details);

/// Callback for the end of a drag gesture.
typedef GestureDragEndCallback = Cmd? Function(DragEndDetails details);

/// Callback for mouse wheel events (passes through raw MouseMsg).
typedef GestureWheelCallback = Cmd? Function(MouseMsg msg);

/// Callback for mouse enter events.
typedef MouseEnterCallback = Cmd? Function(MouseMsg msg);

/// Callback for mouse exit events.
typedef MouseExitCallback = Cmd? Function(MouseMsg msg);
