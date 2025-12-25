import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:ormed/src/model/model.dart';
import 'package:ormed/src/query/plan/join_definition.dart';
import 'package:ormed/src/query/plan/join_type.dart';

import '../contracts.dart';
import '../driver/driver.dart';
import 'json_path.dart';
import 'query_plan.dart';

/// Result of compiling a [QueryPlan] into SQL + bindings.
class QueryCompilation {
  /// Creates a new [QueryCompilation].
  QueryCompilation({required this.sql, List<Object?>? bindings})
    : bindings = List.unmodifiable(bindings ?? const []);

  /// The compiled SQL statement.
  final String sql;

  /// The bindings for the SQL statement.
  final List<Object?> bindings;

  /// Converts this compilation to a [StatementPreview].
  StatementPreview toPreview() => StatementPreview(
    payload: SqlStatementPayload(
      sql: sql,
      parameters: bindings.toList(growable: false),
    ),
  );
}

/// Result of compiling a [JsonWhereClause] into SQL + bindings.
class JsonPredicateCompilation {
  /// Creates a new [JsonPredicateCompilation].
  JsonPredicateCompilation({required this.sql, List<Object?>? bindings})
    : bindings = List.unmodifiable(bindings ?? const []);

  /// The compiled SQL statement.
  final String sql;

  /// The bindings for the SQL statement.
  final List<Object?> bindings;
}

/// Result of compiling a JSON update into SQL + bindings.
class JsonUpdateCompilation {
  /// Creates a new [JsonUpdateCompilation].
  JsonUpdateCompilation({required this.sql, List<Object?>? bindings})
    : bindings = List.unmodifiable(bindings ?? const []);

  /// The compiled SQL statement.
  final String sql;

  /// The bindings for the SQL statement.
  final List<Object?> bindings;
}

/// Result of compiling a [DateWhereClause] into SQL + bindings.
class DatePredicateCompilation {
  /// Creates a new [DatePredicateCompilation].
  DatePredicateCompilation({required this.sql, List<Object?>? bindings})
    : bindings = List.unmodifiable(bindings ?? const []);

  /// The compiled SQL statement.
  final String sql;

  /// The bindings for the SQL statement.
  final List<Object?> bindings;
}

/// Base grammar capable of compiling [QueryPlan] objects into SQL strings.
///
/// This class provides a base for implementing SQL grammars for different
/// database dialects.
abstract class QueryGrammar {
  const QueryGrammar();

  /// Compiles a [QueryPlan] into a [QueryCompilation].
  ///
  /// Example:
  /// ```dart
  /// final plan = QueryPlan(
  ///   definition: userDefinition,
  ///   selects: ['id', 'name'],
  ///   limit: 10,
  /// );
  /// final compilation = grammar.compileSelect(plan);
  /// print(compilation.sql); // SELECT "id", "name" FROM "users" LIMIT ?
  /// print(compilation.bindings); // [10]
  /// ```
  QueryCompilation compileSelect(QueryPlan plan) {
    final builder = _SelectCompilation(plan, this);
    var sql = builder.sql;
    final bindings = builder.bindings.toList(growable: true);

    if (plan.unions.isNotEmpty) {
      final unionCompilation = _compileUnions(plan);
      final wrapped = wrapUnion(sql);
      sql = unionCompilation.sql.isEmpty
          ? wrapped
          : '$wrapped ${unionCompilation.sql}'.trim();
      bindings.addAll(unionCompilation.bindings);
    }

    final groupLimit = builder.activeGroupLimit;
    if (groupLimit != null) {
      final tableAlias = wrapIdentifier(_SelectCompilation.groupTableAlias);
      final rowAlias = wrapIdentifier(_SelectCompilation.groupRowAlias);
      final rowIdentifier = '$tableAlias.$rowAlias';
      final placeholder = parameterPlaceholder();
      final buffer = StringBuffer('SELECT $tableAlias.* FROM (')
        ..write(sql)
        ..write(') AS ')
        ..write(tableAlias)
        ..write(' WHERE ')
        ..write('$rowIdentifier <= $placeholder');
      bindings.add(groupLimit.limit);
      if (groupLimit.offset != null) {
        buffer
          ..write(' AND ')
          ..write('$rowIdentifier > $placeholder');
        bindings.add(groupLimit.offset);
      }
      buffer
        ..write(' ORDER BY ')
        ..write(rowIdentifier);
      sql = buffer.toString();
    }
    return QueryCompilation(sql: sql, bindings: bindings);
  }

  _UnionCompilation _compileUnions(QueryPlan plan) {
    final sql = StringBuffer();
    final bindings = <Object?>[];
    for (final union in plan.unions) {
      if (sql.isNotEmpty) {
        sql.write(' ');
      }
      final compilation = compileSelect(union.plan);
      sql
        ..write(union.all ? 'UNION ALL ' : 'UNION ')
        ..write(wrapUnion(compilation.sql));
      bindings.addAll(compilation.bindings);
    }
    return _UnionCompilation(sql: sql.toString().trim(), bindings: bindings);
  }

  /// Wraps an identifier in quotes.
  ///
  /// Example:
  /// ```dart
  /// print(grammar.wrapIdentifier('users')); // "users"
  /// ```
  String wrapIdentifier(String value) => value;

  /// Returns an expression for case-insensitive comparisons.
  ///
  /// Example:
  /// ```dart
  /// print(grammar.caseInsensitiveExpression('name')); // LOWER(name)
  /// ```
  String caseInsensitiveExpression(String expression) => 'LOWER($expression)';

  /// Returns the placeholder for a query parameter.
  ///
  /// Example:
  /// ```dart
  /// print(grammar.parameterPlaceholder()); // ?
  /// ```
  String parameterPlaceholder() => '?';

  /// Compiles a `WHERE NULL` clause.
  String compileWhereNull(String column, String resolvedColumn) =>
      '$resolvedColumn IS NULL';

  /// Compiles a `WHERE NOT NULL` clause.
  String compileWhereNotNull(String column, String resolvedColumn) =>
      '$resolvedColumn IS NOT NULL';

  /// Compiles a random ordering expression.
  String compileRandom([num? seed]) => 'RANDOM()';

  /// Compiles a `LIMIT` clause.
  String? compileLimit(int? limit) {
    if (limit == null) return null;
    return 'LIMIT ${parameterPlaceholder()}';
  }

  /// Compiles an `OFFSET` clause.
  String? compileOffset(int? offset, {required bool limitProvided}) {
    if (offset == null) return null;
    return 'OFFSET ${parameterPlaceholder()}';
  }

  /// Compiles a lock clause.
  String compileLock(String? clause) => clause ?? '';

  /// Compiles index hints.
  String compileIndexHints(List<IndexHint> hints) => '';

  /// Compiles the `SELECT` columns.
  String compileColumns(
    QueryPlan plan,
    String projections,
    List<String> distinctOnExpressions,
  ) {
    final buffer = StringBuffer('SELECT ');
    if (distinctOnExpressions.isNotEmpty && supportsDistinctOn) {
      buffer
        ..write('DISTINCT ON (')
        ..write(distinctOnExpressions.join(', '))
        ..write(') ');
    } else if (plan.distinct || distinctOnExpressions.isNotEmpty) {
      buffer.write('DISTINCT ');
    }
    buffer.write(projections);
    return buffer.toString();
  }

  /// Whether the grammar supports DISTINCT ON expressions.
  bool get supportsDistinctOn => false;

  /// Allows grammars to include additional GROUP BY clauses when needed.
  Iterable<String> finalizeGroupByColumns(
    Iterable<String> groupByColumns,
    Iterable<String> hydrationColumns,
    QueryPlan plan,
  ) => groupByColumns;

  /// SQL used to retrieve the number of open connections, when supported.
  String? compileThreadCount() => null;

  /// Compiles a full-text search clause.
  String compileFullText(FullTextWhere clause) =>
      throw UnsupportedError('Full-text search is not supported.');

  /// Formats a column for a `LIKE` comparison.
  String formatLikeColumn(String column, {required bool caseInsensitive}) =>
      caseInsensitive ? caseInsensitiveExpression(column) : column;

  /// Formats a value for a `LIKE` comparison.
  String formatLikeValue(String value, {required bool caseInsensitive}) =>
      caseInsensitive ? caseInsensitiveExpression(value) : value;

  /// Returns the `LIKE` operator.
  String likeOperator({required bool caseInsensitive, required bool negated}) =>
      negated ? 'NOT LIKE' : 'LIKE';

