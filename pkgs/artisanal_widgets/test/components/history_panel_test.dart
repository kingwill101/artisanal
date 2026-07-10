import 'package:artisanal/artisanal.dart';
import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:test/test.dart';

void main() {
  group('HistoryEntry', () {
    test('creates with description and isRedo', () {
      const entry = HistoryEntry(description: 'Delete line');
      expect(entry.description, equals('Delete line'));
      expect(entry.isRedo, isFalse);

      const redo = HistoryEntry(description: 'Paste', isRedo: true);
      expect(redo.isRedo, isTrue);
    });
  });

  group('HistoryPanelMode', () {
    test('has compact and full values', () {
      expect(HistoryPanelMode.values, contains(HistoryPanelMode.compact));
      expect(HistoryPanelMode.values, contains(HistoryPanelMode.full));
    });
  });

  group('HistoryPanel', () {
    test('empty panel is empty', () {
      final panel = HistoryPanel();
      expect(panel.isEmpty, isTrue);
      expect(panel.length, equals(0));
    });

    test('with undo items', () {
      final panel = HistoryPanel(
        undoItems: [
          const HistoryEntry(description: 'Insert text'),
          const HistoryEntry(description: 'Delete word'),
        ],
      );
      expect(panel.isEmpty, isFalse);
      expect(panel.length, equals(2));
      expect(panel.undoItems.length, equals(2));
    });

    test('with redo items', () {
      final panel = HistoryPanel(
        redoItems: [const HistoryEntry(description: 'Paste')],
      );
      expect(panel.isEmpty, isFalse);
      expect(panel.length, equals(1));
      expect(panel.redoItems.length, equals(1));
    });

    test('with both stacks', () {
      final panel = HistoryPanel(
        undoItems: [
          const HistoryEntry(description: 'A'),
          const HistoryEntry(description: 'B'),
        ],
        redoItems: [const HistoryEntry(description: 'C')],
      );
      expect(panel.length, equals(3));
    });

    test('renders empty panel', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(HistoryPanel());
      expect(tester.view, isNotEmpty);
    });

    test('renders title', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(HistoryPanel(title: 'Edit History'));
      expect(tester.locateText('Edit History'), isNotNull);
    });

    test('renders default title', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        HistoryPanel(undoItems: [const HistoryEntry(description: 'A')]),
      );
      expect(tester.locateText('History'), isNotNull);
    });

    test('renders undo items', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        HistoryPanel(
          undoItems: [const HistoryEntry(description: 'Insert text')],
        ),
      );
      expect(tester.locateText('↶ Insert text'), isNotNull);
    });

    test('renders redo items', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        HistoryPanel(
          redoItems: [const HistoryEntry(description: 'Paste', isRedo: true)],
        ),
      );
      expect(tester.locateText('↷ Paste'), isNotNull);
    });

    test('renders marker text', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        HistoryPanel(
          undoItems: [const HistoryEntry(description: 'A')],
          markerText: '=== NOW ===',
        ),
      );
      expect(tester.locateText('=== NOW ==='), isNotNull);
    });

    test('renders default marker text', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        HistoryPanel(undoItems: [const HistoryEntry(description: 'A')]),
      );
      expect(tester.locateText('─── current ───'), isNotNull);
    });

    test('custom icons', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        HistoryPanel(
          undoIcon: '<< ',
          redoIcon: '>> ',
          undoItems: [const HistoryEntry(description: 'A')],
          redoItems: [const HistoryEntry(description: 'B')],
        ),
      );
      expect(tester.locateText('<< A'), isNotNull);
      expect(tester.locateText('>> B'), isNotNull);
    });

    test('full mode shows all items', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final items = List.generate(
        10,
        (i) => HistoryEntry(description: 'Undo $i'),
      );

      await tester.pumpWidget(
        HistoryPanel(mode: HistoryPanelMode.full, undoItems: items),
      );

      // Should show first and last items
      expect(tester.locateText('↶ Undo 0'), isNotNull);
      expect(tester.locateText('↶ Undo 9'), isNotNull);
    });

    test('compact mode limits items', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final items = List.generate(
        10,
        (i) => HistoryEntry(description: 'Undo $i'),
      );

      await tester.pumpWidget(
        HistoryPanel(
          mode: HistoryPanelMode.compact,
          compactLimit: 4,
          undoItems: items,
        ),
      );

      // Should show overflow indicator
      expect(tester.locateText('... (8 more)'), isNotNull);
    });

    test('custom title style', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        HistoryPanel(
          title: 'Styled',
          titleStyle: Style()..italic(),
          undoItems: [const HistoryEntry(description: 'A')],
        ),
      );
      expect(tester.locateText('Styled'), isNotNull);
    });

    test('with background color', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        HistoryPanel(
          background: Colors.blue,
          undoItems: [const HistoryEntry(description: 'A')],
        ),
      );
      expect(tester.locateText('↶ A'), isNotNull);
    });

    test('empty title skips title row', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        HistoryPanel(
          title: '',
          undoItems: [const HistoryEntry(description: 'A')],
        ),
      );
      // Should still render the undo item
      expect(tester.locateText('↶ A'), isNotNull);
    });
  });
}
