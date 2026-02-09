import 'dart:async';
import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart';

/// Tests for the frame-skip optimization that prevents unnecessary repaints.
///
/// The optimization skips the expensive paint phase when:
/// - No elements need rebuilding (buildOwner.hasDirtyElements == false)
/// - No render objects need layout (pipelineOwner.hasNodesToLayout == false)
/// - No render objects need paint (pipelineOwner.hasNodesToPaint == false)
/// - A previous buffer exists to reuse
///
/// This prevents CPU waste when frames are scheduled but nothing visual changed.
void main() {
  group('Frame Skip Optimization', () {
    test('setState marks elements dirty and triggers rebuild', () async {
      await testNocterm(
        'setState marks dirty',
        (tester) async {
          await tester.pumpComponent(const _BuildCounter());

          expect(tester.terminalState, containsText('Build count: 1'));

          // Get the state and trigger rebuild
          final state = _BuildCounter.lastState!;
          state.triggerRebuild();

          // Pump to process the rebuild
          await tester.pump();

          expect(tester.terminalState, containsText('Build count: 2'));
        },
      );
    });

    test('static widget does not cause rebuilds on subsequent frames',
        () async {
      await testNocterm(
        'static no rebuilds',
        (tester) async {
          await tester.pumpComponent(const _BuildCounter());

          expect(tester.terminalState, containsText('Build count: 1'));

          // Pump several more frames - build count should NOT increase
          await tester.pump();
          await tester.pump();
          await tester.pump();

          // Build count should still be 1 - no unnecessary rebuilds
          expect(tester.terminalState, containsText('Build count: 1'));
        },
      );
    });

    test('timer-based animation only rebuilds when state changes', () async {
      await testNocterm(
        'timer rebuilds only on change',
        (tester) async {
          await tester.pumpComponent(const _TimerCounter());

          expect(tester.terminalState, containsText('Value: 0'));

          // Wait for timer to tick a few times
          await Future.delayed(const Duration(milliseconds: 350));
          await tester.pump();

          // Value should have increased
          final state = _TimerCounter.lastState!;
          expect(state.value, greaterThan(0));

          // Stop the timer
          state.stopTimer();
          final valueAfterStop = state.value;
          final buildCountAfterStop = state.buildCount;

          // Pump more frames - should NOT rebuild since timer is stopped
          await tester.pump();
          await tester.pump();
          await Future.delayed(const Duration(milliseconds: 150));
          await tester.pump();

          expect(state.value, equals(valueAfterStop));
          expect(state.buildCount, equals(buildCountAfterStop));
        },
      );
    });

    test('unchanged widget tree reuses previous frame', () async {
      await testNocterm(
        'unchanged reuses frame',
        (tester) async {
          await tester.pumpComponent(const Text('Static content'));

          // Get initial state as string
          final initialOutput = tester.terminalState.toString();

          // Pump more frames
          await tester.pump();
          await tester.pump();

          // Output should be identical (frame was skipped, buffer reused)
          expect(tester.terminalState.toString(), equals(initialOutput));
        },
      );
    });

    test('nested widgets only rebuild when their state changes', () async {
      await testNocterm(
        'nested rebuild isolation',
        (tester) async {
          await tester.pumpComponent(const _NestedCounters());

          expect(tester.terminalState, containsText('Outer: 1'));
          expect(tester.terminalState, containsText('Inner: 1'));

          // Trigger only inner rebuild
          final innerState = _InnerCounter.lastState!;
          innerState.triggerRebuild();
          await tester.pump();

          // Outer should NOT have rebuilt
          expect(tester.terminalState, containsText('Outer: 1'));
          // Inner should have rebuilt
          expect(tester.terminalState, containsText('Inner: 2'));
        },
      );
    });
  });

  group('Frame Skip Regression Prevention', () {
    test('spinner component causes rebuilds only when animating', () async {
      await testNocterm(
        'spinner rebuild behavior',
        (tester) async {
          await tester.pumpComponent(const _AnimatingSpinner());

          final state = _AnimatingSpinner.lastState!;
          expect(state.buildCount, equals(1));

          // Wait for some animation frames
          await Future.delayed(const Duration(milliseconds: 350));
          await tester.pump();

          final animatingBuildCount = state.buildCount;
          expect(animatingBuildCount, greaterThan(1));

          // Stop the animation
          state.stopAnimation();
          await tester.pump();

          final stoppedBuildCount = state.buildCount;

          // Pump more frames - should NOT rebuild
          await tester.pump();
          await tester.pump();
          await Future.delayed(const Duration(milliseconds: 150));
          await tester.pump();

          // Build count should be same as when stopped
          expect(state.buildCount, equals(stoppedBuildCount));
        },
      );
    });

    test('high-frequency setState calls are batched into single frame',
        () async {
      await testNocterm(
        'frame batching',
        (tester) async {
          await tester.pumpComponent(const _BuildCounter());

          expect(tester.terminalState, containsText('Build count: 1'));

          final state = _BuildCounter.lastState!;

          // Trigger many rebuilds rapidly (simulating scroll events)
          for (int i = 0; i < 100; i++) {
            state.triggerRebuild();
          }

          // Single pump should handle all of them
          await tester.pump();

          // Should have built only twice total (initial + 1 batch)
          expect(state.buildCount, equals(2));
        },
      );
    });

    test('frame skip works with complex widget tree', () async {
      await testNocterm(
        'complex tree skip',
        (tester) async {
          _ComplexTreeTracker.reset();

          await tester.pumpComponent(const _ComplexTree());

          // Count initial builds
          final initialBuilds = _ComplexTreeTracker.totalBuilds;
          expect(initialBuilds, greaterThan(0));

          // Pump frames - no rebuilds should occur
          await tester.pump();
          await tester.pump();
          await tester.pump();

          expect(_ComplexTreeTracker.totalBuilds, equals(initialBuilds));
        },
      );
    });

    test('multiple independent stateful widgets do not affect each other',
        () async {
      await testNocterm(
        'independent widgets',
        (tester) async {
          await tester.pumpComponent(const _TwoIndependentCounters());

          final stateA = _CounterA.lastState!;
          final stateB = _CounterB.lastState!;

          expect(stateA.buildCount, equals(1));
          expect(stateB.buildCount, equals(1));

          // Trigger rebuild on A only
          stateA.triggerRebuild();
          await tester.pump();

          // A rebuilt, B should not
          expect(stateA.buildCount, equals(2));
          expect(stateB.buildCount, equals(1));

          // Trigger rebuild on B only
          stateB.triggerRebuild();
          await tester.pump();

          // B rebuilt, A should not
          expect(stateA.buildCount, equals(2));
          expect(stateB.buildCount, equals(2));
        },
      );
    });

    test('frame skip after animation completes', () async {
      await testNocterm(
        'post animation skip',
        (tester) async {
          await tester.pumpComponent(const _AnimatingSpinner());

          final state = _AnimatingSpinner.lastState!;

          // Let animation run
          await Future.delayed(const Duration(milliseconds: 250));
          await tester.pump();

          // Stop animation
          state.stopAnimation();
          await tester.pump();

          final buildCountAfterStop = state.buildCount;

          // Wait and pump multiple times - no rebuilds should happen
          for (int i = 0; i < 5; i++) {
            await Future.delayed(const Duration(milliseconds: 50));
            await tester.pump();
          }

          // Build count should not have increased
          expect(state.buildCount, equals(buildCountAfterStop));
        },
      );
    });
  });
}

