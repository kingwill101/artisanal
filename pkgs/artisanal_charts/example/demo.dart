// Dashboard demo with four charts (port of opentui-charts demo.ts).
//
// Run: dart run example/demo.dart
import 'package:artisanal_charts/artisanal_charts.dart';

void main() {
  const w = 48;
  const h = 14;

  final line = createLineChart(
    LineChartProps(
      width: w,
      height: h,
      title: 'Line — Monthly Revenue',
      series: const [
        DataSeries(name: '2025', data: [28, 47, 47, 40, 38, 35], color: '#4FC3F7'),
        DataSeries(name: '2026', data: [32, 41, 55, 62, 58, 70], color: '#81C784'),
      ],
      showDots: true,
      grid: GridOptions(show: true, style: GridStyle.dotted),
      legend: LegendOptions(show: true),
      backgroundColor: '#111122',
    ),
  );

  final bar = createBarChart(
    BarChartProps(
      width: w,
      height: h,
      title: 'Bar — Units Sold',
      series: const [
        DataSeries(name: 'North', data: [40, 55, 48, 70], color: '#4FC3F7'),
        DataSeries(name: 'South', data: [30, 45, 52, 60], color: '#FFB74D'),
      ],
      labels: const ['Q1', 'Q2', 'Q3', 'Q4'],
      grouped: true,
      grid: GridOptions(show: true),
      legend: LegendOptions(show: true),
      backgroundColor: '#111122',
    ),
  );

  final pie = createPieChart(
    PieChartProps(
      width: w,
      height: h,
      title: 'Pie — Share',
      slices: const [
        PieSlice(label: 'Product A', value: 40, color: '#4FC3F7'),
        PieSlice(label: 'Product B', value: 25, color: '#81C784'),
        PieSlice(label: 'Product C', value: 20, color: '#FFB74D'),
        PieSlice(label: 'Other', value: 15, color: '#E57373'),
      ],
      donut: true,
      backgroundColor: '#111122',
    ),
  );

  final gauge = createGaugeChart(
    GaugeChartProps(
      width: w,
      height: h,
      title: 'Gauge — Load',
      value: 68,
      label: 'System Load',
      backgroundColor: '#111122',
    ),
  );

  print('  📊 Artisanal Charts Demo\n');
  _printSideBySide(line.renderLines(), bar.renderLines());
  print('');
  _printSideBySide(pie.renderLines(), gauge.renderLines());
}

void _printSideBySide(List<String> left, List<String> right) {
  final rows = left.length > right.length ? left.length : right.length;
  for (var i = 0; i < rows; i++) {
    final l = i < left.length ? left[i] : '';
    final r = i < right.length ? right[i] : '';
    print('$l  $r');
  }
}
