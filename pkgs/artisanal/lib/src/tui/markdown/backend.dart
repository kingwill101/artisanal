import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import 'package:markdown/markdown.dart' as md;

/// Parses Markdown using the shared renderer backend.
///
/// Both the lightweight ANSI renderer and the Glamour renderer should enter
/// through this function so GitHub-flavored Markdown, raw HTML blocks, task
/// inputs, and blockquote normalization behave consistently.
List<md.Node> parseMarkdownNodes(String markdown) {
  final document = md.Document(extensionSet: md.ExtensionSet.gitHubFlavored);
  return normalizeMarkdownNodes(document.parse(markdown));
}

/// Normalizes already-parsed Markdown nodes into the shared renderer AST.
List<md.Node> normalizeMarkdownNodes(List<md.Node> nodes) {
  return _normalizeBlockquotes(_normalizeRawHtml(nodes));
}

List<md.Node> _normalizeRawHtml(List<md.Node> nodes) {
  final normalized = <md.Node>[];
  for (final node in nodes) {
    normalized.addAll(_normalizeRawHtmlNode(node));
  }
  return normalized;
}

List<md.Node> _normalizeRawHtmlNode(md.Node node) {
  if (node is md.Text && _looksLikeRawHtml(node.text)) {
    final htmlNodes = _htmlFragmentToMarkdownNodes(node.text);
    return htmlNodes.isEmpty ? const <md.Node>[] : htmlNodes;
  }

  if (node is md.Element) {
    return [_cloneElement(node, _normalizeRawHtml(node.children ?? []))];
  }

  return [node];
}

bool _looksLikeRawHtml(String text) {
  return RegExp(
    r'<(?:[a-zA-Z][a-zA-Z0-9:-]*(?:\s|>|/>)|/[a-zA-Z][a-zA-Z0-9:-]*\s*>|!--|\?|!)',
    dotAll: true,
  ).hasMatch(text);
}

List<md.Node> _htmlFragmentToMarkdownNodes(String source) {
  final fragment = html_parser.parseFragment(source);
  final nodes = <md.Node>[];
  for (final node in fragment.nodes) {
    nodes.addAll(_htmlNodeToMarkdownNodes(node));
  }
  return nodes;
}

List<md.Node> _htmlNodeToMarkdownNodes(dom.Node node) {
  if (node is dom.Text) {
    final text = node.text
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .replaceAll('\u00a0', ' ')
        .replaceAll(RegExp(r'\s+'), ' ');
    if (text.trim().isEmpty) return const <md.Node>[];
    return [md.Text(text)];
  }

  if (node is! dom.Element) return const <md.Node>[];

  final tag = node.localName?.toLowerCase() ?? node.localName ?? '';
  switch (tag) {
    case 'html':
    case 'body':
    case 'span':
    case 'abbr':
    case 'cite':
    case 'q':
    case 'time':
    case 'var':
      return _htmlChildrenToMarkdownNodes(node);

    case 'p':
      return [_markdownElement('p', _htmlChildrenToMarkdownNodes(node))];

    case 'div':
    case 'section':
    case 'article':
    case 'header':
    case 'footer':
    case 'main':
    case 'nav':
    case 'aside':
    case 'form':
    case 'fieldset':
    case 'figure':
    case 'figcaption':
    case 'caption':
    case 'center':
    case 'address':
    case 'dialog':
    case 'dd':
      final children = _htmlChildrenToMarkdownNodes(node);
      if (_containsBlockHtml(node)) return children;
      return [_markdownElement('p', children)];

    case 'h1':
    case 'h2':
    case 'h3':
    case 'h4':
    case 'h5':
    case 'h6':
      return [_markdownElement(tag, _htmlChildrenToMarkdownNodes(node))];

    case 'strong':
    case 'b':
      return [_markdownElement('strong', _htmlChildrenToMarkdownNodes(node))];

    case 'em':
    case 'i':
      return [_markdownElement('em', _htmlChildrenToMarkdownNodes(node))];

    case 'code':
    case 'kbd':
    case 'samp':
      final element = _markdownElement(
        'code',
        _htmlChildrenToMarkdownNodes(node),
      );
      final className = node.attributes['class'];
      if (className != null) element.attributes['class'] = className;
      return [element];

    case 'del':
    case 's':
    case 'strike':
      return [_markdownElement('del', _htmlChildrenToMarkdownNodes(node))];

    case 'ins':
    case 'u':
      return [_markdownElement('u', _htmlChildrenToMarkdownNodes(node))];

    case 'mark':
      return [_markdownElement('mark', _htmlChildrenToMarkdownNodes(node))];

    case 'sub':
      return [md.Text('_'), ..._htmlChildrenToMarkdownNodes(node)];

    case 'sup':
      return [md.Text('^'), ..._htmlChildrenToMarkdownNodes(node)];

    case 'a':
      final element = _markdownElement('a', _htmlChildrenToMarkdownNodes(node));
      final href = node.attributes['href'];
      if (href != null) element.attributes['href'] = href;
      return [element];

    case 'br':
      return [md.Element.empty('br')];

    case 'hr':
      return [md.Element.empty('hr')];

    case 'img':
      final element = md.Element.empty('img');
      final src = node.attributes['src'];
      final alt = node.attributes['alt'];
      if (src != null) element.attributes['src'] = src;
      if (alt != null) element.attributes['alt'] = alt;
      return [element];

    case 'input':
      final element = md.Element.empty('input');
      for (final entry in node.attributes.entries) {
        element.attributes[entry.key.toString()] = entry.value.toString();
      }
      if (node.attributes.containsKey('checked')) {
        element.attributes['checked'] = 'true';
      }
      return [element];

    case 'ul':
    case 'ol':
      return [_markdownElement(tag, _htmlChildrenToMarkdownNodes(node))];

    case 'li':
      return [_markdownElement('li', _htmlListItemChildren(node))];

    case 'blockquote':
      return [
        _markdownElement('blockquote', _htmlChildrenToMarkdownNodes(node)),
      ];

    case 'pre':
      return [_htmlPreToMarkdownNode(node)];

    case 'table':
    case 'thead':
    case 'tbody':
    case 'tfoot':
    case 'tr':
      return [_markdownElement(tag, _htmlChildrenToMarkdownNodes(node))];

    case 'th':
    case 'td':
      final element = _markdownElement(tag, _htmlChildrenToMarkdownNodes(node));
      final align = node.attributes['align'];
      if (align != null) element.attributes['align'] = align;
      return [element];

    case 'details':
      final element = _markdownElement(
        'details',
        _htmlChildrenToMarkdownNodes(node),
      );
      if (node.attributes.containsKey('open')) {
        element.attributes['open'] = 'true';
      }
      return [element];

    case 'summary':
      return [_markdownElement('summary', _htmlChildrenToMarkdownNodes(node))];

    case 'dl':
      return _htmlChildrenToMarkdownNodes(node);

    case 'dt':
      return [_markdownElement('h6', _htmlChildrenToMarkdownNodes(node))];

    case 'iframe':
      final src = node.attributes['src'];
      return src == null || src.isEmpty
          ? const <md.Node>[]
          : [md.Text('[iframe: $src]')];

    case 'script':
    case 'style':
    case 'head':
    case 'link':
    case 'meta':
    case 'base':
    case 'source':
    case 'track':
    case 'param':
    case 'title':
      return const <md.Node>[];

    default:
      return _htmlChildrenToMarkdownNodes(node);
  }
}

