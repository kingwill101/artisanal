/// Syntax highlighting for code blocks.
///
/// Provides Chroma-style syntax highlighting using the highlight.dart package,
/// with support for custom color themes using artisanal's Style system.
library;

import 'package:highlight/highlight.dart' show highlight, Node;

import '../style/style.dart';
import '../style/color.dart' show BasicColor;

// ─────────────────────────────────────────────────────────────────────────────
// Chroma-Style Color Theme
// ─────────────────────────────────────────────────────────────────────────────

/// Configuration for syntax highlighting colors.
///
/// Inspired by Glamour's Chroma integration, this provides granular control
/// over token colors for syntax highlighting using artisanal's Style system.
///
/// ```dart
/// final theme = ChromaTheme.dark;
///
/// // Or create a custom theme
/// final customTheme = ChromaTheme(
///   keyword: Style().foreground(Colors.blue).bold(),
///   string: Style().foreground(Colors.green),
///   comment: Style().foreground(Colors.gray).italic(),
/// );
/// ```
class ChromaTheme {
  const ChromaTheme({
    this.text,
    this.error,
    this.comment,
    this.commentPreproc,
    this.keyword,
    this.keywordReserved,
    this.keywordNamespace,
    this.keywordType,
    this.operator,
    this.punctuation,
    this.name,
    this.nameBuiltin,
    this.nameTag,
    this.nameAttribute,
    this.nameClass,
    this.nameConstant,
    this.nameDecorator,
    this.nameException,
    this.nameFunction,
    this.nameOther,
    this.literal,
    this.literalNumber,
    this.literalDate,
    this.literalString,
    this.literalStringEscape,
    this.genericDeleted,
    this.genericEmph,
    this.genericInserted,
    this.genericStrong,
    this.genericSubheading,
    this.background,
  });

  final Style? text;
  final Style? error;
  final Style? comment;
  final Style? commentPreproc;
  final Style? keyword;
  final Style? keywordReserved;
  final Style? keywordNamespace;
  final Style? keywordType;
  final Style? operator;
  final Style? punctuation;
  final Style? name;
  final Style? nameBuiltin;
  final Style? nameTag;
  final Style? nameAttribute;
  final Style? nameClass;
  final Style? nameConstant;
  final Style? nameDecorator;
  final Style? nameException;
  final Style? nameFunction;
  final Style? nameOther;
  final Style? literal;
  final Style? literalNumber;
  final Style? literalDate;
  final Style? literalString;
  final Style? literalStringEscape;
  final Style? genericDeleted;
  final Style? genericEmph;
  final Style? genericInserted;
  final Style? genericStrong;
  final Style? genericSubheading;
  final Style? background;

  /// Default dark theme inspired by Glamour/Charm.
  ///
  /// Colors are chosen to work well on dark terminal backgrounds.
  static ChromaTheme get dark => ChromaTheme(
    text: Style().foreground(BasicColor('#C4C4C4')),
    error: Style()
        .foreground(BasicColor('#F1F1F1'))
        .background(BasicColor('#F05B5B')),
    comment: Style().foreground(BasicColor('#676767')),
    commentPreproc: Style().foreground(BasicColor('#FF875F')),
    keyword: Style().foreground(BasicColor('#00AAFF')),
    keywordReserved: Style().foreground(BasicColor('#FF5FD2')),
    keywordNamespace: Style().foreground(BasicColor('#FF5F87')),
    keywordType: Style().foreground(BasicColor('#6E6ED8')),
    operator: Style().foreground(BasicColor('#EF8080')),
    punctuation: Style().foreground(BasicColor('#E8E8A8')),
    name: Style().foreground(BasicColor('#C4C4C4')),
    nameBuiltin: Style().foreground(BasicColor('#FF8EC7')),
    nameTag: Style().foreground(BasicColor('#B083EA')),
    nameAttribute: Style().foreground(BasicColor('#7A7AE6')),
    nameClass: Style().foreground(BasicColor('#F1F1F1')).underline().bold(),
    nameConstant: Style().foreground(BasicColor('#C4C4C4')),
    nameDecorator: Style().foreground(BasicColor('#FFFF87')),
    nameException: Style().foreground(BasicColor('#FF5F87')),
    nameFunction: Style().foreground(BasicColor('#00D787')),
    nameOther: Style().foreground(BasicColor('#C4C4C4')),
    literal: Style().foreground(BasicColor('#C4C4C4')),
    literalNumber: Style().foreground(BasicColor('#6EEFC0')),
    literalDate: Style().foreground(BasicColor('#C4C4C4')),
    literalString: Style().foreground(BasicColor('#C69669')),
    literalStringEscape: Style().foreground(BasicColor('#AFFFD7')),
    genericDeleted: Style().foreground(BasicColor('#FD5B5B')),
    genericEmph: Style().italic(),
    genericInserted: Style().foreground(BasicColor('#00D787')),
    genericStrong: Style().bold(),
    genericSubheading: Style().foreground(BasicColor('#777777')),
    background: Style().background(BasicColor('#373737')),
  );

