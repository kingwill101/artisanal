# Artisanal

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Documentation](https://img.shields.io/badge/docs-ormed.vercel.app-blue)](https://ormed.vercel.app/)
[![Buy Me A Coffee](https://img.shields.io/badge/Buy%20Me%20A%20Coffee-support-yellow?logo=buy-me-a-coffee)](https://www.buymeacoffee.com/kingwill101)

Build polished command-line tools and interactive terminal applications in
Dart with one consistent toolkit.

Artisanal brings together high-level CLI output, Lip Gloss-inspired styling, a
Bubble Tea-style runtime, reusable Bubbles, a widget framework, and the
Ultraviolet cell-buffer renderer.

## Table of contents

- [Overview](#overview)
- [Installation](#installation)
- [Quick start](#quick-start)
  - [CLI output](#cli-output)
  - [Styling](#styling)
  - [Interactive TUI](#interactive-tui)
- [Toolkit](#toolkit)
  - [Console helpers](#console-helpers)
  - [Command runner](#command-runner)
  - [Bubbles](#bubbles)
  - [Ultraviolet renderer](#ultraviolet-renderer)
  - [Replay and trace debugging](#replay-and-trace-debugging)
- [Library entrypoints](#library-entrypoints)
- [Examples and gallery](#examples-and-gallery)
  - [CLI walkthroughs](#cli-walkthroughs)
  - [Full demo captures](#full-demo-captures)
  - [Static screenshots](#static-screenshots)
- [Documentation and support](#documentation-and-support)

## Overview

| Feature | Description |
|---------|-------------|
| **CLI I/O** | High-level `Console` helpers for status lines, tables, tasks, prompts, and styled output |
| **Styling** | Fluent, immutable `Style` API with colors, borders, padding, margins, and themes |
| **TUI Runtime** | Elm Architecture (`Model`/`Msg`/`Cmd`) with a full-featured `Program` event loop |
| **Bubbles** | 20+ reusable widgets: inputs, lists, tables, spinners, progress bars, file pickers, etc. |
| **Ultraviolet (UV)** | High-performance cell-buffer renderer with diff-based updates and graphics support |
| **Terminal + Renderer** | Unified terminal abstraction, ANSI helpers, and renderer backends |
| **Markdown** | ANSI Markdown renderer plus Glamour high-fidelity output |
| **Charting** | Sparklines, line/ribbon charts, histograms, heatmaps, and pie charts |

## Installation

Add Artisanal to your project:

```bash
dart pub add artisanal
```

Or add it to `pubspec.yaml`:

```yaml
dependencies:
  artisanal: ^0.5.0
```

For widget-only applications, depend on `artisanal_widgets` directly. Use
`artisanal` when you want the broader CLI, style, runtime, and rendering stack.

## Quick start

### CLI output

#### Minimal example

```dart
import 'package:artisanal/artisanal.dart';

void main() {
  final io = Console();

  io.title('Minimal Artisanal CLI');
  io.info('Starting up...');
  io.success('Ready to ship.');
}
```

Run the included example from the repository root:

```bash
dart run pkgs/artisanal/example/minimal_cli.dart
```

![Minimal Artisanal CLI](https://github.com/kingwill101/artisanal/raw/artisanal/pkgs/artisanal/assets/minimal_cli.gif)

#### Complete CLI flow

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

![CLI Output](images/console_quickstart.png)

### Styling

```dart
import 'package:artisanal/style.dart';

final style = Style()
    .bold()
    .foreground(Colors.purple)
    .padding(1, 2)
    .border(Border.rounded);

print(style.render('Hello, Artisanal!'));
```

![Hello artisanal](images/hello.png)

#### Style capabilities

- **Text effects**: `bold()`, `italic()`, `underline()`, `strikethrough()`, `dim()`, `inverse()`, `blink()`
- **Colors**: ANSI 16, ANSI 256, TrueColor (RGB), `AdaptiveColor` (light/dark aware)
- **Spacing**: `padding()`, `margin()`
- **Borders**: `rounded`, `thick`, `double`, `hidden`, custom
- **Alignment**: `align()`, `alignVertical()`
- **Dimensions**: `width()`, `height()`, `maxWidth()`, `maxHeight()`
- **Themes**: `ThemePalette` with presets (dark, light, ocean, nord, dracula, monokai, solarized)

### Interactive TUI

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
  String view() => 'Count: $count\n\nUse ↑/↓ to change, q to quit';
}

Future<void> main() async {
  await runProgram(CounterModel());
}
```

## Toolkit

### Console helpers

| Category | Methods |
|----------|---------|
| **Output** | `writeln()`, `write()`, `title()`, `section()` |
| **Messages** | `line()`, `info()`, `comment()`, `question()`, `warn()`, `error()`, `note()`, `caution()`, `alert()`, `verbose()`, `debug()` |
| **Layout** | `table()`, `tree()`, `listing()`, `twoColumnDetail()`, `text()` |
| **Interactive** | `ask()`, `confirm()`, `choice()`, `secret()`, `selectChoice()`, `multiSelectChoice()`, `menu()`, `search()` |
| **Progress** | `task()`, `spin()`, `progress()`, `progressIterate()` |

### Command runner

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

void main(List<String> args) async {
  final runner = CommandRunner('my-cli', 'A great CLI');
  runner.addCommand(HelloCommand());
  await runner.run(args);
}
```

![Command Runner](images/command_runner.png)

### Bubbles

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

### Ultraviolet renderer

High-performance rendering with diff-based updates for flicker-free TUI
applications:

```dart
await runProgram(
  MyModel(),
  options: const ProgramOptions(
    useUltravioletRenderer: true,
    useUltravioletInputDecoder: true,
    altScreen: true,
    mouse: true,
  ),
);
```

#### UV features

- 2D cell buffer with styled cells
- Diff-based terminal updates (minimal redraws)
- Layer composition and hit-testing
- Reusable color, CRT, scanline, distortion, and persistence effects through
  `BufferRenderSink`
- Mouse support and focus events
- Graphics: Kitty, Sixel, iTerm2, half-block drawing

### Replay and trace debugging

The TUI runtime supports deterministic replay (`ProgramReplay`) and built-in
file tracing (`TuiTrace`) for debugging and profiling.

Enable tracing for any TUI app:

```bash
ARTISANAL_TUI_TRACE=1 ARTISANAL_TUI_TRACE_CAPTURE=1 \
ARTISANAL_TUI_TRACE_PATH=traces/my-run.log \
dart run your_app.dart
```

Structured app/domain events can be emitted via `TuiTrace.event(...)` and are
preserved in replay conversion when they use stable typed `type` names.

See the [TUI documentation](../../docs/tui.md) for replay and tracing details.

## Library entrypoints

Choose the smallest public library that covers your use case:

| Import | Purpose |
|--------|---------|
| `package:artisanal/artisanal.dart` | Umbrella API for CLI output, styling, charting, Markdown, app runners, hosts, plugins, and common terminal types |
| `package:artisanal/args.dart` | Command runner utilities (`CommandRunner`, `Command`) |
| `package:artisanal/bubbles.dart` | Reusable TEA widgets |
| `package:artisanal/catalog.dart` | Public metadata registry for Bubbles and display components |
| `package:artisanal/style.dart` | Styles, colors, borders, layout, and themes |
| `package:artisanal/tui.dart` | TEA runtime (`Model`, `Msg`, `Cmd`, `Program`) plus replay and tracing |
| `package:artisanal/terminal.dart` | Terminal abstraction, ANSI helpers, keys, backends, and bridges |
| `package:artisanal/widgets.dart` | Convenience re-export of the widget framework |
| `package:artisanal/testing.dart` | Widget testing helpers |
| `package:artisanal/editor_core.dart` | Low-level text document, editor state, and viewport primitives |
| `package:artisanal/glamour.dart` | High-fidelity Markdown rendering |
| `package:artisanal/uv.dart` | Compatibility re-export of Ultraviolet types |
| `package:artisanal/compat.dart` | Backward-compatible API shims |

Widget-first applications can import `package:artisanal_widgets/...` directly.
Renderer-level applications can import
`package:ultraviolet/ultraviolet.dart` directly.

## Examples and gallery

See the `example/` directory for comprehensive demos:

- `main.dart` – Full feature showcase
- `minimal_cli.dart` – Minimal CLI output example
- `widget_catalog.dart` – Searchable component catalog and theme showcase
- `fluent_style_example.dart` – Style API patterns
- `spinner_demo.dart` – Various spinner types
- `lipgloss_table.dart` – Styled tables
- `log_viewer_demo.dart` – Monitoring dashboard
- `command_center_demo.dart` – Multi-panel layouts
- `tui/examples/uv-effects/main.dart` – Applying UV effects to a canvas buffer
- Additional engine-specific demos live in `pkgs/ultraviolet/example/`

Commands in this gallery assume the repository root as the working directory.

### CLI walkthroughs

The small CLI tapes focus on one interaction at a time and keep the matching
command immediately beside its recording.

**Tables** (`example/.vhs/cli_table.tape`):

```bash
dart run pkgs/artisanal/example/main.dart ui:table --ansi
```

![CLI table](https://github.com/kingwill101/artisanal/raw/artisanal/pkgs/artisanal/assets/cli_table.gif)

**Prompts** (`example/.vhs/cli_prompts.tape`):

```bash
dart run pkgs/artisanal/example/main.dart ui:prompts --defaults --no-interaction --ansi
```

![CLI prompts](https://github.com/kingwill101/artisanal/raw/artisanal/pkgs/artisanal/assets/cli_prompts.gif)

**Display components** (`example/.vhs/cli_components.tape`):

```bash
dart run pkgs/artisanal/example/main.dart ui:components --ansi
```

![CLI components](https://github.com/kingwill101/artisanal/raw/artisanal/pkgs/artisanal/assets/cli_components.gif)

**Progress** (`example/.vhs/cli_progress.tape`):

```bash
dart run pkgs/artisanal/example/main.dart ui:progress --count 40 --ansi
```

![CLI progress](https://github.com/kingwill101/artisanal/raw/artisanal/pkgs/artisanal/assets/cli_progress.gif)

### Full demo captures

Recordings of the more consequential examples, regenerated from the VHS tapes
in [`example/.vhs/`](example/.vhs/README.md) with `task artisanal-demos`:

**Markdown renderer** (`example/markdown_demo.dart`):

![Markdown demo](https://github.com/kingwill101/artisanal/raw/artisanal/pkgs/artisanal/assets/markdown_demo.gif)

**Glamour themes** (`example/glamour_demo.dart`):

![Glamour demo](https://github.com/kingwill101/artisanal/raw/artisanal/pkgs/artisanal/assets/glamour_demo.gif)

**CLI runner showcase** (`example/main.dart`):

![Main demo](https://github.com/kingwill101/artisanal/raw/artisanal/pkgs/artisanal/assets/main.gif)

**Lip Gloss TUI** (`example/lipgloss_tui.dart`):

![Lip Gloss TUI](https://github.com/kingwill101/artisanal/raw/artisanal/pkgs/artisanal/assets/lipgloss_tui.gif)

**Spinners** (`example/spinner_demo.dart`):

![Spinner demo](https://github.com/kingwill101/artisanal/raw/artisanal/pkgs/artisanal/assets/spinner_demo.gif)

**Log viewer** (`example/log_viewer_demo.dart`):

![Log viewer demo](https://github.com/kingwill101/artisanal/raw/artisanal/pkgs/artisanal/assets/log_viewer_demo.gif)

**Split dashboard** (`example/split_dashboard_demo.dart`):

![Split dashboard demo](https://github.com/kingwill101/artisanal/raw/artisanal/pkgs/artisanal/assets/split_dashboard_demo.gif)

**Command center** (`example/command_center_demo.dart`):

![Command center demo](https://github.com/kingwill101/artisanal/raw/artisanal/pkgs/artisanal/assets/command_center_demo.gif)

**Data table** (`example/data_table_demo.dart`):

![Data table demo](https://github.com/kingwill101/artisanal/raw/artisanal/pkgs/artisanal/assets/data_table_demo.gif)

**Sequence diagram** (`example/sequence_diagram_demo.dart`):

![Sequence diagram demo](https://github.com/kingwill101/artisanal/raw/artisanal/pkgs/artisanal/assets/sequence_diagram_demo.gif)

### Static screenshots

**Log viewer**

![Log Viewer](images/log_viewer.png)

**Console tags**

![Console Tags](images/console_tags.png)

**Layout**

![Layout](images/layout.png)

## Documentation and support

- Start with the [documentation index](../../docs/docs_index.md).
- Browse the runnable examples in [`example/`](example/README.md).
- Report bugs or outdated examples in the
  [issue tracker](https://github.com/kingwill101/artisanal/issues).

Artisanal is a Dart port of Charm's
[Lip Gloss](https://github.com/charmbracelet/lipgloss),
[Bubble Tea](https://github.com/charmbracelet/bubbletea), and
[Bubbles](https://github.com/charmbracelet/bubbles). The project aims for broad
parity, but some behavior may still differ from the Go originals. Reports with
small reproductions are especially helpful.
