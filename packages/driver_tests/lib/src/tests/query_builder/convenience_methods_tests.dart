import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

import '../../models/models.dart';

/// Tests for model convenience methods (fill, forceFill, setAttributes, etc.)
void runConvenienceMethodsTests() {
  ormedGroup('Convenience Methods', (dataSource) {
    group('exists property', () {
      test('returns false for new model', () {
        final user = User(id: 1, email: 'test@example.com', active: true);

        expect(user.exists, false);
      });

      test('returns true for fetched model', () async {
        final user = User(id: 1, email: 'test@example.com', active: true);
        await dataSource.repo<User>().insert(user);

        final fetched = await dataSource.context
            .query<User>()
            .where('id', 1)
            .first();

        expect(fetched, isNotNull);
        expect(fetched!.exists, true);
      });
    });

    group('fill()', () {
      test('sets attributes respecting fillable rules', () async {
        // Insert a user first so we get a tracked instance
        await dataSource.repo<User>().insert(
          User(id: 1, email: 'original@example.com', active: true),
        );

        // Fetch to get a tracked instance
        final user = await dataSource.context
            .query<User>()
            .where('id', 1)
            .first();

        expect(user, isNotNull);

        user!.fill({
          'name': 'Test Name', // This will be ignored - not in fillable list
          'email': 'new@example.com',
        });

        // 'name' is not fillable, so it should remain null
        expect(user.getAttribute('name'), isNull);
        // 'email' is fillable, so it should be set
        expect(user.getAttribute('email'), 'new@example.com');
      });

      test('is a convenience wrapper for fillAttributes', () async {
        await dataSource.repo<User>().insert(
          User(id: 1, email: 'test@example.com', active: true),
        );

        final user = await dataSource.context
            .query<User>()
            .where('id', 1)
            .first();

        expect(user, isNotNull);

        // Both should work the same way
        // Note: 'email' is fillable, 'name' is not (per User model definition)
        user!.fill({'email': 'via-fill@example.com'});
        expect(user.getAttribute('email'), 'via-fill@example.com');

        user.fillAttributes({'email': 'via-fillAttributes@example.com'});
        expect(user.getAttribute('email'), 'via-fillAttributes@example.com');
      });

      test('accepts partials and DTOs', () async {
        await dataSource.repo<User>().insert(
          User(id: 1, email: 'test@example.com', active: true),
        );

        final user = await dataSource.context
            .query<User>()
            .where('id', 1)
            .first();

        expect(user, isNotNull);

        user!.fill(UserPartial(email: 'partial@example.com', name: 'Ignored'));
        expect(user.getAttribute('email'), 'partial@example.com');
        expect(user.getAttribute('name'), isNull);

        user.fill(
          UserInsertDto(email: 'dto@example.com', name: 'Still Ignored'),
        );
        expect(user.getAttribute('email'), 'dto@example.com');
        expect(user.getAttribute('name'), isNull);
      });
    });

    group('forceFill()', () {
      test('bypasses fillable/guarded protection', () async {
        await dataSource.repo<User>().insert(
          User(id: 1, email: 'test@example.com', active: true),
        );

        final user = await dataSource.context
            .query<User>()
            .where('id', 1)
            .first();

        expect(user, isNotNull);

        // forceFill should work even for guarded attributes
        user!.forceFill({'name': 'Forced Name', 'email': 'forced@example.com'});

        expect(user.getAttribute('name'), 'Forced Name');
        expect(user.getAttribute('email'), 'forced@example.com');
      });

      test('uses unguarded mode internally', () async {
        await dataSource.repo<User>().insert(
          User(id: 1, email: 'test@example.com', active: true),
        );

        final user = await dataSource.context
            .query<User>()
            .where('id', 1)
            .first();

        expect(user, isNotNull);

        // Should not throw even if attributes are guarded
        expect(
          () => user!.forceFill({'name': 'Test', 'email': 'test@example.com'}),
          returnsNormally,
        );
      });

      test('accepts DTO inputs', () async {
        await dataSource.repo<User>().insert(
          User(id: 1, email: 'test@example.com', active: true),
        );

        final user = await dataSource.context
            .query<User>()
            .where('id', 1)
            .first();

        expect(user, isNotNull);

        user!.forceFill(
          UserUpdateDto(name: 'Forced Name', email: 'forced@example.com'),
        );
        expect(user.getAttribute('name'), 'Forced Name');
        expect(user.getAttribute('email'), 'forced@example.com');
      });
    });

    group('fillIfAbsent()', () {
      test('accepts DTO inputs', () async {
        await dataSource.repo<User>().insert(
          User(id: 1, email: 'original@example.com', active: true),
        );

        final user = await dataSource.context
            .query<User>()
            .where('id', 1)
            .first();

        expect(user, isNotNull);

        user!.fillIfAbsent(UserInsertDto(email: 'new@example.com'));
        expect(user.getAttribute('email'), 'original@example.com');

        user.setAttribute('email', null);
        user.fillIfAbsent(UserInsertDto(email: 'filled@example.com'));
        expect(user.getAttribute('email'), 'filled@example.com');
      });
    });

    group('setAttributes()', () {
      test('sets multiple attributes at once', () async {
        await dataSource.repo<User>().insert(
          User(id: 1, email: 'original@example.com', active: true),
        );

        final user = await dataSource.context
            .query<User>()
            .where('id', 1)
            .first();

        expect(user, isNotNull);

        user!.setAttributes({
          'name': 'New Name',
          'email': 'new@example.com',
          'active': false,
        });

        expect(user.getAttribute('name'), 'New Name');
        expect(user.getAttribute('email'), 'new@example.com');
        expect(user.getAttribute('active'), false);
      });

      test('bypasses fillable/guarded checks', () async {
        await dataSource.repo<User>().insert(
          User(id: 1, email: 'test@example.com', active: true),
        );

        final user = await dataSource.context
            .query<User>()
            .where('id', 1)
            .first();

        expect(user, isNotNull);

        // Should work regardless of fillable/guarded
        expect(
          () => user!.setAttributes({
            'name': 'Test',
            'email': 'test@example.com',
          }),
          returnsNormally,
        );
      });

      test('can set empty map', () async {
        await dataSource.repo<User>().insert(
          User(id: 1, email: 'test@example.com', active: true),
        );

        final user = await dataSource.context
            .query<User>()
            .where('id', 1)
            .first();

        expect(user, isNotNull);
        expect(() => user!.setAttributes({}), returnsNormally);
      });
    });

    group('hasAttribute()', () {
      test('returns true for existing attributes', () async {
        await dataSource.repo<User>().insert(
          User(
            id: 1,
            email: 'test@example.com',
            name: 'Test User',
            active: true,
          ),
        );

        final fetched = await dataSource.context
            .query<User>()
            .where('id', 1)
            .first();

        expect(fetched!.hasAttribute('id'), true);
        expect(fetched.hasAttribute('email'), true);
        expect(fetched.hasAttribute('name'), true);
        expect(fetched.hasAttribute('active'), true);
      });

      test('returns false for non-existent attributes', () async {
        final user = User(id: 1, email: 'test@example.com', active: true);
        await dataSource.repo<User>().insert(user);

        final fetched = await dataSource.context
            .query<User>()
            .where('id', 1)
            .first();

        // Fetched models have all fields in attributes map
        expect(fetched!.hasAttribute('email'), true);
        expect(fetched.hasAttribute('id'), true);

        // But not non-existent fields
        expect(fetched.hasAttribute('nonexistent'), false);
        expect(fetched.hasAttribute('random_field'), false);
      });

      test('hasAttribute reflects tracked and custom fields', () async {
        // Create and save to get a tracked model
        final user = User(id: 1, email: 'test@example.com', active: true);
        await dataSource.repo<User>().insert(user);

        // Fetch tracked model from database
        final tracked = await dataSource.context
            .query<User>()
            .where('id', 1)
            .first();

        // Tracked models have attributes populated from database
        expect(tracked!.hasAttribute('email'), true);
        expect(tracked.hasAttribute('id'), true);

        // Can set additional attributes on tracked models
        tracked.setAttribute('name', 'Test Name');

        expect(tracked.hasAttribute('name'), true);
        expect(tracked.hasAttribute('nonexistent'), false);
      });
    });

    group('getAttributes()', () {
      test('returns all attributes as map', () async {
        final user = User(
          id: 1,
          email: 'test@example.com',
          name: 'Test User',
          active: true,
        );
        await dataSource.repo<User>().insert(user);

        final fetched = await dataSource.context
            .query<User>()
            .where('id', 1)
            .first();

        final attrs = fetched!.getAttributes();
        expect(attrs, isA<Map<String, Object?>>());
        expect(attrs['id'], 1);
        expect(attrs['email'], 'test@example.com');
        expect(attrs['name'], 'Test User');
        expect(attrs['active'], true);
      });

      test('is consistent with attributes getter', () async {
        final user = User(id: 1, email: 'test@example.com', active: true);
        await dataSource.repo<User>().insert(user);

        final fetched = await dataSource.context
            .query<User>()
            .where('id', 1)
            .first();

        final viaMethod = fetched!.getAttributes();
        final viaGetter = fetched.attributes;

        expect(viaMethod.keys, equals(viaGetter.keys));
        for (final key in viaMethod.keys) {
          expect(viaMethod[key], equals(viaGetter[key]));
        }
      });
    });

    group('Integration', () {
      test('convenience methods work together', () async {
        final user = User(
          id: 1,
          email: 'test@example.com',
          name: 'Initial Name',
          active: true,
        );

        // New models don't exist yet
        expect(user.exists, false);

        await dataSource.repo<User>().insert(user);

        // Fetch and verify
        final fetched = await dataSource.context
            .query<User>()
            .where('id', 1)
            .first();

        expect(fetched!.exists, true);
        expect(fetched.hasAttribute('name'), true);
        expect(fetched.getAttribute('name'), 'Initial Name');

        // Use forceFill to update (bypasses fillable rules)
        fetched.forceFill({'name': 'Updated Name'});
        expect(fetched.getAttribute('name'), 'Updated Name');

        // Use setAttributes to update the attributes map directly
        fetched.setAttributes({'name': 'Force Updated'});
        expect(fetched.getAttribute('name'), 'Force Updated');

        // Get all attributes
        final attrs = fetched.getAttributes();
        expect(attrs['name'], 'Force Updated');
      });
    });
  });
}
