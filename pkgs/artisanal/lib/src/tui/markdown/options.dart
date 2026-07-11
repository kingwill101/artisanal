import '../../style/border.dart' as style_border;
import '../../style/color.dart';
import '../../style/style.dart';
import 'syntax_highlighter.dart' show ChromaTheme;
import 'styles.dart' show MarkdownElementStyle;

// ─────────────────────────────────────────────────────────────────────────────
// Renderer Options
// ─────────────────────────────────────────────────────────────────────────────

/// Configuration options for ANSI markdown rendering.
///
/// Provides customizable styles for different markdown elements and
/// various rendering options like terminal width and hyperlink support.
///
/// Each element can be styled with artisanal [Style] objects. For more
/// advanced styling (prefix/suffix/indent/margin), use [MarkdownElementStyle]
/// via [AnsiRendererOptions.fromElementStyles].
class AnsiRendererOptions {
  /// Creates renderer options with legacy [Style] fields.
  ///
  /// This is the original API that uses [Style] objects directly.
  /// For the new [MarkdownElementStyle]-based API, use
  /// [AnsiRendererOptions.fromElementStyles].
  /// Creates renderer options with legacy [Style] fields.
  ///
  /// This is the original API that uses [Style] objects directly.
  /// For the new [MarkdownElementStyle]-based API, use
  /// [AnsiRendererOptions.fromElementStyles].
  const AnsiRendererOptions({
    this.width,
    this.hasDarkBackground = true,
    this.textStyle,

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
    this.checkboxChecked = '[x]',
    this.checkboxUnchecked = '[ ]',
    this.listIndent = 2,
    this.codeBlockBorder = true,
    this.tableBorder,
    this.tableHeaderStyle,
    this.tableCellStyle,
    this.tableBorderStyle,
    this.syntaxHighlighting = true,
    this.maxSyntaxHighlightCodeUnits = 8000,
    this.syntaxTheme,
    this.codeBlockBorderStyle,
  });

  /// Creates options from [MarkdownElementStyle]s, resolving each to [Style].
  ///
  /// This is the preferred way to create options with fine-grained control
  /// over structural properties (prefix, suffix, margin, indent, format).
  /// Falls back to legacy [Style]-based fields for custom styles not
  /// covered by the element style API.
  factory AnsiRendererOptions.fromElementStyles({
    int? width,
    bool hasDarkBackground = true,
    MarkdownElementStyle? textStyle,
    MarkdownElementStyle? h1Style,
    MarkdownElementStyle? h2Style,
    MarkdownElementStyle? h3Style,
    MarkdownElementStyle? h4Style,
    MarkdownElementStyle? h5Style,
    MarkdownElementStyle? h6Style,
    MarkdownElementStyle? emphasisStyle,
    MarkdownElementStyle? strongStyle,
    MarkdownElementStyle? codeStyle,
    MarkdownElementStyle? codeBlockStyle,
    MarkdownElementStyle? linkStyle,
    MarkdownElementStyle? blockquoteStyle,
    Color? blockquoteBorderColor,
    MarkdownElementStyle? strikethroughStyle,
    String bulletChar = '•',
    bool hyperlinks = true,
    String hrChar = '─',
    int? hrWidth,
    String checkboxChecked = '[x]',
    String checkboxUnchecked = '[ ]',
    int listIndent = 2,
    bool codeBlockBorder = true,
    style_border.Border? tableBorder,
    MarkdownElementStyle? tableHeaderStyle,
    MarkdownElementStyle? tableCellStyle,
    MarkdownElementStyle? tableBorderStyle,
    bool syntaxHighlighting = true,
    int? maxSyntaxHighlightCodeUnits,
    ChromaTheme? syntaxTheme,
    style_border.Border? codeBlockBorderStyle,
  }) {
    return AnsiRendererOptions(
      width: width,
      hasDarkBackground: hasDarkBackground,
      textStyle: textStyle?.resolveStyle(),
      h1Style: h1Style?.resolveStyle(),
      h2Style: h2Style?.resolveStyle(),
      h3Style: h3Style?.resolveStyle(),
      h4Style: h4Style?.resolveStyle(),
      h5Style: h5Style?.resolveStyle(),
      h6Style: h6Style?.resolveStyle(),
      emphasisStyle: emphasisStyle?.resolveStyle(),
      strongStyle: strongStyle?.resolveStyle(),
      codeStyle: codeStyle?.resolveStyle(),
      codeBlockStyle: codeBlockStyle?.resolveStyle(),
      linkStyle: linkStyle?.resolveStyle(),
      blockquoteStyle: blockquoteStyle?.resolveStyle(),
      blockquoteBorderColor: blockquoteBorderColor,
      strikethroughStyle: strikethroughStyle?.resolveStyle(),
      bulletChar: bulletChar,
      hyperlinks: hyperlinks,
      hrChar: hrChar,
      hrWidth: hrWidth,
      checkboxChecked: checkboxChecked,
      checkboxUnchecked: checkboxUnchecked,
      listIndent: listIndent,
      codeBlockBorder: codeBlockBorder,
      tableBorder: tableBorder,
      tableHeaderStyle: tableHeaderStyle?.resolveStyle(),
      tableCellStyle: tableCellStyle?.resolveStyle(),
      tableBorderStyle: tableBorderStyle?.resolveStyle(),
      syntaxHighlighting: syntaxHighlighting,
      maxSyntaxHighlightCodeUnits: maxSyntaxHighlightCodeUnits,
      syntaxTheme: syntaxTheme,
      codeBlockBorderStyle: codeBlockBorderStyle,
    );
  }

