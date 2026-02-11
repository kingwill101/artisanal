# Markdown Rendering (ANSI + Glamour)

Artisanal offers two Markdown renderers:

- `markdown.dart`: lightweight Markdown-to-ANSI with simple options.
- `glamour.dart`: high-fidelity renderer with theme-driven formatting.

Use `markdown.dart` for fast, minimal output. Use `glamour.dart` for rich document-style rendering.

## Quick Start (ANSI)

```dart
import 'package:artisanal/markdown.dart';

void main() {
  final markdown = '''
# Hello
This is **bold** and *italic*.

- One
- Two

    void main() {
      print('hi');
    }
''';

  final output = markdownToAnsi(markdown);
  print(output);
}
```

## ANSI Customization

```dart
import 'package:artisanal/markdown.dart';
import 'package:artisanal/artisanal.dart';

void main() {
  final markdown = '''
# Styled
A [link](https://example.com) and some `inline code`.

    void main() {
      print('hi');
    }
''';

  final options = AnsiRendererOptions(
    width: 60,
    bulletChar: '-',
    hyperlinks: true,
    codeBlockBorder: true,
    syntaxHighlighting: true,
    syntaxTheme: ChromaTheme.dracula,
    h1Style: Style().bold().foreground(Colors.cyan),
  );

  print(markdownToAnsi(markdown, options: options));
}
```

## Syntax Highlighting

```dart
import 'package:artisanal/markdown.dart';

void main() {
  final highlighter = SyntaxHighlighter(
    theme: ChromaTheme.monokai,
  );

  final highlighted = highlighter.highlightCode(
    'void main() { print("Hello"); }',
    language: 'dart',
  );

  print(highlighted);
}
```

## Adaptive Highlighting

```dart
import 'package:artisanal/markdown.dart';

void main() {
  final highlighter = SyntaxHighlighter.adaptive(
    adaptiveTheme: AdaptiveChromaTheme.draculaGithub,
    hasDarkBackground: true,
  );

  final highlighted = highlighter.highlightCode(
    'final value = 42;',
    language: 'dart',
  );

  print(highlighted);
}
```

## Quick Start (Glamour)

```dart
import 'package:artisanal/glamour.dart';

void main() {
  final markdown = '''
# Glamour
> Blockquote

- Item 1
- Item 2
''';

  final output = renderStyle(
    markdown,
    theme: GlamourTheme.dark,
    width: 80,
  );

  print(output);
}
```

## Glamour Renderer (Explicit)

```dart
import 'package:artisanal/glamour.dart';
import 'package:markdown/markdown.dart' as md;

void main() {
  final markdown = '''
## Custom Render
Some **bold** text.
''';

  final document = md.Document(
    extensionSet: md.ExtensionSet.gitHubFlavored,
    encodeHtml: false,
  );
  final nodes = document.parseLines(markdown.split('\n'));

  final renderer = GlamourRenderer(
    theme: GlamourTheme.light,
    width: 72,
  );

  final output = renderer.render(nodes);
  print(output);
}
```

## When to Use Which

- `markdown.dart`: faster, simpler, ideal for inline docs and logs.
- `glamour.dart`: richer formatting and consistent document styling.

## Related Docs

- [DOCS_INDEX.md](DOCS_INDEX.md) - Full documentation index
- [STYLE.md](STYLE.md)
- [TERMINAL.md](TERMINAL.md)
