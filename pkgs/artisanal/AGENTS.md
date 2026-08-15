# AGENTS.md — artisanal (core)

Guidance for AI agents and contributors working in `pkgs/artisanal`.

## What this package is

`artisanal` is the core terminal toolkit of the Artisanal workspace: a
faithful Dart port of Charm's Go libraries — Lip Gloss (styling), Bubble Tea
(TEA runtime), and Bubbles (reusable widgets). It provides:

- **Console** — high-level CLI I/O (styled output, prompts, tasks, tables).
- **Style** — fluent, immutable styling with colors, borders, padding, themes.
- **TUI runtime** — Elm Architecture (`Model` / `Msg` / `Cmd` / `Program`).
- **Bubbles** — 30+ reusable TEA widgets (text input, lists, tables, spinners,
  progress, file picker, prompts, forms, …).
- **CommandRunner** — Symfony/Laravel-style CLI commands with namespaces and
  shell completion (`package:artisanal/args.dart`).
- **Markdown / Glamour** — ANSI markdown rendering and high-fidelity renderer.
- **Charting, editor core, remote plugin protocol, Liquid, physics, scoring.**

Rendering is delegated to the `ultraviolet` package (cell buffers, diff-based
`UvTerminalRenderer`, image protocols). The widget framework itself lives in
the separate `artisanal_widgets` package; `package:artisanal/widgets.dart`
re-exports it for convenience. Keep renderer internals in `ultraviolet` and
widget internals in `artisanal_widgets` — this package is the integration
layer.

Part of a Dart workspace (`resolution: workspace`). SDK: `>=3.10.0 <4.0.0`.
Version 0.5.0.

## Commands

Run from the package directory (`pkgs/artisanal`) unless noted:

```sh
dart pub get            # workspace: run once from repo root is also fine
dart analyze            # lint (root analysis_options.yaml: package:lints/recommended.yaml)
dart test               # full test suite
dart test test/tui/program_test.dart   # single file
dart run example/main.dart             # run an example (most are interactive)
dart run tool/precompile_remote_plugins.dart  # CI precompiles remote plugin kernels
```

Root `Taskfile.yml` shortcut: `task test-core`.

CI (`.github/workflows/ci.yaml`):
- `flutter analyze` at the repo root.
- `dart run tool/precompile_remote_plugins.dart` (from `pkgs/artisanal`) before
  the test job.
- `dart test pkgs/artisanal -r compact` from the repo root on Ubuntu;
  `--concurrency=1` on Windows. Tests must pass on both platforms.

## Layout

```
lib/
  artisanal.dart       # umbrella: Console, Style, Terminal, markdown, charting,
                       # plugins, Liquid, physics, widget re-exports
  args.dart            # CommandRunner / Command
  style.dart           # Style system
  tui.dart             # TUI runtime: Model, Msg, Cmd, Program, replay/trace
  bubbles.dart         # reusable TEA widgets
  terminal.dart        # Terminal abstraction, ANSI, Keys
  widgets.dart         # re-export of package:artisanal_widgets
  testing.dart         # widget testing helpers re-export
  editor_core.dart     # low-level editor primitives
  glamour.dart         # high-fidelity Markdown renderer
  uv.dart              # compatibility re-export of ultraviolet
  compat.dart          # backward-compatible shims
  (entry points above export only; no logic lives here)
lib/src/
  io/                  # Console, components, inline animation, output themes, UVConsole
  style/               # style.dart, color.dart, border.dart, theme.dart, tag_parser,
                       # blending, accessibility, uv_color_bridge, writer (io/web split)
  tui/                 # program.dart, runtime, cmd (io/web split), model, msg, view,
                       # renderer, key/keymap_hub, trace + replay, devtools, render_recorder,
                       # hot_reload (io/web split), evidence (io/web split), startup probes,
                       # degradation, resize_coalescer, terminal, theme
    bubbles/           # TEA widgets (textinput, textarea, list, table, viewport,
                       # progress, spinner, filepicker (io/web split), select, forms, …)
    markdown/          # ANSI renderer, glamour bridge, code blocks, syntax highlighting
    editor_core/       # text documents, undo/redo, extmarks, syntax, decorations
  runner/              # command.dart, command_runner.dart, shell_completion
  terminal/            # Terminal, StdioTerminal, StringTerminal, backends, bridges,
                       # browser/socket hosts (io/web stub splits)
  renderer/            # Renderer, TerminalRenderer, StringRenderer, NullRenderer
  colorprofile/        # color capability detection
  unicode/             # width, grapheme
  layout/              # Layout utilities
  charting/            # sparkline, line, ribbon, histogram, heatmap, pie
  glamour/             # glamour renderer + themes
  plugins/             # remote plugin protocol (io/web split)
  liquid/ physics/ scoring/ web/ platform/ compat/ run/
test/                  # mirrors lib structure (tui/, style/, io/, runner/,
                       # terminal/, editor_core/, bubbles/, …)
example/               # demo apps (log_viewer_demo, command_center_demo, args/,
                       # tui/, charting/, glamour_styles/, …)
tool/precompile_remote_plugins.dart   # CI helper
```

