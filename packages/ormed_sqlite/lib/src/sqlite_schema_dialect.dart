import 'package:ormed/migrations.dart';
import 'package:ormed/ormed.dart' show DriverException;

/// Generates SQLite-compatible SQL for schema mutations.
class SqliteSchemaDialect extends SchemaDialect {
  const SqliteSchemaDialect();

  @override
  String get driverName => 'sqlite';

  @override
  List<SchemaStatement> compileMutation(SchemaMutation mutation) {
    switch (mutation.operation) {
      case SchemaMutationOperation.createTable:
        return _compileCreateTable(mutation.blueprint!);
      case SchemaMutationOperation.alterTable:
        return _compileAlterTable(mutation.blueprint!);
      case SchemaMutationOperation.dropTable:
        return [SchemaStatement(_dropTableSql(mutation.dropOptions!))];
      case SchemaMutationOperation.renameTable:
        return [SchemaStatement(_renameTableSql(mutation.rename!))];
      case SchemaMutationOperation.rawSql:
        return [
          SchemaStatement(mutation.sql!, parameters: mutation.parameters),
        ];
      case SchemaMutationOperation.createDatabase:
      case SchemaMutationOperation.dropDatabase:
        // SQLite uses file operations, not SQL, for database management.
        // These mutations are no-ops in the dialect and handled by the driver directly if needed.
        return [];
      default:
        throw UnsupportedError(
          'Unsupported schema mutation operation: ${mutation.operation}',
        );
    }
  }

  List<SchemaStatement> _compileCreateTable(TableBlueprint blueprint) {
    final columnSql = <String>[];
    for (final column in blueprint.columns) {
      if (column.kind == ColumnCommandKind.drop) continue;
      final definition = column.definition;
      if (definition == null) {
        throw StateError('Column ${column.name} is missing a definition.');
      }
      columnSql.add(_columnDefinitionSql(definition));
    }

    final constraints = <String>[];
    for (final indexCommand in blueprint.indexes) {
      final definition = indexCommand.definition;
      if (definition == null) continue;
      if (definition.type == IndexType.primary) {
        final isAutoIncrement =
            definition.columns.length == 1 &&
            blueprint.columns.any(
              (c) =>
                  c.name == definition.columns.first &&
                  (c.definition?.autoIncrement ?? false),
            );
        if (!isAutoIncrement) {
          constraints.add(_primaryKeyConstraint(definition));
        }
      }
    }

    for (final foreignCommand in blueprint.foreignKeys) {
      final definition = foreignCommand.definition;
      if (definition == null) continue;
      constraints.add(_foreignKeyConstraint(definition));
    }

    final segments = [...columnSql, ...constraints];

    final buffer = StringBuffer('CREATE ');
    if (blueprint.temporary) buffer.write('TEMPORARY ');
    buffer
      ..write('TABLE ${_tableNameFromBlueprint(blueprint)} (\n')
      ..write(segments.map((line) => '  $line').join(',\n'))
      ..write('\n)');

    final statements = <SchemaStatement>[SchemaStatement(buffer.toString())];

    for (final indexCommand in blueprint.indexes) {
      final definition = indexCommand.definition;
      if (definition == null || definition.type == IndexType.primary) continue;
      // Pass unquoted table name - _indexStatements will quote it
      statements.addAll(_indexStatements(blueprint.table, definition));
    }

    return statements;
  }

