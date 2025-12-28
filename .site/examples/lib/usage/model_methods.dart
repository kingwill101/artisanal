// Model methods examples for documentation
// ignore_for_file: unused_local_variable

import 'package:ormed/ormed.dart';

import '../models/user.dart';
import '../models/user.orm.dart';
import '../models/post.dart';
import '../models/post.orm.dart';
import '../models/product.dart';
import '../models/product.orm.dart';

// #region model-copywith
void copyWithExample() {
  final user = User(id: 1, email: 'user@example.com', name: 'Ada');

  final renamed = user.copyWith(name: 'Grace');
  final cleared = user.copyWith(name: null);

  print(renamed.name); // Grace
  print(cleared.name); // null
}
// #endregion model-copywith

// #region model-map-helpers
void mapHelpersExample() {
  final user = User(id: 1, email: 'user@example.com', name: 'Ada');

  final map = user.toMap();
  final decoded = UserOrmExtension.fromMap(map);
  final tracked = $User.fromMap(map);

  print(map['email']); // user@example.com
  print(decoded.runtimeType); // $User
  print(tracked.email); // user@example.com
}
// #endregion model-map-helpers

// #region model-replicate
Future<void> replicateExample(DataSource dataSource) async {
  final original = await dataSource.query<$User>().find(1);

  // Create a replica
  if (original != null) {
    final duplicate = original.replicate();
    duplicate.setAttribute('email', 'new@example.com');
    await dataSource.repo<$User>().insert(duplicate);
  }
}
// #endregion model-replicate

// #region model-replicate-exclude
Future<void> replicateExcludeExample(DataSource dataSource) async {
  final post = await dataSource.query<$Post>().find(1);
  if (post != null) {
    final duplicate = post.replicate(except: ['slug', 'viewCount']);

    duplicate.setAttribute('slug', 'new-unique-slug');
    duplicate.setAttribute('viewCount', 0);
    await dataSource.repo<$Post>().insert(duplicate);
  }
}
// #endregion model-replicate-exclude

// #region model-replicate-usecases
Future<void> replicateUseCases(DataSource dataSource) async {
  // Duplicating Records
  final product = await dataSource.query<$Product>().find(1);
  if (product != null) {
    final duplicate = product.replicate(except: ['sku', 'barcode']);
    duplicate.setAttribute('sku', 'NEW-SKU-001');
    duplicate.setAttribute('name', '${product.name} (Copy)');
    await dataSource.repo<$Product>().insert(duplicate);
  }

  // Test Fixtures
  final template = $User(id: 0, name: 'Test User', email: 'template@test.com');

  final user1 = template.replicate();
  user1.setAttribute('email', 'user1@test.com');

  final user2 = template.replicate();
  user2.setAttribute('email', 'user2@test.com');

  await dataSource.repo<$User>().insertMany([user1, user2]);
}
// #endregion model-replicate-usecases

// #region model-comparison
Future<void> comparisonExample(DataSource dataSource) async {
  final user1 = await dataSource.query<$User>().find(1);
  final user2 = await dataSource.query<$User>().find(1);

  if (user1 != null && user2 != null && user1.isSameAs(user2)) {
    print('These are the same user');
  }
}
// #endregion model-comparison

// #region model-different
Future<void> differentExample(DataSource dataSource) async {
  final user1 = await dataSource.query<$User>().find(1);
  final user2 = await dataSource.query<$User>().find(2);

  if (user1 != null && user2 != null && user1.isDifferentFrom(user2)) {
    print('These are different users');
  }
}
// #endregion model-different

// #region model-dedupe
Future<void> dedupeExample(DataSource dataSource) async {
  final users = await dataSource.query<$User>().get();
  final unique = <$User>[];

  for (final user in users) {
    if (!unique.any((u) => u.isSameAs(user))) {
      unique.add(user);
    }
  }
}
// #endregion model-dedupe

// #region model-fresh
Future<void> freshExample(DataSource dataSource) async {
  final user = await dataSource.query<$User>().find(1);
  if (user != null) {
    user.setAttribute('name', 'Changed locally');

    // Get fresh data from database
    final fresh = await user.fresh();

    print(user.getAttribute('name')); // 'Changed locally' (original unchanged)
    print(fresh?.getAttribute('name')); // Original value from database
  }
}
// #endregion model-fresh

