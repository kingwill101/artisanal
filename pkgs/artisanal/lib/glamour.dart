/// Glamour Markdown Rendering for Dart.
///
/// This library provides a high-fidelity Markdown renderer mirroring the
/// capabilities of Charm's Glamour project.
///
/// Note: This is separate from [markdown.dart] which provides a lighter-weight
/// ANSI renderer.
library glamour;

import 'package:markdown/markdown.dart' as md;
import 'src/glamour/renderer.dart';
import 'src/glamour/theme.dart';

export 'src/glamour/theme.dart';
export 'src/glamour/renderer.dart';

/// Renders [markdown] text using the specified [theme].
///
/// If [width] is provided, text will be wrapped to that width.
/// Defaults to 80 columns.
String renderStyle(
  String markdown, {
  required GlamourTheme theme,
  int width = 80,
}) {
  final document = md.Document(
    extensionSet: md.ExtensionSet.gitHubFlavored,
    encodeHtml: false,
  );

  // Parse markdown
  final nodes = _normalizeBlockquotes(
    document.parseLines(markdown.split('\n')),
  );

  // Render
  final renderer = GlamourRenderer(theme: theme, width: width);
  return renderer.render(nodes);
}

List<md.Node> _normalizeBlockquotes(List<md.Node> nodes) {
  final normalized = <md.Node>[];
  var i = 0;

  while (i < nodes.length) {
    final node = nodes[i];
    if (node is md.Element && node.tag == 'blockquote') {
      final mergedChildren = <md.Node>[];

      while (i < nodes.length &&
          nodes[i] is md.Element &&
          (nodes[i] as md.Element).tag == 'blockquote') {
        final blockquote = nodes[i] as md.Element;
        final children = blockquote.children ?? const <md.Node>[];
        final normalizedChildren = _normalizeBlockquotes(children);
        if (normalizedChildren.isEmpty) {
          mergedChildren.add(md.Element('p', [md.Text('')]));
        } else {
          mergedChildren.addAll(normalizedChildren);
        }
        i++;
      }

      final nestedFixed = _normalizeBlockquoteMarkers(mergedChildren);
      normalized.add(_cloneElement(node, nestedFixed));
      continue;
    }

    if (node is md.Element && node.children != null) {
      normalized.add(
        _cloneElement(node, _normalizeBlockquotes(node.children!)),
      );
    } else {
      normalized.add(node);
    }

    i++;
  }

  return normalized;
}

List<md.Node> _normalizeBlockquoteMarkers(List<md.Node> nodes) {
  final normalized = <md.Node>[];

  for (final node in nodes) {
    if (node is md.Element && node.tag == 'p') {
      final children = node.children ?? const <md.Node>[];
      if (children.isNotEmpty && children.first is md.Text) {
        final first = children.first as md.Text;
        final consumed = _consumeBlockquoteMarkers(first.text);
        if (consumed.depth > 0) {
          final updatedChildren = <md.Node>[
            if (consumed.remainder.isNotEmpty) md.Text(consumed.remainder),
            ...children.skip(1),
          ];
          md.Node wrapped = md.Element('p', updatedChildren);
          for (var i = 0; i < consumed.depth; i++) {
            wrapped = md.Element('blockquote', [wrapped]);
          }
          normalized.add(wrapped);
          continue;
        }
      }
    }

    normalized.add(node);
  }

  return normalized;
}

_BlockquoteMarker _consumeBlockquoteMarkers(String text) {
  var index = 0;
  var depth = 0;

  while (index < text.length && text[index] == ' ') {
    index++;
  }

  while (index < text.length && text[index] == '>') {
    depth++;
    index++;
    if (index < text.length && text[index] == ' ') {
      index++;
    }
  }

  return _BlockquoteMarker(depth: depth, remainder: text.substring(index));
}

class _BlockquoteMarker {
  const _BlockquoteMarker({required this.depth, required this.remainder});

  final int depth;
  final String remainder;
}

md.Element _cloneElement(md.Element element, List<md.Node>? children) {
  final cloned = children == null
      ? md.Element.empty(element.tag)
      : md.Element(element.tag, children);
  cloned.attributes.addAll(element.attributes);
  cloned.generatedId = element.generatedId;
  cloned.footnoteLabel = element.footnoteLabel;
  return cloned;
}
