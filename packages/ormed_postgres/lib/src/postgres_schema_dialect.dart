import 'package:ormed/migrations.dart';

/// Generates PostgreSQL-compatible SQL for schema mutations.
class PostgresSchemaDialect extends SchemaDialect {
  const PostgresSchemaDialect();

  @override
  String get driverName => 'postgres';

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
        final name = mutation.documentPayload!['name'] as String;
        final options =
            mutation.documentPayload!['options'] as Map<String, Object?>?;
        final sql = compileCreateDatabase(name, options);
        return sql != null ? [SchemaStatement(sql)] : [];
      case SchemaMutationOperation.dropDatabase:
        final name = mutation.documentPayload!['name'] as String;
        final ifExists =
            mutation.documentPayload!['ifExists'] as bool? ?? false;
        final sql = ifExists
            ? compileDropDatabaseIfExists(name)
            : 'DROP DATABASE ${_quote(name)}';
        return sql != null ? [SchemaStatement(sql)] : [];
      default:
        throw UnimplementedError(
          'Schema mutation operation '
          '${mutation.operation} is not supported by PostgresSchemaDialect.',
        );
    }
  }

  List<SchemaStatement> _compileCreateTable(TableBlueprint blueprint) {
    final buffer = StringBuffer(
      'CREATE TABLE ${_tableNameFromBlueprint(blueprint)} (',
    );

    final indexCommands = blueprint.indexes;
    final primaryDefinitions = <String, IndexDefinition>{};

    for (final index in indexCommands) {
      final definition = index.definition;
      if (index.kind != IndexCommandKind.add ||
          definition == null ||
          definition.type != IndexType.primary) {
        continue;
      }
      final key = definition.columns.join('|');
      primaryDefinitions.putIfAbsent(key, () => definition);
    }

    final primaryColumns = primaryDefinitions.values
        .expand((definition) => definition.columns)
        .toSet();

    final columnSql = <String>[];
    for (final column in blueprint.columns) {
      if (column.kind == ColumnCommandKind.drop || column.definition == null) {
        continue;
      }
      final definition = column.definition!;
      final inlinePrimaryKey =
          !(definition.primaryKey && primaryColumns.contains(definition.name));
      columnSql.add(
        _columnDefinitionSql(definition, inlinePrimaryKey: inlinePrimaryKey),
      );
    }

    final constraints = <String>[];
    for (final definition in primaryDefinitions.values) {
      constraints.add(_primaryKeyConstraint(definition));
    }

    for (final foreign in blueprint.foreignKeys) {
      final definition = foreign.definition;
      if (definition == null) continue;
      constraints.add(_foreignKeyConstraint(definition));
    }

    final segments = [...columnSql, ...constraints];
    buffer
      ..write('\n  ')
      ..write(segments.join(',\n  '))
      ..write('\n)');

    final statements = <SchemaStatement>[SchemaStatement(buffer.toString())];

    for (final index in indexCommands) {
      final definition = index.definition;
      if (definition == null || definition.type == IndexType.primary) continue;
      statements.add(
        SchemaStatement(_createIndexSqlForBlueprint(blueprint, definition)),
      );
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
          if (definition == null) continue;
          statements.add(
            SchemaStatement(
              'ALTER TABLE $tableName '
              'ADD COLUMN ${_columnDefinitionSql(definition)}',
            ),
          );
        case ColumnCommandKind.alter:
          final definition = column.definition;
          if (definition == null) continue;
          statements.addAll(_alterColumnStatements(tableName, definition));
        case ColumnCommandKind.drop:
          statements.add(
            SchemaStatement(
              'ALTER TABLE $tableName '
              'DROP COLUMN ${_quote(column.name)}',
            ),
          );
      }
    }

    for (final rename in blueprint.renamedColumns) {
      statements.add(
        SchemaStatement(
          'ALTER TABLE $tableName '
          'RENAME COLUMN ${_quote(rename.from)} TO ${_quote(rename.to)}',
        ),
      );
    }

    for (final index in blueprint.indexes) {
      final definition = index.definition;
      switch (index.kind) {
        case IndexCommandKind.add:
          if (definition == null) continue;
          statements.add(
            SchemaStatement(_createIndexSqlForBlueprint(blueprint, definition)),
          );
        case IndexCommandKind.drop:
          statements.add(
            SchemaStatement('DROP INDEX IF EXISTS ${_quote(index.name)}'),
          );
      }
    }

    for (final foreign in blueprint.foreignKeys) {
      switch (foreign.kind) {
        case ForeignKeyCommandKind.add:
          final definition = foreign.definition;
          if (definition == null) continue;
          statements.add(
            SchemaStatement(
              'ALTER TABLE $tableName '
              'ADD ${_foreignKeyConstraint(definition)}',
            ),
          );
        case ForeignKeyCommandKind.drop:
          statements.add(
            SchemaStatement(
              'ALTER TABLE $tableName '
              'DROP CONSTRAINT IF EXISTS ${_quote(foreign.name)}',
            ),
          );
      }
    }

    return statements;
  }

  String _dropTableSql(DropTableOptions options) {
    final buffer = StringBuffer('DROP TABLE ');
    if (options.ifExists) buffer.write('IF EXISTS ');
    buffer.write(_quote(options.table));
    if (options.cascade) buffer.write(' CASCADE');
    return buffer.toString();
  }

  String _renameTableSql(RenameTableOptions options) {
    return 'ALTER TABLE ${_quote(options.from)} RENAME TO ${_quote(options.to)}';
  }

  // ignore: unused_element
  String _createIndexSql(String table, IndexDefinition definition) {
    switch (definition.type) {
      case IndexType.unique:
      case IndexType.regular:
      case IndexType.primary:
        final prefix = definition.type == IndexType.unique ? 'UNIQUE ' : '';
        final columns = definition.raw
            ? definition.columns.join(', ')
            : definition.columns.map(_quote).join(', ');
        return 'CREATE ${prefix}INDEX ${_quote(definition.name)} '
            'ON ${_quote(table)} ($columns)';
      case IndexType.fullText:
        final expression = _fullTextExpression(definition);
        return 'CREATE INDEX ${_quote(definition.name)} ON ${_quote(table)} '
            'USING GIN ($expression)';
      case IndexType.spatial:
        final columns = definition.columns.map(_quote).join(', ');
        return 'CREATE INDEX ${_quote(definition.name)} ON ${_quote(table)} '
            'USING GIST ($columns)';
    }
  }

  String _createIndexSqlForBlueprint(
    TableBlueprint blueprint,
    IndexDefinition definition,
  ) {
    final tableName = _tableNameFromBlueprint(blueprint);
    switch (definition.type) {
      case IndexType.unique:
      case IndexType.regular:
      case IndexType.primary:
        final prefix = definition.type == IndexType.unique ? 'UNIQUE ' : '';
        final columns = definition.raw
            ? definition.columns.join(', ')
            : definition.columns.map(_quote).join(', ');
        return 'CREATE ${prefix}INDEX ${_quote(definition.name)} '
            'ON $tableName ($columns)';
      case IndexType.fullText:
        final expression = _fullTextExpression(definition);
        return 'CREATE INDEX ${_quote(definition.name)} ON $tableName '
            'USING GIN ($expression)';
      case IndexType.spatial:
        final columns = definition.columns.map(_quote).join(', ');
        return 'CREATE INDEX ${_quote(definition.name)} ON $tableName '
            'USING GIST ($columns)';
    }
  }

  String _fullTextExpression(IndexDefinition definition) {
    if (definition.columns.length == 1 && !definition.raw) {
      final column = _quote(definition.columns.first);
      return "to_tsvector('simple'::regconfig, COALESCE($column::text, ''))";
    }
    final segments = definition.columns
        .map((column) {
          final value = definition.raw ? column : _quote(column);
          final needsCast = definition.raw ? value : '$value::text';
          return "COALESCE($needsCast, '')";
        })
        .join(" || ' ' || ");
    return "to_tsvector('simple'::regconfig, $segments)";
  }

  List<SchemaStatement> _alterColumnStatements(
    String table,
    ColumnDefinition definition,
  ) {
    final override = definition.overrideForDriver(driverName);
    final statements = <SchemaStatement>[];
    statements.add(
      SchemaStatement(
        'ALTER TABLE ${_quote(table)} '
        'ALTER COLUMN ${_quote(definition.name)} TYPE '
        '${_resolvedType(definition, override)}',
      ),
    );
    final nullabilityClause = definition.nullable
        ? 'ALTER COLUMN ${_quote(definition.name)} DROP NOT NULL'
        : 'ALTER COLUMN ${_quote(definition.name)} SET NOT NULL';
    statements.add(
      SchemaStatement('ALTER TABLE ${_quote(table)} $nullabilityClause'),
    );
    final defaultValue = override?.defaultValue ?? definition.defaultValue;
    if (defaultValue != null) {
      statements.add(
        SchemaStatement(
          'ALTER TABLE ${_quote(table)} '
          'ALTER COLUMN ${_quote(definition.name)} '
          'SET DEFAULT ${_defaultExpression(defaultValue)}',
        ),
      );
    }
    return statements;
  }

  String _columnDefinitionSql(
    ColumnDefinition definition, {
    bool inlinePrimaryKey = true,
  }) {
    final override = definition.overrideForDriver(driverName);
    final buffer = StringBuffer()
      ..write(
        '${_quote(definition.name)} ${_resolvedType(definition, override)}',
      );

    if (!definition.nullable) buffer.write(' NOT NULL');
    if (definition.primaryKey && inlinePrimaryKey) buffer.write(' PRIMARY KEY');
    if (definition.unique) buffer.write(' UNIQUE');
    if (definition.autoIncrement) {
      buffer.write(' GENERATED BY DEFAULT AS IDENTITY');
    }
    final defaultValue = override?.defaultValue ?? definition.defaultValue;
    if (defaultValue != null) {
      buffer.write(' DEFAULT ${_defaultExpression(defaultValue)}');
    } else if (definition.useCurrentOnUpdate) {
      buffer.write(' DEFAULT CURRENT_TIMESTAMP');
    }
    final collation = override?.collation ?? definition.collation;
    if (collation != null && collation.isNotEmpty) {
      buffer.write(' COLLATE $collation');
    }
    if (definition.virtualAs != null || definition.storedAs != null) {
      final expression = definition.virtualAs ?? definition.storedAs;
      buffer
        ..write(' GENERATED ALWAYS AS (${expression!}) ')
        ..write('STORED');
    }
    if (definition.comment != null && definition.comment!.isNotEmpty) {
      buffer.write(' /* ${definition.comment} */');
    }
    return buffer.toString();
  }

  String _primaryKeyConstraint(IndexDefinition definition) {
    final columns = definition.columns.map(_quote).join(', ');
    if (definition.name.isNotEmpty) {
      return 'CONSTRAINT ${_quote(definition.name)} PRIMARY KEY ($columns)';
    }
    return 'PRIMARY KEY ($columns)';
  }

  String _foreignKeyConstraint(ForeignKeyDefinition definition) {
    final columns = definition.columns.map(_quote).join(', ');
    final referenced = definition.referencedColumns.map(_quote).join(', ');
    final buffer = StringBuffer()
      ..write(
        'CONSTRAINT ${_quote(definition.name)} '
        'FOREIGN KEY ($columns) REFERENCES ${_quote(definition.referencedTable)} '
        '($referenced)',
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
        return 'BIGINT';
      case ColumnTypeName.binary:
        return 'BYTEA';
      case ColumnTypeName.boolean:
        return 'BOOLEAN';
      case ColumnTypeName.date:
        return 'DATE';
      case ColumnTypeName.time:
        return type.timezoneAware
            ? 'TIME WITH TIME ZONE'
            : 'TIME WITHOUT TIME ZONE';
      case ColumnTypeName.dateTime:
        return type.timezoneAware
            ? 'TIMESTAMP WITH TIME ZONE'
            : 'TIMESTAMP WITHOUT TIME ZONE';
      case ColumnTypeName.decimal:
        final precision = type.precision ?? 10;
        final scale = type.scale ?? 0;
        return 'DECIMAL($precision, $scale)';
      case ColumnTypeName.doublePrecision:
        return 'DOUBLE PRECISION';
      case ColumnTypeName.float:
        return 'REAL';
      case ColumnTypeName.integer:
        return 'INTEGER';
      case ColumnTypeName.smallInteger:
        return 'SMALLINT';
      case ColumnTypeName.mediumInteger:
        return 'INTEGER';
      case ColumnTypeName.tinyInteger:
        return 'SMALLINT';
      case ColumnTypeName.json:
        return 'JSONB';
      case ColumnTypeName.jsonb:
        return 'JSONB';
      case ColumnTypeName.string:
        final length = type.length ?? 255;
        return 'VARCHAR($length)';
      case ColumnTypeName.text:
        return 'TEXT';
      case ColumnTypeName.longText:
        return 'TEXT';
      case ColumnTypeName.enumType:
      case ColumnTypeName.setType:
        return 'TEXT';
      case ColumnTypeName.uuid:
        return 'UUID';
      case ColumnTypeName.geometry:
        return 'GEOMETRY';
      case ColumnTypeName.geography:
        return 'GEOGRAPHY';
      case ColumnTypeName.vector:
        final dimensions = type.length;
        if (dimensions != null && dimensions > 0) {
          return 'VECTOR($dimensions)';
        }
        return 'VECTOR';
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
    final type = override?.type ?? definition.type;
    return _mapType(type);
  }

  String _defaultExpression(ColumnDefault defaultValue) {
    if (defaultValue.useCurrentTimestamp) {
      return 'CURRENT_TIMESTAMP';
    }
    if (defaultValue.expression != null) {
      return defaultValue.expression!;
    }
    final value = defaultValue.value;
    if (value == null) return 'NULL';
    if (value is num || value is bool) return value.toString();
    return '\'${value.toString().replaceAll("'", "''")}\'';
  }

  String _quote(String identifier) {
    final escaped = identifier.replaceAll('"', '""');
    return '"$escaped"';
  }

  String _tableName(String table, {String? schema}) {
    if (schema != null && schema.isNotEmpty) {
      return '${_quote(schema)}.${_quote(table)}';
    }
    if (table.contains('.')) {
      return table.split('.').map(_quote).join('.');
    }
    return _quote(table);
  }

  String _tableNameFromBlueprint(TableBlueprint blueprint) {
    return _tableName(blueprint.table, schema: blueprint.schema);
  }

  // ========== Database Management ==========

  @override
  String? compileCreateDatabase(String name, Map<String, Object?>? options) {
    final parts = <String>['CREATE DATABASE ${_quote(name)}'];

    if (options?['owner'] != null) {
      parts.add('OWNER ${_quote(options!['owner'] as String)}');
    }
    if (options?['template'] != null) {
      parts.add('TEMPLATE ${_quote(options!['template'] as String)}');
    }
    if (options?['encoding'] != null) {
      final encoding = options!['encoding'] as String;
      parts.add("ENCODING '$encoding'");
    }
    if (options?['locale'] != null) {
      final locale = options!['locale'] as String;
      parts.add("LOCALE '$locale'");
    }
    if (options?['lc_collate'] != null) {
      final lcCollate = options!['lc_collate'] as String;
      parts.add("LC_COLLATE '$lcCollate'");
    }
    if (options?['lc_ctype'] != null) {
      final lcCtype = options!['lc_ctype'] as String;
      parts.add("LC_CTYPE '$lcCtype'");
    }
    if (options?['tablespace'] != null) {
      parts.add('TABLESPACE ${_quote(options!['tablespace'] as String)}');
    }
    if (options?['connection_limit'] != null) {
      parts.add('CONNECTION LIMIT ${options!['connection_limit']}');
    }

    return parts.join(' ');
  }

  @override
  String? compileDropDatabaseIfExists(String name) {
    return 'DROP DATABASE IF EXISTS ${_quote(name)}';
  }

  @override
  String? compileListDatabases() {
    // Mirror Laravel behavior: ignore templates and the default postgres database
    return "SELECT datname FROM pg_database WHERE datistemplate = false AND datname <> 'postgres' ORDER BY datname";
  }

  // ========== Schema Introspection ==========

  @override
  String? compileSchemas({String? schema}) {
    final filter =
        "nspname NOT LIKE 'pg_%' AND nspname <> 'information_schema'";
    final clause = schema == null ? '' : ' AND nspname = ?';
    return 'SELECT nspname AS name, pg_get_userbyid(nspowner) AS owner, '
        'nspname = current_schema() AS is_default '
        'FROM pg_namespace '
        'WHERE $filter$clause '
        'ORDER BY nspname';
  }

  @override
  String? compileTables({String? schema}) {
    final filter = schema == null ? '' : ' AND table_schema = ?';
    return 'SELECT table_schema, table_name, table_type '
        'FROM information_schema.tables '
        "WHERE table_type = 'BASE TABLE' "
        "AND table_schema NOT IN ('pg_catalog', 'information_schema')"
        '$filter '
        'ORDER BY table_schema, table_name';
  }

  @override
  String? compileViews({String? schema}) {
    final filter = schema == null ? '' : ' AND table_schema = ?';
    return 'SELECT table_schema, table_name, view_definition '
        'FROM information_schema.views '
        "WHERE table_schema NOT IN ('pg_catalog', 'information_schema')"
        '$filter '
        'ORDER BY table_schema, table_name';
  }

  @override
  String? compileColumns(String table, {String? schema}) {
    final filter = schema == null ? '' : ' AND c.table_schema = ?';
    return 'SELECT c.table_schema, c.table_name, c.column_name, '
        'COALESCE(format_type(attr.atttypid, attr.atttypmod), c.data_type) '
        'AS data_type, '
        'c.character_maximum_length, c.numeric_precision, c.numeric_scale, '
        'c.is_nullable, c.column_default, c.is_identity, '
        'c.is_generated, c.generation_expression, '
        'pgd.description AS comment '
        'FROM information_schema.columns c '
        'LEFT JOIN pg_catalog.pg_class cls '
        '  ON cls.relname = c.table_name '
        'LEFT JOIN pg_catalog.pg_namespace ns '
        '  ON ns.nspname = c.table_schema AND ns.oid = cls.relnamespace '
        'LEFT JOIN pg_catalog.pg_attribute attr '
        '  ON attr.attrelid = cls.oid AND attr.attname = c.column_name '
        'LEFT JOIN pg_catalog.pg_description pgd '
        '  ON pgd.objoid = attr.attrelid AND pgd.objsubid = attr.attnum '
        'WHERE c.table_name = ?'
        '$filter '
        'ORDER BY c.ordinal_position';
  }

  @override
  String? compileIndexes(String table, {String? schema}) {
    final filter = schema == null ? '' : ' AND ns.nspname = ?';
    return 'SELECT ns.nspname AS schema, tbl.relname AS table_name, '
        'idx.relname AS index_name, i.indisunique AS unique, '
        'i.indisprimary AS primary, am.amname AS method, '
        'pg_get_expr(i.indpred, i.indrelid) AS where_clause, '
        'array_remove(array_agg(att.attname ORDER BY cols.ordinality), NULL) AS columns '
        'FROM pg_index i '
        'JOIN pg_class idx ON idx.oid = i.indexrelid '
        'JOIN pg_class tbl ON tbl.oid = i.indrelid '
        'JOIN pg_namespace ns ON ns.oid = tbl.relnamespace '
        'JOIN pg_am am ON am.oid = idx.relam '
        'LEFT JOIN LATERAL unnest(i.indkey) WITH ORDINALITY AS cols(attnum, ordinality) '
        '  ON true '
        'LEFT JOIN pg_attribute att '
        '  ON att.attrelid = tbl.oid AND att.attnum = cols.attnum '
        'WHERE tbl.relname = ?'
        '$filter '
        'GROUP BY ns.nspname, tbl.relname, idx.relname, i.indisunique, '
        'i.indisprimary, am.amname, pg_get_expr(i.indpred, i.indrelid) '
        'ORDER BY idx.relname';
  }

  @override
  String? compileForeignKeys(String table, {String? schema}) {
    final filter = schema == null ? '' : ' AND tc.table_schema = ?';
    return 'SELECT tc.constraint_name, tc.table_schema, '
        'kcu.column_name, ccu.table_schema AS referenced_schema, '
        'ccu.table_name AS referenced_table, '
        'ccu.column_name AS referenced_column, '
        'rc.update_rule, rc.delete_rule, kcu.ordinal_position '
        'FROM information_schema.table_constraints tc '
        'JOIN information_schema.key_column_usage kcu '
        '  ON kcu.constraint_name = tc.constraint_name '
        ' AND kcu.constraint_schema = tc.constraint_schema '
        'JOIN information_schema.constraint_column_usage ccu '
        '  ON ccu.constraint_name = tc.constraint_name '
        ' AND ccu.constraint_schema = tc.constraint_schema '
        'JOIN information_schema.referential_constraints rc '
        '  ON rc.constraint_name = tc.constraint_name '
        ' AND rc.constraint_schema = tc.constraint_schema '
        "WHERE tc.constraint_type = 'FOREIGN KEY' "
        '  AND tc.table_name = ?'
        '$filter '
        'ORDER BY tc.constraint_name, kcu.ordinal_position';
  }

  // ========== Foreign Key Constraint Management ==========

  @override
  String? compileEnableForeignKeyConstraints() {
    // PostgreSQL doesn't have session-level FK disable
    // Must use ALTER TABLE ... ENABLE TRIGGER ALL on each table
    return null; // Handled at adapter level
  }

  @override
  String? compileDisableForeignKeyConstraints() {
    return null; // Handled at adapter level
  }
}
