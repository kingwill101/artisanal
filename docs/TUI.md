# TUI System (Bubble Tea-inspired)

The TUI system provides an Elm Architecture-based framework for building interactive terminal user interfaces. It's inspired by [Charm's Bubble Tea](https://github.com/charmbracelet/bubbletea) for Go.

## Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Model Interface](#model-interface)
- [Program Class](#program-class)
- [Program Hosts](#program-hosts)
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

Focused stable entrypoints:

- `package:artisanal/runtime.dart` for the supported `Model`/`Msg`/`Cmd`/`Program` surface, including `StringTerminal` for deterministic tests and runtime messages like `ZoneInBoundsMsg`
- `package:artisanal/hosts.dart` for backends, bridges, and browser/socket hosts
- `package:artisanal/app.dart`, `package:artisanal/editors.dart`, `package:artisanal/selection.dart`, and `package:artisanal/testing.dart` for the stable widget modules re-exported by the umbrella package
- `package:artisanal/tui.dart` for the broader compatibility barrel, including bubbles and the widget re-export

```dart
import 'package:artisanal/runtime.dart';

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
    mouseMode: MouseMode.allMotion, // Enable passive hover tracking
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
| `sendSuspendSignal` | `bool` | `true` | Let `SuspendMsg` send `SIGTSTP`; disable it to exercise suspend release/restore without suspending the parent process |
| `startupTitle` | `String?` | `null` | Set window title on startup |
| `useUltravioletRenderer` | `bool` | `true` | Use UV cell-based renderer |
| `startupProbes` | `bool?` | `null` | Force startup probes on/off; `null` auto-runs only on built-in terminals |

`mouse: true` alone enables `MouseMode.cellMotion`, which reports clicks,
wheel input, and pointer motion while a button is pressed. Use
`MouseMode.allMotion` for passive hover behavior such as tooltips and
`MouseRegion` enter/exit callbacks.

Convenience helpers are available on `ProgramOptions`:

- `withFilter(...)` / `withoutFilter()`
- `withInterceptor(...)` / `withoutInterceptor()`
- `withReplay(...)` / `withoutReplay()`
- `withReplayInputBlocking(...)`
- `withoutInterruptMsg()`
- `withStartupProbes(...)`

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

### Startup Probes

`model.init()` is started before the first frame, but `Program` does not block
the initial paint on long-running init commands. Immediately-resolved init
messages are drained into the same startup turn so they can affect the first
render, while slower timers/processes/streams continue in the background after
the first frame is shown.

When UV rendering and UV input decoding are both enabled on a real terminal,
`Program` runs a small set of best-effort startup probes:

- before the first render: background color and color scheme
- after the first render: DA2 and kitty keyboard support
- after the first render in alt-screen mode: emoji width probing

By default, this auto-runs only for the built-in terminal implementations
(`StdioTerminal`, `SplitTerminal`, `TtyTerminal`, and backend terminals). If
you inject a custom terminal, probes are skipped unless you opt in with
`ProgramOptions(startupProbes: true)` or
`ProgramOptions().withStartupProbes(true)`.

These probes are intentionally short-lived and do not block forever. Critical
lifecycle events abort the active probe immediately and skip the remaining
probe sequence:

- `QuitMsg`
- `InterruptMsg`
- legacy `Ctrl+C` key input
- backend shutdown/disconnect requests from browser/socket/embedded hosts

That keeps startup responsive even when a remote host disconnects or the user
quits while probing is still in progress.

### Program Hosts

`ProgramHost` packages backend selection separately from your model and
`ProgramOptions`. Use it when you want a reusable launch target for stdio,
split-TTY, embedded terminals, or future remote/web backends.

```dart
await runProgram(
  MyModel(),
  host: ProgramHost.stdio(inputTTY: true),
);

final backend = EmbeddedTerminalBackend(
  output: (data) => socket.write(data),
);
await runProgram(
  MyModel(),
  options: const ProgramOptions(altScreen: false, frameTick: false),
  host: ProgramHost.backend(backend),
);

final bridge = TerminalBridge(initialSize: (width: 120, height: 32));
bridge.output.listen((data) => xterm.write(data));
xterm.onData(bridge.addInputString);
xterm.onResize((size) {
  bridge.resize(width: size.cols, height: size.rows);
});
await runProgram(
  MyModel(),
  options: const ProgramOptions(altScreen: false),
  host: ProgramHost.bridge(bridge),
);

await runProgram(
  MyModel(),
  host: ProgramHost.socket(socket),
);

final socketServer = await SocketTerminalHostServer.serveProgram(
  port: 2323,
  modelBuilder: () => MyModel(),
);
print('Connect with: nc 127.0.0.1:${socketServer.server.port}');

final terminal = StringTerminal();
await runProgram(
  MyModel(),
  options: const ProgramOptions(altScreen: false),
  host: ProgramHost.terminal(terminal),
);

await runProgram(
  MyModel(),
  host: ProgramHost.custom((options) {
    return ProgramHostBinding(
      options: options.copyWith(startupTitle: 'Embedded demo'),
      terminal: terminal,
    );
  }),
);
```

Use the helpers that fit the current runtime:

- `ProgramHost.stdio(...)` keeps the built-in stdio selection but can opt into
  `inputTTY: true`
- `ProgramHost.backend(...)` wraps a `TerminalBackend` such as
  `StdioTerminalBackend` or `EmbeddedTerminalBackend`
- `ProgramHost.bridge(...)` wraps a `TerminalBridge` for hosts that already
  expose callbacks or streams for output, input, and resize
- `ProgramHost.jsonChannel(...)` wraps any message-oriented transport using the
  JSON bridge protocol
- `ProgramHost.webSocket(...)` is the websocket-specific JSON bridge host
- `ProgramHost.socket(...)` creates a `SocketTerminalBackend` for shell/remote
  transport and understands `OSC 9999;<cols>;<rows>` resize updates
- `SocketTerminalHostServer.bind(...)` accepts raw TCP terminal sessions
- `SocketTerminalHostServer.serveProgram(...)` runs one program per TCP client
- `ProgramHost.terminal(...)` uses an already-created terminal implementation
- `ProgramHost.split(...)` uses separate control/output terminals
- `ProgramHost.custom(...)` is the extension point for embedded, socket, PTY,
  or browser-style hosts

For raw socket clients, report resize events with:

```text
ESC ] 9999 ; <cols> ; <rows> BEL
```

Use `SocketTerminalHostServer.resizeControlSequence(...)` or
`SocketTerminalHostServer.resizeControlBytes(...)` instead of constructing
that control string by hand.

Host shutdown is explicit too:

- `SocketTerminalHostServer.close(force: true)` tears down active client
  sockets immediately and still waits for session cleanup before returning
- `BrowserTerminalHostServer.close(force: true)` closes active websocket
  sessions immediately and still waits for session cleanup before returning
- backend disconnects surface as `InterruptMsg` by default and now also fall
  back to `QuitMsg` shutdown if the model ignores the interrupt

`TerminalBridge` is the recommended controller surface for browser terminals,
GUI widgets, or other embedded hosts:

- `output.listen(...)` receives terminal writes
- `addInput(...)` / `addInputString(...)` forward host input to the runtime
- `resize(...)` reports host viewport changes
- `requestShutdown()` forwards close or interrupt events

When the host lives in another process, tab, or runtime, layer
`TerminalBridgeJsonChannel` over the bridge. It serializes host/runtime traffic
as small JSON objects:

```dart
final bridge = TerminalBridge(initialSize: (width: 120, height: 32));
final channel = TerminalBridgeJsonChannel(bridge);

channel.outboundMessages.listen(webSocket.add);
webSocket.listen(channel.addInboundJson);

await runProgram(
  MyModel(),
  options: const ProgramOptions(altScreen: false),
  host: ProgramHost.bridge(bridge),
);
```

Example protocol messages:

```json
{"type":"output","data":"\u001b[?25l"}
{"type":"input.text","data":"q"}
{"type":"resize","width":120,"height":32}
{"type":"shutdown"}
```

For direct host setup without manually constructing a `TerminalBridge`, use
`ProgramHost.jsonChannel(...)` or `ProgramHost.webSocket(...)`:

```dart
await runProgram(
  MyModel(),
  options: const ProgramOptions(altScreen: false),
  host: ProgramHost.jsonChannel(
    sendMessage: socket.add,
    inboundMessages: socket,
  ),
);
```

The package examples include scripted JSON bridge, raw socket, and browser
websocket demos:

- `dart run example/tui/bridge_json_demo.dart`
- `dart run example/tui/socket_host_demo.dart --port=2323`
- `dart run example/tui/browser_websocket_demo.dart --port=8080`

For a reusable server wrapper, use `BrowserTerminalHostServer.bind(...)` or
`BrowserTerminalHostServer.serveProgram(...)`. These helpers serve the default
xterm.js page and wire websocket sessions into your TUI runtime. The default
page also answers the runtime's basic color-scheme, foreground/background/cursor
color, DA1/DA2/DA3, kitty-keyboard, XTVERSION, XTGETTCAP (`RGB`/`TN`),
cursor-position, ModifyOtherKeys, and window/cell-size queries so browser-backed sessions can
participate in startup probing and session-based capability detection. It also
maps OSC 52 clipboard reads and writes onto the browser clipboard when
available, answers private mode reports for focus and bracketed paste, and
forwards browser focus changes and bracketed paste whenever the runtime enables
those terminal modes. It also tracks mouse mode enables for 1000/1002/1003/1006
so mode report queries can reflect hosted mouse state, mirrors OSC 0/2 title updates into the browser
tab title and the page toolbar heading, applies OSC 10/11/12 color changes
plus OSC 110/111/112 resets to the hosted terminal theme, answers later
color-scheme / OSC color queries from that current hosted theme state, tracks
browser `prefers-color-scheme` changes while the hosted session is still using
the page defaults, and supports `OSC 4` palette queries plus palette
set/reset tracking. The built-in toolbar and badges are tinted from the same
hosted theme state so the page chrome stays in sync with light/dark changes.

### Convenience Functions

```dart
// Simple way to run a program
await runProgram(MyModel());

// With options
await runProgram(
  MyModel(),
  options: const ProgramOptions(
    altScreen: true,
    mouseMode: MouseMode.allMotion,
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

`Cmd.suspend()` and `SuspendMsg` normally release the terminal and then send
`SIGTSTP` on Unix. For tests, embedded hosts, or environments that want the
release/restore lifecycle without suspending the parent process, set
`ProgramOptions(sendSuspendSignal: false)` or call
`ProgramOptions().withoutSuspendSignal()`.

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
// Stable core TUI runtime
import 'package:artisanal/runtime.dart';

// Broader compatibility barrel and pre-built bubbles
import 'package:artisanal/bubbles.dart';
```

## Related Docs

- [DOCS_INDEX.md](DOCS_INDEX.md) - Full documentation index
- [BUBBLES.md](BUBBLES.md) - Interactive components
- [UV.md](UV.md) - UV renderer integration
- [MARKDOWN.md](MARKDOWN.md) - Markdown rendering
