/// SQLite implementation of the routed ORM driver adapter.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:ormed/ormed.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

import 'schema_state.dart';
import 'sqlite_codecs.dart';
import 'sqlite_connector.dart';
import 'sqlite_grammar.dart';
import 'sqlite_schema_dialect.dart';
import 'sqlite_type_mapper.dart';

/// Adapter that executes [QueryPlan] objects against SQLite databases.
class SqliteDriverAdapter
    implements
        DriverAdapter,
        SchemaDriver,
        SchemaStateProvider,
        DriverExtensionHost {
  /// Registers SQLite-specific codecs and type mapper with the global registries.
  /// Call this once during application initialization before using SQLite.
  static void registerCodecs() {
    final mapper = SqliteTypeMapper();
    TypeMapperRegistry.register('sqlite', mapper);

    // Register codecs from TypeMapper to eliminate duplication
    final codecs = <String, ValueCodec<dynamic>>{};
    for (final mapping in mapper.typeMappings) {
      if (mapping.codec != null) {
        final typeKey = mapping.dartType.toString();
        codecs[typeKey] = mapping.codec!;
        codecs['$typeKey?'] = mapping.codec!; // Nullable variant

        // Register common generic variants for Map type
        if (mapping.dartType == Map) {
          codecs['Map<String, Object?>'] = mapping.codec!;
          codecs['Map<String, Object?>?'] = mapping.codec!;
          codecs['Map<String, dynamic>'] = mapping.codec!;
          codecs['Map<String, dynamic>?'] = mapping.codec!;
        }
      }
    }
    ValueCodecRegistry.instance.registerDriver('sqlite', codecs);
  }

  /// Opens an in-memory database connection using the shared connector.
  SqliteDriverAdapter.inMemory({List<DriverExtension> extensions = const []})
    : this.custom(
        config: const DatabaseConfig(
          driver: 'sqlite',
          options: {'memory': true},
        ),
        extensions: extensions,
      );

  /// Opens a database stored at [path].
  SqliteDriverAdapter.file(
    String path, {
    List<DriverExtension> extensions = const [],
  }) : this.custom(
         config: DatabaseConfig(
           driver: 'sqlite',
           options: {'path': path},
           name: path,
         ),
         extensions: extensions,
       );

  /// Creates an adapter for the provided [config] and [connections].
  SqliteDriverAdapter.custom({
    required DatabaseConfig config,
    ConnectionFactory? connections,
    List<DriverExtension> extensions = const [],
  }) : _metadata = const DriverMetadata(
         name: 'sqlite',
         supportsReturning: true,
         supportsQueryDeletes: true,
         requiresPrimaryKeyForQueryUpdate: false,
         queryUpdateRowIdentifier: QueryRowIdentifier(
           column: 'rowid',
           expression: 'rowid',
         ),
         identifierQuote: '"',
         capabilities: {
           DriverCapability.joins,
           DriverCapability.insertUsing,
           DriverCapability.queryDeletes,
           DriverCapability.schemaIntrospection,
           DriverCapability.threadCount,
           DriverCapability.transactions,
           DriverCapability.adHocQueryUpdates,
           DriverCapability.rawSQL,
           DriverCapability.increment,
           DriverCapability.returning,
           DriverCapability.relationAggregates,
           DriverCapability.caseInsensitiveLike,
           DriverCapability.databaseManagement,
           DriverCapability.foreignKeyConstraintControl,
         },
       ),
       _schemaCompiler = SchemaPlanCompiler(SqliteSchemaDialect()),
       _extensions = DriverExtensionRegistry(
         driverName: 'sqlite',
         extensions: extensions,
       ),
       _connections =
           connections ??
           ConnectionFactory(connectors: {'sqlite': () => SqliteConnector()}),
       _config = config,
       _codecs = ValueCodecRegistry.instance.forDriver('sqlite') {
    // Auto-register SQLite codecs on first instantiation
    registerSqliteCodecs();

    _grammar = SqliteQueryGrammar(
      supportsWindowFunctions: sqlite.sqlite3.version.versionNumber >= 3025000,
      extensions: _extensions,
    );

    _planCompiler = ClosurePlanCompiler(
      compileSelect: _compileSelectPreview,
      compileMutation: _compileMutationPreview,
    );
  }

  final DriverMetadata _metadata;
  final ValueCodecRegistry _codecs;
  final SchemaPlanCompiler _schemaCompiler;
  final DriverExtensionRegistry _extensions;
  late final SqliteQueryGrammar _grammar;
  final ConnectionFactory _connections;
  final DatabaseConfig _config;
  late final PlanCompiler _planCompiler;
  ConnectionHandle<sqlite.Database>? _primaryHandle;
  final Random _random = Random();
  bool _closed = false;
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
    final database = await _database();
    final stmt = _prepareStatement(database, sql);
    try {
      stmt.execute(normalizeSqliteParameters(parameters));
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<List<Map<String, Object?>>> queryRaw(
    String sql, [
    List<Object?> parameters = const [],
  ]) async {
    final database = await _database();
    final stmt = _prepareStatement(database, sql);
    try {
      final result = stmt.select(normalizeSqliteParameters(parameters));
      final columnNames = result.columnNames;
      final rows = <Map<String, Object?>>[];
      for (final row in result) {
        rows.add(rowToMap(row, columnNames));
      }
      return rows;
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<List<Map<String, Object?>>> execute(QueryPlan plan) async {
    final database = await _database();
    final compilation = _grammar.compileSelect(plan);
    final stmt = _prepareStatement(database, compilation.sql);
    try {
      final result = stmt.select(
        normalizeSqliteParameters(compilation.bindings),
      );
      final columnNames = result.columnNames;
      final rows = <Map<String, Object?>>[];
      for (final row in result) {
        rows.add(rowToMap(row, columnNames));
      }
      final decodedRows = rows
          .map((row) => _decodeRowValues(plan.definition, row))
          .toList(growable: false);
      if (plan.randomOrder) {
        _shuffleRows(decodedRows, plan.randomSeed);
      }
      return decodedRows;
    } finally {
      stmt.dispose();
    }
  }

  @override
  Stream<Map<String, Object?>> stream(QueryPlan plan) async* {
    final database = await _database();
    final compilation = _grammar.compileSelect(plan);
    final stmt = _prepareStatement(database, compilation.sql);
    try {
      final result = stmt.select(
        normalizeSqliteParameters(compilation.bindings),
      );
      final columnNames = result.columnNames;
      final rows = <Map<String, Object?>>[];
      for (final row in result) {
        rows.add(rowToMap(row, columnNames));
      }
      final decodedRows = rows
          .map((row) => _decodeRowValues(plan.definition, row))
          .toList(growable: false);
      if (plan.randomOrder) {
        _shuffleRows(decodedRows, plan.randomSeed);
      }
      for (final row in decodedRows) {
        yield row;
      }
    } finally {
      stmt.dispose();
    }
  }

  @override
  StatementPreview describeQuery(QueryPlan plan) =>
      _planCompiler.compileSelect(plan);

  @override
  Future<MutationResult> runMutation(MutationPlan plan) async {
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

  StatementPreview _compileSelectPreview(QueryPlan plan) {
    final compilation = _grammar.compileSelect(plan);
    final normalized = normalizeSqliteParameters(compilation.bindings);
    final resolved = _grammar.substituteBindingsIntoRawSql(
      compilation.sql,
      _encodePreviewParameters(normalized),
    );
    return StatementPreview(
      payload: SqlStatementPayload(
        sql: compilation.sql,
        parameters: normalized,
      ),
      resolvedText: resolved,
    );
  }

  StatementPreview _compileMutationPreview(MutationPlan plan) {
    final shape = _shapeForPlan(plan);
    final batches = shape.parameterSets
        .map(normalizeSqliteParameters)
        .toList(growable: false);
    final first = batches.isEmpty ? const <Object?>[] : batches.first;
    final resolved = _grammar.substituteBindingsIntoRawSql(
      shape.sql,
      _encodePreviewParameters(first),
    );
    return StatementPreview(
      payload: SqlStatementPayload(sql: shape.sql, parameters: first),
      parameterSets: batches,
      resolvedText: resolved,
    );
  }

  List<Object?> _encodePreviewParameters(List<Object?> parameters) =>
      parameters.map(_codecs.encodeValue).toList(growable: false);

  @override
  Future<R> transaction<R>(Future<R> Function() action) async {
    final database = await _database();
    if (_transactionDepth == 0) {
      _transactionDepth++;
      database.execute('BEGIN');
      try {
        final result = await action();
        database.execute('COMMIT');
        return result;
      } catch (_) {
        database.execute('ROLLBACK');
        rethrow;
      } finally {
        _transactionDepth--;
      }
    } else {
      // SQLite supports savepoints for nested transactions
      final savepoint = 'sp_${_transactionDepth + 1}';
      _transactionDepth++;
      database.execute('SAVEPOINT $savepoint');
      try {
        final result = await action();
        database.execute('RELEASE SAVEPOINT $savepoint');
        return result;
      } catch (_) {
        database.execute('ROLLBACK TO SAVEPOINT $savepoint');
        rethrow;
      } finally {
        _transactionDepth--;
      }
    }
  }

  @override
  Future<void> beginTransaction() async {
    final database = await _database();
    if (_transactionDepth == 0) {
      database.execute('BEGIN');
      _transactionDepth++;
    } else {
      // Use savepoint for nested transactions
      final savepoint = 'sp_${_transactionDepth + 1}';
      database.execute('SAVEPOINT $savepoint');
      _transactionDepth++;
    }
  }

  @override
  Future<void> commitTransaction() async {
    if (_transactionDepth == 0) {
      throw StateError('No active transaction to commit');
    }

    final database = await _database();
    if (_transactionDepth == 1) {
      database.execute('COMMIT');
      _transactionDepth--;
    } else {
      // Release savepoint for nested transactions
      final savepoint = 'sp_$_transactionDepth';
      database.execute('RELEASE SAVEPOINT $savepoint');
      _transactionDepth--;
    }
  }

  @override
  Future<void> rollbackTransaction() async {
    if (_transactionDepth == 0) {
      throw StateError('No active transaction to rollback');
    }

    final database = await _database();
    if (_transactionDepth == 1) {
      database.execute('ROLLBACK');
      _transactionDepth--;
    } else {
      // Rollback to savepoint for nested transactions
      final savepoint = 'sp_$_transactionDepth';
      database.execute('ROLLBACK TO SAVEPOINT $savepoint');
      _transactionDepth--;
    }
  }

  @override
  Future<void> truncateTable(String tableName) async {
    final database = await _database();
    // SQLite doesn't have TRUNCATE, use DELETE and reset sequence
    database.execute('DELETE FROM $tableName');
    // Reset auto-increment counter
    database.execute("DELETE FROM sqlite_sequence WHERE name = ?", [tableName]);
  }

  @override
  Future<void> applySchemaPlan(SchemaPlan plan) async {
    final preview = describeSchemaPlan(plan);

    for (final statement in preview.statements) {
      await executeRaw(statement.sql, statement.parameters);
    }
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
    final path = _config.options['path'] ?? _config.options['database'];
    if (path is! String || path.isEmpty) {
      return null;
    }
    return SqliteSchemaState(database: path, ledgerTable: ledgerTable);
  }

  @override
  Future<int?> threadCount() async {
    return 1;
  }

  @override
  Future<List<SchemaNamespace>> listSchemas() async {
    final sql = _schemaCompiler.dialect.compileSchemas();
    if (sql == null) {
      throw UnsupportedError('SQLite should support schema listing');
    }

    final result = await queryRaw(sql);
    return result
        .map((row) {
          final name = row['name'] as String;
          final owner = (row['file'] ?? row['path']) as String?;
          final defaultFlag = row['default'];
          final isDefault = switch (defaultFlag) {
            num value => value != 0,
            bool value => value,
            _ => name.toLowerCase() == 'main',
          };
          return SchemaNamespace(
            name: name,
            owner: owner,
            isDefault: isDefault,
          );
        })
        .toList(growable: false);
  }

  @override
  Future<List<SchemaTable>> listTables({String? schema}) async {
    final schemas = schema != null
        ? <String>[schema]
        : (await listSchemas()).map((s) => s.name).toList(growable: false);
    final tables = <SchemaTable>[];
    for (final namespace in schemas) {
      final sql = _schemaCompiler.dialect.compileTables(schema: namespace);
      if (sql == null) {
        throw UnsupportedError('SQLite should support table listing');
      }

      final rows = await queryRaw(sql);
      for (final row in rows) {
        final tableName = row['name'] as String;
        final resolvedSchema = row['schema'] as String? ?? namespace;
        tables.add(
          SchemaTable(
            name: tableName,
            schema: _exposedSchema(_schemaOrDefault(resolvedSchema)),
            type: row['type'] as String?,
            comment: null,
            engine: null,
          ),
        );
      }
    }
    return tables;
  }

  @override
  Future<List<SchemaView>> listViews({String? schema}) async {
    final schemas = schema != null
        ? <String>[schema]
        : (await listSchemas()).map((s) => s.name).toList(growable: false);
    final views = <SchemaView>[];
    for (final namespace in schemas) {
      final sql = _schemaCompiler.dialect.compileViews(schema: namespace);
      if (sql == null) {
        throw UnsupportedError('SQLite should support view listing');
      }

      final rows = await queryRaw(sql);
      for (final row in rows) {
        final resolvedSchema = row['schema'] as String? ?? namespace;
        views.add(
          SchemaView(
            name: row['name'] as String,
            schema: _exposedSchema(_schemaOrDefault(resolvedSchema)),
            definition: (row['definition'] as String?) ?? row['sql'] as String?,
          ),
        );
      }
    }
    return views;
  }

  @override
  Future<List<SchemaColumn>> listColumns(String table, {String? schema}) async {
    final sql = _schemaCompiler.dialect.compileColumns(table, schema: schema);
    if (sql == null) {
      throw UnsupportedError('SQLite should support column listing');
    }

    final rows = (await queryRaw(
      sql,
    )).where((row) => (row['cid'] as int? ?? 0) >= 0);
    return rows
        .map((row) {
          final nullableFlag = row['nullable'];
          final nullable = switch (nullableFlag) {
            num value => value != 0,
            bool value => value,
            _ => (row['notnull'] as int? ?? 0) == 0,
          };
          final defaultValue = row.containsKey('default')
              ? row['default']
              : row['dflt_value'];
          final primaryFlag = row['primary'];
          final primary = switch (primaryFlag) {
            num value => value != 0,
            bool value => value,
            _ => (row['pk'] as int? ?? 0) > 0,
          };
          return SchemaColumn(
            name: row['name'] as String,
            dataType: (row['type'] as String?) ?? 'TEXT',
            schema: _exposedSchema(_schemaOrDefault(schema)),
            tableName: table,
            length: null,
            numericPrecision: null,
            numericScale: null,
            nullable: nullable,
            defaultValue: _normalizeDefault(defaultValue),
            autoIncrement: false,
            primaryKey: primary,
            comment: null,
            generatedExpression: null,
          );
        })
        .toList(growable: false);
  }

  @override
  Future<List<SchemaIndex>> listIndexes(String table, {String? schema}) async {
    final database = await _database();
    final sql = _schemaCompiler.dialect.compileIndexes(table, schema: schema);
    if (sql == null) {
      throw UnsupportedError('SQLite should support index listing');
    }

    final rows = await queryRaw(sql);
    final indexes = <SchemaIndex>[];
    for (final row in rows) {
      final name = row['name'] as String;
      if (name.startsWith('sqlite_')) {
        continue;
      }
      final columns = _splitColumns(row['columns']).isNotEmpty
          ? _splitColumns(row['columns'])
          : _indexColumns(database, name, schema: schema);
      final partialFlag = row['partial'];
      final partial = switch (partialFlag) {
        num value => value != 0,
        bool value => value,
        _ => false,
      };
      final whereClause = partial
          ? _indexWhereClause(database, name, schema: schema)
          : null;
      final uniqueFlag = row['unique'];
      final unique = switch (uniqueFlag) {
        num value => value != 0,
        bool value => value,
        _ => false,
      };
      final primaryFlag = row['primary'];
      final primary = switch (primaryFlag) {
        num value => value != 0,
        bool value => value,
        _ => false,
      };
      indexes.add(
        SchemaIndex(
          name: name,
          columns: columns,
          schema: _exposedSchema(_schemaOrDefault(schema)),
          tableName: table,
          unique: unique,
          primary: primary,
          method: null,
          whereClause: whereClause,
        ),
      );
    }
    return indexes;
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
      throw UnsupportedError('SQLite should support foreign key listing');
    }

    final rows = await queryRaw(sql);
    var counter = 0;
    return rows
        .map((row) {
          counter += 1;
          final columns = _splitColumns(row['columns']);
          final foreignColumns = _splitColumns(row['foreign_columns']);
          final foreignSchema = row['foreign_schema'] as String?;
          return SchemaForeignKey(
            name: 'fk_${table}_$counter',
            columns: columns,
            tableName: table,
            referencedTable: row['foreign_table'] as String,
            referencedColumns: foreignColumns,
            schema: _exposedSchema(_schemaOrDefault(schema)),
            referencedSchema: _exposedSchema(foreignSchema),
            onUpdate: row['on_update'] as String?,
            onDelete: row['on_delete'] as String?,
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
    // SQLite databases are files
    final file = File(name);

    if (await file.exists()) {
      return false; // Already exists
    }

    // Create parent directory if needed
    final parentDir = file.parent;
    if (!await parentDir.exists()) {
      await parentDir.create(recursive: true);
    }

    // Create empty database file by opening connection
    // sqlite3.dart will create the file automatically
    final tempDb = sqlite.sqlite3.open(name);
    tempDb.close();

    return true;
  }

  @override
  Future<bool> dropDatabase(String name) async {
    final file = File(name);

    if (!await file.exists()) {
      throw StateError('Database file does not exist: $name');
    }

    await file.delete();
    return true;
  }

  @override
  Future<bool> dropDatabaseIfExists(String name) async {
    final file = File(name);

    if (!await file.exists()) {
      return false;
    }

    await file.delete();
    return true;
  }

  @override
  Future<List<String>> listDatabases() async {
    // SQLite doesn't have a catalog concept
    // Could list *.db files in a directory, but that's application-specific
    throw UnsupportedError('SQLite does not support listing databases');
  }

  // ========== Schema (Namespace) Management ==========

  // SQLite doesn't have schemas like PostgreSQL. For test isolation:
  // - In-memory databases: Each adapter instance IS its own isolated database
  // - File-based databases: Each file IS its own isolated database
  //
  // These methods provide compatibility with the SchemaDriver interface
  // so that TestDatabaseManager can use the same API for all databases.

  /// Tracks the "virtual" schema name for this adapter (for API compatibility)
  String _currentSchema = 'main';

  @override
  Future<bool> createSchema(String name) async {
    // SQLite doesn't support multiple schemas within a database.
    // For in-memory databases, each adapter is already isolated.
    // For file-based databases, each file is already isolated.
    //
    // We return true to indicate the "schema" is ready (the database itself).
    // The caller should have created a new adapter for true isolation.
    _currentSchema = name;
    return true;
  }

  @override
  Future<bool> dropSchemaIfExists(String name) async {
    // For SQLite, "dropping a schema" means:
    // - In-memory: Just close the connection (handled by dispose)
    // - File-based: Delete the file (use dropDatabaseIfExists instead)
    //
    // Since the TestDatabaseManager creates new adapters per test group,
    // we return false here to let it fall back to dropDatabaseIfExists
    // which handles file deletion.
    if (_currentSchema == name) {
      _currentSchema = 'main';
    }
    return false;
  }

  @override
  Future<void> setCurrentSchema(String name) async {
    // SQLite only has 'main' schema internally, but we track the name
    // for API compatibility with multi-schema databases.
    _currentSchema = name;
  }

  @override
  Future<String> getCurrentSchema() async {
    return _currentSchema;
  }

  // ========== Foreign Key Constraint Management ==========

  @override
  Future<bool> enableForeignKeyConstraints() async {
    final sql = _schemaCompiler.dialect.compileEnableForeignKeyConstraints();
    if (sql == null) {
      throw UnsupportedError('SQLite should support FK constraint management');
    }
    await executeRaw(sql);
    return true;
  }

  @override
  Future<bool> disableForeignKeyConstraints() async {
    final sql = _schemaCompiler.dialect.compileDisableForeignKeyConstraints();
    if (sql == null) {
      throw UnsupportedError('SQLite should support FK constraint management');
    }
    await executeRaw(sql);
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
    final tables = await listTables();

    if (tables.isEmpty) return;

    await disableForeignKeyConstraints();

    try {
      for (final table in tables) {
        await executeRaw('DROP TABLE IF EXISTS ${_quote(table.name)}');
      }
    } finally {
      await enableForeignKeyConstraints();
    }
  }

  // ========== Existence Checking ==========

  @override
  Future<bool> hasTable(String table, {String? schema}) async {
    final tables = await listTables(schema: schema);
    return tables.any((t) => t.name.toLowerCase() == table.toLowerCase());
  }

  @override
  Future<bool> hasView(String view, {String? schema}) async {
    final views = await listViews(schema: schema);
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

  Future<sqlite.Database> _database() async {
    if (_closed) {
      throw StateError('SqliteDriverAdapter has already been closed.');
    }
    if (_primaryHandle == null) {
      final handle =
          await _connections.open(_config) as ConnectionHandle<sqlite.Database>;
      _primaryHandle = handle;
    }
    return _primaryHandle!.client;
  }

  dynamic _prepareStatement(sqlite.Database database, String sql) {
    return database.prepare(sql);
  }

  Future<MutationResult> _runInsert(MutationPlan plan) async {
    final shape = _buildInsertShape(plan);
    if (shape.parameterSets.isEmpty) {
      return const MutationResult(affectedRows: 0);
    }
    final database = await _database();
    final stmt = _prepareStatement(database, shape.sql);
    try {
      var affected = 0;
      final insertedRows = <Map<String, dynamic>>[];

      for (int i = 0; i < shape.parameterSets.length; i++) {
        final parameters = shape.parameterSets[i];
        stmt.execute(normalizeSqliteParameters(parameters));
        affected += database.updatedRows;

        // If returning is requested and insert succeeded, return a row with the PK value
        // SQLite doesn't support RETURNING for non-auto-increment PKs, so we simulate it
        if (plan.returning && database.updatedRows > 0) {
          final pkField = plan.definition.primaryKeyField;
          if (pkField != null) {
            // For auto-increment integer PKs, use lastInsertRowId
            // For non-integer PKs (like String), use the value from the plan
            final isIntegerPk =
                pkField.dartType == 'int' || pkField.dartType == 'int?';
            final isAutoIncrement = pkField.autoIncrement;
            if (isIntegerPk && isAutoIncrement) {
              final lastId = database.lastInsertRowId;
              // Return a minimal row with just the primary key
              // The repository will merge this with the original model data
              insertedRows.add({pkField.columnName: lastId});
            } else {
              // Non-integer or non-autoincrement PK: use the value from the plan
              insertedRows.add(plan.rows[i].values);
            }
          } else {
            // No PK field, return the original data from the plan
            insertedRows.add(plan.rows[i].values);
          }
        }
      }

      return MutationResult(
        affectedRows: affected,
        returnedRows: plan.returning ? insertedRows : null,
      );
    } finally {
      stmt.dispose();
    }
  }

  Future<MutationResult> _runInsertUsing(MutationPlan plan) async {
    final shape = _buildInsertUsingShape(plan);
    if (shape.parameterSets.isEmpty) {
      return const MutationResult(affectedRows: 0);
    }
    final database = await _database();
    final stmt = _prepareStatement(database, shape.sql);
    try {
      var affected = 0;
      for (final parameters in shape.parameterSets) {
        stmt.execute(normalizeSqliteParameters(parameters));
        affected += database.updatedRows;
      }
      return MutationResult(affectedRows: affected);
    } finally {
      stmt.dispose();
    }
  }

  Future<MutationResult> _runUpdate(MutationPlan plan) async {
    final shape = _buildUpdateShape(plan);
    if (shape.parameterSets.isEmpty) {
      return const MutationResult(affectedRows: 0);
    }
    final database = await _database();
    final stmt = _prepareStatement(database, shape.sql);
    try {
      var affected = 0;
      final returnedRows = <Map<String, dynamic>>[];

      for (final parameters in shape.parameterSets) {
        if (plan.returning) {
          // When RETURNING is requested, use select to get the returned rows
          final resultSet = stmt.select(normalizeSqliteParameters(parameters));
          for (final row in resultSet) {
            returnedRows.add(Map<String, dynamic>.from(row));
          }
          affected += database.updatedRows;
        } else {
          stmt.execute(normalizeSqliteParameters(parameters));
          affected += database.updatedRows;
        }
      }

      return MutationResult(
        affectedRows: affected,
        returnedRows: plan.returning ? returnedRows : null,
      );
    } finally {
      stmt.dispose();
    }
  }

  Future<MutationResult> _runDelete(MutationPlan plan) async {
    final shape = _buildDeleteShape(plan);
    if (shape.parameterSets.isEmpty) {
      return const MutationResult(affectedRows: 0);
    }
    final database = await _database();
    final stmt = _prepareStatement(database, shape.sql);
    try {
      var affected = 0;
      final returnedRows = <Map<String, Object?>>[];
      for (final parameters in shape.parameterSets) {
        final normalized = normalizeSqliteParameters(parameters);
        if (plan.returning) {
          final resultSet = stmt.select(normalized);
          for (final row in resultSet) {
            returnedRows.add(Map<String, Object?>.from(row));
          }
          affected += database.updatedRows;
        } else {
          stmt.execute(normalized);
          affected += database.updatedRows;
        }
      }
      return MutationResult(
        affectedRows: affected,
        returnedRows: plan.returning ? returnedRows : null,
      );
    } finally {
      stmt.dispose();
    }
  }

  Future<MutationResult> _runUpsert(MutationPlan plan) async {
    if (plan.rows.isEmpty) {
      return const MutationResult(affectedRows: 0);
    }
    if (_usesPrimaryKeyUpsert(plan)) {
      final shape = _buildUpsertShape(plan);
      if (plan.returning) {
        return _executeShapeWithReturning(shape, plan);
      }
      return _executeShape(shape);
    }
    return _runManualUpsert(plan);
  }

  bool _usesPrimaryKeyUpsert(MutationPlan plan) {
    final pk = plan.definition.primaryKeyField?.columnName;
    final uniqueColumns = _resolveUpsertUniqueColumns(plan);
    return pk != null && uniqueColumns.length == 1 && uniqueColumns.first == pk;
  }

  Future<MutationResult> _executeShape(_SqliteMutationShape shape) async {
    if (shape.parameterSets.isEmpty) {
      return const MutationResult(affectedRows: 0);
    }
    final database = await _database();
    final stmt = _prepareStatement(database, shape.sql);
    try {
      var affected = 0;
      for (final parameters in shape.parameterSets) {
        stmt.execute(normalizeSqliteParameters(parameters));
        affected += database.updatedRows;
      }
      return MutationResult(affectedRows: affected);
    } finally {
      stmt.dispose();
    }
  }

  Future<MutationResult> _executeShapeWithReturning(
    _SqliteMutationShape shape,
    MutationPlan plan,
  ) async {
    if (shape.parameterSets.isEmpty) {
      return const MutationResult(affectedRows: 0);
    }
    final database = await _database();
    final stmt = _prepareStatement(database, shape.sql);
    try {
      var affected = 0;
      final returnedRows = <Map<String, Object?>>[];
      final columnNames = plan.definition.fields
          .map((f) => f.columnName)
          .toList(growable: false);
      for (final parameters in shape.parameterSets) {
        final result = stmt.select(normalizeSqliteParameters(parameters));
        affected += database.updatedRows;
        if (result.isNotEmpty) {
          final rawRow = rowToMap(result.first, columnNames);
          returnedRows.add(rawRow);
        }
      }
      return MutationResult(affectedRows: affected, returnedRows: returnedRows);
    } finally {
      stmt.dispose();
    }
  }

  void _shuffleRows(List<Map<String, Object?>> rows, num? seed) {
    final random = seed != null ? Random(seed.toInt()) : _random;
    rows.shuffle(random);
  }

  Future<MutationResult> _runManualUpsert(MutationPlan plan) async {
    final database = await _database();
    final table = _tableIdentifier(plan.definition);
    final firstRow = plan.rows.first;
    final columns = firstRow.values.keys.toList();
    final columnSql = columns.map(_quote).join(', ');
    final placeholders = List.filled(columns.length, '?').join(', ');
    final insertSql = 'INSERT INTO $table ($columnSql) VALUES ($placeholders)';
    final insertStmt = _prepareStatement(database, insertSql);

    final uniqueColumns = _resolveUpsertUniqueColumns(plan);
    final updateColumns = _resolveUpsertUpdateColumns(
      plan,
      columns,
      uniqueColumns,
    );
    final whereClause = uniqueColumns
        .map((c) => '${_quote(c)} = ?')
        .join(' AND ');
    final selectSql = 'SELECT 1 FROM $table WHERE $whereClause LIMIT 1';
    final selectStmt = _prepareStatement(database, selectSql);

    dynamic updateStmt;
    if (updateColumns.isNotEmpty) {
      final updateClause = updateColumns
          .map((c) => '${_quote(c)} = ?')
          .join(', ');
      final updateSql = 'UPDATE $table SET $updateClause WHERE $whereClause';
      updateStmt = _prepareStatement(database, updateSql);
    }

    // Prepare a select statement to fetch the upserted row when RETURNING is requested
    dynamic fetchStmt;
    List<String>? allColumnNames;
    if (plan.returning) {
      allColumnNames = plan.definition.fields
          .map((f) => f.columnName)
          .toList(growable: false);
      final allColumnsSql = allColumnNames.map(_quote).join(', ');
      final fetchSql =
          'SELECT $allColumnsSql FROM $table WHERE $whereClause LIMIT 1';
      fetchStmt = _prepareStatement(database, fetchSql);
    }

    var affected = 0;
    final returnedRows = <Map<String, Object?>>[];

    for (final row in plan.rows) {
      final insertValues = columns.map((c) => row.values[c]).toList();
      final uniqueValues = uniqueColumns.map((c) => row.values[c]).toList();
      final normalizedInsert = normalizeSqliteParameters(insertValues);
      final normalizedUnique = normalizeSqliteParameters(uniqueValues);

      var updated = false;
      if (updateStmt != null) {
        final updateValues = [
          ...updateColumns.map((c) => row.values[c]),
          ...uniqueValues,
        ];
        updateStmt.execute(normalizeSqliteParameters(updateValues));
        final updatedRows = database.updatedRows;
        if (updatedRows > 0) {
          affected += updatedRows;
          updated = true;
        }
      } else {
        final rows = selectStmt.select(normalizedUnique);
        if (rows.isNotEmpty) {
          continue;
        }
      }

      if (updated) {
        // Row was updated, fetch it if RETURNING is requested
        if (fetchStmt != null && allColumnNames != null) {
          final result = fetchStmt.select(normalizedUnique);
          if (result.isNotEmpty) {
            returnedRows.add(rowToMap(result.first, allColumnNames));
          }
        }
        continue;
      }

      insertStmt.execute(normalizedInsert);
      affected += database.updatedRows;

      // Row was inserted, fetch it if RETURNING is requested
      if (fetchStmt != null && allColumnNames != null) {
        final result = fetchStmt.select(normalizedUnique);
        if (result.isNotEmpty) {
          returnedRows.add(rowToMap(result.first, allColumnNames));
        }
      }
    }

    insertStmt.dispose();
    selectStmt.dispose();
    updateStmt?.dispose();
    fetchStmt?.dispose();

    return MutationResult(
      affectedRows: affected,
      returnedRows: plan.returning ? returnedRows : null,
    );
  }

  Future<MutationResult> _runQueryUpdate(MutationPlan plan) async {
    final shape = _buildQueryUpdateShape(plan);
    if (shape.parameterSets.isEmpty) {
      return const MutationResult(affectedRows: 0);
    }
    final database = await _database();
    final stmt = _prepareStatement(database, shape.sql);
    try {
      var affected = 0;
      final returnedRows = <Map<String, Object?>>[];
      for (final parameters in shape.parameterSets) {
        final normalized = normalizeSqliteParameters(parameters);
        if (plan.returning) {
          final resultSet = stmt.select(normalized);
          for (final row in resultSet) {
            returnedRows.add(Map<String, Object?>.from(row));
          }
          affected += database.updatedRows;
        } else {
          stmt.execute(normalized);
          affected += database.updatedRows;
        }
      }
      return MutationResult(
        affectedRows: affected,
        returnedRows: plan.returning ? returnedRows : null,
      );
    } finally {
      stmt.dispose();
    }
  }

  _SqliteMutationShape _shapeForPlan(MutationPlan plan) {
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
    if (shape.parameterSets.isEmpty) {
      return const MutationResult(affectedRows: 0);
    }
    final database = await _database();
    final stmt = _prepareStatement(database, shape.sql);
    try {
      var affected = 0;
      final returnedRows = <Map<String, Object?>>[];
      for (final parameters in shape.parameterSets) {
        final normalized = normalizeSqliteParameters(parameters);
        if (plan.returning) {
          final resultSet = stmt.select(normalized);
          for (final row in resultSet) {
            returnedRows.add(Map<String, Object?>.from(row));
          }
          affected += database.updatedRows;
        } else {
          stmt.execute(normalized);
          affected += database.updatedRows;
        }
      }
      return MutationResult(
        affectedRows: affected,
        returnedRows: plan.returning ? returnedRows : null,
      );
    } finally {
      stmt.dispose();
    }
  }

  _SqliteMutationShape _buildInsertShape(MutationPlan plan) {
    if (plan.rows.isEmpty) {
      return _emptyShape;
    }
    // Only insert columns present in the input rows.
    // Auto-increment fields are included only when explicitly set to a non-zero value.
    final columnsToInsert = plan.definition.fields
        .where((field) {
          var provided = false;
          var hasNonZeroAuto = false;
          for (final row in plan.rows) {
            if (!row.values.containsKey(field.columnName)) {
              continue;
            }
            provided = true;
            if (field.autoIncrement) {
              final value = row.values[field.columnName];
              if (value != null && value != 0) {
                hasNonZeroAuto = true;
                break;
              }
            }
          }

          if (!provided) return false;
          if (!field.autoIncrement) return true;
          return hasNonZeroAuto;
        })
        .map((field) => field.columnName)
        .toList();

    final columnSql = columnsToInsert.map(_quote).join(', ');
    final placeholders = List.filled(columnsToInsert.length, '?').join(', ');
    final verb = plan.ignoreConflicts ? 'INSERT OR IGNORE' : 'INSERT';
    final sql =
        '$verb INTO ${_tableIdentifier(plan.definition)} ($columnSql) VALUES ($placeholders)';
    final parameters = plan.rows
        .map(
          (row) => columnsToInsert
              .map(
                (column) => _encodeValueForColumn(
                  definition: plan.definition,
                  column: column,
                  value: row.values[column],
                ),
              )
              .toList(growable: false),
        )
        .toList(growable: false);
    return _SqliteMutationShape(sql: sql, parameterSets: parameters);
  }

  _SqliteMutationShape _buildInsertUsingShape(MutationPlan plan) {
    final queryPlan = plan.queryPlan;
    if (queryPlan == null || plan.insertColumns.isEmpty) {
      return _emptyShape;
    }
    final compilation = _grammar.compileSelect(queryPlan);
    final verb = plan.ignoreConflicts ? 'INSERT OR IGNORE' : 'INSERT';
    final columns = plan.insertColumns.map(_quote).join(', ');

    // Wrap the source query in a subquery that only selects the columns we're inserting
    // This handles cases where the source query selects more columns than we need
    final projectedColumns = plan.insertColumns
        .map((col) => _quote(col))
        .join(', ');
    final wrappedSelect =
        'SELECT $projectedColumns FROM (${compilation.sql}) AS __source__';

    final sql = StringBuffer()
      ..write('$verb INTO ${_tableIdentifier(plan.definition)} ($columns) ')
      ..write(wrappedSelect);
    return _SqliteMutationShape(
      sql: sql.toString(),
      parameterSets: [compilation.bindings.toList(growable: false)],
    );
  }

  _SqliteMutationShape _buildUpdateShape(MutationPlan plan) {
    if (plan.rows.isEmpty) {
      return _emptyShape;
    }
    final table = _tableIdentifier(plan.definition);
    final firstRow = plan.rows.first;
    final setColumns = firstRow.values.keys.toList();
    final jsonTemplates = _jsonUpdateTemplates(firstRow);
    if (setColumns.isEmpty && jsonTemplates.isEmpty) {
      return _emptyShape;
    }
    final assignments = <String>[];
    if (setColumns.isNotEmpty) {
      assignments.addAll(setColumns.map((c) => '${_quote(c)} = ?'));
    }
    assignments.addAll(jsonTemplates.map((template) => template.sql));
    final whereColumns = firstRow.keys.keys.toList();
    final whereClause = _whereClause(firstRow.keys);
    final sqlBuf = StringBuffer(
      'UPDATE $table SET ${assignments.join(', ')} WHERE $whereClause',
    );

    // Add RETURNING clause if requested
    if (plan.returning) {
      final allColumns = plan.definition.fields
          .map((f) => f.columnName)
          .map(_quote)
          .join(', ');
      sqlBuf.write(' RETURNING $allColumns');
    }

    final parameters = plan.rows
        .map((row) {
          final values = <Object?>[
            ...setColumns.map(
              (c) => _encodeValueForColumn(
                definition: plan.definition,
                column: c,
                value: row.values[c],
              ),
            ),
          ];
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
              var expression = _quote(template.column);
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
                values.addAll(compiled.bindings);
              }
            }
          }
          values.addAll(
            whereColumns.map(
              (c) => _encodeValueForColumn(
                definition: plan.definition,
                column: c,
                value: row.keys[c],
              ),
            ),
          );
          return values;
        })
        .toList(growable: false);
    return _SqliteMutationShape(
      sql: sqlBuf.toString(),
      parameterSets: parameters,
    );
  }

  _SqliteMutationShape _buildDeleteShape(MutationPlan plan) {
    if (plan.rows.isEmpty) {
      return _emptyShape;
    }
    final table = _tableIdentifier(plan.definition);
    final firstRow = plan.rows.first;
    final whereColumns = firstRow.keys.keys.toList();
    final whereClause = _whereClause(firstRow.keys);
    final sql = StringBuffer('DELETE FROM $table WHERE $whereClause');
    if (plan.returning) {
      final columns = plan.definition.fields
          .map((f) => _quote(f.columnName))
          .join(', ');
      sql.write(' RETURNING $columns');
    }
    final parameters = plan.rows
        .map((row) => whereColumns.map((column) => row.keys[column]).toList())
        .toList(growable: false);
    return _SqliteMutationShape(sql: sql.toString(), parameterSets: parameters);
  }

  _SqliteMutationShape _buildQueryDeleteShape(MutationPlan plan) {
    final queryPlan = plan.queryPlan;
    if (queryPlan == null) {
      return _emptyShape;
    }
    final primaryKey =
        plan.queryPrimaryKey ?? plan.definition.primaryKeyField?.columnName;
    if (primaryKey == null || primaryKey.isEmpty) {
      throw StateError(
        'Query deletes on ${plan.definition.modelName} require a primary key.',
      );
    }
    QueryPlan projectionPlan = queryPlan;
    if (plan.definition.primaryKeyField == null) {
      final identifier = _metadata.queryUpdateRowIdentifier;
      if (identifier == null || identifier.column != primaryKey) {
        throw StateError(
          'Query deletes on ${plan.definition.modelName} require a primary key.',
        );
      }
      projectionPlan = _rowIdentifierProjection(queryPlan, primaryKey);
    }
    final compilation = _grammar.compileSelect(projectionPlan);
    final table = _tableIdentifier(plan.definition);
    final pkIdentifier = _quote(primaryKey);
    // For SQLite, we need to use ROWID for the outer reference since
    // unqualified column names in EXISTS subqueries can be ambiguous
    final outerRef = primaryKey == 'rowid' ? 'ROWID' : pkIdentifier;
    final sql = StringBuffer('DELETE FROM ')
      ..write(table)
      ..write(' WHERE ')
      ..write(outerRef)
      ..write(' IN (SELECT ')
      ..write(pkIdentifier)
      ..write(' FROM (')
      ..write(compilation.sql)
      ..write(') AS "__orm_delete_source")');
    if (plan.returning) {
      final columns = plan.definition.fields
          .map((f) => _quote(f.columnName))
          .join(', ');
      sql.write(' RETURNING $columns');
    }
    return _SqliteMutationShape(
      sql: sql.toString(),
      parameterSets: [compilation.bindings.toList(growable: false)],
    );
  }

  _SqliteMutationShape _buildQueryUpdateShape(MutationPlan plan) {
    final queryPlan = plan.queryPlan;
    final hasColumns = plan.queryUpdateValues.isNotEmpty;
    final hasJson = plan.queryJsonUpdates.isNotEmpty;
    final hasIncrements = plan.queryIncrementValues.isNotEmpty;
    if (queryPlan == null || (!hasColumns && !hasJson && !hasIncrements)) {
      return _emptyShape;
    }
    final key =
        plan.queryPrimaryKey ?? plan.definition.primaryKeyField?.columnName;
    if (key == null) {
      throw StateError(
        'Query updates on ${plan.definition.modelName} require a primary key.',
      );
    }
    final projectionPlan = plan.definition.primaryKeyField == null
        ? _rowIdentifierProjection(queryPlan, key)
        : queryPlan;
    final compilation = _grammar.compileSelect(projectionPlan);
    final assignments = <String>[];
    final parameters = <Object?>[];
    if (hasColumns) {
      assignments.addAll(
        plan.queryUpdateValues.keys.map((column) => '"$column" = ?'),
      );
      parameters.addAll(
        plan.queryUpdateValues.entries.map(
          (entry) => _encodeValueForColumn(
            definition: plan.definition,
            column: entry.key,
            value: entry.value,
          ),
        ),
      );
    }
    if (hasIncrements) {
      for (final entry in plan.queryIncrementValues.entries) {
        final column = entry.key;
        final amount = entry.value;
        assignments.add('"$column" = "$column" + ?');
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
        final resolved = '"$column"';
        var expression = resolved;
        final clauseBindings = <Object?>[];
        for (final clause in clauses) {
          final clauseValue = _encodeValueForColumn(
            definition: plan.definition,
            column: clause.column,
            value: clause.value,
          );
          final compiled = clause.patch
              ? _grammar.compileJsonPatch(
                  clause.column,
                  expression,
                  clauseValue,
                )
              : _grammar.compileJsonUpdate(
                  clause.column,
                  expression,
                  clause.path,
                  clauseValue,
                );
          expression = _assignmentRhs(compiled.sql);
          clauseBindings.addAll(compiled.bindings);
        }
        assignments.add('$resolved = $expression');
        parameters.addAll(clauseBindings);
      });
    }
    if (assignments.isEmpty) {
      return _emptyShape;
    }
    final table = _tableIdentifier(plan.definition);
    final quotedKey = _quote(key);
    final sql = StringBuffer('UPDATE $table SET ')
      ..write(assignments.join(', '))
      ..write(' WHERE EXISTS (SELECT 1 FROM (')
      ..write(compilation.sql)
      ..write(') AS "__orm_update_source" WHERE ')
      ..write(table)
      ..write('.')
      ..write(quotedKey)
      ..write(' = "__orm_update_source".')
      ..write(quotedKey)
      ..write(')');
    if (plan.returning) {
      final columns = plan.definition.fields
          .map((f) => _quote(f.columnName))
          .join(', ');
      sql.write(' RETURNING $columns');
    }
    parameters.addAll(compilation.bindings);
    return _SqliteMutationShape(
      sql: sql.toString(),
      parameterSets: [parameters],
    );
  }

  _SqliteMutationShape _buildUpsertShape(MutationPlan plan) {
    if (plan.rows.isEmpty) {
      return _emptyShape;
    }
    final table = _tableIdentifier(plan.definition);
    final firstRow = plan.rows.first;
    final columns = firstRow.values.keys.toList();
    final columnSql = columns.map(_quote).join(', ');
    final placeholders = List.filled(columns.length, '?').join(', ');
    final uniqueColumns = _resolveUpsertUniqueColumns(plan);
    final updateColumns = _resolveUpsertUpdateColumns(
      plan,
      columns,
      uniqueColumns,
    );
    final jsonTemplates = _jsonUpdateTemplates(firstRow);
    final jsonColumns = jsonTemplates.map((t) => t.column).toSet();
    final updateAssignments = <String>[];
    updateAssignments.addAll(
      updateColumns
          .where((c) => !jsonColumns.contains(c))
          .map((c) => '${_quote(c)} = excluded.${_quote(c)}'),
    );
    updateAssignments.addAll(jsonTemplates.map((template) => template.sql));
    final updateClause = updateAssignments.join(', ');
    final sql =
        StringBuffer('INSERT INTO $table ($columnSql) VALUES ($placeholders) ')
          ..write('ON CONFLICT(${uniqueColumns.map(_quote).join(', ')}) DO ')
          ..write(
            updateClause.isEmpty ? 'NOTHING' : 'UPDATE SET $updateClause',
          );

    // Add RETURNING clause if requested
    if (plan.returning) {
      final allColumns = plan.definition.fields
          .map((f) => f.columnName)
          .map(_quote)
          .join(', ');
      sql.write(' RETURNING $allColumns');
    }
    final parameters = plan.rows
        .map((row) {
          final values = columns
              .map(
                (column) => _encodeValueForColumn(
                  definition: plan.definition,
                  column: column,
                  value: row.values[column],
                ),
              )
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
              var expression = _quote(template.column);
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
                values.addAll(compiled.bindings);
              }
            }
          }
          return values;
        })
        .toList(growable: false);
    return _SqliteMutationShape(sql: sql.toString(), parameterSets: parameters);
  }

  List<_JsonUpdateTemplate> _jsonUpdateTemplates(MutationRow row) {
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
      final resolved = _quote(column);
      var expression = resolved;
      final bindings = <Object?>[];
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
        bindings.addAll(compiled.bindings);
      }
      final sql = '$resolved = $expression';
      templates.add(
        _JsonUpdateTemplate(
          column: column,
          clauses: List.unmodifiable(clauses),
          sql: sql,
          bindings: List.unmodifiable(bindings),
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
    final flattened = templates.expand((template) => template.clauses).toList();
    if (flattened.length != clauses.length) {
      throw StateError(
        'All mutation rows must provide ${flattened.length} JSON update clauses.',
      );
    }
    for (var i = 0; i < clauses.length; i++) {
      final templateClause = flattened[i];
      final clause = clauses[i];
      if (templateClause.column != clause.column ||
          templateClause.path != clause.path ||
          templateClause.patch != clause.patch) {
        throw StateError(
          'JSON update clauses must match the first row ordering and paths.',
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
    // 2. This prevents overwriting an existing auto-increment ID with 0
    final pkColumn = plan.definition.primaryKeyField?.columnName;
    final excludeFromUpdate = <String>{...conflicts};
    if (pkColumn != null && !conflicts.contains(pkColumn)) {
      excludeFromUpdate.add(pkColumn);
    }

    return insertColumns.where((c) => !excludeFromUpdate.contains(c)).toList();
  }

  static const _SqliteMutationShape _emptyShape = _SqliteMutationShape(
    sql: '<no-op>',
    parameterSets: [],
  );

  String _tableIdentifier(ModelDefinition<OrmEntity> definition) {
    final table = _quote(definition.tableName);
    final schema = definition.schema;
    if (schema == null || schema.isEmpty) {
      return table;
    }
    return '${_quote(schema)}.$table';
  }

  String _baseTableReference(QueryPlan plan) {
    final alias = plan.tableAlias;
    if (alias != null && alias.isNotEmpty) {
      return _quote(alias);
    }
    final schema = plan.definition.schema;
    final table = _quote(plan.definition.tableName);
    if (schema == null || schema.isEmpty || schema == 'main') {
      return table;
    }
    return '${_quote(schema)}.$table';
  }

  QueryPlan _rowIdentifierProjection(QueryPlan plan, String key) {
    final reference = _baseTableReference(plan);
    final expression = '$reference.${_quote(key)}';
    return plan.copyWith(
      selects: const [],
      rawSelects: [RawSelectExpression(sql: expression, alias: key)],
      aggregates: const [],
      projectionOrder: const [ProjectionOrderEntry.raw(0)],
    );
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

  String? _exposedSchema(String? schema) {
    if (schema == null || schema.isEmpty || schema == 'main') {
      return null;
    }
    return schema;
  }

  String _schemaOrDefault(String? schema) =>
      schema == null || schema.isEmpty ? 'main' : schema;

  String _sqliteMasterTable(String schema) {
    if (schema == 'main') return 'sqlite_master';
    if (schema == 'temp') return 'sqlite_temp_master';
    return '${_quote(schema)}.sqlite_master';
  }

  String _pragmaFor(String pragma, String identifier, {String? schema}) {
    final namespace = schema == null || schema.isEmpty ? null : schema;
    final buffer = StringBuffer('PRAGMA ');
    if (namespace != null) {
      if (namespace == 'temp') {
        buffer.write('temp.');
      } else {
        buffer
          ..write(_quote(namespace))
          ..write('.');
      }
    }
    buffer
      ..write(pragma)
      ..write('(')
      ..write(_stringLiteral(identifier))
      ..write(')');
    return buffer.toString();
  }

  String _stringLiteral(String value) {
    final escaped = value.replaceAll("'", "''");
    return "'$escaped'";
  }

  List<String> _splitColumns(Object? value) {
    if (value == null) return const [];
    return value
        .toString()
        .split(',')
        .map((c) => c.trim())
        .where((c) => c.isNotEmpty)
        .toList(growable: false);
  }

  String? _normalizeDefault(Object? value) => value?.toString();

  List<String> _indexColumns(
    sqlite.Database database,
    String indexName, {
    String? schema,
  }) {
    final pragma = _pragmaFor('index_xinfo', indexName, schema: schema);
    final rows = database.select(pragma);
    final ordered = rows.toList()
      ..sort((a, b) => (a['seqno'] as int).compareTo(b['seqno'] as int));
    return ordered
        .where((row) => (row['cid'] as int) >= 0)
        .map((row) => row['name'])
        .whereType<String>()
        .toList(growable: false);
  }

  String? _indexWhereClause(
    sqlite.Database database,
    String indexName, {
    String? schema,
  }) {
    final master = _sqliteMasterTable(_schemaOrDefault(schema));
    final rows = database.select(
      'SELECT sql FROM $master WHERE type = ? AND name = ?',
      ['index', indexName],
    );
    if (rows.isEmpty) {
      return null;
    }
    final sql = rows.first['sql'] as String?;
    if (sql == null) return null;
    final match = RegExp(
      r'\bWHERE\b(.*)$',
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(sql);
    return match?.group(1)?.trim();
  }

  Object? _encodeValueForColumn({
    required ModelDefinition<OrmEntity> definition,
    required String column,
    required Object? value,
  }) {
    final metadata = definition.metadata;
    final overrideCast = metadata.fieldOverrides[column]?.cast;
    final cast = overrideCast ?? metadata.casts[column];
    final field = definition.fieldByColumn(column);
    if (cast != null) {
      try {
        final normalizedCast = cast.trim().toLowerCase();
        if ((normalizedCast == 'json' || normalizedCast == 'object') &&
            value is String) {
          return value;
        }
        return _codecs.encodeCast(cast, value, field: field);
      } on TypeError {
        return value;
      }
    }
    if (value is Map || value is List) {
      return jsonEncode(value);
    }
    if (field != null) {
      try {
        return _codecs.encodeField(field, value);
      } on TypeError {
        return value;
      }
    }
    return _codecs.encodeValue(value);
  }

  Map<String, Object?> _decodeRowValues(
    ModelDefinition<OrmEntity> definition,
    Map<String, Object?> row,
  ) => row.map(
    (column, value) => MapEntry(
      column,
      _decodeValueForColumn(
        definition: definition,
        column: column,
        value: value,
      ),
    ),
  );

  Object? _decodeValueForColumn({
    required ModelDefinition<OrmEntity> definition,
    required String column,
    required Object? value,
  }) {
    final metadata = definition.metadata;
    final overrideCast = metadata.fieldOverrides[column]?.cast;
    final cast = overrideCast ?? metadata.casts[column];
    final field = definition.fieldByColumn(column);
    if (cast != null) {
      try {
        return _codecs.decodeCast(cast, value, field: field);
      } on TypeError {
        return value;
      }
    }
    if (field != null) {
      try {
        return _codecs.decodeField(field, value);
      } on TypeError {
        return value;
      }
    }
    return value;
  }
}

class _JsonUpdateTemplate {
  const _JsonUpdateTemplate({
    required this.column,
    required this.clauses,
    required this.sql,
    required this.bindings,
  });

  final String column;
  final List<JsonUpdateClause> clauses;
  final String sql;
  final List<Object?> bindings;
}

class _SqliteMutationShape {
  const _SqliteMutationShape({required this.sql, required this.parameterSets});

  final String sql;
  final List<List<Object?>> parameterSets;
}

String _assignmentRhs(String sql) {
  final index = sql.indexOf('=');
  if (index == -1) {
    return sql;
  }
  return sql.substring(index + 1).trim();
}
