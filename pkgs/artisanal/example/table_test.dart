import 'package:artisanal/artisanal.dart';

void main() {
  final md = """
## Tables

| Name | Age | City |
|------|-----|------|
| Alice | 30 | New York |
| Bob | 25 | Los Angeles |
| Charlie | 35 | Chicago |

## Code Blocks

```dart
String markdownToAnsi(
  String markdown, {
  AnsiRendererOptions? options,
})
```

```javascript
function fibonacci(n) {
  if (n <= 1) return n;
  return fibonacci(n - 1) + fibonacci(n - 2);
}
```
""";
  print(markdownToAnsi(md));
}
