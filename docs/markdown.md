# Render Markdown in the terminal

Artisanal offers a quick ANSI renderer for inline content and a richer Glamour
renderer for documents. Choose based on the output you need:

- `package:artisanal/artisanal.dart`: lightweight Markdown-to-ANSI rendering
  with simple options.
- `package:artisanal/glamour.dart`: high-fidelity rendering with
  theme-driven formatting.

Use the ANSI renderer for fast, minimal output. Use Glamour for rich,
document-style rendering.

## Quick Start (ANSI)

```dart
import 'package:artisanal/artisanal.dart';

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
import 'package:artisanal/artisanal.dart';

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
import 'package:artisanal/artisanal.dart';

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

## Rendering Fidelity

Artisanal provides two markdown renderers with different fidelity levels. The `glamour.dart` renderer delivers high-fidelity markdown-to-ANSI conversion with theme-driven formatting, while `markdown.dart` offers a lightweight, fast alternative for simpler use cases.

### Table Rendering Accuracy

The Glamour renderer calculates column widths dynamically based on content, producing properly aligned tables with clean borders:

```markdown
| Feature | Status |
|---------|--------|
| Tables  | ✅     |
| Nesting | ✅     |
```

Features:
- Measures column widths from both headers and data cells
- Pads cells consistently with proper alignment
- Draws complete borders with `+---+---+` and `|` separators
- Handles nested tables within cells
- Respects alignment hints (left, center, right) in table headers

The ANSI renderer provides basic table borders with fixed-width columns, while Glamour adapts column widths to fit content optimally.

### Code Block Handling with Chroma Syntax Highlighting

Fenced code blocks support comprehensive syntax highlighting via integrated Chroma themes:

```dart
import 'package:artisanal/glamour.dart';

final renderer = GlamourRenderer(
  theme: GlamourTheme.dark,
);
renderer.render(nodes); // Code blocks render with Chroma colors
```

Features:
- Language detection from fence labels (```dart, ```rust, ```python, etc.)
- Integration with `ChromaTheme` for accurate syntax highlighting across 100+ languages
- Margin and padding control via `GlamourCodeBlockStyle`
- Borderless option for embedded code snippets
- Line number support and range highlighting
- Adaptive theme switching (light/dark background detection)

Both renderers support syntax highlighting, but Glamour provides deeper Chroma integration with theme-aware token coloring and customizable code block presentation.

### Nested Lists and Proper Indentation

Nested lists maintain proper indentation at each level with configurable depth:

```markdown
- Item 1
  - Nested item 1.1
    - Deeply nested 1.1.1
      - Level 4 item
  - Nested item 1.2
- Item 2
```

The renderer tracks list depth and applies:
- Per-level indentation configurable via `GlamourListStyle.levelIndent`
- Correct counters for ordered lists at each nesting level (1.1, 1.2, etc.)
- Task list checkbox state preservation ([x] and [ ])
- Mixed list type handling (ordered within unordered and vice versa)

Glamour provides enhanced indentation control compared to the basic ANSI renderer, particularly for deeply nested structures.

### Heading Hierarchy with Theme-Driven Styling

Headings use theme-driven styling with H1 receiving special treatment:

```markdown
# H1 Title (background highlight in dark theme)
## H2 Heading
### H3 Heading
#### H4 Heading
```

Each heading level (`h1` through `h6`) has dedicated theme configuration supporting:
- Foreground colors per level with semantic differentiation
- Background colors (H1 in dark/light themes)
- Prefix/suffix text for visual distinction
- Bold weight for hierarchy emphasis
- Underline styles for secondary headings
- Vertical spacing control before/after

See [style.md](style.md) for detailed theme configuration options.

### Blockquotes with Border Markers

Blockquotes render with distinctive vertical border markers:

```markdown
> This is a blockquote
> Multiple lines are supported
> 
> > Nested blockquote levels also work
```

Features:
- `│ ` prefix marker repeated per nesting level
- Configurable `indentToken` in `GlamourBlockStyle`
- Continuous markers across wrapped lines
- Proper spacing and margin control
- Theme-aware border and text colors
- Support for multiple nesting levels

### Horizontal Rules

Horizontal rules adapt to the current theme:

```markdown
---
```

Rendered using the theme's `horizontalRule.format` property (default: `--------` in light themes, `────────` in dark themes), with theme-appropriate coloring. Custom formats can include Unicode box-drawing characters for visual variety.

### Inline HTML Handling

Raw HTML is rendered using appropriate text styling where applicable:

```html
<strong>Bold</strong> and <em>italic</em>
<span style="color: red">Colored text</span>
```

The renderer applies semantic text styles (bold, italic, underline) instead of passing through raw HTML tags. Color information from inline styles is mapped to theme-appropriate colors where possible. Security-sensitive tags are stripped to prevent injection.

### Link Reference Definitions

Standard markdown links and reference-style definitions render with optional hyperlinks:

```markdown
[Link text](https://example.com)

[Reference link][1]

[1]: https://example.com "Optional title"
```

Both renderers support OSC 8 hyperlinks (configurable via `hyperlinks` option in `AnsiRendererOptions` or theme configuration). Links can be styled with custom colors and underline settings, and are interactive in terminals that support OSC 8 URL detection.

### Emoji Shortcodes

Emoji shortcodes are supported via the standard `:shortcode:` syntax:

```markdown
Success! :tada: :sparkles:
Warning :warning: - Check the docs
```

Supported shortcodes follow the GitHub emoji specification, with rendering that respects the current theme's color palette. Emoji display varies by terminal capability, with fallbacks to shortcode text where emoji rendering is unavailable.

### ANSI vs Glamour Renderer Comparison

| Feature | ANSI Renderer (`markdown.dart`) | Glamour Renderer (`glamour.dart`) |
|---------|---------------------------------|-----------------------------------|
| **Speed** | Faster - lightweight parsing | Moderate - theme processing overhead |
| **Tables** | Basic borders, fixed widths | Dynamic column widths, alignment hints |
| **Code blocks** | Syntax highlighting only | Chroma-integrated with theme adaptation |
| **Nesting** | Supported, basic indentation | Enhanced indentation with per-level control |
| **Blockquotes** | Simple `>` prefix | Styled with border markers and nesting |
| **Headings** | Color per level | Full theme-driven styling with backgrounds |
| **Customization** | Style options per render | Comprehensive theme system |
| **Inline HTML** | Basic tag stripping | Semantic style mapping |
| **Link handling** | Standard and OSC 8 | Standard, OSC 8, and themed styling |
| **Emoji support** | Basic shortcodes | Full GitHub shortcode set with theme awareness |
| **Horizontal rules** | Static characters | Theme-adaptive formats |
| **Best for** | Logs, inline docs, speed-critical | Documents, reports, rich output |

### Related Docs

- [style.md](style.md) - Style system for terminal output
- [console.md](console.md) - Console output and markdown integration  
- [docs_index.md](docs_index.md) - Full documentation index
- [terminal.md](terminal.md)
