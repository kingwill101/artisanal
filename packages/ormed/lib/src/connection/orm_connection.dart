import 'dart:async';

import 'package:contextual/contextual.dart' as contextual;
import 'package:ormed/src/model/model.dart';

import '../contracts.dart';
import '../driver/driver.dart';
import '../migrations/migration_runner.dart';
import '../migrations/migration_status.dart';
import '../migrations/sql_migration_ledger.dart';
import '../query/query.dart';
import '../repository/repository.dart';
import '../value_codec.dart';
import 'connection.dart';

export 'connection_events.dart';

/// Represents a fully materialized ORM connection that exposes helpers,
/// metadata, and instrumentation hooks.
///
/// ## Observability
///
/// OrmConnection provides a unified observability system inspired by Laravel's
/// Connection class. The primary method for observing database operations is
/// [listen], which receives [QueryExecuted] events after every query.
///
/// ```dart
/// // Register a query listener (like Laravel's listen)
/// connection.listen((event) {
///   print('Query: ${event.sql} took ${event.time}ms');
/// });
///
/// // Listen for specific event types
/// connection.onEvent<TransactionBeginning>((event) {
///   print('Transaction started');
/// });
///
/// connection.onEvent<TransactionCommitted>((event) {
///   print('Transaction committed');
/// });
/// ```
///
/// ## Query Logging
///
/// Built-in query logging accumulates [QueryLogEntry] objects for debugging:
///
/// ```dart
/// connection.enableQueryLog();
///
/// // ... execute queries ...
///
/// for (final entry in connection.queryLog) {
///   print('${entry.sql} (${entry.duration.inMilliseconds}ms)');
/// }
///
/// connection.flushQueryLog(); // Clear entries
/// ```
///
/// ## Duration Handlers
///
/// Monitor cumulative query time with [whenQueryingForLongerThan]:
///
/// ```dart
/// connection.whenQueryingForLongerThan(
///   Duration(seconds: 2),
///   (connection, event) {
///     logger.warning('Slow queries detected: ${connection.totalQueryDuration}ms total');
///   },
/// );
/// ```
class OrmConnection implements ConnectionResolver {
  OrmConnection({
    required this.config,
    required DriverAdapter driver,
    required ModelRegistry registry,
    ValueCodecRegistry? codecRegistry,
    ScopeRegistry? scopeRegistry,
    QueryContext? context,
  }) : _driver = driver,
       _registry = registry,
       _codecRegistry = codecRegistry ?? driver.codecs {
    _context =
        context ??
        QueryContext(
          registry: registry,
          driver: driver,
          codecRegistry: _codecRegistry,
          scopeRegistry: scopeRegistry,
          connectionName: config.name,
          connectionDatabase: config.database,
          connectionTablePrefix: config.tablePrefix,
          beforeQueryHook: _dispatchBeforeQuery,
          beforeMutationHook: _dispatchBeforeMutation,
          beforeTransactionHook: _dispatchBeforeTransaction,
          afterTransactionHook: _dispatchAfterTransaction,
          afterTransactionOutcomeHook: _dispatchTransactionOutcome,
          queryLogHook: _handleQueryLogEntry,
          pretendResolver: () => _pretending,
        );
  }

  /// Configuration describing the logical connection.
  final ConnectionConfig config;

  final DriverAdapter _driver;
  final ModelRegistry _registry;
  final ValueCodecRegistry _codecRegistry;
  late final QueryContext _context;
  int _tableAliasCounter = 0;

  bool _pretending = false;
  bool _loggingQueries = false;
  bool _includeLogParameters = true;
  double _totalQueryDuration = 0.0;
  void Function()? _defaultContextualLoggerUnsubscribe;
  contextual.Logger? _defaultContextualLogger;

  final List<QueryLogEntry> _queryLog = [];

  // New Laravel-style listeners
  final List<void Function(QueryExecuted)> _queryListeners = [];
  final List<void Function(ConnectionEvent)> _eventListeners = [];
  final List<_QueryDurationHandler> _queryDurationHandlers = [];

  /// Underlying [QueryContext] for advanced operations.
  ///
  /// This is the lower-level API that powers `connection.query<T>()`,
  /// `connection.repository<T>()`, and helpers like `Model.query()`.
  /// {@macro ormed.query.query_context}
  QueryContext get context => _context;

  /// Current pretend-mode flag.
  bool get pretending => _pretending;

  /// Whether query logging is enabled.
  bool get loggingQueries => _loggingQueries;

