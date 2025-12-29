import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

import '../../../models.dart';

void runFullTextSearchTests() {
  ormedGroup(
    'full text search',
    (dataSource) {
      test('whereFullText returns matching rows', () async {
        final now = DateTime.utc(2024, 1, 1);
        await dataSource.repo<Post>().insertMany([
          Post(
            id: 1,
            authorId: 1,
            title: 'Dart tips',
            content: 'Full text search with Dart',
            publishedAt: now,
          ),
          Post(
            id: 2,
            authorId: 1,
            title: 'Rust guide',
            content: 'Systems programming overview',
            publishedAt: now,
          ),
          Post(
            id: 3,
            authorId: 1,
            title: 'Searching with ORMs',
            content: 'Dart query builders',
            publishedAt: now,
          ),
        ]);

        final results = await dataSource.context
            .query<Post>()
            .whereFullText(
              ['title', 'content'],
              'dart',
              language: 'simple',
              mode: FullTextMode.boolean,
            )
            .orderBy('id')
            .get();

        expect(results.map((post) => post.id).toList(), equals([1, 3]));
      });

      test('adds full text clause to the query plan', () {
        final query = dataSource.context
            .query<Post>()
            .whereFullText(['title', 'content'], 'dart');

        final plan = query.debugPlan();
        expect(plan.fullTextWheres, hasLength(1));

        final clause = plan.fullTextWheres.single;
        expect(clause.columns, equals(['title', 'content']));
        expect(clause.value, equals('dart'));
        expect(clause.language, isNull);
        expect(clause.mode, equals(FullTextMode.natural));
        expect(clause.expanded, isFalse);
      });

      test('passes full text index name through the plan', () {
        final query = dataSource.context.query<Post>().whereFullText(
              ['title', 'content'],
              'dart',
              indexName: 'posts_title_content_fulltext',
            );

        final plan = query.debugPlan();
        expect(plan.fullTextWheres, hasLength(1));
        expect(
          plan.fullTextWheres.single.indexName,
          equals('posts_title_content_fulltext'),
        );
      });

      test('retains bindings in order', () {
        final preview = dataSource.context
            .query<Post>()
            .whereFullText(['title', 'content'], 'dart')
            .toSql();

        expect(preview.parameters, equals(['dart']));
      });
    },
    // Full-text indexes (notably MySQL/MariaDB) do not see uncommitted rows.
    refreshStrategy: DatabaseIsolationStrategy.truncate,
  );
}
