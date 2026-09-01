
// ignore_for_file: unused_shown_name
import 'package:artisanal/style.dart' hide Padding, Align;
import 'package:artisanal/runtime.dart'
    show
        Cmd,
        Msg,
        KeyType,
        KeyMsg,
        MouseMsg,
        MouseAction,
        MouseButton,
        HitTestMouseMsg,
        View,
        TuiTrace,
        TraceTag;
import '../core/framework.dart'
    show BuildContext, StatelessWidget, StatefulWidget, State;
import '../core/widget.dart';
import '../theme/theme.dart' show hasDarkBackground, currentTheme;
import '../animation/animation_controller.dart';
import '../animation/animation_mixin.dart';

import 'tint.dart';

/// A widget that applies an animated color tint over its child.
///
/// The tint color animates from [begin] to [end] over the specified [duration].
/// Uses [AnimationMixin] to drive the animation through the TEA message loop.
///
/// ```dart
/// AnimatedTint(
///   begin: Colors.transparent,
///   end: Colors.red,
///   duration: Duration(milliseconds: 500),
///   child: Text('Fading to red'),
/// )
/// ```
class AnimatedTint extends StatefulWidget {
  AnimatedTint({
    required this.begin,
    required this.end,
    required this.duration,
    this.child,
    this.autoStart = true,
    super.key,
  });

  /// Starting tint color.
  final Color begin;

  /// Ending tint color.
  final Color end;

  /// Duration of the animation.
  final Duration duration;

  /// The child widget to tint.
  final Widget? child;

  /// Whether to start the animation automatically on init.
  final bool autoStart;

  @override
  State<AnimatedTint> createState() => _AnimatedTintState();
}

class _AnimatedTintState extends State<AnimatedTint> with AnimationMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = createAnimationController(duration: widget.duration);
    _controller.addListener(() => setState(() {}));
  }

  @override
  Cmd? handleInit() {
    if (widget.autoStart) {
      return _controller.forward();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // Interpolate between begin and end colors using controller value.
    final t = _controller.value;
    final color = _lerpColor(widget.begin, widget.end, t);
    return Tint(color: color, opacity: t, child: widget.child);
  }
}

/// A widget that fades a tint in or out over its child.
///
/// This is a convenience wrapper around [AnimatedTint] that animates a
/// single color's opacity from 0.0 to 1.0 (or reverse).
///
/// ```dart
/// FadeTint(
///   color: Colors.blue,
///   duration: Duration(milliseconds: 300),
///   child: Text('Fading blue tint'),
/// )
/// ```
class FadeTint extends StatefulWidget {
  FadeTint({
    required this.color,
    required this.duration,
    this.child,
    this.fadeIn = true,
    this.autoStart = true,
    super.key,
  });

  /// The tint color to fade.
  final Color color;

  /// Duration of the fade animation.
  final Duration duration;

  /// The child widget to tint.
  final Widget? child;

  /// If true, fades in (0→1). If false, fades out (1→0).
  final bool fadeIn;

  /// Whether to start the animation automatically on init.
  final bool autoStart;

  @override
  State<FadeTint> createState() => _FadeTintState();
}

class _FadeTintState extends State<FadeTint> with AnimationMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = createAnimationController(
      duration: widget.duration,
      value: widget.fadeIn ? 0.0 : 1.0,
    );
    _controller.addListener(() => setState(() {}));
  }

  @override
  Cmd? handleInit() {
    if (widget.autoStart) {
      return widget.fadeIn ? _controller.forward() : _controller.reverse();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Tint(
      color: widget.color,
      opacity: _controller.value,
      child: widget.child,
    );
  }
}

/// Linearly interpolates between two [Color]s.
///
/// Returns a hex Color for the interpolated value. For terminal use,
/// we convert to hex components and blend.
Color _lerpColor(Color a, Color b, double t) {
  return blendColor(a, b, t, hasDarkBackground: hasDarkBackground);
}