List<md.Node> _htmlChildrenToMarkdownNodes(dom.Element element) {
  final nodes = <md.Node>[];
  for (final child in element.nodes) {
    nodes.addAll(_htmlNodeToMarkdownNodes(child));
  }
  return nodes;
}

List<md.Node> _htmlListItemChildren(dom.Element element) {
  final nodes = <md.Node>[];
  for (final child in element.nodes) {
    if (child is dom.Element && child.localName?.toLowerCase() == 'p') {
      nodes.addAll(_htmlChildrenToMarkdownNodes(child));
      continue;
    }
    nodes.addAll(_htmlNodeToMarkdownNodes(child));
  }
  return nodes;
}

md.Element _htmlPreToMarkdownNode(dom.Element element) {
  final code = element.querySelector('code');
  final text = (code?.text ?? element.text)
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .trimRight();
  final codeElement = md.Element('code', [md.Text(text)]);
  final className = code?.attributes['class'];
  if (className != null) codeElement.attributes['class'] = className;
  return md.Element('pre', [codeElement]);
}

md.Element _markdownElement(String tag, List<md.Node> children) {
  return md.Element(tag, children);
}

bool _containsBlockHtml(dom.Element element) {
  return element.children.any((child) {
    final tag = child.localName?.toLowerCase();
    return tag != null && _blockHtmlTags.contains(tag);
  });
}

const _blockHtmlTags = {
  'address',
  'article',
  'aside',
  'blockquote',
  'caption',
  'center',
  'dd',
  'details',
  'dialog',
  'div',
  'dl',
  'dt',
  'fieldset',
  'figcaption',
  'figure',
  'footer',
  'form',
  'h1',
  'h2',
  'h3',
  'h4',
  'h5',
  'h6',
  'header',
  'hr',
  'li',
  'main',
  'nav',
  'ol',
  'p',
  'pre',
  'section',
  'table',
  'tbody',
  'td',
  'tfoot',
  'th',
  'thead',
  'tr',
  'ul',
};

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

  return _BlockquoteMarker(depth, text.substring(index));
}

md.Element _cloneElement(md.Element original, List<md.Node> children) {
  final clone = original.children == null
      ? md.Element.empty(original.tag)
      : md.Element(original.tag, children);
  clone.attributes.addAll(original.attributes);
  clone.generatedId = original.generatedId;
  clone.footnoteLabel = original.footnoteLabel;
  return clone;
}

class _BlockquoteMarker {
  const _BlockquoteMarker(this.depth, this.remainder);

  final int depth;
  final String remainder;
}
