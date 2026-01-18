import 'dart:convert';

import 'package:ormed/ormed.dart';

/// Query grammar that quotes identifiers for MySQL/MariaDB dialects.
class MySqlQueryGrammar extends QueryGrammar {
  MySqlQueryGrammar({
    this.supportsWindowFunctions = true,
    bool supportsLateralJoins = true,
    super.extensions,
  }) : _supportsLateralJoins = supportsLateralJoins;

  final bool supportsWindowFunctions;
  final bool _supportsLateralJoins;

  @override
  String wrapIdentifier(String value) {
    final escaped = value.replaceAll('`', '``');
    return '`$escaped`';
  }

  @override
  Set<JoinType> get supportedJoinTypes => const {
    JoinType.inner,
    JoinType.left,
    JoinType.right,
    JoinType.cross,
    JoinType.straight,
  };

  @override
  bool get supportsLateralJoins => _supportsLateralJoins;

  @override
  bool supportsGroupLimit(GroupLimit groupLimit) => supportsWindowFunctions;

  @override
  String compileRandom([num? seed]) {
    if (seed == null) {
      return 'RAND()';
    }
    return 'RAND(${seed.toString()})';
  }

  @override
  String? compileOffset(int? offset, {required bool limitProvided}) {
    if (offset == null) return null;
    final placeholder = parameterPlaceholder();
    if (limitProvided) {
      return 'OFFSET $placeholder';
    }
    // MySQL requires LIMIT before OFFSET when no explicit limit is provided.
    return 'LIMIT 18446744073709551615 OFFSET $placeholder';
  }

  @override
  String wrapJsonSelectorReference(
    String columnReference,
    JsonSelector selector,
  ) {
    return 'JSON_UNQUOTE(JSON_EXTRACT($columnReference, ${_jsonPathLiteral(selector.path)}))';
  }

  @override
  String wrapJsonBooleanSelectorReference(
    String columnReference,
    JsonSelector selector,
  ) => 'JSON_EXTRACT($columnReference, ${_jsonPathLiteral(selector.path)})';

  @override
  String compileJsonBooleanValuePlaceholder(String placeholder) =>
      "JSON_EXTRACT($placeholder, '\$')";

  @override
  String? compileThreadCount() =>
      "SHOW STATUS WHERE variable_name = 'Threads_connected'";

  @override
  String compileWhereNull(String column, String resolvedColumn) {
    final selector = parseJsonSelector(column);
    if (selector == null) {
      return super.compileWhereNull(column, resolvedColumn);
    }
    final jsonExpr =
        'JSON_EXTRACT($resolvedColumn, ${_jsonPathLiteral(selector.path)})';
    final typeExpr = 'JSON_TYPE($jsonExpr)';
    return '($jsonExpr IS NULL OR $typeExpr = \'NULL\')';
  }

  @override
  String compileWhereNotNull(String column, String resolvedColumn) {
    final selector = parseJsonSelector(column);
    if (selector == null) {
      return super.compileWhereNotNull(column, resolvedColumn);
    }
    final jsonExpr =
        'JSON_EXTRACT($resolvedColumn, ${_jsonPathLiteral(selector.path)})';
    final typeExpr = 'JSON_TYPE($jsonExpr)';
    return '($jsonExpr IS NOT NULL AND $typeExpr != \'NULL\')';
  }

  @override
  String compileIndexHints(List<IndexHint> hints) {
    if (hints.isEmpty) {
      return '';
    }
    final parts = hints.map((hint) {
      final indexes = hint.indexes
          .map((index) => wrapIdentifier(index))
          .join(', ');
      switch (hint.type) {
        case IndexHintType.use:
          return 'USE INDEX ($indexes)';
        case IndexHintType.force:
          return 'FORCE INDEX ($indexes)';
        case IndexHintType.ignore:
          return 'IGNORE INDEX ($indexes)';
      }
    });
    return parts.join(' ');
  }

  @override
  String compileLock(String? clause) {
    switch (clause) {
      case 'update':
        return 'FOR UPDATE';
      case 'shared':
        return 'LOCK IN SHARE MODE';
      default:
        return clause ?? '';
    }
  }

  @override
  Iterable<String> finalizeGroupByColumns(
    Iterable<String> groupByColumns,
    Iterable<String> hydrationColumns,
    QueryPlan plan,
  ) {
    if (groupByColumns.isEmpty) {
      return groupByColumns;
    }
    final seen = <String>{};
    final columns = <String>[];
    for (final column in groupByColumns) {
      if (column.isEmpty) {
        continue;
      }
      if (seen.add(column)) {
        columns.add(column);
      }
    }
    for (final column in hydrationColumns) {
      if (column.isEmpty) {
        continue;
      }
      if (seen.add(column)) {
        columns.add(column);
      }
    }
    return columns;
  }

