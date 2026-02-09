import 'dart:math' as math;

/// An abstract class providing an interface for evaluating a parametric curve.
///
/// A parametric curve maps a parameter value (t) in the range [0.0, 1.0] to
/// a transformed output value also typically in the range [0.0, 1.0].
///
/// See [Curves] for pre-defined curves.
abstract class Curve {
  /// Abstract const constructor to enable subclasses to provide
  /// const constructors.
  const Curve();

  /// Returns the value of the curve at point [t].
  ///
  /// The value of [t] must be between 0.0 and 1.0, inclusive.
  /// The returned value should also be between 0.0 and 1.0, though some curves
  /// may return values slightly outside this range (e.g., elastic curves).
  double transform(double t);

  /// Returns a new curve that is the reversed version of this one.
  ///
  /// The reversed curve evaluates to `1.0 - transform(1.0 - t)`.
  Curve get flipped => FlippedCurve(this);
}

/// A curve that is the reversed version of its parent.
///
/// Evaluates to `1.0 - parent.transform(1.0 - t)`.
class FlippedCurve extends Curve {
  /// Creates a flipped curve.
  const FlippedCurve(this.curve);

  /// The curve to flip.
  final Curve curve;

  @override
  double transform(double t) => 1.0 - curve.transform(1.0 - t);

  @override
  String toString() => '${curve.runtimeType}.flipped';
}

/// A linear curve (identity function).
class _Linear extends Curve {
  const _Linear._();

  @override
  double transform(double t) => t;
}

/// A cubic Bezier curve defined by two control points.
///
/// The curve passes through (0, 0) and (1, 1), with [a], [b] defining the
/// first control point and [c], [d] defining the second control point.
///
/// This implementation uses Newton-Raphson iteration to solve for the
/// y-coordinate given an x-coordinate (the parameter t represents x).
class Cubic extends Curve {
  /// Creates a cubic Bezier curve.
  ///
  /// The arguments [a], [b], [c], [d] define the two control points:
  /// - First control point: (a, b)
  /// - Second control point: (c, d)
  ///
  /// The curve always starts at (0, 0) and ends at (1, 1).
  const Cubic(this.a, this.b, this.c, this.d);

  /// The x-coordinate of the first control point.
  final double a;

  /// The y-coordinate of the first control point.
  final double b;

  /// The x-coordinate of the second control point.
  final double c;

  /// The y-coordinate of the second control point.
  final double d;

  static const double _cubicErrorBound = 0.001;

  double _evaluateCubic(double a, double b, double m) {
    // Calculate the cubic polynomial at parameter m.
    // The formula is derived from the Bezier curve equation:
    // B(t) = (1-t)^3 * P0 + 3*(1-t)^2*t * P1 + 3*(1-t)*t^2 * P2 + t^3 * P3
    // where P0 = 0, P1 = a, P2 = b, P3 = 1
    return 3 * a * (1 - m) * (1 - m) * m + 3 * b * (1 - m) * m * m + m * m * m;
  }

  @override
  double transform(double t) {
    // Handle edge cases.
    if (t == 0.0 || t == 1.0) {
      return t;
    }

    // Newton-Raphson iteration to find the parameter value m such that
    // the x-coordinate of the cubic equals t.
    double start = 0.0;
    double end = 1.0;
    while (true) {
      final double midpoint = (start + end) / 2;
      final double estimate = _evaluateCubic(a, c, midpoint);

      if ((t - estimate).abs() < _cubicErrorBound) {
        return _evaluateCubic(b, d, midpoint);
      }

      if (estimate < t) {
        start = midpoint;
      } else {
        end = midpoint;
      }
    }
  }

  @override
  String toString() =>
      'Cubic(${a.toStringAsFixed(2)}, ${b.toStringAsFixed(2)}, '
      '${c.toStringAsFixed(2)}, ${d.toStringAsFixed(2)})';
}

/// An oscillating curve that grows in magnitude.
///
/// The curve starts at 0.0 and ends at 1.0, overshooting and oscillating
/// with increasing amplitude.
class _ElasticInCurve extends Curve {
  const _ElasticInCurve();

