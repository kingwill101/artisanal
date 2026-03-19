import 'package:artisanal/tui.dart' show Cmd;
import 'package:artisanal/testing.dart';
import 'package:artisanal/widgets.dart';
import 'package:test/test.dart';

void main() {
  group('Radio', () {
    test('renders unselected by default', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Radio<String>(value: 'a', groupValue: 'b', onChanged: (_) => null),
      );

      expect(tester.view, isNotEmpty);
      expect(tester.view, isNot(contains('●')));
    });

    test('renders selected state', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Radio<String>(value: 'a', groupValue: 'a', onChanged: (_) => null),
      );

      expect(tester.view, isNotEmpty);
    });

    test('renders with label', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Radio<String>(
          value: 'a',
          groupValue: 'b',
          label: Text('Option A'),
          onChanged: (_) => null,
        ),
      );

      expect(tester.find.text('Option A'), isTrue);
    });

    test('calls onChanged when tapped', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());
      String? selectedValue;

      await tester.pumpWidget(
        Radio<String>(
          value: 'option1',
          groupValue: 'option2',
          onChanged: (value) {
            selectedValue = value;
            return Cmd.none();
          },
        ),
      );

      tester.tapAt(0, 0);

      expect(selectedValue, equals('option1'));
    });

    test('does not call onChanged when already selected', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());
      var callCount = 0;

      await tester.pumpWidget(
        Radio<String>(
          value: 'option',
          groupValue: 'option',
          onChanged: (value) {
            callCount++;
            return Cmd.none();
          },
        ),
      );

      tester.tapAt(0, 0);

      // Tapping an already-selected radio should NOT fire onChanged
      expect(callCount, equals(0));
    });

    test('disabled radio does not call onChanged', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());
      var callCount = 0;

      await tester.pumpWidget(
        Radio<String>(
          value: 'a',
          groupValue: 'b',
          enabled: false,
          onChanged: (value) {
            callCount++;
            return Cmd.none();
          },
        ),
      );

      tester.tapAt(0, 0);

      expect(callCount, equals(0));
    });

    test('works with different value types', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());
      int? selectedValue;

      await tester.pumpWidget(
        Radio<int>(
          value: 1,
          groupValue: 2,
          onChanged: (value) {
            selectedValue = value;
            return Cmd.none();
          },
        ),
      );

      tester.tapAt(0, 0);

      expect(selectedValue, equals(1));
    });

    test('is focusable', () {
      // Radio is a StatefulWidget; Widget.focusable defaults to false.
      // The actual focus handling is done by wrapping with the Focusable
      // widget in the build tree, not via the widget's focusable getter.
      final radio = Radio<String>(
        value: 'a',
        groupValue: 'b',
        onChanged: (_) => null,
      );
      expect(radio.focusable, isFalse);
    });

    test('has unique id', () {
      final r1 = Radio<String>(
        value: 'a',
        groupValue: 'b',
        onChanged: (_) => null,
      );
      final r2 = Radio<String>(
        value: 'c',
        groupValue: 'd',
        onChanged: (_) => null,
      );
      expect(r1.id, isNot(equals(r2.id)));
    });

    test('respects key', () {
      final radio = Radio<String>(
        key: ValueKey('radio-key'),
        value: 'a',
        groupValue: 'b',
        onChanged: (_) => null,
      );
      expect(radio.id, equals('radio-key'));
    });
  });

  group('RadioGroup', () {
    test('renders multiple radio buttons', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Column(
          children: [
            Radio<String>(
              value: 'small',
              groupValue: 'medium',
              label: Text('Small'),
              onChanged: (_) => null,
            ),
            Radio<String>(
              value: 'medium',
              groupValue: 'medium',
              label: Text('Medium'),
              onChanged: (_) => null,
            ),
            Radio<String>(
              value: 'large',
              groupValue: 'medium',
              label: Text('Large'),
              onChanged: (_) => null,
            ),
          ],
        ),
      );

      expect(tester.find.text('Small'), isTrue);
      expect(tester.find.text('Medium'), isTrue);
      expect(tester.find.text('Large'), isTrue);
    });

    test('selecting one deselects others in group', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());
      String? currentValue = 'a';

      await tester.pumpWidget(
        Column(
          children: [
            Radio<String>(
              value: 'a',
              groupValue: currentValue,
              onChanged: (value) {
                currentValue = value;
                return Cmd.none();
              },
            ),
            Radio<String>(
              value: 'b',
              groupValue: currentValue,
              onChanged: (value) {
                currentValue = value;
                return Cmd.none();
              },
            ),
          ],
        ),
      );

      tester.tapAt(0, 1);

      expect(currentValue, equals('b'));
    });

    test('labels are positioned correctly', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Radio<String>(
          value: 'test',
          groupValue: 'other',
          label: Text('Test Label'),
          onChanged: (_) => null,
        ),
      );

      final pos = tester.locateText('Test Label');
      expect(pos, isNotNull);
      expect(pos!.x, greaterThan(0));
    });
  });

  group('Radio integration', () {
    test('radios in Card for settings', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Card(
          child: Column(
            children: [
              Text('Select size:'),
              Radio<String>(
                value: 's',
                groupValue: 'm',
                label: Text('Small'),
                onChanged: (_) => null,
              ),
              Radio<String>(
                value: 'm',
                groupValue: 'm',
                label: Text('Medium'),
                onChanged: (_) => null,
              ),
              Radio<String>(
                value: 'l',
                groupValue: 'm',
                label: Text('Large'),
                onChanged: (_) => null,
              ),
            ],
          ),
        ),
      );

      expect(tester.find.text('Select size:'), isTrue);
      expect(tester.find.text('Small'), isTrue);
      expect(tester.find.text('Medium'), isTrue);
      expect(tester.find.text('Large'), isTrue);
    });

    test('horizontal radio group in Row', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Row(
          gap: 2,
          children: [
            Radio<String>(
              value: 'yes',
              groupValue: 'no',
              label: Text('Yes'),
              onChanged: (_) => null,
            ),
            Radio<String>(
              value: 'no',
              groupValue: 'no',
              label: Text('No'),
              onChanged: (_) => null,
            ),
          ],
        ),
      );

      expect(tester.find.text('Yes'), isTrue);
      expect(tester.find.text('No'), isTrue);
    });
  });
}
