/// Markdown-to-ANSI rendering for terminal applications.
///
/// This focused entrypoint exposes the Markdown renderer and its options
/// without loading CLI I/O, charting, or other unrelated Artisanal features.
/// Image downloading and SVG rasterization are available on native platforms;
/// browser builds retain text rendering and image placeholders.
///
/// {@category Markdown}
library;

export 'src/tui/markdown/markdown.dart';
