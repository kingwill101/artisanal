import 'package:artisanal_charts/artisanal_charts.dart';
import 'package:test/test.dart';

void main() {
  group('computeNiceScale', () {
    test('handles equal min/max', () {
      final scale = computeNiceScale(5, 5);
      expect(scale.min, lessThan(scale.max));
      expect(scale.ticks, isNotEmpty);
    });

    test('produces ordered ticks', () {
      final scale = computeNiceScale(0, 100, 5);
      expect(scale.ticks.first, lessThanOrEqualTo(0));
      expect(scale.ticks.last, greaterThanOrEqualTo(100));
      for (var i = 1; i < scale.ticks.length; i++) {
        expect(scale.ticks[i], greaterThan(scale.ticks[i - 1]));
      }
    });

    test('adjusts plot height for even spacing', () {
      final scale = computeNiceScale(0, 10, 6, 20);
      if (scale.effectivePlotH != null) {
        expect(scale.effectivePlotH!, lessThanOrEqualTo(20));
        expect(scale.plotYOffset, isNotNull);
      }
    });
  });

  group('formatNumber', () {
    test('formats integers and large magnitudes', () {
      expect(formatNumber(42), '42');
      expect(formatNumber(1500), '1.5K');
      expect(formatNumber(2e6), '2.0M');
      expect(formatNumber(3e9), '3.0B');
    });
  });

  group('color helpers', () {
    test('parses hex colors', () {
      final c = parseHexColor('#4FC3F7');
      expect(c, isNotNull);
    });
  });
}