// ============================================================================
// Test Helper Components
// ============================================================================

/// A simple counter that tracks how many times it builds.
class _BuildCounter extends StatefulComponent {
  const _BuildCounter();

  static _BuildCounterState? lastState;

  @override
  State<_BuildCounter> createState() => _BuildCounterState();
}

class _BuildCounterState extends State<_BuildCounter> {
  int buildCount = 0;

  @override
  void initState() {
    super.initState();
    _BuildCounter.lastState = this;
  }

  void triggerRebuild() {
    setState(() {});
  }

  @override
  Component build(BuildContext context) {
    buildCount++;
    return Text('Build count: $buildCount');
  }
}

/// A counter that increments via a timer.
class _TimerCounter extends StatefulComponent {
  const _TimerCounter();

  static _TimerCounterState? lastState;

  @override
  State<_TimerCounter> createState() => _TimerCounterState();
}

class _TimerCounterState extends State<_TimerCounter> {
  Timer? _timer;
  int value = 0;
  int buildCount = 0;

  @override
  void initState() {
    super.initState();
    _TimerCounter.lastState = this;
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      setState(() => value++);
    });
  }

  void stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    buildCount++;
    return Text('Value: $value');
  }
}

/// Nested counters to test rebuild isolation.
class _NestedCounters extends StatefulComponent {
  const _NestedCounters();

