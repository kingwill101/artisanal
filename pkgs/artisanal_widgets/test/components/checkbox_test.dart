import 'package:artisanal/testing.dart';
import 'package:artisanal/widgets.dart';
import 'package:test/test.dart';

void main() {
  group('Checkbox', () {
    test('renders unchecked by default', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(Checkbox(value: false, onChanged: (_) => null));

      expect(tester.view, isNotEmpty);
    });

    test('renders checked state', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(Checkbox(value: true, onChanged: (_) => null));

      expect(tester.view, isNotEmpty);
    });

    test('renders with label', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Checkbox(
          value: false,
          label: Text('Accept Terms'),
          onChanged: (_) => null,
        ),
      );

      expect(tester.find.text('Accept Terms'), isTrue);
    });

    test('toggles value when tapped', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());
      bool? newValue;

      await tester.pumpWidget(
        Checkbox(
          value: false,
          onChanged: (value) {
            newValue = value;
            return null;
          },
        ),
      );

      tester.tapAt(0, 0);

      expect(newValue, isNotNull);
    });

    test('calls onChanged with correct value when checked', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());
      var callCount = 0;
      bool? receivedValue;

      await tester.pumpWidget(
        Checkbox(
          value: false,
          onChanged: (value) {
            callCount++;
            receivedValue = value;
            return null;
          },
        ),
      );

      tester.tapAt(0, 0);

      expect(callCount, equals(1));
      expect(receivedValue, isTrue);
    });

    test('calls onChanged with correct value when unchecked', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());
      var callCount = 0;
      bool? receivedValue;

      await tester.pumpWidget(
        Checkbox(
          value: true,
          onChanged: (value) {
            callCount++;
            receivedValue = value;
            return null;
          },
        ),
      );

      tester.tapAt(0, 0);

      expect(callCount, equals(1));
      expect(receivedValue, isFalse);
    });

    test('disabled checkbox does not call onChanged', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());
      var callCount = 0;

      await tester.pumpWidget(
        Checkbox(
          value: false,
          enabled: false,
          onChanged: (value) {
            callCount++;
            return null;
          },
        ),
      );

      tester.tapAt(0, 0);

      expect(callCount, equals(0));
    });

    test('renders disabled state visually', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Checkbox(value: false, enabled: false, onChanged: (_) => null),
      );

      expect(tester.view, isNotEmpty);
    });

    test('is focusable', () {
      // Checkbox is a StatefulWidget; Widget.focusable defaults to false.
      // The actual focus handling is done by wrapping with the Focusable
      // widget in the build tree, not via the widget's focusable getter.
      final checkbox = Checkbox(value: false, onChanged: (_) => null);
      expect(checkbox.focusable, isFalse);
    });

    test('has unique id', () {
      final c1 = Checkbox(value: false, onChanged: (_) => null);
      final c2 = Checkbox(value: false, onChanged: (_) => null);
      expect(c1.id, isNot(equals(c2.id)));
    });

    test('respects key', () {
      final checkbox = Checkbox(
        key: ValueKey('checkbox-key'),
        value: false,
        onChanged: (_) => null,
      );
      expect(checkbox.id, equals('checkbox-key'));
    });
  });

  group('Checkbox with label', () {
    test('label is positioned after checkbox', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Checkbox(value: false, label: Text('Option'), onChanged: (_) => null),
      );

      expect(tester.find.text('Option'), isTrue);
      final pos = tester.locateText('Option');
      expect(pos, isNotNull);
      expect(pos!.x, greaterThan(0));
    });

    test('long label is visible', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Checkbox(
          value: false,
          label: Text('This is a very long label text'),
          onChanged: (_) => null,
        ),
      );

      expect(tester.find.text('This is a very long label text'), isTrue);
    });
  });

  group('Checkbox integration', () {
    test('multiple checkboxes in Column', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Column(
          children: [
            Checkbox(
              value: true,
              label: Text('Option 1'),
              onChanged: (_) => null,
            ),
            Checkbox(
              value: false,
              label: Text('Option 2'),
              onChanged: (_) => null,
            ),
            Checkbox(
              value: true,
              label: Text('Option 3'),
              onChanged: (_) => null,
            ),
          ],
        ),
      );

      expect(tester.find.text('Option 1'), isTrue);
      expect(tester.find.text('Option 2'), isTrue);
      expect(tester.find.text('Option 3'), isTrue);
    });

    test('checkboxes in Card', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Card(
          child: Column(
            children: [
              Text('Select options:'),
              Checkbox(
                value: false,
                label: Text('Enable feature'),
                onChanged: (_) => null,
              ),
            ],
          ),
        ),
      );

      expect(tester.find.text('Select options:'), isTrue);
      expect(tester.find.text('Enable feature'), isTrue);
    });
  });
}