  List<SchemaStatement> _compileAlterTable(TableBlueprint blueprint) {
    final statements = <SchemaStatement>[];
    final tableName = _tableNameFromBlueprint(blueprint);

    for (final column in blueprint.columns) {
      switch (column.kind) {
        case ColumnCommandKind.add:
          final definition = column.definition;
          if (definition == null) {
            throw StateError('Column ${column.name} is missing a definition.');
          }
          statements.add(
            SchemaStatement(
              'ALTER TABLE $tableName ADD COLUMN ${_columnDefinitionSql(definition)}',
            ),
          );
        case ColumnCommandKind.alter:
          throw UnsupportedError('SQLite cannot ALTER COLUMN ${column.name}.');
        case ColumnCommandKind.drop:
          statements.add(
            SchemaStatement(
              'ALTER TABLE $tableName DROP COLUMN ${_quote(column.name)}',
            ),
          );
      }
    }

    for (final rename in blueprint.renamedColumns) {
      statements.add(
        SchemaStatement(
          'ALTER TABLE $tableName RENAME COLUMN ${_quote(rename.from)} TO ${_quote(rename.to)}',
        ),
      );
    }

    for (final indexCommand in blueprint.indexes) {
      switch (indexCommand.kind) {
        case IndexCommandKind.add:
          final definition = indexCommand.definition;
          if (definition == null) continue;
          if (definition.type == IndexType.primary) {
            throw DriverException(
              driver: driverName,
              operation: 'alter_table_add_primary_key',
              message: 'SQLite cannot add a primary key after table creation.',
              hint:
                  'Use schema.create() for new tables or rebuild the table to add a primary key.',
            );
          }
          // Pass unquoted table name - _indexStatements will quote it
          statements.addAll(_indexStatements(blueprint.table, definition));
        case IndexCommandKind.drop:
          // Pass unquoted table name - _dropIndexArtifacts will quote it
          statements.addAll(
            _dropIndexArtifacts(blueprint.table, indexCommand.name),
          );
      }
    }

    if (blueprint.foreignKeys.isNotEmpty) {
      throw UnsupportedError(
        'SQLite cannot alter foreign keys after table creation.',
      );
    }

    return statements;
  }

  String _dropTableSql(DropTableOptions options) {
    final buffer = StringBuffer('DROP TABLE ');
    if (options.ifExists) buffer.write('IF EXISTS ');
    buffer.write(_quote(options.table));
    // SQLite ignores CASCADE on DROP TABLE; we intentionally omit it to keep SQL valid.
    return buffer.toString();
  }

  String _renameTableSql(RenameTableOptions options) {
    return 'ALTER TABLE ${_quote(options.from)} RENAME TO ${_quote(options.to)}';
  }

  List<SchemaStatement> _indexStatements(
    String table,
    IndexDefinition definition,
  ) {
    switch (definition.type) {
      case IndexType.unique:
      case IndexType.regular:
        final prefix = definition.type == IndexType.unique ? 'UNIQUE ' : '';
        final columns = definition.raw
            ? definition.columns.join(', ')
            : definition.columns.map(_quote).join(', ');
        return [
          SchemaStatement(
            'CREATE ${prefix}INDEX ${_quote(definition.name)} '
            'ON ${_quote(table)} ($columns)',
          ),
        ];
      case IndexType.fullText:
        return _fullTextStatements(table, definition);
      case IndexType.spatial:
        return _spatialIndexStatements(table, definition);
      case IndexType.primary:
        throw StateError('PRIMARY indexes handled separately.');
    }
  }