  /// Light theme for light terminal backgrounds.
  static ChromaTheme get light => ChromaTheme(
    text: Style().foreground(BasicColor('#333333')),
    error: Style()
        .foreground(BasicColor('#FFFFFF'))
        .background(BasicColor('#CC0000')),
    comment: Style().foreground(BasicColor('#888888')),
    commentPreproc: Style().foreground(BasicColor('#CC6600')),
    keyword: Style().foreground(BasicColor('#0066CC')),
    keywordReserved: Style().foreground(BasicColor('#CC0099')),
    keywordNamespace: Style().foreground(BasicColor('#CC3366')),
    keywordType: Style().foreground(BasicColor('#5533CC')),
    operator: Style().foreground(BasicColor('#CC4444')),
    punctuation: Style().foreground(BasicColor('#666600')),
    name: Style().foreground(BasicColor('#333333')),
    nameBuiltin: Style().foreground(BasicColor('#CC6699')),
    nameTag: Style().foreground(BasicColor('#9933CC')),
    nameAttribute: Style().foreground(BasicColor('#5555CC')),
    nameClass: Style().foreground(BasicColor('#000000')).underline().bold(),
    nameConstant: Style().foreground(BasicColor('#333333')),
    nameDecorator: Style().foreground(BasicColor('#999900')),
    nameException: Style().foreground(BasicColor('#CC3366')),
    nameFunction: Style().foreground(BasicColor('#009966')),
    nameOther: Style().foreground(BasicColor('#333333')),
    literal: Style().foreground(BasicColor('#333333')),
    literalNumber: Style().foreground(BasicColor('#009999')),
    literalDate: Style().foreground(BasicColor('#333333')),
    literalString: Style().foreground(BasicColor('#996633')),
    literalStringEscape: Style().foreground(BasicColor('#339966')),
    genericDeleted: Style().foreground(BasicColor('#CC0000')),
    genericEmph: Style().italic(),
    genericInserted: Style().foreground(BasicColor('#009900')),
    genericStrong: Style().bold(),
    genericSubheading: Style().foreground(BasicColor('#666666')),
    background: Style().background(BasicColor('#F5F5F5')),
  );

