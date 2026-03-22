import 'dart:math' as math;

/// A mapping of the unit interval to the unit interval.
///
/// A curve must map t=0.0 to 0.0 and t=1.0 to 1.0.
abstract class Curve {
  const Curve();

  /// Returns the value of the curve at point [t].
  ///
  /// [t] must be between 0.0 and 1.0, inclusive.
  double transform(double t) {
    assert(
      t >= 0.0 && t <= 1.0,
      'Curve transform parameter t ($t) must be between 0.0 and 1.0.',
    );
    if (t == 0.0 || t == 1.0) return t;
    return transformInternal(t);
  }

  /// Override this method to define the curve's behavior.
  ///
  /// [t] is guaranteed to be in the range (0.0, 1.0) exclusive.
  double transformInternal(double t);

  /// Returns a new curve that is the reverse of this one.
  Curve get flipped => FlippedCurve(this);

  @override
  String toString() => '$runtimeType';
}

/// A curve that is the reverse of another curve.
///
/// This is the flipped version of [curve]: it evaluates `1.0 - curve.transform(1.0 - t)`.
class FlippedCurve extends Curve {
  const FlippedCurve(this.curve);

  /// The curve that is being flipped.
  final Curve curve;

  @override
  double transformInternal(double t) => 1.0 - curve.transform(1.0 - t);

  @override
  String toString() => 'FlippedCurve($curve)';
}

/// The identity curve — the input value is returned unmodified.
class _Linear extends Curve {
  const _Linear();

  @override
  double transformInternal(double t) => t;
}

/// An interval that starts and/or ends at a fractional point along the curve.
///
/// Maps the input [t] to a sub-range [begin]..[end], then applies [curve].
class Interval extends Curve {
  const Interval(this.begin, this.end, {this.curve = Curves.linear})
    : assert(begin >= 0.0 && begin <= 1.0),
      assert(end >= 0.0 && end <= 1.0),
      assert(end >= begin);

  /// The start of the interval.
  final double begin;

  /// The end of the interval.
  final double end;

  /// The curve to apply within the interval.
  final Curve curve;

  @override
  double transformInternal(double t) {
    t = ((t - begin) / (end - begin)).clamp(0.0, 1.0);
    if (t == 0.0 || t == 1.0) return t;
    return curve.transform(t);
  }

  @override
  String toString() => 'Interval($begin, $end, $curve)';
}

/// A curve that jumps from 0.0 to 1.0 when [t] passes [threshold].
class Threshold extends Curve {
  const Threshold(this.threshold);

  /// The value at which the curve jumps to 1.0.
  final double threshold;

  @override
  double transformInternal(double t) => t < threshold ? 0.0 : 1.0;
}

/// A cubic Bezier curve defined by two control points.
///
/// The curve passes through (0,0) and (1,1).
class Cubic extends Curve {
  const Cubic(this.a, this.b, this.c, this.d);

  /// The x coordinate of the first control point.
  final double a;

  /// The y coordinate of the first control point.
  final double b;

  /// The x coordinate of the second control point.
  final double c;

  /// The y coordinate of the second control point.
  final double d;

  static const double _cubicErrorBound = 0.001;

  double _evaluateCubic(double a, double b, double m) {
    return 3 * a * (1 - m) * (1 - m) * m + 3 * b * (1 - m) * m * m + m * m * m;
  }

