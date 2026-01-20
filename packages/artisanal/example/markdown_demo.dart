/// Demonstrates the markdown to ANSI renderer.
///
/// Run with: dart run example/markdown_demo.dart
library;

import 'package:artisanal/markdown.dart';
import 'package:artisanal/src/style/border.dart';
import 'package:artisanal/src/style/color.dart';
import 'package:artisanal/src/style/style.dart';

void main() {
  _printHeader();
  _demoBasicMarkdown();
  _demoAdaptiveThemes();
  _demoTables();
  _demoApiDocumentation();
  _demoChangelog();
  _demoProjectStatus();
}

void _printHeader() {
  print('');
  final title = Style()
      .bold()
      .foreground(Colors.brightCyan)
      .render('✨ Artisanal Markdown Renderer Demo ✨');
  print(title);
  print(Style().dim().render('━' * 50));
  print('');
}

void _demoBasicMarkdown() {
  _section('Basic Markdown Features');

  const markdown = '''
# Welcome to Artisanal

A powerful **markdown-to-ANSI** renderer for beautiful terminal output.

## Key Features

- **Bold**, *italic*, and ***bold italic*** text
- `inline code` with syntax highlighting
- ~~strikethrough~~ for deletions
- [Hyperlinks](https://github.com) with OSC 8 support

### Task Lists

- [x] Headings (h1-h6)
- [x] Text formatting
- [x] Code blocks with language hints
- [x] Tables with borders
- [ ] Syntax highlighting (coming soon)

### Blockquotes

> "The terminal is a canvas, and ANSI codes are our paint."
>
> — *Anonymous Developer*

### Code Example

```dart
void main() {
  final renderer = AnsiRenderer();
  print(renderer.render(markdown));
}
```

---
''';

  print(markdownToAnsi(markdown));
}

void _demoAdaptiveThemes() {
  _section('Adaptive Syntax Themes');

  const codeMarkdown = '''
## Syntax Highlighting with Adaptive Themes

The renderer automatically selects dark or light syntax themes based on terminal background.

```dart
// Dart code example
class Person {
  final String name;
  final int age;
  
  Person(this.name, this.age);
  
  String greet() => 'Hello, I am \$name!';
  
  @override
  String toString() => 'Person(\$name, \$age)';
}

void main() {
  final people = [
    Person('Alice', 30),
    Person('Bob', 25),
  ];
  
  for (final person in people) {
    print(person.greet());
  }
}
```

```python
# Python code example
from dataclasses import dataclass
from typing import List

@dataclass
class Person:
    name: str
    age: int
    
    def greet(self) -> str:
        return f"Hello, I am {self.name}!"

def main():
    people: List[Person] = [
        Person("Alice", 30),
        Person("Bob", 25),
    ]
    
    for person in people:
        print(person.greet())

if __name__ == "__main__":
    main()
```
''';

  // Dark background (default)
  print(
    Style()
        .bold()
        .foreground(Colors.yellow)
        .render('Dark Background Theme (default)'),
  );
  print(
    markdownToAnsi(
      codeMarkdown,
      options: const AnsiRendererOptions(
        hasDarkBackground: true, // Uses ChromaTheme.dark
      ),
    ),
  );
  print('');

  // Light background
  print(
    Style().bold().foreground(Colors.yellow).render('Light Background Theme'),
  );
  print(
    markdownToAnsi(
      codeMarkdown,
      options: const AnsiRendererOptions(
        hasDarkBackground: false, // Uses ChromaTheme.light
      ),
    ),
  );
  print('');

  // Specific adaptive theme pairings
  _section('Theme Pairings');

  const themeDemo = '''
```javascript
// JavaScript example
const fibonacci = (n) => {
  if (n <= 1) return n;
  return fibonacci(n - 1) + fibonacci(n - 2);
};

const results = Array.from({ length: 10 }, (_, i) => fibonacci(i));
console.log('Fibonacci:', results);
```
''';

  print(
    Style()
        .bold()
        .foreground(Colors.cyan)
        .render('Dracula (dark) / GitHub (light)'),
  );
  print(
    markdownToAnsi(
      themeDemo,
      options: AnsiRendererOptions(
        syntaxTheme: AdaptiveChromaTheme.draculaGithub.dark,
      ),
    ),
  );

  print(Style().bold().foreground(Colors.cyan).render('Monokai (dark)'));
  print(
    markdownToAnsi(
      themeDemo,
      options: AnsiRendererOptions(syntaxTheme: ChromaTheme.monokai),
    ),
  );

  print(Style().bold().foreground(Colors.cyan).render('Nord (arctic colors)'));
  print(
    markdownToAnsi(
      themeDemo,
      options: AnsiRendererOptions(syntaxTheme: ChromaTheme.nord),
    ),
  );

  print(Style().bold().foreground(Colors.cyan).render('Gruvbox Dark'));
  print(
    markdownToAnsi(
      themeDemo,
      options: AnsiRendererOptions(syntaxTheme: ChromaTheme.gruvboxDark),
    ),
  );

  print(Style().bold().foreground(Colors.cyan).render('Solarized Dark'));
  print(
    markdownToAnsi(
      themeDemo,
      options: AnsiRendererOptions(syntaxTheme: ChromaTheme.solarizedDark),
    ),
  );

  print(
    Style().bold().foreground(Colors.cyan).render('One Dark (Atom-inspired)'),
  );
  print(
    markdownToAnsi(
      themeDemo,
      options: AnsiRendererOptions(syntaxTheme: ChromaTheme.oneDark),
    ),
  );
}

