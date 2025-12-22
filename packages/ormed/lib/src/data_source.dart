import 'dart:async';

import 'carbon_config.dart';
import 'connection/connection.dart';
import 'contracts.dart';
import 'driver/driver.dart';
import 'model/model.dart';
import 'query/query.dart';
import 'repository/repository.dart';
import 'value_codec.dart';
import 'orm_project_config.dart';
import 'driver/driver_adapter_registry.dart';

/// Configuration options for initializing a [DataSource].
///
/// Provides a declarative way to configure the ORM with all required
/// components in a single object.
///
/// ```dart
/// final options = DataSourceOptions(
///   driver: SqliteDriverAdapter.file('app.sqlite'),
///   entities: [UserOrmDefinition.definition, PostOrmDefinition.definition],
/// );
/// ```
class DataSourceOptions {
  DataSourceOptions({
    required this.driver,
    List<ModelDefinition<OrmEntity>> entities = const [],
    this.registry,
    this.scopeRegistry,
    this.name = 'default',
    this.database,
    this.tablePrefix = '',
    this.defaultSchema,
    this.codecs = const {},
    this.logging = false,
    this.logFilePath,
    this.carbonTimezone = 'UTC',
    this.carbonLocale = 'en_US',
    this.enableNamedTimezones = false,
  }) : entities = entities.isNotEmpty
           ? entities
           : (registry?.allDefinitions ?? const []),
       assert(
         entities.isNotEmpty || registry != null,
         'Either entities or registry must be provided',
       );

  /// The database driver adapter to use for connections.
  final DriverAdapter driver;

  /// List of model definitions (entities) to register with this data source.
  final List<ModelDefinition<OrmEntity>> entities;

  /// Optional pre-built model registry with type aliases already registered.
  /// If provided, this registry will be used instead of creating a new one.
  final ModelRegistry? registry;

  /// Optional scope registry to use for this data source.
  ///
  /// If omitted, a new [ScopeRegistry] is created per connection context. That
  /// registry will copy any registrations from [ScopeRegistry.instance] (the
  /// global template), so generated bootstrapping can register scopes once and
  /// have them apply automatically without sharing mutable state across
  /// connections.
  final ScopeRegistry? scopeRegistry;

  /// Logical name for this connection. Defaults to 'default'.
  final String name;

  /// Optional database/catalog identifier for observability.
  final String? database;

  /// Table prefix automatically applied by some schemas.
  final String tablePrefix;

  /// Default schema applied to ad-hoc tables when not specified.
  final String? defaultSchema;

  /// Additional value codecs to register beyond the standard set.
  final Map<String, ValueCodec<dynamic>> codecs;

  /// Whether to enable query logging and default contextual query logs.
  final bool logging;

  /// Optional base file path for contextual logging output.
  ///
  /// When set, query logs are written to daily rotating log files at this path.
  /// Example: "logs/ormed" yields "logs/ormed-YYYY-MM-DD.log".
  final String? logFilePath;

  /// Default timezone for Carbon date/time instances.
  /// Defaults to 'UTC'. Use 'America/New_York', 'Europe/London', etc.
  /// for named timezones (requires [enableNamedTimezones] = true).
  final String carbonTimezone;

  /// Default locale for Carbon date/time formatting.
  /// Defaults to 'en_US'. Supports 170+ locales like 'fr_FR', 'es_ES', etc.
  final String carbonLocale;

  /// Whether to enable named timezone support via TimeMachine.
  /// Set to true if you need named timezones like 'America/New_York'.
  /// UTC and fixed offsets ('+05:30') work without this.
  final bool enableNamedTimezones;

  DataSourceOptions copyWith({
    DriverAdapter? driver,
    List<ModelDefinition<OrmEntity>>? entities,
    ModelRegistry? registry,
    ScopeRegistry? scopeRegistry,
    String? name,
    String? database,
    String? tablePrefix,
    String? defaultSchema,
    Map<String, ValueCodec<dynamic>>? codecs,
    bool? logging,
    String? logFilePath,
    String? carbonTimezone,
    String? carbonLocale,
    bool? enableNamedTimezones,
  }) => DataSourceOptions(
    driver: driver ?? this.driver,
    entities: entities ?? this.entities,
    registry: registry ?? this.registry,
    scopeRegistry: scopeRegistry ?? this.scopeRegistry,
    name: name ?? this.name,
    database: database ?? this.database,
    tablePrefix: tablePrefix ?? this.tablePrefix,
    defaultSchema: defaultSchema ?? this.defaultSchema,
    codecs: codecs ?? this.codecs,
    logging: logging ?? this.logging,
    logFilePath: logFilePath ?? this.logFilePath,
    carbonTimezone: carbonTimezone ?? this.carbonTimezone,
    carbonLocale: carbonLocale ?? this.carbonLocale,
    enableNamedTimezones: enableNamedTimezones ?? this.enableNamedTimezones,
  );
}

