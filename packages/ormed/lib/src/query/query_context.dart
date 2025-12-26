part of 'query.dart';

/// Executes [QueryPlan] objects against a concrete backend.
abstract class QueryExecutor {
  /// Resolves [plan] into raw rows where each map represents one record.
  Future<List<Map<String, Object?>>> execute(QueryPlan plan);

  /// Streams rows for [plan]. Drivers may override to avoid buffering.
  Stream<Map<String, Object?>> stream(QueryPlan plan) async* {
    final rows = await execute(plan);
    for (final row in rows) {
      yield row;
    }
  }
}

/// {@template ormed.query.query_context}
/// The central hub for interacting with the ORM.
///
/// A [QueryContext] provides access to model definitions, database drivers,
/// and query builders. It is typically created once per application and
/// passed down to parts of the application that need to perform database operations.
/// {@endtemplate}
class QueryContext implements ConnectionResolver {
  /// {@macro ormed.query.query_context}
  ///
  /// Creates a new [QueryContext] instance.
  ///
  /// [registry] is the model registry containing all model definitions.
  /// [driver] is the database driver to use for all operations.
  /// [codecRegistry] provides value codecs, cast handlers, and encrypters.
  /// [scopeRegistry] is an optional registry for global and local query scopes.
  /// [connectionName] is an optional name for the database connection.
  /// [connectionDatabase] is an optional name for the database.
  /// [connectionTablePrefix] is an optional prefix for table names.
  /// [beforeQueryHook] is a callback executed before each query.
  /// [beforeMutationHook] is a callback executed before each mutation.
  /// [beforeTransactionHook] is a callback executed before each transaction.
  /// [afterTransactionHook] is a callback executed after each transaction.
  /// [queryLogHook] is a callback for logging query events.
  /// [pretendResolver] is a function to determine if queries should be pretended.
  QueryContext({
    required this.registry,
    required this.driver,
    ValueCodecRegistry? codecRegistry,
    ScopeRegistry? scopeRegistry,
    EventBus? events,
    this.connectionName,
    this.connectionDatabase,
    this.connectionTablePrefix,
    QueryHook? beforeQueryHook,
    MutationHook? beforeMutationHook,
    TransactionHook? beforeTransactionHook,
    TransactionHook? afterTransactionHook,
    QueryLogHook? queryLogHook,
    bool Function()? pretendResolver,
  }) : codecRegistry =
           (codecRegistry ?? ValueCodecRegistry.instance).forDriver(
             driver.metadata.name,
           ),
       scopeRegistry = scopeRegistry ?? ScopeRegistry(),
       events = events ?? EventBus.instance,
       queryCache = QueryCache(),
       _beforeQueryHook = beforeQueryHook,
       _beforeMutationHook = beforeMutationHook,
       _beforeTransactionHook = beforeTransactionHook,
       _afterTransactionHook = afterTransactionHook,
       _queryLogHook = queryLogHook,
       _pretendResolver = pretendResolver {
    _registerSoftDeleteScopes();
    registry.addOnRegisteredCallback(_handleLateRegistration);
  }

  /// The model registry containing all model definitions.
  @override
  final ModelRegistry registry;

  /// The underlying database driver used by this context.
  @override
  final DriverAdapter driver;

  /// The registry for custom field and value codecs.
  @override
  final ValueCodecRegistry codecRegistry;

  /// Event bus used for emitting model lifecycle events.
  final EventBus events;

  /// The registry for global and local query scopes.
  final ScopeRegistry scopeRegistry;

  /// The query result cache.
  final QueryCache queryCache;

  /// The name of the database connection.
  final String? connectionName;

  /// The name of the database.
  final String? connectionDatabase;

  /// The prefix applied to table names.
  final String? connectionTablePrefix;

