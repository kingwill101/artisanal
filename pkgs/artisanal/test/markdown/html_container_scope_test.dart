import 'package:markdown/markdown.dart' as md;
import 'package:test/test.dart';

import 'package:artisanal/src/tui/markdown/ansi_renderer.dart';
import 'package:artisanal/src/tui/markdown/backend.dart';
import 'package:artisanal/src/tui/markdown/renderer.dart';
import 'package:artisanal/style.dart';

void main() {
  group('raw HTML container scope', () {
    test('keeps block markdown inside a blockquote across blank lines', () {
      final nodes = parseMarkdownNodes('''
<blockquote>

- item

</blockquote>

After
''');

      final quote =
          nodes.singleWhere(
                (node) => node is md.Element && node.tag == 'blockquote',
              )
              as md.Element;
      expect(quote.children, hasLength(1));
      expect((quote.children!.single as md.Element).tag, equals('ul'));
      expect(
        nodes.whereType<md.Element>().map((node) => node.tag),
        contains('p'),
      );
    });

    test('keeps nested details bodies scoped and preserves a sibling', () {
      final nodes = parseMarkdownNodes('''
<details open>
<summary>Outer</summary>

<details>
<summary>Inner</summary>

Inner body

</details>

Outer body

</details>

After
''');

      final details = nodes.whereType<md.Element>().where(
        (node) => node.tag == 'details',
      );
      expect(details, hasLength(1));
      final outer = details.single;
      final inner =
          outer.children!.singleWhere(
                (node) => node is md.Element && node.tag == 'details',
              )
              as md.Element;
      expect(
        inner.children!.whereType<md.Element>().map((node) => node.tag),
        contains('p'),
      );
      expect(
        nodes.whereType<md.Element>().any(
          (node) => node.tag == 'p' && node.textContent == 'After',
        ),
        isTrue,
      );
    });

    test('both renderer entry points consume the shared scoped tree', () {
      const markdown = '''
<blockquote>

Body

</blockquote>
''';
      final modern = MarkdownRenderer().renderToAnsi(markdown);
      final legacy = AnsiRenderer().render(parseMarkdownNodes(markdown));
      expect(Style.stripAnsi(modern), contains('│ Body'));
      expect(Style.stripAnsi(legacy), contains('│ Body'));
    });

    test('attaches to the open occurrence, not an earlier closed sibling', () {
      for (final tag in ['blockquote', 'details']) {
        final nodes = parseMarkdownNodes(
          '<$tag>first</$tag><$tag>\n\n**second**\n\n</$tag>\n\nAfter',
        );
        final containers = nodes
            .whereType<md.Element>()
            .where((node) => node.tag == tag)
            .toList();
        expect(containers.map((node) => node.textContent), ['first', 'second']);
        expect(nodes.last.textContent, 'After');
      }
    });

    test('handles comments, quoted delimiters, and a tail before closing', () {
      final nodes = normalizeMarkdownNodes([
        md.Text('<blockquote title="a > b"><!-- </blockquote> -->'),
        md.Element.text('p', 'Body'),
        md.Text('tail</blockquote><p>After</p>'),
      ]);
      expect((nodes.first as md.Element).tag, 'blockquote');
      expect(nodes.first.textContent, 'Bodytail');
      expect(nodes.last.textContent, 'After');
    });

    test(
      'keeps literal Markdown code and metadata opaque through HTML parsing',
      () {
        final code = md.Element.text('code', '&lt;details&gt; **literal**');
        final heading = md.Element.text('h2', 'Title')
          ..generatedId = 'generated'
          ..attributes['id'] = 'anchor';
        final nodes = normalizeMarkdownNodes([
          md.Text('<blockquote>'),
          code,
          heading,
          md.Text('</blockquote>'),
        ]);
        final children = (nodes.single as md.Element).children!;
        expect(children.first, same(code));
        expect(children.first.textContent, '&lt;details&gt; **literal**');
        expect((children.last as md.Element).generatedId, 'generated');
        expect((children.last as md.Element).attributes['id'], 'anchor');
      },
    );

    test('does not mistake user custom tags for embedded Markdown nodes', () {
      final nodes = normalizeMarkdownNodes([
        md.Text('<blockquote><ARTISANAL-MD data-index="0">User</ARTISANAL-MD>'),
        md.Element.text('p', 'Body'),
        md.Text('</blockquote>'),
      ]);
      expect(nodes.single.textContent, 'UserBody');
    });

    test('restores Markdown nodes within an HTML table cell', () {
      final nodes = normalizeMarkdownNodes([
        md.Text('<table><tr><td>'),
        md.Element('p', [md.Element.text('strong', 'Cell')]),
        md.Text('</td></tr></table><p>After</p>'),
      ]);
      final table = nodes.first as md.Element;
      expect(table.tag, 'table');
      expect(table.textContent, 'Cell');
      expect(nodes.last.textContent, 'After');
    });

    test('restores rows and cells without HTML table foster-parenting', () {
      final row = md.Element('tr', [md.Element.text('td', 'Cell')]);
      final table =
          normalizeMarkdownNodes([
                md.Text('<table>'),
                row,
                md.Text('</table>'),
              ]).single
              as md.Element;
      expect(table.tag, 'table');
      expect((table.children!.single as md.Element).tag, 'tr');
      final withCell =
          normalizeMarkdownNodes([
                md.Text('<table><tbody><tr>'),
                md.Element.text('td', 'Body'),
                md.Text('</tr></tbody></table>'),
              ]).single
              as md.Element;
      expect(withCell.tag, 'table');
      expect(withCell.textContent, 'Body');
    });

    test(
      'restores text in RCDATA and keeps ignored raw-text elements ignored',
      () {
        for (final tag in ['textarea', 'select']) {
          final nodes = normalizeMarkdownNodes([
            md.Text('<$tag>'),
            md.Element.text('strong', 'Body'),
            md.Text('</$tag>'),
          ]);
          expect(nodes.map((node) => node.textContent).join(), 'Body');
        }
        expect(
          normalizeMarkdownNodes([
            md.Text('<script>'),
            md.Element.text('strong', 'Hidden'),
            md.Text('</script>'),
          ]),
          isEmpty,
        );
      },
    );

    test('preserves spaces between inline HTML siblings and comments', () {
      for (final source in [
        '<p><span>Hello</span> <span>world</span></p>',
        '<p><span>Hello</span> <!-- note --> <em>world</em></p>',
        '<p><span>Hello</span><span> </span><span>world</span></p>',
      ]) {
        final nodes = parseMarkdownNodes(source);
        expect(nodes.single.textContent, 'Hello world');
      }
    });

    test('does not interpret literal or entity-encoded marker text', () {
      final nodes = normalizeMarkdownNodes([
        md.Text('<textarea>&lt;!--&#97;rtisanal-md:0--&gt;</textarea>'),
        md.Element.text('p', 'Body'),
      ]);
      expect(nodes.first.textContent, '<!--artisanal-md:0-->');
      expect(nodes.last.textContent, 'Body');
    });

    test(
      'keeps block Markdown outside paragraph wrappers after restoring nodes',
      () {
        final nodes = normalizeMarkdownNodes([
          md.Text('<p>Before'),
          md.Element.text('h2', 'Heading'),
          md.Text('After</p>'),
        ]);
        expect(nodes.whereType<md.Element>().map((node) => node.tag), [
          'p',
          'h2',
          'p',
        ]);
        expect(nodes.map((node) => node.textContent), [
          'Before',
          'Heading',
          'After',
        ]);
      },
    );

    test(
      'renders nested open and closed details without leaking their bodies',
      () {
        const source = '''
<details open>
<summary>Open</summary>

VISIBLE

<details>
<summary>Closed</summary>

HIDDEN

</details>

VISIBLE_AGAIN

</details>

AFTER
''';
        for (final output in [
          MarkdownRenderer().renderToAnsi(source),
          AnsiRenderer().render(parseMarkdownNodes(source)),
        ]) {
          final plain = Style.stripAnsi(output);
          expect(plain, contains('▾ Open'));
          expect(plain, contains('▸ Closed'));
          expect(plain, contains('VISIBLE'));
          expect(plain, contains('VISIBLE_AGAIN'));
          expect(plain, contains('AFTER'));
          expect(plain, isNot(contains('HIDDEN')));
        }
      },
    );
  });
}
