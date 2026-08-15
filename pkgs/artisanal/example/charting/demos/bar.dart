// Bar chart demo.
//
// Run: dart run example/charting/demos/bar.dart
import 'package:artisanal/artisanal.dart';

void main() {
  final chart = createBarChart(
    BarChartProps(
      width: 60,
      height: 14,
      title: 'Bar Chart — Quarterly Sales',
      series: const [
        DataSeries(name: '2025', data: [40, 55, 48, 70], color: '#4FC3F7'),
        DataSeries(name: '2026', data: [45, 60, 58, 80], color: '#81C784'),
      ],
      labels: const ['Q1', 'Q2', 'Q3', 'Q4'],
      grouped: true,
      grid: GridOptions(show: true),
      backgroundColor: '#0D1117',
    ),
  );
  print(chart);
}
