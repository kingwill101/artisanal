import 'dart:convert';

import 'package:ormed/ormed.dart';

/// SQLite implementation of the shared [QueryGrammar].
class SqliteQueryGrammar extends QueryGrammar {
  const SqliteQueryGrammar({this.supportsWindowFunctions = true});

  final bool supportsWindowFunctions;

  static final RegExp _identifier = RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$');
  static final RegExp _qualifiedIdentifier = RegExp(
    r'^[A-Za-z_][A-Za-z0-9_]*(\.[A-Za-z_][A-Za-z0-9_]*)+$',
  );

  @override
  String wrapIdentifier(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }

  @override
  String caseInsensitiveExpression(String expression) => 'LOWER($expression)';

  @override
  String compileRandom([num? seed]) => 'RANDOM()';

  @override
  String formatLikeColumn(String column, {required bool caseInsensitive}) {
    if (caseInsensitive) {
      return super.formatLikeColumn(column, caseInsensitive: caseInsensitive);
    }
    return column;
  }

  @override
  String formatLikeValue(String value, {required bool caseInsensitive}) {
    if (caseInsensitive) {
      return super.formatLikeValue(value, caseInsensitive: caseInsensitive);
    }
    return value;
  }

  @override
  String wrapUnion(String sql) => 'select * from ($sql)';

  @override
  String compileFullText(FullTextWhere clause) {
    final tableName = _resolveFullTextTableName(clause);
    if (tableName.isEmpty) {
      return '';
    }
    final indexName = _resolveFullTextIndexName(clause, tableName);
    final base = _artifactBaseName(tableName, indexName);
    final ftsTable = wrapIdentifier('${base}_fts');
    final rowIdTarget =
        clause.tableAlias != null && clause.tableAlias!.isNotEmpty
        ? wrapIdentifier(clause.tableAlias!)
        : _wrapQualifiedTable(tableName);
    return '$rowIdTarget.rowid IN '
        '(SELECT rowid FROM $ftsTable WHERE $ftsTable MATCH ${parameterPlaceholder()})';
  }

  @override
  String wrapJsonSelectorReference(
    String columnReference,
    JsonSelector selector,
  ) => _jsonTarget(columnReference, selector.path);

  @override
  String wrapJsonBooleanSelectorReference(
    String columnReference,
    JsonSelector selector,
  ) => _jsonTarget(columnReference, selector.path);

  String _resolveFullTextTableName(FullTextWhere clause) {
    final table = clause.tableName?.trim() ?? '';
    if (table.isEmpty) {
      return '';
    }
    final schema = clause.schema?.trim();
    final prefix = clause.tablePrefix?.trim();
    if (schema != null && schema.isNotEmpty) {
      return table;
    }
    if (_qualifiedIdentifier.hasMatch(table)) {
      return table;
    }
    if (!_identifier.hasMatch(table)) {
      return table;
    }
    if (prefix != null && prefix.isNotEmpty && !table.startsWith(prefix)) {
      return '$prefix$table';
    }
    return table;
  }

  String _resolveFullTextIndexName(FullTextWhere clause, String tableName) {
    final explicit = clause.indexName?.trim();
    if (explicit != null && explicit.isNotEmpty) {
      return explicit;
    }
    final columnPart = clause.columns.join('_');
    return '${tableName}_${columnPart}_fulltext';
  }

  String _artifactBaseName(String table, String indexName) {
    final raw = '${table}_$indexName'.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_');
    final collapsed = raw.replaceAll(RegExp(r'_+'), '_');
    return collapsed.isEmpty ? 'idx' : collapsed;
  }

  String _wrapQualifiedTable(String table) {
    if (table.contains('.')) {
      return table
          .split('.')
          .map((segment) => wrapIdentifier(segment))
          .join('.');
    }
    return wrapIdentifier(table);
  }

  @override
  String compileWhereNull(String column, String resolvedColumn) {
    final selector = parseJsonSelector(column);
    if (selector == null) {
      return super.compileWhereNull(column, resolvedColumn);
    }
    final jsonExpr = _jsonTarget(resolvedColumn, selector.path);
    return '$jsonExpr IS NULL';
  }

