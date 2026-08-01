# Arrange terminal content

The layout helpers place text blocks beside or above one another while
respecting ANSI styles and terminal width. Use them when a full widget tree
would be unnecessary but string concatenation is no longer enough.

## Quick Start

```dart
import 'package:artisanal/artisanal.dart';

void main() {
  final left = 'CPU\n72%';
  final right = 'RAM\n5.2G';
  final row = Layout.joinHorizontal(
    VerticalAlign.top,
    [left, right],
    gap: 3,
  );

  final page = Layout.place(
    width: 20,
    height: 6,
    horizontal: HorizontalAlign.center,
    vertical: VerticalAlign.center,
    content: row,
  );

  print(page);
}
```

## Common Helpers

- Size: `getSize`, `getWidth`, `getHeight`
- Join: `joinHorizontal`, `joinVertical`
- Align: `place`, `placeHorizontal`, `placeVertical`
- Truncate: `truncate`, `truncateLines`, `truncateHeight`
- Wrap: `wrap`, `wrapLines`
- ANSI: `stripAnsi`, `visibleLength`

## Truncate Example

```dart
import 'package:artisanal/artisanal.dart';

void main() {
  final long = 'This is a very long line of text';
  final clipped = Layout.truncate(long, 12);
  print(clipped);
}
```

## Things to keep in mind

- `truncate` appends a reset before the ellipsis; this can reset styles.
- `placeHeight` always pads with spaces, even if a fill char is provided.
- `stack` treats only literal spaces as transparent; styled spaces are opaque.

## Where to go next

- [docs_index.md](docs_index.md) - Full documentation index
- [style.md](style.md)
- [unicode.md](unicode.md)
