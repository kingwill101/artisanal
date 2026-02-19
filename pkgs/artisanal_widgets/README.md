# artisanal_widgets

Flutter-inspired widget framework for terminal UIs, built on top of
`artisanal`.

## Table of Contents

- [Import](#import)
- [Quick start](#quick-start)
- [Architecture review](#architecture-review)
- [Flutter-style component ports](#flutter-style-component-ports)
- [Widget-specific examples](#widget-specific-examples)
- [Program Instrumentation](#program-instrumentation)
- [Tests](#tests)
- [Command execution note](#command-execution-note)

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

## Architecture review

See `ARCHITECTURE_REVIEW.md` for the current architecture/state analysis,
strengths, gaps/risks, and evidence references.

## Flutter-style component ports

- Chips: `Chip`, `ActionChip`, `ChoiceChip`, `FilterChip`, `InputChip`
- Menus: `DropdownButton`, `DropdownMenuItem`, `PopupMenuButton`,
  `PopupMenuItem`, `CheckedPopupMenuItem`, `PopupMenuDivider`
- Sliders: `Slider`, `RangeSlider`, `RangeValues`
- Indicators: `LinearProgressIndicator`, `CircularProgressIndicator`
- Charts: `SparklineChart`, `LineChart`, `BarChart`, `HeatmapChart`,
  `PieChart`, `RibbonChart` with optional in-chart legends

## Widget-specific examples

Run from workspace root:

```bash
dart run pkgs/artisanal_widgets/example/chip/main.dart
dart run pkgs/artisanal_widgets/example/action_chip/main.dart
dart run pkgs/artisanal_widgets/example/choice_chip/main.dart
dart run pkgs/artisanal_widgets/example/filter_chip/main.dart
dart run pkgs/artisanal_widgets/example/input_chip/main.dart
dart run pkgs/artisanal_widgets/example/dropdown_button/main.dart
dart run pkgs/artisanal_widgets/example/slider/main.dart
dart run pkgs/artisanal_widgets/example/range_slider/main.dart
dart run pkgs/artisanal_widgets/example/linear_progress_indicator/main.dart
dart run pkgs/artisanal_widgets/example/circular_progress_indicator/main.dart
dart run pkgs/artisanal_widgets/example/popup_menu_button/main.dart
dart run pkgs/artisanal_widgets/example/charting/main.dart
dart run pkgs/artisanal_widgets/example/opencode/main.dart
```

The OpenCode example is self-contained under
`pkgs/artisanal_widgets/example/opencode` (including local data models and
theme assets).

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

See `docs/TUI.md` for full interceptor/replay API details.

## Tests

Component tests are split by widget under
`pkgs/artisanal_widgets/test/components/*_test.dart`.

Useful commands:

```bash
dart test pkgs/artisanal_widgets/test/components
dart test pkgs/artisanal_widgets
dart analyze pkgs/artisanal_widgets
```

## Command execution note

When combining commands that include runtime-managed commands (`EveryCmd`,
`StreamCmd`, or helpers like `every(...)`), use `ParallelCmd` so those commands
are started by `Program`.

Use `Cmd.batch(...)` for finite commands that only need `execute()`.
