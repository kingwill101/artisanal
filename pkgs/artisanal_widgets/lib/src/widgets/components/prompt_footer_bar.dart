part of 'components_widgets.dart';

/// A footer bar for inline prompt panels and dialog bottoms.
///
/// Displays a row of [ActionButton]s on the left and [KeyHint] shortcut
/// labels on the right, with a distinct background color to visually
/// separate it from the content area above.
///
/// Uses [DialogThemeData.footerBackground] for the background color,
/// falling back to [Theme.resolvedSurfaceVariant].
///
/// ```dart
/// PromptFooterBar(
///   actions: [
///     ActionButton(label: 'Allow once', isSelected: true, onTap: ...),
///     ActionButton(label: 'Reject', onTap: ...),
///   ],
///   hints: [
///     (key: '⇆', description: 'select'),
///     (key: 'enter', description: 'confirm'),
///   ],
/// )
/// ```
class PromptFooterBar extends StatelessWidget {
  PromptFooterBar({
    this.actions = const [],
    this.hints = const [],
    this.background,
    this.padding,
    super.key,
  });

  /// Action buttons displayed on the left side.
  final List<Widget> actions;

  /// Keyboard hint pairs displayed on the right side.
  /// Each record has a `key` label and a `description`.
  final List<({String key, String description})> hints;

  /// Background color override.
  /// Defaults to [DialogThemeData.footerBackground] or
  /// [Theme.resolvedSurfaceVariant].
  final Color? background;

  /// Padding inside the footer bar.
  /// Defaults to left: 2, right: 3, top: 1, bottom: 1.
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final dTheme = theme.dialogTheme;

    final bg =
        background ?? dTheme?.footerBackground ?? theme.resolvedSurfaceVariant;
    final pad =
        padding ?? const EdgeInsets.only(left: 2, right: 3, top: 1, bottom: 1);

    final hintFg = dTheme?.hintForeground ?? theme.muted;

    return Frame(
      background: bg,
      padding: pad,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: action buttons
          Row(gap: 1, children: actions),
          // Right: keyboard hints
          Row(
            gap: 2,
            children: [
              for (final hint in hints)
                _FooterHint(
                  keyLabel: hint.key,
                  description: hint.description,
                  foreground: hintFg,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A compact inline keyboard hint for use in [PromptFooterBar].
///
/// Unlike [KeyHint], this renders both the key and description in the same
/// muted color without a background badge — matching OpenCode's footer style.
class _FooterHint extends StatelessWidget {
  _FooterHint({
    required this.keyLabel,
    required this.description,
    this.foreground,
  });

  final String keyLabel;
  final String description;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final fg = foreground ?? theme.muted;

    final keyStyle = _copyStyle(theme.labelSmall)..foreground(fg);
    final descStyle = _copyStyle(theme.bodySmall)..foreground(fg);

    return Row(
      gap: 1,
      children: [
        Text(keyLabel, style: keyStyle),
        Text(description, style: descStyle),
      ],
    );
  }
}
