import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:test/test.dart';

void main() {
  group('Tween<double>', () {
    test('interpolates between begin and end', () {
      final tween = Tween<double>(begin: 0.0, end: 100.0);
      expect(tween.transform(0.0), 0.0);
      expect(tween.transform(0.5), 50.0);
      expect(tween.transform(1.0), 100.0);
    });

    test('interpolates negative ranges', () {
      final tween = Tween<double>(begin: -50.0, end: 50.0);
      expect(tween.transform(0.0), -50.0);
      expect(tween.transform(0.5), 0.0);
      expect(tween.transform(1.0), 50.0);
    });

    test('interpolates reversed range (begin > end)', () {
      final tween = Tween<double>(begin: 100.0, end: 0.0);
      expect(tween.transform(0.0), 100.0);
      expect(tween.transform(0.5), 50.0);
      expect(tween.transform(1.0), 0.0);
    });

    test('transform at boundaries returns exact begin/end', () {
      final tween = Tween<double>(begin: 3.14, end: 2.72);
      expect(tween.transform(0.0), 3.14);
      expect(tween.transform(1.0), 2.72);
    });

    test('lerp at various points', () {
      final tween = Tween<double>(begin: 10.0, end: 20.0);
      expect(tween.lerp(0.0), 10.0);
      expect(tween.lerp(0.25), 12.5);
      expect(tween.lerp(0.75), 17.5);
      expect(tween.lerp(1.0), 20.0);
    });

    test('same begin and end returns constant', () {
      final tween = Tween<double>(begin: 42.0, end: 42.0);
      expect(tween.transform(0.0), 42.0);
      expect(tween.transform(0.5), 42.0);
      expect(tween.transform(1.0), 42.0);
    });

    test('toString shows begin and end', () {
      final tween = Tween<double>(begin: 0.0, end: 1.0);
      final str = tween.toString();
      expect(str, contains('0.0'));
      expect(str, contains('1.0'));
    });

    test('evaluate reads from animation value', () {
      final tween = Tween<double>(begin: 0.0, end: 200.0);
      const anim = AlwaysStoppedAnimation<double>(0.5);
      expect(tween.evaluate(anim), 100.0);
    });
  });

  group('IntTween', () {
    test('rounds to nearest integer', () {
      final tween = IntTween(begin: 0, end: 10);
      expect(tween.transform(0.0), 0);
      expect(tween.transform(0.5), 5);
      expect(tween.transform(1.0), 10);
    });

    test('rounds correctly at fractional positions', () {
      final tween = IntTween(begin: 0, end: 3);
      // t=0.0 → 0, t=0.33 → 1 (0.99 rounds to 1), t=0.5 → 2 (1.5 rounds to 2)
      expect(tween.lerp(0.0), 0);
      expect(tween.lerp(1.0), 3);
      // 3 * 0.34 = 1.02 → rounds to 1
      expect(tween.lerp(0.34), 1);
      // 3 * 0.5 = 1.5 → rounds to 2
      expect(tween.lerp(0.5), 2);
    });

    test('negative range', () {
      final tween = IntTween(begin: -10, end: 10);
      expect(tween.transform(0.0), -10);
      expect(tween.transform(0.5), 0);
      expect(tween.transform(1.0), 10);
    });

    test('reversed range', () {
      final tween = IntTween(begin: 100, end: 0);
      expect(tween.transform(0.0), 100);
      expect(tween.transform(0.5), 50);
      expect(tween.transform(1.0), 0);
    });

    test('single value', () {
      final tween = IntTween(begin: 7, end: 7);
      expect(tween.transform(0.5), 7);
    });
  });

  group('DoubleTween', () {
    test('interpolates between begin and end', () {
      final tween = DoubleTween(begin: 0.0, end: 1.0);
      expect(tween.transform(0.0), 0.0);
      expect(tween.transform(0.5), 0.5);
      expect(tween.transform(1.0), 1.0);
    });

    test('precision for large ranges', () {
      final tween = DoubleTween(begin: 0.0, end: 1000000.0);
      expect(tween.lerp(0.5), closeTo(500000.0, 0.001));
    });

    test('negative range', () {
      final tween = DoubleTween(begin: -100.0, end: -200.0);
      expect(tween.lerp(0.5), closeTo(-150.0, 1e-10));
    });
  });

  group('StepTween', () {
    test('floors to integer', () {
      final tween = StepTween(begin: 0, end: 10);
      expect(tween.transform(0.0), 0);
      expect(tween.transform(1.0), 10);
    });

    test('floors rather than rounds', () {
      final tween = StepTween(begin: 0, end: 3);
      // 3 * 0.5 = 1.5 → floor to 1 (not 2 like IntTween would round)
      expect(tween.lerp(0.5), 1);
      // 3 * 0.99 = 2.97 → floor to 2
      expect(tween.lerp(0.99), 2);
      // 3 * 1.0 = 3.0 → floor to 3
      expect(tween.lerp(1.0), 3);
    });

    test('discrete steps for progress indication', () {
      final tween = StepTween(begin: 0, end: 5);
      // At various points, we should see discrete steps
      final values = <int>[];
      for (var t = 0.0; t <= 1.0; t += 0.1) {
        values.add(tween.lerp(t));
      }
      // All values should be integers in [0, 5]
      for (final v in values) {
        expect(v, greaterThanOrEqualTo(0));
        expect(v, lessThanOrEqualTo(5));
      }
    });

    test('reversed range floors correctly', () {
      final tween = StepTween(begin: 10, end: 0);
      // 10 + (0 - 10) * 0.5 = 10 - 5 = 5.0 → floor = 5
      expect(tween.lerp(0.5), 5);
      // 10 + (0 - 10) * 0.33 = 10 - 3.3 = 6.7 → floor = 6
      expect(tween.lerp(0.33), 6);
    });
  });

  group('ConstantTween', () {
    test('always returns the same value', () {
      final tween = ConstantTween<double>(42.0);
      expect(tween.transform(0.0), 42.0);
      expect(tween.transform(0.5), 42.0);
      expect(tween.transform(1.0), 42.0);
    });

    test('lerp ignores t', () {
      final tween = ConstantTween<String>('hello');
      expect(tween.lerp(0.0), 'hello');
      expect(tween.lerp(0.5), 'hello');
      expect(tween.lerp(1.0), 'hello');
    });

    test('begin and end are both the constant value', () {
      final tween = ConstantTween<int>(7);
      expect(tween.begin, 7);
      expect(tween.end, 7);
    });

    test('works with nullable type', () {
      final tween = ConstantTween<String?>(null);
      expect(tween.transform(0.0), isNull);
      expect(tween.transform(0.5), isNull);
      expect(tween.transform(1.0), isNull);
    });
  });

  group('ReverseTween', () {
    test('reverses a double tween', () {
      final original = Tween<double>(begin: 0.0, end: 100.0);
      final reversed = ReverseTween<double>(original);

      // ReverseTween: begin=parent.end, end=parent.begin
      expect(reversed.begin, 100.0);
      expect(reversed.end, 0.0);
    });

    test('lerp evaluates parent in reverse', () {
      final original = Tween<double>(begin: 0.0, end: 100.0);
      final reversed = ReverseTween<double>(original);

      // lerp(t) = parent.lerp(1.0 - t)
      expect(reversed.lerp(0.0), 100.0); // parent.lerp(1.0)
      expect(reversed.lerp(0.5), 50.0); // parent.lerp(0.5)
      expect(reversed.lerp(1.0), 0.0); // parent.lerp(0.0)
    });

    test('transform at boundaries returns reversed values', () {
      final original = Tween<double>(begin: 10.0, end: 20.0);
      final reversed = ReverseTween<double>(original);

      expect(reversed.transform(0.0), 20.0);
      expect(reversed.transform(1.0), 10.0);
    });

    test('parent reference is stored', () {
      final original = Tween<double>(begin: 0.0, end: 1.0);
      final reversed = ReverseTween<double>(original);
      expect(reversed.parent, same(original));
    });

    test('double reverse returns approximately original values', () {
      final original = Tween<double>(begin: 0.0, end: 100.0);
      final reversed = ReverseTween<double>(original);
      final doubleReversed = ReverseTween<double>(reversed);

      for (var t = 0.0; t <= 1.0; t += 0.1) {
        expect(
          doubleReversed.lerp(t),
          closeTo(original.lerp(t), 1e-10),
          reason: 'double reverse at t=$t',
        );
      }
    });
  });

  group('CurveTween', () {
    test('applies linear curve (identity)', () {
      final curveTween = CurveTween(curve: Curves.linear);
      expect(curveTween.transform(0.0), 0.0);
      expect(curveTween.transform(0.5), closeTo(0.5, 1e-10));
      expect(curveTween.transform(1.0), 1.0);
    });

    test('applies easeIn curve', () {
      final curveTween = CurveTween(curve: Curves.easeIn);
      expect(curveTween.transform(0.0), 0.0);
      expect(curveTween.transform(1.0), 1.0);
      // easeIn: slow start means value at t=0.5 should be < 0.5
      final mid = curveTween.transform(0.5);
      expect(mid, lessThan(0.5));
    });

    test('applies easeOut curve', () {
      final curveTween = CurveTween(curve: Curves.easeOut);
      // easeOut: fast start means value at t=0.5 should be > 0.5
      final mid = curveTween.transform(0.5);
      expect(mid, greaterThan(0.5));
    });

    test('applies decelerate curve', () {
      final curveTween = CurveTween(curve: Curves.decelerate);
      final quarter = curveTween.transform(0.25);
      // decelerate: 1 - (1-0.25)^2 = 1 - 0.5625 = 0.4375
      expect(quarter, closeTo(0.4375, 1e-6));
    });

    test('boundary values are preserved exactly', () {
      // Even for complex curves, t=0 → 0 and t=1 → 1
      final curveTween = CurveTween(curve: Curves.easeInOutCubic);
      expect(curveTween.transform(0.0), 0.0);
      expect(curveTween.transform(1.0), 1.0);
    });

    test('toString includes curve', () {
      final curveTween = CurveTween(curve: Curves.ease);
      expect(curveTween.toString(), contains('CurveTween'));
    });
  });

  group('TweenSequence', () {
    test('single item spans full range', () {
      final sequence = TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 0.0, end: 100.0), weight: 1),
      ]);
      expect(sequence.transform(0.0), 0.0);
      expect(sequence.transform(0.5), closeTo(50.0, 1e-10));
      expect(sequence.transform(1.0), 100.0);
    });

    test('two equal-weight items split the range', () {
      final sequence = TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 0.0, end: 100.0), weight: 1),
        TweenSequenceItem(tween: Tween(begin: 100.0, end: 200.0), weight: 1),
      ]);

      expect(sequence.transform(0.0), 0.0);
      expect(sequence.transform(0.25), closeTo(50.0, 1e-10));
      expect(sequence.transform(0.5), closeTo(100.0, 1e-6));
      expect(sequence.transform(0.75), closeTo(150.0, 1e-6));
      expect(sequence.transform(1.0), 200.0);
    });

    test('unequal weights allocate proportional time', () {
      final sequence = TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 0.0, end: 100.0), weight: 3),
        TweenSequenceItem(tween: Tween(begin: 100.0, end: 200.0), weight: 1),
      ]);

      // First segment: [0, 0.75), second segment: [0.75, 1.0]
      // At t=0.375 (midpoint of first segment): 50.0
      expect(sequence.transform(0.375), closeTo(50.0, 1e-6));
      // At t=0.75: start of second segment → 100.0
      expect(sequence.transform(0.75), closeTo(100.0, 1e-6));
      // At t=0.875 (midpoint of second segment): 150.0
      expect(sequence.transform(0.875), closeTo(150.0, 1e-6));
      expect(sequence.transform(1.0), 200.0);
    });

    test('three segments with equal weights', () {
      final sequence = TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 0.0, end: 10.0), weight: 1),
        TweenSequenceItem(tween: ConstantTween(10.0), weight: 1),
        TweenSequenceItem(tween: Tween(begin: 10.0, end: 0.0), weight: 1),
      ]);

      // First third: 0→10
      expect(sequence.transform(0.0), 0.0);
      // Midpoint of first third: ~5
      expect(sequence.transform(1.0 / 6.0), closeTo(5.0, 1e-6));

      // Second third: constant 10
      expect(sequence.transform(0.5), closeTo(10.0, 1e-6));

      // Third third: 10→0
      expect(sequence.transform(1.0), 0.0);
    });

    test('constant segment in the middle', () {
      final sequence = TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 0.0, end: 100.0), weight: 1),
        TweenSequenceItem(tween: ConstantTween(100.0), weight: 0.5),
        TweenSequenceItem(tween: Tween(begin: 100.0, end: 0.0), weight: 1),
      ]);

      // Total weight: 2.5
      // Segment 1: [0, 0.4) → 0 to 100
      // Segment 2: [0.4, 0.6) → constant 100
      // Segment 3: [0.6, 1.0] → 100 to 0

      expect(sequence.transform(0.0), 0.0);
      expect(sequence.transform(0.2), closeTo(50.0, 1e-6));
      expect(sequence.transform(0.5), closeTo(100.0, 1e-6));
      expect(sequence.transform(0.8), closeTo(50.0, 1e-6));
      expect(sequence.transform(1.0), 0.0);
    });

    test('handles t=1.0 correctly (last item)', () {
      final sequence = TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 0.0, end: 50.0), weight: 1),
        TweenSequenceItem(tween: Tween(begin: 50.0, end: 100.0), weight: 1),
      ]);
      expect(sequence.transform(1.0), 100.0);
    });

    test('clamps t to [0, 1]', () {
      final sequence = TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 0.0, end: 100.0), weight: 1),
      ]);
      // Should not throw — clamps internally
      expect(sequence.transform(0.0), 0.0);
      expect(sequence.transform(1.0), 100.0);
    });

    test('toString', () {
      final sequence = TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 1),
        TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 1),
      ]);
      expect(sequence.toString(), contains('2 items'));
    });

    test('with integer tweens', () {
      final sequence = TweenSequence<int>([
        TweenSequenceItem(tween: IntTween(begin: 0, end: 10), weight: 1),
        TweenSequenceItem(tween: IntTween(begin: 10, end: 20), weight: 1),
      ]);

      expect(sequence.transform(0.0), 0);
      expect(sequence.transform(0.25), 5);
      expect(sequence.transform(1.0), 20);
    });
  });

  group('TweenSequenceItem', () {
    test('stores tween and weight', () {
      final tween = Tween<double>(begin: 0.0, end: 1.0);
      final item = TweenSequenceItem(tween: tween, weight: 2.0);
      expect(item.tween, same(tween));
      expect(item.weight, 2.0);
    });
  });

  group('Animatable.chain', () {
    test('chains CurveTween with Tween', () {
      final curveTween = CurveTween(curve: Curves.linear);
      final valueTween = Tween<double>(begin: 0.0, end: 100.0);
      final chained = valueTween.chain(curveTween);

      expect(chained.transform(0.0), 0.0);
      expect(chained.transform(0.5), closeTo(50.0, 1e-10));
      expect(chained.transform(1.0), 100.0);
    });

    test('chain with easeIn produces curved output', () {
      final curveTween = CurveTween(curve: Curves.easeIn);
      final valueTween = Tween<double>(begin: 0.0, end: 100.0);
      final chained = valueTween.chain(curveTween);

      // easeIn makes early values small
      final earlyValue = chained.transform(0.25);
      expect(earlyValue, lessThan(25.0));
    });

    test('double chain', () {
      final curve1 = CurveTween(curve: Curves.linear);
      final curve2 = CurveTween(curve: Curves.linear);
      final valueTween = Tween<double>(begin: 0.0, end: 100.0);

      final chained = valueTween.chain(curve1).chain(curve2);

      // Linear chained with linear is still linear
      expect(chained.transform(0.0), 0.0);
      expect(chained.transform(0.5), closeTo(50.0, 1e-10));
      expect(chained.transform(1.0), 100.0);
    });
  });

  group('Animatable.animate', () {
    test('creates derived animation from AlwaysStoppedAnimation', () {
      final tween = Tween<double>(begin: 0.0, end: 200.0);
      const parent = AlwaysStoppedAnimation<double>(0.75);
      final derived = tween.animate(parent);

      expect(derived.value, 150.0);
      expect(derived.status, AnimationStatus.dismissed);
    });

    test('evaluate reads current animation value', () {
      final tween = Tween<double>(begin: 10.0, end: 20.0);
      const anim = AlwaysStoppedAnimation<double>(0.0);
      expect(tween.evaluate(anim), 10.0);

      const anim2 = AlwaysStoppedAnimation<double>(1.0);
      expect(tween.evaluate(anim2), 20.0);
    });
  });

  group('Tween with various types', () {
    test('works with num type', () {
      final tween = Tween<num>(begin: 0, end: 100);
      expect(tween.transform(0.5), closeTo(50, 1e-10));
    });

    test('begin/end can be updated', () {
      final tween = Tween<double>(begin: 0.0, end: 100.0);
      expect(tween.transform(0.5), 50.0);

      tween.begin = 50.0;
      tween.end = 150.0;
      expect(tween.transform(0.0), 50.0);
      expect(tween.transform(0.5), 100.0);
      expect(tween.transform(1.0), 150.0);
    });
  });

  group('Tween edge cases', () {
    test('very small range', () {
      final tween = Tween<double>(begin: 0.0, end: 1e-10);
      expect(tween.transform(0.5), closeTo(5e-11, 1e-20));
    });

    test('very large range', () {
      final tween = Tween<double>(begin: -1e15, end: 1e15);
      expect(tween.transform(0.5), closeTo(0.0, 1.0));
    });

    test('IntTween with begin == end', () {
      final tween = IntTween(begin: 5, end: 5);
      expect(tween.transform(0.0), 5);
      expect(tween.transform(0.5), 5);
      expect(tween.transform(1.0), 5);
    });

    test('StepTween with begin == end', () {
      final tween = StepTween(begin: 3, end: 3);
      expect(tween.transform(0.5), 3);
    });
  });

  group('CurveTween chained with value Tween', () {
    test('produces eased interpolation', () {
      final curved = CurveTween(curve: Curves.easeInOut);
      final value = Tween<double>(begin: 0.0, end: 300.0);
      final chained = value.chain(curved);

      expect(chained.transform(0.0), 0.0);
      expect(chained.transform(1.0), 300.0);

      // Midpoint of easeInOut should be close to 0.5
      final midCurved = curved.transform(0.5);
      expect(chained.transform(0.5), closeTo(300.0 * midCurved, 1e-6));
    });

    test('Interval + Tween for staggered animation', () {
      final interval = CurveTween(curve: const Interval(0.0, 0.5));
      final value = Tween<double>(begin: 0.0, end: 100.0);
      final chained = value.chain(interval);

      // Before halfway: interpolating
      expect(chained.transform(0.0), 0.0);
      expect(chained.transform(0.25), closeTo(50.0, 1e-6));
      // After halfway: already at end
      expect(chained.transform(0.5), closeTo(100.0, 1e-6));
      expect(chained.transform(0.75), closeTo(100.0, 1e-6));
      expect(chained.transform(1.0), 100.0);
    });
  });
}