  final QueryHook? _beforeQueryHook;
  final MutationHook? _beforeMutationHook;
  final TransactionHook? _beforeTransactionHook;
  final TransactionHook? _afterTransactionHook;
  final QueryLogHook? _queryLogHook;
  final bool Function()? _pretendResolver;
  final List<void Function(QueryEvent)> _queryListeners = [];
  final List<void Function(MutationEvent)> _mutationListeners = [];
  final List<ExecutingStatementCallback> _beforeExecutingCallbacks = [];
  final List<_LongQuerySubscription> _longQuerySubscriptions = [];

  /// Returns a [Query] bound to the registered [ModelDefinition] for [T].
  ///
  /// {@macro ormed.query}
  Query<T> query<T extends OrmEntity>() {
    final definition = registry.expect<T>();
    final defaultQuery = Query(definition: definition, context: this);
    final hook = _resolveQueryBuilderHook(definition);
    if (hook != null && hook.handles(definition)) {
      return hook.build(definition, this, defaultQuery);
    }
    return defaultQuery;
  }

  /// Returns a [Query] for a given [ModelDefinition].
  ///
  /// This method allows for creating a query with an explicitly provided
  /// [ModelDefinition], optionally overriding its table, schema, or alias.
  ///
  /// [definition] is the model definition to use for the query.
  /// [table] is an optional table name override.
  /// [schema] is an optional schema name override.
  /// [alias] is an optional alias for the table.
  Query<T> queryFromDefinition<T extends OrmEntity>(
    ModelDefinition<T> definition, {
    String? table,
    String? schema,
    String? alias,
    List<String>? scopes,
  }) {
    final overridden = (table == null && schema == null)
        ? definition
        : definition.copyWith(
            tableName: table ?? definition.tableName,
            schema: schema ?? definition.schema,
          );
    return Query(
      definition: overridden,
      context: this,
      tableAlias: alias,
      globalScopesApplied: false,
      ignoreAllGlobalScopes: true,
      adHocScopes: scopes ?? const [],
    );
  }

  /// Starts a query builder targeting a table by name.
  ///
  /// If a model is registered for the given table name, its definition will be used,
  /// providing full field metadata for inserts, updates, and queries.
  /// The registered model's schema is used (which is typically null for models
  /// that don't specify a schema), ensuring consistency with typed queries.
  /// Otherwise, an ad-hoc definition is created for raw map access.
  ///
  /// The results will be returned as `Map<String, Object?>`.
  ///
  /// [table] is the name of the table to query.
  /// [as] is an optional alias for the table.
  /// [schema] is an optional schema name for the table (only used for unregistered tables).
  /// [scopes] are optional ad-hoc scopes to apply to the query.
  /// [columns] are optional ad-hoc columns to include in the select statement.
  Query<AdHocRow> table(
    String table, {
    String? as,
    String? schema,
    List<String>? scopes,
    List<AdHocColumn> columns = const [],
  }) {
    // Try to find a registered model definition for this table
    final registeredDef = registry.findByTableName(table);

    if (registeredDef != null) {
      // Use the registered definition but wrap it to return Map<String, Object?>
      // Use the registered definition's schema (typically null) to match typed query behavior.
      // Only use the passed schema if the registered def has no schema AND a schema was explicitly provided.
      final wrappedDefinition = TableQueryDefinition(
        underlying: registeredDef,
        // Don't override the registered model's schema with the context default.
        // This ensures table("authors") behaves like query<$Author>().
        schema: registeredDef.schema,
        alias: as,
      );
      return Query(
        definition: wrappedDefinition,
        context: this,
        tableAlias: as,
        globalScopesApplied: false,
        ignoreAllGlobalScopes: true,
        adHocScopes: scopes ?? const [],
      );
    }

    // Fall back to ad-hoc definition for unregistered tables
    final definition = AdHocModelDefinition(
      tableName: table,
      schema: schema,
      alias: as,
      columns: columns,
    );
    return Query(
      definition: definition,
      context: this,
      tableAlias: as,
      globalScopesApplied: false,
      ignoreAllGlobalScopes: true,
      adHocScopes: scopes ?? const [],
    );
  }

