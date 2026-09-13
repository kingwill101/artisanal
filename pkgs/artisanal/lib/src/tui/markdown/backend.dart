import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import 'package:html_unescape/html_unescape.dart';
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
  return _normalizeRawHtml(nodes);
}

List<md.Node> _normalizeRawHtml(List<md.Node> nodes) {
  bool raw(md.Node node) => node is md.Text && _looksLikeRawHtml(node.text);
  md.Node normalize(md.Node node) {
    // Markdown code/pre nodes are opaque, including any escaped HTML.
    if (node is md.Element && node.tag != 'code' && node.tag != 'pre') {
      return _cloneElement(node, _normalizeRawHtml(node.children ?? []));
    }
    return node;
  }

  if (!nodes.any(raw)) return nodes.map(normalize).toList();

  // Markdown splits HTML blocks at blank lines. Parse the sibling sequence
  // together so the HTML parser, not a second tag scanner, owns nesting.
  // Existing Markdown nodes travel through placeholders without serializing
  // their text, losing metadata, or parsing Markdown syntax a second time.
  final rawText = nodes.where(raw).map((node) => node.textContent).join();
  final reserved = RegExp(r'artisanal-md(?:-x)*', caseSensitive: false)
      .allMatches(HtmlUnescape().convert(rawText))
      .map((match) => match.group(0)!.toLowerCase())
      .toSet();
  var tag = 'artisanal-md';
  while (reserved.contains(tag)) {
    tag = '$tag-x';
  }
  final embedded = <md.Node>[];
  final source = StringBuffer();
  for (final node in nodes) {
    if (raw(node)) {
      source.write(node.textContent);
    } else {
      final index = embedded.length;
      embedded.add(normalize(node));
      // Comments survive table/select insertion modes without foster-parenting
      // or dropping the node, unlike an invented custom HTML element.
      source.write('<!--$tag:$index-->');
    }
  }
  return _HtmlConversion(
    tag,
    embedded,
  )._htmlFragmentToMarkdownNodes(source.toString());
}

bool _looksLikeRawHtml(String text) {
  return RegExp(
    r'<(?:[a-zA-Z][a-zA-Z0-9:-]*(?:\s|>|/>)|/[a-zA-Z][a-zA-Z0-9:-]*\s*>|!--|\?|!)',
    dotAll: true,
  ).hasMatch(text);
}

/// Converts an HTML tree while restoring pre-parsed Markdown placeholder nodes.
final class _HtmlConversion {
  _HtmlConversion(this.placeholderTag, this.embedded)
    : preserved = (Set<md.Node>.identity()..addAll(embedded));

  final String placeholderTag;
  final List<md.Node> embedded;
  final Set<md.Node> preserved;

  List<md.Node> _htmlFragmentToMarkdownNodes(String source) {
    final fragment = html_parser.parseFragment(source);
    final nodes = <md.Node>[];
    for (final node in fragment.nodes) {
      nodes.addAll(_htmlNodeToMarkdownNodes(node));
    }
    return _collapseWhitespace(nodes);
  }

