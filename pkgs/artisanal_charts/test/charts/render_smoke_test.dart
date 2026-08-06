import 'package:artisanal_charts/artisanal_charts.dart';
import 'package:test/test.dart';

void main() {
  group('render smoke tests', () {
    test('line chart', () {
      final surface = createLineChart(
        LineChartProps(
          width: 40,
          height: 12,
          title: 'Line',
          series: [
            DataSeries(name: 'A', data: [1, 3, 2, 5, 4], color: '#4FC3F7'),
            DataSeries(name: 'B', data: [2, 2, 4, 3, 6], color: '#81C784'),
          ],
          showDots: true,
          grid: const GridOptions(show: true),
        ),
      );
      final out = surface.render();
      expect(out, isNotEmpty);
      expect(surface.renderLines().length, greaterThanOrEqualTo(1));
    });

    test('bar chart', () {
      final surface = createBarChart(
        BarChartProps(
          width: 40,
          height: 12,
          series: [
            DataSeries(name: 'Sales', data: [10, 20, 15, 30]),
          ],
          labels: const ['Q1', 'Q2', 'Q3', 'Q4'],
        ),
      );
      expect(surface.render(), isNotEmpty);
    });

    test('pie chart', () {
      final surface = createPieChart(
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
      expect(surface.render(), isNotEmpty);
    });

    test('scatter chart', () {
      final surface = createScatterChart(
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
      expect(surface.render(), isNotEmpty);
    });

    test('area chart', () {
      final surface = createAreaChart(
        AreaChartProps(
          width: 40,
          height: 12,
          series: [
            DataSeries(name: 'A', data: [1, 4, 2, 6, 3]),
          ],
        ),
      );
      expect(surface.render(), isNotEmpty);
    });

    test('stacked bar chart', () {
      final surface = createStackedBarChart(
        StackedBarChartProps(
          width: 40,
          height: 12,
          series: [
            DataSeries(name: 'A', data: [1, 2, 3]),
            DataSeries(name: 'B', data: [2, 1, 2]),
          ],
        ),
      );
      expect(surface.render(), isNotEmpty);
    });

    test('heatmap chart', () {
      final surface = createHeatmapChart(
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
      expect(surface.render(), isNotEmpty);
    });

    test('gauge chart', () {
      final surface = createGaugeChart(
        GaugeChartProps(
          width: 40,
          height: 12,
          value: 72,
          label: 'CPU',
        ),
      );
      expect(surface.render(), isNotEmpty);
    });

    test('sparkline', () {
      final surface = createSparkline(
        SparklineProps(
          width: 40,
          height: 3,
          data: [1, 3, 2, 5, 4, 6, 3],
          style: SparklineStyle.line,
          showMinMax: true,
        ),
      );
      expect(surface.render(), isNotEmpty);
    });

    test('update re-renders', () {
      final props = LineChartProps(
        width: 30,
        height: 10,
        series: [DataSeries(name: 'x', data: [1, 2, 3])],
      );
      final surface = createLineChart(props);
      final first = surface.render();
      updateLineChart(
        surface,
        LineChartProps(
          width: 30,
          height: 10,
          series: [DataSeries(name: 'x', data: [9, 8, 7, 6])],
        ),
      );
      final second = surface.render();
      expect(first, isNotEmpty);
      expect(second, isNotEmpty);
    });
  });
}