  @override
  String compileWhereNotNull(String column, String resolvedColumn) {
    final selector = parseJsonSelector(column);
    if (selector == null) {
      return super.compileWhereNotNull(column, resolvedColumn);
    }
    final jsonExpr = _jsonTarget(resolvedColumn, selector.path);
    return '$jsonExpr IS NOT NULL';
  }

  @override
  String? compileOffset(int? offset, {required bool limitProvided}) {
    if (offset == null) {
      return null;
    }
    if (limitProvided) {
      return 'OFFSET ${parameterPlaceholder()}';
    }
    return 'LIMIT -1 OFFSET ${parameterPlaceholder()}';
  }

  @override
  String compileLock(String? clause) => '';

  @override
  String compileColumns(
    QueryPlan plan,
    String projections,
    List<String> distinctOnExpressions,
  ) {
    final keyword = plan.distinct ? 'SELECT DISTINCT ' : 'SELECT ';
    return '$keyword$projections';
  }

  @override
  JsonPredicateCompilation compileJsonPredicate(
    JsonWhereClause clause,
    String resolvedColumn,
  ) {
    final target = _jsonTarget(resolvedColumn, clause.path);
    switch (clause.type) {
      case JsonPredicateType.contains:
        return _sqliteJsonContainsClause(target, clause.value);
      case JsonPredicateType.overlaps:
        final cast = compileJsonValueCast(parameterPlaceholder());
        final sql =
            'EXISTS (SELECT 1 FROM json_each($target) AS lhs '
            'INNER JOIN json_each($cast) AS rhs '
            'ON lhs.value = rhs.value)';
        return JsonPredicateCompilation(
          sql: sql,
          bindings: [_encodeJsonValue(clause.value)],
        );
      case JsonPredicateType.containsKey:
        final sql = '$target IS NOT NULL';
        return JsonPredicateCompilation(sql: sql);
      case JsonPredicateType.length:
        final sql =
            'json_array_length($target) ${clause.lengthOperator} ${parameterPlaceholder()}';
        return JsonPredicateCompilation(
          sql: sql,
          bindings: [clause.lengthValue],
        );
    }
  }

  JsonPredicateCompilation _sqliteJsonContainsClause(
    String target,
    Object? value,
  ) {
    if (value is Iterable && value is! Map) {
      final candidates = value.toList(growable: false);
      if (candidates.isEmpty) {
        return JsonPredicateCompilation(sql: '0 = 1');
      }
      final comparisons = <String>[];
      final bindings = <Object?>[];
      for (final candidate in candidates) {
        comparisons.add(_sqliteJsonContainsCondition(candidate, bindings));
      }
      final sql =
          'EXISTS (SELECT 1 FROM json_each($target) WHERE ${comparisons.join(' OR ')})';
      return JsonPredicateCompilation(sql: sql, bindings: bindings);
    }
    if (value == null) {
      return JsonPredicateCompilation(
        sql:
            'EXISTS (SELECT 1 FROM json_each($target) WHERE json_each.value IS NULL)',
      );
    }
    final binding = _sqliteJsonContainsBinding(value);
    return JsonPredicateCompilation(
      sql:
          'EXISTS (SELECT 1 FROM json_each($target) WHERE json_each.value = ${parameterPlaceholder()})',
      bindings: [binding],
    );
  }

  String _sqliteJsonContainsCondition(
    Object? candidate,
    List<Object?> bindings,
  ) {
    if (candidate == null) {
      return 'json_each.value IS NULL';
    }
    bindings.add(_sqliteJsonContainsBinding(candidate));
    return 'json_each.value = ${parameterPlaceholder()}';
  }

