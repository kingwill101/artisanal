import 'dart:math' as math;

import 'animation.dart';
import 'curves.dart';

/// A linear interpolation between a [begin] and [end] value.
///
/// The [lerp] method defines how values of type [T] are interpolated.
/// Subclasses override [lerp] for specific types (int, double, Color, etc.).
///
/// A [Tween] is an [Animatable] that maps a double in [0.0, 1.0] to a value
/// of type [T].
class Tween<T extends dynamic> extends Animatable<T> {
  /// Creates a tween that linearly interpolates between [begin] and [end].
  Tween({this.begin, this.end});

  /// The value at the beginning of the animation (t = 0.0).
  T? begin;

  /// The value at the end of the animation (t = 1.0).
  T? end;

  /// Returns the interpolated value for the given animation parameter [t].
  ///
  /// By default, this uses the `+`, `-`, and `*` operators on [T].
  /// Subclasses override this for types that do not support those operators.
  T lerp(double t) {
    assert(begin != null, 'Tween.begin must not be null when lerp is called.');
    assert(end != null, 'Tween.end must not be null when lerp is called.');
    // ignore: avoid_dynamic_calls
    return (begin as dynamic) + ((end as dynamic) - (begin as dynamic)) * t
        as T;
  }

  @override
  T transform(double t) {
    if (t == 0.0) return begin as T;
    if (t == 1.0) return end as T;
    return lerp(t);
  }

  @override
  String toString() => '$runtimeType($begin → $end)';
}

/// A tween that interpolates between two integers.
///
/// The value is rounded to the nearest integer at each step.
class IntTween extends Tween<int> {
  /// Creates an integer tween.
  IntTween({super.begin, super.end});

  @override
  int lerp(double t) {
    return (begin! + (end! - begin!) * t).round();
  }
}

/// An explicit double tween (mostly for documentation clarity).
class DoubleTween extends Tween<double> {
  /// Creates a double tween.
  DoubleTween({super.begin, super.end});

  @override
  double lerp(double t) {
    return begin! + (end! - begin!) * t;
  }
}

/// A tween that floors the interpolated value to an integer.
///
/// Useful for discrete step animations (e.g., progress bar segments).
class StepTween extends Tween<int> {
  /// Creates a step tween.
  StepTween({super.begin, super.end});

  @override
  int lerp(double t) {
    return (begin! + (end! - begin!) * t).floor();
  }
}

/// A tween that always returns the same constant value.
class ConstantTween<T> extends Tween<T> {
  /// Creates a constant tween that always evaluates to [value].
  ConstantTween(T value) : super(begin: value, end: value);

  @override
  T lerp(double t) => begin as T;
}

/// A tween that evaluates another tween in reverse.
///
/// The value at t=0.0 is [parent.end] and the value at t=1.0 is
/// [parent.begin].
class ReverseTween<T> extends Tween<T> {
  /// Creates a reverse tween.
  ReverseTween(this.parent) : super(begin: parent.end, end: parent.begin);

  /// The tween being reversed.
  final Tween<T> parent;

  @override
  T lerp(double t) => parent.lerp(1.0 - t);
}

/// An [Animatable] that applies a [Curve] to the input value.
///
/// This does not interpolate between two values; it merely transforms the
/// input double through a curve. Chain it with a [Tween] to get curved
/// interpolation:
///
/// ```dart
/// final curved = CurveTween(curve: Curves.easeIn);
/// final tween = Tween<double>(begin: 0, end: 100);
/// final animatable = curved.chain(tween);
/// ```
class CurveTween extends Animatable<double> {
  /// Creates a curve tween.
  CurveTween({required this.curve});

  /// The curve to apply.
  final Curve curve;

  @override
  double transform(double t) {
    if (t == 0.0 || t == 1.0) {
      // Ensure t=0 → 0 and t=1 → 1 even if the curve has precision issues.
      return t;
    }
    return curve.transform(t);
  }

  @override
  String toString() => 'CurveTween(curve: $curve)';
}

/// A single entry in a [TweenSequence].
///
/// Associates a [tween] with a [weight] that determines how much of the total
/// animation duration this segment occupies.
class TweenSequenceItem<T> {
  /// Creates a tween sequence item.
  const TweenSequenceItem({required this.tween, required this.weight})
    : assert(weight > 0.0);

  /// The tween used to produce values for this segment.
  final Animatable<T> tween;

  /// The relative weight of this segment.
  ///
  /// Weights do not need to sum to any particular value — they are
  /// automatically normalized.
  final double weight;
}

/// An [Animatable] that chains multiple tweens end-to-end with
/// proportional durations.
///
/// Each [TweenSequenceItem] defines a tween and a weight. The weights are
/// normalized so that they describe what fraction of the total animation each
/// segment takes. For example, two items with weight 1 each get 50% of the
/// time apiece.
///
/// ```dart
/// final sequence = TweenSequence<double>([
///   TweenSequenceItem(tween: Tween(begin: 0, end: 100), weight: 1),
///   TweenSequenceItem(tween: ConstantTween(100), weight: 0.5),
///   TweenSequenceItem(tween: Tween(begin: 100, end: 0), weight: 1),
/// ]);
/// ```
class TweenSequence<T> extends Animatable<T> {
  /// Creates a tween sequence from the given items.
  TweenSequence(List<TweenSequenceItem<T>> items)
    : assert(items.isNotEmpty, 'TweenSequence requires at least one item.'),
      _items = items {
    _intervals = _computeIntervals(items);
  }

  final List<TweenSequenceItem<T>> _items;
  late final List<_Interval> _intervals;

  static List<_Interval> _computeIntervals<T>(
    List<TweenSequenceItem<T>> items,
  ) {
    final totalWeight = items.fold(0.0, (sum, item) => sum + item.weight);
    assert(totalWeight > 0.0);
    final intervals = <_Interval>[];
    double start = 0.0;
    for (final item in items) {
      final end = start + item.weight / totalWeight;
      intervals.add(_Interval(start, math.min(end, 1.0)));
      start = end;
    }
    // Correct any floating-point drift on the last interval.
    if (intervals.isNotEmpty) {
      intervals[intervals.length - 1] = _Interval(intervals.last.start, 1.0);
    }
    return intervals;
  }

  @override
  T transform(double t) {
    // Clamp to handle floating point drift at boundaries.
    t = t.clamp(0.0, 1.0);
    if (t == 1.0) {
      // At the very end, evaluate the last tween at t=1.0.
      return _items.last.tween.transform(1.0);
    }
    for (int i = 0; i < _items.length; i++) {
      final interval = _intervals[i];
      if (t >= interval.start && t < interval.end) {
        final localT = (t - interval.start) / (interval.end - interval.start);
        return _items[i].tween.transform(localT);
      }
    }
    // Fallback — should not happen with correct intervals.
    return _items.last.tween.transform(1.0);
  }

  @override
  String toString() => 'TweenSequence(${_items.length} items)';
}

/// A simple start/end interval used internally by [TweenSequence].
class _Interval {
  const _Interval(this.start, this.end);
  final double start;
  final double end;
}
