# Console Components Helper

`Console.components` provides higher-level, Laravel-style UI helpers built on Artisanal components.

## Quick Start

```dart
import 'package:artisanal/artisanal.dart';

Future<void> main() async {
  final io = Console();

  io.components.info('Status', 'Ready');
  io.components.bulletList(['One', 'Two', 'Three']);

  final result = await io.components.spin(
    'Working...',
    run: () async {
      await Future.delayed(const Duration(milliseconds: 200));
      return 42;
    },
  );

  io.writeln('Result: $result');
}
```

## Common Helpers

- `info`, `success`, `warn`, `error`, `comment`
- `alert`
- `twoColumnDetail`, `definitionList`, `horizontalTable`
- `bulletList`, `line`, `rule`
- `spin`, `textArea`
- `renderException`

## Text Area Prompt

```dart
import 'package:artisanal/artisanal.dart';
import 'package:artisanal/bubbles.dart';

Future<void> main() async {
  final io = Console();
  final model = TextAreaModel(placeholder: 'Notes...');

  final value = await io.components.textArea(
    model,
    options: textareaPromptOptions,
  );

  io.components.comment(value ?? 'No input');
}
```

## Gotchas

- Many helpers add their own newlines; avoid double spacing.
- `spin()` falls back to non-animated output when `interactive` is false.
- `line()` and `rule()` use terminal width to size their output.

## Related Docs

- [DOCS_INDEX.md](DOCS_INDEX.md) - Full documentation index
- [CONSOLE.md](CONSOLE.md)
- [BUBBLES.md](BUBBLES.md)
