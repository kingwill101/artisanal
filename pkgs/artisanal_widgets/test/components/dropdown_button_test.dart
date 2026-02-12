import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:artisanal_widgets/testing.dart';
import 'package:test/test.dart';

void main() {
  group('DropdownButton', () {
    test('renders selected item label', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        DropdownButton<String>(
          items: [
            DropdownMenuItem(value: 'a', child: Text('Alpha')),
            DropdownMenuItem(value: 'b', child: Text('Beta')),
          ],
          value: 'b',
          onChanged: (_) => null,
        ),
      );

      expect(tester.find.text('Beta'), isTrue);
    });

    test('uses hint when value is null', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        DropdownButton<String>(
          items: [DropdownMenuItem(value: 'a', child: Text('Alpha'))],
          hint: Text('Pick one'),
          onChanged: (_) => null,
        ),
      );

      expect(tester.find.text('Pick one'), isTrue);
    });

    test('uses disabledHint when not interactive', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        DropdownButton<String>(
          items: [DropdownMenuItem(value: 'a', child: Text('Alpha'))],
          hint: Text('Pick one'),
          disabledHint: Text('Disabled'),
          enabled: false,
          onChanged: (_) => null,
        ),
      );

      expect(tester.find.text('Disabled'), isTrue);
    });

    test('tap advances to next enabled item', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());
      String? changed;

      await tester.pumpWidget(
        DropdownButton<String>(
          key: ValueKey('dropdown'),
          items: [
            DropdownMenuItem(value: 'a', child: Text('Alpha')),
            DropdownMenuItem(value: 'b', child: Text('Beta'), enabled: false),
            DropdownMenuItem(value: 'c', child: Text('Gamma')),
          ],
          value: 'a',
          onChanged: (value) {
            changed = value;
            return null;
          },
        ),
      );

      tester.tap(tester.find.byKeyLocation(ValueKey('dropdown')));
      expect(changed, equals('c'));
    });
  });
}