  /// Prepares a binding for a `LIKE` comparison.
  Object? prepareLikeBinding(Object? value, {required bool caseInsensitive}) =>
      value;

  /// Wraps a `UNION` subquery.
  String wrapUnion(String sql) => '($sql)';

  /// Compiles a bitwise predicate.
  String compileBitwisePredicate(
    String column,
    String operator,
    String placeholder,
  ) => '($column $operator $placeholder)';

  /// Compiles a JSON value cast.
  String compileJsonValueCast(String placeholder) => placeholder;

  /// Compiles a JSON predicate.
  JsonPredicateCompilation compileJsonPredicate(
    JsonWhereClause clause,
    String resolvedColumn,
  ) => throw UnsupportedError('JSON predicates are not supported.');

  /// Compiles a JSON update.
  JsonUpdateCompilation compileJsonUpdate(
    String column,
    String resolvedColumn,
    String path,
    Object? value,
  ) => throw UnsupportedError('JSON updates are not supported.');

  /// Compiles a JSON patch.
  JsonUpdateCompilation compileJsonPatch(
    String column,
    String resolvedColumn,
    Object? value,
  ) => compileJsonUpdate(column, resolvedColumn, r'$', value);

  /// Compiles a date predicate.
  DatePredicateCompilation compileDatePredicate(
    DateWhereClause clause,
    String resolvedColumn,
  ) {
    if (!clause.targetsRoot) {
      throw UnsupportedError(
        'JSON date predicates are not supported for this grammar.',
      );
    }
    final lhs = compileDateComponentExpression(
      clause.component,
      resolvedColumn,
    );
    final sql = '$lhs ${clause.operator} ${parameterPlaceholder()}';
    return DatePredicateCompilation(sql: sql, bindings: [clause.value]);
  }

  /// Compiles a date component expression.
  @protected
  String compileDateComponentExpression(
    DateComponent component,
    String expression,
  ) {
    switch (component) {
      case DateComponent.date:
        return 'DATE($expression)';
      case DateComponent.day:
        return 'DAY($expression)';
      case DateComponent.month:
        return 'MONTH($expression)';
      case DateComponent.year:
        return 'YEAR($expression)';
      case DateComponent.time:
        return 'TIME($expression)';
    }
  }

  /// Checks if a column is a JSON selector.
  bool isJsonSelector(String column) => hasJsonSelector(column);

  /// Parses a JSON selector expression.
  @protected
  JsonSelector? parseJsonSelector(String column) =>
      parseJsonSelectorExpression(column);

  /// Wraps a JSON selector reference.
  @protected
  String wrapJsonSelectorReference(
    String columnReference,
    JsonSelector selector,
  ) => columnReference;

  /// Wraps a JSON boolean selector reference.
  @protected
  String wrapJsonBooleanSelectorReference(
    String columnReference,
    JsonSelector selector,
  ) => wrapJsonSelectorReference(columnReference, selector);

  /// Compiles a JSON boolean value placeholder.
  String compileJsonBooleanValuePlaceholder(String placeholder) => placeholder;

  /// Checks if the grammar supports a group limit.
  bool supportsGroupLimit(GroupLimit groupLimit) => true;

  /// Best-effort conversion of parameterized SQL into a string with bindings.
  String substituteBindingsIntoRawSql(String sql, List<Object?> bindings) {
    final values = bindings.map(_escapeBindingValue).toList(growable: true);
    final buffer = StringBuffer();
    var inLiteral = false;

    for (var i = 0; i < sql.length; i++) {
      final char = sql[i];
      final next = i + 1 < sql.length ? sql[i + 1] : null;
      final pair = next == null ? null : '$char$next';

      if (pair == "\\'" || pair == "''" || pair == '??') {
        buffer.write(pair);
        i++;
        continue;
      }

      if (char == "'") {
        inLiteral = !inLiteral;
        buffer.write(char);
        continue;
      }

      if (char == '?' && !inLiteral) {
        if (values.isEmpty) {
          buffer.write('?');
        } else {
          buffer.write(values.removeAt(0));
        }
        continue;
      }

      buffer.write(char);
    }

    return buffer.toString();
  }

  /// Returns the segments of a normalized JSON path.
  @protected
  List<String> jsonPathSegments(String normalizedPath) =>
      jsonPathSegments(normalizedPath);

  /// Join types supported by this grammar.
  Set<JoinType> get supportedJoinTypes => const {
    JoinType.inner,
    JoinType.left,
    JoinType.cross,
  };

  /// Whether the dialect supports `JOIN LATERAL`.
  bool get supportsLateralJoins => false;

  /// Validates a join definition.
  @protected
  void validateJoin(JoinDefinition join) {
    if (!supportedJoinTypes.contains(join.type)) {
      throw UnsupportedError('${join.type} is not supported by this grammar.');
    }
    if (join.isLateral && !supportsLateralJoins) {
      throw UnsupportedError('LATERAL joins are not supported.');
    }
  }

  /// Returns the name of an aggregate function.
  String aggregateName(AggregateFunction function) {
    switch (function) {
      case AggregateFunction.count:
        return 'COUNT';
      case AggregateFunction.sum:
        return 'SUM';
      case AggregateFunction.avg:
        return 'AVG';
      case AggregateFunction.min:
        return 'MIN';
      case AggregateFunction.max:
        return 'MAX';
    }
  }
}

class _SelectCompilation {
  _SelectCompilation(this.plan, this.grammar) {
    final rawGroupLimit = plan.groupLimit;
    _groupLimit =
        rawGroupLimit != null && grammar.supportsGroupLimit(rawGroupLimit)
        ? rawGroupLimit
        : null;
    final table = grammar.wrapIdentifier(
      _prefixedTableName(
        plan.definition.tableName,
        schema: plan.definition.schema,
      ),
    );
    final schema = plan.definition.schema;
    final qualified = schema == null || schema.isEmpty
        ? table
        : '${grammar.wrapIdentifier(schema)}.$table';
    if (plan.tableAlias != null && plan.tableAlias!.isNotEmpty) {
      final alias = grammar.wrapIdentifier(plan.tableAlias!);
      _fromClause = '$qualified AS $alias';
      _baseTable = alias;
    } else {
      _fromClause = qualified;
      _baseTable = qualified;
    }
    _sql = _compile();
  }

  static const String groupRowAlias = '__orm_row';
  static const String groupTableAlias = '__orm_group';

  final QueryPlan plan;
  final QueryGrammar grammar;
  final List<Object?> bindings = [];
  late final GroupLimit? _groupLimit;
  late final String _baseTable;
  late final String _fromClause;
  late final String _sql;
  int _aliasCounter = 0;
  List<String>? _orderExpressionsCache;
  List<String>? _distinctOnCache;
  List<String> _hydrationColumnNames = const [];

  static final RegExp _identifier = RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$');
  static final RegExp _qualifiedIdentifier = RegExp(
    r'^[A-Za-z_][A-Za-z0-9_]*(\.[A-Za-z_][A-Za-z0-9_]*)+$',
  );

  String get sql => _sql;

  GroupLimit? get activeGroupLimit => _groupLimit;

  String _compile() {
    if (_hasEmptyInClause(plan.filters)) {
      return 'SELECT 0 WHERE 1 = 0';
    }

    final projections = _selectClause();
    final selectClause = grammar.compileColumns(
      plan,
      projections,
      _distinctOnExpressions(),
    );
    final buffer = StringBuffer(selectClause)
      ..write(' FROM ')
      ..write(_fromClause);

    final indexHintsSql = grammar.compileIndexHints(plan.indexHints);
    if (indexHintsSql.isNotEmpty) {
      buffer
        ..write(' ')
        ..write(indexHintsSql);
    }

    _appendJoinClauses(buffer);

    final whereClause = _whereClause();
    if (whereClause != null) {
      buffer
        ..write(' WHERE ')
        ..write(whereClause);
    }

    final groupClause = _groupByClause();
    if (groupClause != null) {
      buffer
        ..write(' GROUP BY ')
        ..write(groupClause);
    }

    final havingClause = _havingClause();
    if (havingClause != null) {
      buffer
        ..write(' HAVING ')
        ..write(havingClause);
    }

    final orderClause = _orderClause();
    if (orderClause != null) {
      buffer
        ..write(' ORDER BY ')
        ..write(orderClause);
    }

    final limitSql = grammar.compileLimit(plan.limit);
    if (limitSql != null && limitSql.isNotEmpty) {
      buffer
        ..write(' ')
        ..write(limitSql);
      bindings.add(plan.limit);
    }
    final offsetSql = grammar.compileOffset(
      plan.offset,
      limitProvided: plan.limit != null,
    );
    if (offsetSql != null && offsetSql.isNotEmpty) {
      buffer
        ..write(' ')
        ..write(offsetSql);
      bindings.add(plan.offset);
    }

    final lockSql = grammar.compileLock(plan.lockClause);
    if (lockSql.isNotEmpty) {
      buffer
        ..write(' ')
        ..write(lockSql);
    }

    return buffer.toString();
  }

