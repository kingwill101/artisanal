import 'package:nocterm/src/utils/ansi_color_quantizer.dart';
import 'package:test/test.dart';

void main() {
  group('AnsiColorQuantizer', () {
    tearDown(resetAnsi256CacheForTesting);

    test('quantizes primary colors to expected xterm indices', () {
      expect(quantizeRgbToAnsi256(255, 0, 0), equals(196));
      expect(quantizeRgbToAnsi256(0, 255, 0), equals(46));
      expect(quantizeRgbToAnsi256(0, 0, 255), equals(21));
    });

    test('grayscale maps to xterm grayscale ramp', () {
      expect(quantizeRgbToAnsi256(128, 128, 128), equals(244));
    });

    test('cache returns results without recomputation', () {
      resetAnsi256CacheForTesting();
      expect(ansi256CacheSizeForTesting(), equals(0));

      final first = quantizeRgbToAnsi256(12, 34, 56);
      final second = quantizeRgbToAnsi256(12, 34, 56);

      expect(first, equals(second));
      expect(ansi256CacheSizeForTesting(), equals(1));
    });

    test('cache prunes least-recently-used entries', () {
      resetAnsi256CacheForTesting();
      setAnsi256CacheMaxEntriesForTesting(4);

      for (int i = 0; i < 6; i++) {
        quantizeRgbToAnsi256(i * 20, i * 10, i * 5);
      }

      expect(ansi256CacheSizeForTesting(), equals(4));
    });
  });
}
