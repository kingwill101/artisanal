import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

import '../../../driver_tests.dart';

/// Comprehensive tests for model relations and generated accessors.
/// Addresses issue #8: "Add comprehensive tests for model relations and generated accessors"
///
/// Tests cover:
/// - Generated $Model().someRelation() query accessors
/// - belongsTo relations
/// - hasMany relations
/// - hasOne relations
/// - manyToMany relations
/// - morphMany relations
/// - Nullable vs non-nullable field types for list relations
/// - Eager loading
/// - Lazy loading
/// - Nested relations
void runGeneratedRelationAccessorsTests() {
  ormedGroup('generated relation accessors', (dataSource) {
    setUp(() async {
      // Bind connection resolver for Model.load() to work
      Model.bindConnectionResolver(
        resolveConnection: (name) => dataSource.context,
      );

      // Seed test data
      await dataSource.repo<Author>().insertMany([
        const Author(id: 1, name: 'Alice'),
        const Author(id: 2, name: 'Bob'),
        const Author(id: 3, name: 'Charlie'),
      ]);

      await dataSource.repo<Post>().insertMany([
        Post(
          id: 1,
          authorId: 1,
          title: 'Post 1 by Alice',
          publishedAt: DateTime(2024),
          views: 100,
        ),
        Post(
          id: 2,
          authorId: 1,
          title: 'Post 2 by Alice',
          publishedAt: DateTime(2024, 2),
          views: 250,
        ),
        Post(
          id: 3,
          authorId: 2,
          title: 'Post 3 by Bob',
          publishedAt: DateTime(2024, 3),
          views: 150,
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
        const PostTag(postId: 2, tagId: 1),
        const PostTag(postId: 3, tagId: 3),
      ]);

      await dataSource.repo<User>().insertMany([
        const User(id: 1, email: 'alice@test.com'),
        const User(id: 2, email: 'bob@test.com'),
      ]);

      await dataSource.repo<UserProfile>().insertMany([
        const UserProfile(id: 1, userId: 1, bio: 'Alice bio'),
      ]);

      await dataSource.repo<Comment>().insertMany([
        const Comment(id: 1, body: 'Comment 1'),
        const Comment(id: 2, body: 'Comment 2'),
        const Comment(id: 3, body: 'Comment 3'),
      ]);

      // Seed nullable relations test data
      await dataSource.repo<NullableRelationsTest>().insertMany([
        const NullableRelationsTest(id: 1, name: 'Test 1'),
        const NullableRelationsTest(id: 2, name: 'Test 2'),
      ]);
    });

    tearDown(() async {
      Model.unbindConnectionResolver();
    });

    group('belongsTo relation', () {
      test('generated accessor returns typed query', () async {
        final rows =
            await dataSource.context.query<Post>().where('id', 1).get();
        final post = rows.first;

        // The generated extension method: postAuthorQuery()
        final authorQuery = post.authorQuery();

        expect(authorQuery, isA<Query<Author>>());

        // Execute the query
        final author = await authorQuery.first();
        expect(author, isNotNull);
        expect(author!.name, equals('Alice'));
      });

      test('eager loading belongsTo with withRelation', () async {
        final rows = await dataSource.context
            .query<Post>()
            .withRelation('author')
            .where('id', 1)
            .get();
        final post = rows.first;

        expect(post.relationLoaded('author'), isTrue);
        expect(post.author, isNotNull);
        expect(post.author!.name, equals('Alice'));
      });

      test('lazy loading belongsTo with load()', () async {
        final rows =
            await dataSource.context.query<Post>().where('id', 1).get();
        final post = rows.first;

        expect(post.relationLoaded('author'), isFalse);

        await post.load('author');

        expect(post.relationLoaded('author'), isTrue);
        expect(post.author, isNotNull);
        expect(post.author!.name, equals('Alice'));
      });

      test('belongsTo returns null for nullable relation when no parent', () async {
        // Create a post with non-existent author
        await dataSource.repo<Post>().insertMany([
          Post(
            id: 99,
            authorId: 999, // non-existent
            title: 'Orphan post',
            publishedAt: DateTime(2024),
          ),
        ]);

        final rows =
            await dataSource.context.query<Post>().where('id', 99).get();
        final post = rows.first;

        await post.load('author');

        expect(post.relationLoaded('author'), isTrue);
        expect(post.author, isNull);
      });
    });

    group('hasMany relation', () {
      test('generated accessor returns typed query', () async {
        final rows =
            await dataSource.context.query<Author>().where('id', 1).get();
        final author = rows.first;

        // The generated extension method: authorPostsQuery()
        final postsQuery = author.postsQuery();

        expect(postsQuery, isA<Query<Post>>());

        // Execute the query
        final posts = await postsQuery.get();
        expect(posts, hasLength(2));
      });

      test('eager loading hasMany with withRelation', () async {
        final rows = await dataSource.context
            .query<Author>()
            .withRelation('posts')
            .where('id', 1)
            .get();
        final author = rows.first;

        expect(author.relationLoaded('posts'), isTrue);
        expect(author.posts, hasLength(2));
        expect(author.posts.map((p) => p.title).toList(), contains('Post 1 by Alice'));
      });

      test('lazy loading hasMany with load()', () async {
        final rows =
            await dataSource.context.query<Author>().where('id', 1).get();
        final author = rows.first;

        expect(author.relationLoaded('posts'), isFalse);

        await author.load('posts');

        expect(author.relationLoaded('posts'), isTrue);
        expect(author.posts, hasLength(2));
      });

      test('hasMany returns empty list when no related records', () async {
        // Author 3 (Charlie) has no posts
        final rows =
            await dataSource.context.query<Author>().where('id', 3).get();
        final author = rows.first;

        await author.load('posts');

        expect(author.relationLoaded('posts'), isTrue);
        expect(author.posts, isEmpty);
        expect(author.posts, isA<List<Post>>());
      });

      test('hasMany generated accessor never returns null', () async {
        final rows =
            await dataSource.context.query<Author>().where('id', 3).get();
        final author = rows.first;

        // Before loading, getter should return empty list (not null)
        // from the base class default
        expect(author.posts, isNotNull);
        expect(author.posts, isA<List<Post>>());

        // After loading empty result
        await author.load('posts');
        expect(author.posts, isNotNull);
        expect(author.posts, isEmpty);
      });
    });

    group('hasOne relation', () {
      test('eager loading hasOne with withRelation', () async {
        final rows = await dataSource.context
            .query<User>()
            .withRelation('userProfile')
            .where('id', 1)
            .get();
        final user = rows.first;

        expect(user.relationLoaded('userProfile'), isTrue);
        expect(user.userProfile, isNotNull);
        expect(user.userProfile!.bio, equals('Alice bio'));
      });

      test('lazy loading hasOne with load()', () async {
        final rows =
            await dataSource.context.query<User>().where('id', 1).get();
        final user = rows.first;

        expect(user.relationLoaded('userProfile'), isFalse);

        await user.load('userProfile');

        expect(user.relationLoaded('userProfile'), isTrue);
        expect(user.userProfile, isNotNull);
      });

      test('hasOne returns null when no related record', () async {
        // User 2 (Bob) has no profile
        final rows =
            await dataSource.context.query<User>().where('id', 2).get();
        final user = rows.first;

        await user.load('userProfile');

        expect(user.relationLoaded('userProfile'), isTrue);
        expect(user.userProfile, isNull);
      });
    });

    group('manyToMany relation', () {
      test('generated accessor returns typed query', () async {
        final rows =
            await dataSource.context.query<Post>().where('id', 1).get();
        final post = rows.first;

        // The generated extension method: postTagsQuery()
        final tagsQuery = post.tagsQuery();

        expect(tagsQuery, isA<Query<Tag>>());

        // Execute the query
        final tags = await tagsQuery.get();
        expect(tags, hasLength(2));
        expect(tags.map((t) => t.label).toSet(), containsAll(['dart', 'flutter']));
      });

      test('eager loading manyToMany with withRelation', () async {
        final rows = await dataSource.context
            .query<Post>()
            .withRelation('tags')
            .where('id', 1)
            .get();
        final post = rows.first;

        expect(post.relationLoaded('tags'), isTrue);
        expect(post.tags, hasLength(2));
      });

      test('lazy loading manyToMany with load()', () async {
        final rows =
            await dataSource.context.query<Post>().where('id', 1).get();
        final post = rows.first;

        expect(post.relationLoaded('tags'), isFalse);

        await post.load('tags');

        expect(post.relationLoaded('tags'), isTrue);
        expect(post.tags, hasLength(2));
      });

      test('manyToMany returns empty list when no related records', () async {
        // Create a post with no tags
        await dataSource.repo<Post>().insertMany([
          Post(
            id: 100,
            authorId: 1,
            title: 'No tags post',
            publishedAt: DateTime(2024),
          ),
        ]);

        final rows =
            await dataSource.context.query<Post>().where('id', 100).get();
        final post = rows.first;

        await post.load('tags');

        expect(post.relationLoaded('tags'), isTrue);
        expect(post.tags, isEmpty);
        expect(post.tags, isA<List<Tag>>());
      });
    });

    group('morphMany relation', () {
      test(
        'eager loading morphMany with withRelation',
        () async {
          // Seed photos for post 1
          await dataSource.repo<Photo>().insertMany([
            const Photo(
              id: 1,
              imageableId: 1,
              imageableType: 'Post',
              path: 'photo1.jpg',
            ),
            const Photo(
              id: 2,
              imageableId: 1,
              imageableType: 'Post',
              path: 'photo2.jpg',
            ),
          ]);

          final rows = await dataSource.context
              .query<Post>()
              .withRelation('photos')
              .where('id', 1)
              .get();
          final post = rows.first;

          expect(post.relationLoaded('photos'), isTrue);
          expect(post.photos, hasLength(2));
        },
      );

      test(
        'lazy loading morphMany with load()',
        () async {
          // Seed photos for post 2
          await dataSource.repo<Photo>().insertMany([
            const Photo(
              id: 10,
              imageableId: 2,
              imageableType: 'Post',
              path: 'photo10.jpg',
            ),
          ]);

          final rows =
              await dataSource.context.query<Post>().where('id', 2).get();
          final post = rows.first;

          await post.load('photos');

          expect(post.relationLoaded('photos'), isTrue);
          expect(post.photos, hasLength(1));
        },
      );
    });

    group('nullable vs non-nullable list relations', () {
      test('nullable field type coalesces to empty list', () async {
        final rows = await dataSource.context
            .query<NullableRelationsTest>()
            .where('id', 1)
            .get();
        final model = rows.first;

        // Before loading: getter returns empty list from coalescing
        expect(model.nullableFieldComments, isNotNull);
        expect(model.nullableFieldComments, isA<List<Comment>>());
        expect(model.nullableFieldComments, isEmpty);
      });

      test('non-nullable field type returns directly', () async {
        final rows = await dataSource.context
            .query<NullableRelationsTest>()
            .where('id', 1)
            .get();
        final model = rows.first;

        // Before loading: getter returns from super directly
        expect(model.nonNullableFieldComments, isNotNull);
        expect(model.nonNullableFieldComments, isA<List<Comment>>());
        expect(model.nonNullableFieldComments, isEmpty);
      });

      test('both relation types can be loaded', () async {
        final rows = await dataSource.context
            .query<NullableRelationsTest>()
            .where('id', 1)
            .get();
        final model = rows.first;

        // Load both relations (they may be empty since comments don't reference this model)
        await model.load('nullableFieldComments');
        await model.load('nonNullableFieldComments');

        expect(model.relationLoaded('nullableFieldComments'), isTrue);
        expect(model.relationLoaded('nonNullableFieldComments'), isTrue);

        // Both should be non-null lists after loading (even if empty)
        expect(model.nullableFieldComments, isNotNull);
        expect(model.nonNullableFieldComments, isNotNull);
        expect(model.nullableFieldComments, isA<List<Comment>>());
        expect(model.nonNullableFieldComments, isA<List<Comment>>());
      });
    });

    group('nested relations', () {
      test('eager load nested belongsTo.hasMany', () async {
        final rows = await dataSource.context
            .query<Post>()
            .withRelation('author.posts')
            .where('id', 1)
            .get();
        final post = rows.first;

        expect(post.relationLoaded('author'), isTrue);
        expect(post.author, isNotNull);
        expect(post.author!.relationLoaded('posts'), isTrue);
        expect(post.author!.posts, hasLength(2));
      });

      test('lazy load nested relations with dot notation', () async {
        final rows =
            await dataSource.context.query<Post>().where('id', 1).get();
        final post = rows.first;

        await post.load('author.posts');

        expect(post.relationLoaded('author'), isTrue);
        expect(post.author!.relationLoaded('posts'), isTrue);
      });

      test('eager load hasMany.manyToMany (posts.tags)', () async {
        final rows = await dataSource.context
            .query<Author>()
            .withRelation('posts.tags')
            .where('id', 1)
            .get();
        final author = rows.first;

        expect(author.relationLoaded('posts'), isTrue);
        expect(author.posts, hasLength(2));

        for (final post in author.posts) {
          expect(post.relationLoaded('tags'), isTrue);
        }
      });
    });

    group('multiple relations', () {
      test('load multiple relations with loadMany', () async {
        final rows =
            await dataSource.context.query<Post>().where('id', 1).get();
        final post = rows.first;

        await post.loadMany({'author': null, 'tags': null});

        expect(post.relationLoaded('author'), isTrue);
        expect(post.relationLoaded('tags'), isTrue);
      });

      test('eager load multiple relations', () async {
        final rows = await dataSource.context
            .query<Post>()
            .withRelation('author')
            .withRelation('tags')
            .where('id', 1)
            .get();
        final post = rows.first;

        expect(post.relationLoaded('author'), isTrue);
        expect(post.relationLoaded('tags'), isTrue);
        expect(post.author!.name, equals('Alice'));
        expect(post.tags, hasLength(2));
      });

      test('loadMissing only loads unloaded relations', () async {
        final rows = await dataSource.context
            .query<Post>()
            .withRelation('author')
            .where('id', 1)
            .get();
        final post = rows.first;

        expect(post.relationLoaded('author'), isTrue);
        expect(post.relationLoaded('tags'), isFalse);

        await post.loadMissing(['author', 'tags']);

        // Both should now be loaded
        expect(post.relationLoaded('author'), isTrue);
        expect(post.relationLoaded('tags'), isTrue);
      });
    });

    group('relation with constraints', () {
      test('withRelation with constraint callback', () async {
        final rows = await dataSource.context
            .query<Author>()
            .withRelation('posts', (q) => q.where('views', 100, PredicateOperator.greaterThan))
            .where('id', 1)
            .get();
        final author = rows.first;

        expect(author.relationLoaded('posts'), isTrue);
        // Only posts with views > 100 (Post 2 with 250 views)
        expect(author.posts, hasLength(1));
        expect(author.posts.first.views, equals(250));
      });

      test('lazy load with constraint', () async {
        final rows =
            await dataSource.context.query<Author>().where('id', 1).get();
        final author = rows.first;

        await author.load(
          'posts',
          (q) => q.where('views', 0, PredicateOperator.greaterThanOrEqual),
        );

        expect(author.posts, hasLength(2));
      });
    });

    group('batch loading relations', () {
      test('Model.loadRelations loads relation on multiple models', () async {
        final authors = await dataSource.context
            .query<Author>()
            .whereIn('id', [1, 2])
            .get();

        expect(authors, hasLength(2));

        await Model.loadRelations(authors, 'posts');

        for (final author in authors) {
          expect(author.relationLoaded('posts'), isTrue);
        }
      });
    });

    group('relation mutations via model methods', () {
      test('associate() sets foreign key for belongsTo', () async {
        // Create a post with no author
        await dataSource.repo<Post>().insertMany([
          Post(
            id: 50,
            authorId: 0,
            title: 'Unassigned post',
            publishedAt: DateTime(2024),
          ),
        ]);

        final rows =
            await dataSource.context.query<Post>().where('id', 50).get();
        final post = rows.first;

        // Associate with existing author
        final author = const Author(id: 1, name: 'Alice');
        await post.associate('author', author);

        // Foreign key should be updated
        expect(post.getAttribute<int>('author_id'), equals(1));
        // Relation should be cached
        expect(post.relationLoaded('author'), isTrue);
        expect(post.author?.id, equals(1));
      });

      test('dissociate() clears foreign key for belongsTo', () async {
        final rows =
            await dataSource.context.query<Post>().where('id', 1).get();
        final post = rows.first;

        // First load the relation
        await post.load('author');
        expect(post.author, isNotNull);

        // Dissociate
        await post.dissociate('author');

        // Foreign key should be nullified
        expect(post.getAttribute<int?>('author_id'), isNull);
        // Relation cache should be cleared
        expect(post.relationLoaded('author'), isFalse);
      });

      test('attach() creates pivot records for manyToMany', () async {
        // Create a post with no tags
        await dataSource.repo<Post>().insertMany([
          Post(
            id: 51,
            authorId: 1,
            title: 'Post without tags',
            publishedAt: DateTime(2024),
          ),
        ]);

        final rows =
            await dataSource.context.query<Post>().where('id', 51).get();
        final post = rows.first;

        // Attach tags
        await post.attach('tags', [1, 2]);

        // Verify pivot records
        final pivotRecords = await dataSource.context
            .query<PostTag>()
            .where('post_id', 51)
            .get();

        expect(pivotRecords, hasLength(2));
        expect(pivotRecords.map((r) => r.tagId).toSet(), equals({1, 2}));
      });

      test('detach() removes pivot records for manyToMany', () async {
        final rows =
            await dataSource.context.query<Post>().where('id', 1).get();
        final post = rows.first;

        // Post 1 has tags 1 and 2 attached
        // Detach tag 1
        await post.detach('tags', [1]);

        final pivotRecords = await dataSource.context
            .query<PostTag>()
            .where('post_id', 1)
            .get();

        expect(pivotRecords, hasLength(1));
        expect(pivotRecords.first.tagId, equals(2));
      });

      test('sync() replaces all pivot records for manyToMany', () async {
        // Create a post with some tags
        await dataSource.repo<Post>().insertMany([
          Post(
            id: 52,
            authorId: 1,
            title: 'Post for sync test',
            publishedAt: DateTime(2024),
          ),
        ]);
        await dataSource.repo<PostTag>().insertMany([
          const PostTag(postId: 52, tagId: 1),
          const PostTag(postId: 52, tagId: 2),
        ]);

        final rows =
            await dataSource.context.query<Post>().where('id', 52).get();
        final post = rows.first;

        // Sync to only tag 3
        await post.sync('tags', [3]);

        final pivotRecords = await dataSource.context
            .query<PostTag>()
            .where('post_id', 52)
            .get();

        expect(pivotRecords, hasLength(1));
        expect(pivotRecords.first.tagId, equals(3));
      });

      test('setRelation() caches relation without database operation', () async {
        final rows =
            await dataSource.context.query<Post>().where('id', 1).get();
        final post = rows.first;

        // Manually set relation
        final mockAuthor = const Author(id: 99, name: 'Mock Author');
        post.setRelation('author', mockAuthor);

        expect(post.relationLoaded('author'), isTrue);
        expect(post.author?.name, equals('Mock Author'));
      });

      test('unsetRelation() removes cached relation', () async {
        final rows = await dataSource.context
            .query<Post>()
            .withRelation('author')
            .where('id', 1)
            .get();
        final post = rows.first;

        expect(post.relationLoaded('author'), isTrue);

        post.unsetRelation('author');

        expect(post.relationLoaded('author'), isFalse);
      });

      test('clearRelations() removes all cached relations', () async {
        final rows = await dataSource.context
            .query<Post>()
            .withRelation('author')
            .withRelation('tags')
            .where('id', 1)
            .get();
        final post = rows.first;

        expect(post.relationLoaded('author'), isTrue);
        expect(post.relationLoaded('tags'), isTrue);

        post.clearRelations();

        expect(post.relationLoaded('author'), isFalse);
        expect(post.relationLoaded('tags'), isFalse);
        expect(post.loadedRelationNames, isEmpty);
      });
    });

    group('generated relation query for filtering', () {
      test('postsQuery() returns filtered query by foreign key', () async {
        final rows =
            await dataSource.context.query<Author>().where('id', 1).get();
        final author = rows.first;

        // The generated query should filter by author_id
        final posts = await author.postsQuery().get();

        expect(posts, hasLength(2));
        for (final post in posts) {
          expect(post.authorId, equals(1));
        }
      });

      test('tagsQuery() returns filtered query through pivot', () async {
        final rows =
            await dataSource.context.query<Post>().where('id', 1).get();
        final post = rows.first;

        // The generated query should return tags through pivot table
        final tags = await post.tagsQuery().get();

        expect(tags, hasLength(2));
        expect(tags.map((t) => t.label).toSet(), containsAll(['dart', 'flutter']));
      });

      test('authorQuery() returns query for belongsTo parent', () async {
        final rows =
            await dataSource.context.query<Post>().where('id', 1).get();
        final post = rows.first;

        final author = await post.authorQuery().first();

        expect(author, isNotNull);
        expect(author!.id, equals(1));
        expect(author.name, equals('Alice'));
      });

      test('can chain additional constraints on relation query', () async {
        final rows =
            await dataSource.context.query<Author>().where('id', 1).get();
        final author = rows.first;

        // Chain where clause to filter posts
        final highViewPosts = await author.postsQuery()
            .where('views', 100, PredicateOperator.greaterThan)
            .get();

        expect(highViewPosts, hasLength(1));
        expect(highViewPosts.first.views, equals(250));
      });

      test('can order results from relation query', () async {
        final rows =
            await dataSource.context.query<Author>().where('id', 1).get();
        final author = rows.first;

        final posts = await author.postsQuery()
            .orderBy('views', descending: true)
            .get();

        expect(posts, hasLength(2));
        expect(posts.first.views, equals(250));
        expect(posts.last.views, equals(100));
      });

      test('can count results from relation query', () async {
        final rows =
            await dataSource.context.query<Author>().where('id', 1).get();
        final author = rows.first;

        final count = await author.postsQuery().count();

        expect(count, equals(2));
      });
    });
  });
}
