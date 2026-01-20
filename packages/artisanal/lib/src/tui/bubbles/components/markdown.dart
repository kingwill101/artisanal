/// A markdown rendering component for TUI applications.
///
/// Renders markdown content to ANSI-styled terminal output with automatic
/// theme adaptation based on terminal background.
library;

import '../../../markdown/ansi_renderer.dart';
import '../../../markdown/syntax_highlighter.dart';
import '../../../style/border.dart' as style_border;
import '../../../style/color.dart';
import '../../../style/style.dart';
import 'base.dart';

/// A component that renders markdown to ANSI-styled terminal output.
///
/// Automatically adapts syntax highlighting and styles based on terminal
/// background (dark vs light) using [RenderConfig].
///
/// ```dart
/// // Basic usage
/// final md = Markdown('# Hello\n\nThis is **bold** text.');
/// print(md.render());
///
/// // With RenderConfig for theme adaptation
/// final config = RenderConfig(
///   terminalWidth: 100,
///   hasDarkBackground: false, // Light terminal
/// );
/// final md = Markdown(
///   '```dart\nvoid main() {}\n```',
///   renderConfig: config,
/// );
/// print(md.render());
///
/// // With custom options
/// final md = Markdown(
///   markdown,
///   options: MarkdownOptions(
///     syntaxTheme: AdaptiveChromaTheme.draculaGithub,
///     tableBorder: Border.rounded,
///   ),
/// );
/// ```
class Markdown extends DisplayComponent {
  /// Creates a markdown component with the given content.
  ///
  /// The [content] is parsed and rendered to ANSI-styled output.
  /// Use [renderConfig] to configure terminal width and background theme.
  /// Use [options] for additional customization.
  const Markdown(
    this.content, {
    this.renderConfig = const RenderConfig(),
    this.options = const MarkdownOptions(),
  });

  /// The markdown content to render.
  final String content;

  /// Render configuration (terminal width, color profile, background theme).
  final RenderConfig renderConfig;

  /// Additional markdown rendering options.
  final MarkdownOptions options;

  @override
  String render() {
    final rendererOptions = _buildOptions();
    return markdownToAnsi(content, options: rendererOptions);
  }

  /// Builds [AnsiRendererOptions] from [renderConfig] and [options].
  AnsiRendererOptions _buildOptions() {
    return AnsiRendererOptions(
      width: options.width ?? renderConfig.terminalWidth,
      hasDarkBackground:
          options.hasDarkBackground ?? renderConfig.hasDarkBackground,
      h1Style: options.h1Style,
      h2Style: options.h2Style,
      h3Style: options.h3Style,
      h4Style: options.h4Style,
      h5Style: options.h5Style,
      h6Style: options.h6Style,
      emphasisStyle: options.emphasisStyle,
      strongStyle: options.strongStyle,
      codeStyle: options.codeStyle,
      codeBlockStyle: options.codeBlockStyle,
      linkStyle: options.linkStyle,
      blockquoteStyle: options.blockquoteStyle,
      blockquoteBorderColor: options.blockquoteBorderColor,
      strikethroughStyle: options.strikethroughStyle,
      bulletChar: options.bulletChar,
      hyperlinks: options.hyperlinks,
      hrChar: options.hrChar,
      hrWidth: options.hrWidth,
      checkboxChecked: options.checkboxChecked,
      checkboxUnchecked: options.checkboxUnchecked,
      listIndent: options.listIndent,
      codeBlockBorder: options.codeBlockBorder,
      tableBorder: options.tableBorder,
      tableHeaderStyle: options.tableHeaderStyle,
      tableCellStyle: options.tableCellStyle,
      tableBorderStyle: options.tableBorderStyle,
      syntaxHighlighting: options.syntaxHighlighting,
      syntaxTheme: _resolveSyntaxTheme(),
      codeBlockBorderStyle: options.codeBlockBorderStyle,
    );
  }