  List<SchemaStatement> _fullTextStatements(
    String table,
    IndexDefinition definition,
  ) {
    if (definition.raw) {
      throw StateError(
        'SQLite fullText indexes do not support raw expressions.',
      );
    }
    if (definition.columns.isEmpty) {
      throw StateError('fullText indexes require at least one column.');
    }
    final base = _artifactBaseName(table, definition.name);
    final virtualTable = _quote('${base}_fts');
    final columnList = definition.columns.map(_quote).join(', ');
    final newValues = definition.columns
        .map((column) => 'new.${_quote(column)}')
        .join(', ');
    final oldRowid = 'old.rowid';
    final options = _sqliteDriverSection(definition, 'fts');
    final optionClauses = <String>[];
    final tokenizer = options?['tokenizer'] as String?;
    final prefixSizes = (options?['prefixes'] as List?)?.cast<int>();
    if (tokenizer != null && tokenizer.isNotEmpty) {
      optionClauses.add('tokenize=$tokenizer');
    }
    if (prefixSizes != null && prefixSizes.isNotEmpty) {
      optionClauses.add("prefix='${prefixSizes.join(' ')}'");
    }
    final optionsSql = optionClauses.isEmpty
        ? ''
        : ', ${optionClauses.join(', ')}';
    final statements = <SchemaStatement>[
      SchemaStatement(
        'CREATE VIRTUAL TABLE $virtualTable USING fts5($columnList$optionsSql)',
      ),
      SchemaStatement(
        'INSERT INTO $virtualTable(rowid, $columnList) '
        'SELECT rowid, $columnList FROM ${_quote(table)}',
      ),
    ];
    statements.addAll(
      _ftsTriggers(table, base, virtualTable, columnList, newValues, oldRowid),
    );
    return statements;
  }

  List<SchemaStatement> _spatialIndexStatements(
    String table,
    IndexDefinition definition,
  ) {
    if (definition.raw) {
      throw StateError(
        'SQLite spatial indexes do not support raw expressions.',
      );
    }
    final base = _artifactBaseName(table, definition.name);
    final virtualTable = _quote('${base}_rtree');
    final options = _sqliteDriverSection(definition, 'spatial');
    final boundingColumns = (options?['boundingColumns'] as List?)
        ?.cast<String>();
    final maintainSync = options?['maintainSync'] as bool? ?? true;
    final rtreeColumns = (boundingColumns != null && boundingColumns.isNotEmpty)
        ? boundingColumns
        : definition.columns;
    if (rtreeColumns.isEmpty) {
      throw StateError('spatialIndex requires at least one column.');
    }
    final columnList = rtreeColumns.map(_quote).join(', ');
    final newValues = rtreeColumns
        .map((column) => 'new.${_quote(column)}')
        .join(', ');
    final statements = <SchemaStatement>[
      SchemaStatement(
        'CREATE VIRTUAL TABLE $virtualTable USING rtree('
        'rowid, $columnList)',
      ),
      SchemaStatement(
        'INSERT INTO $virtualTable(rowid, $columnList) '
        'SELECT rowid, $columnList FROM ${_quote(table)}',
      ),
    ];
    if (maintainSync) {
      statements.addAll(
        _rtreeTriggers(table, base, virtualTable, columnList, newValues),
      );
    }
    return statements;
  }

  Iterable<SchemaStatement> _ftsTriggers(
    String table,
    String base,
    String virtualTable,
    String columnList,
    String newValues,
    String oldRowid,
  ) sync* {
    final insertTrigger = _quote('${base}_fts_ai');
    final deleteTrigger = _quote('${base}_fts_ad');
    final updateTrigger = _quote('${base}_fts_au');
    final tableName = _quote(table);
    yield SchemaStatement(
      'CREATE TRIGGER $insertTrigger AFTER INSERT ON $tableName '
      'BEGIN INSERT INTO $virtualTable(rowid, $columnList) '
      'VALUES (new.rowid, $newValues); END',
    );
    yield SchemaStatement(
      'CREATE TRIGGER $deleteTrigger AFTER DELETE ON $tableName '
      'BEGIN DELETE FROM $virtualTable WHERE rowid = $oldRowid; END',
    );
    yield SchemaStatement(
      'CREATE TRIGGER $updateTrigger AFTER UPDATE ON $tableName '
      'BEGIN DELETE FROM $virtualTable WHERE rowid = $oldRowid; '
      'INSERT INTO $virtualTable(rowid, $columnList) '
      'VALUES (new.rowid, $newValues); END',
    );
  }

