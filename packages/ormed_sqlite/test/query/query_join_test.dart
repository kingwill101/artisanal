import 'package:driver_tests/driver_tests.dart';
import 'package:ormed/ormed.dart';
import 'package:ormed_sqlite/src/sqlite_grammar.dart' show SqliteQueryGrammar;
import 'package:test/test.dart';

class PreviewDriver extends InMemoryQueryExecutor {
  @override
  DriverMetadata get metadata => const DriverMetadata(
    name: 'sqlite',
    capabilities: {
      DriverCapability.joins,
      DriverCapability.sqlPreviews,
      DriverCapability.advancedQueryBuilders,
    },
  );
}

void main() {
  ModelRegistry registry = bootstrapOrm();

  QueryContext context0() =>
      QueryContext(registry: registry, driver: PreviewDriver());

  group('sqlite join gating', () {
    test('sql grammar renders join clause', () {
      final context = context0();
      final plan = context
          .query<Author>()
          .join('posts', 'posts.author_id', '=', 'base.id')
          .orderBy('id')
          .debugPlan();

      final sql = SqliteQueryGrammar().compileSelect(plan).sql;
      expect(sql, contains('JOIN "posts"'));
      expect(sql, contains('ON "posts"."author_id" ='));
    });

    test('lateral join throws on sqlite grammar', () {
      final context = context0();
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
      final context = context0();
      final plan = context
          .query<Author>()
          .rightJoin('posts', 'posts.author_id', '=', 'base.id')
          .debugPlan();

      expect(
        () => SqliteQueryGrammar().compileSelect(plan),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });
}