  Object? _sqliteJsonContainsBinding(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is num || value is bool) {
      return value;
    }
    if (value is String) {
      return value;
    }
    return jsonEncode(value);
  }

  @override
  String compileJsonValueCast(String placeholder) => 'json($placeholder)';

  @override
  String compileJsonBooleanValuePlaceholder(String placeholder) =>
      "json_extract(json($placeholder), '\$')";

  @override
  DatePredicateCompilation compileDatePredicate(
    DateWhereClause clause,
    String resolvedColumn,
  ) {
    final target = _jsonTarget(resolvedColumn, clause.path);
    final format = _strftimeFormat(clause.component);
    final lhs = "strftime('$format', $target)";
    final sql =
        '$lhs ${clause.operator} CAST(${parameterPlaceholder()} AS TEXT)';
    final binding = _sqliteDateBinding(clause);
    return DatePredicateCompilation(sql: sql, bindings: [binding]);
  }

  @override
  JsonUpdateCompilation compileJsonUpdate(
    String column,
    String resolvedColumn,
    String path,
    Object? value,
  ) {
    final target = _jsonTarget(resolvedColumn, r'$');
    final literal = _jsonPathLiteral(path);
    final valueExpr = _sqliteJsonUpdateValue(value);
    final expression = 'json_set($target, $literal, ${valueExpr.sql})';
    final sql = '$resolvedColumn = $expression';
    return JsonUpdateCompilation(sql: sql, bindings: valueExpr.bindings);
  }

  @override
  JsonUpdateCompilation compileJsonPatch(
    String column,
    String resolvedColumn,
    Object? value,
  ) {
    if (value is! Map && value is! List) {
      return compileJsonUpdate(column, resolvedColumn, r'$', value);
    }
    final binding = jsonEncode(value);
    final expression =
        "json_patch(ifnull($resolvedColumn, json('{}')), json(${parameterPlaceholder()}))";
    final sql = '$resolvedColumn = $expression';
    return JsonUpdateCompilation(sql: sql, bindings: [binding]);
  }

  String _jsonPathLiteral(String path) {
    final escaped = path.replaceAll("'", r"\\'");
    return "'$escaped'";
  }

  String _jsonTarget(String column, String path) {
    if (path == r'$') {
      return column;
    }
    return 'json_extract($column, ${_jsonPathLiteral(path)})';
  }

  String _strftimeFormat(DateComponent component) {
    switch (component) {
      case DateComponent.date:
        return '%Y-%m-%d';
      case DateComponent.day:
        return '%d';
      case DateComponent.month:
        return '%m';
      case DateComponent.year:
        return '%Y';
      case DateComponent.time:
        return '%H:%M:%S';
    }
  }

  Object _sqliteDateBinding(DateWhereClause clause) {
    switch (clause.component) {
      case DateComponent.date:
      case DateComponent.time:
        return clause.value.toString();
      case DateComponent.day:
      case DateComponent.month:
        return _zeroPad(clause.value, width: 2);
      case DateComponent.year:
        return clause.value.toString();
    }
  }

  String _zeroPad(Object value, {required int width}) {
    final parsed = value is int ? value : int.tryParse(value.toString());
    if (parsed == null) {
      throw ArgumentError.value(value, 'value', 'Expected numeric date part.');
    }
    return parsed.toString().padLeft(width, '0');
  }

  Object? _encodeJsonValue(Object? value) => jsonEncode(value);

  @override
  bool supportsGroupLimit(GroupLimit groupLimit) => supportsWindowFunctions;

  _JsonValueExpression _sqliteJsonUpdateValue(Object? value) {
    if (value == null) {
      return _JsonValueExpression('NULL', const []);
    }
    if (value is bool) {
      return _JsonValueExpression('CASE WHEN ? THEN true ELSE false END', [
        value,
      ]);
    }
    if (value is num) {
      return _JsonValueExpression('?', [value]);
    }
    if (value is String) {
      return _JsonValueExpression('?', [value]);
    }
    return _JsonValueExpression('json(?)', [jsonEncode(value)]);
  }
}

class _JsonValueExpression {
  const _JsonValueExpression(this.sql, this.bindings);

  final String sql;
  final List<Object?> bindings;
}
