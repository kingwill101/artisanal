import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart';

void main() {
  group('Tween<double>', () {
    test('lerps between begin and end', () {
      final tween = Tween<double>(begin: 0.0, end: 100.0);
      expect(tween.transform(0.0), 0.0);
      expect(tween.transform(0.5), 50.0);
      expect(tween.transform(1.0), 100.0);
    });

    test('lerps negative values', () {
      final tween = Tween<double>(begin: -100.0, end: 100.0);
      expect(tween.transform(0.0), -100.0);
      expect(tween.transform(0.5), 0.0);
      expect(tween.transform(1.0), 100.0);
    });

    test('lerps reversed range', () {
      final tween = Tween<double>(begin: 100.0, end: 0.0);
      expect(tween.transform(0.0), 100.0);
      expect(tween.transform(0.5), 50.0);
      expect(tween.transform(1.0), 0.0);
    });

    test('handles small fractional values', () {
      final tween = Tween<double>(begin: 0.0, end: 1.0);
      expect(tween.transform(0.1), closeTo(0.1, 0.0001));
      expect(tween.transform(0.25), closeTo(0.25, 0.0001));
      expect(tween.transform(0.75), closeTo(0.75, 0.0001));
    });

    test('toString returns readable representation', () {
      final tween = Tween<double>(begin: 0.0, end: 100.0);
      expect(tween.toString(), contains('Tween'));
      expect(tween.toString(), contains('0'));
      expect(tween.toString(), contains('100'));
    });
  });

  group('IntTween', () {
    test('lerps between begin and end and rounds', () {
      final tween = IntTween(begin: 0, end: 100);
      expect(tween.transform(0.0), 0);
      expect(tween.transform(0.5), 50);
      expect(tween.transform(1.0), 100);
    });

    test('rounds correctly', () {
      final tween = IntTween(begin: 0, end: 10);
      // At t=0.34, value = 3.4, should round to 3
      expect(tween.transform(0.34), 3);
      // At t=0.35, value = 3.5, should round to 4
      expect(tween.transform(0.35), 4);
      // At t=0.36, value = 3.6, should round to 4
      expect(tween.transform(0.36), 4);
    });

    test('handles negative values', () {
      final tween = IntTween(begin: -10, end: 10);
      expect(tween.transform(0.0), -10);
      expect(tween.transform(0.5), 0);
      expect(tween.transform(1.0), 10);
    });
  });

  group('DoubleTween', () {
    test('lerps between begin and end', () {
      final tween = DoubleTween(begin: 0.0, end: 100.0);
      expect(tween.transform(0.0), 0.0);
      expect(tween.transform(0.5), 50.0);
      expect(tween.transform(1.0), 100.0);
    });

    test('handles precision well', () {
      final tween = DoubleTween(begin: 0.0, end: 1.0);
      expect(tween.transform(0.333), closeTo(0.333, 0.0001));
    });
  });

  group('CurveTween', () {
    test('applies linear curve unchanged', () {
      final tween = CurveTween(curve: Curves.linear);
      expect(tween.transform(0.0), 0.0);
      expect(tween.transform(0.5), 0.5);
      expect(tween.transform(1.0), 1.0);
    });

    test('applies ease curve', () {
      final tween = CurveTween(curve: Curves.ease);
      expect(tween.transform(0.0), 0.0);
      expect(tween.transform(1.0), 1.0);
      // Ease should not be linear
      final value = tween.transform(0.5);
      expect(value, isNot(equals(0.5)));
    });

    test('applies easeIn curve', () {
      final tween = CurveTween(curve: Curves.easeIn);
      // EaseIn starts slow
      expect(tween.transform(0.5), lessThan(0.5));
    });

    test('applies easeOut curve', () {
      final tween = CurveTween(curve: Curves.easeOut);
      // EaseOut ends slow
      expect(tween.transform(0.5), greaterThan(0.5));
    });

    test('toString contains curve info', () {
      final tween = CurveTween(curve: Curves.ease);
      expect(tween.toString(), contains('CurveTween'));
    });
  });

  group('ConstantTween', () {
    test('always returns the same value', () {
      final tween = ConstantTween<double>(42.0);
      expect(tween.transform(0.0), 42.0);
      expect(tween.transform(0.5), 42.0);
      expect(tween.transform(1.0), 42.0);
    });

    test('works with strings', () {
      final tween = ConstantTween<String>('hello');
      expect(tween.transform(0.0), 'hello');
      expect(tween.transform(0.5), 'hello');
      expect(tween.transform(1.0), 'hello');
    });

    test('has begin and end set to same value', () {
      final tween = ConstantTween<int>(5);
      expect(tween.begin, 5);
      expect(tween.end, 5);
    });
  });

  group('ReverseTween', () {
    test('reverses a tween', () {
      final originalTween = Tween<double>(begin: 0.0, end: 100.0);
      final reverseTween = ReverseTween<double>(originalTween);

      // At t=0, reverse should return the end of original
      expect(reverseTween.transform(0.0), 100.0);
      // At t=1, reverse should return the begin of original
      expect(reverseTween.transform(1.0), 0.0);
      // At t=0.5, should return middle
      expect(reverseTween.transform(0.5), 50.0);
    });

    test('has begin and end swapped', () {
      final originalTween = Tween<double>(begin: 10.0, end: 90.0);
      final reverseTween = ReverseTween<double>(originalTween);

      expect(reverseTween.begin, 90.0);
      expect(reverseTween.end, 10.0);
    });
  });

  group('StepTween', () {
    test('floors the interpolated value', () {
      final tween = StepTween(begin: 0, end: 10);
      // At t=0.34, value = 3.4, should floor to 3
      expect(tween.transform(0.34), 3);
      // At t=0.39, value = 3.9, should floor to 3
      expect(tween.transform(0.39), 3);
      // At t=0.4, value = 4.0, should floor to 4
      expect(tween.transform(0.4), 4);
    });

    test('handles edge cases', () {
      final tween = StepTween(begin: 0, end: 10);
      expect(tween.transform(0.0), 0);
      expect(tween.transform(1.0), 10);
    });
  });

  group('TweenSequence', () {
    test('sequences multiple tweens', () {
      final sequence = TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween<double>(begin: 0.0, end: 50.0),
          weight: 1.0,
        ),
        TweenSequenceItem(
          tween: Tween<double>(begin: 50.0, end: 100.0),
          weight: 1.0,
        ),
      ]);

      expect(sequence.transform(0.0), 0.0);
      expect(sequence.transform(0.25), 25.0);
      expect(sequence.transform(0.5), 50.0);
      expect(sequence.transform(0.75), 75.0);
      expect(sequence.transform(1.0), 100.0);
    });

    test('handles unequal weights', () {
      final sequence = TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween<double>(begin: 0.0, end: 100.0),
          weight: 3.0, // 75% of animation
        ),
        TweenSequenceItem(
          tween: Tween<double>(begin: 100.0, end: 200.0),
          weight: 1.0, // 25% of animation
        ),
      ]);

      // At t=0, should be at begin of first tween
      expect(sequence.transform(0.0), 0.0);
      // At t=0.75, should be at end of first tween
      expect(sequence.transform(0.75), closeTo(100.0, 0.1));
      // At t=1, should be at end of second tween
      expect(sequence.transform(1.0), 200.0);
    });

    test('single item sequence', () {
      final sequence = TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween<double>(begin: 10.0, end: 20.0),
          weight: 1.0,
        ),
      ]);

      expect(sequence.transform(0.0), 10.0);
      expect(sequence.transform(0.5), 15.0);
      expect(sequence.transform(1.0), 20.0);
    });
  });

  group('Interval', () {
    test('maps values within interval', () {
      const interval = Interval(0.25, 0.75);

      // Before interval starts
      expect(interval.transform(0.0), 0.0);
      expect(interval.transform(0.2), 0.0);
      // At interval start
      expect(interval.transform(0.25), 0.0);
      // Middle of interval
      expect(interval.transform(0.5), closeTo(0.5, 0.01));
      // At interval end
      expect(interval.transform(0.75), 1.0);
      // After interval ends
      expect(interval.transform(0.8), 1.0);
      expect(interval.transform(1.0), 1.0);
    });

    test('applies curve within interval', () {
      const interval = Interval(0.0, 1.0, curve: Curves.easeIn);

      expect(interval.transform(0.0), 0.0);
      expect(interval.transform(1.0), 1.0);
      // EaseIn at 0.5 should be less than 0.5
      expect(interval.transform(0.5), lessThan(0.5));
    });

    test('full range interval with linear curve is identity', () {
      const interval = Interval(0.0, 1.0);

      expect(interval.transform(0.0), 0.0);
      expect(interval.transform(0.25), closeTo(0.25, 0.01));
      expect(interval.transform(0.5), closeTo(0.5, 0.01));
      expect(interval.transform(0.75), closeTo(0.75, 0.01));
      expect(interval.transform(1.0), 1.0);
    });

    test('toString representation', () {
      const interval = Interval(0.25, 0.75);
      expect(interval.toString(), contains('Interval'));
    });
  });

  group('Threshold', () {
    test('returns 0 below threshold', () {
      const threshold = Threshold(0.5);
      expect(threshold.transform(0.0), 0.0);
      expect(threshold.transform(0.49), 0.0);
    });

    test('returns 1 at and above threshold', () {
      const threshold = Threshold(0.5);
      expect(threshold.transform(0.5), 1.0);
      expect(threshold.transform(0.51), 1.0);
      expect(threshold.transform(1.0), 1.0);
    });

    test('threshold at 0', () {
      const threshold = Threshold(0.0);
      // Everything is at or above 0
      expect(threshold.transform(0.0), 1.0);
      expect(threshold.transform(0.5), 1.0);
    });

    test('threshold at 1', () {
      const threshold = Threshold(1.0);
      // Only at 1.0 will it be >= threshold
      expect(threshold.transform(0.0), 0.0);
      expect(threshold.transform(0.99), 0.0);
      expect(threshold.transform(1.0), 1.0);
    });
  });

  group('Animatable.chain', () {
    test('chains two animatables', () {
      final tween = Tween<double>(begin: 0.0, end: 100.0);
      final curve = CurveTween(curve: Curves.linear);
      final chained = tween.chain(curve);

      expect(chained.transform(0.0), 0.0);
      expect(chained.transform(0.5), 50.0);
      expect(chained.transform(1.0), 100.0);
    });

    test('chains with non-linear curve', () {
      final tween = Tween<double>(begin: 0.0, end: 100.0);
      final curve = CurveTween(curve: Curves.easeIn);
      final chained = tween.chain(curve);

      expect(chained.transform(0.0), 0.0);
      expect(chained.transform(1.0), 100.0);
      // EaseIn means at t=0.5, the curve is less than 0.5
      // so the tween value should be less than 50
      expect(chained.transform(0.5), lessThan(50.0));
    });
  });
}
