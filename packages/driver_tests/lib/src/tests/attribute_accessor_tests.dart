import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

import '../models/models.dart';

void runAttributeAccessorTests() {
  ormedGroup('Attribute Accessors', (dataSource) {
    test('accessors apply after insert and reflect saved updates', () async {
      final repo = dataSource.repo<AccessorUser>();
      await repo.insert(
        AccessorUser(
          id: 1,
          firstName: 'Ada',
          lastName: 'Lovelace',
          email: 'Ada@Example.com',
        ),
      );

      final fetched = await dataSource.context
          .query<AccessorUser>()
          .where('id', 1)
          .first();
      final $AccessorUser tracked = fetched!.toTracked();

      expect(tracked.fullName, 'Ada Lovelace');
      expect(tracked.emailDomain, 'example.com');
      expect(tracked.toArray()['full_name'], 'Ada Lovelace');
      expect(tracked.toArray()['email_domain'], 'example.com');

      tracked.firstName = 'Ada';
      tracked.lastName = 'Byron';
      tracked.normalizeEmail('Ada@Compute.io');
      await tracked.save();

      final updated = await dataSource.context
          .query<AccessorUser>()
          .where('id', 1)
          .first();
      final $AccessorUser updatedTracked = updated!.toTracked();

      expect(updatedTracked.email, 'ada@compute.io');
      expect(updatedTracked.fullName, 'Ada Byron');
      expect(updatedTracked.emailDomain, 'compute.io');
      expect(updatedTracked.toArray()['full_name'], 'Ada Byron');
      expect(updatedTracked.toArray()['email_domain'], 'compute.io');
    });

    test('mutators apply during fill and persist', () async {
      final user = AccessorUser(
        id: 2,
        firstName: 'Grace',
        lastName: 'Hopper',
        email: 'Grace@Example.com',
      ).toTracked();

      user.fill({'email': 'Grace@Example.com'});
      await user.save();

      final fetched = await dataSource.context
          .query<AccessorUser>()
          .where('id', 2)
          .first();
      final $AccessorUser tracked = fetched!.toTracked();

      expect(tracked.email, 'grace@example.com');
      expect(tracked.getAttribute<String>('email'), 'grace@example.com');
      expect(tracked.emailDomain, 'example.com');
    });
  });
}
