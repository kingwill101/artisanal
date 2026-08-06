import 'package:artisanal_charts/artisanal_charts.dart';

void main() {
  final chart = createGaugeChart(
    GaugeChartProps(
      width: 40,
      height: 12,
      title: 'Gauge — CPU',
      value: 72,
      min: 0,
      max: 100,
      label: 'CPU %',
      backgroundColor: '#0D1117',
    ),
  );
  print(chart.render());
}
