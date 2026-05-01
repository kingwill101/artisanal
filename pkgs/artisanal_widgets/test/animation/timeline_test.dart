import 'package:artisanal/tui.dart' show Cmd;
import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:test/test.dart';

void main() {
  group('AnimationTimeline', () {
    test('runs controller steps in sequence', () {
      final firstStart = DateTime(2026, 1, 1, 0, 0, 0);
      final secondStart = DateTime(2026, 1, 1, 0, 0, 1);
      final first = AnimationController(
        duration: const Duration(milliseconds: 100),
      );
      final second = AnimationController(
        duration: const Duration(milliseconds: 100),
      );
      addTearDown(first.dispose);
      addTearDown(second.dispose);

      final timeline = AnimationTimeline(
        steps: [
          AnimationTimelineStep.forward(first),
          AnimationTimelineStep.forward(second),
        ],
      );

      final initial = timeline.start();
      expect(initial, isA<Cmd>());
      expect(timeline.isRunning, isTrue);
      expect(timeline.currentStepIndex, 0);
      expect(first.status, AnimationStatus.forward);
      expect(second.isAnimating, isFalse);

      timeline.handleMessage(AnimationTickMsg(first.id, firstStart));
      final advance = timeline.handleMessage(
        AnimationTickMsg(
          first.id,
          firstStart.add(const Duration(milliseconds: 100)),
        ),
      );

      expect(advance, isA<Cmd>());
      expect(first.status, AnimationStatus.completed);
      expect(second.status, AnimationStatus.forward);
      expect(timeline.currentStepIndex, 1);

      timeline.handleMessage(AnimationTickMsg(second.id, secondStart));
      final done = timeline.handleMessage(
        AnimationTickMsg(
          second.id,
          secondStart.add(const Duration(milliseconds: 100)),
        ),
      );

      expect(done, isNull);
      expect(second.status, AnimationStatus.completed);
      expect(timeline.isRunning, isFalse);
      expect(timeline.completedCycles, 1);
    });

    test('starts parallel steps together and waits for all of them', () {
      final firstStart = DateTime(2026, 1, 1, 0, 0, 0);
      final secondStart = DateTime(2026, 1, 1, 0, 0, 1);
      final first = AnimationController(
        duration: const Duration(milliseconds: 100),
      );
      final second = AnimationController(
        duration: const Duration(milliseconds: 100),
      );
      addTearDown(first.dispose);
      addTearDown(second.dispose);

      final timeline = AnimationTimeline(
        steps: [
          AnimationTimelineStep.parallel([
            AnimationTimelineStep.forward(first),
            AnimationTimelineStep.forward(second),
          ]),
        ],
      );

      final initial = timeline.start();
      expect(initial, isA<Cmd>());
      expect(first.status, AnimationStatus.forward);
      expect(second.status, AnimationStatus.forward);

      timeline.handleMessage(AnimationTickMsg(first.id, firstStart));
      final partial = timeline.handleMessage(
        AnimationTickMsg(
          first.id,
          firstStart.add(const Duration(milliseconds: 100)),
        ),
      );
      expect(partial, isNull);
      expect(first.status, AnimationStatus.completed);
      expect(second.isAnimating, isTrue);
      expect(timeline.isRunning, isTrue);

      timeline.handleMessage(AnimationTickMsg(second.id, secondStart));
      final done = timeline.handleMessage(
        AnimationTickMsg(
          second.id,
          secondStart.add(const Duration(milliseconds: 100)),
        ),
      );

      expect(done, isNull);
      expect(second.status, AnimationStatus.completed);
      expect(timeline.isRunning, isFalse);
      expect(timeline.completedCycles, 1);
    });

    test('zero-delay steps advance immediately into the next step', () {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 100),
      );
      addTearDown(controller.dispose);

      final timeline = AnimationTimeline(
        steps: [
          AnimationTimelineStep.delay(Duration.zero),
          AnimationTimelineStep.forward(controller),
        ],
      );

      final initial = timeline.start();
      expect(initial, isA<Cmd>());
      expect(controller.status, AnimationStatus.forward);
      expect(timeline.currentStepIndex, 1);
    });

    test(
      'repeat with alternate flips playback direction on the next cycle',
      () {
        final start = DateTime(2026, 1, 1, 0, 0, 0);
        final controller = AnimationController(
          value: 0.0,
          duration: const Duration(milliseconds: 100),
        );
        addTearDown(controller.dispose);

        final timeline = AnimationTimeline(
          steps: [AnimationTimelineStep.forward(controller)],
          repeat: true,
          alternate: true,
        );

        timeline.start();
        timeline.handleMessage(AnimationTickMsg(controller.id, start));
        final restart = timeline.handleMessage(
          AnimationTickMsg(
            controller.id,
            start.add(const Duration(milliseconds: 100)),
          ),
        );

        expect(restart, isA<Cmd>());
        expect(timeline.isRunning, isTrue);
        expect(timeline.completedCycles, 1);
        expect(timeline.direction, TimelineDirection.reverse);
        expect(controller.status, AnimationStatus.reverse);
      },
    );

    test('stop resets active execution without changing controller state', () {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 100),
      );
      addTearDown(controller.dispose);

      final timeline = AnimationTimeline(
        steps: [AnimationTimelineStep.forward(controller)],
      );

      timeline.start();
      expect(timeline.isRunning, isTrue);

      timeline.stop();
      expect(timeline.isRunning, isFalse);
      expect(timeline.currentStepIndex, -1);
      expect(controller.status, AnimationStatus.forward);
      expect(
        timeline.handleMessage(
          AnimationTickMsg(controller.id, DateTime(2026, 1, 1)),
        ),
        isNull,
      );
    });

    test('exposes active step labels and invokes lifecycle hooks', () {
      final start = DateTime(2026, 1, 1, 0, 0, 0);
      final first = AnimationController(
        duration: const Duration(milliseconds: 100),
      );
      final second = AnimationController(
        duration: const Duration(milliseconds: 100),
      );
      addTearDown(first.dispose);
      addTearDown(second.dispose);

      final events = <String>[];
      final timeline = AnimationTimeline(
        steps: [
          AnimationTimelineStep.forward(first, label: 'fade-in'),
          AnimationTimelineStep.forward(second, label: 'slide-in'),
        ],
        onStepStart: (index, step, direction) {
          events.add('start:$index:${step.label}:$direction');
        },
        onStepComplete: (index, step, direction) {
          events.add('done:$index:${step.label}:$direction');
        },
      );

      timeline.start();
      expect(timeline.currentStepLabel, 'fade-in');
      expect(events, ['start:0:fade-in:TimelineDirection.forward']);

      timeline.handleMessage(AnimationTickMsg(first.id, start));
      timeline.handleMessage(
        AnimationTickMsg(
          first.id,
          start.add(const Duration(milliseconds: 100)),
        ),
      );

      expect(timeline.currentStepLabel, 'slide-in');
      expect(events, [
        'start:0:fade-in:TimelineDirection.forward',
        'done:0:fade-in:TimelineDirection.forward',
        'start:1:slide-in:TimelineDirection.forward',
      ]);
    });

    test('staggeredForward builds delayed sequential controller playback', () {
      final firstStart = DateTime(2026, 1, 1, 0, 0, 0);
      final first = AnimationController(
        duration: const Duration(milliseconds: 100),
      );
      final second = AnimationController(
        duration: const Duration(milliseconds: 100),
      );
      addTearDown(first.dispose);
      addTearDown(second.dispose);

      final timeline = AnimationTimeline.staggeredForward(
        controllers: [first, second],
        gap: Duration.zero,
        labelForController: (index) => 'controller-$index',
      );

      final initial = timeline.start();
      expect(initial, isA<Cmd>());
      expect(timeline.currentStepLabel, 'controller-0');

      timeline.handleMessage(AnimationTickMsg(first.id, firstStart));
      final afterFirst = timeline.handleMessage(
        AnimationTickMsg(
          first.id,
          firstStart.add(const Duration(milliseconds: 100)),
        ),
      );

      expect(afterFirst, isA<Cmd>());
      expect(timeline.currentStepLabel, 'controller-1');
      expect(second.isAnimating, isTrue);
    });

    test('callback steps run synchronously and can hand off to next step', () {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 100),
      );
      addTearDown(controller.dispose);

      final events = <String>[];
      final timeline = AnimationTimeline(
        steps: [
          AnimationTimelineStep.callback((direction) {
            events.add('callback:$direction');
            return null;
          }, label: 'hook'),
          AnimationTimelineStep.forward(controller, label: 'animate'),
        ],
      );

      final initial = timeline.start();
      expect(initial, isA<Cmd>());
      expect(events, ['callback:TimelineDirection.forward']);
      expect(timeline.currentStepLabel, 'animate');
      expect(controller.status, AnimationStatus.forward);
    });

    test('generic staggered builder supports custom step choreography', () {
      final firstStart = DateTime(2026, 1, 1, 0, 0, 0);
      final first = AnimationController(
        value: 1.0,
        duration: const Duration(milliseconds: 100),
      );
      final second = AnimationController(
        value: 1.0,
        duration: const Duration(milliseconds: 100),
      );
      addTearDown(first.dispose);
      addTearDown(second.dispose);

      final timeline = AnimationTimeline.staggered(
        controllers: [first, second],
        gap: Duration.zero,
        buildStep: (index, controller) =>
            AnimationTimelineStep.reverse(controller, label: 'reverse-$index'),
      );

      final initial = timeline.start();
      expect(initial, isA<Cmd>());
      expect(timeline.currentStepLabel, 'reverse-0');
      expect(first.status, AnimationStatus.reverse);

      timeline.handleMessage(AnimationTickMsg(first.id, firstStart));
      final afterFirst = timeline.handleMessage(
        AnimationTickMsg(
          first.id,
          firstStart.add(const Duration(milliseconds: 100)),
        ),
      );

      expect(afterFirst, isA<Cmd>());
      expect(timeline.currentStepLabel, 'reverse-1');
      expect(second.status, AnimationStatus.reverse);
    });

    test('pulse builds a reusable forward-then-reverse cycle', () {
      final start = DateTime(2026, 1, 1, 0, 0, 0);
      final controller = AnimationController(
        duration: const Duration(milliseconds: 100),
      );
      addTearDown(controller.dispose);

      final started = <String>[];
      final completed = <String>[];
      final timeline = AnimationTimeline.pulse(
        controller: controller,
        onStepStart: (index, step, direction) {
          started.add(step.label ?? '$index');
        },
        onStepComplete: (index, step, direction) {
          completed.add(step.label ?? '$index');
        },
      );

      final initial = timeline.start();
      expect(initial, isA<Cmd>());
      expect(timeline.currentStepLabel, 'pulse-in');
      expect(controller.status, AnimationStatus.forward);

      timeline.handleMessage(AnimationTickMsg(controller.id, start));
      final afterForward = timeline.handleMessage(
        AnimationTickMsg(
          controller.id,
          start.add(const Duration(milliseconds: 100)),
        ),
      );
      expect(afterForward, isA<Cmd>());
      expect(timeline.currentStepLabel, 'pulse-out');
      expect(controller.status, AnimationStatus.reverse);

      timeline.handleMessage(
        AnimationTickMsg(
          controller.id,
          start.add(const Duration(milliseconds: 101)),
        ),
      );
      final afterReverse = timeline.handleMessage(
        AnimationTickMsg(
          controller.id,
          start.add(const Duration(milliseconds: 201)),
        ),
      );
      expect(afterReverse, isNull);
      expect(timeline.isRunning, isFalse);
      expect(started, ['pulse-in', 'pulse-out']);
      expect(completed, ['pulse-in', 'pulse-out']);
    });

    test(
      'cascade pulses controllers sequentially with per-controller labels',
      () {
        final start = DateTime(2026, 1, 1, 0, 0, 0);
        final first = AnimationController(
          duration: const Duration(milliseconds: 100),
        );
        final second = AnimationController(
          duration: const Duration(milliseconds: 100),
        );
        addTearDown(first.dispose);
        addTearDown(second.dispose);

        final timeline = AnimationTimeline.cascade(
          controllers: [first, second],
          hold: Duration.zero,
          gap: Duration.zero,
          labelBuilder: (index, phase) => '$phase-$index',
        );

        final initial = timeline.start();
        expect(initial, isA<Cmd>());
        expect(timeline.currentStepLabel, 'in-0');
        expect(first.status, AnimationStatus.forward);
        expect(second.isAnimating, isFalse);

        timeline.handleMessage(AnimationTickMsg(first.id, start));
        final afterFirstIn = timeline.handleMessage(
          AnimationTickMsg(
            first.id,
            start.add(const Duration(milliseconds: 100)),
          ),
        );
        expect(afterFirstIn, isA<Cmd>());
        expect(timeline.currentStepLabel, 'out-0');
        expect(first.status, AnimationStatus.reverse);

        timeline.handleMessage(
          AnimationTickMsg(
            first.id,
            start.add(const Duration(milliseconds: 101)),
          ),
        );
        final afterFirstOut = timeline.handleMessage(
          AnimationTickMsg(
            first.id,
            start.add(const Duration(milliseconds: 201)),
          ),
        );
        expect(afterFirstOut, isA<Cmd>());
        expect(timeline.currentStepLabel, 'in-1');
        expect(second.status, AnimationStatus.forward);

        timeline.handleMessage(
          AnimationTickMsg(
            second.id,
            start.add(const Duration(milliseconds: 202)),
          ),
        );
        timeline.handleMessage(
          AnimationTickMsg(
            second.id,
            start.add(const Duration(milliseconds: 302)),
          ),
        );
        expect(timeline.currentStepLabel, 'out-1');

        timeline.handleMessage(
          AnimationTickMsg(
            second.id,
            start.add(const Duration(milliseconds: 303)),
          ),
        );
        final done = timeline.handleMessage(
          AnimationTickMsg(
            second.id,
            start.add(const Duration(milliseconds: 403)),
          ),
        );
        expect(done, isNull);
        expect(timeline.isRunning, isFalse);
        expect(first.status, AnimationStatus.dismissed);
        expect(second.status, AnimationStatus.dismissed);
      },
    );

    test('wave mirrors controller order on the return sweep', () {
      final start = DateTime(2026, 1, 1, 0, 0, 0);
      final first = AnimationController(
        duration: const Duration(milliseconds: 100),
      );
      final second = AnimationController(
        duration: const Duration(milliseconds: 100),
      );
      final third = AnimationController(
        duration: const Duration(milliseconds: 100),
      );
      addTearDown(first.dispose);
      addTearDown(second.dispose);
      addTearDown(third.dispose);

      final timeline = AnimationTimeline.wave(
        controllers: [first, second, third],
        gap: Duration.zero,
        crestHold: Duration.zero,
        returnGap: Duration.zero,
        labelBuilder: (index, phase) => '$phase-$index',
      );

      final initial = timeline.start();
      expect(initial, isA<Cmd>());
      expect(timeline.currentStepLabel, 'crest-in-0');
      expect(first.status, AnimationStatus.forward);

      timeline.handleMessage(AnimationTickMsg(first.id, start));
      timeline.handleMessage(
        AnimationTickMsg(
          first.id,
          start.add(const Duration(milliseconds: 100)),
        ),
      );
      expect(timeline.currentStepLabel, 'crest-in-1');
      expect(second.status, AnimationStatus.forward);

      timeline.handleMessage(
        AnimationTickMsg(
          second.id,
          start.add(const Duration(milliseconds: 101)),
        ),
      );
      timeline.handleMessage(
        AnimationTickMsg(
          second.id,
          start.add(const Duration(milliseconds: 201)),
        ),
      );
      expect(timeline.currentStepLabel, 'crest-in-2');
      expect(third.status, AnimationStatus.forward);

      timeline.handleMessage(
        AnimationTickMsg(
          third.id,
          start.add(const Duration(milliseconds: 202)),
        ),
      );
      timeline.handleMessage(
        AnimationTickMsg(
          third.id,
          start.add(const Duration(milliseconds: 302)),
        ),
      );
      expect(timeline.currentStepLabel, 'crest-out-2');
      expect(third.status, AnimationStatus.reverse);

      timeline.handleMessage(
        AnimationTickMsg(
          third.id,
          start.add(const Duration(milliseconds: 303)),
        ),
      );
      timeline.handleMessage(
        AnimationTickMsg(
          third.id,
          start.add(const Duration(milliseconds: 403)),
        ),
      );
      expect(timeline.currentStepLabel, 'crest-out-1');
      expect(second.status, AnimationStatus.reverse);

      timeline.handleMessage(
        AnimationTickMsg(
          second.id,
          start.add(const Duration(milliseconds: 404)),
        ),
      );
      timeline.handleMessage(
        AnimationTickMsg(
          second.id,
          start.add(const Duration(milliseconds: 504)),
        ),
      );
      expect(timeline.currentStepLabel, 'crest-out-0');
      expect(first.status, AnimationStatus.reverse);

      timeline.handleMessage(
        AnimationTickMsg(
          first.id,
          start.add(const Duration(milliseconds: 505)),
        ),
      );
      final done = timeline.handleMessage(
        AnimationTickMsg(
          first.id,
          start.add(const Duration(milliseconds: 605)),
        ),
      );
      expect(done, isNull);
      expect(timeline.isRunning, isFalse);
      expect(first.status, AnimationStatus.dismissed);
      expect(second.status, AnimationStatus.dismissed);
      expect(third.status, AnimationStatus.dismissed);
    });

    test('fan staggers entrance and collapses controllers together', () {
      final start = DateTime(2026, 1, 1, 0, 0, 0);
      final first = AnimationController(
        duration: const Duration(milliseconds: 100),
      );
      final second = AnimationController(
        duration: const Duration(milliseconds: 100),
      );
      addTearDown(first.dispose);
      addTearDown(second.dispose);

      final timeline = AnimationTimeline.fan(
        controllers: [first, second],
        gap: Duration.zero,
        hold: Duration.zero,
        labelBuilder: (index, phase) => '$phase-$index',
      );

      final initial = timeline.start();
      expect(initial, isA<Cmd>());
      expect(timeline.currentStepLabel, 'in-0');
      expect(first.status, AnimationStatus.forward);
      expect(second.isAnimating, isFalse);

      timeline.handleMessage(AnimationTickMsg(first.id, start));
      final afterFirst = timeline.handleMessage(
        AnimationTickMsg(
          first.id,
          start.add(const Duration(milliseconds: 100)),
        ),
      );
      expect(afterFirst, isA<Cmd>());
      expect(timeline.currentStepLabel, 'in-1');
      expect(second.status, AnimationStatus.forward);

      timeline.handleMessage(
        AnimationTickMsg(
          second.id,
          start.add(const Duration(milliseconds: 101)),
        ),
      );
      final collapse = timeline.handleMessage(
        AnimationTickMsg(
          second.id,
          start.add(const Duration(milliseconds: 201)),
        ),
      );
      expect(collapse, isA<Cmd>());
      expect(timeline.currentStepLabel, 'collapse-1');
      expect(first.status, AnimationStatus.reverse);
      expect(second.status, AnimationStatus.reverse);

      timeline.handleMessage(
        AnimationTickMsg(
          first.id,
          start.add(const Duration(milliseconds: 202)),
        ),
      );
      timeline.handleMessage(
        AnimationTickMsg(
          second.id,
          start.add(const Duration(milliseconds: 202)),
        ),
      );
      timeline.handleMessage(
        AnimationTickMsg(
          first.id,
          start.add(const Duration(milliseconds: 302)),
        ),
      );
      final done = timeline.handleMessage(
        AnimationTickMsg(
          second.id,
          start.add(const Duration(milliseconds: 302)),
        ),
      );
      expect(done, isNull);
      expect(timeline.isRunning, isFalse);
      expect(first.status, AnimationStatus.dismissed);
      expect(second.status, AnimationStatus.dismissed);
    });

    test('breath expands and contracts controllers together', () {
      final start = DateTime(2026, 1, 1, 0, 0, 0);
      final first = AnimationController(
        duration: const Duration(milliseconds: 100),
      );
      final second = AnimationController(
        duration: const Duration(milliseconds: 100),
      );
      addTearDown(first.dispose);
      addTearDown(second.dispose);

      final timeline = AnimationTimeline.breath(
        controllers: [first, second],
        hold: Duration.zero,
        labelBuilder: (index, phase) => '$phase-$index',
      );

      final initial = timeline.start();
      expect(initial, isA<Cmd>());
      expect(timeline.currentStepLabel, 'expand-1');
      expect(first.status, AnimationStatus.forward);
      expect(second.status, AnimationStatus.forward);

      timeline.handleMessage(AnimationTickMsg(first.id, start));
      timeline.handleMessage(AnimationTickMsg(second.id, start));
      timeline.handleMessage(
        AnimationTickMsg(
          first.id,
          start.add(const Duration(milliseconds: 100)),
        ),
      );
      final contract = timeline.handleMessage(
        AnimationTickMsg(
          second.id,
          start.add(const Duration(milliseconds: 100)),
        ),
      );
      expect(contract, isA<Cmd>());
      expect(timeline.currentStepLabel, 'contract-1');
      expect(first.status, AnimationStatus.reverse);
      expect(second.status, AnimationStatus.reverse);

      timeline.handleMessage(
        AnimationTickMsg(
          first.id,
          start.add(const Duration(milliseconds: 101)),
        ),
      );
      timeline.handleMessage(
        AnimationTickMsg(
          second.id,
          start.add(const Duration(milliseconds: 101)),
        ),
      );
      timeline.handleMessage(
        AnimationTickMsg(
          first.id,
          start.add(const Duration(milliseconds: 201)),
        ),
      );
      final done = timeline.handleMessage(
        AnimationTickMsg(
          second.id,
          start.add(const Duration(milliseconds: 201)),
        ),
      );
      expect(done, isNull);
      expect(timeline.isRunning, isFalse);
      expect(first.status, AnimationStatus.dismissed);
      expect(second.status, AnimationStatus.dismissed);
    });

    test('ripple expands from the origin index and mirrors on return', () {
      final start = DateTime(2026, 1, 1, 0, 0, 0);
      final first = AnimationController(
        duration: const Duration(milliseconds: 100),
      );
      final second = AnimationController(
        duration: const Duration(milliseconds: 100),
      );
      final third = AnimationController(
        duration: const Duration(milliseconds: 100),
      );
      addTearDown(first.dispose);
      addTearDown(second.dispose);
      addTearDown(third.dispose);

      final timeline = AnimationTimeline.ripple(
        controllers: [first, second, third],
        originIndex: 1,
        gap: Duration.zero,
        crestHold: Duration.zero,
        returnGap: Duration.zero,
        labelBuilder: (index, phase) => '$phase-$index',
      );

      final initial = timeline.start();
      expect(initial, isA<Cmd>());
      expect(timeline.currentStepLabel, 'in-1');
      expect(second.status, AnimationStatus.forward);

      timeline.handleMessage(AnimationTickMsg(second.id, start));
      timeline.handleMessage(
        AnimationTickMsg(
          second.id,
          start.add(const Duration(milliseconds: 100)),
        ),
      );
      expect(timeline.currentStepLabel, 'in-0');
      expect(first.status, AnimationStatus.forward);

      timeline.handleMessage(
        AnimationTickMsg(
          first.id,
          start.add(const Duration(milliseconds: 101)),
        ),
      );
      timeline.handleMessage(
        AnimationTickMsg(
          first.id,
          start.add(const Duration(milliseconds: 201)),
        ),
      );
      expect(timeline.currentStepLabel, 'in-2');
      expect(third.status, AnimationStatus.forward);

      timeline.handleMessage(
        AnimationTickMsg(
          third.id,
          start.add(const Duration(milliseconds: 202)),
        ),
      );
      timeline.handleMessage(
        AnimationTickMsg(
          third.id,
          start.add(const Duration(milliseconds: 302)),
        ),
      );
      expect(timeline.currentStepLabel, 'out-2');
      expect(third.status, AnimationStatus.reverse);

      timeline.handleMessage(
        AnimationTickMsg(
          third.id,
          start.add(const Duration(milliseconds: 303)),
        ),
      );
      timeline.handleMessage(
        AnimationTickMsg(
          third.id,
          start.add(const Duration(milliseconds: 403)),
        ),
      );
      expect(timeline.currentStepLabel, 'out-0');
      expect(first.status, AnimationStatus.reverse);

      timeline.handleMessage(
        AnimationTickMsg(
          first.id,
          start.add(const Duration(milliseconds: 404)),
        ),
      );
      timeline.handleMessage(
        AnimationTickMsg(
          first.id,
          start.add(const Duration(milliseconds: 504)),
        ),
      );
      expect(timeline.currentStepLabel, 'out-1');
      expect(second.status, AnimationStatus.reverse);

      timeline.handleMessage(
        AnimationTickMsg(
          second.id,
          start.add(const Duration(milliseconds: 505)),
        ),
      );
      final done = timeline.handleMessage(
        AnimationTickMsg(
          second.id,
          start.add(const Duration(milliseconds: 605)),
        ),
      );
      expect(done, isNull);
      expect(timeline.isRunning, isFalse);
      expect(first.status, AnimationStatus.dismissed);
      expect(second.status, AnimationStatus.dismissed);
      expect(third.status, AnimationStatus.dismissed);
    });

    test('converge travels from the edges inward and back out', () {
      final start = DateTime(2026, 1, 1, 0, 0, 0);
      final first = AnimationController(
        duration: const Duration(milliseconds: 100),
      );
      final second = AnimationController(
        duration: const Duration(milliseconds: 100),
      );
      final third = AnimationController(
        duration: const Duration(milliseconds: 100),
      );
      addTearDown(first.dispose);
      addTearDown(second.dispose);
      addTearDown(third.dispose);

      final timeline = AnimationTimeline.converge(
        controllers: [first, second, third],
        gap: Duration.zero,
        crestHold: Duration.zero,
        returnGap: Duration.zero,
        labelBuilder: (index, phase) => '$phase-$index',
      );

      final initial = timeline.start();
      expect(initial, isA<Cmd>());
      expect(timeline.currentStepLabel, 'in-0');
      expect(first.status, AnimationStatus.forward);

      timeline.handleMessage(AnimationTickMsg(first.id, start));
      timeline.handleMessage(
        AnimationTickMsg(
          first.id,
          start.add(const Duration(milliseconds: 100)),
        ),
      );
      expect(timeline.currentStepLabel, 'in-2');
      expect(third.status, AnimationStatus.forward);

      timeline.handleMessage(
        AnimationTickMsg(
          third.id,
          start.add(const Duration(milliseconds: 101)),
        ),
      );
      timeline.handleMessage(
        AnimationTickMsg(
          third.id,
          start.add(const Duration(milliseconds: 201)),
        ),
      );
      expect(timeline.currentStepLabel, 'in-1');
      expect(second.status, AnimationStatus.forward);

      timeline.handleMessage(
        AnimationTickMsg(
          second.id,
          start.add(const Duration(milliseconds: 202)),
        ),
      );
      timeline.handleMessage(
        AnimationTickMsg(
          second.id,
          start.add(const Duration(milliseconds: 302)),
        ),
      );
      expect(timeline.currentStepLabel, 'out-1');
      expect(second.status, AnimationStatus.reverse);

      timeline.handleMessage(
        AnimationTickMsg(
          second.id,
          start.add(const Duration(milliseconds: 303)),
        ),
      );
      timeline.handleMessage(
        AnimationTickMsg(
          second.id,
          start.add(const Duration(milliseconds: 403)),
        ),
      );
      expect(timeline.currentStepLabel, 'out-2');
      expect(third.status, AnimationStatus.reverse);

      timeline.handleMessage(
        AnimationTickMsg(
          third.id,
          start.add(const Duration(milliseconds: 404)),
        ),
      );
      timeline.handleMessage(
        AnimationTickMsg(
          third.id,
          start.add(const Duration(milliseconds: 504)),
        ),
      );
      expect(timeline.currentStepLabel, 'out-0');
      expect(first.status, AnimationStatus.reverse);

      timeline.handleMessage(
        AnimationTickMsg(
          first.id,
          start.add(const Duration(milliseconds: 505)),
        ),
      );
      final done = timeline.handleMessage(
        AnimationTickMsg(
          first.id,
          start.add(const Duration(milliseconds: 605)),
        ),
      );
      expect(done, isNull);
      expect(timeline.isRunning, isFalse);
      expect(first.status, AnimationStatus.dismissed);
      expect(second.status, AnimationStatus.dismissed);
      expect(third.status, AnimationStatus.dismissed);
    });

    test('accordion expands and collapses symmetric pairs together', () {
      final start = DateTime(2026, 1, 1, 0, 0, 0);
      final first = AnimationController(
        duration: const Duration(milliseconds: 100),
      );
      final second = AnimationController(
        duration: const Duration(milliseconds: 100),
      );
      final third = AnimationController(
        duration: const Duration(milliseconds: 100),
      );
      final fourth = AnimationController(
        duration: const Duration(milliseconds: 100),
      );
      addTearDown(first.dispose);
      addTearDown(second.dispose);
      addTearDown(third.dispose);
      addTearDown(fourth.dispose);

      final timeline = AnimationTimeline.accordion(
        controllers: [first, second, third, fourth],
        gap: Duration.zero,
        crestHold: Duration.zero,
        returnGap: Duration.zero,
      );

      final initial = timeline.start();
      expect(initial, isA<Cmd>());
      expect(timeline.currentStepLabel, 'accordion-expand-0');
      expect(second.status, AnimationStatus.forward);
      expect(third.status, AnimationStatus.forward);
      expect(first.isAnimating, isFalse);
      expect(fourth.isAnimating, isFalse);

      timeline.handleMessage(AnimationTickMsg(second.id, start));
      timeline.handleMessage(AnimationTickMsg(third.id, start));
      timeline.handleMessage(
        AnimationTickMsg(
          second.id,
          start.add(const Duration(milliseconds: 100)),
        ),
      );
      final afterCenter = timeline.handleMessage(
        AnimationTickMsg(
          third.id,
          start.add(const Duration(milliseconds: 100)),
        ),
      );
      expect(afterCenter, isA<Cmd>());
      expect(timeline.currentStepLabel, 'accordion-expand-1');
      expect(first.status, AnimationStatus.forward);
      expect(fourth.status, AnimationStatus.forward);

      timeline.handleMessage(
        AnimationTickMsg(
          first.id,
          start.add(const Duration(milliseconds: 101)),
        ),
      );
      timeline.handleMessage(
        AnimationTickMsg(
          fourth.id,
          start.add(const Duration(milliseconds: 101)),
        ),
      );
      timeline.handleMessage(
        AnimationTickMsg(
          first.id,
          start.add(const Duration(milliseconds: 201)),
        ),
      );
      final collapseOuter = timeline.handleMessage(
        AnimationTickMsg(
          fourth.id,
          start.add(const Duration(milliseconds: 201)),
        ),
      );
      expect(collapseOuter, isA<Cmd>());
      expect(timeline.currentStepLabel, 'accordion-collapse-1');
      expect(first.status, AnimationStatus.reverse);
      expect(fourth.status, AnimationStatus.reverse);

      timeline.handleMessage(
        AnimationTickMsg(
          first.id,
          start.add(const Duration(milliseconds: 202)),
        ),
      );
      timeline.handleMessage(
        AnimationTickMsg(
          fourth.id,
          start.add(const Duration(milliseconds: 202)),
        ),
      );
      timeline.handleMessage(
        AnimationTickMsg(
          first.id,
          start.add(const Duration(milliseconds: 302)),
        ),
      );
      final collapseCenter = timeline.handleMessage(
        AnimationTickMsg(
          fourth.id,
          start.add(const Duration(milliseconds: 302)),
        ),
      );
      expect(collapseCenter, isA<Cmd>());
      expect(timeline.currentStepLabel, 'accordion-collapse-0');
      expect(second.status, AnimationStatus.reverse);
      expect(third.status, AnimationStatus.reverse);

      timeline.handleMessage(
        AnimationTickMsg(
          second.id,
          start.add(const Duration(milliseconds: 303)),
        ),
      );
      timeline.handleMessage(
        AnimationTickMsg(
          third.id,
          start.add(const Duration(milliseconds: 303)),
        ),
      );
      timeline.handleMessage(
        AnimationTickMsg(
          second.id,
          start.add(const Duration(milliseconds: 403)),
        ),
      );
      final done = timeline.handleMessage(
        AnimationTickMsg(
          third.id,
          start.add(const Duration(milliseconds: 403)),
        ),
      );
      expect(done, isNull);
      expect(timeline.isRunning, isFalse);
      expect(first.status, AnimationStatus.dismissed);
      expect(second.status, AnimationStatus.dismissed);
      expect(third.status, AnimationStatus.dismissed);
      expect(fourth.status, AnimationStatus.dismissed);
    });
  });
}