  @override
  double transformInternal(double t) {
    double start = 0.0;
    double end = 1.0;
    while (true) {
      final midpoint = (start + end) / 2;
      final estimate = _evaluateCubic(a, c, midpoint);
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
  String toString() => 'Cubic($a, $b, $c, $d)';
}

/// A sawtooth curve that repeats [count] times over the unit interval.
class SawTooth extends Curve {
  const SawTooth(this.count);

  /// The number of teeth.
  final int count;

  @override
  double transformInternal(double t) => (t * count) % 1.0;

  @override
  String toString() => 'SawTooth($count)';
}

// ── Elastic curves ──────────────────────────────────────────────────────────

/// An elastic curve that overshoots and then oscillates at the start.
///
/// The [period] parameter controls the duration of the oscillation.
class ElasticInCurve extends Curve {
  /// Creates an elastic-in curve with the given [period].
  const ElasticInCurve([this.period = 0.4]);

  final double period;

  @override
  double transformInternal(double t) {
    final s = period / 4.0;
    t = t - 1.0;
    return -math.pow(2.0, 10.0 * t).toDouble() *
        math.sin((t - s) * (math.pi * 2.0) / period);
  }

  @override
  String toString() => 'ElasticInCurve(period: $period)';
}

/// An elastic curve that overshoots and then oscillates at the end.
///
/// The [period] parameter controls the duration of the oscillation.
class ElasticOutCurve extends Curve {
  /// Creates an elastic-out curve with the given [period].
  const ElasticOutCurve([this.period = 0.4]);

  final double period;

  @override
  double transformInternal(double t) {
    final s = period / 4.0;
    return math.pow(2.0, -10.0 * t).toDouble() *
            math.sin((t - s) * (math.pi * 2.0) / period) +
        1.0;
  }

  @override
  String toString() => 'ElasticOutCurve(period: $period)';
}

/// An elastic curve that overshoots and oscillates at both ends.
///
/// The [period] parameter controls the duration of the oscillation.
class ElasticInOutCurve extends Curve {
  /// Creates an elastic-in-out curve with the given [period].
  const ElasticInOutCurve([this.period = 0.4]);

  final double period;

  @override
  double transformInternal(double t) {
    final s = period / 4.0;
    t = 2.0 * t - 1.0;
    if (t < 0.0) {
      return -0.5 *
          math.pow(2.0, 10.0 * t).toDouble() *
          math.sin((t - s) * (math.pi * 2.0) / period);
    } else {
      return 0.5 *
              math.pow(2.0, -10.0 * t).toDouble() *
              math.sin((t - s) * (math.pi * 2.0) / period) +
          1.0;
    }
  }

  @override
  String toString() => 'ElasticInOutCurve(period: $period)';
}

// ── Bounce curves ───────────────────────────────────────────────────────────

double _bounce(double t) {
  if (t < 1.0 / 2.75) {
    return 7.5625 * t * t;
  } else if (t < 2.0 / 2.75) {
    t -= 1.5 / 2.75;
    return 7.5625 * t * t + 0.75;
  } else if (t < 2.5 / 2.75) {
    t -= 2.25 / 2.75;
    return 7.5625 * t * t + 0.9375;
  }
  t -= 2.625 / 2.75;
  return 7.5625 * t * t + 0.984375;
}

class _BounceInCurve extends Curve {
  const _BounceInCurve();

  @override
  double transformInternal(double t) => 1.0 - _bounce(1.0 - t);

  @override
  String toString() => 'BounceInCurve';
}

class _BounceOutCurve extends Curve {
  const _BounceOutCurve();

  @override
  double transformInternal(double t) => _bounce(t);

  @override
  String toString() => 'BounceOutCurve';
}

class _BounceInOutCurve extends Curve {
  const _BounceInOutCurve();

  @override
  double transformInternal(double t) {
    if (t < 0.5) {
      return (1.0 - _bounce(1.0 - t * 2.0)) * 0.5;
    } else {
      return _bounce(t * 2.0 - 1.0) * 0.5 + 0.5;
    }
  }

  @override
  String toString() => 'BounceInOutCurve';
}

// ── Decelerate curve ────────────────────────────────────────────────────────

class _DecelerateCurve extends Curve {
  const _DecelerateCurve();

  @override
  double transformInternal(double t) => 1.0 - (1.0 - t) * (1.0 - t);

  @override
  String toString() => 'DecelerateCurve';
}

// ── Curves collection ───────────────────────────────────────────────────────

/// A collection of common animation curves.
///
/// These are the standard curves used in material design and general UI
/// animation. Each curve maps the unit interval `0` to `1` to the unit interval.
abstract final class Curves {
  /// A linear animation curve.
  static const Curve linear = _Linear();

  /// A curve where the rate of change starts out quickly and then decelerates.
  static const Curve decelerate = _DecelerateCurve();

  /// A curve used by material design for standard transitions.
  ///
  /// Starts slowly, accelerates sharply, then decelerates smoothly.
  static const Curve fastLinearToSlowEaseIn = Cubic(0.18, 1.0, 0.04, 1.0);

  /// The standard easing curve.
  static const Curve ease = Cubic(0.25, 0.1, 0.25, 1.0);

  /// A cubic animation curve that starts slowly and ends quickly.
  static const Curve easeIn = Cubic(0.42, 0.0, 1.0, 1.0);

  /// A sine-based ease-in curve.
  static const Curve easeInSine = Cubic(0.47, 0.0, 0.745, 0.715);

  /// A quadratic ease-in curve.
  static const Curve easeInQuad = Cubic(0.55, 0.085, 0.68, 0.53);

  /// A cubic ease-in curve.
  static const Curve easeInCubic = Cubic(0.55, 0.055, 0.675, 0.19);

  /// A quartic ease-in curve.
  static const Curve easeInQuart = Cubic(0.895, 0.03, 0.685, 0.22);

  /// A quintic ease-in curve.
  static const Curve easeInQuint = Cubic(0.755, 0.05, 0.855, 0.06);

  /// An exponential ease-in curve.
  static const Curve easeInExpo = Cubic(0.95, 0.05, 0.795, 0.035);

  /// A circular ease-in curve.
  static const Curve easeInCirc = Cubic(0.6, 0.04, 0.98, 0.335);

  /// An ease-in curve that overshoots then returns.
  static const Curve easeInBack = Cubic(0.6, -0.28, 0.735, 0.045);

  /// A cubic animation curve that starts quickly and ends slowly.
  static const Curve easeOut = Cubic(0.0, 0.0, 0.58, 1.0);

  /// A sine-based ease-out curve.
  static const Curve easeOutSine = Cubic(0.39, 0.575, 0.565, 1.0);

  /// A quadratic ease-out curve.
  static const Curve easeOutQuad = Cubic(0.25, 0.46, 0.45, 0.94);

  /// A cubic ease-out curve.
  static const Curve easeOutCubic = Cubic(0.215, 0.61, 0.355, 1.0);

  /// A quartic ease-out curve.
  static const Curve easeOutQuart = Cubic(0.165, 0.84, 0.44, 1.0);

  /// A quintic ease-out curve.
  static const Curve easeOutQuint = Cubic(0.23, 1.0, 0.32, 1.0);

  /// An exponential ease-out curve.
  static const Curve easeOutExpo = Cubic(0.19, 1.0, 0.22, 1.0);

  /// A circular ease-out curve.
  static const Curve easeOutCirc = Cubic(0.075, 0.82, 0.165, 1.0);

  /// An ease-out curve that overshoots then returns.
  static const Curve easeOutBack = Cubic(0.175, 0.885, 0.32, 1.275);

  /// A cubic animation curve that starts slowly, speeds up, then ends slowly.
  static const Curve easeInOut = Cubic(0.42, 0.0, 0.58, 1.0);

  /// A sine-based ease-in-out curve.
  static const Curve easeInOutSine = Cubic(0.445, 0.05, 0.55, 0.95);

  /// A quadratic ease-in-out curve.
  static const Curve easeInOutQuad = Cubic(0.455, 0.03, 0.515, 0.955);

  /// A cubic ease-in-out curve.
  static const Curve easeInOutCubic = Cubic(0.645, 0.045, 0.355, 1.0);

  /// A quartic ease-in-out curve.
  static const Curve easeInOutQuart = Cubic(0.77, 0.0, 0.175, 1.0);

  /// A quintic ease-in-out curve.
  static const Curve easeInOutQuint = Cubic(0.86, 0.0, 0.07, 1.0);

  /// An exponential ease-in-out curve.
  static const Curve easeInOutExpo = Cubic(1.0, 0.0, 0.0, 1.0);

  /// A circular ease-in-out curve.
  static const Curve easeInOutCirc = Cubic(0.785, 0.135, 0.15, 0.86);

  /// An ease-in-out curve that overshoots at both ends.
  static const Curve easeInOutBack = Cubic(0.68, -0.55, 0.265, 1.55);

  /// Material Design's standard easing curve.
  ///
  /// Elements that begin and end at rest use this curve.
  static const Curve fastOutSlowIn = Cubic(0.4, 0.0, 0.2, 1.0);

  /// Material Design's accelerate easing curve.
  ///
  /// Used for elements that exit the screen.
  static const Curve slowMiddle = Cubic(0.15, 0.85, 0.85, 0.15);

  /// An elastic-in curve with the default period of 0.4.
  static const Curve elasticIn = ElasticInCurve();

  /// An elastic-out curve with the default period of 0.4.
  static const Curve elasticOut = ElasticOutCurve();

  /// An elastic-in-out curve with the default period of 0.4.
  static const Curve elasticInOut = ElasticInOutCurve();

  /// A bounce-in curve.
  static const Curve bounceIn = _BounceInCurve();

  /// A bounce-out curve.
  static const Curve bounceOut = _BounceOutCurve();

  /// A bounce-in-out curve.
  static const Curve bounceInOut = _BounceInOutCurve();
}
