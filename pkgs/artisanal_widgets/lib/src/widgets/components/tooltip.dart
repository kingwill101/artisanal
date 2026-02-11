part of 'components_widgets.dart';

enum TooltipPosition { above, below }

class Tooltip extends StatefulWidget {
  Tooltip({
    required this.message,
    required this.child,
    this.position = TooltipPosition.above,
    this.show,
    this.padding,
    this.background,
    this.foreground,
    this.textStyle,
    this.enabled = true,
    super.key,
  });

  final String message;
  final Widget child;
  final TooltipPosition position;
  final bool? show;
  final EdgeInsets? padding;
  final Color? background;
  final Color? foreground;
  final Style? textStyle;
  final bool enabled;

  @override
  State createState() => _TooltipState();
}

class _TooltipState extends State<Tooltip> {
  bool _hovered = false;

  void _setHovered(bool value) {
    if (_hovered == value) return;
    setState(() {
      _hovered = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final show = widget.enabled && (widget.show ?? _hovered);
    final labelStyle = _copyStyle(widget.textStyle ?? theme.bodySmall)
      ..foreground(widget.foreground ?? theme.onSurface);

    final bubble = Frame(
      padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 1),
      background: widget.background ?? theme.surface,
      border: Border.normal,
      borderColor: theme.border,
      child: Text(widget.message, style: labelStyle),
    );

    final target = widget.enabled
        ? MouseRegion(
            onEnter: (_) {
              _setHovered(true);
              return null;
            },
            onExit: (_) {
              _setHovered(false);
              return null;
            },
            child: widget.child,
          )
        : widget.child;

    if (!show) return target;

    return Column(
      gap: 1,
      children: widget.position == TooltipPosition.above
          ? [bubble, target]
          : [target, bubble],
    );
  }
}
