# Measure terminal text correctly

String length is not the same as terminal width. These helpers let you iterate
visible graphemes and estimate how many terminal cells text will occupy,
including wide CJK characters and emoji.

## Grapheme Iteration

```dart
import 'package:artisanal/terminal.dart' as terminal;

void main() {
  final s = String.fromCharCodes([0x41, 0x1F600, 0x6F22]);
  for (final g in terminal.graphemes(s)) {
    print(g);
  }
}
```

## Width Calculation

```dart
import 'package:ultraviolet/ultraviolet.dart' as uv;

void main() {
  print(uv.stringWidth('ASCII'));
  print(uv.stringWidth(String.fromCharCodes([0x1F600])));
  final cjk = String.fromCharCodes([0x6F22, 0x5B57]);
  print(uv.maxLineWidth('ab\n$cjk'));

  uv.setEmojiPresentationWidth(1);
  print('emoji width=1: ${uv.stringWidth(String.fromCharCodes([0x1F600]))}');

  uv.setEmojiPresentationWidth(2);
  print('emoji width=2: ${uv.stringWidth(String.fromCharCodes([0x1F600]))}');
}
```

## Things to keep in mind

- Width is minimal and approximate; complex emoji sequences may be undercounted.
- Emoji width is a global setting; set it once at startup.

## Where to go next

- [docs_index.md](docs_index.md) - Full documentation index
- [layout.md](layout.md)
