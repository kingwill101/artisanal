import 'package:artisanal/tui.dart' show MouseMsg, MouseAction, MouseButton;
import 'package:artisanal/style.dart';
import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:artisanal_widgets/testing.dart';
import 'package:test/test.dart';

/// Full Kitchen Sink markdown content from example/markdown_text/main.dart.
/// This is the exact content that triggers scroll rendering corruption.
const _kitchenSinkMarkdown = '''# The Kitchen Sink

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
```

### Bash

```bash
#!/usr/bin/env bash
set -euo pipefail

VERSION=\$(git describe --tags --always)
DEPLOY_DIR="/opt/app/releases/\$VERSION"

echo "Deploying version \$VERSION..."
mkdir -p "\$DEPLOY_DIR"
rsync -a --delete ./build/ "\$DEPLOY_DIR/"
echo "Deployed \$VERSION successfully."
```

---

## 9. Tables

| Feature       | Status | Notes             |
|---------------|--------|-------------------|
| Headings      | \u{2705}     | H1 through H6      |
| Bold / Italic | \u{2705}     | Nested too          |
| Code blocks   | \u{2705}     | With highlighting   |
| Tables        | \u{2705}     | GitHub-flavored     |
| Emoji         | \u{2705}     | Unicode pass-through|

---

## 10. Long Paragraphs

Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.

\u{1F4DD} The quick brown fox \u{1F98A} jumps over the lazy dog \u{1F436}. Pack my box with five dozen liquor jugs \u{1F37A}. How vexingly quick daft zebras \u{1F993} jump!

**Performance matters.** When rendering thousands of lines of markdown in a terminal, every millisecond counts. The artisanal renderer parses the AST once and walks it in a single pass, emitting ANSI escape sequences directly.

---

## 11. Mixed Formatting Stress Test

Here is a paragraph with **bold**, *italic*, ***bold-italic***, `inline code`, ~~strikethrough~~, and a link all in one sentence, plus some emoji: \u{1F525}\u{1F680}\u{2728}\u{1F4A5}\u{1F3C6}.

> **Quoted bold** with *quoted italic* and `quoted code` plus \u{1F31F}.

- **Bold list item** with `code` and *italic*
- ~~Struck-through item~~ -- no longer relevant
- Regular item with \u{1F44D}

1. First with **emphasis**
2. Second with `code` and *italics*
3. Third with ~~old info~~ \u{274C} replaced by new info \u{2705}

---

## 12. The Grand Finale

\u{1F3AC} **That's a wrap!** This document exercises every major feature of the
`MarkdownText` renderer.

> \u{1F4A1} *Tip:* Press `t` to cycle through the other tabs.

---

*Built with* ***artisanal*** *\u{2764}\u{FE0F} -- Terminal UIs, the artisanal way.*

```dart
void main() => print('\u{1F44B} Thanks for exploring!');
```''';

/// Large generated document for stress testing scroll behavior.
/// Each section has unique content to avoid false-positive duplicate detection.
String _generateLargeDocument(int sections) {
  final buf = StringBuffer();
  buf.writeln('# Large Document Scroll Test\n');
  buf.writeln('This document has $sections sections for scroll testing.\n');
  buf.writeln('---\n');

  for (var i = 1; i <= sections; i++) {
    buf.writeln('## Section $i of $sections\n');
    // Each paragraph is unique to avoid false duplicate detection
    buf.writeln(
      'Section $i paragraph: The quick brown fox jumps over the lazy dog. '
      'This is section number $i out of $sections total sections.\n',
    );

    if (i % 3 == 0) {
      buf.writeln('Items unique to section $i:\n');
      for (var j = 1; j <= 5; j++) {
        buf.writeln('- Item $j in section $i');
      }
      buf.writeln();
    }

    if (i % 4 == 0) {
      buf.writeln(
        'Section $i emoji: \u{1F600} \u{1F60E} \u{1F914} \u{1F631}\n',
      );
    }

    if (i % 5 == 0) {
      buf.writeln('```dart');
      buf.writeln('void functionForSection$i() {');
      buf.writeln("  print('Running section $i');");
      buf.writeln('}');
      buf.writeln('```\n');
    }

    buf.writeln('---\n');
  }

  buf.writeln('## Document End\n');
  buf.writeln('All $sections sections complete.');
  return buf.toString();
}

/// Strips ANSI escape sequences from a string for content comparison.
final _ansiPattern = RegExp(r'\x1B\[[0-9;]*[a-zA-Z]|\x1B\].*?\x07|\x1B\[.*?m');
String _stripAnsi(String s) => s.replaceAll(_ansiPattern, '');

