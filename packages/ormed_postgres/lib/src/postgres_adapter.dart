import 'package:ormed/ormed.dart';
import 'package:postgres/postgres.dart';

import 'postgres_codecs.dart';
import 'postgres_connector.dart';
import 'postgres_grammar.dart';
import 'postgres_schema_dialect.dart';
import 'postgres_type_mapper.dart';
import 'schema_state.dart';

/// PostgreSQL implementation of the routed ORM driver adapter.
class PostgresDriverAdapter
    implements
        DriverAdapter,
        SchemaDriver,
        SchemaStateProvider,
        DriverExtensionHost {
  /// Registers PostgreSQL-specific codecs and type mapper with the global registries.
  /// Call this once during application initialization before using PostgreSQL.
  static void registerCodecs() {
    final mapper = PostgresTypeMapper();
    TypeMapperRegistry.register('postgres', mapper);

    // Register codecs from TypeMapper to eliminate duplication
    final codecs = <String, ValueCodec<dynamic>>{};
    for (final mapping in mapper.typeMappings) {
      if (mapping.codec != null) {
        final typeKey = mapping.dartType.toString();
        codecs[typeKey] = mapping.codec!;
        codecs['$typeKey?'] = mapping.codec!; // Nullable variant
      }
    }
    ValueCodecRegistry.instance.registerDriver('postgres', codecs);

    // Ensure postgres-specific codecs are also registered.
    registerPostgresCodecs();
  }

  PostgresDriverAdapter.custom({
    required DatabaseConfig config,
    ConnectionFactory? connections,
    List<DriverExtension> extensions = const [],
  }) : _metadata = const DriverMetadata(
         name: 'postgres',
         supportsReturning: true,
         supportsTransactions: true,
         supportsQueryDeletes: true,
         requiresPrimaryKeyForQueryUpdate: false,
         queryUpdateRowIdentifier: QueryRowIdentifier(
           column: 'ctid',
           expression: 'ctid',
         ),
         identifierQuote: '"',
         capabilities: {
           DriverCapability.joins,
           DriverCapability.insertUsing,
           DriverCapability.queryDeletes,
           DriverCapability.schemaIntrospection,
           DriverCapability.threadCount,
           DriverCapability.transactions,
           DriverCapability.returning,
           DriverCapability.adHocQueryUpdates,
           DriverCapability.increment,
           DriverCapability.relationAggregates,
           DriverCapability.caseInsensitiveLike,
           DriverCapability.distinctOn,
           DriverCapability.rightJoin,
           DriverCapability.rawSQL,
           DriverCapability.advancedQueryBuilders,
           DriverCapability.sqlPreviews,
           DriverCapability.databaseManagement,
           DriverCapability.foreignKeyConstraintControl,
         },
       ),
       _schemaCompiler = SchemaPlanCompiler(PostgresSchemaDialect()),
       _extensions = DriverExtensionRegistry(
         driverName: 'postgres',
         extensions: extensions,
       ),
       _connections =
           connections ??
           ConnectionFactory(
             connectors: {'postgres': () => PostgresConnector()},
           ),
       _config = config,
       _codecs = ValueCodecRegistry.instance.forDriver('postgres') {
    // Auto-register PostgreSQL codecs on first instantiation
    registerPostgresCodecs();

    _grammar = PostgresQueryGrammar(extensions: _extensions);

    _planCompiler = ClosurePlanCompiler(
      compileSelect: _compileSelectPreview,
      compileMutation: _compileMutationPreview,
    );
  }

  factory PostgresDriverAdapter.fromUrl(
    String url, {
    ConnectionFactory? connections,
    List<DriverExtension> extensions = const [],
  }) => PostgresDriverAdapter.custom(
    config: DatabaseConfig(driver: 'postgres', options: {'url': url}),
    connections: connections,
    extensions: extensions,
  );

  factory PostgresDriverAdapter.insecureLocal({
    String database = 'postgres',
    String username = 'postgres',
    String? password,
    ConnectionFactory? connections,
    List<DriverExtension> extensions = const [],
  }) => PostgresDriverAdapter.custom(
    config: DatabaseConfig(
      driver: 'postgres',
      options: {
        'host': 'localhost',
        'port': 5432,
        'database': database,
        'username': username,
        if (password != null) 'password': password,
      },
    ),
    connections: connections,
    extensions: extensions,
  );

  final DriverMetadata _metadata;
  final ValueCodecRegistry _codecs;
  final SchemaPlanCompiler _schemaCompiler;
  final DriverExtensionRegistry _extensions;
  late final PostgresQueryGrammar _grammar;
  final ConnectionFactory _connections;
  final DatabaseConfig _config;
  late final PlanCompiler _planCompiler;
  ConnectionHandle<Connection>? _primaryHandle;
  bool _closed = false;
  Session? _activeSession;
  int _transactionDepth = 0;
  @override
  PlanCompiler get planCompiler => _planCompiler;

  @override
  DriverMetadata get metadata => _metadata;

  @override
  ValueCodecRegistry get codecs => _codecs;

  @override
  DriverExtensionRegistry get driverExtensions => _extensions;

  @override
  void registerExtensions(Iterable<DriverExtension> extensions) {
    _extensions.registerAll(extensions);
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    if (_primaryHandle != null) {
      await _primaryHandle!.close();
      _primaryHandle = null;
    }
    _closed = true;
  }

  @override
  Future<void> executeRaw(
    String sql, [
    List<Object?> parameters = const [],
  ]) async {
    final session = await _executionSession();
    final statement = _prepareStatement(sql, parameters);
    if (statement.parameters.isEmpty) {
      await session.execute(statement.query);
    } else {
      await session.execute(statement.query, parameters: statement.parameters);
    }
  }

  @override
  Future<List<Map<String, Object?>>> queryRaw(
    String sql, [
    List<Object?> parameters = const [],
  ]) async {
    final session = await _executionSession();
    final statement = _prepareStatement(sql, parameters);
    final result = await session.execute(
      statement.query,
      parameters: statement.parameters.isEmpty ? null : statement.parameters,
    );
    return _collectRows(result);
  }

  @override
  Future<List<Map<String, Object?>>> execute(QueryPlan plan) async {
    final session = await _executionSession();
    final compilation = _grammar.compileSelect(plan);
    final statement = _prepareStatement(compilation.sql, compilation.bindings);
    final result = await session.execute(
      statement.query,
      parameters: statement.parameters.isEmpty ? null : statement.parameters,
    );
    return _collectRows(result);
  }

  @override
  Stream<Map<String, Object?>> stream(QueryPlan plan) async* {
    final session = await _executionSession();
    final compilation = _grammar.compileSelect(plan);
    final statement = _prepareStatement(compilation.sql, compilation.bindings);
    final result = await session.execute(
      statement.query,
      parameters: statement.parameters.isEmpty ? null : statement.parameters,
    );
    for (final row in result) {
      yield Map<String, Object?>.from(row.toColumnMap());
    }
  }

  @override
  StatementPreview describeQuery(QueryPlan plan) =>
      _planCompiler.compileSelect(plan);

  @override
  Future<MutationResult> runMutation(MutationPlan plan) {
    switch (plan.operation) {
      case MutationOperation.insert:
        return _runInsert(plan);
      case MutationOperation.insertUsing:
        return _runInsertUsing(plan);
      case MutationOperation.update:
        return _runUpdate(plan);
      case MutationOperation.delete:
        return _runDelete(plan);
      case MutationOperation.upsert:
        return _runUpsert(plan);
      case MutationOperation.queryDelete:
        return _runQueryDelete(plan);
      case MutationOperation.queryUpdate:
        return _runQueryUpdate(plan);
    }
  }

  @override
  StatementPreview describeMutation(MutationPlan plan) =>
      _planCompiler.compileMutation(plan);

  List<Object?> _encodePreviewParameters(List<Object?> parameters) =>
      parameters.map(_codecs.encodeValue).toList(growable: false);

  StatementPreview _compileSelectPreview(QueryPlan plan) {
    final compilation = _grammar.compileSelect(plan);
    final normalized = _normalizeParameters(compilation.bindings);
    final previewSql = _formatPreviewSql(compilation.sql, normalized.length);
    final resolved = _grammar.substituteBindingsIntoRawSql(
      compilation.sql,
      _encodePreviewParameters(normalized),
    );
    return StatementPreview(
      payload: SqlStatementPayload(sql: previewSql, parameters: normalized),
      resolvedText: resolved,
    );
  }

  StatementPreview _compileMutationPreview(MutationPlan plan) {
    final shape = _shapeForPlan(plan);
    if (shape.parameterSets.isEmpty) {
      return StatementPreview(
        payload: SqlStatementPayload(sql: shape.sql),
        resolvedText: shape.sql,
      );
    }
    final normalized = shape.parameterSets
        .map(_normalizeParameters)
        .toList(growable: false);
    final previewSql = _formatPreviewSql(shape.sql, normalized.first.length);
    final resolved = _grammar.substituteBindingsIntoRawSql(
      shape.sql,
      _encodePreviewParameters(normalized.first),
    );
    return StatementPreview(
      payload: SqlStatementPayload(
        sql: previewSql,
        parameters: normalized.first,
      ),
      parameterSets: normalized,
      resolvedText: resolved,
    );
  }

  @override
  Future<R> transaction<R>(Future<R> Function() action) async {
    if (_transactionDepth > 0) {
      return _runNestedTransaction(action);
    }

    final connection = await _connection();
    _transactionDepth++;
    try {
      return await connection.runTx((tx) async {
        _activeSession = tx;
        try {
          return await action();
        } finally {
          _activeSession = null;
        }
      });
    } finally {
      _transactionDepth--;
    }
  }

  @override
  Future<void> applySchemaPlan(SchemaPlan plan) async {
    final preview = describeSchemaPlan(plan);

    for (final statement in preview.statements) {
      final session = await _executionSession();
      final prepared = _prepareStatement(statement.sql, statement.parameters);
      if (prepared.parameters.isEmpty) {
        await session.execute(prepared.query);
      } else {
        await session.execute(
          prepared.query,
          parameters: prepared.parameters,
        );
      }
    }
  }

  @override
  Future<void> beginTransaction() async {
    final connection = await _connection();
    if (_transactionDepth == 0) {
      await connection.execute('BEGIN');
      _transactionDepth++;
      // Set active session so nested transactions can use it
      _activeSession = connection;
    } else {
      // Use savepoint for nested transactions
      final savepoint = 'sp_${_transactionDepth + 1}';
      await connection.execute('SAVEPOINT $savepoint');
      _transactionDepth++;
    }
  }

  @override
  Future<void> commitTransaction() async {
    if (_transactionDepth == 0) {
      throw StateError('No active transaction to commit');
    }

    final connection = await _connection();
    if (_transactionDepth == 1) {
      await connection.execute('COMMIT');
      _transactionDepth--;
      _activeSession = null; // Clear session when top-level transaction ends
    } else {
      // Release savepoint for nested transactions
      final savepoint = 'sp_$_transactionDepth';
      await connection.execute('RELEASE SAVEPOINT $savepoint');
      _transactionDepth--;
    }
  }

  @override
  Future<void> rollbackTransaction() async {
    if (_transactionDepth == 0) {
      throw StateError('No active transaction to rollback');
    }

    final connection = await _connection();
    if (_transactionDepth == 1) {
      await connection.execute('ROLLBACK');
      _transactionDepth--;
      _activeSession = null; // Clear session when top-level transaction ends
    } else {
      // Rollback to savepoint for nested transactions
      final savepoint = 'sp_$_transactionDepth';
      await connection.execute('ROLLBACK TO SAVEPOINT $savepoint');
      _transactionDepth--;
    }
  }

  @override
  Future<void> truncateTable(String tableName) async {
    final connection = await _connection();
    // PostgreSQL supports TRUNCATE TABLE with RESTART IDENTITY
    await connection.execute('TRUNCATE TABLE $tableName RESTART IDENTITY');
  }

  @override
  SchemaPreview describeSchemaPlan(SchemaPlan plan) {
    return _schemaCompiler.compile(plan);
  }

  @override
  SchemaState? createSchemaState({
    required OrmConnection connection,
    required String ledgerTable,
  }) {
    return PostgresSchemaState(
      config: _config,
      connection: connection,
      ledgerTable: ledgerTable,
    );
  }

  @override
  Future<List<SchemaNamespace>> listSchemas() async {
    final sql = _schemaCompiler.dialect.compileSchemas();
    if (sql == null) {
      throw UnsupportedError('PostgreSQL should support schema listing');
    }

    final rows = await queryRaw(sql);
    return rows
        .map(
          (row) => SchemaNamespace(
            name: row['name'] as String,
            owner: row['owner'] as String?,
            isDefault: row['is_default'] as bool? ?? false,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<List<SchemaTable>> listTables({String? schema}) async {
    final sql = _schemaCompiler.dialect.compileTables(schema: schema);
    if (sql == null) {
      throw UnsupportedError('PostgreSQL should support table listing');
    }

    final rows = await queryRaw(sql, schema == null ? const [] : [schema]);
    return rows
        .map(
          (row) => SchemaTable(
            name: row['table_name'] as String,
            schema: row['table_schema'] as String?,
            type: row['table_type'] as String?,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<List<SchemaView>> listViews({String? schema}) async {
    final sql = _schemaCompiler.dialect.compileViews(schema: schema);
    if (sql == null) {
      throw UnsupportedError('PostgreSQL should support view listing');
    }

    final rows = await queryRaw(sql, schema == null ? const [] : [schema]);
    return rows
        .map(
          (row) => SchemaView(
            name: row['table_name'] as String,
            schema: row['table_schema'] as String?,
            definition: row['view_definition'] as String?,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<List<SchemaColumn>> listColumns(String table, {String? schema}) async {
    final sql = _schemaCompiler.dialect.compileColumns(table, schema: schema);
    if (sql == null) {
      throw UnsupportedError('PostgreSQL should support column listing');
    }

    final rows = await queryRaw(
      sql,
      schema == null ? [table] : [table, schema],
    );
    final pkColumns = await _primaryKeyColumns(table, schema: schema);
    return rows
        .map(
          (row) => SchemaColumn(
            name: row['column_name'] as String,
            dataType: row['data_type'] as String,
            schema: row['table_schema'] as String?,
            tableName: row['table_name'] as String?,
            length: row['character_maximum_length'] as int?,
            numericPrecision: row['numeric_precision'] as int?,
            numericScale: row['numeric_scale'] as int?,
            nullable: (row['is_nullable'] as String?) != 'NO',
            defaultValue: row['column_default'] as String?,
            autoIncrement: _isAutoIncrement(row),
            primaryKey: pkColumns.contains(row['column_name']),
            comment: row['comment'] as String?,
            generatedExpression: row['generation_expression'] as String?,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<List<SchemaIndex>> listIndexes(String table, {String? schema}) async {
    final sql = _schemaCompiler.dialect.compileIndexes(table, schema: schema);
    if (sql == null) {
      throw UnsupportedError('PostgreSQL should support index listing');
    }

    final rows = await queryRaw(
      sql,
      schema == null ? [table] : [table, schema],
    );
    return rows
        .map(
          (row) => SchemaIndex(
            name: row['index_name'] as String,
            columns: _normalizeTextArray(row['columns']),
            schema: row['schema'] as String?,
            tableName: row['table_name'] as String?,
            unique: row['unique'] as bool? ?? false,
            primary: row['primary'] as bool? ?? false,
            method: row['method'] as String?,
            whereClause: row['where_clause'] as String?,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<List<SchemaForeignKey>> listForeignKeys(
    String table, {
    String? schema,
  }) async {
    final sql = _schemaCompiler.dialect.compileForeignKeys(
      table,
      schema: schema,
    );
    if (sql == null) {
      throw UnsupportedError('PostgreSQL should support foreign key listing');
    }

    final rows = await queryRaw(
      sql,
      schema == null ? [table] : [table, schema],
    );
    final byConstraint = <String, List<Map<String, Object?>>>{};
    for (final row in rows) {
      final key = row['constraint_name'] as String;
      byConstraint.putIfAbsent(key, () => []).add(row);
    }
    return byConstraint.entries
        .map((entry) {
          final rows = entry.value
            ..sort(
              (a, b) => (a['ordinal_position'] as int).compareTo(
                b['ordinal_position'] as int,
              ),
            );
          return SchemaForeignKey(
            name: entry.key,
            columns: rows.map((row) => row['column_name'] as String).toList(),
            tableName: table,
            referencedTable: rows.first['referenced_table'] as String,
            referencedColumns: rows
                .map((row) => row['referenced_column'] as String)
                .toList(),
            schema: rows.first['table_schema'] as String?,
            referencedSchema: rows.first['referenced_schema'] as String?,
            onUpdate: rows.first['update_rule'] as String?,
            onDelete: rows.first['delete_rule'] as String?,
          );
        })
        .toList(growable: false);
  }

  // ========== Database Management ==========

  @override
  Future<bool> createDatabase(
    String name, {
    Map<String, Object?>? options,
  }) async {
    final sql = _schemaCompiler.dialect.compileCreateDatabase(name, options);
    if (sql == null) {
      throw UnsupportedError('PostgreSQL should support database creation');
    }

    // Postgres requires being outside a transaction block for CREATE DATABASE
    if (_transactionDepth > 0) {
      throw StateError('Cannot create database within a transaction');
    }

    try {
      await executeRaw(sql);
      return true;
    } on Exception catch (e) {
      // Check if error is "database exists" (error code 42P04)
      final errorMsg = e.toString();
      if (errorMsg.contains('42P04') ||
          errorMsg.toLowerCase().contains('already exists')) {
        return false;
      }
      rethrow;
    }
  }

  @override
  Future<bool> dropDatabase(String name) async {
    final sql = 'DROP DATABASE ${_quote(name)}';

    if (_transactionDepth > 0) {
      throw StateError('Cannot drop database within a transaction');
    }

    await executeRaw(sql);
    return true;
  }

  @override
  Future<bool> dropDatabaseIfExists(String name) async {
    if (_transactionDepth > 0) {
      throw StateError('Cannot drop database within a transaction');
    }

    // Check if database exists first
    final databases = await listDatabases();
    if (!databases.contains(name)) {
      return false;
    }

    final sql = _schemaCompiler.dialect.compileDropDatabaseIfExists(name);
    if (sql == null) {
      throw UnsupportedError('PostgreSQL should support database dropping');
    }

    await executeRaw(sql);
    return true;
  }

  @override
  Future<List<String>> listDatabases() async {
    final sql = _schemaCompiler.dialect.compileListDatabases();
    if (sql == null) {
      throw UnsupportedError('PostgreSQL should support listing databases');
    }

    final results = await queryRaw(sql);
    return results.map((row) => row['datname'] as String).toList();
  }

  // ========== Schema (Namespace) Management ==========

  @override
  Future<bool> createSchema(String name) async {
    try {
      await executeRaw('CREATE SCHEMA ${_quote(name)}');
      return true;
    } on Exception catch (e) {
      // Check if error is "schema exists" (error code 42P06)
      final errorMsg = e.toString();
      if (errorMsg.contains('42P06') ||
          errorMsg.toLowerCase().contains('already exists')) {
        return false;
      }
      rethrow;
    }
  }

  @override
  Future<bool> dropSchemaIfExists(String name) async {
    try {
      await executeRaw('DROP SCHEMA IF EXISTS ${_quote(name)} CASCADE');
      return true;
    } catch (e) {
      // Return false if schema didn't exist (shouldn't happen with IF EXISTS)
      return false;
    }
  }

  @override
  Future<void> setCurrentSchema(String name) async {
    await executeRaw('SET search_path TO ${_quote(name)}, public');
  }

  @override
  Future<String> getCurrentSchema() async {
    final result = await queryRaw('SHOW search_path');
    if (result.isEmpty) {
      return 'public';
    }
    final searchPath = result.first['search_path'] as String? ?? 'public';
    // Return the first schema in the search_path
    return searchPath.split(',').first.trim().replaceAll('"', '');
  }

  // ========== Foreign Key Constraint Management ==========

  @override
  Future<bool> enableForeignKeyConstraints() async {
    // PostgreSQL doesn't have session-level FK disable
    // Must use ALTER TABLE ... ENABLE TRIGGER ALL on each table
    // List tables from the current search_path (no schema filter = uses search_path)
    final tables = await listTables();

    for (final table in tables) {
      // Use the schema from the table if available, otherwise just the table name
      final tableName = table.schema != null
          ? '${_quote(table.schema!)}.${_quote(table.name)}'
          : _quote(table.name);
      try {
        await executeRaw('ALTER TABLE $tableName ENABLE TRIGGER ALL');
      } catch (e) {
        // Ignore errors if table doesn't exist - it may have been dropped
        // or may be in a different schema than expected
        final errorMsg = e.toString().toLowerCase();
        if (!errorMsg.contains('does not exist') &&
            !errorMsg.contains('42p01')) {
          rethrow;
        }
      }
    }

    return true;
  }

  @override
  Future<bool> disableForeignKeyConstraints() async {
    // List tables from the current search_path (no schema filter = uses search_path)
    final tables = await listTables();

    for (final table in tables) {
      // Use the schema from the table if available, otherwise just the table name
      final tableName = table.schema != null
          ? '${_quote(table.schema!)}.${_quote(table.name)}'
          : _quote(table.name);
      try {
        await executeRaw('ALTER TABLE $tableName DISABLE TRIGGER ALL');
      } catch (e) {
        // Ignore errors if table doesn't exist - it may have been dropped
        // or may be in a different schema than expected
        final errorMsg = e.toString().toLowerCase();
        if (!errorMsg.contains('does not exist') &&
            !errorMsg.contains('42p01')) {
          rethrow;
        }
      }
    }

    return true;
  }

  @override
  Future<T> withoutForeignKeyConstraints<T>(
    Future<T> Function() callback,
  ) async {
    await disableForeignKeyConstraints();
    try {
      return await callback();
    } finally {
      await enableForeignKeyConstraints();
    }
  }

  // ========== Bulk Operations ==========

  @override
  Future<void> dropAllTables({String? schema}) async {
    final schemaName = schema ?? await getCurrentSchema();
    final tables = await listTables(schema: schemaName);

    if (tables.isEmpty) return;

    // Disable constraints to mirror Laravel behavior, then drop with CASCADE
    // Note: We don't re-enable constraints after dropping since there are no tables left
    try {
      // Disable triggers on all tables first
      for (final table in tables) {
        final tableName = '${_quote(schemaName)}.${_quote(table.name)}';
        try {
          await executeRaw('ALTER TABLE $tableName DISABLE TRIGGER ALL');
        } catch (_) {
          // Ignore - table may already be dropped
        }
      }

      // Drop all tables with CASCADE
      for (final table in tables) {
        final tableName = '${_quote(schemaName)}.${_quote(table.name)}';
        await executeRaw('DROP TABLE IF EXISTS $tableName CASCADE');
      }
    } catch (e) {
      // Try to re-enable constraints on any remaining tables
      try {
        await enableForeignKeyConstraints();
      } catch (_) {
        // Ignore - tables may not exist
      }
      rethrow;
    }
  }

  // ========== Existence Checking ==========

  @override
  Future<bool> hasTable(String table, {String? schema}) async {
    final tables = await listTables(schema: schema ?? 'public');
    return tables.any((t) => t.name.toLowerCase() == table.toLowerCase());
  }

  @override
  Future<bool> hasView(String view, {String? schema}) async {
    final views = await listViews(schema: schema ?? 'public');
    return views.any((v) => v.name.toLowerCase() == view.toLowerCase());
  }

  @override
  Future<bool> hasColumn(String table, String column, {String? schema}) async {
    final columns = await listColumns(table, schema: schema);
    return columns.any((c) => c.name.toLowerCase() == column.toLowerCase());
  }

  @override
  Future<bool> hasColumns(
    String table,
    List<String> columns, {
    String? schema,
  }) async {
    final tableColumns = await listColumns(table, schema: schema);
    final lowerCaseColumns = tableColumns
        .map((c) => c.name.toLowerCase())
        .toSet();

    for (final column in columns) {
      if (!lowerCaseColumns.contains(column.toLowerCase())) {
        return false;
      }
    }

    return true;
  }

  @override
  Future<bool> hasIndex(
    String table,
    String index, {
    String? schema,
    String? type,
  }) async {
    final indexes = await listIndexes(table, schema: schema);

    for (final idx in indexes) {
      final typeMatches =
          type == null ||
          (type == 'primary' && idx.primary) ||
          (type == 'unique' && idx.unique) ||
          type.toLowerCase() == idx.type?.toLowerCase();

      if (idx.name.toLowerCase() == index.toLowerCase() && typeMatches) {
        return true;
      }
    }

    return false;
  }

  Future<MutationResult> _runInsert(MutationPlan plan) async {
    if (plan.rows.isEmpty) {
      return const MutationResult(affectedRows: 0);
    }

    final pkField = plan.definition.primaryKeyField;
    final pkColumn = pkField?.columnName;

    // Check if we have mixed rows (some with PK, some without) for auto-increment PKs
    if (pkColumn != null && pkField!.autoIncrement) {
      final rowsWithPk = <MutationRow>[];
      final rowsWithoutPk = <MutationRow>[];

      for (final row in plan.rows) {
        final pkValue = row.values[pkColumn];
        if (pkValue != null && pkValue != 0) {
          rowsWithPk.add(row);
        } else {
          // Remove the PK from values for rows without it
          final newValues = Map<String, Object?>.from(row.values);
          newValues.remove(pkColumn);
          rowsWithoutPk.add(
            MutationRow(
              values: newValues,
              keys: row.keys,
              jsonUpdates: row.jsonUpdates,
            ),
          );
        }
      }

      // If we have both types, execute separately and combine results
      if (rowsWithPk.isNotEmpty && rowsWithoutPk.isNotEmpty) {
        // Execute rows with PK
        final planWithPk = MutationPlan.insert(
          definition: plan.definition,
          rows: rowsWithPk.map((r) => r.values).toList(),
          driverName: plan.driverName,
          returning: plan.returning,
          ignoreConflicts: plan.ignoreConflicts,
        );
        final shapeWithPk = _buildInsertShape(planWithPk);
        final resultWithPk = await _executeMutation(shapeWithPk);

        // Execute rows without PK
        final planWithoutPk = MutationPlan.insert(
          definition: plan.definition,
          rows: rowsWithoutPk.map((r) => r.values).toList(),
          driverName: plan.driverName,
          returning: plan.returning,
          ignoreConflicts: plan.ignoreConflicts,
        );
        final shapeWithoutPk = _buildInsertShape(planWithoutPk);
        final resultWithoutPk = await _executeMutation(shapeWithoutPk);

        // Combine results in original order
        final combinedRows = <Map<String, Object?>>[];
        int withPkIndex = 0;
        int withoutPkIndex = 0;
        for (final row in plan.rows) {
          final pkValue = row.values[pkColumn];
          if (pkValue != null && pkValue != 0) {
            if (resultWithPk.returnedRows != null &&
                withPkIndex < resultWithPk.returnedRows!.length) {
              combinedRows.add(resultWithPk.returnedRows![withPkIndex]);
            }
            withPkIndex++;
          } else {
            if (resultWithoutPk.returnedRows != null &&
                withoutPkIndex < resultWithoutPk.returnedRows!.length) {
              combinedRows.add(resultWithoutPk.returnedRows![withoutPkIndex]);
            }
            withoutPkIndex++;
          }
        }

        return MutationResult(
          affectedRows:
              resultWithPk.affectedRows + resultWithoutPk.affectedRows,
          returnedRows: plan.returning ? combinedRows : null,
        );
      }

      // Only one type of rows
      if (rowsWithPk.isNotEmpty) {
        final newPlan = MutationPlan.insert(
          definition: plan.definition,
          rows: rowsWithPk.map((r) => r.values).toList(),
          driverName: plan.driverName,
          returning: plan.returning,
          ignoreConflicts: plan.ignoreConflicts,
        );
        final shape = _buildInsertShape(newPlan);
        return _executeMutation(shape);
      } else {
        final newPlan = MutationPlan.insert(
          definition: plan.definition,
          rows: rowsWithoutPk.map((r) => r.values).toList(),
          driverName: plan.driverName,
          returning: plan.returning,
          ignoreConflicts: plan.ignoreConflicts,
        );
        final shape = _buildInsertShape(newPlan);
        return _executeMutation(shape);
      }
    }

    // Non-auto-increment PK or no PK - use standard shape
    final shape = _buildInsertShape(plan);
    return _executeMutation(shape);
  }

  Future<MutationResult> _runInsertUsing(MutationPlan plan) async {
    final shape = _buildInsertUsingShape(plan);
    return _executeMutation(shape);
  }

  Future<MutationResult> _runUpdate(MutationPlan plan) async {
    final shape = _buildUpdateShape(plan);
    return _executeMutation(shape);
  }

  Future<MutationResult> _runDelete(MutationPlan plan) async {
    final shape = _buildDeleteShape(plan);
    return _executeMutation(shape);
  }

  Future<MutationResult> _runUpsert(MutationPlan plan) async {
    if (plan.rows.isEmpty) {
      return const MutationResult(affectedRows: 0);
    }

    final pkField = plan.definition.primaryKeyField;
    final pkColumn = pkField?.columnName;

    // Check if we have mixed rows (some with PK, some without) for auto-increment PKs
    if (pkColumn != null && pkField!.autoIncrement) {
      final rowsWithPk = <MutationRow>[];
      final rowsWithoutPk = <MutationRow>[];

      for (final row in plan.rows) {
        final pkValue = row.values[pkColumn];
        if (pkValue != null && pkValue != 0) {
          rowsWithPk.add(row);
        } else {
          // Remove the PK from values for rows without it
          final newValues = Map<String, Object?>.from(row.values);
          newValues.remove(pkColumn);
          rowsWithoutPk.add(
            MutationRow(
              values: newValues,
              keys: row.keys,
              jsonUpdates: row.jsonUpdates,
            ),
          );
        }
      }

      // If we have both types, execute separately and combine results
      if (rowsWithPk.isNotEmpty && rowsWithoutPk.isNotEmpty) {
        // Execute rows with PK first
        final planWithPk = MutationPlan.upsert(
          definition: plan.definition,
          rows: rowsWithPk,
          driverName: plan.driverName,
          returning: plan.returning,
          uniqueBy: plan.upsertUniqueColumns,
          updateColumns: plan.upsertUpdateColumns,
        );
        final shapeWithPk = _buildUpsertShapeForRows(
          planWithPk,
          rowsWithPk,
          pkColumn,
          true,
        );
        final resultWithPk = await _executeMutation(shapeWithPk);

        // Execute rows without PK
        final planWithoutPk = MutationPlan.upsert(
          definition: plan.definition,
          rows: rowsWithoutPk,
          driverName: plan.driverName,
          returning: plan.returning,
          uniqueBy: plan.upsertUniqueColumns,
          updateColumns: plan.upsertUpdateColumns,
        );
        final shapeWithoutPk = _buildUpsertShapeForRows(
          planWithoutPk,
          rowsWithoutPk,
          pkColumn,
          false,
        );
        final resultWithoutPk = await _executeMutation(shapeWithoutPk);

        // Combine results in original order
        final combinedRows = <Map<String, Object?>>[];
        int withPkIndex = 0;
        int withoutPkIndex = 0;
        for (final row in plan.rows) {
          final pkValue = row.values[pkColumn];
          if (pkValue != null && pkValue != 0) {
            if (resultWithPk.returnedRows != null &&
                withPkIndex < resultWithPk.returnedRows!.length) {
              combinedRows.add(resultWithPk.returnedRows![withPkIndex]);
            }
            withPkIndex++;
          } else {
            if (resultWithoutPk.returnedRows != null &&
                withoutPkIndex < resultWithoutPk.returnedRows!.length) {
              combinedRows.add(resultWithoutPk.returnedRows![withoutPkIndex]);
            }
            withoutPkIndex++;
          }
        }

        return MutationResult(
          affectedRows:
              resultWithPk.affectedRows + resultWithoutPk.affectedRows,
          returnedRows: plan.returning ? combinedRows : null,
        );
      }

      // Only one type of rows, build shape accordingly
      if (rowsWithPk.isNotEmpty) {
        final shape = _buildUpsertShapeForRows(
          plan,
          rowsWithPk,
          pkColumn,
          true,
        );
        return _executeMutation(shape);
      } else {
        final shape = _buildUpsertShapeForRows(
          plan,
          rowsWithoutPk,
          pkColumn,
          false,
        );
        return _executeMutation(shape);
      }
    }

    // Non-auto-increment PK or no PK - use standard shape
    final shape = _buildUpsertShapeForRows(
      plan,
      plan.rows.toList(),
      pkColumn,
      true,
    );
    return _executeMutation(shape);
  }

  Future<MutationResult> _runQueryUpdate(MutationPlan plan) async {
    final shape = _buildQueryUpdateShape(plan);
    return _executeMutation(shape);
  }

  Future<MutationResult> _executeMutation(_PostgresMutationShape shape) async {
    if (shape.parameterSets.isEmpty) {
      return const MutationResult(affectedRows: 0);
    }
    final session = await _executionSession();
    var affected = 0;
    List<Map<String, Object?>>? returnedRows;

    for (final parameters in shape.parameterSets) {
      final statement = _prepareStatement(shape.sql, parameters);
      final result = await session.execute(
        statement.query,
        parameters: statement.parameters.isEmpty ? null : statement.parameters,
      );
      affected += result.affectedRows;
      if (shape.returnsRows) {
        returnedRows ??= <Map<String, Object?>>[];
        returnedRows.addAll(_collectRows(result));
      }
    }

    return MutationResult(affectedRows: affected, returnedRows: returnedRows);
  }

  _PostgresMutationShape _shapeForPlan(MutationPlan plan) {
    switch (plan.operation) {
      case MutationOperation.insert:
        return _buildInsertShape(plan);
      case MutationOperation.insertUsing:
        return _buildInsertUsingShape(plan);
      case MutationOperation.update:
        return _buildUpdateShape(plan);
      case MutationOperation.delete:
        return _buildDeleteShape(plan);
      case MutationOperation.upsert:
        return _buildUpsertShape(plan);
      case MutationOperation.queryDelete:
        return _buildQueryDeleteShape(plan);
      case MutationOperation.queryUpdate:
        return _buildQueryUpdateShape(plan);
    }
  }

  Future<MutationResult> _runQueryDelete(MutationPlan plan) async {
    final shape = _buildQueryDeleteShape(plan);
    return _executeMutation(shape);
  }

  _PostgresMutationShape _buildInsertShape(MutationPlan plan) {
    if (plan.rows.isEmpty) return _PostgresMutationShape.empty();
    final insertFields = plan.definition.fields
        .where((field) {
          if (_shouldUseDefaultForInsert(field, plan.rows)) {
            return false;
          }
          for (final row in plan.rows) {
            if (row.values.containsKey(field.columnName)) {
              return true;
            }
          }
          return false;
        })
        .toList(growable: false);
    final returning = plan.returning
        ? ' RETURNING ${_returningColumns(plan.definition)}'
        : '';
    final ignoreClause = plan.ignoreConflicts ? ' ON CONFLICT DO NOTHING' : '';
    final sql = insertFields.isEmpty
        ? 'INSERT INTO ${_tableIdentifier(plan.definition)} '
              'DEFAULT VALUES$ignoreClause$returning'
        : 'INSERT INTO ${_tableIdentifier(plan.definition)} '
              '(${insertFields.map((f) => _quote(f.columnName)).join(', ')}) '
              'VALUES (${List.filled(insertFields.length, '?').join(', ')})'
              '$ignoreClause$returning';
    final parameterSets = insertFields.isEmpty
        ? List<List<Object?>>.generate(plan.rows.length, (_) => const [])
        : plan.rows
              .map(
                (row) => insertFields
                    .map((field) => row.values[field.columnName])
                    .toList(),
              )
              .toList(growable: false);
    return _PostgresMutationShape(
      sql: sql,
      parameterSets: parameterSets,
      returnsRows: plan.returning,
    );
  }

  _PostgresMutationShape _buildInsertUsingShape(MutationPlan plan) {
    final queryPlan = plan.queryPlan;
    if (queryPlan == null || plan.insertColumns.isEmpty) {
      return _PostgresMutationShape.empty();
    }
    final compilation = _grammar.compileSelect(queryPlan);
    final columns = plan.insertColumns.map(_quote).join(', ');
    final ignoreClause = plan.ignoreConflicts ? ' ON CONFLICT DO NOTHING' : '';
    final returning = plan.returning
        ? ' RETURNING ${_returningColumns(plan.definition)}'
        : '';
    final sql = StringBuffer('INSERT INTO ')
      ..write(_tableIdentifier(plan.definition))
      ..write(' ($columns) ')
      ..write(compilation.sql)
      ..write(ignoreClause)
      ..write(returning);
    return _PostgresMutationShape(
      sql: sql.toString(),
      parameterSets: [compilation.bindings.toList(growable: false)],
      returnsRows: plan.returning,
    );
  }

  _PostgresMutationShape _buildUpdateShape(MutationPlan plan) {
    if (plan.rows.isEmpty) return _PostgresMutationShape.empty();
    final table = _tableIdentifier(plan.definition);
    final firstRow = plan.rows.first;
    final jsonTemplates = _jsonUpdateTemplates(firstRow);
    final jsonColumns = jsonTemplates.map((t) => t.column).toSet();
    final setColumns = firstRow.values.keys
        .where((column) => !jsonColumns.contains(column))
        .toList();
    if (setColumns.isEmpty && jsonTemplates.isEmpty) {
      return _PostgresMutationShape.empty();
    }
    final assignments = <String>[];
    if (setColumns.isNotEmpty) {
      assignments.addAll(setColumns.map((c) => '${_quote(c)} = ?'));
    }
    assignments.addAll(jsonTemplates.map((template) => template.sql));
    final whereColumns = firstRow.keys.keys.toList();
    final whereClause = _whereClause(firstRow.keys);
    final returning = plan.returning
        ? ' RETURNING ${_returningColumns(plan.definition)}'
        : '';
    final sql =
        'UPDATE $table SET ${assignments.join(', ')} WHERE $whereClause$returning';
    final parameterSets = plan.rows
        .map((row) {
          final parameters = <Object?>[...setColumns.map((c) => row.values[c])];
          if (jsonTemplates.isNotEmpty) {
            final clauses = row.jsonUpdates;
            _validateJsonUpdateShape(jsonTemplates, clauses);

            // Group clauses by column to match template structure
            final grouped = <String, List<JsonUpdateClause>>{};
            for (final clause in clauses) {
              grouped
                  .putIfAbsent(clause.column, () => <JsonUpdateClause>[])
                  .add(clause);
            }

            // Collect bindings for each template (column group)
            for (final template in jsonTemplates) {
              final columnClauses = grouped[template.column]!;
              var expression = template.resolvedColumn;

              for (final clause in columnClauses) {
                final compiled = clause.patch
                    ? _grammar.compileJsonPatch(
                        clause.column,
                        expression,
                        clause.value,
                      )
                    : _grammar.compileJsonUpdate(
                        clause.column,
                        expression,
                        clause.path,
                        clause.value,
                      );
                expression = _assignmentRhs(compiled.sql);
                parameters.addAll(compiled.bindings);
              }
            }
          }
          parameters.addAll(whereColumns.map((c) => row.keys[c]));
          return parameters;
        })
        .toList(growable: false);
    return _PostgresMutationShape(
      sql: sql,
      parameterSets: parameterSets,
      returnsRows: plan.returning,
    );
  }

  _PostgresMutationShape _buildDeleteShape(MutationPlan plan) {
    if (plan.rows.isEmpty) return _PostgresMutationShape.empty();
    final table = _tableIdentifier(plan.definition);
    final firstRow = plan.rows.first;
    final whereColumns = firstRow.keys.keys.toList();
    final whereClause = _whereClause(firstRow.keys);
    final returning = plan.returning
        ? ' RETURNING ${_returningColumns(plan.definition)}'
        : '';
    final sql = 'DELETE FROM $table WHERE $whereClause$returning';
    final parameterSets = plan.rows
        .map((row) => whereColumns.map((c) => row.keys[c]).toList())
        .toList(growable: false);
    return _PostgresMutationShape(
      sql: sql,
      parameterSets: parameterSets,
      returnsRows: plan.returning,
    );
  }

  _PostgresMutationShape _buildQueryDeleteShape(MutationPlan plan) {
    final queryPlan = plan.queryPlan;
    if (queryPlan == null) {
      return _PostgresMutationShape.empty();
    }
    final primaryKey =
        plan.queryPrimaryKey ?? plan.definition.primaryKeyField?.columnName;
    if (primaryKey == null || primaryKey.isEmpty) {
      throw StateError(
        'Query deletes on ${plan.definition.modelName} require a primary key.',
      );
    }
    final compilation = _grammar.compileSelect(queryPlan);
    final table = _tableIdentifier(plan.definition);
    final targetAlias = _quote('__orm_delete_target');
    final sourceAlias = _quote('__orm_delete_source');
    final pkIdentifier = _quote(primaryKey);
    final returning = plan.returning
        ? ' RETURNING ${_returningColumnsWithAlias(plan.definition, targetAlias)}'
        : '';
    final sql = StringBuffer('DELETE FROM ')
      ..write(table)
      ..write(' AS ')
      ..write(targetAlias)
      ..write(' USING (')
      ..write(compilation.sql)
      ..write(') AS ')
      ..write(sourceAlias)
      ..write(' WHERE ')
      ..write('$sourceAlias.$pkIdentifier = $targetAlias.$pkIdentifier')
      ..write(returning);
    return _PostgresMutationShape(
      sql: sql.toString(),
      parameterSets: [compilation.bindings.toList(growable: false)],
      returnsRows: plan.returning,
    );
  }

  _PostgresMutationShape _buildQueryUpdateShape(MutationPlan plan) {
    final queryPlan = plan.queryPlan;
    final hasColumns = plan.queryUpdateValues.isNotEmpty;
    final hasJson = plan.queryJsonUpdates.isNotEmpty;
    final hasIncrements = plan.queryIncrementValues.isNotEmpty;
    if (queryPlan == null || (!hasColumns && !hasJson && !hasIncrements)) {
      return _PostgresMutationShape.empty();
    }
    final key =
        plan.queryPrimaryKey ?? plan.definition.primaryKeyField?.columnName;
    if (key == null) {
      throw StateError(
        'Query updates on ${plan.definition.modelName} require a primary key.',
      );
    }
    final baseReference = _baseTableReference(queryPlan);
    final keyAlias = _quote(key);
    final sourceAlias = _quote('__orm_update_source');
    final projectionPlan = plan.definition.primaryKeyField == null
        ? queryPlan.copyWith(
            selects: const [],
            rawSelects: [
              RawSelectExpression(sql: '$baseReference.$keyAlias', alias: key),
            ],
            aggregates: const [],
          )
        : queryPlan;
    final compilation = _grammar.compileSelect(projectionPlan);
    final assignments = <String>[];
    final parameters = <Object?>[];
    if (hasColumns) {
      assignments.addAll(
        plan.queryUpdateValues.keys.map((column) => '${_quote(column)} = ?'),
      );
      parameters.addAll(plan.queryUpdateValues.values);
    }
    if (hasIncrements) {
      final baseRef = _baseTableReference(queryPlan);
      for (final entry in plan.queryIncrementValues.entries) {
        final column = entry.key;
        final amount = entry.value;
        assignments.add('${_quote(column)} = $baseRef.${_quote(column)} + ?');
        parameters.add(amount);
      }
    }
    if (hasJson) {
      final grouped = <String, List<JsonUpdateClause>>{};
      for (final clause in plan.queryJsonUpdates) {
        grouped
            .putIfAbsent(clause.column, () => <JsonUpdateClause>[])
            .add(clause);
      }
      grouped.forEach((column, clauses) {
        final resolved = _quote(column);
        var expression = '$baseReference.$resolved';
        final clauseBindings = <Object?>[];
        for (final clause in clauses) {
          final compiled = clause.patch
              ? _grammar.compileJsonPatch(
                  clause.column,
                  expression,
                  clause.value,
                )
              : _grammar.compileJsonUpdate(
                  clause.column,
                  expression,
                  clause.path,
                  clause.value,
                );
          expression = _assignmentRhs(compiled.sql);
          clauseBindings.addAll(compiled.bindings);
        }
        assignments.add('$resolved = $expression');
        clauseBindings.forEach(parameters.add);
      });
    }
    if (assignments.isEmpty) {
      return _PostgresMutationShape.empty();
    }
    final target = _tableIdentifier(plan.definition);
    final returning = plan.returning
        ? ' RETURNING ${_returningColumnsWithAlias(plan.definition, baseReference)}'
        : '';
    final sql = StringBuffer('UPDATE $target SET ')
      ..write(assignments.join(', '))
      ..write(' FROM (')
      ..write(compilation.sql)
      ..write(') AS ')
      ..write(sourceAlias)
      ..write(' WHERE ')
      ..write('$baseReference.$keyAlias = ')
      ..write('$sourceAlias.$keyAlias')
      ..write(returning);
    parameters.addAll(compilation.bindings);
    return _PostgresMutationShape(
      sql: sql.toString(),
      parameterSets: [parameters],
      returnsRows: plan.returning,
    );
  }

  String _baseTableReference(QueryPlan plan) {
    final schema = plan.definition.schema;
    final base = plan.tableAlias;
    if (base != null && base.isNotEmpty) {
      return _quote(base);
    }
    final table = _quote(plan.definition.tableName);
    if (schema == null || schema.isEmpty) {
      return table;
    }
    return '${_quote(schema)}.$table';
  }

  _PostgresMutationShape _buildUpsertShape(MutationPlan plan) {
    if (plan.rows.isEmpty) return _PostgresMutationShape.empty();

    final pkField = plan.definition.primaryKeyField;
    final pkColumn = pkField?.columnName;

    // For auto-increment PKs, check if we should include the PK column
    if (pkColumn != null && pkField!.autoIncrement) {
      final allRowsHaveNullPk = plan.rows.every((row) {
        final val = row.values[pkColumn];
        return val == null || val == 0;
      });
      return _buildUpsertShapeForRows(
        plan,
        plan.rows.toList(),
        pkColumn,
        !allRowsHaveNullPk,
      );
    }

    return _buildUpsertShapeForRows(plan, plan.rows.toList(), pkColumn, true);
  }

  _PostgresMutationShape _buildUpsertShapeForRows(
    MutationPlan plan,
    List<MutationRow> rows,
    String? pkColumn,
    bool includePk,
  ) {
    if (rows.isEmpty) return _PostgresMutationShape.empty();

    final table = _tableIdentifier(plan.definition);
    final firstRow = rows.first;
    var columns = firstRow.values.keys.toList();

    // Exclude PK if not including it
    if (!includePk && pkColumn != null) {
      columns = columns.where((c) => c != pkColumn).toList();
    }

    final columnSql = columns.map(_quote).join(', ');
    final placeholders = List.filled(columns.length, '?').join(', ');
    final uniqueColumns = _resolveUpsertUniqueColumns(plan);
    final updateColumns = _resolveUpsertUpdateColumns(
      plan,
      columns,
      uniqueColumns,
    );
    final jsonTemplates = _jsonUpsertUpdateTemplates(firstRow, table);
    final jsonColumns = jsonTemplates.map((t) => t.column).toSet();
    final returning = plan.returning
        ? ' RETURNING ${_returningColumns(plan.definition)}'
        : '';
    final sql = StringBuffer(
      'INSERT INTO $table ($columnSql) VALUES ($placeholders) ',
    )..write('ON CONFLICT(${uniqueColumns.map(_quote).join(', ')}) ');
    final updateAssignments = <String>[];
    updateAssignments.addAll(
      updateColumns
          .where((c) => !jsonColumns.contains(c))
          .map((c) => '${_quote(c)} = EXCLUDED.${_quote(c)}'),
    );
    updateAssignments.addAll(jsonTemplates.map((t) => t.sql));
    if (updateAssignments.isEmpty) {
      sql.write('DO NOTHING');
    } else {
      sql.write('DO UPDATE SET ${updateAssignments.join(', ')}');
    }
    sql.write(returning);
    final parameterSets = rows
        .map((row) {
          final parameters = columns
              .map((column) => row.values[column])
              .toList(growable: true);
          if (jsonTemplates.isNotEmpty) {
            final clauses = row.jsonUpdates;
            _validateJsonUpdateShape(jsonTemplates, clauses);

            final grouped = <String, List<JsonUpdateClause>>{};
            for (final clause in clauses) {
              grouped
                  .putIfAbsent(clause.column, () => <JsonUpdateClause>[])
                  .add(clause);
            }

            for (final template in jsonTemplates) {
              final columnClauses = grouped[template.column]!;
              var expression = template.resolvedColumn;
              for (final clause in columnClauses) {
                final compiled = clause.patch
                    ? _grammar.compileJsonPatch(
                        clause.column,
                        expression,
                        clause.value,
                      )
                    : _grammar.compileJsonUpdate(
                        clause.column,
                        expression,
                        clause.path,
                        clause.value,
                      );
                expression = _assignmentRhs(compiled.sql);
                parameters.addAll(compiled.bindings);
              }
            }
          }
          return parameters;
        })
        .toList(growable: false);
    return _PostgresMutationShape(
      sql: sql.toString(),
      parameterSets: parameterSets,
      returnsRows: plan.returning,
    );
  }

  List<_JsonUpdateTemplate> _jsonUpdateTemplates(MutationRow row) {
    if (row.jsonUpdates.isEmpty) {
      return const <_JsonUpdateTemplate>[];
    }

    // Group updates by base column to avoid multiple assignments
    final grouped = <String, List<JsonUpdateClause>>{};
    for (final clause in row.jsonUpdates) {
      grouped
          .putIfAbsent(clause.column, () => <JsonUpdateClause>[])
          .add(clause);
    }

    final templates = <_JsonUpdateTemplate>[];
    grouped.forEach((column, clauses) {
      final resolved = _quote(column);
      var expression = resolved;

      // Chain all updates for this column into a single expression
      for (final clause in clauses) {
        final compiled = clause.patch
            ? _grammar.compileJsonPatch(clause.column, expression, clause.value)
            : _grammar.compileJsonUpdate(
                clause.column,
                expression,
                clause.path,
                clause.value,
              );
        expression = _assignmentRhs(compiled.sql);
      }

      // Create a single template for all updates to this column
      templates.add(
        _JsonUpdateTemplate(
          column: column,
          path: clauses
              .map((c) => c.path)
              .join(','), // Combined path for validation
          sql: '$resolved = $expression',
          resolvedColumn: resolved,
          patch: clauses.any((c) => c.patch),
        ),
      );
    });

    return templates;
  }

  List<_JsonUpdateTemplate> _jsonUpsertUpdateTemplates(
    MutationRow row,
    String tableReference,
  ) {
    if (row.jsonUpdates.isEmpty) {
      return const <_JsonUpdateTemplate>[];
    }

    final grouped = <String, List<JsonUpdateClause>>{};
    for (final clause in row.jsonUpdates) {
      grouped
          .putIfAbsent(clause.column, () => <JsonUpdateClause>[])
          .add(clause);
    }

    final templates = <_JsonUpdateTemplate>[];
    grouped.forEach((column, clauses) {
      final resolved = '$tableReference.${_quote(column)}';
      var expression = resolved;

      for (final clause in clauses) {
        final compiled = clause.patch
            ? _grammar.compileJsonPatch(clause.column, expression, clause.value)
            : _grammar.compileJsonUpdate(
                clause.column,
                expression,
                clause.path,
                clause.value,
              );
        expression = _assignmentRhs(compiled.sql);
      }

      templates.add(
        _JsonUpdateTemplate(
          column: column,
          path: clauses.map((c) => c.path).join(','),
          sql: '${_quote(column)} = $expression',
          resolvedColumn: resolved,
          patch: clauses.any((c) => c.patch),
        ),
      );
    });

    return templates;
  }

  void _validateJsonUpdateShape(
    List<_JsonUpdateTemplate> templates,
    List<JsonUpdateClause> clauses,
  ) {
    if (templates.isEmpty) {
      return;
    }

    // Group clauses by column to match the template structure
    final grouped = <String, List<JsonUpdateClause>>{};
    for (final clause in clauses) {
      grouped
          .putIfAbsent(clause.column, () => <JsonUpdateClause>[])
          .add(clause);
    }

    if (templates.length != grouped.length) {
      throw StateError(
        'All mutation rows must update the same ${templates.length} columns.',
      );
    }

    // Validate that each template matches its corresponding group
    for (final template in templates) {
      final columnClauses = grouped[template.column];
      if (columnClauses == null) {
        throw StateError(
          'Row missing JSON updates for column ${template.column}.',
        );
      }

      // Validate that the paths match what we expect
      final paths = columnClauses.map((c) => c.path).join(',');
      if (template.path != paths) {
        throw StateError(
          'JSON update paths for ${template.column} must match first row.',
        );
      }
    }
  }

  List<String> _resolveUpsertUniqueColumns(MutationPlan plan) {
    if (plan.upsertUniqueColumns.isNotEmpty) {
      return plan.upsertUniqueColumns;
    }
    final pk = plan.definition.primaryKeyField?.columnName;
    if (pk != null) {
      return [pk];
    }
    throw StateError(
      'Upserts on ${plan.definition.modelName} require a primary key or uniqueBy columns.',
    );
  }

  List<String> _resolveUpsertUpdateColumns(
    MutationPlan plan,
    List<String> insertColumns,
    List<String> uniqueColumns,
  ) {
    if (plan.upsertUpdateColumns.isNotEmpty) {
      final normalized = <String>[];
      for (final column in plan.upsertUpdateColumns) {
        if (!insertColumns.contains(column)) {
          throw StateError(
            'Unknown upsert update column $column for ${plan.definition.modelName}.',
          );
        }
        normalized.add(column);
      }
      return normalized;
    }

    final conflicts = uniqueColumns.toSet();

    // Also exclude the primary key from UPDATE columns when:
    // 1. We're not conflicting on the PK (uniqueBy is on different columns)
    // 2. This prevents overwriting an existing auto-increment ID with null/0
    final pkColumn = plan.definition.primaryKeyField?.columnName;
    final excludeFromUpdate = <String>{...conflicts};
    if (pkColumn != null && !conflicts.contains(pkColumn)) {
      excludeFromUpdate.add(pkColumn);
    }

    return insertColumns.where((c) => !excludeFromUpdate.contains(c)).toList();
  }

  bool _shouldUseDefaultForInsert(
    FieldDefinition field,
    List<MutationRow> rows,
  ) {
    if (!field.autoIncrement) {
      return false;
    }
    for (final row in rows) {
      if (row.values[field.columnName] != null) {
        return false;
      }
    }
    return true;
  }

  String _returningColumns(ModelDefinition<OrmEntity> definition) {
    if (definition.fields.isEmpty) {
      return '*';
    }
    return definition.fields.map((f) => _quote(f.columnName)).join(', ');
  }

  String _returningColumnsWithAlias(
    ModelDefinition<OrmEntity> definition,
    String alias,
  ) {
    if (definition.fields.isEmpty) {
      return '$alias.*';
    }
    return definition.fields
        .map((f) => '$alias.${_quote(f.columnName)}')
        .join(', ');
  }

  Future<Connection> _connection() async {
    if (_closed) {
      throw StateError('PostgresDriverAdapter has already been closed.');
    }
    if (_primaryHandle == null) {
      final handle =
          await _connections.open(_config) as ConnectionHandle<Connection>;
      _primaryHandle = handle;
    }
    return _primaryHandle!.client;
  }

  Future<Session> _executionSession() async {
    final session = _activeSession;
    if (session != null) {
      return session;
    }
    return _connection();
  }

  Future<R> _runNestedTransaction<R>(Future<R> Function() action) async {
    final session = _activeSession;
    if (session == null) {
      throw StateError('Nested transaction requires an active session.');
    }
    final savepoint = 'sp_${_transactionDepth + 1}';
    await session.execute('SAVEPOINT $savepoint');
    _transactionDepth++;
    try {
      final result = await action();
      await session.execute('RELEASE SAVEPOINT $savepoint');
      return result;
    } catch (error) {
      await session.execute('ROLLBACK TO SAVEPOINT $savepoint');
      rethrow;
    } finally {
      _transactionDepth--;
    }
  }

  List<Map<String, Object?>> _collectRows(Result result) {
    return result
        .map((row) => Map<String, Object?>.from(row.toColumnMap()))
        .toList(growable: false);
  }

  @override
  Future<int?> threadCount() async {
    try {
      final sql = _grammar.compileThreadCount();
      if (sql == null) {
        return null;
      }
      final rows = await queryRaw(sql);
      if (rows.isEmpty) return null;
      final value = rows.first['value'];
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value);
      return null;
    } catch (_) {
      return null;
    }
  }

  _PostgresStatement _prepareStatement(String sql, List<Object?> parameters) {
    if (parameters.isEmpty) {
      return _PostgresStatement(
        query: sql,
        previewSql: sql,
        parameters: const [],
      );
    }
    final normalized = _normalizeParameters(parameters);
    final previewSql = _formatPreviewSql(sql, normalized.length);
    final query = Sql.indexed(sql, substitution: '?');
    return _PostgresStatement(
      query: query,
      previewSql: previewSql,
      parameters: normalized,
    );
  }

  String _formatPreviewSql(String sql, int parameterCount) {
    final buffer = StringBuffer();
    var index = 0;
    for (var i = 0; i < sql.length; i++) {
      final char = sql[i];
      if (char == '?') {
        index++;
        buffer
          ..write('\$')
          ..write(index.toString());
      } else {
        buffer.write(char);
      }
    }
    if (index != parameterCount) {
      throw StateError(
        'Expected $parameterCount placeholders but found $index.',
      );
    }
    return buffer.toString();
  }

  String _tableIdentifier(ModelDefinition<OrmEntity> definition) {
    final table = _quote(definition.tableName);
    final schema = definition.schema;
    if (schema == null || schema.isEmpty) {
      return table;
    }
    return '${_quote(schema)}.$table';
  }

  String _quote(String identifier) {
    final escaped = identifier.replaceAll('"', '""');
    return '"$escaped"';
  }

  String _whereClause(Map<String, Object?> keys) {
    if (keys.isEmpty) {
      throw StateError('Mutation requires keys for WHERE clause.');
    }
    return keys.keys.map((c) => '${_quote(c)} = ?').join(' AND ');
  }

  Future<Set<String>> _primaryKeyColumns(String table, {String? schema}) async {
    final filter = schema == null ? '' : ' AND tc.table_schema = ?';
    final rows = await queryRaw(
      'SELECT kcu.column_name '
      'FROM information_schema.table_constraints tc '
      'JOIN information_schema.key_column_usage kcu '
      '  ON kcu.constraint_name = tc.constraint_name '
      ' AND kcu.constraint_schema = tc.constraint_schema '
      'WHERE tc.constraint_type = \'PRIMARY KEY\' '
      '  AND tc.table_name = ?'
      '$filter '
      'ORDER BY kcu.ordinal_position',
      schema == null ? [table] : [table, schema],
    );
    return rows.map((row) => row['column_name'] as String).toSet();
  }

  bool _isAutoIncrement(Map<String, Object?> row) {
    final identity = row['is_identity'] as String?;
    if (identity != null && identity.toUpperCase() == 'YES') {
      return true;
    }
    final defaultValue = row['column_default'] as String?;
    return defaultValue != null && defaultValue.startsWith('nextval(');
  }

  List<String> _normalizeTextArray(Object? value) {
    if (value is List) {
      return value.whereType<String>().toList(growable: false);
    }
    return const [];
  }
}

class _PostgresMutationShape {
  const _PostgresMutationShape({
    required this.sql,
    required this.parameterSets,
    this.returnsRows = false,
  });

  final String sql;
  final List<List<Object?>> parameterSets;
  final bool returnsRows;

  static _PostgresMutationShape empty() =>
      const _PostgresMutationShape(sql: '<no-op>', parameterSets: []);
}

String _assignmentRhs(String sql) {
  final index = sql.indexOf('=');
  if (index == -1) {
    return sql;
  }
  return sql.substring(index + 1).trim();
}

class _JsonUpdateTemplate {
  const _JsonUpdateTemplate({
    required this.column,
    required this.path,
    required this.sql,
    required this.resolvedColumn,
    required this.patch,
  });

  final String column;
  final String path;
  final String sql;
  final String resolvedColumn;
  final bool patch;
}

class _PostgresStatement {
  const _PostgresStatement({
    required this.query,
    required this.previewSql,
    required this.parameters,
  });

  final Object query;
  final String previewSql;
  final List<Object?> parameters;
}

List<Object?> _normalizeParameters(List<Object?> values) =>
    values.map(_normalizeValue).toList(growable: false);

Object? _normalizeValue(Object? value) {
  if (value == null) return null;
  if (value is TypedValue) return value;
  if (value is DateTime) {
    return TypedValue<DateTime>(Type.timestampTz, value.toUtc());
  }
  if (value is Duration) {
    return TypedValue<Interval>(Type.interval, Interval.duration(value));
  }
  if (value is BigInt) return value.toInt();
  if (value is Iterable) {
    return value.map(_normalizeValue).toList(growable: false);
  }
  return value;
}
