// Scatter chart demo.
//
// Run: dart run example/charting/demos/scatter.dart
import 'package:artisanal/artisanal.dart';

void main() {
  final chart = createScatterChart(
    ScatterChartProps(
      width: 50,
      height: 14,
      title: 'Scatter — Correlation',
      points: const [
        ScatterPoint(x: 1, y: 2),
        ScatterPoint(x: 2, y: 3.5),
        ScatterPoint(x: 3, y: 3),
        ScatterPoint(x: 4, y: 5),
        ScatterPoint(x: 5, y: 4.5, color: '#E57373'),
        ScatterPoint(x: 6, y: 7),
        ScatterPoint(x: 7, y: 6.5),
        ScatterPoint(x: 8, y: 8),
      ],
      grid: GridOptions(show: true),
      backgroundColor: '#0D1117',
    ),
  );
  print(chart);
}
