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

- [tui.md](tui.md) - TUI runtime and Program class
- [testing.md](testing.md) - Testing infrastructure including storms and gauntlet
- [uv.md](uv.md) - UV renderer integration

## Replay Harness Mixin

The `ReplayHarnessMixin` (exported from `package:artisanal/tui.dart`) wraps trace-to-scenario conversion, child-process spawning, and trace-summary analysis into a reusable mixin so any TUI app can add `replay` and `profile` subcommands in ~10 lines.

### Quick Start — Auto-Wired Runner

```dart
import 'package:artisanal/args.dart' show CommandRunner;
import 'package:artisanal/tui.dart' show HarnessCommandsMixin;

class MyRunner extends CommandRunner<void> with HarnessCommandsMixin {
  MyRunner() : super('myapp', 'My TUI app');

  @override
  String get harnessEntrypointPath => 'bin/myapp.dart';
}
```

This automatically registers `myapp replay` and `myapp profile` subcommands. Running:

```bash
# Convert a trace to a replay scenario
dart run bin/myapp.dart replay --replay-trace traces/latest --replay-convert-only

# Run the replay
dart run bin/myapp.dart replay --replay-scenario scenarios/demo.json --replay-speed 8 --replay-block-input

# Profile the replay
dart run bin/myapp.dart profile --replay-scenario scenarios/demo.json
```

### Flags

The harness registers the following CLI flags:

| Flag | Default | Description |
|------|---------|-------------|
| `--replay-trace` | — | Trace log to convert |
| `--replay-scenario` | — | Scenario file to load |
| `--replay-scenario-out` | — | Where to write the converted scenario |
| `--replay-speed` | `1.0` | Speed multiplier |
| `--replay-block-input` | `false` | Ignore manual input during replay |
| `--replay-loop` | `false` | Restart replay on finish |
| `--replay-keep-open` | `false` | Keep the app alive after replay |
| `--replay-lead-in-ms` | `3500` | Initial wait before first action |
| `--replay-script-filter` | `bin/*.dart` | Session filter for multi-session traces |
| `--replay-trace-min-sleep-us` | `30000` | Minimum trace gap preserved as sleep |
| `--replay-trace-screen-width` | `0` | Override source screen width |
| `--replay-trace-screen-height` | `0` | Override source screen height |
| `--replay-trace-fixed-right-width` | `60` | Right-pane anchor for mouse scaling |
| `--replay-trace-from-us` | — | Trim trace before this microsecond |
| `--replay-trace-to-us` | — | Trim trace after this microsecond |
| `--replay-trace-include-hover` | `false` | Include hover-only mouse moves |
| `--replay-convert-only` | `false` | Convert trace without running app |
| `--replay-capture-trace` | `true` | Capture a lightweight trace while replaying |
| `--replay-trace-out` | `.dart_tool/replay/trace.log` | Where to write the replay trace |
| `--replay-trace-tags` | `general,render,layout,paint,scroll` | Trace tags for capture |
| `--replay-capture-dispatch` | `false` | Include dispatch capture diagnostics |
| `--replay-summary-count` | `12` | Number of slowest spans to print |
| `--replay-max-span-us` | `0` | Fail if the slowest span exceeds this |
| `--replay-timeout-seconds` | `180` | Kill child process after this timeout |

Profile subcommand adds:

| Flag | Default | Description |
|------|---------|-------------|
| `--profile-profiler-command` | `devtools-profiler` | Profiler executable |
| `--profile-artifact-dir` | `.dart_tool/profile` | Where to write artifacts |
| `--profile-clean-artifact-dir` | `true` | Delete artifact dir before profiling |
| `--profile-region` | `true` | Mark replay window as profile region |
| `--profile-region-name` | `app.replay` | Profile region name |
| `--profile-timeout-seconds` | `240` | Kill profiler after this timeout |

### Override Points

Override these in a command or runner that mixes in `ReplayHarnessMixin` / `ProfileHarnessMixin`:

