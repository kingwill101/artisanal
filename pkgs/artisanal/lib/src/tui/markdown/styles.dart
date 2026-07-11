import '../../style/color.dart';
import '../../style/style.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Markdown Element Style
// ─────────────────────────────────────────────────────────────────────────────

/// Fine-grained style for a markdown element.
///
/// Combines artisanal's [Style] with structural properties
/// (prefix, suffix, margins, indent) for full control over rendering.
/// Mirrors the capabilities of Glamour's `StylePrimitive`/`StyleBlock`.
///
/// This is the foundation for the unified markdown theming system.
/// Eventually all [AnsiRendererOptions] style fields will accept this type.
class MarkdownElementStyle {
  const MarkdownElementStyle({
    this.style,
    this.blockPrefix,
    this.blockSuffix,
    this.prefix,
    this.suffix,
    this.margin,
    this.indent,
    this.indentToken,
    this.format,
    this.bold,
    this.italic,
    this.underline,
    this.strikethrough,
    this.dim,
    this.blink,
    this.inverse,
    this.foreground,
    this.background,
  });

  /// Base artisanal [Style] applied to content.
  final Style? style;

  /// Text prepended before the element on its own line.
  final String? blockPrefix;

  /// Text appended after the element on its own line.
  final String? blockSuffix;

  /// Text prepended directly before the content (inline).
  final String? prefix;

  /// Text appended directly after the content (inline).
  final String? suffix;

  /// Number of blank lines before/after the block.
  final int? margin;

  /// Number of characters to indent.
  final int? indent;

  /// Character(s) used for the indent marker (e.g., `│ ` for blockquotes).
  final String? indentToken;

  /// Custom format string (e.g., `Image: {{.text}} →`).
  final String? format;

  // ── Convenience style flags ───────────────────────────────────────────
  final bool? bold;
  final bool? italic;
  final bool? underline;
  final bool? strikethrough;
  final bool? dim;
  final bool? blink;
  final bool? inverse;
  final Color? foreground;
  final Color? background;

  /// Resolves the effective [Style] by merging [style] with convenience flags.
  Style resolveStyle() {
    var s = style ?? Style();
    if (bold == true) s = s.bold();
    if (italic == true) s = s.italic();
    if (underline == true) s = s.underline();
    if (strikethrough == true) s = s.strikethrough();
    if (dim == true) s = s.dim();
    if (blink == true) s = s.blink();
    if (inverse == true) s = s.inverse();
    if (foreground != null) s = s.foreground(foreground!);
    if (background != null) s = s.background(background!);
    return s;
  }

  /// Creates a copy with the given fields replaced.
  MarkdownElementStyle copyWith({
    Style? style,
    String? blockPrefix,
    String? blockSuffix,
    String? prefix,
    String? suffix,
    int? margin,
    int? indent,
    String? indentToken,
    String? format,
    bool? bold,
    bool? italic,
    bool? underline,
    bool? strikethrough,
    bool? dim,
    bool? blink,
    bool? inverse,
    Color? foreground,
    Color? background,
  }) {
    return MarkdownElementStyle(
      style: style ?? this.style,
      blockPrefix: blockPrefix ?? this.blockPrefix,
      blockSuffix: blockSuffix ?? this.blockSuffix,
      prefix: prefix ?? this.prefix,
      suffix: suffix ?? this.suffix,
      margin: margin ?? this.margin,
      indent: indent ?? this.indent,
      indentToken: indentToken ?? this.indentToken,
      format: format ?? this.format,
      bold: bold ?? this.bold,
      italic: italic ?? this.italic,
      underline: underline ?? this.underline,
      strikethrough: strikethrough ?? this.strikethrough,
      dim: dim ?? this.dim,
      blink: blink ?? this.blink,
      inverse: inverse ?? this.inverse,
      foreground: foreground ?? this.foreground,
      background: background ?? this.background,
    );
  }
}
