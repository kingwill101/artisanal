import 'package:ormed/ormed.dart';
import 'package:ormed_sqlite/ormed_sqlite.dart';
import 'package:test/test.dart';

void main() {
  test('supportsReturning can be disabled via config', () {
    final adapter = SqliteDriverAdapter.custom(
      config: DatabaseConfig(
        driver: 'sqlite',
        options: const {'supportsReturning': false},
      ),
    );
    expect(adapter.metadata.supportsReturning, isFalse);
    expect(
      adapter.metadata.supportsCapability(DriverCapability.returning),
      isFalse,
    );
  });

  test('returning clauses are suppressed when disabled', () async {
    final adapter = SqliteDriverAdapter.custom(
      config: DatabaseConfig(
        driver: 'sqlite',
        options: const {
          'memory': true,
          'supportsReturning': false,
        },
      ),
    );
    final context = QueryContext(
      registry: ModelRegistry(),
      driver: adapter,
    );

    await adapter.executeRaw(
      'CREATE TABLE returning_tests (id INTEGER, name TEXT)',
    );

    try {
      final columns = const [
        AdHocColumn(name: 'id', columnName: 'id'),
        AdHocColumn(name: 'name', columnName: 'name'),
      ];
      final plan = context
          .table('returning_tests', columns: columns)
          .previewInsertPlan([
            {'id': 1, 'name': 'alpha'},
          ], returning: true);

      final preview = context.describeMutation(plan);
      expect(
        preview.sql,
        isNot(matches(RegExp(r'\\bRETURNING\\b', caseSensitive: false))),
      );
    } finally {
      await adapter.executeRaw('DROP TABLE IF EXISTS returning_tests');
      await adapter.close();
    }
  });
}
