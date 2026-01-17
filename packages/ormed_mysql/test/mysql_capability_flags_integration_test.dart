import 'package:driver_tests/driver_tests.dart';
import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

import 'support/mysql_test_harness.dart';

Future<void> main() async {
  final harness = await createMySqlTestHarness(
    adapterOptions: const {
      'supportsWindowFunctions': false,
      'supportsLateralJoins': false,
    },
    dataSourceName: 'driver_tests_mysql_flags',
  );

  tearDownAll(() async {
    await harness.dispose();
  });

  ormedGroup('MySQL capability flags', (dataSource) {
    test('limitPerGroup throws when window functions disabled', () {
      expect(
        () => dataSource.context.query<Author>().limitPerGroup(1, 'id').toSql(),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('lateral joins throw when disabled', () {
      final subquery = dataSource.context.query<Post>().limit(1);
      expect(
        () => dataSource.context
            .query<Author>()
            .joinLateral(
              subquery,
              'recent_posts',
              on: (join) =>
                  join.on('recent_posts.author_id', '=', 'base.id'),
            )
            .toSql(),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });
}