  /// Contextual logger attached for query logging, if any.
  contextual.Logger? get logger => _defaultContextualLogger;

  /// Immutable view of recorded query log entries.
  List<QueryLogEntry> get queryLog => List.unmodifiable(_queryLog);

  /// Connection name convenience accessor.
  String get name => config.name;

  /// Optional database/catalog identifier.
  String? get database => config.database;

  /// Table prefix metadata.
  String get tablePrefix => config.tablePrefix;

  ConnectionRole get role => config.role;

  Map<String, Object?> get options => config.options;

  /// Runs [action] with pretend mode enabled and returns the captured SQL.
  Future<List<QueryLogEntry>> pretend(FutureOr<void> Function() action) async {
    final previousPretending = _pretending;
    final previousLogging = _loggingQueries;
    final previousInclude = _includeLogParameters;
    final previousLog = List<QueryLogEntry>.from(_queryLog);
    _pretending = true;
    enableQueryLog(includeParameters: true, clear: true);
    try {
      await Future.sync(action);
    } finally {
      _pretending = previousPretending;
    }
    final captured = List<QueryLogEntry>.from(_queryLog);
    _queryLog
      ..clear()
      ..addAll(previousLog);
    _loggingQueries = previousLogging;
    _includeLogParameters = previousInclude;
    return captured;
  }

  /// Enables query logging for this connection.
  void enableQueryLog({bool includeParameters = true, bool clear = true}) {
    _loggingQueries = true;
    _includeLogParameters = includeParameters;
    if (clear) {
      _queryLog.clear();
    }
  }

  /// Attaches the default contextual logger for query events.
  ///
  /// This is used when [DataSourceOptions.logging] is enabled to emit
  /// structured query logs without requiring user callbacks.
  void attachDefaultContextualLogger({
    contextual.Logger? logger,
    String? logFilePath,
  }) {
    if (_defaultContextualLoggerUnsubscribe != null) {
      return;
    }
    final resolvedLogger =
        logger ?? _buildDefaultContextualLogger(logFilePath: logFilePath);
    _defaultContextualLogger = resolvedLogger;
    _defaultContextualLoggerUnsubscribe = listen((event) {
      final context = contextual.Context({
        'connection': name,
        if (database != null) 'database': database,
        'duration_ms': event.time,
        'succeeded': event.succeeded,
        if (event.rowCount != null) 'row_count': event.rowCount,
      });
      if (event.error != null) {
        context.add('error', event.error.toString());
      }
      if (event.stackTrace != null) {
        context.add('stack_trace', event.stackTrace.toString());
      }

      if (event.succeeded) {
        resolvedLogger.info(event.sql, context);
      } else {
        resolvedLogger.error(event.sql, context);
      }
    });
  }

  contextual.Logger _buildDefaultContextualLogger({String? logFilePath}) {
    final logger = contextual.Logger(defaultChannelEnabled: false)
      ..withContext({'prefix': 'ormed'});
    final resolvedPath = logFilePath?.trim();
    if (resolvedPath != null && resolvedPath.isNotEmpty) {
      logger.addChannel(
        'file',
        contextual.DailyFileLogDriver(resolvedPath),
        formatter: contextual.PlainTextLogFormatter(),
      );
    } else {
      logger.addChannel(
        'console',
        contextual.ConsoleLogDriver(),
        formatter: contextual.PrettyLogFormatter(),
      );
    }
    return logger;
  }

  /// Disables query logging and optionally clears existing entries.
  void disableQueryLog({bool clear = false}) {
    _loggingQueries = false;
    if (clear) {
      _queryLog.clear();
    }
  }

  /// Clears all accumulated query log entries.
  ///
  /// This is the Laravel-style naming for clearing the query log.
  void flushQueryLog() => _queryLog.clear();

  /// Returns the total time spent executing queries in milliseconds.
  ///
  /// This accumulates over the lifetime of the connection. Use with
  /// [whenQueryingForLongerThan] to detect slow query patterns.
  double totalQueryDuration() => _totalQueryDuration;

  // ---------------------------------------------------------------------------
  // Laravel-style Listener API
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
  /// final unsubscribe = connection.listen((event) {
  ///   print('Query: ${event.sql} took ${event.time}ms');
  ///   if (!event.succeeded) {
  ///     logger.error('Query failed: ${event.error}');
  ///   }
  /// });
  ///
  /// // Later, to stop listening:
  /// unsubscribe();
  /// ```
  void Function() listen(void Function(QueryExecuted event) callback) {
    _queryListeners.add(callback);
    return () => _queryListeners.remove(callback);
  }

