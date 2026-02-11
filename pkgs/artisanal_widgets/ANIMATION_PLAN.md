# Animation System Implementation Plan for artisanal_widgets

## Overview

This plan describes how to create an animation subsystem for `artisanal_widgets`,
informed by the nocterm `animation/` module (which is itself a port of Flutter's
animation framework). The goal is to provide curves, tweens, animation
controllers, and animated builder widgets that integrate naturally with the
TEA (The Elm Architecture) message loop used by artisanal.

The nocterm animation system cannot be ported verbatim because it depends on
`SchedulerBinding` for frame scheduling — a frame-loop abstraction that does
not exist in artisanal. Instead, artisanal drives rendering through its
`Msg → update() → view()` cycle. Animation frames must therefore flow through
this message loop, using `Cmd.tick()` or `EveryCmd` to schedule frame callbacks.

---

## Current State

### What exists in artisanal_widgets today

| Concern | Status |
|---------|--------|
| Curves / easing | **None** |
| Tweens / interpolation | **None** |
| AnimationController | **None** |
| AnimatedBuilder widget | **None** |
| Ticker / frame scheduling | **None** — no `SchedulerBinding` equivalent |
| Listenable / ValueListenable | **None** |
| Timer-driven animation | `SpinnerIndicator` uses `EveryCmd` + `Msg` to cycle frames — proves the pattern works |

### How SpinnerIndicator animates today

The spinner is the only animation-like widget. It demonstrates the TEA-native
frame scheduling pattern that the animation system will generalize:

```dart
// In SpinnerIndicator (StatefulWidget):
@override
Cmd? handleInit() {
  if (!active || frames.isEmpty) return null;
  return every(interval, (_) => _SpinnerTickMsg(id), id: id);
}

// In _SpinnerIndicatorState:
@override
Cmd? handleUpdate(Msg msg) {
  if (msg is _SpinnerTickMsg && msg.id == widget.id) {
    setState(() { _index = (_index + 1) % widget.frames.length; });
    return null;
  }
  return null;
}
```

Key observations:
- `EveryCmd` sends a `Msg` at a fixed interval through the TEA loop.
- `handleUpdate` receives the tick, mutates state via `setState()`, which marks
  the element dirty.
- The program's `update() → view()` cycle re-renders the dirty subtree.

### Key architectural facts

- `State.setState(fn)` calls `fn()` then `_element?.markNeedsBuild()`.
- `BuildOwner.scheduleBuildFor(element)` queues the element for rebuild.
- `WidgetApp.update()` checks `_tree.hasDirty` and sets `_dirty = true`.
- `WidgetApp.view()` renders dirty elements and caches the result.
- **Crucially**: `view()` is only called after `update(Msg)`. If no message
  arrives, nothing renders. Animation ticks MUST arrive as messages.

### What the nocterm animation module provides (reference)

```
nocterm/lib/src/animation/
├── animation.dart          # AnimationStatus, Animation<T>, Animatable<T>,
│                           # AnimationController, simulation classes
├── animated_builder.dart   # AnimatedComponent, AnimatedBuilder,
│                           # ListenableBuilder
├── animations.dart         # Library barrel — exports everything
├── curves.dart             # Curve, Cubic, Elastic/Bounce/Decelerate,
│                           # Curves presets (30+ curves)
├── ticker.dart             # Ticker, TickerFuture, TickerCanceled,
│                           # TickerCallback, TickerProvider
├── ticker_provider.dart    # SingleTickerProviderStateMixin,
│                           # TickerProviderStateMixin
└── tween.dart              # Tween<T>, IntTween, DoubleTween, ColorTween,
                            # CurveTween, ConstantTween, ReverseTween,
                            # StepTween, TweenSequence, Interval, Threshold
```

Dependencies of nocterm's animation system:
- `SchedulerBinding` — frame callbacks (`scheduleFrame`, `scheduleFrameCallback`,
  `cancelFrameCallbackWithId`). **Does not exist in artisanal.**
- `Listenable` / `ValueListenable` — observer pattern. **Does not exist in
  artisanal_widgets.**
- `Component` / `StatefulComponent` / `State` — nocterm's widget framework.
  **artisanal_widgets has its own `Widget` / `StatefulWidget` / `State`.**

---

## The Core Design Problem: TEA vs Imperative Frame Scheduling

