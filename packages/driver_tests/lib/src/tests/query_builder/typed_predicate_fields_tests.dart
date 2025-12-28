import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

import '../../models/models.dart';

void runTypedPredicateFieldsTests() {
  ormedGroup('Typed predicate fields', (dataSource) {
    int nextId() {
      final seed = DateTime.now().microsecondsSinceEpoch % 100000;
      return seed + Random().nextInt(1000) + 1000;
    }

    test('where callback uses typed field accessors', () async {
      final baseId = nextId();
      final aliceName = 'Alice_$baseId';
      final bobName = 'Bob_$baseId';
      await dataSource.repo<Author>().insertMany([
        Author(id: baseId, name: aliceName),
        Author(id: baseId + 1, name: bobName),
      ]);

      final authors = await dataSource.context
          .query<Author>()
          .where((q) => q.name.eq(aliceName))
          .get();

      expect(authors, hasLength(1));
      expect(authors.first.name, equals(aliceName));
    });

    test('whereTyped callback uses typed field accessors', () async {
      final baseId = nextId();
      final aliceName = 'Alice_$baseId';
      final bobName = 'Bob_$baseId';
      await dataSource.repo<Author>().insertMany([
        Author(id: baseId, name: aliceName),
        Author(id: baseId + 1, name: bobName),
      ]);

      final authors = await dataSource.context
          .query<Author>()
          .whereTyped((q) => q.name.eq(bobName))
          .get();

      expect(authors, hasLength(1));
      expect(authors.first.name, equals(bobName));
    });

    test('orWhere callback combines typed predicates', () async {
      final baseId = nextId();
      final aliceName = 'Alice_$baseId';
      final bobName = 'Bob_$baseId';
      await dataSource.repo<Author>().insertMany([
        Author(id: baseId, name: aliceName),
        Author(id: baseId + 1, name: bobName),
      ]);

      final authors = await dataSource.context
          .query<Author>()
          .where((q) => q.name.eq(aliceName))
          .orWhere((q) => q.name.eq(bobName))
          .get();

      expect(authors, hasLength(2));
      expect(authors.map((a) => a.name), containsAll([aliceName, bobName]));
    });

    test('orWhereTyped callback combines typed predicates', () async {
      final baseId = nextId();
      final aliceName = 'Alice_$baseId';
      final bobName = 'Bob_$baseId';
      await dataSource.repo<Author>().insertMany([
        Author(id: baseId, name: aliceName),
        Author(id: baseId + 1, name: bobName),
      ]);

      final authors = await dataSource.context
          .query<Author>()
          .whereTyped((q) => q.name.eq(aliceName))
          .orWhereTyped((q) => q.name.eq(bobName))
          .get();

      expect(authors, hasLength(2));
      expect(authors.map((a) => a.name), containsAll([aliceName, bobName]));
    });

    test('between/notBetween/in/notIn work on typed fields', () async {
      final baseId = nextId();
      await dataSource.repo<Author>().insertMany([
        Author(id: baseId, name: 'Alice_$baseId'),
        Author(id: baseId + 1, name: 'Bob_$baseId'),
      ]);

      final between = await dataSource.context
          .query<Author>()
          .where((q) => q.id.between(baseId, baseId))
          .get();
      expect(between, hasLength(1));
      expect(between.first.id, equals(baseId));

      final notBetween = await dataSource.context
          .query<Author>()
          .where((q) => q.id.notBetween(baseId, baseId))
          .get();
      expect(notBetween, hasLength(1));
      expect(notBetween.first.id, equals(baseId + 1));

      final inResults = await dataSource.context
          .query<Author>()
          .where((q) => q.id.in_([baseId]))
          .get();
      expect(inResults, hasLength(1));
      expect(inResults.first.id, equals(baseId));

      final notInResults = await dataSource.context
          .query<Author>()
          .where((q) => q.id.notIn([baseId]))
          .get();
      expect(notInResults, hasLength(1));
      expect(notInResults.first.id, equals(baseId + 1));
    });

    test('null checks and like filters work on typed fields', () async {
      final baseId = nextId();
      await dataSource.repo<Author>().insertMany([
        Author(id: baseId, name: 'Alice_$baseId'),
      ]);
      await dataSource.repo<Post>().insertMany([
        Post(
          id: baseId,
          authorId: baseId,
          title: 'Alpha_$baseId',
          content: null,
          publishedAt: DateTime(2024),
        ),
        Post(
          id: baseId + 1,
          authorId: baseId,
          title: 'Beta_$baseId',
          content: 'body',
          publishedAt: DateTime(2024, 2),
        ),
      ]);

      final nullContent = await dataSource.context
          .query<Post>()
          .where((q) => q.content.isNull())
          .get();
      expect(nullContent, hasLength(1));
      expect(nullContent.first.title, contains('Alpha_'));

      final notNullContent = await dataSource.context
          .query<Post>()
          .where((q) => q.content.isNotNull())
          .get();
      expect(notNullContent, hasLength(1));
      expect(notNullContent.first.title, contains('Beta_'));

      final likeMatch = await dataSource.context
          .query<Post>()
          .where((q) => q.title.like('Alpha%'))
          .get();
      expect(likeMatch, hasLength(1));
      expect(likeMatch.first.title, contains('Alpha_'));

      final notLikeMatch = await dataSource.context
          .query<Post>()
          .where((q) => q.title.notLike('Alpha%'))
          .get();
      expect(notLikeMatch, hasLength(1));
      expect(notLikeMatch.first.title, contains('Beta_'));
    });

    test(
      'case-insensitive like variants are available when supported',
      () async {
        final supportsCaseInsensitive = dataSource.options.driver.metadata
            .supportsCapability(DriverCapability.caseInsensitiveLike);
        if (!supportsCaseInsensitive) {
          return;
        }

        final baseId = nextId();
        await dataSource.repo<Author>().insertMany([
          Author(id: baseId, name: 'Alice_$baseId'),
        ]);
        await dataSource.repo<Post>().insertMany([
          Post(
            id: baseId,
            authorId: baseId,
            title: 'Alpha_$baseId',
            content: 'body',
            publishedAt: DateTime(2024),
          ),
        ]);

        final iLikeMatch = await dataSource.context
            .query<Post>()
            .where((q) => q.title.iLike('alpha%'))
            .get();
        expect(iLikeMatch, hasLength(1));

        final notILikeMatch = await dataSource.context
            .query<Post>()
            .where((q) => q.title.notILike('alpha%'))
            .get();
        expect(notILikeMatch, isEmpty);
      },
    );

    test('missing predicate field throws a NoSuchMethodError', () {
      final query = dataSource.context.query<Author>();
      expect(
        () => query.where((q) => q.missingField.eq('nope')).get(),
        throwsA(isA<NoSuchMethodError>()),
      );
    });

    test('typed and untyped callbacks generate the same SQL', () {
      final untyped = dataSource.context
          .query<Author>()
          .where((q) => q.name.eq('Same'))
          .toSql();
      final typed = dataSource.context
          .query<Author>()
          .whereTyped((q) => q.name.eq('Same'))
          .toSql();

      expect(typed.sql, equals(untyped.sql));
      expect(typed.parameters, equals(untyped.parameters));
    });

    test('typed and untyped whereHas generate the same SQL', () {
      final untyped = dataSource.context
          .query<Author>()
          .whereHas('posts', (q) => q.where('title', 'Same'))
          .toSql();
      final typed = dataSource.context
          .query<Author>()
          .whereHasPosts((q) => q.title.eq('Same'))
          .toSql();

      expect(typed.sql, equals(untyped.sql));
      expect(typed.parameters, equals(untyped.parameters));
    });

    test('reserved field names are skipped in generated predicate fields', () async {
      final uri = await Isolate.resolvePackageUri(
        Uri.parse('package:driver_tests/src/models/predicate_collision.orm.dart'),
      );
      expect(uri, isNotNull);
      final contents = await File.fromUri(uri!).readAsString();
      final start = contents.indexOf(
        'extension PredicateCollisionPredicateFields',
      );
      expect(start, isNot(equals(-1)));
      final end = contents.indexOf(
        'void registerPredicateCollisionEventHandlers',
        start,
      );
      expect(end, isNot(equals(-1)));
      final extensionBody = contents.substring(start, end);
      expect(extensionBody, isNot(contains('get where')));
      expect(extensionBody, isNot(contains('get orWhere')));
      expect(extensionBody, contains('get id'));
    });

    test('whereHas relation constraint uses typed callback', () async {
      final baseId = nextId();
      final aliceName = 'Alice_$baseId';
      final bobName = 'Bob_$baseId';
      await dataSource.repo<Author>().insertMany([
        Author(id: baseId, name: aliceName),
        Author(id: baseId + 1, name: bobName),
      ]);

      await dataSource.repo<Post>().insertMany([
        Post(
          id: baseId,
          authorId: baseId,
          title: 'Post 1 by $aliceName',
          publishedAt: DateTime(2024),
        ),
        Post(
          id: baseId + 1,
          authorId: baseId + 1,
          title: 'Post 1 by $bobName',
          publishedAt: DateTime(2024, 2),
        ),
      ]);

      final authors = await dataSource.context
          .query<Author>()
          .whereHasPosts((q) => q.title.eq('Post 1 by $aliceName'))
          .get();

      expect(authors, hasLength(1));
      expect(authors.first.name, equals(aliceName));
    });

    test('withRelation helper filters eager-loaded relations', () async {
      final baseId = nextId();
      final aliceName = 'Alice_$baseId';
      final bobName = 'Bob_$baseId';
      await dataSource.repo<Author>().insertMany([
        Author(id: baseId, name: aliceName),
        Author(id: baseId + 1, name: bobName),
      ]);

      await dataSource.repo<Post>().insertMany([
        Post(
          id: baseId,
          authorId: baseId,
          title: 'Post 1 by $aliceName',
          publishedAt: DateTime(2024),
        ),
        Post(
          id: baseId + 1,
          authorId: baseId,
          title: 'Post 2 by $aliceName',
          publishedAt: DateTime(2024, 2),
        ),
        Post(
          id: baseId + 2,
          authorId: baseId + 1,
          title: 'Post 1 by $bobName',
          publishedAt: DateTime(2024, 3),
        ),
      ]);

      final authors = await dataSource.context
          .query<Author>()
          .withPosts((q) => q.title.eq('Post 2 by $aliceName'))
          .where('id', baseId)
          .get();

      expect(authors, hasLength(1));
      final author = authors.first;
      expect(author.relationLoaded('posts'), isTrue);
      expect(author.posts, hasLength(1));
      expect(author.posts.first.title, equals('Post 2 by $aliceName'));
    });
  });
}
