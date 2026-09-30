import '../core/framework.dart' show BuildContext, InheritedWidget;

/// Acceleration applied to consecutive vertical wheel pulses.
enum ScrollAcceleration {
  /// Every pulse has the configured logical size.
  none,

  /// Pulses less than 200ms apart ramp from 1x to 4x in half-step increments.
  adaptive,
}

/// Logical wheel policy; terminal offsets remain integer cell coordinates.
///
/// Fractional steps accumulate per scroll surface. Keyboard navigation,
/// scrollbar dragging and selection edge autoscroll are not accelerated.
class ScrollBehavior {
  const ScrollBehavior({
    this.wheelStep = 3,
    this.acceleration = ScrollAcceleration.none,
  }) : assert(wheelStep > 0 && wheelStep < double.infinity);

  /// Positive finite logical rows per unaccelerated wheel pulse.
  final double wheelStep;

  /// How rapid consecutive wheel pulses change their logical size.
  final ScrollAcceleration acceleration;

  @override
  bool operator ==(Object other) =>
      other is ScrollBehavior &&
      wheelStep == other.wheelStep &&
      acceleration == other.acceleration;

  @override
  int get hashCode => Object.hash(wheelStep, acceleration);
}

/// Supplies a shared wheel policy without owning any scroll positions.
///
/// A widget's explicit behavior takes precedence over this scope. Without
/// either, widgets retain their individual mouseWheelDelta setting.
class ScrollBehaviorScope extends InheritedWidget {
  ScrollBehaviorScope({
    required this.behavior,
    required super.child,
    super.key,
  });

  /// Policy used by descendant scroll surfaces.
  final ScrollBehavior behavior;

  /// The nearest inherited policy, if one is installed.
  static ScrollBehavior? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<ScrollBehaviorScope>()
      ?.behavior;

  @override
  bool updateShouldNotify(covariant ScrollBehaviorScope oldWidget) =>
      behavior != oldWidget.behavior;
}

/// Converts logical wheel pulses to bounded integer movement for one surface.
///
/// Reversal, external position changes, changed policy and bounds reset pending
/// movement. Idle gaps reset acceleration, retaining fractions for slow input.
/// It schedules no timers.
class ScrollWheelAccumulator {
  final Stopwatch _clock = Stopwatch();
  ScrollBehavior? _behavior;
  Duration? _lastPulse;
  int _direction = 0;
  int? _expectedOffset;
  double _remainder = 0;
  double _multiplier = 1;

  /// Clears pending movement, for example when replacing a scroll controller.
  void reset() {
    _behavior = null;
    _lastPulse = null;
    _direction = 0;
    _expectedOffset = null;
    _remainder = 0;
    _multiplier = 1;
  }

  /// Returns movement for a pulse with direction -1 or 1.
  ///
  /// [timestamp] supports deterministic hosts/tests; otherwise elapsed
  /// monotonic time is used. A zero direction is ignored.
  int consume(
    int direction, {
    required ScrollBehavior behavior,
    required int offset,
    required int maxOffset,
    Duration? timestamp,
  }) {
    if (direction == 0) return 0;
    if (direction != -1 && direction != 1) {
      throw ArgumentError.value(direction, 'direction', 'Must be -1 or 1');
    }
    if (!behavior.wheelStep.isFinite || behavior.wheelStep <= 0) {
      throw ArgumentError.value(behavior.wheelStep, 'wheelStep');
    }
    if (offset < 0 || maxOffset < offset) {
      throw ArgumentError('Offset must be within the scroll extent');
    }
    _clock.start();
    final now = timestamp ?? _clock.elapsed;
    final previous = _lastPulse;
    final gap = previous == null ? null : now - previous;
    if (_behavior != behavior ||
        _direction != direction ||
        _expectedOffset != offset) {
      reset();
    } else if (gap == null ||
        gap.isNegative ||
        gap >= const Duration(milliseconds: 200)) {
      _multiplier = 1;
    } else if (behavior.acceleration == ScrollAcceleration.adaptive) {
      _multiplier = (_multiplier + .5).clamp(1, 4);
    }
    if ((direction < 0 && offset == 0) ||
        (direction > 0 && offset == maxOffset)) {
      reset();
      return 0;
    }
    _behavior = behavior;
    _direction = direction;
    _lastPulse = now;
    _remainder += direction * behavior.wheelStep * _multiplier;
    final bounded = _remainder.clamp(
      -offset.toDouble(),
      (maxOffset - offset).toDouble(),
    );
    final movement = bounded.truncate();
    _remainder = bounded - movement;
    _expectedOffset = offset + movement;
    if (movement != 0 &&
        (_expectedOffset == 0 || _expectedOffset == maxOffset)) {
      reset();
    }
    return movement;
  }
}