  /// Resolves the syntax theme based on options and render config.
  ChromaTheme? _resolveSyntaxTheme() {
    // If an explicit theme is provided, use it directly
    if (options.explicitSyntaxTheme != null) {
      return options.explicitSyntaxTheme;
    }

    // If an adaptive theme is provided, resolve based on background
    if (options.syntaxTheme != null) {
      final hasDark =
          options.hasDarkBackground ?? renderConfig.hasDarkBackground;
      return options.syntaxTheme!.resolve(hasDarkBackground: hasDark);
    }

    // Let AnsiRenderer handle adaptive theme selection
    return null;
  }
}

/// Configuration options for the [Markdown] component.
///
/// These options allow customization of markdown rendering beyond what
/// [RenderConfig] provides. For simple cases, the defaults work well.
class MarkdownOptions {
  /// Creates markdown options with the given settings.
  const MarkdownOptions({
    this.width,
    this.hasDarkBackground,
    this.h1Style,
    this.h2Style,
    this.h3Style,
    this.h4Style,
    this.h5Style,
    this.h6Style,
    this.emphasisStyle,
    this.strongStyle,
    this.codeStyle,
    this.codeBlockStyle,
    this.linkStyle,
    this.blockquoteStyle,
    this.blockquoteBorderColor,
    this.strikethroughStyle,
    this.bulletChar = '\u2022',
    this.hyperlinks = true,
    this.hrChar = '\u2500',
    this.hrWidth,
    this.checkboxChecked = '\u2611',
    this.checkboxUnchecked = '\u2610',
    this.listIndent = 2,
    this.codeBlockBorder = true,
    this.tableBorder,
    this.tableHeaderStyle,
    this.tableCellStyle,
    this.tableBorderStyle,
    this.syntaxHighlighting = true,
    this.syntaxTheme,
    this.explicitSyntaxTheme,
    this.codeBlockBorderStyle,
  });

  /// Terminal width override. If null, uses [RenderConfig.terminalWidth].
  final int? width;

  /// Background override. If null, uses [RenderConfig.hasDarkBackground].
  ///
  /// This affects:
  /// - Syntax highlighting theme selection (when using [AdaptiveChromaTheme])
  /// - Adaptive colors in custom styles
  final bool? hasDarkBackground;

  /// Style for H1 headings.
  final Style? h1Style;

  /// Style for H2 headings.
  final Style? h2Style;

  /// Style for H3 headings.
  final Style? h3Style;

  /// Style for H4 headings.
  final Style? h4Style;

  /// Style for H5 headings.
  final Style? h5Style;

  /// Style for H6 headings.
  final Style? h6Style;

  /// Style for emphasized (italic) text.
  final Style? emphasisStyle;

  /// Style for strong (bold) text.
  final Style? strongStyle;

  /// Style for inline code.
  final Style? codeStyle;

  /// Style for code blocks.
  final Style? codeBlockStyle;

  /// Style for links.
  final Style? linkStyle;

  /// Style for blockquote text.
  final Style? blockquoteStyle;

  /// Color for blockquote border.
  final Color? blockquoteBorderColor;

  /// Style for strikethrough text.
  final Style? strikethroughStyle;

  /// Character used for bullet points.
  final String bulletChar;

  /// Whether to use OSC 8 hyperlinks for links.
  final bool hyperlinks;

  /// Character used for horizontal rules.
  final String hrChar;

  /// Width of horizontal rules.
  final int? hrWidth;

  /// Character for checked checkboxes.
  final String checkboxChecked;

  /// Character for unchecked checkboxes.
  final String checkboxUnchecked;

  /// Number of spaces for list indentation per level.
  final int listIndent;

  /// Whether to draw a border around code blocks.
  final bool codeBlockBorder;

  /// Border style for tables.
  final style_border.Border? tableBorder;

  /// Style for table header cells.
  final Style? tableHeaderStyle;

  /// Style for table data cells.
  final Style? tableCellStyle;

  /// Style for table borders.
  final Style? tableBorderStyle;

  /// Whether to apply syntax highlighting to fenced code blocks.
  final bool syntaxHighlighting;