  Iterable<SchemaStatement> _rtreeTriggers(
    String table,
    String base,
    String virtualTable,
    String columnList,
    String newValues,
  ) sync* {
    final insertTrigger = _quote('${base}_rtree_ai');
    final deleteTrigger = _quote('${base}_rtree_ad');
    final updateTrigger = _quote('${base}_rtree_au');
    final tableName = _quote(table);
    yield SchemaStatement(
      'CREATE TRIGGER $insertTrigger AFTER INSERT ON $tableName '
      'BEGIN INSERT OR REPLACE INTO $virtualTable(rowid, $columnList) '
      'VALUES (new.rowid, $newValues); END',
    );
    yield SchemaStatement(
      'CREATE TRIGGER $deleteTrigger AFTER DELETE ON $tableName '
      'BEGIN DELETE FROM $virtualTable WHERE rowid = old.rowid; END',
    );
    yield SchemaStatement(
      'CREATE TRIGGER $updateTrigger AFTER UPDATE ON $tableName '
      'BEGIN DELETE FROM $virtualTable WHERE rowid = old.rowid; '
      'INSERT OR REPLACE INTO $virtualTable(rowid, $columnList) '
      'VALUES (new.rowid, $newValues); END',
    );
  }

  List<SchemaStatement> _dropIndexArtifacts(String table, String indexName) {
    final base = _artifactBaseName(table, indexName);
    final statements = <SchemaStatement>[
      SchemaStatement('DROP INDEX IF EXISTS ${_quote(indexName)}'),
      SchemaStatement('DROP TABLE IF EXISTS ${_quote('${base}_fts')}'),
      SchemaStatement('DROP TABLE IF EXISTS ${_quote('${base}_rtree')}'),
    ];
    for (final suffix in const [
      'fts_ai',
      'fts_ad',
      'fts_au',
      'rtree_ai',
      'rtree_ad',
      'rtree_au',
    ]) {
      statements.add(
        SchemaStatement('DROP TRIGGER IF EXISTS ${_quote('${base}_$suffix')}'),
      );
    }
    return statements;
  }

  Map<String, Object?>? _sqliteDriverSection(
    IndexDefinition definition,
    String section,
  ) {
    final sqliteOptions = definition.driverOptions['sqlite'];
    if (sqliteOptions == null) return null;
    final value = sqliteOptions[section];
    if (value is Map<String, Object?>) return value;
    return null;
  }

  String _artifactBaseName(String table, String indexName) {
    final raw = '${table}_$indexName'.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_');
    final collapsed = raw.replaceAll(RegExp(r'_+'), '_');
    return collapsed.isEmpty ? 'idx' : collapsed;
  }

  String _columnDefinitionSql(ColumnDefinition definition) {
    final override = definition.overrideForDriver(driverName);
    final buffer = StringBuffer()
      ..write(
        '${_quote(definition.name)} ${_resolvedType(definition, override)}',
      );

    if (!definition.nullable) buffer.write(' NOT NULL');
    if (definition.unique) buffer.write(' UNIQUE');
    if (definition.primaryKey && definition.autoIncrement) {
      buffer.write(' PRIMARY KEY');
    }
    if (definition.autoIncrement) buffer.write(' AUTOINCREMENT');
    final defaultValue = override?.defaultValue ?? definition.defaultValue;
    if (defaultValue != null) {
      buffer.write(' DEFAULT ${_defaultExpression(defaultValue)}');
    }
    final collation = override?.collation ?? definition.collation;
    if (collation != null && collation.isNotEmpty) {
      buffer.write(' COLLATE $collation');
    }
    if (definition.virtualAs != null || definition.storedAs != null) {
      final expression = definition.virtualAs ?? definition.storedAs;
      final storage = definition.storedAs != null ? 'STORED' : 'VIRTUAL';
      buffer
        ..write(' GENERATED ALWAYS AS (${expression!}) ')
        ..write(storage);
    }
    return buffer.toString();
  }

  String _primaryKeyConstraint(IndexDefinition definition) {
    final columns = definition.columns.map(_quote).join(', ');
    return 'PRIMARY KEY ($columns)';
  }

