# AGENTS.md — artisanal_widgets

Guidance for AI agents and contributors working in `pkgs/artisanal_widgets`.

## What this package is

`artisanal_widgets` is the widget framework of the Artisanal workspace: a
Flutter-inspired composable widget system for terminal UIs, built on top of
`artisanal`. This is the **primary package for widget-first apps**. Widget
entrypoints and implementations are owned here; core `artisanal` does not
depend on or re-export them.

Rendering flows through the element tree into UV buffers:
`Widget` → `Element` tree → `RenderObject` tree → `Canvas`/`Buffer` →
`UvTerminalRenderer` → diffed terminal output. `WidgetApp` is itself a
`Model`, so widget apps run on the same `Program` runtime as plain TEA apps.

Part of a Dart workspace (`resolution: workspace`). SDK: `>=3.10.0 <4.0.0`.
Version 0.4.0. Depends on `artisanal ^0.6.0`, `image`, `meta`. This package
has its own `analysis_options.yaml` (`package:lints/recommended.yaml`).

## Commands

Run from the package directory (`pkgs/artisanal_widgets`) unless noted:

```sh
dart pub get            # workspace: run once from repo root is also fine
dart analyze            # lint
dart test               # full test suite
dart test test/components   # all component tests
dart test test/components/button_test.dart   # single file
dart run example/main.dart   # run an example (most are interactive)
```

CI (`.github/workflows/ci.yaml`) runs `flutter test pkgs/artisanal_widgets
-r compact` from the repo root on Ubuntu and with `--concurrency=1` on
Windows. This is the only package treated as a Flutter package. `flutter
analyze` runs at the repo root.

## Layout

```
lib/
  artisanal_widgets.dart   # LEGACY broad compatibility surface (experimental)
  widgets.dart             # stable high-level widget surface (preferred)
  app.dart                 # app shells: WidgetApp, ArtisanalApp, reload helpers
  charting.dart            # chart widgets (SparklineChart, LineChart, ...)
  editors.dart             # TextField, TextArea, TextEditor, CodeEditor,
                           # MarkdownEditor, key maps, diagnostics/decorations
  selection.dart           # SelectableText, SelectionArea, SelectableRichText
  testing.dart             # WidgetTester
  (entry points above export only; no logic lives here)
lib/src/widgets/
  core/            # widget.dart (Widget/StatelessWidget/StatefulWidget/State/
                   # InheritedWidget), element.dart, framework.dart
                   # (BuildContext), key.dart, accessibility.dart
  app/             # widget_app.dart (WidgetApp), artisanal_app.dart,
                   # reload.dart + reload_watcher.dart, render_metrics_provider.dart
  components/      # 70+ widgets: button, chip, card, checkbox, radio, switch,
                   # tabs, tree_view, data_table, slider, dropdown/popup menu,
                   # dialog/modal/drawer, tooltip, toast, wizard, command_palette,
                   # scroll_area, split_view, status_bar, help_view, text/code/
                   # markdown editors, file_picker, git_diff, monthly_calendar, ...
  input/           # input_widgets, text diagnostics + decoration bindings
  layout/          # geometry, layout (Row/Column/Stack/...), keyboard_listener
  scroll/          # scroll_widgets (SingleChildScrollView, scrollbars, viewport)
  rendering/       # render_object, rendering, render_layout
  theme/           # theme, theme_scope, opencode_themes
  gestures/        # gesture recognizers (tap, double-tap, long-press, drag)
  animation/       # AnimationController + tick messages
  navigation/      # Navigator-style routing
  selection/       # shared text-selection surfaces
  charting/        # chart widgets and models
  focus/ media/ chords/ composer/
  testing/         # widget_tester, widget_testing, widget_fuzzer,
                   # widget_gauntlet, widget_storm, flicker_analyzer, manual_clock
test/              # mirrors lib structure (components/, input/, focus/, scroll/,
                   # theme/, gestures/, animation/, navigation/, selection/,
                   # charting/, app/, layout/, core/, perf/, example/)
example/           # ~70 standalone demos, incl. opencode/, widget_features/,
                   # uv_effects/, inline_build_monitor/, github_cli/
tool/              # ANSI dump helpers for debugging output
```

## Key concepts

- **Framework model (Flutter-style)**: `Widget` (configuration; immutable),
  `Element` (mounted instance, managed by `ElementTree` / `BuildOwner`),
  `State` (`setState`, `initState`, `dispose`, `didUpdateWidget`,
  `handleInit`, `handleIntercept`, `handleUpdate`), `BuildContext`
  (`findAncestorWidgetOfExactType`, `dependOnInheritedWidgetOfExactType`,
  `findAncestorStateOfType`), `InheritedWidget` (theme/media/focus scopes).
