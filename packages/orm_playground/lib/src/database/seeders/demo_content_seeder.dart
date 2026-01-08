import 'package:orm_playground/orm_playground.dart';
import 'package:ormed/ormed.dart';

import '../../factories/playground_factories.dart';

/// Seeds the sample user/post/tag/comment relationships the playground expects.
class DemoContentSeeder extends DatabaseSeeder {
  DemoContentSeeder(super.connection);

  @override
  Future<void> run() async {
    final admin = await _ensureUser(
      factory: adminUserFactory(),
      email: 'playground@routed.dev',
    );
    final guest = await _ensureUser(
      factory: guestUserFactory(),
      email: 'guest@routed.dev',
    );
    final tags = await _ensureTags();
    await _ensurePosts(connection, [admin, guest], tags);
  }

  Future<User> _ensureUser({
    required ModelFactoryBuilder<User> factory,
    required String email,
  }) async {
    final existing = await connection
        .query<User>()
        .whereEquals('email', email)
        .firstOrNull();
    if (existing != null) return existing;

    final now = DateTime.now().toUtc();
    final user = factory.withOverrides({
      'email': email,
      'createdAt': now,
      'updatedAt': now,
    }).make();
    await connection.repository<User>().insert(user);
    return (await connection
        .query<User>()
        .whereEquals('email', email)
        .firstOrFail());
  }

  Future<List<Tag>> _ensureTags() async {
    final existing = await connection.query<Tag>().orderBy('id').get();
    final desired = <String>{'dart', 'orm', 'sqlite', 'playground', 'demo'};
    for (final tag in existing) {
      desired.remove(tag.name);
    }
    if (desired.isEmpty) return existing;

    final now = DateTime.now().toUtc();
    for (final name in desired) {
      final tag = Tag(name: name, createdAt: now, updatedAt: now);
      await connection.repository<Tag>().insert(tag);
    }
    return connection.query<Tag>().orderBy('name').get();
  }

  Future<void> _ensurePosts(
    OrmConnection connection,
    List<User> authors,
    List<Tag> tags,
  ) async {
    final existingPosts = await connection.query<Post>().orderBy('id').get();
    if (existingPosts.length >= 3) return;

    final now = DateTime.now().toUtc();
    final authorCycle = authors.isEmpty ? [authors.first] : authors;
    final newPosts = <Post>[
      Post(
        userId: authorCycle.first.id!,
        title: 'Query Builder Tour',
        body: 'Chaining whereHas, withCount, and paginate.',
        published: true,
        publishedAt: now.subtract(const Duration(days: 2)),
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(days: 1, hours: 4)),
      ),
      Post(
        userId: authorCycle.last.id!,
        title: 'Seeder Orchestration',
        body: 'Demonstrating Seeder.call([]) with pretend mode.',
        published: true,
        publishedAt: now.subtract(const Duration(days: 1)),
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now,
      ),
    ];

    await connection.repository<Post>().insertMany(newPosts);
    final inserted = await connection.query<Post>().orderBy('id').get();
    final newlyInserted = inserted
        .where((post) => existingPosts.every((p) => p.id != post.id))
        .toList();
    if (newlyInserted.isEmpty) return;

    final pivotRows = <PostTag>[];
    final comments = <Comment>[];
    for (final post in newlyInserted) {
      final sampleTags = tags.take(3).toList();
      for (final tag in sampleTags) {
        pivotRows.add(PostTag(postId: post.id!, tagId: tag.id!));
      }
      comments.add(
        Comment(
          postId: post.id!,
          userId: authors.first.id,
          body: 'Loving ${post.title.toLowerCase()}!',
          createdAt: now,
          updatedAt: now,
        ),
      );
      comments.add(
        Comment(
          postId: post.id!,
          userId: authors.last.id,
          body: 'Can we chunk these rows next?',
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
    if (pivotRows.isNotEmpty) {
      await connection.repository<PostTag>().insertMany(pivotRows);
    }
    if (comments.isNotEmpty) {
      await connection.repository<Comment>().insertMany(comments);
    }
  }
}
