/// Console tag parser for Symfony/Laravel-style tagged text.
///
/// Parses text containing console tags and renders it with ANSI styles.
/// Tags can specify foreground color, background color, text options, and hyperlinks.
///
/// ## Syntax
///
/// ### Named Styles
/// ```dart
/// '<info>Information message</info>'
/// '<comment>A comment</comment>'
/// '<question>A question?</question>'
/// '<error>An error occurred</error>'
/// ```
///
/// ### Inline Styles
/// ```dart
/// '<fg=red>Red text</>'
/// '<bg=blue>Blue background</>'
/// '<options=bold,underline>Bold and underlined</>'
/// '<fg=green;bg=black;options=bold>Combined styles</>'
/// '<href=https://example.com>Clickable link</>'
/// '<fg=#ff5500>Hex color</>'
/// '<fg=196>ANSI 256 color</>'
/// ```
///
/// ### Nesting
/// ```dart
/// '<fg=green>Green <options=bold>bold green</> still green</>'
/// '<info>Info with <fg=yellow>yellow</> text</info>'
/// ```
///
/// ### Escaping
/// Use `\\<` to output a literal `<` character:
/// ```dart
/// 'Use \\<info> for information'  // Output: Use <info> for information
/// ```
///
/// ## Usage
///
/// ```dart
/// final parser = ConsoleTagParser();
/// final output = parser.render('<info>Hello</info> <fg=red>World</>');
/// print(output);
/// ```
///
/// ## Custom Named Styles
///
/// ```dart
/// final parser = ConsoleTagParser()
///   ..registerStyle('success', Style().foreground(Colors.green).bold())
///   ..registerStyle('warning', Style().foreground(Colors.yellow));
///
/// print(parser.render('<success>Done!</success>'));
/// ```
library;

import 'color.dart';
import 'style.dart';
import 'style_model.dart';

/// A parsed segment of tagged text.
sealed class TagSegment {
  const TagSegment();
}

/// Plain text segment (no tags).
class TextSegment extends TagSegment {
  const TextSegment(this.text);
  final String text;

  @override
  String toString() => 'TextSegment("$text")';
}

/// A styled segment containing child segments.
class StyledSegment extends TagSegment {
  const StyledSegment({
    required this.children,
    this.foreground,
    this.background,
    this.options = const [],
    this.href,
    this.namedStyle,
  });

  final List<TagSegment> children;
  final String? foreground;
  final String? background;
  final List<String> options;
  final String? href;
  final String? namedStyle;

  @override
  String toString() =>
      'StyledSegment(fg: $foreground, bg: $background, opts: $options, href: $href, name: $namedStyle, children: $children)';
}

/// Token types for the lexer.
enum _TokenType {
  text,
  openTag, // <...>
  closeTag, // </...> or </>
  escape, // \<
}

/// A lexer token.
class _Token {
  const _Token(this.type, this.value);
  final _TokenType type;
  final String value;

  @override
  String toString() => '_Token($type, "$value")';
}

/// Parser for console-style tags.
///
/// Converts tagged text into a tree of [TagSegment]s, which can then
/// be rendered to ANSI-styled output.
class ConsoleTagParser {
  /// Creates a new console tag parser with default named styles.
  ConsoleTagParser({
    ColorProfile colorProfile = ColorProfile.trueColor,
    bool hasDarkBackground = true,
  }) : _colorProfile = colorProfile,
       _hasDarkBackground = hasDarkBackground {
    // Register default Symfony-style named styles
    _namedStyles['info'] = Style().foreground(Colors.green);
    _namedStyles['comment'] = Style().foreground(Colors.yellow);
    _namedStyles['question'] = Style()
        .foreground(Colors.black)
        .background(Colors.cyan);
    _namedStyles['error'] = Style()
        .foreground(Colors.white)
        .background(Colors.red);

    // Additional useful named styles
    _namedStyles['success'] = Style().foreground(Colors.green);
    _namedStyles['warning'] = Style().foreground(Colors.yellow);
    _namedStyles['danger'] = Style().foreground(Colors.red);
    _namedStyles['muted'] = Style().foreground(Colors.gray);
    _namedStyles['bold'] = Style().bold();
    _namedStyles['dim'] = Style().faint();
    _namedStyles['italic'] = Style().italic();
    _namedStyles['underline'] = Style().underline();
    _namedStyles['strikethrough'] = Style().strikethrough();
  }

  final ColorProfile _colorProfile;
  final bool _hasDarkBackground;
  final Map<String, Style> _namedStyles = {};

  /// The color profile used for rendering.
  ColorProfile get colorProfile => _colorProfile;

  /// Whether the terminal has a dark background.
  bool get hasDarkBackground => _hasDarkBackground;

