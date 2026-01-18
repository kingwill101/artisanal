import 'dart:convert';

import 'package:ormed/ormed.dart';
import 'package:ormed_mysql/ormed_mysql.dart';
import 'package:test/test.dart';

void main() {
  final grammar = MySqlQueryGrammar();
  final definition = AdHocModelDefinition(
    tableName: 'articles',
    columns: const [
      AdHocColumn(name: 'id', columnName: 'id', isPrimaryKey: true),
      AdHocColumn(name: 'data', columnName: 'data'),
      AdHocColumn(name: 'title', columnName: 'title'),
    ],
  );

  QueryPlan plan0({
    List<FilterClause> filters = const [],
    bool randomOrder = false,
    num? randomSeed,
    List<IndexHint> hints = const [],
    List<FullTextWhere> fullText = const [],
    List<JsonWhereClause> jsonWheres = const [],
    List<DateWhereClause> dateWheres = const [],
    String? lock,
    List<OrderClause> orders = const [],
    QueryPredicate? predicate,
  }) => QueryPlan(
    definition: definition,
    filters: filters,
    randomOrder: randomOrder,
    randomSeed: randomSeed,
    indexHints: hints,
    fullTextWheres: fullText,
    jsonWheres: jsonWheres,
    dateWheres: dateWheres,
    lockClause: lock,
    orders: orders,
    predicate: predicate,
  );

  test('json where null uses JSON_EXTRACT + JSON_TYPE guard', () {
    final plan = plan0(
      filters: const [
        FilterClause(
          field: r'data->"$.author.id"',
          operator: FilterOperator.isNull,
          value: null,
        ),
      ],
    );

    final sql = grammar.compileSelect(plan).sql;
    expect(sql, contains('JSON_EXTRACT'));
    expect(sql, contains(r"'$.author.id'"));
  });

  test('index hints render after FROM clause', () {
    final plan = plan0(
      hints: [
        IndexHint(IndexHintType.use, ['articles_author_index']),
      ],
    );

    final sql = grammar.compileSelect(plan).sql;
    expect(sql, contains('USE INDEX (`articles_author_index`)'));
  });

  test('random ordering uses RAND()', () {
    final plan = plan0(randomOrder: true);
    final sql = grammar.compileSelect(plan).sql;
    expect(sql, contains('ORDER BY RAND()'));
  });

  test('random ordering accepts seed', () {
    final plan = plan0(randomOrder: true, randomSeed: 123);
    final sql = grammar.compileSelect(plan).sql;
    expect(sql, contains('ORDER BY RAND(123)'));
  });

  test('group limit throws when window functions are disabled', () {
    final legacyGrammar = MySqlQueryGrammar(supportsWindowFunctions: false);
    final plan = QueryPlan(
      definition: definition,
      groupLimit: const GroupLimit(column: 'id', limit: 2),
      orders: const [OrderClause(field: 'id')],
    );
    expect(
      () => legacyGrammar.compileSelect(plan),
      throwsA(isA<UnsupportedError>()),
    );
  });

  test('order by json selector unwraps value', () {
    final plan = plan0(
      orders: const [
        OrderClause(
          field: 'data',
          jsonSelector: JsonSelector('data', r'$.name', true),
        ),
      ],
    );
    final sql = grammar.compileSelect(plan).sql;
    expect(sql, contains('JSON_UNQUOTE(JSON_EXTRACT(`articles`.`data`, '));
    expect(sql, contains('ORDER BY'));
  });

  test('full text search compiles MATCH AGAINST clause', () {
    final clause = FullTextWhere(
      columns: const ['title'],
      value: 'laravel',
      mode: FullTextMode.boolean,
    );
    final plan = plan0(fullText: [clause]);

    final compilation = grammar.compileSelect(plan);
    expect(
      compilation.sql,
      contains('MATCH (`title`) AGAINST (? IN BOOLEAN MODE)'),
    );
    expect(compilation.bindings.single, 'laravel');
  });

  test('lock helpers map to MySQL syntax', () {
    final updateSql = grammar.compileSelect(plan0(lock: 'update')).sql;
    expect(updateSql.trim().endsWith('FOR UPDATE'), isTrue);

    final sharedSql = grammar.compileSelect(plan0(lock: 'shared')).sql;
    expect(sharedSql.trim().endsWith('LOCK IN SHARE MODE'), isTrue);
  });

  test('json where contains compiles JSON_CONTAINS', () {
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
    expect(compilation.sql, contains('JSON_CONTAINS'));
    expect(compilation.bindings.last, jsonEncode(['foo']));
  });

  test('json contains key compiles JSON_CONTAINS_PATH', () {
    final plan = plan0(
      jsonWheres: [
        JsonWhereClause.containsKey(column: 'data', path: r'$.meta.author'),
      ],
    );
    final sql = grammar.compileSelect(plan).sql;
    expect(sql, contains('JSON_CONTAINS_PATH'));
    expect(sql, contains("'\$.meta.author'"));
  });

  test('json length compiles JSON_LENGTH comparison', () {
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
    expect(compilation.sql, contains('JSON_LENGTH'));
    expect(compilation.bindings.single, 2);
  });

  test('date predicates wrap DATE()', () {
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
    expect(sql, contains('DATE(`articles`.`title`) = ?'));
  });

  test('json time predicates extract values before casting', () {
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
    expect(
      sql,
      contains(
        "TIME(JSON_UNQUOTE(JSON_EXTRACT(`articles`.`data`, '\$.published'))) = ?",
      ),
    );
  });

  test('json boolean comparisons cast bindings to JSON', () {
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
      contains(
        "JSON_EXTRACT(`articles`.`data`, '\$.featured') = JSON_EXTRACT(",
      ),
    );
    expect(compilation.bindings.single, 'true');
  });
}
