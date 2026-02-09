import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart';

void main() {
  group('BoxConstraints equality', () {
    test('same values are equal', () {
      final c1 = BoxConstraints(
          minWidth: 10, maxWidth: 100, minHeight: 20, maxHeight: 200);
      final c2 = BoxConstraints(
          minWidth: 10, maxWidth: 100, minHeight: 20, maxHeight: 200);
      expect(c1, equals(c2));
      expect(c1.hashCode, equals(c2.hashCode));
    });

    test('different values are not equal', () {
      final c1 = BoxConstraints(
          minWidth: 10, maxWidth: 100, minHeight: 20, maxHeight: 200);
      final c2 = BoxConstraints(
          minWidth: 11, maxWidth: 100, minHeight: 20, maxHeight: 200);
      expect(c1, isNot(equals(c2)));
    });

    test('constraints with infinity are equal', () {
      final c1 = BoxConstraints(
          minWidth: 0,
          maxWidth: double.infinity,
          minHeight: 0,
          maxHeight: double.infinity);
      final c2 = BoxConstraints(
          minWidth: 0,
          maxWidth: double.infinity,
          minHeight: 0,
          maxHeight: double.infinity);
      expect(c1, equals(c2));
      expect(c1.hashCode, equals(c2.hashCode));
    });

    test('tight constraints with same size are equal', () {
      final c1 = BoxConstraints.tight(Size(50, 60));
      final c2 = BoxConstraints.tight(Size(50, 60));
      expect(c1, equals(c2));
      expect(c1.hashCode, equals(c2.hashCode));
    });

    test('expand constraints with same values are equal', () {
      final c1 = BoxConstraints.expand(width: 100, height: 200);
      final c2 = BoxConstraints.expand(width: 100, height: 200);
      expect(c1, equals(c2));
      expect(c1.hashCode, equals(c2.hashCode));
    });

    test('same instance is equal to itself', () {
      final c1 = BoxConstraints(
          minWidth: 10, maxWidth: 100, minHeight: 20, maxHeight: 200);
      expect(c1, equals(c1));
    });

    test('default constraints are equal', () {
      final c1 = BoxConstraints();
      final c2 = BoxConstraints();
      expect(c1, equals(c2));
      expect(c1.hashCode, equals(c2.hashCode));
    });

    test('different type is not equal', () {
      final c1 = BoxConstraints(
          minWidth: 10, maxWidth: 100, minHeight: 20, maxHeight: 200);
      expect(c1, isNot(equals('not a BoxConstraints')));
      expect(c1, isNot(equals(null)));
      expect(c1, isNot(equals(42)));
    });
  });
}
