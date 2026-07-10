import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:test/test.dart';

void main() {
  group('MetricDisplay', () {
    test('renders label and value', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(MetricDisplay(label: 'CPU Usage', value: '42'));

      expect(tester.find.text('CPU Usage'), isTrue);
      expect(tester.find.text('42'), isTrue);
    });

    test('renders value with unit suffix', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        MetricDisplay(label: 'Memory', value: '256', unit: 'MB'),
      );

      expect(tester.find.text('Memory'), isTrue);
      expect(tester.find.text('256MB'), isTrue);
    });

    test('renders without unit when unit is null', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(MetricDisplay(label: 'Count', value: '7'));

      expect(tester.find.text('7'), isTrue);
    });

    test('renders up trend indicator', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        MetricDisplay(label: 'Price', value: '100', trend: MetricTrend.up),
      );

      expect(tester.find.text('▲'), isTrue);
    });

    test('renders down trend indicator', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        MetricDisplay(label: 'Errors', value: '3', trend: MetricTrend.down),
      );

      expect(tester.find.text('▼'), isTrue);
    });

    test('renders flat trend indicator', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        MetricDisplay(
          label: 'Latency',
          value: '50',
          unit: 'ms',
          trend: MetricTrend.flat,
        ),
      );

      expect(tester.find.text('─'), isTrue);
    });

    test('no trend indicator when trend is null', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(MetricDisplay(label: 'Simple', value: '10'));

      expect(tester.find.text('▲'), isFalse);
      expect(tester.find.text('▼'), isFalse);
    });

    test('label appears before value horizontally', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        MetricDisplay(label: 'CPU', value: '99', unit: '%'),
      );

      final labelLoc = tester.locateText('CPU');
      final valueLoc = tester.locateText('99%');
      expect(labelLoc, isNotNull);
      expect(valueLoc, isNotNull);
      // Label should be to the left of the value (same row, lower x).
      expect(labelLoc!.x, lessThan(valueLoc!.x));
    });

    test('trend indicator appears after value', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        MetricDisplay(label: 'Speed', value: '60', trend: MetricTrend.up),
      );

      final valueLoc = tester.locateText('60');
      final trendLoc = tester.locateText('▲');
      expect(valueLoc, isNotNull);
      expect(trendLoc, isNotNull);
      expect(trendLoc!.x, greaterThan(valueLoc!.x));
    });

    test('MetricTrend enum has 3 values', () {
      expect(MetricTrend.values, hasLength(3));
      expect(MetricTrend.values, contains(MetricTrend.up));
      expect(MetricTrend.values, contains(MetricTrend.down));
      expect(MetricTrend.values, contains(MetricTrend.flat));
    });

    test('has unique id', () {
      final m1 = MetricDisplay(label: 'A', value: '1');
      final m2 = MetricDisplay(label: 'A', value: '1');
      expect(m1.id, isNot(equals(m2.id)));
    });

    test('respects key', () {
      final m = MetricDisplay(
        key: ValueKey('metric-key'),
        label: 'A',
        value: '1',
      );
      expect(m.id, equals('metric-key'));
    });
  });
}
