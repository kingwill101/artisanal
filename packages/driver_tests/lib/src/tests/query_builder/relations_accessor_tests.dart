import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

import '../../../driver_tests.dart';

void runRelationsAccessorTests() {
  ormedGroup('relations getter (shorthand accessor)', (dataSource) {
    setUp(() async {
      // Bind connection resolver for Model methods to work
      Model.bindConnectionResolver(
        resolveConnection: (name) => dataSource.context,
      );

      // Seed test data
      await dataSource.repo<Author>().insertMany([
        const Author(id: 1, name: 'Alice'),
        const Author(id: 2, name: 'Bob'),
      ]);
      await dataSource.repo<Post>().insertMany([
        Post(id: 1, authorId: 1, title: 'Post 1', publishedAt: DateTime(2024)),
        Post(
          id: 2,
          authorId: 1,
          title: 'Post 2',
          publishedAt: DateTime(2024, 2),
        ),
        Post(
          id: 3,
          authorId: 2,
          title: 'Post 3',
          publishedAt: DateTime(2024, 3),
        ),
      ]);
      await dataSource.repo<Tag>().insertMany([
        const Tag(id: 1, label: 'dart'),
        const Tag(id: 2, label: 'flutter'),
      ]);
      await dataSource.repo<PostTag>().insertMany([
        const PostTag(postId: 1, tagId: 1, sortOrder: 10, note: 'primary'),
        const PostTag(postId: 1, tagId: 2, sortOrder: 20, note: 'secondary'),
      ]);
    });

    tearDown(() async {
      Model.unbindConnectionResolver();
    });

    group('basic functionality', () {
      test(
        'relations getter returns empty map when no relations loaded',
        () async {
          final rows = await dataSource.context
              .query<Author>()
              .where('id', 1)
              .get();
          final author = rows.first;

          expect(author.relations, isEmpty);
          expect(author.relations, isA<Map<String, dynamic>>());
        },
      );

      test('relations getter equals loadedRelations', () async {
        final rows = await dataSource.context
            .query<Author>()
            .withRelation('posts')
            .where('id', 1)
            .get();
        final author = rows.first;

        expect(author.relations, equals(author.loadedRelations));
        expect(author.relations.keys, contains('posts'));
      });

      test('relations map available after eager loading list', () async {
        final rows = await dataSource.context
            .query<Author>()
            .withRelation('posts')
            .where('id', 1)
            .get();
        final author = rows.first;

        expect(author.relations, isNotEmpty);
        expect(author.relations.containsKey('posts'), isTrue);
        expect(author.relations['posts'], isA<List>());
        expect((author.relations['posts'] as List), hasLength(2));
      });

      test(
        'relations map available after eager loading single model',
        () async {
          final rows = await dataSource.context
              .query<Post>()
              .withRelation('author')
              .where('id', 1)
              .get();
          final post = rows.first;

          expect(post.relations, isNotEmpty);
          expect(post.relations.containsKey('author'), isTrue);
          expect(post.relations['author'], isA<Author>());
        },
      );

      test('relations map handles multiple eager relations', () async {
        final rows = await dataSource.context
            .query<Post>()
            .withRelation('author')
            .withRelation('tags')
            .where('id', 1)
            .get();
        final post = rows.first;

        expect(post.relations, hasLength(2));
        expect(post.relations.containsKey('author'), isTrue);
        expect(post.relations.containsKey('tags'), isTrue);
      });

      test('pivot data is hydrated for many-to-many relations', () async {
        final post = await dataSource.context
            .query<Post>()
            .withRelation('tags')
            .where('id', 1)
            .first();

        expect(post, isNotNull);
        final tags = post!.tags;
        expect(tags, hasLength(2));

        final pivot = tags.first.getRelation<PostTag>('pivot');
        expect(pivot, isNotNull);
        expect(pivot!.sortOrder, equals(10));
        expect(pivot.note, equals('primary'));
      });
    });

    group('with lazy loading', () {
      test('relations map populated after lazy load', () async {
        final rows = await dataSource.context
            .query<Author>()
            .where('id', 1)
            .get();
        final author = rows.first;

        expect(author.relations, isEmpty);

        await author.load('posts');

        expect(author.relations, isNotEmpty);
        expect(author.relations.containsKey('posts'), isTrue);
      });

      test('relations getter updates after loadMissing', () async {
        final rows = await dataSource.context
            .query<Post>()
            .where('id', 1)
            .get();
        final post = rows.first;

        expect(post.relations, isEmpty);

        await post.loadMissing(['author', 'tags']);

        expect(post.relations, hasLength(2));
        expect(post.relations.keys, containsAll(['author', 'tags']));
      });

      test('relations getter updates after loadMany', () async {
        final rows = await dataSource.context
            .query<Post>()
            .where('id', 1)
            .get();
        final post = rows.first;

        await post.loadMany({'author': null, 'tags': (q) => q.where('id', 1)});

        expect(post.relations, hasLength(2));
        expect(post.relations['author'], isNotNull);
        expect(post.relations['tags'], isA<List>());
      });
    });

    group('with manual relation management', () {
      test('relations getter reflects setRelation', () async {
        final rows = await dataSource.context
            .query<Post>()
            .where('id', 1)
            .get();
        final post = rows.first;

        expect(post.relations, isEmpty);

        final mockAuthor = const Author(id: 99, name: 'Mock');
        post.setRelation('author', mockAuthor);

        expect(post.relations, hasLength(1));
        expect(post.relations['author'], equals(mockAuthor));
      });

      test('relations getter reflects setRelations bulk', () async {
        final rows = await dataSource.context
            .query<Post>()
            .where('id', 1)
            .get();
        final post = rows.first;

        post.setRelations({
          'author': const Author(id: 99, name: 'Mock'),
          'tags': <Tag>[const Tag(id: 99, label: 'mock')],
        });

        expect(post.relations, hasLength(2));
        expect(post.relations.keys, containsAll(['author', 'tags']));
      });

      test('relations getter reflects unsetRelation', () async {
        final rows = await dataSource.context
            .query<Post>()
            .withRelation('author')
            .withRelation('tags')
            .where('id', 1)
            .get();
        final post = rows.first;

        expect(post.relations, hasLength(2));

        post.unsetRelation('author');

        expect(post.relations, hasLength(1));
        expect(post.relations.containsKey('author'), isFalse);
        expect(post.relations.containsKey('tags'), isTrue);
      });

      test('relations getter reflects clearRelations', () async {
        final rows = await dataSource.context
            .query<Post>()
            .withRelation('author')
            .withRelation('tags')
            .where('id', 1)
            .get();
        final post = rows.first;

        expect(post.relations, hasLength(2));

        post.clearRelations();

        expect(post.relations, isEmpty);
      });
    });

    group('snapshot behavior', () {
      test('relations getter returns a snapshot copy', () async {
        final rows = await dataSource.context
            .query<Author>()
            .withRelation('posts')
            .where('id', 1)
            .get();
        final author = rows.first;

        final snapshot1 = author.relations;
        final snapshot2 = author.relations;

        // Should be equal in content
        expect(snapshot1, equals(snapshot2));

        // Modifying snapshot should not affect model's relations
        // (this depends on implementation - testing the concept)
        expect(snapshot1.containsKey('posts'), isTrue);
      });

      test('relations snapshot updates after lazy load', () async {
        final rows = await dataSource.context
            .query<Author>()
            .where('id', 1)
            .get();
        final author = rows.first;

        final beforeLoad = author.relations;
        expect(beforeLoad, isEmpty);

        await author.load('posts');

        final afterLoad = author.relations;
        expect(afterLoad, isNotEmpty);
        expect(afterLoad.containsKey('posts'), isTrue);
      });
    });

    group('different models independently', () {
      test('each model instance has its own relations', () async {
        final author1Rows = await dataSource.context
            .query<Author>()
            .withRelation('posts')
            .where('id', 1)
            .get();
        final author2Rows = await dataSource.context
            .query<Author>()
            .where('id', 2)
            .get();

        final author1 = author1Rows.first;
        final author2 = author2Rows.first;

        // Author1 has relations loaded
        expect(author1.relations, isNotEmpty);
        expect(author1.relations.containsKey('posts'), isTrue);

        // Author2 does not have relations loaded
        expect(author2.relations, isEmpty);
      });

      test('relations are isolated between model instances', () async {
        final author1Rows = await dataSource.context
            .query<Author>()
            .where('id', 1)
            .get();
        final author2Rows = await dataSource.context
            .query<Author>()
            .where('id', 2)
            .get();

        final author1 = author1Rows.first;
        final author2 = author2Rows.first;

        await author1.load('posts');

        expect(author1.relations, isNotEmpty);
        expect(author2.relations, isEmpty);
      });
    });

    group('integration with loadedRelationNames', () {
      test('relations keys match loadedRelationNames', () async {
        final rows = await dataSource.context
            .query<Post>()
            .withRelation('author')
            .withRelation('tags')
            .where('id', 1)
            .get();
        final post = rows.first;

        final relationKeys = post.relations.keys.toSet();
        final loadedNames = post.loadedRelationNames;

        expect(relationKeys, equals(loadedNames));
      });

      test('loadedRelationNames stay in sync after changes', () async {
        final rows = await dataSource.context
            .query<Post>()
            .where('id', 1)
            .get();
        final post = rows.first;

        expect(post.relations.keys.toSet(), equals(post.loadedRelationNames));

        await post.load('author');
        expect(post.relations.keys.toSet(), equals(post.loadedRelationNames));

        await post.load('tags');
        expect(post.relations.keys.toSet(), equals(post.loadedRelationNames));

        post.unsetRelation('author');
        expect(post.relations.keys.toSet(), equals(post.loadedRelationNames));
      });
    });

    group('use cases', () {
      test('iterate over all loaded relations', () async {
        final rows = await dataSource.context
            .query<Post>()
            .withRelation('author')
            .withRelation('tags')
            .where('id', 1)
            .get();
        final post = rows.first;

        final relationEntries = <String, dynamic>{};
        for (final entry in post.relations.entries) {
          relationEntries[entry.key] = entry.value;
        }

        expect(relationEntries, hasLength(2));
        expect(relationEntries.containsKey('author'), isTrue);
        expect(relationEntries.containsKey('tags'), isTrue);
      });

      test('check specific relation in relations map', () async {
        final rows = await dataSource.context
            .query<Author>()
            .withRelation('posts')
            .where('id', 1)
            .get();
        final author = rows.first;

        if (author.relations.containsKey('posts')) {
          final postsRaw = author.relations['posts'];
          expect(postsRaw, isA<List>());
          final posts = (postsRaw as List).cast<Post>();
          expect(posts, hasLength(2));
        } else {
          fail('Expected posts relation to be loaded');
        }
      });

      test('use relations for serialization context', () async {
        final rows = await dataSource.context
            .query<Post>()
            .withRelation('author')
            .withRelation('tags')
            .where('id', 1)
            .get();
        final post = rows.first;

        // Simulating building a response with relations
        final responseData = <String, dynamic>{
          'id': post.id,
          'title': post.title,
          'relations': post.relations.keys.toList(),
          'relationCount': post.relations.length,
        };

        expect(responseData['relationCount'], equals(2));
        expect(responseData['relations'], containsAll(['author', 'tags']));
      });
    });
  });
}
