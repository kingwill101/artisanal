import 'package:artisanal_widgets/src/widgets/core/widget.dart';
import 'package:artisanal_widgets/src/widgets/framework.dart';
import 'package:artisanal_widgets/src/widgets/layout_widgets.dart';
import 'package:artisanal_widgets/src/widgets/theme_scope.dart';
import 'package:artisanal_widgets/src/widgets/components/component_style.dart';

/// An expandable/collapsible section with a header.
///
/// The [Accordion] widget shows a [title] and expands to reveal its [child]
/// when [expanded] is `true`. Clicking the header toggles the expanded state
/// if [onChanged] is provided.
///
/// Use [leading] to add an icon or indicator before the title.
///
/// Example:
/// ```dart
/// Accordion(
///   title: 'Advanced Settings',
///   leading: Icon('⚙'),
///   expanded: _expanded,
///   onChanged: (v) => setState(() => _expanded = v),
///   child: Column(children: [Toggle('Option 1'), Toggle('Option 2')]),
/// )
/// ```
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
