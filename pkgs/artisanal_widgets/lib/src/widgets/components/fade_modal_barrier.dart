part of 'components_widgets.dart';

/// A modal barrier that fades in/out with an animated opacity.
///
/// In terminal layouts there is no true alpha compositing, so when this widget
/// has real child content it blends that content toward the barrier color in
/// place rather than painting an opaque colored layer above it. When used as a
/// standalone overlay with an empty child, it falls back to painting a
/// full-screen barrier layer.
///
/// When visible, it covers the entire parent area and optionally dismisses on
/// tap. Uses [AnimationMixin] to animate the opacity transition.
///
/// ```dart
/// FadeModalBarrier(
///   visible: _showBarrier,
///   color: Colors.black,
///   opacity: 0.6,
///   duration: Duration(milliseconds: 300),
///   onDismiss: () => setState(() => _showBarrier = false),
///   child: myContent,
/// )
/// ```
class FadeModalBarrier extends StatefulWidget {
  FadeModalBarrier({
    required this.child,
    this.visible = false,
    this.color,
    this.opacity = 0.6,
    this.duration = const Duration(milliseconds: 300),
    this.onDismiss,
    this.dismissible = true,
    super.key,
  });

  /// The content behind the barrier.
  final Widget child;

  /// Whether the barrier is visible.
  final bool visible;

  /// The barrier color. Defaults to the theme background color.
  final Color? color;

  /// Maximum opacity of the barrier when fully visible.
  final double opacity;

  /// Duration of the fade animation.
  final Duration duration;

  /// Callback when the barrier is tapped (for dismissal).
  final CmdCallback? onDismiss;

  /// Whether the barrier can be dismissed by tapping.
  final bool dismissible;

  @override
  State<FadeModalBarrier> createState() => _FadeModalBarrierState();
}

class _FadeModalBarrierState extends State<FadeModalBarrier>
    with AnimationMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = createAnimationController(
      duration: widget.duration,
      value: widget.visible ? 1.0 : 0.0,
    );
    _controller.addListener(() => setState(() {}));
  }

  @override
  Cmd? handleInit() {
    if (widget.visible) {
      return _controller.forward();
    }
    return null;
  }

  @override
  Cmd? didUpdateWidget(FadeModalBarrier oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible != oldWidget.visible) {
      if (widget.visible) {
        return _controller.forward();
      } else {
        return _controller.reverse();
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.value <= 0.0 && !widget.visible) {
      return widget.child;
    }

    final theme = ThemeScope.of(context);
    final effectiveOpacity = (_controller.value * widget.opacity).clamp(
      0.0,
      1.0,
    );

    if (_usesStandaloneOverlayFallback(widget.child)) {
      final barrier = GestureDetector(
        onTap: widget.dismissible ? () => widget.onDismiss?.call() : null,
        child: Opacity(
          opacity: effectiveOpacity,
          child: Container(color: widget.color ?? theme.background),
        ),
      );

      return Stack(fit: StackFit.expand, children: [widget.child, barrier]);
    }

    final dimmedChild = effectiveOpacity > 0.0
        ? Tint(
            color: widget.color ?? theme.background,
            opacity: effectiveOpacity,
            child: widget.child,
          )
        : widget.child;

    final dismissLayer = widget.dismissible
        ? GestureDetector(
            onTap: () => widget.onDismiss?.call(),
            child: Container(),
          )
        : Container();

    return Stack(
      fit: StackFit.expand,
      children: [
        IgnorePointer(ignoring: true, child: dimmedChild),
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          bottom: 0,
          child: dismissLayer,
        ),
      ],
    );
  }
}

bool _usesStandaloneOverlayFallback(Widget child) {
  return child is SizedBox &&
      child.child == null &&
      (child.width == null || child.width == 0) &&
      (child.height == null || child.height == 0);
}
