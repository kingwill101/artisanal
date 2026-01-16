import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:decimal/decimal.dart';
import 'package:mysql_client_plus/mysql_client_plus.dart';
import 'package:ormed/ormed.dart';
import 'package:uuid/uuid_value.dart';

import 'mysql_codecs.dart';
import 'mysql_connection_info.dart';
import 'mysql_connector.dart';
import 'mysql_grammar.dart';
import 'mysql_schema_dialect.dart';
import 'mysql_type_mapper.dart';
import 'mysql_value_types.dart';
import 'schema_state.dart';

/// Shared MySQL/MariaDB implementation of the routed ORM driver adapter.
class MySqlDriverAdapter
    implements
        DriverAdapter,
        SchemaDriver,
        SchemaStateProvider,
        DriverExtensionHost {
  /// Registers MySQL/MariaDB-specific codecs and type mapper with the global registries.
  /// Call this once during application initialization before using MySQL.
  static void registerCodecs() {
    final mapper = MysqlTypeMapper();
    TypeMapperRegistry.register('mysql', mapper);
    TypeMapperRegistry.register('mariadb', mapper);

    // Register MySQL/MariaDB codecs.
    registerMySqlCodecs();
  }

  MySqlDriverAdapter.custom({
    required DatabaseConfig config,
    ConnectionFactory? connections,
    String driverName = 'mysql',
    bool isMariaDb = false,
    List<DriverExtension> extensions = const [],
  }) : _driverName = driverName,
       _metadata = DriverMetadata(
         name: driverName,
         supportsQueryDeletes: true,
         requiresPrimaryKeyForQueryUpdate: false,
         queryUpdateRowIdentifier: QueryRowIdentifier(
           column: 'id',
           expression: 'id',
         ),
         identifierQuote: '`',
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
           DriverCapability.rightJoin,
           DriverCapability.relationAggregates,
           DriverCapability.returning,
           DriverCapability.databaseManagement,
           DriverCapability.foreignKeyConstraintControl,
         },
       ),
       _schemaCompiler = SchemaPlanCompiler(
         MySqlSchemaDialect(isMariaDb: isMariaDb),
       ),
       _extensions = DriverExtensionRegistry(
         driverName: driverName,
         extensions: extensions,
       ),
       _connections =
           connections ??
           ConnectionFactory(
             connectors: {
               'mysql': () => MySqlConnector(),
               'mariadb': () => MySqlConnector(),
             },
           ),
       _config = config,
       _codecs = ValueCodecRegistry.instance.forDriver(driverName) {
    // Auto-register MySQL codecs on first instantiation
    registerMySqlCodecs();

    _grammar = MySqlQueryGrammar(extensions: _extensions);

    _planCompiler = ClosurePlanCompiler(
      compileSelect: _compileSelectPreview,
      compileMutation: _compileMutationPreview,
    );
  }

  factory MySqlDriverAdapter.fromUrl(
    String url, {
    ConnectionFactory? connections,
    List<DriverExtension> extensions = const [],
  }) => MySqlDriverAdapter.custom(
    config: DatabaseConfig(driver: 'mysql', options: {'url': url}),
    connections: connections,
    extensions: extensions,
  );

  factory MySqlDriverAdapter.insecureLocal({
    String database = 'orm_test',
    String username = 'root',
    String? password,
    int port = 3306,
    String host = '127.0.0.1',
    String? timezone,
    ConnectionFactory? connections,
    List<DriverExtension> extensions = const [],
  }) => MySqlDriverAdapter.custom(
    config: DatabaseConfig(
      driver: 'mysql',
      options: {
        'host': host,
        'port': port,
        'database': database,
        'username': username,
        if (password != null) 'password': password,
        if (timezone != null) 'timezone': timezone,
      },
    ),
    connections: connections,
    extensions: extensions,
  );

  // ignore: unused_field
  final String _driverName;
  final DriverMetadata _metadata;
  final ValueCodecRegistry _codecs;
  final SchemaPlanCompiler _schemaCompiler;
  final DriverExtensionRegistry _extensions;
  late final MySqlQueryGrammar _grammar;
  final ConnectionFactory _connections;
  final DatabaseConfig _config;
  late final PlanCompiler _planCompiler;
  ConnectionHandle<MySQLConnection>? _primaryHandle;
  bool _closed = false;
  int _transactionDepth = 0;
  String? _currentDatabase;
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
    _closed = true;
    if (_primaryHandle != null) {
      await _primaryHandle!.close();
      _primaryHandle = null;
    }
  }

  @override
  Future<void> executeRaw(
    String sql, [
    List<Object?> parameters = const [],
  ]) async {
    // Track USE database commands to maintain current database context
    final trimmedSql = sql.trim();
    if (trimmedSql.toUpperCase().startsWith('USE ')) {
      final dbName = trimmedSql
          .substring(4)
          .trim()
          .replaceAll(RegExp(r'[`;]'), '');
      _currentDatabase = dbName;
    }
    await _executeStatement(sql, parameters);
  }

  @override
  Future<List<Map<String, Object?>>> queryRaw(
    String sql, [
    List<Object?> parameters = const [],
  ]) async {
    final result = await _executeStatement(sql, parameters);
    return _collectRows(result);
  }

  @override
  Future<List<Map<String, Object?>>> execute(QueryPlan plan) async {
    final compilation = _grammar.compileSelect(plan);
    final result = await _executeStatement(
      compilation.sql,
      compilation.bindings,
    );
    return _collectRows(result);
  }

  @override
  Stream<Map<String, Object?>> stream(QueryPlan plan) async* {
    final compilation = _grammar.compileSelect(plan);
    final result = await _executeStatement(
      compilation.sql,
      compilation.bindings,
    );
    for (final row in _rowIterable(result)) {
      yield row;
    }
  }

  @override
  StatementPreview describeQuery(QueryPlan plan) =>
      _planCompiler.compileSelect(plan);

  @override
  Future<MutationResult> runMutation(MutationPlan plan) async {
    // MySQL/MariaDB don't support native RETURNING clause
    // For INSERT operations, we simulate it by returning the lastInsertID
    // For other operations (UPDATE, DELETE, UPSERT), returning is silently ignored
    // since we can't efficiently implement it without re-querying

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
    final normalized = normalizeMySqlParameters(compilation.bindings);
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
    final normalized = shape.parameterSets
        .map(normalizeMySqlParameters)
        .toList(growable: false);
    final sql = shape.parameterSets.isEmpty
        ? shape.sql
        : _formatPreviewSql(shape.sql, normalized.first.length);
    final first = normalized.isEmpty ? const <Object?>[] : normalized.first;
    final resolved = _grammar.substituteBindingsIntoRawSql(
      shape.sql,
      _encodePreviewParameters(first),
    );
    return StatementPreview(
      payload: SqlStatementPayload(sql: sql, parameters: first),
      parameterSets: normalized,
      resolvedText: resolved,
    );
  }

  List<Object?> _encodePreviewParameters(List<Object?> parameters) =>
      parameters.map(_codecs.encodeValue).toList(growable: false);

  @override
  Future<int?> threadCount() async {
    try {
      final sql = _grammar.compileThreadCount();
      if (sql == null) {
        return null;
      }
      final rows = await queryRaw(sql);
      if (rows.isEmpty) {
        return null;
      }
      final row = rows.first;
      final value = row['value'] ?? row['Value'] ?? row['VALUE'];
      if (value is num) {
        return value.toInt();
      }
      if (value is String) {
        return int.tryParse(value);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<R> transaction<R>(Future<R> Function() action) async {
    final connection = await _connection();
    if (_transactionDepth == 0) {
      _transactionDepth++;
      await connection.execute('START TRANSACTION');
      try {
        final result = await action();
        await connection.execute('COMMIT');
        return result;
      } catch (error) {
        await connection.execute('ROLLBACK');
        rethrow;
      } finally {
        _transactionDepth--;
      }
    } else {
      final savepoint = 'sp_${_transactionDepth + 1}';
      _transactionDepth++;
      await connection.execute('SAVEPOINT $savepoint');
      try {
        final result = await action();
        await connection.execute('RELEASE SAVEPOINT $savepoint');
        return result;
      } catch (error) {
        await connection.execute('ROLLBACK TO SAVEPOINT $savepoint');
        rethrow;
      } finally {
        _transactionDepth--;
      }
    }
  }

  @override
  Future<void> beginTransaction() async {
    final connection = await _connection();
    if (_transactionDepth == 0) {
      await connection.execute('START TRANSACTION');
      _transactionDepth++;
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
    // MySQL supports TRUNCATE TABLE which is faster and resets auto-increment
    await connection.execute('TRUNCATE TABLE $tableName');
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
    return MySqlSchemaState(
      config: _config,
      connection: connection,
      ledgerTable: ledgerTable,
    );
  }

  @override
  Future<List<SchemaNamespace>> listSchemas() async {
    final sql = _schemaCompiler.dialect.compileSchemas();
    if (sql == null) {
      throw UnsupportedError('MySQL should support schema listing');
    }

    final rows = await queryRaw(sql);
    return rows
        .map(
          (row) => SchemaNamespace(
            name: row['name'] as String,
            isDefault: _asBool(row['is_default']),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<List<SchemaTable>> listTables({String? schema}) async {
    final effectiveSchema = schema ?? _getCurrentDatabase();
    final sql = _schemaCompiler.dialect.compileTables(schema: effectiveSchema);
    if (sql == null) {
      throw UnsupportedError('MySQL should support table listing');
    }

    final rows = await queryRaw(
      sql,
      effectiveSchema == null ? const [] : [effectiveSchema],
    );
    return rows
        .map(
          (row) => SchemaTable(
            name: _stringValue(row, 'table_name')!,
            schema: _stringValue(row, 'table_schema'),
            type: _stringValue(row, 'table_type'),
            sizeBytes: _asInt(row['size_bytes']),
            comment: _stringValue(row, 'table_comment'),
            engine: _stringValue(row, 'engine'),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<List<SchemaView>> listViews({String? schema}) async {
    final sql = _schemaCompiler.dialect.compileViews(schema: schema);
    if (sql == null) {
      throw UnsupportedError('MySQL should support view listing');
    }

    final rows = await queryRaw(sql, schema == null ? const [] : [schema]);
    return rows
        .map(
          (row) => SchemaView(
            name: _stringValue(row, 'table_name')!,
            schema: _stringValue(row, 'table_schema'),
            definition: _stringValue(row, 'view_definition'),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<List<SchemaColumn>> listColumns(String table, {String? schema}) async {
    final effectiveSchema = schema ?? _getCurrentDatabase() ?? 'test';
    final sql = _schemaCompiler.dialect.compileColumns(
      table,
      schema: effectiveSchema,
    );
    if (sql == null) {
      throw UnsupportedError('MySQL should support column listing');
    }

    final rows = await queryRaw(sql, [table, effectiveSchema]);
    final pkColumns = await _primaryKeyColumns(table, schema: schema);
    String? field(Map<String, Object?> row, String key) {
      final value =
          row[key] ??
          row[key.toLowerCase()] ??
          row[key.toUpperCase()] ??
          row.entries
              .firstWhere(
                (e) => e.key.toString().toLowerCase() == key.toLowerCase(),
                orElse: () => const MapEntry('', null),
              )
              .value;
      return value?.toString();
    }

    return rows
        .map((row) {
          final columnName = field(row, 'column_name');
          if (columnName == null) return null;
          final tableSchema = field(row, 'table_schema');
          final columnType = field(row, 'column_type');
          final dataType = field(row, 'data_type');
          final defaultValue = field(row, 'column_default');
          final extra = field(row, 'extra');
          final nullable = field(row, 'is_nullable');
          final comment = field(row, 'column_comment');

          return SchemaColumn(
            name: columnName,
            dataType: columnType ?? dataType ?? '',
            schema: tableSchema,
            tableName: table,
            length: _asInt(row['character_maximum_length']),
            numericPrecision: _asInt(row['numeric_precision']),
            numericScale: _asInt(row['numeric_scale']),
            nullable: (nullable ?? '').toUpperCase() != 'NO',
            defaultValue: defaultValue,
            autoIncrement: _containsText(extra, 'auto_increment'),
            primaryKey: pkColumns.contains(columnName),
            comment: comment,
          );
        })
        .whereType<SchemaColumn>()
        .toList(growable: false);
  }

  @override
  Future<List<SchemaIndex>> listIndexes(String table, {String? schema}) async {
    final effectiveSchema = schema ?? _getCurrentDatabase() ?? 'test';
    final sql = _schemaCompiler.dialect.compileIndexes(
      table,
      schema: effectiveSchema,
    );
    if (sql == null) {
      throw UnsupportedError('MySQL should support index listing');
    }

    final rows = await queryRaw(sql, [effectiveSchema, table]);
    return rows
        .where((row) => row['name'] != null && row['columns'] != null)
        .map((row) {
          final name = row['name'] as String;
          final columns = _splitColumns(row['columns'] as String?);
          final isPrimary = _asBool(row['is_primary']);
          return SchemaIndex(
            name: name,
            columns: columns,
            schema: schema,
            tableName: table,
            unique: !isPrimary && _asBool(row['unique']) == true,
            primary: isPrimary,
            method: row['type'] as String?,
          );
        })
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
      throw UnsupportedError('MySQL should support foreign key listing');
    }

    final rows = await queryRaw(
      sql,
      schema == null ? [table] : [table, schema],
    );
    return rows
        .map(
          (row) => SchemaForeignKey(
            name: row['constraint_name'] as String,
            columns: _splitColumns(row['columns'] as String?),
            referencedTable: row['referenced_table_name'] as String,
            referencedColumns: _splitColumns(
              row['referenced_columns'] as String?,
            ),
            schema: schema,
            referencedSchema: row['referenced_table_schema'] as String?,
            onDelete: row['delete_rule'] as String?,
            onUpdate: row['update_rule'] as String?,
            tableName: table,
          ),
        )
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
      throw UnsupportedError('MySQL should support database creation');
    }

    try {
      await executeRaw(sql);
      return true;
    } on Exception catch (e) {
      // Check if error is "database exists" (error 1007)
      final errorMsg = e.toString();
      if (errorMsg.contains('1007') ||
          errorMsg.toLowerCase().contains('database exists')) {
        return false;
      }
      rethrow;
    }
  }

  @override
  Future<bool> dropDatabase(String name) async {
    final sql = 'DROP DATABASE ${_quote(name)}';
    await executeRaw(sql);
    return true;
  }

  @override
  Future<bool> dropDatabaseIfExists(String name) async {
    // Quick existence check to return false without relying on error codes
    final existing = await listDatabases();
    if (!existing.contains(name)) {
      return false;
    }

    final sql = _schemaCompiler.dialect.compileDropDatabaseIfExists(name);
    if (sql == null) {
      throw UnsupportedError('MySQL should support database dropping');
    }

    try {
      await executeRaw(sql);
      return true;
    } on Exception catch (e) {
      final message = e.toString().toLowerCase();
      if (message.contains('unknown database') ||
          message.contains('does not exist')) {
        return false;
      }
      rethrow;
    }
  }

  @override
  @override
  Future<List<String>> listDatabases() async {
    final sql = _schemaCompiler.dialect.compileListDatabases();
    if (sql == null) {
      throw UnsupportedError('MySQL should support listing databases');
    }

    final results = await queryRaw(sql);

    // Defensive: support both `db_name` (our alias), `database` (previous alias) and `Database` (SHOW DATABASES)
    final names = results.map((row) {
      final database = row['db_name'] ?? row['database'] ?? row['Database'];
      return database?.toString();
    }).whereType<String>();

    return names.toList(growable: false);
  }

  // ========== Schema (Namespace) Management ==========

  @override
  Future<bool> createSchema(String name) async {
    // MySQL schemas are databases - delegate to createDatabase
    return createDatabase(name);
  }

  @override
  Future<bool> dropSchemaIfExists(String name) async {
    // MySQL schemas are databases - delegate to dropDatabaseIfExists
    return dropDatabaseIfExists(name);
  }

  @override
  Future<void> setCurrentSchema(String name) async {
    // MySQL uses USE command to switch databases/schemas
    await executeRaw('USE `$name`');
    _currentDatabase = name;
  }

  @override
  Future<String> getCurrentSchema() async {
    return _getCurrentDatabase() ?? 'mysql';
  }

  /// Get the current database name from the connection configuration.
  /// This matches Laravel's approach of using the connection's database name
  /// rather than relying on the DATABASE() SQL function.
  /// Also tracks USE commands to maintain correct database context.
  String? _getCurrentDatabase() {
    // If we've executed a USE command, return that database
    if (_currentDatabase != null) {
      return _currentDatabase;
    }
    // Try to get from URL first
    final url = _config.options['url'] as String?;
    if (url != null) {
      return MySqlConnectionInfo.fromUrl(url).database;
    }
    // Fallback to 'database' option
    return _config.options['database'] as String?;
  }

  // ========== Foreign Key Constraint Management ==========

  @override
  Future<bool> enableForeignKeyConstraints() async {
    final sql = _schemaCompiler.dialect.compileEnableForeignKeyConstraints();
    if (sql == null) {
      throw UnsupportedError('MySQL should support FK constraint management');
    }
    await executeRaw(sql);
    return true;
  }

  @override
  Future<bool> disableForeignKeyConstraints() async {
    final sql = _schemaCompiler.dialect.compileDisableForeignKeyConstraints();
    if (sql == null) {
      throw UnsupportedError('MySQL should support FK constraint management');
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
    final tables = await listTables(schema: schema);

    if (tables.isEmpty) return;

    await disableForeignKeyConstraints();

    try {
      for (final table in tables) {
        final tableName = schema != null
            ? '${_quote(schema)}.${_quote(table.name)}'
            : _quote(table.name);
        await executeRaw('DROP TABLE IF EXISTS $tableName');
      }
    } finally {
      await enableForeignKeyConstraints();
    }
  }

  // ========== Existence Checking ==========

  @override
  Future<bool> hasTable(String table, {String? schema}) async {
    final effectiveSchema = schema ?? _getCurrentDatabase() ?? 'test';
    final rows = await queryRaw(
      'SELECT 1 FROM information_schema.tables '
      'WHERE LOWER(table_name) = LOWER(?) AND table_schema = ? '
      'LIMIT 1',
      [table, effectiveSchema],
    );
    return rows.isNotEmpty;
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
    if (plan.rows.isEmpty) {
      return const MutationResult(affectedRows: 0);
    }

    final pkField = plan.definition.primaryKeyField;
    final pkColumn = pkField?.columnName;

    // If returning is requested, pre-fetch the PK values for rows where the
    // WHERE clause doesn't include the PK (e.g., using InsertDto with email)
    // We also need to validate rows exist when WHERE has multiple conditions (e.g., Partial with id AND email)
    List<Object?>? preFetchedPkValues;
    if (plan.returning && pkColumn != null) {
      preFetchedPkValues = <Object?>[];

      for (final row in plan.rows) {
        // Check if PK is in the keys
        final pkValue = row.keys[pkColumn];

        // If there are additional WHERE conditions beyond just the PK,
        // we need to validate a row actually matches ALL conditions
        final hasAdditionalConditions =
            row.keys.length > 1 ||
            (row.keys.length == 1 && !row.keys.containsKey(pkColumn));

        if (pkValue != null && !hasAdditionalConditions) {
          // Simple case: only PK in WHERE, use it directly
          preFetchedPkValues.add(pkValue);
        } else if (row.keys.isNotEmpty) {
          // Either PK is not in keys, or there are additional WHERE conditions
          // Need to pre-fetch to validate and get the PK
          final whereClauses = row.keys.entries
              .map((e) => '${_quote(e.key)} = ?')
              .join(' AND ');
          final fetchSql =
              'SELECT ${_quote(pkColumn)} FROM '
              '${_tableIdentifier(plan.definition)} WHERE $whereClauses LIMIT 1';
          final fetchResult = await _executeStatement(
            fetchSql,
            row.keys.values.toList(),
          );
          final fetchedRows = _collectRows(fetchResult);
          if (fetchedRows.isNotEmpty) {
            preFetchedPkValues.add(fetchedRows.first[pkColumn]);
          } else {
            preFetchedPkValues.add(null);
          }
        } else {
          preFetchedPkValues.add(null);
        }
      }
    }

    final shape = _buildUpdateShape(plan);
    final result = await _executeMutation(shape);

    // If returning is requested, re-query to get the updated rows
    // MySQL doesn't support RETURNING for UPDATE, so we simulate it
    if (plan.returning && pkColumn != null) {
      final connection = await _connection();
      final returnedRows = <Map<String, Object?>>[];

      // Use pre-fetched PK values if available, otherwise fall back to keys
      final pkValues =
          preFetchedPkValues ?? plan.rows.map((r) => r.keys[pkColumn]).toList();

      for (final pkValue in pkValues) {
        if (pkValue != null) {
          final fetchedRow = await _fetchRowByPrimaryKey(
            plan.definition,
            pkValue,
            connection,
          );
          if (fetchedRow != null) {
            returnedRows.add(fetchedRow);
          }
        }
      }

      if (returnedRows.isNotEmpty) {
        return MutationResult(
          affectedRows: result.affectedRows > 0
              ? result.affectedRows
              : returnedRows.length,
          returnedRows: returnedRows,
        );
      }
    }

    return result;
  }

  Future<MutationResult> _runDelete(MutationPlan plan) async {
    final shape = _buildDeleteShape(plan);
    return _executeMutation(shape);
  }

  Future<MutationResult> _runQueryDelete(MutationPlan plan) async {
    // MySQL doesn't support RETURNING for DELETE, so we need to:
    // 1. First SELECT the rows that will be deleted (before the delete)
    // 2. Execute the DELETE
    // 3. Return the pre-fetched rows
    List<Map<String, Object?>>? preSelectedRows;
    if (plan.returning && plan.queryPlan != null) {
      // Execute the original SELECT query to get the rows that will be deleted
      preSelectedRows = await execute(plan.queryPlan!);
    }

    final shape = _buildQueryDeleteShape(plan);
    final result = await _executeMutation(shape);

    // If returning is requested and we have pre-selected rows, return them
    if (plan.returning &&
        preSelectedRows != null &&
        preSelectedRows.isNotEmpty) {
      return MutationResult(
        affectedRows: result.affectedRows > 0
            ? result.affectedRows
            : preSelectedRows.length,
        returnedRows: preSelectedRows,
      );
    }

    return result;
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
        // Execute rows with PK
        final planWithPk = MutationPlan.upsert(
          definition: plan.definition,
          rows: rowsWithPk,
          driverName: plan.driverName,
          returning: plan.returning,
          uniqueBy: plan.upsertUniqueColumns,
          updateColumns: plan.upsertUpdateColumns,
        );
        final resultWithPk = _usesPrimaryKeyUpsert(planWithPk)
            ? await _executeMutation(_buildUpsertShape(planWithPk))
            : await _runManualUpsert(planWithPk);

        // Execute rows without PK
        final planWithoutPk = MutationPlan.upsert(
          definition: plan.definition,
          rows: rowsWithoutPk,
          driverName: plan.driverName,
          returning: plan.returning,
          uniqueBy: plan.upsertUniqueColumns,
          updateColumns: plan.upsertUpdateColumns,
        );
        final resultWithoutPk = _usesPrimaryKeyUpsert(planWithoutPk)
            ? await _executeMutation(_buildUpsertShape(planWithoutPk))
            : await _runManualUpsert(planWithoutPk);

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
        final newPlan = MutationPlan.upsert(
          definition: plan.definition,
          rows: rowsWithPk,
          driverName: plan.driverName,
          returning: plan.returning,
          uniqueBy: plan.upsertUniqueColumns,
          updateColumns: plan.upsertUpdateColumns,
        );
        if (_usesPrimaryKeyUpsert(newPlan)) {
          return _executeMutation(_buildUpsertShape(newPlan));
        }
        return _runManualUpsert(newPlan);
      } else {
        final newPlan = MutationPlan.upsert(
          definition: plan.definition,
          rows: rowsWithoutPk,
          driverName: plan.driverName,
          returning: plan.returning,
          uniqueBy: plan.upsertUniqueColumns,
          updateColumns: plan.upsertUpdateColumns,
        );
        if (_usesPrimaryKeyUpsert(newPlan)) {
          return _executeMutation(_buildUpsertShape(newPlan));
        }
        return _runManualUpsert(newPlan);
      }
    }

    // Non-auto-increment PK or no PK - use standard path
    if (_usesPrimaryKeyUpsert(plan)) {
      final shape = _buildUpsertShape(plan);
      return _executeMutation(shape);
    }
    return _runManualUpsert(plan);
  }

  Future<MutationResult> _runQueryUpdate(MutationPlan plan) async {
    // MySQL doesn't support RETURNING for UPDATE, so we need to:
    // 1. First SELECT the rows that will be updated (before the update)
    // 2. Execute the UPDATE
    // 3. Re-fetch the updated rows and return them
    List<Map<String, Object?>>? preSelectedRows;
    if (plan.returning && plan.queryPlan != null) {
      // Execute the original SELECT query to get the rows that will be updated
      preSelectedRows = await execute(plan.queryPlan!);
    }

    final shape = _buildQueryUpdateShape(plan);
    final result = await _executeMutation(shape);

    // If returning is requested and we have pre-selected rows, re-fetch them
    if (plan.returning &&
        preSelectedRows != null &&
        preSelectedRows.isNotEmpty) {
      final pkField = plan.definition.primaryKeyField;
      if (pkField != null) {
        final pkColumn = pkField.columnName;
        final connection = await _connection();
        final returnedRows = <Map<String, Object?>>[];

        for (final row in preSelectedRows) {
          final pkValue = row[pkColumn];
          if (pkValue != null) {
            final fetchedRow = await _fetchRowByPrimaryKey(
              plan.definition,
              pkValue,
              connection,
            );
            if (fetchedRow != null) {
              returnedRows.add(fetchedRow);
            }
          }
        }

        if (returnedRows.isNotEmpty) {
          return MutationResult(
            affectedRows: result.affectedRows > 0
                ? result.affectedRows
                : returnedRows.length,
            returnedRows: returnedRows,
          );
        }
      }
    }

    return result;
  }

  Future<MutationResult> _executeMutation(_MySqlMutationShape shape) async {
    if (shape.parameterSets.isEmpty) {
      return const MutationResult(affectedRows: 0);
    }
    final connection = await _connection();
    var affected = 0;
    final returnedRows = <Map<String, Object?>>[];

    final stmt = await connection.prepare(shape.sql);
    try {
      for (int i = 0; i < shape.parameterSets.length; i++) {
        final parameters = shape.parameterSets[i];
        final result = await stmt.execute(normalizeMySqlParameters(parameters));
        affected += result.affectedRows.toInt();

        // For INSERTs with RETURNING, capture the last insert ID as a returned row
        // MySQL doesn't support native RETURNING, so we simulate it for INSERTs only
        if (shape.isInsert &&
            shape.returning &&
            result.lastInsertID.toInt() > 0 &&
            shape.definition != null) {
          // Find the primary key field name from the plan
          try {
            final pkField = shape.definition!.fields.firstWhere(
              (f) => f.isPrimaryKey,
            );
            returnedRows.add({pkField.columnName: result.lastInsertID.toInt()});
          } catch (_) {
            // No primary key found, skip
          }
        }

        // For UPSERTs with RETURNING, we need to re-query to get the actual row data
        // since MySQL doesn't support RETURNING and we need accurate post-update values
        if (shape.isUpsert && shape.returning && shape.definition != null) {
          final pkValue = await _extractPrimaryKeyForUpsert(
            shape,
            result,
            parameters,
            i,
          );
          if (pkValue != null) {
            final row = await _fetchRowByPrimaryKey(
              shape.definition!,
              pkValue,
              connection,
            );
            if (row != null) {
              returnedRows.add(row);
            }
          }
        }
      }
    } finally {
      await stmt.deallocate();
    }

    return MutationResult(
      affectedRows: affected,
      returnedRows: shape.returning && returnedRows.isNotEmpty
          ? returnedRows
          : null,
    );
  }

  _MySqlMutationShape _shapeForPlan(MutationPlan plan) {
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

  _MySqlMutationShape _buildInsertShape(MutationPlan plan) {
    if (plan.rows.isEmpty) {
      return _MySqlMutationShape.empty();
    }
    // Use columns from the first row to determine which fields are actually being inserted
    // This handles cases where auto-increment PKs are filtered out
    final columns = plan.rows.first.values.keys.toList();
    final columnSql = columns.map(_quote).join(', ');
    final placeholders = List.filled(columns.length, '?').join(', ');
    final verb = plan.ignoreConflicts ? 'INSERT IGNORE' : 'INSERT';
    final sql =
        '$verb INTO ${_tableIdentifier(plan.definition)} ($columnSql) VALUES ($placeholders)';
    final parameterSets = plan.rows
        .map((row) => columns.map((column) => row.values[column]).toList())
        .toList(growable: false);
    return _MySqlMutationShape(
      sql: sql,
      parameterSets: parameterSets,
      isInsert: true,
      definition: plan.definition,
      returning: plan.returning,
    );
  }

  _MySqlMutationShape _buildInsertUsingShape(MutationPlan plan) {
    final queryPlan = plan.queryPlan;
    if (queryPlan == null || plan.insertColumns.isEmpty) {
      return _MySqlMutationShape.empty();
    }
    final compilation = _grammar.compileSelect(queryPlan);
    final verb = plan.ignoreConflicts ? 'INSERT IGNORE' : 'INSERT';
    final columns = plan.insertColumns.map(_quote).join(', ');
    final sql = StringBuffer()
      ..write('$verb INTO ${_tableIdentifier(plan.definition)} ($columns) ')
      ..write(compilation.sql);
    return _MySqlMutationShape(
      sql: sql.toString(),
      parameterSets: [compilation.bindings.toList(growable: false)],
      isInsert: true,
      definition: plan.definition,
      returning: plan.returning,
    );
  }

  _MySqlMutationShape _buildUpdateShape(MutationPlan plan) {
    if (plan.rows.isEmpty) {
      return _MySqlMutationShape.empty();
    }
    final table = _tableIdentifier(plan.definition);
    final firstRow = plan.rows.first;
    final setColumns = firstRow.values.keys.toList();
    final jsonTemplates = _jsonUpdateTemplates(firstRow);
    if (setColumns.isEmpty && jsonTemplates.isEmpty) {
      return _MySqlMutationShape.empty();
    }
    final assignments = <String>[];
    if (setColumns.isNotEmpty) {
      assignments.addAll(setColumns.map((c) => '${_quote(c)} = ?'));
    }
    assignments.addAll(jsonTemplates.map((template) => template.sql));
    final whereColumns = firstRow.keys.keys.toList();
    final whereClause = _whereClause(firstRow.keys);
    final sql =
        'UPDATE $table SET ${assignments.join(', ')} WHERE $whereClause';
    final parameterSets = plan.rows
        .map((row) {
          final parameters = <Object?>[...setColumns.map((c) => row.values[c])];
          if (jsonTemplates.isNotEmpty) {
            final clauses = row.jsonUpdates;
            _validateJsonUpdateShape(jsonTemplates, clauses);
            for (var i = 0; i < jsonTemplates.length; i++) {
              final template = jsonTemplates[i];
              final clause = clauses[i];
              final compiled = template.patch
                  ? _grammar.compileJsonPatch(
                      clause.column,
                      template.resolvedColumn,
                      clause.value,
                    )
                  : _grammar.compileJsonUpdate(
                      clause.column,
                      template.resolvedColumn,
                      clause.path,
                      clause.value,
                    );
              if (compiled.sql != template.sql) {
                throw StateError(
                  'JSON update clause mismatch for ${clause.column} ${clause.path}.',
                );
              }
              parameters.addAll(compiled.bindings);
            }
          }
          parameters.addAll(whereColumns.map((c) => row.keys[c]));
          return parameters;
        })
        .toList(growable: false);
    return _MySqlMutationShape(sql: sql, parameterSets: parameterSets);
  }

  _MySqlMutationShape _buildDeleteShape(MutationPlan plan) {
    if (plan.rows.isEmpty) {
      return _MySqlMutationShape.empty();
    }
    final table = _tableIdentifier(plan.definition);
    final firstRow = plan.rows.first;
    final whereColumns = firstRow.keys.keys.toList();
    final whereClause = _whereClause(firstRow.keys);
    final sql = 'DELETE FROM $table WHERE $whereClause';
    final parameterSets = plan.rows
        .map((row) => whereColumns.map((c) => row.keys[c]).toList())
        .toList(growable: false);
    return _MySqlMutationShape(sql: sql, parameterSets: parameterSets);
  }

  _MySqlMutationShape _buildQueryDeleteShape(MutationPlan plan) {
    final queryPlan = plan.queryPlan;
    if (queryPlan == null) {
      return _MySqlMutationShape.empty();
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
    final sql = StringBuffer('DELETE ')
      ..write(targetAlias)
      ..write(' FROM ')
      ..write('$table AS $targetAlias JOIN (')
      ..write(compilation.sql)
      ..write(') AS $sourceAlias ON ')
      ..write('$sourceAlias.$pkIdentifier = $targetAlias.$pkIdentifier');
    return _MySqlMutationShape(
      sql: sql.toString(),
      parameterSets: [compilation.bindings.toList(growable: false)],
    );
  }

  _MySqlMutationShape _buildQueryUpdateShape(MutationPlan plan) {
    final queryPlan = plan.queryPlan;
    final hasColumns = plan.queryUpdateValues.isNotEmpty;
    final hasJson = plan.queryJsonUpdates.isNotEmpty;
    final hasIncrements = plan.queryIncrementValues.isNotEmpty;
    if (queryPlan == null || (!hasColumns && !hasJson && !hasIncrements)) {
      return _MySqlMutationShape.empty();
    }
    final metadata = _metadata;
    final pk =
        plan.queryPrimaryKey ??
        plan.definition.primaryKeyField?.columnName ??
        metadata.queryUpdateRowIdentifier?.column;
    if (pk == null) {
      throw StateError(
        'Query updates on ${plan.definition.modelName} require a primary key.',
      );
    }
    final compilation = _grammar.compileSelect(queryPlan);
    final assignments = <String>[];
    final parameters = <Object?>[];
    if (hasColumns) {
      assignments.addAll(
        plan.queryUpdateValues.keys.map((column) => '${_quote(column)} = ?'),
      );
      parameters.addAll(plan.queryUpdateValues.values);
    }
    if (hasIncrements) {
      for (final entry in plan.queryIncrementValues.entries) {
        final column = entry.key;
        final amount = entry.value;
        assignments.add('${_quote(column)} = ${_quote(column)} + ?');
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
        var expression = resolved;
        final clauseBindings = <Object?>[];
        for (final clause in clauses) {
          final compiledJson = clause.patch
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
          expression = _assignmentRhs(compiledJson.sql);
          clauseBindings.addAll(compiledJson.bindings);
        }
        assignments.add('$resolved = $expression');
        parameters.addAll(clauseBindings);
      });
    }
    if (assignments.isEmpty) {
      return _MySqlMutationShape.empty();
    }
    final derivedAlias = '__orm_update';
    final sql = StringBuffer('UPDATE ${_tableIdentifier(plan.definition)} SET ')
      ..write(assignments.join(', '))
      ..write(' WHERE ${_quote(pk)} IN (SELECT ')
      ..write('$derivedAlias.${_quote(pk)}')
      ..write(' FROM (')
      ..write(compilation.sql)
      ..write(') AS $derivedAlias)');
    parameters.addAll(compilation.bindings);
    return _MySqlMutationShape(
      sql: sql.toString(),
      parameterSets: [parameters],
    );
  }

  _MySqlMutationShape _buildUpsertShape(MutationPlan plan) {
    if (plan.rows.isEmpty) {
      return _MySqlMutationShape.empty();
    }
    final table = _tableIdentifier(plan.definition);
    final firstRow = plan.rows.first;
    final columns = firstRow.values.keys.toList();
    if (columns.isEmpty) {
      return _MySqlMutationShape.empty();
    }
    final uniqueColumns = _resolveUpsertUniqueColumns(plan);
    final updateColumns = _resolveUpsertUpdateColumns(
      plan,
      columns,
      uniqueColumns,
    );
    final jsonTemplates = _jsonUpdateTemplates(firstRow);
    final jsonColumns = jsonTemplates.map((t) => t.column).toSet();
    final columnSql = columns.map(_quote).join(', ');
    final placeholders = List.filled(columns.length, '?').join(', ');
    final assignments = <String>[];
    assignments.addAll(
      updateColumns
          .where((c) => !jsonColumns.contains(c))
          .map((c) => '${_quote(c)} = VALUES(${_quote(c)})'),
    );
    assignments.addAll(jsonTemplates.map((template) => template.sql));
    final updateClause = assignments.join(', ');
    final buffer = StringBuffer(
      'INSERT INTO $table ($columnSql) VALUES ($placeholders) ON DUPLICATE KEY UPDATE ',
    );
    if (updateClause.isEmpty) {
      final column = uniqueColumns.isNotEmpty
          ? uniqueColumns.first
          : columns.first;
      buffer.write('${_quote(column)} = ${_quote(column)}');
    } else {
      buffer.write(updateClause);
    }
    final parameterSets = plan.rows
        .map((row) {
          final parameters = columns
              .map((column) => row.values[column])
              .toList(growable: true);
          if (jsonTemplates.isNotEmpty) {
            final clauses = row.jsonUpdates;
            _validateJsonUpdateShape(jsonTemplates, clauses);
            for (var i = 0; i < jsonTemplates.length; i++) {
              final template = jsonTemplates[i];
              final clause = clauses[i];
              final compiled = template.patch
                  ? _grammar.compileJsonPatch(
                      clause.column,
                      template.resolvedColumn,
                      clause.value,
                    )
                  : _grammar.compileJsonUpdate(
                      clause.column,
                      template.resolvedColumn,
                      clause.path,
                      clause.value,
                    );
              if (compiled.sql != template.sql) {
                throw StateError(
                  'JSON update clause mismatch for ${clause.column} ${clause.path}.',
                );
              }
              parameters.addAll(compiled.bindings);
            }
          }
          return parameters;
        })
        .toList(growable: false);
    return _MySqlMutationShape(
      sql: buffer.toString(),
      parameterSets: parameterSets,
      isUpsert: true,
      definition: plan.definition,
      returning: plan.returning,
      plan: plan,
    );
  }

  bool _usesPrimaryKeyUpsert(MutationPlan plan) {
    final pk = plan.definition.primaryKeyField?.columnName;
    return pk != null &&
        plan.upsertUniqueColumns.length == 1 &&
        plan.upsertUniqueColumns.first == pk;
  }

  Future<MutationResult> _runManualUpsert(MutationPlan plan) async {
    final table = _tableIdentifier(plan.definition);
    final firstRow = plan.rows.first;
    final columns = firstRow.values.keys.toList();
    final columnSql = columns.map(_quote).join(', ');
    final placeholders = List.filled(columns.length, '?').join(', ');
    final insertSql = 'INSERT INTO $table ($columnSql) VALUES ($placeholders)';
    final uniqueColumns = _resolveUpsertUniqueColumns(plan);
    final updateColumns = _resolveUpsertUpdateColumns(
      plan,
      columns,
      uniqueColumns,
    );
    final whereClause = uniqueColumns
        .map((column) => '${_quote(column)} = ?')
        .join(' AND ');
    final selectSql = 'SELECT 1 FROM $table WHERE $whereClause LIMIT 1';
    final updateClause = updateColumns
        .map((column) => '${_quote(column)} = ?')
        .join(', ');
    final updateSql = updateClause.isEmpty
        ? null
        : 'UPDATE $table SET $updateClause WHERE $whereClause';

    var affected = 0;
    final returnedRows = <Map<String, Object?>>[];
    final connection = await _connection();

    for (final row in plan.rows) {
      final selectors = uniqueColumns
          .map((column) => row.values[column])
          .toList(growable: false);
      final selectResult = await _executeStatement(selectSql, selectors);
      final exists = selectResult.rows.isNotEmpty;
      if (exists) {
        if (updateSql != null) {
          final updateParams = <Object?>[];
          for (final column in updateColumns) {
            updateParams.add(row.values[column]);
          }
          updateParams.addAll(selectors);
          final result = await _executeStatement(updateSql, updateParams);
          affected += result.affectedRows.toInt();
        }

        // If returning is requested, fetch the updated row
        if (plan.returning) {
          final pkValue = _extractPrimaryKeyFromRow(plan.definition, row);
          Map<String, Object?>? fetchedRow;
          if (pkValue != null) {
            fetchedRow = await _fetchRowByPrimaryKey(
              plan.definition,
              pkValue,
              connection,
            );
          } else {
            // Fall back to fetching by unique columns
            fetchedRow = await _fetchRowByUniqueColumns(
              plan.definition,
              uniqueColumns,
              selectors,
              connection,
            );
          }
          if (fetchedRow != null) {
            returnedRows.add(fetchedRow);
          }
        }
        continue;
      }
      final values = columns
          .map((column) => row.values[column])
          .toList(growable: false);
      final result = await _executeStatement(insertSql, values);
      affected += result.affectedRows.toInt();

      // If returning is requested, fetch the inserted row
      if (plan.returning) {
        final pkValue = result.lastInsertID.toInt() > 0
            ? result.lastInsertID.toInt()
            : _extractPrimaryKeyFromRow(plan.definition, row);
        Map<String, Object?>? fetchedRow;
        if (pkValue != null) {
          fetchedRow = await _fetchRowByPrimaryKey(
            plan.definition,
            pkValue,
            connection,
          );
        } else {
          // Fall back to fetching by unique columns
          fetchedRow = await _fetchRowByUniqueColumns(
            plan.definition,
            uniqueColumns,
            selectors,
            connection,
          );
        }
        if (fetchedRow != null) {
          returnedRows.add(fetchedRow);
        }
      }
    }
    return MutationResult(
      affectedRows: affected,
      returnedRows: plan.returning && returnedRows.isNotEmpty
          ? returnedRows
          : null,
    );
  }

  /// Extracts primary key value from a mutation row
  Object? _extractPrimaryKeyFromRow(
    ModelDefinition<OrmEntity> definition,
    MutationRow row,
  ) {
    try {
      final pkField = definition.fields.firstWhere((f) => f.isPrimaryKey);
      return row.values[pkField.columnName];
    } catch (_) {
      return null;
    }
  }

  /// Fetches a single row by unique columns
  Future<Map<String, Object?>?> _fetchRowByUniqueColumns(
    ModelDefinition<OrmEntity> definition,
    List<String> uniqueColumns,
    List<Object?> values,
    MySQLConnection connection,
  ) async {
    try {
      final table = _tableIdentifier(definition);
      final whereClause = uniqueColumns
          .map((c) => '${_quote(c)} = ?')
          .join(' AND ');

      final sql = 'SELECT * FROM $table WHERE $whereClause LIMIT 1';
      final stmt = await connection.prepare(sql);
      final result = await stmt.execute(normalizeMySqlParameters(values));
      await stmt.deallocate();

      if (result.rows.isEmpty) return null;
      final columns = result.cols.toList(growable: false);
      return _decodeRow(result.rows.first, columns);
    } catch (_) {
      return null;
    }
  }

  List<_JsonUpdateTemplate> _jsonUpdateTemplates(MutationRow row) {
    if (row.jsonUpdates.isEmpty) {
      return const <_JsonUpdateTemplate>[];
    }
    final templates = <_JsonUpdateTemplate>[];
    for (final clause in row.jsonUpdates) {
      final resolved = _quote(clause.column);
      final compiled = clause.patch
          ? _grammar.compileJsonPatch(clause.column, resolved, clause.value)
          : _grammar.compileJsonUpdate(
              clause.column,
              resolved,
              clause.path,
              clause.value,
            );
      templates.add(
        _JsonUpdateTemplate(
          column: clause.column,
          path: clause.path,
          sql: compiled.sql,
          resolvedColumn: resolved,
          patch: clause.patch,
        ),
      );
    }
    return templates;
  }

  void _validateJsonUpdateShape(
    List<_JsonUpdateTemplate> templates,
    List<JsonUpdateClause> clauses,
  ) {
    if (templates.isEmpty) {
      return;
    }
    if (templates.length != clauses.length) {
      throw StateError(
        'All mutation rows must provide ${templates.length} JSON update clauses.',
      );
    }
    for (var i = 0; i < templates.length; i++) {
      final template = templates[i];
      final clause = clauses[i];
      if (template.column != clause.column ||
          template.path != clause.path ||
          template.patch != clause.patch) {
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

    final uniques = uniqueColumns.toSet();

    // Also exclude the primary key from UPDATE columns when:
    // 1. We're not conflicting on the PK (uniqueBy is on different columns)
    // 2. This prevents overwriting an existing auto-increment ID with null/0
    final pkColumn = plan.definition.primaryKeyField?.columnName;
    final excludeFromUpdate = <String>{...uniques};
    if (pkColumn != null && !uniques.contains(pkColumn)) {
      excludeFromUpdate.add(pkColumn);
    }

    return insertColumns.where((c) => !excludeFromUpdate.contains(c)).toList();
  }

  /// Extracts the primary key value for an upserted row
  /// Returns the PK value if available, null otherwise
  Future<Object?> _extractPrimaryKeyForUpsert(
    _MySqlMutationShape shape,
    IResultSet result,
    List<Object?> parameters,
    int rowIndex,
  ) async {
    if (shape.definition == null) return null;

    try {
      final pkField = shape.definition!.fields.firstWhere(
        (f) => f.isPrimaryKey,
      );
      final pkColumnName = pkField.columnName;

      // If lastInsertID > 0, it was an INSERT
      if (result.lastInsertID.toInt() > 0) {
        return result.lastInsertID.toInt();
      }

      // Otherwise it was an UPDATE, extract PK from the row data
      // The PK should be in the parameters corresponding to the row
      if (shape.plan != null && rowIndex < shape.plan!.rows.length) {
        final row = shape.plan!.rows[rowIndex];
        return row.values[pkColumnName];
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  /// Fetches a single row by primary key
  Future<Map<String, Object?>?> _fetchRowByPrimaryKey(
    ModelDefinition<OrmEntity> definition,
    Object pkValue,
    MySQLConnection connection,
  ) async {
    try {
      final pkField = definition.fields.firstWhere((f) => f.isPrimaryKey);
      final table = _tableIdentifier(definition);
      final pkColumn = _quote(pkField.columnName);

      final sql = 'SELECT * FROM $table WHERE $pkColumn = ? LIMIT 1';
      final stmt = await connection.prepare(sql);
      final result = await stmt.execute(normalizeMySqlParameters([pkValue]));
      await stmt.deallocate();

      if (result.rows.isEmpty) return null;
      final columns = result.cols.toList(growable: false);
      return _decodeRow(result.rows.first, columns);
    } catch (_) {
      return null;
    }
  }

  Future<MySQLConnection> _connection() async {
    if (_closed) {
      throw StateError('MySqlDriverAdapter has already been closed.');
    }
    if (_primaryHandle == null) {
      final handle =
          await _connections.open(_config) as ConnectionHandle<MySQLConnection>;
      _primaryHandle = handle;
    }
    return _primaryHandle!.client;
  }

  Future<IResultSet> _executeStatement(
    String sql,
    List<Object?> parameters,
  ) async {
    final connection = await _connection();
    if (parameters.isEmpty) {
      return connection.execute(sql);
    }

    final normalized = normalizeMySqlParameters(parameters);
    final stmt = await connection.prepare(sql);
    try {
      return await stmt.execute(normalized);
    } finally {
      await stmt.deallocate();
    }
  }

  List<Map<String, Object?>> _collectRows(IResultSet result) =>
      _rowIterable(result).toList(growable: false);

  Iterable<Map<String, Object?>> _rowIterable(IResultSet result) sync* {
    IResultSet? current = result;
    while (current != null) {
      final columns = current.cols.toList(growable: false);
      for (final row in current.rows) {
        yield _decodeRow(row, columns);
      }
      current = current.next;
    }
  }

  Map<String, Object?> _decodeRow(
    ResultSetRow row,
    List<ResultSetColumn> columns,
  ) {
    final typed = Map<String, Object?>.from(row.typedAssoc());
    final types = <String, int>{
      for (final column in columns) column.name: column.type.intVal,
    };
    // Preserve column casing from the driver so fields map correctly.
    return typed.map((key, value) {
      return MapEntry(
        key.toString(),
        _decodeResultValue(value, types[key.toString()]),
      );
    });
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
    final escaped = identifier.replaceAll('`', '``');
    return '`$escaped`';
  }

  String _whereClause(Map<String, Object?> keys) {
    if (keys.isEmpty) {
      throw StateError('Mutation requires keys for WHERE clause.');
    }
    return keys.keys.map((c) => '${_quote(c)} = ?').join(' AND ');
  }

  Future<Set<String>> _primaryKeyColumns(String table, {String? schema}) async {
    final effectiveSchema = schema ?? _getCurrentDatabase() ?? 'test';
    final rows = await queryRaw(
      'SELECT kcu.column_name '
      'FROM information_schema.table_constraints tc '
      'JOIN information_schema.key_column_usage kcu '
      ' ON tc.constraint_name = kcu.constraint_name '
      ' AND tc.table_schema = kcu.table_schema '
      "WHERE tc.constraint_type = 'PRIMARY KEY' AND tc.table_name = ? AND tc.table_schema = ? "
      'ORDER BY kcu.ordinal_position',
      [table, effectiveSchema],
    );
    return rows
        .map((row) => row['column_name'] as String?)
        .where((name) => name != null)
        .cast<String>()
        .toSet();
  }

  List<String> _splitColumns(String? value) {
    if (value == null || value.isEmpty) {
      return const [];
    }
    return value.split(',').map((part) => part.trim()).toList(growable: false);
  }

  bool _containsText(Object? source, String needle) {
    if (source == null) return false;
    return source.toString().toLowerCase().contains(needle);
  }

  bool _asBool(Object? value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is num) return value != 0;
    return value.toString() == '1';
  }

  int? _asInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is BigInt) return value.toInt();
    return int.tryParse(value.toString());
  }

  Object? _valueForColumn(Map<String, Object?> row, String column) {
    if (row.containsKey(column)) {
      return row[column];
    }
    final normalized = column.toLowerCase();
    for (final entry in row.entries) {
      if (entry.key.toLowerCase() == normalized) {
        return entry.value;
      }
    }
    return null;
  }

  String? _stringValue(Map<String, Object?> row, String column) {
    final value = _valueForColumn(row, column);
    if (value == null) return null;
    if (value is String) return value;
    return value.toString();
  }

  String _formatPreviewSql(String sql, int parameterCount) {
    final buffer = StringBuffer();
    var index = 0;
    for (var i = 0; i < sql.length; i++) {
      final char = sql[i];
      if (char == '?') {
        index++;
        buffer
          ..write(':p')
          ..write(index);
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

/// Adapter wrapper that mirrors Laravel's `MariaDbConnection`.
class MariaDbDriverAdapter extends MySqlDriverAdapter {
  MariaDbDriverAdapter.custom({required super.config, super.connections})
    : super.custom(driverName: 'mariadb', isMariaDb: true);

  factory MariaDbDriverAdapter.fromUrl(
    String url, {
    ConnectionFactory? connections,
  }) => MariaDbDriverAdapter.custom(
    config: DatabaseConfig(driver: 'mariadb', options: {'url': url}),
    connections: connections,
  );

  factory MariaDbDriverAdapter.insecureLocal({
    String database = 'orm_test',
    String username = 'root',
    String? password,
    int port = 3306,
    String host = '127.0.0.1',
    String? timezone,
    ConnectionFactory? connections,
  }) => MariaDbDriverAdapter.custom(
    config: DatabaseConfig(
      driver: 'mariadb',
      options: {
        'host': host,
        'port': port,
        'database': database,
        'username': username,
        if (password != null) 'password': password,
        if (timezone != null) 'timezone': timezone,
      },
    ),
    connections: connections,
  );
}

class _MySqlMutationShape {
  const _MySqlMutationShape({
    required this.sql,
    required this.parameterSets,
    this.isInsert = false,
    this.isUpsert = false,
    this.definition,
    this.returning = false,
    this.plan,
  });

  final String sql;
  final List<List<Object?>> parameterSets;
  final bool isInsert;
  final bool isUpsert;
  final ModelDefinition<OrmEntity>? definition;
  final bool returning;
  final MutationPlan? plan;

  static _MySqlMutationShape empty() =>
      const _MySqlMutationShape(sql: '<no-op>', parameterSets: []);
}

String _assignmentRhs(String sql) {
  final index = sql.indexOf('=');
  if (index == -1) {
    return sql;
  }
  return sql.substring(index + 1).trim();
}

List<Object?> normalizeMySqlParameters(List<Object?> values) =>
    values.map(_normalizeMySqlValue).toList(growable: false);

Object? _normalizeMySqlValue(Object? value) {
  if (value == null) return null;
  if (value is bool) return value ? 1 : 0;
  if (value is DateTime) return _formatDateTime(value);
  if (value is Duration) return _formatDurationAsTime(value);
  if (value is BigInt) return value.toInt();
  if (value is Decimal) return value.toString();
  if (value is UuidValue) return value.toString();
  if (value is MySqlGeometry) return value.bytes;
  if (value is MySqlBitString) return value.bytes;
  if (value is Uint8List) return value;
  if (value is Iterable) {
    return value.map(_normalizeMySqlValue).toList();
  }
  return value;
}

String _formatDateTime(DateTime value) {
  final utc = value.toUtc();
  final buffer = StringBuffer()
    ..write(_padNumber(utc.year, 4))
    ..write('-')
    ..write(_padNumber(utc.month, 2))
    ..write('-')
    ..write(_padNumber(utc.day, 2))
    ..write(' ')
    ..write(_padNumber(utc.hour, 2))
    ..write(':')
    ..write(_padNumber(utc.minute, 2))
    ..write(':')
    ..write(_padNumber(utc.second, 2))
    ..write('.')
    ..write(_padNumber(utc.millisecond * 1000 + utc.microsecond, 6));
  return buffer.toString();
}

String _padNumber(int value, int width) => value.toString().padLeft(width, '0');

final _integerStringPattern = RegExp(r'^[+-]?\d+$');
final _zeroFractionPattern = RegExp(r'^[+-]?\d+\.0+$');

const int _mysqlColumnTypeDecimal = 0;
const int _mysqlColumnTypeTinyBlob = 249;
const int _mysqlColumnTypeMediumBlob = 250;
const int _mysqlColumnTypeLongBlob = 251;
const int _mysqlColumnTypeBlob = 252;
const int _mysqlColumnTypeJson = 245;
const int _mysqlColumnTypeNewDecimal = 246;

Object? _decodeResultValue(Object? value, [int? columnType]) {
  if (value == null) return null;
  if (value is String) {
    if (columnType == _mysqlColumnTypeJson) {
      final trimmed = value.trim();
      final looksLikeJson = trimmed.startsWith('{') || trimmed.startsWith('[');
      if (looksLikeJson) {
        try {
          final decoded = jsonDecode(trimmed);
          if (decoded is Map || decoded is List) {
            return decoded;
          }
        } catch (_) {
          // Fall back to the raw string.
        }
      }
    }
    if (columnType == _mysqlColumnTypeDecimal ||
        columnType == _mysqlColumnTypeNewDecimal) {
      final trimmed = value.trim();
      if (_integerStringPattern.hasMatch(trimmed)) {
        return int.tryParse(trimmed) ?? value;
      }
      if (_zeroFractionPattern.hasMatch(trimmed)) {
        final integerPart = trimmed.split('.').first;
        return int.tryParse(integerPart) ?? value;
      }
    }
    return value;
  }
  if (value is Uint8List) {
    final canContainJson =
        columnType == _mysqlColumnTypeJson ||
        columnType == _mysqlColumnTypeBlob ||
        columnType == _mysqlColumnTypeLongBlob ||
        columnType == _mysqlColumnTypeMediumBlob ||
        columnType == _mysqlColumnTypeTinyBlob;
    if (canContainJson) {
      try {
        final decodedText = utf8.decode(value).trim();
        final looksLikeJson =
            decodedText.startsWith('{') || decodedText.startsWith('[');
        if (looksLikeJson) {
          final decoded = jsonDecode(decodedText);
          if (decoded is Map || decoded is List) {
            return decoded;
          }
        }
      } catch (_) {
        // Fall back to raw bytes.
      }
    }
    return value;
  }
  if (value is List<int>) {
    return _decodeResultValue(Uint8List.fromList(value), columnType);
  }
  return value;
}

String _formatDurationAsTime(Duration value) {
  final negative = value.isNegative;
  final microsTotal = value.inMicroseconds.abs();
  final secondsTotal = microsTotal ~/ 1000000;
  final micros = microsTotal % 1000000;

  final hours = secondsTotal ~/ 3600;
  final minutes = (secondsTotal % 3600) ~/ 60;
  final seconds = secondsTotal % 60;

  final buffer = StringBuffer();
  if (negative) buffer.write('-');
  buffer
    ..write(hours.toString().padLeft(2, '0'))
    ..write(':')
    ..write(minutes.toString().padLeft(2, '0'))
    ..write(':')
    ..write(seconds.toString().padLeft(2, '0'));
  if (micros != 0) {
    buffer
      ..write('.')
      ..write(micros.toString().padLeft(6, '0'));
  }
  return buffer.toString();
}
