import 'package:ormed/src/core/sql_null.dart';
import 'package:test/test.dart';

class _SqlNullWrapper {
  const _SqlNullWrapper(this.isSqlNull);

  final bool isSqlNull;
}

void main() {
  group('SQL null helpers', () {
    test('detects SQL null wrappers', () {
      expect(isSqlNullValue(const _SqlNullWrapper(true)), isTrue);
      expect(isSqlNullValue(const _SqlNullWrapper(false)), isFalse);
    });

    test('treats null as effectively null', () {
      expect(isEffectivelyNull(null), isTrue);
      expect(isEffectivelyNull(const _SqlNullWrapper(true)), isTrue);
      expect(isEffectivelyNull(const _SqlNullWrapper(false)), isFalse);
      expect(isEffectivelyNull('value'), isFalse);
    });
  });
}
