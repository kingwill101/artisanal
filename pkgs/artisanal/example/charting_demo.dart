import 'dart:math' as math;

import 'package:artisanal/charting.dart' as chart;
import 'package:artisanal/style.dart';
import 'package:artisanal/uv.dart' show Rectangle;

void main() {
  final heading = Style().bold().foreground(Colors.cyan);
  final dim = Style().foreground(Colors.gray);

  final seriesA = _series(60, seed: 13, min: 20, max: 90);
  final seriesB = _series(60, seed: 42, min: 10, max: 75);
  final seriesC = _series(60, seed: 77, min: 5, max: 55);

  print(heading.render('Artisanal Charting Demo'));
  print(dim.render('Sparkline, line, histogram, heatmap, ribbon, pie'));
  print('');

  _printBlock(
    heading.render('Line Chart'),
    chart.renderChartLines(64, 12, (screen, area) {
      chart.drawLineChart(
        screen,
        area,
        seriesA,
        lineStyle: chart.uvStyleFromHex('#56ccf2'),
        showGrid: true,
        gridRows: 3,
        gridCols: 3,
        gridStyle: chart.uvStyleFromHex('#3b4252'),
        xLabels: const ['-60s', '-30s', 'now'],
        yLabels: const ['100%', '50%', '0%'],
        labelStyle: chart.uvStyleFromHex('#3b4252'),
      );
    }),
  );

  _printBlock(
    heading.render('Histogram'),
    chart.renderChartLines(64, 10, (screen, area) {
      chart.drawHistogram(
        screen,
        area,
        seriesB,
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
    }),
  );

  _printBlock(
    heading.render('Heatmap'),
    chart.renderChartLines(64, 12, (screen, area) {
      chart.drawHeatmap(
        screen,
        area,
        _heatmap(28, 12),
        ramp: chart.ChartRamp.thermal(),
        showGrid: true,
        gridRows: 3,
        gridCols: 4,
        gridStyle: chart.uvStyleFromHex('#3b4252'),
      );
    }),
  );

  _printBlock(
    heading.render('Ribbon Chart + Legend'),
    chart.renderChartLines(64, 12, (screen, area) {
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
      final legendArea = Rectangle(
        minX: area.minX + 1,
        minY: area.minY + 1,
        maxX: area.minX + 22,
        maxY: area.minY + 3,
      );
      chart.drawLegend(screen, legendArea, [
        chart.ChartLegendEntry(label: 'alpha', style: styles[0]),
        chart.ChartLegendEntry(label: 'beta', style: styles[1]),
        chart.ChartLegendEntry(label: 'gamma', style: styles[2]),
      ], columns: 2);
    }),
  );

  _printBlock(
    heading.render('Pie Chart'),
    chart.renderChartLines(40, 12, (screen, area) {
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
      final legendArea = Rectangle(
        minX: area.minX + 1,
        minY: area.maxY - 3,
        maxX: area.minX + 22,
        maxY: area.maxY - 1,
      );
      chart.drawLegend(screen, legendArea, [
        chart.ChartLegendEntry(label: 'A', style: styles[0]),
        chart.ChartLegendEntry(label: 'B', style: styles[1]),
        chart.ChartLegendEntry(label: 'C', style: styles[2]),
        chart.ChartLegendEntry(label: 'D', style: styles[3]),
      ], columns: 2);
    }),
  );
}

void _printBlock(String title, List<String> lines) {
  print(title);
  print(lines.join('\n'));
  print('');
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

List<List<double>> _heatmap(int width, int height) {
  final rng = math.Random(7);
  return List.generate(
    height,
    (y) => List<double>.generate(
      width,
      (x) =>
          (math.sin(x * 0.22) + math.cos(y * 0.31)) * 0.25 +
          rng.nextDouble() * 0.5,
      growable: false,
    ),
    growable: false,
  );
}