| Concern | Nocterm (Flutter-like) | Artisanal (TEA) |
|---------|----------------------|-----------------|
| **Frame scheduling** | `SchedulerBinding.scheduleFrame()` → `Timer` → callback | `Cmd.tick()` → `Msg` → `update()` → `view()` |
| **Animation drive** | `Ticker._tick(elapsed)` called by scheduler | Must arrive as a `Msg` through the TEA loop |
| **State mutation** | `setState(() {})` → immediate `markNeedsBuild` → next frame rebuilds | `setState(() {})` → `markNeedsBuild` → rebuild happens during `update(Msg)` → `view()` cycle |
| **Starting animation** | `controller.forward()` returns `TickerFuture` | Must return `Cmd?` to schedule frame ticks |
| **Stopping animation** | `controller.stop()` → `ticker.stop()` → cancel scheduled callback | Self-terminating: stop returning `Cmd.tick()` from `handleUpdate` |

### Resolution: Self-chaining `Cmd.tick()`

The primary frame scheduling mechanism uses `Cmd.tick()` — a one-shot delayed
command that returns a message after a duration. Each animation frame:

1. `controller.forward()` returns `Cmd.tick(frameDuration, (t) => AnimationTickMsg(...))`
2. `handleUpdate(AnimationTickMsg)` processes the tick, updates animation values
3. If still animating → return another `Cmd.tick(...)` to schedule the next frame
4. If animation is complete → return `null` — no more ticks, animation stops

This is **self-terminating**, requires **no cleanup**, and is **pure TEA**. No
special runtime support needed.

```dart
// Cmd.tick (already exists in artisanal):
static Cmd tick(Duration duration, Msg? Function(DateTime time) callback) {
  return Cmd(() async {
    await Future<void>.delayed(duration);
    return callback(DateTime.now());
  });
}
```

### Alternative: `EveryCmd` with direct `.stop()`

For long-running or repeating animations where `Cmd.tick` chaining adds
overhead, hold a reference to an `EveryCmd` and call `.stop()` directly:

```dart
late EveryCmd _tickCmd;

Cmd startAnimation() {
  _tickCmd = EveryCmd(interval: frameDuration, callback: (t) => _TickMsg(t), id: _id);
  return _tickCmd;
}

void stopAnimation() {
  _tickCmd.stop(); // Directly cancels the underlying Timer
}
```

This is more efficient for animations that repeat indefinitely (e.g., loading
spinners, pulsing indicators) but less TEA-pure. Both approaches will be
supported.

---

## Implementation Plan

### Phase 1: Listenable Foundation

Create minimal `Listenable`, `ValueListenable`, and `ChangeNotifier` classes.
These are needed by `Animation<T>`, `AnimationController`, and
`AnimatedBuilder`.

**New file: `lib/src/widgets/animation/listenable.dart`**

```dart
/// An object that maintains a list of listeners.
abstract class Listenable {
  const Listenable();

  factory Listenable.merge(Iterable<Listenable?> listenables) = _MergingListenable;

  void addListener(void Function() listener);
  void removeListener(void Function() listener);
}

/// A [Listenable] that exposes a current value.
abstract class ValueListenable<T> extends Listenable {
  const ValueListenable();
  T get value;
}

/// A [Listenable] that notifies listeners when its state changes.
class ChangeNotifier implements Listenable {
  final List<void Function()> _listeners = [];

  @override
  void addListener(void Function() listener) => _listeners.add(listener);

  @override
  void removeListener(void Function() listener) => _listeners.remove(listener);

  void notifyListeners() {
    for (final listener in List<void Function()>.of(_listeners)) {
      listener();
    }
  }

  bool get hasListeners => _listeners.isNotEmpty;

  void dispose() => _listeners.clear();
}

/// A [ChangeNotifier] that holds a single value.
class ValueNotifier<T> extends ChangeNotifier implements ValueListenable<T> {
  ValueNotifier(this._value);

  T _value;

  @override
  T get value => _value;

  set value(T newValue) {
    if (_value == newValue) return;
    _value = newValue;
    notifyListeners();
  }
}
```

No dependencies on other artisanal code. Pure Dart.

---

### Phase 2: Curves

Port `curves.dart` verbatim from nocterm. This is pure math — no framework
dependencies.

**New file: `lib/src/widgets/animation/curves.dart`**