void _demoTables() {
  _section('Table Rendering Styles');

  const tableData = '''
| Language   | Type    | Year | Popular For          |
|------------|---------|------|----------------------|
| Dart       | Static  | 2011 | Flutter, Web         |
| Rust       | Static  | 2010 | Systems, WebAssembly |
| Go         | Static  | 2009 | Cloud, DevOps        |
| TypeScript | Static  | 2012 | Web, Node.js         |
| Python     | Dynamic | 1991 | AI/ML, Scripting     |
''';

  // Rounded (default)
  print(
    Style()
        .bold()
        .foreground(Colors.yellow)
        .render('╭─ Rounded Border (Default)'),
  );
  print(markdownToAnsi(tableData));
  print('');

  // Double border with styled headers
  print(
    Style()
        .bold()
        .foreground(Colors.yellow)
        .render('╔═ Double Border + Cyan Headers'),
  );
  print(
    markdownToAnsi(
      tableData,
      options: AnsiRendererOptions(
        tableBorder: Border.double,
        tableHeaderStyle: Style().bold().foreground(Colors.brightCyan),
        tableBorderStyle: Style().foreground(Colors.blue),
      ),
    ),
  );
  print('');

  // ASCII for compatibility
  print(
    Style()
        .bold()
        .foreground(Colors.yellow)
        .render('+- ASCII Border (Compatible)'),
  );
  print(
    markdownToAnsi(
      tableData,
      options: AnsiRendererOptions(
        tableBorder: Border.ascii,
        tableHeaderStyle: Style().bold(),
      ),
    ),
  );
  print('');

  // Thick border
  print(
    Style()
        .bold()
        .foreground(Colors.yellow)
        .render('┏━ Thick Border + Green Theme'),
  );
  print(
    markdownToAnsi(
      tableData,
      options: AnsiRendererOptions(
        tableBorder: Border.thick,
        tableHeaderStyle: Style().bold().foreground(Colors.brightGreen),
        tableBorderStyle: Style().foreground(Colors.green),
      ),
    ),
  );
}

void _demoApiDocumentation() {
  _section('API Documentation Style');

  const apiDoc = '''
## `markdownToAnsi()`

Converts markdown to ANSI-styled terminal output.

### Signature

```dart
String markdownToAnsi(
  String markdown, {
  AnsiRendererOptions? options,
})
```

### Parameters

| Parameter  | Type                   | Required | Description                    |
|------------|------------------------|----------|--------------------------------|
| `markdown` | `String`               | Yes      | The markdown content to render |
| `options`  | `AnsiRendererOptions?` | No       | Customization options          |

### Options

| Option             | Type      | Default   | Description                |
|--------------------|-----------|-----------|----------------------------|
| `tableBorder`      | `Border?` | `rounded` | Table border style         |
| `tableHeaderStyle` | `Style?`  | `bold()`  | Style for table headers    |
| `hyperlinks`       | `bool`    | `true`    | Enable OSC 8 hyperlinks    |
| `codeBlockBorder`  | `bool`    | `true`    | Draw borders on code blocks|

### Example

```dart
final output = markdownToAnsi(
  '# Hello World\nThis is **bold** and *italic*.',
);
print(output);
```

### Returns

A `String` containing ANSI escape sequences for terminal rendering.
''';

  print(
    markdownToAnsi(
      apiDoc,
      options: AnsiRendererOptions(
        tableBorder: Border.rounded,
        tableHeaderStyle: Style().bold().foreground(Colors.cyan),
        h2Style: Style().bold().foreground(Colors.brightMagenta),
        h3Style: Style().bold().foreground(Colors.magenta),
        codeStyle: Style()
            .foreground(Colors.brightYellow)
            .background(Colors.gray900),
      ),
    ),
  );
}

