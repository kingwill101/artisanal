part of 'components_widgets.dart';

class BreadcrumbItem {
  const BreadcrumbItem(this.label, {this.onTap, this.enabled = true});

  final String label;
  final CmdCallback? onTap;
  final bool enabled;
}

class Breadcrumbs extends StatelessWidget {
  Breadcrumbs({
    required this.items,
    this.separator = '/',
    this.gap = 1,
    this.interactiveLast = false,
    super.key,
  });

  final List<BreadcrumbItem> items;
  final String separator;
  final int gap;
  final bool interactiveLast;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final activeStyle = _copyStyle(theme.labelMedium)
      ..foreground(theme.onSurface)
      ..bold();
    final inactiveStyle = _copyStyle(theme.labelMedium)
      ..foreground(theme.muted);

    return Row(
      gap: gap,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          _crumb(items[i], i == items.length - 1, activeStyle, inactiveStyle),
          if (i < items.length - 1) Text(separator, style: inactiveStyle),
        ],
      ],
    );
  }

  Widget _crumb(
    BreadcrumbItem item,
    bool isLast,
    Style activeStyle,
    Style inactiveStyle,
  ) {
    final clickable =
        item.onTap != null && item.enabled && (!isLast || interactiveLast);
    if (clickable) {
      return Button(
        label: item.label,
        size: ButtonSize.small,
        variant: ButtonVariant.ghost,
        onPressed: item.onTap,
      );
    }
    return Text(item.label, style: isLast ? activeStyle : inactiveStyle);
  }
}