  /// Adaptive syntax theme that selects dark/light based on background.
  ///
  /// Takes precedence over [explicitSyntaxTheme] when both are provided.
  /// Use this for automatic theme adaptation.
  final AdaptiveChromaTheme? syntaxTheme;

  /// Explicit syntax theme (not adaptive).
  ///
  /// Use this to force a specific theme regardless of background.
  final ChromaTheme? explicitSyntaxTheme;

  /// Border style for code blocks.
  final style_border.Border? codeBlockBorderStyle;

  /// Creates a copy with the given fields replaced.
  MarkdownOptions copyWith({
    int? width,
    bool? hasDarkBackground,
    Style? h1Style,
    Style? h2Style,
    Style? h3Style,
    Style? h4Style,
    Style? h5Style,
    Style? h6Style,
    Style? emphasisStyle,
    Style? strongStyle,
    Style? codeStyle,
    Style? codeBlockStyle,
    Style? linkStyle,
    Style? blockquoteStyle,
    Color? blockquoteBorderColor,
    Style? strikethroughStyle,
    String? bulletChar,
    bool? hyperlinks,
    String? hrChar,
    int? hrWidth,
    String? checkboxChecked,
    String? checkboxUnchecked,
    int? listIndent,
    bool? codeBlockBorder,
    style_border.Border? tableBorder,
    Style? tableHeaderStyle,
    Style? tableCellStyle,
    Style? tableBorderStyle,
    bool? syntaxHighlighting,
    AdaptiveChromaTheme? syntaxTheme,
    ChromaTheme? explicitSyntaxTheme,
    style_border.Border? codeBlockBorderStyle,
  }) {
    return MarkdownOptions(
      width: width ?? this.width,
      hasDarkBackground: hasDarkBackground ?? this.hasDarkBackground,
      h1Style: h1Style ?? this.h1Style,
      h2Style: h2Style ?? this.h2Style,
      h3Style: h3Style ?? this.h3Style,
      h4Style: h4Style ?? this.h4Style,
      h5Style: h5Style ?? this.h5Style,
      h6Style: h6Style ?? this.h6Style,
      emphasisStyle: emphasisStyle ?? this.emphasisStyle,
      strongStyle: strongStyle ?? this.strongStyle,
      codeStyle: codeStyle ?? this.codeStyle,
      codeBlockStyle: codeBlockStyle ?? this.codeBlockStyle,
      linkStyle: linkStyle ?? this.linkStyle,
      blockquoteStyle: blockquoteStyle ?? this.blockquoteStyle,
      blockquoteBorderColor:
          blockquoteBorderColor ?? this.blockquoteBorderColor,
      strikethroughStyle: strikethroughStyle ?? this.strikethroughStyle,
      bulletChar: bulletChar ?? this.bulletChar,
      hyperlinks: hyperlinks ?? this.hyperlinks,
      hrChar: hrChar ?? this.hrChar,
      hrWidth: hrWidth ?? this.hrWidth,
      checkboxChecked: checkboxChecked ?? this.checkboxChecked,
      checkboxUnchecked: checkboxUnchecked ?? this.checkboxUnchecked,
      listIndent: listIndent ?? this.listIndent,
      codeBlockBorder: codeBlockBorder ?? this.codeBlockBorder,
      tableBorder: tableBorder ?? this.tableBorder,
      tableHeaderStyle: tableHeaderStyle ?? this.tableHeaderStyle,
      tableCellStyle: tableCellStyle ?? this.tableCellStyle,
      tableBorderStyle: tableBorderStyle ?? this.tableBorderStyle,
      syntaxHighlighting: syntaxHighlighting ?? this.syntaxHighlighting,
      syntaxTheme: syntaxTheme ?? this.syntaxTheme,
      explicitSyntaxTheme: explicitSyntaxTheme ?? this.explicitSyntaxTheme,
      codeBlockBorderStyle: codeBlockBorderStyle ?? this.codeBlockBorderStyle,
    );
  }
}
