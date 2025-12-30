import 'dart:convert';

import 'package:ormed/ormed.dart';

/// Postgres-flavoured query grammar that simply double-quotes identifiers.
class PostgresQueryGrammar extends QueryGrammar {
  PostgresQueryGrammar({super.extensions});

  @override
  String wrapIdentifier(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }

  @override
  String caseInsensitiveExpression(String expression) => 'LOWER($expression)';

  @override
  Set<JoinType> get supportedJoinTypes => const {
    JoinType.inner,
    JoinType.left,
    JoinType.right,
    JoinType.cross,
  };

  @override
  bool get supportsLateralJoins => true;

  @override
  String compileRandom([num? seed]) => 'RANDOM()';

  @override
  bool get supportsDistinctOn => true;

  @override
  String compileColumns(
    QueryPlan plan,
    String projections,
    List<String> distinctOnExpressions,
  ) {
    final buffer = StringBuffer('SELECT ');
    if (distinctOnExpressions.isNotEmpty) {
      buffer
        ..write('DISTINCT ON (')
        ..write(distinctOnExpressions.join(', '))
        ..write(') ');
    } else if (plan.distinct) {
      buffer.write('DISTINCT ');
    }
    buffer.write(projections);
    return buffer.toString();
  }

  @override
  String wrapJsonSelectorReference(
    String columnReference,
    JsonSelector selector,
  ) {
    if (selector.path == r'$') {
      return '($columnReference)::text';
    }
    final literal = _postgresPath(selector.path);
    return '($columnReference #>> $literal)';
  }

  @override
  String wrapJsonBooleanSelectorReference(
    String columnReference,
    JsonSelector selector,
  ) {
    if (selector.path == r'$') {
      return '($columnReference)::jsonb';
    }
    final literal = _postgresPath(selector.path);
    return '($columnReference #> $literal)';
  }

  @override
  String? compileThreadCount() =>
      'select count(*) as value from pg_stat_activity';

  @override
  String compileWhereNull(String column, String resolvedColumn) {
    final selector = parseJsonSelector(column);
    if (selector == null) {
      return super.compileWhereNull(column, resolvedColumn);
    }
    final jsonExpr = '($resolvedColumn #>> ${_postgresPath(selector.path)})';
    return '$jsonExpr IS NULL';
  }

  @override
  String compileWhereNotNull(String column, String resolvedColumn) {
    final selector = parseJsonSelector(column);
    if (selector == null) {
      return super.compileWhereNotNull(column, resolvedColumn);
    }
    final jsonExpr = '($resolvedColumn #>> ${_postgresPath(selector.path)})';
    return '$jsonExpr IS NOT NULL';
  }

  @override
  String compileLock(String? clause) {
    switch (clause) {
      case 'update':
        return 'FOR UPDATE';
      case 'shared':
        return 'FOR SHARE';
      default:
        return clause ?? '';
    }
  }

  @override
  String compileFullText(FullTextWhere clause) {
    final language = clause.language ?? 'english';
    final vectors = clause.columns
        .map((column) => "to_tsvector('$language', ${wrapIdentifier(column)})")
        .join(' || ');
    final buffer = StringBuffer('($vectors) @@ ');
    buffer.write(_queryFunction(clause.mode));
    buffer.write("('$language', ${parameterPlaceholder()})");
    return buffer.toString();
  }

  @override
  JsonPredicateCompilation compileJsonPredicate(
    JsonWhereClause clause,
    String resolvedColumn,
  ) {
    switch (clause.type) {
      case JsonPredicateType.contains:
        final target = _postgresJsonTarget(resolvedColumn, clause.path);
        final sql = '$target @> ${parameterPlaceholder()}::jsonb';
        return JsonPredicateCompilation(
          sql: sql,
          bindings: [_encodeJsonValue(clause.value)],
        );
      case JsonPredicateType.overlaps:
        final accessor = _postgresJsonTarget(resolvedColumn, clause.path);
        final placeholder = parameterPlaceholder();
        final cast = compileJsonValueCast(placeholder);
        final sql =
            'EXISTS (SELECT 1 FROM jsonb_array_elements($accessor) AS lhs(elem) '
            'INNER JOIN jsonb_array_elements($cast) AS rhs(elem) '
            'ON lhs.elem = rhs.elem)';
        return JsonPredicateCompilation(
          sql: sql,
          bindings: [_encodeJsonValue(clause.value)],
        );
      case JsonPredicateType.containsKey:
        final jsonPath = _jsonbPathLiteral(clause.path);
        final sql = 'jsonb_path_exists(($resolvedColumn)::jsonb, $jsonPath)';
        return JsonPredicateCompilation(sql: sql);
      case JsonPredicateType.length:
        final accessor = _postgresJsonTarget(resolvedColumn, clause.path);
        final sql =
            'jsonb_array_length($accessor) ${clause.lengthOperator} ${parameterPlaceholder()}';
        return JsonPredicateCompilation(
          sql: sql,
          bindings: [clause.lengthValue],
        );
    }
  }

