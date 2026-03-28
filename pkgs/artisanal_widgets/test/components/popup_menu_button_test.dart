import 'package:artisanal/terminal.dart' show KeyType;
import 'package:artisanal/testing.dart';
import 'package:artisanal/widgets.dart';
import 'package:test/test.dart';

void main() {
  group('PopupMenuButton', () {
    test(
      'default trigger label reflects initialValue when child is null',
      () async {
        final tester = WidgetTester();
        addTearDown(() => tester.dispose());

        await tester.pumpWidget(
          PopupMenuButton<String>(
            initialValue: 'save',
            items: [
              PopupMenuItem(value: 'open', child: Text('Open')),
              PopupMenuItem(value: 'save', child: Text('Save')),
            ],
            onSelected: (_) => null,
          ),
        );

        expect(tester.find.text('Save'), isTrue);
      },
    );

    test('opens and selects item via mouse tap', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());
      String? selected;

      await tester.pumpWidget(
        PopupMenuButton<String>(
          key: ValueKey('popup-menu'),
          items: [
            PopupMenuItem(value: 'open', child: Text('Open')),
            PopupMenuItem(value: 'save', child: Text('Save')),
          ],
          onSelected: (value) {
            selected = value;
            return null;
          },
        ),
      );

      tester.tap(tester.find.byKeyLocation(ValueKey('popup-menu')));
      expect(tester.find.text('Open'), isTrue);

      tester.tap(tester.find.textLocation('Save'));
      expect(selected, equals('save'));
      expect(tester.find.text('Open'), isFalse);
    });

    test('default trigger label updates to selected item', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        PopupMenuButton<String>(
          key: ValueKey('popup-menu-label-update'),
          initialValue: 'save',
          items: [
            PopupMenuItem(value: 'open', child: Text('Open')),
            PopupMenuItem(value: 'save', child: Text('Save')),
          ],
          onSelected: (_) => null,
        ),
      );

      expect(tester.find.text('Save'), isTrue);

      tester.tap(
        tester.find.byKeyLocation(ValueKey('popup-menu-label-update')),
      );
      tester.tap(tester.find.textLocation('Open'));

      expect(tester.find.text('Open'), isTrue);
      expect(tester.find.text('Save'), isFalse);
    });

    test('keyboard navigation selects highlighted item', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());
      String? selected;

      await tester.pumpWidget(
        PopupMenuButton<String>(
          key: ValueKey('popup-menu-kbd'),
          items: [
            PopupMenuItem(value: 'open', child: Text('Open')),
            PopupMenuItem(value: 'save', child: Text('Save')),
          ],
          onSelected: (value) {
            selected = value;
            return null;
          },
        ),
      );

      tester.tap(tester.find.byKeyLocation(ValueKey('popup-menu-kbd')));
      tester.sendSpecialKey(KeyType.down);
      tester.sendSpecialKey(KeyType.enter);

      expect(selected, equals('save'));
    });

    test('disabled menu item is not selectable', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());
      String? selected;

      await tester.pumpWidget(
        PopupMenuButton<String>(
          key: ValueKey('popup-disabled-item'),
          items: [
            PopupMenuItem(
              value: 'disabled',
              child: Text('Disabled'),
              enabled: false,
            ),
            PopupMenuItem(value: 'enabled', child: Text('Enabled')),
          ],
          onSelected: (value) {
            selected = value;
            return null;
          },
        ),
      );

      tester.tap(tester.find.byKeyLocation(ValueKey('popup-disabled-item')));
      tester.tap(tester.find.textLocation('Disabled'));

      expect(selected, isNull);
    });

    test(
      'overlay menu opens, selects, and does not push sibling content',
      () async {
        final tester = WidgetTester();
        addTearDown(() => tester.dispose());
        String? selected;

        await tester.pumpWidget(
          Overlay(
            initialEntries: [
              OverlayEntry(
                builder: (context) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PopupMenuButton<String>(
                        key: ValueKey('popup-overlay-anchor'),
                        items: [
                          PopupMenuItem(value: 'open', child: Text('Open')),
                          PopupMenuItem(value: 'save', child: Text('Save')),
                        ],
                        onSelected: (value) {
                          selected = value;
                          return null;
                        },
                      ),
                      Text('ANCHOR-LINE'),
                    ],
                  );
                },
              ),
            ],
          ),
        );

        final before = tester.locateText('ANCHOR-LINE');
        expect(before, isNotNull);

        tester.tap(tester.find.byKeyLocation(ValueKey('popup-overlay-anchor')));

        expect(tester.find.text('Open'), isTrue);

        tester.sendSpecialKey(KeyType.down);
        tester.sendSpecialKey(KeyType.enter);
        expect(selected, equals('save'));

        final after = tester.locateText('ANCHOR-LINE');
        expect(after, isNotNull);
        expect(after!.y, equals(before!.y));
      },
    );

    test('overlay menu aligns near trigger label x position', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Overlay(
          initialEntries: [
            OverlayEntry(
              builder: (context) {
                return PopupMenuButton<String>(
                  key: ValueKey('popup-overlay-alignment'),
                  child: Text('Action: none'),
                  items: [
                    PopupMenuItem(value: 'open', child: Text('Open')),
                    PopupMenuItem(value: 'save', child: Text('Save')),
                  ],
                  onSelected: (_) => null,
                );
              },
            ),
          ],
        ),
      );

      final trigger = tester.locateText('Action: none');
      expect(trigger, isNotNull);

      tester.tap(
        tester.find.byKeyLocation(ValueKey('popup-overlay-alignment')),
      );

      final menuLabel = tester.locateText('Open');
      expect(menuLabel, isNotNull);
      expect((menuLabel!.x - trigger!.x).abs() <= 8, isTrue);
    });

    test('hovering a floating menu item selects it immediately', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());
      String? selected;

      await tester.pumpWidget(
        Overlay(
          initialEntries: [
            OverlayEntry(
              builder: (_) => PopupMenuButton<String>(
                key: ValueKey('popup-hover-highlight'),
                items: [
                  PopupMenuItem(value: 'open', child: Text('Open')),
                  PopupMenuItem(value: 'save', child: Text('Save')),
                ],
                onSelected: (value) {
                  selected = value;
                  return null;
                },
              ),
            ),
          ],
        ),
      );

      tester.tap(tester.find.byKeyLocation(ValueKey('popup-hover-highlight')));
      final save = tester.locateText('Save');
      expect(save, isNotNull);
      expect(selected, isNull);

      tester.mouseMove(save!.x + 2, save.y);

      expect(selected, equals('save'));
    });

    test('escape closes menu and triggers onCanceled', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());
      var canceled = false;

      await tester.pumpWidget(
        PopupMenuButton<String>(
          key: ValueKey('popup-cancel-escape'),
          items: [PopupMenuItem(value: 'open', child: Text('Open'))],
          onCanceled: () {
            canceled = true;
            return null;
          },
          onSelected: (_) => null,
        ),
      );

      tester.tap(tester.find.byKeyLocation(ValueKey('popup-cancel-escape')));
      expect(tester.find.text('Open'), isTrue);

      tester.sendSpecialKey(KeyType.escape);

      expect(canceled, isTrue);
      expect(tester.find.text('Open'), isFalse);
    });
  });
}