  /// Registers a listener for specific connection event types.
  ///
  /// Use this to listen for transaction events and other connection lifecycle
  /// events.
  ///
  /// Returns a function that can be called to unregister the listener.
  ///
  /// ## Example
  ///
  /// ```dart
  /// connection.onEvent<TransactionBeginning>((event) {
  ///   print('Transaction started on ${event.connectionName}');
  /// });
  ///
  /// connection.onEvent<TransactionCommitted>((event) {
  ///   print('Transaction committed');
  /// });
  ///
  /// connection.onEvent<TransactionRolledBack>((event) {
  ///   logger.warning('Transaction rolled back');
  /// });
  /// ```
  void Function() onEvent<T extends ConnectionEvent>(
    void Function(T event) callback,
  ) {
    void listener(ConnectionEvent event) {
      if (event is T) callback(event);
    }

    _eventListeners.add(listener);
    return () => _eventListeners.remove(listener);
  }

  /// Registers a callback when cumulative query time exceeds [threshold].
  ///
  /// The handler is called once when [totalQueryDuration] first exceeds the
  /// threshold. To allow it to fire again, call [allowQueryDurationHandlersToRunAgain].
  ///
  /// ## Example
  ///
  /// ```dart
  /// connection.whenQueryingForLongerThan(
  ///   Duration(seconds: 2),
  ///   (connection, event) {
  ///     logger.warning(
  ///       'Slow queries detected: ${connection.totalQueryDuration()}ms total',
  ///     );
  ///   },
  /// );
  /// ```
  void Function() whenQueryingForLongerThan(
    Duration threshold,
    void Function(OrmConnection connection, QueryExecuted event) handler,
  ) {
    final thresholdMs = threshold.inMilliseconds.toDouble();
    final handlerEntry = _QueryDurationHandler(
      thresholdMs: thresholdMs,
      handler: handler,
    );
    _queryDurationHandlers.add(handlerEntry);
    return () => _queryDurationHandlers.remove(handlerEntry);
  }

  /// Allows duration handlers registered via [whenQueryingForLongerThan] to
  /// run again.
  ///
  /// By default, each handler only fires once when the threshold is exceeded.
  /// Call this method to reset all handlers so they can fire again.
  void allowQueryDurationHandlersToRunAgain() {
    for (final handler in _queryDurationHandlers) {
      handler.hasRun = false;
    }
  }

  /// Registers a callback invoked before any SQL is dispatched.
  void Function() beforeExecuting(ExecutingStatementCallback callback) =>
      _context.beforeExecuting(callback);

  /// Creates a typed query builder.
  ///
  /// {@macro ormed.query}
  Query<T> query<T extends OrmEntity>() => _context.query<T>();

  /// Ensures the migrations ledger table exists for this connection.
  Future<void> ensureLedgerInitialized({String? tableName}) async {
    final ledger = SqlMigrationLedger(
      _driver,
      tableName: tableName ?? 'orm_migrations',
      tablePrefix: config.tablePrefix,
    );
    await ledger.ensureInitialized();
  }

  /// Ensures pending migrations are applied using [runner].
  ///
  /// When [applyPendingMigrations] is `false`, this simply verifies the ledger
  /// exists and returns an empty report.
  Future<MigrationReport> ensureSchemaReady({
    required MigrationRunner runner,
    bool applyPendingMigrations = true,
  }) async {
    if (!applyPendingMigrations) {
      await runner.status();
      return const MigrationReport([]);
    }
    return runner.applyAll();
  }

  static OrmConnection fromManager(
    String name, {
    ConnectionRole role = ConnectionRole.primary,
    ConnectionManager? manager,
  }) => (manager ?? ConnectionManager.defaultManager).connection(
    name,
    role: role,
  );

  /// Queries using a specific model definition, optionally overriding table/schema.
  Query<T> queryFromDefinition<T extends OrmEntity>(
    ModelDefinition<T> definition, {
    String? table,
    String? schema,
    String? alias,
  }) => _context.queryFromDefinition(
    definition,
    table: table,
    schema: schema,
    alias: alias,
  );

  /// Returns a repository for [T].
  Repository<T> repository<T extends OrmEntity>() => _context.repository<T>();

  /// Executes [callback] within a transaction boundary.
  Future<R> transaction<R>(Future<R> Function() callback) =>
      _context.transaction(callback);

