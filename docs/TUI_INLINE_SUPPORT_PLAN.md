# Artisanal Inline TUI Support Plan

## Problem Statement

Artisanal's fullscreen TUI path is strong, but inline mode is currently a thin
renderer offset. It can draw a UV frame into the bottom rows, but streaming
output above that frame is not modeled as a first-class terminal operation. This
causes the failures seen while porting `third_party/flutter-cli`: logs push the
dashboard down, scrollback becomes unusable, and rendered panel content can be
scrolled into the log area.

Inline mode must support the same class of CLI UX as mature terminal UI
frameworks and the original `flutter-cli`:

- stay on the primary screen, not the alternate screen;
- keep the UI pinned to a top or bottom viewport;
- stream process output above a bottom-pinned UI without corrupting it;
- preserve native terminal scrollback and scroll-wheel behavior;
- clean up cursor, scroll-region, style, mouse, and raw-mode state on exit;
- provide tests that validate actual inline terminal behavior, not just that
  bytes were emitted.

## Reference Findings

### Reference viewport model

A mature Rust implementation models inline rendering with a real viewport.
Its inline viewport tracks the renderable rectangle, while a separate insertion
primitive writes logs above it. Log lines are not composed into the widget
view; viewport geometry is updated, cleared as needed, and redrawn afterward.

Important design point: viewport ownership and output insertion are separate
from widget rendering.

### Original flutter-cli

The Rust `flutter-cli` intentionally does not use its renderer's built-in inline
viewport for its long-running run dashboard. It avoids DSR cursor-position
queries by:

1. reading terminal size via ioctl;
2. pre-scrolling the primary screen with CRLFs to reserve bottom rows;
3. creating a fixed viewport at the bottom of the terminal;
4. using DECSTBM scroll margins to write logs into the band above the viewport.

It also tracks how many rows of the log band contain real content. Until the
band is full, it scrolls only the filled sub-region so blank rows are not pushed
into terminal scrollback. Once full, the oldest real log line scrolls into
native scrollback like `tail -f`.

Important design point: bottom inline mode should behave like a fixed viewport
plus a log-insertion channel, not like a fullscreen renderer with shifted CUP
sequences.

### Frankentui

Frankentui treats inline mode as a terminal-session strategy with invariants:

- one writer owns terminal output;
- cursor save/restore wraps inline writes and presents;
- no full-screen clears in inline mode;
- scroll-region state is reset during cleanup;
- synchronized output can be used where safe;
- strategy can vary between scroll-region, overlay-redraw, and hybrid.

Important design point: inline mode needs explicit session state and cleanup,
not just renderer output post-processing.

## Target Architecture

### Ownership

- Artisanal runtime owns terminal lifecycle, input, raw mode, mouse mode, and
  routing of `PrintLineMsg`.
- Artisanal renderer owns inline viewport state and the operations that mutate
  visible output around that viewport.
- Ultraviolet owns drawing a cell buffer into a rectangular target. UV should
  not own terminal scrollback semantics.

### New Core Concepts

Add an inline viewport state in `pkgs/artisanal/lib/src/tui/renderer.dart`:

- terminal width and height;
- inline UI height;
- UI top row and bottom row;
- log band top and bottom rows;
- log-band filled row count;
- anchor;
- whether the inline region needs a full clear.

Add ANSI helpers in `pkgs/artisanal/lib/src/terminal/ansi.dart`:

- `setScrollRegion(top, bottom)` for DECSTBM;
- `resetScrollRegion`;
- named CRLF helper if useful.

Add renderer operations:

- `insertLineAboveInlineViewport(String text)` for bottom-anchored inline logs;
- `insertLineBelowInlineViewport(String text)` or a documented top-anchor
  behavior for top-pinned dashboards;
- `restoreInlineTerminalState()` during cleanup.

### Bottom Inline Algorithm

For bottom-anchored inline mode:

1. On initialize, clamp UI height to terminal height while leaving at least one
   log row when possible.
2. Pre-scroll the primary screen with CRLFs to create a clean viewport region.
3. Render UV into exactly the UI rectangle.
4. For each `PrintLineMsg`, sanitize and truncate the line to terminal width.
5. Save cursor using DEC save (`ESC 7`).
6. Set the scroll region to the filled portion of the log band.
7. Move to the bottom row of that region.
8. Emit CRLF or LF in the region to create space.
9. Write the log line at the bottom of the band.
10. Reset the scroll region.
11. Restore cursor with DEC restore (`ESC 8`).
12. Redraw the UI rectangle if the selected strategy requires it.