  /// Registers a global scope for models of type [T].
  ///
  /// Global scopes are automatically applied to all queries for a given model type.
  ///
  /// [identifier] is a unique identifier for the global scope.
  /// [scope] is the callback function that applies the scope's constraints to a query.
  void registerGlobalScope<T extends OrmEntity>(
    String identifier,
    GlobalScopeCallback<T> scope,
  ) {
    scopeRegistry.addGlobalScope<T>(identifier, scope);
    // Also register for the actual model type if T is an alias
    try {
      final definition = registry.expect<T>();
      final actualType = definition.modelType;
      if (actualType != T) {
        scopeRegistry.addGlobalScopeForType(
          actualType,
          identifier,
          (query) => scope(query as Query<T>) as Query<OrmEntity>,
        );
      }
    } catch (_) {
      // If the type is not registered, just register the scope for T only
    }
  }

  /// Registers a global scope pattern for models of type [T].
  ///
  /// This allows for applying global scopes based on a pattern match against the model name.
  ///
  /// [identifier] is a unique identifier for the global scope.
  /// [scope] is the callback function that applies the scope's constraints to a query.
  /// [pattern] is a glob-style pattern to match against model names (e.g., 'User*', '*Post').
  void registerGlobalScopePattern<T extends OrmEntity>(
    String identifier,
    GlobalScopeCallback<T> scope, {
    String pattern = '*',
  }) => scopeRegistry.addGlobalScopePattern(
    identifier,
    (query) => scope(query as Query<T>) as Query<OrmEntity>,
    pattern: pattern,
  );

  /// Registers a local scope for models of type [T].
  ///
  /// Local scopes are reusable query constraints that can be applied to a query
  /// by name.
  ///
  /// [name] is the name of the local scope.
  /// [scope] is the callback function that applies the scope's constraints to a query.
  void registerLocalScope<T extends OrmEntity>(
    String name,
    LocalScopeCallback<T> scope,
  ) => scopeRegistry.addLocalScope<T>(name, scope);

  /// Registers a local scope pattern for models of type [T].
  ///
  /// This allows for applying local scopes based on a pattern match against the model name.
  ///
  /// [name] is the name of the local scope.
  /// [scope] is the callback function that applies the scope's constraints to a query.
  /// [pattern] is a glob-style pattern to match against model names (e.g., 'User*', '*Post').
  void registerLocalScopePattern<T extends OrmEntity>(
    String name,
    LocalScopeCallback<T> scope, {
    String pattern = '*',
  }) => scopeRegistry.addLocalScopePattern(
    name,
    (query, args) => scope(query as Query<T>, args) as Query<OrmEntity>,
    pattern: pattern,
  );

  /// Registers a query macro.
  ///
  /// Macros provide a way to extend the query builder with custom, reusable logic.
  ///
  /// [name] is the name of the macro.
  /// [macro] is the callback function that implements the macro's logic.
  void registerMacro(String name, QueryMacroCallback macro) =>
      scopeRegistry.addMacro(name, macro);

  /// Returns the number of open database connections, when supported by the
  /// driver.
  ///
  /// This method can be used to monitor the connection pool usage.
  Future<int?> threadCount() => driver.threadCount();

  /// Attaches runtime metadata to a model instance.
  ///
  /// This is used internally to track changes and relationships for models.
  ///
  /// [model] is the model instance to attach metadata to.
  void attachRuntimeMetadata(Object? model) {
    if (model is ModelConnection) {
      model.attachConnectionResolver(this);
    }
    // Mark models loaded from database as existing and sync their original state
    final modelInstance = model;
    if (modelInstance is Model<dynamic>) {
      modelInstance.markAsExisting();
      if (modelInstance is ModelAttributes) {
        (modelInstance as ModelAttributes).syncOriginal();
      }
    }
  }