// #region model-refresh
Future<void> refreshExample(DataSource dataSource) async {
  final user = await dataSource.query<$User>().find(1);
  if (user != null) {
    user.setAttribute('name', 'Changed locally');

    // Discard changes and reload
    await user.refresh();

    print(user.getAttribute('name')); // Original value (changes lost)
  }
}
// #endregion model-refresh

// #region model-refresh-relations
Future<void> refreshWithRelations(DataSource dataSource) async {
  final user = await dataSource.query<$User>().find(1);
  if (user != null) {
    // Load relationships when refreshing
    final fresh = await user.fresh(withRelations: ['posts', 'comments']);
    await user.refresh(withRelations: ['posts', 'comments']);
  }
}
// #endregion model-refresh-relations

// #region model-optimistic-lock
Future<void> optimisticLockExample(DataSource dataSource) async {
  final user = await dataSource.query<$User>().find(1);
  if (user == null) return;

  final originalUpdatedAt = user.getAttribute('updatedAt');

  user.setAttribute('name', 'New Name');

  // Check for concurrent modifications
  final fresh = await user.fresh();
  if (fresh?.getAttribute('updatedAt') != originalUpdatedAt) {
    throw Exception('Record modified by another user');
  }

  await dataSource.repo<$User>().update(user);
}
// #endregion model-optimistic-lock

// #region model-dedupe-usecase
Future<void> dedupeUseCaseExample(DataSource dataSource) async {
  final users = await dataSource.query<$User>().get();
  final unique = <$User>[];

  for (final user in users) {
    if (!unique.any((u) => u.isSameAs(user))) {
      unique.add(user);
    }
  }
}
// #endregion model-dedupe-usecase

// #region model-validation-usecase
void validationUseCaseExample(User from, User to) {
  if (from.isSameAs(to)) {
    throw ArgumentError('Cannot transfer to the same account');
  }
  // Process transfer...
}
// #endregion model-validation-usecase

// #region model-soft-delete-refresh
Future<void> softDeleteRefreshExample(User user) async {
  // Include soft-deleted records
  final fresh = await user.fresh(withTrashed: true);
  await user.refresh(withTrashed: true);
}
// #endregion model-soft-delete-refresh

// #region model-exists
Future<void> existsExample(DataSource dataSource, String email) async {
  final user = $User(id: 0, email: email);
  print(user.exists); // false

  await user.save();
  print(user.exists); // true
}
// #endregion model-exists

// #region model-was-recently-created
Future<void> wasRecentlyCreatedExample(User user) async {
  await user.save();

  if (user.wasRecentlyCreated) {
    // await sendWelcomeEmail(user);
  } else {
    // await sendUpdateNotification(user);
  }
}
// #endregion model-was-recently-created

// #region model-save-upsert
Future<void> saveUpsertExample(DataSource dataSource) async {
  // Insert a new model
  final user = $User(id: 100, email: 'assigned@example.com');
  await user.save(); // Inserts

  // Update an existing model
  user.setAttribute('email', 'updated@example.com');
  await user.save(); // Updates

  // If externally deleted, save() will re-insert
  await user.save(); // Falls back to insert if 0 rows affected
}
// #endregion model-save-upsert

// #region model-touch
Future<void> touchExample(DataSource dataSource) async {
  final post = await dataSource.query<$Post>().find(1);
  if (post == null) return;

  await post.touch(); // update this model's updated_at
  await post.touchOwners(); // update touched relations
}
// #endregion model-touch

// #region model-touch-scope
Future<void> touchScopeExample(DataSource dataSource) async {
  await Model.withoutTouchingOn(<Type>[Post], () async {
    final post = await dataSource.query<$Post>().find(1);
    if (post == null) return;
    await post.save(); // skips touching related models
  });
}
// #endregion model-touch-scope

// #region model-static-helpers
Future<void> staticHelpersExample() async {
  // Assumes a default connection is configured (see DataSource docs).
  final repo = Users.repo();
  await repo.insert($User(id: 0, email: 'hi@example.com'));

  final users = await Users.query().orderBy('id').get();
  print(users.length);
}

// #endregion model-static-helpers