Contents (direct port):
- `Curve` abstract base — `transform(double t) → double`, `get flipped`
- `FlippedCurve`
- `_Linear` (used by `Curves.linear`)
- `Cubic` — cubic Bezier with binary search solver
- `_ElasticInCurve`, `_ElasticOutCurve`, `_ElasticInOutCurve`
- `_BounceInCurve`, `_BounceOutCurve`, `_BounceInOutCurve`
- `_DecelerateCurve`
- `Curves` — static const collection of 30+ preset curves

No changes needed vs nocterm source. Direct copy.

---

### Phase 3: Tweens

Port `tween.dart` from nocterm. Pure math except `ColorTween` which references
`Color` from `style.dart`.

**New file: `lib/src/widgets/animation/tween.dart`**

Contents (direct port with import adjustments):
- `Tween<T>` — linear interpolation between `begin` and `end`
- `IntTween` — rounds to nearest int
- `DoubleTween` — explicit double lerp
- `ColorTween` — uses `Color.lerp` (import from artisanal's `Style`/`Color`)
- `CurveTween` — applies a `Curve` to a double value
- `ConstantTween<T>` — always returns the same value
- `ReverseTween<T>` — reverses another tween
- `StepTween` — floors the interpolated value
- `TweenSequence<T>` — chains weighted tween segments
- `TweenSequenceItem<T>` — entry for TweenSequence
- `Interval` — a Curve subclass active only within a time range
- `Threshold` — a Curve that jumps from 0 to 1 at a threshold

Import change: `Color` comes from `package:artisanal/tui.dart` (via `Style`)
rather than nocterm's `style.dart`. If the Color type does not have a `lerp`
static method, we implement one or skip `ColorTween` for Phase 3 and add it
later.

---

### Phase 4: Animation Core

Create `AnimationStatus`, `Animation<T>`, and `Animatable<T>`.

**New file: `lib/src/widgets/animation/animation.dart`**

```dart
/// The status of an animation.
enum AnimationStatus {
  /// Stopped at the beginning.
  dismissed,
  /// Running from beginning to end.
  forward,
  /// Running from end to beginning.
  reverse,
  /// Stopped at the end.
  completed,
}

/// Signature for animation status change callbacks.
typedef AnimationStatusListener = void Function(AnimationStatus status);

/// An animation with a value of type [T].
abstract class Animation<T> extends Listenable implements ValueListenable<T> {
  const Animation();

  @override
  T get value;

  AnimationStatus get status;

  void addStatusListener(AnimationStatusListener listener);
  void removeStatusListener(AnimationStatusListener listener);

  bool get isDismissed => status == AnimationStatus.dismissed;
  bool get isCompleted => status == AnimationStatus.completed;
  bool get isAnimating =>
      status == AnimationStatus.forward || status == AnimationStatus.reverse;

  /// Chains with an [Animatable] to create a derived animation.
  Animation<U> drive<U>(Animatable<U> child) {
    assert(this is Animation<double>);
    return child.animate(this as Animation<double>);
  }
}

/// Transforms a double parameter value into a value of type [T].
abstract class Animatable<T> {
  const Animatable();

  T transform(double t);
  T evaluate(Animation<double> animation) => transform(animation.value);

  Animation<T> animate(Animation<double> parent) {
    return _AnimatedEvaluation<T>(parent, this);
  }

  Animatable<T> chain(Animatable<double> parent) {
    return _ChainedEvaluation<T>(parent, this);
  }
}
```

Plus internal `_AnimatedEvaluation` and `_ChainedEvaluation` classes (direct
port from nocterm).

---

### Phase 5: Animation Tick Message

Define the message type that carries animation frame ticks through the TEA loop.

**New file: `lib/src/widgets/animation/animation_tick.dart`**

```dart
import 'package:artisanal/tui.dart' show Msg;

/// Message delivered on each animation frame tick.
///
/// Carries the controller's identity and the wall-clock time of the tick,
/// allowing the controller to compute elapsed duration.
class AnimationTickMsg extends Msg {
  const AnimationTickMsg(this.controllerId, this.time);

  /// Identifies which controller this tick belongs to.
  final Object controllerId;

  /// The wall-clock time when this tick was generated.
  final DateTime time;
}
```

---

### Phase 6: AnimationController — TEA-Native

This is the most significant adaptation. The nocterm `AnimationController`:
- Owns a `Ticker` which talks to `SchedulerBinding`
- Calls `_tick(Duration elapsed)` on each frame

Our `AnimationController`:
- Does NOT own a Ticker
- `forward()` / `reverse()` / `animateTo()` / `repeat()` return a `Cmd`
- `processTick(DateTime now)` is called from `handleUpdate()` when an
  `AnimationTickMsg` arrives
- Internally uses the same `_InterpolationSimulation` / `_RepeatingSimulation`
  classes from nocterm for time-based value computation
- Self-terminates by not scheduling another tick when done

**New file: `lib/src/widgets/animation/animation_controller.dart`**

```dart
import 'package:artisanal/tui.dart' show Cmd, EveryCmd;
import 'animation.dart';
import 'animation_tick.dart';
import 'curves.dart';
import 'listenable.dart';

class AnimationController extends Animation<double> with ChangeNotifier {
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

  final double lowerBound;
  final double upperBound;
  Duration? duration;
  Duration? reverseDuration;

  /// Target frame rate for animation ticks.
  final int fps;

  Duration get _frameDuration => Duration(microseconds: (1000000 / fps).round());

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
  /// The hosting State must return this Cmd from [handleUpdate] or
  /// [handleInit].
  Cmd forward({double? from, Curve curve = Curves.linear}) {
    if (from != null) _value = from.clamp(lowerBound, upperBound);
    _targetValue = upperBound;
    _startValue = _value;
    _curve = curve;
    _status = AnimationStatus.forward;
    _startTime = null;
    _repeating = false;
    _notifyStatusListeners();
    return _scheduleTick();
  }

  /// Starts animating backward (toward [lowerBound]).
  Cmd reverse({double? from, Curve curve = Curves.linear}) {
    if (from != null) _value = from.clamp(lowerBound, upperBound);
    _targetValue = lowerBound;
    _startValue = _value;
    _curve = curve;
    _status = AnimationStatus.reverse;
    _startTime = null;
    _repeating = false;
    _notifyStatusListeners();
    return _scheduleTick();
  }

  /// Animates to [target] with optional [duration] and [curve] overrides.
  Cmd animateTo(double target, {Duration? duration, Curve curve = Curves.linear}) {
    _targetValue = target.clamp(lowerBound, upperBound);
    _startValue = _value;
    _curve = curve;
    if (duration != null) this.duration = duration;
    _status = target >= _value ? AnimationStatus.forward : AnimationStatus.reverse;
    _startTime = null;
    _repeating = false;
    _notifyStatusListeners();
    return _scheduleTick();
  }

  /// Repeats the animation indefinitely between [min] and [max].
  ///
  /// If [reverse] is true, alternates direction each cycle.
  Cmd repeat({
    double? min,
    double? max,
    bool reverse = false,
    Duration? period,
  }) {
    final lo = min ?? lowerBound;
    final hi = max ?? upperBound;
    if (period != null) duration = period;
    _value = lo;
    _startValue = lo;
    _targetValue = hi;
    _curve = Curves.linear;
    _status = AnimationStatus.forward;
    _startTime = null;
    _repeating = true;
    _reverseOnRepeat = reverse;
    _notifyStatusListeners();
    return _scheduleTick();
  }

  /// Stops the animation at its current value.
  void stop() {
    if (!isAnimating) return;
    _status = _value == upperBound
        ? AnimationStatus.completed
        : (_value == lowerBound
            ? AnimationStatus.dismissed
            : _status); // keep forward/reverse for in-between values
    // By setting status to non-animating, processTick becomes a no-op
    // and handleUpdate won't return another Cmd.tick — animation self-terminates.
    _status = _value >= upperBound
        ? AnimationStatus.completed
        : AnimationStatus.dismissed;
    _repeating = false;
    _notifyStatusListeners();
  }

  /// Resets the animation to [lowerBound].
  void reset() {
    _value = lowerBound;
    _status = AnimationStatus.dismissed;
    _startTime = null;
    _repeating = false;
    notifyListeners();
    _notifyStatusListeners();
  }

  /// Releases resources.
  @override
  void dispose() {
    _statusListeners.clear();
    super.dispose(); // ChangeNotifier.dispose clears listeners
  }

  // ── API: Process Frame Ticks ──────────────────────────────────────────────

  /// Processes a frame tick. Call this from [State.handleUpdate] when an
  /// [AnimationTickMsg] with a matching [controllerId] is received.
  ///
  /// Returns a [Cmd] to schedule the next tick if the animation is still
  /// running, or `null` if it has completed.
  Cmd? processTick(DateTime now) {
    if (!isAnimating) return null;

    _startTime ??= now;
    final elapsed = now.difference(_startTime!);
    final totalDuration = _activeDuration;

    if (totalDuration == null || totalDuration == Duration.zero) {
      _value = _targetValue;
      _completeAnimation();
      return null;
    }

    final t = (elapsed.inMicroseconds / totalDuration.inMicroseconds)
        .clamp(0.0, 1.0);
    final curvedT = _curve.transform(t);
    _value = _startValue + (_targetValue - _startValue) * curvedT;

    if (t >= 1.0) {
      _value = _targetValue;

      if (_repeating) {
        return _handleRepeatCycle();
      }

      _completeAnimation();
      return null;
    }

    notifyListeners();
    return _scheduleTick();
  }

  // ── Internals ─────────────────────────────────────────────────────────────

  Duration? get _activeDuration {
    if (_status == AnimationStatus.reverse && reverseDuration != null) {
      return reverseDuration;
    }
    return duration;
  }

  void _completeAnimation() {
    _status = _targetValue >= upperBound
        ? AnimationStatus.completed
        : AnimationStatus.dismissed;
    notifyListeners();
    _notifyStatusListeners();
  }

  Cmd? _handleRepeatCycle() {
    if (_reverseOnRepeat) {
      // Swap direction
      final tmp = _startValue;
      _startValue = _targetValue;
      _targetValue = tmp;
      _status = _status == AnimationStatus.forward
          ? AnimationStatus.reverse
          : AnimationStatus.forward;
    } else {
      // Jump back to start
      _value = _startValue;
    }
    _startTime = null; // Reset for next cycle
    notifyListeners();
    _notifyStatusListeners();
    return _scheduleTick();
  }

  Cmd _scheduleTick() {
    return Cmd.tick(_frameDuration, (time) => AnimationTickMsg(_id, time));
  }

  AnimationStatus? _lastReportedStatus;

  void _notifyStatusListeners() {
    if (_status == _lastReportedStatus) return;
    _lastReportedStatus = _status;
    for (final listener in List<AnimationStatusListener>.of(_statusListeners)) {
      listener(_status);
    }
  }
}
```

### Key differences from nocterm's AnimationController

| Aspect | Nocterm | Ours |
|--------|--------|------|
| Constructor requires `TickerProvider vsync` | Yes | No — no Ticker |
| `forward()` returns `TickerFuture` | Yes | Returns `Cmd` |
| Frame scheduling | Internal `Ticker` → `SchedulerBinding` | External: returns `Cmd.tick()` |
| Tick processing | Internal `_tick(Duration elapsed)` | Public `processTick(DateTime now)` |
| Stopping | `stop()` → cancels ticker | `stop()` → sets non-animating status; self-terminates |
| Simulation classes | `_InterpolationSimulation`, `_RepeatingSimulation` | Inline math (simpler); can factor out if needed |
| Listener pattern | Same (`addListener`, `notifyListeners`) | Same |

---

### Phase 7: AnimationMixin for State

Convenience mixin that handles `AnimationTickMsg` dispatch automatically.

**New file: `lib/src/widgets/animation/animation_mixin.dart`**

```dart
import 'package:artisanal/tui.dart' show Cmd, Msg;
import '../core/framework.dart' show State, StatefulWidget;
import 'animation_controller.dart';
import 'animation_tick.dart';

/// Mixin for [State] classes that host one or more [AnimationController]s.
///
/// Automatically dispatches [AnimationTickMsg] to the correct controller
/// and chains the next frame tick if the animation is still running.
///
/// Usage:
/// ```dart
/// class _MyState extends State<MyWidget> with AnimationMixin {
///   late AnimationController _controller;
///
///   @override
///   void initState() {
///     super.initState();
///     _controller = createAnimationController(
///       duration: Duration(milliseconds: 300),
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
mixin AnimationMixin<T extends StatefulWidget> on State<T> {
  final List<AnimationController> _controllers = [];

  /// Creates and registers an [AnimationController].
  ///
  /// The controller is automatically disposed when this State is disposed.
  AnimationController createAnimationController({
    double? value,
    Duration? duration,
    Duration? reverseDuration,
    double lowerBound = 0.0,
    double upperBound = 1.0,
    int fps = 30,
    Object? id,
  }) {
    final controller = AnimationController(
      value: value,
      duration: duration,
      reverseDuration: reverseDuration,
      lowerBound: lowerBound,
      upperBound: upperBound,
      fps: fps,
      id: id,
    );
    _controllers.add(controller);
    return controller;
  }

  /// Registers an externally-created controller for tick dispatch and
  /// automatic disposal.
  void registerAnimationController(AnimationController controller) {
    if (!_controllers.contains(controller)) {
      _controllers.add(controller);
    }
  }

  @override
  Cmd? handleUpdate(Msg msg) {
    if (msg is AnimationTickMsg) {
      for (final controller in _controllers) {
        if (controller.id == msg.controllerId) {
          final nextCmd = controller.processTick(msg.time);
          // processTick calls notifyListeners which calls setState
          // so the widget is already marked dirty.
          return nextCmd;
        }
      }
    }
    return super.handleUpdate(msg);
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    _controllers.clear();
    super.dispose();
  }
}
```

---

### Phase 8: Animated Builder Widgets

Port `AnimatedBuilder` and `ListenableBuilder` from nocterm, adapted for
artisanal's `StatefulWidget` / `State` / `Widget`.

**New file: `lib/src/widgets/animation/animated_builder.dart`**

```dart
/// A widget that rebuilds whenever a [Listenable] notifies.
class AnimatedBuilder extends StatefulWidget {
  AnimatedBuilder({
    required this.animation,
    required this.builder,
    this.child,
    super.key,
  });

  final Listenable animation;
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  @override
  State createState() => _AnimatedBuilderState();
}

class _AnimatedBuilderState extends State<AnimatedBuilder> {
  @override
  void initState() {
    super.initState();
    widget.animation.addListener(_handleChange);
  }

  @override
  void didUpdateWidget(AnimatedBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animation != oldWidget.animation) {
      oldWidget.animation.removeListener(_handleChange);
      widget.animation.addListener(_handleChange);
    }
  }

  @override
  void dispose() {
    widget.animation.removeListener(_handleChange);
    super.dispose();
  }

  void _handleChange() => setState(() {});

  @override
  Widget build(BuildContext context) => widget.builder(context, widget.child);
}

