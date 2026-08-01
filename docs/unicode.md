# Unicode Utilities

Artisanal includes helpers for grapheme cluster iteration and approximate terminal width calculations.

## Grapheme Iteration

```dart
import 'package:artisanal/src/unicode/grapheme.dart' as uni;

void main() {
  final s = String.fromCharCodes([0x41, 0x1F600, 0x6F22]);
  for (final g in uni.graphemes(s)) {
    print(g);
  }
}
```

## Width Calculation

```dart
import 'package:artisanal/src/unicode/width.dart' as uw;

void main() {
  print(uw.stringWidth('ASCII'));
  print(uw.stringWidth(String.fromCharCodes([0x1F600])));
  final cjk = String.fromCharCodes([0x6F22, 0x5B57]);
  print(uw.maxLineWidth('ab\n$cjk'));

  uw.setEmojiPresentationWidth(1);
  print('emoji width=1: ${uw.stringWidth(String.fromCharCodes([0x1F600]))}');

  uw.setEmojiPresentationWidth(2);
  print('emoji width=2: ${uw.stringWidth(String.fromCharCodes([0x1F600]))}');
}
```

## Gotchas

- Width is minimal and approximate; complex emoji sequences may be undercounted.
- Emoji width is a global setting; set it once at startup.

## Related Docs

- [docs_index.md](docs_index.md) - Full documentation index
- [layout.md](layout.md)
