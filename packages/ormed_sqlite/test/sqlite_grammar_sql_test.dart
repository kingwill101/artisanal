import 'package:ormed/ormed.dart';
import 'package:ormed_sqlite/src/sqlite_grammar.dart';
import 'package:test/test.dart';

void main() {
  final grammar = SqliteQueryGrammar();
  final definition = AdHocModelDefinition(
    tableName: 'articles',
    columns: const [
      AdHocColumn(name: 'id', columnName: 'id', isPrimaryKey: true),
      AdHocColumn(name: 'data', columnName: 'data'),
    ],
  );

  QueryPlan plan0({
    List<JsonWhereClause> jsonWheres = const [],
    List<DateWhereClause> dateWheres = const [],
    QueryPredicate? predicate,
  }) => QueryPlan(
    definition: definition,
    jsonWheres: jsonWheres,
    dateWheres: dateWheres,
    predicate: predicate,
  );

  test('json where not null uses json_extract', () {
    final plan = QueryPlan(
      definition: definition,
      filters: const [
        FilterClause(
          field: r'data->"$.metadata.author"',
          operator: FilterOperator.isNotNull,
          value: null,
        ),
      ],
    );

    final sql = grammar.compileSelect(plan).sql;
    expect(sql, contains('json_extract'));
    expect(sql, contains(r"'$.metadata.author'"));
  });

  test('offset without limit still compiles via LIMIT -1', () {
    final plan = QueryPlan(definition: definition, offset: 5);
    final compilation = grammar.compileSelect(plan);
    expect(compilation.sql, contains('LIMIT -1 OFFSET ?'));
    expect(compilation.bindings.single, 5);
  });

  test('lock clauses are ignored', () {
    final sql = grammar
        .compileSelect(QueryPlan(definition: definition, lockClause: 'update'))
        .sql;
    expect(sql.contains('FOR UPDATE'), isFalse);
  });

  test('full text clauses compile using FTS table', () {
    final fullTextDefinition = AdHocModelDefinition(
      tableName: 'articles',
      columns: const [
        AdHocColumn(name: 'id', columnName: 'id', isPrimaryKey: true),
        AdHocColumn(name: 'title', columnName: 'title'),
        AdHocColumn(name: 'body', columnName: 'body'),
      ],
    );

    String ftsTableName(String table, String indexName) {
      final raw = '${table}_$indexName'.replaceAll(
        RegExp(r'[^A-Za-z0-9]+'),
        '_',
      );
      final collapsed = raw.replaceAll(RegExp(r'_+'), '_');
      final base = collapsed.isEmpty ? 'idx' : collapsed;
      return '${base}_fts';
    }

    final clause = FullTextWhere(
      columns: const ['title', 'body'],
      value: 'dart',
      tableName: 'articles',
    );
    final plan = QueryPlan(
      definition: fullTextDefinition,
      fullTextWheres: [clause],
    );

    final compilation = grammar.compileSelect(plan);
    final sql = compilation.sql;
    final expectedIndexName = 'articles_title_body_fulltext';
    final expectedFts = ftsTableName('articles', expectedIndexName);

    expect(sql, contains('MATCH'));
    expect(sql, contains('"articles".rowid'));
    expect(sql, contains('"$expectedFts"'));
    expect(compilation.bindings.single, 'dart');
  });

  test('full text clauses honor explicit index names', () {
    final fullTextDefinition = AdHocModelDefinition(
      tableName: 'articles',
      columns: const [
        AdHocColumn(name: 'id', columnName: 'id', isPrimaryKey: true),
        AdHocColumn(name: 'title', columnName: 'title'),
      ],
    );

    String ftsTableName(String table, String indexName) {
      final raw = '${table}_$indexName'.replaceAll(
        RegExp(r'[^A-Za-z0-9]+'),
        '_',
      );
      final collapsed = raw.replaceAll(RegExp(r'_+'), '_');
      final base = collapsed.isEmpty ? 'idx' : collapsed;
      return '${base}_fts';
    }

    const indexName = 'articles_title_search';
    final clause = FullTextWhere(
      columns: const ['title'],
      value: 'orm',
      tableName: 'articles',
      indexName: indexName,
    );
    final plan = QueryPlan(
      definition: fullTextDefinition,
      fullTextWheres: [clause],
    );

    final compilation = grammar.compileSelect(plan);
    final expectedFts = ftsTableName('articles', indexName);
    expect(compilation.sql, contains('"$expectedFts"'));
    expect(compilation.bindings.single, 'orm');
  });

  test('json contains compiles json_each query', () {
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
    expect(compilation.sql, contains('json_each'));
    expect(compilation.bindings.single, 'foo');
  });

  test('json contains key uses json_type', () {
    final plan = plan0(
      jsonWheres: [
        JsonWhereClause.containsKey(column: 'data', path: r'$.meta.author'),
      ],
    );
    final sql = grammar.compileSelect(plan).sql;
    expect(
      sql,
      contains(r"""json_extract("articles"."data", '$.meta.author')"""),
    );
  });

  test('json length compiles json_array_length comparison', () {
    final plan = plan0(
      jsonWheres: [
        JsonWhereClause.length(
          column: 'data',
          path: r'$.items',
          lengthOperator: '<=',
          lengthValue: 5,
        ),
      ],
    );
    final compilation = grammar.compileSelect(plan);
    expect(compilation.sql, contains('json_array_length'));
    expect(compilation.bindings.single, 5);
  });

  test('json boolean comparisons wrap placeholders with json()', () {
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
    const jsonPathLiteral = r"'$.featured'";
    expect(
      compilation.sql,
      contains(
        'json_extract("articles"."data", $jsonPathLiteral) = '
        "json_extract(json(?), '\$')",
      ),
    );
    expect(compilation.bindings.single, 'true');
  });

  test('date predicates convert via strftime', () {
    final plan = plan0(
      dateWheres: [
        DateWhereClause(
          column: 'data',
          path: r'$',
          component: DateComponent.date,
          operator: '=',
          value: '2024-01-01',
        ),
      ],
    );
    final sql = grammar.compileSelect(plan).sql;
    expect(sql, contains("strftime('%Y-%m-%d', \"articles\".\"data\")"));
    expect(sql, contains('CAST(? AS TEXT)'));
  });

  test('time predicates extract JSON paths', () {
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
    expect(sql, contains('json_extract'));
    expect(sql, contains("strftime('%H:%M:%S'"));
  });

  test('day predicates zero pad bindings', () {
    final plan = plan0(
      dateWheres: [
        DateWhereClause(
          column: 'data',
          path: r'$',
          component: DateComponent.day,
          operator: '=',
          value: 5,
        ),
      ],
    );
    final compilation = grammar.compileSelect(plan);
    expect(compilation.bindings.single, '05');
  });

  test('like predicates keep LIKE and original bindings', () {
    final plan = QueryPlan(
      definition: definition,
      predicate: const FieldPredicate(
        field: 'data',
        operator: PredicateOperator.like,
        value: '%Foo_',
      ),
    );

    final compilation = grammar.compileSelect(plan);
    expect(compilation.sql, contains('"articles"."data" LIKE ?'));
    expect(compilation.bindings.single, '%Foo_');
  });

  test('case insensitive like falls back to LIKE', () {
    final plan = QueryPlan(
      definition: definition,
      predicate: const FieldPredicate(
        field: 'data',
        operator: PredicateOperator.iLike,
        value: '%foo%',
        caseInsensitive: true,
      ),
    );

    final compilation = grammar.compileSelect(plan);
    expect(compilation.sql, contains('LIKE LOWER(?)'));
    expect(compilation.bindings.single, '%foo%');
  });

  test('group limit uses row number when window functions available', () {
    final limitedPlan = QueryPlan(
      definition: definition,
      groupLimit: const GroupLimit(column: 'id', limit: 2),
      orders: const [OrderClause(field: 'id')],
    );
    final sql = grammar.compileSelect(limitedPlan).sql;
    expect(sql, contains('ROW_NUMBER() OVER'));
    expect(sql, contains('__orm_group'));
  });

  test('group limit degrades when window functions disabled', () {
    final legacyGrammar = SqliteQueryGrammar(supportsWindowFunctions: false);
    final limitedPlan = QueryPlan(
      definition: definition,
      groupLimit: const GroupLimit(column: 'id', limit: 2),
      orders: const [OrderClause(field: 'id')],
    );
    final sql = legacyGrammar.compileSelect(limitedPlan).sql;
    expect(sql.contains('ROW_NUMBER'), isFalse);
    expect(sql.contains('__orm_group'), isFalse);
  });

  test('wrapUnion nests each select', () {
    final unionPlan = QueryPlan(
      definition: definition,
      filters: const [
        FilterClause(field: 'id', operator: FilterOperator.equals, value: 2),
      ],
    );
    final plan = QueryPlan(
      definition: definition,
      unions: [QueryUnion(plan: unionPlan)],
    );
    final sql = grammar.compileSelect(plan).sql.toLowerCase();
    expect(sql, contains('union'));
    expect(sql, contains('select * from (select'));
  });
}