This mirrors the original `flutter-cli` UX: logs flow above the fixed UI and
old logs enter native terminal scrollback when the visible log band fills.

### Mouse Defaults

Inline mode should not enable mouse capture by default. Native scrollback must
remain usable. Widget apps may opt into mouse capture explicitly, but examples
that demonstrate scrollback-sensitive inline mode should use `MouseMode.none`.

### Cleanup

Inline cleanup must always:

- reset DECSTBM scroll margins with `ESC[r`;
- reset SGR style;
- end synchronized output if it may have been enabled;
- show the cursor;
- disable mouse modes that Artisanal enabled;
- move the cursor below the inline viewport before returning control to the
  shell.

## Testing Harness Plan

### Phase 1: Byte-Level Inline Contract Tests

Add focused tests under `pkgs/artisanal/test/tui/inline_renderer_test.dart`:

- inline initialization never enters alt-screen;
- inline render never emits `clearScreen` or `clearScreenAndScrollback`;
- bottom inline `printLine` emits DEC cursor save/restore;
- bottom inline `printLine` emits `setScrollRegion` and `resetScrollRegion`;
- bottom inline `printLine` truncates lines to terminal width;
- bottom inline cleanup resets scroll region and shows cursor;
- inline rendering keeps UV output within UI rows after resize.

These tests are necessary but not sufficient because they only prove byte
contracts.

### Phase 2: Virtual Terminal Harness

Add a small inline-focused virtual terminal test harness. It only needs to
interpret the sequences Artisanal inline mode emits:

- CUP (`ESC[row;colH`);
- DEC save/restore (`ESC 7`, `ESC 8`);
- DECSTBM set/reset (`ESC[top;bottomr`, `ESC[r`);
- erase line (`ESC[2K`);
- LF/CRLF scrolling inside the active scroll region;
- printable text;
- synchronized-output wrappers as no-ops.

The harness should expose:

- visible grid lines;
- scrollback lines;
- active scroll region;
- cursor position.

Use it to assert:

- streaming many logs keeps the dashboard rows fixed;
- no dashboard border/content enters the log band;
- once the visible log band fills, older real log lines enter scrollback;
- blank rows are not pushed into scrollback before the band is full;
- resize clears stale UI rows without clearing native scrollback.

### Phase 3: Program-Level Harness

Add a program-level helper that runs a `Model` with:

- inline `ProgramOptions`;
- a virtual terminal or byte-capturing terminal;
- scripted messages and ticks;
- captured final terminal state.

Use it for examples that emit `Cmd.println` while the UI changes.

## Example Plan

### Artisanal TUI Examples

Replace the current minimal inline examples with a richer directory:

- `inline/bottom_status.dart`: simple status bar plus active log streaming.
- `inline/pinned_build_dashboard.dart`: process-like log stream above a
  dashboard with progress, phase, and key hints.
- `inline/top_panel.dart`: top-pinned monitor with output below it.
- `inline/README.md`: explains which examples demonstrate scrollback,
  log insertion, and top/bottom anchoring.

### Artisanal Widgets Examples

Add widget examples that use `runWidgetApp` with inline options:

- `example/inline_status_dashboard/main.dart`: bottom-pinned widget dashboard,
  log stream above, no mouse capture by default.
- `example/inline_build_monitor/main.dart`: compact multi-panel build monitor
  with responsive staged progress, live metrics, keyboard controls, and logs
  emitted through `Cmd.println` into native terminal scrollback.

These should be usable standalone, not just screenshots.

## Execution Order

1. Add ANSI helpers and renderer inline viewport state.
2. Replace ad hoc bottom inline `printLine` behavior with a dedicated
   scroll-region insertion primitive.
3. Add byte-level tests for the primitive.
4. Add the virtual terminal harness and scrollback invariants.
5. Update the current inline examples.
6. Add widget inline examples.
7. Revisit `flutter_cli_port` after the shared inline foundation is stable.

## Non-Goals For This Pass

- Do not make UV responsible for scrollback.
- Do not complete the full `flutter-cli` port here.
- Do not rely on terminal screenshots as the only proof.
- Do not optimize every terminal/mux strategy before the fixed-bottom,
  scrollback-preserving baseline is correct.

## Completion Criteria

- There is a documented inline architecture in the repo.
- Bottom inline mode has a dedicated log insertion primitive.
- Tests prove scroll-region byte contracts.
- Tests prove terminal-state behavior with a virtual terminal harness.
- Artisanal TUI has compelling inline examples that stream logs while pinned.
- Artisanal Widgets has at least one compelling inline example.
- Focused analyzer/test commands pass for the touched areas.