/// Same pattern but for any [Listenable], not just animations.
class ListenableBuilder extends StatefulWidget {
  ListenableBuilder({
    required this.listenable,
    required this.builder,
    this.child,
    super.key,
  });

  final Listenable listenable;
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  @override
  State createState() => _ListenableBuilderState();
}
// (Same State implementation as AnimatedBuilder, referencing listenable.)
```

---

### Phase 9: Implicit Animation Widgets (Future / Optional)

Once the core animation system is in place, build implicit animation widgets
that animate automatically when their properties change. Examples:

- `AnimatedContainer` — animates padding, color, width, height changes
- `AnimatedOpacity` — animates opacity transitions
- `AnimatedCrossFade` — cross-fades between two children
- `AnimatedSwitcher` — animates child replacement

These widgets internally create an `AnimationController`, use `AnimationMixin`,
and call `forward()` / `reverse()` when properties change in
`didUpdateWidget()`.

**This phase is deferred.** The foundation (Phases 1–8) must be solid first.

---

## File Structure (Final)

```
lib/src/widgets/animation/
├── animation.dart              # AnimationStatus, Animation<T>, Animatable<T>,
│                               # _AnimatedEvaluation, _ChainedEvaluation
├── animation_controller.dart   # AnimationController
├── animation_mixin.dart        # AnimationMixin for State
├── animation_tick.dart         # AnimationTickMsg
├── animated_builder.dart       # AnimatedBuilder, ListenableBuilder
├── animations.dart             # Barrel file — exports everything
├── curves.dart                 # Curve, Cubic, Curves presets
├── listenable.dart             # Listenable, ValueListenable,
│                               # ChangeNotifier, ValueNotifier
└── tween.dart                  # Tween<T>, IntTween, DoubleTween, ColorTween,
                                # CurveTween, TweenSequence, Interval, Threshold