  /// Registers a named style that can be used with `<name>...</name>` syntax.
  ///
  /// ```dart
  /// parser.registerStyle('brand', Style().foreground(BasicColor('#ff5500')).bold());
  /// print(parser.render('<brand>My Brand</brand>'));
  /// ```
  void registerStyle(String name, Style style) {
    _namedStyles[name.toLowerCase()] = style;
  }

  /// Removes a named style.
  void unregisterStyle(String name) {
    _namedStyles.remove(name.toLowerCase());
  }

  /// Gets a registered named style, or null if not found.
  Style? getStyle(String name) => _namedStyles[name.toLowerCase()];

  /// Returns all registered style names.
  Iterable<String> get styleNames => _namedStyles.keys;

  /// Parses tagged text and renders it with ANSI escape codes.
  ///
  /// This is the main entry point for converting tagged text to styled output.
  String render(String text) {
    if (!text.contains('<')) return text;

    final segments = parse(text);
    return _renderSegments(segments, Style());
  }

  /// Parses tagged text into a list of segments.
  ///
  /// Use this if you need access to the parsed structure before rendering.
  List<TagSegment> parse(String text) {
    final tokens = _tokenize(text);
    return _parse(tokens);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Lexer
  // ─────────────────────────────────────────────────────────────────────────

  List<_Token> _tokenize(String text) {
    final tokens = <_Token>[];
    final textBuf = StringBuffer();
    var i = 0;

    void flushText() {
      if (textBuf.isNotEmpty) {
        tokens.add(_Token(_TokenType.text, textBuf.toString()));
        textBuf.clear();
      }
    }

    while (i < text.length) {
      final ch = text[i];

      // Handle escape sequence \<
      if (ch == '\\' && i + 1 < text.length && text[i + 1] == '<') {
        flushText();
        tokens.add(const _Token(_TokenType.escape, '<'));
        i += 2;
        continue;
      }

      // Handle tags
      if (ch == '<') {
        final tagEnd = _findTagEnd(text, i);
        if (tagEnd == -1) {
          // Not a valid tag, treat as text
          textBuf.write(ch);
          i++;
          continue;
        }

        final tagContent = text.substring(i + 1, tagEnd);

        // Check if it's a valid console tag
        if (_isValidTag(tagContent)) {
          flushText();

          if (tagContent.startsWith('/')) {
            // Closing tag
            tokens.add(_Token(_TokenType.closeTag, tagContent.substring(1)));
          } else {
            // Opening tag
            tokens.add(_Token(_TokenType.openTag, tagContent));
          }
          i = tagEnd + 1;
          continue;
        }

        // Not a console tag, treat as text
        textBuf.write(ch);
        i++;
        continue;
      }

      textBuf.write(ch);
      i++;
    }

    flushText();
    return tokens;
  }

  /// Finds the closing `>` for a tag starting at position [start].
  /// Returns -1 if not found.
  int _findTagEnd(String text, int start) {
    String? quote;
    for (var i = start + 1; i < text.length; i++) {
      final ch = text[i];
      if (quote != null) {
        if (ch == quote && (i == start + 1 || text[i - 1] != '\\')) {
          quote = null;
        }
        if (ch == '\n') return -1;
        continue;
      }

      if ((ch == '"' || ch == '\'') &&
          (i == start + 1 || text[i - 1] != '\\')) {
        quote = ch;
        continue;
      }

      if (ch == '>') return i;
      // Abort on newline - tags shouldn't span lines
      if (ch == '\n') return -1;
    }
    return -1;
  }

  /// Checks if the tag content represents a valid console tag.
  bool _isValidTag(String content) {
    if (content.isEmpty) return false;

    // Closing tag: / or /name
    if (content == '/') return true;
    if (content.startsWith('/')) {
      final name = content.substring(1).toLowerCase();
      // Valid if it's a named style or looks like an inline style closer
      return _namedStyles.containsKey(name) || _looksLikeInlineTag(name);
    }

    // Check for inline style attributes
    final lower = content.toLowerCase();
    if (lower.contains('fg=') ||
        lower.contains('bg=') ||
        lower.contains('options=') ||
        lower.contains('href=')) {
      return true;
    }

    // Check for named style
    if (_namedStyles.containsKey(lower)) {
      return true;
    }

    return false;
  }

  /// Checks if a tag name looks like it could be an inline style tag.
  bool _looksLikeInlineTag(String name) {
    final lower = name.toLowerCase();
    return lower.contains('fg=') ||
        lower.contains('bg=') ||
        lower.contains('options=') ||
        lower.contains('href=');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Parser
  // ─────────────────────────────────────────────────────────────────────────

  List<TagSegment> _parse(List<_Token> tokens) {
    final segments = <TagSegment>[];
    var i = 0;

    while (i < tokens.length) {
      final token = tokens[i];

      switch (token.type) {
        case _TokenType.text:
          segments.add(TextSegment(token.value));
          i++;

        case _TokenType.escape:
          segments.add(TextSegment(token.value));
          i++;

        case _TokenType.openTag:
          final (segment, newIndex) = _parseStyledSegment(tokens, i);
          segments.add(segment);
          i = newIndex;

        case _TokenType.closeTag:
          // Orphan closing tag - treat as text
          segments.add(TextSegment('</${token.value}>'));
          i++;
      }
    }

    return segments;
  }

  /// Parses a styled segment starting at [index].
  /// Returns the segment and the new index after parsing.
  (TagSegment, int) _parseStyledSegment(List<_Token> tokens, int index) {
    final openToken = tokens[index];
    assert(openToken.type == _TokenType.openTag);

    final tagInfo = _parseTagAttributes(openToken.value);
    final children = <TagSegment>[];
    var i = index + 1;

    // Find matching closing tag
    var depth = 1;
    while (i < tokens.length && depth > 0) {
      final token = tokens[i];

      switch (token.type) {
        case _TokenType.text:
          children.add(TextSegment(token.value));
          i++;

        case _TokenType.escape:
          children.add(TextSegment(token.value));
          i++;

        case _TokenType.openTag:
          // Nested opening tag
          final (child, newIndex) = _parseStyledSegment(tokens, i);
          children.add(child);
          i = newIndex;

        case _TokenType.closeTag:
          // Check if this closes our tag
          if (_isMatchingClose(openToken.value, token.value)) {
            depth--;
            if (depth == 0) {
              i++;
              break;
            }
          }
          // Non-matching close - could be for a parent, stop here
          // and let parent handle it
          depth = 0;
      }
    }

    return (
      StyledSegment(
        children: children,
        foreground: tagInfo.foreground,
        background: tagInfo.background,
        options: tagInfo.options,
        href: tagInfo.href,
        namedStyle: tagInfo.namedStyle,
      ),
      i,
    );
  }

  /// Checks if a close tag matches an open tag.
  bool _isMatchingClose(String openTag, String closeTag) {
    // Empty close </> matches anything
    if (closeTag.isEmpty) return true;

    // For named styles, must match exactly
    final openLower = openTag.toLowerCase();
    final closeLower = closeTag.toLowerCase();

    if (_namedStyles.containsKey(openLower)) {
      return openLower == closeLower;
    }

    // For inline styles, </> or matching tag name
    return closeTag.isEmpty || openLower == closeLower;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Tag Attribute Parsing
  // ─────────────────────────────────────────────────────────────────────────

  _TagInfo _parseTagAttributes(String tag) {
    final lower = tag.toLowerCase();

    // Check for named style first
    if (_namedStyles.containsKey(lower)) {
      return _TagInfo(namedStyle: lower);
    }

    // Parse inline attributes
    String? fg;
    String? bg;
    final options = <String>[];
    String? href;

    for (final part in _splitTagAttributes(tag)) {
      final trimmed = part.trim();
      final eqIndex = trimmed.indexOf('=');
      if (eqIndex == -1) continue;

      final key = trimmed.substring(0, eqIndex).toLowerCase();
      final value = _unquoteAttributeValue(trimmed.substring(eqIndex + 1));

      switch (key) {
        case 'fg':
          fg = value;
        case 'bg':
          bg = value;
        case 'options':
          options.addAll(value.split(',').map((s) => s.trim().toLowerCase()));
        case 'href':
          href = value;
      }
    }

    return _TagInfo(
      foreground: fg,
      background: bg,
      options: options,
      href: href,
    );
  }

  List<String> _splitTagAttributes(String tag) {
    final parts = <String>[];
    final buffer = StringBuffer();
    String? quote;

    for (var i = 0; i < tag.length; i++) {
      final ch = tag[i];
      if (quote != null) {
        buffer.write(ch);
        if (ch == quote && (i == 0 || tag[i - 1] != '\\')) {
          quote = null;
        }
        continue;
      }

      if ((ch == '"' || ch == '\'') && (i == 0 || tag[i - 1] != '\\')) {
        quote = ch;
        buffer.write(ch);
        continue;
      }

      if (ch == ';') {
        parts.add(buffer.toString());
        buffer.clear();
        continue;
      }

      buffer.write(ch);
    }

    parts.add(buffer.toString());
    return parts;
  }

  String _unquoteAttributeValue(String value) {
    final trimmed = value.trim();
    if (trimmed.length < 2) return trimmed;

    final first = trimmed[0];
    final last = trimmed[trimmed.length - 1];
    if ((first == '"' && last == '"') || (first == '\'' && last == '\'')) {
      return trimmed.substring(1, trimmed.length - 1);
    }

    return trimmed;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Rendering
  // ─────────────────────────────────────────────────────────────────────────

  String _renderSegments(List<TagSegment> segments, Style parentStyle) {
    final buf = StringBuffer();

    for (final segment in segments) {
      switch (segment) {
        case TextSegment(:final text):
          // Render text with current style
          if (parentStyle.hasStyling) {
            buf.write(_renderStyledText(text, parentStyle));
          } else {
            buf.write(text);
          }

        case StyledSegment():
          // Build style for this segment, inheriting from parent
          final style = _buildStyle(segment, parentStyle);

          // Render children with the combined style
          buf.write(_renderSegments(segment.children, style));
      }
    }

    return buf.toString();
  }

  /// Renders text with the given style.
  String _renderStyledText(String text, Style style) {
    return style.inline(true).renderWithContext(
      text,
      RenderContext(
        colorProfile: _colorProfile,
        hasDarkBackground: _hasDarkBackground,
      ),
    );
  }

  /// Builds a style from a styled segment, inheriting from parent.
  Style _buildStyle(StyledSegment segment, Style parentStyle) {
    var style = parentStyle.copy();

    // Apply named style if present
    if (segment.namedStyle != null) {
      final namedStyle = _namedStyles[segment.namedStyle];
      if (namedStyle != null) {
        style = _mergeStyles(style, namedStyle);
      }
    }

    // Apply foreground color
    if (segment.foreground != null) {
      final color = _parseColor(segment.foreground!);
      if (color != null) {
        style = style.foreground(color);
      }
    }

    // Apply background color
    if (segment.background != null) {
      final color = _parseColor(segment.background!);
      if (color != null) {
        style = style.background(color);
      }
    }

    // Apply text options
    for (final opt in segment.options) {
      style = _applyOption(style, opt);
    }

    // Apply hyperlink
    if (segment.href != null) {
      style = style.hyperlink(segment.href!);
    }

    return style;
  }

  /// Merges two styles, with [override] taking precedence.
  Style _mergeStyles(Style base, Style override) {
    return base.copy()..inherit(override);
  }

  /// Parses a color string into a Color object.
  Color? _parseColor(String value) {
    final lower = value.toLowerCase();

    // Hex color
    if (lower.startsWith('#')) {
      return BasicColor(lower);
    }

    // Named colors
    const namedColors = <String, Color>{
      'black': AnsiColor(0),
      'red': AnsiColor(1),
      'green': AnsiColor(2),
      'yellow': AnsiColor(3),
      'blue': AnsiColor(4),
      'magenta': AnsiColor(5),
      'cyan': AnsiColor(6),
      'white': AnsiColor(7),
      'gray': AnsiColor(8),
      'grey': AnsiColor(8),
      'bright-black': AnsiColor(8),
      'bright-red': AnsiColor(9),
      'bright-green': AnsiColor(10),
      'bright-yellow': AnsiColor(11),
      'bright-blue': AnsiColor(12),
      'bright-magenta': AnsiColor(13),
      'bright-cyan': AnsiColor(14),
      'bright-white': AnsiColor(15),
      'default': DefaultColor(),
    };

    if (namedColors.containsKey(lower)) {
      return namedColors[lower];
    }

    // ANSI 256 color code
    final code = int.tryParse(lower);
    if (code != null && code >= 0 && code <= 255) {
      return AnsiColor(code);
    }

    return null;
  }

  /// Applies a text option to a style.
  Style _applyOption(Style style, String option) {
    return switch (option) {
      'bold' => style.bold(),
      'dim' || 'faint' => style.faint(),
      'italic' => style.italic(),
      'underline' || 'underscore' => style.underline(),
      'blink' => style.blink(),
      'reverse' || 'inverse' => style.inverse(),
      // Note: 'conceal' not supported by Style class, treated as no-op
      'conceal' || 'hidden' => style,
      'strikethrough' => style.strikethrough(),
      _ => style,
    };
  }
}

/// Internal class for parsed tag attributes.
class _TagInfo {
  const _TagInfo({
    this.foreground,
    this.background,
    this.options = const [],
    this.href,
    this.namedStyle,
  });

  final String? foreground;
  final String? background;
  final List<String> options;
  final String? href;
  final String? namedStyle;
}

/// Extension on Style to check if it has any styling applied.
extension _StyleHasStyling on Style {
  bool get hasStyling =>
      getForeground != null ||
      getBackground != null ||
      isBold ||
      isDim ||
      isItalic ||
      isUnderline ||
      isBlink ||
      isInverse ||
      isStrikethrough ||
      hasHyperlink;
}
