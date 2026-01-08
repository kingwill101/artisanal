/// Manages the playground's configured connections using the DataSource API.
library;

import 'dart:io';

import 'package:ormed/ormed.dart';
import 'package:orm_playground/orm_registry.g.dart';
import 'package:ormed_sqlite/ormed_sqlite.dart';
import 'package:path/path.dart' as p;

import 'factories/playground_factories.dart';

/// Helper that manages playground database connections using the DataSource API.
///
/// ## Single-tenant usage:
/// ```dart
/// final database = PlaygroundDatabase();
/// final ds = await database.dataSource();
///
/// final users = await ds.query<User>().get();
/// await ds.repo<Post>().insert(post);
///
/// await database.dispose();
/// ```
///
/// ## Multi-tenant usage:
/// ```dart
/// final database = PlaygroundDatabase();
///
/// final mainDs = await database.dataSource(tenant: 'default');
/// final analyticsDs = await database.dataSource(tenant: 'analytics');
///
/// await database.dispose();
/// ```
class PlaygroundDatabase {
  /// Creates a helper that manages playground database connections.
  factory PlaygroundDatabase({Directory? workspaceRoot}) {
    ensureSqliteDriverRegistration();
    final root = workspaceRoot ?? Directory.current;
    var configFile = File(p.join(root.path, 'ormed.yaml'));
    if (!configFile.existsSync()) {
      configFile = File(p.join(root.path, 'orm.yaml'));
    }
    final config = loadOrmProjectConfig(configFile);
    final path = _deriveDatabasePath(root, config);
    return PlaygroundDatabase._(root: root, config: config, databasePath: path);
  }

  PlaygroundDatabase._({
    required this.root,
    required OrmProjectConfig config,
    required this.databasePath,
  }) : _config = config;

  /// Directory that contains `orm.yaml`.
  final Directory root;

  /// Default SQLite path derived from the active connection or overrides.
  final String databasePath;

  final OrmProjectConfig _config;
  final Map<String, DataSource> _dataSources = {};

  /// Returns all tenant/connection names defined in the configuration.
  ///
  /// This allows iterating over available tenants without hardcoding names:
  /// ```dart
  /// final database = PlaygroundDatabase();
  /// for (final tenant in database.tenantNames) {
  ///   final ds = await database.dataSource(tenant: tenant);
  ///   // ...
  /// }
  /// ```
  Iterable<String> get tenantNames => _config.connections.keys;

  /// Returns a [DataSource] for the given [tenant].
  ///
  /// The DataSource is lazily created and cached. Multiple calls with the
  /// same tenant return the same instance.
  Future<DataSource> dataSource({String tenant = 'default'}) async {
    if (_dataSources.containsKey(tenant)) {
      return _dataSources[tenant]!;
    }

    ensureSqliteDriverRegistration();

    final tenantConfig = _config.withConnection(tenant);
    final driverConfig = tenantConfig.activeConnection.driver;
    final dbPath = _resolveDatabasePath(driverConfig);
    registerPlaygroundFactories();

    final ds = DataSource(
      DataSourceOptions(
        driver: SqliteDriverAdapter.file(dbPath),
        name: tenant,
        database: dbPath,
        registry: buildOrmRegistryWithFactories(),
      ),
    );

    await ds.init();

    ds.enableQueryLog();
    _dataSources[tenant] = ds;
    return ds;
  }

  /// Opens the configured connection for [tenant].
  ///
  /// This is a convenience method that returns the underlying [OrmConnection]
  /// from the [DataSource]. For new code, prefer using [dataSource] directly.
  @Deprecated('Use dataSource() instead for new code')
  Future<OrmConnection> open({String tenant = 'default'}) async {
    final ds = await dataSource(tenant: tenant);
    return ds.connection;
  }

  /// Releases all managed data sources.
  Future<void> dispose() async {
    for (final ds in _dataSources.values) {
      await ds.dispose();
    }
    _dataSources.clear();
  }

  String _resolveDatabasePath(DriverConfig driverConfig) {
    final configured = driverConfig.option('database');
    if (configured != null && configured.isNotEmpty) {
      return p.normalize(p.join(root.path, configured));
    }
    return databasePath;
  }

  static String _deriveDatabasePath(Directory root, OrmProjectConfig config) {
    final configured = config.activeConnection.driver.option('database');
    if (configured != null && configured.isNotEmpty) {
      return p.normalize(p.join(root.path, configured));
    }
    return _defaultDatabasePath(root);
  }

  static String _defaultDatabasePath(Directory root) {
    final override = Platform.environment['PLAYGROUND_DB'];
    if (override != null && override.isNotEmpty) {
      return p.normalize(override);
    }
    final workspaceDatabase = File(
      p.join(root.path, 'orm_playground', 'database.sqlite'),
    );
    if (workspaceDatabase.existsSync()) {
      return workspaceDatabase.path;
    }
    return p.normalize(p.join(root.path, 'database.sqlite'));
  }
}
