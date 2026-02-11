part of 'components_widgets.dart';

class Badge extends StatelessWidget {
  Badge(
    this.label, {
    this.background,
    this.foreground,
    this.padding,
    this.textStyle,
    super.key,
  });

  final String label;
  final Color? background;
  final Color? foreground;
  final EdgeInsets? padding;
  final Style? textStyle;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final bg = background ?? theme.secondary;
    final fg = foreground ?? theme.onSecondary;
    final style = _copyStyle(textStyle ?? theme.labelSmall)..foreground(fg);
    return Frame(
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 1, vertical: 0),
      background: bg,
      child: Text(label, style: style),
    );
  }
}
