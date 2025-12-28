import 'package:test/test.dart';
import 'package:driver_tests/driver_tests.dart';
import 'package:ormed/ormed.dart';

import 'support/postgres_test_harness.dart';

Future<void> main() async {
  final harness = await createPostgresTestHarness();

  tearDownAll(() async {
    await harness.dispose();
  });

  runAllDriverTests();
  runRawQueryOrderGroupByPreviewTests();
}

void runRawQueryOrderGroupByPreviewTests() {
  ormedGroup('Raw Query Helpers (Postgres preview)', (dataSource) {
    final supportsRaw = dataSource.options.driver.metadata.supportsCapability(
      DriverCapability.rawSQL,
    );

    test('includes raw SQL fragments and bindings in order', () {
      final preview = dataSource.context
          .query<Post>()
          .whereRaw('status = ?', ['draft'])
          .groupByRaw('CASE WHEN ? THEN status END', [true])
          .orderByRaw('CASE WHEN status = ? THEN 0 ELSE 1 END', ['draft'])
          .toSql();

      expect(preview.sql, contains('GROUP BY CASE WHEN \$2 THEN status END'));
      expect(
        preview.sql,
        contains('ORDER BY CASE WHEN status = \$3 THEN 0 ELSE 1 END'),
      );
      expect(preview.parameters, hasLength(3));
      expect(preview.parameters.first, 'draft');
      expect(
        preview.parameters[1],
        anyOf(isTrue, equals(1)),
        reason: 'boolean may be encoded as bool or int',
      );
      expect(preview.parameters.last, 'draft');
    }, skip: !supportsRaw);
  });
}
