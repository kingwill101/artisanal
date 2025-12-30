import 'dart:io';
import 'dart:math';

import 'package:driver_tests/driver_tests.dart';
import 'package:ormed/ormed.dart';
import 'package:ormed_postgres/ormed_postgres.dart';
import 'package:test/test.dart';

void main() {
  // Generate unique schema name for concurrency safety
  final uniqueSchema = 'test_join_${Random().nextInt(1000000)}';

  group('Postgres-specific joins', () {
    late DataSource dataSource;
    late PostgresDriverAdapter driverAdapter;

    setUpAll(() async {
      final url =
          Platform.environment['POSTGRES_URL'] ??
          'postgres://postgres:postgres@localhost:6543/orm_test';

      // Create custom codecs map
      final customCodecs = <String, ValueCodec<dynamic>>{
        'PostgresPayloadCodec': const PostgresPayloadCodec(),
        'SqlitePayloadCodec': const SqlitePayloadCodec(),
        'MariaDbPayloadCodec': const MariaDbPayloadCodec(),
        'JsonMapCodec': const JsonMapCodec(),
      };

      // Create codec registry for the adapter
      PostgresDriverAdapter.registerCodecs();

      for (final entry in customCodecs.entries) {
        ValueCodecRegistry.instance.registerCodec(
          key: entry.key,
          codec: entry.value,
        );
      }

      driverAdapter = PostgresDriverAdapter.custom(
        config: DatabaseConfig(driver: 'postgres', options: {'url': url}),
      );

      final registry = bootstrapOrm();
      dataSource = DataSource(
        DataSourceOptions(
          driver: driverAdapter,
          entities: registry.allDefinitions,
          registry: registry,
          codecs: customCodecs,
          defaultSchema: uniqueSchema,
        ),
      );

      await dataSource.init();
      registerOrmFactories();

      // Create schema for isolation
      await driverAdapter.executeRaw(
        'CREATE SCHEMA IF NOT EXISTS "$uniqueSchema"',
      );
      await driverAdapter.executeRaw('SET search_path TO "$uniqueSchema"');

      await dropDriverTestSchema(driverAdapter, schema: uniqueSchema);
      await resetDriverTestSchema(driverAdapter, schema: uniqueSchema);
    });

    tearDownAll(() async {
      await dropDriverTestSchema(driverAdapter, schema: uniqueSchema);
      // Drop the schema after tests
      await driverAdapter.executeRaw(
        'DROP SCHEMA IF EXISTS "$uniqueSchema" CASCADE',
      );
      await dataSource.dispose();
    });

    test('emits LATERAL join keyword', () async {
      final subquery = dataSource.context
          .query<Post>()
          .orderBy('id', descending: true)
          .limit(1);

      final plan = dataSource.context
          .query<Author>()
          .joinLateral(
            subquery,
            'recent_posts',
            on: (join) => join.on('recent_posts.author_id', '=', 'base.id'),
          )
          .debugPlan();

      final sql = PostgresQueryGrammar().compileSelect(plan).sql;
      expect(sql.toUpperCase(), contains('JOIN LATERAL'));
    });
  });
}