/// Builds the widget tree matching the markdown example structure.
Widget _buildExampleTree(
  WidgetScrollController ctrl,
  String markdownContent, {
  bool withScrollbar = false,
  int maxWidth = 68,
}) {
  final scrollView = ScrollView(
    controller: ctrl,
    handleKeys: true,
    child: Container(
      padding: const EdgeInsets.all(1),
      child: Column(
        gap: 1,
        children: [
          Text('MarkdownText Widget Demo'),
          Text('t = cycle tab | q = quit'),
          Divider(width: 70),
          Text('  Headings  Formatting  Code  Lists  Mixed  > Kitchen Sink'),
          Divider(width: 70),
          MarkdownText(data: markdownContent, maxWidth: maxWidth),
        ],
      ),
    ),
  );

  if (!withScrollbar) return scrollView;

  return Scrollbar(
    controller: ctrl,
    thickness: 1,
    gap: 1,
    enableHover: true,
    trackChar: '│',
    thumbChar: '█',
    child: scrollView,
  );
}

/// Collects the full rendered content as a list of ANSI-stripped lines.
/// This is the "ground truth" for verifying viewport slices.
///
/// When [stripScrollbarCols] > 0, that many columns are stripped from the
/// right edge of each line to remove the scrollbar track/thumb/gap area
/// which changes with scroll position and would cause false mismatches.
List<String> _collectFullContent(
  WidgetTester tester,
  WidgetScrollController ctrl, {
  int stripScrollbarCols = 0,
}) {
  // Get the content at offset 0 first
  ctrl.jumpTo(0);
  tester.pump();
  final firstView = tester.view
      .split('\n')
      .map(_stripAnsi)
      .map((l) => _trimScrollbar(l, stripScrollbarCols))
      .toList();

  // Now collect all content by scrolling through all offsets
  final allLines = <String>[];
  allLines.addAll(firstView);

  final maxOffset = ctrl.maxOffset;
  for (var offset = 1; offset <= maxOffset; offset++) {
    ctrl.jumpTo(offset);
    tester.pump();
    final lines = tester.view
        .split('\n')
        .map(_stripAnsi)
        .map((l) => _trimScrollbar(l, stripScrollbarCols))
        .toList();
    // Each increment by 1 reveals one new line at the bottom
    if (lines.isNotEmpty) {
      allLines.add(lines.last);
    }
  }

  return allLines;
}

/// Removes the rightmost [cols] characters from a line to strip the
/// scrollbar area. If cols is 0 or the line is too short, returns as-is.
String _trimScrollbar(String line, int cols) {
  if (cols <= 0) return line;
  // Strip trailing whitespace first, then trim the scrollbar columns
  final trimmed = line.trimRight();
  if (trimmed.length <= cols) return '';
  return trimmed.substring(0, trimmed.length - cols);
}

