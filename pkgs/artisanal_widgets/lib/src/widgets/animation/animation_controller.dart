import 'package:artisanal/runtime.dart' show Cmd;

import 'animation.dart';
import 'animation_tick.dart';
import 'curves.dart';
import 'listenable.dart';

/// A TEA-native animation controller.
///
/// Unlike Flutter's `AnimationController` which relies on `SchedulerBinding`
/// and `Ticker` for frame scheduling, this controller integrates with the
/// TEA (The Elm Architecture) message loop used by artisanal.
///
/// ## How it works
///
/// 1. Calling [forward], [reverse], [animateTo], or [repeat] returns a [Cmd]
///    that schedules the first animation frame tick via `Cmd.tick`.
/// 2. When the tick fires, the TEA loop delivers an [AnimationTickMsg] to
///    `State.handleUpdate` (or [AnimationMixin] handles it automatically).
/// 3. The handler calls [processTick] with the message's timestamp.
/// 4. [processTick] updates [value] and [status], notifies listeners, and
///    returns another [Cmd] to schedule the next tick — or `null` if done.
/// 5. The animation self-terminates by not returning a [Cmd] when complete.
///
/// ## Usage
///
/// ```dart
/// class _MyState extends State<MyWidget> with AnimationMixin {
///   late AnimationController _controller;
///
///   @override
///   void initState() {
///     super.initState();
///     _controller = createAnimationController(
///       duration: const Duration(milliseconds: 300),
///     );
///     _controller.addListener(() => setState(() {}));
///   }
///
///   @override
///   Cmd? handleInit() => _controller.forward();
///
///   @override
///   Widget build(BuildContext context) {
///     return Opacity(opacity: _controller.value, child: widget.child);
///   }
/// }
/// ```
class AnimationController extends Animation<double> with ChangeNotifier {
  /// Creates an animation controller.
  ///
  /// - [value]: initial value. Defaults to [lowerBound].
  /// - [duration]: the length of this animation when going forward.
  /// - [reverseDuration]: the length of this animation when going in reverse.
  ///   Defaults to [duration] when null.
  /// - [lowerBound] / [upperBound]: the range of values this animation spans.
  /// - [fps]: target frame rate for animation ticks. Higher values produce
  ///   smoother animation at the cost of more TEA messages.
  /// - [id]: an identity object used to match [AnimationTickMsg]s to this
  ///   controller. Auto-generated if not provided.
  AnimationController({
    double? value,
    this.duration,
    this.reverseDuration,
    this.lowerBound = 0.0,
    this.upperBound = 1.0,
    this.fps = 30,
    Object? id,
  }) : _id = id ?? Object() {
    _value = value ?? lowerBound;
    _status = AnimationStatus.dismissed;
  }

  // ── Identity ──────────────────────────────────────────────────────────────

  final Object _id;

  /// The unique identity of this controller, used to match tick messages.
  Object get id => _id;

  // ── Configuration ─────────────────────────────────────────────────────────

  /// The lowest value this animation can have.
  final double lowerBound;

  /// The highest value this animation can have.
  final double upperBound;

  /// The length of time this animation should last when going forward.
  Duration? duration;

  /// The length of time this animation should last when going in reverse.
  ///
  /// If null, [duration] is used instead.
  Duration? reverseDuration;

  /// Target frame rate for animation ticks (frames per second).
  final int fps;

  /// The duration between consecutive animation frames.
  Duration get _frameDuration =>
      Duration(microseconds: (1000000 / fps).round());

  // ── State ─────────────────────────────────────────────────────────────────

  double _value = 0.0;
  AnimationStatus _status = AnimationStatus.dismissed;
  final List<AnimationStatusListener> _statusListeners = [];

  DateTime? _startTime;
  double _startValue = 0.0;
  double _targetValue = 1.0;
  Curve _curve = Curves.linear;
  bool _repeating = false;
  bool _reverseOnRepeat = false;

  @override
  double get value => _value;

  @override
  AnimationStatus get status => _status;

  @override
  void addStatusListener(AnimationStatusListener listener) =>
      _statusListeners.add(listener);

  @override
  void removeStatusListener(AnimationStatusListener listener) =>
      _statusListeners.remove(listener);

  // ── API: Start / Stop ─────────────────────────────────────────────────────

