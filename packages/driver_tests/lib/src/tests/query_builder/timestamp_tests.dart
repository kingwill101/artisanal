import 'package:ormed/ormed.dart';
import 'package:test/test.dart' hide Tags;

import '../../models/models.dart';

/// Tests for timestamp functionality (Timestamps and TimestampsTZ mixins)
///
/// Note: TimeMachine (named timezone support) should be configured via
/// DataSourceOptions.enableNamedTimezones = true, or the timezone conversion
/// tests will fail.
void runTimestampTests() {
  ormedGroup('Timestamps', (dataSource) {
    group('Non-TZ Timestamps (Author)', () {
      test('createdAt is set automatically on insert', () async {
        final author = const Author(id: 1000, name: 'Test Author');
        await Authors.repo(dataSource.options.name).insert(author.toTracked());

        final fetched = await Authors.query(
          dataSource.options.name,
        ).where('id', 1000).first();

        expect(fetched, isNotNull);
        expect(fetched!.createdAt, isNotNull);
        expect(fetched.createdAt, isA<CarbonInterface>());
      });

      test('updatedAt is set automatically on insert', () async {
        final author = const Author(id: 1001, name: 'Test Author 2');
        await Authors.repo(dataSource.options.name).insert(author.toTracked());

        final fetched = await Authors.query(
          dataSource.options.name,
        ).where('id', 1001).first();

        expect(fetched, isNotNull);
        expect(fetched!.updatedAt, isNotNull);
        expect(fetched.updatedAt, isA<CarbonInterface>());
      });

      test('InsertDto sets timestamps when omitted', () async {
        final label = 'dto_${DateTime.now().microsecondsSinceEpoch}';
        final inserted = await Tags.repo(
          dataSource.options.name,
        ).insert(TagInsertDto(label: label));

        final fetched = await Tags.query(
          dataSource.options.name,
        ).where('id', inserted.id).first();

        expect(fetched, isNotNull);
        expect(fetched!.createdAt, isNotNull);
        expect(fetched.updatedAt, isNotNull);
      });

      test('updatedAt changes on update', () async {
        final author = const Author(id: 1002, name: 'Original Name');
        await Authors.repo(dataSource.options.name).insert(author.toTracked());

        final fetched = await Authors.query(
          dataSource.options.name,
        ).where('id', 1002).first();

        final originalUpdatedAt = fetched!.updatedAt;

        // Wait longer to ensure timestamp difference (MySQL has millisecond precision)
        await Future.delayed(const Duration(milliseconds: 500));

        // Update the author
        await Authors.query(
          dataSource.options.name,
        ).where('id', 1002).update({'name': 'Updated Name'});

        final refetched = await Authors.query(
          dataSource.options.name,
        ).where('id', 1002).first();

        expect(refetched!.updatedAt, isNotNull);
        expect(
          refetched.updatedAt!.toDateTime().millisecondsSinceEpoch,
          isNot(equals(originalUpdatedAt!.toDateTime().millisecondsSinceEpoch)),
        );
      });

      test('explicit updatedAt in update map is preserved', () async {
        final author = const Author(id: 1005, name: 'Explicit Map');
        await Authors.repo(dataSource.options.name).insert(author.toTracked());

        final explicit = Carbon.fromDateTime(DateTime.utc(2020, 1, 2, 3, 4, 5));

        await Authors.query(dataSource.options.name).where('id', 1005).update({
          'name': 'Explicit Map Updated',
          'updatedAt': explicit,
        });

        final fetched = await Authors.query(
          dataSource.options.name,
        ).where('id', 1005).first();

        expect(fetched, isNotNull);
        expect(
          fetched!.updatedAt!.toDateTime().millisecondsSinceEpoch,
          equals(explicit.toDateTime().millisecondsSinceEpoch),
        );
      });

      test('touch() updates updatedAt', () async {
        final author = const Author(id: 1003, name: 'Touch Test');
        await Authors.repo(dataSource.options.name).insert(author.toTracked());

        final fetchedTracked = await Authors.query(
          dataSource.options.name,
        ).where('id', 1003).first();

        final originalUpdatedAt = fetchedTracked!.updatedAt;

        // Wait longer to ensure timestamp difference (MySQL has millisecond precision)
        await Future.delayed(const Duration(milliseconds: 500));

        // Touch the model
        await fetchedTracked.touch();

        final refetched = await Authors.query(
          dataSource.options.name,
        ).where('id', 1003).first();

        expect(refetched!.updatedAt, isNotNull);
        expect(
          refetched.updatedAt!.toDateTime().millisecondsSinceEpoch,
          isNot(equals(originalUpdatedAt!.toDateTime().millisecondsSinceEpoch)),
        );
      });

      test('Carbon methods work on createdAt', () async {
        final now = Carbon.now();
        Carbon.setTestNow(now);

        try {
          final author = const Author(id: 1004, name: 'Carbon Test');
          final tracked = author.toTracked();
          tracked.createdAt = now;
          await Authors.repo(dataSource.options.name).insert(tracked);

          final fetched = await Authors.query(
            dataSource.options.name,
          ).where('id', 1004).first();

          expect(fetched, isNotNull);
          expect(fetched!.createdAt, isNotNull);

          // Test Carbon methods - use Dart DateFormat syntax
          final formatted = fetched.createdAt!.format('yyyy-MM-dd');
          expect(formatted, isA<String>());
          expect(formatted.length, equals(10)); // YYYY-MM-DD format

          final diffHumans = fetched.createdAt!.diffForHumans();
          expect(diffHumans, isA<String>());
          // Check that it contains a time-related word (second, minute, hour, etc.)
          expect(
            diffHumans.contains('second') ||
                diffHumans.contains('seconds') ||
                diffHumans.contains('ago') ||
                diffHumans.contains('now'),
            isTrue,
            reason:
                'Expected diffForHumans to contain time reference, got: $diffHumans',
          );
        } finally {
          Carbon.setTestNow(null);
        }
      });
    });

    group('TZ-Aware Timestamps (Post)', () {
      test('createdAt is set automatically on insert (UTC)', () async {
        final post = Post(
          id: 2000,
          authorId: 1,
          title: 'Test Post',
          publishedAt: DateTime.now(),
        );
        await dataSource.repo<Post>().insert(post);

        final fetched = await dataSource.context
            .query<Post>()
            .where('id', 2000)
            .first();

        expect(fetched, isNotNull);
        expect(fetched!.createdAt, isNotNull);
        expect(fetched.createdAt, isA<CarbonInterface>());
        expect(fetched.createdAt!.isUtc, isTrue);
      });

      test('updatedAt is set automatically on insert (UTC)', () async {
        final post = Post(
          id: 2001,
          authorId: 1,
          title: 'Test Post 2',
          publishedAt: DateTime.now(),
        );
        await dataSource.repo<Post>().insert(post);

        final fetched = await dataSource.context
            .query<Post>()
            .where('id', 2001)
            .first();

        expect(fetched, isNotNull);
        expect(fetched!.updatedAt, isNotNull);
        expect(fetched.updatedAt, isA<CarbonInterface>());
        expect(fetched.updatedAt!.isUtc, isTrue);
      });

      test('updatedAt changes on update (UTC)', () async {
        final post = Post(
          id: 2002,
          authorId: 1,
          title: 'Original Title',
          publishedAt: DateTime.now(),
        );
        await dataSource.repo<Post>().insert(post);

        final fetched = await dataSource.context
            .query<Post>()
            .where('id', 2002)
            .first();

        final originalUpdatedAt = fetched!.updatedAt;

        // Wait a moment
        await Future.delayed(const Duration(milliseconds: 100));

        // Update
        await dataSource.context.query<Post>().where('id', 2002).update({
          'title': 'Updated Title',
        });

        final refetched = await dataSource.context
            .query<Post>()
            .where('id', 2002)
            .first();

        expect(refetched!.updatedAt, isNotNull);
        expect(refetched.updatedAt!.isUtc, isTrue);
        expect(
          refetched.updatedAt!.toDateTime().millisecondsSinceEpoch,
          isNot(equals(originalUpdatedAt!.toDateTime().millisecondsSinceEpoch)),
        );
      });

      test('explicit updatedAt on tracked model is preserved (UTC)', () async {
        final post = Post(
          id: 2004,
          authorId: 1,
          title: 'Explicit Model Timestamp',
          publishedAt: DateTime.now(),
        );
        await dataSource.repo<Post>().insert(post);

        final fetched = await dataSource.context
            .query<Post>()
            .where('id', 2004)
            .first();

        final explicit = Carbon.fromDateTime(DateTime.utc(2021, 2, 3, 4, 5, 6));
        fetched!.updatedAt = explicit;

        await dataSource.context.query<Post>().updateInputs([fetched]);

        final refetched = await dataSource.context
            .query<Post>()
            .where('id', 2004)
            .first();

        expect(refetched, isNotNull);
        expect(refetched!.updatedAt!.isUtc, isTrue);
        expect(
          refetched.updatedAt!.toDateTime().millisecondsSinceEpoch,
          equals(explicit.toDateTime().millisecondsSinceEpoch),
        );
      });

      test('touch() updates updatedAt (UTC)', () async {
        final post = Post(
          id: 2003,
          authorId: 1,
          title: 'Touch Test',
          publishedAt: DateTime.now(),
        );
        await dataSource.repo<Post>().insert(post);

        final fetchedTracked = await dataSource.context
            .query<Post>()
            .where('id', 2003)
            .first();

        final originalUpdatedAt = fetchedTracked!.updatedAt;

        // Wait a moment
        await Future.delayed(const Duration(milliseconds: 100));

        // Touch
        await fetchedTracked.touch();

        final refetched = await dataSource.context
            .query<Post>()
            .where('id', 2003)
            .first();

        expect(refetched!.updatedAt, isNotNull);
        expect(refetched.updatedAt!.isUtc, isTrue);
        expect(
          refetched.updatedAt!.toDateTime().millisecondsSinceEpoch,
          isNot(equals(originalUpdatedAt!.toDateTime().millisecondsSinceEpoch)),
        );
      });

      test('Carbon methods work on UTC timestamps', () async {
        final now = Carbon.now().toUtc();
        Carbon.setTestNow(now);

        try {
          final post = Post(
            id: 2004,
            authorId: 1,
            title: 'Carbon TZ Test',
            publishedAt: now.toDateTime(),
          );
          final tracked = post.toTracked();
          tracked.createdAt = now;

          await dataSource.repo<Post>().insert(tracked);

          final fetched = await dataSource.context
              .query<Post>()
              .where('id', 2004)
              .first();

          expect(fetched, isNotNull);
          expect(fetched!.createdAt, isNotNull);
          expect(fetched.createdAt!.isUtc, isTrue);

          // Test Carbon timezone methods - use Dart DateFormat syntax
          final formatted = fetched.createdAt!.format('yyyy-MM-dd HH:mm:ss z');
          expect(formatted, contains('UTC'));

          // Test that we can access Carbon properties
          expect(fetched.createdAt!.isUtc, isTrue);

          // Test timezone conversion (now works because TimeMachine is configured)
          final eastern = fetched.createdAt!.tz('America/New_York');
          expect(eastern, isNotNull);
          expect(eastern, isA<CarbonInterface>());

          // Test comparison methods.
          //
          // Note: Some environments (notably MariaDB in CI) can exhibit small
          // clock skew between the database container and the test runner.
          // We use Carbon.setTestNow() to ensure consistent "now" during the test.
          expect(fetched.createdAt!.addDays(1).isFuture(), isTrue);
          final yesterday = fetched.createdAt!.subDay();
          expect(yesterday.isFuture(), isFalse);
          expect(yesterday.isPast(), isTrue);
        } finally {
          Carbon.setTestNow(null);
        }
      });

      test('can set timestamps explicitly', () async {
        final customTime = DateTime(2024, 1, 1, 12, 0, 0);
        final post = Post(
          id: 2005,
          authorId: 1,
          title: 'Custom Time Test',
          publishedAt: DateTime.now(),
        );

        await dataSource.repo<Post>().insert(post);
        final fetched = await dataSource.context
            .query<Post>()
            .where('id', 2005)
            .first();

        // Set custom timestamp
        fetched!.createdAt = customTime;
        await fetched.save();

        final refetched = await dataSource.context
            .query<Post>()
            .where('id', 2005)
            .first();

        expect(refetched!.createdAt, isNotNull);
        expect(refetched.createdAt!.year, equals(2024));
        expect(refetched.createdAt!.month, equals(1));
        expect(refetched.createdAt!.day, equals(1));
      });
    });

    group('Carbon Localization', () {
      test('diffForHumans supports locales', () async {
        final author = const Author(id: 1005, name: 'Locale Test');
        await dataSource.repo<Author>().insert(author);

        final fetched = await dataSource.context
            .query<Author>()
            .where('id', 1005)
            .first();

        expect(fetched, isNotNull);
        expect(fetched!.createdAt, isNotNull);

        // English (default)
        final english = fetched.createdAt!.diffForHumans();
        expect(english, isA<String>());

        // French
        final french = fetched.createdAt!.locale('fr').diffForHumans();
        expect(french, isA<String>());
      });

      test('format supports locale-specific formatting', () async {
        final author = const Author(id: 1006, name: 'Format Locale Test');
        await dataSource.repo<Author>().insert(author);

        final fetched = await dataSource.context
            .query<Author>()
            .where('id', 1006)
            .first();

        expect(fetched, isNotNull);
        expect(fetched!.createdAt, isNotNull);

        // Format with different locales
        final englishFormat = fetched.createdAt!.format('l, F jS Y');
        expect(englishFormat, isA<String>());

        final frenchFormat = fetched.createdAt!.locale('fr').format('l d F Y');
        expect(frenchFormat, isA<String>());
      });
    });

    group('Touching', () {
      test('touches owners on save when configured', () async {
        final author = const Author(id: 3000, name: 'Touch Owner');
        await Authors.repo(dataSource.options.name).insert(author.toTracked());

        final post = Post(
          id: 3001,
          authorId: 3000,
          title: 'Touch Parent',
          publishedAt: DateTime.now(),
        );
        await Posts.repo(dataSource.options.name).insert(post.toTracked());

        final fetchedPost = await Posts.query(
          dataSource.options.name,
        ).where('id', 3001).first();
        final beforeAuthor = await Authors.query(
          dataSource.options.name,
        ).where('id', 3000).first();

        await Future.delayed(const Duration(milliseconds: 500));
        fetchedPost!.title = 'Touch Parent Updated';
        await fetchedPost.save();

        final afterAuthor = await Authors.query(
          dataSource.options.name,
        ).where('id', 3000).first();

        expect(afterAuthor, isNotNull);
        expect(beforeAuthor, isNotNull);
        final beforeMillis =
            beforeAuthor!.updatedAt!.toDateTime().millisecondsSinceEpoch;
        final afterMillis =
            afterAuthor!.updatedAt!.toDateTime().millisecondsSinceEpoch;
        expect(afterMillis, isNot(equals(beforeMillis)));
        expect(afterMillis, greaterThanOrEqualTo(beforeMillis - 1000));
      });

      test('withoutTouching suppresses owner touching', () async {
        final author = const Author(id: 3002, name: 'No Touch Owner');
        await Authors.repo(dataSource.options.name).insert(author.toTracked());

        final post = Post(
          id: 3003,
          authorId: 3002,
          title: 'No Touch Parent',
          publishedAt: DateTime.now(),
        );
        await Posts.repo(dataSource.options.name).insert(post.toTracked());

        final fetchedPost = await Posts.query(
          dataSource.options.name,
        ).where('id', 3003).first();
        final beforeAuthor = await Authors.query(
          dataSource.options.name,
        ).where('id', 3002).first();

        await Future.delayed(const Duration(milliseconds: 500));
        await Model.withoutTouchingOn(<Type>[Post], () async {
          fetchedPost!.title = 'No Touch Parent Updated';
          await fetchedPost.save();
        });

        final afterAuthor = await Authors.query(
          dataSource.options.name,
        ).where('id', 3002).first();

        expect(afterAuthor, isNotNull);
        expect(beforeAuthor, isNotNull);
        expect(
          afterAuthor!.updatedAt!.toDateTime().millisecondsSinceEpoch,
          equals(beforeAuthor!.updatedAt!.toDateTime().millisecondsSinceEpoch),
        );
      });

      test('withoutTimestamps skips automatic updated_at', () async {
        final author = const Author(id: 3004, name: 'No Timestamp');
        await Authors.repo(dataSource.options.name).insert(author.toTracked());

        final before = await Authors.query(
          dataSource.options.name,
        ).where('id', 3004).first();

        await Future.delayed(const Duration(milliseconds: 500));
        await Model.withoutTimestampsOn(<Type>[Author], () async {
          await Authors.query(
            dataSource.options.name,
          ).where('id', 3004).update({'name': 'No Timestamp Updated'});
        });

        final after = await Authors.query(
          dataSource.options.name,
        ).where('id', 3004).first();

        expect(before, isNotNull);
        expect(after, isNotNull);
        expect(
          after!.updatedAt!.toDateTime().millisecondsSinceEpoch,
          equals(before!.updatedAt!.toDateTime().millisecondsSinceEpoch),
        );
      });
    });
  });
}
