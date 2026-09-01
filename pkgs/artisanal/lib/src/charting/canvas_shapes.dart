/// World-coordinate shapes for terminal canvases.
library;

import 'dart:math' as math;

import 'package:ultraviolet/core.dart';
import 'braille.dart';

/// A finite range used to project world coordinates onto a terminal canvas.
final class CanvasRange {
  /// Creates a range from [min] to [max].
  const CanvasRange(this.min, this.max) : assert(max > min);

  /// Inclusive lower bound.
  final double min;

  /// Inclusive upper bound.
  final double max;

  double get _span => max - min;

  bool _contains(double value) => value >= min && value <= max;
}

/// A point in a canvas's world-coordinate system.
final class CanvasPoint {
  /// Creates a point at ([x], [y]).
  const CanvasPoint(this.x, this.y);

  final double x;
  final double y;
}

/// Something that can draw itself through a [CanvasPainter].
abstract interface class CanvasShape {
  /// Draws this shape.
  void draw(CanvasPainter painter);
}

/// Projects world coordinates onto a high-resolution braille canvas.
///
/// The world uses the conventional mathematical orientation: X increases to
/// the right and Y increases upward. The painter clips points and lines to the
/// configured bounds before converting them to terminal dot coordinates.
final class CanvasPainter {
  /// Creates a painter for [canvas].
  CanvasPainter(
    this.canvas, {
    this.xBounds = const CanvasRange(0, 100),
    this.yBounds = const CanvasRange(0, 100),
  });

  /// The high-resolution backing canvas.
  final BrailleCanvas canvas;

  /// Visible horizontal world range.
  final CanvasRange xBounds;

  /// Visible vertical world range.
  final CanvasRange yBounds;

  /// Projects a world point to braille-dot coordinates.
  ///
  /// Returns `null` when the point is outside the visible world bounds.
  Position? project(double x, double y) {
    if (!xBounds._contains(x) || !yBounds._contains(y)) return null;
    final normalizedX = (x - xBounds.min) / xBounds._span;
    final normalizedY = (y - yBounds.min) / yBounds._span;
    return Position(
      (normalizedX * (canvas.dotWidth - 1)).round(),
      (canvas.dotHeight - 1) - (normalizedY * (canvas.dotHeight - 1)).round(),
    );
  }

  /// Paints a world-coordinate point if it is visible.
  void paint(double x, double y, {UvStyle style = const UvStyle()}) {
    final point = project(x, y);
    if (point == null) return;
    canvas.point(point.x, point.y, style: style);
  }

  /// Draws [shape].
  void draw(CanvasShape shape) => shape.draw(this);

  /// Draws a clipped line between two world-coordinate points.
  void line(
    double x1,
    double y1,
    double x2,
    double y2, {
    UvStyle style = const UvStyle(),
  }) {
    final clipped = _clipLine(x1, y1, x2, y2);
    if (clipped == null) return;
    final start = project(clipped.x1, clipped.y1);
    final end = project(clipped.x2, clipped.y2);
    if (start == null || end == null) return;
    _drawDotLine(start.x, start.y, end.x, end.y, style);
  }

  ({double x1, double y1, double x2, double y2})? _clipLine(
    double x1,
    double y1,
    double x2,
    double y2,
  ) {
    var firstCode = _outCode(x1, y1);
    var secondCode = _outCode(x2, y2);

    while (true) {
      if ((firstCode | secondCode) == 0) {
        return (x1: x1, y1: y1, x2: x2, y2: y2);
      }
      if ((firstCode & secondCode) != 0) return null;

      final code = firstCode != 0 ? firstCode : secondCode;
      late double x;
      late double y;
      if ((code & _above) != 0) {
        x = x1 + (x2 - x1) * (yBounds.max - y1) / (y2 - y1);
        y = yBounds.max;
      } else if ((code & _below) != 0) {
        x = x1 + (x2 - x1) * (yBounds.min - y1) / (y2 - y1);
        y = yBounds.min;
      } else if ((code & _right) != 0) {
        y = y1 + (y2 - y1) * (xBounds.max - x1) / (x2 - x1);
        x = xBounds.max;
      } else {
        y = y1 + (y2 - y1) * (xBounds.min - x1) / (x2 - x1);
        x = xBounds.min;
      }

      if (code == firstCode) {
        x1 = x;
        y1 = y;
        firstCode = _outCode(x1, y1);
      } else {
        x2 = x;
        y2 = y;
        secondCode = _outCode(x2, y2);
      }
    }
  }

