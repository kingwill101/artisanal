import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:test/test.dart';

void main() {
  group('CheckboxListTile', () {
    test('renders title and checked control', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        CheckboxListTile(
          value: true,
          title: 'Enable feature',
          onChanged: (_) {
            return null;
          },
        ),
      );

      expect(tester.find.text('Enable feature'), isTrue);
      expect(tester.find.text('[x]'), isTrue);
    });

    test('tile tap toggles value', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      bool? nextValue;
      await tester.pumpWidget(
        CheckboxListTile(
          value: false,
          title: 'Tap toggle',
          onChanged: (value) {
            nextValue = value;
            return null;
          },
        ),
      );

      final loc = tester.locateText('Tap toggle');
      expect(loc, isNotNull);
      tester.tapAt(loc!.x, loc.y);
      expect(nextValue, isTrue);
    });

    test('trailing control affinity places checkbox after title', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        CheckboxListTile(
          value: false,
          title: 'Trailing checkbox',
          onChanged: (_) {
            return null;
          },
          controlAffinity: ListTileControlAffinity.trailing,
        ),
      );

      final titleLoc = tester.locateText('Trailing checkbox');
      final controlLoc = tester.locateText('[ ]');
      expect(titleLoc, isNotNull);
      expect(controlLoc, isNotNull);
      expect(controlLoc!.x, greaterThan(titleLoc!.x));
    });
  });

  group('SwitchListTile', () {
    test('renders title and switch state', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        SwitchListTile(
          value: true,
          title: 'Dark mode',
          onChanged: (_) {
            return null;
          },
        ),
      );

      expect(tester.find.text('Dark mode'), isTrue);
      expect(tester.find.text('[ON]'), isTrue);
    });

    test('tile tap toggles value', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      bool? nextValue;
      await tester.pumpWidget(
        SwitchListTile(
          value: false,
          title: 'Notifications',
          onChanged: (value) {
            nextValue = value;
            return null;
          },
        ),
      );

      final loc = tester.locateText('Notifications');
      expect(loc, isNotNull);
      tester.tapAt(loc!.x, loc.y);
      expect(nextValue, isTrue);
    });
  });

  group('RadioListTile', () {
    test('renders selected state from groupValue', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        RadioListTile<String>(
          value: 'a',
          groupValue: 'a',
          title: 'Option A',
          onChanged: (_) {
            return null;
          },
        ),
      );

      expect(tester.find.text('Option A'), isTrue);
      expect(tester.find.text('(*)'), isTrue);
    });

    test('tile tap selects unselected value', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      String? selected;
      await tester.pumpWidget(
        RadioListTile<String>(
          value: 'b',
          groupValue: 'a',
          title: 'Option B',
          onChanged: (value) {
            selected = value;
            return null;
          },
        ),
      );

      final loc = tester.locateText('Option B');
      expect(loc, isNotNull);
      tester.tapAt(loc!.x, loc.y);
      expect(selected, equals('b'));
    });

    test('tile tap does not re-select currently selected value', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      var callbackCount = 0;
      await tester.pumpWidget(
        RadioListTile<String>(
          value: 'a',
          groupValue: 'a',
          title: 'Already selected',
          onChanged: (value) {
            callbackCount++;
            return null;
          },
        ),
      );

      final loc = tester.locateText('Already selected');
      expect(loc, isNotNull);
      tester.tapAt(loc!.x, loc.y);
      expect(callbackCount, equals(0));
    });
  });
}
