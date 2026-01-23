# artisanal

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Documentation](https://img.shields.io/badge/docs-ormed.vercel.app-blue)](https://ormed.vercel.app/)
[![Buy Me A Coffee](https://img.shields.io/badge/Buy%20Me%20A%20Coffee-support-yellow?logo=buy-me-a-coffee)](https://www.buymeacoffee.com/kingwill101)

A full-stack terminal toolkit for Dart, inspired by popular Go terminal libraries: [Lip Gloss](https://github.com/charmbracelet/lipgloss) (styling), [Bubble Tea](https://github.com/charmbracelet/bubbletea) (TUI framework), and [Bubbles](https://github.com/charmbracelet/bubbles) (reusable widgets).

Build everything from rich command-line tools to complex interactive TUI applications with a consistent, idiomatic Dart API.

## Features

| Feature | Description |
|---------|-------------|
| **CLI I/O** | High-level `Console` helpers for status lines, tables, tasks, prompts, and styled output |
| **Styling** | Fluent, immutable `Style` API with colors, borders, padding, margins, and themes |
| **TUI Runtime** | Elm Architecture (`Model`/`Msg`/`Cmd`) with a full-featured `Program` event loop |
| **Bubbles** | 20+ reusable widgets: inputs, lists, tables, spinners, progress bars, file pickers, etc. |
| **Ultraviolet (UV)** | High-performance cell-buffer renderer with diff-based updates and graphics support |

## Installation

```yaml
dependencies:
  artisanal: ^0.1.2
```

> **Note**: This package uses workspace resolution. Use a path or git reference in standalone projects.

## Library Exports

| Import | Purpose |
|--------|---------|
| `package:artisanal/artisanal.dart` | Full CLI kit (Console, Style, Terminal, Layout) |
| `package:artisanal/args.dart` | Command runner utilities (`CommandRunner`, `Command`) |
| `package:artisanal/style.dart` | Styling, Layout, Colors, Borders, Themes |
| `package:artisanal/tui.dart` | TUI runtime: Model, Msg, Cmd, Program |
| `package:artisanal/bubbles.dart` | Reusable interactive widgets |
| `package:artisanal/terminal.dart` | Terminal abstraction, ANSI codes, Keys |
| `package:artisanal/uv.dart` | Low-level cell-buffer renderer |

## Quick Start: CLI Output

```dart
import 'package:artisanal/artisanal.dart';

Future<void> main() async {
  final io = Console();

  io.title('My App');
  io.section('Setup');
  io.info('Checking configuration...');

  await io.task('Running migrations', run: () async {
    await Future.delayed(const Duration(milliseconds: 200));
    return TaskResult.success;
  });

  io.table(
    headers: ['ID', 'Name', 'Status'],
    rows: [
      [1, 'users', io.style.success('DONE')],
      [2, 'posts', io.style.warning('PENDING')],
    ],
  );

  final proceed = io.confirm('Continue?', defaultValue: true);
  if (!proceed) return;

  io.success('All good.');
}
```

## Quick Start: Styling (Lip Gloss)

```dart
import 'package:artisanal/style.dart';

final style = Style()
    .bold()
    .foreground(Colors.purple)
    .padding(1, 2)
    .border(Border.rounded);

print(style.render('Hello, Artisanal!'));
```

### Style Capabilities

- **Text effects**: `bold()`, `italic()`, `underline()`, `strikethrough()`, `dim()`, `inverse()`, `blink()`
- **Colors**: ANSI 16, ANSI 256, TrueColor (RGB), `AdaptiveColor` (light/dark aware)
- **Spacing**: `padding()`, `margin()`
- **Borders**: `rounded`, `thick`, `double`, `hidden`, custom
- **Alignment**: `align()`, `alignVertical()`
- **Dimensions**: `width()`, `height()`, `maxWidth()`, `maxHeight()`
- **Themes**: `ThemePalette` with presets (dark, light, ocean, nord, dracula, monokai, solarized)

## Quick Start: TUI (Elm Architecture)

```dart
import 'package:artisanal/tui.dart';

class CounterModel implements Model {
  final int count;
  const CounterModel([this.count = 0]);

  @override
  Cmd? init() => null;

  @override
  (Model, Cmd?) update(Msg msg) {
    return switch (msg) {
      KeyMsg(key: Key(type: KeyType.up)) => (CounterModel(count + 1), null),
      KeyMsg(key: Key(type: KeyType.down)) => (CounterModel(count - 1), null),
      KeyMsg(key: Key(type: KeyType.runes, runes: [0x71])) => (this, Cmd.quit()),
      _ => (this, null),
    };
  }

  @override
  String view() => 'Count: \$count\n\nUse ↑/↓ to change, q to quit';
}

Future<void> main() async {
  await runProgram(CounterModel());
}
```

## Bubbles (Reusable Widgets)

| Widget | Description |
|--------|-------------|
| `TextInputModel` | Single-line text input |
| `TextAreaModel` | Multi-line text editing |
| `ListModel` | Filterable list selection |
| `TableModel` | Interactive tables |
| `ViewportModel` | Scrollable content pane |
| `ProgressModel` | Progress bars with ETA |
| `SpinnerModel` | Animated loading spinners |
| `FilePickerModel` | File/directory browser |
| `AnticipateModel` | Autocomplete with suggestions |
| `WizardModel` | Multi-step form wizard |
| `SelectModel<T>` | Single-choice selection prompt |
| `MultiSelectModel<T>` | Multiple-choice selection |
| `PasswordModel` | Masked password input |
| `TimerModel` | Countdown timer |
| `StopwatchModel` | Elapsed time tracking |
| `PaginatorModel` | Pagination controls |
| `HelpModel` | Key binding help views |

## Command Runner

Build CLI tools with styled help and nested commands:

```dart
import 'package:artisanal/args.dart';

class HelloCommand extends Command {
  @override
  String get name => 'hello';
  
  @override
  String get description => 'Say hello';

  @override
  void run() {
    io.success('Hello, world!');
  }
}

void main(List<String> args) {
  final runner = CommandRunner('my-cli', 'A great CLI');
  runner.addCommand(HelloCommand());
  runner.run(args);
}
```

## Ultraviolet Renderer

High-performance rendering with diff-based updates for flicker-free TUI applications:

```dart
await runProgram(
  MyModel(),
  options: const ProgramOptions(
    useUltravioletRenderer: true,
    useUltravioletInputDecoder: true,
    altScreen: true,
    mouseTracking: true,
  ),
);
```

### UV Features

- 2D cell buffer with styled cells
- Diff-based terminal updates (minimal redraws)
- Layer composition and hit-testing
- Mouse support and focus events
- Graphics: Kitty, Sixel, iTerm2, half-block drawing

## Console Methods

| Category | Methods |
|----------|---------|
| **Output** | `writeln()`, `write()`, `title()`, `section()` |
| **Messages** | `info()`, `success()`, `warning()`, `error()`, `note()`, `caution()` |
| **Layout** | `table()`, `tree()`, `listing()`, `twoColumnDetail()` |
| **Interactive** | `ask()`, `confirm()`, `choice()`, `secret()`, `selectChoice()`, `multiSelectChoice()` |
| **Progress** | `task()`, `progressBar()` |

## Examples

See the `example/` directory for comprehensive demos:

- `main.dart` – Full feature showcase
- `fluent_style_example.dart` – Style API patterns
- `spinner_demo.dart` – Various spinner types
- `lipgloss_table.dart` – Styled tables
- `log_viewer_demo.dart` – Monitoring dashboard
- `command_center_demo.dart` – Multi-panel layouts
- `uv_demo.dart` – Ultraviolet renderer basics