/// A unified entry point for ORM operations that manages connections,
/// model registration, and provides ergonomic access to queries and repositories.
///
/// ## Single Data Source Example
///
/// ```dart
/// final ds = DataSource(DataSourceOptions(
///   driver: SqliteDriverAdapter.file('app.sqlite'),
///   entities: [UserOrmDefinition.definition, PostOrmDefinition.definition],
/// ));
///
/// await ds.init();
///
/// // Query data
/// final users = await ds.query<User>().whereEquals('active', true).get();
///
/// // Use repository
/// final userRepo = ds.repo<User>();
/// await userRepo.insert(newUser);
///
/// // Transaction
/// await ds.transaction(() async {
///   await ds.repo<User>().insert(user);
///   await ds.repo<Post>().insert(post);
/// });
///
/// await ds.dispose();
/// ```
///
/// ## Multi-Tenant Example
///
/// ```dart
/// final mainDs = DataSource(DataSourceOptions(
///   name: 'main',
///   driver: SqliteDriverAdapter.file('main.sqlite'),
///   entities: entities,
/// ));
///
/// final analyticsDs = DataSource(DataSourceOptions(
///   name: 'analytics',
///   driver: SqliteDriverAdapter.file('analytics.sqlite'),
///   entities: entities,
/// ));
///
/// await mainDs.init();
/// await analyticsDs.init();
///
/// // Query specific data sources
/// final mainUsers = await mainDs.query<User>().get();
/// final analyticsUsers = await analyticsDs.query<User>().get();
/// ```
class DataSource {
  /// Creates a new data source with the given configuration options.
  DataSource(this.options)
    : _registry = options.registry ?? ModelRegistry(),
      _codecRegistry = ValueCodecRegistry.instance.fork(
        codecs: options.codecs,
      ) {
    // no-op: codecs applied via fork above
  }

  /// Creates a [DataSource] from an [OrmProjectConfig].
  ///
  /// This uses the [DriverAdapterRegistry] to instantiate the driver
  /// defined in the configuration.
  factory DataSource.fromConfig(
    OrmProjectConfig config, {
    ModelRegistry? registry,
    ScopeRegistry? scopeRegistry,
    Map<String, ValueCodec<dynamic>> codecs = const {},
  }) {
    final driverConfig = config.driver;
    return DataSource(
      DataSourceOptions(
        driver: DriverAdapterRegistry.create(driverConfig),
        registry: registry,
        scopeRegistry: scopeRegistry,
        name: config.activeConnectionName,
        codecs: codecs,
        logging: driverConfig.options['logging'] == true,
        database: driverConfig.options['database']?.toString(),
        tablePrefix: driverConfig.options['table_prefix']?.toString() ?? '',
        defaultSchema: driverConfig.options['default_schema']?.toString(),
      ),
    );
  }

  /// The configuration options for this data source.
  final DataSourceOptions options;

  final ModelRegistry _registry;
  final ValueCodecRegistry _codecRegistry;
  OrmConnection? _connection;
  bool _initialized = false;

  /// Whether this data source has been initialized.
  bool get isInitialized => _initialized;

  /// The logical name of this data source connection.
  String get name => options.name;

  /// The underlying model registry.
  ModelRegistry get registry => _registry;

  /// The underlying value codec registry.
  ValueCodecRegistry get codecRegistry => _codecRegistry;

  /// The underlying ORM connection.
  ///
  /// Throws [StateError] if the data source has not been initialized.
  OrmConnection get connection {
    _ensureInitialized();
    return _connection!;
  }

  /// The underlying query context.
  ///
  /// This is the lower-level API that powers [query] and [repo]. Use it when
  /// you need advanced hooks, caching, or to construct queries/repositories
  /// from a shared runtime context.
  ///
  /// Throws [StateError] if the data source has not been initialized.
  QueryContext get context {
    _ensureInitialized();
    return _connection!.context;
  }

