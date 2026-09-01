import 'package:artisanal_widgets/src/widgets/core/widget.dart';
import 'package:artisanal_widgets/src/widgets/framework.dart';
import 'package:artisanal_widgets/src/widgets/layout/_layout_core.dart';
import 'package:artisanal_widgets/src/widgets/style.dart' hide Padding;
import 'package:artisanal_widgets/src/widgets/theme/theme.dart';
import 'package:artisanal_widgets/src/widgets/theme_scope.dart';
import 'package:artisanal_widgets/src/widgets/components/component_style.dart';

import 'frame.dart';

/// The side on which the accent stripe is drawn.
enum AccentSide {
  /// Left edge accent (default).
  left,

  /// Right edge accent.
  right,
}

/// A panel with a colored vertical accent stripe on one side.
///
/// This is a common TUI pattern for callouts, info panels, collapsible
/// sections, and message annotations. The accent color can convey semantic
/// meaning (e.g., green for success, red for error, blue for info).
///
/// Fully themeable via [AccentPanelThemeData].
///
/// ```dart
/// AccentPanel(
///   accentColor: theme.success,
///   child: Text('File saved successfully'),
/// )
/// ```
class AccentPanel extends StatelessWidget {
  AccentPanel({
    required this.child,
    this.accentColor,
    this.accentWidth,
    this.accentChar,
    this.side = AccentSide.left,
    this.background,
    this.foreground,
    this.padding,
    this.title,
    this.titleStyle,
    this.expanded,
    this.onExpandChanged,
    super.key,
  });

  /// The panel body content.
  final Widget child;

  /// Color of the accent stripe.
  /// Defaults to [AccentPanelThemeData.accentColor] or [Theme.primary].
  final Color? accentColor;

  /// Width of the accent stripe in columns (default: 1).
  /// Defaults to [AccentPanelThemeData.accentWidth] or 1.
  final int? accentWidth;

  /// Character used for the accent stripe (default: '│').
  final String? accentChar;

  /// Which side the accent stripe is drawn on.
  final AccentSide side;

  /// Background color of the panel body.
  /// Defaults to [AccentPanelThemeData.background] or transparent.
  final Color? background;

  /// Text color in the panel body.
  /// Defaults to [AccentPanelThemeData.foreground] or [Theme.onSurface].
  final Color? foreground;

  /// Content padding inside the panel (excluding the accent stripe).
  /// Defaults to [AccentPanelThemeData.padding] or left: 1.
  final EdgeInsets? padding;

  /// Optional title shown on the first line.
  final String? title;

  /// Style for the title text.
  final Style? titleStyle;

  /// If non-null, makes the panel collapsible with this expansion state.
  final bool? expanded;

  /// Called when the expand/collapse toggle is tapped.
  final ValueCmdCallback<bool>? onExpandChanged;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final apTheme = theme.accentPanelTheme;

    final color = accentColor ?? apTheme?.accentColor ?? theme.primary;
    final width = accentWidth ?? apTheme?.accentWidth ?? 1;
    final char = accentChar ?? '│';
    final bg = background ?? apTheme?.background;
    final fg = foreground ?? apTheme?.foreground ?? theme.onSurface;
    final pad = padding ?? apTheme?.padding ?? const EdgeInsets.only(left: 1);

    // Build the accent stripe
    final accentStyle = copyStyle(null)..foreground(color);
    final accentText = List.filled(width, char).join();
    final accent = Text(accentText, style: accentStyle);

    // Build the content
    Widget content;
    final isCollapsible = expanded != null;

    if (title != null) {
      final tStyle = copyStyle(titleStyle ?? theme.titleSmall)
        ..foreground(fg)
        ..bold();

      Widget header;
      if (isCollapsible) {
        final chevronStyle = copyStyle(theme.labelMedium)
          ..foreground(theme.muted);
        header = GestureDetector(
          onTap: () => onExpandChanged?.call(!expanded!),
          child: Row(
            gap: 1,
            children: [
              Text(expanded! ? 'v' : '>', style: chevronStyle),
              Text(title!, style: tStyle),
            ],
          ),
        );
      } else {
        header = Text(title!, style: tStyle);
      }

      if (isCollapsible && !expanded!) {
        content = header;
      } else {
        content = Column(gap: 1, children: [header, child]);
      }
    } else {
      content = child;
    }

    // Wrap content with padding and optional background
    Widget body = Padding(padding: pad, child: content);
    if (bg != null) {
      body = Frame(background: bg, child: body);
    }
    if (fg != theme.onSurface) {
      body = Frame(foreground: fg, child: body);
    }

    // Compose accent + body
    final children = side == AccentSide.left
        ? [accent, Expanded(child: body)]
        : [Expanded(child: body), accent];

    return Row(children: children);
  }
}
