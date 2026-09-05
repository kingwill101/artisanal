import 'package:listen/listen.dart';

// ---------------------------------------------------------------------------
// AnimationStatus
// ---------------------------------------------------------------------------

/// The status of an animation.
enum AnimationStatus {
  /// The animation is stopped at the beginning.
  dismissed,

  /// The animation is running from beginning to end.
  forward,

  /// The animation is running backwards, from end to beginning.
  reverse,

  /// The animation is stopped at the end.
  completed,
}

/// Signature for callbacks that receive [AnimationStatus] changes.
typedef AnimationStatusListener = void Function(AnimationStatus status);

// ---------------------------------------------------------------------------
// Animation<T>
// ---------------------------------------------------------------------------

/// An animation with a value of type [T].
///
/// This is the core abstraction for animations. It extends [Listenable] so
/// widgets can subscribe to value changes, and [ValueListenable] so the
/// current value is always accessible.
///
/// Concrete implementations include [AnimationController] (which drives the
/// animation) and [_AnimatedEvaluation] (which applies an [Animatable] to a
/// parent animation).
abstract class Animation<T> extends Listenable implements ValueListenable<T> {
  const Animation();

  /// The current value of the animation.
  @override
  T get value;

  /// The current status of this animation.
  AnimationStatus get status;

  /// Registers a [listener] that is called when the animation status changes.
  void addStatusListener(AnimationStatusListener listener);

  /// Removes a previously registered status [listener].
  void removeStatusListener(AnimationStatusListener listener);

  /// Whether this animation is stopped at the beginning.
  bool get isDismissed => status == AnimationStatus.dismissed;

  /// Whether this animation is stopped at the end.
  bool get isCompleted => status == AnimationStatus.completed;

  /// Whether this animation is currently running (forward or reverse).
  bool get isAnimating =>
      status == AnimationStatus.forward || status == AnimationStatus.reverse;

  /// Chains this animation with an [Animatable] to produce a derived
  /// [Animation] of a different type.
  ///
  /// This is typically called on an [Animation<double>] (like an
  /// [AnimationController]) to transform the double into another type
  /// via a [Tween] or [CurveTween].
  ///
  /// ```dart
  /// final curved = controller.drive(CurveTween(curve: Curves.easeIn));
  /// final color = controller.drive(ColorTween(begin: red, end: blue));
  /// ```
  Animation<U> drive<U>(Animatable<U> child) {
    assert(
      this is Animation<double>,
      'drive() can only be called on Animation<double>',
    );
    return child.animate(this as Animation<double>);
  }
}

// ---------------------------------------------------------------------------
// Animatable<T>
// ---------------------------------------------------------------------------

/// Transforms a double (typically from an [Animation<double>]) into a value
/// of type [T].
///
/// This is the base class for [Tween], [CurveTween], and similar
/// interpolation/mapping objects.
abstract class Animatable<T> {
  const Animatable();

  /// Returns the value of this animatable at the given [t].
  ///
  /// [t] is typically in the range 0.0 to 1.0 but may extend beyond that
  /// range for curves that overshoot.
  T transform(double t);

  /// Evaluates this animatable at the current value of [animation].
  T evaluate(Animation<double> animation) => transform(animation.value);

  /// Creates a new [Animation] by applying this animatable on top of [parent].
  ///
  /// The returned animation's value is `this.transform(parent.value)` and it
  /// notifies listeners whenever [parent] notifies.
  Animation<T> animate(Animation<double> parent) {
    return _AnimatedEvaluation<T>(parent, this);
  }

  /// Chains this animatable after [parent].
  ///
  /// The result is an [Animatable] that first applies [parent]'s transform,
  /// then this animatable's transform.
  ///
  /// ```dart
  /// final curved = tween.chain(CurveTween(curve: Curves.easeIn));
  /// ```
  Animatable<T> chain(Animatable<double> parent) {
    return _ChainedEvaluation<T>(parent, this);
  }
}

// ---------------------------------------------------------------------------
// _AnimatedEvaluation (internal)
// ---------------------------------------------------------------------------