  int _outCode(double x, double y) {
    var code = 0;
    if (x < xBounds.min) {
      code |= _left;
    } else if (x > xBounds.max) {
      code |= _right;
    }
    if (y < yBounds.min) {
      code |= _below;
    } else if (y > yBounds.max) {
      code |= _above;
    }
    return code;
  }

  void _drawDotLine(int x1, int y1, int x2, int y2, UvStyle style) {
    var x = x1;
    var y = y1;
    final dx = (x2 - x1).abs();
    final stepX = x1 < x2 ? 1 : -1;
    final dy = -(y2 - y1).abs();
    final stepY = y1 < y2 ? 1 : -1;
    var error = dx + dy;

    while (true) {
      canvas.point(x, y, style: style);
      if (x == x2 && y == y2) return;
      final doubledError = error * 2;
      if (doubledError >= dy) {
        error += dy;
        x += stepX;
      }
      if (doubledError <= dx) {
        error += dx;
        y += stepY;
      }
    }
  }

  static const _left = 1;
  static const _right = 2;
  static const _below = 4;
  static const _above = 8;
}

/// A line between two world-coordinate points.
final class CanvasLine implements CanvasShape {
  const CanvasLine({
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
    this.style = const UvStyle(),
  });

  final double x1;
  final double y1;
  final double x2;
  final double y2;
  final UvStyle style;

  @override
  void draw(CanvasPainter painter) =>
      painter.line(x1, y1, x2, y2, style: style);
}

/// An outlined rectangle positioned from its bottom-left corner.
final class CanvasRectangle implements CanvasShape {
  const CanvasRectangle({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.style = const UvStyle(),
  });

  final double x;
  final double y;
  final double width;
  final double height;
  final UvStyle style;

  @override
  void draw(CanvasPainter painter) {
    painter
      ..line(x, y, x + width, y, style: style)
      ..line(x + width, y, x + width, y + height, style: style)
      ..line(x + width, y + height, x, y + height, style: style)
      ..line(x, y + height, x, y, style: style);
  }
}

/// An outlined circle in world coordinates.
final class CanvasCircle implements CanvasShape {
  const CanvasCircle({
    required this.x,
    required this.y,
    required this.radius,
    this.style = const UvStyle(),
  });

  final double x;
  final double y;
  final double radius;
  final UvStyle style;

  @override
  void draw(CanvasPainter painter) {
    for (var angle = 0; angle < 360; angle++) {
      final radians = angle * math.pi / 180;
      painter.paint(
        x + radius * math.cos(radians),
        y + radius * math.sin(radians),
        style: style,
      );
    }
  }
}

/// A collection of independently projected world-coordinate points.
final class CanvasPoints implements CanvasShape {
  const CanvasPoints(this.points, {this.style = const UvStyle()});

  final List<CanvasPoint> points;
  final UvStyle style;

  @override
  void draw(CanvasPainter painter) {
    for (final point in points) {
      painter.paint(point.x, point.y, style: style);
    }
  }
}

/// Draws [shapes] into [screen] using a braille sub-cell canvas.
void drawCanvasShapes(
  Screen screen,
  Rectangle area,
  Iterable<CanvasShape> shapes, {
  CanvasRange xBounds = const CanvasRange(0, 100),
  CanvasRange yBounds = const CanvasRange(0, 100),
  UvStyle fallbackStyle = const UvStyle(),
}) {
  if (area.isEmpty) return;
  final canvas = BrailleCanvas(area.width, area.height);
  final painter = CanvasPainter(canvas, xBounds: xBounds, yBounds: yBounds);
  for (final shape in shapes) {
    painter.draw(shape);
  }
  canvas.renderTo(screen, area, fallbackStyle: fallbackStyle);
}