```

---

## Implementation Order & Dependencies

```
Phase 1: listenable.dart
  ↓
Phase 2: curves.dart            (no deps)
  ↓
Phase 3: tween.dart             (depends on: curves, listenable)
  ↓
Phase 4: animation.dart         (depends on: listenable)
  ↓
Phase 5: animation_tick.dart    (depends on: artisanal Msg)
  ↓
Phase 6: animation_controller.dart  (depends on: animation, curves,
  ↓                                  animation_tick, listenable, artisanal Cmd)
Phase 7: animation_mixin.dart   (depends on: animation_controller,
  ↓                               animation_tick, framework State)
Phase 8: animated_builder.dart   (depends on: listenable, framework)
  ↓
Phase 9: animations.dart barrel  (exports all)
  ↓
Phase 10: Wire into widgets.dart exports
  ↓
Phase 11 (future): Implicit animation widgets
```

Phases 1–4 are independent of each other except tween→curves and
animation→listenable. Phases 2 and 3 can be done in parallel with Phase 1.

---

## Usage Examples

### Example 1: Fade-in animation

```dart
class FadeIn extends StatefulWidget {
  FadeIn({required this.child, super.key});
  final Widget child;

  @override
  State createState() => _FadeInState();
}

class _FadeInState extends State<FadeIn> with AnimationMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = createAnimationController(
      duration: const Duration(milliseconds: 500),
    );
    _controller.addListener(() => setState(() {}));
  }

  @override
  Cmd? handleInit() => _controller.forward(curve: Curves.easeIn);

  @override
  Widget build(BuildContext context) {
    // _controller.value goes from 0.0 → 1.0
    // Use it to control opacity, visibility, etc.
    if (_controller.value < 0.01) return SizedBox.shrink();
    return widget.child;
  }
}
```

### Example 2: Pulsing indicator (repeating animation)

```dart
class PulsingDot extends StatefulWidget {
  PulsingDot({super.key});

