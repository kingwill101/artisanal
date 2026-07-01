# Inline TUI Guide

Inline TUIs render on the terminal's primary screen instead of the alternate
screen. Use them for command workflows where users need normal shell output,
native scrollback, and a small live status surface at the same time.

Good examples are build dashboards, `flutter run` style process monitors,
device pickers, command palettes, and compact progress panels.

## Quick Start

Use `ScreenMode.inline` and choose a fixed height for the live UI region.

```dart
import 'package:artisanal/tui.dart';

Future<void> main() async {
  await runProgram(
    MyStatusModel(),
    options: const ProgramOptions(
      screenMode: ScreenMode.inline,
      inlineHeight: 4,
      uiAnchor: UiAnchor.bottom,
      mouseMode: MouseMode.none,
      startupProbes: false,
    ),
  );
}
```

`screenMode: ScreenMode.inline` is the preferred API. `altScreen: false` still
maps to inline mode for compatibility, but new code should use `screenMode`.

## When to Use Inline Mode

Use inline mode when:

- logs or child-process output should remain visible above the UI;
- users should be able to scroll back through normal terminal history;
- the UI is a small, bounded surface rather than a full application shell;
- the command should feel like a CLI with a live panel, not a full-screen app.

Use full-screen mode when:

- the UI owns the whole terminal;
- mouse interaction, hover, or complex layout is the primary workflow;
- scrollback is less important than a stable application viewport;
- the app needs modal surfaces, large lists, editors, or routed screens.

## Bottom-Pinned Dashboards

Bottom-pinned inline mode is the common layout for long-running commands. The
dashboard stays fixed in the bottom rows and process output streams above it.

Emit logs with `Cmd.println`; do not print directly to stdout from the model.
The runtime routes `Cmd.println` through the inline log-insertion path so the
panel remains pinned and native scrollback stays useful.

```dart
class BuildModel implements Model {
  const BuildModel({this.tick = 0});

  final int tick;

  @override
  Cmd? init() {
    return every(
      const Duration(milliseconds: 500),
      (_) => const BuildTick(),
    );
  }

  @override
  (Model, Cmd?) update(Msg msg) {
    if (msg is KeyMsg &&
        msg.key.type == KeyType.runes &&
        msg.key.runes.isNotEmpty &&
        String.fromCharCode(msg.key.runes.first) == 'q') {
      return (this, Cmd.quit());
    }

    if (msg is BuildTick) {
      final next = BuildModel(tick: tick + 1);
      return (
        next,
        Cmd.println('[${next.tick.toString().padLeft(4, '0')}] compiling...'),
      );
    }

    return (this, null);
  }

  @override
  String view() {
    return 'RUNNING  phase: compile kernel  progress: ${tick % 100}%\n'
        'device: linux ready  perf: ${60 + tick % 40}fps\n'
        'keys: q quit';
  }
}

class BuildTick extends Msg {
  const BuildTick();
}
```

Run the complete reference example from `pkgs/artisanal`:

```bash
dart run example/tui/examples/inline/pinned_build_dashboard.dart
```

## Top-Pinned Monitors

Use `UiAnchor.top` when the live panel should stay above normal output. This is
useful for compact monitors where subsequent command output should appear below
the status region.

```dart
await runProgram(
  MonitorModel(),
  options: const ProgramOptions(
    screenMode: ScreenMode.inline,
    inlineHeight: 4,
    uiAnchor: UiAnchor.top,
    mouseMode: MouseMode.none,
    startupProbes: false,
  ),
);
```

Run the reference example from `pkgs/artisanal`:

```bash
dart run example/tui/examples/inline/top_panel.dart
```

## Widget-Based Inline TUIs

Widget apps can run inline too. Prefer calling `runProgram` with a `WidgetApp`
when native scrollback matters, because the higher-level widget runners default
to mouse tracking for hover-heavy apps.