  void _appendJoinClauses(StringBuffer buffer) {
    if (plan.joins.isEmpty) {
      return;
    }
    for (final join in plan.joins) {
      grammar.validateJoin(join);
      buffer
        ..write(' ')
        ..write(_joinKeyword(join));
      if (join.isLateral) {
        buffer.write(' LATERAL');
      }
      buffer
        ..write(' ')
        ..write(_compileJoinTarget(join));
      final condition = _compileJoinConditions(join);
      if (condition != null && condition.isNotEmpty) {
        buffer
          ..write(' ON ')
          ..write(condition);
      } else if (join.type != JoinType.cross) {
        throw StateError('Join clauses require constraints unless CROSS JOIN.');
      }
    }
  }

  String _selectClause() {
    final projections = <String>[];
    final hasCustomProjection =
        plan.selects.isNotEmpty ||
        plan.rawSelects.isNotEmpty ||
        plan.aggregates.isNotEmpty;
    final requiresHydrationColumns =
        plan.selects.isNotEmpty || plan.rawSelects.isNotEmpty;
    final coveredColumns = <String>{
      ...plan.selects,
      for (final raw in plan.rawSelects)
        if (raw.alias != null && raw.alias!.isNotEmpty)
          raw.alias!
        else
          _rawSelectColumn(raw.sql) ?? '',
    }..removeWhere((column) => column.isEmpty);

    if (!hasCustomProjection) {
      if (plan.definition.fields.isEmpty) {
        projections.add('*');
      } else {
        projections.addAll(
          plan.definition.fields.map(
            (field) =>
                '${_qualifiedBaseColumn(field.columnName)} AS ${grammar.wrapIdentifier(field.columnName)}',
          ),
        );
      }
    } else if (plan.projectionOrder.isEmpty) {
      projections.addAll(plan.selects.map(grammar.wrapIdentifier));
      for (final raw in plan.rawSelects) {
        bindings.addAll(raw.bindings);
        final alias = raw.alias != null
            ? ' AS ${grammar.wrapIdentifier(raw.alias!)}'
            : '';
        projections.add('${raw.sql}$alias');
      }
    } else {
      for (final entry in plan.projectionOrder) {
        switch (entry.kind) {
          case ProjectionKind.column:
            final column = plan.selects[entry.index];
            projections.add(grammar.wrapIdentifier(column));
            break;
          case ProjectionKind.raw:
            final raw = plan.rawSelects[entry.index];
            bindings.addAll(raw.bindings);
            final alias = raw.alias != null
                ? ' AS ${grammar.wrapIdentifier(raw.alias!)}'
                : '';
            projections.add('${raw.sql}$alias');
            break;
        }
      }
    }

    for (final aggregate in plan.aggregates) {
      projections.add(_compileAggregate(aggregate));
    }

    for (final relationAggregate in plan.relationAggregates) {
      final expression = _relationAggregateExpression(relationAggregate);
      projections.add(
        '$expression AS ${grammar.wrapIdentifier(relationAggregate.alias)}',
      );
    }

    if (_groupLimit != null) {
      projections.add(_rowNumberProjection());
    }

    if (requiresHydrationColumns && !plan.disableAutoHydration) {
      final aggregateHydration = plan.groupBy.isNotEmpty;
      _hydrationColumnNames = const [];
      projections.addAll(
        _hydrationColumns(plan.definition, coveredColumns, aggregateHydration),
      );
    } else {
      _hydrationColumnNames = const [];
    }

    if (projections.isEmpty) {
      return '*';
    }

    return projections.join(', ');
  }

  String _qualifiedBaseColumn(String column) =>
      '$_baseTable.${grammar.wrapIdentifier(column)}';

  List<String> _hydrationColumns(
    ModelDefinition<OrmEntity> definition,
    Set<String> coveredColumns,
    bool aggregateExpressions,
  ) {
    if (definition.fields.isEmpty) {
      _hydrationColumnNames = const [];
      return const [];
    }
    final columns = <String>[];
    final names = <String>[];
    for (final field in definition.fields) {
      final column = field.columnName;
      if (coveredColumns.contains(column)) {
        continue;
      }
      names.add(column);
      columns.add(
        aggregateExpressions
            ? _aggregationExpression(column)
            : '${_qualifiedBaseColumn(column)} AS ${grammar.wrapIdentifier(column)}',
      );
    }
    if (columns.isEmpty) {
      _hydrationColumnNames = const [];
      return const [];
    }
    _hydrationColumnNames = aggregateExpressions ? const [] : names;
    return columns;
  }

  String _aggregationExpression(String column) {
    final expr = _qualifiedBaseColumn(column);
    return 'MIN($expr) AS ${grammar.wrapIdentifier(column)}';
  }

  String? _rawSelectColumn(String expression) {
    final trimmed = expression.trim();
    if (trimmed.isEmpty) return null;
    if (_identifier.hasMatch(trimmed)) {
      return trimmed;
    }
    if (_qualifiedIdentifier.hasMatch(trimmed)) {
      return trimmed.split('.').last;
    }
    return null;
  }

  String _joinKeyword(JoinDefinition join) {
    switch (join.type) {
      case JoinType.inner:
        return 'JOIN';
      case JoinType.left:
        return 'LEFT JOIN';
      case JoinType.right:
        return 'RIGHT JOIN';
      case JoinType.cross:
        return 'CROSS JOIN';
      case JoinType.straight:
        return 'STRAIGHT_JOIN';
    }
  }

  String _compileJoinTarget(JoinDefinition join) {
    if (join.target.isSubquery) {
      if (join.alias == null || join.alias!.isEmpty) {
        throw StateError('Subquery joins require an alias.');
      }
      bindings.addAll(join.target.bindings);
      final alias = grammar.wrapIdentifier(join.alias!);
      return '(${join.target.subquery}) AS $alias';
    }
    final table = join.target.table!;
    final formatted = _formatTableReference(table);
    if (join.alias != null && join.alias!.isNotEmpty) {
      final alias = grammar.wrapIdentifier(join.alias!);
      return '$formatted AS $alias';
    }
    return formatted;
  }

  String? _compileJoinConditions(JoinDefinition join) {
    if (join.conditions.isEmpty) {
      return null;
    }
    final buffer = StringBuffer();
    for (final condition in join.conditions) {
      final prefix = buffer.isEmpty
          ? ''
          : condition.boolean == PredicateLogicalOperator.and
          ? ' AND '
          : ' OR ';
      if (condition.isRaw) {
        buffer
          ..write(prefix)
          ..write('(')
          ..write(condition.rawSql)
          ..write(')');
        bindings.addAll(condition.bindings);
        continue;
      }
      if (condition.isColumnComparison) {
        final left = _formatJoinColumn(condition.left!);
        final right = _formatJoinColumn(condition.right!);
        buffer
          ..write(prefix)
          ..write('$left ${condition.operator ?? '='} $right');
        continue;
      }
      if (condition.isValueComparison) {
        final left = _formatJoinColumn(condition.left!);
        buffer
          ..write(prefix)
          ..write(
            '$left ${condition.operator ?? '='} ${grammar.parameterPlaceholder()}',
          );
        bindings.add(condition.value);
        continue;
      }
      throw StateError('Unsupported join condition.');
    }
    return buffer.toString();
  }

  String _formatJoinColumn(String column) {
    const basePrefix = 'base.';
    if (column.startsWith(basePrefix)) {
      final name = column.substring(basePrefix.length);
      return '$_baseTable.${grammar.wrapIdentifier(name)}';
    }
    if (column == 'base') {
      return _baseTable;
    }
    return _formatExpression(column);
  }

