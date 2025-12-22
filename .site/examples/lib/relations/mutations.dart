// Relation mutation examples for documentation
// ignore_for_file: unused_local_variable

import 'package:ormed/ormed.dart';

import '../models/relations/has_many.dart';

// #region create-relation-basic
Future<void> createRelationBasic(DataSource dataSource) async {
  final user = await dataSource.query<$UserWithPosts>().first();

  if (user != null) {
    // Create a related post using a map
    final post = await user.createRelation<$UserPost>('posts', {
      'title': 'My First Post',
    });

    print(post.authorId); // Automatically set to user.id
  }
}
// #endregion create-relation-basic

// #region create-relation-dto
Future<void> createRelationWithDto(DataSource dataSource) async {
  final user = await dataSource.query<$UserWithPosts>().first();

  if (user != null) {
    // Create using InsertDto - type-safe, only insert fields
    final post = await user.createRelation<$UserPost>(
      'posts',
      UserPostInsertDto(title: 'DTO Post'),
    );

    // Create using UpdateDto - includes id if needed
    final anotherPost = await user.createRelation<$UserPost>(
      'posts',
      UserPostUpdateDto(title: 'UpdateDto Post'),
    );

    print('Created: ${post.title}, ${anotherPost.title}');
  }
}
// #endregion create-relation-dto

// #region create-many-relation
Future<void> createManyRelation(DataSource dataSource) async {
  final user = await dataSource.query<$UserWithPosts>().first();

  if (user != null) {
    // Create multiple related posts at once
    final posts = await user.createManyRelation<$UserPost>('posts', [
      {'title': 'First Post'},
      {'title': 'Second Post'},
      {'title': 'Third Post'},
    ]);

    print('Created ${posts.length} posts'); // 3
    print(posts.every((p) => p.authorId == user.id)); // true
  }
}
// #endregion create-many-relation

// #region create-many-relation-mixed
Future<void> createManyRelationMixed(DataSource dataSource) async {
  final user = await dataSource.query<$UserWithPosts>().first();

  if (user != null) {
    // Mix different input types in the same call
    final posts = await user.createManyRelation<$UserPost>('posts', [
      // Map
      {'title': 'Map Post'},
      // InsertDto
      UserPostInsertDto(title: 'InsertDto Post'),
      // UpdateDto
      UserPostUpdateDto(title: 'UpdateDto Post'),
    ]);

    for (final post in posts) {
      print('${post.title} - author: ${post.authorId}');
    }
  }
}
// #endregion create-many-relation-mixed

// #region create-quietly-relation
Future<void> createQuietlyRelation(DataSource dataSource) async {
  final user = await dataSource.query<$UserWithPosts>().first();

  if (user != null) {
    // Create without triggering model events (creating/created/saving/saved)
    final post = await user.createQuietlyRelation<$UserPost>('posts', {
      'title': 'Silent Post',
    });

    // Works with DTOs too
    final dtoPost = await user.createQuietlyRelation<$UserPost>(
      'posts',
      UserPostInsertDto(title: 'Silent DTO Post'),
    );

    print('Quietly created: ${post.title}, ${dtoPost.title}');
  }
}
// #endregion create-quietly-relation

// #region create-many-quietly-relation
Future<void> createManyQuietlyRelation(DataSource dataSource) async {
  final user = await dataSource.query<$UserWithPosts>().first();

  if (user != null) {
    // Create multiple without events
    final posts = await user.createManyQuietlyRelation<$UserPost>('posts', [
      {'title': 'Quiet Post 1'},
      UserPostInsertDto(title: 'Quiet Post 2'),
      UserPostUpdateDto(title: 'Quiet Post 3'),
    ]);

    print('Quietly created ${posts.length} posts');
  }
}
// #endregion create-many-quietly-relation

// #region without-events-query
Future<void> withoutEventsQuery(DataSource dataSource) async {
  // Suppress events for any query operation
  final query = dataSource.query<$UserPost>().withoutEvents();

  // Insert without events
  final post = await query.insertReturning({
    'author_id': 1,
    'title': 'No Events',
  });

  // Update without events
  await dataSource
      .query<$UserPost>()
      .withoutEvents()
      .whereEquals('id', post.id)
      .update({'title': 'Updated Silently'});

  // Delete without events
  await dataSource
      .query<$UserPost>()
      .withoutEvents()
      .whereEquals('id', post.id)
      .delete();
}
// #endregion without-events-query

// #region without-events-use-case
Future<void> withoutEventsUseCase(DataSource dataSource) async {
  // Use case: Bulk import where you want to skip audit logging
  final importedPosts = <Map<String, Object?>>[];
  for (var i = 0; i < 1000; i++) {
    importedPosts.add({'author_id': 1, 'title': 'Import $i'});
  }

  // Skip events for performance during bulk operations
  await dataSource.query<$UserPost>().withoutEvents().insertMany(importedPosts);

  // Use case: Seeding test data without triggering side effects
  await dataSource.query<$UserWithPosts>().withoutEvents().insertReturning({
    'id': 999,
  });
}
// #endregion without-events-use-case

// #region relation-mutations-summary
Future<void> relationMutationsSummary(DataSource dataSource) async {
  final user = await dataSource.query<$UserWithPosts>().first();
  if (user == null) return;

  // All relation mutation methods accept these input types:
  // - Map<String, Object?> (column names)
  // - InsertDto<T> (type-safe insert fields)
  // - UpdateDto<T> (type-safe update fields)

  // Single creation
  await user.createRelation<$UserPost>('posts', {'title': 'Map'});
  await user.createRelation<$UserPost>('posts', UserPostInsertDto(title: 'DTO'));

  // Batch creation
  await user.createManyRelation<$UserPost>('posts', [
    {'title': 'Post 1'},
    UserPostInsertDto(title: 'Post 2'),
  ]);

  // Event-suppressed variants
  await user.createQuietlyRelation<$UserPost>('posts', {'title': 'Quiet'});
  await user.createManyQuietlyRelation<$UserPost>('posts', [
    {'title': 'Quiet 1'},
    UserPostInsertDto(title: 'Quiet 2'),
  ]);
}
// #endregion relation-mutations-summary
