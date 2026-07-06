import 'package:artisanal/artisanal.dart' show Style;
import 'package:artisanal/style.dart' show Color;
import 'package:artisanal_widgets/src/widgets/components/frame.dart';
import 'package:artisanal_widgets/src/widgets/core/widget.dart';
import 'package:artisanal_widgets/src/widgets/framework.dart';
import 'package:artisanal_widgets/src/widgets/layout_widgets.dart';
import 'package:artisanal_widgets/src/widgets/theme_scope.dart';
import 'package:artisanal_widgets/src/widgets/components/component_style.dart';

/// A compact label with colored background, used for status, priority, or tags.
///
/// ```dart
/// Badge('Active')
/// Badge('v2.0', background: Colors.green, foreground: Colors.white)
/// Badge('Error', padding: EdgeInsets.only(left: 2, right: 1))
/// ```
class Badge extends StatelessWidget {
  Badge(
    this.label, {
    this.background,
    this.foreground,
    this.padding,
    this.paddingLeft,
    this.paddingRight,
    this.textStyle,
    super.key,
  });

  /// The text displayed inside the badge.
  final String label;

  /// Background color. Defaults to [Theme.secondary].
  final Color? background;

  /// Foreground (text) color. Defaults to [Theme.onSecondary].
  final Color? foreground;

  /// Symmetric padding. Ignored when [paddingLeft] or [paddingRight] is set.
  final EdgeInsets? padding;

  /// Left padding in cells. Overrides the left side of [padding].
  final int? paddingLeft;

  /// Right padding in cells. Overrides the right side of [padding].
  final int? paddingRight;

  /// Style override for the label text.
  final Style? textStyle;

  /// The display width of this badge in terminal cells.
  ///
  /// Includes the label text width plus any horizontal padding.
  int get width {
    final labelWidth = label.length;
    final left = paddingLeft ?? padding?.left.toInt() ?? 1;
    final right = paddingRight ?? padding?.right.toInt() ?? 1;
    return labelWidth + left + right;
  }

  EdgeInsets get _resolvedPadding {
    final left = paddingLeft;
    final right = paddingRight;
    if (left != null || right != null) {
      return EdgeInsets.only(
        left: left ?? 1,
        right: right ?? 1,
        top: 0,
        bottom: 0,
      );
    }
    return padding ?? const EdgeInsets.symmetric(horizontal: 1, vertical: 0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final bg = background ?? theme.secondary;
    final fg = foreground ?? theme.onSecondary;
    final style = copyStyle(textStyle ?? theme.labelSmall)..foreground(fg);
    return Frame(
      padding: _resolvedPadding,
      background: bg,
      child: Text(label, style: style),
    );
  }
}