  @override
  double transform(double t) {
    const double period = 0.4;
    final double s = period / 4.0;
    t = t - 1.0;
    return -math.pow(2.0, 10.0 * t) *
        math.sin((t - s) * (math.pi * 2.0) / period);
  }

  @override
  String toString() => 'Curves.elasticIn';
}

/// An oscillating curve that shrinks in magnitude.
///
/// The curve starts at 0.0 and ends at 1.0, overshooting and oscillating
/// with decreasing amplitude.
class _ElasticOutCurve extends Curve {
  const _ElasticOutCurve();

  @override
  double transform(double t) {
    const double period = 0.4;
    final double s = period / 4.0;
    return math.pow(2.0, -10.0 * t) *
            math.sin((t - s) * (math.pi * 2.0) / period) +
        1.0;
  }

  @override
  String toString() => 'Curves.elasticOut';
}

/// An oscillating curve that grows and then shrinks in magnitude.
class _ElasticInOutCurve extends Curve {
  const _ElasticInOutCurve();

  @override
  double transform(double t) {
    const double period = 0.4;
    final double s = period / 4.0;
    t = 2.0 * t - 1.0;
    if (t < 0.0) {
      return -0.5 *
          math.pow(2.0, 10.0 * t) *
          math.sin((t - s) * (math.pi * 2.0) / period);
    } else {
      return math.pow(2.0, -10.0 * t) *
              math.sin((t - s) * (math.pi * 2.0) / period) *
              0.5 +
          1.0;
    }
  }

  @override
  String toString() => 'Curves.elasticInOut';
}

/// A curve that bounces at the end.
class _BounceOutCurve extends Curve {
  const _BounceOutCurve._();

  @override
  double transform(double t) {
    if (t < 1 / 2.75) {
      return 7.5625 * t * t;
    } else if (t < 2 / 2.75) {
      t -= 1.5 / 2.75;
      return 7.5625 * t * t + 0.75;
    } else if (t < 2.5 / 2.75) {
      t -= 2.25 / 2.75;
      return 7.5625 * t * t + 0.9375;
    } else {
      t -= 2.625 / 2.75;
      return 7.5625 * t * t + 0.984375;
    }
  }

  @override
  String toString() => 'Curves.bounceOut';
}

/// A curve that bounces at the start.
class _BounceInCurve extends Curve {
  const _BounceInCurve._();

  @override
  double transform(double t) {
    return 1.0 - const _BounceOutCurve._().transform(1.0 - t);
  }

  @override
  String toString() => 'Curves.bounceIn';
}

/// A curve that bounces at both ends.
class _BounceInOutCurve extends Curve {
  const _BounceInOutCurve._();

  @override
  double transform(double t) {
    if (t < 0.5) {
      return (1.0 - const _BounceOutCurve._().transform(1.0 - t * 2.0)) * 0.5;
    } else {
      return const _BounceOutCurve._().transform(t * 2.0 - 1.0) * 0.5 + 0.5;
    }
  }

  @override
  String toString() => 'Curves.bounceInOut';
}

/// A curve that starts slowly and accelerates.
class _DecelerateCurve extends Curve {
  const _DecelerateCurve._();

  @override
  double transform(double t) {
    // Decelerate curve is equivalent to 1 - (1-t)^2
    t = 1.0 - t;
    return 1.0 - t * t;
  }

  @override
  String toString() => 'Curves.decelerate';
}

/// A collection of commonly used animation curves.
///
/// These curves are typically used with [AnimationController.animateTo] or
/// [AnimationController.animateWith] to create smooth animations.
abstract class Curves {
  Curves._();

  /// A linear animation curve.
  ///
  /// The value changes at a constant rate throughout the animation.
  static const Curve linear = _Linear._();

  /// A curve where the rate of change starts slowly, speeds up, and then
  /// slows down again.
  ///
  /// This is the most commonly used curve for animations.
  static const Curve ease = Cubic(0.25, 0.1, 0.25, 1.0);

  /// A curve where the rate of change starts slowly and speeds up.
  static const Curve easeIn = Cubic(0.42, 0.0, 1.0, 1.0);

  /// A curve where the rate of change starts fast and slows down.
  static const Curve easeOut = Cubic(0.0, 0.0, 0.58, 1.0);

