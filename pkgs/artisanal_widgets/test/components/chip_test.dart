import 'package:artisanal/artisanal.dart';
import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:test/test.dart';

void main() {
  group('Chip widgets', () {
    test('Chip renders label and optional avatar', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Chip(label: Text('feature/login'), avatar: Text('@')),
      );

      expect(tester.find.text('feature/login'), isTrue);
      expect(tester.find.text('@'), isTrue);
    });

    test('Chip delete action fires on delete icon tap', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());
      var deleted = false;

      await tester.pumpWidget(
        Chip(
          label: Text('artifact.log'),
          onDeleted: () {
            deleted = true;
            return null;
          },
        ),
      );

      final icon = tester.locateText('x');
      expect(icon, isNotNull);
      tester.tapAt(icon!.x, icon.y);
      expect(deleted, isTrue);
    });

    test('ActionChip invokes onPressed', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());
      var pressed = false;

      await tester.pumpWidget(
        ActionChip(
          key: ValueKey('action-chip'),
          label: Text('Run'),
          onPressed: () {
            pressed = true;
            return null;
          },
        ),
      );

      tester.tap(tester.find.byKeyLocation(ValueKey('action-chip')));
      expect(pressed, isTrue);
    });

    test('ChoiceChip forwards toggled selected state', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());
      bool? selected;

      await tester.pumpWidget(
        ChoiceChip(
          key: ValueKey('choice-chip'),
          label: Text('Stable'),
          selected: false,
          onSelected: (value) {
            selected = value;
            return null;
          },
        ),
      );

      tester.tap(tester.find.byKeyLocation(ValueKey('choice-chip')));
      expect(selected, isTrue);
    });

    test('FilterChip shows checkmark when selected', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        FilterChip(
          label: Text('Modified'),
          selected: true,
          onSelected: (_) => null,
        ),
      );

      expect(tester.find.text('+'), isTrue);
      expect(tester.find.text('Modified'), isTrue);
    });

    test('InputChip forwards selected toggle', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());
      bool? selected;

      await tester.pumpWidget(
        InputChip(
          key: ValueKey('input-chip'),
          label: Text('Draft'),
          selected: false,
          onSelected: (value) {
            selected = value;
            return null;
          },
        ),
      );

      tester.tap(tester.find.byKeyLocation(ValueKey('input-chip')));
      expect(selected, isTrue);
    });

    test('InputChip delete action fires on delete icon tap', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());
      var deleted = false;

      await tester.pumpWidget(
        InputChip(
          label: Text('notes.log'),
          onDeleted: () {
            deleted = true;
            return null;
          },
        ),
      );

      final icon = tester.locateText('x');
      expect(icon, isNotNull);
      tester.tapAt(icon!.x, icon.y);
      expect(deleted, isTrue);
    });
  });
}