```dart
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/widgets.dart' as w;

Future<void> main() async {
  await tui.runProgram(
    w.WidgetApp(MyInlinePanel()),
    options: const tui.ProgramOptions(
      screenMode: tui.ScreenMode.inline,
      inlineHeight: 8,
      uiAnchor: tui.UiAnchor.bottom,
      mouseMode: tui.MouseMode.none,
      startupProbes: false,
    ),
  );
}
```

If the inline UI truly needs pointer interaction, opt in deliberately with
`MouseMode.cellMotion` or `MouseMode.allMotion`. Native scrollback behavior can
vary once mouse tracking is enabled because the terminal may send wheel events
to the app instead of scrolling history.

Run the widget reference example from the workspace root:

```bash
dart run pkgs/artisanal_widgets/example/inline_status_dashboard/main.dart
```

## Rules for App Code

Do:

- keep the inline surface small and fixed-height;
- use `Cmd.println` for logs that should flow around the pinned UI;
- use `MouseMode.none` unless the inline surface requires pointer input;
- set `startupProbes: false` for examples and command dashboards;
- handle `WindowSizeMsg` or render responsively for narrow terminals;
- let the runtime restore cursor, scroll region, style, and terminal modes.

Do not:

- emit manual ANSI cursor movement, clears, or scroll-region sequences;
- call `print`, `stdout.write`, or child-process stdout directly from a model;
- use full-screen clear operations in inline mode;
- enter the alternate screen from an inline command;
- compose process logs into the `view()` string just to make them scroll;
- rely on mouse wheel input and native scrollback at the same time.

## Child Process Output

For commands that run a child process, route stdout and stderr into program
messages and turn those messages into `Cmd.println` calls.

```dart
class ProcessLine extends Msg {
  const ProcessLine(this.text);
  final String text;
}

@override
(Model, Cmd?) update(Msg msg) {
  if (msg is ProcessLine) {
    return (this, Cmd.println(msg.text));
  }
  return (this, null);
}
```

This keeps terminal writes serialized through the TUI runtime. One writer must
own the terminal while an inline UI is active.

## Testing Inline Behavior

Inline bugs are terminal-behavior bugs, not just string-output bugs. Tests
should verify the terminal effects that matter:

- inline mode does not enter the alternate screen;
- inline renders do not emit full-screen clears;
- bottom-pinned logs enter the log band above the UI;
- once the log band fills, older log lines move into native scrollback;
- resizing does not erase prior log history or leave stale UI rows;
- cleanup resets cursor visibility and scroll regions.

Use the inline terminal harness for regression tests:

- `pkgs/artisanal/test/tui/inline_renderer_test.dart`
- `pkgs/artisanal/test/tui/inline_program_harness_test.dart`
- `pkgs/artisanal/test/tui/inline_terminal_harness.dart`

For manual diagnosis, run the traceable dashboard and inspect its trace:

```bash
cd pkgs/artisanal
dart run example/tui/examples/inline/pinned_build_dashboard.dart --trace
dart run example/tui/examples/inline/inspect_inline_trace.dart build/inline-traces/<trace>.log
```

## Example Directory

The primary TEA examples live in:

```text
pkgs/artisanal/example/tui/examples/inline/
```

- `bottom_status.dart`: compact bottom status bar with streaming logs.
- `pinned_build_dashboard.dart`: build/run dashboard with scrollback-sensitive
  bottom anchoring.
- `top_panel.dart`: top-anchored panel with output below it.
- `inspect_inline_trace.dart`: helper for reading recorded inline traces.

The widget example lives in:

```text
pkgs/artisanal_widgets/example/inline_status_dashboard/main.dart
```

## Mental Model

Inline mode is a fixed viewport plus a log-insertion channel. Widgets and TEA
views draw only the live viewport. Logs are not part of the viewport; they are
inserted above or below it by the runtime so the terminal's own scrollback keeps
working.

That separation is the key difference from full-screen TUIs.
