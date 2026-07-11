/// Glamour Markdown Rendering for Dart.
///
/// This library provides a high-fidelity Markdown renderer mirroring the
/// capabilities of Charm's Glamour project.
///
/// Note: This is separate from `markdown.dart` which provides a lighter-weight
/// ANSI renderer.
library;

import 'src/glamour/renderer.dart';
import 'src/glamour/theme.dart';
import 'src/tui/markdown/backend.dart' as markdown_backend;

export 'src/glamour/theme.dart';
export 'src/glamour/renderer.dart';

/// Renders [markdown] text using the specified [theme].
///
/// If [width] is provided, text will be wrapped to that width.
/// Defaults to 80 columns.
///
/// This function is **deprecated**. Use [markdownToAnsi] with
/// `GlamourTheme.toAnsiRendererOptions()` instead.
@Deprecated('Use markdownToAnsi with GlamourTheme.toAnsiRendererOptions() instead')
String renderStyle(
  String markdown, {
  required GlamourTheme theme,
  int width = 80,
}) {
  final nodes = markdown_backend.parseMarkdownNodes(markdown);
  final renderer = GlamourRenderer(theme: theme, width: width);
  return renderer.render(nodes);
}
