# DevTools Integration

artisanal provides built-in support for Dart DevTools through the
`ArtisanalDevTools` interceptor. This guide covers how to connect,
what data is exposed, and how to use it for debugging your TUI
applications.

## Quick Start

Add the `ArtisanalDevTools` interceptor to your program:

```dart
import 'package:artisanal/tui.dart';

void main() async {
  await runProgram(
    MyModel(),
    options: ProgramOptions(
      interceptor: ArtisanalDevTools(),
    ),
  );
}
```

## Running with VM Service

To connect DevTools, your program must expose the VM service. Run with
the `--enable-vm-service` flag:

```bash
dart run --enable-vm-service bin/my_app.dart
```

You'll see output like:

```
The Dart VM service is listening on http://127.0.0.1:8181/AbCdEf=/
```

Copy this URL — you'll need it to connect DevTools.

## Connecting Dart DevTools

### Option A: From the terminal

```bash
dart devtools
```

Then enter the VM service URL in the connection dialog.

### Option B: From VS Code

1. Run your app with `--enable-vm-service`
2. Open the Command Palette (`Ctrl+Shift+P`)
3. Select **Dart: Open DevTools**
4. Choose the running program from the list

### Option C: Direct URL

Open your browser to:

```
http://127.0.0.1:9100?uri=ws://127.0.0.1:8181/AbCdEf=/ws
```

(Replace `AbCdEf=` with your actual VM service auth token.)

## What You Get

### Timeline Events (Performance Tab)

When connected, the Performance tab shows structured timeline events:

| Event | Description |
|-------|-------------|
| `artisanal.message` | Each message dispatch through `model.update()` |
| `artisanal.render` | Each render frame (view + terminal output) |

Timeline events include metadata:
- **message events**: message type, human-readable summary
- **render events**: generation number, duration, degradation level, dimensions

### Service Extensions

The following `ext.artisanal.*` service extensions are registered
automatically:

#### `ext.artisanal.getState`

Returns the current program state snapshot.

```json
{
  "running": true,
  "renderGeneration": 42,
  "pendingMessages": 0,
  "lastModel": "MyModel(count=5)"
}
```

#### `ext.artisanal.getMessageLog`

Returns the most recent N dispatched messages (default 50).

Parameters:
- `count` (optional): number of entries to return

```json
{
  "entries": [
    {
      "timestamp": "2025-06-15T12:00:00.000Z",
      "messageType": "KeyMsg",
      "summary": "key: runes runes=[113]",
      "processingTimeUs": 420
    }
  ]
}
```

#### `ext.artisanal.getRenderStats`

Returns accumulated render timing statistics.

```json
{
  "frameCount": 3600,
  "totalRenderUs": 5400000,
  "avgRenderUs": 1500,
  "minRenderUs": 800,
  "maxRenderUs": 4200,
  "lastRenderUs": 1200,
  "lastDegradation": "full",
  "lastWidth": 120,
  "lastHeight": 40
}
```

#### `ext.artisanal.getOptions`

Returns the active `ProgramOptions` summary.

```json
{
  "altScreen": true,
  "screenMode": "altScreen",
  "mouse": true,
  "mouseMode": "allMotion",
  "fps": 60,
  "frameTick": true,
  "captureOutput": false,
  "hotReload": false
}
```

#### `ext.artisanal.sendCustomMessage`

Injects a `CustomMsg<String>` into the running program.

Parameters:
- `value` (required): the string payload

This is useful for triggering debug behavior from DevTools without
terminal input.

#### `ext.artisanal.requestRepaint`

Forces an immediate repaint cycle.

### Calling Service Extensions

Use `dart:developer` or the VM service protocol:

```bash
# Using curl against the VM service
curl -s "http://127.0.0.1:8181/AbCdEf=/ext.artisanal.getState" | jq .
```

Or programmatically from another Dart process:

```dart
import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

void main() async {
  final service = await vmServiceConnectUri(
    'ws://127.0.0.1:8181/AbCdEf=/ws',
  );
  final vm = await service.getVM();
  final isolateId = vm.isolates!.first.id!;

  final result = await service.callServiceExtension(
    'ext.artisanal.getState',
    isolateId: isolateId,
  );
  print(result.json);
}
```

### Live Event Stream (postEvent)

When a DevTools extension is listening, structured events are emitted
via `dart:developer` `postEvent`:

