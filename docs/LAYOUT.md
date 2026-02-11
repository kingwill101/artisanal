# Layout Utilities

The layout helpers build aligned, width-aware text blocks. They are ANSI-aware for most operations and integrate with the style system.

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

## Gotchas

- `truncate` appends a reset before the ellipsis; this can reset styles.
- `placeHeight` always pads with spaces, even if a fill char is provided.
- `stack` treats only literal spaces as transparent; styled spaces are opaque.

## Related Docs

- [DOCS_INDEX.md](DOCS_INDEX.md) - Full documentation index
- [STYLE.md](STYLE.md)
- [UNICODE.md](UNICODE.md)