  /// Starts animating forward (toward [upperBound]).
  ///
  /// Returns a [Cmd] that schedules the first animation frame tick.
  /// The hosting State must return this Cmd from `handleInit` or
  /// `handleUpdate`.
  ///
  /// If [from] is provided the controller jumps to that value before
  /// animating. The optional [curve] defaults to [Curves.linear].
  ///
  /// When [duration] is `null` or `Duration.zero`, the animation completes
  /// synchronously and [processTick] is not required.
  Cmd forward({double? from, Curve curve = Curves.linear}) {
    if (from != null) _value = from.clamp(lowerBound, upperBound);
    _targetValue = upperBound;
    _startValue = _value;
    _curve = curve;
    _status = AnimationStatus.forward;
    _startTime = null;
    _repeating = false;
    _notifyStatusListeners();
    if (duration == null || duration == Duration.zero) {
      _value = _targetValue;
      _completeAnimation();
      return Cmd.none();
    }
    return _scheduleTick();
  }

  /// Starts animating backward (toward [lowerBound]).
  ///
  /// Returns a [Cmd] that schedules the first animation frame tick.
  ///
  /// When [reverseDuration] (or [duration]) is `null` or `Duration.zero`,
  /// the animation completes synchronously and [processTick] is not required.
  Cmd reverse({double? from, Curve curve = Curves.linear}) {
    if (from != null) _value = from.clamp(lowerBound, upperBound);
    _targetValue = lowerBound;
    _startValue = _value;
    _curve = curve;
    _status = AnimationStatus.reverse;
    _startTime = null;
    _repeating = false;
    _notifyStatusListeners();
    final activeDuration = _activeDuration;
    if (activeDuration == null || activeDuration == Duration.zero) {
      _value = _targetValue;
      _completeAnimation();
      return Cmd.none();
    }
    return _scheduleTick();
  }

  /// Animates to [target] with optional [duration] and [curve] overrides.
  ///
  /// Returns a [Cmd] that schedules the first animation frame tick.
  Cmd animateTo(
    double target, {
    Duration? duration,
    Curve curve = Curves.linear,
  }) {
    _targetValue = target.clamp(lowerBound, upperBound);
    _startValue = _value;
    _curve = curve;
    if (duration != null) this.duration = duration;
    _status = target >= _value
        ? AnimationStatus.forward
        : AnimationStatus.reverse;
    _startTime = null;
    _repeating = false;
    _notifyStatusListeners();
    return _scheduleTick();
  }

  /// Animates backward to [target] with optional [duration] and [curve]
  /// overrides.
  ///
  /// This is the reverse counterpart of [animateTo]. Returns a [Cmd] that
  /// schedules the first animation frame tick.
  Cmd animateBack(
    double target, {
    Duration? duration,
    Curve curve = Curves.linear,
  }) {
    _targetValue = target.clamp(lowerBound, upperBound);
    _startValue = _value;
    _curve = curve;
    if (duration != null) {
      reverseDuration = duration;
    }
    _status = target <= _value
        ? AnimationStatus.reverse
        : AnimationStatus.forward;
    _startTime = null;
    _repeating = false;
    _notifyStatusListeners();
    return _scheduleTick();
  }

  /// Repeats the animation indefinitely between [min] and [max].
  ///
  /// If [reverse] is true, alternates direction each cycle (ping-pong).
  /// Otherwise the value jumps back to [min] at the end of each cycle.
  ///
  /// Returns a [Cmd] that schedules the first animation frame tick.
  Cmd repeat({
    double? min,
    double? max,
    bool reverse = false,
    Duration? period,
    Curve curve = Curves.linear,
  }) {
    final lo = min ?? lowerBound;
    final hi = max ?? upperBound;
    if (period != null) duration = period;
    _value = lo;
    _startValue = lo;
    _targetValue = hi;
    _curve = curve;
    _status = AnimationStatus.forward;
    _startTime = null;
    _repeating = true;
    _reverseOnRepeat = reverse;
    _notifyStatusListeners();
    return _scheduleTick();
  }

  /// Stops the animation at its current value.
  ///
  /// After calling stop, [processTick] becomes a no-op and the next
  /// [AnimationTickMsg] will not schedule another tick — the animation
  /// self-terminates.
  ///
  /// If [canceled] is false (the default), the status is set to
  /// [AnimationStatus.completed] or [AnimationStatus.dismissed] depending
  /// on the current value. If [canceled] is true the status is set based on
  /// the most recent direction.
  void stop({bool canceled = false}) {
    if (!isAnimating) return;
    _repeating = false;
    if (canceled) {
      _status = _status == AnimationStatus.forward
          ? AnimationStatus.dismissed
          : AnimationStatus.completed;
    } else {
      _status = _value >= upperBound
          ? AnimationStatus.completed
          : AnimationStatus.dismissed;
    }
    _notifyStatusListeners();
  }