  /// Initializes the data source by registering all entities and
  /// establishing the database connection.
  ///
  /// Automatically registers this DataSource with ConnectionManager.
  /// If this is the first DataSource registered, it becomes the default.
  ///
  /// Also automatically configures Carbon date/time library based on
  /// the [DataSourceOptions.carbonTimezone], [DataSourceOptions.carbonLocale],
  /// and [DataSourceOptions.enableNamedTimezones] settings.
  ///
  /// Must be called before using [query], [repo], or other database operations.
  ///
  /// ```dart
  /// final ds = DataSource(options);
  /// await ds.init(); // Auto-registers and sets as default if first
  ///
  /// // Static helpers now work
  /// final users = await User.query().get();
  /// ```
  Future<void> init() async {
    if (_initialized) {
      return;
    }

    // Configure Carbon date/time library if not already configured
    if (!CarbonConfig.isTimeMachineConfigured && options.enableNamedTimezones) {
      await CarbonConfig.configureWithTimeMachine(
        defaultTimezone: options.carbonTimezone,
        defaultLocale: options.carbonLocale,
      );
    } else if (CarbonConfig.defaultTimezone == 'UTC' &&
        CarbonConfig.defaultLocale == 'en_US') {
      // Only configure if still at default values (allow manual pre-configuration)
      CarbonConfig.configure(
        defaultTimezone: options.carbonTimezone,
        defaultLocale: options.carbonLocale,
      );
    }

    // Register all model definitions
    _registry.registerAll(options.entities);

    // Create the connection configuration
    final config = ConnectionConfig(
      name: options.name,
      database: options.database,
      tablePrefix: options.tablePrefix,
      defaultSchema: options.defaultSchema,
    );

    // Create the ORM connection
    _connection = OrmConnection(
      config: config,
      driver: options.driver,
      registry: _registry,
      codecRegistry: _codecRegistry,
      scopeRegistry: options.scopeRegistry,
    );

    // Enable logging if requested
    if (options.logging) {
      _connection!.enableQueryLog();
      _connection!.attachDefaultContextualLogger(
        logFilePath: options.logFilePath,
      );
    }

    // Mark as initialized BEFORE registering (registration may access connection)
    _initialized = true;

    // Auto-register with ConnectionManager
    ConnectionManager.instance.registerDataSource(this);

    // If this is the first DataSource, set it as default
    if (!ConnectionManager.instance.hasDefaultConnection) {
      setAsDefault();
    }
  }

  /// Sets this DataSource as the default connection for Model static helpers.
  ///
  /// This enables usage of static methods like `User.query()`, `Post.find()`, etc.
  /// without explicitly passing a connection.
  ///
  /// ```dart
  /// final ds = DataSource(options);
  /// await ds.init();
  /// ds.setAsDefault(); // Now User.query() works
  ///
  /// final users = await User.query().get();
  /// ```
  void setAsDefault() {
    _ensureInitialized();
    // Register if not already registered
    if (!ConnectionManager.instance.isRegistered(options.name)) {
      ConnectionManager.instance.registerDataSource(this);
    }
    ConnectionManager.instance.setDefaultConnection(options.name);
    // Update Model's default connection name so static helpers work
    Model.bindConnectionResolver(
      defaultConnection: options.name,
      connectionManager: ConnectionManager.instance,
    );
    _defaultDataSource = this;
  }

  static DataSource? _defaultDataSource;

  /// Sets a DataSource as the default for Model static helpers.
  ///
  /// This is a convenience method equivalent to calling `dataSource.setAsDefault()`.
  ///
  /// ```dart
  /// final ds = DataSource(options);
  /// await ds.init();
  /// DataSource.setDefault(ds); // Same as ds.setAsDefault()
  ///
  /// final users = await User.query().get();
  /// ```
  static void setDefault(DataSource dataSource) {
    dataSource.setAsDefault();
  }

  /// Returns the current default DataSource, or null if none is set.
  ///
  /// ```dart
  /// final ds = DataSource.getDefault();
  /// if (ds != null) {
  ///   final users = await ds.query<User>().get();
  /// }
  /// ```
  static DataSource? getDefault() => _defaultDataSource;

  /// Clears the default DataSource. Useful for testing.
  static void clearDefault() {
    _defaultDataSource = null;
  }

  /// Creates a typed query builder for the specified model type.
  ///
  /// {@macro ormed.query}
  Query<T> query<T extends OrmEntity>() {
    _ensureInitialized();
    return _connection!.query<T>();
  }