  String _formatTableReference(String table) {
    final resolved = _prefixedTableName(table);
    if (_qualifiedIdentifier.hasMatch(resolved)) {
      return resolved
          .split('.')
          .map((segment) => grammar.wrapIdentifier(segment))
          .join('.');
    }
    if (_identifier.hasMatch(resolved)) {
      return grammar.wrapIdentifier(resolved);
    }
    return resolved;
  }

  String _prefixedTableName(String table, {String? schema}) {
    final prefix = plan.tablePrefix;
    if (prefix == null || prefix.isEmpty) {
      return table;
    }
    if (schema != null && schema.isNotEmpty) {
      return table;
    }
    if (_qualifiedIdentifier.hasMatch(table)) {
      return table;
    }
    if (!_identifier.hasMatch(table)) {
      return table;
    }
    if (table.startsWith(prefix)) {
      return table;
    }
    return '$prefix$table';
  }

  String _qualifiedTable(ModelDefinition<OrmEntity> definition) {
    final table = grammar.wrapIdentifier(
      _prefixedTableName(definition.tableName, schema: definition.schema),
    );
    final schema = definition.schema;
    if (schema == null || schema.isEmpty) {
      return table;
    }
    return '${grammar.wrapIdentifier(schema)}.$table';
  }

  String _qualifiedPivotTable(String table) =>
      _formatTableReference(_prefixedTableName(table));

  String? _whereClause() {
    final clauses = <String>[];
    final predicateClause = _compilePredicate(
      plan.predicate,
      tableIdentifier: _baseTable,
    );
    if (predicateClause != null && predicateClause.isNotEmpty) {
      clauses.add(predicateClause);
    }
    final compiledFilters = plan.filters
        .where((filter) => filter.compile)
        .map(_filterExpression)
        .where((sql) => sql.isNotEmpty)
        .toList(growable: false);
    if (compiledFilters.isNotEmpty) {
      clauses.addAll(compiledFilters);
    }
    if (plan.fullTextWheres.isNotEmpty) {
      for (final clause in plan.fullTextWheres) {
        final sql = grammar.compileFullText(clause);
        if (sql.isEmpty) continue;
        clauses.add(sql);
        bindings.add(clause.value);
      }
    }
    if (plan.jsonWheres.isNotEmpty) {
      for (final clause in plan.jsonWheres) {
        final column = _resolvedColumnReference(clause.column, _baseTable);
        final compiled = grammar.compileJsonPredicate(clause, column);
        clauses.add(compiled.sql);
        bindings.addAll(compiled.bindings);
      }
    }
    if (plan.dateWheres.isNotEmpty) {
      for (final clause in plan.dateWheres) {
        final column = _resolvedColumnReference(clause.column, _baseTable);
        final compiled = grammar.compileDatePredicate(clause, column);
        clauses.add(compiled.sql);
        bindings.addAll(compiled.bindings);
      }
    }
    if (clauses.isEmpty) {
      return null;
    }
    return clauses.join(' AND ');
  }

  String? _groupByClause() {
    final columns = grammar.finalizeGroupByColumns(
      plan.groupBy,
      _hydrationColumnNames,
      plan,
    );
    final seen = <String>{};
    final values = <String>[];
    for (final column in columns) {
      if (column.isEmpty) {
        continue;
      }
      if (seen.add(column)) {
        values.add(column);
      }
    }
    if (values.isEmpty) {
      return null;
    }
    return values.map(grammar.wrapIdentifier).join(', ');
  }

  String? _havingClause() => _compilePredicate(
    plan.having,
    tableIdentifier: _baseTable,
    resolveAggregates: true,
  );

  String? _orderClause() {
    final clauses = _orderExpressions();
    if (clauses.isEmpty) {
      return null;
    }
    return clauses.join(', ');
  }

  List<String> _orderExpressions() {
    if (_orderExpressionsCache != null) {
      return _orderExpressionsCache!;
    }
    final clauses = <String>[];
    clauses.addAll(
      plan.orders.map((order) {
        final base = _columnReference(order.field, _baseTable);
        final expression = order.jsonSelector == null
            ? base
            : order.jsonSelector!.extractsText
            ? grammar.wrapJsonSelectorReference(base, order.jsonSelector!)
            : grammar.wrapJsonBooleanSelectorReference(
                base,
                order.jsonSelector!,
              );
        return '$expression ${order.descending ? 'DESC' : 'ASC'}';
      }),
    );
    for (final relationOrder in plan.relationOrders) {
      final aggregate = RelationAggregate(
        type: relationOrder.aggregateType,
        alias: _nextAlias('order'),
        path: relationOrder.path,
        where: relationOrder.where,
        distinct: relationOrder.distinct,
      );
      final expression = _relationAggregateExpression(aggregate);
      clauses.add('$expression ${relationOrder.descending ? 'DESC' : 'ASC'}');
    }
    if (plan.randomOrder) {
      clauses.add(grammar.compileRandom(plan.randomSeed));
    }
    return _orderExpressionsCache = clauses;
  }

  String _filterExpression(FilterClause clause) {
    final column = _resolvedColumnReference(clause.field, _baseTable);
    final placeholder = grammar.parameterPlaceholder();
    switch (clause.operator) {
      case FilterOperator.equals:
        bindings.add(clause.value);
        return '$column = $placeholder';
      case FilterOperator.greaterThan:
        bindings.add(clause.value);
        return '$column > $placeholder';
      case FilterOperator.greaterThanOrEqual:
        bindings.add(clause.value);
        return '$column >= $placeholder';
      case FilterOperator.lessThan:
        bindings.add(clause.value);
        return '$column < $placeholder';
      case FilterOperator.lessThanOrEqual:
        bindings.add(clause.value);
        return '$column <= $placeholder';
      case FilterOperator.contains:
        bindings.add('%${clause.value ?? ''}%');
        final formattedColumn = grammar.formatLikeColumn(
          column,
          caseInsensitive: false,
        );
        final formattedValue = grammar.formatLikeValue(
          placeholder,
          caseInsensitive: false,
        );
        final op = grammar.likeOperator(caseInsensitive: false, negated: false);
        return '$formattedColumn $op $formattedValue';
      case FilterOperator.inValues:
        final list = (clause.value as List?) ?? const [];
        if (list.isEmpty) {
          return '0 = 1';
        }
        bindings.addAll(list);
        final placeholders = List.filled(list.length, placeholder).join(', ');
        return '$column IN ($placeholders)';
      case FilterOperator.isNull:
        return grammar.compileWhereNull(clause.field, column);
      case FilterOperator.isNotNull:
        return grammar.compileWhereNotNull(clause.field, column);
    }
  }

  List<String> _distinctOnExpressions() {
    if (plan.distinctOn.isEmpty) {
      return const [];
    }
    if (_distinctOnCache != null) {
      return _distinctOnCache!;
    }
    final expressions = plan.distinctOn
        .map((clause) {
          final base = _columnReference(clause.field, _baseTable);
          final selector = clause.jsonSelector;
          if (selector == null) {
            return base;
          }
          return selector.extractsText
              ? grammar.wrapJsonSelectorReference(base, selector)
              : grammar.wrapJsonBooleanSelectorReference(base, selector);
        })
        .toList(growable: false);
    return _distinctOnCache = expressions;
  }

  String? _compilePredicate(
    QueryPredicate? predicate, {
    String? tableIdentifier,
    bool resolveAggregates = false,
  }) {
    if (predicate == null) {
      return null;
    }

    switch (predicate) {
      case BitwisePredicate():
        return _compileBitwisePredicate(predicate, tableIdentifier);
      case PredicateGroup():
        return _compilePredicateGroup(
          predicate,
          tableIdentifier: tableIdentifier,
          resolveAggregates: resolveAggregates,
        );
      case FieldPredicate():
        return _compileFieldPredicate(
          predicate,
          tableIdentifier,
          resolveAggregates: resolveAggregates,
        );
      case RawPredicate():
        bindings.addAll(predicate.bindings);
        return '(${predicate.sql})';
      case SubqueryPredicate():
        return _compileSubqueryPredicate(predicate);
      case RelationPredicate():
        final parentAlias = tableIdentifier ?? _baseTable;
        return _compileRelationPredicate(predicate, parentAlias);
    }
  }

