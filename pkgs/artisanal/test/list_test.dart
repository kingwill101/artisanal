import 'package:artisanal/style.dart';
import 'package:test/test.dart';

void main() {
  group('LipList', () {
    test('creates empty list', () {
      final list = LipList();
      expect(list.render(), isEmpty);
    });

    test('creates list with items', () {
      final list = LipList.create(['Foo', 'Bar', 'Baz']);
      final output = list.render();
      expect(output, contains('Foo'));
      expect(output, contains('Bar'));
      expect(output, contains('Baz'));
      expect(output, contains('•')); // Default bullet
    });

    test('uses arabic enumerator', () {
      final list = LipList.create([
        'A',
        'B',
        'C',
      ]).enumerator(ListEnumerators.arabic);
      final output = list.render();
      expect(output, contains('1.'));
      expect(output, contains('2.'));
      expect(output, contains('3.'));
    });

    test('uses roman enumerator', () {
      final list = LipList.create([
        'A',
        'B',
        'C',
        'D',
      ]).enumerator(ListEnumerators.roman);
      final output = list.render();
      expect(output, contains('I.'));
      expect(output, contains('II.'));
      expect(output, contains('III.'));
      expect(output, contains('IV.'));
    });

    test('uses alphabet enumerator', () {
      final list = LipList.create([
        'A',
        'B',
        'C',
      ]).enumerator(ListEnumerators.alphabet);
      final output = list.render();
      expect(output, contains('A.'));
      expect(output, contains('B.'));
      expect(output, contains('C.'));
    });

    test('uses dash enumerator', () {
      final list = LipList.create(['A', 'B']).enumerator(ListEnumerators.dash);
      final output = list.render();
      expect(output, contains('-'));
    });

    test('supports nested lists', () {
      final nested = LipList.create(['Inner 1', 'Inner 2']);
      final list = LipList.create(['Outer', nested, 'After']);
      final output = list.render();
      expect(output, contains('Outer'));
      expect(output, contains('Inner 1'));
      expect(output, contains('Inner 2'));
      expect(output, contains('After'));
    });

    test('applies item style', () {
      final list = LipList.create(['Test']).itemStyle(Style().bold());
      final output = list.render();
      // Bold ANSI codes should be present
      expect(output, contains('\x1b['));
    });

    test('applies enumerator style', () {
      final list = LipList.create(['Test']).enumeratorStyle(Style().dim());
      final output = list.render();
      expect(output, contains('\x1b['));
    });

    test('hides list', () {
      final list = LipList.create(['A', 'B', 'C']).hide();
      expect(list.render(), isEmpty);
      expect(list.isHidden, isTrue);
    });

    test('offset skips items', () {
      final list = LipList.create([
        'A',
        'B',
        'C',
        'D',
        'E',
      ]).offset(1, 1); // Skip first and last
      final output = list.render();
      expect(output, isNot(contains('• A')));
      expect(output, contains('B'));
      expect(output, contains('C'));
      expect(output, contains('D'));
      expect(output, isNot(contains('• E')));
    });

    test('converts to string', () {
      final list = LipList.create(['X']);
      expect(list.toString(), equals(list.render()));
    });
  });

  group('ListEnumerators', () {
    late _MockItems items;

    setUp(() {
      items = _MockItems(5);
    });

    test('bullet returns •', () {
      expect(ListEnumerators.bullet(items, 0), equals('•'));
      expect(ListEnumerators.bullet(items, 4), equals('•'));
    });

    test('dash returns -', () {
      expect(ListEnumerators.dash(items, 0), equals('-'));
    });

    test('asterisk returns *', () {
      expect(ListEnumerators.asterisk(items, 0), equals('*'));
    });

    test('arabic returns 1. 2. 3.', () {
      expect(ListEnumerators.arabic(items, 0), equals('1.'));
      expect(ListEnumerators.arabic(items, 1), equals('2.'));
      expect(ListEnumerators.arabic(items, 9), equals('10.'));
    });

    test('alphabet handles single and double letters', () {
      expect(ListEnumerators.alphabet(items, 0), equals('A.'));
      expect(ListEnumerators.alphabet(items, 25), equals('Z.'));
      expect(ListEnumerators.alphabet(items, 26), equals('AA.'));
    });

    test('roman numerals', () {
      expect(ListEnumerators.roman(items, 0), equals('I.'));
      expect(ListEnumerators.roman(items, 1), equals('II.'));
      expect(ListEnumerators.roman(items, 2), equals('III.'));
      expect(ListEnumerators.roman(items, 3), equals('IV.'));
      expect(ListEnumerators.roman(items, 4), equals('V.'));
      expect(ListEnumerators.roman(items, 8), equals('IX.'));
      expect(ListEnumerators.roman(items, 9), equals('X.'));
    });

    test('fixed creates constant enumerator', () {
      final fixed = ListEnumerators.fixed('→');
      expect(fixed(items, 0), equals('→'));
      expect(fixed(items, 99), equals('→'));
    });

    test('custom uses provided function', () {
      final custom = ListEnumerators.custom((i) => '[${i + 1}]');
      expect(custom(items, 0), equals('[1]'));
      expect(custom(items, 2), equals('[3]'));
    });
  });

  group('ListIndenters', () {
    late _MockItems items;

    setUp(() {
      items = _MockItems(3);
    });

    test('space returns single space', () {
      expect(ListIndenters.space(items, 0), equals(' '));
    });

    test('doubleSpace returns two spaces', () {
      expect(ListIndenters.doubleSpace(items, 0), equals('  '));
    });

    test('tab returns four spaces', () {
      expect(ListIndenters.tab(items, 0), equals('    '));
    });

    test('tree returns pipe for non-last', () {
      expect(ListIndenters.tree(items, 0), equals('│  '));
      expect(ListIndenters.tree(items, 1), equals('│  '));
    });

    test('tree returns spaces for last', () {
      expect(ListIndenters.tree(items, 2), equals('   '));
    });

    test('arrow returns arrow', () {
      expect(ListIndenters.arrow(items, 0), equals('→ '));
    });

    test('fixed creates constant indenter', () {
      final fixed = ListIndenters.fixed('>>');
      expect(fixed(items, 0), equals('>>'));
    });
  });
}

/// Mock implementation of ListItems for testing enumerators/indenters.
class _MockItems implements ListItems {
  final int _length;

  _MockItems(this._length);

  @override
  ListItem at(int index) => _MockItem('Item $index');

  @override
  int get length => _length;
}

class _MockItem implements ListItem {
  @override
  final String value;

  _MockItem(this.value);

  @override
  ListItems get children => _MockItems(0);

  @override
  bool get hidden => false;
}
