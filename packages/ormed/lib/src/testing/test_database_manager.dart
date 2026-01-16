import 'dart:async';

import '../../migrations.dart';
import '../connection/orm_connection.dart';
import '../data_source.dart';
import '../driver/driver_adapter.dart';
import '../query/query.dart';
import 'test_schema_manager.dart';

/// Defines strategies for database isolation in tests.
enum DatabaseIsolationStrategy {
  /// Runs migrations before each group.
  migrate,

  /// Uses transactions for each test.
  ///
  /// This is the fastest strategy as it rolls back the transaction after each test.
  migrateWithTransactions,

  /// Truncates tables after each test.
  ///
  /// Slower than transactions but works across all drivers.
  truncate,

  /// Drops and recreates the schema after each test.
  ///
  /// The slowest but most thorough isolation strategy.
  recreate,
}

/// Manages the lifecycle and isolation of test databases.
class TestDatabaseManager {
  final DataSource _baseDataSource;
  final Future<void> Function(DataSource)? _runMigrations;
  final List<Migration>? _migrations;
  final List<MigrationDescriptor>? _migrationDescriptors;
  final DatabaseIsolationStrategy _strategy;
  final List<DatabaseSeeder Function(OrmConnection)>? _seeders;
  final DriverAdapter Function(String testDbName)? _adapterFactory;
  final String? _baseSchema;

  /// Resolved migration descriptors
  List<MigrationDescriptor>? _resolvedMigrationDescriptors;

  /// Track all created databases for cleanup
  final Set<String> _createdDatabases = {};

  /// Track all created DataSources for cleanup
  final List<DataSource> _createdDataSources = [];

  TestDatabaseManager({
    required DataSource baseDataSource,
    Future<void> Function(DataSource)? runMigrations,
    List<Migration>? migrations,
    List<MigrationDescriptor>? migrationDescriptors,
    List<DatabaseSeeder Function(OrmConnection)>? seeders,
    DatabaseIsolationStrategy strategy =
        DatabaseIsolationStrategy.migrateWithTransactions,
    DriverAdapter Function(String testDbName)? adapterFactory,
    String? baseSchema,
    // Deprecated/Removed parameters
    bool parallel = false,
  }) : _baseDataSource = baseDataSource,
       _runMigrations = runMigrations,
       _migrations = migrations,
       _migrationDescriptors = migrationDescriptors,
       _seeders = seeders,
       _strategy = strategy,
       _adapterFactory = adapterFactory,
       _baseSchema = baseSchema;

  DatabaseIsolationStrategy get strategy => _strategy;

  DataSource get baseDataSource => _baseDataSource;

  List<Migration>? get migrations => _migrations;

  List<MigrationDescriptor>? get migrationDescriptors => _migrationDescriptors;

  List<DatabaseSeeder Function(OrmConnection)>? get seeders => _seeders;

  DriverAdapter Function(String testDbName)? get adapterFactory =>
      _adapterFactory;

  Future<void> Function(DataSource)? get runMigrations => _runMigrations;

  /// Initialize the test database manager
  Future<void> initialize() async {
    _resolvedMigrationDescriptors = _resolveMigrationDescriptors();
    await _baseDataSource.init();
  }

