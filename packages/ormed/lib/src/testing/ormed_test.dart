import 'dart:async';
import 'dart:math';

import 'package:hashlib/hashlib.dart';
import 'package:meta/meta.dart';
import 'package:test/test.dart';

import '../../migrations.dart';
import '../connection/orm_connection.dart';
import '../data_source.dart';
import '../driver/driver_adapter.dart' show DriverAdapter;
import '../query/query.dart';
import 'test_database_manager.dart';

/// Re-export DatabaseIsolationStrategy as DatabaseRefreshStrategy for backwards compatibility
typedef DatabaseRefreshStrategy = DatabaseIsolationStrategy;

/// Global test counter for unique IDs

/// Configuration object returned by setUpOrmed.
/// Pass this to ormedGroup to ensure the correct manager is used.
class OrmedTestConfig {
  /// Unique key identifying this test configuration
  final String configKey;

  /// The DataSource name
  final String dataSourceName;

  /// Hash to detect configuration changes
  final String _configHash;

  OrmedTestConfig._({
    required this.configKey,
    required this.dataSourceName,
    required String configHash,
  }) : _configHash = configHash;

  /// Hash of the configuration used to create this test environment.
  String get configHash => _configHash;

  /// Get the manager for this configuration
  TestDatabaseManager get manager {
    final m = _managers[configKey];
    if (m == null) {
      throw StateError(
        'No manager found for config key "$configKey". '
        'The test environment may have been disposed or not initialized.',
      );
    }
    return m;
  }

  /// Get the DataSource for this configuration
  DataSource get dataSource => manager.baseDataSource;

  @override
  String toString() => 'OrmedTestConfig($configKey, ds: $dataSourceName)';
}

/// Tracks managers per configuration key.
/// Key: Unique config key (hash of DataSource name + call site)
/// Value: The TestDatabaseManager for that configuration
final Map<String, TestDatabaseManager> _managers = {};

/// Zone key for the current test configuration
final _zoneConfigKey = Object();

/// Zone key for the current group context
final _groupContextKey = Object();

/// Get the current OrmedTestConfig from Zone-local storage
OrmedTestConfig? get _currentZoneConfig {
  return Zone.current[_zoneConfigKey] as OrmedTestConfig?;
}

/// Get the current group context from Zone-local storage
_GroupContext? get _currentGroupContext {
  return Zone.current[_groupContextKey] as _GroupContext?;
}

/// Stack of active configurations (for nested groups)
final List<OrmedTestConfig> _configStack = [];

/// Legacy: The most recently registered config for backwards compatibility.
OrmedTestConfig? _lastRegisteredConfig;

/// Context for the current test group
class _GroupContext {
  DataSource? dataSource;
  final TestDatabaseManager manager;
  final DatabaseIsolationStrategy strategy;
  final String groupId;
  final OrmedTestConfig? config;

  _GroupContext(this.manager, this.strategy, this.groupId, {this.config});
}

/// Global group counter for unique IDs
int _groupCounter = 0;

final Random _groupIdRandom = _createGroupIdRandom();

Random _createGroupIdRandom() {
  try {
    return Random.secure();
  } on UnsupportedError {
    return Random();
  }
}

/// Generate a unique group ID
String _generateGroupId() {
  final timestamp = DateTime.now().microsecondsSinceEpoch;
  final randomBits = _groupIdRandom.nextInt(0x7fffffff);
  return 'g${timestamp}_${randomBits.toRadixString(16)}_${_groupCounter++}';
}

/// Generate a unique configuration key based on DataSource name and call context
String _generateConfigKey(String dataSourceName, {String? hint}) {
  // Use timestamp + counter + datasource name for uniqueness
  final timestamp = DateTime.now().microsecondsSinceEpoch;
  final raw = '$dataSourceName:$timestamp:${hint ?? ''}';
  final hash = sha256.string(raw).toString().substring(0, 16);
  return '${dataSourceName}_$hash';
}

String? _resolveBaseSchemaName({
  required DataSource dataSource,
  required String configKey,
  required bool migrateBaseDatabase,
}) {
  if (!migrateBaseDatabase) {
    return null;
  }
  if (dataSource.options.defaultSchema != null) {
    return null;
  }
  final driverName = dataSource.options.driver.metadata.name.toLowerCase();
  if (driverName != 'postgres') {
    return null;
  }

  final suffix = configKey.split('_').last.trim();
  final hash = suffix.isEmpty
      ? sha256.string(configKey).toString().substring(0, 16)
      : suffix;
  return 'ormed_test_$hash';
}

