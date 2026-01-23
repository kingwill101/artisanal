import 'dart:io';
import 'package:artisanal/glamour.dart';

void main() {
  const markdown = '''
# Glamour Style Test

## All Available Themes

Testing all glamour themes with the same markdown content.

## Inline Formatting

This is **bold** and this is *italic*.
This is ~~strikethrough~~ text.
Inline `code` looks like this.

## Lists

* Unordered list item 1
* Unordered list item 2
  * Nested item 2.1
  * Nested item 2.2

1. Ordered list item 1
2. Ordered list item 2
3. Ordered list item 3

## Task Lists

* [x] Completed task
* [ ] Pending task
* [x] Another completed task

## Tables

| Feature | Status | Description |
|---------|--------|-------------|
| Bold    | ✓      | **bold** text works |
| Italic  | ✓      | *italic* text works |
| Code    | ✓      | `code` in tables |
| Link    | ✓      | [link](url) here |

## Blockquotes

> This is a blockquote.
> It can have multiple lines.
>
> > And can be nested!

## Links

Visit [GitHub](https://github.com) for more info.
Check out [Dart](https://dart.dev) too.

---

End of test.
''';

  // List of all available themes
  final themes = [
    'ascii',
    'dark',
    'light',
    'notty',
    'pink',
    'dracula',
    'tokyo-night',
  ];

  // Load JSON style files if they exist
  for (final theme in themes) {
    print('=== $theme Theme ===\n');
    try {
      final stylePath = 'example/glamour_styles/$theme.json';
      final styleFile = File(stylePath);
      if (styleFile.existsSync()) {
        final styleContent = styleFile.readAsStringSync();
        // Note: Currently GlamourTheme.fromJson is used in renderer
        // In a full implementation, we'd pass the JSON content
      }
    } catch (e) {
      // If JSON file doesn't exist or has issues, try built-in theme
    }

    // Render with the theme
    // For now, use built-in themes that match
    GlamourTheme selectedTheme;
    switch (theme) {
      case 'ascii':
        selectedTheme = GlamourTheme.ascii;
        break;
      case 'dark':
        selectedTheme = GlamourTheme.dark;
        break;
      case 'light':
        selectedTheme = GlamourTheme.light;
        break;
      case 'notty':
        selectedTheme = GlamourTheme.ascii; // Use ascii for notty
        break;
      case 'pink':
        selectedTheme = GlamourTheme.pink;
        break;
      default:
        selectedTheme = GlamourTheme.dark; // Fallback
    }

    print(renderStyle(markdown, theme: selectedTheme));
  }
}
