/// Demonstrates Glamour themes through the unified MarkdownRenderer.
///
/// Instead of using the deprecated GlamourRenderer directly, this example
/// converts GlamourTheme to AnsiRendererOptions via the bridge and renders
/// through the unified MarkdownRenderer.
///
/// Run with: dart run example/glamour_demo.dart
library;

import 'package:artisanal/artisanal.dart';

const _sample = '''
# Glamour Themes

This demo shows **Glamour themes** rendered through the unified
`MarkdownRenderer` using `toAnsiRendererOptions()`.

## Available Themes

- **Dark** — default dark terminal theme
- **Light** — light terminal theme
- **Pink** — pink accent theme
- **ASCII** — plain ASCII compatible

## Features

> Blockquotes with styled borders and *italic* text.

- [x] Theme conversion via bridge
- [x] Syntax highlighting support
- [x] Custom width control
''';

void main() {
  print('');
  print(
    '\x1b[1m\x1b[96m═ Glamour Theme Demo (via MarkdownRenderer) ═══════════\x1b[0m',
  );
  print('');

  _renderTheme('Dark Theme', GlamourTheme.dark);
  _renderTheme('Light Theme', GlamourTheme.light);
  _renderTheme('Pink Theme', GlamourTheme.pink);
  _renderTheme('ASCII Theme', GlamourTheme.ascii);
}

void _renderTheme(String label, GlamourTheme theme) {
  print('\x1b[1m\x1b[93m$label\x1b[0m');
  print('\x1b[90m   theme.toAnsiRendererOptions()\x1b[0m');
  print('');

  // Convert theme to options and render through the unified pipeline
  final options = theme.toAnsiRendererOptions(width: 72);
  final result = MarkdownRenderer(options: options).renderToAnsi(_sample);

  print(result);
  print('');
}
