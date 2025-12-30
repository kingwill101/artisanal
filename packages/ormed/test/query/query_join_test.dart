import 'package:driver_tests/driver_tests.dart';
import 'package:ormed/ormed.dart';
import 'package:ormed_mysql/ormed_mysql.dart' show MySqlQueryGrammar;
import 'package:ormed_postgres/ormed_postgres.dart' show PostgresQueryGrammar;
import 'package:ormed_sqlite/src/sqlite_grammar.dart' show SqliteQueryGrammar;
import 'package:test/test.dart';

class PreviewDriver extends InMemoryQueryExecutor {
  PreviewDriver(this._name);

  final String _name;

  @override
  DriverMetadata get metadata => DriverMetadata(
    name: _name,
    capabilities: {
      DriverCapability.joins,
      DriverCapability.sqlPreviews,
      DriverCapability.advancedQueryBuilders,
    },
  );
}

void main() {
  ModelRegistry registry = bootstrapOrm();

  QueryContext context0(String driver) =>
      QueryContext(registry: registry, driver: PreviewDriver(driver));

  group('manual joins', () {
    test('join builds join definition', () {
      final context = context0('sqlite');
      final plan = context
          .query<Author>()
          .join('posts', 'posts.author_id', '=', 'base.id')
          .debugPlan();

      expect(plan.joins, hasLength(1));
      final join = plan.joins.single;
      expect(join.type, JoinType.inner);
      expect(join.target.table, 'posts');
      expect(join.conditions.single.left, 'posts.author_id');
      expect(join.conditions.single.right, 'base.id');
    });

    test('joinRelation expands relation metadata', () {
      final context = context0('sqlite');
      final plan = context.query<Author>().joinRelation('posts').debugPlan();

      expect(plan.joins, hasLength(1));
      final join = plan.joins.single;
      expect(join.alias, 'rel_posts_0');
      expect(join.target.table, PostOrmDefinition.definition.tableName);
      final condition = join.conditions.first;
      expect(condition.left, 'rel_posts_0.author_id');
      expect(condition.right, 'base.id');
    });

    test('joinSub stores subquery target', () {
      final context = context0('sqlite');
      final recent = context.query<Post>().whereGreaterThan('id', 0);
      final plan = context
          .query<Author>()
          .joinSub(
            recent,
            'recent_posts',
            'recent_posts.author_id',
            '=',
            'base.id',
          )
          .debugPlan();

      expect(plan.joins, hasLength(1));
      final join = plan.joins.single;
      expect(join.alias, 'recent_posts');
      expect(join.target.isSubquery, isTrue);
    });

    test('sql grammar renders join clause', () {
      final context = context0('sqlite');
      final plan = context
          .query<Author>()
          .join('posts', 'posts.author_id', '=', 'base.id')
          .orderBy('id')
          .debugPlan();

      final sql = SqliteQueryGrammar().compileSelect(plan).sql;
      expect(sql, contains('JOIN "posts"'));
      expect(sql, contains('ON "posts"."author_id" ='));
    });
  });

  group('dialect gating', () {
    test('lateral join allowed on postgres', () {
      final context = context0('postgres');
      final sub = context.query<Post>().limit(1);
      final plan = context
          .query<Author>()
          .joinLateral(
            sub,
            'recent_posts',
            on: (join) => join.on('recent_posts.author_id', '=', 'base.id'),
          )
          .debugPlan();

      final sql = PostgresQueryGrammar().compileSelect(plan).sql;
      expect(sql, contains('JOIN LATERAL'));
    });

    test('lateral join allowed on mysql', () {
      final context = context0('mysql');
      final sub = context.query<Post>().limit(1);
      final plan = context
          .query<Author>()
          .joinLateral(
            sub,
            'recent_posts',
            on: (join) => join.on('recent_posts.author_id', '=', 'base.id'),
          )
          .debugPlan();

      final sql = MySqlQueryGrammar().compileSelect(plan).sql;
      expect(sql, contains('JOIN LATERAL'));
    });

    test('lateral join throws on sqlite grammar', () {
      final context = context0('sqlite');
      final sub = context.query<Post>().limit(1);
      final plan = context
          .query<Author>()
          .joinLateral(
            sub,
            'recent_posts',
            on: (join) => join.on('recent_posts.author_id', '=', 'base.id'),
          )
          .debugPlan();

      expect(
        () => SqliteQueryGrammar().compileSelect(plan),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('right join unsupported on sqlite', () {
      final context = context0('sqlite');
      final plan = context
          .query<Author>()
          .rightJoin('posts', 'posts.author_id', '=', 'base.id')
          .debugPlan();

      expect(
        () => SqliteQueryGrammar().compileSelect(plan),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('right join allowed on postgres grammar', () {
      final context = context0('postgres');
      final plan = context
          .query<Author>()
          .rightJoin('posts', 'posts.author_id', '=', 'base.id')
          .debugPlan();

      final sql = PostgresQueryGrammar().compileSelect(plan).sql;
      expect(sql.toUpperCase(), contains('RIGHT JOIN'));
    });

    test('straight join allowed on mysql grammar', () {
      final context = context0('mysql');
      final plan = context
          .query<Author>()
          .straightJoin('posts', 'posts.author_id', '=', 'base.id')
          .debugPlan();

      final sql = MySqlQueryGrammar().compileSelect(plan).sql;
      expect(sql.toUpperCase(), contains('STRAIGHT_JOIN'));
    });
  });
}
