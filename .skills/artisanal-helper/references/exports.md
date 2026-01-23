# Artisanal exports cheat sheet

Focus on the public entrypoints first, then dive into src/ for details.

## Primary entrypoints

- `packages/artisanal/lib/artisanal.dart`
  - High-level CLI I/O: `Console`, components, validators
  - Terminal: `Terminal`, `StdioTerminal`, `RawModeGuard`, `Ansi`, keys
  - Styling: `Style`, `Color`, `Verbosity`
  - Renderer: `Renderer`, `TerminalRenderer`
  - Layout helpers
  - CLI runner: `Command`, `CommandRunner`

- `packages/artisanal/lib/args.dart`
  - CLI subcommands: `Command`, `CommandRunner`

- `packages/artisanal/lib/tui.dart`
  - Elm-style TUI runtime: `Model`, `Msg`, `Cmd`, `Program`
  - Bubbles: interactive widgets (textinput, list, table, viewport, etc.)

- `packages/artisanal/lib/uv.dart`
  - Low-level high-performance rendering and input

- `packages/artisanal/lib/style.dart`, `packages/artisanal/lib/terminal.dart`
  - Styling and terminal helpers for non-TUI usage

## TUI internals to know

- `packages/artisanal/lib/src/tui/program.dart`
  - Program runtime and options, renderer selection
- `packages/artisanal/lib/src/tui/renderer.dart`
  - `TuiRenderer` and `FullScreenTuiRenderer`
- `packages/artisanal/lib/src/tui/cmd.dart`
  - `Cmd.tick`, `every(...)`, `Cmd.batch`, `Cmd.exec`, etc.

## UV internals to know

- `packages/artisanal/lib/src/uv/terminal_renderer.dart`
  - Diff-based renderer and metrics
- `packages/artisanal/lib/src/uv/screen.dart`, `buffer.dart`, `canvas.dart`
  - Screen/buffer drawing primitives