## Key concepts

- **TEA runtime**: `Model` (immutable state; `init` / `update` / `view`),
  `Msg` (events), `Cmd` (effects: `Cmd.quit`, `Cmd.tick`, `Cmd.perform`,
  `Cmd.batch`, `Cmd.sequence`), and `Program` (event loop + rendering).
  `runProgram(Model, options: ...)` is the convenience entry point.
- **ProgramOptions** (see `program.dart`): `useUltravioletRenderer: true`
  (default) renders `Model.view()` through the UV cell-buffer diff renderer;
  `useUltravioletInputDecoder` swaps in the UV event decoder; `screenMode`
  selects `fullScreen` (alt screen), `inline` / `inlineAuto` (scrollback-
  preserving, anchored top/bottom), or `fixed` (arbitrary `FixedViewport`
  rectangle on the primary screen); `mouse` / `mouseMode`, `fps`, `frameTick`,
  `bracketedPaste`, `catchPanics`, `signalHandlers`, `sendInterrupt`,
  `sendSuspendSignal`, `startupProbes`, `hotReload`, `captureOutput`, `replay`,
  `filter`, `interceptor`, and many `with*` / `without*` builders.
- **A `Program` instance is single-use**: calling `run()` twice throws
  `StateError`. The runtime is also single-use after `Cmd.quit()`.
- **Message pipeline**: messages can be filtered (`MessageFilter`), observed /
  injected (`ProgramInterceptor`), and replayed deterministically
  (`ProgramReplay.script` / `.stream`, `ProgramMacro`, `blockInputWhileReplay`).
- **Tracing / replay**: `TuiTrace` records structured events (enable with
  `ARTISANAL_TUI_TRACE=1 ARTISANAL_TUI_TRACE_CAPTURE=1
  ARTISANAL_TUI_TRACE_PATH=...`); `render_recorder.dart` / `render_feed.dart`
  capture render output. Used heavily for debugging and regression coverage.
- **Style system** (Lip Gloss port): immutable fluent `Style` builder; colors
  are `Color`, `AnsiColor`, `BasicColor`, `AdaptiveColor` (light/dark);
  `ThemePalette` presets; `<tag>`-style console output parsing
  (`tag_parser.dart`); automatic degradation to the terminal's color profile.
- **Two color systems**: Style colors (high-level, produce ANSI strings) and
  UV colors (`UvColor`, cell storage). Bridge through
  `style/uv_color_bridge.dart` — do not mix them in one API.
- **Hosts / backends**: `ProgramHost` (`.stdio`, `.backend`, `.bridge`,
  `.terminal`, `.split`, `.custom`) packages terminal selection separately from
  model logic; backends include `StdioTerminalBackend`,
  `SocketTerminalBackend`, `EmbeddedTerminalBackend`, plus browser/socket host
  servers (`BrowserTerminalHostServer`, `SocketTerminalHostServer`).
- **CommandRunner**: Symfony/Laravel-style; namespaces, `option()` /
  `argument()` helpers, automatic shell completion (`ShellCompleter`), styled
  `<error>` blocks on stderr.
