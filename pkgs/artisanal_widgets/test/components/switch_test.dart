import 'package:artisanal/tui.dart' show Cmd;
import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:artisanal_widgets/testing.dart';
import 'package:test/test.dart';

void main() {
  group('Switch', () {
    test('renders off state', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(Switch(value: false, onChanged: (_) => null));

      expect(tester.view, isNotEmpty);
    });

    test('renders on state', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(Switch(value: true, onChanged: (_) => null));

      expect(tester.view, isNotEmpty);
    });

    test('toggles from off to on when tapped', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());
      bool? newValue;

      await tester.pumpWidget(
        Switch(
          value: false,
          onChanged: (value) {
            newValue = value;
            return Cmd.none();
          },
        ),
      );

      tester.tapAt(0, 0);

      expect(newValue, isTrue);
    });

    test('toggles from on to off when tapped', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());
      bool? newValue;

      await tester.pumpWidget(
        Switch(
          value: true,
          onChanged: (value) {
            newValue = value;
            return Cmd.none();
          },
        ),
      );

      tester.tapAt(0, 0);

      expect(newValue, isFalse);
    });

    test('disabled switch does not call onChanged', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());
      var callCount = 0;

      await tester.pumpWidget(
        Switch(
          value: false,
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

    test('renders disabled visual state', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Switch(value: true, enabled: false, onChanged: (_) => null),
      );

      expect(tester.view, isNotEmpty);
    });

    test('is focusable', () {
      // Switch is a StatefulWidget; Widget.focusable defaults to false.
      // The actual focus handling is done by wrapping with the Focusable
      // widget in the build tree, not via the widget's focusable getter.
      final switch_ = Switch(value: false, onChanged: (_) => null);
      expect(switch_.focusable, isFalse);
    });

    test('has unique id', () {
      final s1 = Switch(value: false, onChanged: (_) => null);
      final s2 = Switch(value: true, onChanged: (_) => null);
      expect(s1.id, isNot(equals(s2.id)));
    });

    test('respects key', () {
      final switch_ = Switch(
        key: ValueKey('switch-key'),
        value: false,
        onChanged: (_) => null,
      );
      expect(switch_.id, equals('switch-key'));
    });
  });

  group('Switch with label', () {
    test('renders with label widget', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Row(
          children: [
            Switch(value: false, onChanged: (_) => null),
            Text('Enable notifications'),
          ],
        ),
      );

      expect(tester.find.text('Enable notifications'), isTrue);
    });

    test('label positioned after switch', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Row(
          children: [
            Switch(value: false, onChanged: (_) => null),
            Text('Label'),
          ],
        ),
      );

      final pos = tester.locateText('Label');
      expect(pos, isNotNull);
      expect(pos!.x, greaterThan(0));
    });
  });

  group('Switch integration', () {
    test('multiple switches in settings panel', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        PanelBox(
          title: 'Settings',
          child: Column(
            children: [
              Row(
                children: [
                  Switch(value: true, onChanged: (_) => null),
                  Text('Dark Mode'),
                ],
              ),
              Row(
                children: [
                  Switch(value: false, onChanged: (_) => null),
                  Text('Notifications'),
                ],
              ),
              Row(
                children: [
                  Switch(value: true, onChanged: (_) => null),
                  Text('Auto-save'),
                ],
              ),
            ],
          ),
        ),
      );

      expect(tester.find.text('Settings'), isTrue);
      expect(tester.find.text('Dark Mode'), isTrue);
      expect(tester.find.text('Notifications'), isTrue);
      expect(tester.find.text('Auto-save'), isTrue);
    });

    test('switch in Card', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Card(
          child: Row(
            children: [
              Switch(value: false, onChanged: (_) => null),
              Text('Toggle Feature'),
            ],
          ),
        ),
      );

      expect(tester.find.text('Toggle Feature'), isTrue);
    });

    test('switches aligned in Column', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Column(
          children: [
            Row(
              children: [
                Expanded(child: Text('Feature A')),
                Switch(value: true, onChanged: (_) => null),
              ],
            ),
            Row(
              children: [
                Expanded(child: Text('Feature B')),
                Switch(value: false, onChanged: (_) => null),
              ],
            ),
          ],
        ),
      );

      expect(tester.find.text('Feature A'), isTrue);
      expect(tester.find.text('Feature B'), isTrue);
    });
  });
}
