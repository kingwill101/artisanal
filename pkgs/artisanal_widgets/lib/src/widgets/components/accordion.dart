part of 'components_widgets.dart';

class Accordion extends StatelessWidget {
  Accordion({
    required this.title,
    required this.child,
    this.expanded = false,
    this.onChanged,
    this.enabled = true,
    this.leading,
    this.padding,
    super.key,
  });

  final String title;
  final Widget child;
  final bool expanded;
  final ValueCmdCallback<bool>? onChanged;
  final bool enabled;
  final Widget? leading;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final titleStyle = copyStyle(theme.bodyMedium)
      ..foreground(theme.onSurface)
      ..bold();
    final chevronStyle = copyStyle(theme.labelMedium)..foreground(theme.muted);

    Widget header = Row(
      gap: 1,
      children: [
        Text(expanded ? 'v' : '>', style: chevronStyle),
        ?leading,
        Text(title, style: titleStyle),
      ],
    );

    if (enabled && onChanged != null) {
      header = GestureDetector(
        onTap: () => onChanged?.call(!expanded),
        child: header,
      );
    }

    final content = Column(
      gap: expanded ? 1 : 0,
      children: [
        header,
        if (expanded)
          Padding(
            padding: padding ?? const EdgeInsets.only(left: 2),
            child: child,
          ),
      ],
    );

    return content;
  }
}