- **Widgets**: the widget framework ships in `artisanal_widgets`;
  `package:artisanal/widgets.dart` re-exports it. For widget-first apps prefer
  importing `artisanal_widgets` directly.

## Conventions

- **Imports**: consumers import the modular entrypoints
  (`package:artisanal/artisanal.dart`, `tui.dart`, `style.dart`, `bubbles.dart`,
  `args.dart`, `terminal.dart`, …). Internal code uses relative imports within
  `lib/src`. Note: the README documents `runtime.dart`, `hosts.dart`,
  `plugins.dart`, `app.dart`, etc. as separate entrypoints, but those files do
  **not** exist — that surface is exported through `artisanal.dart` and
  `tui.dart`. Trust the actual `lib/*.dart` files.
- **Platform splitting**: io/web/stub splits via conditional imports, e.g.
  `export 'cmd_impl.dart' if (dart.library.html) 'cmd_stub.dart';`. Patterns:
  `cmd`, `writer`, `trace`, `evidence`, `hot_reload_mixin`, `filepicker`,
  `plugins`, terminal backends, and hosts. Keep IO-specific behavior out of
  shared code; web and stub variants must keep compiling.
- **Doc comments**: public APIs get `///` docs; major types carry
  `{@category ...}` tags and `{@template}` / `{@macro}` blocks shared across
  the docs. Match that style for new public surface.
- **API stability**: this is the flagship package (0.5.0, many dependents).
  Prefer additive, backwards-compatible changes; `compat.dart` exists for
  shims; keep the stable entrypoints covered by
  `test/stable_entrypoints_test.dart` compiling. Document changes in
  `CHANGELOG.md`.
- **Parity with upstream**: this is a port of Charm's Go libraries. Where a
  feature mirrors Lip Gloss / Bubble Tea / Bubbles, match upstream behavior
  (see parity tests below) rather than inventing new semantics.

## Testing conventions

- All tests live in `test/` using `package:test`, mirroring the `lib/src`
  directory layout. Name files `*_test.dart`.
- **Parity tests** pin upstream (Go) behavior — e.g.
  `program_runtime_parity_test.dart`, `viewport_parity_test.dart`,
  `progress_parity_test.dart`, `filepicker_parity_test.dart`,
  `ranges_parity_test.dart`; `lipgloss_v2_list_golden_test.dart` /
  `lipgloss_v2_tree_golden_test.dart` are golden output tests. When changing
  behavior these files are the contract; update them deliberately and run the
  full suite.
- **Harnesses**: deterministic program tests use
  `inline_terminal_harness.dart`, `inline_program_harness_test.dart`, and
  replay/macro harnesses; use `ProgramOptions.withNowProvider(...)` /
  `nowProvider` for deterministic timestamps and `withoutSuspendSignal()` to
  avoid real `SIGTSTP` in tests.
- **Regression tests** guard specific bugs (e.g. `prompt_interrupt_test.dart`,
  `destructive_confirm_grapheme_test.dart`, `clear_screen_forces_full_redraw
  _test.dart`). Add one when fixing a bug.
- Tests must not depend on a real TTY/stdin; inject `input` / `output` streams
  through `ProgramOptions` or use `StringTerminal`.
- Windows runs with `--concurrency=1` in CI; keep platform-conditional output
  branches (`Platform.isWindows`) explicit where behavior differs.

## Gotchas

- Interactive examples (`dart run example/...`) are full-screen TUI apps that
  need a TTY and typically quit on `q` / `ctrl+c`; don't run them expecting
  immediate exit in a non-interactive context.
- `print()` from application code corrupts a full-screen TUI; use
  `ProgramOptions.withCaptureOutput()` or `Cmd.println`.
- The package already depends on many libraries (args, markdown, html,
  highlight, forge2d, pure_svg, …) — add dependencies sparingly and only for
  real needs.
- Hot reload (`hotReload`) is auto-detected via `package:hotreloader` and is
  disabled in production builds; tests should not rely on it.
- Startup probing (`startupProbes`) is terminal-driven and skipped for
  arbitrary injected terminals unless they opt in; inline modes skip auto
  probes because they can disturb the primary screen.
