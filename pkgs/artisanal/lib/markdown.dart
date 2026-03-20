/// Markdown to ANSI terminal rendering.
///
/// This library provides utilities to convert markdown text to ANSI-styled
/// terminal output using artisanal's style system.
///
/// ## Usage
///
/// ```dart
/// import 'package:artisanal/markdown.dart';
///
/// final styled = markdownToAnsi('''
/// # Hello World
///
/// This is **bold** and *italic* text.
///
/// - Item 1
/// - Item 2
///
/// > A blockquote
///
/// ```dart
/// void main() {
///   print('Hello!');
/// }
/// ```
/// ''');
///
/// print(styled);
/// ```
///
/// ## Customization
///
/// You can customize the rendering with [AnsiRendererOptions]:
///
/// ```dart
/// final options = AnsiRendererOptions(
///   h1Style: Style().bold().foreground(Colors.magenta),
///   bulletChar: '-',
///   hyperlinks: true,
/// );
///
/// print(markdownToAnsi(markdown, options: options));
/// ```
///
/// ## Adaptive Themes
///
/// The renderer supports automatic theme selection based on terminal background:
///
/// ```dart
/// final options = AnsiRendererOptions(
///   hasDarkBackground: terminalTheme.hasDarkBackground ?? true,
/// );
/// ```
///
/// For syntax highlighting, you can use [AdaptiveChromaTheme]:
///
/// ```dart
/// final highlighter = SyntaxHighlighter.adaptive(
///   adaptiveTheme: AdaptiveChromaTheme.draculaGithub,
///   hasDarkBackground: terminalTheme.hasDarkBackground ?? true,
/// );
/// ```
library;

export 'src/tui/markdown/ansi_renderer.dart'
    show AnsiRenderer, AnsiRendererOptions, markdownToAnsi;
export 'src/tui/markdown/syntax_highlighter.dart'
    show
        AdaptiveChromaTheme,
        ChromaTheme,
        codeSyntaxDecorationPrefix,
        codeSyntaxDecorationStyleKey,
        SyntaxHighlightSpan,
        SyntaxHighlighter,
        highlightCodeString;