  @override
  String compileJsonValueCast(String placeholder) => '($placeholder)::jsonb';

  @override
  String compileJsonBooleanValuePlaceholder(String placeholder) =>
      compileJsonValueCast(placeholder);

  @override
  DatePredicateCompilation compileDatePredicate(
    DateWhereClause clause,
    String resolvedColumn,
  ) {
    final isJson = !clause.targetsRoot;
    final operand = clause.targetsRoot
        ? resolvedColumn
        : _jsonTextSelector(resolvedColumn, clause.path);
    final placeholder = parameterPlaceholder();
    late final String lhs;
    switch (clause.component) {
      case DateComponent.date:
        lhs = '${_castExpression(operand)}::date';
        break;
      case DateComponent.time:
        lhs = '${_castExpression(operand)}::time';
        break;
      case DateComponent.day:
        lhs = 'EXTRACT(DAY FROM ${_timestampOperand(operand, isJson)})';
        break;
      case DateComponent.month:
        lhs = 'EXTRACT(MONTH FROM ${_timestampOperand(operand, isJson)})';
        break;
      case DateComponent.year:
        lhs = 'EXTRACT(YEAR FROM ${_timestampOperand(operand, isJson)})';
        break;
    }
    final sql = '$lhs ${clause.operator} $placeholder';
    return DatePredicateCompilation(sql: sql, bindings: [clause.value]);
  }

  String _queryFunction(FullTextMode mode) {
    switch (mode) {
      case FullTextMode.phrase:
        return 'phraseto_tsquery';
      case FullTextMode.websearch:
        return 'websearch_to_tsquery';
      case FullTextMode.boolean:
        return 'to_tsquery';
      case FullTextMode.natural:
        return 'plainto_tsquery';
    }
  }

  String _postgresPath(String path) {
    final selector = parseJsonSelector('dummy->$path');
    final segments = jsonPathSegments(selector?.path ?? path);
    if (segments.isEmpty) {
      return "'{}'";
    }
    final formatted = segments
        .map((segment) {
          final trimmed = segment.trim();
          final numeric = int.tryParse(trimmed);
          if (numeric != null) {
            return trimmed;
          }
          final escaped = trimmed.replaceAll('"', '\\"').replaceAll("'", "''");
          return '"$escaped"';
        })
        .join(',');
    return "'{$formatted}'";
  }

  String _postgresJsonTarget(String column, String path) {
    if (path == r'$') {
      return '($column)::jsonb';
    }
    final literal = _postgresPath(path);
    return '($column #> $literal)::jsonb';
  }

  @override
  String formatLikeColumn(String column, {required bool caseInsensitive}) =>
      '($column)::text';

  @override
  String formatLikeValue(String value, {required bool caseInsensitive}) =>
      value;

  @override
  String likeOperator({required bool caseInsensitive, required bool negated}) {
    final op = caseInsensitive ? 'ILIKE' : 'LIKE';
    return negated ? 'NOT $op' : op;
  }

  @override
  String compileBitwisePredicate(
    String column,
    String operator,
    String placeholder,
  ) => '($column $operator $placeholder)::bool';

  @override
  JsonUpdateCompilation compileJsonUpdate(
    String column,
    String resolvedColumn,
    String path,
    Object? value,
  ) {
    final literal = _postgresPath(path);
    final valueExpr = _postgresJsonUpdateValue(value);
    final sql =
        '$resolvedColumn = jsonb_set(($resolvedColumn)::jsonb, $literal, ${valueExpr.sql}, true)';
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
    final placeholder = parameterPlaceholder();
    final target = "COALESCE(($resolvedColumn)::jsonb, CAST('{}' AS jsonb))";
    final sql = '$resolvedColumn = $target || CAST($placeholder AS jsonb)';
    return JsonUpdateCompilation(sql: sql, bindings: [binding]);
  }

  String _jsonTextSelector(String column, String path) {
    final literal = _postgresPath(path);
    return '($column #>> $literal)';
  }

  String _castExpression(String expression) => '($expression)';

  String _timestampOperand(String expression, bool isJsonOperand) {
    if (isJsonOperand) {
      return '($expression)::timestamp';
    }
    return expression;
  }

  _JsonValueExpression _postgresJsonUpdateValue(Object? value) {
    if (value == null) {
      return _JsonValueExpression('CAST(NULL AS jsonb)', const []);
    }
    Object? normalized = value;
    if (value is! String || (value).isNotEmpty) {
      normalized = jsonEncode(value);
    }
    return _JsonValueExpression('CAST(? AS jsonb)', [normalized]);
  }

  String _jsonbPathLiteral(String path) {
    final normalized = path.trim().isEmpty
        ? r'$'
        : (path.startsWith(r'$') ? path : r'$.${path}');
    final escaped = normalized.replaceAll("'", "''");
    return "'$escaped'";
  }

  Object? _encodeJsonValue(Object? value) => jsonEncode(value);
}

class _JsonValueExpression {
  const _JsonValueExpression(this.sql, this.bindings);

  final String sql;
  final List<Object?> bindings;
}
