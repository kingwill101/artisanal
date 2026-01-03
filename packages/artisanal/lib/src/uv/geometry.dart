/// Geometry primitives for UV rendering: [Position] and [Rectangle].
///
/// These types describe integer cell coordinates and inclusive‑exclusive
/// bounds (`[min, max)`), used throughout [Canvas] drawing, [Screen]
/// clipping, and [Layer] composition. The [rect] helper constructs concise
/// rectangles for common operations.
///
/// {@category Ultraviolet}
/// {@subCategory Geometry}
///
/// {@macro artisanal_uv_concept_overview}
/// {@macro artisanal_uv_renderer_overview}
/// {@macro artisanal_uv_performance_tips}
///
/// Example:
/// ```dart
/// final bar = rect(0, 0, 80, 1);
/// if (!bar.isEmpty) {
///   // use bar with Screen/Canvas operations
/// }
/// ```
library;
import 'dart:math' as math;

/// Upstream: `third_party/ultraviolet/buffer.go` (`Position`, `Rectangle`).
/// A 2D integer coordinate in terminal cell space.
///
/// Represents the location of a cell with `x` (column) and `y` (row).
final class Position {
  const Position(this.x, this.y);

  final int x;
  final int y;

  @override
  bool operator ==(Object other) =>
      other is Position && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);
}

/// Rectangle with inclusive-exclusive bounds: `[min, max)`.
///
/// Upstream: `third_party/ultraviolet/buffer.go` (`Rectangle`).
/// A rectangle with inclusive-exclusive bounds: `[min, max)`.
///
/// Describes a region in cell coordinates using top-left ([minX], [minY]) and
/// bottom-right ([maxX], [maxY]) corners. Width and height are derived.
final class Rectangle {
  const Rectangle({
    required this.minX,
    required this.minY,
    required this.maxX,
    required this.maxY,
  });

  final int minX;
  final int minY;
  final int maxX;
  final int maxY;

  /// The width of this rectangle in cells.
  int get width => maxX - minX;

  /// The height of this rectangle in cells.
  int get height => maxY - minY;

  /// Whether this rectangle has no area.
  bool get isEmpty => width <= 0 || height <= 0;

  /// Returns whether [p] lies within this rectangle.
  bool contains(Position p) =>
      p.x >= minX && p.x < maxX && p.y >= minY && p.y < maxY;

  /// Returns whether [other] is entirely contained within this rectangle.
  bool containsRect(Rectangle other) =>
      other.minX >= minX &&
      other.minY >= minY &&
      other.maxX <= maxX &&
      other.maxY <= maxY;

  /// Returns whether [other] overlaps this rectangle.
  bool overlaps(Rectangle other) =>
      !(other.maxX <= minX ||
          other.minX >= maxX ||
          other.maxY <= minY ||
          other.minY >= maxY);

  /// Returns the minimal rectangle that contains both this and [other].
  Rectangle union(Rectangle other) {
    if (isEmpty) return other;
    if (other.isEmpty) return this;
    return Rectangle(
      minX: math.min(minX, other.minX),
      minY: math.min(minY, other.minY),
      maxX: math.max(maxX, other.maxX),
      maxY: math.max(maxY, other.maxY),
    );
  }

  /// Returns the intersection of this and [other], or an empty rectangle.
  Rectangle intersect(Rectangle other) {
    final minX = math.max(this.minX, other.minX);
    final minY = math.max(this.minY, other.minY);
    final maxX = math.min(this.maxX, other.maxX);
    final maxY = math.min(this.maxY, other.maxY);
    if (minX >= maxX || minY >= maxY) {
      return const Rectangle(minX: 0, minY: 0, maxX: 0, maxY: 0);
    }
    return Rectangle(minX: minX, minY: minY, maxX: maxX, maxY: maxY);
  }

  @override
  bool operator ==(Object other) =>
      other is Rectangle &&
      other.minX == minX &&
      other.minY == minY &&
      other.maxX == maxX &&
      other.maxY == maxY;

  @override
  int get hashCode => Object.hash(minX, minY, maxX, maxY);
}

/// Creates a rectangle from origin ([x], [y]) and size ([width], [height]).
Rectangle rect(int x, int y, int width, int height) =>
    Rectangle(minX: x, minY: y, maxX: x + width, maxY: y + height);
