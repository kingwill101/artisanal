
import 'package:artisanal/widgets.dart';

import 'package:artisanal/style.dart' show Color, Border, Style, Colors;


/// A small widget that displays a keyboard shortcut key and its label.
///
/// Commonly used in status bars and help text to show available actions.
///
/// ```dart
/// KeyHint(keyLabel: 'esc', description: 'interrupt')
/// KeyHint(keyLabel: 'ctrl+p', description: 'commands')
/// ```
class KeyHint extends StatelessWidget {
  KeyHint({
    required this.keyLabel,
    required this.description,
    this.keyBackground,
    this.keyForeground,
    this.descriptionForeground,
    this.keyStyle,
    this.descriptionStyle,
    this.gap = 1,
    super.key,
  });

  /// The key combination text (e.g., "esc", "ctrl+p", "tab").
  final String keyLabel;

  /// Description of the action (e.g., "interrupt", "commands").
  final String description;

  /// Background color for the key badge.
  /// Defaults to [StatusBarThemeData.keyBackground] or [Theme.muted].
  final Color? keyBackground;

  /// Foreground color for the key badge text.
  /// Defaults to [StatusBarThemeData.keyForeground] or [Theme.onSurface].
  final Color? keyForeground;

  /// Foreground color for the description text.
  /// Defaults to [Theme.muted].
  final Color? descriptionForeground;

  /// Style override for the key badge text.
  final Style? keyStyle;

  /// Style override for the description text.
  final Style? descriptionStyle;

  /// Gap between the key badge and description (default: 1).
  final int gap;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final sbTheme = theme.statusBarTheme;

    final kBg = keyBackground ?? sbTheme?.keyBackground ?? theme.muted;
    final kFg = keyForeground ?? sbTheme?.keyForeground ?? theme.onSurface;
    final dFg = descriptionForeground ?? theme.muted;

    final kStyle = copyStyle(keyStyle ?? sbTheme?.keyStyle ?? theme.labelSmall)
      ..foreground(kFg);
    final dStyle = copyStyle(
      descriptionStyle ?? sbTheme?.labelStyle ?? theme.bodySmall,
    )..foreground(dFg);

    return Row(
      gap: gap,
      children: [
        Frame(
          padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 0),
          background: kBg,
          child: Text(keyLabel, style: kStyle),
        ),
        Text(description, style: dStyle),
      ],
    );
  }
}