  /// Returns a [Repository] that emits events through this context.
  ///
  /// This method provides a repository instance for a given model type,
  /// allowing for common CRUD operations.
  ///
  /// {@macro ormed.repository}
  ///
  /// Example:
  /// ```dart
  /// final userRepository = context.repository<$User>();
  /// final newUser = await userRepository.insert(
  ///   $UserInsertDto(email: 'john@example.com'),
  /// );
  /// ```
  Repository<T> repository<T extends OrmEntity>() {
    final definition = registry.expect<T>();
    final defaultRepository = Repository(
      definition: definition,
      driverName: driver.metadata.name,
      runMutation: runMutation,
      describeMutation: describeMutation,
      attachRuntimeMetadata: attachRuntimeMetadata,
      context: this,
    );
    final hook = _resolveRepositoryHook(definition);
    if (hook != null && hook.handles(definition)) {
      return hook.build(definition, this, defaultRepository);
    }
    return defaultRepository;
  }

  QueryBuilderHook? _resolveQueryBuilderHook(
    ModelDefinition<OrmEntity> definition,
  ) {
    for (final annotation in definition.metadata.driverAnnotations) {
      final hook =
          driver.metadata.annotationQueryHooks?[annotation.runtimeType];
      if (hook != null) {
        return hook;
      }
    }
    return driver.metadata.queryBuilderHook;
  }

  RepositoryHook? _resolveRepositoryHook(
    ModelDefinition<OrmEntity> definition,
  ) {
    for (final annotation in definition.metadata.driverAnnotations) {
      final hook =
          driver.metadata.annotationRepositoryHooks?[annotation.runtimeType];
      if (hook != null) {
        return hook;
      }
    }
    return driver.metadata.repositoryHook;
  }

  /// Registers a listener that receives [QueryEvent] payloads.
  ///
  /// [listener] is a callback function that will be invoked with a [QueryEvent]
  /// whenever a query is executed.
  void onQuery(void Function(QueryEvent event) listener) =>
      _queryListeners.add(listener);

  /// Registers a listener that receives [MutationEvent] payloads.
  ///
  /// [listener] is a callback function that will be invoked with a [MutationEvent]
  /// whenever a mutation is executed.
  void onMutation(void Function(MutationEvent event) listener) =>
      _mutationListeners.add(listener);

  /// Registers a callback that is invoked before any statement is executed.
  ///
  /// [callback] is a function that receives an [ExecutingStatement] object.
  /// Returns a function that can be called to unregister the callback.
  void Function() beforeExecuting(ExecutingStatementCallback callback) {
    _beforeExecutingCallbacks.add(callback);
    return () => _beforeExecutingCallbacks.remove(callback);
  }

  /// Registers a callback that is invoked when a query runs for longer than [threshold].
  ///
  /// This is useful for identifying and debugging slow queries.
  ///
  /// [threshold] is the duration after which the callback should be invoked.
  /// [callback] is a function that receives a [LongRunningQueryEvent] object.
  /// Returns a function that can be called to unregister the callback.
  void Function() whenQueryingForLongerThan(
    Duration threshold,
    LongRunningQueryCallback callback,
  ) {
    final subscription = _LongQuerySubscription(
      threshold: threshold,
      callback: callback,
    );
    _longQuerySubscriptions.add(subscription);
    return () => _longQuerySubscriptions.remove(subscription);
  }

  /// Returns the statement preview for [plan] without hitting the driver.
  ///
  /// This method is useful for debugging and inspecting the generated SQL.
  ///
  /// [plan] is the [QueryPlan] to describe.
  @override
  StatementPreview describeQuery(QueryPlan plan) {
    try {
      return driver.describeQuery(plan);
    } catch (_) {
      return const StatementPreview(
        payload: SqlStatementPayload(sql: '<unavailable>'),
      );
    }
  }

  /// Returns the statement preview for [plan] without mutating the database.
  ///
  /// This method is useful for debugging and inspecting the generated SQL for mutations.
  ///
  /// [plan] is the [MutationPlan] to describe.
  @override
  StatementPreview describeMutation(MutationPlan plan) {
    try {
      return driver.describeMutation(plan);
    } catch (_) {
      return const StatementPreview(
        payload: SqlStatementPayload(sql: '<unavailable>'),
      );
    }
  }

