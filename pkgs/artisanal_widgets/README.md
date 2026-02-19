# artisanal_widgets

Flutter-inspired widget framework for terminal UIs, built on top of
`artisanal`.

## Table of Contents

- [Installation](#installation)
- [Import](#import)
- [Quick start](#quick-start)
- [Flutter-style component ports](#flutter-style-component-ports)
- [Program Instrumentation](#program-instrumentation)
- [Tests](#tests)
- [Command execution note](#command-execution-note)

## Installation

```yaml
dependencies:
  artisanal_widgets: ^0.1.0
```

## Import

```dart
import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:artisanal/tui.dart' as tui;
```

## Quick start

```dart
class HelloApp extends StatelessWidget {
  HelloApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Hello widgets', style: theme.titleLarge),
        Text('Press q to quit', style: theme.bodyMedium),
      ],
    );
  }
}

void main() async {
  final app = tui.WidgetApp(HelloApp());

  await tui.runProgram(app);
}
```

## Flutter-style component ports

- Chips: `Chip`, `ActionChip`, `ChoiceChip`, `FilterChip`, `InputChip`
- Menus: `DropdownButton`, `DropdownMenuItem`, `PopupMenuButton`,
  `PopupMenuItem`, `CheckedPopupMenuItem`, `PopupMenuDivider`
- Sliders: `Slider`, `RangeSlider`, `RangeValues`
- Indicators: `LinearProgressIndicator`, `CircularProgressIndicator`
- Charts: `SparklineChart`, `LineChart`, `BarChart`, `HeatmapChart`,
  `PieChart`, `RibbonChart` with optional in-chart legends

![Charts](images/charting.png)
The OpenCode example is self-contained under
`example/opencode` (including local data models and theme assets).

![OpenCode Clone](images/opencode_clone.png)
![OpenCode Clone 2](images/opencode_clone2.png)
![Panel Box](images/panel_box.png)

## Program Instrumentation

The core TUI runtime (`Program`) supports general instrumentation and automation
for any app (not OpenCode-specific):

- `ProgramInterceptor` for message interception/timing hooks.
- `ProgramReplay` for deterministic event playback.

```dart
import 'package:artisanal/tui.dart' as tui;

final replay = tui.ProgramReplay.script([
  tui.ProgramReplayStep(
    after: Duration(milliseconds: 120),
    msg: tui.KeyMsg(tui.Key(tui.KeyType.runes, runes: [0x61])),
  ),
  tui.ProgramReplayStep(after: Duration(milliseconds: 16), msg: tui.QuitMsg()),
]);

await tui.runProgram(
  tui.WidgetApp(MyApp()),
  options: tui.ProgramOptions(replay: replay),
);
```

See the `package:artisanal/tui.dart` API docs for full interceptor/replay details.

## Tests

Component tests are split by widget under
`test/components/*_test.dart`.

Useful commands:

```bash
dart test test/components
dart test
dart analyze
```

## Command execution note

When combining commands that include runtime-managed commands (`EveryCmd`,
`StreamCmd`, or helpers like `every(...)`), use `ParallelCmd` so those commands
are started by `Program`.

Use `Cmd.batch(...)` for finite commands that only need `execute()`.
