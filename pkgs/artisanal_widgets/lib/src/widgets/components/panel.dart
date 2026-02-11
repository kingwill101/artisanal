part of 'components_widgets.dart';

class PanelBox extends StatelessWidget {
  PanelBox({
    required this.child,
    this.title,
    this.actions = const [],
    this.padding,
    this.margin,
    this.background,
    this.foreground,
    this.border,
    this.borderColor,
    this.titleStyle,
    this.bodyStyle,
    super.key,
  });

  final Widget child;
  final String? title;
  final List<Widget> actions;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? background;
  final Color? foreground;
  final Border? border;
  final Color? borderColor;
  final Style? titleStyle;
  final Style? bodyStyle;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final headerStyle = _copyStyle(titleStyle ?? theme.titleSmall)
      ..foreground(foreground ?? theme.onSurface);
    final contentStyle = _copyStyle(bodyStyle ?? theme.bodyMedium)
      ..foreground(foreground ?? theme.onSurface);

    final hasHeader = title != null || actions.isNotEmpty;
    final header = hasHeader
        ? Row(
            gap: 1,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (title != null) Text(title!, style: headerStyle),
              if (actions.isNotEmpty) Spacer(),
              if (actions.isNotEmpty) Row(gap: 1, children: actions),
            ],
          )
        : null;

    final body = bodyStyle == null
        ? child
        : Frame(style: contentStyle, child: child);

    final content = Column(
      gap: hasHeader ? 1 : 0,
      children: [
        if (header != null) header,
        if (header != null) Divider(style: Style().foreground(theme.border)),
        body,
      ],
    );

    return Frame(
      padding: padding ?? const EdgeInsets.all(1),
      margin: margin,
      background: background ?? theme.surface,
      border: border ?? Border.rounded,
      borderColor: borderColor ?? theme.border,
      child: content,
    );
  }
}
