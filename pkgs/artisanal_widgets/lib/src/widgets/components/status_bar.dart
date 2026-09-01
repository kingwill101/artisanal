import 'package:artisanal/style.dart' show Color;
import '_component_foundation.dart';

/// A horizontal bar that displays a row of [KeyHint] items.
///
/// Commonly used at the bottom of TUI applications to show available
/// keyboard shortcuts. Fully themeable via [StatusBarThemeData].
///
/// ```dart
/// StatusBar(
///   items: [
///     KeyHint(keyLabel: 'esc', description: 'interrupt'),
///     KeyHint(keyLabel: 'ctrl+p', description: 'commands'),
///   ],
/// )
/// ```
class StatusBar extends StatelessWidget {
  StatusBar({
    this.items = const [],
    this.leading,
    this.trailing,
    this.background,
    this.foreground,
    this.padding,
    this.separator,
    this.gap = 2,
    super.key,
  });

  /// Key hint items to display in the bar.
  final List<Widget> items;

  /// Optional widget at the start of the bar.
  final Widget? leading;

  /// Optional widget at the end of the bar.
  final Widget? trailing;

  /// Background color of the bar.
  /// Defaults to [StatusBarThemeData.background] or [Theme.surface].
  final Color? background;

  /// Default foreground color.
  /// Defaults to [StatusBarThemeData.foreground] or [Theme.onSurface].
  final Color? foreground;

  /// Padding inside the bar.
  final EdgeInsets? padding;

  /// Separator string between items (e.g., " | ").
  /// Defaults to [StatusBarThemeData.separator] or "  " (double space).
  final String? separator;

  /// Gap between items when no separator is set (default: 2).
  final int gap;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final sbTheme = theme.statusBarTheme;

    final bg = background ?? sbTheme?.background ?? theme.surface;
    final fg = foreground ?? sbTheme?.foreground ?? theme.onSurface;
    final sep = separator ?? sbTheme?.separator;
    final fgStyle = copyStyle(theme.bodySmall)..foreground(fg);

    final children = <Widget>[];

    if (leading != null) {
      children.add(leading!);
    }

    for (var i = 0; i < items.length; i++) {
      children.add(items[i]);
      if (sep != null && i < items.length - 1) {
        children.add(Text(sep, style: fgStyle));
      }
    }

    if (trailing != null) {
      if (children.isNotEmpty) children.add(Spacer());
      children.add(trailing!);
    }

    return Container(
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 1, vertical: 0),
      color: bg,
      child: Row(gap: sep != null ? 0 : gap, children: children),
    );
  }
}