/// Configures Ormed for testing.
///
/// Call this once in your test file's `main()` before defining tests.
/// Returns an [OrmedTestConfig] that can be passed to [ormedGroup] to ensure
/// the correct database manager is used.
///
/// ```dart
/// Future<void> main() async {
///   final harness = await createTestHarness();
///   final config = setUpOrmed(dataSource: harness.dataSource, ...);
///
///   tearDownAll(() => harness.dispose());
///
///   runAllDriverTests(config); // Pass config to tests
/// }
/// ```
/// [migrateBaseDatabase] defaults to true and runs the configured migrations
/// on the manager's base data source so the connections registered with
/// [ConnectionManager] are usable outside of an [ormedGroup].
OrmedTestConfig setUpOrmed({
  required DataSource dataSource,
  Future<void> Function(DataSource)? runMigrations,
  List<Migration>? migrations,
  List<MigrationDescriptor>? migrationDescriptors,
  List<DatabaseSeeder Function(OrmConnection)>? seeders,
  DatabaseIsolationStrategy strategy =
      DatabaseIsolationStrategy.migrateWithTransactions,
  bool parallel = false, // Deprecated, ignored
  DriverAdapter Function(String testDbName)? adapterFactory,
  bool migrateBaseDatabase = true,

  //TODO
  //ModelRegistry reigstry
  //DriverAdapter adapter // remove datasource and create data source inside setupOrmed when needed dont accept user datasource
}) {
  final dbName = dataSource.options.name;

  // Generate a unique config key for this setUpOrmed call.
  // This ensures that even if multiple test files use the same DataSource name,
  // they get separate managers (unless they explicitly share one).
  final configKey = _generateConfigKey(dbName);

  // Create the configuration hash for collision detection
  final configHash = sha256
      .string(
        '$dbName:${migrations?.length ?? 0}:${migrationDescriptors?.length ?? 0}:$strategy',
      )
      .toString()
      .substring(0, 16);

  // Check for existing manager with same DataSource name.
  // For migrateWithTransactions, we WANT to share the provisioned database
  // across multiple test files (like Laravel's RefreshDatabase).
  // But each test file gets its own config key to track its lifecycle.
  late final TestDatabaseManager resolvedManager;
  var hasResolvedManager = false;

  // Look for an existing manager that can be shared
  for (final entry in _managers.entries) {
    final existingManager = entry.value;
    if (existingManager.baseDataSource.options.name == dbName) {
      // Found an existing manager for the same database
      // Verify configurations match (same migrations, etc.)
      if (strategy == DatabaseIsolationStrategy.migrateWithTransactions) {
        // For migrateWithTransactions, we share the manager
        resolvedManager = existingManager;
        // Store under our config key as well
        _managers[configKey] = resolvedManager;
        hasResolvedManager = true;
        break;
      } else {
        // For other strategies, we need separate databases per test file
        // So create a new manager
      }
    }
  }

  // Create new manager if we didn't find one to share
  if (!hasResolvedManager) {
    final baseSchema = _resolveBaseSchemaName(
      dataSource: dataSource,
      configKey: configKey,
      migrateBaseDatabase: migrateBaseDatabase,
    );
    resolvedManager = TestDatabaseManager(
      baseDataSource: dataSource,
      runMigrations: runMigrations,
      migrations: migrations,
      migrationDescriptors: migrationDescriptors,
      seeders: seeders,
      strategy: strategy,
      adapterFactory: adapterFactory,
      baseSchema: baseSchema,
    );
    _managers[configKey] = resolvedManager;
  }

  // Create the config object
  final config = OrmedTestConfig._(
    configKey: configKey,
    dataSourceName: dbName,
    configHash: configHash,
  );

  // Track as the last registered config for legacy fallback
  _lastRegisteredConfig = config;

  // Push to config stack
  _configStack.add(config);

  setUpAll(() async {
    await resolvedManager.initialize();
  });

  if (migrateBaseDatabase) {
    setUpAll(() async {
      await resolvedManager.migrate(resolvedManager.baseDataSource);
    });
  }

  tearDownAll(() async {
    // Remove from config stack
    _configStack.remove(config);
    if (_lastRegisteredConfig == config) {
      _lastRegisteredConfig = _configStack.isNotEmpty
          ? _configStack.last
          : null;
    }

    await resolvedManager.cleanup();
    _managers.remove(configKey);
  });

  return config;
}