/// An [Animation] produced by applying an [Animatable] to a parent animation.
///
/// Created by [Animatable.animate]. Delegates listener registration to the
/// parent and evaluates [_evaluatable] on every access.
class _AnimatedEvaluation<T> extends Animation<T> {
  _AnimatedEvaluation(this._parent, this._evaluatable);

  final Animation<double> _parent;
  final Animatable<T> _evaluatable;

  @override
  T get value => _evaluatable.evaluate(_parent);

  @override
  AnimationStatus get status => _parent.status;

  @override
  void addListener(void Function() listener) => _parent.addListener(listener);

  @override
  void removeListener(void Function() listener) =>
      _parent.removeListener(listener);

  @override
  void addStatusListener(AnimationStatusListener listener) =>
      _parent.addStatusListener(listener);

  @override
  void removeStatusListener(AnimationStatusListener listener) =>
      _parent.removeStatusListener(listener);

  @override
  String toString() =>
      '$runtimeType(parent: $_parent, evaluatable: $_evaluatable)';
}

// ---------------------------------------------------------------------------
// _ChainedEvaluation (internal)
// ---------------------------------------------------------------------------

/// An [Animatable] that chains two animatables: first [_parent], then [_child].
///
/// Created by [Animatable.chain]. The transform is
/// `_child.transform(_parent.transform(t))`.
class _ChainedEvaluation<T> extends Animatable<T> {
  const _ChainedEvaluation(this._parent, this._child);

  final Animatable<double> _parent;
  final Animatable<T> _child;

  @override
  T transform(double t) => _child.transform(_parent.transform(t));

  @override
  String toString() => '$runtimeType(parent: $_parent, child: $_child)';
}

// ---------------------------------------------------------------------------
// AlwaysStoppedAnimation
// ---------------------------------------------------------------------------

/// An [Animation] that is always stopped at a given value.
///
/// Useful as a default or placeholder animation.
class AlwaysStoppedAnimation<T> extends Animation<T> {
  const AlwaysStoppedAnimation(this._value);

  final T _value;

  @override
  T get value => _value;

  @override
  AnimationStatus get status => AnimationStatus.dismissed;

  @override
  void addListener(void Function() listener) {}

  @override
  void removeListener(void Function() listener) {}

  @override
  void addStatusListener(AnimationStatusListener listener) {}

  @override
  void removeStatusListener(AnimationStatusListener listener) {}

  @override
  String toString() => 'AlwaysStoppedAnimation($_value)';
}

// ---------------------------------------------------------------------------
// ProxyAnimation
// ---------------------------------------------------------------------------

/// An [Animation] that proxies another animation.
///
/// Useful for swapping the underlying animation without re-registering
/// listeners.
class ProxyAnimation extends Animation<double> {
  /// Creates a proxy animation, optionally wrapping [parent].
  ProxyAnimation([Animation<double>? parent])
    : _parent = parent ?? const AlwaysStoppedAnimation<double>(0.0);

  Animation<double> _parent;
  final List<void Function()> _listeners = [];
  final List<AnimationStatusListener> _statusListeners = [];

  /// The animation this proxy is currently delegating to.
  Animation<double> get parent => _parent;

  set parent(Animation<double> value) {
    if (_parent == value) return;
    // Move listeners from old parent to new parent.
    for (final listener in _listeners) {
      _parent.removeListener(listener);
      value.addListener(listener);
    }
    for (final listener in _statusListeners) {
      _parent.removeStatusListener(listener);
      value.addStatusListener(listener);
    }
    _parent = value;
  }

  @override
  double get value => _parent.value;

  @override
  AnimationStatus get status => _parent.status;

  @override
  void addListener(void Function() listener) {
    _listeners.add(listener);
    _parent.addListener(listener);
  }

  @override
  void removeListener(void Function() listener) {
    _listeners.remove(listener);
    _parent.removeListener(listener);
  }

  @override
  void addStatusListener(AnimationStatusListener listener) {
    _statusListeners.add(listener);
    _parent.addStatusListener(listener);
  }

  @override
  void removeStatusListener(AnimationStatusListener listener) {
    _statusListeners.remove(listener);
    _parent.removeStatusListener(listener);
  }

  @override
  String toString() => '$runtimeType(parent: $_parent)';
}
