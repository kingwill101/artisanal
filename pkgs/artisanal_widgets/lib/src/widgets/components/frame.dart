part of 'components_widgets.dart';

class Frame extends Widget {
  Frame({
    required this.child,
    this.padding,
    this.margin,
    this.background,
    this.foreground,
    this.border,
    this.borderColor,
    this.style,
    super.key,
  });

  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? background;
  final Color? foreground;
  final Border? border;
  final Color? borderColor;
  final Style? style;

  @override
  List<Widget> get children => [child];

  @override
  Object view() {
    final content = _renderWidget(child);
    final resolved = _copyStyle(style);
    if (background != null) resolved.background(background!);
    if (foreground != null) resolved.foreground(foreground!);
    if (border != null) resolved.border(border!);
    if (borderColor != null) resolved.borderForeground(borderColor!);
    _applyPadding(resolved, padding);
    _applyMargin(resolved, margin);
    return resolved.render(content);
  }
}