  /// Monokai-inspired theme.
  static ChromaTheme get monokai => ChromaTheme(
    text: Style().foreground(BasicColor('#F8F8F2')),
    error: Style().foreground(BasicColor('#960050')),
    comment: Style().foreground(BasicColor('#75715E')),
    commentPreproc: Style().foreground(BasicColor('#75715E')),
    keyword: Style().foreground(BasicColor('#F92672')),
    keywordReserved: Style().foreground(BasicColor('#F92672')),
    keywordNamespace: Style().foreground(BasicColor('#F92672')),
    keywordType: Style().foreground(BasicColor('#66D9EF')).italic(),
    operator: Style().foreground(BasicColor('#F92672')),
    punctuation: Style().foreground(BasicColor('#F8F8F2')),
    name: Style().foreground(BasicColor('#F8F8F2')),
    nameBuiltin: Style().foreground(BasicColor('#66D9EF')),
    nameTag: Style().foreground(BasicColor('#F92672')),
    nameAttribute: Style().foreground(BasicColor('#A6E22E')),
    nameClass: Style().foreground(BasicColor('#A6E22E')).bold(),
    nameConstant: Style().foreground(BasicColor('#66D9EF')),
    nameDecorator: Style().foreground(BasicColor('#A6E22E')),
    nameException: Style().foreground(BasicColor('#A6E22E')),
    nameFunction: Style().foreground(BasicColor('#A6E22E')),
    nameOther: Style().foreground(BasicColor('#A6E22E')),
    literal: Style().foreground(BasicColor('#AE81FF')),
    literalNumber: Style().foreground(BasicColor('#AE81FF')),
    literalDate: Style().foreground(BasicColor('#E6DB74')),
    literalString: Style().foreground(BasicColor('#E6DB74')),
    literalStringEscape: Style().foreground(BasicColor('#AE81FF')),
    genericDeleted: Style().foreground(BasicColor('#F92672')),
    genericEmph: Style().italic(),
    genericInserted: Style().foreground(BasicColor('#A6E22E')),
    genericStrong: Style().bold(),
    genericSubheading: Style().foreground(BasicColor('#75715E')),
    background: Style().background(BasicColor('#272822')),
  );

  /// Dracula-inspired theme.
  static ChromaTheme get dracula => ChromaTheme(
    text: Style().foreground(BasicColor('#F8F8F2')),
    error: Style().foreground(BasicColor('#FF5555')),
    comment: Style().foreground(BasicColor('#6272A4')),
    commentPreproc: Style().foreground(BasicColor('#FF79C6')),
    keyword: Style().foreground(BasicColor('#FF79C6')),
    keywordReserved: Style().foreground(BasicColor('#FF79C6')),
    keywordNamespace: Style().foreground(BasicColor('#FF79C6')),
    keywordType: Style().foreground(BasicColor('#8BE9FD')).italic(),
    operator: Style().foreground(BasicColor('#FF79C6')),
    punctuation: Style().foreground(BasicColor('#F8F8F2')),
    name: Style().foreground(BasicColor('#F8F8F2')),
    nameBuiltin: Style().foreground(BasicColor('#8BE9FD')).italic(),
    nameTag: Style().foreground(BasicColor('#FF79C6')),
    nameAttribute: Style().foreground(BasicColor('#50FA7B')),
    nameClass: Style().foreground(BasicColor('#8BE9FD')),
    nameConstant: Style().foreground(BasicColor('#BD93F9')),
    nameDecorator: Style().foreground(BasicColor('#50FA7B')),
    nameException: Style().foreground(BasicColor('#50FA7B')),
    nameFunction: Style().foreground(BasicColor('#50FA7B')),
    nameOther: Style().foreground(BasicColor('#F8F8F2')),
    literal: Style().foreground(BasicColor('#BD93F9')),
    literalNumber: Style().foreground(BasicColor('#BD93F9')),
    literalDate: Style().foreground(BasicColor('#F1FA8C')),
    literalString: Style().foreground(BasicColor('#F1FA8C')),
    literalStringEscape: Style().foreground(BasicColor('#FF79C6')),
    genericDeleted: Style().foreground(BasicColor('#FF5555')),
    genericEmph: Style().italic(),
    genericInserted: Style().foreground(BasicColor('#50FA7B')),
    genericStrong: Style().bold(),
    genericSubheading: Style().foreground(BasicColor('#6272A4')),
    background: Style().background(BasicColor('#282A36')),
  );

