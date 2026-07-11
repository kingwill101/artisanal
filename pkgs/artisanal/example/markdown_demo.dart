/// Demonstrates the new [MarkdownRenderer] API.
///
/// Shows basic usage, custom styling with [MarkdownElementStyle],
/// and Glamour theming via the bridge.
///
/// Run with: dart run example/markdown_demo.dart
library;

import 'package:artisanal/artisanal.dart';

const _md = '''
# Artisanal Markdown

A **markdown-to-ANSI** renderer for beautiful terminal output.

## Inline Styling

- **Bold**, *italic*, and `inline code`
- ~~strikethrough~~ for deletions
- [Hyperlinks](https://github.com) with OSC 8 support

## Task Lists

- [x] Headings (h1-h6)
- [x] Text formatting
- [x] Code blocks with language labels
- [ ] Tables with borders

## Blockquote

> "The terminal is a canvas, and ANSI codes are our paint."
> — *Anonymous Developer*

## Code Block

```dart
void main() {
  print('Hello, world!');
}
```

## Table

| Feature | Status | Priority |
|---------|--------|----------|
| Headings | Done | High |
| Lists | Done | High |
| Code | Done | Medium |
''';

void main() {
  _demo('1. Basic MarkdownRenderer',
        'MarkdownRenderer().renderToAnsi(md)',
        MarkdownRenderer().renderToAnsi(_md));

  _demo('2. Custom MarkdownElementStyle',
        'AnsiRendererOptions.fromElementStyles(...)',
        MarkdownRenderer(
          options: AnsiRendererOptions.fromElementStyles(
            width: 72,
            h1Style: MarkdownElementStyle(
              foreground: Colors.brightMagenta, bold: true),
            h2Style: MarkdownElementStyle(
              foreground: Colors.magenta, bold: true),
            codeStyle: MarkdownElementStyle(
              foreground: Colors.brightYellow,
              background: Colors.gray800),
            strongStyle: MarkdownElementStyle(
              bold: true, underline: true),
            bulletChar: '\u25b8',
          ),
        ).renderToAnsi(_md));

  _demo('3. Glamour Dark Theme',
        'GlamourTheme.dark.toAnsiRendererOptions()',
        MarkdownRenderer(
          options: GlamourTheme.dark.toAnsiRendererOptions(width: 72),
        ).renderToAnsi(_md));

  _demo('4. Glamour Light Theme',
        'GlamourTheme.light.toAnsiRendererOptions()',
        MarkdownRenderer(
          options: GlamourTheme.light.toAnsiRendererOptions(width: 72),
        ).renderToAnsi(_md));
}

void _demo(String label, String subtitle, String output) {
  print('\x1b[1m\x1b[93m$label\x1b[0m');
  print('\x1b[90m   $subtitle\x1b[0m\n');
  print(output);
  print('\n');
}