  @override
  String compileFullText(FullTextWhere clause) {
    final columns = clause.columns
        .map((column) => wrapIdentifier(column))
        .join(', ');
    final buffer = StringBuffer(
      'MATCH ($columns) AGAINST (${parameterPlaceholder()}',
    );
    switch (clause.mode) {
      case FullTextMode.boolean:
        buffer.write(' IN BOOLEAN MODE');
        break;
      case FullTextMode.phrase:
        buffer.write(' IN NATURAL LANGUAGE MODE');
        break;
      case FullTextMode.websearch:
        buffer.write(' IN NATURAL LANGUAGE MODE');
        break;
      case FullTextMode.natural:
        buffer.write(' IN NATURAL LANGUAGE MODE');
        break;
    }
    if (clause.mode == FullTextMode.natural && clause.expanded) {
      buffer.write(' WITH QUERY EXPANSION');
    }
    buffer.write(')');
    return buffer.toString();
  }

  @override
  JsonPredicateCompilation compileJsonPredicate(
    JsonWhereClause clause,
    String resolvedColumn,
  ) {
    switch (clause.type) {
      case JsonPredicateType.contains:
        final sql =
            'JSON_CONTAINS($resolvedColumn, ${parameterPlaceholder()}, ${_jsonPathLiteral(clause.path)})';
        return JsonPredicateCompilation(
          sql: sql,
          bindings: [_encodeJsonValue(clause.value)],
        );
      case JsonPredicateType.overlaps:
        final values = _jsonOverlapValues(clause.value);
        if (values.isEmpty) {
          return JsonPredicateCompilation(sql: '0 = 1');
        }
        final pathLiteral = _jsonPathLiteral(clause.path);
        final expressions = <String>[];
        final bindings = <Object?>[];
        for (final candidate in values) {
          final placeholder = compileJsonValueCast(parameterPlaceholder());
          expressions.add(
            'JSON_CONTAINS($resolvedColumn, $placeholder, $pathLiteral)',
          );
          bindings.add(_encodeJsonValue(candidate));
        }
        final sql = expressions.length == 1
            ? expressions.single
            : '(${expressions.join(' OR ')})';
        return JsonPredicateCompilation(sql: sql, bindings: bindings);
      case JsonPredicateType.containsKey:
        final sql =
            "JSON_CONTAINS_PATH($resolvedColumn, 'one', ${_jsonPathLiteral(clause.path)})";
        return JsonPredicateCompilation(sql: sql);
      case JsonPredicateType.length:
        final pathLiteral = clause.path == r'$'
            ? ''
            : ', ${_jsonPathLiteral(clause.path)}';
        final sql =
            'JSON_LENGTH($resolvedColumn$pathLiteral) '
            '${clause.lengthOperator} ${parameterPlaceholder()}';
        return JsonPredicateCompilation(
          sql: sql,
          bindings: [clause.lengthValue],
        );
    }

    // Exhaustive switch; we should never reach this point.
  }

  @override
  JsonUpdateCompilation compileJsonUpdate(
    String column,
    String resolvedColumn,
    String path,
    Object? value,
  ) {
    final pathLiteral = _jsonPathLiteral(path);
    final valueExpr = _jsonUpdateValue(value);
    final sql =
        '$resolvedColumn = JSON_SET($resolvedColumn, $pathLiteral, ${valueExpr.sql})';
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
    final valueExpr = _jsonUpdateValue(value);
    final sql =
        '$resolvedColumn = JSON_MERGE_PATCH('
        'COALESCE($resolvedColumn, JSON_OBJECT()), '
        '${valueExpr.sql})';
    return JsonUpdateCompilation(sql: sql, bindings: valueExpr.bindings);
  }

  @override
  DatePredicateCompilation compileDatePredicate(
    DateWhereClause clause,
    String resolvedColumn,
  ) {
    final expression = clause.targetsRoot
        ? resolvedColumn
        : _jsonValueExpression(resolvedColumn, clause.path);
    final lhs = compileDateComponentExpression(clause.component, expression);
    final sql = '$lhs ${clause.operator} ${parameterPlaceholder()}';
    return DatePredicateCompilation(sql: sql, bindings: [clause.value]);
  }

  String _jsonPathLiteral(String path) {
    final escaped = path.replaceAll("'", r"\\'");
    return "'$escaped'";
  }

  Object? _encodeJsonValue(Object? value) => jsonEncode(value);

  String _jsonValueExpression(String column, String path) =>
      'JSON_UNQUOTE(JSON_EXTRACT($column, ${_jsonPathLiteral(path)}))';

  List<Object?> _jsonOverlapValues(Object? value) {
    if (value is Iterable) {
      return value.toList(growable: false);
    }
    return [value];
  }

  _JsonValueExpression _jsonUpdateValue(Object? value) {
    final encoded = jsonEncode(value);
    final placeholder = parameterPlaceholder();
    return _JsonValueExpression("JSON_EXTRACT($placeholder, '\$')", [encoded]);
  }
}

class _JsonValueExpression {
  const _JsonValueExpression(this.sql, this.bindings);

  final String sql;
  final List<Object?> bindings;
}