  String _foreignKeyConstraint(ForeignKeyDefinition definition) {
    final columns = definition.columns.map(_quote).join(', ');
    final referenced = definition.referencedColumns.map(_quote).join(', ');
    final buffer = StringBuffer()
      ..write(
        'FOREIGN KEY ($columns) REFERENCES ${_quote(definition.referencedTable)} ($referenced)',
      );
    if (definition.onDelete != ReferenceAction.noAction) {
      buffer.write(' ON DELETE ${_referentialAction(definition.onDelete)}');
    }
    if (definition.onUpdate != ReferenceAction.noAction) {
      buffer.write(' ON UPDATE ${_referentialAction(definition.onUpdate)}');
    }
    return buffer.toString();
  }

  String _referentialAction(ReferenceAction action) {
    return switch (action) {
      ReferenceAction.cascade => 'CASCADE',
      ReferenceAction.restrict => 'RESTRICT',
      ReferenceAction.setNull => 'SET NULL',
      ReferenceAction.noAction => 'NO ACTION',
    };
  }

  String _mapType(ColumnType type) {
    switch (type.name) {
      case ColumnTypeName.bigInteger:
      case ColumnTypeName.integer:
      case ColumnTypeName.smallInteger:
      case ColumnTypeName.mediumInteger:
      case ColumnTypeName.tinyInteger:
        return 'INTEGER';
      case ColumnTypeName.boolean:
        return 'INTEGER';
      case ColumnTypeName.binary:
        return 'BLOB';
      case ColumnTypeName.string:
      case ColumnTypeName.text:
      case ColumnTypeName.longText:
      case ColumnTypeName.json:
      case ColumnTypeName.jsonb:
      case ColumnTypeName.enumType:
      case ColumnTypeName.setType:
      case ColumnTypeName.date:
      case ColumnTypeName.time:
        if (type.length != null) {
          return 'VARCHAR(${type.length})';
        }
        return 'TEXT';
      case ColumnTypeName.dateTime:
        return 'TEXT';
      case ColumnTypeName.decimal:
        final precision = type.precision ?? 10;
        final scale = type.scale ?? 0;
        return 'NUMERIC($precision, $scale)';
      case ColumnTypeName.float:
      case ColumnTypeName.doublePrecision:
        return 'REAL';
      case ColumnTypeName.uuid:
        return 'TEXT';
      case ColumnTypeName.geometry:
      case ColumnTypeName.geography:
      case ColumnTypeName.vector:
        return 'TEXT';
      case ColumnTypeName.custom:
        return type.customName ?? 'TEXT';
    }
  }

  String _resolvedType(
    ColumnDefinition definition,
    ColumnDriverOverride? override,
  ) {
    if (override?.sqlType != null) {
      return override!.sqlType!;
    }
    return _mapType(override?.type ?? definition.type);
  }

  String _defaultExpression(ColumnDefault value) {
    if (value.useCurrentTimestamp) return 'CURRENT_TIMESTAMP';
    if (value.expression != null) return value.expression!;
    final literal = value.value;
    if (literal is num || literal is bool) {
      if (literal is bool) {
        return literal ? '1' : '0';
      }
      return literal.toString();
    }
    if (literal == null) return 'NULL';
    return "'${_escapeString(literal.toString())}'";
  }

  String _escapeString(String value) => value.replaceAll("'", "''");

  String _quote(String identifier) {
    final escaped = identifier.replaceAll('"', '""');
    return '"$escaped"';
  }

  String _tableName(String table) {
    // SQLite doesn't support real schemas like PostgreSQL/MySQL
    // Schema parameter is ignored - SQLite uses attached databases instead
    if (table.contains('.')) {
      return table.split('.').map(_quote).join('.');
    }
    return _quote(table);
  }

  String _tableNameFromBlueprint(TableBlueprint blueprint) {
    // Ignore blueprint.schema for SQLite - it doesn't support schemas
    return _tableName(blueprint.table);
  }