  // ignore: unused_field
  static _NestedCountersState? lastState;

  @override
  State<_NestedCounters> createState() => _NestedCountersState();
}

class _NestedCountersState extends State<_NestedCounters> {
  int outerBuildCount = 0;

  @override
  void initState() {
    super.initState();
    _NestedCounters.lastState = this;
  }

  @override
  Component build(BuildContext context) {
    outerBuildCount++;
    return Column(
      children: [
        Text('Outer: $outerBuildCount'),
        const _InnerCounter(),
      ],
    );
  }
}

class _InnerCounter extends StatefulComponent {
  const _InnerCounter();

  static _InnerCounterState? lastState;

  @override
  State<_InnerCounter> createState() => _InnerCounterState();
}

class _InnerCounterState extends State<_InnerCounter> {
  int innerBuildCount = 0;

  @override
  void initState() {
    super.initState();
    _InnerCounter.lastState = this;
  }

  void triggerRebuild() {
    setState(() {});
  }

  @override
  Component build(BuildContext context) {
    innerBuildCount++;
    return Text('Inner: $innerBuildCount');
  }
}

/// An animating spinner that can be stopped.
class _AnimatingSpinner extends StatefulComponent {
  const _AnimatingSpinner();

  static _AnimatingSpinnerState? lastState;

  @override
  State<_AnimatingSpinner> createState() => _AnimatingSpinnerState();
}

class _AnimatingSpinnerState extends State<_AnimatingSpinner> {
  static const _frames = ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'];
  Timer? _timer;
  int _index = 0;
  int buildCount = 0;
  bool isAnimating = true;

  @override
  void initState() {
    super.initState();
    _AnimatingSpinner.lastState = this;
    _startAnimation();
  }

  void _startAnimation() {
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      setState(() {
        _index = (_index + 1) % _frames.length;
      });
    });
  }

  void stopAnimation() {
    _timer?.cancel();
    _timer = null;
    isAnimating = false;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    buildCount++;
    return Text(isAnimating ? _frames[_index] : 'Stopped');
  }
}

/// Tracks complex tree builds.
class _ComplexTreeTracker {
  static int totalBuilds = 0;

  static void reset() {
    totalBuilds = 0;
  }

  static void recordBuild() {
    totalBuilds++;
  }
}

/// A complex widget tree for testing.
class _ComplexTree extends StatelessComponent {
  const _ComplexTree();

  @override
  Component build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < 10; i++)
          Builder(builder: (context) {
            _ComplexTreeTracker.recordBuild();
            return Row(
              children: [
                Text('Row $i'),
                for (int j = 0; j < 5; j++)
                  Builder(builder: (context) {
                    _ComplexTreeTracker.recordBuild();
                    return Text(' Cell $j');
                  }),
              ],
            );
          }),
      ],
    );
  }
}

/// Two independent counters to test isolation.
class _TwoIndependentCounters extends StatelessComponent {
  const _TwoIndependentCounters();

  @override
  Component build(BuildContext context) {
    return Column(
      children: const [
        _CounterA(),
        _CounterB(),
      ],
    );
  }
}

class _CounterA extends StatefulComponent {
  const _CounterA();

  static _CounterAState? lastState;

  @override
  State<_CounterA> createState() => _CounterAState();
}

class _CounterAState extends State<_CounterA> {
  int buildCount = 0;

  @override
  void initState() {
    super.initState();
    _CounterA.lastState = this;
  }

  void triggerRebuild() => setState(() {});

  @override
  Component build(BuildContext context) {
    buildCount++;
    return Text('A: $buildCount');
  }
}

class _CounterB extends StatefulComponent {
  const _CounterB();

  static _CounterBState? lastState;

  @override
  State<_CounterB> createState() => _CounterBState();
}

class _CounterBState extends State<_CounterB> {
  int buildCount = 0;

  @override
  void initState() {
    super.initState();
    _CounterB.lastState = this;
  }

  void triggerRebuild() => setState(() {});

  @override
  Component build(BuildContext context) {
    buildCount++;
    return Text('B: $buildCount');
  }
}
