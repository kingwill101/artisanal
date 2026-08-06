# Test widget apps

Widget tests run through the same message and rendering pipeline as a real app.
You can mount a widget, send keyboard or mouse input, inspect the rendered
terminal, and reproduce tricky resize or flicker bugs without opening an
interactive session.

## Start with WidgetTester

The `WidgetTester` is the primary tool for testing widgets. It is designed to feel familiar to Flutter developers while adapting to the terminal environment.

### What it can do

- **Production Pipeline**: Unlike simple state-to-view tests, `WidgetTester` runs a real `Program` with a mock terminal. Every event follows the full path: `send(msg) -> update(msg) -> view() -> render()`.
- **Deterministic Frames**: Capture snapshots of the rendered view after each message or pump.
- **Input Simulation**: Send keys, paste text, simulate mouse clicks, and drag gestures.
- **Render-Tree Hit Testing**: Interact with widgets using their actual coordinates on the terminal screen.

### Basic Usage

Use the `testWidgets` helper to manage the tester lifecycle:

```dart
void main() {
  testWidgets('increments counter on tap', (tester) async {
    // Mount the widget
    await tester.pumpWidget(MyCounterWidget());

    // Assert on initial state
    expect(tester.find.text('Count: 0'), isTrue);

    // Find and tap a widget by its text content
    tester.tap(tester.find.textLocation('Increment'));

    // Assert on updated state
    expect(tester.find.text('Count: 1'), isTrue);
  });
}
```

### Finding Widgets

The `tester.find` helper provides several ways to locate elements:
- `find.text('hello')`: Check if text is visible.
- `find.textLocation('button')`: Get coordinates for tapping.
- `find.byType<MyWidget>()`: Find by widget class.
- `find.byKey(MyKey)`: Find by explicit widget key.

## Stress Testing (Widget Storms)

To ensure robustness, Artisanal includes "Storm" testing—the ability to flood a widget with high-frequency, deterministic events.

### Storm Patterns

- **`keyboardStorm`**: Rapid-fire character input.
- **`mouseFlood`**: High-frequency mouse motion.
- **`mixedBurst`**: Interleaved keys, mouse events, resizes, and pumps.
- **`pathologicalResize`**: Rapidly oscillating between extreme viewport sizes (e.g., 1x1 to 200x80).

```dart
testWidgets('handles pathological resizes', (tester) async {
  await tester.pumpWidget(MyComplexLayout());

  final result = tester.runStorm(
    WidgetStormProfile.pathologicalResize(count: 50),
  );

  expect(result.passed, isTrue);
});
```

## Flicker Analysis

Visual quality is critical in TUI apps. The `FlickerAnalyzer` scans the raw terminal output emitted during tests to detect patterns that cause visual artifacts or "tearing."

### Detected Issues

- **Partial Clears**: Using `EL` (Erase Line) or `ED` (Erase Display) in the middle of a frame, which might briefly expose blank cells before text is written over them.
- **Unsynchronized Output**: Writing visible characters outside of "synchronized update" (`DECSET 2026`) brackets.
- **Interleaved Writes**: Starting a new frame before the previous one has finished its sync bracket.

```dart
testWidgets('renders without flicker', (tester) async {
  await tester.pumpWidget(MyWidget());

  // Run some interactions...
  tester.sendKey('a');

  // Analyze the raw terminal output
  final analysis = tester.analyzeFlicker(requireSynchronizedOutput: true);
  analysis.assertFlickerFree();
});
```

## The Widget Gauntlet

The `WidgetGauntlet` is a high-level composite check that runs multiple storm profiles and a flicker analysis in a single pass, producing a structured "evidence bundle."

```dart
final gauntlet = WidgetGauntlet(
  config: WidgetGauntletConfig(
    analyzeFlicker: true,
    stormProfiles: [
      WidgetStormProfile.mixedBurst(),
      WidgetStormProfile.pathologicalResize(),
    ],
  ),
);

final result = await gauntlet.run(tester: tester, widget: MyWidget());
expect(result.passed, isTrue);
```

## Deterministic Testing Helpers

- **`ManualClock`**: Control time for animation tests. Use `tester.advanceAnimation(controllerId, clock, delta: Duration(...))` to precisely step through frames.
- **`HarnessArtifactManifest`**: Structured metadata about a test run, including logs, frame snapshots, and replay scripts.
