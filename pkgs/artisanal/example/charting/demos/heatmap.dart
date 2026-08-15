// Heatmap chart demo.
//
// Run: dart run example/charting/demos/heatmap.dart
import 'dart:math' as math;

import 'package:artisanal/artisanal.dart';

void main() {
  final rng = math.Random(42);
  final data = List.generate(
    8,
    (y) => List.generate(12, (x) {
      return (math.sin(x * 0.5) + math.cos(y * 0.4)) * 10 + rng.nextDouble() * 5;
    }),
  );

  final chart = createHeatmapChart(
    HeatmapChartProps(
      width: 50,
      height: 14,
      title: 'Heatmap — Activity',
      data: data,
      showValues: false,
      backgroundColor: '#0D1117',
    ),
  );
  print(chart);
}
