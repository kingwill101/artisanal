import 'package:artisanal/src/tui/resize_coalescer.dart';
import 'package:test/test.dart';

void main() {
  group('ResizeCoalescer', () {
    test('first resize is immediate', () {
      const coalescer = ResizeCoalescer();
      final state = coalescer.next(
        const ResizeCoalescerState(),
        DateTime(2026),
      );

      expect(state.delay, Duration.zero);
      expect(state.burstCount, 0);
    });

    test('steady resize uses a short delay', () {
      const coalescer = ResizeCoalescer();
      final first = coalescer.next(
        const ResizeCoalescerState(),
        DateTime(2026),
      );
      final second = coalescer.next(
        first,
        DateTime(2026).add(const Duration(milliseconds: 40)),
      );

      expect(second.delay, const Duration(milliseconds: 8));
      expect(second.burstCount, 1);
    });

    test('rapid burst resize uses a longer delay', () {
      const coalescer = ResizeCoalescer();
      final first = coalescer.next(
        const ResizeCoalescerState(),
        DateTime(2026),
      );
      final second = coalescer.next(
        first,
        DateTime(2026).add(const Duration(milliseconds: 10)),
      );

      expect(second.delay, const Duration(milliseconds: 30));
      expect(second.burstCount, 1);
    });

    test('widely spaced resize resets to immediate dispatch', () {
      const coalescer = ResizeCoalescer();
      final first = coalescer.next(
        const ResizeCoalescerState(),
        DateTime(2026),
      );
      final second = coalescer.next(
        first,
        DateTime(2026).add(const Duration(milliseconds: 120)),
      );

      expect(second.delay, Duration.zero);
      expect(second.burstCount, 0);
    });
  });
}