/// Runs a test with database isolation.
///
/// Automatically sets up and tears down database state for each test.
/// The [DataSource] is passed to the test body.
///
/// If called inside an [ormedGroup], this uses the group's [DataSource] and
/// follows the group's isolation strategy. If called standalone, this creates
/// a fresh database for this specific test.
///
/// ```dart
/// ormedTest('creates a user', (db) async {
///   final user = User(name: 'John');
///   await user.save(db);
///
///   expect(user.id, isNotNull);
/// });
/// ```
void ormedTest(
  String description,
  FutureOr<void> Function(DataSource dataSource) body, {
  String? testOn,
  Timeout? timeout,
  dynamic skip,
  dynamic tags,
  Map<String, dynamic>? onPlatform,
  int? retry,
}) {
  test(
    description,
    () async {
      final context = _currentGroupContext;

      // Resolve manager from context/config or fail
      final manager =
          context?.manager ??
          _currentZoneConfig?.manager ??
          _lastRegisteredConfig?.manager ??
          (_managers.isEmpty ? null : _managers.values.first);
      if (manager == null) {
        throw StateError(
          'Ormed test environment not initialized. '
          'ormedTest must be called within an ormedGroup, or call setUpOrmed() first.',
        );
      }

      DataSource dataSource;
      bool isStandalone = context == null;

      if (isStandalone) {
        // Standalone test: create fresh DB
        final testId = 'test_${_generateGroupId()}';
        dataSource = await manager.createDatabase(testId);
        // Optional: begin transaction for consistency, though we drop DB anyway
        await dataSource.beginTransaction();
        dataSource.setAsDefault();
      } else {
        // Group test: use context's datasource
        if (context.dataSource == null) {
          throw StateError(
            'Group DataSource not initialized. Check ormedGroup strategy.',
          );
        }
        dataSource = context.dataSource!;
      }

      try {
        await body(dataSource);
      } finally {
        if (isStandalone) {
          await dataSource.rollback();
          await manager.dropDatabase(dataSource);
        }
      }
    },
    testOn: testOn,
    timeout: timeout,
    skip: skip,
    tags: tags,
    onPlatform: onPlatform,
    retry: retry,
  );
}

/// Runs a test group with database isolation.
///
/// Groups related tests that share a common database setup. Every group gets
/// its own unique [DataSource] (and thus a unique database) for true concurrency.
///
/// Use [ormedGroup] when you have multiple tests that operate on the same
/// schema and you want to avoid the overhead of creating a fresh database
/// for every single test.
///
/// ```dart
/// ormedGroup('User tests', (db) {
///   ormedTest('creates a user', (db) async {
///     // ...
///   });
/// });
/// ```
///
/// Pass [config] from [setUpOrmed] for explicit manager association:
/// ```dart
/// final config = setUpOrmed(dataSource: harness.dataSource, ...);
/// ormedGroup('User tests', (db) { ... }, config: config);
/// ```
@isTestGroup
void ormedGroup(
  String description,
  void Function(DataSource dataSource) body, {
  OrmedTestConfig? config,
  DataSource? dataSource, // Optional override
  List<Migration>? migrations, // Optional override
  DatabaseRefreshStrategy? refreshStrategy,
  String? testOn,
  Timeout? timeout,
  dynamic skip,
  dynamic tags,
  Map<String, dynamic>? onPlatform,
  int? retry,
}) {
  group(
    description,
    () {
      // Resolve the manager to use
      late final TestDatabaseManager manager;
      late final OrmedTestConfig? resolvedConfig;

      // Priority for finding manager:
      // 1. Explicit config parameter
      // 2. Explicit dataSource parameter
      // 3. Parent group's context
      // 4. Current Zone's config
      // 5. Last registered config (legacy fallback)
      // 6. Any available manager (last resort)

      if (config != null) {
        // Explicit config provided - use it
        manager = config.manager;
        resolvedConfig = config;
      } else if (dataSource != null) {
        // Custom dataSource provided - look up its manager or find matching one
        resolvedConfig = null;
        final dsName = dataSource.options.name;

        // First, look for a manager registered for this dataSource
        TestDatabaseManager? foundManager;
        for (final entry in _managers.entries) {
          if (entry.value.baseDataSource.options.name == dsName) {
            foundManager = entry.value;
            break;
          }
        }

        if (foundManager == null) {
          throw StateError(
            'No manager found for DataSource "$dsName". '
            'Call setUpOrmed() with this DataSource first.',
          );
        }

        // Create a new manager with overrides if needed
        if (migrations != null || refreshStrategy != null) {
          manager = TestDatabaseManager(
            baseDataSource: dataSource,
            migrations: migrations ?? foundManager.migrations,
            migrationDescriptors: foundManager.migrationDescriptors,
            seeders: foundManager.seeders,
            strategy: refreshStrategy ?? foundManager.strategy,
            adapterFactory: foundManager.adapterFactory,
            runMigrations: foundManager.runMigrations,
          );
        } else {
          manager = foundManager;
        }
      } else if (_currentGroupContext?.config != null) {
        // Use parent group's config
        resolvedConfig = _currentGroupContext!.config;
        manager = resolvedConfig!.manager;
      } else if (_currentGroupContext != null) {
        // Use parent group's manager (no config)
        resolvedConfig = null;
        manager = _currentGroupContext!.manager;
      } else if (_currentZoneConfig != null) {
        // Use Zone-local config
        resolvedConfig = _currentZoneConfig;
        manager = resolvedConfig!.manager;
      } else if (_lastRegisteredConfig != null) {
        // Legacy fallback: use last registered config
        resolvedConfig = _lastRegisteredConfig;
        manager = resolvedConfig!.manager;
      } else if (_managers.isNotEmpty) {
        // Last resort: use any available manager
        resolvedConfig = null;
        manager = _managers.values.first;
        // Log a warning - this shouldn't happen in well-structured tests
        print(
          '[ormed_test] Warning: No explicit config found for ormedGroup "$description". '
          'Using first available manager. Consider passing config explicitly.',
        );
      } else {
        throw StateError(
          'No test manager available. Call setUpOrmed() in main() first, '
          'or pass config parameter to ormedGroup.',
        );
      }

      final strategy = refreshStrategy ?? manager.strategy;
      final groupId = _generateGroupId();

      // Every group gets its own unique DataSource for true concurrency.
      // This ensures that tests in different groups (even in the same file)
      // do not interfere with each other.
      final groupDataSource = manager.createDataSource(groupId);

      final context = _GroupContext(
        manager,
        strategy,
        groupId,
        config: resolvedConfig,
      );
      context.dataSource = groupDataSource;

      runZoned(() {
        if (dataSource != null) {
          setUpAll(() async {
            await manager.initialize();
          });
        }

        // Provision the unique database for the group
        setUpAll(() async {
          await manager.provisionDatabase(groupDataSource);
        });

        tearDownAll(() async {
          await manager.dropDatabase(groupDataSource);
        });

        if (strategy == DatabaseIsolationStrategy.migrateWithTransactions) {
          setUp(() async {
            await groupDataSource.beginTransaction();
            groupDataSource.setAsDefault();
          });

          tearDown(() async {
            await groupDataSource.rollback();
          });
        } else {
          setUp(() async {
            final ds = groupDataSource;
            final schemaManager = manager.getSchemaManager(ds);

            if (schemaManager != null &&
                strategy == DatabaseIsolationStrategy.truncate) {
              // Fast path: truncate tables
              await schemaManager.truncateAll();
            } else if (strategy == DatabaseIsolationStrategy.recreate) {
              // Slow path: full reset
              if (schemaManager != null) {
                await schemaManager.reset();
              } else {
                await manager.migrate(ds);
              }
            }
            ds.setAsDefault();
          });
        }

        // Execute body to define tests
        body(groupDataSource);
      }, zoneValues: {_groupContextKey: context});
    },
    testOn: testOn,
    timeout: timeout,
    skip: skip,
    tags: tags,
    onPlatform: onPlatform,
    retry: retry,
  );
}

