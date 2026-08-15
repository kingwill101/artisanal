// Sparkline demo.
//
// Run: dart run example/charting/demos/sparkline.dart
import 'package:artisanal/artisanal.dart';

void main() {
  final chart = createSparkline(
    SparklineProps(
      width: 50,
      height: 4,
      title: 'Sparkline',
      data: const [12, 18, 15, 22, 30, 28, 35, 40, 38, 45, 42, 50],
      color: '#4FC3F7',
      style: SparklineStyle.line,
      showMinMax: true,
      backgroundColor: '#0D1117',
    ),
  );
  print(chart);
}
