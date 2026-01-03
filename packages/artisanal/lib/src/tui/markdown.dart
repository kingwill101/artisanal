/// Markdown rendering helper backed by `package:markdown`.
///
/// This intentionally renders to ANSI-colored plain text suitable for
/// terminal viewports in the examples. It is not a fully faithful Glamour
/// port, but it follows structure and uses the official Markdown parser for
/// correctness.
library;

import 'package:markdown/markdown.dart' as md;

import '../style/color.dart';
import '../style/style.dart';
import 'bubbles/runeutil.dart';

/// Render Markdown to ANSI-styled text, wrapped to [width].
String renderMarkdown(String markdown, {int width = 80}) {
  final doc = md.Document(
    extensionSet: md.ExtensionSet.gitHubFlavored,
    encodeHtml: false,
  );
  final nodes = doc.parseLines(markdown.replaceAll('\r', '').split('\n'));
  final renderer = _AnsiRenderer(width: width);
  return renderer.render(nodes).trimRight();
}

class _AnsiRenderer {
  _AnsiRenderer({required this.width});

  final int width;

  final _h1 = Style().bold().foreground(const AnsiColor(213));
  final _h2 = Style().bold().foreground(const AnsiColor(105));
  final _strong = Style().bold();
  final _em = Style().italic();
  final _code = Style()
      .foreground(const AnsiColor(180))
      .background(const AnsiColor(236));

  String render(List<md.Node> nodes) {
    final buf = StringBuffer();
    for (final node in nodes) {
      _renderNode(node, buf, 0, listIndex: 1);
    }
    return buf.toString();
  }

  void _renderNode(
    md.Node node,
    StringBuffer buf,
    int indent, {
    int listIndex = 1,
  }) {
    if (node is md.Element) {
      switch (node.tag) {
        case 'h1':
          _renderBlock(_h1.render(_text(node)), buf);
          buf.writeln();
          break;
        case 'h2':
          _renderBlock(_h2.render(_text(node)), buf);
          buf.writeln();
          break;
        case 'p':
          _renderBlock(_wrap(_text(node), indent: indent), buf);
          buf.writeln();
          break;
        case 'blockquote':
          final content = _text(node);
          final wrapped = _wrap(content, indent: indent + 2);
          for (final line in wrapped.split('\n')) {
            buf.writeln('${' ' * indent}> $line');
          }
          buf.writeln();
          break;
        case 'ul':
          for (final child in node.children ?? []) {
            _renderListItem(child, buf, indent, bullet: '•');
          }
          buf.writeln();
          break;
        case 'ol':
          var i = listIndex;
          for (final child in node.children ?? []) {
            _renderListItem(child, buf, indent, bullet: '$i.');
            i += 1;
          }
          buf.writeln();
          break;
        case 'pre':
          final code = node.textContent;
          for (final line in code.split('\n')) {
            buf.writeln('${' ' * indent}$line');
          }
          buf.writeln();
          break;
        case 'code':
          buf.write(_code.render(node.textContent));
          break;
        case 'strong':
          buf.write(_strong.render(_inlineText(node)));
          break;
        case 'em':
          buf.write(_em.render(_inlineText(node)));
          break;
        case 'table':
          // Simple table rendering: rows separated by newlines.
          for (final row in node.children ?? []) {
            if (row is md.Element && row.tag == 'tr') {
              final cells = <String>[];
              for (final cell in row.children ?? []) {
                cells.add(_text(cell).trim());
              }
              buf.writeln(cells.join(' | '));
            }
          }
          buf.writeln();
          break;
        case 'br':
          buf.writeln();
          break;
        default:
          // Fall back to rendering children inline.
          for (final child in node.children ?? []) {
            _renderNode(child, buf, indent, listIndex: listIndex);
          }
      }
      return;
    }

    if (node is md.Text) {
      buf.write(node.text);
    }
  }

  void _renderListItem(
    md.Node node,
    StringBuffer buf,
    int indent, {
    required String bullet,
  }) {
    final content = _text(node);
    final bulletWidth = stringWidth(bullet) + 1;
    final wrapped = _wrap(
      content,
      indent: indent + bulletWidth + 1,
    ).split('\n');
    for (var i = 0; i < wrapped.length; i++) {
      final prefix = i == 0 ? '$bullet ' : ' ' * bulletWidth;
      buf.writeln('${' ' * indent}$prefix${wrapped[i]}');
    }
  }

  void _renderBlock(String text, StringBuffer buf) {
    for (final line in text.split('\n')) {
      buf.writeln(line);
    }
  }

  String _text(md.Node node) {
    final sb = StringBuffer();
    _collectText(node, sb);
    return sb.toString().trimRight();
  }

  String _inlineText(md.Node node) {
    final sb = StringBuffer();
    _collectText(node, sb);
    return sb.toString();
  }

  void _collectText(md.Node node, StringBuffer sb) {
    if (node is md.Text) {
      sb.write(node.text);
      return;
    }
    if (node is md.Element) {
      if (node.tag == 'br') {
        sb.write('\n');
      }
      for (final child in node.children ?? []) {
        _collectText(child, sb);
      }
    }
  }

  String _wrap(String text, {required int indent}) {
    final available = (width - indent).clamp(10, width);
    if (stringWidth(text) <= available) {
      return text.padLeft(indent + text.length);
    }

    final words = text.split(RegExp(r'\\s+'));
    final lines = <String>[];
    var current = StringBuffer();
    var currentWidth = 0;

    void push() {
      if (current.isNotEmpty) {
        lines.add(current.toString());
        current = StringBuffer();
        currentWidth = 0;
      }
    }

    for (final word in words) {
      final w = stringWidth(word);
      if (currentWidth == 0) {
        current.write(word);
        currentWidth = w;
        continue;
      }
      if (currentWidth + 1 + w > available) {
        push();
        current.write(word);
        currentWidth = w;
      } else {
        current.write(' $word');
        currentWidth += 1 + w;
      }
    }
    push();

    return lines.map((l) => '${' ' * indent}$l').join('\n').trimRight();
  }
}
