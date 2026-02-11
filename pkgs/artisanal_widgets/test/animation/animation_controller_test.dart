import 'package:artisanal/tui.dart' show Cmd;
import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:test/test.dart';

void main() {
  group('AnimationController construction', () {
    test('initial value defaults to lowerBound', () {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 300),
      );
      expect(controller.value, 0.0);
      expect(controller.status, AnimationStatus.dismissed);
      addTearDown(controller.dispose);
    });

    test('initial value can be set explicitly', () {
      final controller = AnimationController(
        value: 0.5,
        duration: const Duration(milliseconds: 300),
      );
      expect(controller.value, 0.5);
      addTearDown(controller.dispose);
    });

    test('custom bounds are respected', () {
      final controller = AnimationController(
        lowerBound: 10.0,
        upperBound: 20.0,
        duration: const Duration(milliseconds: 300),
      );
      expect(controller.value, 10.0);
      expect(controller.lowerBound, 10.0);
      expect(controller.upperBound, 20.0);
      addTearDown(controller.dispose);
    });

    test('custom id is used', () {
      final id = 'my-animation';
      final controller = AnimationController(
        duration: const Duration(milliseconds: 300),
        id: id,
      );
      expect(controller.id, id);
      addTearDown(controller.dispose);
    });

    test('auto-generated id is an Object', () {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 300),
      );
      expect(controller.id, isNotNull);
      addTearDown(controller.dispose);
    });

    test('two controllers get different auto-generated ids', () {
      final a = AnimationController(
        duration: const Duration(milliseconds: 300),
      );
      final b = AnimationController(
        duration: const Duration(milliseconds: 300),
      );
      expect(a.id, isNot(equals(b.id)));
      addTearDown(a.dispose);
      addTearDown(b.dispose);
    });

    test('fps defaults to 30', () {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 300),
      );
      expect(controller.fps, 30);
      addTearDown(controller.dispose);
    });

    test('custom fps is accepted', () {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 300),
        fps: 60,
      );
      expect(controller.fps, 60);
      addTearDown(controller.dispose);
    });

    test('initial status is dismissed', () {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 300),
      );
      expect(controller.status, AnimationStatus.dismissed);
      expect(controller.isDismissed, isTrue);
      expect(controller.isCompleted, isFalse);
      expect(controller.isAnimating, isFalse);
      addTearDown(controller.dispose);
    });
  });

  group('AnimationController.forward', () {
    test('returns a Cmd', () {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 300),
      );
      final cmd = controller.forward();
      expect(cmd, isA<Cmd>());
      addTearDown(controller.dispose);
    });

    test('sets status to forward', () {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 300),
      );
      controller.forward();
      expect(controller.status, AnimationStatus.forward);
      expect(controller.isAnimating, isTrue);
      addTearDown(controller.dispose);
    });

    test('from parameter sets initial value', () {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 300),
      );
      controller.forward(from: 0.3);
      expect(controller.value, 0.3);
      addTearDown(controller.dispose);
    });

    test('from parameter is clamped to bounds', () {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 300),
      );
      controller.forward(from: -1.0);
      expect(controller.value, 0.0);

      controller.forward(from: 5.0);
      expect(controller.value, 1.0);
      addTearDown(controller.dispose);
    });

    test('notifies status listeners', () {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 300),
      );
      AnimationStatus? reported;
      controller.addStatusListener((status) => reported = status);

      controller.forward();
      expect(reported, AnimationStatus.forward);
      addTearDown(controller.dispose);
    });
  });

  group('AnimationController.reverse', () {
    test('returns a Cmd', () {
      final controller = AnimationController(
        value: 1.0,
        duration: const Duration(milliseconds: 300),
      );
      final cmd = controller.reverse();
      expect(cmd, isA<Cmd>());
      addTearDown(controller.dispose);
    });

    test('sets status to reverse', () {
      final controller = AnimationController(
        value: 1.0,
        duration: const Duration(milliseconds: 300),
      );
      controller.reverse();
      expect(controller.status, AnimationStatus.reverse);
      expect(controller.isAnimating, isTrue);
      addTearDown(controller.dispose);
    });

    test('from parameter sets initial value', () {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 300),
      );
      controller.reverse(from: 0.8);
      expect(controller.value, 0.8);
      addTearDown(controller.dispose);
    });

    test('notifies status listeners', () {
      final controller = AnimationController(
        value: 1.0,
        duration: const Duration(milliseconds: 300),
      );
      AnimationStatus? reported;
      controller.addStatusListener((status) => reported = status);

      controller.reverse();
      expect(reported, AnimationStatus.reverse);
      addTearDown(controller.dispose);
    });
  });

  group('AnimationController.animateTo', () {
    test('returns a Cmd', () {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 300),
      );
      final cmd = controller.animateTo(0.5);
      expect(cmd, isA<Cmd>());
      addTearDown(controller.dispose);
    });

    test('target is clamped to bounds', () {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 300),
      );
      controller.animateTo(5.0);
      // Target is clamped internally; animation heads toward upperBound
      expect(controller.status, AnimationStatus.forward);
      addTearDown(controller.dispose);
    });

    test('animating up sets status to forward', () {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 300),
      );
      controller.animateTo(0.8);
      expect(controller.status, AnimationStatus.forward);
      addTearDown(controller.dispose);
    });

    test('animating down sets status to reverse', () {
      final controller = AnimationController(
        value: 1.0,
        duration: const Duration(milliseconds: 300),
      );
      controller.animateTo(0.2);
      expect(controller.status, AnimationStatus.reverse);
      addTearDown(controller.dispose);
    });

    test('optional duration overrides controller duration', () {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 300),
      );
      controller.animateTo(1.0, duration: const Duration(milliseconds: 100));
      expect(controller.duration, const Duration(milliseconds: 100));
      addTearDown(controller.dispose);
    });
  });

  group('AnimationController.animateBack', () {
    test('returns a Cmd', () {
      final controller = AnimationController(
        value: 1.0,
        duration: const Duration(milliseconds: 300),
      );
      final cmd = controller.animateBack(0.0);
      expect(cmd, isA<Cmd>());
      addTearDown(controller.dispose);
    });

    test('animating down sets status to reverse', () {
      final controller = AnimationController(
        value: 1.0,
        duration: const Duration(milliseconds: 300),
      );
      controller.animateBack(0.0);
      expect(controller.status, AnimationStatus.reverse);
      addTearDown(controller.dispose);
    });

    test('optional duration overrides reverseDuration', () {
      final controller = AnimationController(
        value: 1.0,
        duration: const Duration(milliseconds: 300),
      );
      controller.animateBack(0.0, duration: const Duration(milliseconds: 100));
      expect(controller.reverseDuration, const Duration(milliseconds: 100));
      addTearDown(controller.dispose);
    });
  });

  group('AnimationController.repeat', () {
    test('returns a Cmd', () {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 300),
      );
      final cmd = controller.repeat();
      expect(cmd, isA<Cmd>());
      addTearDown(controller.dispose);
    });

    test('sets status to forward', () {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 300),
      );
      controller.repeat();
      expect(controller.status, AnimationStatus.forward);
      expect(controller.isAnimating, isTrue);
      addTearDown(controller.dispose);
    });

    test('resets value to lowerBound (or min)', () {
      final controller = AnimationController(
        value: 0.5,
        duration: const Duration(milliseconds: 300),
      );
      controller.repeat();
      expect(controller.value, 0.0);
      addTearDown(controller.dispose);
    });

    test('custom min/max is used', () {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 300),
      );
      controller.repeat(min: 0.2, max: 0.8);
      expect(controller.value, 0.2);
      addTearDown(controller.dispose);
    });

    test('period overrides duration', () {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 300),
      );
      controller.repeat(period: const Duration(seconds: 1));
      expect(controller.duration, const Duration(seconds: 1));
      addTearDown(controller.dispose);
    });
  });

  group('AnimationController.stop', () {
    test('stops a forward animation', () {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 300),
      );
      controller.forward();
      expect(controller.isAnimating, isTrue);

      controller.stop();
      expect(controller.isAnimating, isFalse);
      addTearDown(controller.dispose);
    });

    test('stop on non-animating controller is a no-op', () {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 300),
      );
      expect(controller.isAnimating, isFalse);
      controller.stop(); // should not throw
      expect(controller.status, AnimationStatus.dismissed);
      addTearDown(controller.dispose);
    });

    test('canceled=true sets status based on direction', () {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 300),
      );
      controller.forward();
      controller.stop(canceled: true);
      // Forward animation canceled → dismissed
      expect(controller.status, AnimationStatus.dismissed);
      addTearDown(controller.dispose);
    });

    test('canceled=true on reverse sets completed', () {
      final controller = AnimationController(
        value: 1.0,
        duration: const Duration(milliseconds: 300),
      );
      controller.reverse();
      controller.stop(canceled: true);
      // Reverse animation canceled → completed
      expect(controller.status, AnimationStatus.completed);
      addTearDown(controller.dispose);
    });

    test('notifies status listeners on stop', () {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 300),
      );
      final statuses = <AnimationStatus>[];
      controller.addStatusListener(statuses.add);

      controller.forward();
      controller.stop();

      // Should have reported forward, then dismissed (or completed)
      expect(statuses, contains(AnimationStatus.forward));
      expect(statuses.length, greaterThanOrEqualTo(2));
      addTearDown(controller.dispose);
    });
  });

  group('AnimationController.reset', () {
    test('resets value to lowerBound', () {
      final controller = AnimationController(
        value: 0.7,
        duration: const Duration(milliseconds: 300),
      );
      controller.reset();
      expect(controller.value, 0.0);
      expect(controller.status, AnimationStatus.dismissed);
      addTearDown(controller.dispose);
    });

    test('reset with custom lowerBound', () {
      final controller = AnimationController(
        lowerBound: 5.0,
        upperBound: 10.0,
        value: 8.0,
        duration: const Duration(milliseconds: 300),
      );
      controller.reset();
      expect(controller.value, 5.0);
      addTearDown(controller.dispose);
    });

    test('reset notifies value listeners', () {
      final controller = AnimationController(
        value: 0.5,
        duration: const Duration(milliseconds: 300),
      );
      var notified = false;
      controller.addListener(() => notified = true);

      controller.reset();
      expect(notified, isTrue);
      addTearDown(controller.dispose);
    });

    test('reset notifies status listeners', () {
      final controller = AnimationController(
        value: 1.0,
        duration: const Duration(milliseconds: 300),
      );
      // First put into a non-dismissed state
      controller.forward();
      AnimationStatus? lastStatus;
      controller.addStatusListener((s) => lastStatus = s);

      controller.reset();
      expect(lastStatus, AnimationStatus.dismissed);
      addTearDown(controller.dispose);
    });

    test('reset stops repeating animation', () {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 300),
      );
      controller.repeat();
      controller.reset();
      expect(controller.isAnimating, isFalse);
      expect(controller.status, AnimationStatus.dismissed);
      addTearDown(controller.dispose);
    });
  });

  group('AnimationController.processTick — forward animation', () {
    test('progresses value toward upperBound', () {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 1000),
      );
      controller.forward();

      final start = DateTime(2024, 1, 1, 0, 0, 0, 0);
      // First tick sets startTime
      controller.processTick(start);

      // 500ms later — halfway through the animation
      final midTime = start.add(const Duration(milliseconds: 500));
      controller.processTick(midTime);

      expect(controller.value, closeTo(0.5, 0.05));
      expect(controller.isAnimating, isTrue);
      addTearDown(controller.dispose);
    });

    test('completes at the end of duration', () {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 1000),
      );
      controller.forward();

      final start = DateTime(2024, 1, 1, 0, 0, 0, 0);
      controller.processTick(start);

      final endTime = start.add(const Duration(milliseconds: 1000));
      final nextCmd = controller.processTick(endTime);

      expect(controller.value, 1.0);
      expect(controller.status, AnimationStatus.completed);
      expect(controller.isCompleted, isTrue);
      expect(nextCmd, isNull); // No more ticks needed
      addTearDown(controller.dispose);
    });

    test('returns Cmd for next tick while animating', () {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 1000),
      );
      controller.forward();

      final start = DateTime(2024, 1, 1, 0, 0, 0, 0);
      final nextCmd = controller.processTick(start);

      // Should return a Cmd to schedule the next tick
      expect(nextCmd, isA<Cmd>());
      addTearDown(controller.dispose);
    });

    test('returns null when animation completes', () {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 1000),
      );
      controller.forward();

      final start = DateTime(2024, 1, 1, 0, 0, 0, 0);
      controller.processTick(start);

      // Jump past the end
      final pastEnd = start.add(const Duration(milliseconds: 2000));
      final result = controller.processTick(pastEnd);

      expect(result, isNull);
      expect(controller.value, 1.0);
      expect(controller.isCompleted, isTrue);
      addTearDown(controller.dispose);
    });

    test('returns null when not animating', () {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 1000),
      );
      // Don't call forward — controller is dismissed
      final result = controller.processTick(DateTime.now());
      expect(result, isNull);
      addTearDown(controller.dispose);
    });

    test('notifies value listeners on each tick', () {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 1000),
      );
      var notifyCount = 0;
      controller.addListener(() => notifyCount++);
      controller.forward();

      final start = DateTime(2024, 1, 1, 0, 0, 0, 0);
      controller.processTick(start);
      expect(notifyCount, greaterThanOrEqualTo(1));

      final mid = start.add(const Duration(milliseconds: 500));
      controller.processTick(mid);
      expect(notifyCount, greaterThanOrEqualTo(2));
      addTearDown(controller.dispose);
    });

    test('notifies status listeners on completion', () {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 1000),
      );
      final statuses = <AnimationStatus>[];
      controller.addStatusListener(statuses.add);
      controller.forward();

      final start = DateTime(2024, 1, 1, 0, 0, 0, 0);
      controller.processTick(start);

      final end = start.add(const Duration(milliseconds: 1000));
      controller.processTick(end);

      expect(statuses, contains(AnimationStatus.forward));
      expect(statuses, contains(AnimationStatus.completed));
      addTearDown(controller.dispose);
    });

    test('incremental ticks produce monotonically increasing values', () {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 1000),
      );
      controller.forward();

      final start = DateTime(2024, 1, 1, 0, 0, 0, 0);
      controller.processTick(start);

      final values = <double>[controller.value];
      for (int i = 1; i <= 10; i++) {
        final time = start.add(Duration(milliseconds: i * 100));
        final cmd = controller.processTick(time);
        values.add(controller.value);
        if (cmd == null) break;
      }

      // Each value should be >= the previous one
      for (int i = 1; i < values.length; i++) {
        expect(
          values[i],
          greaterThanOrEqualTo(values[i - 1]),
          reason:
              'value[$i]=${values[i]} should be >= value[${i - 1}]=${values[i - 1]}',
        );
      }
      addTearDown(controller.dispose);
    });

    test('final value is exactly upperBound', () {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 1000),
      );
      controller.forward();

      final start = DateTime(2024, 1, 1, 0, 0, 0, 0);
      controller.processTick(start);

      final end = start.add(const Duration(milliseconds: 1000));
      controller.processTick(end);

      expect(controller.value, 1.0); // Exactly upperBound, not 0.999...
      addTearDown(controller.dispose);
    });
  });

  group('AnimationController.processTick — reverse animation', () {
    test('progresses value toward lowerBound', () {
      final controller = AnimationController(
        value: 1.0,
        duration: const Duration(milliseconds: 1000),
      );
      controller.reverse();

      final start = DateTime(2024, 1, 1, 0, 0, 0, 0);
      controller.processTick(start);

      final mid = start.add(const Duration(milliseconds: 500));
      controller.processTick(mid);

      expect(controller.value, closeTo(0.5, 0.05));
      expect(controller.status, AnimationStatus.reverse);
      addTearDown(controller.dispose);
    });

    test('completes at lowerBound', () {
      final controller = AnimationController(
        value: 1.0,
        duration: const Duration(milliseconds: 1000),
      );
      controller.reverse();

      final start = DateTime(2024, 1, 1, 0, 0, 0, 0);
      controller.processTick(start);

      final end = start.add(const Duration(milliseconds: 1000));
      controller.processTick(end);

      expect(controller.value, 0.0);
      expect(controller.status, AnimationStatus.dismissed);
      expect(controller.isDismissed, isTrue);
      addTearDown(controller.dispose);
    });

    test('uses reverseDuration when provided', () {
      final controller = AnimationController(
        value: 1.0,
        duration: const Duration(milliseconds: 1000),
        reverseDuration: const Duration(milliseconds: 500),
      );
      controller.reverse();

      final start = DateTime(2024, 1, 1, 0, 0, 0, 0);
      controller.processTick(start);

      // At 250ms into a 500ms reverse, should be about halfway
      final mid = start.add(const Duration(milliseconds: 250));
      controller.processTick(mid);

      expect(controller.value, closeTo(0.5, 0.05));

      // At 500ms, should be done
      final end = start.add(const Duration(milliseconds: 500));
      controller.processTick(end);

      expect(controller.value, 0.0);
      expect(controller.status, AnimationStatus.dismissed);
      addTearDown(controller.dispose);
    });

    test('incremental ticks produce monotonically decreasing values', () {
      final controller = AnimationController(
        value: 1.0,
        duration: const Duration(milliseconds: 1000),
      );
      controller.reverse();

      final start = DateTime(2024, 1, 1, 0, 0, 0, 0);
      controller.processTick(start);

      final values = <double>[controller.value];
      for (int i = 1; i <= 10; i++) {
        final time = start.add(Duration(milliseconds: i * 100));
        final cmd = controller.processTick(time);
        values.add(controller.value);
        if (cmd == null) break;
      }

      for (int i = 1; i < values.length; i++) {
        expect(
          values[i],
          lessThanOrEqualTo(values[i - 1]),
          reason:
              'value[$i]=${values[i]} should be <= value[${i - 1}]=${values[i - 1]}',
        );
      }
      addTearDown(controller.dispose);
    });
  });

  group('AnimationController.processTick — with curves', () {
    test('easeIn produces slow start', () {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 1000),
      );
      controller.forward(curve: Curves.easeIn);

      final start = DateTime(2024, 1, 1, 0, 0, 0, 0);
      controller.processTick(start);

      // At 25% through with easeIn, value should be < 0.25
      final quarter = start.add(const Duration(milliseconds: 250));
      controller.processTick(quarter);

      expect(controller.value, lessThan(0.25));
      addTearDown(controller.dispose);
    });

    test('easeOut produces fast start', () {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 1000),
      );
      controller.forward(curve: Curves.easeOut);

      final start = DateTime(2024, 1, 1, 0, 0, 0, 0);
      controller.processTick(start);

      // At 25% through with easeOut, value should be > 0.25
      final quarter = start.add(const Duration(milliseconds: 250));
      controller.processTick(quarter);

      expect(controller.value, greaterThan(0.25));
      addTearDown(controller.dispose);
    });

    test('linear curve produces proportional progress', () {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 1000),
      );
      controller.forward(curve: Curves.linear);

      final start = DateTime(2024, 1, 1, 0, 0, 0, 0);
      controller.processTick(start);

      for (var i = 1; i <= 10; i++) {
        final time = start.add(Duration(milliseconds: i * 100));
        controller.processTick(time);
        expect(
          controller.value,
          closeTo(i * 0.1, 0.01),
          reason: 'linear at ${i * 100}ms',
        );
      }
      addTearDown(controller.dispose);
    });

    test('completed value is exact regardless of curve', () {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 1000),
      );
      controller.forward(curve: Curves.easeInOutCubic);

      final start = DateTime(2024, 1, 1, 0, 0, 0, 0);
      controller.processTick(start);

      final end = start.add(const Duration(milliseconds: 1000));
      controller.processTick(end);

      expect(controller.value, 1.0);
      addTearDown(controller.dispose);
    });
  });

  group('AnimationController.processTick — repeat', () {
    test('repeating animation cycles back to start', () {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 1000),
      );
      controller.repeat();

      final start = DateTime(2024, 1, 1, 0, 0, 0, 0);
      controller.processTick(start);

      // At 500ms: halfway through first cycle
      final mid = start.add(const Duration(milliseconds: 500));
      controller.processTick(mid);
      expect(controller.value, closeTo(0.5, 0.05));

      // At 1000ms: end of first cycle, jumps back
      final end = start.add(const Duration(milliseconds: 1000));
      final nextCmd = controller.processTick(end);

      // Should still be animating (repeating)
      expect(nextCmd, isA<Cmd>());
      expect(controller.isAnimating, isTrue);
      addTearDown(controller.dispose);
    });

    test('repeat with reverse alternates direction', () {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 1000),
      );
      controller.repeat(reverse: true);

      final start = DateTime(2024, 1, 1, 0, 0, 0, 0);
      controller.processTick(start);

      // Complete first forward cycle
      final endFirst = start.add(const Duration(milliseconds: 1000));
      controller.processTick(endFirst);

      // After first cycle with reverse: should be going in reverse now
      expect(controller.status, AnimationStatus.reverse);
      expect(controller.isAnimating, isTrue);
      addTearDown(controller.dispose);
    });

    test('repeat without reverse jumps back to start value', () {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 1000),
      );
      controller.repeat(reverse: false);

      final start = DateTime(2024, 1, 1, 0, 0, 0, 0);
      controller.processTick(start);

      // Complete first cycle
      final endFirst = start.add(const Duration(milliseconds: 1000));
      controller.processTick(endFirst);

      // Value should jump back to start (lowerBound)
      expect(controller.value, 0.0);
      // Still forward status
      expect(controller.status, AnimationStatus.forward);
      addTearDown(controller.dispose);
    });

    test('repeat returns Cmd after each cycle', () {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 500),
      );
      controller.repeat();

      final start = DateTime(2024, 1, 1, 0, 0, 0, 0);
      Cmd? cmd = controller.processTick(start);
      expect(cmd, isNotNull);

      // Complete 3 cycles — each should return a Cmd
      for (var cycle = 1; cycle <= 3; cycle++) {
        final endOfCycle = start.add(Duration(milliseconds: 500 * cycle));
        cmd = controller.processTick(endOfCycle);
        expect(cmd, isA<Cmd>(), reason: 'Cmd expected after cycle $cycle');
      }
      addTearDown(controller.dispose);
    });

    test('stop ends repeating animation', () {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 1000),
      );
      controller.repeat();

      final start = DateTime(2024, 1, 1, 0, 0, 0, 0);
      controller.processTick(start);

      // Animate partway
      final mid = start.add(const Duration(milliseconds: 300));
      controller.processTick(mid);
      expect(controller.isAnimating, isTrue);

      controller.stop();
      expect(controller.isAnimating, isFalse);

      // Next tick should be a no-op
      final next = mid.add(const Duration(milliseconds: 100));
      final cmd = controller.processTick(next);
      expect(cmd, isNull);
      addTearDown(controller.dispose);
    });

    test('repeat with custom min/max range', () {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 1000),
      );
      controller.repeat(min: 0.2, max: 0.8);

      final start = DateTime(2024, 1, 1, 0, 0, 0, 0);
      controller.processTick(start);
      expect(controller.value, closeTo(0.2, 0.01));

      // Halfway
      final mid = start.add(const Duration(milliseconds: 500));
      controller.processTick(mid);
      expect(controller.value, closeTo(0.5, 0.05));

      // Complete cycle
      final end = start.add(const Duration(milliseconds: 1000));
      controller.processTick(end);
      // Should have reached 0.8 and then cycled
      expect(controller.isAnimating, isTrue);
      addTearDown(controller.dispose);
    });
  });

  group('AnimationController.processTick — zero/null duration', () {
    test('null duration jumps to target immediately', () {
      final controller = AnimationController();
      controller.forward();

      final result = controller.processTick(DateTime.now());

      expect(controller.value, 1.0);
      expect(controller.isCompleted, isTrue);
      expect(result, isNull);
      addTearDown(controller.dispose);
    });

    test('zero duration jumps to target immediately', () {
      final controller = AnimationController(duration: Duration.zero);
      controller.forward();

      final result = controller.processTick(DateTime.now());

      expect(controller.value, 1.0);
      expect(controller.isCompleted, isTrue);
      expect(result, isNull);
      addTearDown(controller.dispose);
    });
  });

  group('AnimationController.processTick — custom bounds', () {
    test('forward animates from lowerBound to upperBound', () {
      final controller = AnimationController(
        lowerBound: 10.0,
        upperBound: 20.0,
        duration: const Duration(milliseconds: 1000),
      );
      controller.forward();

      final start = DateTime(2024, 1, 1, 0, 0, 0, 0);
      controller.processTick(start);

      final mid = start.add(const Duration(milliseconds: 500));
      controller.processTick(mid);
      expect(controller.value, closeTo(15.0, 0.5));

      final end = start.add(const Duration(milliseconds: 1000));
      controller.processTick(end);
      expect(controller.value, 20.0);
      expect(controller.isCompleted, isTrue);
      addTearDown(controller.dispose);
    });

    test('reverse animates from upperBound to lowerBound', () {
      final controller = AnimationController(
        lowerBound: 10.0,
        upperBound: 20.0,
        value: 20.0,
        duration: const Duration(milliseconds: 1000),
      );
      controller.reverse();

      final start = DateTime(2024, 1, 1, 0, 0, 0, 0);
      controller.processTick(start);

      final end = start.add(const Duration(milliseconds: 1000));
      controller.processTick(end);
      expect(controller.value, 10.0);
      expect(controller.isDismissed, isTrue);
      addTearDown(controller.dispose);
    });
  });

  group('AnimationController status listeners', () {
    test('addStatusListener and removeStatusListener', () {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 300),
      );
      var callCount = 0;
      void listener(AnimationStatus s) => callCount++;

      controller.addStatusListener(listener);
      controller.forward();
      expect(callCount, 1);

      controller.removeStatusListener(listener);
      controller.stop();
      // Stop would normally notify, but listener was removed
      // (status changed from forward to dismissed, so _notifyStatusListeners
      // would fire, but we removed the listener)
      expect(callCount, 1);
      addTearDown(controller.dispose);
    });

    test('does not fire if status has not changed', () {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 300),
      );
      var callCount = 0;
      controller.addStatusListener((_) => callCount++);

      // Calling forward twice — status is already forward
      controller.forward();
      expect(callCount, 1);

      // forward again while already forward — status didn't change
      controller.forward();
      expect(callCount, 1);
      addTearDown(controller.dispose);
    });

    test('fires on each distinct status change', () {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 1000),
      );
      final statuses = <AnimationStatus>[];
      controller.addStatusListener(statuses.add);

      // dismissed → forward
      controller.forward();
      expect(statuses, [AnimationStatus.forward]);

      // forward → (stop) → dismissed
      controller.stop();
      expect(statuses.last, AnimationStatus.dismissed);

      // dismissed → forward
      controller.forward();
      expect(statuses.last, AnimationStatus.forward);

      // forward → completed (via processTick)
      final start = DateTime(2024, 1, 1, 0, 0, 0, 0);
      controller.processTick(start);
      controller.processTick(start.add(const Duration(milliseconds: 1000)));
      expect(statuses.last, AnimationStatus.completed);

      addTearDown(controller.dispose);
    });

    test('multiple status listeners all get called', () {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 300),
      );
      var count1 = 0;
      var count2 = 0;
      controller.addStatusListener((_) => count1++);
      controller.addStatusListener((_) => count2++);

      controller.forward();
      expect(count1, 1);
      expect(count2, 1);
      addTearDown(controller.dispose);
    });
  });

  group('AnimationController value listeners', () {
    test('notifies on tick', () {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 1000),
      );
      final values = <double>[];
      controller.addListener(() => values.add(controller.value));

      controller.forward();

      final start = DateTime(2024, 1, 1, 0, 0, 0, 0);
      controller.processTick(start);
      controller.processTick(start.add(const Duration(milliseconds: 500)));
      controller.processTick(start.add(const Duration(milliseconds: 1000)));

      expect(values.length, greaterThanOrEqualTo(2));
      // Last value should be 1.0
      expect(values.last, 1.0);
      addTearDown(controller.dispose);
    });

    test('removeListener stops notifications', () {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 1000),
      );
      var callCount = 0;
      void listener() => callCount++;

      controller.addListener(listener);
      controller.forward();

      final start = DateTime(2024, 1, 1, 0, 0, 0, 0);
      controller.processTick(start);
      final countAfterFirst = callCount;

      controller.removeListener(listener);
      controller.processTick(start.add(const Duration(milliseconds: 500)));

      // Should not have been called again
      expect(callCount, countAfterFirst);
      addTearDown(controller.dispose);
    });
  });

  group('AnimationController.dispose', () {
    test('clears all listeners', () {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 300),
      );
      controller.addListener(() {});
      controller.addStatusListener((_) {});

      expect(controller.hasListeners, isTrue);

      controller.dispose();

      // After dispose, listeners should have been cleared
      expect(controller.hasListeners, isFalse);
    });
  });

  group('AnimationController.drive', () {
    test('creates derived animation with tween', () {
      final controller = AnimationController(
        value: 0.5,
        duration: const Duration(milliseconds: 300),
      );
      final derived = controller.drive(Tween<double>(begin: 0.0, end: 100.0));

      expect(derived.value, 50.0);
      addTearDown(controller.dispose);
    });

    test('creates derived animation with CurveTween', () {
      final controller = AnimationController(
        value: 0.0,
        duration: const Duration(milliseconds: 300),
      );
      final curved = controller.drive(CurveTween(curve: Curves.easeIn));

      // At value 0.0, curved should also be 0.0
      expect(curved.value, 0.0);
      addTearDown(controller.dispose);
    });

    test('derived animation updates when controller ticks', () {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 1000),
      );
      final scaled = controller.drive(Tween<double>(begin: 0.0, end: 200.0));
      controller.forward();

      final start = DateTime(2024, 1, 1, 0, 0, 0, 0);
      controller.processTick(start);

      final mid = start.add(const Duration(milliseconds: 500));
      controller.processTick(mid);

      expect(scaled.value, closeTo(100.0, 10.0));
      addTearDown(controller.dispose);
    });

    test('derived animation delegates status', () {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 300),
      );
      final derived = controller.drive(Tween<double>(begin: 0.0, end: 1.0));

      expect(derived.status, AnimationStatus.dismissed);

      controller.forward();
      expect(derived.status, AnimationStatus.forward);
      addTearDown(controller.dispose);
    });

    test('derived animation inherits listener registration', () {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 1000),
      );
      final derived = controller.drive(Tween<double>(begin: 0.0, end: 100.0));

      var notified = false;
      derived.addListener(() => notified = true);

      controller.forward();
      final start = DateTime(2024, 1, 1, 0, 0, 0, 0);
      controller.processTick(start);

      final mid = start.add(const Duration(milliseconds: 500));
      controller.processTick(mid);

      expect(notified, isTrue);
      addTearDown(controller.dispose);
    });
  });

  group('AnimationController interaction patterns', () {
    test('forward then reverse', () {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 500),
      );

      // Forward
      controller.forward();
      final start = DateTime(2024, 1, 1, 0, 0, 0, 0);
      controller.processTick(start);
      controller.processTick(start.add(const Duration(milliseconds: 500)));
      expect(controller.value, 1.0);
      expect(controller.isCompleted, isTrue);

      // Now reverse
      controller.reverse();
      expect(controller.status, AnimationStatus.reverse);

      final reverseStart = DateTime(2024, 1, 1, 0, 0, 1, 0);
      controller.processTick(reverseStart);
      controller.processTick(
        reverseStart.add(const Duration(milliseconds: 500)),
      );
      expect(controller.value, 0.0);
      expect(controller.isDismissed, isTrue);
      addTearDown(controller.dispose);
    });

    test('restart animation mid-flight', () {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 1000),
      );
      controller.forward();

      final start = DateTime(2024, 1, 1, 0, 0, 0, 0);
      controller.processTick(start);

      // Animate to 30%
      controller.processTick(start.add(const Duration(milliseconds: 300)));
      expect(controller.value, closeTo(0.3, 0.05));

      // Restart from the beginning
      controller.forward(from: 0.0);
      expect(controller.value, 0.0);
      expect(controller.status, AnimationStatus.forward);
      addTearDown(controller.dispose);
    });

    test('switch direction mid-flight', () {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 1000),
      );
      controller.forward();

      final start = DateTime(2024, 1, 1, 0, 0, 0, 0);
      controller.processTick(start);

      // Animate to ~50%
      controller.processTick(start.add(const Duration(milliseconds: 500)));
      final midValue = controller.value;
      expect(midValue, closeTo(0.5, 0.05));

      // Now reverse from current position
      controller.reverse();
      expect(controller.status, AnimationStatus.reverse);
      expect(controller.value, midValue); // hasn't changed yet
      addTearDown(controller.dispose);
    });

    test('animateTo specific value', () {
      final controller = AnimationController(
        value: 0.0,
        duration: const Duration(milliseconds: 500),
      );
      controller.animateTo(0.5);

      final start = DateTime(2024, 1, 1, 0, 0, 0, 0);
      controller.processTick(start);

      final end = start.add(const Duration(milliseconds: 500));
      controller.processTick(end);

      expect(controller.value, 0.5);
      // Since 0.5 is not upperBound, status should be dismissed
      expect(controller.status, AnimationStatus.dismissed);
      addTearDown(controller.dispose);
    });
  });

  group('AnimationController.toString', () {
    test('includes value and status', () {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 300),
      );
      final str = controller.toString();
      expect(str, contains('AnimationController'));
      expect(str, contains('0.000'));
      expect(str, contains('dismissed'));
      addTearDown(controller.dispose);
    });

    test('updates after forward', () {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 300),
      );
      controller.forward();
      final str = controller.toString();
      expect(str, contains('forward'));
      addTearDown(controller.dispose);
    });
  });

  group('AnimationController isAnimating / isCompleted / isDismissed', () {
    test('initial state', () {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 300),
      );
      expect(controller.isDismissed, isTrue);
      expect(controller.isCompleted, isFalse);
      expect(controller.isAnimating, isFalse);
      addTearDown(controller.dispose);
    });

    test('while animating forward', () {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 300),
      );
      controller.forward();
      expect(controller.isDismissed, isFalse);
      expect(controller.isCompleted, isFalse);
      expect(controller.isAnimating, isTrue);
      addTearDown(controller.dispose);
    });

    test('after completion', () {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 300),
      );
      controller.forward();

      final start = DateTime(2024, 1, 1, 0, 0, 0, 0);
      controller.processTick(start);
      controller.processTick(start.add(const Duration(milliseconds: 300)));

      expect(controller.isDismissed, isFalse);
      expect(controller.isCompleted, isTrue);
      expect(controller.isAnimating, isFalse);
      addTearDown(controller.dispose);
    });

    test('after reverse completion', () {
      final controller = AnimationController(
        value: 1.0,
        duration: const Duration(milliseconds: 300),
      );
      controller.reverse();

      final start = DateTime(2024, 1, 1, 0, 0, 0, 0);
      controller.processTick(start);
      controller.processTick(start.add(const Duration(milliseconds: 300)));

      expect(controller.isDismissed, isTrue);
      expect(controller.isCompleted, isFalse);
      expect(controller.isAnimating, isFalse);
      addTearDown(controller.dispose);
    });
  });

  group('AnimationController Animation interface', () {
    test('implements Animation<double>', () {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 300),
      );
      expect(controller, isA<Animation<double>>());
      addTearDown(controller.dispose);
    });

    test('implements Listenable', () {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 300),
      );
      expect(controller, isA<Listenable>());
      addTearDown(controller.dispose);
    });

    test('implements ValueListenable<double>', () {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 300),
      );
      expect(controller, isA<ValueListenable<double>>());
      addTearDown(controller.dispose);
    });
  });

  group('AnimationController edge cases', () {
    test('processTick with time exactly at start', () {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 1000),
      );
      controller.forward();

      final start = DateTime(2024, 1, 1, 0, 0, 0, 0);
      // First tick establishes start time
      final cmd = controller.processTick(start);
      expect(cmd, isA<Cmd>());
      // Value at t=0 should still be near 0
      expect(controller.value, closeTo(0.0, 0.01));
      addTearDown(controller.dispose);
    });

    test('processTick with very small elapsed', () {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 1000),
      );
      controller.forward();

      final start = DateTime(2024, 1, 1, 0, 0, 0, 0);
      controller.processTick(start);

      // 1 microsecond later
      final next = start.add(const Duration(microseconds: 1));
      controller.processTick(next);

      expect(controller.value, closeTo(0.0, 0.001));
      expect(controller.isAnimating, isTrue);
      addTearDown(controller.dispose);
    });

    test('processTick well past the end clamps to target', () {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 1000),
      );
      controller.forward();

      final start = DateTime(2024, 1, 1, 0, 0, 0, 0);
      controller.processTick(start);

      // 10 seconds later — well past the end
      final way_past = start.add(const Duration(seconds: 10));
      controller.processTick(way_past);

      expect(controller.value, 1.0);
      expect(controller.isCompleted, isTrue);
      addTearDown(controller.dispose);
    });

    test('calling forward while already forward resets startTime', () {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 1000),
      );
      controller.forward();

      final start = DateTime(2024, 1, 1, 0, 0, 0, 0);
      controller.processTick(start);
      controller.processTick(start.add(const Duration(milliseconds: 500)));

      final midValue = controller.value;
      expect(midValue, closeTo(0.5, 0.05));

      // Call forward again — this resets the animation
      controller.forward();
      expect(controller.value, midValue); // value preserved as start value

      // New tick from a fresh start
      final newStart = DateTime(2024, 1, 1, 0, 0, 1, 0);
      controller.processTick(newStart);

      // Value should start from midValue, heading toward 1.0
      expect(controller.isAnimating, isTrue);
      addTearDown(controller.dispose);
    });

    test('multiple repeat cycles produce consistent values', () {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 100),
      );
      controller.repeat(reverse: true);

      final start = DateTime(2024, 1, 1, 0, 0, 0, 0);
      var lastCmd = controller.processTick(start);

      // Run through several cycles
      for (var ms = 10; ms <= 500; ms += 10) {
        final time = start.add(Duration(milliseconds: ms));
        lastCmd = controller.processTick(time);

        // Value should always be in bounds
        expect(controller.value, greaterThanOrEqualTo(0.0));
        expect(controller.value, lessThanOrEqualTo(1.0));

        if (lastCmd == null) {
          // If null, something stopped it — shouldn't happen during repeat
          fail('repeat should never return null');
        }
      }
      addTearDown(controller.dispose);
    });
  });
}