  /// Create a DataSource object synchronously without provisioning the DB
  DataSource createDataSource(String id) {
    final options = _baseDataSource.options;
    final driver = options.driver;

    final testDbName = 'test_${id.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_')}';

    // Get fresh adapter
    final testDriver = _adapterFactory != null
        ? _adapterFactory(testDbName)
        : driver;

    // Create DataSource
    final testOptions = options.copyWith(
      name: testDbName,
      defaultSchema: testDbName,
      driver: testDriver,
    );

    return DataSource(testOptions);
  }

  /// Provision the database/schema on the server and initialize the DataSource
  ///
  /// For PostgreSQL: Creates a schema within the current database and sets search_path.
  /// For MySQL: Creates a database and switches to it.
  /// For SQLite: Uses the test database file.
  Future<void> provisionDatabase(DataSource dataSource) async {
    final driver = _baseDataSource.connection.driver;

    // Verify driver supports schema operations
    if (driver is! SchemaDriver) {
      throw StateError(
        'TestDatabaseManager requires a SchemaDriver implementation. '
        'Driver ${driver.runtimeType} does not support schema/database operations.',
      );
    }

    final schemaDriver = driver as SchemaDriver;
    final dbName = dataSource.options.defaultSchema;

    if (dbName != null) {
      // Try to create as schema first (for PostgreSQL)
      // If that fails or isn't supported, fall back to database creation
      final schemaCreated = await schemaDriver.createSchema(dbName);

      if (schemaCreated) {
        // Schema was created - set it as current schema for this adapter
        await schemaDriver.setCurrentSchema(dbName);
      } else {
        // Schema creation not supported or schema already exists
        // Try database creation (for MySQL) or just proceed (for SQLite)
        try {
          await schemaDriver.createDatabase(dbName);
        } catch (e) {
          // Ignore errors - database might already exist or not be supported
        }
      }

      // Track the created schema/database for cleanup
      _createdDatabases.add(dbName);
    }

    // Track the DataSource for cleanup
    _createdDataSources.add(dataSource);

    await dataSource.init();

    // Set the schema again on the datasource's driver if it's different from base
    final dsDriver = dataSource.connection.driver;
    if (dsDriver is SchemaDriver && dbName != null) {
      try {
        await (dsDriver as SchemaDriver).setCurrentSchema(dbName);
      } catch (_) {
        // Ignore if not supported
      }
    }

    await _prepareDatabase(dataSource);
  }

  /// Create a new isolated database for a test group or standalone test
  Future<DataSource> createDatabase(String id) async {
    final dataSource = createDataSource(id);
    await provisionDatabase(dataSource);
    return dataSource;
  }

  /// Drop a created database/schema
  Future<void> dropDatabase(DataSource dataSource) async {
    final driver = _baseDataSource.connection.driver;
    final dbName = dataSource.options.defaultSchema;

    if (driver is SchemaDriver && dbName != null) {
      try {
        // Try dropping as schema first (for PostgreSQL)
        final schemaDropped = await (driver as SchemaDriver).dropSchemaIfExists(
          dbName,
        );

        if (!schemaDropped) {
          // Schema drop not supported - try database drop
          await (driver as SchemaDriver).dropDatabaseIfExists(dbName);
        }
      } catch (e) {
        // Log but don't fail - database might already be dropped
        print(
          '[TestDatabaseManager] Warning: Failed to drop database/schema $dbName: $e',
        );
      }
      _createdDatabases.remove(dbName);
    }

    _createdDataSources.remove(dataSource);

    try {
      await dataSource.dispose();
    } catch (e) {
      // Log but don't fail - datasource might already be disposed
      print('[TestDatabaseManager] Warning: Failed to dispose datasource: $e');
    }
  }

  /// Run migrations on a specific datasource
  Future<void> migrate(DataSource dataSource) async {
    await _ensureBaseSchema(dataSource);
    await _prepareDatabase(dataSource);
  }

  Future<void> _ensureBaseSchema(DataSource dataSource) async {
    final baseSchema = _baseSchema;
    if (baseSchema == null) {
      return;
    }
    if (!identical(dataSource, _baseDataSource)) {
      return;
    }
    if (dataSource.options.defaultSchema != null) {
      return;
    }

    final driver = dataSource.connection.driver;
    if (driver is! SchemaDriver) {
      return;
    }

    final schemaDriver = driver as SchemaDriver;
    if (!_createdDatabases.contains(baseSchema)) {
      await schemaDriver.createSchema(baseSchema);
      _createdDatabases.add(baseSchema);
    }
    await schemaDriver.setCurrentSchema(baseSchema);
  }

  /// Run seeders on a specific datasource
  Future<void> seed(
    List<DatabaseSeeder Function(OrmConnection)> seeders,
    DataSource dataSource,
  ) async {
    for (final factory in seeders) {
      final seeder = factory(dataSource.connection);
      await seeder.run();
    }
  }

  /// Preview seeders
  Future<List<QueryLogEntry>> seedWithPretend(
    List<DatabaseSeeder Function(OrmConnection)> seeders,
    DataSource dataSource, {
    bool pretend = true,
  }) async {
    return [];
  }

  /// Get migration status
  Future<List<MigrationStatus>> migrationStatus(DataSource dataSource) async {
    final driver = dataSource.connection.driver;
    if (driver is SchemaDriver) {
      final descriptors =
          _resolvedMigrationDescriptors ?? _resolveMigrationDescriptors();
      if (descriptors == null) return [];
      final manager = TestSchemaManager(
        schemaDriver: driver as SchemaDriver,
        migrations: descriptors,
      );
      return await manager.status();
    }
    return [];
  }

  Future<void> _prepareDatabase(DataSource dataSource) async {
    if (_runMigrations != null) {
      await _runMigrations(dataSource);
      if (_seeders != null && _seeders.isNotEmpty) {
        await _runSeeders(dataSource);
      }
      return;
    }

    final descriptors =
        _resolvedMigrationDescriptors ?? _resolveMigrationDescriptors();
    if (descriptors == null || descriptors.isEmpty) {
      return;
    }

    final driver = dataSource.connection.driver;
    if (driver is SchemaDriver) {
      final schemaManager = TestSchemaManager(
        schemaDriver: driver as SchemaDriver,
        migrations: descriptors,
        tablePrefix: dataSource.options.tablePrefix,
      );
      await schemaManager.setup();

      if (_seeders != null && _seeders.isNotEmpty) {
        await schemaManager.seed(dataSource.connection, _seeders);
      }
    }
  }

  Future<void> _runSeeders(DataSource dataSource) async {
    final seeders = _seeders;
    if (seeders == null || seeders.isEmpty) {
      return;
    }

    for (final factory in seeders) {
      final seeder = factory(dataSource.connection);
      await seeder.run();
    }
  }

  List<MigrationDescriptor>? _resolveMigrationDescriptors() {
    final descriptors = _migrationDescriptors;
    if (descriptors != null && descriptors.isNotEmpty) {
      return descriptors;
    }

    if (_migrations == null || _migrations.isEmpty) {
      return null;
    }

    final resolved = <MigrationDescriptor>[];
    final migrations = _migrations;
    final defaultSchema = _baseDataSource.options.defaultSchema;
    final tablePrefix = _baseDataSource.options.tablePrefix;
    for (var i = 0; i < migrations.length; i++) {
      final migration = migrations[i];
      resolved.add(
        MigrationDescriptor.fromMigration(
          id: MigrationId(
            DateTime.utc(2023, 1, 1, 0, 0, i + 1),
            migration.runtimeType.toString(),
          ),
          migration: migration,
          defaultSchema: defaultSchema,
          tablePrefix: tablePrefix,
        ),
      );
    }

    return resolved;
  }

  /// Cleanup all created test databases
  ///
  /// This method should be called in tearDownAll to ensure all test databases
  /// are properly dropped after tests complete.
  Future<void> cleanup() async {
    // Only try to drop databases if the base datasource was initialized
    if (_baseDataSource.isInitialized) {
      final driver = _baseDataSource.connection.driver;

      // Drop all tracked databases
      if (driver is SchemaDriver) {
        final schemaDriver = driver as SchemaDriver;
        final databasesToClean = Set<String>.from(_createdDatabases);

        for (final dbName in databasesToClean) {
          try {
            // Try dropping as schema first (Postgres)
            final dropped = await schemaDriver.dropSchemaIfExists(dbName);
            if (!dropped) {
              // Then try as database (MySQL)
              await schemaDriver.dropDatabaseIfExists(dbName);
            }
            _createdDatabases.remove(dbName);
          } catch (e) {
            print(
              '[TestDatabaseManager] Warning: Failed to drop database/schema $dbName during cleanup: $e',
            );
          }
        }
      }
    }

    // Dispose all tracked DataSources
    final dataSourcesToDispose = List<DataSource>.from(_createdDataSources);
    for (final ds in dataSourcesToDispose) {
      try {
        await ds.dispose();
      } catch (e) {
        // Ignore - might already be disposed
      }
    }
    _createdDataSources.clear();

    // Dispose the base datasource
    try {
      await _baseDataSource.dispose();
    } catch (e) {
      // Ignore - might already be disposed
    }
  }

  // Helper to get a schema manager for a specific datasource
  TestSchemaManager? getSchemaManager(DataSource dataSource) {
    final driver = dataSource.connection.driver;
    if (driver is SchemaDriver) {
      final descriptors =
          _resolvedMigrationDescriptors ?? _resolveMigrationDescriptors();
      if (descriptors == null) return null;
      return TestSchemaManager(
        schemaDriver: driver as SchemaDriver,
        migrations: descriptors,
      );
    }
    return null;
  }
}
