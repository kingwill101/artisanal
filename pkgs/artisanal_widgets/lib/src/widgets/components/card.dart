part of 'components_widgets.dart';

class Card extends StatelessWidget {
  Card({
    required this.child,
    this.padding,
    this.margin,
    this.background,
    this.foreground,
    this.border,
    this.borderColor,
    this.textStyle,
    super.key,
  });

  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? background;
  final Color? foreground;
  final Border? border;
  final Color? borderColor;
  final Style? textStyle;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final style = _copyStyle(textStyle ?? theme.bodyMedium)
      ..foreground(foreground ?? theme.onSurface);
    return Frame(
      padding: padding ?? const EdgeInsets.all(1),
      margin: margin,
      background: background ?? theme.surface,
      border: border ?? Border.rounded,
      borderColor: borderColor ?? theme.border,
      style: style,
      child: child,
    );
  }
}
