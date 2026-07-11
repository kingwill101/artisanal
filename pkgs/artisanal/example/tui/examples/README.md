# Examples

This directory mirrors the Bubble Tea examples as Dart ports. Each folder contains a runnable Dart implementation (`main.dart`) for artisanal's Bubble Tea-style runtime. To try an example from the package root:

```bash
dart run example/tui/examples/<example>/main.dart
```

### Alt Screen Toggle

The `altscreen-toggle` example shows how to transition between the alternative
screen buffer and the normal screen buffer using Bubble Tea.

<a href="./altscreen-toggle/main.dart">
  <img width="750" src="./altscreen-toggle/altscreen-toggle.gif" />
</a>

### Chat

The `chat` examples shows a basic chat application with a multi-line `textarea`
input.

<a href="./chat/main.dart">
  <img width="750" src="./chat/chat.gif" />
</a>

### Composable Views

The `composable-views` example shows how to compose two bubble models (spinner
and timer) together in a single application and switch between them.

<a href="./composable-views/main.dart">
  <img width="750" src="./composable-views/composable-views.gif" />
</a>

### Credit Card Form

The `credit-card-form` example demonstrates how to build a multi-step form with
`textinputs` bubbles and validation on the inputs.

<a href="./credit-card-form/main.dart">
  <img width="750" src="./credit-card-form/credit-card-form.gif" />
</a>

### Debounce

The `debounce` example shows how to throttle key presses to avoid overloading
your Bubble Tea application.

<a href="./debounce/main.dart">
  <img width="750" src="./debounce/debounce.gif" />
</a>

### Layout

The `layout` example shows how to use `Layout.joinVertical` and
`Layout.joinHorizontal` to build a responsive, width-aware card layout.

<a href="./layout/main.dart">
  Code
</a>

### Layout Breakpoints

The `layout-breakpoints` example demonstrates threshold-based layout decisions
using `ResponsiveBreakpoints` with `isAtLeast`, `isBelow`, and `resolve`.

<a href="./layout-breakpoints/main.dart">
  Code
</a>

### Evidence Logging

The `evidence-logging` examples show how to emit runtime `TuiEvidence` records
to JSONL and how to parse them with `TuiEvidence.tryParseLine`.

<a href="./evidence-logging/main.dart">
  Code
</a>

<a href="./evidence-logging/inspect.dart">
  Inspect log utility
</a>

<a href="./evidence-logging/summary.dart">
  Summarize log utility
</a>

<a href="./evidence-logging/toggle.dart">
  Toggle logging mode utility
</a>

<a href="./evidence-logging/render_budget.dart">
  Render-budget diagnostics demo
</a>

### Macro Recorder/Player

The `macro-recorder` example records runtime key traffic into a
`ProgramMacro`, replays it, and demonstrates stopping looped playback.

<a href="./macro-recorder/main.dart">
  Code
</a>

### Exec

The `exec` example shows how to execute a running command during the execution
of a Bubble Tea application such as launching an `EDITOR`.
 
<a href="./exec/main.dart">
  <img width="750" src="./exec/exec.gif" />
</a>

### Full Screen

The `fullscreen` example shows how to make a Bubble Tea application fullscreen.

<a href="./fullscreen/main.dart">
  <img width="750" src="./fullscreen/fullscreen.gif" />
</a>

### Glamour

