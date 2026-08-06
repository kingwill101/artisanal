// Animated live-update demo (port of opentui-charts demo-animated.ts).
// Prints successive frames of live charts using TimeSeriesBuffer.
//
// Run: dart run example/demo_animated.dart
import 'dart:io';
import 'dart:math' as math;

import 'package:artisanal_charts/artisanal_charts.dart';

void main() async {
  final multi = MultiSeriesBuffer(
    const TimeSeriesBufferOptions(windowMs: 30000, maxPoints: 80),
  );
  final rng = math.Random(7);
  var cpu = 40.0;
  var mem = 55.0;

  const frames = 8;
  for (var frame = 0; frame < frames; frame++) {
    cpu = (cpu + (rng.nextDouble() - 0.45) * 8).clamp(5.0, 95.0);
    mem = (mem + (rng.nextDouble() - 0.5) * 5).clamp(10.0, 90.0);
    multi.push('cpu', cpu);
    multi.push('mem', mem);

    final line = createLineChart(
      LineChartProps(
        width: 60,
        height: 12,
        title: 'Live — CPU / MEM (frame ${frame + 1}/$frames)',
        series: multi.toDataSeries({'cpu': '#4FC3F7', 'mem': '#81C784'}),
        showDots: false,
        grid: const GridOptions(show: true),
        legend: const LegendOptions(show: true),
        backgroundColor: '#0D1117',
      ),
    );

    final gauge = createGaugeChart(
      GaugeChartProps(
        width: 30,
        height: 10,
        title: 'CPU',
        value: cpu,
        label: 'load',
        backgroundColor: '#0D1117',
      ),
    );

    final spark = createSparkline(
      SparklineProps(
        width: 50,
        height: 3,
        title: 'MEM spark',
        data: multi.series('mem').getData(),
        color: '#81C784',
        style: SparklineStyle.line,
        showMinMax: true,
        backgroundColor: '#0D1117',
      ),
    );

    // Clear screen between frames when interactive.
    if (stdout.hasTerminal) {
      stdout.write('\x1B[2J\x1B[H');
    }
    print(line.render());
    print('');
    print(gauge.render());
    print('');
    print(spark.render());
    await Future<void>.delayed(const Duration(milliseconds: 150));
  }
}
