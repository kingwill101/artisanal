// MarkdownText Example
//
// Demonstrates the MarkdownText widget rendering different Markdown content.
// Press 't' to cycle through content tabs showing headings, formatting,
// code blocks, and lists.
//
// Run with: dart run example/markdown_text/main.dart

import 'package:artisanal/style.dart';
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/widgets.dart' as w;

void main() async {
  final app = tui.WidgetApp(MarkdownTextDemo());
  await tui.runProgram(
    app,
    options: const tui.ProgramOptions(
      altScreen: true,
      mouseMode: tui.MouseMode.allMotion,
    ),
  );
}

class MarkdownTextDemo extends w.StatefulWidget {
  MarkdownTextDemo({super.key});

  @override
  w.State createState() => _MarkdownTextDemoState();
}

class _MarkdownTextDemoState extends w.State<MarkdownTextDemo> {
  final w.WidgetScrollController _scrollController = w.WidgetScrollController();
  int _tabIndex = 0;

  static const _tabs = [
    'Headings',
    'Formatting',
    'Code',
    'Lists',
    'Mixed',
    'Kitchen Sink',
  ];

  static const _contents = [
    // Headings
    '''# Heading 1

## Heading 2

### Heading 3

#### Heading 4

Regular paragraph text below the headings.''',

    // Formatting
    '''# Text Formatting

This is **bold text** and this is *italic text*.

You can combine ***bold and italic*** together.

Here is `inline code` within a sentence.

> This is a blockquote that highlights
> an important piece of information.''',

    // Code
    '''# Code Blocks

Inline code: `var x = 42;`

A fenced code block:

```dart
void main() {
  print('Hello, World!');
  for (var i = 0; i < 5; i++) {
    print('Count: \$i');
  }
}
```

Another block:

```
plain text code block
no syntax highlighting
```''',

    // Lists
    '''# Lists

## Unordered List

- First item
- Second item
- Third item with more detail
- Fourth item

## Ordered List

1. Step one
2. Step two
3. Step three
4. Step four

## Nested

- Parent item
  - Child item A
  - Child item B
- Another parent''',

    // Mixed
    '''# Mixed Content Demo

This paragraph has **bold**, *italic*, and `code`.

## Features

- Headings (H1-H4)
- **Bold** and *italic*
- Code blocks
- Lists (ordered and unordered)
- Blockquotes

> Terminal markdown rendering powered by artisanal.

---

```
Thank you for trying MarkdownText!
```''',

    // Kitchen Sink — long, comprehensive markdown document
    '''# The Kitchen Sink

Everything the renderer can do, in one scrollable document.
Grab the scrollbar, use arrow keys, or mouse-wheel to explore.

---

## 1. Headings at Every Level

# Heading 1 -- the biggest
## Heading 2 -- still pretty big
### Heading 3 -- getting smaller
#### Heading 4 -- modest
##### Heading 5 -- subtle
###### Heading 6 -- the smallest

---

## 2. Inline Formatting Buffet

Regular text, **bold text**, *italic text*, and ***bold italic text***.

Here is ~~strikethrough text~~ for things that are no longer true.

Mix them: **bold with *nested italic* inside** and *italic with **nested bold** inside*.

Inline `code spans` can appear anywhere: `let x = 42;`

---

## 3. Emoji & Unicode

Emoji render as regular Unicode glyphs in the terminal:

Faces: \u{1F600} \u{1F60E} \u{1F914} \u{1F631} \u{1F4A9} \u{1F389} \u{1F525} \u{2728} \u{1F680} \u{1F30D}

Hands: \u{1F44D} \u{1F44E} \u{1F44B} \u{1F64F} \u{1F4AA} \u{270C}\u{FE0F} \u{1F91D} \u{1F448} \u{1F449} \u{261D}\u{FE0F}

Animals: \u{1F431} \u{1F436} \u{1F98A} \u{1F43B} \u{1F41D} \u{1F40D} \u{1F422} \u{1F419} \u{1F433} \u{1F985}

Food: \u{1F355} \u{1F354} \u{1F363} \u{1F370} \u{2615} \u{1F37A} \u{1F34E} \u{1F34C} \u{1F952} \u{1F966}

Weather: \u{2600}\u{FE0F} \u{1F324}\u{FE0F} \u{26C5} \u{1F327}\u{FE0F} \u{26C8}\u{FE0F} \u{2744}\u{FE0F} \u{1F308} \u{1F32A}\u{FE0F} \u{1F321}\u{FE0F} \u{2614}

Symbols: \u{2705} \u{274C} \u{26A0}\u{FE0F} \u{1F6AB} \u{2B50} \u{1F4A1} \u{1F512} \u{1F513} \u{267B}\u{FE0F} \u{1F3AF}

Flags: \u{1F3F3}\u{FE0F} \u{1F3F4} \u{1F3C1}

Arrows & math: \u{2190} \u{2191} \u{2192} \u{2193} \u{21C4} \u{2234} \u{221E} \u{2248} \u{2260} \u{2264}

Box-drawing chars: \u{250C}\u{2500}\u{2500}\u{2500}\u{2510}  \u{256D}\u{2500}\u{2500}\u{2500}\u{256E}
                   \u{2502}   \u{2502}  \u{2502}   \u{2502}
                   \u{2514}\u{2500}\u{2500}\u{2500}\u{2518}  \u{2570}\u{2500}\u{2500}\u{2500}\u{256F}

---

## 4. Blockquotes

> A simple single-line blockquote.

> A multi-line blockquote that spans
> multiple lines to show how the vertical
> bar prefix wraps with the text.

> **Bold inside a quote**, *italic inside a quote*, and `code inside a quote`.

> > Nested blockquote -- a quote within a quote.
> > This demonstrates depth.

> \u{1F4AC} "The only way to do great work is to love what you do."
> -- Steve Jobs

---

## 5. Unordered Lists

- Apples \u{1F34E}
- Bananas \u{1F34C}
- Cherries \u{1F352}
- Dates
- Elderberries

Nested:

- Programming languages
  - Dart \u{1F3AF}
  - Rust \u{1F980}
  - Python \u{1F40D}
    - CPython
    - PyPy
    - MicroPython
  - Go
- Databases
  - PostgreSQL
  - SQLite
  - Redis

---

## 6. Ordered Lists

1. Mercury
2. Venus
3. Earth \u{1F30D}
4. Mars
5. Jupiter
6. Saturn
7. Uranus
8. Neptune

With detail:

1. **Wake up** -- \u{23F0} 6:00 AM
2. **Exercise** -- \u{1F3CB}\u{FE0F} 30 minutes of stretching
3. **Breakfast** -- \u{2615} Coffee and toast
4. **Deep work** -- \u{1F4BB} 4 hours of focused coding
5. **Lunch** -- \u{1F355} Something quick
6. **Meetings** -- \u{1F4DE} Sync with the team
7. **Review PRs** -- \u{1F50D} Read diffs, leave comments
8. **Wind down** -- \u{1F4DA} Read a book
9. **Sleep** -- \u{1F634} 10:30 PM

---

## 7. Task Lists

- [x] Design the widget API
- [x] Implement the renderer
- [x] Add syntax highlighting
- [ ] Write documentation
- [ ] Publish to pub.dev
- [x] Add table support
- [ ] Add footnote support
- [x] Ship emoji in examples \u{1F680}

---

## 8. Code Blocks

Inline: `print("Hello!")` and `42.toString()` and `List<Map<String, dynamic>>`.

### Dart

```dart
import 'dart:math';

/// A generic binary tree node.
class TreeNode<T extends Comparable<T>> {
  TreeNode(this.value, {this.left, this.right});

  final T value;
  TreeNode<T>? left;
  TreeNode<T>? right;

  /// In-order traversal yields sorted values.
  Iterable<T> inOrder() sync* {
    if (left != null) yield* left!.inOrder();
    yield value;
    if (right != null) yield* right!.inOrder();
  }

  @override
  String toString() => 'TreeNode(\$value)';
}

void main() {
  final rng = Random(42);
  final values = List.generate(10, (_) => rng.nextInt(100));
  print('Values: \$values');

  // Build a naive BST.
  TreeNode<int>? root;
  for (final v in values) {
    root = _insert(root, v);
  }

  print('Sorted: \${root!.inOrder().toList()}');
}

TreeNode<int> _insert(TreeNode<int>? node, int value) {
  if (node == null) return TreeNode(value);
  if (value < node.value) {
    node.left = _insert(node.left, value);
  } else {
    node.right = _insert(node.right, value);
  }
  return node;
}
```

### Python

```python
from dataclasses import dataclass
from typing import Optional, Iterator

@dataclass
class TreeNode:
    value: int
    left: Optional["TreeNode"] = None
    right: Optional["TreeNode"] = None

    def in_order(self) -> Iterator[int]:
        if self.left:
            yield from self.left.in_order()
        yield self.value
        if self.right:
            yield from self.right.in_order()

def insert(node: Optional[TreeNode], value: int) -> TreeNode:
    if node is None:
        return TreeNode(value)
    if value < node.value:
        node.left = insert(node.left, value)
    else:
        node.right = insert(node.right, value)
    return node

if __name__ == "__main__":
    import random
    random.seed(42)
    values = [random.randint(0, 99) for _ in range(10)]
    root = None
    for v in values:
        root = insert(root, v)
    print(f"Sorted: {list(root.in_order())}")
```

### Bash

```bash
#!/usr/bin/env bash
set -euo pipefail

# Deploy script with rollback support
VERSION=\$(git describe --tags --always)
DEPLOY_DIR="/opt/app/releases/\$VERSION"
CURRENT_LINK="/opt/app/current"

echo "Deploying version \$VERSION..."

mkdir -p "\$DEPLOY_DIR"
rsync -a --delete ./build/ "\$DEPLOY_DIR/"

# Swap the symlink atomically
ln -sfn "\$DEPLOY_DIR" "\$CURRENT_LINK"

echo "Restarting services..."
systemctl restart myapp.service

echo "Deployed \$VERSION successfully."
```

### JSON

```json
{
  "name": "artisanal",
  "version": "2.1.0",
  "description": "Terminal UI toolkit for Dart",
  "features": {
    "widgets": true,
    "markdown": true,
    "emoji": "\u{1F680}",
    "themes": ["dark", "light", "monokai", "dracula"]
  },
  "dependencies": {
    "dart": ">=3.0.0",
    "markdown": "^7.0.0"
  }
}
```

### Plain text (no highlighting)

```
This is a plain code block with no language specified.
It should render without syntax highlighting but still
inside a bordered box.

    Indented content is preserved.
    Whitespace matters here.
```

---

## 9. Tables

### Simple table

| Feature       | Status | Notes             |
|---------------|--------|-------------------|
| Headings      | \u{2705}     | H1 through H6      |
| Bold / Italic | \u{2705}     | Nested too          |
| Code blocks   | \u{2705}     | With highlighting   |
| Tables        | \u{2705}     | GitHub-flavored     |
| Emoji         | \u{2705}     | Unicode pass-through|
| Footnotes     | \u{274C}     | Not yet             |

### Alignment

| Left-aligned | Center-aligned | Right-aligned |
|:-------------|:--------------:|--------------:|
| \u{1F34E} Apples    |   \u{1F34C} Bananas    |     \u{1F352} Cherries |
| 10           |       20       |            30 |
| Hello        |     World      |           !!! |
| Short        |    Longer      |  Even Longer! |

### Data table

| Language   | Year | Paradigm         | Typing   | Emoji |
|------------|------|------------------|----------|-------|
| Dart       | 2011 | OOP, Functional  | Static   | \u{1F3AF}    |
| Python     | 1991 | Multi-paradigm   | Dynamic  | \u{1F40D}    |
| Rust       | 2010 | Systems, Safe    | Static   | \u{1F980}    |
| JavaScript | 1995 | Event-driven     | Dynamic  | \u{1F310}    |
| Haskell    | 1990 | Pure Functional  | Static   | \u{1F9EA}    |
| C          | 1972 | Imperative       | Static   | \u{2699}\u{FE0F}    |
| Lisp       | 1958 | Functional       | Dynamic  | \u{1F4DC}    |

---

## 10. Horizontal Rules

Above this is a standard `---` rule.

***

Above was a `***` rule (should also render).

---

## 11. Links

Visit [Dart](https://dart.dev) for the language homepage.

Check out [artisanal on GitHub](https://github.com/example/artisanal) for the source.

Multiple links in one line: [Google](https://google.com), [GitHub](https://github.com), [Stack Overflow](https://stackoverflow.com).

---

## 12. Images (terminal approximation)

![Artisanal Logo](https://example.com/logo.png)

![A beautiful sunset over mountains](https://example.com/sunset.jpg)

---

## 13. Long Paragraphs for Selection Testing

Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.

\u{1F4DD} The quick brown fox \u{1F98A} jumps over the lazy dog \u{1F436}. Pack my box with five dozen liquor jugs \u{1F37A}. How vexingly quick daft zebras \u{1F993} jump! The five boxing wizards \u{1F93C} jump quickly. Bright vixens jump; dozy fowl quack \u{1F986}. Jackdaws love my big sphinx of quartz \u{1F48E}.

**Performance matters.** When rendering thousands of lines of markdown in a terminal, every millisecond counts. The artisanal renderer parses the AST once and walks it in a single pass, emitting ANSI escape sequences directly. No intermediate HTML, no browser engine, no WebView -- just raw terminal power. \u{26A1}

*Architecture note:* The `MarkdownText` widget caches its rendered output keyed on `(data, options, softWrap, maxWidth, hasDarkBackground)`. This means re-renders are essentially free when the input hasn't changed, which is critical for 60fps TUI applications that redraw every frame.

---

## 14. Mixed Formatting Stress Test

Here is a paragraph with **bold**, *italic*, ***bold-italic***, `inline code`, ~~strikethrough~~, and [a link](https://example.com) all in one sentence, plus some emoji: \u{1F525}\u{1F680}\u{2728}\u{1F4A5}\u{1F3C6}.

> **Quoted bold** with *quoted italic* and `quoted code` and ~~quoted strikethrough~~ plus \u{1F31F}.

- **Bold list item** with `code` and *italic*
- ~~Struck-through item~~ -- no longer relevant
- Regular item with [link](https://example.com) and \u{1F44D}
- `Code-styled list item`

1. First with **emphasis**
2. Second with `code` and *italics*
3. Third with ~~old info~~ \u{274C} replaced by new info \u{2705}

---

## 15. Deeply Nested Content

- Level 1
  - Level 2
    - Level 3
      - Level 4 -- this is getting deep
      - Another level 4 item
    - Back to level 3
  - Back to level 2
- Back to level 1
  - Side branch level 2
    - Side branch level 3

---

## 16. ASCII Art & Monospace

```
  \u{2554}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2557}
  \u{2551}  \u{2588}\u{2588}\u{2588}\u{2588}\u{2588}                          \u{2551}
  \u{2551}  \u{2588}   \u{2588}  artisanal              \u{2551}
  \u{2551}  \u{2588}\u{2588}\u{2588}\u{2588}\u{2588}  Terminal UI Toolkit      \u{2551}
  \u{2551}  \u{2588}   \u{2588}  for Dart                \u{2551}
  \u{2551}  \u{2588}   \u{2588}  v2.1.0                  \u{2551}
  \u{255A}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{255D}
```

---

## 17. Special Characters & Escaping

Angle brackets: < > (should not break rendering)

Ampersand: & -- used in HTML entities

Pipes in text (not tables): cmd1 | cmd2 | cmd3

Backslash: \\\\ double backslash

Backtick in code: `` ` `` (single backtick inside code)

---

## 18. The Grand Finale

\u{1F3AC} **That's a wrap!** This document exercises every major feature of the
`MarkdownText` renderer. If you've scrolled all the way down here, try these:

1. \u{1F446} Scroll back up and **click-drag** to select text
2. \u{1F4CB} Press **Ctrl+C** to copy your selection
3. \u{1F5B1}\u{FE0F} **Double-click** a word to select it
4. \u{1F4CF} Resize your terminal and watch the layout adapt
5. \u{1F3A8} Try changing the theme

> \u{1F4A1} *Tip:* Press `t` to cycle through the other tabs and compare rendering.

---

*Built with* ***artisanal*** *\u{2764}\u{FE0F} -- Terminal UIs, the artisanal way.*

```dart
// One last code block for the road
void main() => print('\u{1F44B} Thanks for exploring!');
```''',
  ];

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg is tui.KeyMsg) {
      if (msg.key.char == 'q') return tui.Cmd.quit();
      if (msg.key.char == 't') {
        setState(() {
          _tabIndex = (_tabIndex + 1) % _tabs.length;
        });
      }
    }
    return null;
  }

  @override
  w.Widget build(w.BuildContext context) {
    final theme = widget.theme;
    final label = theme.labelSmall.copy()..foreground(theme.onBackground);

    final tabLabels = List.generate(_tabs.length, (i) {
      final active = i == _tabIndex;
      final prefix = active ? '> ' : '  ';
      return '$prefix${_tabs[i]}';
    }).join('  ');

    return w.Container(
      child: w.Scrollbar(
        controller: _scrollController,
        thickness: 1,
        gap: 1,
        enableHover: true,
        trackChar: ' ',
        thumbChar: ' ',
        trackUsesBackground: true,
        thumbUsesBackground: true,
        trackGradient: w.ScrollbarGradient.background(
          start: w.hasDarkBackground
              ? const BasicColor('#2f363d')
              : const BasicColor('#e3e7eb'),
          end: w.hasDarkBackground
              ? const BasicColor('#1f252a')
              : const BasicColor('#d3d9e0'),
        ),
        thumbGradient: w.ScrollbarGradient.background(
          start: w.hasDarkBackground
              ? const BasicColor('#3fb2ff')
              : const BasicColor('#2f7df6'),
          end: w.hasDarkBackground
              ? const BasicColor('#7c5cff')
              : const BasicColor('#6e55f5'),
        ),
        hoverThumbGradient: w.ScrollbarGradient.background(
          start: w.hasDarkBackground
              ? const BasicColor('#79ddff')
              : const BasicColor('#4f93ff'),
          end: w.hasDarkBackground
              ? const BasicColor('#b18bff')
              : const BasicColor('#836bff'),
        ),
        hoverThumbChar: ' ',
        child: w.ScrollView(
          controller: _scrollController,
          handleKeys: true,
          child: w.Container(
            padding: const w.EdgeInsets.all(1),
            color: theme.background,
            child: w.Column(
              gap: 1,
              children: [
                w.Text('MarkdownText Widget Demo', style: theme.titleLarge),
                w.Text('t = cycle tab | q = quit', style: label),
                w.Divider(width: 70),
                w.Text(tabLabels, style: theme.titleSmall),
                w.Divider(width: 70),
                w.MarkdownText(data: _contents[_tabIndex], maxWidth: 68),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
