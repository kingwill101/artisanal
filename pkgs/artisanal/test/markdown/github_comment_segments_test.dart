import 'package:artisanal/artisanal.dart';
import 'package:test/test.dart';

void main() {
  group('GitHub disclosure segmentation', () {
    test(
      'keeps commented details opaque and leaves following Markdown intact',
      () {
        const source = '''
Before
<!--
<details open>
<summary>Supporting CLs</summary>

- Hidden work

</details>
-->

## Use cases
Visible ending
''';
        final segments = githubDisplayMarkdownSegments(source);
        expect(segments, hasLength(1));
        final text = segments.single as GithubMarkdownTextSegment;
        expect(text.markdown, contains('<!--'));
        expect(text.markdown, contains('-->'));
        final rendered = Style.stripAnsi(markdownToAnsi(text.markdown));
        expect(rendered, contains('Use cases'));
        expect(rendered, contains('Visible ending'));
        expect(rendered, isNot(contains('Supporting CLs')));
        expect(rendered, isNot(contains('Hidden work')));
        expect(rendered, isNot(contains('-->')));
      },
    );

    test(
      'extracts real details after commented, fenced, and inline lookalikes',
      () {
        const source = '''
<!-- <details><summary>Comment</summary></details> -->

````html
<details><summary>Code</summary></details>
```
<!-- literal unmatched comment in a code block
````

`<details><summary>Inline</summary></details>` and `<!--`

<details open>
<summary>Real</summary>
Visible body
</details>

After
''';
        final segments = githubDisplayMarkdownSegments(source);
        final disclosures = segments
            .whereType<GithubMarkdownDetailsSegment>()
            .toList();
        expect(disclosures, hasLength(1));
        expect(disclosures.single.summary, 'Real');
        expect(disclosures.single.initiallyExpanded, isTrue);
        expect(disclosures.single.markdown, 'Visible body');
        expect((segments.last as GithubMarkdownTextSegment).markdown, 'After');
      },
    );

    test('ignores details in quoted fences and HTML code blocks', () {
      for (final source in [
        '> ~~~html\n> <details><summary>Code</summary></details>\n> ~~~',
        '<pre><code><details>Code</details></code></pre>',
        '<code><details>Code</details></code>',
        r'\<details>Literal\</details>',
      ]) {
        expect(
          githubDisplayMarkdownSegments(
            source,
          ).whereType<GithubMarkdownDetailsSegment>(),
          isEmpty,
        );
      }
    });

    test('protects indented code while retaining nested-list disclosures', () {
      for (final literal in [
        '    <details>\n    <summary>Code</summary>\n    </details>',
        'Before\n\n    <details>\n    <summary>Code</summary>\n    </details>\n\nAfter',
        'Before\n\n\t<details>\n\t<summary>Code</summary>\n\t</details>\n\nAfter',
        '>     <details>\n>     <summary>Code</summary>\n>     </details>',
      ]) {
        expect(
          githubDisplayMarkdownSegments(
            literal,
          ).whereType<GithubMarkdownDetailsSegment>(),
          isEmpty,
        );
      }
      final nested = githubDisplayMarkdownSegments(
        '1. Item\n\n   <details>\n   <summary>Real</summary>\n   Body\n   </details>',
      ).whereType<GithubMarkdownDetailsSegment>().single;
      expect(nested.summary, 'Real');
      final htmlIndented = githubDisplayMarkdownSegments(
        '<details>\n    <summary>Indented HTML</summary>\n    Body\n</details>',
      ).whereType<GithubMarkdownDetailsSegment>().single;
      expect(htmlIndented.summary, 'Indented HTML');
      final tabbed = githubDisplayMarkdownSegments(
        '1. Item\n\n   \t<details>\n   \t<summary>Tabbed</summary>\n   \tBody\n   \t</details>',
      ).whereType<GithubMarkdownDetailsSegment>().single;
      expect(tabbed.summary, 'Tabbed');
    });

    test(
      'display normalization preserves indentation and hard line breaks',
      () {
        expect(
          githubDisplayMarkdown('\n    code  \r\n    more\n\n'),
          '    code  \n    more',
        );
        expect(
          githubStripBlockquoteMarkers('>     code  \n>     more'),
          '    code  \n    more',
        );
        final parts = githubDisplayMarkdownSegments('First  \nSecond');
        expect(
          (parts.single as GithubMarkdownTextSegment).markdown,
          'First  \nSecond',
        );
      },
    );

    test('an unclosed quote fence ends with its Markdown container', () {
      final parts = githubDisplayMarkdownSegments(
        '> ```html\n> <details>Code</details>\n\n'
        '<details><summary>Real</summary>Body</details>',
      ).whereType<GithubMarkdownDetailsSegment>();
      expect(parts, hasLength(1));
      expect(parts.single.summary, 'Real');
    });

    test('ignores fake close and summary tags inside comments and code', () {
      const source = '''
<details title="not open > here">
<!-- <summary>Wrong</summary> </details> -->
<summary><b>Actual &amp; title</b></summary>

```html
</details>
```

Body tail
</details>
Outside
''';
      final segments = githubDisplayMarkdownSegments(source);
      final details = segments.first as GithubMarkdownDetailsSegment;
      expect(details.summary, 'Actual & title');
      expect(details.initiallyExpanded, isFalse);
      expect(details.markdown, contains('Body tail'));
      expect((segments.last as GithubMarkdownTextSegment).markdown, 'Outside');
    });

    test('keeps nested real details within their outer disclosure', () {
      const source = '''
<details>
<summary>Outer</summary>
<details open><summary>Inner</summary>Inner body</details>
Outer tail
</details>
After
''';
      final segments = githubDisplayMarkdownSegments(source);
      final details = segments.first as GithubMarkdownDetailsSegment;
      expect(details.summary, 'Outer');
      expect(details.markdown, contains('<summary>Inner</summary>'));
      expect(details.markdown, contains('Outer tail'));
      expect(segments, hasLength(2));
      expect(details.children, hasLength(2));
      final inner = details.children[0] as GithubMarkdownDetailsSegment;
      expect(inner.summary, 'Inner');
      expect(inner.initiallyExpanded, isTrue);
      expect(
        (details.children[1] as GithubMarkdownTextSegment).markdown,
        'Outer tail',
      );
    });

    test(
      'bounds deeply nested disclosures and retains the remaining source',
      () {
        final source = StringBuffer();
        for (
          var depth = 0;
          depth < githubMaxInteractiveDetailsDepth + 8;
          depth++
        ) {
          source
            ..writeln('<details>')
            ..writeln('<summary>Depth $depth</summary>');
        }
        source.writeln('<!-- hidden nested source -->');
        for (
          var depth = 0;
          depth < githubMaxInteractiveDetailsDepth + 8;
          depth++
        ) {
          source.writeln('</details>');
        }

        final segments = githubDisplayMarkdownSegments(source.toString());
        var current = segments.whereType<GithubMarkdownDetailsSegment>().single;
        var interactiveDepth = 1;
        while (current.children.isNotEmpty &&
            current.children.first is GithubMarkdownDetailsSegment) {
          current = current.children.first as GithubMarkdownDetailsSegment;
          interactiveDepth++;
        }
        final fallback = current.children
            .whereType<GithubMarkdownTextSegment>()
            .single;

        expect(interactiveDepth, githubMaxInteractiveDetailsDepth);
        expect(fallback.markdown, contains('<!-- hidden nested source -->'));
        expect(fallback.markdown, contains('depth limit reached'));
        expect(fallback.markdown, contains('```'));
      },
    );

    test(
      'preserves quoted details and unterminated input without duplication',
      () {
        final quoted = githubDisplayMarkdownSegments(
          '> <details open>\n> <summary>Quote</summary>\n> Body\n> </details>',
        ).whereType<GithubMarkdownDetailsSegment>().single;
        expect(quoted.quoted, isTrue);
        expect(quoted.markdown, 'Body');
        final unterminated = githubDisplayMarkdownSegments(
          'Before\n<details>\nUnfinished',
        );
        expect(unterminated.whereType<GithubMarkdownDetailsSegment>(), isEmpty);
        expect(
          unterminated
              .whereType<GithubMarkdownTextSegment>()
              .map((part) => part.markdown)
              .join('\n'),
          'Before\n<details>\nUnfinished',
        );
      },
    );
  });
}
