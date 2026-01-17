import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

import '../../models.dart';
import '../seed_data.dart';

void runDriverMutationTests() {
  // Skip entire group for drivers that don't support raw SQL,
  // as these tests use executeRaw, queryRaw, and SQL-specific features
  ormedGroup('mutations', (dataSource) {
    final metadata = dataSource.options.driver.metadata;
    if (!metadata.supportsCapability(DriverCapability.rawSQL)) {
      return;
    }
    String wrap(String value) =>
        '${metadata.identifierQuote}$value${metadata.identifierQuote}';

    void expectPreviewMetadata(StatementPreview preview) {
      final normalized = preview.normalized;
      expect(normalized.command, isNotEmpty);
      expect(normalized.type, isIn(['sql', 'document']));
      expect(normalized.arguments, isNotNull);
      expect(normalized.parameters, isNotNull);
    }

    setUp(() async {
      // Clean per-test state is handled by ormedGroup isolation; seed happens within tests below.
    });

    test('insert + update + delete round trip', () async {
      final repo = dataSource.context.repository<User>();
      await repo.insert(
        const User(id: 1, email: 'seed@example.com', active: true),
      );

      await repo.updateMany([
        const User(id: 1, email: 'updated@example.com', active: false),
      ]);

      var users = await dataSource.context.query<User>().get();
      expect(users.single.email, 'updated@example.com');
      expect(users.single.active, isFalse);

      final deleted = await repo.deleteByKeys([
        {'id': 1},
      ]);
      expect(deleted, 1);

      users = await dataSource.context.query<User>().get();
      expect(users, isEmpty);
    });

    test('upsert inserts then updates', () async {
      final repo = dataSource.context.repository<$User>();

      // First insert a record
      await repo.insert(
        $User(id: 5, email: 'upsert@example.com', active: true),
      );

      var users = await dataSource.context
          .query<$User>()
          .whereEquals('id', 5)
          .get();
      expect(users.single.email, 'upsert@example.com');

      // Then upsert to update
      await repo.upsertMany([
        $User(id: 5, email: 'updated@upsert.com', active: true),
      ]);

      users = await dataSource.context
          .query<$User>()
          .whereEquals('id', 5)
          .get();
      expect(users.single.email, 'updated@upsert.com');
    });

    test('upsert honors custom unique and update columns', () async {
      final repo = dataSource.context.repository<User>();
      await repo.insert(
        const User(id: 40, email: 'unique@example.com', active: false),
      );

      await repo.upsertMany(
        [const User(id: 41, email: 'unique@example.com', active: true)],
        uniqueBy: ['email'],
        updateColumns: ['active'],
      );

      final refreshed = await dataSource.context
          .query<User>()
          .whereEquals('email', 'unique@example.com')
          .firstOrFail();
      expect(refreshed.id, 40);
      expect(refreshed.active, isTrue);
    });

    test('insertOrIgnore skips duplicate rows', () async {
      final repo = dataSource.context.repository<User>();
      await repo.insert(
        const User(id: 50, email: 'unique-insert@example.com', active: true),
      );

      final inserted = await repo.insertOrIgnoreMany([
        const User(id: 51, email: 'second@example.com', active: true),
        const User(id: 50, email: 'duplicate@example.com', active: false),
      ]);
      expect(inserted, 1);

      final rows = await dataSource.context.query<User>().get();
      expect(rows.length, 2);
      expect(rows.where((user) => user.id == 50).single.active, isTrue);
    });

    if (metadata.supportsCapability(DriverCapability.insertUsing)) {
      test('insertUsing copies rows from select queries', () async {
        final repo = dataSource.context.repository<User>();
        await repo.insertMany(const [
          User(id: 2050, email: 'copy-source-a@example.com', active: true),
          User(id: 2051, email: 'copy-source-b@example.com', active: false),
        ]);

        final offset = 400;
        var source = dataSource.context
            .query<User>()
            .select([])
            .selectRaw('${wrap('users')}.${wrap('id')} + $offset', alias: 'id');

        final emailExpr = metadata.name == 'mysql' || metadata.name == 'mariadb'
            ? "CONCAT(${wrap('users')}.${wrap('email')}, '-copy')"
            : "${wrap('users')}.${wrap('email')} || '-copy'";

        source = source
            .selectRaw(emailExpr, alias: 'email')
            .selectRaw('${wrap('users')}.${wrap('active')}', alias: 'active')
            .whereIn('id', const [2050, 2051]);

        final inserted = await dataSource.context.query<User>().insertUsing([
          'id',
          'email',
          'active',
        ], source);
        expect(inserted, 2);

        final copies = await dataSource.context
            .query<User>()
            .whereIn('id', const [2450, 2451])
            .orderBy('id')
            .get();

        expect(copies.length, 2);
        expect(copies.first.email, 'copy-source-a@example.com-copy');
        expect(copies.first.active, isTrue);
        expect(copies.last.email, 'copy-source-b@example.com-copy');
        expect(copies.last.active, isFalse);
      });

      test(
        'insertOrIgnoreUsing suppresses duplicates from select queries',
        () async {
          final repo = dataSource.context.repository<User>();
          await repo.insertMany(const [
            User(id: 3100, email: 'ignore-select@example.com', active: true),
          ]);

          final source = dataSource.context
              .query<User>()
              .select([])
              .selectRaw('${wrap('users')}.${wrap('id')}', alias: 'id')
              .selectRaw('${wrap('users')}.${wrap('email')}', alias: 'email')
              .selectRaw('${wrap('users')}.${wrap('active')}', alias: 'active')
              .whereEquals('id', 3100);

          final inserted = await dataSource.context
              .query<User>()
              .insertOrIgnoreUsing(['id', 'email', 'active'], source);
          expect(inserted, 0);

          final rows = await dataSource.context
              .query<User>()
              .whereEquals('id', 3100)
              .get();
          expect(rows.length, 1);
          expect(rows.single.email, 'ignore-select@example.com');
        },
      );
    }

    test('jsonPatch merges payload columns without clobbering state', () async {
      final repo = dataSource.context.repository<DriverOverrideEntry>();
      await repo.insert(
        const DriverOverrideEntry(
          id: 900,
          payload: {
            'status': 'pending',
            'meta': {'visits': 1},
          },
        ),
      );

      await repo.updateMany(
        const [
          DriverOverrideEntry(
            id: 900,
            payload: {
              'status': 'pending',
              'meta': {'visits': 1},
            },
          ),
        ],
        jsonUpdates: (_) => [
          JsonUpdateDefinition.patch('payload', {
            'meta': {'visits': 2},
            'tags': ['beta'],
          }),
        ],
      );

      final refreshed = await dataSource.context
          .query<DriverOverrideEntry>()
          .whereEquals('id', 900)
          .firstOrFail();
      expect(refreshed.payload['status'], 'pending');
      final meta = refreshed.payload['meta'] as Map<String, Object?>;
      expect(meta['visits'], 2);
      expect(refreshed.payload['tags'], ['beta']);
    });

    test('forceDelete honors ordering and limit clauses', () async {
      await dataSource.repo<User>().insertMany(buildDefaultUsers());

      final removed = await dataSource.context
          .query<User>()
          .orderBy('id')
          .limit(1)
          .forceDelete();

      expect(removed, 1);
      final remaining = await dataSource.context
          .query<User>()
          .orderBy('id')
          .get();
      expect(remaining.map((user) => user.id), equals([2, 3]));
    });

    // TODO: This test uses ModelDefinition<Map<String, Object?>> which is no longer
    // supported after the DTO refactoring. Need to create a proper OrmEntity model.
    // test(
    //   'auto increment primary keys use driver defaults when omitted',
    //   () async {
    //     if (!metadata.supportsCapability(DriverCapability.rawSQL)) {
    //       return;
    //     }
    //     final plan = MutationPlan.insert(
    //       definition: _serialTestDefinition,
    //       rows: const [
    //         {'label': 'first'},
    //         {'label': 'second'},
    //       ],
    //       driverName: dataSource.options.driver.metadata.name,
    //       returning: metadata.supportsCapability(DriverCapability.returning),
    //     );

    //     final result = await dataSource.connection.driver.runMutation(plan);
    //     expect(result.affectedRows, 2);

    //     final inserted = await dataSource.connection.driver.queryRaw(
    //       'SELECT id, label FROM serial_tests ORDER BY id',
    //     );
    //     expect(inserted.length, 2);
    //     final firstId = (inserted.first['id'] as num).toInt();
    //     final secondId = (inserted.last['id'] as num).toInt();
    //     expect(inserted.first['label'], 'first');
    //     expect(inserted.last['label'], 'second');
    //     expect(firstId, greaterThan(0));
    //     expect(secondId, greaterThan(firstId));

    //     if (metadata.supportsCapability(DriverCapability.returning)) {
    //       expect(result.returnedRows, isNotNull);
    //       final returnedIds = result.returnedRows!
    //           .map((row) => row['id'])
    //           .whereType<num>();
    //       expect(returnedIds, containsAll(<num>[firstId, secondId]));
    //     }
    //   },
    // );

    test('query builder update applies mutations to matching rows', () async {
      final repo = dataSource.context.repository<User>();
      await repo.insertMany(const [
        User(id: 5000, email: 'builder-update-a@example.com', active: true),
        User(id: 5001, email: 'builder-update-b@example.com', active: true),
      ]);

      final affected = await dataSource.context
          .query<User>()
          .whereEquals('id', 5000)
          .update({'active': false});

      expect(affected, 1);

      final first = await dataSource.context
          .query<User>()
          .whereEquals('id', 5000)
          .firstOrFail();
      final second = await dataSource.context
          .query<User>()
          .whereEquals('id', 5001)
          .firstOrFail();

      expect(first.active, isFalse);
      expect(second.active, isTrue);
    });

    test('query builder update encodes values using model codecs', () async {
      final repo = dataSource.context.repository<DriverOverrideEntry>();
      await repo.insertMany(const [
        DriverOverrideEntry(id: 9000, payload: {'mode': 'light'}),
      ]);

      final affected = await dataSource.context
          .query<DriverOverrideEntry>()
          .whereEquals('id', 9000)
          .update({
            'payload': {'mode': 'dark', 'count': 2},
          });

      expect(affected, 1);

      final refreshed = await dataSource.context
          .query<DriverOverrideEntry>()
          .whereEquals('id', 9000)
          .firstOrFail();

      expect(refreshed.payload['mode'], 'dark');
      expect(refreshed.payload['count'], 2);
    });

    test(
      'query builder update works without primary key when supported',
      () async {
        final repo = dataSource.context.repository<User>();
        await repo.insertMany(const [
          User(id: 7200, email: 'adhoc@example.com', active: true),
        ]);

        final affected = await dataSource.context
            .table('users')
            .whereEquals('email', 'adhoc@example.com')
            .limit(1)
            .update({'active': false});

        expect(affected, 1);

        final refreshed = await dataSource.context
            .query<User>()
            .whereEquals('email', 'adhoc@example.com')
            .firstOrFail();

        expect(refreshed.active, isFalse);
      },
      skip: !metadata.supportsCapability(DriverCapability.adHocQueryUpdates),
    );

    test(
      'query builder deleteWhere accepts map/partial/model/raw pk',
      () async {
        final repo = dataSource.context.repository<$User>();
        final users = await repo.insertMany([
          $User(id: 8000, email: 'qb-del-map@example.com', active: true),
          $User(id: 8001, email: 'qb-del-partial@example.com', active: true),
          $User(id: 8002, email: 'qb-del-model@example.com', active: true),
          $User(id: 8003, email: 'qb-del-pk@example.com', active: true),
        ]);

        final partial = UserPartial(id: 8001);

        final affected = await dataSource.context
            .query<$User>()
            .deleteWhereMany([
              {'id': 8000}, // map
              partial, // partial
              users[2], // tracked model
              8003, // raw pk value
            ]);

        expect(affected, 4);

        for (final id in [8000, 8001, 8002, 8003]) {
          final fetched = await dataSource.context
              .query<$User>()
              .whereEquals('id', id)
              .first();
          expect(fetched, isNull);
        }
      },
    );

    test(
      'query builder updateReturning hydrates returned rows',
      () async {
        final repo = dataSource.context.repository<$User>();
        await repo.insert(
          $User(id: 8100, email: 'qb-update-return@example.com', active: true),
        );

        final updated = await dataSource.context
            .query<$User>()
            .whereEquals('id', 8100)
            .updateReturning({'active': false});

        expect(updated, hasLength(1));
        expect(updated.single.id, 8100);
        expect(updated.single.email, 'qb-update-return@example.com');
        expect(updated.single.active, isFalse);
      },
      skip: !metadata.supportsCapability(DriverCapability.returning),
    );

    test(
      'query builder deleteReturning returns deleted models',
      () async {
        final repo = dataSource.context.repository<$User>();
        await repo.insert(
          $User(id: 8101, email: 'qb-delete-return@example.com', active: true),
        );

        final deleted = await dataSource.context
            .query<$User>()
            .whereEquals('id', 8101)
            .deleteReturning();

        expect(deleted, hasLength(1));
        expect(deleted.single.id, 8101);
        expect(deleted.single.email, 'qb-delete-return@example.com');

        final remaining = await dataSource.context
            .query<$User>()
            .whereEquals('id', 8101)
            .first();
        expect(remaining, isNull);
      },
      skip: !metadata.supportsCapability(DriverCapability.returning),
    );

    test(
      'sqlite query updates encode json bindings for ad-hoc tables',
      () async {
        if (metadata.name != 'sqlite') {
          return;
        }
        final repo = dataSource.context.repository<DriverOverrideEntry>();
        await repo.insertMany(const [
          DriverOverrideEntry(id: 9050, payload: {'mode': 'legacy'}),
        ]);

        final affected = await dataSource.context
            .table('driver_override_entries')
            .whereEquals('id', 9050)
            .limit(1)
            .update({
              'payload': {'mode': 'encoded', 'count': 2},
            });

        expect(affected, 1);

        final refreshed = await dataSource.context
            .query<DriverOverrideEntry>()
            .whereEquals('id', 9050)
            .firstOrFail();

        expect(refreshed.payload['mode'], 'encoded');
        expect(refreshed.payload['count'], 2);
      },
    );

    test('sqlite query updates support joins and limits', () async {
      if (metadata.name != 'sqlite') {
        return;
      }
      await dataSource.repo<User>().insertMany(buildDefaultUsers());
      await dataSource.connection.driver.executeRaw(
        'CREATE TABLE orm_test_join_updates ('
        'user_id INTEGER NOT NULL, '
        'label TEXT NOT NULL'
        ')',
      );
      await dataSource.connection.driver.executeRaw(
        'INSERT INTO orm_test_join_updates (user_id, label) VALUES (?, ?)',
        [1, 'alpha'],
      );
      await dataSource.connection.driver.executeRaw(
        'INSERT INTO orm_test_join_updates (user_id, label) VALUES (?, ?)',
        [2, 'beta'],
      );

      final affected = await dataSource.context
          .table('orm_test_join_updates')
          .join('users', 'users.id', '=', 'orm_test_join_updates.user_id')
          .orderBy('user_id')
          .limit(1)
          .update({'label': 'patched'});

      expect(affected, 1);

      final rows = await dataSource.connection.driver.queryRaw(
        'SELECT user_id, label FROM orm_test_join_updates ORDER BY user_id',
      );
      expect(rows.length, 2);
      expect(rows.first['label'], 'patched');
      expect(rows.last['label'], 'beta');
    });

    test('sqlite query deletes support joins and limits', () async {
      if (metadata.name != 'sqlite') {
        return;
      }
      await dataSource.repo<User>().insertMany(buildDefaultUsers());
      await dataSource.connection.driver.executeRaw(
        'CREATE TABLE orm_test_join_deletes ('
        'user_id INTEGER NOT NULL, '
        'label TEXT NOT NULL'
        ')',
      );
      await dataSource.connection.driver.executeRaw(
        'INSERT INTO orm_test_join_deletes (user_id, label) VALUES (?, ?)',
        [1, 'alpha'],
      );
      await dataSource.connection.driver.executeRaw(
        'INSERT INTO orm_test_join_deletes (user_id, label) VALUES (?, ?)',
        [2, 'beta'],
      );
      await dataSource.connection.driver.executeRaw(
        'INSERT INTO orm_test_join_deletes (user_id, label) VALUES (?, ?)',
        [3, 'gamma'],
      );

      final removed = await dataSource.context
          .table('orm_test_join_deletes')
          .join('users', 'users.id', '=', 'orm_test_join_deletes.user_id')
          .orderBy('user_id')
          .limit(1)
          .forceDelete();

      expect(removed, 1);

      final rows = await dataSource.connection.driver.queryRaw(
        'SELECT user_id FROM orm_test_join_deletes ORDER BY user_id',
      );
      expect(rows.map((row) => row['user_id']), equals([2, 3]));
    });

    test('query builder update json selectors patch nested payload', () async {
      final repo = dataSource.context.repository<DriverOverrideEntry>();
      await repo.insertMany(const [
        DriverOverrideEntry(
          id: 9100,
          payload: {
            'mode': 'light',
            'meta': {'count': 1},
          },
        ),
      ]);

      MutationEvent? mutation;
      dataSource.context.onMutation((event) => mutation = event);

      final affected = await dataSource.context
          .query<DriverOverrideEntry>()
          .whereEquals('id', 9100)
          .update({'payload->mode': 'dark', r'payload->$.meta.count': 5});

      expect(affected, 1);

      final refreshed = await dataSource.context
          .query<DriverOverrideEntry>()
          .whereEquals('id', 9100)
          .firstOrFail();

      expect(refreshed.payload['mode'], 'dark');
      expect((refreshed.payload['meta'] as Map)['count'], 5);
      expect(mutation, isNotNull);
      expectPreviewMetadata(mutation!.preview);
    });

    test('repository previewInsert exposes metadata', () async {
      final repo = dataSource.context.repository<User>();
      final preview = repo.previewInsert(
        const User(id: 9, email: 'preview@example.com', active: true),
      );

      expectPreviewMetadata(preview);
      final normalized = preview.normalized;
      expect(normalized.parameters, hasLength(8));
      expect(normalized.parameters[0], 9);
      expect(normalized.parameters[1], 'preview@example.com');
      expect(
        normalized.parameters[2],
        anyOf(isTrue, equals(1)),
        reason: 'boolean may be encoded as bool or int',
      );
      expect(normalized.parameters[3], isNull); // name
      expect(normalized.parameters[4], isNull); // age
      expect(normalized.parameters[5], anything); // createdAt
      expect(normalized.parameters[6], isNull); // profile
      expect(normalized.parameters[7], isNull); // metadata
    });

    test('mutation events include normalized parameters', () async {
      final events = <MutationEvent>[];
      dataSource.context.onMutation(events.add);

      final repo = dataSource.context.repository<User>();
      await repo.insert(
        const User(id: 11, email: 'events@example.com', active: true),
      );

      expect(events, isNotEmpty);
      final event = events.single;
      expectPreviewMetadata(event.preview);
      final normalized = event.preview.normalized;
      expect(normalized.parameters.length, 8);
      expect(normalized.parameters[0], 11);
      expect(normalized.parameters[1], 'events@example.com');
      expect(
        normalized.parameters[2],
        anyOf(isTrue, equals(1)),
        reason: 'boolean may be encoded as bool or int',
      );
      expect(normalized.parameters[3], isNull); // name
      expect(normalized.parameters[4], isNull); // age
      expect(normalized.parameters[5], anything); // createdAt
      expect(normalized.parameters[6], isNull); // profile
      expect(normalized.parameters[7], isNull); // metadata
      expect(event.affectedRows, 1);
      expect(event.succeeded, isTrue);
    });

    test('mutation events capture driver errors', () async {
      final events = <MutationEvent>[];
      dataSource.context.onMutation(events.add);

      // Try to insert with a value that violates constraints to trigger mutation error
      // Use duplicate primary key to cause error
      await dataSource.context.repository<User>().insert(
        const User(id: 1, email: 'first@example.com', active: true),
      );

      await expectLater(
        () => dataSource.context.repository<User>().insert(
          const User(id: 1, email: 'duplicate@example.com', active: true),
        ),
        throwsA(isA<Exception>()),
      );

      // Should have 2 events: first successful insert, then failed duplicate
      expect(events.length, greaterThanOrEqualTo(2));
      expect(events.last.error, isNotNull);
      expect(events.last.succeeded, isFalse);
    });

    test('json updates patch nested payload columns', () async {
      final docId = 9001;
      await dataSource.context.repository<DriverOverrideEntry>().insert(
        DriverOverrideEntry(
          id: docId,
          payload: const {
            'mode': 'dark',
            'meta': {'count': 1},
          },
        ),
      );

      final repo = dataSource.context.repository<DriverOverrideEntry>();
      await repo.updateMany(
        [
          DriverOverrideEntry(
            id: docId,
            payload: const {
              'mode': 'dark',
              'meta': {'count': 1},
            },
          ),
        ],
        jsonUpdates: (_) => [
          JsonUpdateDefinition.selector('payload->mode', 'light'),
          JsonUpdateDefinition.path('payload', r'$.meta.count', 5),
        ],
      );

      final refreshed = await dataSource.context
          .query<DriverOverrideEntry>()
          .whereEquals('id', docId)
          .firstOrFail();
      final payload = refreshed.payload;
      expect(payload['mode'], equals('light'));
      final meta = payload['meta'] as Map<String, Object?>?;
      expect(meta, isNotNull);
      expect(meta!['count'], equals(5));
    });

    test(
      'insert/update/delete returning payloads',
      () async {
        final repo = dataSource.context.repository<User>();
        final inserted = await repo.insert(
          const User(id: 20, email: 'returning@example.com', active: true),
        );
        expect(inserted.email, 'returning@example.com');

        final updated = await repo.updateMany([
          const User(id: 20, email: 'updated@returning.com', active: false),
        ]);
        expect(updated.single.email, 'updated@returning.com');
        expect(updated.single.active, isFalse);

        final deleted = await repo.deleteByKeys([
          {'id': 20},
        ]);
        expect(deleted, 1);
      },
      skip: metadata.supportsCapability(DriverCapability.returning)
          ? false
          : 'Driver does not support RETURNING mutations',
    );

    test(
      'upsert returning payloads',
      () async {
        final repo = dataSource.context.repository<User>();
        final first = await repo.upsertMany([
          const User(id: 25, email: 'upsert@return.com', active: true),
        ]);
        expect(first.single.email, 'upsert@return.com');

        final second = await repo.upsertMany([
          const User(id: 25, email: 'new@upsert.com', active: true),
        ]);
        expect(second.single.email, 'new@upsert.com');
      },
      skip: metadata.supportsCapability(DriverCapability.returning)
          ? false
          : 'Driver does not support RETURNING mutations',
    );

    test('query updates warn when using fallback row identifiers', () async {
      final table =
          'orm_warning_updates_${DateTime.now().microsecondsSinceEpoch}';
      final driver = dataSource.connection.driver;
      await driver.executeRaw(
        'CREATE TABLE $table (id INTEGER, name TEXT)',
      );
      await driver.executeRaw(
        'INSERT INTO $table (id, name) VALUES (?, ?)',
        [1, 'alpha'],
      );

      final warnings = <QueryWarning>[];
      dataSource.context.onWarning(warnings.add);

      try {
        final columns = const [
          AdHocColumn(name: 'id', columnName: 'id'),
          AdHocColumn(name: 'name', columnName: 'name'),
        ];

        await dataSource.context
            .table(table, columns: columns)
            .whereEquals('id', 1)
            .update({'name': 'beta'});

        expect(
          warnings.any((warning) => warning.feature == 'update'),
          isTrue,
        );
      } finally {
        await driver.executeRaw('DROP TABLE IF EXISTS $table');
      }
    });

    test('forceDelete warns when using fallback row identifiers', () async {
      final table =
          'orm_warning_deletes_${DateTime.now().microsecondsSinceEpoch}';
      final driver = dataSource.connection.driver;
      await driver.executeRaw(
        'CREATE TABLE $table (id INTEGER, name TEXT)',
      );
      await driver.executeRaw(
        'INSERT INTO $table (id, name) VALUES (?, ?)',
        [1, 'alpha'],
      );

      final warnings = <QueryWarning>[];
      dataSource.context.onWarning(warnings.add);

      try {
        final columns = const [
          AdHocColumn(name: 'id', columnName: 'id'),
          AdHocColumn(name: 'name', columnName: 'name'),
        ];

        await dataSource.context
            .table(table, columns: columns)
            .whereEquals('id', 1)
            .forceDelete();

        expect(
          warnings.any((warning) => warning.feature == 'forceDelete'),
          isTrue,
        );
      } finally {
        await driver.executeRaw('DROP TABLE IF EXISTS $table');
      }
    });

    test(
      'forceDelete with custom projections works with fallback identifiers',
      () async {
        final table =
            'orm_projection_delete_${DateTime.now().microsecondsSinceEpoch}';
        final driver = dataSource.connection.driver;
        await driver.executeRaw(
          'CREATE TABLE $table (id INTEGER, name TEXT)',
        );
        await driver.executeRaw(
          'INSERT INTO $table (id, name) VALUES (?, ?)',
          [1, 'alpha'],
        );

        try {
          final columns = const [
            AdHocColumn(name: 'id', columnName: 'id'),
            AdHocColumn(name: 'name', columnName: 'name'),
          ];

          final deleted = await dataSource.context
              .table(table, columns: columns)
              .select(['name'])
              .selectRaw('1 AS projection_marker')
              .whereEquals('id', 1)
              .forceDelete();

          expect(deleted, 1);
        } finally {
          await driver.executeRaw('DROP TABLE IF EXISTS $table');
        }
      },
      skip: metadata.name == 'postgres'
          ? false
          : 'Postgres fallback identifier repro only',
    );
  });
}

