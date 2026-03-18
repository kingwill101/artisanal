# TUI System (Bubble Tea-inspired)

The TUI system provides an Elm Architecture-based framework for building interactive terminal user interfaces. It's inspired by [Charm's Bubble Tea](https://github.com/charmbracelet/bubbletea) for Go.

## Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Model Interface](#model-interface)
- [Program Class](#program-class)
- [Command System (Cmd)](#command-system-cmd)
- [Message Types (Msg)](#message-types-msg)
- [Interrupt Handling](#interrupt-handling)
- [View Rendering](#view-rendering)
- [Markdown Rendering](#markdown-rendering)
- [Built-in Bubbles (Components)](#built-in-bubbles-components)
- [Creating Custom Components](#creating-custom-components)
- [Composing Components](#composing-components)
- [Message Filtering](#message-filtering)
- [Program Interceptors](#program-interceptors)
- [Replay Automation](#replay-automation)
- [UV Renderer Integration](#uv-renderer-integration)
- [Helper Functions](#helper-functions)
- [Best Practices](#best-practices)
- [Import](#import)
- [Related Docs](#related-docs)

## Overview

The Elm Architecture (TEA) is a pattern for building interactive applications with three core concepts:

```
┌─────────────────────────────────────────────────────────────┐
│                       Program Runtime                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│    ┌──────────┐     ┌──────────┐     ┌──────────┐         │
│    │  Model   │────▶│  View    │────▶│ Terminal │         │
│    │  (State) │     │ (Render) │     │ (Output) │         │
│    └────▲─────┘     └──────────┘     └──────────┘         │
│         │                                                   │
│    ┌────┴─────┐     ┌──────────┐     ┌──────────┐         │
│    │  Update  │◀────│   Msg    │◀────│  Input   │         │
│    │ (Logic)  │     │ (Events) │     │ (Stdin)  │         │
│    └──────────┘     └──────────┘     └──────────┘         │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

1. **Model** - Immutable state of your application
2. **Update** - Pure function that handles messages and returns new state
3. **View** - Pure function that renders state to the terminal

## Quick Start

```dart
import 'package:artisanal/tui.dart';

class CounterModel implements Model {
  final int count;
  const CounterModel([this.count = 0]);

  @override
  Cmd? init() => null;

  @override
  (Model, Cmd?) update(Msg msg) {
    return switch (msg) {
      KeyMsg(key: Key(type: KeyType.up)) => (CounterModel(count + 1), null),
      KeyMsg(key: Key(type: KeyType.down)) => (CounterModel(count - 1), null),
      KeyMsg(key: Key(type: KeyType.runes, runes: [0x71])) => (this, Cmd.quit()),
      _ => (this, null),
    };
  }

  @override
  String view() => '''
Counter: $count

Press ↑/↓ to change, q to quit
''';
}

void main() async {
  await runProgram(CounterModel());
}
```

## Model Interface

The `Model` interface defines the core contract for TUI applications:

```dart
abstract class Model {
  /// Called once at startup, returns an optional initial command
  Cmd? init() => null;

  /// Handles messages and returns (newState, optionalCommand)
  (Model, Cmd?) update(Msg msg);

  /// Renders current state to a string or View object
  Object view();
}
```

### Immutability

Models should be immutable - create new instances rather than mutating:

```dart
class TodoModel implements Model {
  final List<String> items;
  final int cursor;
  
  const TodoModel({this.items = const [], this.cursor = 0});
  
  // Good: copyWith pattern for updates
  TodoModel copyWith({List<String>? items, int? cursor}) {
    return TodoModel(
      items: items ?? this.items,
      cursor: cursor ?? this.cursor,
    );
  }
  
  @override
  (Model, Cmd?) update(Msg msg) {
    return switch (msg) {
      KeyMsg(key: Key(type: KeyType.down)) =>
        (copyWith(cursor: (cursor + 1).clamp(0, items.length - 1)), null),
      _ => (this, null),
    };
  }
}
```

## Program Class

The `Program` class manages the runtime lifecycle:

```dart
final program = Program(
  MyModel(),
  options: ProgramOptions(
    altScreen: true,        // Use alternate screen buffer
    mouse: true,            // Enable mouse tracking
    fps: 60,                // Maximum frames per second
    frameTick: true,        // Auto-send FrameTickMsg
    hideCursor: true,       // Hide cursor during execution
    bracketedPaste: false,  // Enable bracketed paste mode
    catchPanics: true,      // Catch exceptions and restore terminal
  ),
);

await program.run();
```

### ProgramOptions

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `altScreen` | `bool` | `true` | Use alternate screen buffer (fullscreen mode) |
| `mouse` | `bool` | `false` | Enable mouse tracking |
| `mouseMode` | `MouseMode` | `none` | Mouse tracking mode (`none`, `cellMotion`, `allMotion`) |
| `fps` | `int` | `60` | Maximum frames per second (1-120) |
| `frameTick` | `bool` | `true` | Auto-send FrameTickMsg at configured fps |
| `hideCursor` | `bool` | `true` | Hide cursor during execution |
| `bracketedPaste` | `bool` | `false` | Enable bracketed paste mode |
| `inputTimeout` | `Duration` | `50ms` | Timeout for incomplete escape sequences |
| `catchPanics` | `bool` | `true` | Catch exceptions and restore terminal |
| `filter` | `MessageFilter?` | `null` | Filter messages before reaching model |
| `interceptor` | `ProgramInterceptor?` | `null` | Hook for message interception, automation, and timing |
| `replay` | `ProgramReplay?` | `null` | Stream/script source for automatic message injection |
| `blockInputWhileReplay` | `bool` | `false` | Drop terminal input while replay stream is active |
| `signalHandlers` | `bool` | `true` | Install signal handlers (SIGINT, SIGWINCH) |
| `sendInterrupt` | `bool` | `true` | Deliver SIGINT/Ctrl+C as `InterruptMsg` instead of a Ctrl+C `KeyMsg` |
| `startupTitle` | `String?` | `null` | Set window title on startup |
| `useUltravioletRenderer` | `bool` | `true` | Use UV cell-based renderer |

Convenience helpers are available on `ProgramOptions`:

- `withFilter(...)` / `withoutFilter()`
- `withInterceptor(...)` / `withoutInterceptor()`
- `withReplay(...)` / `withoutReplay()`
- `withReplayInputBlocking(...)`
- `withoutInterruptMsg()`

### Renderers and Output Modes

```dart
final program = Program(
  MyModel(),
  options: ProgramOptions(
    ansiCompress: true,
    useUltravioletRenderer: true,
  ),
);
await program.run();

final compressed = compressAnsi('\x1b[1mBold\x1b[0m');
print(compressed);
```

### Terminal Integration

```dart
final program = Program(
  MyModel(),
  options: ProgramOptions(
    inputTTY: true,
    altScreen: false,
  ),
);
await program.run();

final stream = sharedStdinStream;
await shutdownSharedStdinStream();
```

### Convenience Functions

```dart
// Simple way to run a program
await runProgram(MyModel());

// With options
await runProgram(
  MyModel(),
  options: const ProgramOptions(
    altScreen: true,
    mouse: true,
  ),
);
```

## Command System (Cmd)

Commands represent side effects - async operations that may produce messages.

### Built-in Commands

```dart
// No-op command
Cmd.none()

// Exit the program
Cmd.quit()

// Send a message after delay
Cmd.tick(Duration(seconds: 1), (_) => TimerMsg())

// Repeating timer
every(Duration(milliseconds: 100), (time) => AnimateMsg())

// Run multiple finite commands concurrently
Cmd.batch([cmd1, cmd2, cmd3])

// Run commands through Program execution (required for EveryCmd/StreamCmd)
ParallelCmd([cmd1, cmd2, cmd3])

// Run commands in sequence
Cmd.sequence([cmd1, cmd2, cmd3])

// Immediately send a message
Cmd.message(MyMsg())

// Force repaint
Cmd.repaint()

// Set window title
Cmd.setWindowTitle('My App')

// Execute external process
Cmd.exec(
  'ls',
  ['-la'],
  onComplete: (result) => ProcessCompleteMsg(result),
)
```

### Custom Commands with Cmd.perform

```dart
Cmd? init() {
  return Cmd.perform(
    () => fetchDataFromApi(),
    onSuccess: (data) => DataLoadedMsg(data),
    onError: (error, stack) => ErrorMsg(error.toString()),
  );
}
```

### StreamCmd for Continuous Events

```dart
// Subscribe to a stream
StreamCmd(
  stream: myStream,
  onData: (data) => DataReceivedMsg(data),
  onError: (error, stack) => StreamErrorMsg(error),
  onDone: () => StreamDoneMsg(),
)
```

### EveryCmd for Repeating Timers

```dart
// Animation tick every 100ms
EveryCmd(
  interval: const Duration(milliseconds: 100),
  callback: (time) => AnimationTickMsg(),
)
```

### Cmd.batch vs ParallelCmd

`Cmd.batch()` executes child commands via `cmd.execute()` and combines the
results into a `BatchMsg`. This is ideal for normal finite commands like
`Cmd.perform`, `Cmd.tick`, and `Cmd.message`.

`ParallelCmd()` dispatches each child command through `Program._executeCommand`.
Use this when a command list may contain runtime-managed command types like
`EveryCmd` and `StreamCmd` (including helpers like `every(...)`), since those
must be started by the Program runtime.

```dart
// Good: finite commands
Cmd.batch([
  Cmd.perform(loadUser, onSuccess: UserLoadedMsg.new),
  Cmd.perform(loadSettings, onSuccess: SettingsLoadedMsg.new),
])

// Good: includes repeating timer
ParallelCmd([
  every(const Duration(milliseconds: 120), (_) => SpinnerTickMsg()),
  Cmd.perform(fetchData, onSuccess: DataLoadedMsg.new),
])
```

## Message Types (Msg)

Messages are events that trigger state updates:

### Input Messages

```dart
// Keyboard input
KeyMsg(key: Key(KeyType.enter))
KeyMsg(key: Key(KeyType.runes, runes: [0x61])) // 'a'
KeyMsg(key: Key(KeyType.runes, ctrl: true, runes: [0x63])) // Ctrl+C

// Mouse input
MouseMsg(
  action: MouseAction.press,
  button: MouseButton.left,
  x: 10,
  y: 5,
)

// Window resize
WindowSizeMsg(80, 24)

// Focus change
FocusMsg(true)

// Pasted text (bracketed paste mode)
PasteMsg('pasted content')
```

### Timer Messages

```dart
// From Cmd.tick
TickMsg(DateTime.now(), id: 'myTimer')

// From frameTick option
FrameTickMsg(
  time: DateTime.now(),
  frameNumber: 42,
  delta: Duration.zero,
)
```

### Control Messages

```dart
// Quit signal
QuitMsg()

// Interrupt (default Ctrl+C behavior)
InterruptMsg()

// Batch multiple messages
BatchMsg([msg1, msg2, msg3])
```

By default, terminal Ctrl+C is delivered as `InterruptMsg`, not as
`KeyMsg(key: Key(ctrl: true, ...))`. This makes interrupt handling explicit and
keeps it separate from normal key bindings. If you need the legacy key-based
behavior, set `ProgramOptions(sendInterrupt: false)` or call
`ProgramOptions().withoutInterruptMsg()`.

## Interrupt Handling

Use `InterruptMsg` when you want to react to a real terminal interrupt such as
Ctrl+C:

```dart
@override
(Model, Cmd?) update(Msg msg) {
  return switch (msg) {
    InterruptMsg() when hasUnsavedChanges => (
      copyWith(showConfirmQuit: true),
      null,
    ),
    InterruptMsg() => (this, Cmd.quit()),
    _ => (this, null),
  };
}
```

If you explicitly want Ctrl+C to arrive as a `KeyMsg`, opt out of interrupt
messages:

```dart
await runProgram(
  MyModel(),
  options: ProgramOptions().withoutInterruptMsg(),
);
```

### Extended Messages

```dart
// Terminal background color response
BackgroundColorMsg(hex: '#0f172a')

// Clipboard response
ClipboardMsg(selection: ClipboardSelection.system, content: 'copied text')

// Render metrics for profiling
RenderMetricsMsg(RenderMetrics())
```

### Custom Messages

```dart
class DataLoadedMsg extends Msg {
  final List<String> items;
  const DataLoadedMsg(this.items);
}

class ErrorMsg extends Msg {
  final String message;
  const ErrorMsg(this.message);
}
```

## View Rendering

The `view()` method can return a `String` or a `View` object:

### Simple String View

```dart
@override
String view() {
  return '''
╔════════════════════════╗
║     My Application     ║
╚════════════════════════╝

Items: ${items.length}
Selected: ${items[cursor]}

↑/↓: Navigate  q: Quit
''';
}
```

### View Object with Metadata

```dart
@override
View view() {
  return View(
    content: renderContent(),
    cursor: Cursor.at(cursorX, cursorY),             // Show cursor at position
    windowTitle: 'My App - Page $page',              // Window title
    progressBar: TerminalProgressBar(
      state: TerminalProgressBarState.defaultState,
      value: progress,
    ),
    mouseMode: MouseMode.allMotion,                  // Dynamic mouse mode
  );
}
```

## Markdown Rendering

```dart
import 'package:artisanal/markdown.dart';

@override
View view() {
  final content = markdownToAnsi('# Title\n\n* bullet');
  return View(content: content);
}
```

## Built-in Bubbles (Components)

Artisanal includes pre-built interactive components called "bubbles":

### TextInputModel

```dart
final input = TextInputModel(
  placeholder: 'Enter your name...',
  prompt: '> ',
  charLimit: 50,
  width: 40,
  echoMode: EchoMode.normal, // normal, password, none
);

// In update:
final (newInput, cmd) = input.update(msg);

// In view:
return input.view();

// Get value:
final text = input.value;
```

### ListModel

```dart
final list = ListModel(
  items: ['Apple', 'Banana', 'Cherry'].map(StringItem.new).toList(),
  delegate: DefaultItemDelegate(),
  height: 5,
  showFilter: true,
);

// In update:
final (newList, cmd) = list.update(msg);

// Get selected item:
final selected = list.selectedItem;
```

### ConfirmModel

```dart
final confirm = ConfirmModel(
  prompt: 'Delete all files?',
  defaultValue: true,
);

// Check result:
if (confirm.value) {
  // User confirmed
}
```

### SpinnerModel

```dart
final spinner = SpinnerModel(
  spinner: Spinners.dot,  // or: line, pulse, globe, moon, etc.
);

// In init:
Cmd? init() => spinner.tick();

// In update:
final (newSpinner, cmd) = spinner.update(msg);
```

Available spinner presets in `Spinners`:
- `line`, `dot`, `miniDot`, `jump`
- `pulse`, `points`, `globe`, `moon`
- `monkey`, `meter`, `hamburger`, `ellipsis`

### FilePickerModel

```dart
final picker = FilePickerModel(
  currentDirectory: Directory.current.path,
  fileAllowed: true,
  dirAllowed: false,
  allowedTypes: ['.dart', '.yaml'],
);

// Get selected path:
final path = picker.selectedPath;
```

### WizardModel

```dart
final wizard = WizardModel(
  steps: [
    WizardStep.textInput(
      key: 'name',
      prompt: 'Enter your name:',
      validate: (v) => v.isNotEmpty ? null : 'Name required',
    ),
    WizardStep.select(
      key: 'language',
      prompt: 'Choose language:',
      options: ['Dart', 'Go', 'Rust'],
    ),
    WizardStep.confirm(
      key: 'confirm',
      prompt: 'Proceed?',
    ),
  ],
);

// Get all answers:
final answers = wizard.answers; // Map<String, dynamic>
```

### PaginatorModel

```dart
final paginator = PaginatorModel(
  totalPages: 10,
  currentPage: 0,
  style: PaginatorStyle.dots, // or: arabic
);
```

## Creating Custom Components

### ViewComponent Interface

```dart
class MyComponent implements ViewComponent {
  final String label;
  const MyComponent(this.label);

  @override
  (ViewComponent, Cmd?) init() => (this, null);

  @override
  (ViewComponent, Cmd?) update(Msg msg) {
    // Handle messages
    return (this, null);
  }

  @override
  String view() => '[$label]';
}
```

### StaticComponent (No State Updates)

```dart
class HeaderComponent extends StaticComponent {
  final String title;
  const HeaderComponent(this.title);

  @override
  String view() => '''
╔════════════════════════════════╗
║  $title  ║
╚════════════════════════════════╝
''';
}
```

## Composing Components

Use the `ComponentHost` mixin to manage child components:

```dart
class AppModel with ComponentHost implements Model {
  TextInputModel searchInput;
  ListModel itemList;
  
  AppModel({
    required this.searchInput,
    required this.itemList,
  });

  @override
  Cmd? init() => null;

  @override
  (Model, Cmd?) update(Msg msg) {
    final (_, inputCmd) = updateComponent(
      searchInput,
      msg,
      (next) => searchInput = next,
    );
    final (_, listCmd) = updateComponent(
      itemList,
      msg,
      (next) => itemList = next,
    );
    return (this, Cmd.batch([if (inputCmd != null) inputCmd, if (listCmd != null) listCmd]));
  }

  @override
  String view() {
    return '''
Search: ${searchInput.view()}

${itemList.view()}
''';
  }
}
```

## Message Filtering

Filter or transform messages before they reach the model:

```dart
Msg? preventUnsavedQuit(Model model, Msg msg) {
  if (msg is InterruptMsg &&
      model is EditorModel &&
      model.hasUnsavedChanges) {
    // Show warning instead of quitting.
    return const ShowUnsavedWarningMsg();
  }
  return msg; // Allow message through.
}

final program = Program(
  EditorModel(),
  options: ProgramOptions(filter: preventUnsavedQuit),
);
```

## Program Interceptors

`ProgramInterceptor` lets you observe and control runtime message flow.
It is a core `Program` feature and works with any TUI model/application.

```dart
class MetricsInterceptor extends ProgramInterceptor {
  final List<Duration> keyDurations = [];

  @override
  Msg? onSend(Msg msg) {
    // Drop noisy hover events in this run.
    if (msg is MouseMsg &&
        msg.action == MouseAction.motion &&
        msg.button == MouseButton.none) {
      return null;
    }
    return msg;
  }

  @override
  void onProcessed(Msg msg, Duration elapsed) {
    if (msg is KeyMsg) keyDurations.add(elapsed);
  }
}

final program = Program(
  MyModel(),
  options: ProgramOptions(
    interceptor: MetricsInterceptor(),
  ),
);
```

Lifecycle hooks:

- `onStart(send)` fires once after initial render; use `send(...)` to inject messages.
- `onSend(msg)` runs before queueing; return `null` to drop.
- `onProcessed(msg, elapsed)` runs after each message is processed.
- `onStop()` runs during cleanup.

## Replay Automation

`ProgramReplay` provides deterministic event playback for demos, tests, and perf runs.
It is runtime-level automation, not tied to any specific example app.

### Script Replay

```dart
final replay = ProgramReplay.script([
  ProgramReplayStep(
    after: Duration(milliseconds: 120),
    msg: MouseMsg(
      action: MouseAction.wheel,
      button: MouseButton.wheelDown,
      x: 82,
      y: 14,
    ),
  ),
  ProgramReplayStep(
    after: Duration(milliseconds: 16),
    msg: KeyMsg(Key(KeyType.runes, runes: [0x61])), // 'a'
  ),
  ProgramReplayStep(after: Duration(milliseconds: 10), msg: QuitMsg()),
]);

await runProgram(
  MyModel(),
  options: ProgramOptions(replay: replay),
);
```

### Stream Replay

```dart
final controller = StreamController<Msg>();

await runProgram(
  MyModel(),
  options: ProgramOptions(
    replay: ProgramReplay.stream(controller.stream),
  ),
);

controller.add(const CustomMsg('step-1'));
controller.add(const QuitMsg());
```

### Deterministic Replay (Block Manual Input)

```dart
await runProgram(
  MyModel(),
  options: ProgramOptions(
    replay: replay,
    blockInputWhileReplay: true,
  ),
);
```

Notes:

- Replay messages are injected through `Program.send(...)`, so filters/interceptors still apply.
- Replay does not quit automatically; include `QuitMsg` (or call `program.quit()`) when needed.
- Replay and real terminal input can run together for mixed-mode automation.
- Set `blockInputWhileReplay: true` to ignore manual key/mouse input until replay completes.
- Custom replay `event` actions are supported. Register `eventHook` in
  `ReplayScenario.toProgramReplay(...)` / `replayScenarioStream(...)` to run
  synchronous or asynchronous (`FutureOr`) handlers and decide replay behavior
  (`proceed`, `stop`, or `quit`).

## Trace Logging

The TUI runtime includes an opt-in file tracer (`TuiTrace`) for input, queue,
dispatch, render, and command timing diagnostics.

Environment variables:

- `ARTISANAL_TUI_TRACE=1`: enable trace logging.
- `ARTISANAL_TUI_TRACE_PATH=/path/to/file.log`: explicit trace file path.
- `ARTISANAL_TUI_TRACE_CAPTURE=1`: include dispatch-capture diagnostics.
- `ARTISANAL_TUI_TRACE_TAGS=input,queue,dispatch`: optional trace tag allow-list.

When `ARTISANAL_TUI_TRACE_PATH` is unset, the tracer writes to
`./traces/artisanal-YYYY-MM-DDTHH-MM-SS.log` relative to the current working
directory.

Trace headers include wall-clock start time, PID, CWD, executable/script info,
capture flag state, and active trace-tag filter.

Structured trace events use a strict, versioned schema:

- marker: `@event`
- protocol keys: `v`, `type`
- current `type` values:
  - `input.batch` with `parser`, `flush`, `dropped`, `messages`
  - `window.size` with `width`, `height`
  - any additional custom type (for example `ui.sidebar.toggle`) is preserved
    by trace conversion as replay `event` actions
- message payload keys in `input.batch.messages` include:
  - key: `kind=key`, `keyType`, `runes`, modifier flags
  - mouse: `kind=mouse`, `action`, `button`, `x`, `y`

Use `TuiTrace.tryParseEventLine(...)` to consume trace events without regex.
This gives apps/custom tooling a stable contract for type-specific replay and
interceptor logic.

### Extension Log Routing

Application config can support extension log routing under
`tui.extensionLogMode`:

- `ui` (default): route `app.log.*` through the UI bridge (safe for TUI)
- `stdout`: write logs to terminal stdout directly
- `off`: suppress extension log output

```json
{
  "tui": {
    "extensionLogMode": "ui"
  }
}
```

## Replay + Trace Workflow (OpenCode Example)

Record a manual run:

```bash
ARTISANAL_TUI_TRACE=1 ARTISANAL_TUI_TRACE_CAPTURE=1 \
ARTISANAL_TUI_TRACE_PATH="pkgs/artisanal_widgets/example/opencode/traces/manual-$(date +%Y-%m-%dT%H-%M-%S).log" \
dart run pkgs/artisanal_widgets/example/opencode/main.dart
```

Convert trace to replay scenario:

```bash
LATEST_TRACE="$(ls -1t pkgs/artisanal_widgets/example/opencode/traces/*.log | head -n1)"
dart run pkgs/artisanal_widgets/example/opencode/main.dart \
  --replay-trace "$LATEST_TRACE" \
  --replay-trace-out pkgs/artisanal_widgets/example/opencode/scenarios/manual_from_trace.json \
  --replay-trace-name manual_from_trace \
  --replay-convert-only
```

Replay deterministically (and block manual input):

```bash
dart run pkgs/artisanal_widgets/example/opencode/main.dart \
  --replay-scenario pkgs/artisanal_widgets/example/opencode/scenarios/manual_from_trace.json \
  --replay-block-input \
  --replay-speed 8
```

Inspect top trace hotspots after a run:

```bash
python pkgs/artisanal_widgets/example/opencode/analyze_trace.py \
  "$LATEST_TRACE" --top 12
```

The analyzer summarizes high-cost handlers and event categories.

## UV Renderer Integration

The TUI system can use the Ultraviolet cell-based renderer for optimized rendering:

```dart
final program = Program(
  MyModel(),
  options: ProgramOptions(
    useUltravioletRenderer: true, // Default
  ),
);
```

The UV renderer provides:
- Diff-based rendering (only update changed cells)
- Proper wide character handling
- Graphics protocol support (Sixel, Kitty, iTerm2)
- Synchronized output for flicker-free updates

## Helper Functions

```dart
// Create update result with no command
UpdateResult noCmd(Model model) => (model, null);

// Create update result that quits
UpdateResult quit(Model model) => (model, Cmd.quit());
```

## Best Practices

1. **Keep Models Immutable** - Use `copyWith` pattern
2. **Pure View Functions** - No side effects in `view()`
3. **Use Pattern Matching** - Dart's `switch` expressions are perfect for `update()`
4. **Choose the Right Command Combiner** - Use `Cmd.batch()` for finite commands; use `ParallelCmd` when including `EveryCmd`/`StreamCmd`
5. **Handle All Key Types** - Include a default case in your update function
6. **Clean Up Resources** - Return cleanup commands when needed

## Import

```dart
// Core TUI framework
import 'package:artisanal/tui.dart';

// Pre-built bubble components
import 'package:artisanal/bubbles.dart';
```

## Related Docs

- [DOCS_INDEX.md](DOCS_INDEX.md) - Full documentation index
- [BUBBLES.md](BUBBLES.md) - Interactive components
- [UV.md](UV.md) - UV renderer integration
- [MARKDOWN.md](MARKDOWN.md) - Markdown rendering
