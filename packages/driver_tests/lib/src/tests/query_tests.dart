import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

import '../../models.dart';
import '../seed_data.dart';

void runDriverQueryTests() {
  ormedGroup('queries', (dataSource) {
    final metadata = dataSource.options.driver.metadata;
    late List<User> seededUsers;

    void expectPreviewMetadata(StatementPreview preview) {
      final normalized = preview.normalized;
      expect(normalized.command, isNotEmpty);
      expect(normalized.type, isIn(['sql', 'document']));
      expect(normalized.arguments, isNotNull);
      expect(normalized.parameters, isNotNull);
    }

    setUp(() async {
      seededUsers = buildDefaultUsers(suffix: 'fixed');
      // Seed data directly via repository
      await dataSource.repo<User>().insertMany(seededUsers);
      await dataSource.repo<UserProfile>().insertMany(const [
        UserProfile(id: 1, userId: 1, bio: 'Bio for Alice'),
        UserProfile(id: 2, userId: 2, bio: 'Bio for Bob'),
      ]);
      await dataSource.repo<Author>().insertMany(defaultAuthors.toList());
      await dataSource.repo<Post>().insertMany(buildDefaultPosts());
      await dataSource.repo<Tag>().insertMany(defaultTags.toList());
      await dataSource.repo<PostTag>().insertMany(defaultPostTags.toList());
      await dataSource.repo<Taggable>().insertMany(defaultTaggables.toList());
      await dataSource.repo<Image>().insertMany(defaultImages.toList());
      await dataSource.repo<Photo>().insertMany(defaultPhotos.toList());
      await dataSource.context.query<Comment>().createMany(defaultComments);
    });

    test('supports filtering, ordering, and pagination', () async {
      final expectedUser = seededUsers.where((user) => user.active).toList()
        ..sort((a, b) => b.email.compareTo(a.email));

      final rows = await dataSource.context
          .query<User>()
          .whereEquals('active', true)
          .orderBy('email', descending: true)
          .limit(1)
          .rows();
      expect(rows.single.model.email, expectedUser.first.email);
    });

    test('exposes statement previews for queries', () async {
      final preview = dataSource.context
          .query<User>()
          .whereEquals('active', true)
          .orderBy('email')
          .limit(1)
          .toSql();

      expectPreviewMetadata(preview);
    });

    test('emits query events with metadata', () async {
      final events = <QueryEvent>[];
      dataSource.context.onQuery(events.add);

      await dataSource.context.query<User>().whereEquals('id', 1).first();

      expect(events, hasLength(1));
      final event = events.single;
      expect(event.rows, 1);
      expectPreviewMetadata(event.preview);
      expect(event.duration, greaterThan(Duration.zero));
      expect(event.succeeded, isTrue);
    });

    test(
      'records query errors in events',
      () async {
        final events = <QueryEvent>[];
        dataSource.context.onQuery(events.add);

        // Use an invalid query that goes through QueryContext to trigger error
        // Query with invalid column should cause error and emit event
        await expectLater(
          () => dataSource.context.query<User>().whereRaw(
            'invalid_column_xyz = ?',
            [1],
          ).get(),
          throwsA(isA<Exception>()),
        );

        expect(events, hasLength(1));
        expect(events.single.error, isNotNull);
        expect(events.single.succeeded, isFalse);
      },
      skip: !metadata.supportsCapability(DriverCapability.rawSQL),
    );

    test('threadCount reports driver metric', () async {
      final count = await dataSource.context.threadCount();
      if (metadata.supportsCapability(DriverCapability.threadCount)) {
        expect(count, isNotNull);
        expect(count, greaterThanOrEqualTo(1));
      } else {
        expect(count, isNull);
      }
    });

    test('union combines results from separate queries', () async {
      final users = await dataSource.context
          .query<User>()
          .whereEquals('active', true)
          .union(dataSource.context.query<User>().whereEquals('active', false))
          .get();

      final ids = users.map((u) => u.id).toList()..sort();
      expect(ids, equals([1, 2, 3]));
    });

    test('date helpers filter by calendar components', () async {
      final posts = await dataSource.context
          .query<Post>()
          .whereYear('publishedAt', 2024)
          .whereMonth('publishedAt', 2)
          .get();

      expect(posts.map((p) => p.id), equals([2]));

      final exact = await dataSource.context
          .query<Post>()
          .whereDate('publishedAt', DateTime.utc(2024, 1, 1))
          .first();

      expect(exact?.id, 1);
    });

    if (metadata.supportsCapability(DriverCapability.advancedQueryBuilders)) {
      test('time helpers compare HH:mm:ss fragments', () async {
        final timeQuery = dataSource.context.query<Post>().whereTime(
          'publishedAt',
          '08:30:00',
        );
        final preview = timeQuery.toSql();
        expectPreviewMetadata(preview);

        if (metadata.name != 'MySqlDriverAdapter') {
          final match = await timeQuery.first();
          expect(match?.id, 2);
        }

        final dayMatches = await dataSource.context
            .query<Post>()
            .whereDay('publishedAt', 12)
            .orderBy('id')
            .get();

        expect(dayMatches.map((post) => post.id), equals([3]));
      });
    }

    test('eager loads hasMany relations', () async {
      final rows = await dataSource.context
          .query<Author>()
          .withRelation('posts')
          .orderBy('id')
          .rows();

      final posts = rows.first.relationList<Post>('posts');
      expect(posts.map((p) => p.title), containsAll(['Welcome', 'Second']));
    });

    test('eager loads belongsTo relations', () async {
      final post = await dataSource.context
          .query<Post>()
          .whereEquals('title', 'Intro')
          .withRelation('author')
          .firstRow();

      expect(post?.relation<Author>('author')?.name, 'Bob');
    });

    test('eager loads multiple relations using with_', () async {
      final post = await dataSource.context
          .query<Post>()
          .whereEquals('title', 'Intro')
          .with_(['author', 'tags'])
          .firstRow();

      expect(post?.relation<Author>('author')?.name, 'Bob');
      expect(
        post?.relationList<Tag>('tags').map((t) => t.label),
        contains('featured'),
      );
    });

    test('eager loads manyToMany relations', () async {
      final post = await dataSource.context
          .query<Post>()
          .whereEquals('id', 1)
          .withRelation('tags')
          .firstRow();

      final tags = post!.relationList<Tag>('tags');
      expect(tags.map((t) => t.label), containsAll(['featured']));
    });

    test('eager loads morphMany relations', () async {
      final post = await dataSource.context
          .query<Post>()
          .whereEquals('id', 1)
          .withRelation('photos')
          .firstRow();

      final photos = post!.relationList<Photo>('photos');
      expect(photos.map((p) => p.path), containsAll(['hero.jpg', 'thumb.jpg']));
    });

    test('eager loads morphOne relations', () async {
      final image = await dataSource.context
          .query<Image>()
          .whereEquals('id', 101)
          .withRelation('primaryPhoto')
          .firstRow();

      expect(image?.relation<Photo>('primaryPhoto')?.path, 'cover.jpg');
    });

    test('eager loads morphTo relations', () async {
      final photo = await dataSource.context
          .query<Photo>()
          .whereEquals('id', 1)
          .withRelation('imageable')
          .firstRow();

      final imageable = photo?.relation<OrmEntity>('imageable');
      expect(imageable, isA<Post>());
      expect((imageable as Post).id, 1);
    });

    test('resolves morphTo aliases via morph map registry', () async {
      dataSource.context.registry.registerMorphMap({'post_alias': Post});
      await dataSource.repo<Photo>().insertMany(const [
        Photo(
          id: 6,
          imageableId: 2,
          imageableType: 'post_alias',
          path: 'alias.jpg',
        ),
      ]);

      final photo = await dataSource.context
          .query<Photo>()
          .whereEquals('id', 6)
          .withRelation('imageable')
          .firstRow();

      final imageable = photo?.relation<OrmEntity>('imageable');
      expect(imageable, isA<Post>());
      expect((imageable as Post).id, 2);
    });

    test('eager loads morphToMany relations', () async {
      final post = await dataSource.context
          .query<Post>()
          .whereEquals('id', 1)
          .withRelation('morphTags')
          .firstRow();

      final tags = post!.relationList<Tag>('morphTags');
      expect(tags.map((t) => t.label), containsAll(['featured', 'draft']));
    });

    test('eager loads morphedByMany relations', () async {
      final tag = await dataSource.context
          .query<Tag>()
          .whereEquals('id', 2)
          .withRelation('morphedPosts')
          .firstRow();

      final posts = tag!.relationList<Post>('morphedPosts');
      expect(posts.map((p) => p.id), containsAll([1, 2]));
    });

    test('eager loads hasOne relations', () async {
      final user = await dataSource.context
          .query<User>()
          .whereEquals('id', 1)
          .withRelation('userProfile')
          .firstRow();

      expect(user?.relation<UserProfile>('userProfile')?.bio, 'Bio for Alice');
    });

    group('eager loading constraints', () {
      test('applies constraint callback for hasMany relations', () async {
        final row = await dataSource.context
            .query<Author>()
            .whereEquals('id', 1)
            .withRelation('posts', (q) => q.where('id', 2))
            .firstRow();

        final posts = row!.relationList<Post>('posts');
        expect(posts.map((p) => p.id), equals([2]));
      });

      test('applies constraint callback for belongsTo relations', () async {
        final row = await dataSource.context
            .query<Post>()
            .whereEquals('id', 1)
            .withRelation('author', (q) => q.where('name', 'Bob'))
            .firstRow();

        expect(row!.relation<Author>('author'), isNull);
      });

      test('applies constraint callback for hasOne relations', () async {
        final row = await dataSource.context
            .query<User>()
            .whereEquals('id', 1)
            .withRelation('userProfile', (q) => q.where('bio', 'Bio for Bob'))
            .firstRow();

        expect(row!.relation<UserProfile>('userProfile'), isNull);
      });

      test('applies constraint callback for manyToMany relations', () async {
        final row = await dataSource.context
            .query<Post>()
            .whereEquals('id', 1)
            .withRelation('tags', (q) => q.where('label', 'draft'))
            .firstRow();

        final tags = row!.relationList<Tag>('tags');
        expect(tags.map((t) => t.label), equals(['draft']));
      });

      test('applies constraint callback for morphMany relations', () async {
        final row = await dataSource.context
            .query<Post>()
            .whereEquals('id', 1)
            .withRelation('photos', (q) => q.where('path', 'hero.jpg'))
            .firstRow();

        final photos = row!.relationList<Photo>('photos');
        expect(photos.map((p) => p.path), equals(['hero.jpg']));
      });

      test('applies constraint callback for morphOne relations', () async {
        final row = await dataSource.context
            .query<Image>()
            .whereEquals('id', 101)
            .withRelation('primaryPhoto', (q) => q.where('path', 'alt.jpg'))
            .firstRow();

        expect(row!.relation<Photo>('primaryPhoto'), isNull);
      });
    });

    group('eager loading missing relations', () {
      test('returns empty list when hasMany has no matches', () async {
        await dataSource.repo<Author>().insertMany(const [
          Author(id: 99, name: 'NoPosts'),
        ]);

        final row = await dataSource.context
            .query<Author>()
            .whereEquals('id', 99)
            .withRelation('posts')
            .firstRow();

        expect(row!.relationList<Post>('posts'), isEmpty);
      });

      test('returns null when belongsTo has no match', () async {
        await dataSource.repo<Post>().insertMany([
          Post(
            id: 99,
            authorId: 999,
            title: 'Orphan',
            publishedAt: DateTime.utc(2024, 5, 1),
          ),
        ]);

        final row = await dataSource.context
            .query<Post>()
            .whereEquals('id', 99)
            .withRelation('author')
            .firstRow();

        expect(row!.relation<Author>('author'), isNull);
      });

      test('returns null when hasOne has no match', () async {
        final row = await dataSource.context
            .query<User>()
            .whereEquals('id', 3)
            .withRelation('userProfile')
            .firstRow();

        expect(row!.relation<UserProfile>('userProfile'), isNull);
      });

      test('returns empty list when manyToMany has no matches', () async {
        await dataSource.repo<Post>().insertMany([
          Post(
            id: 100,
            authorId: 1,
            title: 'No Tags',
            publishedAt: DateTime.utc(2024, 5, 2),
          ),
        ]);

        final row = await dataSource.context
            .query<Post>()
            .whereEquals('id', 100)
            .withRelation('tags')
            .firstRow();

        expect(row!.relationList<Tag>('tags'), isEmpty);
      });

      test('returns empty list when morphMany has no matches', () async {
        await dataSource.repo<Post>().insertMany([
          Post(
            id: 101,
            authorId: 1,
            title: 'No Photos',
            publishedAt: DateTime.utc(2024, 5, 3),
          ),
        ]);

        final row = await dataSource.context
            .query<Post>()
            .whereEquals('id', 101)
            .withRelation('photos')
            .firstRow();

        expect(row!.relationList<Photo>('photos'), isEmpty);
      });

      test('returns null when morphOne has no match', () async {
        await dataSource.repo<Image>().insertMany(const [
          Image(id: 999, label: 'No Primary Photo'),
        ]);

        final row = await dataSource.context
            .query<Image>()
            .whereEquals('id', 999)
            .withRelation('primaryPhoto')
            .firstRow();

        expect(row!.relation<Photo>('primaryPhoto'), isNull);
      });
    });

    test('describes nested orderByRelation preview for morph paths', () {
      final preview = dataSource.context
          .query<Author>()
          .orderByRelation('posts.photos', descending: true)
          .limit(1)
          .toSql();

      expectPreviewMetadata(preview);
    });

    test('withExists builds nested EXISTS preview for morph paths', () {
      final preview = dataSource.context
          .query<Author>()
          .withExists('posts.photos', alias: 'has_photos')
          .limit(1)
          .toSql();

      expectPreviewMetadata(preview);
    });

    test(
      'orderByRelation distinct preview metadata for nested pivot paths',
      () {
        final preview = dataSource.context
            .query<Author>()
            .orderByRelation('posts.tags', distinct: true)
            .limit(1)
            .toSql();

        expectPreviewMetadata(preview);
      },
    );

    if (metadata.supportsCapability(DriverCapability.advancedQueryBuilders)) {
      group('predicate AST support', () {
        test('applies nested boolean groups and advanced operators', () async {
          final rows = await dataSource.context
              .query<Post>()
              .where((outer) {
                outer
                  ..where('authorId', 1)
                  ..orWhere((inner) => inner.whereBetween('id', 2, 3));
              })
              .whereNotIn('id', [1])
              .orderBy('id')
              .rows();

          expect(rows.map((row) => row.model.id), equals([2, 3]));
        });

        test(
          'handles raw predicates and case-insensitive like comparisons',
          () async {
            final rows = await dataSource.context
                .query<Post>()
                .whereRaw('substr(title, 1, 1) = ?', ['I'])
                .orWhere((builder) {
                  if (metadata.supportsCapability(
                    DriverCapability.caseInsensitiveLike,
                  )) {
                    builder.whereILike('title', 'wel%');
                  } else {
                    builder.whereLike('title', 'Wel%');
                  }
                })
                .orderBy('id')
                .rows();

            expect(
              rows.map((row) => row.model.title),
              equals(['Welcome', 'Intro']),
            );
          },
        );
      });

      group('projection metadata', () {
        test('exposes preview metadata for aggregates and raw selects', () {
          final preview = dataSource.context
              .query<Post>()
              .select(['authorId'])
              .selectRaw(
                'strftime(?, published_at)',
                alias: 'published_year',
                bindings: ['%Y'],
              )
              .countAggregate(expression: '*', alias: 'total_posts')
              .groupBy(['authorId'])
              .having('authorId', PredicateOperator.greaterThan, 0)
              .havingBitwise('authorId', '&', 1)
              .havingRaw('COUNT(*) > ?', [1])
              .orderBy('authorId')
              .toSql();

          expectPreviewMetadata(preview);
        });
      });

      group('relation helpers', () {
        test('filters parents via whereHas constraints', () async {
          final ids = await dataSource.context
              .query<Author>()
              .whereHas('posts', (posts) => posts.where('title', 'Welcome'))
              .orderBy('id')
              .get()
              .then((authors) => authors.map((a) => a.id).toList());

          expect(ids, equals([1]));
        });

        test('filters parents via hasOne whereHas constraints', () async {
          final ids = await dataSource.context
              .query<User>()
              .whereHas(
                'userProfile',
                (profiles) => profiles.where('bio', 'Bio for Alice'),
              )
              .orderBy('id')
              .get()
              .then((users) => users.map((u) => u.id).toList());

          expect(ids, equals([1]));
        });

        test(
          'filters parents via hasManyThrough whereHas constraints',
          () async {
            final ids = await dataSource.context
                .query<Author>()
                .whereHas(
                  'comments',
                  (comments) => comments.where('body', 'Visible'),
                )
                .orderBy('id')
                .get()
                .then((authors) => authors.map((a) => a.id).toList());

            expect(ids, equals([1]));
          },
        );

        test('supports withCount and exposes alias in rows', () async {
          final rows = await dataSource.context
              .query<Author>()
              .withCount('posts')
              .orderBy('id')
              .rows();

          expect(rows[0].row['posts_count'], 2);
          expect(rows[1].row['posts_count'], 1);
        });

        test('supports withCount for hasOne relations', () async {
          final rows = await dataSource.context
              .query<User>()
              .withCount('userProfile')
              .orderBy('id')
              .rows();

          expect(rows[0].row['userProfile_count'], 1);
          expect(rows[1].row['userProfile_count'], 1);
          expect(rows[2].row['userProfile_count'], 0);
        });

        test('supports withCount for hasManyThrough relations', () async {
          final rows = await dataSource.context
              .query<Author>()
              .withCount('comments')
              .orderBy('id')
              .rows();

          expect(rows[0].row['comments_count'], 1);
          expect(rows[1].row['comments_count'], 0);
        });

        test('supports nested withCount over morph relations', () async {
          final rows = await dataSource.context
              .query<Author>()
              .withCount('posts.photos')
              .orderBy('id')
              .rows();

          expect(rows[0].row['posts_photos_count'], 2);
          expect(rows[1].row['posts_photos_count'], 1);
        });

        test(
          'withCount preserves multiplicity for nested pivot paths',
          () async {
            final rows = await dataSource.context
                .query<Author>()
                .withCount('posts.tags')
                .orderBy('id')
                .rows();

            expect(rows[0].row['posts_tags_count'], 3);
            expect(rows[1].row['posts_tags_count'], 1);
          },
        );

        test('distinct withCount collapses duplicate pivot rows', () async {
          final rows = await dataSource.context
              .query<Author>()
              .withCount('posts.tags', distinct: true)
              .orderBy('id')
              .rows();

          expect(rows[0].row['posts_tags_count'], 2);
          expect(rows[1].row['posts_tags_count'], 1);
        });

        test('filters parents via nested morph whereHas constraints', () async {
          final ids = await dataSource.context
              .query<Author>()
              .whereHas(
                'posts.photos',
                (photos) => photos.where('path', 'hero.jpg'),
              )
              .orderBy('id')
              .get()
              .then((authors) => authors.map((a) => a.id).toList());

          expect(ids, equals([1]));
        });

        test('eager loads hasManyThrough relations', () async {
          final authors = await dataSource.context
              .query<Author>()
              .withRelation('comments')
              .orderBy('id')
              .get();

          expect(authors.first.comments, hasLength(1));
          expect(authors.last.comments, isEmpty);
        });

        test('orders by relation aggregate', () async {
          final authors = await dataSource.context
              .query<Author>()
              .orderByRelation('posts', descending: true)
              .get();

          expect(authors.first.id, 1);
          expect(authors.last.id, 2);
        });
      });

      group('pagination and chunking', () {
        test('paginate returns metadata and eager loads relations', () async {
          final result = await dataSource.context
              .query<Post>()
              .withRelation('author')
              .orderBy('id')
              .paginate(perPage: 2, page: 1);

          expect(result.total, 3);
          expect(result.perPage, 2);
          expect(result.currentPage, 1);
          expect(result.lastPage, 2);
          expect(result.hasMorePages, isTrue);
          expect(result.items, hasLength(2));
          expect(result.items.first.relation<Author>('author')?.name, 'Alice');
        });

        test('simplePaginate and cursorPaginate advance windows', () async {
          final simple = await dataSource.context
              .query<Post>()
              .orderBy('id')
              .simplePaginate(perPage: 2, page: 1);
          expect(simple.items, hasLength(2));
          expect(simple.hasMorePages, isTrue);

          final simpleTail = await dataSource.context
              .query<Post>()
              .orderBy('id')
              .simplePaginate(perPage: 2, page: 2);
          expect(simpleTail.items, hasLength(1));
          expect(simpleTail.hasMorePages, isFalse);

          final firstCursor = await dataSource.context
              .query<Post>()
              .cursorPaginate(perPage: 2, column: 'id');
          expect(firstCursor.items.map((row) => row.model.id), equals([1, 2]));
          expect(firstCursor.hasMore, isTrue);
          expect(firstCursor.nextCursor, 2);

          final secondCursor = await dataSource.context
              .query<Post>()
              .cursorPaginate(
                perPage: 2,
                column: 'id',
                cursor: firstCursor.nextCursor,
              );
          expect(secondCursor.items.map((row) => row.model.id), equals([3]));
          expect(secondCursor.hasMore, isFalse);
          expect(secondCursor.nextCursor, isNull);
        });

        test('chunk helpers iterate deterministically', () async {
          final visited = <int>[];
          await dataSource.context.query<Post>().chunk(1, (rows) {
            visited.add(rows.single.model.id);
            return visited.length < 2;
          });
          expect(visited, equals([1, 2]));

          final batches = <List<int>>[];
          await dataSource.context.query<Post>().chunkById(2, (rows) {
            batches.add(rows.map((row) => row.model.id).toList());
            return true;
          });
          expect(
            batches,
            equals([
              [1, 2],
              [3],
            ]),
          );

          final eachVisited = <int>[];
          await dataSource.context.query<Post>().eachById(1, (row) {
            eachVisited.add(row.model.id);
            return row.model.id < 2;
          });
          expect(eachVisited, equals([1, 2]));
        });
      });
      group('soft deletes', () {
        test('withTrashed and onlyTrashed toggle the default scope', () async {
          final scoped = await dataSource.context.query<Comment>().get();
          expect(scoped.single.body, 'Visible');

          final all = await dataSource.context
              .query<Comment>()
              .withTrashed()
              .get();
          expect(all.map((c) => c.body), containsAll(['Visible', 'Hidden']));

          final trashed = await dataSource.context
              .query<Comment>()
              .onlyTrashed()
              .get();
          expect(trashed.single.body, 'Hidden');
        });

        test('restore clears deleted_at for matching rows', () async {
          final affected = await dataSource.context
              .query<Comment>()
              .whereEquals('id', 2)
              .restore();

          expect(affected, 1);
          final rows = await dataSource.context
              .query<Comment>()
              .withTrashed()
              .orderBy('id')
              .get();
          expect(rows.map((c) => c.deletedAt), everyElement(isNull));
        });

        test('forceDelete removes rows regardless of scope', () async {
          final affected = await dataSource.context
              .query<Comment>()
              .withTrashed()
              .whereEquals('id', 1)
              .forceDelete();

          expect(affected, 1);
          final remaining = await dataSource.context
              .query<Comment>()
              .withTrashed()
              .get();
          expect(remaining.single.id, 2);
        });

        test(
          'forceDelete honors order and limit clauses',
          () async {
            final affected = await dataSource.context
                .query<Comment>()
                .withTrashed()
                .orderBy('id', descending: true)
                .limit(1)
                .forceDelete();

            expect(affected, 1);
            final rows = await dataSource.context
                .query<Comment>()
                .withTrashed()
                .orderBy('id')
                .get();
            expect(rows.map((c) => c.id), equals([1]));
          },
          skip: !metadata.supportsCapability(DriverCapability.queryDeletes),
        );
      });

      group('json predicates', () {
        Future<void> seedDriverSettings() => dataSource.context
            .repository<DriverOverrideEntry>()
            .insertMany(const [
              DriverOverrideEntry(
                id: 1,
                payload: {
                  'mode': 'dark',
                  'featured': true,
                  'tags': ['alpha', 'beta'],
                  'meta': {
                    'author': {'name': 'Alicia'},
                  },
                },
              ),
              DriverOverrideEntry(
                id: 2,
                payload: {
                  'mode': 'light',
                  'featured': false,
                  'tags': ['gamma'],
                },
              ),
            ]);

        test('whereJsonContains filters JSON arrays', () async {
          await seedDriverSettings();

          final results = await dataSource.context
              .query<DriverOverrideEntry>()
              .whereJsonContains('payload->tags', ['beta'])
              .get();

          expect(results.map((entry) => entry.id), [1]);
        });

        test('whereJsonContainsKey matches nested paths', () async {
          await seedDriverSettings();

          final results = await dataSource.context
              .query<DriverOverrideEntry>()
              .whereJsonContainsKey('payload', 'meta.author.name')
              .get();

          expect(results.map((entry) => entry.id), [1]);
        });

        test('whereJsonLength compares array lengths', () async {
          await seedDriverSettings();

          final results = await dataSource.context
              .query<DriverOverrideEntry>()
              .whereJsonLength('payload->tags', '>=', 2)
              .get();

          expect(results.map((entry) => entry.id), [1]);
        });

        test('whereJsonOverlaps matches any overlapping array value', () async {
          await seedDriverSettings();

          final results = await dataSource.context
              .query<DriverOverrideEntry>()
              .whereJsonOverlaps('payload->tags', ['beta', 'delta'])
              .get();

          expect(results.map((entry) => entry.id), [1]);
        });

        test('json selectors compare boolean payload fragments', () async {
          await seedDriverSettings();

          final featured = await dataSource.context
              .query<DriverOverrideEntry>()
              .where('payload->featured', true)
              .get();

          expect(featured.map((entry) => entry.id), [1]);

          final hidden = await dataSource.context
              .query<DriverOverrideEntry>()
              .where('payload->featured', false)
              .get();

          expect(hidden.map((entry) => entry.id), [2]);
        });
      });

      test('limitPerGroup returns the latest post per author', () async {
        // TODO: Implement limitPerGroup when window function support is available
        // final posts = await dataSource.context
        //     .query<Post>()
        //     .orderBy('publishedAt', descending: true)
        //     .limitPerGroup(1, 'authorId')
        //     .get();

        // expect(posts, hasLength(2));
        // expect(posts.map((post) => post.id).toSet(), {2, 3});
      });
    }
  });
}
