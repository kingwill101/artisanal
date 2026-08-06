import 'package:artisanal_charts/artisanal_charts.dart';

void main() {
  final chart = createAreaChart(
    AreaChartProps(
      width: 60,
      height: 14,
      title: 'Area Chart — Traffic',
      series: const [
        DataSeries(
          name: 'Organic',
          data: [10, 15, 20, 25, 30, 28, 35],
          color: '#4FC3F7',
        ),
        DataSeries(
          name: 'Paid',
          data: [5, 8, 12, 10, 15, 18, 20],
          color: '#81C784',
        ),
      ],
      stacked: true,
      grid: GridOptions(show: true),
      backgroundColor: '#0D1117',
    ),
  );
  print(chart.render());
}
