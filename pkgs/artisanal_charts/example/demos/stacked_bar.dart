import 'package:artisanal_charts/artisanal_charts.dart';

void main() {
  final chart = createStackedBarChart(
    StackedBarChartProps(
      width: 50,
      height: 14,
      title: 'Stacked Bar — Stack Mix',
      series: const [
        DataSeries(name: 'Core', data: [10, 15, 12, 18], color: '#4FC3F7'),
        DataSeries(name: 'Pro', data: [5, 8, 10, 12], color: '#81C784'),
        DataSeries(name: 'Ent', data: [3, 4, 6, 8], color: '#FFB74D'),
      ],
      labels: const ['Q1', 'Q2', 'Q3', 'Q4'],
      grid: GridOptions(show: true),
      backgroundColor: '#0D1117',
    ),
  );
  print(chart.render());
}