- **Message dispatch**: `Widget.update` forwards messages to all `children`
  first, then calls `handleUpdate`. Override `handleUpdate` (not `update`).
  `handleIntercept` runs before children and can stop dispatch by returning a
  `Cmd`.
- **Reconciliation**: widgets match by `runtimeType` + `key`
  (`Widget.canUpdate`); `ValueKey` preserves state across reordering. Match
  position+type when no key is provided (like Flutter).
- **Hit-testing**: mouse events dispatch through the render tree
  (`WidgetApp.useHitTesting: true` default) as `HitTestMouseMsg` bubbling up
  from the deepest hit, with mouse capture for press/drag owners.
  `GestureDetector` recognizers: `onTap`, `onDoubleTap`, `onLongPress`,
  `onDragStart/Update/End`, `onWheel`, `onEnter/onExit` (hover).
- **WidgetApp**: implements `Model` (plus `FrameTickModel`,
  `RenderMetricsModel`, `ReassemblableModel`). `view()` renders the element
  tree and caches output so unchanged frames skip the renderer pipeline.
  F12 toggles the built-in debug overlay; `backgroundColor` /
  `backgroundColorBuilder` drive OSC 11 terminal background; `imageAutoMode`
  selects environment vs session-capability image rendering.
- **App shells**: `ArtisanalApp` (title + home), `WidgetApp`, reload support
  (`ReloadController`, `ReloadFileWatcher`). Entry: `runWidgetApp(...)` from
  `package:artisanal_widgets/app.dart`. `runWidgetApp` defaults to
  `MouseMode.allMotion` for hover support — plain `runProgram` needs it set
  explicitly.
- **Commands**: commands combining runtime-managed commands (`EveryCmd`,
  `StreamCmd`, `every(...)`) must use `ParallelCmd` so `Program` starts them;
  `Cmd.batch` is for finite commands that only need `execute()`.
- **Testing surface**: `WidgetTester` mounts widgets headlessly
  (`pumpWidget`/`pump`/`dispose`), dispatches keys (`sendKey`,
  `sendSpecialKey`, `typeText`, `pasteText`) and mouse (`tap`, `tapAt`,
  `mouseDown/Up/Move`, `drag`), resizes, asserts via `find` (`text`,
  `textMatching`, `textLocation`, `byType`, `byKey`), drives deterministic
  animations with `ManualClock`/`advanceAnimation`, and can fuzz
  (`WidgetFuzzOptions`), record frames, and run gauntlets.

## Conventions

- **Imports**: consumers import the stable entrypoints
  (`package:artisanal_widgets/widgets.dart`, `app.dart`, `editors.dart`,
  `charting.dart`, `selection.dart`, `testing.dart`). `artisanal_widgets.dart`
  is the legacy broad surface — prefer stable entrypoints in new code and
  tests. Internal code uses relative imports within `lib/src/widgets`.
- **API stability**: 0.4.0, built on `artisanal` core. Keep the
  stable entrypoints compiling (`test/stable_entrypoints_test.dart` covers
  them). Prefer additive changes; document changes in `CHANGELOG.md`.
- **Widget style**: follow the Flutter naming conventions already in use
  (`StatelessWidget`/`StatefulWidget`/`State`, `build(BuildContext)`,
  `ValueKey`, camelCase callbacks, `*Controller`/`*KeyMap` parameter
  objects). Match existing component structure when adding a widget —
  components live in `components/` with a matching `test/components/*_test.dart`.
- **Doc comments**: public APIs get `///` docs; entrypoints carry
  `{@category ...}` tags. Match the existing style.
- **Testing**: component tests use `WidgetTester`; Program-level tests use
  `MockTerminal` (`test/mock_terminal.dart`) or `StringTerminal` with injected
  input/output. Tests import the real example apps when exercising them
  (e.g. `../example/main.dart show AppWidget`) — test real code, not
  reimplementations. Add a regression test when fixing a bug.

## Gotchas

- `WidgetApp` catches widget exceptions and renders a built-in error screen
  (fuzz/gauntlet tests rely on this — exceptions do not propagate).
- Interactive examples (`dart run example/...`) are full-screen TUI apps that
  need a TTY; quit with `q` / `ctrl+c`.
- `print()` from app code corrupts a full-screen TUI — use
  `ProgramOptions.withCaptureOutput()` or `Cmd.println`.
- Do not add widget implementations or entrypoints to `package:artisanal`;
  they belong in this package.
- Terminal image decoding runs off the main TUI isolate; keep image-heavy
  paths from stalling render.
- Scrollbar/selection/hover behavior has many edge-case regression tests
  (scroll_widgets_program_test.dart, renderer_pipeline_test.dart,
  help_view UV regressions) — run the full suite before changing rendering,
  hit-testing, or scroll code.
