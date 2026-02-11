part of 'components_widgets.dart';

class ListTile extends StatelessWidget {
  ListTile({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.selected = false,
    this.dense = false,
    this.padding,
    this.background,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final bool selected;
  final bool dense;
  final EdgeInsets? padding;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final fg = selected ? theme.onPrimary : theme.onSurface;
    final bg = selected ? theme.primary : (background ?? theme.surface);

    final titleStyle = _copyStyle(theme.bodyMedium)..foreground(fg);
    final subtitleStyle = _copyStyle(theme.bodySmall)
      ..foreground(selected ? theme.onPrimary : theme.muted);

    final body = Column(
      gap: subtitle == null ? 0 : 1,
      children: [
        Text(title, style: titleStyle),
        if (subtitle != null) Text(subtitle!, style: subtitleStyle),
      ],
    );

    return Container(
      padding:
          padding ??
          EdgeInsets.symmetric(horizontal: 1, vertical: dense ? 0 : 1),
      color: bg,
      child: Row(
        gap: 1,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (leading != null) leading!,
          Expanded(child: body),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
