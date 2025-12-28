// Repository examples for documentation
// ignore_for_file: unused_local_variable

import 'package:ormed/ormed.dart';

import 'models/user.dart';
import 'models/user.orm.dart';

// #region repo-get
Future<void> getRepositoryExample(DataSource dataSource) async {
  final userRepo = dataSource.repo<$User>();
}
// #endregion repo-get

// #region repo-get-static
Future<void> getRepositoryStaticHelpers() async {
  // Assumes a default connection is configured (see DataSource docs).
  final userRepo = Users.repo();
  await userRepo.find(1);
}
// #endregion repo-get-static

// #region repo-insert
Future<void> insertExamples(DataSource dataSource) async {
  final userRepo = dataSource.repo<$User>();

  // With tracked model
  final user = await userRepo.insert(
    $User(id: 0, email: 'john@example.com', name: 'John'),
  );

  // With insert DTO
  final user2 = await userRepo.insert(
    UserInsertDto(email: 'john@example.com', name: 'John'),
  );

  // With raw map
  final user3 = await userRepo.insert({
    'email': 'john@example.com',
    'name': 'John',
  });
}
// #endregion repo-insert

// #region repo-insert-many
Future<void> insertManyExample(DataSource dataSource) async {
  final userRepo = dataSource.repo<$User>();

  final users = await userRepo.insertMany([
    $User(id: 0, email: 'user1@example.com'),
    $User(id: 0, email: 'user2@example.com'),
  ]);
}
// #endregion repo-insert-many

// #region repo-upsert
Future<void> upsertExample(DataSource dataSource) async {
  final userRepo = dataSource.repo<$User>();

  // Insert if not exists, update if exists
  final user = await userRepo.upsert(
    $User(id: 1, email: 'john@example.com', name: 'Updated Name'),
  );
}
// #endregion repo-upsert

// #region repo-find
Future<void> findExamples(DataSource dataSource) async {
  final userRepo = dataSource.repo<$User>();

  final user = await userRepo.find(1); // Returns null if not found
  final user2 = await userRepo.findOrFail(1); // Throws if not found
  final users = await userRepo.findMany([1, 2, 3]);
}
// #endregion repo-find

// #region repo-first-count
Future<void> firstCountExamples(DataSource dataSource) async {
  final userRepo = dataSource.repo<$User>();

  final user = await userRepo.first();
  final user2 = await userRepo.first(where: {'active': true});

  final count = await userRepo.count();
  final activeCount = await userRepo.count(where: {'active': true});

  final hasActive = await userRepo.exists({'active': true});
}
// #endregion repo-first-count

// #region repo-update
Future<void> updateExamples(DataSource dataSource) async {
  final userRepo = dataSource.repo<$User>();
  final user = await userRepo.find(1);

  // With tracked model (uses primary key)
  if (user != null) {
    user.setAttribute('name', 'Updated Name');
    final updated = await userRepo.update(user);
  }

  // With DTO and where clause
  final updated2 = await userRepo.update(
    UserUpdateDto(name: 'Updated Name'),
    where: {'id': 1},
  );

  // With Query callback
  final updated3 = await userRepo.update(
    UserUpdateDto(name: 'Updated Name'),
    where: (Query<$User> q) => q.whereEquals('email', 'john@example.com'),
  );
}
// #endregion repo-update

// #region repo-update-many
Future<void> updateManyExample(DataSource dataSource) async {
  final userRepo = dataSource.repo<$User>();

  final updated = await userRepo.updateMany([
    $User(id: 1, email: 'user1@example.com', name: 'Name 1'),
    $User(id: 2, email: 'user2@example.com', name: 'Name 2'),
  ]);
}
// #endregion repo-update-many

// #region repo-where-types
Future<void> whereTypesExamples(DataSource dataSource) async {
  final userRepo = dataSource.repo<$User>();

  // Map
  await userRepo.update(UserUpdateDto(name: 'Test'), where: {'id': 1});

  // Partial entity
  await userRepo.update(
    UserUpdateDto(name: 'Test'),
    where: $UserPartial(id: 1),
  );

  // DTO
  await userRepo.update(
    UserUpdateDto(name: 'Test'),
    where: UserUpdateDto(email: 'john@example.com'),
  );

  // Query callback (must type the parameter!)
  await userRepo.update(
    UserUpdateDto(name: 'Test'),
    where: (Query<$User> q) => q.whereEquals('email', 'test@example.com'),
  );
}
// #endregion repo-where-types

// #region repo-where-typed
Future<void> whereTypedCallbackExample(DataSource dataSource) async {
  final userRepo = dataSource.repo<$User>();

  await userRepo.update(
    UserUpdateDto(name: 'Test'),
    where: (Query<$User> q) =>
        q.whereTyped((p) => p.email.eq('test@example.com')),
  );
}
// #endregion repo-where-typed

// #region repo-where-typing-caution
// ✅ Preferred - typed parameter enables typed predicate fields
// where: (Query<$User> q) => q.whereTyped((p) => p.email.eq('test@example.com'))
//
// ✅ Works, but `q` is dynamic (less static checking)
// where: (q) => q.whereTyped((p) => p.email.eq('test@example.com'))
// #endregion repo-where-typing-caution

// #region repo-delete
Future<void> deleteExamples(DataSource dataSource) async {
  final userRepo = dataSource.repo<$User>();
  final user = await userRepo.find(1);

  // By primary key
  await userRepo.delete(1);

  // By tracked model
  if (user != null) {
    await userRepo.delete(user);
  }

  // By where clause
  await userRepo.delete({'email': 'john@example.com'});

  // By Query callback
  await userRepo.delete((Query<$User> q) => q.whereEquals('role', 'guest'));
}
// #endregion repo-delete

// #region repo-delete-many
Future<void> deleteManyExamples(DataSource dataSource) async {
  final userRepo = dataSource.repo<$User>();

  await userRepo.deleteByIds([1, 2, 3]);

  await userRepo.deleteMany([
    {'id': 1},
    (Query<$User> q) => q.whereEquals('role', 'guest'),
  ]);
}
// #endregion repo-delete-many

// #region repo-soft-delete
Future<void> softDeleteExamples(DataSource dataSource) async {
  final userRepo = dataSource.repo<$User>();
  final user = await userRepo.find(1);

  if (user != null) {
    // Soft delete (sets deleted_at)
    await userRepo.delete(user);

    // Restore
    await userRepo.restore(user);
    await userRepo.restore({'id': 1});

    // Force delete (permanently removes)
    await userRepo.forceDelete(user);
  }
}
// #endregion repo-soft-delete

// #region repo-relations
Future<void> relationExamples(DataSource dataSource) async {
  final userRepo = dataSource.repo<$User>();
  final user = await userRepo.find(1);

  if (user != null) {
    // Load relations
    await user.load(['posts', 'profile']);
  }
}
// #endregion repo-relations

// #region repo-errors
Future<void> errorHandlingExample(DataSource dataSource) async {
  final userRepo = dataSource.repo<$User>();

  try {
    final user = await userRepo.findOrFail(999);
  } on ModelNotFoundException catch (e) {
    print('User not found: ${e.key}');
  }

  try {
    await userRepo.update(UserUpdateDto(name: 'Test'), where: {'id': 999});
  } on NoRowsAffectedException {
    print('No rows were updated');
  }
}

// #endregion repo-errors
