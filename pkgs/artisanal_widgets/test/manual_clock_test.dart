import 'package:artisanal_widgets/testing.dart';
import 'package:test/test.dart';

void main() {
  group('ManualClock', () {
    test('defaults to a stable UTC epoch', () {
      final clock = ManualClock();
      expect(
        clock.now,
        equals(DateTime.fromMillisecondsSinceEpoch(0, isUtc: true)),
      );
    });

    test('advance moves time deterministically', () {
      final clock = ManualClock();
      final advanced = clock.advance(const Duration(milliseconds: 125));

      expect(advanced, equals(clock.now));
      expect(
        clock.now,
        equals(DateTime.fromMillisecondsSinceEpoch(125, isUtc: true)),
      );
    });

    test('animationTick and advanceAnimationTick preserve explicit time', () {
      final clock = ManualClock(
        initialTime: DateTime.fromMillisecondsSinceEpoch(10, isUtc: true),
      );

      final first = clock.animationTick('controller-a');
      final second = clock.advanceAnimationTick(
        'controller-a',
        const Duration(milliseconds: 50),
      );

      expect(first.controllerId, equals('controller-a'));
      expect(
        first.time,
        equals(clock.now.subtract(const Duration(milliseconds: 50))),
      );
      expect(second.time, equals(clock.now));
    });
  });
}
