import 'dart:convert';
import 'dart:io';

import 'package:artisanal/glamour.dart';

import '_path_utils.dart';

void main() {
  final file = File(
    resolveArtisanalPath(<String>['example', 'glamour_styles', 'dark.json']),
  );
  if (!file.existsSync()) {
    print('Error: dark.json not found at ${file.path}');
    return;
  }

  final jsonContent = file.readAsStringSync();
  final jsonMap = jsonDecode(jsonContent) as Map<String, dynamic>;

  final theme = GlamourTheme.fromJson(jsonMap);

  print('Loaded theme successfully.');
  print('Document margin: ${theme.document.margin}');
  print('H1 prefix: "${theme.h1.style.prefix}"');
  print('H1 color: ${theme.h1.style.color}');

  final markdown = '''
# Hello JSON Theme
This is a paragraph.
- List item 1
- List item 2

```dart
void main() {
  print("Code block");
}
```
''';

  print('\nRendering with loaded theme:\n');
  print(renderStyle(markdown, theme: theme));
}
