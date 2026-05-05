# Replay Automation System

The replay system provides deterministic event playback for demos, tests, and performance runs. It is runtime-level automation, not tied to any specific app.

## Overview

Replay automation allows you to:

- Record and replay user input programmatically
- Convert trace logs into replay scenarios
- Run deterministic demos and tests with precise timing control
- Capture and inspect render state during playback
- Block manual input during replay for consistent profiling

The system integrates with the TUI runtime through `ProgramOptions.replay`, with optional input blocking and custom event hooks.

## Quick Start

```dart
import 'package:artisanal/runtime.dart';

void main() async {
  // Scripted replay with timed key presses
  final replay = ProgramReplay.script([
    ProgramReplayStep(
      after: Duration(milliseconds: 500),
      msg: KeyMsg(Key(KeyType.runes, runes: [0x61])), // 'a'
    ),
    ProgramReplayStep(
      after: Duration(milliseconds: 100),
      msg: QuitMsg(),
    ),
  ]);

  await runProgram(
    MyModel(),
    options: ProgramOptions(replay: replay),
  );
}
```

## Replay Protocol

### ProgramReplay

The `ProgramReplay` class provides two factory constructors for different replay sources:

```dart
// Scripted replay from timed steps
final scriptReplay = ProgramReplay.script([
  ProgramReplayStep(after: Duration(seconds: 1), msg: KeyMsg(...)),
  ProgramReplayStep(after: Duration(seconds: 2), msg: QuitMsg()),
]);

// Live stream replay
final controller = StreamController<Msg>();
final streamReplay = ProgramReplay.stream(controller.stream);
```

### ProgramReplayStep

One timed step for script replay:

```dart
final step = ProgramReplayStep(
  after: Duration(milliseconds: 500),
  msg: KeyMsg(Key(KeyType.enter)),
);
```

### ProgramOptions Integration

```dart
final program = Program(
  MyModel(),
  options: ProgramOptions(
    replay: ProgramReplay.script([...]),
    blockInputWhileReplay: true, // Ignore manual input during replay
  ),
);
```

## Replay Scenario

A replay scenario is a JSON document containing actions that can be played back:

```dart
final scenario = ReplayScenario(
  name: 'demo_run',
  description: 'Automated demo workflow',
  screen: const ReplayScreen(width: 80, height: 24),
  actions: [
    ReplayAction(type: 'text', value: 'hello'),
    ReplayAction(type: 'special', key: 'enter'),
    ReplayAction(type: 'sleep', ms: 100),
  ],
);

// Convert to ProgramReplay
final replay = scenario.toProgramReplay(
  loop: false,
  keepOpen: false,
  speed: 1.0,
);
```

### Action Types

| Type | Description | Fields |
|------|-------------|--------|
| `text` | Keyboard text input | `value`, `repeat` |
| `special` | Special keys (enter, tab, arrows) | `key` |
| `wheel` | Mouse wheel | `direction` (up/down/left/right), `x`, `y`, `repeat` |
| `tap` | Mouse click | `x`, `y`, `repeat` |
| `move` | Mouse motion | `x`, `y` |
| `drag` | Mouse drag gesture | `x`, `y`, `x2`, `y2`, `steps` |
| `sleep` | Timing delay | `ms` |
| `event` | Custom event | `eventType`, `eventFields` |

## Replay Event History Widgets

The `artisanal_widgets` package provides widgets for displaying replay events.

### ReplayEventPanel

Shows a single replay event's details:

```dart
ReplayEventPanel(
  presentation: event.presentation,
  title: 'Replay Event',
  maxDetailLines: 4,
);
```

### ReplayEventHistoryPanel

Shows a filtered history of replay events:

```dart
ReplayEventHistoryBrowser(
  events: eventHistory,
  state: historyState,
  onStateChanged: (newState) => historyState = newState,
);
```

Filter modes:
- `ReplayEventHistoryFilter.all` - All events
- `ReplayEventHistoryFilter.renderCaptures` - Only render capture events
- `ReplayEventHistoryFilter.custom` - Only custom events

Display modes:
- `ReplayEventHistoryMode.flat` - Show each event individually
- `ReplayEventHistoryMode.grouped` - Group similar events

