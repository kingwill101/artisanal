import 'package:driver_tests/driver_tests.dart';
import 'package:ormed/ormed.dart';
import 'package:test/test.dart';
import '../support/mock_driver.dart';

void main() {
  ModelRegistry registry = bootstrapOrm();

  QueryContext context0() =>
      QueryContext(registry: registry, driver: MockDriver());

  group('manual joins', () {
    test('join builds join definition', () {
      final context = context0();
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
      final context = context0();
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
      final context = context0();
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
  });
}