  String _schemaOrDefault(String? schema) =>
      schema?.isNotEmpty == true ? schema! : 'main';

  String _schemaLiteral(String? schema) =>
      "'${_escapeString(_schemaOrDefault(schema))}'";

  String _tableLiteral(String table) => "'${_escapeString(table)}'";

  // ========== Schema Introspection ==========

  @override
  String? compileSchemas({String? schema}) {
    return "select name, file as path, name = 'main' as \"default\", file "
        'from pragma_database_list order by name';
  }

  @override
  String? compileTables({String? schema}) {
    final filter = schema != null && schema.isNotEmpty
        ? ' tl.schema = ${_schemaLiteral(schema)} and'
        : '';
    return 'select tl.name as name, tl.schema as schema, tl.type as type '
        'from pragma_table_list as tl where'
        '$filter tl.type in (\'table\', \'virtual\') '
        "and tl.name not like 'sqlite\\_%' escape '\\' "
        'order by tl.schema, tl.name';
  }

  @override
  String? compileViews({String? schema}) {
    final targetSchema = _schemaOrDefault(schema);
    final master = '${_quote(targetSchema)}.sqlite_master';
    return 'select name, ${_schemaLiteral(schema)} as schema, '
        'sql as definition, sql from $master '
        "where type = 'view' order by name";
  }

  @override
  String? compileColumns(String table, {String? schema}) {
    final targetSchema = _schemaLiteral(schema);
    final targetTable = _tableLiteral(table);
    return 'select name, type, cid, "notnull", dflt_value, pk, hidden, '
        'not "notnull" as "nullable", dflt_value as "default", '
        'pk as "primary", hidden as "extra" '
        'from pragma_table_xinfo($targetTable, $targetSchema) '
        'order by cid asc';
  }

  @override
  String? compileIndexes(String table, {String? schema}) {
    final targetTable = _tableLiteral(table);
    final targetSchema = _schemaLiteral(schema);
    return "select 'primary' as name, group_concat(col) as columns, 1 as \"unique\", "
        '1 as "primary", 0 as partial '
        'from (select name as col from pragma_table_xinfo('
        '$targetTable, $targetSchema) where pk > 0 order by pk, cid) '
        'group by name '
        'union select name, group_concat(col) as columns, "unique", '
        "origin = 'pk' as \"primary\", max(partial) as partial "
        'from (select il.*, ii.name as col from pragma_index_list('
        '$targetTable, $targetSchema) il, pragma_index_info(il.name, '
        '$targetSchema) ii order by il.seq, ii.seqno) '
        'group by name, "unique", "primary"';
  }

  @override
  String? compileForeignKeys(String table, {String? schema}) {
    final targetSchema = _schemaLiteral(schema);
    final targetTable = _tableLiteral(table);
    return 'select group_concat("from") as columns, '
        '$targetSchema as foreign_schema, "table" as foreign_table, '
        'group_concat("to") as foreign_columns, on_update, on_delete '
        'from (select * from pragma_foreign_key_list('
        '$targetTable, $targetSchema) order by id desc, seq) '
        'group by id, "table", on_update, on_delete';
  }

  // ========== Database Management ==========

  @override
  String? compileCreateDatabase(String name, Map<String, Object?>? options) {
    // SQLite is file-based, handled at adapter level
    return null;
  }

  @override
  String? compileDropDatabaseIfExists(String name) {
    // SQLite is file-based, handled at adapter level
    return null;
  }

  @override
  String? compileListDatabases() {
    // SQLite doesn't have a database catalog concept in the traditional sense
    return null;
  }

  // ========== Foreign Key Constraint Management ==========

  @override
  String? compileEnableForeignKeyConstraints() {
    return 'PRAGMA foreign_keys = ON';
  }

  @override
  String? compileDisableForeignKeyConstraints() {
    return 'PRAGMA foreign_keys = OFF';
  }
}