  String _compileSubqueryPredicate(SubqueryPredicate predicate) {
    // For subqueries, disable auto-hydration to only select the specified columns
    final subqueryPlan = predicate.subquery.copyWith(
      disableAutoHydration: true,
    );

    // Compile the subquery
    final subqueryCompilation = _SelectCompilation(subqueryPlan, grammar);
    final subquerySql = subqueryCompilation._sql;

    // Add bindings from subquery
    bindings.addAll(subqueryCompilation.bindings);

    if (predicate.type == SubqueryType.whereIn) {
      // WHERE field IN (subquery) or WHERE field NOT IN (subquery)
      final operator = predicate.negate ? 'NOT IN' : 'IN';
      final field = grammar.wrapIdentifier(predicate.field!);
      return '$field $operator ($subquerySql)';
    } else {
      // WHERE EXISTS (subquery) or WHERE NOT EXISTS (subquery)
      final operator = predicate.negate ? 'NOT EXISTS' : 'EXISTS';
      return '$operator ($subquerySql)';
    }
  }

  String _compilePredicateGroup(
    PredicateGroup group, {
    String? tableIdentifier,
    bool resolveAggregates = false,
  }) {
    final parts = <String>[];
    for (final predicate in group.predicates) {
      final compiled = _compilePredicate(
        predicate,
        tableIdentifier: tableIdentifier,
        resolveAggregates: resolveAggregates,
      );
      if (compiled != null && compiled.isNotEmpty) {
        parts.add(compiled);
      }
    }
    if (parts.isEmpty) {
      return group.logicalOperator == PredicateLogicalOperator.and
          ? '1 = 1'
          : '0 = 0';
    }
    if (parts.length == 1) {
      return parts.first;
    }
    final separator = group.logicalOperator == PredicateLogicalOperator.and
        ? ' AND '
        : ' OR ';
    return '(${parts.join(separator)})';
  }

  String _compileFieldPredicate(
    FieldPredicate predicate,
    String? tableIdentifier, {
    bool resolveAggregates = false,
  }) {
    String? aggregateExpression;
    if (resolveAggregates) {
      for (final agg in plan.aggregates) {
        if (agg.alias == predicate.field) {
          final function = grammar.aggregateName(agg.function);
          final expression = agg.expression == '*'
              ? '*'
              : _resolvedColumnReference(agg.expression, tableIdentifier);
          aggregateExpression = '$function($expression)';
          break;
        }
      }
    }

    final column =
        aggregateExpression ??
        (_isAggregateAlias(predicate.field)
            ? grammar.wrapIdentifier(predicate.field)
            : _resolvedColumnReference(
                predicate.field,
                tableIdentifier,
                predicate.jsonSelector,
              ));
    String placeholder() {
      final base = grammar.parameterPlaceholder();
      return predicate.jsonBooleanComparison
          ? grammar.compileJsonBooleanValuePlaceholder(base)
          : base;
    }

    final bool caseInsensitive =
        predicate.caseInsensitive ||
        predicate.operator == PredicateOperator.iLike ||
        predicate.operator == PredicateOperator.notILike;

    switch (predicate.operator) {
      case PredicateOperator.equals:
        bindings.add(predicate.value);
        return '$column = ${placeholder()}';
      case PredicateOperator.notEquals:
        bindings.add(predicate.value);
        return '$column <> ${placeholder()}';
      case PredicateOperator.greaterThan:
        bindings.add(predicate.value);
        return '$column > ${placeholder()}';
      case PredicateOperator.greaterThanOrEqual:
        bindings.add(predicate.value);
        return '$column >= ${placeholder()}';
      case PredicateOperator.lessThan:
        bindings.add(predicate.value);
        return '$column < ${placeholder()}';
      case PredicateOperator.lessThanOrEqual:
        bindings.add(predicate.value);
        return '$column <= ${placeholder()}';
      case PredicateOperator.between:
        bindings
          ..add(predicate.lower)
          ..add(predicate.upper);
        return '$column BETWEEN ${placeholder()} AND ${placeholder()}';
      case PredicateOperator.notBetween:
        bindings
          ..add(predicate.lower)
          ..add(predicate.upper);
        return '$column NOT BETWEEN ${placeholder()} AND ${placeholder()}';
      case PredicateOperator.inValues:
        final values = _predicateValues(predicate);
        if (values.isEmpty) {
          return '0 = 1';
        }
        bindings.addAll(values);
        final placeholders = List.generate(
          values.length,
          (_) => placeholder(),
        ).join(', ');
        return '$column IN ($placeholders)';
      case PredicateOperator.notInValues:
        final values = _predicateValues(predicate);
        if (values.isEmpty) {
          return '1 = 1';
        }
        bindings.addAll(values);
        final placeholders = List.generate(
          values.length,
          (_) => placeholder(),
        ).join(', ');
        return '$column NOT IN ($placeholders)';
      case PredicateOperator.like:
      case PredicateOperator.iLike:
        bindings.add(
          grammar.prepareLikeBinding(
            predicate.value,
            caseInsensitive: caseInsensitive,
          ),
        );
        final formattedColumn = grammar.formatLikeColumn(
          column,
          caseInsensitive: caseInsensitive,
        );
        final formattedValue = grammar.formatLikeValue(
          placeholder(),
          caseInsensitive: caseInsensitive,
        );
        final op = grammar.likeOperator(
          caseInsensitive: caseInsensitive,
          negated: false,
        );
        return '$formattedColumn $op $formattedValue';
      case PredicateOperator.notLike:
      case PredicateOperator.notILike:
        bindings.add(
          grammar.prepareLikeBinding(
            predicate.value,
            caseInsensitive: caseInsensitive,
          ),
        );
        final formattedColumn = grammar.formatLikeColumn(
          column,
          caseInsensitive: caseInsensitive,
        );
        final formattedValue = grammar.formatLikeValue(
          placeholder(),
          caseInsensitive: caseInsensitive,
        );
        final op = grammar.likeOperator(
          caseInsensitive: caseInsensitive,
          negated: true,
        );
        return '$formattedColumn $op $formattedValue';
      case PredicateOperator.isNull:
        return grammar.compileWhereNull(predicate.field, column);
      case PredicateOperator.isNotNull:
        return grammar.compileWhereNotNull(predicate.field, column);
      case PredicateOperator.columnEquals:
        final other = _resolvedColumnReference(
          predicate.compareField!,
          tableIdentifier,
        );
        return '$column = $other';
      case PredicateOperator.columnNotEquals:
        final other = _resolvedColumnReference(
          predicate.compareField!,
          tableIdentifier,
        );
        return '$column <> $other';
      case PredicateOperator.raw:
        throw UnsupportedError('FieldPredicate.raw is not supported.');
    }
  }

  String _compileBitwisePredicate(
    BitwisePredicate predicate,
    String? tableIdentifier,
  ) {
    final column = _resolvedColumnReference(predicate.field, tableIdentifier);
    final placeholder = grammar.parameterPlaceholder();
    bindings.add(predicate.value);
    return grammar.compileBitwisePredicate(
      column,
      predicate.operator,
      placeholder,
    );
  }

  String _compileAggregate(AggregateExpression aggregate) {
    final expression = _formatExpression(aggregate.expression);
    final alias = aggregate.alias != null
        ? ' AS ${grammar.wrapIdentifier(aggregate.alias!)}'
        : '';
    final fn = grammar.aggregateName(aggregate.function);
    return '$fn($expression)$alias';
  }

  String _formatExpression(String expression) {
    if (expression == '*') {
      return '*';
    }
    if (_qualifiedIdentifier.hasMatch(expression)) {
      return expression
          .split('.')
          .map((segment) => grammar.wrapIdentifier(segment))
          .join('.');
    }
    if (_identifier.hasMatch(expression)) {
      return grammar.wrapIdentifier(expression);
    }
    return expression;
  }

  bool _hasEmptyInClause(List<FilterClause> filters) {
    for (final filter in filters) {
      if (filter.operator == FilterOperator.inValues) {
        final list = filter.value as List?;
        if (list != null && list.isEmpty) {
          return true;
        }
      }
    }
    return false;
  }

  String _columnReference(String column, String? tableIdentifier) {
    // Check if column is already table-qualified (e.g., "users.id" for correlated subqueries)
    if (column.contains('.')) {
      final parts = column.split('.');
      if (parts.length == 2) {
        // It's table.column format - wrap each part separately
        final table = grammar.wrapIdentifier(parts[0]);
        final col = grammar.wrapIdentifier(parts[1]);
        return '$table.$col';
      }
    }

    final wrapped = grammar.wrapIdentifier(column);
    if (tableIdentifier == null) {
      return wrapped;
    }
    return '$tableIdentifier.$wrapped';
  }

