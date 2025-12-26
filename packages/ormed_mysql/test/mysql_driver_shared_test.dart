import 'package:driver_tests/driver_tests.dart';
import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

import 'support/mysql_test_harness.dart';

Future<void> main() async {
  final harness = await createMySqlTestHarness();

  tearDownAll(() async {
    await harness.dispose();
  });

  // All driver tests are run using ormedTest/ormedGroup which
  // automatically gets isolated databases via the setUpOrmed configuration
  runAllDriverTests();
  runRawQueryOrderGroupByPreviewTests();
}

void runRawQueryOrderGroupByPreviewTests() {
  ormedGroup('Raw Query Helpers (MySQL preview)', (dataSource) {
    final supportsRaw = dataSource.options.driver.metadata.supportsCapability(
      DriverCapability.rawSQL,
    );

    test(
      'includes raw SQL fragments and bindings in order',
      () {
        final preview = dataSource.context
            .query<Post>()
            .whereRaw('status = ?', ['draft'])
            .groupByRaw('CASE WHEN ? THEN status END', [true])
            .orderByRaw(
              'CASE WHEN status = ? THEN 0 ELSE 1 END',
              ['draft'],
            )
            .toSql();

        expect(
          preview.sql,
          matches(
            RegExp(r'GROUP BY CASE WHEN (\?|:p\d+|\$\d+) THEN status END'),
          ),
        );
        expect(
          preview.sql,
          matches(
            RegExp(
              r'ORDER BY CASE WHEN status = (\?|:p\d+|\$\d+) THEN 0 ELSE 1 END',
            ),
          ),
        );
        expect(preview.parameters, hasLength(3));
        expect(preview.parameters.first, 'draft');
        expect(
          preview.parameters[1],
          anyOf(isTrue, equals(1)),
          reason: 'boolean may be encoded as bool or int',
        );
        expect(preview.parameters.last, 'draft');
      },
      skip: !supportsRaw,
    );
  });
}