  /// GitHub-inspired theme (light).
  static ChromaTheme get github => ChromaTheme(
    text: Style().foreground(BasicColor('#24292e')),
    error: Style().foreground(BasicColor('#cb2431')),
    comment: Style().foreground(BasicColor('#6a737d')),
    commentPreproc: Style().foreground(BasicColor('#6a737d')),
    keyword: Style().foreground(BasicColor('#d73a49')),
    keywordReserved: Style().foreground(BasicColor('#d73a49')),
    keywordNamespace: Style().foreground(BasicColor('#d73a49')),
    keywordType: Style().foreground(BasicColor('#d73a49')),
    operator: Style().foreground(BasicColor('#d73a49')),
    punctuation: Style().foreground(BasicColor('#24292e')),
    name: Style().foreground(BasicColor('#24292e')),
    nameBuiltin: Style().foreground(BasicColor('#005cc5')),
    nameTag: Style().foreground(BasicColor('#22863a')),
    nameAttribute: Style().foreground(BasicColor('#6f42c1')),
    nameClass: Style().foreground(BasicColor('#6f42c1')),
    nameConstant: Style().foreground(BasicColor('#005cc5')),
    nameDecorator: Style().foreground(BasicColor('#6f42c1')),
    nameException: Style().foreground(BasicColor('#005cc5')),
    nameFunction: Style().foreground(BasicColor('#6f42c1')),
    nameOther: Style().foreground(BasicColor('#005cc5')),
    literal: Style().foreground(BasicColor('#005cc5')),
    literalNumber: Style().foreground(BasicColor('#005cc5')),
    literalDate: Style().foreground(BasicColor('#032f62')),
    literalString: Style().foreground(BasicColor('#032f62')),
    literalStringEscape: Style().foreground(BasicColor('#005cc5')),
    genericDeleted: Style()
        .foreground(BasicColor('#cb2431'))
        .background(BasicColor('#ffeef0')),
    genericEmph: Style().italic(),
    genericInserted: Style()
        .foreground(BasicColor('#22863a'))
        .background(BasicColor('#f0fff4')),
    genericStrong: Style().bold(),
    genericSubheading: Style().foreground(BasicColor('#005cc5')),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Adaptive Theme
// ─────────────────────────────────────────────────────────────────────────────

/// An adaptive syntax highlighting theme that selects between light and dark
/// variants based on terminal background.
///
/// Similar to [AdaptiveColor], this allows themes to automatically adapt to
/// the terminal's color scheme.
///
/// ```dart
/// // Create an adaptive theme
/// final theme = AdaptiveChromaTheme(
///   light: ChromaTheme.github,
///   dark: ChromaTheme.dracula,
/// );
///
/// // Use with SyntaxHighlighter
/// final highlighter = SyntaxHighlighter.adaptive(
///   theme: theme,
///   hasDarkBackground: terminalTheme.hasDarkBackground ?? true,
/// );
/// ```
class AdaptiveChromaTheme {
  /// Creates an adaptive theme with light and dark variants.
  const AdaptiveChromaTheme({required this.light, required this.dark});

  /// Theme to use on light terminal backgrounds.
  final ChromaTheme light;

  /// Theme to use on dark terminal backgrounds.
  final ChromaTheme dark;

  /// Selects the appropriate theme based on background.
  ChromaTheme resolve({required bool hasDarkBackground}) {
    return hasDarkBackground ? dark : light;
  }

  /// Default adaptive theme using dark/light presets.
  static AdaptiveChromaTheme get defaultTheme =>
      AdaptiveChromaTheme(light: ChromaTheme.light, dark: ChromaTheme.dark);

  /// Monokai (dark) / GitHub (light) pairing.
  static AdaptiveChromaTheme get monokaiGithub =>
      AdaptiveChromaTheme(light: ChromaTheme.github, dark: ChromaTheme.monokai);

  /// Dracula (dark) / GitHub (light) pairing.
  static AdaptiveChromaTheme get draculaGithub =>
      AdaptiveChromaTheme(light: ChromaTheme.github, dark: ChromaTheme.dracula);
}

// ─────────────────────────────────────────────────────────────────────────────
// Syntax Highlighter
// ─────────────────────────────────────────────────────────────────────────────

/// Syntax highlighter that converts code to ANSI-styled terminal output.
///
/// Uses the highlight.dart package for parsing and artisanal's Style system
/// for rendering.
///
/// ```dart
/// final highlighter = SyntaxHighlighter(theme: ChromaTheme.dark);
/// final highlighted = highlighter.highlight(
///   'void main() { print("Hello"); }',
///   language: 'dart',
/// );
/// print(highlighted);
/// ```
class SyntaxHighlighter {
  /// Creates a syntax highlighter with the given theme.
  SyntaxHighlighter({ChromaTheme? theme}) : theme = theme ?? ChromaTheme.dark;

  /// Creates a syntax highlighter that adapts to terminal background.
  ///
  /// Uses [adaptiveTheme] to select between light and dark themes based on
  /// [hasDarkBackground].
  ///
  /// ```dart
  /// final highlighter = SyntaxHighlighter.adaptive(
  ///   adaptiveTheme: AdaptiveChromaTheme.draculaGithub,
  ///   hasDarkBackground: terminalTheme.hasDarkBackground ?? true,
  /// );
  /// ```
  factory SyntaxHighlighter.adaptive({
    AdaptiveChromaTheme? adaptiveTheme,
    bool hasDarkBackground = true,
  }) {
    final theme = (adaptiveTheme ?? AdaptiveChromaTheme.defaultTheme).resolve(
      hasDarkBackground: hasDarkBackground,
    );
    return SyntaxHighlighter(theme: theme);
  }

  /// The color theme to use for highlighting.
  final ChromaTheme theme;

  /// Highlights code and returns ANSI-styled output.
  ///
  /// If [language] is not specified or not recognized, attempts auto-detection.
  /// Falls back to plain text styling if highlighting fails.
  String highlightCode(String code, {String? language}) {
    // Normalize the language name
    final lang = _normalizeLanguage(language);

    // Try to highlight with the specified language
    if (lang != null && lang.isNotEmpty) {
      try {
        final result = highlight.parse(code, language: lang);
        if (result.nodes != null && result.nodes!.isNotEmpty) {
          return _nodesToAnsi(result.nodes!);
        }
      } catch (e) {
        // Language not recognized, fall through to auto-detection
      }
    }

    // Try auto-detection
    try {
      final result = highlight.parse(code, autoDetection: true);
      if (result.nodes != null &&
          result.nodes!.isNotEmpty &&
          result.language != null &&
          result.language != 'plaintext') {
        return _nodesToAnsi(result.nodes!);
      }
    } catch (e) {
      // Auto-detection failed
    }

    // Default: return with text style
    final textStyle = theme.text;
    if (textStyle != null) {
      return textStyle.inline(true).render(code);
    }
    return code;
  }

  /// Normalizes language name to match highlight.dart's expectations.
  String? _normalizeLanguage(String? language) {
    if (language == null || language.isEmpty) return null;

    final lang = language.toLowerCase().trim();

    // Common aliases
    return switch (lang) {
      'js' => 'javascript',
      'ts' => 'typescript',
      'py' => 'python',
      'rb' => 'ruby',
      'rs' => 'rust',
      'sh' || 'shell' => 'bash',
      'yml' => 'yaml',
      'md' => 'markdown',
      'objc' => 'objectivec',
      'c++' || 'cxx' => 'cpp',
      'c#' => 'csharp',
      'f#' => 'fsharp',
      _ => lang,
    };
  }

  /// Converts highlight.dart nodes to ANSI-styled string.
  String _nodesToAnsi(List<Node> nodes) {
    final buffer = StringBuffer();

    for (final node in nodes) {
      _renderNode(node, buffer);
    }

    return buffer.toString();
  }

  /// Renders a single node to the buffer.
  ///
  /// [parentClass] is passed down from parent nodes so that children
  /// of styled containers (like `keyword` nodes) inherit the parent's style.
  void _renderNode(Node node, StringBuffer buffer, {String? parentClass}) {
    // Determine the effective class - prefer node's own class, then parent's
    final effectiveClass = node.className ?? parentClass;

    if (node.value != null) {
      // Text node - apply styling based on effective class
      final style = _getStyleForClass(effectiveClass);
      if (style != null) {
        buffer.write(style.inline(true).render(node.value!));
      } else {
        buffer.write(node.value);
      }
    } else if (node.children != null) {
      // Container node with children - pass down the effective class
      for (final child in node.children!) {
        _renderNode(child, buffer, parentClass: effectiveClass);
      }
    }
  }

  /// Maps highlight.js class names to our theme styles.
  Style? _getStyleForClass(String? className) {
    if (className == null) return theme.text;

    // Handle compound classes (e.g., 'hljs-keyword hljs-type')
    final classes = className.split(' ');
    for (final cls in classes) {
      final style = _getStyleForSingleClass(cls);
      if (style != null) return style;
    }
    return theme.text;
  }

  /// Maps a single class name to a style.
  Style? _getStyleForSingleClass(String className) {
    return switch (className) {
      // Comments
      'hljs-comment' || 'comment' => theme.comment,
      'hljs-doctag' => theme.comment,
      'hljs-meta' || 'meta' => theme.commentPreproc,

      // Keywords
      'hljs-keyword' || 'keyword' => theme.keyword,
      'hljs-type' || 'type' => theme.keywordType,
      'hljs-selector-tag' => theme.keyword,

      // Literals
      'hljs-string' || 'string' => theme.literalString,
      'hljs-number' || 'number' => theme.literalNumber,
      'hljs-literal' || 'literal' => theme.literal,
      'hljs-regexp' => theme.literalString,

      // Names
      'hljs-title' || 'title' => theme.nameFunction,
      'hljs-title.function_' || 'title function_' => theme.nameFunction,
      'hljs-title.class_' || 'title class_' => theme.nameClass,
      'hljs-function' || 'function' => theme.nameFunction,
      'hljs-class' || 'class' => theme.nameClass,
      'hljs-params' || 'params' => theme.name,
      'hljs-variable' || 'variable' => theme.name,
      'hljs-attr' || 'attr' => theme.nameAttribute,
      'hljs-attribute' || 'attribute' => theme.nameAttribute,
      'hljs-name' || 'name' => theme.nameTag,
      'hljs-tag' || 'tag' => theme.nameTag,
      'hljs-built_in' || 'built_in' => theme.nameBuiltin,
      'hljs-builtin-name' => theme.nameBuiltin,
      'hljs-symbol' || 'symbol' => theme.nameConstant,

      // Operators and punctuation
      'hljs-operator' || 'operator' => theme.operator,
      'hljs-punctuation' || 'punctuation' => theme.punctuation,

      // Template literals
      'hljs-template-variable' => theme.name,
      'hljs-template-tag' => theme.nameTag,
      'hljs-subst' => theme.name,

      // Diff
      'hljs-addition' || 'addition' => theme.genericInserted,
      'hljs-deletion' || 'deletion' => theme.genericDeleted,

      // Emphasis
      'hljs-emphasis' || 'emphasis' => theme.genericEmph,
      'hljs-strong' || 'strong' => theme.genericStrong,

      // Section
      'hljs-section' || 'section' => theme.genericSubheading,

      // Quote
      'hljs-quote' || 'quote' => theme.comment,

      // Selector
      'hljs-selector-class' => theme.nameClass,
      'hljs-selector-id' => theme.nameConstant,
      'hljs-selector-attr' => theme.nameAttribute,
      'hljs-selector-pseudo' => theme.nameBuiltin,

      // Links/references
      'hljs-link' || 'link' => theme.literalString,

      _ => theme.text,
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Convenience Function
// ─────────────────────────────────────────────────────────────────────────────

/// Highlights code and returns ANSI-styled output.
///
/// ```dart
/// final highlighted = highlightCode(
///   'void main() { print("Hello"); }',
///   language: 'dart',
/// );
/// print(highlighted);
/// ```
String highlightCodeString(
  String code, {
  String? language,
  ChromaTheme? theme,
}) {
  return SyntaxHighlighter(
    theme: theme,
  ).highlightCode(code, language: language);
}
