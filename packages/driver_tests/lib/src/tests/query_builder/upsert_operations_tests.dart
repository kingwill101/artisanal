import 'package:driver_tests/models.dart';
import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

import '../../../driver_tests.dart';

/// Runs comprehensive upsert operation tests for the query builder.
///
/// These tests verify:
/// - Basic upsert operations (insert when not exists)
/// - Upsert updates (update when exists)
/// - Upsert with custom uniqueBy columns
/// - Upsert with selective updateColumns
/// - Batch upsert operations
/// - Edge cases and error handling
void runUpsertOperationsTests() {
  ormedGroup('Upsert Operations', (dataSource) {
    test('upsert() inserts new record', () async {
      final user = await dataSource.query<User>().upsert({
        'email': 'newuser@example.com',
        'active': true,
      });

      expect(user.email, 'newuser@example.com');
      expect(user.active, isTrue);

      // Verify it was actually inserted
      final fetched = await dataSource
          .query<User>()
          .whereEquals('id', user.id)
          .first();
      expect(fetched, isNotNull);
      expect(fetched?.email, 'newuser@example.com');
    });

    test('upsert() updates existing record by primary key', () async {
      // Insert initial record and capture the actual ID
      final created = await dataSource.query<User>().create({
        'email': 'original@example.com',
        'active': true,
      });
      final createdId = created.id;

      // Upsert with same ID should update
      final updated = await dataSource.query<User>().upsert({
        'id': createdId,
        'email': 'updated@example.com',
        'active': false,
      });

      expect(updated.id, createdId);
      expect(updated.email, 'updated@example.com');
      expect(updated.active, isFalse);

      // Verify only one record exists with this ID
      final all = await dataSource
          .query<User>()
          .whereEquals('id', createdId)
          .get();
      expect(all.length, 1);
    });

    test('upsert() with custom uniqueBy column', () async {
      // Insert with specific email and capture the ID
      final created = await dataSource.query<User>().create({
        'email': 'unique@example.com',
        'active': false,
      });

      // Upsert with same email should update (using email as uniqueBy)
      final updated = await dataSource.query<User>().upsert(
        {'email': 'unique@example.com', 'active': true},
        uniqueBy: ['email'],
      );

      expect(updated.email, 'unique@example.com');
      expect(updated.active, isTrue);
      // The ID should match the original record since we updated by email
      expect(updated.id, created.id);

      // Verify only one record with this email exists
      final all = await dataSource
          .query<User>()
          .whereEquals('email', 'unique@example.com')
          .get();
      expect(all.length, 1);
    });

    test('upsert() with updateColumns restricts what is updated', () async {
      // Insert initial record and capture the ID
      final created = await dataSource.query<User>().create({
        'email': 'selective@example.com',
        'active': true,
      });
      final createdId = created.id;

      // Upsert with selective update (only email)
      final updated = await dataSource.query<User>().upsert(
        {'id': createdId, 'email': 'newemail@example.com', 'active': false},
        updateColumns: ['email'],
      );

      expect(updated.email, 'newemail@example.com');
      // active should still be true since we didn't update it
      expect(updated.active, isTrue);
    });

    test('upsert() handles json casts across value types', () async {
      final record = await dataSource.query<JsonValueRecord>().upsert({
        'id': 'json-value-1',
        'object_value': 'done',
        'string_value': 'ok',
        'map_dynamic': {'count': 2},
        'map_object': {'flag': true},
        'list_dynamic': [1, 'two'],
        'list_object': [
          false,
          {'key': 'value'},
        ],
      });

      expect(record.objectValue, 'done');
      expect(record.stringValue, 'ok');
      expect(record.mapDynamic, equals({'count': 2}));
      expect(record.mapObject, equals({'flag': true}));
      expect(record.listDynamic, equals([1, 'two']));
      expect(
        record.listObject,
        equals([
          false,
          {'key': 'value'},
        ]),
      );

      final fetched = await dataSource
          .query<JsonValueRecord>()
          .whereEquals('id', 'json-value-1')
          .first();
      expect(fetched, isNotNull);
      expect(fetched?.objectValue, 'done');
      expect(fetched?.stringValue, 'ok');
      expect(fetched?.mapDynamic, equals({'count': 2}));
      expect(fetched?.mapObject, equals({'flag': true}));
      expect(fetched?.listDynamic, equals([1, 'two']));
      expect(
        fetched?.listObject,
        equals([
          false,
          {'key': 'value'},
        ]),
      );
    });

    test('upsertMany() inserts multiple new records', () async {
      final users = await dataSource.query<User>().upsertMany([
        {'email': 'batch1@example.com', 'active': true},
        {'email': 'batch2@example.com', 'active': true},
        {'email': 'batch3@example.com', 'active': false},
      ]);

      expect(users.length, 3);
      expect(users[0].email, 'batch1@example.com');
      expect(users[1].email, 'batch2@example.com');
      expect(users[2].email, 'batch3@example.com');

      // Verify all were inserted using the returned IDs
      final insertedIds = users.map((u) => u.id).toList();
      final all = await dataSource
          .query<User>()
          .whereIn('id', insertedIds)
          .get();
      expect(all.length, 3);
    });

    test('upsertMany() updates existing records', () async {
      // Insert initial records and capture IDs
      final created = await dataSource.query<User>().createMany([
        {'email': 'update1@example.com', 'active': true},
        {'email': 'update2@example.com', 'active': true},
      ]);
      final id1 = created[0].id;
      final id2 = created[1].id;

      // Upsert with updates using captured IDs
      final updated = await dataSource.query<User>().upsertMany([
        {'id': id1, 'email': 'updated1@example.com', 'active': false},
        {'id': id2, 'email': 'updated2@example.com', 'active': false},
      ]);

      expect(updated.length, 2);
      expect(updated[0].email, 'updated1@example.com');
      expect(updated[0].active, isFalse);
      expect(updated[1].email, 'updated2@example.com');
      expect(updated[1].active, isFalse);
    });

    test('upsertMany() handles mix of inserts and updates', () async {
      // Insert one record and capture its ID
      final existing = await dataSource.query<User>().create({
        'email': 'existing@example.com',
        'active': true,
      });

      // Upsert with one update and two inserts
      final results = await dataSource.query<User>().upsertMany([
        {
          'id': existing.id,
          'email': 'updated@example.com',
          'active': false,
        }, // Update
        {'email': 'new1@example.com', 'active': true}, // Insert
        {'email': 'new2@example.com', 'active': true}, // Insert
      ]);

      expect(results.length, 3);
      expect(results[0].email, 'updated@example.com');
      expect(results[1].email, 'new1@example.com');
      expect(results[2].email, 'new2@example.com');
    });

    test('upsertMany() with custom uniqueBy', () async {
      // Insert initial records and capture IDs
      final created = await dataSource.query<User>().createMany([
        {'email': 'email1@example.com', 'active': true},
        {'email': 'email2@example.com', 'active': true},
      ]);

      // Upsert using email as unique key
      final results = await dataSource.query<User>().upsertMany(
        [
          {
            'email': 'email1@example.com',
            'active': false,
          }, // Should update existing
          {'email': 'email3@example.com', 'active': true}, // Should insert new
        ],
        uniqueBy: ['email'],
      );

      expect(results.length, 2);

      // Verify email1 was updated
      final user1 = await dataSource
          .query<User>()
          .whereEquals('email', 'email1@example.com')
          .first();
      expect(user1?.active, isFalse);
      expect(user1?.id, created[0].id); // Same ID as originally created

      // Verify email3 was inserted
      final user3 = await dataSource
          .query<User>()
          .whereEquals('email', 'email3@example.com')
          .first();
      expect(user3, isNotNull);
    });

    test('upsertMany() with updateColumns', () async {
      // Insert initial records and capture IDs
      final created = await dataSource.query<User>().createMany([
        {'email': 'col1@example.com', 'active': true},
        {'email': 'col2@example.com', 'active': true},
      ]);
      final id1 = created[0].id;
      final id2 = created[1].id;

      // Upsert with selective updates (only active)
      final results = await dataSource.query<User>().upsertMany(
        [
          {'id': id1, 'email': 'newemail1@example.com', 'active': false},
          {'id': id2, 'email': 'newemail2@example.com', 'active': false},
        ],
        updateColumns: ['active'],
      );

      expect(results.length, 2);

      // Emails should not have changed
      expect(results[0].email, 'col1@example.com');
      expect(results[1].email, 'col2@example.com');

      // Active should have changed
      expect(results[0].active, isFalse);
      expect(results[1].active, isFalse);
    });

    test('upsertMany() with empty list returns empty', () async {
      final results = await dataSource.query<User>().upsertMany([]);
      expect(results, isEmpty);
    });

    test('upsert() throws on failure', () async {
      // This should fail when upserting with no data
      // Expect either an Error or Exception depending on how the driver handles it
      expect(
        () => dataSource.query<User>().upsert({}),
        throwsA(anyOf(isA<Error>(), isA<Exception>())),
      );
    });

    test('upsert() works with Posts model', () async {
      // First create an author
      final author = await dataSource.query<Author>().create({
        'name': 'Test Author',
        'active': true,
      });

      // Test upsert with Posts - create new
      final post = await dataSource.query<Post>().upsert({
        'title': 'Test Post',
        'content': 'Content',
        'authorId': author.id,
        'publishedAt': DateTime.now(),
      });

      expect(post.title, 'Test Post');
      final postId = post.id;

      // Update the post using the returned ID
      final updated = await dataSource.query<Post>().upsert({
        'id': postId,
        'title': 'Updated Post',
        'content': 'Updated Content',
        'authorId': author.id,
        'publishedAt': DateTime.now(),
      });

      expect(updated.id, postId);
      expect(updated.title, 'Updated Post');
      expect(updated.content, 'Updated Content');
    });

    test('upsert() handles datetime fields correctly', () async {
      final author = await dataSource.query<Author>().create({
        'name': 'Author with DateTime',
        'active': true,
      });

      // Posts have publishedAt
      final now = DateTime.now();
      final post = await dataSource.query<Post>().upsert({
        'title': 'Timestamped Post',
        'content': 'Content',
        'authorId': author.id,
        'publishedAt': now.toIso8601String(),
      });

      expect(post.publishedAt, isNotNull);
    });

    test('upsertMany() handles large batches', () async {
      // Create author for posts
      final author = await dataSource.query<Author>().create({
        'name': 'Batch Author',
        'active': true,
      });

      // Generate large batch without hardcoded IDs
      final batch = List.generate(
        50,
        (i) => {
          'title': 'Post $i',
          'content': 'Content $i',
          'authorId': author.id,
          'publishedAt': DateTime.now(),
        },
      );

      final results = await dataSource.query<Post>().upsertMany(batch);
      expect(results.length, 50);

      // Verify all were inserted using returned IDs
      final insertedIds = results.map((p) => p.id).toList();
      final all = await dataSource
          .query<Post>()
          .whereIn('id', insertedIds)
          .get();
      expect(all.length, 50);
    });

    test('upsert() with uniqueBy validates column exists', () async {
      // Should throw when specifying non-existent column
      expect(
        () => dataSource.query<User>().upsert(
          {'email': 'test@example.com', 'active': true},
          uniqueBy: ['nonexistent_column'],
        ),
        throwsA(isA<Error>()),
      );
    });

    test(
      'upsert() maintains data integrity across multiple operations',
      () async {
        // Initial insert
        final user1 = await dataSource.query<User>().upsert({
          'email': 'integrity@example.com',
          'active': true,
        });
        expect(user1.active, isTrue);
        final userId = user1.id;

        // First update by ID
        final user2 = await dataSource.query<User>().upsert({
          'id': userId,
          'email': 'integrity@example.com',
          'active': false,
        });
        expect(user2.active, isFalse);
        expect(user2.id, userId);

        // Second update by ID
        final user3 = await dataSource.query<User>().upsert({
          'id': userId,
          'email': 'integrity-updated@example.com',
          'active': true,
        });
        expect(user3.email, 'integrity-updated@example.com');
        expect(user3.active, isTrue);
        expect(user3.id, userId);

        // Verify only one record exists
        final all = await dataSource
            .query<User>()
            .whereEquals('id', userId)
            .get();
        expect(all.length, 1);
        expect(all.first.email, 'integrity-updated@example.com');
      },
    );

    test('upsertMany() is atomic for batch operations', () async {
      // Create initial state and capture IDs
      final created = await dataSource.query<User>().createMany([
        {'email': 'atomic1@example.com', 'active': true},
        {'email': 'atomic2@example.com', 'active': true},
      ]);
      final id1 = created[0].id;
      final id2 = created[1].id;

      // Batch upsert - update existing and add new
      final results = await dataSource.query<User>().upsertMany([
        {'id': id1, 'email': 'atomic1@example.com', 'active': false},
        {'id': id2, 'email': 'atomic2@example.com', 'active': false},
        {'email': 'atomic3@example.com', 'active': true}, // New record
      ]);

      expect(results.length, 3);
      final newId = results[2].id;

      // Verify final state
      final all = await dataSource
          .query<User>()
          .whereIn('id', [id1, id2, newId])
          .orderBy('id')
          .get();

      expect(all.length, 3);
      expect(all[0].active, isFalse); // Updated
      expect(all[1].active, isFalse); // Updated
      expect(all[2].active, isTrue); // Inserted
    });

    test('upsert() respects driver capabilities', () async {
      // This test just verifies upsert executes successfully
      // The driver handles native vs emulated internally
      final user = await dataSource.query<User>().upsert({
        'email': 'capabilities@example.com',
        'active': true,
      });

      expect(user.id, isNotNull);
      expect(user.email, 'capabilities@example.com');

      // Verify driver metadata if available
      print('Driver: ${dataSource.options.driver.metadata.name}');
      print(
        'Supports returning: '
        '${dataSource.options.driver.metadata.supportsReturning}',
      );
    });
  });
}