| Method | Type | Default | Purpose |
|--------|------|---------|---------|
| `harnessEntrypointPath` | `String` (getter) | required | Path to the app entrypoint |
| `buildAppSpecificReplayArgs` | `(config, scenarioPath) → List<String>` | `[]` | App-specific CLI args (e.g. `--limit`, `--view`) |
| `customizeReplayEnvironment` | `(config) → Map<String, String>?` | `null` | Override child-process env vars |
| `customizeReplayScenario` | `(scenario, path) → Future<Scenario?>` | `null` | Transform the scenario before execution |
| `resolveTracePath` | `(path) → String` | file-exists check | Resolve `--replay-trace` paths |
| `tryResolveTracePath` | `(path) → Future<String?>` | `traces/` search | Resolve `latest` alias to newest trace |
| `resolveScenarioPath` | `(path) → String` | file-exists check | Resolve `--replay-scenario` paths |
| `tryResolveScenarioPath` | `(path) → Future<String?>` | `null` | Resolve special scenario paths (e.g. `issues` → `scenarios/issues_scroll_detail.json`) |
| `onReplayPrepared` | `(prepared) → void` | — | Log or inspect the prepared scenario |
| `onReplayCompleted` | `(prepared, exitCode, …) → void` | — | Post-replay logging / summary |
| `enableReplayHarness` | `bool` (getter) | `true` | Gate for auto-adding replay subcommand |
| `enableProfileHarness` | `bool` (getter) | `true` | Gate for auto-adding profile subcommand |

`ProfileHarnessMixin` adds:

| Method | Type | Default | Purpose |
|--------|------|---------|---------|
| `profileProfilerCommand` | `String` (getter) | required | Profiler executable name |
| `profileArtifactDir` | `String` (getter) | required | Artifact directory path |
| `profileRegionName` | `String` (getter) | required | Profile region identifier |
| `profileEventPrefix` | `String` (getter) | `profile.harness` | Event type prefix for profile regions |
| `profileRegionMetadata` | `(scenarioPath) → Map` | `{}` | Extra fields on the start event |
| `buildProfileArgs` | `(config, scenarioPath) → List<String>` | defaults | Full profiler command arguments |
| `buildDevtoolsProfilerRunArgs` | `(config, scenarioPath) → List<String>` | devtools args | Args after the profiler executable |
| `onProfileCompleted` | `(config, exitCode) → void` | — | Post-profile logging |

### Standalone Helpers

For apps that don't use the auto-wired commands, these top-level utilities provide the same functionality:

| Function | Signature | Description |
|----------|-----------|-------------|
| `loadReplayPlan()` | `({required ReplayHarnessConfig config, Future<String?> Function(String)? resolveScenarioPath}) → Future<ResolvedReplay>` | Load and resolve a replay plan from the given config. Parses the scenario, processes traces, and returns a `ResolvedReplay` ready for execution. |
| `registerReplayFlags()` | Extension `ReplayFlagsArgParser` on `ArgParser` | Registers all `--replay-*` flags. |
| `registerProfileFlags()` | Extension `ProfileFlagsArgParser` on `ArgParser` with optional defaults | Registers all `--profile-*` flags. Defaults: `profilerCommand = 'devtools-profiler'`, `artifactDir = '.dart_tool/profile'`, `regionName = 'app.replay'`. |

```dart
import 'package:artisanal/args.dart' show ArgParser;
import 'package:artisanal/tui.dart'
    show registerReplayFlags, registerProfileFlags, loadReplayPlan;

final parser = ArgParser()
  ..registerReplayFlags()
  ..registerProfileFlags();
final config = ReplayHarnessConfig.fromArgResults(parser.parse(args));
final resolved = await loadReplayPlan(config: config);
```

### References

- **`example/tui/examples/harness_demo/main.dart`** — minimal example (10 lines of app code).
- **`example/github_cli/lib/src/app/runner.dart`** — full-featured example using compile-time flags (`enableReplayHarness`, `enableProfileHarness`).
- **`lib/src/tui/replay_harness_mixin.dart`** — source of `ReplayHarnessMixin`, `ProfileHarnessMixin`, `HarnessCommandsMixin`.