part of 'components_widgets.dart';

class Frame extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final stylePadding = _edgeInsetsFromStylePadding(style?.getPadding);
    final styleMargin = _edgeInsetsFromStyleMargin(style?.getMargin);
    final styleBorder = _borderFromStyle(style);
    final styleBackground = style?.getBackground;
    final styleForeground = style?.getForeground;
    final styleBorderColor = style?.getBorderForeground;

    final effectiveBorder = border ?? styleBorder;
    final effectiveBackground = background ?? styleBackground;
    final effectiveForeground = foreground ?? styleForeground;
    final effectiveBorderColor = borderColor ?? styleBorderColor;

    final decoration = (effectiveBackground != null || effectiveBorder != null)
        ? BoxDecoration(color: effectiveBackground, border: effectiveBorder)
        : null;

    Widget content = child;
    if (effectiveForeground != null) {
      content = Tint(color: effectiveForeground, child: content);
    }

    return Container(
      padding: padding ?? stylePadding,
      margin: margin ?? styleMargin,
      decoration: decoration,
      foreground: effectiveBorderColor,
      child: content,
    );
  }
}

Border? _borderFromStyle(Style? style) {
  if (style == null) return null;
  final border = style.getBorder;
  if (border == null || !border.isVisible) return border;
  final sides = style.getBorderSides;

  return border.copyWith(
    top: sides.top ? border.top : '',
    bottom: sides.bottom ? border.bottom : '',
    left: sides.left ? border.left : '',
    right: sides.right ? border.right : '',
    topLeft: sides.top && sides.left ? border.topLeft : '',
    topRight: sides.top && sides.right ? border.topRight : '',
    bottomLeft: sides.bottom && sides.left ? border.bottomLeft : '',
    bottomRight: sides.bottom && sides.right ? border.bottomRight : '',
  );
}

EdgeInsets? _edgeInsetsFromStylePadding(Object? padding) {
  if (padding == null) return null;
  final top = (padding as dynamic).top as int? ?? 0;
  final right = (padding as dynamic).right as int? ?? 0;
  final bottom = (padding as dynamic).bottom as int? ?? 0;
  final left = (padding as dynamic).left as int? ?? 0;
  if (top == 0 && right == 0 && bottom == 0 && left == 0) {
    return null;
  }
  return EdgeInsets.only(top: top, right: right, bottom: bottom, left: left);
}

EdgeInsets? _edgeInsetsFromStyleMargin(Object? margin) {
  if (margin == null) return null;
  final top = (margin as dynamic).top as int? ?? 0;
  final right = (margin as dynamic).right as int? ?? 0;
  final bottom = (margin as dynamic).bottom as int? ?? 0;
  final left = (margin as dynamic).left as int? ?? 0;
  if (top == 0 && right == 0 && bottom == 0 && left == 0) {
    return null;
  }
  return EdgeInsets.only(top: top, right: right, bottom: bottom, left: left);
}
