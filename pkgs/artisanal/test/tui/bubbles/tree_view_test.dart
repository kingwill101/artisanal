import 'package:artisanal/bubbles.dart';
import 'package:artisanal/runtime.dart'
    show KeyMsg, MouseAction, MouseButton, MouseMsg;
import 'package:artisanal/style.dart' show Style;
import 'package:artisanal/terminal.dart' show Key, KeyType;
import 'package:test/test.dart';

void main() {
  group('TreeModel', () {
    late TreeModel<String> tree;

    setUp(() {
      tree = TreeModel<String>(
        height: 3,
        items: [
          TreeItem(
            id: 'lib',
            label: 'lib',
            value: 'lib',
            children: [
              TreeItem(
                id: 'lib/src',
                label: 'src',
                value: 'src',
                children: [
                  TreeItem(
                    id: 'lib/src/main.dart',
                    label: 'main.dart',
                    value: 'main',
                  ),
                ],
              ),
            ],
          ),
          TreeItem(id: 'README.md', label: 'README.md', value: 'readme'),
        ],
      );
    });

    test('projects expanded hierarchy with stable depth and connectors', () {
      expect(tree.rows.map((row) => row.item.id), [
        'lib',
        'lib/src',
        'lib/src/main.dart',
        'README.md',
      ]);
      expect(tree.rows.map((row) => row.depth), [0, 1, 2, 0]);
      expect(tree.rows[1].connector, '└─ ');
      expect(tree.rows[2].connector, '└─ ');
      expect(tree.view(), contains('main.dart'));
    });

    test('collapse hides descendants and keeps their selection on parent', () {
      tree.select('lib/src/main.dart');

      expect(tree.collapse('lib'), isTrue);
      expect(tree.rows.map((row) => row.item.id), ['lib', 'README.md']);
      expect(tree.selectedItem?.id, 'lib');
    });

    test(
      'keyboard navigation expands, collapses, and activates rows',
      () async {
        tree
          ..select('lib')
          ..update(const KeyMsg(Key(KeyType.left)));
        expect(tree.isExpanded('lib'), isFalse);

        tree.update(const KeyMsg(Key(KeyType.right)));
        expect(tree.isExpanded('lib'), isTrue);
        tree.update(const KeyMsg(Key(KeyType.right)));
        expect(tree.selectedItem?.id, 'lib/src');

        final (_, command) = tree.update(const KeyMsg(Key(KeyType.enter)));
        expect(command, isNotNull);
        expect(await command!.execute(), isA<TreeItemActivatedMsg<String>>());
      },
    );

    test('mouse wheel scrolls viewport without moving selection', () {
      final selected = tree.selectedItem;

      tree.update(
        const MouseMsg(
          action: MouseAction.wheel,
          button: MouseButton.wheelDown,
          x: 0,
          y: 0,
        ),
      );

      expect(tree.offset, 1);
      expect(tree.selectedItem, same(selected));
      expect(tree.visibleRows.first.item.id, 'lib/src');
    });

    test('horizontal panning is independent from tree expansion', () {
      expect(tree.horizontalOffset, 0);

      tree
        ..panBy(6)
        ..update(const KeyMsg(Key(KeyType.left, shift: true)));

      expect(tree.horizontalOffset, 4);
      expect(tree.isExpanded('lib'), isTrue);
      tree.update(const KeyMsg(Key(KeyType.right, shift: true)));
      expect(tree.horizontalOffset, 6);
      expect(Style.stripAnsi(tree.view()).split('\n').first, startsWith('b'));

      tree
        ..width = 6
        ..setHorizontalOffset(1000);
      expect(tree.horizontalOffset, tree.maxHorizontalOffset);
      expect(tree.horizontalOffset, lessThan(1000));
    });

    test('replacement preserves expansion and selection by stable ID', () {
      tree
        ..collapse('lib/src')
        ..select('README.md')
        ..replaceItems([
          TreeItem(
            id: 'lib',
            label: 'lib',
            value: 'lib',
            children: [
              TreeItem(
                id: 'lib/src',
                label: 'source',
                value: 'src',
                children: [
                  TreeItem(
                    id: 'lib/src/next.dart',
                    label: 'next.dart',
                    value: 'next',
                  ),
                ],
              ),
            ],
          ),
          TreeItem(id: 'README.md', label: 'README', value: 'readme'),
        ]);

      expect(tree.isExpanded('lib/src'), isFalse);
      expect(tree.selectedItem?.id, 'README.md');
    });

    test('bulk expansion preserves selection by stable ID', () {
      tree
        ..collapseAll()
        ..select('README.md')
        ..expandAll();

      expect(tree.selectedItem?.id, 'README.md');
    });

    test('bulk collapse selects the nearest visible ancestor', () {
      tree
        ..select('lib/src/main.dart')
        ..collapseAll();

      expect(tree.selectedItem?.id, 'lib');
    });
  });
}