void _demoChangelog() {
  _section('Changelog Style');

  const changelog = '''
# Changelog

## [2.0.0] - 2025-01-19

### ✨ Added
- **Table rendering** with proper borders using artisanal's Table component
- Customizable table styles: `tableBorder`, `tableHeaderStyle`, `tableBorderStyle`
- Support for rounded, double, thick, and ASCII border styles

### 🔧 Changed
- Tables now render with visual borders instead of tab-separated values
- Improved cell content handling for inline formatting

### 🐛 Fixed
- Text wrapping issues in table cells
- State reset between multiple render calls

---

## [1.5.0] - 2025-01-15

### ✨ Added
- OSC 8 hyperlink support for clickable links
- Task list checkbox rendering (☑/☐)
- Nested blockquote support

### 📝 Documentation
- Added comprehensive test fixtures
- Updated API documentation

| Version | Release Date | Highlights                    |
|---------|--------------|-------------------------------|
| 2.0.0   | 2025-01-19   | Table borders, custom styles  |
| 1.5.0   | 2025-01-15   | Hyperlinks, task lists        |
| 1.0.0   | 2025-01-01   | Initial release               |
''';

  print(
    markdownToAnsi(
      changelog,
      options: AnsiRendererOptions(
        h1Style: Style().bold().foreground(Colors.brightCyan),
        h2Style: Style().bold().foreground(Colors.cyan),
        h3Style: Style().bold().foreground(Colors.blue),
        tableBorder: Border.rounded,
        tableHeaderStyle: Style().bold().foreground(Colors.brightYellow),
      ),
    ),
  );
}

void _demoProjectStatus() {
  _section('Project Dashboard');

  const dashboard = '''
# 📊 Project Status Dashboard

## Build Status

| Service    | Status | Uptime  | Response |
|------------|--------|---------|----------|
| API Server | ✅ UP  | 99.99%  | 45ms     |
| Database   | ✅ UP  | 99.95%  | 12ms     |
| Cache      | ✅ UP  | 100%    | 2ms      |
| CDN        | ⚠️ DEG | 98.5%   | 125ms    |
| Worker     | ❌ DOWN| 85.2%   | N/A      |

## Recent Deployments

| Environment | Version | Deployed          | By         |
|-------------|---------|-------------------|------------|
| Production  | v2.4.1  | 2025-01-19 14:30  | @alice     |
| Staging     | v2.5.0  | 2025-01-19 16:45  | @bob       |
| Development | v2.5.1  | 2025-01-19 17:22  | @charlie   |

## Performance Metrics

> **Note:** All metrics are from the last 24 hours.

| Metric              | Value    | Change  | Status |
|---------------------|----------|---------|--------|
| Requests/sec        | 12,450   | +15%    | 📈     |
| Avg Response Time   | 89ms     | -8%     | 📉     |
| Error Rate          | 0.02%    | -50%    | ✅     |
| Active Users        | 8,234    | +22%    | 📈     |
| Memory Usage        | 68%      | +5%     | ⚠️     |

---

*Dashboard updated: 2025-01-19 18:00 UTC*
''';

  print(
    markdownToAnsi(
      dashboard,
      options: AnsiRendererOptions(
        h1Style: Style().bold().foreground(Colors.brightWhite),
        h2Style: Style().bold().foreground(Colors.brightCyan),
        tableBorder: Border.rounded,
        tableHeaderStyle: Style().bold().foreground(Colors.brightGreen),
        tableBorderStyle: Style().foreground(Colors.gray),
        blockquoteStyle: Style().italic().foreground(Colors.yellow),
        blockquoteBorderColor: Colors.yellow,
      ),
    ),
  );

  print('');
  print(Style().dim().render('━' * 50));
  print(
    Style().dim().italic().render(
      '  Demo complete! Run: dart run example/markdown_demo.dart',
    ),
  );
  print('');
}

void _section(String title) {
  print('');
  print(
    Style()
        .bold()
        .foreground(Colors.brightWhite)
        .background(Colors.blue)
        .render(' $title '),
  );
  print('');
}
