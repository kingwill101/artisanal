import 'package:artisanal/src/tui/markdown/backend.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:test/test.dart';

void main() {
  group('markdown backend normalization', () {
    test('does not turn an escaped HTML entity into a blockquote', () {
      final nodes = parseMarkdownNodes('<p>&gt; literal text</p>');

      expect(nodes, hasLength(1));
      expect(nodes.single, isA<md.Element>());
      final paragraph = nodes.single as md.Element;
      expect(paragraph.tag, 'p');
      expect(paragraph.children!.single.textContent, '> literal text');
    });

    test('does not turn an escaped Markdown marker into a blockquote', () {
      final nodes = parseMarkdownNodes(r'\> literal text');

      expect(nodes, hasLength(1));
      expect((nodes.single as md.Element).tag, 'p');
    });

    test('preserves nested Markdown blockquotes', () {
      final nodes = parseMarkdownNodes('> outer\n>\n> > inner');

      final outer = nodes.single as md.Element;
      expect(outer.tag, 'blockquote');
      expect(outer.children, hasLength(2));
      final inner = outer.children!.last as md.Element;
      expect(inner.tag, 'blockquote');
      expect(inner.children!.single.textContent, 'inner');
    });

    test('preserves blockquote elements from raw HTML', () {
      final nodes = parseMarkdownNodes(
        '<blockquote><p><strong>nested</strong> quote</p></blockquote>',
      );

      final quote = nodes.single as md.Element;
      expect(quote.tag, 'blockquote');
      final paragraph = quote.children!.single as md.Element;
      expect(paragraph.children!.first, isA<md.Element>());
      expect(paragraph.textContent, 'nested quote');
    });

    test('does not parse HTML-looking text inside an HTML code block', () {
      final nodes = parseMarkdownNodes(
        '<pre><code>&lt;div&gt;\n&gt; literal</code></pre>',
      );

      final pre = nodes.single as md.Element;
      final code = pre.children!.single as md.Element;
      expect(code.tag, 'code');
      expect(code.children!.single.textContent, '<div>\n> literal');
    });
  });
}
