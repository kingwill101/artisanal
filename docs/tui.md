# TUI System (Bubble Tea-inspired)

The TUI system provides an Elm Architecture-based framework for building interactive terminal user interfaces. It's inspired by [Charm's Bubble Tea](https://github.com/charmbracelet/bubbletea) for Go.

> **Two ways to build a TUI in Artisanal**
>
> | Model | Best for | Key entry point |
> |-------|----------|-----------------|
> | **TEA model** (this doc) | Direct control, simple apps, custom pipelines | `runProgram(MyModel())` |
> | **Widget system** ([widgets.md](widgets.md)) | Composable layouts, Flutter-style state, rich interactions | `runArtisanalApp(ArtisanalApp(...))` |
>
> This document covers the **TEA model only**. If you want the Flutter-like widget tree (`StatelessWidget`, `StatefulWidget`, `WidgetApp`), go to [widgets.md](widgets.md).

## Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Model Interface](#model-interface)
- [Program Class](#program-class)
- [Inline Mode](#inline-mode)
- [Program Hosts](#program-hosts)
- [Remote Plugin Surfaces](#remote-plugin-surfaces)
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
- [Trace Logging](#trace-logging)
- [Hot Reload Support](#hot-reload-support)
- [TUI Runtime Instrumentation](#tui-runtime-instrumentation)
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

TEA model entrypoints:

- `package:artisanal/runtime.dart` — `Model`, `Msg`, `Cmd`, `Program`, `runProgram`, `StringTerminal` (for tests), runtime messages
- `package:artisanal/hosts.dart` — backends, browser/socket hosts, `ProgramHost`
- `package:artisanal/tui.dart` — broader compatibility barrel (includes bubbles and Bubbles components)

> **Widget system?** Use `package:artisanal_widgets/widgets.dart` and `package:artisanal_widgets/app.dart`. See [widgets.md](widgets.md).

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
    screenMode: ScreenMode.fullScreen,
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
| `screenMode` | `ScreenMode?` | `null` | Explicitly choose `fullScreen`, `inline`, `inlineAuto`, or `fixed`; takes precedence over `altScreen` |
| `inlineHeight` | `int` | `4` | Height of the inline UI region when using inline modes |
| `uiAnchor` | `UiAnchor` | `bottom` | Anchor the inline UI to the top or bottom of the viewport |
| `fixedViewport` | `FixedViewport?` | `null` | Zero-based terminal rectangle owned by `ScreenMode.fixed` |
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
| `renderBudget` | `RenderBudgetOptions` | disabled | Enable budget-aware degradation and define frame-pressure thresholds |

`mouse: true` alone enables `MouseMode.cellMotion`, which reports clicks,
wheel input, and pointer motion while a button is pressed. Use
`MouseMode.allMotion` for passive hover behavior such as tooltips and
`MouseRegion` enter/exit callbacks.

`screenMode` is the preferred way to select between full-screen and inline
presentation. `altScreen` remains for backward compatibility and resolves to
`ScreenMode.fullScreen` when `true` and `ScreenMode.inline` when `false`.

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

### Inline Mode

Inline mode renders a bounded TUI region on the terminal's primary screen
instead of switching to the alternate screen buffer.

For a complete guide to scrollback-preserving command dashboards, child-process
logs, and widget-based inline panels, see [inline_tui.md](inline_tui.md).

```dart
await runProgram(
  const StatusModel(),
  options: const ProgramOptions(
    screenMode: ScreenMode.inline,
    inlineHeight: 4,
    uiAnchor: UiAnchor.bottom,
  ),
);
```

Use `UiAnchor.bottom` for status bars and command palettes that should stay
near the prompt, or `UiAnchor.top` for dashboards and monitors that should pin
to the top of the viewport.

```dart
await runProgram(
  const MonitorModel(),
  options: const ProgramOptions(
    screenMode: ScreenMode.inline,
    inlineHeight: 4,
    uiAnchor: UiAnchor.top,
    startupProbes: false,
  ),
);
```

Inline-mode behavior:

- preserves scrollback because it never enters the alternate screen buffer
- redraws only the configured inline rows instead of clearing the full screen
- restores the surrounding CLI cursor position after each frame
- skips startup probes by default because cursor-report and emoji-width probes
  can visibly disturb the primary screen

`ScreenMode.inlineAuto` is reserved for future content-aware sizing. Today it
behaves the same as `ScreenMode.inline` and still uses `inlineHeight`.

### Fixed Viewport Mode

Fixed mode owns an arbitrary rectangle on the primary screen. It clips output
to that rectangle, translates absolute cursor movement into it, and preserves
terminal content outside it. This is useful for embedding a TUI beside other
terminal-owned content.

```dart
await runProgram(
  const StatusModel(),
  options: const ProgramOptions(
    screenMode: ScreenMode.fixed,
    fixedViewport: FixedViewport(x: 2, y: 1, width: 58, height: 20),
  ),
);
```

`x` and `y` are zero-based. A viewport that reaches beyond the current terminal
is clipped on each resize. Fixed mode uses the UV renderer and never enters the
alternate screen.

### Budget-Aware Degradation

The runtime can degrade `View` content when render frames stay over budget.

```dart
final program = Program(
  const DashboardModel(),
  options: const ProgramOptions(
    renderBudget: RenderBudgetOptions(
      enabled: true,
      overBudgetFrames: 3,
      recoveryFrames: 8,
      maxLevel: DegradationLevel.essentialOnly,
    ),
  ),
);
```

Attach degraded content stages to a `View` when you want the runtime to swap
representations under pressure:

```dart
return const View(
  content: 'full fidelity dashboard',
  degradation: ViewDegradation(
    simpleBordersContent: 'simple border dashboard',
    noStylingContent: 'unstyled dashboard',
    skeletonContent: 'loading dashboard skeleton',
  ),
);
```

Current behavior:

- tracks sustained over-budget renders and steps through degradation levels
- recovers toward full fidelity after sustained within-budget renders
- preserves all other `View` metadata when swapping degraded content
- keeps this feature opt-in through `ProgramOptions.renderBudget`
- emits `RenderBudgetMsg` when the active degradation level changes so models
  can react directly

### Responsive Breakpoints

The layout system provides `ResponsiveBreakpoints` for terminal-width-aware
visual decisions.

```dart
final breakpoints = ResponsiveBreakpoints(
  xs: 40,  // Extra-small up to 40
  sm: 80,  // Small up to 80
  md: 120, // Medium up to 120
  lg: 160, // Large up to 160
  xl: 200, // Extra-large above 160
);

final columnCount = breakpoints.resolve(
  terminalWidth,
  {
    LayoutBreakpoint.xs: 1,
    LayoutBreakpoint.sm: 2,
    LayoutBreakpoint.md: 3,
    LayoutBreakpoint.lg: 4,
  },
);
```

- **Standard Thresholds**: Defaults to (xs: 0, sm: 80, md: 120, lg: 160, xl: 200).
- **Branching**: Use `isAtLeast(LayoutBreakpoint.md)` or `isBelow(...)` for
  conditional widget builds.
- **Auto-Detection**: `ArtisanalApp` and `WidgetApp` provide the current
  breakpoint in `BuildContext` when a provider is available.

---

### Tiling Pane Manager

The `TilingPaneManager` provides a high-level API for split-view window
management, similar to `tmux` or `i3`.

```dart
final manager = TilingPaneManager(
  root: PaneSplit(
    direction: PaneSplitDirection.horizontal,
    children: [
      PaneLeaf(id: 'editor', flex: 3),
      PaneLeaf(id: 'sidebar', flex: 1),
    ],
  ),
);

// Programmatically manipulate the tree
final updated = manager.split('editor', PaneSplitDirection.vertical);
```

- **Immutable Model**: Tree updates return new manager instances for easy
  integration with the Elm Architecture (`Model`).
- **Drag-to-Resize**: Built-in handles with magnetic snap zones and minimum
  size constraints.
- **Focus Navigation**: Cycle through panes using directional cues
  (`left`, `right`, `up`, `down`).
- **Split/Merge**: Dynamically create new leaf nodes or merge existing
  neighbors into a single pane.

---

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

Inline programs skip auto-probing by default even when UV rendering is enabled.
Set `startupProbes: true` only if you explicitly want probe traffic on the
primary screen and have verified your terminal handles it cleanly.

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
hosted theme state so the page chrome stays in sync with light/dark changes,
and the default ANSI palette follows those light/dark host defaults too until
the session mutates it explicitly. The initial page CSS also preloads matching
light/dark values so browser-backed sessions do not flash the wrong theme
before the host script applies the runtime state.

## Remote Plugin Surfaces

`package:artisanal/plugins.dart` defines the supported out-of-process plugin
surface for remote-rendered plugins.

The current stable layers are:

- `RemotePluginHostConnection` for the bundled host-side startup path,
  including process launch, hello handshake, surface controller binding, and
  optional generic service auto-binding
- `RemotePluginJsonTransport` / `RemotePluginJsonChannel` for newline-delimited
  JSON framing plus typed decoding and validation over line or byte streams
- `RemotePluginSession` for the lower-level host-side hello handshake and
  post-handshake plugin messages
- `RemotePluginGuestSession` for the plugin-side hello handshake, including
  `bindStdio(...)` for plugin executables
- `RemotePluginSurfaceController` and `RemotePluginSurfaceStore` for applying
  open/resize/frame/close messages into concrete host-side cell state
- `RemotePluginSurfaceInputRouter` for routing focus, blur, mouse, and key
  input into composed plugin surfaces
- `RemotePluginGenericServiceCatalog`, `RemotePluginGenericHostService`, and
  `RemotePluginGuestServices` for schema-backed host-owned RPCs over the shared
  `plugin.service.request` / `host.service.response` envelope
- `RemotePluginWorkspace` for the common multi-plugin host case, including
  manifest-directory startup, shared surface state, shared generic services,
  plugin-id lookup, and a ready-to-use input router
- `RemotePluginManifest`, `loadRemotePluginManifest(...)`, and
  `RemotePluginHostConnection.startManifest(...)` /
  `startManifestFile(...)` for manifest-backed discovery and launch
- `RemotePluginProtocolSchemas` and `RemotePluginManifestSchemas` for
  `json_schema_builder` validation of the wire protocol and manifest format

The intended flow is:

1. Host launches one plugin with `RemotePluginHostConnection.startProcess(...)`
   or a manifest-backed multi-plugin workspace with
   `RemotePluginWorkspace.startManifestDirectory(...)` /
   `RemotePluginWorkspace.startManifests(...)`.
2. Plugin binds stdin/stdout with `RemotePluginGuestSession.bindStdio(...)`.
3. Plugin emits `RemotePluginSurfaceOpen` / `RemotePluginFrame` lifecycle
   messages for one or more remote-rendered surfaces.
4. The bundled host connection applies those messages into
   `RemotePluginSurfaceStore` through `RemotePluginSurfaceController`.
5. The host compositor renders the resulting surface state in its own layout,
   optionally using `RemotePluginSurfaceInputRouter` to route focus, hover,
   clicks, and keys back into the plugin surfaces.
6. Host-owned capabilities such as clipboard, URL opening, notifications, and
   file picking should normally travel through the generic
   `plugin.service.request` / `host.service.response` envelope, with optional
   `RemotePluginServiceDescriptor` discovery metadata in `host.hello`.

Reference demo:

```bash
dart run pkgs/artisanal/example/tui/remote_plugin_host_demo.dart
```

That host example automatically launches the matching guest plugin and prints
the rendered panel state it receives back over stdio.

Manifest-backed multi-plugin workspace:

```bash
dart run pkgs/artisanal/example/tui/remote_plugin_workspace/host/main.dart
```

That example now uses `RemotePluginWorkspace.startManifestDirectory(...)`
instead of rebuilding manifest loading, shared surfaces, connection maps, and
router wiring inside app code.

Schema dump helper for non-Dart host/plugin tooling:

```bash
dart run pkgs/artisanal/example/tui/remote_plugin_schema_dump.dart
dart run pkgs/artisanal/example/tui/remote_plugin_schema_dump.dart --manifest
dart run pkgs/artisanal/example/tui/remote_plugin_schema_dump.dart --message-type=plugin.surface.open
dart run pkgs/artisanal/example/tui/remote_plugin_schema_dump.dart --built-in-services
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

### Key Chord Interceptor

`KeyChordInterceptor` is a built-in `ProgramInterceptor` that turns prefix key
sequences (chords) into structured messages. It is engine-level and works with
any TUI model.

```dart
import 'package:artisanal/tui.dart' as tui;

final interceptor = tui.KeyChordInterceptor(
  bindings: [
    tui.KeyChordBinding(
      id: 'open-themes',
      prefix: tui.KeyBinding.withHelp(['ctrl+x'], 'ctrl+x', 'prefix'),
      key: tui.KeyBinding.withHelp(['t'], 't', 'themes'),
    ),
    tui.KeyChordBinding(
      id: 'switch-model',
      prefix: tui.KeyBinding.withHelp(['ctrl+x'], 'ctrl+x', 'prefix'),
      key: tui.KeyBinding.withHelp(['m'], 'm', 'model'),
    ),
  ],
  timeout: null, // wait indefinitely (opencode-style)
);

await tui.runProgram(
  MyModel(),
  options: tui.ProgramOptions(interceptor: interceptor),
);
```

Chord messages your model can handle:

| Message | When |
|---------|------|
| `KeyChordPrefixMsg` | A chord prefix key was pressed and the interceptor is waiting for the continuation key. |
| `KeyChordResolvedMsg` | A full chord sequence matched a binding. Includes the binding `id`, `prefix`, and `key`. |
| `KeyChordCancelledMsg` | The pending chord was cancelled (unmatched key or timeout). Check `timedOut`. |

When an unmatched key cancels a pending chord, the interceptor emits a
`BatchMsg` containing both `KeyChordCancelledMsg` and the original `KeyMsg`,
so the model receives both the cancellation notice and the key that caused it.

Configuration:

- `timeout` — `null` (default) waits indefinitely for the continuation key
  (opencode-style). Set a `Duration` to auto-cancel after inactivity
  (e.g., `const Duration(milliseconds: 900)`).
- `inner` — an optional `ProgramInterceptor` to compose underneath the chord
  layer. The inner interceptor runs first; the chord interceptor processes the
  result.

Annotated example:

<a href="../examples/key-chord/main.dart">
  Key Chord Demo
</a>
(Run with `dart run example/tui/examples/key-chord/main.dart`)

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

### Macro Recorder/Player

`ProgramMacro` lets you capture live user-input during one run and replay it
later as deterministic input.

```dart
final program = Program(
  MyModel(),
  options: const ProgramOptions(altScreen: false, frameTick: false),
);

await program.run();

program.startMacroRecording();
// User input is recorded here (keys, mouse, paste, focus, UV input events).
...
final macro = program.stopMacroRecording();

// Later, replay on another run.
await Program(
  MyModel(),
  options: ProgramOptions(
    altScreen: false,
    frameTick: false,
    replay: macro.toReplay(),
  ),
).run();
```

For a playback started explicitly from a running program, `playMacro(...)`
returns the underlying replay subscription. Use `isMacroPlaying` and
`stopMacroPlayback()` to introspect and control in-flight playback.

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

### Evidence Logging

Use `TuiEvidence` for opt-in, structured JSONL decision logs.

The logger is currently focused on runtime-policy decisions (for example:
render-budget degradation transitions) and is enabled when either:

- `TuiEvidence.configureForTest(...)` is used with `enabled: true`, or
- `ARTISANAL_TUI_EVIDENCE=1` (or `true`, `on`, `yes`) is set.

Optional controls:

- `ARTISANAL_TUI_EVIDENCE_PATH=/path/to/file.jsonl` sets a custom file path.
  If unset, evidence is written to `./evidence/artisanal-<microsecond>-<timestamp>.jsonl`.
- `ARTISANAL_TUI_EVIDENCE_RUN_ID=<id>` adds a run-level correlation id.
- `TuiEvidence.configureForTest(...)` supports test-only `path` and `runId` and
  clears state between tests.

Log lines are strict JSON objects with keys:

- `v` (`1`)
- `type` (`runtime.decision`)
- `timestampUs`
- `decisionType`
- `result`
- `factors` (decision context map)
- optional `runId`

Example patterns:

```bash
ARTISANAL_TUI_EVIDENCE=1 \
ARTISANAL_TUI_EVIDENCE_PATH=./traces/artifacts.jsonl \
dart run bin/my_app.dart
```

```dart
import 'package:artisanal/runtime.dart';

void main() async {
  TuiEvidence.configureForTest(
    enabled: true,
    path: 'build/evidence.jsonl',
    runId: 'run-123',
  );

  final program = Program(MyModel());
  await program.run();

  // Always clear overrides when tests finish.
  TuiEvidence.clearTestOverrides();
}
```

```dart
import 'dart:io';

import 'package:artisanal/runtime.dart';

void main() async {
  final lines = await File('build/evidence.jsonl').readAsLines();
  for (final line in lines) {
    final record = TuiEvidence.tryParseLine(line);
    if (record == null) continue;
    print('${record.decisionType} => ${record.result}');
    print('  frameBudgetUs=${record.factors['frameBudgetUs']}');
    print('  renderDurationUs=${record.factors['renderDurationUs']}');
  }
}
```

Use `TuiEvidence.tryParseLine(...)` to decode one line and validate schema
before feeding it into downstream audit tooling.

For a runnable end-to-end example, use
`pkgs/artisanal/example/tui/examples/evidence-logging/main.dart` and the matching
`inspect.dart` helper in the same folder.
For a built-in runtime event example (render-budget transitions), use
`pkgs/artisanal/example/tui/examples/evidence-logging/render_budget.dart`.

## Hot Reload Support

Widget apps can detect and apply live source-code changes without restarting
the process. Hot reload is powered by the `hotreloader` package and is wired
into the widget host through `HotReloadMixin`.

### Enabling Hot Reload

Hot reload requires the Dart VM service. Launch your app with:

```sh
dart run --enable-vm-service bin/my_app.dart
# or via the convenience helpers
dart run --enable-vm-service example/my_example.dart
```

The `runWatchedArtisanalApp` and `runReloadableArtisanalApp` helpers from
`package:artisanal/app.dart` activate the file-watcher automatically when the
VM service is reachable:

```dart
import 'package:artisanal/app.dart';
import 'package:artisanal_widgets/widgets.dart';

void main() async {
  await runWatchedArtisanalApp(MyApp());
}
```

### HotReloadStatusMsg

The host dispatches a `HotReloadStatusMsg` through the normal `Program.send`
path whenever the reload lifecycle transitions. Models can react to it:

```dart
@override
(Model, Cmd?) update(Msg msg) {
  return switch (msg) {
    HotReloadStatusMsg(status: HotReloadStatus.changeDetected, :final detail) =>
      (copyWith(reloadBanner: 'Reloading: ${detail ?? \'\'}'), null),
    HotReloadStatusMsg(status: HotReloadStatus.succeeded) =>
      (copyWith(reloadBanner: null), null),
    HotReloadStatusMsg(status: HotReloadStatus.failed, :final detail) =>
      (copyWith(reloadBanner: 'Reload failed: ${detail ?? \'\'}'), null),
    _ => (this, null),
  };
}
```

### HotReloadStatus Values

| Status | Meaning |
|--------|--------|
| `initializing` | Mixin is starting the file-watcher |
| `ready` | Watching for file changes |
| `changeDetected` | A source file changed; reload is about to start |
| `reassembling` | Reload succeeded; widget tree is being reassembled |
| `succeeded` | Reassembly complete; app reflects latest code |
| `failed` | Compilation error or reassemble error |
| `unavailable` | VM service not reachable or not in debug mode |

Hot reload is automatically disabled in AOT/release builds
(`dart compile exe`, `flutter --release`). In those modes the mixin skips
all initialization and `HotReloadStatusMsg` is never dispatched.

## TUI Runtime Instrumentation

`TuiTrace` is a zero-overhead structured tracer for the TUI render and input
pipeline. It writes tagged, timestamped log lines (with optional span timing)
to a file. All methods are static and guarded behind `TuiTrace.enabled`, so
they add negligible overhead in production builds where tracing is off.

### Enabling Tracing

Set environment variables before running your app:

```sh
# Enable tracing (writes to ./traces/)
ARTISANAL_TUI_TRACE=1 dart run bin/my_app.dart

# Write to a specific file
ARTISANAL_TUI_TRACE_PATH=/tmp/my_trace.log dart run bin/my_app.dart

# Capture message-dispatch events (higher volume)
ARTISANAL_TUI_TRACE_CAPTURE=1 ARTISANAL_TUI_TRACE=1 dart run bin/my_app.dart

# Filter to specific subsystems
ARTISANAL_TUI_TRACE_TAGS=render,layout dart run bin/my_app.dart
```

### TraceTag Values

Each log line is tagged with a pipeline phase:

| Tag | Phase |
|-----|-------|
| `input` | Terminal input parsing and message coalescing |
| `queue` | Message queue management and drain loop |
| `dispatch` | Message dispatch to the widget/element tree |
| `rebuild` | Widget tree dirty marking and rebuild |
| `layout` | Constraint propagation and size computation |
| `paint` | RenderObject paint phase |
| `render` | Canvas → ANSI string serialization |
| `flush` | UV renderer: diff, buffer draw, ANSI flush |
| `focus` | Focus system operations |
| `scroll` | Scroll position and optimization |
| `metrics` | Frame counter and FPS tracking |
| `cmd` | Command execution |
| `general` | Uncategorized |

### Logging and Spans

```dart
import 'package:artisanal/runtime.dart'; // TuiTrace and TraceTag are exported

// Simple tagged log
TuiTrace.log('custom message', tag: TraceTag.render);

// Span-based timing
final span = TuiTrace.begin('my_view', tag: TraceTag.render);
// ... do work ...
span.end(); // logs: [render] my_view 1234us

// Structured event
TuiTrace.event('my.event', tag: TraceTag.general, fields: {'key': 'value'});
```

### Testing

```dart
TuiTrace.configureForTest(enabled: true, path: '/tmp/test_trace.log');
// run test code
TuiTrace.clearTestOverrides();
```

### Trace Output Format

Each line in the trace file is:

```
[+NNNus] [tag] message
```

For structured events the message starts with `@event ` followed by a
JSON object: `{"v":1,"type":"input.batch",...}`.

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

- [docs_index.md](docs_index.md) - Full documentation index
- [widgets.md](widgets.md) - Flutter-like Widget system (the alternative UI model)
- [replay.md](replay.md) - Replay automation system
- [bubbles.md](bubbles.md) - TEA-composable interactive components
- [uv.md](uv.md) - UV renderer integration
- [markdown.md](markdown.md) - Markdown rendering
