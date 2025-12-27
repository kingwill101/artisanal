import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

import '../../../driver_tests.dart';

void runRelationMutationTests() {
  ormedGroup('relation mutations', (scopedDataSource) {
    final dataSource = scopedDataSource;
    setUp(() async {
      // Bind connection resolver for Model methods
      Model.bindConnectionResolver(
        resolveConnection: (name) => dataSource.context,
      );
    });

    tearDown(() async {
      Model.unbindConnectionResolver();
    });

    group('setRelation / unsetRelation / clearRelations', () {
      test('setRelation caches relation and marks loaded', () async {
        await dataSource.repo<Author>().insertMany([
          const Author(id: 1, name: 'Alice'),
        ]);
        await dataSource.repo<Post>().insertMany([
          Post(
            id: 1,
            authorId: 1,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);

        final rows = await dataSource.context
            .query<Post>()
            .where('id', 1)
            .get();
        final post = rows.first;

        final author = const Author(id: 1, name: 'Alice');
        post.setRelation('author', author);

        expect(post.relationLoaded('author'), isTrue);
        expect(post.getRelation<Author>('author'), equals(author));
      });

      test('unsetRelation removes cached relation', () async {
        await dataSource.repo<Author>().insertMany([
          const Author(id: 1, name: 'Alice'),
        ]);
        await dataSource.repo<Post>().insertMany([
          Post(
            id: 1,
            authorId: 1,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);

        final rows = await dataSource.context
            .query<Post>()
            .where('id', 1)
            .get();
        final post = rows.first;

        final author = const Author(id: 1, name: 'Alice');
        post.setRelation('author', author);
        expect(post.relationLoaded('author'), isTrue);

        post.unsetRelation('author');

        expect(post.relationLoaded('author'), isFalse);
        expect(post.getRelation<Author>('author'), isNull);
      });

      test('clearRelations removes all cached relations', () async {
        await dataSource.repo<Author>().insertMany([
          const Author(id: 1, name: 'Alice'),
        ]);
        await dataSource.repo<Post>().insertMany([
          Post(
            id: 1,
            authorId: 1,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);
        await dataSource.repo<Tag>().insertMany([
          const Tag(id: 1, label: 'dart'),
        ]);

        final rows = await dataSource.context
            .query<Post>()
            .where('id', 1)
            .get();
        final post = rows.first;

        post.setRelation('author', const Author(id: 1, name: 'Alice'));
        post.setRelation('tags', [const Tag(id: 1, label: 'dart')]);

        expect(post.relationLoaded('author'), isTrue);
        expect(post.relationLoaded('tags'), isTrue);

        post.clearRelations();

        expect(post.relationLoaded('author'), isFalse);
        expect(post.relationLoaded('tags'), isFalse);
        expect(post.loadedRelationNames, isEmpty);
      });
    });

    group('associate() - belongsTo', () {
      test('associates parent and updates foreign key', () async {
        await dataSource.repo<Author>().insertMany([
          const Author(id: 5, name: 'Alice'),
        ]);
        await dataSource.repo<Post>().insertMany([
          Post(
            id: 1,
            authorId: 999,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);

        final rows = await dataSource.context
            .query<Post>()
            .where('id', 1)
            .get();
        final post = rows.first;

        final author = const Author(id: 5, name: 'Alice');
        await post.associate('author', author);

        // Check foreign key was updated
        expect(post.getAttribute<int>('author_id'), equals(5));

        // Check relation is cached
        expect(post.relationLoaded('author'), isTrue);
        expect(post.getRelation<Author>('author'), equals(author));
      });

      test('associate throws for unknown relation', () async {
        await dataSource.repo<Post>().insertMany([
          Post(
            id: 1,
            authorId: 1,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);

        final rows = await dataSource.context
            .query<Post>()
            .where('id', 1)
            .get();
        final post = rows.first;

        expect(
          () => post.associate('invalid', const Author(id: 1, name: 'Test')),
          throwsArgumentError,
        );
      });

      test('associate rejects non-belongsTo relation', () async {
        await dataSource.repo<Author>().insertMany([
          const Author(id: 1, name: 'Alice'),
        ]);

        final rows = await dataSource.context
            .query<Author>()
            .where('id', 1)
            .get();
        final author = rows.first;

        // 'posts' is hasMany, not belongsTo
        expect(
          () => author.associate(
            'posts',
            Post(
              id: 1,
              authorId: 1,
              title: 'Post',
              publishedAt: DateTime(2024),
            ),
          ),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('belongsTo'),
            ),
          ),
        );
      });

      test('returns self for method chaining', () async {
        await dataSource.repo<Author>().insertMany([
          const Author(id: 1, name: 'Alice'),
        ]);
        await dataSource.repo<Post>().insertMany([
          Post(
            id: 1,
            authorId: 999,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);

        final rows = await dataSource.context
            .query<Post>()
            .where('id', 1)
            .get();
        final post = rows.first;

        final result = await post.associate(
          'author',
          const Author(id: 1, name: 'Alice'),
        );

        expect(identical(result, post), isTrue);
      });
    });

    group('dissociate() - belongsTo', () {
      test('dissociates parent and nullifies foreign key', () async {
        await dataSource.repo<Author>().insertMany([
          const Author(id: 1, name: 'Alice'),
        ]);
        await dataSource.repo<Post>().insertMany([
          Post(
            id: 1,
            authorId: 1,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);

        final rows = await dataSource.context
            .query<Post>()
            .where('id', 1)
            .get();
        final post = rows.first;

        // First associate
        post.setRelation('author', const Author(id: 1, name: 'Alice'));
        post.setAttribute('author_id', 1);

        // Then dissociate
        await post.dissociate('author');

        // Check foreign key was nullified
        expect(post.getAttribute<int?>('author_id'), isNull);

        // Check relation is removed from cache
        expect(post.relationLoaded('author'), isFalse);
        expect(post.getRelation<Author>('author'), isNull);
      });

      test('dissociate throws for invalid relation', () async {
        await dataSource.repo<Post>().insertMany([
          Post(
            id: 1,
            authorId: 1,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);

        final rows = await dataSource.context
            .query<Post>()
            .where('id', 1)
            .get();
        final post = rows.first;

        expect(() => post.dissociate('invalid'), throwsArgumentError);
      });

      test('dissociate rejects non-belongsTo relation', () async {
        await dataSource.repo<Author>().insertMany([
          const Author(id: 1, name: 'Alice'),
        ]);

        final rows = await dataSource.context
            .query<Author>()
            .where('id', 1)
            .get();
        final author = rows.first;

        expect(
          () => author.dissociate('posts'),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('belongsTo'),
            ),
          ),
        );
      });

      test('returns self for method chaining', () async {
        await dataSource.repo<Post>().insertMany([
          Post(
            id: 1,
            authorId: 1,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);

        final rows = await dataSource.context
            .query<Post>()
            .where('id', 1)
            .get();
        final post = rows.first;

        final result = await post.dissociate('author');

        expect(identical(result, post), isTrue);
      });
    });

    group('relation cache after mutations', () {
      test(
        'attach refreshes relation cache and loadMissing preserves cache',
        () async {
          await dataSource.repo<Author>().insertMany(const [
            Author(id: 1, name: 'Alice'),
          ]);
          await dataSource.repo<Post>().insertMany([
            Post(
              id: 1,
              authorId: 1,
              title: 'Post 1',
              publishedAt: DateTime(2024),
            ),
          ]);
          await dataSource.repo<Tag>().insertMany(const [
            Tag(id: 1, label: 'dart'),
            Tag(id: 2, label: 'flutter'),
            Tag(id: 3, label: 'ormed'),
          ]);
          await dataSource.repo<PostTag>().insertMany(const [
            PostTag(postId: 1, tagId: 1),
          ]);

          final post =
              (await dataSource.context.query<Post>().where('id', 1).get())
                  .first;

          await post.load('tags');
          expect(post.tags.map((t) => t.id), equals([1]));

          await post.attach('tags', [2, 3]);
          expect(post.tags.map((t) => t.id).toSet(), equals({1, 2, 3}));

          await post.loadMissing(['tags']);
          expect(post.tags.map((t) => t.id).toSet(), equals({1, 2, 3}));

          // If cache is cleared, loadMissing should query again.
          post.unsetRelation('tags');
          await post.loadMissing(['tags']);
          expect(post.tags.map((t) => t.id).toSet(), equals({1, 2, 3}));
        },
      );

      test(
        'associate caches belongsTo and loadMissing preserves cache',
        () async {
          await dataSource.repo<Author>().insertMany(const [
            Author(id: 1, name: 'Alice'),
            Author(id: 2, name: 'Bob'),
          ]);
          await dataSource.repo<Post>().insertMany([
            Post(
              id: 1,
              authorId: 1,
              title: 'Post 1',
              publishedAt: DateTime(2024),
            ),
          ]);

          final post =
              (await dataSource.context.query<Post>().where('id', 1).get())
                  .first;

          await post.load('author');
          expect(post.author?.id, equals(1));

          await post.associate('author', const Author(id: 2, name: 'Bob'));
          expect(post.author?.id, equals(2));

          await post.loadMissing(['author']);
          expect(post.author?.id, equals(2));
        },
      );
    });

    group('attach() - manyToMany', () {
      test('attach creates pivot rows for many-to-many', () async {
        await dataSource.repo<Post>().insertMany([
          Post(
            id: 1,
            authorId: 1,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);
        await dataSource.repo<Tag>().insertMany([
          const Tag(id: 1, label: 'dart'),
          const Tag(id: 2, label: 'flutter'),
          const Tag(id: 3, label: 'web'),
        ]);

        final rows = await dataSource.context
            .query<Post>()
            .where('id', 1)
            .get();
        final post = rows.first;

        await post.attach('tags', [1, 2, 3]);

        // Verify pivot records were created
        final pivotRecords = await dataSource.context
            .query<PostTag>()
            .where('post_id', 1)
            .get();

        expect(pivotRecords, hasLength(3));
        expect(pivotRecords.any((r) => r.tagId == 1), isTrue);
        expect(pivotRecords.any((r) => r.tagId == 2), isTrue);
        expect(pivotRecords.any((r) => r.tagId == 3), isTrue);
      });

      test('attach sets pivot timestamps when enabled', () async {
        await dataSource.repo<Post>().insertMany([
          Post(
            id: 1,
            authorId: 1,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);
        await dataSource.repo<Tag>().insertMany([
          const Tag(id: 1, label: 'dart'),
        ]);

        final post = (await dataSource.context
                .query<Post>()
                .where('id', 1)
                .get())
            .first;

        await post.attach('tags', [1]);

        final pivotRecord = await dataSource.context
            .query<PostTag>()
            .where('post_id', 1)
            .where('tag_id', 1)
            .first();

        expect(pivotRecord, isNotNull);
        expect(pivotRecord!.createdAt, isNotNull);
        expect(pivotRecord.updatedAt, isNotNull);
        expect(
          pivotRecord.updatedAt!.isBefore(pivotRecord.createdAt!),
          isFalse,
        );
      });

      test('attach touches parent and related when configured', () async {
        await dataSource.repo<Post>().insertMany([
          Post(
            id: 10,
            authorId: 1,
            title: 'Post Touch',
            publishedAt: DateTime(2024),
          ),
        ]);
        await dataSource.repo<Tag>().insertMany([
          const Tag(id: 11, label: 'touch'),
        ]);

        final postBefore = await dataSource.context
            .query<Post>()
            .where('id', 10)
            .first();
        final tagBefore = await dataSource.context
            .query<Tag>()
            .where('id', 11)
            .first();

        expect(postBefore, isNotNull);
        expect(tagBefore, isNotNull);

        await Future.delayed(const Duration(milliseconds: 500));
        await postBefore!.attach('tags', [11]);

        final postAfter = await dataSource.context
            .query<Post>()
            .where('id', 10)
            .first();
        final tagAfter = await dataSource.context
            .query<Tag>()
            .where('id', 11)
            .first();

        expect(postAfter, isNotNull);
        expect(tagAfter, isNotNull);
        expect(
          postAfter!.updatedAt!.toDateTime().millisecondsSinceEpoch,
          greaterThan(
            postBefore.updatedAt!.toDateTime().millisecondsSinceEpoch,
          ),
        );
        expect(
          tagAfter!.updatedAt!.toDateTime().millisecondsSinceEpoch,
          greaterThan(
            tagBefore!.updatedAt!.toDateTime().millisecondsSinceEpoch,
          ),
        );
      });

      test('attach with empty list does nothing', () async {
        await dataSource.repo<Post>().insertMany([
          Post(
            id: 1,
            authorId: 1,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);

        final rows = await dataSource.context
            .query<Post>()
            .where('id', 1)
            .get();
        final post = rows.first;

        await post.attach('tags', []);

        final pivotRecords = await dataSource.context
            .query<PostTag>()
            .where('post_id', 1)
            .get();

        expect(pivotRecords, isEmpty);
      });

      test('attach throws for invalid relation name', () async {
        await dataSource.repo<Post>().insertMany([
          Post(
            id: 1,
            authorId: 1,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);

        final rows = await dataSource.context
            .query<Post>()
            .where('id', 1)
            .get();
        final post = rows.first;

        expect(() => post.attach('invalid', [1, 2]), throwsArgumentError);
      });

      test('attach rejects non many-to-many relations', () async {
        await dataSource.repo<Post>().insertMany([
          Post(
            id: 1,
            authorId: 1,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);

        final rows = await dataSource.context
            .query<Post>()
            .where('id', 1)
            .get();
        final post = rows.first;

        expect(
          () => post.attach('author', [1]),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('manyToMany'),
            ),
          ),
        );
      });

      test('returns self for method chaining', () async {
        await dataSource.repo<Post>().insertMany([
          Post(
            id: 1,
            authorId: 1,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);
        await dataSource.repo<Tag>().insertMany([
          const Tag(id: 1, label: 'dart'),
        ]);

        final rows = await dataSource.context
            .query<Post>()
            .where('id', 1)
            .get();
        final post = rows.first;

        final result = await post.attach('tags', [1]);

        expect(identical(result, post), isTrue);
      });
    });

    group('detach() - manyToMany', () {
      test('detaches specific related models', () async {
        await dataSource.repo<Post>().insertMany([
          Post(
            id: 1,
            authorId: 1,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);
        await dataSource.repo<Tag>().insertMany([
          const Tag(id: 1, label: 'dart'),
          const Tag(id: 2, label: 'flutter'),
          const Tag(id: 3, label: 'web'),
        ]);
        await dataSource.repo<PostTag>().insertMany([
          const PostTag(postId: 1, tagId: 1),
          const PostTag(postId: 1, tagId: 2),
          const PostTag(postId: 1, tagId: 3),
        ]);

        final rows = await dataSource.context
            .query<Post>()
            .where('id', 1)
            .get();
        final post = rows.first;

        // Detach tags 1 and 2
        await post.detach('tags', [1, 2]);

        final pivotRecords = await dataSource.context
            .query<PostTag>()
            .where('post_id', 1)
            .get();

        expect(pivotRecords, hasLength(1));
        expect(pivotRecords.first.tagId, equals(3));
      });

      test('detach removes all relations when ids omitted', () async {
        await dataSource.repo<Post>().insertMany([
          Post(
            id: 1,
            authorId: 1,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);
        await dataSource.repo<Tag>().insertMany([
          const Tag(id: 1, label: 'dart'),
          const Tag(id: 2, label: 'flutter'),
        ]);
        await dataSource.repo<PostTag>().insertMany([
          const PostTag(postId: 1, tagId: 1),
          const PostTag(postId: 1, tagId: 2),
        ]);

        final rows = await dataSource.context
            .query<Post>()
            .where('id', 1)
            .get();
        final post = rows.first;

        await post.detach('tags');

        final pivotRecords = await dataSource.context
            .query<PostTag>()
            .where('post_id', 1)
            .get();

        expect(pivotRecords, isEmpty);
      });

      test('detach with empty list detaches all', () async {
        await dataSource.repo<Post>().insertMany([
          Post(
            id: 1,
            authorId: 1,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);
        await dataSource.repo<Tag>().insertMany([
          const Tag(id: 1, label: 'dart'),
        ]);
        await dataSource.repo<PostTag>().insertMany([
          const PostTag(postId: 1, tagId: 1),
        ]);

        final rows = await dataSource.context
            .query<Post>()
            .where('id', 1)
            .get();
        final post = rows.first;

        await post.detach('tags', []);

        final pivotRecords = await dataSource.context
            .query<PostTag>()
            .where('post_id', 1)
            .get();

        expect(pivotRecords, isEmpty);
      });

      test('detach throws for invalid relation', () async {
        await dataSource.repo<Post>().insertMany([
          Post(
            id: 1,
            authorId: 1,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);

        final rows = await dataSource.context
            .query<Post>()
            .where('id', 1)
            .get();
        final post = rows.first;

        expect(() => post.detach('invalid'), throwsArgumentError);
      });

      test('detach rejects non many-to-many relations', () async {
        await dataSource.repo<Post>().insertMany([
          Post(
            id: 1,
            authorId: 1,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);

        final rows = await dataSource.context
            .query<Post>()
            .where('id', 1)
            .get();
        final post = rows.first;

        expect(
          () => post.detach('author'),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('manyToMany'),
            ),
          ),
        );
      });

      test('returns self for method chaining', () async {
        await dataSource.repo<Post>().insertMany([
          Post(
            id: 1,
            authorId: 1,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);

        final rows = await dataSource.context
            .query<Post>()
            .where('id', 1)
            .get();
        final post = rows.first;

        final result = await post.detach('tags');

        expect(identical(result, post), isTrue);
      });
    });

    group('sync() - manyToMany', () {
      test('syncs to match given IDs exactly', () async {
        await dataSource.repo<Post>().insertMany([
          Post(
            id: 1,
            authorId: 1,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);
        await dataSource.repo<Tag>().insertMany([
          const Tag(id: 1, label: 'dart'),
          const Tag(id: 2, label: 'flutter'),
          const Tag(id: 3, label: 'web'),
          const Tag(id: 4, label: 'mobile'),
        ]);
        await dataSource.repo<PostTag>().insertMany([
          const PostTag(postId: 1, tagId: 1),
          const PostTag(postId: 1, tagId: 2),
          const PostTag(postId: 1, tagId: 3),
        ]);

        final rows = await dataSource.context
            .query<Post>()
            .where('id', 1)
            .get();
        final post = rows.first;

        // Currently has tags 1, 2, 3
        // Sync to have tags 2, 3, 4
        await post.sync('tags', [2, 3, 4]);

        final pivotRecords = await dataSource.context
            .query<PostTag>()
            .where('post_id', 1)
            .orderBy('tag_id')
            .get();

        expect(pivotRecords, hasLength(3));
        expect(pivotRecords[0].tagId, equals(2));
        expect(pivotRecords[1].tagId, equals(3));
        expect(pivotRecords[2].tagId, equals(4));
      });

      test('sync with empty list removes all', () async {
        await dataSource.repo<Post>().insertMany([
          Post(
            id: 1,
            authorId: 1,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);
        await dataSource.repo<Tag>().insertMany([
          const Tag(id: 1, label: 'dart'),
          const Tag(id: 2, label: 'flutter'),
        ]);
        await dataSource.repo<PostTag>().insertMany([
          const PostTag(postId: 1, tagId: 1),
          const PostTag(postId: 1, tagId: 2),
        ]);

        final rows = await dataSource.context
            .query<Post>()
            .where('id', 1)
            .get();
        final post = rows.first;

        await post.sync('tags', []);

        final pivotRecords = await dataSource.context
            .query<PostTag>()
            .where('post_id', 1)
            .get();

        expect(pivotRecords, isEmpty);
      });

      test('sync replaces all existing with new IDs', () async {
        await dataSource.repo<Post>().insertMany([
          Post(
            id: 1,
            authorId: 1,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);
        await dataSource.repo<Tag>().insertMany([
          const Tag(id: 1, label: 'dart'),
          const Tag(id: 2, label: 'flutter'),
          const Tag(id: 3, label: 'web'),
        ]);
        await dataSource.repo<PostTag>().insertMany([
          const PostTag(postId: 1, tagId: 1),
        ]);

        final rows = await dataSource.context
            .query<Post>()
            .where('id', 1)
            .get();
        final post = rows.first;

        await post.sync('tags', [2, 3]);

        final pivotRecords = await dataSource.context
            .query<PostTag>()
            .where('post_id', 1)
            .orderBy('tag_id')
            .get();

        expect(pivotRecords, hasLength(2));
        expect(pivotRecords[0].tagId, equals(2));
        expect(pivotRecords[1].tagId, equals(3));
      });

      test('returns self for method chaining', () async {
        await dataSource.repo<Post>().insertMany([
          Post(
            id: 1,
            authorId: 1,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);
        await dataSource.repo<Tag>().insertMany([
          const Tag(id: 1, label: 'dart'),
        ]);

        final rows = await dataSource.context
            .query<Post>()
            .where('id', 1)
            .get();
        final post = rows.first;

        final result = await post.sync('tags', [1]);

        expect(identical(result, post), isTrue);
      });
    });

    group('Method chaining with mutations', () {
      test('can chain associate with other operations', () async {
        await dataSource.repo<Author>().insertMany([
          const Author(id: 1, name: 'Alice'),
        ]);
        await dataSource.repo<Post>().insertMany([
          Post(
            id: 1,
            authorId: 999,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);

        final rows = await dataSource.context
            .query<Post>()
            .where('id', 1)
            .get();
        final post = rows.first;

        final author = const Author(id: 1, name: 'Alice');
        final result = await post.associate('author', author);

        expect(identical(result, post), isTrue);
        expect(post.getAttribute<int>('author_id'), equals(1));
      });

      test('can chain attach, sync operations', () async {
        await dataSource.repo<Post>().insertMany([
          Post(
            id: 1,
            authorId: 1,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);
        await dataSource.repo<Tag>().insertMany([
          const Tag(id: 1, label: 'dart'),
          const Tag(id: 2, label: 'flutter'),
          const Tag(id: 3, label: 'web'),
        ]);

        final rows = await dataSource.context
            .query<Post>()
            .where('id', 1)
            .get();
        final post = rows.first;

        await post.attach('tags', [1, 2]).then((p) => p.sync('tags', [2, 3]));

        final pivotRecords = await dataSource.context
            .query<PostTag>()
            .where('post_id', 1)
            .orderBy('tag_id')
            .get();

        expect(pivotRecords, hasLength(2));
        expect(pivotRecords[0].tagId, equals(2));
        expect(pivotRecords[1].tagId, equals(3));
      });
    });

    group('syncWithoutDetaching() - manyToMany', () {
      test('adds new IDs without removing existing ones', () async {
        await dataSource.repo<Post>().insertMany([
          Post(
            id: 1,
            authorId: 1,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);
        await dataSource.repo<Tag>().insertMany([
          const Tag(id: 1, label: 'dart'),
          const Tag(id: 2, label: 'flutter'),
          const Tag(id: 3, label: 'web'),
        ]);
        await dataSource.repo<PostTag>().insertMany([
          const PostTag(postId: 1, tagId: 1),
        ]);

        final rows = await dataSource.context
            .query<Post>()
            .where('id', 1)
            .get();
        final post = rows.first;

        // Sync without detaching: add 2 and 3, keep 1
        await post.syncWithoutDetaching('tags', [2, 3]);

        final pivotRecords = await dataSource.context
            .query<PostTag>()
            .where('post_id', 1)
            .orderBy('tag_id')
            .get();

        expect(pivotRecords, hasLength(3));
        expect(pivotRecords[0].tagId, equals(1));
        expect(pivotRecords[1].tagId, equals(2));
        expect(pivotRecords[2].tagId, equals(3));
      });

      test('does not duplicate existing IDs', () async {
        await dataSource.repo<Post>().insertMany([
          Post(
            id: 1,
            authorId: 1,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);
        await dataSource.repo<Tag>().insertMany([
          const Tag(id: 1, label: 'dart'),
          const Tag(id: 2, label: 'flutter'),
        ]);
        await dataSource.repo<PostTag>().insertMany([
          const PostTag(postId: 1, tagId: 1),
          const PostTag(postId: 1, tagId: 2),
        ]);

        final rows = await dataSource.context
            .query<Post>()
            .where('id', 1)
            .get();
        final post = rows.first;

        // Try to sync with existing IDs
        await post.syncWithoutDetaching('tags', [1, 2]);

        final pivotRecords = await dataSource.context
            .query<PostTag>()
            .where('post_id', 1)
            .get();

        // Should still only have 2 records
        expect(pivotRecords, hasLength(2));
      });

      test('returns self for method chaining', () async {
        await dataSource.repo<Post>().insertMany([
          Post(
            id: 1,
            authorId: 1,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);
        await dataSource.repo<Tag>().insertMany([
          const Tag(id: 1, label: 'dart'),
        ]);

        final rows = await dataSource.context
            .query<Post>()
            .where('id', 1)
            .get();
        final post = rows.first;

        final result = await post.syncWithoutDetaching('tags', [1]);

        expect(identical(result, post), isTrue);
      });

      test('throws for non-manyToMany relation', () async {
        await dataSource.repo<Post>().insertMany([
          Post(
            id: 1,
            authorId: 1,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);

        final rows = await dataSource.context
            .query<Post>()
            .where('id', 1)
            .get();
        final post = rows.first;

        expect(
          () => post.syncWithoutDetaching('author', [1]),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('manyToMany'),
            ),
          ),
        );
      });
    });

    group('toggle() - manyToMany', () {
      test('attaches missing IDs and detaches existing ones', () async {
        await dataSource.repo<Post>().insertMany([
          Post(
            id: 1,
            authorId: 1,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);
        await dataSource.repo<Tag>().insertMany([
          const Tag(id: 1, label: 'dart'),
          const Tag(id: 2, label: 'flutter'),
          const Tag(id: 3, label: 'web'),
        ]);
        await dataSource.repo<PostTag>().insertMany([
          const PostTag(postId: 1, tagId: 1),
          const PostTag(postId: 1, tagId: 2),
        ]);

        final rows = await dataSource.context
            .query<Post>()
            .where('id', 1)
            .get();
        final post = rows.first;

        // Toggle [2, 3]: 2 exists (detach), 3 missing (attach)
        await post.toggle('tags', [2, 3]);

        final pivotRecords = await dataSource.context
            .query<PostTag>()
            .where('post_id', 1)
            .orderBy('tag_id')
            .get();

        expect(pivotRecords, hasLength(2));
        expect(pivotRecords[0].tagId, equals(1)); // unchanged
        expect(pivotRecords[1].tagId, equals(3)); // attached
      });

      test('attaches all when none exist', () async {
        await dataSource.repo<Post>().insertMany([
          Post(
            id: 1,
            authorId: 1,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);
        await dataSource.repo<Tag>().insertMany([
          const Tag(id: 1, label: 'dart'),
          const Tag(id: 2, label: 'flutter'),
        ]);

        final rows = await dataSource.context
            .query<Post>()
            .where('id', 1)
            .get();
        final post = rows.first;

        await post.toggle('tags', [1, 2]);

        final pivotRecords = await dataSource.context
            .query<PostTag>()
            .where('post_id', 1)
            .get();

        expect(pivotRecords, hasLength(2));
      });

      test('detaches all when all exist', () async {
        await dataSource.repo<Post>().insertMany([
          Post(
            id: 1,
            authorId: 1,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);
        await dataSource.repo<Tag>().insertMany([
          const Tag(id: 1, label: 'dart'),
          const Tag(id: 2, label: 'flutter'),
        ]);
        await dataSource.repo<PostTag>().insertMany([
          const PostTag(postId: 1, tagId: 1),
          const PostTag(postId: 1, tagId: 2),
        ]);

        final rows = await dataSource.context
            .query<Post>()
            .where('id', 1)
            .get();
        final post = rows.first;

        await post.toggle('tags', [1, 2]);

        final pivotRecords = await dataSource.context
            .query<PostTag>()
            .where('post_id', 1)
            .get();

        expect(pivotRecords, isEmpty);
      });

      test('returns self for method chaining', () async {
        await dataSource.repo<Post>().insertMany([
          Post(
            id: 1,
            authorId: 1,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);
        await dataSource.repo<Tag>().insertMany([
          const Tag(id: 1, label: 'dart'),
        ]);

        final rows = await dataSource.context
            .query<Post>()
            .where('id', 1)
            .get();
        final post = rows.first;

        final result = await post.toggle('tags', [1]);

        expect(identical(result, post), isTrue);
      });

      test('throws for non-manyToMany relation', () async {
        await dataSource.repo<Post>().insertMany([
          Post(
            id: 1,
            authorId: 1,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);

        final rows = await dataSource.context
            .query<Post>()
            .where('id', 1)
            .get();
        final post = rows.first;

        expect(
          () => post.toggle('author', [1]),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('manyToMany'),
            ),
          ),
        );
      });
    });

    group('updateExistingPivot() - manyToMany', () {
      test('updates pivot attributes for existing relation', () async {
        await dataSource.repo<Post>().insertMany([
          Post(
            id: 1,
            authorId: 1,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);
        await dataSource.repo<Tag>().insertMany([
          const Tag(id: 1, label: 'dart'),
        ]);
        await dataSource.repo<PostTag>().insertMany([
          const PostTag(postId: 1, tagId: 1),
        ]);

        final rows = await dataSource.context
            .query<Post>()
            .where('id', 1)
            .get();
        final post = rows.first;

        // Note: This test assumes pivot table has additional columns
        // If it doesn't, the update will succeed but have no effect
        await post.updateExistingPivot('tags', 1, {});

        // The pivot record should still exist
        final pivotRecords = await dataSource.context
            .query<PostTag>()
            .where('post_id', 1)
            .get();

        expect(pivotRecords, hasLength(1));
      });

      test('updateExistingPivot bumps updated_at when enabled', () async {
        await dataSource.repo<Post>().insertMany([
          Post(
            id: 1,
            authorId: 1,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);
        await dataSource.repo<Tag>().insertMany([
          const Tag(id: 1, label: 'dart'),
        ]);

        final post =
            (await dataSource.context.query<Post>().where('id', 1).get()).first;
        await post.attach('tags', [1]);

        final before = await dataSource.context
            .query<PostTag>()
            .where('post_id', 1)
            .where('tag_id', 1)
            .first();

        expect(before, isNotNull);
        expect(before!.updatedAt, isNotNull);

        await post.updateExistingPivot('tags', 1, {'note': 'updated'});

        final after = await dataSource.context
            .query<PostTag>()
            .where('post_id', 1)
            .where('tag_id', 1)
            .first();

        expect(after, isNotNull);
        expect(after!.updatedAt, isNotNull);
        expect(after.updatedAt!.isAfter(before.updatedAt!), isTrue);
        expect(after.createdAt, equals(before.createdAt));
      });

      test('returns self for method chaining', () async {
        await dataSource.repo<Post>().insertMany([
          Post(
            id: 1,
            authorId: 1,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);
        await dataSource.repo<Tag>().insertMany([
          const Tag(id: 1, label: 'dart'),
        ]);
        await dataSource.repo<PostTag>().insertMany([
          const PostTag(postId: 1, tagId: 1),
        ]);

        final rows = await dataSource.context
            .query<Post>()
            .where('id', 1)
            .get();
        final post = rows.first;

        final result = await post.updateExistingPivot('tags', 1, {});

        expect(identical(result, post), isTrue);
      });

      test('throws for non-manyToMany relation', () async {
        await dataSource.repo<Post>().insertMany([
          Post(
            id: 1,
            authorId: 1,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);

        final rows = await dataSource.context
            .query<Post>()
            .where('id', 1)
            .get();
        final post = rows.first;

        expect(
          () => post.updateExistingPivot('author', 1, {}),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('manyToMany'),
            ),
          ),
        );
      });
    });

    // ==========================================================================
    // HasOne/HasMany mutation methods: saveRelation, createRelation, etc.
    // ==========================================================================

    group('saveRelation() - hasMany', () {
      test('saves related model with foreign key set', () async {
        await dataSource.repo<Author>().insertMany([
          const Author(id: 1, name: 'Alice'),
        ]);

        final rows = await dataSource.context
            .query<Author>()
            .where('id', 1)
            .get();
        final author = rows.first;

        // Create a post to save
        final post = Post(
          id: 100,
          authorId: 999, // Wrong FK initially
          title: 'New Post',
          publishedAt: DateTime(2024),
        );

        final saved = await author.saveRelation<Post>('posts', post);

        expect(saved.authorId, equals(1)); // FK was set
        expect(saved.title, equals('New Post'));

        // Verify persisted
        final dbPost = await dataSource.context
            .query<Post>()
            .where('id', 100)
            .first();
        expect(dbPost, isNotNull);
        expect(dbPost!.authorId, equals(1));
      });

      test('returns the saved model', () async {
        await dataSource.repo<Author>().insertMany([
          const Author(id: 1, name: 'Alice'),
        ]);

        final rows = await dataSource.context
            .query<Author>()
            .where('id', 1)
            .get();
        final author = rows.first;

        final post = Post(
          id: 101,
          authorId: 999,
          title: 'Test Post',
          publishedAt: DateTime(2024),
        );

        final saved = await author.saveRelation<Post>('posts', post);

        expect(saved, isA<Post>());
        expect(saved.id, equals(101));
      });

      test('throws for non-hasMany/hasOne relation', () async {
        await dataSource.repo<Post>().insertMany([
          Post(
            id: 1,
            authorId: 1,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);

        final rows = await dataSource.context
            .query<Post>()
            .where('id', 1)
            .get();
        final post = rows.first;

        expect(
          () => post.saveRelation<Author>(
            'author',
            const Author(id: 1, name: 'Test'),
          ),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('hasOne or hasMany'),
            ),
          ),
        );
      });
    });

    group('saveManyRelation() - hasMany', () {
      test('saves multiple related models', () async {
        await dataSource.repo<Author>().insertMany([
          const Author(id: 1, name: 'Alice'),
        ]);

        final rows = await dataSource.context
            .query<Author>()
            .where('id', 1)
            .get();
        final author = rows.first;

        final posts = [
          Post(
            id: 200,
            authorId: 999,
            title: 'Post A',
            publishedAt: DateTime(2024),
          ),
          Post(
            id: 201,
            authorId: 999,
            title: 'Post B',
            publishedAt: DateTime(2024),
          ),
        ];

        final saved = await author.saveManyRelation<Post>('posts', posts);

        expect(saved, hasLength(2));
        expect(saved[0].authorId, equals(1));
        expect(saved[1].authorId, equals(1));

        // Verify persisted
        final dbPosts = await dataSource.context.query<Post>().whereIn('id', [
          200,
          201,
        ]).get();
        expect(dbPosts, hasLength(2));
      });
    });

    group('createRelation() - hasMany', () {
      test('creates related model from attributes', () async {
        await dataSource.repo<Author>().insertMany([
          const Author(id: 1, name: 'Alice'),
        ]);

        final rows = await dataSource.context
            .query<Author>()
            .where('id', 1)
            .get();
        final author = rows.first;

        final created = await author.createRelation<Post>('posts', {
          'id': 300,
          'title': 'Created Post',
          'published_at': DateTime(2024),
        });

        expect(created.authorId, equals(1)); // FK was set
        expect(created.title, equals('Created Post'));

        // Verify persisted
        final dbPost = await dataSource.context
            .query<Post>()
            .where('id', 300)
            .first();
        expect(dbPost, isNotNull);
        expect(dbPost!.authorId, equals(1));
      });

      test('returns the created model', () async {
        await dataSource.repo<Author>().insertMany([
          const Author(id: 1, name: 'Alice'),
        ]);

        final rows = await dataSource.context
            .query<Author>()
            .where('id', 1)
            .get();
        final author = rows.first;

        final created = await author.createRelation<Post>('posts', {
          'id': 301,
          'title': 'Test Create',
          'published_at': DateTime(2024),
        });

        expect(created, isA<Post>());
        expect(created.id, equals(301));
      });

      test('throws for non-hasMany/hasOne relation', () async {
        await dataSource.repo<Post>().insertMany([
          Post(
            id: 1,
            authorId: 1,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);

        final rows = await dataSource.context
            .query<Post>()
            .where('id', 1)
            .get();
        final post = rows.first;

        expect(
          () =>
              post.createRelation<Author>('author', {'id': 1, 'name': 'Test'}),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('hasOne or hasMany'),
            ),
          ),
        );
      });

      test('accepts InsertDto as input', () async {
        final author = await AuthorModelFactory.factory().create(
          context: dataSource.context,
        );

        final created = await author.createRelation<Post>(
          'posts',
          PostInsertDto(title: 'DTO Post', publishedAt: DateTime(2024)),
        );

        expect(created.authorId, equals(author.id)); // FK was set
        expect(created.title, equals('DTO Post'));
      });

      test('accepts UpdateDto as input', () async {
        final author = await AuthorModelFactory.factory().create(
          context: dataSource.context,
        );

        final created = await author.createRelation<Post>(
          'posts',
          PostUpdateDto(title: 'UpdateDto Post', publishedAt: DateTime(2024)),
        );

        expect(created.authorId, equals(author.id)); // FK was set
        expect(created.title, equals('UpdateDto Post'));
      });
    });

    group('createManyRelation() - hasMany', () {
      test('creates multiple related models', () async {
        final author = await AuthorModelFactory.factory().create(
          context: dataSource.context,
        );

        final created = await author.createManyRelation<Post>('posts', [
          {'title': 'Post X', 'published_at': DateTime(2024)},
          {'title': 'Post Y', 'published_at': DateTime(2024)},
        ]);

        expect(created, hasLength(2));
        expect(created[0].authorId, equals(author.id));
        expect(created[1].authorId, equals(author.id));

        // Verify persisted
        final dbPosts = await dataSource.context.query<Post>().whereIn('id', [
          created[0].id,
          created[1].id,
        ]).get();
        expect(dbPosts, hasLength(2));
      });

      test('accepts list of mixed input types (DTOs and maps)', () async {
        final author = await AuthorModelFactory.factory().create(
          context: dataSource.context,
        );

        final created = await author.createManyRelation<Post>('posts', [
          {'title': 'Map Post', 'published_at': DateTime(2024)},
          PostInsertDto(title: 'DTO Post', publishedAt: DateTime(2024)),
          PostUpdateDto(title: 'UpdateDto Post', publishedAt: DateTime(2024)),
        ]);

        expect(created, hasLength(3));
        expect(created.every((p) => p.authorId == author.id), isTrue);
        expect(created[0].title, equals('Map Post'));
        expect(created[1].title, equals('DTO Post'));
        expect(created[2].title, equals('UpdateDto Post'));
      });
    });

    group('createQuietlyRelation() - hasMany', () {
      test(
        'creates related model (behaves like createRelation for now)',
        () async {
          final author = await AuthorModelFactory.factory().create(
            context: dataSource.context,
          );

          final created = await author.createQuietlyRelation<Post>('posts', {
            'title': 'Quiet Post',
            'published_at': DateTime(2024),
          });

          expect(created.authorId, equals(author.id));
          expect(created.title, equals('Quiet Post'));

          // Verify persisted
          final dbPost = await dataSource.context
              .query<Post>()
              .where('id', created.id)
              .first();
          expect(dbPost, isNotNull);
        },
      );

      test('suppresses model events when creating', () async {
        final author = await AuthorModelFactory.factory().create(
          context: dataSource.context,
        );

        // Track emitted events
        final events = <String>[];
        final creatingUnsub = dataSource.context.events.on<ModelCreatingEvent>((
          event,
        ) {
          if (event.tableName == 'posts') events.add('creating');
        });
        final createdUnsub = dataSource.context.events.on<ModelCreatedEvent>((
          event,
        ) {
          if (event.tableName == 'posts') events.add('created');
        });
        final savingUnsub = dataSource.context.events.on<ModelSavingEvent>((
          event,
        ) {
          if (event.tableName == 'posts') events.add('saving');
        });
        final savedUnsub = dataSource.context.events.on<ModelSavedEvent>((
          event,
        ) {
          if (event.tableName == 'posts') events.add('saved');
        });

        try {
          // Use createQuietlyRelation - should suppress events
          await author.createQuietlyRelation<Post>('posts', {
            'title': 'Quiet Post No Events',
            'published_at': DateTime(2024),
          });

          // No events should be emitted for quietly created models
          expect(
            events,
            isEmpty,
            reason: 'createQuietlyRelation should suppress all events',
          );
        } finally {
          creatingUnsub();
          createdUnsub();
          savingUnsub();
          savedUnsub();
        }
      });
    });

    group('createManyQuietlyRelation() - hasMany', () {
      test('creates multiple related models without events', () async {
        final author = await AuthorModelFactory.factory().create(
          context: dataSource.context,
        );

        final created = await author.createManyQuietlyRelation<Post>('posts', [
          {'title': 'Quiet A', 'published_at': DateTime(2024)},
          {'title': 'Quiet B', 'published_at': DateTime(2024)},
        ]);

        expect(created, hasLength(2));
        expect(created[0].authorId, equals(author.id));
        expect(created[1].authorId, equals(author.id));
      });

      test('suppresses model events when creating multiple', () async {
        final author = await AuthorModelFactory.factory().create(
          context: dataSource.context,
        );

        // Track emitted events
        final events = <String>[];
        final creatingUnsub = dataSource.context.events.on<ModelCreatingEvent>((
          event,
        ) {
          if (event.tableName == 'posts') events.add('creating');
        });
        final createdUnsub = dataSource.context.events.on<ModelCreatedEvent>((
          event,
        ) {
          if (event.tableName == 'posts') events.add('created');
        });

        try {
          await author.createManyQuietlyRelation<Post>('posts', [
            {'title': 'Quiet X', 'published_at': DateTime(2024)},
            {'title': 'Quiet Y', 'published_at': DateTime(2024)},
          ]);

          // No events should be emitted
          expect(
            events,
            isEmpty,
            reason: 'createManyQuietlyRelation should suppress all events',
          );
        } finally {
          creatingUnsub();
          createdUnsub();
        }
      });

      test('accepts list of mixed input types (DTOs and maps)', () async {
        final author = await AuthorModelFactory.factory().create(
          context: dataSource.context,
        );

        final created = await author.createManyQuietlyRelation<Post>('posts', [
          {'title': 'Quiet Map', 'published_at': DateTime(2024)},
          PostInsertDto(title: 'Quiet DTO', publishedAt: DateTime(2024)),
          PostUpdateDto(title: 'Quiet UpdateDto', publishedAt: DateTime(2024)),
        ]);

        expect(created, hasLength(3));
        expect(created.every((p) => p.authorId == author.id), isTrue);
        expect(created[0].title, equals('Quiet Map'));
        expect(created[1].title, equals('Quiet DTO'));
        expect(created[2].title, equals('Quiet UpdateDto'));
      });

      test('accepts InsertDto as input', () async {
        final author = await AuthorModelFactory.factory().create(
          context: dataSource.context,
        );

        final created = await author.createQuietlyRelation<Post>(
          'posts',
          PostInsertDto(title: 'Quiet DTO Post', publishedAt: DateTime(2024)),
        );

        expect(created.authorId, equals(author.id));
        expect(created.title, equals('Quiet DTO Post'));
      });
    });

    group('withoutEvents() - Query', () {
      test('insert suppresses creating/created events', () async {
        final events = <String>[];
        final creatingUnsub = dataSource.context.events.on<ModelCreatingEvent>((
          event,
        ) {
          if (event.tableName == 'authors') events.add('creating');
        });
        final createdUnsub = dataSource.context.events.on<ModelCreatedEvent>((
          event,
        ) {
          if (event.tableName == 'authors') events.add('created');
        });

        try {
          // Normal insert should emit events
          await dataSource.context.query<Author>().insertInput(
            const Author(id: 900, name: 'Normal Insert'),
          );
          expect(events, containsAll(['creating', 'created']));
          events.clear();

          // withoutEvents() should suppress events
          await dataSource.context.query<Author>().withoutEvents().insertInput(
            const Author(id: 901, name: 'Quiet Insert'),
          );
          expect(
            events,
            isEmpty,
            reason: 'withoutEvents() should suppress events',
          );
        } finally {
          creatingUnsub();
          createdUnsub();
        }
      });

      test('update suppresses updating/updated events', () async {
        await dataSource.repo<Author>().insertMany([
          const Author(id: 950, name: 'Before Update'),
        ]);

        final events = <String>[];
        final savingUnsub = dataSource.context.events.on<ModelSavingEvent>((
          event,
        ) {
          if (event.tableName == 'authors') events.add('saving');
        });
        final savedUnsub = dataSource.context.events.on<ModelSavedEvent>((
          event,
        ) {
          if (event.tableName == 'authors') events.add('saved');
        });

        try {
          // withoutEvents() update should suppress events
          await dataSource.context
              .query<Author>()
              .where('id', 950)
              .withoutEvents()
              .update({'name': 'After Update'});
          expect(
            events,
            isEmpty,
            reason: 'withoutEvents() should suppress update events',
          );
        } finally {
          savingUnsub();
          savedUnsub();
        }
      });
    });
  });
}
