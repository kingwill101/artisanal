# Artisanal Editor

A standalone modal terminal code editor built on the published Artisanal
packages. Editor product policy lives here rather than in the framework.

## Run

From the repository root:

```sh
dart run artisanal_editor edit
dart run artisanal_editor edit README.md
dart run artisanal_editor edit --workspace .
dart run artisanal_editor edit --no-lsp
```

The executable also accepts a file directly:

```sh
dart run artisanal_editor README.md
```

## Trace and profile editor scrolling

Artisanal's structured TUI tracer is already connected to the editor's input,
widget, layout, paint, render, and Ultraviolet flush pipeline. The editor also
records an `editor_scroll` span with the file and cursor-line transition for
each successful scroll. Capture a manual scroll session from this directory:

```sh
ARTISANAL_TUI_TRACE=1 \
ARTISANAL_TUI_TRACE_CAPTURE=1 \
ARTISANAL_TUI_TRACE_TAGS=input,queue,dispatch,rebuild,layout,paint,render,flush,scroll \
ARTISANAL_TUI_TRACE_PATH=.dart_tool/traces/editor-scroll.log \
dart run bin/artisanal_editor.dart edit --no-lsp --workspace .
```

That full trace is intended for replay and event-by-event diagnosis. It writes
high-volume layout and paint records synchronously, so do not use it as the
CPU-performance baseline. In particular, `ARTISANAL_TUI_TRACE_CAPTURE=1` adds
dispatch-capture instrumentation, and leaving `ARTISANAL_TUI_TRACE_TAGS`
unset enables every trace category.

Run `devtools-profiler` without tracing for clean CPU comparisons. When a
correlated trace is necessary, keep capture disabled and restrict the output
to the pipeline boundaries:

```sh
ARTISANAL_TUI_TRACE=1 \
ARTISANAL_TUI_TRACE_TAGS=input,dispatch,render,flush \
ARTISANAL_TUI_TRACE_PATH=.dart_tool/traces/editor-profile.log \
devtools-profiler run --terminal -- dart run bin/artisanal_editor.dart
```

Compare trace-enabled profiles only with runs using the same trace and capture
settings. Use the full trace command separately when layout, paint, queue, or
replay evidence is the goal.

Use the offline workload for repeatable measurements. It mounts the real
`EditorScreen` with the production Ultraviolet renderer, generates a fixed
2,000-line Dart document outside the timed section, warms up, and checks that
every down/up round restores the starting viewport:

```sh
dart run tool/editor_scroll_profile.dart \
  --rounds=10 --warmup=3 --steps=40 \
  --out=.dart_tool/benchmarks/editor-scroll.json
```

The JSON report contains per-round timings plus p50, p95, p99, and maximum
latency for individual wheel events. Keep the terminal dimensions, warmup,
round count, and step count identical when comparing revisions.

Capture only the measured rounds in the named CPU region
`artisanal_editor.scroll`:

```sh
devtools-profiler run \
  --artifact-dir=.dart_tool/devtools_profiler/editor-scroll \
  -- dart run tool/editor_scroll_profile.dart \
  --rounds=10 --warmup=3 --steps=40 --profile \
  --out=.dart_tool/benchmarks/editor-scroll-profiled.json
```

Inspect the result from the app directory with both top-down and bottom-up
views:

```sh
devtools-profiler summarize --call-tree --bottom-up --hide-sdk \
  .dart_tool/devtools_profiler/editor-scroll
```

For scrollbar-thumb work, use the separate drag workload. It opens a fixed
Markdown document with both the source editor and rendered preview visible,
drags each thumb down and back to the top, and reports p50, p95, p99, and
maximum motion latency for each surface:

```sh
dart run tool/editor_scrollbar_drag_profile.dart \
  --rounds=8 --warmup=2 --steps=12 --document-lines=1000 \
  --out=.dart_tool/benchmarks/editor-scrollbar-drag.json
```

Add `--profile` under `devtools-profiler run` to capture the two measured
regions independently:

```sh
devtools-profiler run \
  --artifact-dir=.dart_tool/devtools_profiler/editor-scrollbar-drag \
  -- dart run tool/editor_scrollbar_drag_profile.dart \
  --rounds=8 --warmup=2 --steps=12 --document-lines=1000 --profile \
  --out=.dart_tool/benchmarks/editor-scrollbar-drag-profiled.json
```

The region names are `artisanal_editor.markdown_scrollbar_drag` and
`artisanal_editor.editor_scrollbar_drag`. Compare those regions separately;
the whole-session summary also includes startup, Markdown parsing, warmup, and
profiler finalization.