  @override
  State createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot> with AnimationMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = createAnimationController(
      duration: const Duration(seconds: 1),
    );
    _controller.addListener(() => setState(() {}));
  }

  @override
  Cmd? handleInit() => _controller.repeat(reverse: true);

  @override
  Widget build(BuildContext context) {
    // _controller.value oscillates 0.0 → 1.0 → 0.0 → ...
    final char = _controller.value > 0.5 ? '●' : '○';
    return Text(char);
  }
}
```

### Example 3: Animated builder with tween

```dart
class ColorTransition extends StatefulWidget {
  ColorTransition({super.key});

  @override
  State createState() => _ColorTransitionState();
}

class _ColorTransitionState extends State<ColorTransition> with AnimationMixin {
  late AnimationController _controller;
  late Animation<double> _curved;

  @override
  void initState() {
    super.initState();
    _controller = createAnimationController(
      duration: const Duration(milliseconds: 800),
    );
    _curved = CurveTween(curve: Curves.easeInOut).animate(_controller);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curved,
      builder: (context, child) {
        // _curved.value goes 0.0 → 1.0 with easeInOut curve applied
        return Container(
          color: _curved.value > 0.5 ? theme.primary : theme.surface,
          child: child,
        );
      },
      child: Text('Hello'),
    );
  }

  Cmd? _toggle() {
    return _controller.isCompleted
        ? _controller.reverse()
        : _controller.forward();
  }
}
```

### Example 4: AnimationController without mixin (manual)

```dart
class _ManualState extends State<ManualWidget> {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
    );
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Cmd? handleInit() => _controller.forward();

  @override
  Cmd? handleUpdate(Msg msg) {
    // Manual tick dispatch (AnimationMixin does this automatically)
    if (msg is AnimationTickMsg && msg.controllerId == _controller.id) {
      return _controller.processTick(msg.time);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Text('Value: ${_controller.value.toStringAsFixed(2)}');
  }
}
```

---

## Testing Strategy

### Unit tests — pure logic (no widget framework)

| Test file | What it covers |
|-----------|---------------|
| `test/animation/listenable_test.dart` | `ChangeNotifier` add/remove/notify/dispose, `ValueNotifier` value changes, `Listenable.merge` |
| `test/animation/curves_test.dart` | Each curve: `transform(0.0) == 0.0`, `transform(1.0) == 1.0`, monotonicity for monotone curves, `flipped` correctness |
| `test/animation/tween_test.dart` | `Tween.transform` at 0, 0.5, 1; `IntTween` rounding; `CurveTween` applies curve; `TweenSequence` weight distribution; `Interval` clamping |
| `test/animation/animation_test.dart` | `Animatable.transform`, `_AnimatedEvaluation` delegates, `_ChainedEvaluation` composes |
| `test/animation/animation_controller_test.dart` | `forward()` returns Cmd; `processTick` updates value; status transitions; `stop()`/`reset()`; `repeat()` cycling; `reverse()`; curve application; listener notifications; `dispose()` cleanup |

### Widget integration tests

| Test file | What it covers |
|-----------|---------------|
| `test/animation/animation_mixin_test.dart` | Mixin creates controllers; dispatches `AnimationTickMsg`; disposes on unmount; multiple controllers |
| `test/animation/animated_builder_test.dart` | Rebuilds when listenable notifies; swaps listenable on update; child optimization; cleanup on dispose |

### Testing animation timing

Since `Cmd.tick()` is async, controller tests should test `processTick()`
directly with synthetic `DateTime` values:

```dart
test('forward animates value from 0 to 1', () {
  final controller = AnimationController(
    duration: const Duration(milliseconds: 100),
  );

  final cmd = controller.forward();
  expect(cmd, isA<Cmd>());
  expect(controller.status, AnimationStatus.forward);
  expect(controller.value, 0.0);

  // Simulate ticks
  final start = DateTime(2024, 1, 1);
  controller.processTick(start); // sets _startTime
  expect(controller.value, 0.0);

  controller.processTick(start.add(Duration(milliseconds: 50)));
  expect(controller.value, closeTo(0.5, 0.01));

  final nextCmd = controller.processTick(start.add(Duration(milliseconds: 100)));
  expect(controller.value, 1.0);
  expect(controller.status, AnimationStatus.completed);
  expect(nextCmd, isNull); // self-terminated
});
```

---

## Migration Impact

### No breaking changes

This plan adds new files only. No existing APIs are modified or removed.
The animation system is purely additive.

### New export

Add to `lib/src/widgets/widgets.dart`:

```dart
export 'animation/animations.dart';
```

### Widgets that could adopt animations later

Once the system is in place, these existing widgets could optionally use
animations for transitions (non-breaking, progressive enhancement):

| Widget | Potential animation |
|--------|-------------------|
| `Accordion` | Expand/collapse transition |
| `Drawer` | Slide-in/slide-out |
| `Modal` | Fade-in backdrop + slide content |
| `Switch` | Thumb slide animation |
| `SpinnerIndicator` | Could migrate to `AnimationController.repeat()` |
| `ScrollView` | Smooth scroll (momentum/deceleration) |

---

## Open Questions

### 1. First-tick timing with `Cmd.tick()`

`Cmd.tick(frameDuration, callback)` has a minimum delay of `frameDuration`
before the first tick. This means the first frame of animation is delayed by
one frame period (~33ms at 30fps). For most TUI animations this is
imperceptible, but we could add a `Cmd.immediate()` variant that fires on the
next microtask if needed.

### 2. Multiple controllers sharing a single tick

When a State has multiple AnimationControllers, each creates its own
`Cmd.tick()` chain. This means N controllers produce N timers. An optimization
would be a shared frame tick that dispatches to all controllers, but this adds
complexity. Defer until profiling shows it matters.

### 3. Frame rate

Default is 30fps (`_frameDuration = ~33ms`). This matches nocterm's
`SchedulerBinding` default and is appropriate for TUI. Should be configurable
per-controller and possibly globally.

### 4. `ColorTween` availability

`ColorTween` requires `Color.lerp`. If artisanal's `Color` type does not have
a `lerp` method, we either:
- Add `Color.lerp` to the core package
- Implement lerp inline in `ColorTween`
- Skip `ColorTween` initially

### 5. `EveryCmd`-based animation for long-running effects

For effects like a permanent pulsing cursor or background color cycling, the
self-chaining `Cmd.tick()` approach creates garbage (a new `Cmd` object each
frame). `EveryCmd` with a direct `.stop()` reference is more efficient for
these cases. Both approaches should be documented; `AnimationController` should
support both modes.

### 6. Interaction with gesture system

The gesture plan (see `GESTURE_PLAN.md`) introduces recognizers that return
`Cmd?`. Starting an animation from a gesture callback means returning a `Cmd`
from the gesture handler. This composes naturally:

```dart
Cmd? _onTap(TapDetails d) {
  return _controller.forward();
}
```

If both a gesture Cmd and an animation Cmd need to be returned simultaneously,
use `Cmd.batch([gestureCmd, animationCmd])`.

### 7. Status listener Cmd returns

In the current design, `AnimationStatusListener` is `void Function(status)`.
If a status listener needs to produce a `Cmd` (e.g., start another animation
when the first completes), it must call a method on the State that queues the
Cmd. This is a pattern to document clearly. One approach:

```dart
_controller.addStatusListener((status) {
  if (status == AnimationStatus.completed) {
    // Queue the reverse animation for next tick
    _pendingCmd = _controller.reverse();
    setState(() {});
  }
});
```

Then in `handleUpdate`, return `_pendingCmd` and clear it. The `AnimationMixin`
could provide a helper for this pattern.