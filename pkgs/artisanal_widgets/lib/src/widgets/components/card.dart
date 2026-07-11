import 'package:artisanal/style.dart' show Color, Border, Style;
import 'package:artisanal_widgets/src/widgets/components/frame.dart';
import 'package:artisanal_widgets/src/widgets/core/widget.dart';
import 'package:artisanal_widgets/src/widgets/framework.dart';
import 'package:artisanal_widgets/src/widgets/layout_widgets.dart';
import 'package:artisanal_widgets/src/widgets/theme_scope.dart';
import 'package:artisanal_widgets/src/widgets/components/component_style.dart';

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
    final resolvedStyle = (textStyle != null || foreground != null)
        ? (copyStyle(textStyle ?? theme.bodyMedium)
            ..foreground(foreground ?? theme.onSurface))
        : null;
    return Frame(
      padding: padding ?? const EdgeInsets.all(1),
      margin: margin,
      background: background ?? theme.surface,
      border: border ?? Border.rounded,
      borderColor: borderColor ?? theme.border,
      style: resolvedStyle,
      child: child,
    );
  }
}
