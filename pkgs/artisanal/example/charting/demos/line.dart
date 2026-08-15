// Line chart demo.
//
// Run: dart run example/charting/demos/line.dart
import 'package:artisanal/artisanal.dart';

void main() {
  final chart = createLineChart(
    LineChartProps(
      width: 60,
      height: 16,
      title: 'Line Chart — Monthly Revenue',
      series: const [
        DataSeries(
          name: 'Revenue',
          data: [12, 28, 35, 47, 42, 55, 63, 58, 71, 80, 74, 92],
          color: '#4FC3F7',
        ),
        DataSeries(
          name: 'Costs',
          data: [8, 15, 22, 30, 35, 32, 40, 45, 50, 48, 52, 60],
          color: '#E57373',
        ),
      ],
      showDots: true,
      grid: GridOptions(show: true),
      backgroundColor: '#0D1117',
    ),
  );
  print(chart);
}
