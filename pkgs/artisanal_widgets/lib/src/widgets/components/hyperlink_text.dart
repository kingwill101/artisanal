part of 'components_widgets.dart';

/// A text widget that renders as a clickable hyperlink using OSC 8 escape
/// sequences in terminals that support them, or as underlined text with
/// the URL shown in parentheses in other terminals.
///
/// ```dart
/// HyperlinkText(
///   url: 'https://example.com',
///   label: 'Example Website',
/// )
/// ```
class HyperlinkText extends StatelessWidget {
  HyperlinkText({
    required this.url,
    this.label,
    this.style,
    this.linkColor,
    super.key,
  });

  /// The URL to link to.
  final String url;

  /// Display text. If null, the URL itself is shown.
  final String? label;

  /// Optional base style. Defaults to theme body with underline.
  final Style? style;

  /// Link color. Defaults to theme info/accent.
  final Color? linkColor;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final color = linkColor ?? theme.resolvedInfo;
    final resolvedStyle = _copyStyle(style ?? theme.bodyMedium)
      ..foreground(color)
      ..underline();

    final displayText = label ?? url;

    // Use OSC 8 hyperlink escape sequence:
    // ESC ] 8 ; params ; uri ST  text  ESC ] 8 ; ; ST
    final osc8Start = '\x1b]8;;$url\x1b\\';
    final osc8End = '\x1b]8;;\x1b\\';
    final styledText = resolvedStyle.render(displayText);

    return Text('$osc8Start$styledText$osc8End');
  }
}
