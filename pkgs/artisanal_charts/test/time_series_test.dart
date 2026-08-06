import 'package:artisanal_charts/artisanal_charts.dart';
import 'package:test/test.dart';

void main() {
  group('TimeSeriesBuffer', () {
    test('push and getData', () {
      final buf = TimeSeriesBuffer(
        const TimeSeriesBufferOptions(windowMs: 60000, maxPoints: 100),
      );
      buf.push(1);
      buf.push(2);
      buf.push(3);
      expect(buf.getData(), [1, 2, 3]);
      expect(buf.last(), 3);
      expect(buf.length, 3);
    });

    test('enforces maxPoints', () {
      final buf = TimeSeriesBuffer(
        const TimeSeriesBufferOptions(windowMs: 60000, maxPoints: 3),
      );
      for (var i = 0; i < 10; i++) {
        buf.push(i.toDouble());
      }
      expect(buf.length, 3);
      expect(buf.getData(), [7, 8, 9]);
    });

    test('stats', () {
      final buf = TimeSeriesBuffer();
      buf.pushMany([10, 20, 30]);
      final s = buf.stats();
      expect(s.min, 10);
      expect(s.max, 30);
      expect(s.avg, 20);
      expect(s.count, 3);
    });

    test('clear', () {
      final buf = TimeSeriesBuffer();
      buf.push(1);
      buf.clear();
      expect(buf.length, 0);
      expect(buf.last(), isNull);
    });
  });

  group('MultiSeriesBuffer', () {
    test('toDataSeries', () {
      final multi = MultiSeriesBuffer();
      multi.push('cpu', 10);
      multi.push('cpu', 20);
      multi.push('mem', 50);
      final series = multi.toDataSeries({'cpu': '#4FC3F7', 'mem': '#81C784'});
      expect(series.length, 2);
      final cpu = series.firstWhere((s) => s.name == 'cpu');
      expect(cpu.data, [10, 20]);
      expect(cpu.color, '#4FC3F7');
    });
  });
}
