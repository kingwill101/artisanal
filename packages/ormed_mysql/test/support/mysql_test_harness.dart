import 'dart:io';

import 'package:driver_tests/driver_tests.dart';
import 'package:ormed/ormed.dart';
import 'package:ormed_mysql/ormed_mysql.dart';

/// Reusable MySQL test harness for driver packages.
///
/// This sets up a DataSource with the driver test registry, registers
/// codecs, and provides adapter factory for parallel test isolation.
///
/// MySQL uses databases for isolation (schema = database in MySQL),
/// so each test group gets its own database with unique table prefixes.
class MySqlTestHarness {
  MySqlTestHarness({
    required this.adapter,
    required this.dataSource,
    required this.registry,
    required this.connectionUrl,
    required this.connectionInfo,
    required this.customCodecs,
    required this.logging,
    required this.enableNamedTimezones,
    required this.adapterOptions,
  });

  final MySqlDriverAdapter adapter;
  final DataSource dataSource;
  final ModelRegistry registry;
  final String connectionUrl;
  final MySqlConnectionInfo connectionInfo;
  final Map<String, ValueCodec<dynamic>> customCodecs;
  final bool logging;
  final bool enableNamedTimezones;
  final Map<String, Object?> adapterOptions;

  /// Create a new adapter for test isolation (parallel mode)
  ///
  /// Returns a fresh adapter that will connect to the same MySQL server
  /// but will use a unique database for this test group.
  /// The TestDatabaseManager will call createSchema/setCurrentSchema
  /// to set up the isolated database.
  MySqlDriverAdapter createTestAdapter(String testDbName) {
    // For MySQL, createSchema creates a database.
    // We connect to the base database initially, then TestDatabaseManager
    // will create and switch to the test-specific database.
    return MySqlDriverAdapter.custom(
      config: DatabaseConfig(
        driver: 'mysql',
        options: {
          'url': connectionUrl,
          'ssl': connectionInfo.secure,
          ...adapterOptions,
        },
      ),
    );
  }

  Future<void> dispose() async {
    await dataSource.dispose();
    await adapter.close();
  }
}

/// Creates a MySQL test harness for driver tests.
///
/// Uses the `MYSQL_URL` environment variable if set, otherwise
/// defaults to `mysql://root:secret@localhost:6605/orm_test`.
///
/// For concurrent test execution, each test group gets its own MySQL database.
/// MySQL treats schemas as databases, so we use database-level isolation.
///
/// Example:
/// ```dart
/// void main() async {
///   final harness = await createMySqlTestHarness();
///
///   tearDownAll(() async {
///     await harness.dispose();
///   });
///
///   // Tests use ormedTest() which gets isolated databases automatically
///   runAllDriverTests();
/// }
/// ```
Future<MySqlTestHarness> createMySqlTestHarness({
  String? url,
  bool logging = true,
  bool enableNamedTimezones = true,
  Map<String, Object?> adapterOptions = const {},
  String dataSourceName = 'driver_tests_mysql_base',
}) async {
  registerOrmFactories();
  MySqlDriverAdapter.registerCodecs();

  final resolvedUrl =
      url ??
      Platform.environment['MYSQL_URL'] ??
      'mysql://root:secret@localhost:6605/orm_test';

  // Parse the connection URL for later use
  final connectionInfo = MySqlConnectionInfo.fromUrl(
    resolvedUrl,
    secureByDefault: true,
  );

  final resolvedOptions = <String, Object?>{
    'url': resolvedUrl,
    'ssl': connectionInfo.secure,
    ...adapterOptions,
  };

  final adapter = MySqlDriverAdapter.custom(
    config: DatabaseConfig(driver: 'mysql', options: resolvedOptions),
  );

  final registry = bootstrapOrm();

  // Custom codecs used by driver_tests fixtures.
  final customCodecs = <String, ValueCodec<dynamic>>{
    'PostgresPayloadCodec': const PostgresPayloadCodec(),
    'SqlitePayloadCodec': const SqlitePayloadCodec(),
    'MariaDbPayloadCodec': const MariaDbPayloadCodec(),
    'JsonMapCodec': const JsonMapCodec(),
    'json': const JsonMapCodec(),
    'bool': const MySqlBoolCodec(),
    'bool?': const MySqlBoolCodec(),
    'Map<String, Object?>': const JsonMapCodec(),
    'Map<String, Object?>?': const JsonMapCodec(),
  };

  // Register globally so ValueCodecRegistry.instance stays in sync for helpers
  // that don't receive DataSourceOptions.codecs.
  customCodecs.forEach((key, codec) {
    ValueCodecRegistry.instance.registerCodec(key: key, codec: codec);
  });

  final dataSource = DataSource(
    DataSourceOptions(
      name: dataSourceName,
      driver: adapter,
      entities: registry.allDefinitions,
      registry: registry,
      codecs: customCodecs,
      logging: logging,
      enableNamedTimezones: enableNamedTimezones,
    ),
  );

  await dataSource.init();

  setUpOrmed(
    dataSource: dataSource,
    migrationDescriptors: driverTestMigrationEntries
        .map(
          (e) => MigrationDescriptor.fromMigration(
            id: e.id,
            migration: e.migration,
            defaultSchema: dataSource.options.defaultSchema,
            tablePrefix: dataSource.options.tablePrefix,
          ),
        )
        .toList(),
    // Use 'migrateWithTransactions' strategy for MySQL for much better performance.
    // This uses transactions for test isolation (rollback after each test).
    // Each test group still gets its own database, but tests within a group
    // use transaction rollback for fast cleanup.
    strategy: DatabaseIsolationStrategy.migrateWithTransactions,
    adapterFactory: (dbName) {
      // Create a new adapter for each test group.
      // The TestDatabaseManager will call setCurrentSchema(dbName) to
      // switch to the test group's database.
      return MySqlDriverAdapter.custom(
        config: DatabaseConfig(driver: 'mysql', options: resolvedOptions),
      );
    },
  );

  return MySqlTestHarness(
    adapter: adapter,
    dataSource: dataSource,
    registry: registry,
    connectionUrl: resolvedUrl,
    connectionInfo: connectionInfo,
    customCodecs: customCodecs,
    logging: logging,
    enableNamedTimezones: enableNamedTimezones,
    adapterOptions: adapterOptions,
  );
}