  /// A curve where the rate of change starts slowly, speeds up, and then
  /// slows down again.
  static const Curve easeInOut = Cubic(0.42, 0.0, 0.58, 1.0);

  /// A curve where the rate of change starts slowly and speeds up more
  /// aggressively than [easeIn].
  static const Curve easeInSine = Cubic(0.47, 0.0, 0.745, 0.715);

  /// A curve where the rate of change starts fast and slows down more
  /// gradually than [easeOut].
  static const Curve easeOutSine = Cubic(0.39, 0.575, 0.565, 1.0);

  /// A sine-based ease-in-out curve.
  static const Curve easeInOutSine = Cubic(0.445, 0.05, 0.55, 0.95);

  /// A curve where the rate of change starts slowly and speeds up with
  /// a quadratic relationship.
  static const Curve easeInQuad = Cubic(0.55, 0.085, 0.68, 0.53);

  /// A curve where the rate of change starts fast and slows down with
  /// a quadratic relationship.
  static const Curve easeOutQuad = Cubic(0.25, 0.46, 0.45, 0.94);

  /// A quadratic ease-in-out curve.
  static const Curve easeInOutQuad = Cubic(0.455, 0.03, 0.515, 0.955);

  /// A curve where the rate of change starts slowly and speeds up with
  /// a cubic relationship.
  static const Curve easeInCubic = Cubic(0.55, 0.055, 0.675, 0.19);

  /// A curve where the rate of change starts fast and slows down with
  /// a cubic relationship.
  static const Curve easeOutCubic = Cubic(0.215, 0.61, 0.355, 1.0);

  /// A cubic ease-in-out curve.
  static const Curve easeInOutCubic = Cubic(0.645, 0.045, 0.355, 1.0);

  /// A curve where the rate of change starts slowly and speeds up with
  /// an exponential relationship.
  static const Curve easeInExpo = Cubic(0.95, 0.05, 0.795, 0.035);

  /// A curve where the rate of change starts fast and slows down with
  /// an exponential relationship.
  static const Curve easeOutExpo = Cubic(0.19, 1.0, 0.22, 1.0);

  /// An exponential ease-in-out curve.
  static const Curve easeInOutExpo = Cubic(1.0, 0.0, 0.0, 1.0);

  /// A curve where the rate of change starts slowly and speeds up with
  /// a circular relationship.
  static const Curve easeInCirc = Cubic(0.6, 0.04, 0.98, 0.335);

  /// A curve where the rate of change starts fast and slows down with
  /// a circular relationship.
  static const Curve easeOutCirc = Cubic(0.075, 0.82, 0.165, 1.0);

  /// A circular ease-in-out curve.
  static const Curve easeInOutCirc = Cubic(0.785, 0.135, 0.15, 0.86);

  /// A curve that slightly overshoots then settles at 1.0.
  static const Curve easeInBack = Cubic(0.6, -0.28, 0.735, 0.045);

  /// A curve that starts at 0.0 and ends slightly past 1.0 before settling.
  static const Curve easeOutBack = Cubic(0.175, 0.885, 0.32, 1.275);

  /// A curve that overshoots at both ends.
  static const Curve easeInOutBack = Cubic(0.68, -0.55, 0.265, 1.55);

  /// An elastic curve that overshoots and oscillates at the beginning.
  static const Curve elasticIn = _ElasticInCurve();

  /// An elastic curve that overshoots and oscillates at the end.
  static const Curve elasticOut = _ElasticOutCurve();

  /// An elastic curve that overshoots and oscillates at both ends.
  static const Curve elasticInOut = _ElasticInOutCurve();

  /// A curve that bounces at the end.
  static const Curve bounceIn = _BounceInCurve._();

  /// A curve that bounces at the beginning.
  static const Curve bounceOut = _BounceOutCurve._();

  /// A curve that bounces at both ends.
  static const Curve bounceInOut = _BounceInOutCurve._();

  /// A curve that starts fast and decelerates.
  static const Curve decelerate = _DecelerateCurve._();

  /// Alias for [decelerate].
  static const Curve fastOutSlowIn = Cubic(0.4, 0.0, 0.2, 1.0);
}