The `glamour` example shows how to use [Glamour](https://github.com/charmbracelet/glamour) inside a viewport bubble.

<a href="./glamour/main.dart">
  <img width="750" src="./glamour/glamour.gif" />
</a>

### Markdown

The `markdown` example parses Markdown with `package:markdown`, renders ANSI
with `renderMarkdown`, and displays it inside a viewport.

<a href="./markdown/main.dart">
  Code
</a>

### Help

The `help` example shows how to use the `help` bubble to display help to the
user of your application.

<a href="./help/main.dart">
  <img width="750" src="./help/help.gif" />
</a>

### Http

The `http` example shows how to make an `http` call within your Bubble Tea
application.

<a href="./http/main.dart">
  <img width="750" src="./http/http.gif" />
</a>

### Key Chord

The `key-chord` example demonstrates engine-level chord key bindings using
`KeyChordInterceptor`. Prefix keys like `Ctrl+X` are intercepted and a
second key (e.g., `t` or `m`) resolves the chord. Timeout and cancellation
are also shown.

<a href="./key-chord/main.dart">
  Code
</a>

### Inline

The `inline` examples run on the primary terminal screen and preserve native
scrollback while a top or bottom UI remains pinned. The bottom dashboard
examples stream `Cmd.println` output above the UI, which is the same class of
behavior needed by long-running command dashboards.

<a href="./inline/README.md">
  Code
</a>

### Default List

The `list-default` example shows how to use the list bubble.

<a href="./list-default/main.dart">
  <img width="750" src="./list-default/list-default.gif" />
</a>

### Fancy List

The `list-fancy` example shows how to use the list bubble with extra customizations.

<a href="./list-fancy/main.dart">
  <img width="750" src="./list-fancy/list-fancy.gif" />
</a>

### Simple List

The `list-simple` example shows how to use the list and customize it to have a simpler, more compact, appearance.

<a href="./list-simple/main.dart">
  <img width="750" src="./list-simple/list-simple.gif" />
</a>

### Mouse

The `mouse` example shows how to receive mouse events in a Bubble Tea
application.

<a href="./mouse/main.dart">
  Code
</a>

### Package Manager

The `package-manager` example shows how to build an interface for a package
manager using output commands such as `tui.Cmd.println` / `tui.Cmd.printf`.

<a href="./package-manager/main.dart">
  <img width="750" src="./package-manager/package-manager.gif" />
</a>

### Pager

The `pager` example shows how to build a simple pager application similar to
`less`.

<a href="./pager/main.dart">
  <img width="750" src="./pager/pager.gif" />
</a>

### Paginator

The `paginator` example shows how to build a simple paginated list.

<a href="./paginator/main.dart">
  <img width="750" src="./paginator/paginator.gif" />
</a>

### Pipe

The `pipe` example demonstrates using shell pipes to communicate with Bubble
Tea applications.

<a href="./pipe/main.dart">
  <img width="750" src="./pipe/pipe.gif" />
</a>

### Animated Progress

The `progress-animated` example shows how to build a progress bar with an
animated progression.

<a href="./progress-animated/main.dart">
  <img width="750" src="./progress-animated/progress-animated.gif" />
</a>

### Download Progress

The `progress-download` example demonstrates how to download a file while
indicating download progress through Bubble Tea.

<a href="./progress-download/main.dart">
  Code
</a>

### Static Progress

The `progress-static` example shows a progress bar with static incrementation
of progress.

<a href="./progress-static/main.dart">
  <img width="750" src="./progress-static/progress-static.gif" />
</a>

### Real Time

The `realtime` example demonstrates the use of go channels to perform realtime
communication with a Bubble Tea application.

<a href="./realtime/main.dart">
  <img width="750" src="./realtime/realtime.gif" />
</a>

### Result

The `result` example shows a choice menu with the ability to select an option.

<a href="./result/main.dart">
  <img width="750" src="./result/result.gif" />
</a>

### Send Msg

The `send-msg` example demonstrates the usage of custom `tui.Msg`s.

<a href="./send-msg/main.dart">
  <img width="750" src="./send-msg/send-msg.gif" />
</a>

### Sequence

The `sequence` example demonstrates the `tui.Cmd.sequence` command.

<a href="./sequence/main.dart">
  <img width="750" src="./sequence/sequence.gif" />
</a>

### Simple

The `simple` example shows a very simple Bubble Tea application.

<a href="./simple/main.dart">
  <img width="750" src="./simple/simple.gif" />
</a>

### Spinner

The `spinner` example demonstrates a spinner bubble being used to indicate loading.

<a href="./spinner/main.dart">
  <img width="750" src="./spinner/spinner.gif" />
</a>

### Spinners

The `spinner` example shows various spinner types that are available.

<a href="./spinners/main.dart">
  <img width="750" src="./spinners/spinners.gif" />
</a>

### Split Editors

The `split-editors` example shows multiple `textarea`s being used in a single
application and being able to switch focus between them.

<a href="./split-editors/main.dart">
  <img width="750" src="./split-editors/split-editors.gif" />
</a>

### Stop Watch

The `stopwatch` example shows a sample stop watch built with Bubble Tea.

<a href="./stopwatch/main.dart">
  <img width="750" src="./stopwatch/stopwatch.gif" />
</a>

### Table

The `table` example demonstrates the table bubble being used to display tabular
data.

<a href="./table/main.dart">
  <img width="750" src="./table/table.gif" />
</a>

### Tabs

The `tabs` example demonstrates tabbed navigation styled with [Lip Gloss](https://github.com/charmbracelet/lipgloss).

<a href="./tabs/main.dart">
  <img width="750" src="./tabs/tabs.gif" />
</a>

### Text Area

The `textarea` example demonstrates a simple Bubble Tea application using a
`textarea` bubble.

<a href="./textarea/main.dart">
  <img width="750" src="./textarea/textarea.gif" />
</a>

### Text Input

The `textinput` example demonstrates a simple Bubble Tea application using a `textinput` bubble.

<a href="./textinput/main.dart">
  <img width="750" src="./textinput/textinput.gif" />
</a>

### Multiple Text Inputs

The `textinputs` example shows multiple `textinputs` and being able to switch
focus between them as well as changing the cursor mode.

<a href="./textinputs/main.dart">
  <img width="750" src="./textinputs/textinputs.gif" />
</a>

### Timer

The `timer` example shows a simple timer built with Bubble Tea.

<a href="./timer/main.dart">
  <img width="750" src="./timer/timer.gif" />
</a>

### TUI Daemon

The `tui-daemon-combo` demonstrates building a text-user interface along with a
daemon mode using Bubble Tea.

<a href="./tui-daemon-combo/main.dart">
  <img width="750" src="./tui-daemon-combo/tui-daemon-combo.gif" />
</a>

### Views

The `views` example demonstrates how to build a Bubble Tea application with
multiple views and switch between them.

<a href="./views/main.dart">
  <img width="750" src="./views/views.gif" />
</a>
