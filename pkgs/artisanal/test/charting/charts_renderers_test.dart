/// Tests for the high-level props-based chart renderers.
library;

import 'package:artisanal/uv.dart';
import 'package:artisanal/artisanal.dart';
import 'package:test/test.dart';

/// Helper to render a chart and return the full rendered string.
String _render(int w, int h, void Function(Canvas, Rectangle) painter) {
  final canvas = Canvas(w, h);
  final area = Rectangle(minX: 0, minY: 0, maxX: w, maxY: h);
  painter(canvas, area);
  return canvas.render();
}

void main() {
  // -------------------------------------------------------------------------
  // util helpers
  // -------------------------------------------------------------------------

  group('color helpers', () {
    test('parseHexColor parses 6-digit hex', () {
      final c = parseHexColor('#FF8000');
      expect(c, isNotNull);
      expect(c, UvColor.rgb(255, 128, 0));
    });

    test('parseHexColor returns fallback for invalid input', () {
      final fallback = parseHexColor('#000000');
      expect(parseHexColor('nope', fallback: fallback), fallback);
    });

    test('fg creates style with foreground color', () {
      final style = fg('#FF0000');
      expect(style.fg, isNotNull);
      expect(style.bg, isNull);
    });

    test('dimFg darkens the color', () {
      final style = dimFg('#FFFFFF', 0.5);
      expect(style.fg, isNotNull);
      expect(style.fg, isNot(UvColor.rgb(255, 255, 255)));
    });

    test('mergeStyle merges fg and bg styles', () {
      final merged = mergeStyle(fg('#FF0000'), fg('#0000FF'));
      expect(merged.fg, isNotNull);
      expect(merged.bg, isNotNull);
    });
  });

  group('NiceScale', () {
    test('computeNiceScale returns tick range', () {
      final scale = computeNiceScale(0, 100);
      expect(scale.min, 0);
      expect(scale.max, 100);
      expect(scale.ticks.length, greaterThan(1));
    });

    test('computeNiceScale handles degenerate range', () {
      final scale = computeNiceScale(5, 5);
      expect(scale.max, greaterThan(scale.min));
    });
  });

  group('drawHLine / drawVLine', () {
    test('drawHLine draws horizontal line', () {
      final canvas = Canvas(10, 3);
      final area = Rectangle(minX: 0, minY: 0, maxX: 10, maxY: 3);
      drawHLine(canvas, area, 1, 5, 1, fg('#FFFFFF'), fg('#000000'));
      for (var x = 1; x <= 5; x++) {
        expect(canvas.cellAt(x, 1)?.content, '─');
      }
    });

    test('drawVLine draws vertical line', () {
      final canvas = Canvas(3, 10);
      final area = Rectangle(minX: 0, minY: 0, maxX: 3, maxY: 10);
      drawVLine(canvas, area, 1, 2, 7, fg('#FFFFFF'), fg('#000000'));
      for (var y = 2; y <= 7; y++) {
        expect(canvas.cellAt(1, y)?.content, '│');
      }
    });
  });

  group('renderChart', () {
    test('joins renderChartLines with newlines', () {
      final out = renderChart(5, 3, (screen, area) {
        putText(screen, area, 0, 0, 'AB', const UvStyle());
      });
      expect(out.split('\n').length, 3);
    });
  });

  // -------------------------------------------------------------------------
  // Line chart
  // -------------------------------------------------------------------------

  group('renderLineChart', () {
    final props = LineChartProps(
      width: 40,
      height: 12,
      title: 'Line',
      series: [
        DataSeries(name: 'A', data: [1, 3, 2, 5, 4], color: '#4FC3F7'),
        DataSeries(name: 'B', data: [2, 2, 4, 3, 6], color: '#81C784'),
      ],
      showDots: true,
      grid: const GridOptions(show: true),
    );

    test('renders braille line output', () {
      final out = renderChart(props.width, props.height, (s, a) {
        renderLineChart(s, a, props);
      });
      final quadrantPattern = RegExp(r'[\u2580\u2584\u2596-\u259F]');
      expect(quadrantPattern.hasMatch(out), isTrue);
    });

    test('renders title', () {
      final out = _render(40, 12, (s, a) => renderLineChart(s, a, props));
      expect(out, contains('Line'));
    });

    test('renders legend for multiple series', () {
      final out = _render(40, 12, (s, a) => renderLineChart(s, a, props));
      expect(out, contains('A'));
      expect(out, contains('B'));
    });

    test('createLineChart returns multi-line string', () {
      final out = createLineChart(props);
      expect(out.split('\n').length, props.height);
    });

    test('handles empty series', () {
      final out = _render(20, 10, (s, a) {
        renderLineChart(s, a, LineChartProps(width: 20, height: 10, series: []));
      });
      expect(out, isNotNull);
    });
  });

  // -------------------------------------------------------------------------
  // Bar chart
  // -------------------------------------------------------------------------

  group('renderBarChart', () {
    test('renders bars and labels', () {
      final out = renderChart(40, 12, (s, a) {
        renderBarChart(
          s,
          a,
          BarChartProps(
            width: 40,
            height: 12,
            series: [DataSeries(name: 'Sales', data: [10, 20, 15, 30])],
            labels: const ['Q1', 'Q2', 'Q3', 'Q4'],
          ),
        );
      });
      expect(out, isNotEmpty);
      expect(out, contains('Q1'));
      expect(out, contains('Q4'));
    });

    test('horizontal orientation renders bars', () {
      final out = renderChart(40, 12, (s, a) {
        renderBarChart(
          s,
          a,
          BarChartProps(
            width: 40,
            height: 12,
            series: [DataSeries(name: 'A', data: [10, 20, 15])],
            orientation: ChartOrientation.horizontal,
          ),
        );
      });
      expect(out, isNotEmpty);
    });

    test('grouped series render legend', () {
      final out = renderChart(40, 12, (s, a) {
        renderBarChart(
          s,
          a,
          BarChartProps(
            width: 40,
            height: 12,
            series: [
              DataSeries(name: 'X', data: [10, 20]),
              DataSeries(name: 'Y', data: [5, 15]),
            ],
          ),
        );
      });
      expect(out, contains('X'));
      expect(out, contains('Y'));
    });

    test('createBarChart returns multi-line string', () {
      final out = createBarChart(
        BarChartProps(
          width: 40,
          height: 12,
          series: [DataSeries(name: 'A', data: [1, 2, 3])],
        ),
      );
      expect(out.split('\n').length, 12);
    });

    test('handles empty series', () {
      final out = _render(20, 10, (s, a) {
        renderBarChart(
          s,
          a,
          BarChartProps(width: 20, height: 10, series: []),
        );
      });
      expect(out, isNotNull);
    });
  });

  // -------------------------------------------------------------------------
  // Area chart
  // -------------------------------------------------------------------------

  group('renderAreaChart', () {
    test('renders filled area', () {
      final out = renderChart(40, 12, (s, a) {
        renderAreaChart(
          s,
          a,
          AreaChartProps(
            width: 40,
            height: 12,
            series: [DataSeries(name: 'A', data: [1, 4, 2, 6, 3])],
          ),
        );
      });
      expect(out, contains('▒'));
    });

    test('stacked series fill to cumulative totals', () {
      final out = renderChart(40, 12, (s, a) {
        renderAreaChart(
          s,
          a,
          AreaChartProps(
            width: 40,
            height: 12,
            series: [
              DataSeries(name: 'A', data: [1, 2, 3]),
              DataSeries(name: 'B', data: [2, 1, 2]),
            ],
            stacked: true,
          ),
        );
      });
      expect(out, contains('▒'));
    });

    test('renders legend for multiple series', () {
      final out = renderChart(40, 12, (s, a) {
        renderAreaChart(
          s,
          a,
          AreaChartProps(
            width: 40,
            height: 12,
            series: [
              DataSeries(name: 'A', data: [1, 2, 3]),
              DataSeries(name: 'B', data: [3, 2, 1]),
            ],
          ),
        );
      });
      expect(out, contains('A'));
      expect(out, contains('B'));
    });

    test('createAreaChart returns multi-line string', () {
      final out = createAreaChart(
        AreaChartProps(
          width: 40,
          height: 12,
          series: [DataSeries(name: 'A', data: [1, 2, 3])],
        ),
      );
      expect(out.split('\n').length, 12);
    });
  });

  // -------------------------------------------------------------------------
  // Scatter chart
  // -------------------------------------------------------------------------

  group('renderScatterChart', () {
    test('renders points', () {
      final out = renderChart(40, 12, (s, a) {
        renderScatterChart(
          s,
          a,
          ScatterChartProps(
            width: 40,
            height: 12,
            points: const [
              ScatterPoint(x: 1, y: 2),
              ScatterPoint(x: 3, y: 5, color: '#E57373'),
              ScatterPoint(x: 5, y: 1),
            ],
          ),
        );
      });
      expect(out, contains('●'));
    });

    test('handles single point', () {
      final out = renderChart(40, 12, (s, a) {
        renderScatterChart(
          s,
          a,
          ScatterChartProps(
            width: 40,
            height: 12,
            points: const [ScatterPoint(x: 2, y: 3)],
          ),
        );
      });
      expect(out, contains('●'));
    });

    test('createScatterChart returns multi-line string', () {
      final out = createScatterChart(
        ScatterChartProps(
          width: 40,
          height: 12,
          points: const [ScatterPoint(x: 1, y: 2), ScatterPoint(x: 2, y: 3)],
        ),
      );
      expect(out.split('\n').length, 12);
    });

    test('handles empty points', () {
      final out = _render(20, 10, (s, a) {
        renderScatterChart(
          s,
          a,
          ScatterChartProps(width: 20, height: 10, points: const []),
        );
      });
      expect(out, isNotNull);
    });
  });

  // -------------------------------------------------------------------------
  // Gauge chart
  // -------------------------------------------------------------------------

  group('renderGaugeChart', () {
    test('renders arc, value and label', () {
      final out = renderChart(40, 12, (s, a) {
        renderGaugeChart(
          s,
          a,
          GaugeChartProps(width: 40, height: 12, value: 72, label: 'CPU'),
        );
      });
      final braillePattern = RegExp(r'[\u2800-\u28FF]');
      expect(braillePattern.hasMatch(out), isTrue);
      expect(out, contains('CPU'));
      expect(out, contains('72'));
    });

    test('renders threshold colors', () {
      final out = renderChart(40, 12, (s, a) {
        renderGaugeChart(
          s,
          a,
          GaugeChartProps(
            width: 40,
            height: 12,
            value: 90,
            thresholds: const [
              GaugeThreshold(value: 0.5, color: '#4CAF50'),
              GaugeThreshold(value: 1.0, color: '#F44336'),
            ],
          ),
        );
      });
      expect(out, isNotEmpty);
    });

    test('clamps value to min/max', () {
      final out = renderChart(40, 12, (s, a) {
        renderGaugeChart(
          s,
          a,
          GaugeChartProps(width: 40, height: 12, value: 200, max: 100),
        );
      });
      expect(out, contains('100'));
    });

    test('createGaugeChart returns multi-line string', () {
      final out = createGaugeChart(
        GaugeChartProps(width: 40, height: 12, value: 50),
      );
      expect(out.split('\n').length, 12);
    });
  });

  // -------------------------------------------------------------------------
  // Pie chart
  // -------------------------------------------------------------------------

  group('renderPieChart', () {
    test('renders slices and legend', () {
      final out = renderChart(40, 14, (s, a) {
        renderPieChart(
          s,
          a,
          PieChartProps(
            width: 40,
            height: 14,
            slices: const [
              PieSlice(label: 'A', value: 40, color: '#4FC3F7'),
              PieSlice(label: 'B', value: 30, color: '#81C784'),
              PieSlice(label: 'C', value: 30, color: '#FFB74D'),
            ],
          ),
        );
      });
      expect(out, contains('A'));
      expect(out, contains('B'));
      expect(out, contains('C'));
    });

    test('donut mode leaves center empty', () {
      final canvas = Canvas(30, 15);
      final area = Rectangle(minX: 0, minY: 0, maxX: 30, maxY: 15);
      renderPieChart(
        canvas,
        area,
        PieChartProps(
          width: 30,
          height: 15,
          slices: const [
            PieSlice(label: 'A', value: 50),
            PieSlice(label: 'B', value: 50),
          ],
          donut: true,
        ),
      );
      final center = canvas.cellAt(15, 7);
      if (center != null) {
        expect(center.content == ' ' || center.style.bg == null, isTrue);
      }
    });

    test('hides legend when disabled', () {
      final out = renderChart(40, 14, (s, a) {
        renderPieChart(
          s,
          a,
          PieChartProps(
            width: 40,
            height: 14,
            slices: const [PieSlice(label: 'Secret', value: 100)],
            legend: const LegendOptions(show: false),
          ),
        );
      });
      expect(out.contains('Secret'), isFalse);
    });

    test('createPieChart returns multi-line string', () {
      final out = createPieChart(
        PieChartProps(
          width: 40,
          height: 14,
          slices: const [PieSlice(label: 'A', value: 100)],
        ),
      );
      expect(out.split('\n').length, 14);
    });

    test('handles empty slices', () {
      final out = _render(20, 10, (s, a) {
        renderPieChart(
          s,
          a,
          PieChartProps(width: 20, height: 10, slices: const []),
        );
      });
      expect(out, isNotNull);
    });
  });

  // -------------------------------------------------------------------------
  // Heatmap chart
  // -------------------------------------------------------------------------

  group('renderHeatmapChart', () {
    test('renders grid cells', () {
      final out = renderChart(40, 12, (s, a) {
        renderHeatmapChart(
          s,
          a,
          HeatmapChartProps(
            width: 40,
            height: 12,
            data: [
              [1, 2, 3],
              [4, 5, 6],
              [7, 8, 9],
            ],
            showValues: true,
          ),
        );
      });
      expect(out, contains('1'));
      expect(out, contains('9'));
    });

    test('renders axis labels', () {
      final out = renderChart(40, 12, (s, a) {
        renderHeatmapChart(
          s,
          a,
          HeatmapChartProps(
            width: 40,
            height: 12,
            data: [
              [1, 2, 3],
              [4, 5, 6],
            ],
            xLabels: const ['A', 'B', 'C'],
            yLabels: const ['Low', 'High'],
          ),
        );
      });
      expect(out, contains('A'));
      expect(out, contains('High'));
    });

    test('uses custom colorScale', () {
      final out = renderChart(40, 12, (s, a) {
        renderHeatmapChart(
          s,
          a,
          HeatmapChartProps(
            width: 40,
            height: 12,
            data: [
              [1, 2, 3],
              [4, 5, 6],
            ],
            colorScale: const ['#FF0000', '#00FF00', '#0000FF'],
          ),
        );
      });
      expect(out, isNotEmpty);
    });

    test('handles uniform data', () {
      final out = renderChart(40, 12, (s, a) {
        renderHeatmapChart(
          s,
          a,
          HeatmapChartProps(
            width: 40,
            height: 12,
            data: [
              [5, 5],
              [5, 5],
            ],
          ),
        );
      });
      expect(out, isNotEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // Stacked bar chart
  // -------------------------------------------------------------------------

  group('renderStackedBarChart', () {
    test('renders stacked bars with labels', () {
      final out = renderChart(50, 14, (s, a) {
        renderStackedBarChart(
          s,
          a,
          StackedBarChartProps(
            width: 50,
            height: 14,
            series: const [
              DataSeries(name: 'Core', data: [10, 15, 12], color: '#4FC3F7'),
              DataSeries(name: 'Pro', data: [5, 8, 10], color: '#81C784'),
            ],
            labels: const ['Q1', 'Q2', 'Q3'],
          ),
        );
      });
      expect(out, contains('Q1'));
      expect(out, contains('Q3'));
    });

    test('renders legend for multiple series', () {
      final out = renderChart(50, 14, (s, a) {
        renderStackedBarChart(
          s,
          a,
          StackedBarChartProps(
            width: 50,
            height: 14,
            series: const [
              DataSeries(name: 'Core', data: [10, 15, 12], color: '#4FC3F7'),
              DataSeries(name: 'Pro', data: [5, 8, 10], color: '#81C784'),
              DataSeries(name: 'Ent', data: [3, 4, 6], color: '#FFB74D'),
            ],
          ),
        );
      });
      expect(out, contains('Core'));
      expect(out, contains('Ent'));
    });

    test('horizontal orientation renders bars', () {
      final out = renderChart(50, 14, (s, a) {
        renderStackedBarChart(
          s,
          a,
          StackedBarChartProps(
            width: 50,
            height: 14,
            series: const [
              DataSeries(name: 'A', data: [10, 15]),
              DataSeries(name: 'B', data: [5, 8]),
            ],
            orientation: ChartOrientation.horizontal,
          ),
        );
      });
      expect(out, isNotEmpty);
    });

    test('createStackedBarChart returns multi-line string', () {
      final out = createStackedBarChart(
        StackedBarChartProps(
          width: 50,
          height: 14,
          series: const [DataSeries(name: 'A', data: [1, 2, 3])],
        ),
      );
      expect(out.split('\n').length, 14);
    });

    test('handles empty series', () {
      final out = _render(20, 10, (s, a) {
        renderStackedBarChart(
          s,
          a,
          StackedBarChartProps(width: 20, height: 10, series: const []),
        );
      });
      expect(out, isNotNull);
    });
  });

  // -------------------------------------------------------------------------
  // Sparkline chart
  // -------------------------------------------------------------------------

  group('renderSparklineChart', () {
    test('line style renders continuous line', () {
      final out = renderChart(40, 3, (s, a) {
        renderSparklineChart(
          s,
          a,
          SparklineProps(
            width: 40,
            height: 3,
            data: [1, 3, 2, 5, 4, 6, 3],
            style: SparklineStyle.line,
            showMinMax: true,
          ),
        );
      });
      expect(out, isNotEmpty);
      expect(out, contains('1'));
      expect(out, contains('6'));
    });

    test('bar style renders vertical bars', () {
      final out = renderChart(40, 3, (s, a) {
        renderSparklineChart(
          s,
          a,
          SparklineProps(
            width: 40,
            height: 3,
            data: [1, 2, 3],
            style: SparklineStyle.bar,
          ),
        );
      });
      expect(out, isNotEmpty);
    });

    test('dot style renders dots', () {
      final out = renderChart(40, 3, (s, a) {
        renderSparklineChart(
          s,
          a,
          SparklineProps(
            width: 40,
            height: 3,
            data: [1, 2, 3],
            style: SparklineStyle.dot,
          ),
        );
      });
      expect(out, contains('●'));
    });

    test('handles uniform data', () {
      final out = renderChart(40, 3, (s, a) {
        renderSparklineChart(
          s,
          a,
          SparklineProps(width: 40, height: 3, data: [5, 5, 5, 5]),
        );
      });
      expect(out, isNotEmpty);
    });

    test('handles empty data', () {
      final out = _render(40, 3, (s, a) {
        renderSparklineChart(
          s,
          a,
          SparklineProps(width: 40, height: 3, data: []),
        );
      });
      expect(out, isNotNull);
    });
  });
}
