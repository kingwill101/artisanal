// Donut pie chart demo.
//
// Run: dart run example/charting/demos/pie.dart
import 'package:artisanal/artisanal.dart';

void main() {
  final chart = createPieChart(
    PieChartProps(
      width: 50,
      height: 16,
      title: 'Pie Chart — Market Share',
      slices: const [
        PieSlice(label: 'Alpha', value: 35, color: '#4FC3F7'),
        PieSlice(label: 'Beta', value: 25, color: '#81C784'),
        PieSlice(label: 'Gamma', value: 20, color: '#FFB74D'),
        PieSlice(label: 'Delta', value: 20, color: '#E57373'),
      ],
      donut: true,
      backgroundColor: '#0D1117',
    ),
  );
  print(chart);
}