  String _resolvedColumnReference(
    String column,
    String? tableIdentifier, [
    JsonSelector? selectorOverride,
  ]) {
    final selector = selectorOverride ?? grammar.parseJsonSelector(column);
    if (selector != null) {
      final base = _columnReference(selector.column, tableIdentifier);
      return selector.extractsText
          ? grammar.wrapJsonSelectorReference(base, selector)
          : grammar.wrapJsonBooleanSelectorReference(base, selector);
    }
    return _columnReference(column, tableIdentifier);
  }

  bool _isAggregateAlias(String column) =>
      plan.aggregates.any((aggregate) => aggregate.alias == column);

  List<Object?> _predicateValues(FieldPredicate predicate) {
    if (predicate.values != null) {
      return List<Object?>.from(predicate.values!);
    }
    if (predicate.value is Iterable) {
      return List<Object?>.from(predicate.value as Iterable);
    }
    return const [];
  }

  String _relationAggregateExpression(RelationAggregate aggregate) {
    switch (aggregate.type) {
      case RelationAggregateType.count:
        final subquery = _buildRelationSubquery(
          aggregate.path,
          aggregate.where,
          _baseTable,
          aggregate: RelationAggregateType.count,
          distinct: aggregate.distinct,
        );
        return '($subquery)';
      case RelationAggregateType.exists:
        final existsSubquery = _buildRelationSubquery(
          aggregate.path,
          aggregate.where,
          _baseTable,
        );
        return '(CASE WHEN EXISTS($existsSubquery) THEN 1 ELSE 0 END)';
      case RelationAggregateType.sum:
      case RelationAggregateType.avg:
      case RelationAggregateType.max:
      case RelationAggregateType.min:
        final subquery = _buildRelationSubquery(
          aggregate.path,
          aggregate.where,
          _baseTable,
          aggregate: aggregate.type,
          aggregateColumn: aggregate.column,
        );
        return '($subquery)';
    }
  }

  String _compileRelationPredicate(
    RelationPredicate predicate,
    String parentAlias,
  ) {
    if (predicate.minimum == 1 && predicate.maximum == null) {
      final subquery = _buildRelationSubquery(
        predicate.path,
        predicate.where,
        parentAlias,
      );
      return 'EXISTS($subquery)';
    }
    if (predicate.minimum == 0 && predicate.maximum == 0) {
      final subquery = _buildRelationSubquery(
        predicate.path,
        predicate.where,
        parentAlias,
      );
      return 'NOT EXISTS($subquery)';
    }
    throw UnsupportedError('Relation predicate bounds not supported yet.');
  }

  String _rowNumberProjection() {
    final partition = _resolvedColumnReference(_groupLimit!.column, _baseTable);
    final orderExpressions = _orderExpressions();
    final orderClause = orderExpressions.isNotEmpty
        ? ' ORDER BY ${orderExpressions.join(', ')}'
        : ' ORDER BY ${_defaultGroupOrder()}';
    return 'ROW_NUMBER() OVER (PARTITION BY $partition$orderClause) AS '
        '${grammar.wrapIdentifier(groupRowAlias)}';
  }

  String _defaultGroupOrder() {
    final pk = plan.definition.primaryKeyField?.columnName;
    final fallback = pk ?? _groupLimit!.column;
    final reference = _resolvedColumnReference(fallback, _baseTable);
    return '$reference ASC';
  }

  String _buildRelationSubquery(
    RelationPath path,
    QueryPredicate? where,
    String parentAlias, {
    RelationAggregateType? aggregate,
    bool distinct = false,
    String? aggregateColumn,
  }) {
    if (path.segments.length == 1) {
      return _buildSingleSegmentSubquery(
        path.segments.first,
        where,
        parentAlias,
        aggregate: aggregate,
        distinct: distinct,
        aggregateColumn: aggregateColumn,
      );
    }
    if (aggregate == RelationAggregateType.count) {
      return _buildMultiSegmentCountSubquery(
        path,
        where,
        parentAlias,
        distinct: distinct,
      );
    }
    if (aggregate != null && aggregate != RelationAggregateType.exists) {
      return _buildMultiSegmentAggregateSubquery(
        path,
        where,
        parentAlias,
        aggregate: aggregate,
        aggregateColumn: aggregateColumn,
      );
    }
    return _buildNestedExistsSubquery(path.segments, 0, parentAlias, where);
  }

  String _buildMultiSegmentCountSubquery(
    RelationPath path,
    QueryPredicate? where,
    String baseAlias, {
    bool distinct = false,
  }) {
    final aliases = _assignRelationAliases(path, baseAlias);
    final leaf = aliases.last;
    final distinctColumn = _distinctColumnReference(leaf.segment, leaf.alias);
    final countExpression = distinct && distinctColumn != null
        ? 'COUNT(DISTINCT $distinctColumn)'
        : 'COUNT(*)';
    final buffer = StringBuffer('SELECT $countExpression FROM ')
      ..write(_qualifiedTable(leaf.segment.targetDefinition))
      ..write(' AS ')
      ..write(leaf.alias)
      ..write(' ');

    final joins = StringBuffer();
    final whereClauses = <String>[];
    final includedAliases = <String>{leaf.alias};
    final includedPivots = <String>{};
    final includedThrough = <String>{};

    for (var i = aliases.length - 1; i >= 0; i--) {
      final aliasData = aliases[i];
      final segment = aliasData.segment;
      final parentAlias = aliasData.parentAlias;

      if (segment.usesPivot) {
        final pivotAlias = aliasData.pivotAlias!;
        if (includedPivots.add(pivotAlias)) {
          joins
            ..write('JOIN ')
            ..write(_qualifiedPivotTable(segment.pivotTable!))
            ..write(' AS ')
            ..write(pivotAlias)
            ..write(' ON ')
            ..write(
              '$pivotAlias.${grammar.wrapIdentifier(segment.pivotRelatedKey!)} = '
              '${aliasData.alias}.${grammar.wrapIdentifier(segment.childKey)} ',
            );
        }

        if (parentAlias == baseAlias) {
          whereClauses.add(
            '$pivotAlias.${grammar.wrapIdentifier(segment.pivotParentKey!)} = '
            '$baseAlias.${grammar.wrapIdentifier(segment.parentKey)}',
          );
        } else {
          final parentDefinition = aliases[i - 1].segment.targetDefinition;
          if (includedAliases.add(parentAlias)) {
            joins
              ..write('JOIN ')
              ..write(_qualifiedTable(parentDefinition))
              ..write(' AS ')
              ..write(parentAlias)
              ..write(' ON ')
              ..write(
                '$pivotAlias.${grammar.wrapIdentifier(segment.pivotParentKey!)} = '
                '$parentAlias.${grammar.wrapIdentifier(segment.parentKey)} ',
              );
          }
        }
      } else if (segment.usesThrough) {
        final throughAlias = aliasData.throughAlias!;
        if (includedThrough.add(throughAlias)) {
          joins
            ..write('JOIN ')
            ..write(_qualifiedTable(segment.throughDefinition!))
            ..write(' AS ')
            ..write(throughAlias)
            ..write(' ON ')
            ..write(
              '${aliasData.alias}.${grammar.wrapIdentifier(segment.childKey)} = '
              '$throughAlias.${grammar.wrapIdentifier(segment.throughChildKey!)} ',
            );
        }

        if (parentAlias == baseAlias) {
          whereClauses.add(
            '$throughAlias.${grammar.wrapIdentifier(segment.throughParentKey!)} = '
            '$baseAlias.${grammar.wrapIdentifier(segment.parentKey)}',
          );
        } else {
          final parentDefinition = aliases[i - 1].segment.targetDefinition;
          if (includedAliases.add(parentAlias)) {
            joins
              ..write('JOIN ')
              ..write(_qualifiedTable(parentDefinition))
              ..write(' AS ')
              ..write(parentAlias)
              ..write(' ON ')
              ..write(
                '$throughAlias.${grammar.wrapIdentifier(segment.throughParentKey!)} = '
                '$parentAlias.${grammar.wrapIdentifier(segment.parentKey)} ',
              );
          }
        }
      } else {
        final condition = _nonPivotRelationCondition(
          segment,
          aliasData.alias,
          parentAlias,
        );
        if (parentAlias == baseAlias) {
          whereClauses.add(condition);
        } else {
          final parentDefinition = aliases[i - 1].segment.targetDefinition;
          if (includedAliases.add(parentAlias)) {
            joins
              ..write('JOIN ')
              ..write(_qualifiedTable(parentDefinition))
              ..write(' AS ')
              ..write(parentAlias)
              ..write(' ON ')
              ..write(condition)
              ..write(' ');
          }
        }
      }

      if (segment.usesMorph) {
        final morphAlias =
            segment.usesPivot && segment.morphOnPivot
                ? (aliasData.pivotAlias ?? aliasData.alias)
                : aliasData.alias;
        whereClauses.add(
          '$morphAlias.${grammar.wrapIdentifier(segment.morphTypeColumn!)} = '
          '${grammar.parameterPlaceholder()}',
        );
        bindings.add(segment.morphClass);
      }
    }

    final predicateSql = _compilePredicate(where, tableIdentifier: leaf.alias);
    if (predicateSql != null && predicateSql.isNotEmpty) {
      whereClauses.add(predicateSql);
    }

    buffer.write(joins.toString());
    if (whereClauses.isNotEmpty) {
      buffer
        ..write('WHERE ')
        ..write(whereClauses.join(' AND '));
    }
    return buffer.toString();
  }