  /// Builds a query against an arbitrary table name.
  Query<AdHocRow> table(
    String table, {
    String? as,
    String? schema,
    List<String>? scopes,
    List<AdHocColumn> columns = const [],
  }) {
    final effectiveSchema = schema ?? config.defaultSchema;
    final alias = as ?? _generateAlias(table);
    return _context.table(
      table,
      as: alias,
      schema: effectiveSchema,
      scopes: scopes,
      columns: columns,
    );
  }

  /// Builds a query for [T] using an alternate table/schema/alias.
  Query<T> queryAs<T extends OrmEntity>({
    String? table,
    String? schema,
    String? alias,
  }) => queryFromDefinition(
    registry.expect<T>(),
    table: table,
    schema: schema,
    alias: alias,
  );

  @override
  DriverAdapter get driver => _driver;

  @override
  ModelRegistry get registry => _registry;

  @override
  ValueCodecRegistry get codecRegistry =>
      _codecRegistry.forDriver(_driver.metadata.name);

  @override
  Future<List<Map<String, Object?>>> runSelect(QueryPlan plan) =>
      _context.runSelect(plan);

  @override
  Future<MutationResult> runMutation(MutationPlan plan) =>
      _context.runMutation(plan);

  @override
  StatementPreview describeQuery(QueryPlan plan) =>
      _context.describeQuery(plan);

  @override
  StatementPreview describeMutation(MutationPlan plan) =>
      _context.describeMutation(plan);

  void _dispatchBeforeQuery(QueryPlan plan) {
    // No-op: legacy hooks removed
  }

  void _dispatchBeforeMutation(MutationPlan plan) {
    // No-op: legacy hooks removed
  }

  Future<void> _dispatchBeforeTransaction() async {
    _fireEvent(TransactionBeginning(this));
  }

  Future<void> _dispatchAfterTransaction() async {
    // No-op: transaction outcome hook now handles commit/rollback events.
  }

  Future<void> _dispatchTransactionOutcome(
    TransactionOutcome outcome,
    TransactionScope scope,
  ) async {
    if (scope != TransactionScope.root) {
      return;
    }
    switch (outcome) {
      case TransactionOutcome.committed:
        _fireEvent(TransactionCommitted(this));
      case TransactionOutcome.rolledBack:
        _fireEvent(TransactionRolledBack(this));
    }
  }

  String? _generateAlias(String table) {
    switch (config.tableAliasStrategy) {
      case TableAliasStrategy.none:
        return null;
      case TableAliasStrategy.tableName:
        return table;
      case TableAliasStrategy.incremental:
        return 't${_tableAliasCounter++}';
    }
  }

  /// Handles query log entries from QueryContext and fires QueryExecuted events.
  void _handleQueryLogEntry(QueryLogEntry entry) {
    final timeMs = entry.duration.inMicroseconds / 1000.0;
    _totalQueryDuration += timeMs;

    // Fire QueryExecuted event to all listeners
    final event = QueryExecuted(
      sql: entry.preview.sql,
      bindings: entry.preview.parameters,
      time: timeMs,
      connection: this,
      rowCount: entry.rowCount,
      error: entry.error,
    );
    _fireQueryExecuted(event);

    // Check duration handlers
    for (final handler in _queryDurationHandlers) {
      if (!handler.hasRun && _totalQueryDuration > handler.thresholdMs) {
        handler.handler(this, event);
        handler.hasRun = true;
      }
    }

    // Query logging
    if (_loggingQueries) {
      final sanitized = _includeLogParameters
          ? entry
          : entry.withoutParameters();
      _queryLog.add(sanitized);
    }
  }

  /// Fires a [QueryExecuted] event to all registered query listeners.
  void _fireQueryExecuted(QueryExecuted event) {
    for (final listener in _queryListeners) {
      try {
        listener(event);
      } catch (_) {
        // Don't let listener exceptions break query execution
      }
    }
  }

  /// Fires a connection event to all registered event listeners.
  void _fireEvent(ConnectionEvent event) {
    for (final listener in _eventListeners) {
      try {
        listener(event);
      } catch (_) {
        // Don't let listener exceptions break execution
      }
    }
    // Also fire QueryExecuted events through the query listeners
    if (event is QueryExecuted) {
      _fireQueryExecuted(event);
    }
  }
}

/// Internal class for tracking query duration handlers.
class _QueryDurationHandler {
  _QueryDurationHandler({required this.thresholdMs, required this.handler});

  final double thresholdMs;
  final void Function(OrmConnection, QueryExecuted) handler;
  bool hasRun = false;
}
