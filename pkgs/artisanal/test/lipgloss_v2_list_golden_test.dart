import 'dart:io';

import 'package:artisanal/src/style/color.dart';
import 'package:artisanal/src/style/list.dart';
import 'package:artisanal/src/style/style.dart';
import 'package:artisanal/src/tui/bubbles/components/base.dart';
import 'package:artisanal/src/tui/bubbles/components/tree.dart';
import 'package:test/test.dart';

String _readGolden(String relativePath) {
  // We now use local testdata
  final localPath = relativePath.replaceFirst(
    'test/testdata/list/',
    'test/testdata/list/',
  );
  var file = File(localPath);
  if (!file.existsSync()) {
    file = File('packages/artisanal/$localPath');
  }
  return file.readAsStringSync().replaceAll('\r\n', '\n');
}

void _expectGolden(String relativePath, String actual) {
  expect(actual.replaceAll('\r\n', '\n'), equals(_readGolden(relativePath)));
}

void main() {
  group('lipgloss v2 parity: list', () {
    const cfg = RenderConfig(colorProfile: ColorProfile.ansi256);

    test('TestList', () {
      final l = LipList(renderConfig: cfg)
        ..item('Foo')
        ..item('Bar')
        ..item('Baz');
      _expectGolden('test/testdata/list/TestList.golden', l.render());
    });

    test('TestListItems', () {
      final l = LipList(renderConfig: cfg)..items(['Foo', 'Bar', 'Baz']);
      _expectGolden('test/testdata/list/TestListItems.golden', l.render());
    });

    test('TestSublist', () {
      final l = LipList(renderConfig: cfg)
        ..item('Foo')
        ..item('Bar')
        ..item(
          LipList.create([
            'Hi',
            'Hello',
            'Halo',
          ], renderConfig: cfg).enumerator(ListEnumerators.roman),
        )
        ..item('Qux');
      _expectGolden('test/testdata/list/TestSublist.golden', l.render());
    });

    test('TestSublistItems', () {
      final l = LipList.create([
        'A',
        'B',
        'C',
        LipList.create([
          'D',
          'E',
          'F',
        ], renderConfig: cfg).enumerator(ListEnumerators.roman),
        'G',
      ], renderConfig: cfg);
      _expectGolden('test/testdata/list/TestSublistItems.golden', l.render());
    });

    test('TestComplexSublist', () {
      final style1 = Style().foreground(const BasicColor('99')).paddingRight(1);
      final style2 = Style()
          .foreground(const BasicColor('212'))
          .paddingRight(1);

      final l = LipList(renderConfig: cfg)
        ..item('Foo')
        ..item('Bar')
        ..item(LipList.create(['foo2', 'bar2'], renderConfig: cfg))
        ..item('Qux')
        ..item(
          LipList.create(
            ['aaa', 'bbb'],
            renderConfig: cfg,
          ).enumeratorStyle(style1).enumerator(ListEnumerators.roman),
        )
        ..item('Deep')
        ..item(
          LipList(renderConfig: cfg)
            ..enumeratorStyle(style2)
            ..indenterStyle(style2)
            ..enumerator(ListEnumerators.alphabet)
            ..item('foo')
            ..item('Deeper')
            ..item(
              LipList(renderConfig: cfg)
                ..indenterStyle(style1)
                ..enumeratorStyle(style1)
                ..enumerator(ListEnumerators.arabic)
                ..item('a')
                ..item('b')
                ..item('Even Deeper, inherit parent renderer')
                ..item(
                  LipList(renderConfig: cfg)
                    ..enumerator(ListEnumerators.asterisk)
                    ..indenterStyle(style2)
                    ..enumeratorStyle(style2)
                    ..item('sus')
                    ..item('d minor')
                    ..item('f#')
                    ..item('One ore level, with another renderer')
                    ..item(
                      LipList(renderConfig: cfg)
                        ..indenterStyle(style1)
                        ..enumeratorStyle(style1)
                        ..enumerator(ListEnumerators.dash)
                        ..item('a\nmultine\nstring')
                        ..item('hoccus poccus')
                        ..item('abra kadabra')
                        ..item('And finally, a tree within all this')
                        ..item(
                          Tree(renderConfig: cfg)
                            ..indenterStyle(style2)
                            ..enumeratorStyle(style2)
                            ..child('another\nmultine\nstring')
                            ..child('something')
                            ..child('a subtree')
                            ..child(
                              Tree(renderConfig: cfg)
                                ..indenterStyle(style2)
                                ..enumeratorStyle(style2)
                                ..child('yup')
                                ..child('many itens')
                                ..child('another'),
                            )
                            ..child('hallo')
                            ..child('wunderbar!'),
                        )
                        ..item('this is a tree\nand other obvious statements'),
                    ),
                ),
            )
            ..item('bar'),
        )
        ..item('Baz');

      _expectGolden('test/testdata/list/TestComplexSublist.golden', l.render());
    });

    test('TestMultiline', () {
      final l = LipList(renderConfig: cfg)
        ..item('Item1\nline 2\nline 3')
        ..item('Item2\nline 2\nline 3')
        ..item('3');
      _expectGolden('test/testdata/list/TestMultiline.golden', l.render());
    });

    test('TestListIntegers', () {
      final l = LipList(renderConfig: cfg)
        ..item('1')
        ..item('2')
        ..item('3');
      _expectGolden('test/testdata/list/TestListIntegers.golden', l.render());
    });

    test('TestEnumerators/alphabet', () {
      final l = LipList(renderConfig: cfg)
        ..enumerator(ListEnumerators.alphabet)
        ..item('Foo')
        ..item('Bar')
        ..item('Baz');
      _expectGolden(
        'test/testdata/list/TestEnumerators/alphabet.golden',
        l.render(),
      );
    });

    test('TestEnumerators/arabic', () {
      final l = LipList(renderConfig: cfg)
        ..enumerator(ListEnumerators.arabic)
        ..item('Foo')
        ..item('Bar')
        ..item('Baz');
      _expectGolden(
        'test/testdata/list/TestEnumerators/arabic.golden',
        l.render(),
      );
    });

    test('TestEnumerators/roman', () {
      final l = LipList(renderConfig: cfg)
        ..enumerator(ListEnumerators.roman)
        ..item('Foo')
        ..item('Bar')
        ..item('Baz');
      _expectGolden(
        'test/testdata/list/TestEnumerators/roman.golden',
        l.render(),
      );
    });

    test('TestEnumerators/bullet', () {
      final l = LipList(renderConfig: cfg)
        ..enumerator(ListEnumerators.bullet)
        ..item('Foo')
        ..item('Bar')
        ..item('Baz');
      _expectGolden(
        'test/testdata/list/TestEnumerators/bullet.golden',
        l.render(),
      );
    });

    test('TestEnumerators/asterisk', () {
      final l = LipList(renderConfig: cfg)
        ..enumerator(ListEnumerators.asterisk)
        ..item('Foo')
        ..item('Bar')
        ..item('Baz');
      _expectGolden(
        'test/testdata/list/TestEnumerators/asterisk.golden',
        l.render(),
      );
    });

    test('TestEnumerators/dash', () {
      final l = LipList(renderConfig: cfg)
        ..enumerator(ListEnumerators.dash)
        ..item('Foo')
        ..item('Bar')
        ..item('Baz');
      _expectGolden(
        'test/testdata/list/TestEnumerators/dash.golden',
        l.render(),
      );
    });

    test('TestEnumeratorsTransform/alphabet lower', () {
      final l = LipList(renderConfig: cfg)
        ..enumeratorStyle(
          Style().paddingRight(1).transform((s) => s.toLowerCase()),
        )
        ..enumerator(ListEnumerators.alphabet)
        ..item('Foo')
        ..item('Bar')
        ..item('Baz');
      _expectGolden(
        'test/testdata/list/TestEnumeratorsTransform/alphabet_lower.golden',
        l.render(),
      );
    });

    test('TestEnumeratorsTransform/arabic)', () {
      final l = LipList(renderConfig: cfg)
        ..enumeratorStyle(
          Style().paddingRight(1).transform((s) => s.replaceFirst('.', ')')),
        )
        ..enumerator(ListEnumerators.arabic)
        ..item('Foo')
        ..item('Bar')
        ..item('Baz');
      _expectGolden(
        'test/testdata/list/TestEnumeratorsTransform/arabic).golden',
        l.render(),
      );
    });

    test('TestEnumeratorsTransform/roman within ()', () {
      final l = LipList(renderConfig: cfg)
        ..enumeratorStyle(
          Style().transform((s) {
            final lower = s.toLowerCase().replaceFirst('.', '');
            return '($lower) ';
          }),
        )
        ..enumerator(ListEnumerators.roman)
        ..item('Foo')
        ..item('Bar')
        ..item('Baz');
      _expectGolden(
        'test/testdata/list/TestEnumeratorsTransform/roman_within_().golden',
        l.render(),
      );
    });

    test('TestEnumeratorsTransform/bullet is dash', () {
      final l = LipList(renderConfig: cfg)
        ..enumeratorStyle(Style().transform((_) => '- '))
        ..enumerator(ListEnumerators.bullet)
        ..item('Foo')
        ..item('Bar')
        ..item('Baz');
      _expectGolden(
        'test/testdata/list/TestEnumeratorsTransform/bullet_is_dash.golden',
        l.render(),
      );
    });

    test('TestBullet', () {
      final emptyItems = _EmptyListItems();
      final cases = <({ListEnumeratorFunc enumerator, int index, String exp})>[
        (enumerator: ListEnumerators.alphabet, index: 0, exp: 'A'),
        (enumerator: ListEnumerators.alphabet, index: 25, exp: 'Z'),
        (enumerator: ListEnumerators.alphabet, index: 26, exp: 'AA'),
        (enumerator: ListEnumerators.alphabet, index: 51, exp: 'AZ'),
        (enumerator: ListEnumerators.alphabet, index: 52, exp: 'BA'),
        (enumerator: ListEnumerators.alphabet, index: 79, exp: 'CB'),
        (enumerator: ListEnumerators.alphabet, index: 701, exp: 'ZZ'),
        (enumerator: ListEnumerators.alphabet, index: 702, exp: 'AAA'),
        (enumerator: ListEnumerators.alphabet, index: 801, exp: 'ADV'),
        (enumerator: ListEnumerators.alphabet, index: 1000, exp: 'ALM'),
        (enumerator: ListEnumerators.roman, index: 0, exp: 'I'),
        (enumerator: ListEnumerators.roman, index: 25, exp: 'XXVI'),
        (enumerator: ListEnumerators.roman, index: 26, exp: 'XXVII'),
        (enumerator: ListEnumerators.roman, index: 50, exp: 'LI'),
        (enumerator: ListEnumerators.roman, index: 100, exp: 'CI'),
        (enumerator: ListEnumerators.roman, index: 701, exp: 'DCCII'),
        (enumerator: ListEnumerators.roman, index: 1000, exp: 'MI'),
      ];

      for (final c in cases) {
        final prefix = c.enumerator(emptyItems, c.index);
        final bullet = prefix.endsWith('.')
            ? prefix.substring(0, prefix.length - 1)
            : prefix;
        expect(bullet, equals(c.exp));
      }
    });

    test('TestEnumeratorsAlign', () {
      final l = LipList(renderConfig: cfg)..enumerator(ListEnumerators.roman);
      for (var i = 0; i < 100; i++) {
        l.item('Foo');
      }
      _expectGolden(
        'test/testdata/list/TestEnumeratorsAlign.golden',
        l.render(),
      );
    });

    test('TestSubListItems2', () {
      final l = LipList(renderConfig: cfg).items([
        'S',
        LipList(renderConfig: cfg)..items(['neovim', 'vscode']),
        'HI',
        LipList(renderConfig: cfg)..items(['vim', 'doom emacs']),
        'Parent 2',
        LipList(renderConfig: cfg)..item('I like fuzzy socks'),
      ]);
      _expectGolden('test/testdata/list/TestSubListItems2.golden', l.render());
    });
  });
}

final class _EmptyListItems implements ListItems {
  @override
  ListItem at(int index) => const _EmptyListItem();

  @override
  int get length => 0;
}

final class _EmptyListItem implements ListItem {
  const _EmptyListItem();

  @override
  ListItems get children => _EmptyListItems();

  @override
  bool get hidden => true;

  @override
  String get value => '';
}