  String _buildNestedExistsSubquery(
    List<RelationSegment> segments,
    int index,
    String parentAlias,
    QueryPredicate? where,
  ) {
    final segment = segments[index];
    final targetAlias = _nextAlias('rel');
    String? pivotAlias;
    final buffer = StringBuffer('SELECT 1 FROM ');
    if (segment.usesPivot) {
      pivotAlias = _nextAlias('pivot');
      buffer
        ..write('${_qualifiedPivotTable(segment.pivotTable!)} AS $pivotAlias ')
        ..write(
          'JOIN ${_qualifiedTable(segment.targetDefinition)} AS $targetAlias ',
        )
        ..write(
          'ON $targetAlias.${grammar.wrapIdentifier(segment.childKey)} = '
          '$pivotAlias.${grammar.wrapIdentifier(segment.pivotRelatedKey!)} ',
        )
        ..write(
          'WHERE $pivotAlias.${grammar.wrapIdentifier(segment.pivotParentKey!)} = '
          '$parentAlias.${grammar.wrapIdentifier(segment.parentKey)}',
        );
    } else if (segment.usesThrough) {
      final throughAlias = _nextAlias('through');
      buffer
        ..write('${_qualifiedTable(segment.targetDefinition)} AS $targetAlias ')
        ..write(
          'JOIN ${_qualifiedTable(segment.throughDefinition!)} AS $throughAlias ',
        )
        ..write(
          'ON $targetAlias.${grammar.wrapIdentifier(segment.childKey)} = '
          '$throughAlias.${grammar.wrapIdentifier(segment.throughChildKey!)} ',
        )
        ..write(
          'WHERE $throughAlias.${grammar.wrapIdentifier(segment.throughParentKey!)} = '
          '$parentAlias.${grammar.wrapIdentifier(segment.parentKey)}',
        );
    } else {
      buffer
        ..write('${_qualifiedTable(segment.targetDefinition)} AS $targetAlias ')
        ..write(
          'WHERE $targetAlias.${grammar.wrapIdentifier(segment.childKey)} = '
          '$parentAlias.${grammar.wrapIdentifier(segment.parentKey)}',
        );
    }
    if (segment.usesMorph) {
      final morphAlias =
          segment.usesPivot && segment.morphOnPivot
              ? pivotAlias ?? targetAlias
              : targetAlias;
      buffer
        ..write(' AND ')
        ..write(
          '$morphAlias.${grammar.wrapIdentifier(segment.morphTypeColumn!)} = '
          '${grammar.parameterPlaceholder()}',
        );
      bindings.add(segment.morphClass);
    }
    if (index < segments.length - 1) {
      final nested = _buildNestedExistsSubquery(
        segments,
        index + 1,
        targetAlias,
        where,
      );
      buffer
        ..write(' AND EXISTS(')
        ..write(nested)
        ..write(')');
    } else {
      final predicateSql = _compilePredicate(
        where,
        tableIdentifier: targetAlias,
      );
      if (predicateSql != null && predicateSql.isNotEmpty) {
        buffer
          ..write(' AND ')
          ..write(predicateSql);
      }
    }
    return buffer.toString();
  }

  String _buildSingleSegmentSubquery(
    RelationSegment segment,
    QueryPredicate? where,
    String parentAlias, {
    RelationAggregateType? aggregate,
    bool distinct = false,
    String? aggregateColumn,
  }) {
    final targetAlias = _nextAlias('rel');
    final selectExpression = aggregate == RelationAggregateType.count
        ? _countExpressionForSegment(segment, targetAlias, distinct)
        : aggregate != null && aggregate != RelationAggregateType.exists
        ? _aggregateExpressionForSegment(
            aggregate,
            aggregateColumn,
            targetAlias,
          )
        : '1';
    final buffer = StringBuffer('SELECT $selectExpression FROM ');
    String? pivotAlias;
    if (segment.usesPivot) {
      pivotAlias = _nextAlias('pivot');
      buffer
        ..write('${_qualifiedPivotTable(segment.pivotTable!)} AS $pivotAlias ')
        ..write(
          'JOIN ${_qualifiedTable(segment.targetDefinition)} AS $targetAlias ',
        )
        ..write(
          'ON $targetAlias.${grammar.wrapIdentifier(segment.childKey)} = '
          '$pivotAlias.${grammar.wrapIdentifier(segment.pivotRelatedKey!)} ',
        )
        ..write(
          'WHERE $pivotAlias.${grammar.wrapIdentifier(segment.pivotParentKey!)} = '
          '$parentAlias.${grammar.wrapIdentifier(segment.parentKey)}',
        );
    } else if (segment.usesThrough) {
      final throughAlias = _nextAlias('through');
      buffer
        ..write('${_qualifiedTable(segment.targetDefinition)} AS $targetAlias ')
        ..write(
          'JOIN ${_qualifiedTable(segment.throughDefinition!)} AS $throughAlias ',
        )
        ..write(
          'ON $targetAlias.${grammar.wrapIdentifier(segment.childKey)} = '
          '$throughAlias.${grammar.wrapIdentifier(segment.throughChildKey!)} ',
        )
        ..write(
          'WHERE $throughAlias.${grammar.wrapIdentifier(segment.throughParentKey!)} = '
          '$parentAlias.${grammar.wrapIdentifier(segment.parentKey)}',
        );
    } else {
      buffer
        ..write('${_qualifiedTable(segment.targetDefinition)} AS $targetAlias ')
        ..write(
          'WHERE $targetAlias.${grammar.wrapIdentifier(segment.childKey)} = '
          '$parentAlias.${grammar.wrapIdentifier(segment.parentKey)}',
        );
    }
    if (segment.usesMorph) {
      final morphAlias =
          segment.usesPivot && segment.morphOnPivot
              ? pivotAlias ?? targetAlias
              : targetAlias;
      buffer
        ..write(' AND ')
        ..write(
          '$morphAlias.${grammar.wrapIdentifier(segment.morphTypeColumn!)} = '
          '${grammar.parameterPlaceholder()}',
        );
      bindings.add(segment.morphClass);
    }
    final predicateSql = _compilePredicate(where, tableIdentifier: targetAlias);
    if (predicateSql != null && predicateSql.isNotEmpty) {
      buffer
        ..write(' AND ')
        ..write(predicateSql);
    }
    return buffer.toString();
  }

  List<_RelationAlias> _assignRelationAliases(
    RelationPath path,
    String baseAlias,
  ) {
    final join = _joinForPath(path);
    if (join != null) {
      final aliases = <_RelationAlias>[];
      for (final edge in join.edges) {
        aliases.add(
          _RelationAlias(
            edge.segment,
            edge.alias,
            edge.pivotAlias,
            edge.throughAlias,
            edge.parentAlias == 'base' ? baseAlias : edge.parentAlias,
          ),
        );
      }
      return aliases;
    }
    final result = <_RelationAlias>[];
    var parent = baseAlias;
    for (final segment in path.segments) {
      final alias = _nextAlias('rel');
      final pivotAlias = segment.usesPivot ? _nextAlias('pivot') : null;
      final throughAlias =
          segment.usesThrough ? _nextAlias('through') : null;
      result.add(
        _RelationAlias(segment, alias, pivotAlias, throughAlias, parent),
      );
      parent = alias;
    }
    return result;
  }