Profiler overhead changes absolute timing, so compare profiled runs only with
other profiled runs. The workspace guides document the reusable setup in
[`docs/tui.md`](../../docs/tui.md#tui-runtime-instrumentation) and
[`docs/replay.md`](../../docs/replay.md#replay-harness-mixin).

## Current milestone

- explicitly expandable workspace file tree with all directories collapsed by
  default, mouse wheel scrolling, horizontal panning, and a scrollbar;
- persistent open buffers with clickable tabs and close buttons;
- dense, borderless syntax-highlighted `CodeEditor` surface;
- asynchronous Tree-sitter coloring through `tree_sitter_language_pack`, with
  the built-in highlighter retained as a fallback;
- live, independently scrollable Markdown previews beside Markdown buffers,
  with a pointer-resizable editor/preview divider;
- mouse wheel navigation and a draggable editor scrollbar;
- pointer-resizable Explorer/editor split;
- Vim-style normal, insert, visual, and operator-pending input;
- counts and common motions/edits;
- severity-colored, underlined TODO/FIXME/HACK and LSP diagnostics with
  app-owned virtual details beside the clicked source line;
- Dart LSP lifecycle, document synchronization, diagnostic underlines, and
  completion;
- Markdown-rendered Dart hover documentation;
- command-revealed Problems and Output panels, hidden by default;
- persistent, workspace-rooted `artisanal_pty` terminal instances with full
  terminal colors, keyboard input, shell history navigation, automatic
  resizing, primary-screen scrollback, child-TUI mouse forwarding, a
  pointer-draggable top divider, and new/restart/kill/hide controls;
- searchable command and file palette;
- save, safe close, save-and-close, buffer cycling, and diagnostic navigation.

Key bindings:

| Key | Action |
|---|---|
| `i`, `a`, `I`, `A`, `o`, `O` | Enter insert mode |
| `Esc` | Return to normal mode |
| `h`, `j`, `k`, `l`, `w`, `b`, `0`, `$`, `gg`, `G` | Move |
| `v`, `V` | Character/line visual mode |
| `x`, `dd`, `dw`, `d$`, `cc`, `cw`, `c$` | Edit |
| `u`, `Ctrl+Z`, `Ctrl+R` | Undo/undo/redo |
| `K` | Show hover documentation |
| `Ctrl+P` | Open the command and file palette |
| `Ctrl+Space` | Request completion |
| `Up`/`Down`, `Enter`/`Tab`, `Esc` | Select, accept, or dismiss completion |
| `Ctrl+B` | Toggle the Explorer |
| `Ctrl+J` | Toggle the Problems/Output panel |
| ``Ctrl+` `` | Toggle the integrated terminal |
| `Ctrl+D` | Terminate and close the focused terminal instance |
| `Ctrl+Shift+V` | Toggle the active Markdown buffer's rendered preview |
| `Ctrl+S` | Save |
| `Ctrl+W` | Close, prompting to save or discard when modified |
| `Ctrl+Tab` | Next buffer |
| `F8` | Next diagnostic |
| `Shift+F8` | Previous diagnostic |
| `Ctrl+Q` | Quit |

Click an underlined diagnostic or its gutter marker to place the cursor on the
issue and reveal its message beside that source line. This virtual diagnostic
is composed by the application around `CodeEditor`; no product-specific
diagnostic presentation is built into the reusable text editor.

`Ctrl+Z` is reclaimed from Unix job control, so it always performs editor undo
without suspending the process or leaving the terminal in a partially rendered
state.

Each buffer tab also has a clickable `×` close control. Dirty buffers are never
discarded implicitly: closing a modified tab opens an explicit **Save and
close** / **Discard changes** dialog, and `Esc` keeps the buffer open.

The Explorer uses Artisanal's shared `TreeModel` through the model-backed
`TreeView`, so pointer expansion, keyboard navigation, selection, vertical
scrolling, horizontal `H`/`L` panning, and scrollbar position follow the same
reusable state policy as non-widget TUI trees. Directories never auto-expand:
each level must be opened explicitly. Drag the vertical divider to resize the
Explorer.

Markdown buffers open with a rendered preview beside the editable source.
Scroll the preview independently, drag its divider to resize it, or close it
with the preview header's `×`. `Ctrl+Shift+V` and the command palette restore
or hide the preview without affecting non-Markdown buffers.

## Architecture

```text
bin/                    executable only
lib/src/cli/            Artisanal CommandRunner integration
lib/src/lsp/            pro_lsp adapter and coordinate conversion
lib/src/syntax/         tree_sitter_language_pack adapter and styling
lib/src/workspace/      files, buffers, persistence, diagnostics
lib/src/modal/          product-owned Vim interaction policy
lib/src/ui/             Artisanal widget workbench
```

The Dart adapter delegates typed LSP 3.18 messages, JSON-RPC, cancellation, and
stdio framing to [`pro_lsp`](https://pub.dev/packages/pro_lsp). Artisanal's
editor model owns the completion request session and text transaction; this
application owns process selection, buffer synchronization,
UTF-16-to-grapheme conversion, and widget presentation.

Tree-sitter follows the same boundary: the application initializes the native
runtime, rejects stale asynchronous parse results, and publishes syntax ranges
on its own decoration layer. `artisanal` and `artisanal_widgets` remain free of
the native parser dependency.

The explorer maps workspace paths into Artisanal `TreeItem` values. Its
selection, expansion, visible-row projection, and scroll offset are owned by
the reusable Bubble `TreeModel`; `artisanal_widgets` supplies focus, pointer
handling, custom row rendering, and the scrollbar through `TreeView.model`.

The integrated terminal lazily starts the user's shell in the workspace root
through `pty2`, while `artisanal_pty` owns terminal emulation, rendering,
keyboard encoding, and resize propagation. Hiding the panel preserves the
shell session; the panel header can restart or hide it, and shell exit never
quits the editor. The PTY uses cooked mode so foreground commands receive
terminal-generated signals such as `Ctrl+C`, and acknowledged output chunks
provide bounded, incremental rendering during long-running commands. Each
terminal tab owns an independent shell; use `+` to create one, `↻` to restart
the active shell, `⊗` to terminate it, and `×` to hide the panel without
terminating any sessions. While a terminal is focused it owns the keyboard,
including editor-like chords such as `Ctrl+W`; use ``Ctrl+` `` to return to
the editor before invoking editor shortcuts. `Ctrl+D` is reserved by the
workbench to forcibly close the focused terminal. An application interrupt
terminates every owned PTY and waits briefly for their worker isolates before
the editor exits.

Planned next layers are code-action and definition surfaces, recursive split
trees, and workspace text search.
