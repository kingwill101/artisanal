# Artisanal API reference (concise)

This is a Dart package. Prefer importing public entrypoints:
- `package:artisanal/artisanal.dart`
- `package:artisanal/args.dart`
- `package:artisanal/tui.dart`
- `package:artisanal/bubbles.dart`
- `package:artisanal/style.dart`
- `package:artisanal/terminal.dart`
- `package:artisanal/uv.dart`

See `packages/artisanal/README.md` for full docs and examples.

## CLI I/O (Console)

Import: `package:artisanal/artisanal.dart`

- `Console()` high-level IO helper
- `console.title(...)`, `section(...)`, `info(...)`, `success(...)`, `warning(...)`, `error(...)`
- `console.table(headers: ..., rows: ...)`
- `console.confirm(...)`, `console.input(...)`, `console.select(...)`
- `console.task(label, run: () async { ... })`

Good for quick CLIs, status output, prompts.

## Args (CommandRunner)

Import: `package:artisanal/args.dart`

- `CommandRunner(name, description)`
- Extend `Command` for subcommands
- `runner.addCommand(...)`, `runner.run(args)`

Use for nested subcommands with styled help output.

## Styling (Lip Gloss style API)

Import: `package:artisanal/style.dart`

- `Style()` fluent API: `bold()`, `foreground(...)`, `padding(...)`, `border(...)`
- Colors: `Colors.*`, `Color.rgb(...)`, `AdaptiveColor(...)`
- `ThemePalette` presets

## TUI runtime (Elm-style)

Import: `package:artisanal/tui.dart`

- `Model` with `init()`, `update(Msg)`, `view()`
- `Msg` (input, timers, window size, focus, etc.)
- `Cmd` (side effects)
- `runProgram(model, options: ProgramOptions(...))`

Useful Cmd helpers:
- `Cmd.tick(Duration, (time) => Msg)` for one-shot timer
- `every(Duration, (time) => Msg)` for periodic updates
- `Cmd.batch([...])` and `Cmd.sequence([...])`
- `Cmd.quit()` to exit

Examples:
- `packages/artisanal/example/tui/examples/realtime/main.dart` (live updates)
- `packages/artisanal/example/tui/examples/textinput/main.dart` (input handling)
- `packages/artisanal/example/tui/examples/pipe/main.dart` (viewport scrolling)

## Bubbles widgets

Import: `package:artisanal/bubbles.dart`

Common models:
- `TextInputModel`, `TextareaModel`, `ListModel`, `TableModel`, `ViewportModel`
- `SpinnerModel`, `ProgressModel`, `FilePickerModel`, `SelectModel`, `WizardModel`

Pattern:
- Keep widget models in your app model
- Forward `Msg` to widget update functions
- Compose widget `view()` strings in your `view()`

## UV (Ultraviolet) rendering

Import: `package:artisanal/uv.dart`

- `Terminal`, `Screen`, `Buffer`, `Cell`, `UvStyle`
- `UvTerminalRenderer` for diff-based rendering
- `EventDecoder` for key/mouse/window events

Use for custom rendering or performance-sensitive TUIs.

Examples:
- `packages/artisanal/example/uv/helloworld.dart` (minimal UV)
- `packages/artisanal/example/uv_demo.dart` (full demo)
- `packages/artisanal/example/uv/layout.dart` (splits/layout)
- `packages/artisanal/example/uv/draw.dart` (canvas drawing)

## File pointers

- Entry exports: `packages/artisanal/lib/*.dart`
- TUI runtime: `packages/artisanal/lib/src/tui/`
- UV engine: `packages/artisanal/lib/src/uv/`
- Examples: `packages/artisanal/example/`