  String _nonPivotRelationCondition(
    RelationSegment segment,
    String childAlias,
    String parentAlias,
  ) {
    final childColumn =
        '$childAlias.${grammar.wrapIdentifier(segment.childKey)}';
    final parentColumn =
        '$parentAlias.${grammar.wrapIdentifier(segment.parentKey)}';
    return segment.foreignKeyOnParent
        ? '$parentColumn = $childColumn'
        : '$childColumn = $parentColumn';
  }

  String _nextAlias(String prefix) => '${prefix}_${_aliasCounter++}';

  String _countExpressionForSegment(
    RelationSegment segment,
    String alias,
    bool distinct,
  ) {
    if (!distinct) {
      return 'COUNT(*)';
    }
    final column = _distinctColumnReference(segment, alias);
    if (column == null) {
      return 'COUNT(*)';
    }
    return 'COUNT(DISTINCT $column)';
  }

  String _aggregateExpressionForSegment(
    RelationAggregateType aggregate,
    String? column,
    String alias,
  ) {
    if (column == null) {
      throw ArgumentError('Column is required for aggregate type: $aggregate');
    }
    final wrappedColumn = '$alias.${grammar.wrapIdentifier(column)}';
    switch (aggregate) {
      case RelationAggregateType.sum:
        return 'COALESCE(SUM($wrappedColumn), 0)';
      case RelationAggregateType.avg:
        return 'AVG($wrappedColumn)';
      case RelationAggregateType.max:
        return 'MAX($wrappedColumn)';
      case RelationAggregateType.min:
        return 'MIN($wrappedColumn)';
      case RelationAggregateType.count:
      case RelationAggregateType.exists:
        throw ArgumentError('Use _countExpressionForSegment for count/exists');
    }
  }

  String _buildMultiSegmentAggregateSubquery(
    RelationPath path,
    QueryPredicate? where,
    String baseAlias, {
    required RelationAggregateType aggregate,
    String? aggregateColumn,
  }) {
    final aliases = _assignRelationAliases(path, baseAlias);
    final leaf = aliases.last;
    final aggregateExpression = _aggregateExpressionForSegment(
      aggregate,
      aggregateColumn,
      leaf.alias,
    );
    final buffer = StringBuffer('SELECT $aggregateExpression FROM ')
      ..write(_qualifiedTable(leaf.segment.targetDefinition))
      ..write(' AS ')
      ..write(leaf.alias)
      ..write(' ');

    final joins = StringBuffer();
    final whereClauses = <String>[];
    final includedAliases = <String>{leaf.alias};
    final includedPivots = <String>{};
    final includedThrough = <String>{};

    for (var i = aliases.length - 1; i >= 0; i--) {
      final aliasData = aliases[i];
      final segment = aliasData.segment;
      final parentAlias = aliasData.parentAlias;

      if (segment.usesPivot) {
        final pivotAlias = aliasData.pivotAlias!;
        if (includedPivots.add(pivotAlias)) {
          joins
            ..write('JOIN ')
            ..write(_qualifiedPivotTable(segment.pivotTable!))
            ..write(' AS ')
            ..write(pivotAlias)
            ..write(' ON ')
            ..write(
              '$pivotAlias.${grammar.wrapIdentifier(segment.pivotRelatedKey!)} = '
              '${aliasData.alias}.${grammar.wrapIdentifier(segment.childKey)} ',
            );
        }

        if (parentAlias == baseAlias) {
          whereClauses.add(
            '$pivotAlias.${grammar.wrapIdentifier(segment.pivotParentKey!)} = '
            '$baseAlias.${grammar.wrapIdentifier(segment.parentKey)}',
          );
        } else {
          final parentDefinition = aliases[i - 1].segment.targetDefinition;
          if (includedAliases.add(parentAlias)) {
            joins
              ..write('JOIN ')
              ..write(_qualifiedTable(parentDefinition))
              ..write(' AS ')
              ..write(parentAlias)
              ..write(' ON ')
              ..write(
                '$pivotAlias.${grammar.wrapIdentifier(segment.pivotParentKey!)} = '
                '$parentAlias.${grammar.wrapIdentifier(segment.parentKey)} ',
              );
          }
        }
      } else if (segment.usesThrough) {
        final throughAlias = aliasData.throughAlias!;
        if (includedThrough.add(throughAlias)) {
          joins
            ..write('JOIN ')
            ..write(_qualifiedTable(segment.throughDefinition!))
            ..write(' AS ')
            ..write(throughAlias)
            ..write(' ON ')
            ..write(
              '${aliasData.alias}.${grammar.wrapIdentifier(segment.childKey)} = '
              '$throughAlias.${grammar.wrapIdentifier(segment.throughChildKey!)} ',
            );
        }

        if (parentAlias == baseAlias) {
          whereClauses.add(
            '$throughAlias.${grammar.wrapIdentifier(segment.throughParentKey!)} = '
            '$baseAlias.${grammar.wrapIdentifier(segment.parentKey)}',
          );
        } else {
          final parentDefinition = aliases[i - 1].segment.targetDefinition;
          if (includedAliases.add(parentAlias)) {
            joins
              ..write('JOIN ')
              ..write(_qualifiedTable(parentDefinition))
              ..write(' AS ')
              ..write(parentAlias)
              ..write(' ON ')
              ..write(
                '$throughAlias.${grammar.wrapIdentifier(segment.throughParentKey!)} = '
                '$parentAlias.${grammar.wrapIdentifier(segment.parentKey)} ',
              );
          }
        }
      } else {
        final condition = _nonPivotRelationCondition(
          segment,
          aliasData.alias,
          parentAlias,
        );
        if (parentAlias == baseAlias) {
          whereClauses.add(condition);
        } else {
          final parentDefinition = aliases[i - 1].segment.targetDefinition;
          if (includedAliases.add(parentAlias)) {
            joins
              ..write('JOIN ')
              ..write(_qualifiedTable(parentDefinition))
              ..write(' AS ')
              ..write(parentAlias)
              ..write(' ON ')
              ..write(condition)
              ..write(' ');
          }
        }
      }

      if (segment.usesMorph) {
        final morphAlias =
            segment.usesPivot && segment.morphOnPivot
                ? (aliasData.pivotAlias ?? aliasData.alias)
                : aliasData.alias;
        whereClauses.add(
          '$morphAlias.${grammar.wrapIdentifier(segment.morphTypeColumn!)} = '
          '${grammar.parameterPlaceholder()}',
        );
        bindings.add(segment.morphClass);
      }
    }

    final predicateSql = _compilePredicate(where, tableIdentifier: leaf.alias);
    if (predicateSql != null && predicateSql.isNotEmpty) {
      whereClauses.add(predicateSql);
    }

    buffer.write(joins.toString());
    if (whereClauses.isNotEmpty) {
      buffer
        ..write('WHERE ')
        ..write(whereClauses.join(' AND '));
    }
    return buffer.toString();
  }

  String? _distinctColumnReference(RelationSegment segment, String alias) {
    final pk = segment.targetDefinition.primaryKeyField?.columnName;
    if (pk == null || pk.isEmpty) {
      return null;
    }
    return '$alias.${grammar.wrapIdentifier(pk)}';
  }

  RelationJoin? _joinForPath(RelationPath path) {
    if (plan.relationJoins.isEmpty) {
      return null;
    }
    final key = path.segments.map((segment) => segment.name).join('.');
    for (final join in plan.relationJoins) {
      if (join.pathKey == key) {
        return join;
      }
    }
    return null;
  }
}

class _UnionCompilation {
  const _UnionCompilation({required this.sql, required this.bindings});

  final String sql;
  final List<Object?> bindings;
}

String _escapeBindingValue(Object? value) {
  if (value == null) {
    return 'null';
  }
  if (value is bool) {
    return value ? '1' : '0';
  }
  if (value is num) {
    return value.toString();
  }
  if (value is DateTime) {
    return "'${value.toIso8601String()}'";
  }
  if (value is Uint8List) {
    final buffer = StringBuffer("X'");
    for (final byte in value) {
      buffer.write(byte.toRadixString(16).padLeft(2, '0'));
    }
    buffer.write("'");
    return buffer.toString();
  }
  final stringValue = value.toString();
  final escaped = stringValue.replaceAll("'", "''");
  return "'$escaped'";
}

class _RelationAlias {
  _RelationAlias(
    this.segment,
    this.alias,
    this.pivotAlias,
    this.throughAlias,
    this.parentAlias,
  );

  final RelationSegment segment;
  final String alias;
  final String? pivotAlias;
  final String? throughAlias;
  final String parentAlias;
}
