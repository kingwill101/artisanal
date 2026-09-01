import 'package:artisanal/style.dart';
import 'package:artisanal_widgets/src/widgets/components/button.dart';
import 'package:artisanal_widgets/src/widgets/core/widget.dart';
import 'package:artisanal_widgets/src/widgets/framework.dart';
import 'package:artisanal_widgets/src/widgets/layout/_layout_core.dart';
import 'package:artisanal_widgets/src/widgets/theme_scope.dart';
import 'package:artisanal_widgets/src/widgets/components/component_style.dart';

/// An item in a breadcrumb navigation trail.
class BreadcrumbItem {
  const BreadcrumbItem(this.label, {this.onTap, this.enabled = true});

  final String label;
  final CmdCallback? onTap;
  final bool enabled;
}

/// A horizontal breadcrumb trail showing navigation hierarchy.
///
/// The [Breadcrumbs] widget displays a list of [items] separated by [separator].
/// Clicking a breadcrumb invokes its [BreadcrumbItem.onTap] callback.
///
/// Set [interactiveLast] to `true` to make the last item clickable as well.
///
/// Example:
/// ```dart
/// Breadcrumbs(
///   items: [
///     BreadcrumbItem('Home', onTap: () => navigate('/')),
///     BreadcrumbItem('Settings', onTap: () => navigate('/settings')),
///     BreadcrumbItem('Theme', onTap: () => navigate('/settings/theme')),
///   ],
/// )
/// ```
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
    final activeStyle = copyStyle(theme.labelMedium)
      ..foreground(theme.onSurface)
      ..bold();
    final inactiveStyle = copyStyle(theme.labelMedium)..foreground(theme.muted);

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