  /// Executes [plan] while emitting a [QueryEvent].
  ///
  /// This method is typically used internally by the [QueryBuilder].
  ///
  /// [plan] is the [QueryPlan] to execute.
  @override
  Future<List<Map<String, Object?>>> runSelect(QueryPlan plan) async {
    final preview = describeQuery(plan);

    // Check cache if enabled
    if (plan.cacheTtl != null && !plan.disableCache) {
      final cached = queryCache.get<List<Map<String, Object?>>>(
        preview.sql,
        preview.parameters,
        ttl: plan.cacheTtl,
      );
      if (cached != null) {
        return cached;
      }
    }

    final timer = Stopwatch()..start();
    _beforeQueryHook?.call(plan);
    final pretending = _pretendResolver?.call() ?? false;
    final trackStatements = _shouldTrackStatements;
    final statement = trackStatements
        ? _buildStatement(
            type: ExecutingStatementType.query,
            preview: preview,
            queryPlan: plan,
          )
        : null;
    if (statement != null) {
      _notifyBeforeExecuting(statement);
    }
    try {
      if (pretending) {
        timer.stop();
        final event = QueryEvent(
          plan: plan,
          preview: preview,
          duration: timer.elapsed,
          rows: 0,
          connectionName: connectionName,
          connectionDatabase: connectionDatabase,
          connectionTablePrefix: connectionTablePrefix,
        );
        _emitQuery(event);
        _recordQueryLog(
          type: 'query',
          definition: plan.definition,
          preview: preview,
          duration: timer.elapsed,
          rowCount: 0,
          error: null,
        );
        return const [];
      }
      final result = await driver.execute(plan);
      timer.stop();
      if (statement != null && !pretending) {
        _notifyLongRunning(statement, timer.elapsed);
      }
      _emitQuery(
        QueryEvent(
          plan: plan,
          preview: preview,
          duration: timer.elapsed,
          rows: result.length,
          connectionName: connectionName,
          connectionDatabase: connectionDatabase,
          connectionTablePrefix: connectionTablePrefix,
        ),
      );
      _recordQueryLog(
        type: 'query',
        definition: plan.definition,
        preview: preview,
        duration: timer.elapsed,
        rowCount: result.length,
        error: null,
      );

      // Store in cache if caching is enabled
      if (plan.cacheTtl != null && !plan.disableCache) {
        queryCache.put(
          preview.sql,
          preview.parameters,
          result,
          ttl: plan.cacheTtl,
        );
      }

      return result;
    } catch (error, stackTrace) {
      timer.stop();
      if (statement != null && !pretending) {
        _notifyLongRunning(statement, timer.elapsed, error: error);
      }
      _emitQuery(
        QueryEvent(
          plan: plan,
          preview: preview,
          duration: timer.elapsed,
          error: error,
          stackTrace: stackTrace,
          connectionName: connectionName,
          connectionDatabase: connectionDatabase,
          connectionTablePrefix: connectionTablePrefix,
        ),
      );
      _recordQueryLog(
        type: 'query',
        definition: plan.definition,
        preview: preview,
        duration: timer.elapsed,
        rowCount: null,
        error: error,
      );
      rethrow;
    }
  }

