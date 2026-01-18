import 'dart:convert';

import 'package:ormed/ormed.dart';
import 'package:ormed_postgres/src/postgres_grammar.dart';
import 'package:test/test.dart';

void main() {
  final grammar = PostgresQueryGrammar();
  final definition = AdHocModelDefinition(
    tableName: 'articles',
    columns: const [
      AdHocColumn(name: 'id', columnName: 'id', isPrimaryKey: true),
      AdHocColumn(name: 'data', columnName: 'data'),
      AdHocColumn(name: 'title', columnName: 'title'),
      AdHocColumn(name: 'body', columnName: 'body'),
    ],
  );

  QueryPlan plan0({
    List<FilterClause> filters = const [],
    bool randomOrder = false,
    List<FullTextWhere> fullText = const [],
    String? lock,
    List<JsonWhereClause> jsonWheres = const [],
    List<DateWhereClause> dateWheres = const [],
    QueryPredicate? predicate,
    bool distinct = false,
    List<DistinctOnClause> distinctOn = const <DistinctOnClause>[],
  }) => QueryPlan(
    definition: definition,
    filters: filters,
    randomOrder: randomOrder,
    fullTextWheres: fullText,
    lockClause: lock,
    jsonWheres: jsonWheres,
    dateWheres: dateWheres,
    predicate: predicate,
    distinct: distinct,
    distinctOn: distinctOn,
  );

  test('json where null compiles to #>> path extraction', () {
    final plan = plan0(
      filters: const [
        FilterClause(
          field: r'data->"$.owner.addresses[0].street"',
          operator: FilterOperator.isNotNull,
          value: null,
        ),
      ],
    );

    final sql = grammar.compileSelect(plan).sql;
    expect(sql, contains("#>> '{\"owner\",\"addresses\",0,\"street\"}'"));
  });

  test('full text search composes to_tsvector aggregates', () {
    final clause = FullTextWhere(
      columns: const ['title', 'body'],
      value: 'eloquent tips',
      language: 'simple',
      mode: FullTextMode.phrase,
    );
    final plan = plan0(fullText: [clause]);

    final compilation = grammar.compileSelect(plan);
    expect(
      compilation.sql,
      contains(
        "to_tsvector('simple', \"title\") || to_tsvector('simple', \"body\")",
      ),
    );
    expect(compilation.sql, contains("@@ phraseto_tsquery('simple', ?"));
    expect(compilation.bindings.single, 'eloquent tips');
  });

  test('full text search rejects invalid language identifiers', () {
    final clause = FullTextWhere(
      columns: const ['title'],
      value: 'ormed',
      language: "english;DROP",
      mode: FullTextMode.natural,
    );
    final plan = plan0(fullText: [clause]);
    expect(
      () => grammar.compileSelect(plan),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('lock clause maps shared variants', () {
    final sql = grammar.compileSelect(plan0(lock: 'shared')).sql;
    expect(sql.trim().endsWith('FOR SHARE'), isTrue);
  });

  test('random ordering uses RANDOM()', () {
    final plan = plan0(randomOrder: true);
    // ignore: avoid_print
    final sql = grammar.compileSelect(plan).sql;
    expect(sql, contains('ORDER BY RANDOM()'));
  });

  test('distinct adds select modifier', () {
    final sql = grammar.compileSelect(plan0(distinct: true)).sql;
    expect(sql.startsWith('SELECT DISTINCT '), isTrue);
  });

  test('distinct on renders dialect-specific clause', () {
    final plan = plan0(
      distinct: true,
      distinctOn: const [DistinctOnClause(field: 'title')],
    );
    final sql = grammar.compileSelect(plan).sql;
    expect(sql.startsWith('SELECT DISTINCT ON ("articles"."title")'), isTrue);
  });

  test('json contains compiles @> predicate', () {
    final plan = plan0(
      jsonWheres: [
        JsonWhereClause.contains(
          column: 'data',
          path: r'$.tags',
          value: ['foo'],
        ),
      ],
    );
    final compilation = grammar.compileSelect(plan);
    expect(compilation.sql, contains('@>'));
    expect(compilation.bindings.last, jsonEncode(['foo']));
  });

  test('json contains key compiles jsonb_path_exists', () {
    final plan = plan0(
      jsonWheres: [
        JsonWhereClause.containsKey(column: 'data', path: r'$.meta.author'),
      ],
    );
    final sql = grammar.compileSelect(plan).sql;
    expect(sql, contains('jsonb_path_exists'));
    expect(sql, contains("'\$.meta.author'"));
  });

  test('json length compiles jsonb_array_length', () {
    final plan = plan0(
      jsonWheres: [
        JsonWhereClause.length(
          column: 'data',
          path: r'$.items',
          lengthOperator: '>=',
          lengthValue: 2,
        ),
      ],
    );
    final compilation = grammar.compileSelect(plan);
    expect(compilation.sql, contains('jsonb_array_length'));
    expect(compilation.bindings.single, 2);
  });

  test('LIKE filters cast columns to text', () {
    final plan = plan0(
      filters: const [
        FilterClause(
          field: 'title',
          operator: FilterOperator.contains,
          value: 'foo',
        ),
      ],
    );
    final sql = grammar.compileSelect(plan).sql;
    expect(sql, contains('("articles"."title")::text LIKE'));
  });

  test('case-insensitive likes use ILIKE without folding', () {
    final plan = QueryPlan(
      definition: definition,
      predicate: const FieldPredicate(
        field: 'title',
        operator: PredicateOperator.iLike,
        value: 'foo',
        caseInsensitive: true,
      ),
    );
    final sql = grammar.compileSelect(plan).sql;
    expect(sql, contains('("articles"."title")::text ILIKE'));
    expect(sql.contains('LOWER'), isFalse);
  });

  test('bitwise predicates cast expressions to bool', () {
    final plan = QueryPlan(
      definition: definition,
      predicate: const BitwisePredicate(
        field: 'title',
        operator: '&',
        value: 1,
      ),
    );
    final sql = grammar.compileSelect(plan).sql;
    expect(sql, contains('("articles"."title" & ?)::bool'));
  });

  test('json boolean comparisons cast placeholders to jsonb', () {
    final plan = plan0(
      predicate: const FieldPredicate(
        field: 'data',
        operator: PredicateOperator.equals,
        value: 'true',
        jsonSelector: JsonSelector('data', r'$.featured', false),
        jsonBooleanComparison: true,
      ),
    );

    final compilation = grammar.compileSelect(plan);
    expect(
      compilation.sql,
      contains(r"""("articles"."data" #> '{"featured"}') = """),
    );
    expect(compilation.sql, contains('::jsonb'));
    expect(compilation.bindings.single, 'true');
  });

  test('date predicates cast columns to date', () {
    final plan = plan0(
      dateWheres: [
        DateWhereClause(
          column: 'title',
          path: r'$',
          component: DateComponent.date,
          operator: '=',
          value: '2024-01-01',
        ),
      ],
    );
    final sql = grammar.compileSelect(plan).sql;
    expect(sql, contains('("articles"."title")::date = ?'));
  });

  test('day predicates use EXTRACT for JSON selectors', () {
    final plan = plan0(
      dateWheres: [
        DateWhereClause(
          column: 'data',
          path: r'$.published',
          component: DateComponent.day,
          operator: '=',
          value: 12,
        ),
      ],
    );
    final sql = grammar.compileSelect(plan).sql;
    expect(sql, contains("EXTRACT(DAY FROM ((\"articles\".\"data\" #>>"));
    expect(sql, contains(')::timestamp) = ?'));
  });

  test('time predicates cast JSON selectors to time', () {
    final plan = plan0(
      dateWheres: [
        DateWhereClause(
          column: 'data',
          path: r'$.published',
          component: DateComponent.time,
          operator: '=',
          value: '08:30:00',
        ),
      ],
    );
    final sql = grammar.compileSelect(plan).sql;
    expect(sql, contains("((\"articles\".\"data\" #>>"));
    expect(sql, contains(')::time = ?'));
  });
}