/// Get current test database manager
///
/// Returns the manager from the current group context, or the first available
/// manager if not in a group context.
TestDatabaseManager? get testDatabaseManager {
  if (_currentGroupContext != null) {
    return _currentGroupContext!.manager;
  }
  return _managers.isEmpty ? null : _managers.values.first;
}

/// Get the current test data source (valid inside ormedGroup/ormedTest)
///
/// This is useful for accessing the datasource in `setUp` or `tearDown` blocks
/// within an `ormedGroup`.
DataSource? get currentTestDataSource => _currentGroupContext?.dataSource;

/// Seed data in the current test environment
Future<void> seedTestData(
  List<DatabaseSeeder Function(OrmConnection)> seeders,
  DataSource dataSource,
) async {
  final manager =
      _currentGroupContext?.manager ??
      _managers[dataSource.options.name] ??
      (_managers.isEmpty ? null : _managers.values.first);
  if (manager == null) {
    throw StateError('Ormed test environment not initialized.');
  }
  await manager.seed(seeders, dataSource);
}

/// Preview seeder queries without executing them
Future<List<QueryLogEntry>> previewTestSeed(
  List<DatabaseSeeder Function(OrmConnection)> seeders,
  DataSource dataSource,
) async {
  final manager =
      _currentGroupContext?.manager ??
      _managers[dataSource.options.name] ??
      (_managers.isEmpty ? null : _managers.values.first);
  if (manager == null) {
    throw StateError('Ormed test environment not initialized.');
  }
  return await manager.seedWithPretend(seeders, dataSource, pretend: true);
}

/// Get migration status in the test environment
Future<List<MigrationStatus>> testMigrationStatus(DataSource dataSource) async {
  final manager =
      _currentGroupContext?.manager ??
      _managers[dataSource.options.name] ??
      (_managers.isEmpty ? null : _managers.values.first);
  if (manager == null) {
    throw StateError('Ormed test environment not initialized.');
  }
  return await manager.migrationStatus(dataSource);
}
