import 'dart:io';

import 'package:artisanal/src/style/color.dart';
import 'package:artisanal/src/style/style.dart';
import 'package:artisanal/src/terminal/ansi.dart';
import 'package:artisanal/src/tui/bubbles/components/base.dart';
import 'package:artisanal/src/tui/bubbles/components/table.dart';
import 'package:artisanal/src/tui/bubbles/components/tree.dart';
import 'package:artisanal/src/style/list.dart';
import 'package:test/test.dart';

String _readGolden(String relativePath) {
  // We now use local testdata
  final localPath = relativePath.replaceFirst(
    'test/testdata/tree/',
    'test/testdata/tree/',
  );
  var file = File(localPath);
  if (!file.existsSync()) {
    // Try going up to find the workspace root if run from package dir
    // but wait, if we are in package dir, 'test/testdata' should work.
    // If we are in root, 'packages/artisanal/test/testdata' should work.
    file = File('packages/artisanal/$localPath');
  }
  return file.readAsStringSync().replaceAll('\r\n', '\n');
}

void _expectGolden(String relativePath, String actual) {
  expect(actual.replaceAll('\r\n', '\n'), equals(_readGolden(relativePath)));
}

Tree _testTree() {
  const cfg = RenderConfig(colorProfile: ColorProfile.ansi256);
  return Tree(renderConfig: cfg)
    ..child('Foo')
    ..child(
      Tree(renderConfig: cfg)
        ..root('Bar')
        ..child('Qux')
        ..child(
          Tree(renderConfig: cfg)
            ..root('Quux')
            ..child('Foo')
            ..child('Bar'),
        )
        ..child('Quuux'),
    )
    ..child('Baz');
}

