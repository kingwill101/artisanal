/// Base classes for implicitly animated widgets.
///
/// Provides [ImplicitlyAnimatedWidget] and [AnimatedWidgetBaseState] that
/// automatically animate property changes using tweens and animation
/// controllers. Subclasses override [forEachTween] to declare which
/// properties should be animated.
///
/// This follows the Flutter pattern where property changes trigger
/// animations automatically, without requiring manual controller management.
library;

import 'package:artisanal/tui.dart' show Cmd;

import '../core/framework.dart' show StatefulWidget, State;
import 'animation_controller.dart';
import 'animation_mixin.dart';
import 'curves.dart';
import 'tween.dart';

/// Abstract base class for widgets that implicitly animate when their
/// properties change.
///
/// Subclasses should override [State.build] and read animated values
/// from tweens set up in [AnimatedWidgetBaseState.forEachTween].
///
/// ```dart
/// class AnimatedOpacity extends ImplicitlyAnimatedWidget {
///   AnimatedOpacity({
///     required this.opacity,
///     required super.duration,
///     super.curve,
///   });
///   final double opacity;
///
///   @override
///   AnimatedWidgetBaseState<AnimatedOpacity> createState() =>
///       _AnimatedOpacityState();
/// }
/// ```
abstract class ImplicitlyAnimatedWidget extends StatefulWidget {
  ImplicitlyAnimatedWidget({required this.duration, this.curve, super.key});

  /// The duration over which to animate changes.
  final Duration duration;

  /// The curve to apply to the animation. Null uses linear.
  final Curve? curve;
}

/// Base state class for [ImplicitlyAnimatedWidget].
///
/// Subclasses must override [forEachTween] to register tweens for
/// each animatable property, and [build] to use the current tween values.
///
/// ```dart
/// class _AnimatedOpacityState
///     extends AnimatedWidgetBaseState<AnimatedOpacity> {
///   Tween<double>? _opacity;
///
///   @override
///   void forEachTween(TweenVisitor visitor) {
///     _opacity = visitor(
///       _opacity,
///       widget.opacity,
///       (value) => Tween<double>(begin: value as double, end: value),
///     ) as Tween<double>?;
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return Opacity(
///       opacity: _opacity?.evaluate(controller) ?? widget.opacity,
///       child: widget.child,
///     );
///   }
/// }
/// ```
abstract class AnimatedWidgetBaseState<T extends ImplicitlyAnimatedWidget>
    extends State<T>
    with AnimationMixin {
  late AnimationController _controller;

  /// The animation controller driving the implicit animation.
  AnimationController get controller => _controller;

  @override
  void initState() {
    super.initState();
    _controller = createAnimationController(duration: widget.duration);
    _controller.addListener(() => setState(() {}));
    _constructTweens();
  }

  @override
  Cmd? didUpdateWidget(T oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_shouldAnimate(oldWidget)) {
      _updateTweens();
      return _controller.forward(from: 0.0);
    }
    return null;
  }

  void _constructTweens() {
    forEachTween((
      Tween<dynamic>? tween,
      dynamic targetValue,
      TweenConstructor constructor,
    ) {
      if (tween == null) {
        return constructor(targetValue);
      }
      return tween;
    });
  }

  void _updateTweens() {
    forEachTween((
      Tween<dynamic>? tween,
      dynamic targetValue,
      TweenConstructor constructor,
    ) {
      if (tween == null) {
        return constructor(targetValue);
      }
      tween.begin = tween.evaluate(_controller);
      tween.end = targetValue;
      return tween;
    });
  }

  bool _shouldAnimate(T oldWidget) {
    bool changed = false;
    forEachTween((
      Tween<dynamic>? tween,
      dynamic targetValue,
      TweenConstructor constructor,
    ) {
      if (tween?.end != targetValue) {
        changed = true;
      }
      return tween;
    });
    return changed;
  }

  /// Called to register tweens for each animatable property.
  ///
  /// The [visitor] function takes:
  /// - The current tween (or null if first build)
  /// - The target value for the property
  /// - A constructor that creates a new tween for the given value
  ///
  /// The visitor returns the tween to use.
  void forEachTween(TweenVisitor visitor);
}

/// Callback type for visiting tweens in [AnimatedWidgetBaseState.forEachTween].
typedef TweenVisitor =
    Tween<dynamic>? Function(
      Tween<dynamic>? tween,
      dynamic targetValue,
      TweenConstructor constructor,
    );

/// Callback type for constructing a new [Tween] from a target value.
typedef TweenConstructor = Tween<dynamic> Function(dynamic value);
