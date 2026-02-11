# Charting Primitives

Artisanal provides terminal-native chart renderers that draw into UV buffers. Use `renderChartLines` to produce printable output.

## Quick Start (Sparkline)

```dart
import 'package:artisanal/charting.dart' as chart;

void main() {
  final values = [12, 18, 22, 19, 25, 29, 31, 28, 24, 26, 30, 34];
  final lines = chart.renderChartLines(40, 3, (screen, area) {
    chart.drawSparkline(
      screen,
      area,
      values,
      style: chart.uvStyleFromHex('#56ccf2'),
      showGrid: true,
      gridStyle: chart.uvStyleFromHex('#3b4252'),
    );
  });
  print(lines.join('\n'));
}
```

## Line Chart

```dart
import 'dart:math' as math;
import 'package:artisanal/charting.dart' as chart;

void main() {
  final series = _series(60, seed: 13, min: 20, max: 90);
  final lines = chart.renderChartLines(64, 12, (screen, area) {
    chart.drawLineChart(
      screen,
      area,
      series,
      lineStyle: chart.uvStyleFromHex('#56ccf2'),
      showGrid: true,
      gridRows: 3,
      gridCols: 3,
      gridStyle: chart.uvStyleFromHex('#3b4252'),
      xLabels: const ['-60s', '-30s', 'now'],
      yLabels: const ['100%', '50%', '0%'],
      labelStyle: chart.uvStyleFromHex('#3b4252'),
    );
  });
  print(lines.join('\n'));
}

List<double> _series(
  int count, {
  required int seed,
  required double min,
  required double max,
}) {
  final rng = math.Random(seed);
  var value = (min + max) / 2;
  return List<double>.generate(count, (i) {
    value += (rng.nextDouble() * 2 - 1) * ((max - min) * 0.08);
    value = value.clamp(min, max).toDouble();
    return value;
  }, growable: false);
}
```

## Ribbon / Area Chart

```dart
import 'dart:math' as math;
import 'package:artisanal/charting.dart' as chart;

void main() {
  final seriesA = _series(60, seed: 13, min: 20, max: 90);
  final seriesB = _series(60, seed: 42, min: 10, max: 75);
  final seriesC = _series(60, seed: 77, min: 5, max: 55);

  final lines = chart.renderChartLines(64, 12, (screen, area) {
    final styles = [
      chart.uvStyleFromHex('#00bbf9'),
      chart.uvStyleFromHex('#00f5d4'),
      chart.uvStyleFromHex('#f15bb5'),
    ];
    chart.drawRibbonChart(
      screen,
      area,
      [seriesA, seriesB, seriesC],
      styles: styles,
      showGrid: true,
      gridRows: 2,
      gridStyle: chart.uvStyleFromHex('#3b4252'),
    );
  });

  print(lines.join('\n'));
}

List<double> _series(
  int count, {
  required int seed,
  required double min,
  required double max,
}) {
  final rng = math.Random(seed);
  var value = (min + max) / 2;
  return List<double>.generate(count, (i) {
    value += (rng.nextDouble() * 2 - 1) * ((max - min) * 0.08);
    value = value.clamp(min, max).toDouble();
    return value;
  }, growable: false);
}
```

## Histogram

```dart
import 'dart:math' as math;
import 'package:artisanal/charting.dart' as chart;

void main() {
  final values = _series(50, seed: 99, min: 0, max: 100);
  final lines = chart.renderChartLines(64, 10, (screen, area) {
    chart.drawHistogram(
      screen,
      area,
      values,
      barStyle: chart.uvStyleFromHex('#9b5de5'),
      axisStyle: chart.uvStyleFromHex('#3b4252'),
      showGrid: true,
      gridRows: 3,
      gridCols: 2,
      gridStyle: chart.uvStyleFromHex('#3b4252'),
      xLabels: const ['0', 'mid', 'max'],
      yLabels: const ['100', '50', '0'],
      labelStyle: chart.uvStyleFromHex('#3b4252'),
    );
  });
  print(lines.join('\n'));
}

List<double> _series(
  int count, {
  required int seed,
  required double min,
  required double max,
}) {
  final rng = math.Random(seed);
  return List<double>.generate(
    count,
    (i) => rng.nextDouble() * (max - min) + min,
    growable: false,
  );
}
```

## Heatmap

```dart
import 'dart:math' as math;
import 'package:artisanal/charting.dart' as chart;

void main() {
  final grid = _heatmap(28, 12);
  final lines = chart.renderChartLines(64, 12, (screen, area) {
    chart.drawHeatmap(
      screen,
      area,
      grid,
      ramp: chart.ChartRamp.thermal(),
      showGrid: true,
      gridRows: 3,
      gridCols: 4,
      gridStyle: chart.uvStyleFromHex('#3b4252'),
    );
  });
  print(lines.join('\n'));
}

List<List<double>> _heatmap(int width, int height) {
  final rng = math.Random(7);
  return List.generate(
    height,
    (y) => List<double>.generate(
      width,
      (x) => (math.sin(x * 0.22) + math.cos(y * 0.31)) * 0.25 +
          rng.nextDouble() * 0.5,
      growable: false,
    ),
    growable: false,
  );
}
```

## Pie Chart

```dart
import 'package:artisanal/charting.dart' as chart;

void main() {
  final lines = chart.renderChartLines(40, 12, (screen, area) {
    final styles = [
      chart.uvStyleFromHex('#ff006e'),
      chart.uvStyleFromHex('#8338ec'),
      chart.uvStyleFromHex('#3a86ff'),
      chart.uvStyleFromHex('#ffbe0b'),
    ];
    chart.drawPieChart(
      screen,
      area,
      [30, 20, 15, 35],
      styles: styles,
      donut: true,
      useBackground: true,
    );
  });
  print(lines.join('\n'));
}
```

## Legend and Palette

```dart
import 'package:artisanal/charting.dart' as chart;

void main() {
  final ramp = chart.ChartRamp.fromHexes(
    ['#0b132b', '#1b2a6b', '#3a86ff', '#88ffcc', '#ffbe0b', '#ff006e'],
  );

  final entries = List<chart.ChartLegendEntry>.generate(
    ramp.colors.length,
    (i) {
      final t = ramp.colors.length == 1 ? 0.0 : i / (ramp.colors.length - 1);
      final style = ramp.styleFor(t, background: true);
      return chart.ChartLegendEntry(label: 'step $i', style: style);
    },
    growable: false,
  );

  final lines = chart.renderChartLines(30, 6, (screen, area) {
    chart.drawLegend(screen, area, entries, columns: 2, rowGap: 0);
  });

  print(lines.join('\n'));
}
```

## Related Docs

- [DOCS_INDEX.md](DOCS_INDEX.md) - Full documentation index
- [UV.md](UV.md)
