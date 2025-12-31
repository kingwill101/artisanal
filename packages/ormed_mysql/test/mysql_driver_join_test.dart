import 'dart:io';

import 'package:driver_tests/driver_tests.dart';
import 'package:ormed/ormed.dart';
import 'package:ormed_mysql/ormed_mysql.dart';
import 'package:test/test.dart';

/// Creates a simple MySQL harness for SQL-only tests that don't need ormedTest.
/// This avoids the setUpOrmed() call which conflicts with tests that have their own setUpAll.
Future<(MySqlDriverAdapter, DataSource)> _createSimpleHarness() async {
  registerOrmFactories();
  MySqlDriverAdapter.registerCodecs();

  final url =
      Platform.environment['MYSQL_URL'] ??
      'mysql://root:secret@localhost:6605/orm_test';

  final adapter = MySqlDriverAdapter.custom(
    config: DatabaseConfig(
      driver: 'mysql',
      options: {'url': url, 'ssl': true, 'secure': true},
    ),
  );

  final registry = bootstrapOrm();

  final dataSource = DataSource(
    DataSourceOptions(
      name: 'mysql_join_test',
      driver: adapter,
      entities: registry.allDefinitions,
      registry: registry,
      logging: false,
    ),
  );

  await dataSource.init();
  return (adapter, dataSource);
}

Future<void> main() async {
  late MySqlDriverAdapter adapter;
  late DataSource dataSource;

  setUpAll(() async {
    final result = await _createSimpleHarness();
    adapter = result.$1;
    dataSource = result.$2;
  });

  tearDownAll(() async {
    await dataSource.dispose();
    await adapter.close();
  });

  group('MySQL-specific joins', () {
    test('emits STRAIGHT_JOIN keyword', () async {
      final plan = dataSource.context
          .query<Post>()
          .straightJoin('authors', 'authors.id', '=', 'posts.author_id')
          .debugPlan();

      final sql = MySqlQueryGrammar().compileSelect(plan).sql;
      expect(sql.toUpperCase(), contains('STRAIGHT_JOIN'));
    });

    test('joinLateral emits keyword', () async {
      final subquery = dataSource.context.query<Post>().limit(1);
      final plan = dataSource.context
          .query<Author>()
          .joinLateral(
            subquery,
            'recent_posts',
            on: (join) => join.on('recent_posts.author_id', '=', 'base.id'),
          )
          .debugPlan();

      final sql = MySqlQueryGrammar().compileSelect(plan).sql;
      expect(sql.toUpperCase(), contains('JOIN LATERAL'));
    });
  });
}