  /// Streams rows for [plan] while emitting a [QueryEvent].
  ///
  /// This method is typically used internally by the [QueryBuilder].
  ///
  /// [plan] is the [QueryPlan] to execute.
  Stream<Map<String, Object?>> streamSelect(QueryPlan plan) {
    final preview = describeQuery(plan);
    final timer = Stopwatch()..start();
    _beforeQueryHook?.call(plan);
    final pretending = _pretendResolver?.call() ?? false;
    final trackStatements = _shouldTrackStatements;
    final statement = trackStatements
        ? _buildStatement(
            type: ExecutingStatementType.query,
            preview: preview,
            queryPlan: plan,
          )
        : null;
    if (statement != null) {
      _notifyBeforeExecuting(statement);
    }
    if (pretending) {
      timer.stop();
      final event = QueryEvent(
        plan: plan,
        preview: preview,
        duration: timer.elapsed,
        rows: 0,
        connectionName: connectionName,
        connectionDatabase: connectionDatabase,
        connectionTablePrefix: connectionTablePrefix,
      );
      _emitQuery(event);
      _recordQueryLog(
        type: 'query',
        definition: plan.definition,
        preview: preview,
        duration: timer.elapsed,
        rowCount: 0,
        error: null,
      );
      return const Stream<Map<String, Object?>>.empty();
    }

    StreamSubscription<Map<String, Object?>>? subscription;
    final controller = StreamController<Map<String, Object?>>();
    controller.onListen = () {
      var rowCount = 0;
      Stream<Map<String, Object?>> source;
      try {
        source = driver.stream(plan);
      } catch (error, stackTrace) {
        timer.stop();
        if (statement != null) {
          _notifyLongRunning(statement, timer.elapsed, error: error);
        }
        _emitQuery(
          QueryEvent(
            plan: plan,
            preview: preview,
            duration: timer.elapsed,
            error: error,
            stackTrace: stackTrace,
            connectionName: connectionName,
            connectionDatabase: connectionDatabase,
            connectionTablePrefix: connectionTablePrefix,
          ),
        );
        _recordQueryLog(
          type: 'query',
          definition: plan.definition,
          preview: preview,
          duration: timer.elapsed,
          rowCount: null,
          error: error,
        );
        controller.addError(error, stackTrace);
        controller.close();
        return;
      }

      subscription = source.listen(
        (row) {
          rowCount++;
          controller.add(row);
        },
        onError: (error, stackTrace) {
          timer.stop();
          if (statement != null) {
            _notifyLongRunning(statement, timer.elapsed, error: error);
          }
          _emitQuery(
            QueryEvent(
              plan: plan,
              preview: preview,
              duration: timer.elapsed,
              error: error,
              stackTrace: stackTrace,
              connectionName: connectionName,
              connectionDatabase: connectionDatabase,
              connectionTablePrefix: connectionTablePrefix,
            ),
          );
          _recordQueryLog(
            type: 'query',
            definition: plan.definition,
            preview: preview,
            duration: timer.elapsed,
            rowCount: null,
            error: error,
          );
          controller.addError(error, stackTrace);
          controller.close();
        },
        onDone: () {
          timer.stop();
          if (statement != null) {
            _notifyLongRunning(statement, timer.elapsed);
          }
          _emitQuery(
            QueryEvent(
              plan: plan,
              preview: preview,
              duration: timer.elapsed,
              rows: rowCount,
              connectionName: connectionName,
              connectionDatabase: connectionDatabase,
              connectionTablePrefix: connectionTablePrefix,
            ),
          );
          _recordQueryLog(
            type: 'query',
            definition: plan.definition,
            preview: preview,
            duration: timer.elapsed,
            rowCount: rowCount,
            error: null,
          );
          controller.close();
        },
        cancelOnError: false,
      );
    };

    controller.onPause = () => subscription?.pause();
    controller.onResume = () => subscription?.resume();
    controller.onCancel = () => subscription?.cancel();

    return controller.stream;
  }