  /// Returns a repository for performing CRUD operations on the specified model type.
  ///
  /// {@macro ormed.repository}
  ///
  /// ```dart
  /// final userRepo = ds.repo<User>();
  /// await userRepo.insert(newUser);
  /// await userRepo.updateMany([updatedUser]);
  /// await userRepo.deleteByKeys([{'id': userId}]);
  /// ```
  Repository<T> repo<T extends OrmEntity>() {
    _ensureInitialized();
    return _connection!.repository<T>();
  }

  /// Alias for [repo]. Returns a repository for the specified model type.
  Repository<T> getRepository<T extends OrmEntity>() => repo<T>();

  /// Executes the provided callback within a database transaction.
  ///
  /// If the callback completes successfully, the transaction is committed.
  /// If an exception is thrown, the transaction is rolled back.
  ///
  /// ```dart
  /// await ds.transaction(() async {
  ///   await ds.repo<User>().insert(user);
  ///   await ds.repo<Post>().insert(post);
  ///   // If either fails, both are rolled back
  /// });
  /// ```
  Future<R> transaction<R>(Future<R> Function() callback) {
    _ensureInitialized();
    return _connection!.transaction(callback);
  }

  /// Begins a new database transaction.
  ///
  /// Use this for manual transaction control. Must be paired with
  /// [commit] or [rollback].
  ///
  /// ```dart
  /// await ds.beginTransaction();
  /// try {
  ///   await ds.repo<User>().insert(user);
  ///   await ds.commit();
  /// } catch (e) {
  ///   await ds.rollback();
  ///   rethrow;
  /// }
  /// ```
  Future<void> beginTransaction() {
    _ensureInitialized();
    return _connection!.driver.beginTransaction();
  }

  /// Commits the active database transaction.
  Future<void> commit() {
    _ensureInitialized();
    return _connection!.driver.commitTransaction();
  }

  /// Rolls back the active database transaction.
  Future<void> rollback() {
    _ensureInitialized();
    return _connection!.driver.rollbackTransaction();
  }

  /// Builds a query against an arbitrary table name.
  ///
  /// Useful for ad-hoc queries or tables without a model definition.
  ///
  /// ```dart
  /// final rows = await ds.table('audit_logs')
  ///     .whereEquals('action', 'login')
  ///     .orderBy('timestamp', descending: true)
  ///     .limit(100)
  ///     .get();
  /// ```
  Query<AdHocRow> table(
    String table, {
    String? as,
    String? schema,
    List<String>? scopes,
    List<AdHocColumn> columns = const [],
  }) {
    _ensureInitialized();
    return _connection!.table(
      table,
      as: as,
      schema: schema,
      scopes: scopes,
      columns: columns,
    );
  }

  /// Runs [action] with pretend mode enabled and returns the captured SQL.
  ///
  /// No actual database operations are performed; this is useful for
  /// debugging and previewing generated queries.
  ///
  /// ```dart
  /// final statements = await ds.pretend(() async {
  ///   await ds.repo<User>().insert(user);
  /// });
  /// for (final entry in statements) {
  ///   print('SQL: ${entry.sql}');
  /// }
  /// ```
  Future<List<QueryLogEntry>> pretend(FutureOr<void> Function() action) {
    _ensureInitialized();
    return _connection!.pretend(action);
  }

  // ---------------------------------------------------------------------------
  // Observability API
  // ---------------------------------------------------------------------------

  /// Registers a listener for [QueryExecuted] events (like Laravel's listen).
  ///
  /// This is the primary method for observing database queries. The callback
  /// receives a [QueryExecuted] event after every query completes.
  ///
  /// Returns a function that can be called to unregister the listener.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final unsubscribe = ds.listen((event) {
  ///   print('Query: ${event.sql} took ${event.time}ms');
  /// });
  /// ```
  void Function() listen(void Function(QueryExecuted event) callback) {
    _ensureInitialized();
    return _connection!.listen(callback);
  }

  /// Registers a listener for specific connection event types.
  ///
  /// Returns a function that can be called to unregister the listener.
  ///
  /// ## Example
  ///
  /// ```dart
  /// ds.onEvent<TransactionBeginning>((event) {
  ///   print('Transaction started');
  /// });
  /// ```
  void Function() onEvent<T extends ConnectionEvent>(
    void Function(T event) callback,
  ) {
    _ensureInitialized();
    return _connection!.onEvent<T>(callback);
  }