## Trace Logging

Enable trace logging with environment variables:

```bash
# Enable trace logging
export ARTISANAL_TUI_TRACE=1

# Set trace file path
export ARTISANAL_TUI_TRACE_PATH=./traces/run.log

# Enable dispatch capture diagnostics
export ARTISANAL_TUI_TRACE_CAPTURE=1

# Filter by trace tags
export ARTISANAL_TUI_TRACE_TAGS=input,dispatch,render
```

When `ARTISANAL_TUI_TRACE_PATH` is unset, traces are written to `./traces/artisanal-YYYY-MM-DDTHH-MM-SS.log`.

### Trace Event Format

Trace events use a structured JSON format:

```
[+123456us] [input] @event {"v":1,"type":"input.batch","messages":[...]}
```

## Macro Recorder/Player

Record user input during a live session and replay it later:

```dart
final program = Program(MyModel());

// Start recording
program.startMacroRecording();
// ... user interacts ...
final macro = program.stopMacroRecording();

// Replay the macro
await Program(
  MyModel(),
  options: ProgramOptions(replay: macro.toReplay()),
);
```

### Macro to Replay Conversion

```dart
class ProgramMacro {
  final List<ProgramReplayStep> steps;
  
  ProgramReplay toReplay({bool loop = false}) =>
      ProgramReplay.script(steps, loop: loop);
}
```

## Replay Scenarios and Conversion

### Trace to Replay Conversion

Convert a trace log to a replay scenario:

```dart
final result = await ReplayTraceConverter.convertFile(
  path: tracePath,
  options: const ReplayTraceConversionOptions(
    name: 'converted_scenario',
    description: 'Converted from trace log',
    screenWidth: 120,
    screenHeight: 32,
    minSleepUs: 30000, // Minimum gap to preserve
    includeHoverMoves: false, // Skip hover-only mouse moves
    includeCustomEvents: true, // Include custom trace events
  ),
);

// Save the scenario
await result.scenario.save('scenarios/converted.json');
```

### Conversion Result

```dart
class ReplayTraceConversionResult {
  final String tracePath;
  final ReplayScenario scenario;
  final int eventCount;
  final int actionCount;
  final int skippedCount;
  final int inferredScreenWidth;
  final int inferredScreenHeight;
}
```

## TUI Render Capture Optimization

### ProgramRenderCapture

Capture structured render state during replay:

```dart
class ProgramRenderCapture extends ProgramInterceptor {
  // Most recent snapshot
  ProgramRenderSnapshot? get lastSnapshot;
  
  // Build a structured payload
  ProgramRenderCapturePayload payload({String prefix = 'Render'}) =>
      payload(prefix: prefix, maxFrameLines: 3);
}
```

### ProgramRenderCapturePayload

```dart
class ProgramRenderCapturePayload {
  final ProgramRenderStats stats;
  final ProgramRenderCaptureReport report;
  final ProgramRenderSnapshot? lastSnapshot;
  final ProgramRenderSnapshotSummary? lastSnapshotSummary;
}
```

### ReplayRenderCaptureEvent

Typed view of a render-capture replay event:

```dart
final customEvent = ReplayCustomEvent(
  type: 'runtime.render_capture',
  fields: payload.toJson(),
);

final renderCapture = customEvent.renderCapture; // ReplayRenderCaptureEvent?
if (renderCapture != null) {
  print(renderCapture.presentation.summary);
}
```

## Custom Event Hooks

Handle custom events during replay with an event hook:

```dart
final replay = ProgramReplay.stream(
  replayScenarioStream(
    actions,
    eventHook: (event) async {
      if (event.type == 'runtime.render_capture') {
        final payload = event.renderCapturePayload;
        if (payload != null) {
          // Inspect render state during replay
          print('Render at generation ${payload.lastSnapshotSummary?.renderGeneration}');
        }
        return ReplayEventDirective.proceed;
      }
      return ReplayEventDirective.emit([ReplayEventMsg(event)]);
    },
  ),
);
```

### Event Hook Return Values

