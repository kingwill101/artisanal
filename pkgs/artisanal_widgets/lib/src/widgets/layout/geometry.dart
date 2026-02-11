/// Geometry primitives for widget layout.
@experimental
library;

import 'package:meta/meta.dart' show experimental;

import 'dart:math' as math;

/// An offset in terminal cell units (column, row).
class Offset {
  const Offset(this.dx, this.dy);

  static const zero = Offset(0, 0);

  final double dx;
  final double dy;

  Offset operator +(Offset other) => Offset(dx + other.dx, dy + other.dy);
  Offset operator -(Offset other) => Offset(dx - other.dx, dy - other.dy);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Offset && dx == other.dx && dy == other.dy;

  @override
  int get hashCode => Object.hash(dx, dy);

  @override
  String toString() => 'Offset($dx, $dy)';
}

/// A rectangle defined by offset + size, in terminal cell units.
class Rect {
  const Rect.fromLTWH(this.left, this.top, this.width, this.height);

  Rect.fromOffsetAndSize(Offset offset, Size size)
    : left = offset.dx,
      top = offset.dy,
      width = size.width,
      height = size.height;

  final double left;
  final double top;
  final double width;
  final double height;

  double get right => left + width;
  double get bottom => top + height;

  /// Returns `true` if the point (x, y) is inside this rectangle.
  bool contains(double x, double y) =>
      x >= left && x < right && y >= top && y < bottom;

  @override
  String toString() => 'Rect($left, $top, $width, $height)';
}

/// Size in terminal cell units.
class Size {
  const Size(this.width, this.height);

  static const zero = Size(0, 0);

  final double width;
  final double height;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Size && width == other.width && height == other.height;

  @override
  int get hashCode => Object.hash(width, height);
}

/// Box constraints for layout.
class BoxConstraints {
  BoxConstraints({
    this.minWidth = 0,
    this.maxWidth = double.infinity,
    this.minHeight = 0,
    this.maxHeight = double.infinity,
  });

  BoxConstraints.tight(Size size)
    : minWidth = size.width,
      maxWidth = size.width,
      minHeight = size.height,
      maxHeight = size.height;

  BoxConstraints.expand({double? width, double? height})
    : minWidth = width ?? double.infinity,
      maxWidth = width ?? double.infinity,
      minHeight = height ?? double.infinity,
      maxHeight = height ?? double.infinity;

  final double minWidth;
  final double maxWidth;
  final double minHeight;
  final double maxHeight;

  double constrainWidth(double width) {
    return math.min(math.max(width, minWidth), maxWidth);
  }

  double constrainHeight(double height) {
    return math.min(math.max(height, minHeight), maxHeight);
  }

  Size constrain(Size size) {
    return Size(constrainWidth(size.width), constrainHeight(size.height));
  }

  /// Returns a copy with the minimum constraints removed (set to zero),
  /// keeping the maximum constraints unchanged.
  BoxConstraints loosen() {
    return BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight);
  }

  bool get hasBoundedWidth => maxWidth < double.infinity;
  bool get hasBoundedHeight => maxHeight < double.infinity;
  bool get isTight => minWidth == maxWidth && minHeight == maxHeight;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BoxConstraints &&
          minWidth == other.minWidth &&
          maxWidth == other.maxWidth &&
          minHeight == other.minHeight &&
          maxHeight == other.maxHeight;

  @override
  int get hashCode => Object.hash(minWidth, maxWidth, minHeight, maxHeight);
}

// ---------------------------------------------------------------------------
// Hit testing
// ---------------------------------------------------------------------------

/// A single entry in a [HitTestResult], linking a render object to the
/// local coordinates at which it was hit.
class HitTestEntry {
  const HitTestEntry(this.renderObject, {this.localX = 0, this.localY = 0});

  /// The render object that was hit.
  final Object renderObject;

  /// X coordinate in the render object's local coordinate space.
  final double localX;

  /// Y coordinate in the render object's local coordinate space.
  final double localY;
}

/// Accumulated result of a hit test, ordered deepest-first.
class HitTestResult {
  final List<HitTestEntry> path = [];

  void add(HitTestEntry entry) => path.add(entry);

  bool get isNotEmpty => path.isNotEmpty;
  bool get isEmpty => path.isEmpty;
}