void main() {
  group('lipgloss v2 parity: tree', () {
    const cfg = RenderConfig(colorProfile: ColorProfile.ansi256);

    test('TestTree (before)', () {
      final tr = _testTree();
      _expectGolden('test/testdata/tree/TestTree/before.golden', tr.render());
    });

    test('TestTree (after)', () {
      final tr = _testTree()..enumerator(TreeEnumerator.rounded);
      _expectGolden('test/testdata/tree/TestTree/after.golden', tr.render());
    });

    test('TestTreeHidden', () {
      final tr = Tree(renderConfig: cfg)
        ..child('Foo')
        ..child(
          Tree(renderConfig: cfg)
            ..root('Bar')
            ..child('Qux')
            ..child(
              (Tree(renderConfig: cfg)
                    ..root('Quux')
                    ..child('Foo')
                    ..child('Bar'))
                  .hide(true),
            )
            ..child('Quuux'),
        )
        ..child('Baz');

      _expectGolden('test/testdata/tree/TestTreeHidden.golden', tr.render());
    });

    test('TestTreeAllHidden', () {
      final tr = (_testTree()..root(''))..hide(true);
      _expectGolden('test/testdata/tree/TestTreeAllHidden.golden', tr.render());
    });

    test('TestTreeRoot', () {
      final tr = Tree(renderConfig: cfg)
        ..root('Root')
        ..child('Foo')
        ..child(
          Tree(renderConfig: cfg)
            ..root('Bar')
            ..child('Qux')
            ..child('Quuux'),
        )
        ..child('Baz');

      _expectGolden('test/testdata/tree/TestTreeRoot.golden', tr.render());
    });

    test('TestTreeStartsWithSubtree', () {
      final tr = Tree(renderConfig: cfg)
        ..child(
          Tree(renderConfig: cfg)
            ..root('Bar')
            ..child('Qux')
            ..child('Quuux'),
        )
        ..child('Baz');
      _expectGolden(
        'test/testdata/tree/TestTreeStartsWithSubtree.golden',
        tr.render(),
      );
    });

    test('TestTreeAddTwoSubTreesWithoutName', () {
      final tr = Tree(renderConfig: cfg)
        ..child('Bar')
        ..child('Foo')
        ..child(
          Tree(renderConfig: cfg)
            ..children(['Qux', 'Qux', 'Qux', 'Qux', 'Qux']),
        )
        ..child(
          Tree(renderConfig: cfg)
            ..children(['Quux', 'Quux', 'Quux', 'Quux', 'Quux']),
        )
        ..child('Baz');

      _expectGolden(
        'test/testdata/tree/TestTreeAddTwoSubTreesWithoutName.golden',
        tr.render(),
      );
    });

    test('TestTreeLastNodeIsSubTree', () {
      final tr = Tree(renderConfig: cfg)
        ..child('Foo')
        ..child(
          Tree(renderConfig: cfg)
            ..root('Bar')
            ..child('Qux')
            ..child(
              Tree(renderConfig: cfg)
                ..root('Quux')
                ..child('Foo')
                ..child('Bar'),
            )
            ..child('Quuux'),
        );
      _expectGolden(
        'test/testdata/tree/TestTreeLastNodeIsSubTree.golden',
        tr.render(),
      );
    });

    test('TestTreeNil', () {
      final tr = Tree(renderConfig: cfg)
        ..child(null)
        ..child(
          Tree(renderConfig: cfg)
            ..root('Bar')
            ..child('Qux')
            ..child(
              Tree(renderConfig: cfg)
                ..root('Quux')
                ..child('Bar'),
            )
            ..child('Quuux'),
        )
        ..child('Baz');
      _expectGolden('test/testdata/tree/TestTreeNil.golden', tr.render());
    });

    test('TestTreeCustom', () {
      final tr = _testTree()
        ..itemStyle(Style().foreground(const BasicColor('9')))
        ..enumeratorStyle(
          Style().foreground(const BasicColor('12')).paddingRight(1),
        )
        ..indenterStyle(
          Style().foreground(const BasicColor('12')).paddingRight(1),
        )
        ..enumeratorFunc((_, _) => '->')
        ..indenterFunc((_, _) => '->');

      _expectGolden('test/testdata/tree/TestTreeCustom.golden', tr.render());
    });

    test('TestTreeMultilineNode', () {
      final tr = Tree(renderConfig: cfg)
        ..root('Big\nRoot\nNode')
        ..child('Foo')
        ..child(
          Tree(renderConfig: cfg)
            ..root('Bar')
            ..child('Line 1\nLine 2\nLine 3\nLine 4')
            ..child(
              Tree(renderConfig: cfg)
                ..root('Quux')
                ..child('Foo')
                ..child('Bar'),
            )
            ..child('Quuux'),
        )
        ..child('Baz\nLine 2');

      _expectGolden(
        'test/testdata/tree/TestTreeMultilineNode.golden',
        tr.render(),
      );
    });

    test('TestTreeSubTreeWithCustomEnumerator', () {
      final tr = Tree(renderConfig: cfg)
        ..root('The Root Node™')
        ..child(
          Tree(renderConfig: cfg)
            ..root('Parent')
            ..child('child 1')
            ..child('child 2')
            ..itemStyleFunc((_, _) => Style().setString('*'))
            ..enumeratorStyleFunc(
              (_, _) => Style().setString('+').paddingRight(1),
            ),
        )
        ..child('Baz');

      _expectGolden(
        'test/testdata/tree/TestTreeSubTreeWithCustomEnumerator.golden',
        tr.render(),
      );
    });

    test('TestTreeMixedEnumeratorSize', () {
      final romans = <int, String>{
        1: 'I',
        2: 'II',
        3: 'III',
        4: 'IV',
        5: 'V',
        6: 'VI',
      };
      final tr =
          (Tree(renderConfig: cfg)
                ..root('The Root Node™')
                ..children(['Foo', 'Foo', 'Foo', 'Foo', 'Foo']))
              .enumeratorFunc((_, i) => romans[i + 1] ?? '');

      _expectGolden(
        'test/testdata/tree/TestTreeMixedEnumeratorSize.golden',
        tr.render(),
      );
    });

    test('TestTreeStyleNilFuncs', () {
      final tr =
          (Tree(renderConfig: cfg)
              ..root('Silly')
              ..children(['Willy ', 'Nilly']))
            ..itemStyleFunc((_, _) => Style())
            ..enumeratorStyleFunc((_, _) => Style());
      _expectGolden(
        'test/testdata/tree/TestTreeStyleNilFuncs.golden',
        tr.render(),
      );
    });

    test('TestTreeStyleAt', () {
      final tr =
          (Tree(renderConfig: cfg)
                ..root('Root')
                ..child('Foo')
                ..child('Baz'))
              .enumeratorFunc((children, i) {
                if (children[i].value == 'Foo') return '>';
                return '-';
              });

      _expectGolden('test/testdata/tree/TestTreeStyleAt.golden', tr.render());
    });

    test('TestRootStyle (strip ANSI)', () {
      final tr =
          (Tree(renderConfig: cfg)
                ..root('Root')
                ..child('Foo')
                ..child('Baz'))
              .rootStyle(Style().background(const BasicColor('#5A56E0')))
              .itemStyle(Style().background(const BasicColor('#04B575')));

      _expectGolden(
        'test/testdata/tree/TestRootStyle.golden',
        Ansi.stripAnsi(tr.render()),
      );
    });

    test('TestAt + TestNodeDataRemoveOutOfBounds', () {
      final data = TreeStringData(['Foo', 'Bar']);
      expect(data.at(0)?.value, equals('Foo'));
      expect(data.at(10), isNull);
      expect(data.at(-1), isNull);

      final single = TreeStringData(['a']);
      expect(single.length, equals(1));
    });

    test('TestFilter', () {
      final data = (TreeFilter(TreeStringData(['Foo', 'Bar', 'Baz', 'Nope'])))
        ..filter((index) => index != 3);

      final tr = Tree(renderConfig: cfg)
        ..root('Root')
        ..child(data);
      _expectGolden('test/testdata/tree/TestFilter.golden', tr.render());

      expect(data.at(1)?.value, equals('Bar'));
      expect(data.at(10), isNull);
    });

    test('TestTreeTable', () {
      final table =
          (Table(renderConfig: cfg)
                ..width(20)
                ..styleFunc((_, _, __) => Style().padding(0, 1))
                ..headers(['Foo', 'Bar'])
                ..row(['Qux', 'Baz'])
                ..row(['Qux', 'Baz']))
              .render();

      final tr = Tree(renderConfig: cfg)
        ..child('Foo')
        ..child(
          Tree(renderConfig: cfg)
            ..root('Bar')
            ..child('Baz')
            ..child('Baz')
            ..child(table)
            ..child('Baz'),
        )
        ..child('Qux');

      _expectGolden('test/testdata/tree/TestTreeTable.golden', tr.render());
    });

    test('TestAddItemWithAndWithoutRoot/with_root', () {
      final tr = Tree(renderConfig: cfg)
        ..child('Foo')
        ..child('Bar')
        ..child(Tree(renderConfig: cfg)..child('Baz'))
        ..child('Qux');
      _expectGolden(
        'test/testdata/tree/TestAddItemWithAndWithoutRoot/with_root.golden',
        tr.render(),
      );
    });

    test('TestAddItemWithAndWithoutRoot/without_root', () {
      final tr = Tree(renderConfig: cfg)
        ..child('Foo')
        ..child(
          Tree(renderConfig: cfg)
            ..root('Bar')
            ..child('Baz'),
        )
        ..child('Qux');
      _expectGolden(
        'test/testdata/tree/TestAddItemWithAndWithoutRoot/without_root.golden',
        tr.render(),
      );
    });

    test('TestEmbedListWithinTree', () {
      final tr = Tree(renderConfig: cfg)
        ..child(
          LipList.create([
            'A',
            'B',
            'C',
          ], renderConfig: cfg).enumerator(ListEnumerators.arabic),
        )
        ..child(
          LipList.create([
            '1',
            '2',
            '3',
          ], renderConfig: cfg).enumerator(ListEnumerators.alphabet),
        );

      _expectGolden(
        'test/testdata/tree/TestEmbedListWithinTree.golden',
        tr.render(),
      );
    });

    test('TestMultilinePrefix', () {
      final paddingsStyle = Style().paddingLeft(1).paddingBottom(1);
      final tr = (Tree(renderConfig: cfg)
        ..enumeratorFunc((_, i) => i == 1 ? '│\n│' : ' ')
        ..indenterFunc((_, _) => ' ')
        ..itemStyle(paddingsStyle)
        ..child('Foo Document\nThe Foo Files')
        ..child('Bar Document\nThe Bar Files')
        ..child('Baz Document\nThe Baz Files'));

      _expectGolden(
        'test/testdata/tree/TestMultilinePrefix.golden',
        tr.render(),
      );
    });

    test('TestMultilinePrefixSubtree', () {
      final paddingsStyle = Style().padding(0, 0, 1, 1);
      final subtree = (Tree(renderConfig: cfg)
        ..root('Baz')
        ..enumeratorFunc((_, i) => i == 1 ? '│\n│' : ' ')
        ..indenterFunc((_, _) => ' ')
        ..itemStyle(paddingsStyle)
        ..child('Foo Document\nThe Foo Files')
        ..child('Bar Document\nThe Bar Files')
        ..child('Baz Document\nThe Baz Files'));

      final tr = Tree(renderConfig: cfg)
        ..child('Foo')
        ..child('Bar')
        ..child(subtree)
        ..child('Qux');

      _expectGolden(
        'test/testdata/tree/TestMultilinePrefixSubtree.golden',
        tr.render(),
      );
    });

    test('TestMultilinePrefixInception', () {
      String glowEnum(_, int i) => i == 1 ? '│\n│' : ' ';
      String glowIndent(_, _) => '  ';
      final paddingsStyle = Style().paddingLeft(1).paddingBottom(1);

      final tr = (Tree(renderConfig: cfg)
        ..enumeratorFunc(glowEnum)
        ..indenterFunc(glowIndent)
        ..itemStyle(paddingsStyle)
        ..child('Foo Document\nThe Foo Files')
        ..child('Bar Document\nThe Bar Files')
        ..child(
          Tree(renderConfig: cfg)
            ..enumeratorFunc(glowEnum)
            ..indenterFunc(glowIndent)
            ..itemStyle(paddingsStyle)
            ..child('Qux Document\nThe Qux Files')
            ..child('Quux Document\nThe Quux Files')
            ..child('Quuux Document\nThe Quuux Files'),
        )
        ..child('Baz Document\nThe Baz Files'));

      _expectGolden(
        'test/testdata/tree/TestMultilinePrefixInception.golden',
        tr.render(),
      );
    });

    test('TestTypes', () {
      final tr = Tree(renderConfig: cfg)
        ..child(0)
        ..child(true)
        ..child(['Foo', 'Bar'])
        ..child(['Qux', 'Quux', 'Quuux']);

      _expectGolden('test/testdata/tree/TestTypes.golden', tr.render());
    });
  });
}