```dart
// Continue with default behavior
ReplayEventDirective.proceed

// Continue with custom messages
ReplayEventDirective.emit([Msg1(), Msg2()])

// Stop replay
ReplayEventDirective.stop([Msg1()])

// Stop and quit
ReplayEventDirective.quit([Msg1()])
```

## Coordinate Scaling

Mouse coordinates are scaled from the source screen dimensions to the current terminal size:

```dart
final interceptor = ReplayCoordinateInterceptor(
  sourceWidth: 80,
  sourceHeight: 24,
  sourceRightFixedWidth: 0, // Right pane width for anchor scaling
);
```

This ensures mouse clicks and drags work correctly regardless of terminal size differences.

## OpenCode Example Workflow

Record a manual run, convert to replay, and playback deterministically:

```bash
# 1. Record a manual run with tracing
ARTISANAL_TUI_TRACE=1 \
ARTISANAL_TUI_TRACE_CAPTURE=1 \
ARTISANAL_TUI_TRACE_PATH="traces/manual-$(date +%Y-%m-%dT%H-%M-%S).log" \
dart run my_app.dart

# 2. Convert trace to replay scenario
dart run my_app.dart \
  --replay-trace "$LATEST_TRACE" \
  --replay-trace-out scenarios/manual_from_trace.json \
  --replay-trace-name manual_from_trace \
  --replay-convert-only

# 3. Replay deterministically (with input blocking)
dart run my_app.dart \
  --replay-scenario scenarios/manual_from_trace.json \
  --replay-block-input \
  --replay-speed 8
```

### Trace Analysis

Analyze trace hotspots after a run:

```bash
python analyze_trace.py "$LATEST_TRACE" --top 12
```

## API Reference

### Core Classes

| Class | Description |
|-------|-------------|
| `ProgramReplay` | Message replay source for `ProgramOptions.replay` |
| `ProgramReplayStep` | Timed replay step for script mode |
| `ProgramMacro` | Recorded user input macro |
| `ReplayScenario` | JSON-serializable replay document |
| `ReplayAction` | Single action in a scenario |
| `ReplayCustomEvent` | Structured custom event |
| `ReplayEventPresentation` | Presentation model for UI/debug |
| `ReplayRenderCaptureEvent` | Typed render-capture view |

### Interceptor Classes

| Class | Description |
|-------|-------------|
| `ReplayCoordinateInterceptor` | Scales mouse coordinates |
| `ProgramRenderRecorder` | Records render snapshots |
| `ProgramRenderCapture` | Combined recorder + monitor |

### Conversion Classes

| Class | Description |
|-------|-------------|
| `ReplayTraceConverter` | Converts traces to scenarios |
| `ReplayTraceConversionOptions` | Conversion configuration |
| `ReplayTraceConversionResult` | Conversion output |

## Best Practices

1. **Always include QuitMsg** - Replay does not automatically quit; include `QuitMsg` at the end of your script.

2. **Use blockInputWhileReplay for profiling** - This ensures consistent timing by ignoring manual input.

3. **Match screen dimensions** - For best mouse coordinate scaling, record traces at the same dimensions you'll replay.

4. **Keep actions meaningful** - Focus on essential user actions; skip noisy intermediate states with `minSleepUs`.

5. **Test with different speeds** - Use `--replay-speed` to find timing-sensitive bugs.

6. **Capture custom events** - Use `event` actions for application-specific state that should be preserved.

7. **Verify determinism** - Run the same scenario multiple times to ensure consistent output.

## Troubleshooting Determinism

### Replay timing differs from original

- Check terminal size matches the recorded trace
- Use `ReplayCoordinateInterceptor` for mouse events
- Ensure frame tick timing is consistent

### Mouse clicks in wrong positions

- Verify `ReplayScreen` dimensions in the scenario
- Use `--replay-block-input` to prevent terminal interference
- Check that the UI doesn't dynamically resize during playback

### Missing messages during replay

- Replay messages pass through filters/interceptors; check for filtering
- Verify the stream isn't being cancelled prematurely

## Related Documentation

- [TUI.md](TUI.md) - TUI runtime and Program class
- [TESTING.md](TESTING.md) - Testing infrastructure including storms and gauntlet
- [UV.md](UV.md) - UV renderer integration