  /// Executes [plan] while emitting a [MutationEvent].
  ///
  /// This method is typically used internally by the [QueryBuilder].
  ///
  /// [plan] is the [MutationPlan] to execute.
  @override
  Future<MutationResult> runMutation(MutationPlan plan) async {
    final preview = describeMutation(plan);
    final timer = Stopwatch()..start();
    _beforeMutationHook?.call(plan);
    final pretending = _pretendResolver?.call() ?? false;
    final trackStatements = _shouldTrackStatements;
    final statement = trackStatements
        ? _buildStatement(
            type: ExecutingStatementType.mutation,
            preview: preview,
            mutationPlan: plan,
          )
        : null;
    if (statement != null) {
      _notifyBeforeExecuting(statement);
    }
    try {
      if (pretending) {
        timer.stop();
        final event = MutationEvent(
          plan: plan,
          preview: preview,
          duration: timer.elapsed,
          affectedRows: 0,
          connectionName: connectionName,
          connectionDatabase: connectionDatabase,
          connectionTablePrefix: connectionTablePrefix,
        );
        _emitMutation(event);
        _recordQueryLog(
          type: 'mutation',
          definition: plan.definition,
          preview: preview,
          duration: timer.elapsed,
          rowCount: 0,
          error: null,
        );
        return const MutationResult(affectedRows: 0);
      }
      final result = await driver.runMutation(plan);
      timer.stop();
      if (statement != null && !pretending) {
        _notifyLongRunning(statement, timer.elapsed);
      }
      _emitMutation(
        MutationEvent(
          plan: plan,
          preview: preview,
          duration: timer.elapsed,
          affectedRows: result.affectedRows,
          connectionName: connectionName,
          connectionDatabase: connectionDatabase,
          connectionTablePrefix: connectionTablePrefix,
        ),
      );
      _recordQueryLog(
        type: 'mutation',
        definition: plan.definition,
        preview: preview,
        duration: timer.elapsed,
        rowCount: result.affectedRows,
        error: null,
      );
      return result;
    } catch (error, stackTrace) {
      timer.stop();
      if (statement != null && !pretending) {
        _notifyLongRunning(statement, timer.elapsed, error: error);
      }
      _emitMutation(
        MutationEvent(
          plan: plan,
          preview: preview,
          duration: timer.elapsed,
          error: error,
          stackTrace: stackTrace,
          connectionName: connectionName,
          connectionDatabase: connectionDatabase,
          connectionTablePrefix: connectionTablePrefix,
        ),
      );
      _recordQueryLog(
        type: 'mutation',
        definition: plan.definition,
        preview: preview,
        duration: timer.elapsed,
        rowCount: null,
        error: error,
      );
      rethrow;
    }
  }

  /// Executes a database transaction.
  ///
  /// [callback] is an asynchronous function that receives a [Transaction] object.
  /// All database operations performed within the callback using the provided
  /// [Transaction] will be part of the same atomic transaction.
  ///
  /// Example:
  /// ```dart
  /// await context.transaction(() async {
  ///   await context.query<User>().where('id', 1).update({'name': 'New Name'});
  ///   await context.query<Log>().create({'message': 'User updated'});
  /// });
  /// ```
  Future<R> transaction<R>(Future<R> Function() callback) {
    final before = _beforeTransactionHook;
    final after = _afterTransactionHook;
    if (before == null && after == null) {
      return driver.transaction(callback);
    }
    return driver.transaction(() async {
      if (before != null) {
        await before();
      }
      try {
        final result = await callback();
        if (after != null) {
          await after();
        }
        return result;
      } catch (error) {
        if (after != null) {
          await after();
        }
        rethrow;
      }
    });
  }

  void _emitQuery(QueryEvent event) {
    for (final listener in _queryListeners) {
      listener(event);
    }
  }

  void _emitMutation(MutationEvent event) {
    for (final listener in _mutationListeners) {
      listener(event);
    }
  }

  bool get _shouldTrackStatements =>
      _beforeExecutingCallbacks.isNotEmpty ||
      _longQuerySubscriptions.isNotEmpty;

  ExecutingStatement _buildStatement({
    required ExecutingStatementType type,
    required StatementPreview preview,
    QueryPlan? queryPlan,
    MutationPlan? mutationPlan,
  }) => ExecutingStatement(
    type: type,
    preview: preview,
    queryPlan: queryPlan,
    mutationPlan: mutationPlan,
    connectionName: connectionName,
    connectionDatabase: connectionDatabase,
    connectionTablePrefix: connectionTablePrefix,
  );

  void _notifyBeforeExecuting(ExecutingStatement statement) {
    for (final callback in _beforeExecutingCallbacks) {
      callback(statement);
    }
  }

  void _notifyLongRunning(
    ExecutingStatement statement,
    Duration duration, {
    Object? error,
  }) {
    if (_longQuerySubscriptions.isEmpty) return;
    final event = LongRunningQueryEvent(
      statement: statement,
      duration: duration,
      error: error,
    );
    for (final subscription in _longQuerySubscriptions) {
      if (duration >= subscription.threshold) {
        subscription.callback(event);
      }
    }
  }

