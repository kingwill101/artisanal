import 'dart:io';

import 'package:artisanal/artisanal.dart';
import 'package:test/test.dart';

String normalize(String input) => input.replaceAll('\r\n', '\n');

File _resolveFixture(String relativePath) {
  final candidates = <String>[
    relativePath,
    'pkgs/artisanal/$relativePath',
    'packages/artisanal/$relativePath',
  ];
  for (final candidate in candidates) {
    final file = File(candidate);
    if (file.existsSync()) return file;
  }
  throw FileSystemException('Unable to locate test fixture', relativePath);
}

void expectParity(String markdown, {AnsiRendererOptions? options}) {
  final oldOutput = markdownToAnsi(markdown, options: options);
  final newOutput = MarkdownRenderer(options: options).renderToAnsi(markdown);

  expect(
    normalize(newOutput),
    equals(normalize(oldOutput)),
    reason: 'MarkdownRenderer output should match markdownToAnsi()',
  );
}

void main() {
  final comprehensive = _resolveFixture(
    'test/markdown/fixtures/comprehensive.md',
  ).readAsStringSync();

  group('MarkdownRenderer parity', () {
    test('matches the comprehensive fixture', () {
      expectParity(comprehensive);
    });

    test('matches the comprehensive fixture with wrapping and theming', () {
      expectParity(
        comprehensive,
        options: AnsiRendererOptions.fromElementStyles(
          width: 88,
          h1Style: MarkdownElementStyle(
            foreground: Colors.brightCyan,
            bold: true,
          ),
          h2Style: MarkdownElementStyle(foreground: Colors.cyan, bold: true),
          emphasisStyle: MarkdownElementStyle(italic: true),
          strongStyle: MarkdownElementStyle(bold: true),
          codeStyle: MarkdownElementStyle(
            foreground: Colors.brightYellow,
            background: Colors.gray800,
          ),
          blockquoteStyle: MarkdownElementStyle(italic: true, dim: true),
          blockquoteBorderColor: Colors.gray,
          bulletChar: '•',
          syntaxHighlighting: true,
        ),
      );
    });

    test('headings, inline styles, links, and entities', () {
      expectParity(r'''
# H1

## H2

### H3

This is **bold**, *italic*, `code`, ~~strike~~, and [link](https://example.com).

Use &lt;tag&gt; &amp; &quot;quotes&quot;.
''');
    });

    test('nested lists and task lists', () {
      expectParity(r'''
- Parent
  - Child A
  - Child B
    - Grandchild
- [x] Done
- [ ] Todo
1. First
2. Second
   1. Nested one
   2. Nested two
''');
    });

    test('blockquotes, nested blockquotes, and quoted lists', () {
      expectParity(r'''
> Quote line 1
> Quote line 2
>
> - Item one
> - Item two
>
> > Nested quote
''');
    });

    test('fenced code blocks and inline code', () {
      expectParity(r'''
Inline `code`.

```dart
void main() {
  print('hello');
}
```

```json
{"name": "artisanal"}
```
''');
    });

    test('tables, images, horizontal rules, and details', () {
      expectParity(r'''
![Alt text](https://example.com/image.png)

---

<details>
<summary>More</summary>

| A | B |
|---|---|
| 1 | 2 |

</details>
''');
    });
  });
}