  /// Terminal width for text wrapping. If null, no wrapping is applied.
  final int? width;

  /// Whether the terminal has a dark background.
  final bool hasDarkBackground;

  /// Body text style (paragraphs, regular text).
  final Style? textStyle;

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

  /// Style for blockquotes.
  final Style? blockquoteStyle;

  /// Color for blockquote border.
  final Color? blockquoteBorderColor;

  /// Style for strikethrough.
  final Style? strikethroughStyle;

  /// Character used for unordered list bullets.
  final String bulletChar;

  /// Whether to render hyperlinks (OSC 8) for markdown links.
  final bool hyperlinks;

  /// Character used for horizontal rules.
  final String hrChar;

  /// Width of horizontal rules. Defaults to [width] if null.
  final int? hrWidth;

  /// Display string for checked checkboxes.
  final String checkboxChecked;

  /// Display string for unchecked checkboxes.
  final String checkboxUnchecked;

  /// Indentation width for nested lists.
  final int listIndent;

  /// Whether to draw a border around code blocks.
  final bool codeBlockBorder;

  /// Border style for tables.
  final style_border.Border? tableBorder;

  /// Style for table headers.
  final Style? tableHeaderStyle;

  /// Style for table cells.
  final Style? tableCellStyle;

  /// Style for table borders.
  final Style? tableBorderStyle;

  /// Whether to enable syntax highlighting for code blocks.
  final bool syntaxHighlighting;

  /// Maximum code units to syntax-highlight.
  final int? maxSyntaxHighlightCodeUnits;

  /// Syntax highlighting theme.
  final ChromaTheme? syntaxTheme;

  /// Border style for code blocks.
  final style_border.Border? codeBlockBorderStyle;

  /// Creates a copy with the given fields replaced.
  AnsiRendererOptions copyWith({
    int? width,
    bool? hasDarkBackground,
    Style? textStyle,
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
    int? maxSyntaxHighlightCodeUnits,
    ChromaTheme? syntaxTheme,
    style_border.Border? codeBlockBorderStyle,
  }) {
    return AnsiRendererOptions(
      width: width ?? this.width,
      hasDarkBackground: hasDarkBackground ?? this.hasDarkBackground,
      textStyle: textStyle ?? this.textStyle,
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
      blockquoteBorderColor: blockquoteBorderColor ?? this.blockquoteBorderColor,
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
      maxSyntaxHighlightCodeUnits:
          maxSyntaxHighlightCodeUnits ?? this.maxSyntaxHighlightCodeUnits,
      syntaxTheme: syntaxTheme ?? this.syntaxTheme,
      codeBlockBorderStyle: codeBlockBorderStyle ?? this.codeBlockBorderStyle,
    );
  }
}
