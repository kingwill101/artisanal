import 'package:artisanal/terminal.dart' show KeyType;
import 'package:artisanal/testing.dart';
import 'package:artisanal/widgets.dart';
import 'package:test/test.dart';

void main() {
  group('Slider', () {
    test('tap emits a new value', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());
      double? changed;

      await tester.pumpWidget(
        Slider(
          value: 0.0,
          width: 11,
          onChanged: (value) {
            changed = value;
            return null;
          },
        ),
      );

      tester.tapAt(10, 0);
      expect(changed, isNotNull);
      expect(changed!, greaterThan(0.8));
    });
  });

  group('RangeSlider', () {
    test('tap updates nearest thumb', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());
      RangeValues? changed;

      await tester.pumpWidget(
        RangeSlider(
          values: RangeValues(0.3, 0.7),
          width: 11,
          onChanged: (values) {
            changed = values;
            return null;
          },
        ),
      );

      tester.tapAt(0, 0);
      expect(changed, isNotNull);
      expect(changed!.start, lessThan(0.3));
      expect(changed!.end, closeTo(0.7, 1e-6));
    });

    test('keyboard controls active thumb', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());
      RangeValues? changed;

      await tester.pumpWidget(
        RangeSlider(
          autofocus: true,
          values: RangeValues(0.2, 0.8),
          divisions: 10,
          onChanged: (values) {
            changed = values;
            return null;
          },
        ),
      );

      tester.sendSpecialKey(KeyType.right);
      expect(changed, isNotNull);
      expect(changed!.start, greaterThan(0.2));
    });
  });
}