  List<md.Node> _htmlNodeToMarkdownNodes(dom.Node node) {
    if (node is dom.Comment) {
      final restored = _commentNode(node.data);
      return restored == null ? const [] : [restored];
    }
    if (node is dom.Text) {
      final text = _restoreRawText(node.text)
          .replaceAll('\r\n', '\n')
          .replaceAll('\r', '\n')
          .replaceAll('\u00a0', ' ')
          .replaceAll(RegExp(r'\s+'), ' ');
      return text.isEmpty ? const [] : [md.Text(text)];
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
        return _paragraphs(_htmlChildrenToMarkdownNodes(node));

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
        if (children.any(
          (child) => child is md.Element && _blockHtmlTags.contains(child.tag),
        )) {
          return children;
        }
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
        final element = _markdownElement(
          'a',
          _htmlChildrenToMarkdownNodes(node),
        );
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
        final element = _markdownElement(
          tag,
          _htmlChildrenToMarkdownNodes(node),
        );
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
        return [
          _markdownElement('summary', _htmlChildrenToMarkdownNodes(node)),
        ];

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
    return _collapseWhitespace(
      nodes,
      preserveEdges: !_blockHtmlTags.contains(element.localName),
    );
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
    return _collapseWhitespace(nodes);
  }

  md.Element _htmlPreToMarkdownNode(dom.Element element) {
    final code = element.querySelector('code');
    String textOf(dom.Node node) {
      if (node is dom.Text) return _restoreRawText(node.text);
      if (node is dom.Comment) {
        return _commentNode(node.data)?.textContent ?? '';
      }
      return node.nodes.map(textOf).join();
    }

    final text = textOf(
      code ?? element,
    ).replaceAll('\r\n', '\n').replaceAll('\r', '\n').trimRight();
    final codeElement = md.Element('code', [md.Text(text)]);
    final className = code?.attributes['class'];
    if (className != null) codeElement.attributes['class'] = className;
    return md.Element('pre', [codeElement]);
  }

  md.Node? _commentNode(String? text) {
    if (text == null || !text.startsWith('$placeholderTag:')) return null;
    final index = int.tryParse(text.substring(placeholderTag.length + 1));
    return index != null && index >= 0 && index < embedded.length
        ? embedded[index]
        : null;
  }

  // RCDATA/raw-text tokenization turns comments into text. Restore only text
  // content there, never leak marker syntax or introduce styled HTML into code.
  String _restoreRawText(String text) => text.replaceAllMapped(
    RegExp('<!--${RegExp.escape(placeholderTag)}:([0-9]+)-->'),
    (match) =>
        _commentNode('$placeholderTag:${match.group(1)}')?.textContent ?? '',
  );

  bool _block(md.Node node) =>
      node is md.Element && _blockHtmlTags.contains(node.tag);

  List<md.Node> _collapseWhitespace(
    List<md.Node> nodes, {
    bool preserveEdges = false,
  }) {
    final result = <md.Node>[];
    for (var i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      if (node is! md.Text ||
          node.text.trim().isNotEmpty ||
          preserved.contains(node)) {
        result.add(node);
        continue;
      }
      // HTML indentation between blocks is not content; whitespace between
      // inline siblings is. Original Markdown whitespace stays opaque above.
      final previous = result.isEmpty ? null : result.last;
      var next = i + 1;
      while (next < nodes.length &&
          nodes[next] is md.Text &&
          nodes[next].textContent.trim().isEmpty &&
          !preserved.contains(nodes[next])) {
        next++;
      }
      final following = next < nodes.length ? nodes[next] : null;
      if ((previous == null ? preserveEdges : !_block(previous)) &&
          (following == null ? preserveEdges : !_block(following)) &&
          !(previous is md.Text && previous.text.endsWith(' '))) {
        result.add(md.Text(' '));
      }
      i = next - 1;
    }
    return result;
  }

  // A comment standing for a block node cannot trigger HTML's implicit </p>.
  // Split such a paragraph after restoring the real Markdown node types.
  List<md.Node> _paragraphs(List<md.Node> children) {
    if (!children.any(_block)) return [md.Element('p', children)];
    final result = <md.Node>[];
    var inline = <md.Node>[];
    void flush() {
      if (inline.isNotEmpty) {
        result.add(md.Element('p', inline));
        inline = [];
      }
    }

    for (final child in children) {
      if (_block(child)) {
        flush();
        result.add(child);
      } else {
        inline.add(child);
      }
    }
    flush();
    return result;
  }
}

md.Element _markdownElement(String tag, List<md.Node> children) {
  return md.Element(tag, children);
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
  'summary',
  'table',
  'tbody',
  'td',
  'tfoot',
  'th',
  'thead',
  'tr',
  'ul',
};

md.Element _cloneElement(md.Element original, List<md.Node> children) {
  final clone = original.children == null
      ? md.Element.empty(original.tag)
      : md.Element(original.tag, children);
  clone.attributes.addAll(original.attributes);
  clone.generatedId = original.generatedId;
  clone.footnoteLabel = original.footnoteLabel;
  return clone;
}
