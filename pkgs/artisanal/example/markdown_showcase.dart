/// Kitchen-sink Markdown showcase for the unified MarkdownRenderer.
library;

import 'package:artisanal/artisanal.dart';

const _markdown = r'''
# Markdown Showcase

A **complete** showcase for *MarkdownRenderer* with `inline code`, ~~strike~~,
and HTML entities like &lt; &amp; &gt;.

## Headings

### Level 3
#### Level 4
##### Level 5
###### Level 6

### Heading with **Bold** and *Italic*

## Links

- [Example link](https://example.com)
- Autolink: <https://dart.dev>
- Email: <user@example.com>

## Hard Line Breaks

Line one with two spaces··
Line two after a hard break.
Line three with backslash\
Line four after backslash break.

## Escaped Characters

\*This is not italic\*  
\*\*This is not bold\*\*  
\`This is not code\`

## Lists

- Unordered item one
- Unordered item two
  - Nested item A
  - Nested item B
    1. Deep ordered one
    2. Deep ordered two

1. Ordered item one
2. Ordered item two
   - Mixed nested bullet
   - Another nested bullet with **bold**

- [x] Completed task
- [ ] Pending task

## Blockquotes

> A quote can span multiple lines,
> include **bold** text, and even
>
> > Nested quote.

> Here's a code block inside a quote:
>
> ```dart
> void main() {
>   print('hello');
> }
> ```

## Code

Plain fence:

```
raw text without language
```

With language label:

```dart

void main() {
  print('Hello, world!');
}
```

```json

{
  "name": "artisanal"
}
```

## Tables

| Left | Center | Right |
|:-----|:------:|------:|
| A | B | C |
| **bold** | *italic* | `code` |

## Image

![Dart logo](https://dart.dev/assets/img/logo/dart-192.svg)

(With `renderImages: true`, SVG images are rasterized via pure_svg
and displayed inline using the terminal's image protocol.)

---

<details>
<summary>Expandable details</summary>

Toggle content with **formatting** and `code`.

</details>
''';

void main() async {
  // Pre-download images (SVG is rasterized via pure_svg).
  final imageCache = await MarkdownRenderer.preloadImages(_markdown);

  final defaultRendered = MarkdownRenderer(
    options: const AnsiRendererOptions(width: 88, renderImages: true),
  ).renderToAnsi(_markdown, imageCache: imageCache);

  final glamourRendered = MarkdownRenderer(
    options: GlamourTheme.dark.toAnsiRendererOptions(
      width: 88,
      renderImages: true,
    ),
  ).renderToAnsi(_markdown, imageCache: imageCache);

  _section('Default MarkdownRenderer', defaultRendered);
  _section('Glamour dark theme via bridge', glamourRendered);
}

void _section(String title, String output) {
  print('\x1b[1m\x1b[96m$title\x1b[0m');
  print(output);
  print('');
}
