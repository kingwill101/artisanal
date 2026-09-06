import 'package:artisanal/tui.dart';
import 'package:test/test.dart';
import 'package:ultraviolet/core.dart' as ultraviolet;

void main() {
  group('FrameLayout', () {
    test('allocates fixed, percentage, then weighted fill constraints', () {
      final areas = FrameLayout.horizontal(
        const FrameArea(0, 0, 40, 10),
        const [FrameLength(8), FramePercentage(25), FrameFill(), FrameFill(2)],
        gap: 1,
      );

      expect(areas, const [
        FrameArea(0, 0, 8, 10),
        FrameArea(9, 0, 9, 10),
        FrameArea(19, 0, 7, 10),
        FrameArea(27, 0, 13, 10),
      ]);
    });

    test('applies insets and vertical gaps', () {
      final areas = FrameLayout.vertical(
        const FrameArea(10, 20, 20, 12),
        const [FrameLength(2), FrameFill(), FrameLength(1)],
        gap: 1,
        insets: const FrameInsets(left: 2, top: 1, right: 3, bottom: 2),
      );

      expect(areas, const [
        FrameArea(12, 21, 15, 2),
        FrameArea(12, 24, 15, 4),
        FrameArea(12, 29, 15, 1),
      ]);
    });

    test('clips later constraints in undersized areas', () {
      final areas = FrameLayout.horizontal(const FrameArea(0, 0, 5, 1), const [
        FrameLength(4),
        FrameLength(4),
        FrameFill(),
      ], gap: 2);

      expect(areas, const [
        FrameArea(0, 0, 1, 1),
        FrameArea(3, 0, 0, 1),
        FrameArea(5, 0, 0, 1),
      ]);
    });

    test('distributes fill rounding by remainder then declaration order', () {
      final areas = FrameLayout.horizontal(const FrameArea(0, 0, 8, 1), const [
        FrameFill(),
        FrameFill(),
        FrameFill(),
      ]);

      expect(areas.map((area) => area.width), [3, 3, 2]);
    });

    test('weighted fills preserve Ultraviolet allocation parity', () {
      const weights = [1, 3, 2, 5];
      final areas = FrameLayout.horizontal(const FrameArea(0, 0, 29, 1), const [
        FrameFill(1),
        FrameFill(3),
        FrameFill(2),
        FrameFill(5),
      ]);

      expect(
        areas.map((area) => area.width),
        ultraviolet.splitByLargestRemainder(29, weights),
      );
    });

    test('fixed and percentage constraints preserve Ultraviolet parity', () {
      final areas = FrameLayout.horizontal(const FrameArea(0, 0, 37, 1), const [
        FrameLength(9),
        FramePercentage(40),
        FrameFill(),
      ]);
      final fixed = const ultraviolet.Fixed(9).apply(37);
      final percentage = const ultraviolet.Percent(40).apply(37);

      expect(areas.map((area) => area.width), [
        fixed,
        percentage,
        37 - fixed - percentage,
      ]);
    });

    test('returns empty regions when insets consume the viewport', () {
      final areas = FrameLayout.vertical(const FrameArea(0, 0, 4, 2), const [
        FrameFill(),
      ], insets: const FrameInsets.all(3));

      expect(areas, const [FrameArea(3, 2, 0, 0)]);
    });

    test('rejects negative gaps', () {
      expect(
        () => FrameLayout.horizontal(const FrameArea(0, 0, 10, 1), const [
          FrameFill(),
        ], gap: -1),
        throwsArgumentError,
      );
    });
  });
}
