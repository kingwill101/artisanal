import '../animation/curves.dart' show Curve;

/// Configurable animation durations and curves for route transitions.
///
/// Matches Flutter's [AnimationStyle] API for route animations.
///
/// ```dart
/// AnimationStyle(
///   duration: Duration(milliseconds: 150),
///   curve: Curves.easeOut,
/// )
/// ```
class AnimationStyle {
  /// An animation style with default values.
  ///
  /// Consumers that accept an [AnimationStyle] parameter usually have their
  /// own fallback defaults when fields are null. Use this constant when you
  /// need to explicitly opt into defaults without specifying custom values.
  static const AnimationStyle defaults = AnimationStyle._defaults();

  const AnimationStyle._defaults()
    : duration = null,
      reverseDuration = null,
      curve = null,
      reverseCurve = null;

  /// Creates an [AnimationStyle] with the given properties.
  ///
  /// All parameters are optional. When null, the default values of the
  /// consuming route apply.
  const AnimationStyle({
    this.duration,
    this.reverseDuration,
    this.curve,
    this.reverseCurve,
  });

  /// The duration of the forward (appearance) transition.
  final Duration? duration;

  /// The duration of the reverse (dismissal) transition.
  ///
  /// When null, [duration] is used.
  final Duration? reverseDuration;

  /// The curve of the forward (appearance) transition.
  final Curve? curve;

  /// The curve of the reverse (dismissal) transition.
  ///
  /// When null, [curve] is used.
  final Curve? reverseCurve;

  @override
  bool operator ==(Object other) {
    if (other case AnimationStyle s) {
      return duration == s.duration &&
          reverseDuration == s.reverseDuration &&
          curve == s.curve &&
          reverseCurve == s.reverseCurve;
    }
    return false;
  }

  @override
  int get hashCode =>
      Object.hash(duration, reverseDuration, curve, reverseCurve);

  @override
  String toString() {
    return 'AnimationStyle(duration: $duration, '
        'reverseDuration: $reverseDuration, '
        'curve: $curve, '
        'reverseCurve: $reverseCurve)';
  }
}
