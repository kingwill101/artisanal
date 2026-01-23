import 'package:artisanal/src/uv/uv.dart';
import 'package:test/test.dart';

// Upstream parity:
// - `third_party/ultraviolet/tabstop_test.go`
// - `third_party/ultraviolet/tabstop.go`

void main() {
  group('TabStops parity', () {
    test('default interval of 8', () {
      final ts = TabStops(24, TabStops.defaultTabInterval);

      expect(ts.isStop(0), true);
      expect(ts.isStop(7), false);
      expect(ts.isStop(8), true);
      expect(ts.isStop(15), false);
      expect(ts.isStop(16), true);
      expect(ts.isStop(23), false);

      final customCol = TabStops.defaultTabInterval + 1;
      ts.set(customCol);
      expect(ts.isStop(customCol), true);

      final regularStop = TabStops.defaultTabInterval;
      ts.reset(regularStop);
      expect(ts.isStop(regularStop), false);
    });

    test('custom interval of 4', () {
      final ts = TabStops(16, 4);

      expect(ts.isStop(0), true);
      expect(ts.isStop(3), false);
      expect(ts.isStop(4), true);
      expect(ts.isStop(7), false);
      expect(ts.isStop(8), true);
      expect(ts.isStop(12), true);
      expect(ts.isStop(15), false);

      final customCol = 4 + 1;
      ts.set(customCol);
      expect(ts.isStop(customCol), true);

      final regularStop = 4;
      ts.reset(regularStop);
      expect(ts.isStop(regularStop), false);
    });

    test('navigation', () {
      final ts = TabStops.defaults(24);

      expect(ts.next(0), 8);
      expect(ts.prev(0), 0);

      expect(ts.next(4), 8);
      expect(ts.prev(4), 0);

      expect(ts.next(8), 16);
      expect(ts.prev(8), 0);

      expect(ts.next(20), 23);
      expect(ts.prev(20), 16);
    });

    test('clear', () {
      final ts = TabStops.defaults(24);
      expect(ts.isStop(0), true);
      expect(ts.isStop(8), true);
      expect(ts.isStop(16), true);

      ts.clear();
      for (var i = 0; i < 24; i++) {
        expect(ts.isStop(i), false);
      }
    });

    test('resize', () {
      final grow = TabStops.defaults(16);
      expect(grow.width, 16);
      grow.resize(24);
      expect(grow.width, 24);
      expect(grow.isStop(0), true);
      expect(grow.isStop(8), true);
      expect(grow.isStop(16), true);
      expect(grow.isStop(23), false);

      final same = TabStops.defaults(16);
      same.resize(16);
      expect(same.width, 16);
      expect(same.isStop(0), true);
      expect(same.isStop(8), true);
      expect(same.isStop(15), false);

      final custom = TabStops(8, 4);
      expect(custom.width, 8);
      custom.resize(16);
      expect(custom.width, 16);
      expect(custom.isStop(0), true);
      expect(custom.isStop(4), true);
      expect(custom.isStop(8), true);
      expect(custom.isStop(12), true);
      expect(custom.isStop(15), false);

      final expectedStopsLen = (16 + (custom.interval - 1)) ~/ custom.interval;
      expect(custom.stops.length, expectedStopsLen);
    });

    test('resize edge cases', () {
      final ts = TabStops.defaults(8);
      ts.resize(0);
      expect(ts.width, 0);
      expect(ts.isStop(0), false);

      final ts2 = TabStops.defaults(8);
      ts2.resize(1000);
      expect(ts2.width, 1000);
      expect(ts2.isStop(0), true);
      expect(ts2.isStop(8), true);
      expect(ts2.isStop(16), true);
    });
  });
}
