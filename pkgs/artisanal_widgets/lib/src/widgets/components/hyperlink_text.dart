import 'package:artisanal/widgets.dart';

import 'package:artisanal/style.dart' show Color, Border, Style, Colors;

/// A text widget that renders as a clickable hyperlink using OSC 8 escape
/// sequences in terminals that support them.
///
/// When [showUrl] is true and [label] differs from [url], the URL is shown
/// in parentheses after the label as a fallback for terminals that do not
/// support OSC 8. When [showUrl] is false (the default), only the styled
/// label text is shown.
///
/// ```dart
/// HyperlinkText(
///   url: 'https://example.com',
///   label: 'Example Website',
///   showUrl: true, // renders: "Example Website (https://example.com)"
/// )
/// ```
class HyperlinkText extends StatelessWidget {
  HyperlinkText({
    required this.url,
    this.label,
    this.style,
    this.linkColor,
    this.showUrl = false,
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

  /// Whether to show the URL in parentheses after the label.
  ///
  /// Useful as a fallback for terminals that do not support OSC 8 hyperlinks.
  /// Only has an effect when [label] is non-null and differs from [url].
  final bool showUrl;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final color = linkColor ?? theme.resolvedInfo;
    final resolvedStyle = copyStyle(style ?? theme.bodyMedium)
      ..foreground(color)
      ..underline()
      ..hyperlink(url);

    final displayText = label ?? url;
    final styledLink = resolvedStyle.render(displayText);

    // Show URL in parens when label is different and showUrl is enabled.
    if (showUrl && label != null && label != url) {
      final urlStyle = copyStyle(Style())..foreground(theme.muted);
      return Row(
        gap: 1,
        children: [Text(styledLink), Text('(${urlStyle.render(url)})')],
      );
    }

    return Text(styledLink);
  }
}