| Event Kind | When |
|-----------|------|
| `artisanal:start` | Program starts |
| `artisanal:message` | Each message dispatched |
| `artisanal:render` | Each render frame |
| `artisanal:stop` | Program stops |

These events are consumed by custom DevTools extensions.

## CLI Inspector

A standalone CLI inspector is included at
`example/artisanal_inspector.dart`. It connects to a running program
via WebSocket and provides an interactive REPL for querying state.

### Running the Inspector

```bash
# Terminal 1: run your app
dart run --enable-vm-service bin/my_app.dart

# Terminal 2: run the inspector
dart run example/artisanal_inspector.dart ws://127.0.0.1:8181/AbCdEf=/ws
```

### Available Commands

| Command | Description |
|---------|-------------|
| `state` | Show current model state |
| `log [n]` | Show last n messages (default 20) |
| `stats` | Show render statistics |
| `options` | Show program options |
| `send <v>` | Inject a `CustomMsg<String>` |
| `repaint` | Force repaint |
| `watch` | Poll state every 500ms |
| `help` | Show help |
| `quit` | Exit |

The inspector uses raw `dart:io` WebSocket — no extra dependencies
needed.

## Composing with Other Interceptors

`ArtisanalDevTools` supports the decorator pattern. If you already have
an interceptor (e.g., `ProgramRenderRecorder`), pass it as `inner`:

```dart
final recorder = ProgramRenderRecorder();
final devtools = ArtisanalDevTools(inner: recorder);

await runProgram(
  MyModel(),
  options: ProgramOptions(interceptor: devtools),
);
```

Both interceptors will receive all lifecycle events.

## In-App Debug Overlay

The `DebugOverlayModel` can display DevTools data directly in your
TUI. It supports four modes:

| Mode | What's Shown |
|------|--------------|
| `metrics` | FPS, frame time, render time (original) |
| `messages` | Recent message log from DevTools |
| `output` | Captured `print()` output |
| `all` | All three sections combined |

### Feeding Data to the Overlay

```dart
class MyModel implements Model, CapturedOutputModel {
  final DebugOverlayModel debugOverlay;
  final OutputLog outputLog;

  // In your update() method, feed DevTools data:
  (Model, Cmd?) update(Msg msg) {
    var nextDebug = debugOverlay;

    // Feed the overlay with message log entries from DevTools.
    // (Requires access to your ArtisanalDevTools instance.)
    nextDebug = nextDebug.copyWith(
      messageEntries: devtools.messageLog.reversed.take(10).toList(),
    );

    // Feed captured output entries.
    nextDebug = nextDebug.copyWith(
      outputEntries: outputLog.entries.reversed.take(10).toList(),
    );

    // Handle overlay-specific messages (metrics, mouse, resize).
    final debugUpdate = nextDebug.update(msg);
    // ...
  }

  // In your view(), compose the overlay:
  String view() {
    final base = renderMyUI();
    return debugOverlay.compose(base);
  }
}
```

### Cycling Modes

Bind a key (e.g., `Shift+D`) to cycle overlay modes:

```dart
case KeyMsg(key: Key(type: KeyType.runes, runes: [0x44])): // 'D'
  return (copyWith(debugOverlay: debugOverlay.cycleMode()), null);
```

## Configuration

`ArtisanalDevTools` constructor parameters:

| Parameter | Default | Description |
|-----------|---------|-------------|
| `inner` | `null` | Inner interceptor to delegate to |
| `maxLogEntries` | `500` | Ring buffer size for message log |
| `enableTimeline` | `true` | Emit Timeline events |
| `enablePostEvent` | `true` | Emit live `postEvent` stream |
| `enableServiceExtensions` | `true` | Register `ext.artisanal.*` extensions |

To disable features you don't need (e.g., in tests):

```dart
ArtisanalDevTools(
  enableTimeline: false,
  enablePostEvent: false,
  enableServiceExtensions: false,
)
```

## Captured Output (`CapturedOutputModel`)

When your model implements `CapturedOutputModel`, the runtime
automatically captures `print()` calls inside the program zone
and appends them to the model's `OutputLog`:

```dart
class MyModel implements Model, CapturedOutputModel {
  @override
  final OutputLog outputLog;

  MyModel({this.outputLog = const OutputLog()});

  @override
  MyModel withOutputLog(OutputLog log) =>
      MyModel(outputLog: log);
}
```

Enable capture in options:

```dart
ProgramOptions(captureOutput: true)
```

The runtime handles `CapturedOutputMsg` automatically — your
`model.update()` is never called with it.
