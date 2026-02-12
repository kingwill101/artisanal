# artisanal_widgets

Flutter-inspired widget framework for terminal UIs, built on top of
`artisanal`.

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
```

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