  /// Returns the total time spent executing queries in milliseconds.
  double totalQueryDuration() {
    _ensureInitialized();
    return _connection!.totalQueryDuration();
  }

  /// Registers a callback when cumulative query time exceeds [threshold].
  ///
  /// ## Example
  ///
  /// ```dart
  /// ds.whenQueryingForLongerThan(
  ///   Duration(seconds: 2),
  ///   (connection, event) {
  ///     logger.warning('Slow queries detected');
  ///   },
  /// );
  /// ```
  void Function() whenQueryingForLongerThan(
    Duration threshold,
    void Function(OrmConnection connection, QueryExecuted event) handler,
  ) {
    _ensureInitialized();
    return _connection!.whenQueryingForLongerThan(threshold, handler);
  }

  /// Registers a callback invoked before any SQL is dispatched.
  ///
  /// Returns a function that can be called to unregister the callback.
  void Function() beforeExecuting(ExecutingStatementCallback callback) {
    _ensureInitialized();
    return _connection!.beforeExecuting(callback);
  }

  /// Enables query logging for this data source.
  void enableQueryLog({bool includeParameters = true, bool clear = true}) {
    _ensureInitialized();
    _connection!.enableQueryLog(
      includeParameters: includeParameters,
      clear: clear,
    );
  }

  /// Disables query logging.
  void disableQueryLog({bool clear = false}) {
    _ensureInitialized();
    _connection!.disableQueryLog(clear: clear);
  }

  /// Returns the accumulated query log entries.
  List<QueryLogEntry> get queryLog {
    _ensureInitialized();
    return _connection!.queryLog;
  }

  /// Clears all accumulated query log entries.
  void flushQueryLog() {
    _ensureInitialized();
    _connection!.flushQueryLog();
  }

  /// Closes the data source connection and releases resources.
  ///
  /// After calling this method, the data source can no longer be used.
  /// Call [init] again to re-initialize if needed.
  Future<void> dispose() async {
    if (!_initialized || _connection == null) {
      return;
    }

    final manager = ConnectionManager.instance;
    final shouldClearDefault =
        _defaultDataSource == this ||
        manager.defaultConnectionName == options.name;

    if (shouldClearDefault) {
      _defaultDataSource = null;
      manager.clearDefault();
      Model.unbindConnectionResolver();
    }

    if (manager.isRegistered(options.name)) {
      await manager.unregister(options.name);
    } else {
      await _connection!.driver.close();
    }
    _connection = null;
    _initialized = false;
  }

  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError(
        'DataSource has not been initialized. Call init() first.',
      );
    }
  }
}

/// Extension to add data source registration to [ConnectionManager].
extension DataSourceManagerExtension on ConnectionManager {
  /// Registers a [DataSource] with this connection manager.
  ///
  /// This allows the data source's connection to be retrieved by name
  /// through the connection manager.
  void registerDataSource(DataSource dataSource) {
    if (!dataSource.isInitialized) {
      throw StateError(
        'DataSource must be initialized before registering with ConnectionManager.',
      );
    }

    register(
      dataSource.name,
      ConnectionConfig(
        name: dataSource.name,
        database: dataSource.options.database,
        tablePrefix: dataSource.options.tablePrefix,
        defaultSchema: dataSource.options.defaultSchema,
      ),
      (config) => dataSource.connection,
      singleton: true,
    );
  }

  /// Sets a default data source for convenience when using static Model helpers.
  ///
  /// This registers the data source under the 'default' connection name,
  /// which is used by Model static helpers like `User.all()`, `User.find()`, etc.
  ///
  /// ```dart
  /// final ds = DataSource(DataSourceOptions(
  ///   driver: SqliteDriverAdapter.file('app.sqlite'),
  ///   entities: [UserOrmDefinition.definition],
  /// ));
  /// await ds.init();
  ///
  /// // Register as default
  /// ConnectionManager.instance.setDefaultDataSource(ds);
  ///
  /// // Now you can use static helpers
  /// final users = await User.all();
  /// final user = await User.find(1);
  /// ```
  void setDefaultDataSource(DataSource dataSource) {
    if (dataSource.name != 'default') {
      throw ArgumentError(
        'DataSource must have name "default" to be set as default. '
        'Current name: "${dataSource.name}"',
      );
    }
    registerDataSource(dataSource);
  }
}