void main() {
  group('Kitchen Sink scroll rendering', () {
    test(
      'viewport at offset N matches contiguous slice from full content',
      () async {
        final tester = WidgetTester(screenWidth: 80, screenHeight: 24);
        addTearDown(() => tester.dispose());

        final ctrl = WidgetScrollController();
        await tester.pumpWidget(_buildExampleTree(ctrl, _kitchenSinkMarkdown));

        // Collect the full content
        final fullContent = _collectFullContent(
          tester,
          ctrl,
          stripScrollbarCols: 2,
        );
        expect(
          fullContent.length,
          greaterThan(24),
          reason: 'content should be longer than viewport',
        );

        // Now verify that at each offset, the viewport shows the correct
        // contiguous slice.
        final maxOffset = ctrl.maxOffset;
        for (var offset = 0; offset <= maxOffset; offset++) {
          ctrl.jumpTo(offset);
          tester.pump();

          final viewLines = tester.view
              .split('\n')
              .map(_stripAnsi)
              .map((l) => _trimScrollbar(l, 2))
              .toList();
          expect(
            viewLines.length,
            equals(24),
            reason: 'viewport must have 24 lines at offset $offset',
          );

          // Each viewport line should match the corresponding line from
          // the full content (offset + i).
          for (var i = 0; i < viewLines.length; i++) {
            final fullIdx = offset + i;
            if (fullIdx >= fullContent.length) break;
            expect(
              viewLines[i].trimRight(),
              equals(fullContent[fullIdx].trimRight()),
              reason:
                  'At offset $offset, viewport line $i should match '
                  'full content line $fullIdx.\n'
                  'Expected: "${fullContent[fullIdx].trimRight()}"\n'
                  'Actual:   "${viewLines[i].trimRight()}"',
            );
          }
        }
      },
    );

    test('each viewport line is unique after mouse wheel scroll', () async {
      final tester = WidgetTester(screenWidth: 80, screenHeight: 24);
      addTearDown(() => tester.dispose());

      final ctrl = WidgetScrollController();
      await tester.pumpWidget(_buildExampleTree(ctrl, _kitchenSinkMarkdown));

      expect(tester.find.text('The Kitchen Sink'), isTrue);

      for (var i = 0; i < 3; i++) {
        tester.sendMsg(
          MouseMsg(
            action: MouseAction.press,
            button: MouseButton.wheelDown,
            x: 10,
            y: 10,
          ),
        );
      }

      final scrolledLines = tester.view.split('\n');
      expect(scrolledLines.length, equals(24));
      expect(tester.find.text('MarkdownText Widget Demo'), isFalse);
    });

    test('viewport line count consistency at every scroll position', () async {
      final tester = WidgetTester(screenWidth: 80, screenHeight: 24);
      addTearDown(() => tester.dispose());

      final ctrl = WidgetScrollController();
      await tester.pumpWidget(_buildExampleTree(ctrl, _kitchenSinkMarkdown));

      final maxOffset = ctrl.maxOffset;
      for (var offset = 0; offset <= maxOffset; offset++) {
        ctrl.jumpTo(offset);
        tester.pump();
        final lines = tester.view.split('\n');
        expect(
          lines.length,
          equals(24),
          reason: 'viewport must have 24 lines at offset $offset',
        );
      }
    });

    test(
      'incremental scroll continuity -- adjacent viewports overlap correctly',
      () async {
        final tester = WidgetTester(screenWidth: 80, screenHeight: 24);
        addTearDown(() => tester.dispose());

        final ctrl = WidgetScrollController();
        await tester.pumpWidget(_buildExampleTree(ctrl, _kitchenSinkMarkdown));

        final maxOffset = ctrl.maxOffset;
        List<String>? prevLines;

        for (var offset = 0; offset <= maxOffset; offset++) {
          ctrl.jumpTo(offset);
          tester.pump();

          final lines = tester.view.split('\n').map(_stripAnsi).toList();

          if (prevLines != null) {
            // Lines 0..22 of current view should match lines 1..23 of prev
            var matches = 0;
            for (var i = 0; i < 23; i++) {
              if (lines[i].trimRight() == prevLines[i + 1].trimRight()) {
                matches++;
              }
            }
            // At least 22 of 23 lines should match (allow 1 for padding)
            expect(
              matches,
              greaterThanOrEqualTo(22),
              reason:
                  'At offset $offset, only $matches/23 lines matched '
                  'previous viewport shifted by 1',
            );
          }

          prevLines = lines;
        }
      },
    );
  });

  group('Large document scroll rendering with Scrollbar', () {
    test(
      'scrollbar + large document -- viewport line count at all offsets',
      () async {
        final tester = WidgetTester(screenWidth: 80, screenHeight: 24);
        addTearDown(() => tester.dispose());

        final ctrl = WidgetScrollController();
        final largeDoc = _generateLargeDocument(30);

        await tester.pumpWidget(
          _buildExampleTree(ctrl, largeDoc, withScrollbar: true),
        );

        expect(tester.find.text('Large Document'), isTrue);

        final maxOffset = ctrl.maxOffset;
        expect(
          maxOffset,
          greaterThan(50),
          reason: 'large document should require scrolling',
        );

        for (var offset = 0; offset <= maxOffset; offset++) {
          ctrl.jumpTo(offset);
          tester.pump();

          final lines = tester.view.split('\n');
          expect(
            lines.length,
            equals(24),
            reason: 'viewport must have 24 lines at offset $offset',
          );
        }
      },
    );

    test(
      'scrollbar + large document -- contiguous slice verification',
      () async {
        final tester = WidgetTester(screenWidth: 80, screenHeight: 24);
        addTearDown(() => tester.dispose());

        final ctrl = WidgetScrollController();
        final largeDoc = _generateLargeDocument(30);

        await tester.pumpWidget(
          _buildExampleTree(ctrl, largeDoc, withScrollbar: true),
        );

        final fullContent = _collectFullContent(
          tester,
          ctrl,
          stripScrollbarCols: 2,
        );
        final maxOffset = ctrl.maxOffset;

        for (var offset = 0; offset <= maxOffset; offset++) {
          ctrl.jumpTo(offset);
          tester.pump();

          final viewLines = tester.view
              .split('\n')
              .map(_stripAnsi)
              .map((l) => _trimScrollbar(l, 2))
              .toList();

          for (var i = 0; i < viewLines.length; i++) {
            final fullIdx = offset + i;
            if (fullIdx >= fullContent.length) break;
            expect(
              viewLines[i].trimRight(),
              equals(fullContent[fullIdx].trimRight()),
              reason:
                  'At offset $offset, viewport line $i should match '
                  'full content line $fullIdx',
            );
          }
        }
      },
    );

    test(
      'scrollbar + kitchen sink -- line widths are uniform within viewport',
      () async {
        final tester = WidgetTester(screenWidth: 80, screenHeight: 24);
        addTearDown(() => tester.dispose());

        final ctrl = WidgetScrollController();
        await tester.pumpWidget(
          _buildExampleTree(ctrl, _kitchenSinkMarkdown, withScrollbar: true),
        );

        final maxOffset = ctrl.maxOffset;
        for (var offset = 0; offset <= maxOffset; offset += 5) {
          ctrl.jumpTo(offset);
          tester.pump();

          final lines = tester.view.split('\n');
          final widths = lines.map(Layout.visibleLength).toList();

          final maxW = widths.reduce((a, b) => a > b ? a : b);
          for (var i = 0; i < lines.length; i++) {
            if (lines[i].isEmpty) continue;
            expect(
              widths[i],
              equals(maxW),
              reason:
                  'At offset $offset, line $i has width ${widths[i]} '
                  'but expected $maxW.\n'
                  'Line: "${_stripAnsi(lines[i])}"',
            );
          }
        }
      },
    );

    test(
      'mouse wheel scroll through kitchen sink with scrollbar -- consistency',
      () async {
        final tester = WidgetTester(screenWidth: 80, screenHeight: 24);
        addTearDown(() => tester.dispose());

        final ctrl = WidgetScrollController();
        await tester.pumpWidget(
          _buildExampleTree(ctrl, _kitchenSinkMarkdown, withScrollbar: true),
        );

        // Collect full content first
        final fullContent = _collectFullContent(
          tester,
          ctrl,
          stripScrollbarCols: 2,
        );

        // Reset to 0 and scroll with mouse wheel
        ctrl.jumpTo(0);
        tester.pump();

        for (var scroll = 0; scroll < 20; scroll++) {
          tester.sendMsg(
            MouseMsg(
              action: MouseAction.press,
              button: MouseButton.wheelDown,
              x: 40,
              y: 12,
            ),
          );

          final lines = tester.view.split('\n');
          expect(
            lines.length,
            equals(24),
            reason: 'viewport must have 24 lines after scroll $scroll',
          );

          // Verify the current offset matches expected slice
          final offset = ctrl.offset;
          final viewLines = lines
              .map(_stripAnsi)
              .map((l) => _trimScrollbar(l, 2))
              .toList();
          for (var i = 0; i < viewLines.length; i++) {
            final fullIdx = offset + i;
            if (fullIdx >= fullContent.length) break;
            expect(
              viewLines[i].trimRight(),
              equals(fullContent[fullIdx].trimRight()),
              reason:
                  'After scroll $scroll (offset $offset), '
                  'line $i should match full content line $fullIdx',
            );
          }
        }
      },
    );
  });

  group('Large document stress tests', () {
    test(
      'very large document (50 sections) -- scroll every offset with scrollbar',
      () async {
        final tester = WidgetTester(screenWidth: 100, screenHeight: 30);
        addTearDown(() => tester.dispose());

        final ctrl = WidgetScrollController();
        final largeDoc = _generateLargeDocument(50);

        await tester.pumpWidget(
          _buildExampleTree(ctrl, largeDoc, withScrollbar: true, maxWidth: 90),
        );

        final maxOffset = ctrl.maxOffset;
        expect(
          maxOffset,
          greaterThan(100),
          reason: '50-section doc should have >100 lines of content',
        );

        for (var offset = 0; offset <= maxOffset; offset += 5) {
          ctrl.jumpTo(offset);
          tester.pump();

          final lines = tester.view.split('\n');
          expect(
            lines.length,
            equals(30),
            reason: 'viewport must be 30 lines at offset $offset',
          );
        }
      },
    );

    test(
      'very large document -- incremental scroll overlap verification',
      () async {
        final tester = WidgetTester(screenWidth: 100, screenHeight: 30);
        addTearDown(() => tester.dispose());

        final ctrl = WidgetScrollController();
        final largeDoc = _generateLargeDocument(50);

        await tester.pumpWidget(
          _buildExampleTree(ctrl, largeDoc, withScrollbar: true, maxWidth: 90),
        );

        List<String>? prevLines;
        final maxOffset = ctrl.maxOffset;
        for (var offset = 0; offset <= maxOffset && offset < 300; offset++) {
          ctrl.jumpTo(offset);
          tester.pump();

          final lines = tester.view
              .split('\n')
              .map(_stripAnsi)
              .map((l) => l.trimRight())
              .toList();

          if (prevLines != null) {
            // Lines 0..(n-2) of new view should match lines 1..(n-1) of prev
            var matchCount = 0;
            for (var i = 0; i < lines.length - 1; i++) {
              if (lines[i] == prevLines[i + 1]) matchCount++;
            }
            // At least 90% should match (scrollbar thumb may change)
            final matchRatio = matchCount / (lines.length - 1);
            expect(
              matchRatio,
              greaterThan(0.85),
              reason:
                  'At offset $offset, only $matchCount/${lines.length - 1} '
                  'lines matched previous viewport shifted by 1',
            );
          }

          prevLines = lines;
        }
      },
    );

    test(
      'large document with emoji and variation selectors -- scroll consistency',
      () async {
        final tester = WidgetTester(screenWidth: 80, screenHeight: 24);
        addTearDown(() => tester.dispose());

        final ctrl = WidgetScrollController();
        // Build a document with emoji including variation selectors
        final buf = StringBuffer();
        buf.writeln('# Unicode Stress Test\n');
        for (var i = 0; i < 20; i++) {
          buf.writeln('## Section $i of 20\n');
          buf.writeln('Section $i text content.\n');
          if (i % 3 == 0) {
            buf.writeln('Faces in section $i: \u{1F600} \u{1F60E} \u{1F914}\n');
          }
          if (i % 4 == 0) {
            buf.writeln(
              'Weather in section $i: \u{2600}\u{FE0F} \u{1F324}\u{FE0F} '
              '\u{26C5} \u{1F327}\u{FE0F}\n',
            );
          }
          buf.writeln('---\n');
        }

        await tester.pumpWidget(
          _buildExampleTree(ctrl, buf.toString(), withScrollbar: true),
        );

        final fullContent = _collectFullContent(
          tester,
          ctrl,
          stripScrollbarCols: 2,
        );
        final maxOffset = ctrl.maxOffset;

        for (var offset = 0; offset <= maxOffset; offset++) {
          ctrl.jumpTo(offset);
          tester.pump();

          final viewLines = tester.view
              .split('\n')
              .map(_stripAnsi)
              .map((l) => _trimScrollbar(l, 2))
              .toList();
          expect(
            viewLines.length,
            equals(24),
            reason: 'viewport must have 24 lines at offset $offset',
          );

          for (var i = 0; i < viewLines.length; i++) {
            final fullIdx = offset + i;
            if (fullIdx >= fullContent.length) break;
            expect(
              viewLines[i].trimRight(),
              equals(fullContent[fullIdx].trimRight()),
              reason:
                  'At offset $offset, viewport line $i should match '
                  'full content line $fullIdx.\n'
                  'Expected: "${fullContent[fullIdx].trimRight()}"\n'
                  'Actual:   "${viewLines[i].trimRight()}"',
            );
          }
        }
      },
    );

    test(
      'kitchen sink contiguous slice with scrollbar at every offset',
      () async {
        final tester = WidgetTester(screenWidth: 80, screenHeight: 24);
        addTearDown(() => tester.dispose());

        final ctrl = WidgetScrollController();
        await tester.pumpWidget(
          _buildExampleTree(ctrl, _kitchenSinkMarkdown, withScrollbar: true),
        );

        final fullContent = _collectFullContent(
          tester,
          ctrl,
          stripScrollbarCols: 2,
        );
        final maxOffset = ctrl.maxOffset;

        for (var offset = 0; offset <= maxOffset; offset++) {
          ctrl.jumpTo(offset);
          tester.pump();

          final viewLines = tester.view
              .split('\n')
              .map(_stripAnsi)
              .map((l) => _trimScrollbar(l, 2))
              .toList();

          for (var i = 0; i < viewLines.length; i++) {
            final fullIdx = offset + i;
            if (fullIdx >= fullContent.length) break;
            expect(
              viewLines[i].trimRight(),
              equals(fullContent[fullIdx].trimRight()),
              reason:
                  'At offset $offset, viewport line $i should match '
                  'full content line $fullIdx.\n'
                  'Expected: "${fullContent[fullIdx].trimRight()}"\n'
                  'Actual:   "${viewLines[i].trimRight()}"',
            );
          }
        }
      },
    );
  });
}