  void _recordQueryLog({
    required String type,
    required ModelDefinition<OrmEntity> definition,
    required StatementPreview preview,
    required Duration duration,
    int? rowCount,
    Object? error,
  }) {
    final hook = _queryLogHook;
    if (hook == null) return;
    hook(
      QueryLogEntry(
        type: type,
        preview: preview,
        duration: duration,
        success: error == null,
        model: definition.modelName,
        table: definition.tableName,
        rowCount: rowCount,
        error: error,
      ),
    );
  }

  void _registerSoftDeleteScopes() {
    for (final definition in registry.values) {
      final field = definition.softDeleteField;
      if (field == null) continue;
      scopeRegistry.addGlobalScopeForType(
        definition.modelType,
        ScopeRegistry.softDeleteScopeIdentifier,
        (query) => query.applySoftDeleteFilter(field),
      );
    }
  }

  /// Clear all cached query results.
  ///
  /// Example:
  /// ```dart
  /// context.flushQueryCache();
  /// ```
  void flushQueryCache() => queryCache.flush();

  /// Remove expired cache entries (automatic cleanup).
  ///
  /// Example:
  /// ```dart
  /// context.vacuumQueryCache();
  /// ```
  void vacuumQueryCache() => queryCache.vacuum();

  /// Get query cache statistics.
  ///
  /// Example:
  /// ```dart
  /// final stats = context.queryCacheStats;
  /// print('Active entries: ${stats.activeEntries}');
  /// ```
  CacheStats get queryCacheStats => queryCache.stats;

  void _handleLateRegistration(ModelDefinition<OrmEntity> definition) {
    final field = definition.softDeleteField;
    if (field == null) return;
    scopeRegistry.addGlobalScopeForType(
      definition.modelType,
      ScopeRegistry.softDeleteScopeIdentifier,
      (query) => query.applySoftDeleteFilter(field),
    );
  }
}

/// Event payload emitted for every query execution.
class QueryEvent {
  QueryEvent({
    required this.plan,
    required this.preview,
    required this.duration,
    this.rows,
    this.error,
    this.stackTrace,
    this.connectionName,
    this.connectionDatabase,
    this.connectionTablePrefix,
  });

  /// Plan that was sent to the driver.
  final QueryPlan plan;

  /// Driver-provided statement preview.
  final StatementPreview preview;

  /// Wall-clock duration for the execution.
  final Duration duration;

  /// Number of rows returned, if available.
  final int? rows;

  /// Error thrown by the driver, when present.
  final Object? error;

  /// Stack trace captured when [error] is populated.
  final StackTrace? stackTrace;

  /// Connection metadata when available.
  final String? connectionName;
  final String? connectionDatabase;
  final String? connectionTablePrefix;

  /// Whether the query completed successfully.
  bool get succeeded => error == null;
}

/// Event payload emitted for every mutation execution.
class MutationEvent {
  MutationEvent({
    required this.plan,
    required this.preview,
    required this.duration,
    this.affectedRows,
    this.error,
    this.stackTrace,
    this.connectionName,
    this.connectionDatabase,
    this.connectionTablePrefix,
  });

  /// Plan that was sent to the driver.
  final MutationPlan plan;

  /// Driver-provided statement preview.
  final StatementPreview preview;

  /// Wall-clock duration for the execution.
  final Duration duration;

  /// Number of rows the driver reported as affected, if available.
  final int? affectedRows;

  /// Error thrown by the driver, when present.
  final Object? error;

  /// Stack trace captured when [error] is populated.
  final StackTrace? stackTrace;

  /// Connection metadata when available.
  final String? connectionName;
  final String? connectionDatabase;
  final String? connectionTablePrefix;

  /// Whether the mutation completed successfully.
  bool get succeeded => error == null;
}

class _LongQuerySubscription {
  const _LongQuerySubscription({
    required this.threshold,
    required this.callback,
  });

  final Duration threshold;
  final LongRunningQueryCallback callback;
}
