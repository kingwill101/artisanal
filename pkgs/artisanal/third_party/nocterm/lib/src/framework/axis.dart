import 'package:nocterm/src/components/basic.dart' show Axis;

/// The direction of a scroll, relative to the axis of the scrollable.
enum AxisDirection {
  /// Towards the top of the screen.
  up,

  /// Towards the right side of the screen.
  right,

  /// Towards the bottom of the screen (default for vertical scrolling).
  down,

  /// Towards the left side of the screen.
  left,
}

/// Returns whether the given axis direction is reversed.
///
/// - [AxisDirection.up] and [AxisDirection.left] are reversed.
/// - [AxisDirection.down] and [AxisDirection.right] are not reversed.
bool axisDirectionIsReversed(AxisDirection axisDirection) {
  switch (axisDirection) {
    case AxisDirection.up:
    case AxisDirection.left:
      return true;
    case AxisDirection.down:
    case AxisDirection.right:
      return false;
  }
}

/// Converts an [Axis] and reverse flag to an [AxisDirection].
AxisDirection axisToAxisDirection(Axis axis, {bool reverse = false}) {
  switch (axis) {
    case Axis.horizontal:
      return reverse ? AxisDirection.left : AxisDirection.right;
    case Axis.vertical:
      return reverse ? AxisDirection.up : AxisDirection.down;
  }
}
