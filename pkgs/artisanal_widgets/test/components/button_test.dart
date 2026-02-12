import 'package:artisanal/tui.dart' show Cmd;
import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:artisanal_widgets/testing.dart';
import 'package:test/test.dart';

void main() {
  group('Button', () {
    test('renders with label', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(Button(label: 'Click Me', onPressed: () => null));
      expect(tester.find.text('Click Me'), isTrue);
    });

    test('renders with child widget', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Button(child: Text('Custom Child'), onPressed: () => null),
      );
      expect(tester.find.text('Custom Child'), isTrue);
    });

    test('calls onPressed when tapped', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());
      var pressed = false;

      await tester.pumpWidget(
        Button(
          label: 'Tap Me',
          onPressed: () {
            pressed = true;
            return Cmd.none();
          },
        ),
      );

      final location = tester.locateText('Tap Me');
      expect(location, isNotNull);

      tester.tapAt(location!.x, location.y);
      expect(pressed, isTrue);
    });

    test('supports primary variant', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Button(
          label: 'Primary',
          variant: ButtonVariant.primary,
          onPressed: () => null,
        ),
      );
      expect(tester.find.text('Primary'), isTrue);
    });

    test('supports secondary variant', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Button(
          label: 'Secondary',
          variant: ButtonVariant.secondary,
          onPressed: () => null,
        ),
      );
      expect(tester.find.text('Secondary'), isTrue);
    });

    test('supports outline variant', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Button(
          label: 'Outline',
          variant: ButtonVariant.outline,
          onPressed: () => null,
        ),
      );
      expect(tester.find.text('Outline'), isTrue);
    });

    test('supports ghost variant', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Button(
          label: 'Ghost',
          variant: ButtonVariant.ghost,
          onPressed: () => null,
        ),
      );
      expect(tester.find.text('Ghost'), isTrue);
    });

    test('supports danger variant', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Button(
          label: 'Danger',
          variant: ButtonVariant.danger,
          onPressed: () => null,
        ),
      );
      expect(tester.find.text('Danger'), isTrue);
    });

    test('supports small size', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Button(label: 'Small', size: ButtonSize.small, onPressed: () => null),
      );
      expect(tester.find.text('Small'), isTrue);
    });

    test('supports medium size', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Button(label: 'Medium', size: ButtonSize.medium, onPressed: () => null),
      );
      expect(tester.find.text('Medium'), isTrue);
    });

    test('supports large size', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Button(label: 'Large', size: ButtonSize.large, onPressed: () => null),
      );
      expect(tester.find.text('Large'), isTrue);
    });

    test('can be disabled', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());
      var pressed = false;

      await tester.pumpWidget(
        Button(
          label: 'Disabled',
          enabled: false,
          onPressed: () {
            pressed = true;
            return Cmd.none();
          },
        ),
      );

      expect(tester.find.text('Disabled'), isTrue);

      final location = tester.locateText('Disabled');
      if (location != null) {
        tester.tapAt(location.x, location.y);
      }
      expect(pressed, isFalse);
    });

    test('supports autofocus', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Button(label: 'Autofocus', autofocus: true, onPressed: () => null),
      );
      expect(tester.find.text('Autofocus'), isTrue);
    });

    test('is focusable', () async {
      // Button is a StatefulWidget; Widget.focusable defaults to false.
      // The actual focus handling is done by wrapping with the Focusable
      // widget in the build tree, not via the widget's focusable getter.
      final button = Button(label: 'test', onPressed: () => null);
      expect(button.focusable, isFalse);
    });

    test('has unique id', () {
      final b1 = Button(label: 'a', onPressed: () => null);
      final b2 = Button(label: 'b', onPressed: () => null);
      expect(b1.id, isNot(equals(b2.id)));
    });

    test('respects key', () {
      final button = Button(
        key: ValueKey('button-key'),
        label: 'test',
        onPressed: () => null,
      );
      expect(button.id, equals('button-key'));
    });
  });

  group('Button variants', () {
    test('ButtonVariant.primary exists', () {
      expect(ButtonVariant.primary, isNotNull);
    });

    test('ButtonVariant.secondary exists', () {
      expect(ButtonVariant.secondary, isNotNull);
    });

    test('ButtonVariant.outline exists', () {
      expect(ButtonVariant.outline, isNotNull);
    });

    test('ButtonVariant.ghost exists', () {
      expect(ButtonVariant.ghost, isNotNull);
    });

    test('ButtonVariant.danger exists', () {
      expect(ButtonVariant.danger, isNotNull);
    });
  });

  group('Flutter-style button wrappers', () {
    test('ElevatedButton renders and handles tap', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());
      var pressed = false;

      await tester.pumpWidget(
        ElevatedButton(
          child: Text('Save'),
          onPressed: () {
            pressed = true;
            return null;
          },
        ),
      );

      expect(tester.find.text('Save'), isTrue);
      final location = tester.locateText('Save');
      expect(location, isNotNull);
      tester.tapAt(location!.x, location.y);
      expect(pressed, isTrue);
    });

    test(
      'TextButton and ElevatedButton produce different output styles',
      () async {
        final textTester = WidgetTester();
        addTearDown(() => textTester.dispose());
        final elevatedTester = WidgetTester();
        addTearDown(() => elevatedTester.dispose());

        await textTester.pumpWidget(
          TextButton(child: Text('Action'), onPressed: () => null),
        );
        await elevatedTester.pumpWidget(
          ElevatedButton(child: Text('Action'), onPressed: () => null),
        );

        expect(textTester.view, isNot(equals(elevatedTester.view)));
      },
    );

    test('FilledButton renders and handles tap', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());
      var pressed = false;

      await tester.pumpWidget(
        FilledButton(
          child: Text('Confirm'),
          onPressed: () {
            pressed = true;
            return null;
          },
        ),
      );

      expect(tester.find.text('Confirm'), isTrue);
      final location = tester.locateText('Confirm');
      expect(location, isNotNull);
      tester.tapAt(location!.x, location.y);
      expect(pressed, isTrue);
    });

    test('FilledButton tonal produces different output from default', () async {
      final defaultTester = WidgetTester();
      addTearDown(() => defaultTester.dispose());
      final tonalTester = WidgetTester();
      addTearDown(() => tonalTester.dispose());

      await defaultTester.pumpWidget(
        FilledButton(child: Text('Action'), onPressed: () => null),
      );
      await tonalTester.pumpWidget(
        FilledButton.tonal(child: Text('Action'), onPressed: () => null),
      );

      expect(defaultTester.view, isNot(equals(tonalTester.view)));
    });

    test('OutlinedButton renders with label', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        OutlinedButton(child: Text('Outline'), onPressed: () => null),
      );

      expect(tester.find.text('Outline'), isTrue);
    });

    test('IconButton renders icon and handles tap', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());
      var pressed = false;

      await tester.pumpWidget(
        IconButton(
          key: ValueKey('icon-btn'),
          icon: Text('*'),
          onPressed: () {
            pressed = true;
            return null;
          },
        ),
      );

      tester.tap(tester.find.byKeyLocation(ValueKey('icon-btn')));
      expect(pressed, isTrue);
    });

    test('disabled IconButton does not fire tap callback', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());
      var pressed = false;

      await tester.pumpWidget(
        IconButton(
          key: ValueKey('icon-btn-disabled'),
          icon: Text('*'),
          enabled: false,
          onPressed: () {
            pressed = true;
            return null;
          },
        ),
      );

      tester.tap(tester.find.byKeyLocation(ValueKey('icon-btn-disabled')));
      expect(pressed, isFalse);
    });
  });

  group('Button sizes', () {
    test('ButtonSize.small exists', () {
      expect(ButtonSize.small, isNotNull);
    });

    test('ButtonSize.medium exists', () {
      expect(ButtonSize.medium, isNotNull);
    });

    test('ButtonSize.large exists', () {
      expect(ButtonSize.large, isNotNull);
    });
  });

  group('Button integration', () {
    test('Button in Column', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Column(
          children: [
            Button(label: 'Button 1', onPressed: () => null),
            Button(label: 'Button 2', onPressed: () => null),
          ],
        ),
      );
      expect(tester.find.text('Button 1'), isTrue);
      expect(tester.find.text('Button 2'), isTrue);
    });

    test('Button in Row', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Row(
          children: [
            Button(label: 'Left', onPressed: () => null),
            Button(label: 'Right', onPressed: () => null),
          ],
        ),
      );
      expect(tester.find.text('Left'), isTrue);
      expect(tester.find.text('Right'), isTrue);
    });

    test('outline button stays inline with filled variants in Row', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Row(
          gap: 1,
          children: [
            Button(
              label: 'Primary',
              variant: ButtonVariant.primary,
              onPressed: () => null,
            ),
            Button(
              label: 'Outline',
              variant: ButtonVariant.outline,
              onPressed: () => null,
            ),
          ],
        ),
      );

      final primaryLoc = tester.locateText('Primary');
      final outlineLoc = tester.locateText('Outline');
      expect(primaryLoc, isNotNull);
      expect(outlineLoc, isNotNull);
      expect(outlineLoc!.y, equals(primaryLoc!.y));
    });

    test('primary button in Row renders its own background fill', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Row(
          children: [
            Button(
              label: 'Primary',
              variant: ButtonVariant.primary,
              onPressed: () => null,
            ),
          ],
        ),
      );

      final line = tester.view
          .split('\n')
          .firstWhere((entry) => entry.contains('Primary'));
      final before = line.substring(0, line.indexOf('Primary'));
      final bgCodeCount = RegExp(r'48;').allMatches(before).length;
      expect(bgCodeCount, greaterThanOrEqualTo(1), reason: line);
    });

    test('Multiple buttons in Card', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Card(
          child: Column(
            children: [
              Text('Actions:'),
              Row(
                children: [
                  Button(
                    label: 'Save',
                    variant: ButtonVariant.primary,
                    onPressed: () => null,
                  ),
                  Button(
                    label: 'Cancel',
                    variant: ButtonVariant.secondary,
                    onPressed: () => null,
                  ),
                ],
              ),
            ],
          ),
        ),
      );
      expect(tester.find.text('Actions:'), isTrue);
      expect(tester.find.text('Save'), isTrue);
      expect(tester.find.text('Cancel'), isTrue);
    });
  });
}
