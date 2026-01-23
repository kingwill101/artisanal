import 'package:test/test.dart';
import 'package:artisanal/src/uv/uv.dart';

void main() {
  group('SizeNotifier', () {
    test('getSize returns a valid size', () {
      final notifier = SizeNotifier();
      final (w, h) = notifier.getSize();

      // Even if not a terminal, it should return the default 80x24 or the actual size.
      expect(w, isPositive);
      expect(h, isPositive);
    });

    test('getWindowSize returns cells and pixels', () {
      final notifier = SizeNotifier();
      final size = notifier.getWindowSize();

      expect(size.cells.width, isPositive);
      expect(size.cells.height, isPositive);
      expect(size.pixels.width, equals(0));
      expect(size.pixels.height, equals(0));
    });

    test('start and stop', () {
      final notifier = SizeNotifier();
      // Should not throw
      notifier.start();
      notifier.stop();
    });
  });
}
