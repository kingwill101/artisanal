/// Markdown to ANSI terminal rendering.
///
/// This library provides utilities to convert markdown text to ANSI-styled
/// terminal output.
///
/// ```dart
/// import 'package:artisanal/artisanal.dart';
///
/// final styled = markdownToAnsi('''
/// # Hello World
///
/// This is **bold** and *italic* text.
/// ''');
///
/// print(styled);
/// ```
library;

export 'ansi_renderer.dart';
export 'fence_language_resolver.dart' show FenceLanguageResolver;
export 'syntax_highlighter.dart'
    show
        AdaptiveChromaTheme,
        ChromaTheme,
        SyntaxHighlighter,
        highlightCodeString;