// TODO: ModelDefinition<Map<String, Object?>> no longer supported after DTO refactoring
// These definitions were used by the 'auto increment primary keys' test above.
// const FieldDefinition _serialIdField = FieldDefinition(
//   name: 'id',
//   columnName: 'id',
//   dartType: 'int',
//   resolvedType: 'int',
//   isPrimaryKey: true,
//   isNullable: false,
//   isUnique: false,
//   isIndexed: false,
//   autoIncrement: true,
// );
// const FieldDefinition _serialLabelField = FieldDefinition(
//   name: 'label',
//   columnName: 'label',
//   dartType: 'String',
//   resolvedType: 'String',
//   isPrimaryKey: false,
//   isNullable: false,
//   isUnique: false,
//   isIndexed: false,
//   autoIncrement: false,
// );
// final ModelDefinition<Map<String, Object?>> _serialTestDefinition =
//     ModelDefinition<Map<String, Object?>>(
//       modelName: 'SerialTest',
//       tableName: 'serial_tests',
//       fields: const [_serialIdField, _serialLabelField],
//       codec: const _PlainMapCodec(),
//     );
// class _PlainMapCodec extends ModelCodec<Map<String, Object?>> {
//   const _PlainMapCodec();
//   @override
//   Map<String, Object?> encode(
//     Map<String, Object?> model,
//     ValueCodecRegistry registry,
//   ) => Map<String, Object?>.from(model);
//   @override
//   Map<String, Object?> decode(
//     Map<String, Object?> data,
//     ValueCodecRegistry registry,
//   ) => Map<String, Object?>.from(data);
// }
