import 'package:driver_tests/driver_tests.dart';
import 'package:ormed/ormed.dart';
import 'package:ormed_postgres/ormed_postgres.dart' show PostgresQueryGrammar;
import 'package:test/test.dart';

class PreviewDriver extends InMemoryQueryExecutor {
  @override
  DriverMetadata get metadata => const DriverMetadata(
    name: 'postgres',
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

  group('postgres join gating', () {
    test('lateral join allowed on postgres', () {
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

      expect(plan.joins.single.isLateral, isTrue);

      final sql = PostgresQueryGrammar().compileSelect(plan).sql;
      expect(sql.toUpperCase(), contains('JOIN LATERAL'));
    });

    test('right join allowed on postgres grammar', () {
      final context = context0();
      final plan = context
          .query<Author>()
          .rightJoin('posts', 'posts.author_id', '=', 'base.id')
          .debugPlan();

      final sql = PostgresQueryGrammar().compileSelect(plan).sql;
      expect(sql.toUpperCase(), contains('RIGHT JOIN'));
    });
  });
}