  /// Resets the animation to [lowerBound] with [AnimationStatus.dismissed].
  void reset() {
    _value = lowerBound;
    _status = AnimationStatus.dismissed;
    _startTime = null;
    _repeating = false;
    notifyListeners();
    _notifyStatusListeners();
  }

  /// Releases resources held by this controller.
  ///
  /// After calling dispose the controller must not be used.
  @override
  void dispose() {
    _statusListeners.clear();
    super.dispose(); // ChangeNotifier.dispose clears value listeners
  }

  // ── API: Process Frame Ticks ──────────────────────────────────────────────

  /// Processes a frame tick. Call this from `handleUpdate` when an
  /// [AnimationTickMsg] with a matching `controllerId` is received.
  ///
  /// Returns a [Cmd] to schedule the next tick if the animation is still
  /// running, or `null` if the animation has completed (or was stopped).
  Cmd? processTick(DateTime now) {
    if (!isAnimating) return null;

    // Record the start time on the very first tick.
    _startTime ??= now;
    final elapsed = now.difference(_startTime!);
    final totalDuration = _activeDuration;

    // Zero or null duration → jump to target immediately.
    if (totalDuration == null || totalDuration == Duration.zero) {
      _value = _targetValue;
      _completeAnimation();
      return null;
    }

    // Compute normalized time progress [0.0, 1.0].
    final t = (elapsed.inMicroseconds / totalDuration.inMicroseconds).clamp(
      0.0,
      1.0,
    );

    // Apply curve and interpolate.
    final curvedT = _curve.transform(t);
    _value = _startValue + (_targetValue - _startValue) * curvedT;

    if (t >= 1.0) {
      // Animation segment is complete.
      _value = _targetValue;

      if (_repeating) {
        return _handleRepeatCycle();
      }

      _completeAnimation();
      return null;
    }

    // Still animating — notify and schedule next tick.
    notifyListeners();
    return _scheduleTick();
  }

  // ── Internals ─────────────────────────────────────────────────────────────

  /// Returns the active duration based on the current direction.
  Duration? get _activeDuration {
    if (_status == AnimationStatus.reverse && reverseDuration != null) {
      return reverseDuration;
    }
    return duration;
  }

  /// Marks the current animation segment as complete and notifies listeners.
  void _completeAnimation() {
    _status = _targetValue >= upperBound
        ? AnimationStatus.completed
        : AnimationStatus.dismissed;
    notifyListeners();
    _notifyStatusListeners();
  }

  /// Handles the transition between repeat cycles.
  ///
  /// If [_reverseOnRepeat] is true, swaps direction (ping-pong). Otherwise
  /// jumps back to [_startValue] for another forward cycle.
  ///
  /// Returns a [Cmd] to schedule the next tick.
  Cmd? _handleRepeatCycle() {
    if (_reverseOnRepeat) {
      // Swap direction.
      final tmp = _startValue;
      _startValue = _targetValue;
      _targetValue = tmp;
      _status = _status == AnimationStatus.forward
          ? AnimationStatus.reverse
          : AnimationStatus.forward;
    } else {
      // Jump back to start for another forward cycle.
      _value = _startValue;
    }
    _startTime = null; // Reset for next cycle.
    notifyListeners();
    _notifyStatusListeners();
    return _scheduleTick();
  }

  /// Creates a [Cmd.tick] that will produce an [AnimationTickMsg] after
  /// one frame duration.
  Cmd _scheduleTick() {
    return Cmd.tick(_frameDuration, (time) => AnimationTickMsg(_id, time));
  }

  AnimationStatus? _lastReportedStatus;

  /// Notifies status listeners only when the status actually changes.
  void _notifyStatusListeners() {
    if (_status == _lastReportedStatus) return;
    _lastReportedStatus = _status;
    for (final listener in List<AnimationStatusListener>.of(_statusListeners)) {
      listener(_status);
    }
  }

  @override
  String toString() =>
      'AnimationController#${_id.hashCode}'
      '(value: ${_value.toStringAsFixed(3)}, status: $_status)';
}
