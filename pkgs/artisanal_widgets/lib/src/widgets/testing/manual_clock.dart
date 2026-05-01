/// Deterministic manual clock for tests.
library;

import '../animation/animation_tick.dart';

/// A manually advanced clock intended for deterministic tests.
///
/// The clock never moves unless [advance] or [set] is called, making it useful
/// for animation, replay, and frame-recording tests that should not depend on
/// wall-clock timing.
final class ManualClock {
  /// Creates a manual clock seeded at [initialTime].
  ///
  /// Defaults to the Unix epoch in UTC for stable reproducibility.
  ManualClock({DateTime? initialTime})
    : _now = initialTime ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

  DateTime _now;

  /// The current clock time.
  DateTime get now => _now;

  /// Moves the clock forward by [delta] and returns the updated time.
  DateTime advance([Duration delta = Duration.zero]) {
    _now = _now.add(delta);
    return _now;
  }

  /// Sets the clock to an explicit [time].
  void set(DateTime time) {
    _now = time;
  }

  /// Returns an [AnimationTickMsg] for [controllerId] at the current time.
  AnimationTickMsg animationTick(Object controllerId) {
    return AnimationTickMsg(controllerId, _now);
  }

  /// Advances by [delta] and returns an [AnimationTickMsg] at the new time.
  AnimationTickMsg advanceAnimationTick(
    Object controllerId, [
    Duration delta = Duration.zero,
  ]) {
    return AnimationTickMsg(controllerId, advance(delta));
  }
}
