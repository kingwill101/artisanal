---
name: artisanal-helper
description: Comprehensive guidance for creating reliable and polished CLIs, TUIs, and terminal applications using the Artisanal Dart package. Includes best practices for `commandRunner`, `UV`, `Style`, and `TUI` to ensure high-quality results.
---

# Artisanal Helper

Artisanal is a Dart terminal toolkit. Use `package:artisanal/...` imports.

## Quick triage

- CLI with subcommands or rich console output: use `package:artisanal/args.dart` and `package:artisanal/artisanal.dart`. Leverage `CommandRunner` for structured subcommands and `Console` for styled output.
- Interactive TUI (Elm-style Model/Update/View): use `package:artisanal/tui.dart` with `bubbles` widgets for input, lists, and tables. Combine `ProgramOptions` with `Model` and `Cmd` for seamless state management.
- High-performance rendering or custom terminal behaviors: use `package:artisanal/uv.dart` with `Compositor`, `Canvas`, and `Layer` for advanced terminal graphics and layouts.

See `references/exports.md` for entrypoints, `references/examples.md` for example map, and `references/api_reference.md` for API notes.

## Workflow

1. Pick the closest example and adapt it; start from TUI examples for dashboards/input or UV examples for custom rendering.
2. Keep the `Model` immutable and small; use helper functions for derived view data and avoid embedding logic in the `view` method.
3. Use `Cmd.tick`, `Cmd.batch`, or `every(...)` for live dashboards, periodic refresh, and handling asynchronous updates.
4. Prefer `bubbles` widgets like `TextInputModel`, `ListModel`, and `TableModel` for input, lists, tables, and viewports before resorting to custom drawing.
5. For CLI tools, wire `CommandRunner` with subcommands, use `Console` for styled output, and ensure proper error handling with non-zero exit codes.

## Task playbooks

### Create a nice log dashboard

- Start from `packages/artisanal/example/log_viewer_demo.dart`.
- Reuse viewport + list or table components; keep log lines as model data.
- Use `every(...)` to append new entries; gate auto-scroll with a "live" flag. Combine `ViewportModel` for efficient scrolling and rendering.

### Create a live dashboard

- Start from `packages/artisanal/example/tui/examples/realtime/main.dart`.
- Track data in the `Model`, render with tables, gauges, or progress bars; use `every(...)` for refresh and `Cmd.batch` for multiple updates.
- Optionally add `DebugOverlayModel` to show render metrics.

### Create a TUI to handle user input

- Start from `packages/artisanal/example/tui/examples/textinput/main.dart` or `textarea/`.
- Use `bubbles` widgets (`TextInputModel`, `TextareaModel`, `SelectModel`, `ListModel`) for handling user input and interactive components.
- Forward input `Msg` to the active widget, then compose view strings.

### TUI patterns to follow

- Compose multiple widgets with layout helpers like `Layout.joinHorizontal` and `Layout.joinVertical`; see `packages/artisanal/example/tui/examples/composable-views/main.dart`.
- Use `ViewportModel` for log panes or long text; see `packages/artisanal/example/tui/examples/pipe/main.dart`.
- Add help overlays with `HelpModel`; see `packages/artisanal/example/tui/examples/help/main.dart`.
- Prefer `ProgramOptions` for renderer/input toggles and configuration over manual terminal calls for better portability and maintainability.

### UV (low-level) patterns to follow

- Start from `packages/artisanal/example/uv/helloworld.dart` or `packages/artisanal/example/uv_demo.dart`.
- Use `Terminal`, `Screen`, and `Buffer` for drawing; call `draw()` to flush updates. Combine `Canvas` and `Layer` for composable rendering.
- Use `Canvas` for immediate-mode shapes and `Compositor` for layered rendering; see `packages/artisanal/example/uv/draw.dart`.
- Use layout helpers like `splitHorizontal` and `splitVertical` for responsive designs; see `packages/artisanal/example/uv/layout.dart`.

### Create a CLI with subcommands

- Use `package:artisanal/args.dart` and `CommandRunner`.
- Keep each subcommand in its own class; return non-zero exit codes on failure.

```dart
import 'package:artisanal/args.dart';

class HelloCommand extends Command {
  @override
  String get name => 'hello';

  @override
  String get description => 'Print a greeting.';

  @override
  void run() {
    print('Hello, world!');
  }
}

void main(List<String> args) {
  final runner = CommandRunner('my-cli', 'A great CLI');
  runner.addCommand(HelloCommand());
  runner.run(args);
}
```

## Resources

- `scripts/example.py`: list or search Artisanal examples by keyword.
- `assets/example_asset.txt`: TUI skeleton template (copy into a new Dart file).
