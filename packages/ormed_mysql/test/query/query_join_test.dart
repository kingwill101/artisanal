import 'package:driver_tests/driver_tests.dart';
import 'package:ormed/ormed.dart';
import 'package:ormed_mysql/ormed_mysql.dart' show MySqlQueryGrammar;
import 'package:test/test.dart';

class PreviewDriver extends InMemoryQueryExecutor {
  @override
  DriverMetadata get metadata => const DriverMetadata(
    name: 'mysql',
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

  group('mysql join gating', () {
    test('lateral join allowed on mysql', () {
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

      final sql = MySqlQueryGrammar().compileSelect(plan).sql;
      expect(sql, contains('JOIN LATERAL'));
    });

    test('straight join allowed on mysql grammar', () {
      final context = context0();
      final plan = context
          .query<Author>()
          .straightJoin('posts', 'posts.author_id', '=', 'base.id')
          .debugPlan();

      final sql = MySqlQueryGrammar().compileSelect(plan).sql;
      expect(sql.toUpperCase(), contains('STRAIGHT_JOIN'));
    });
  });
}
