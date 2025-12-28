import 'package:test/test.dart';

import '../models/models.dart';

void runModelCopyWithTests() {
  group('Model copyWith', () {
    test('nullable fields can be explicitly nulled', () {
      final post = Post(
        id: 1,
        authorId: 10,
        title: 'Hello',
        publishedAt: DateTime(2024),
        content: 'body',
      );

      final updated = post.copyWith(content: null);

      expect(updated.content, isNull);
      expect(updated.title, equals('Hello'));
    });

    test('relation fields in constructor can be replaced', () {
      final originalPosts = [
        Post(
          id: 1,
          authorId: 42,
          title: 'First',
          publishedAt: DateTime(2024),
        ),
      ];
      final author = Author(
        id: 42,
        name: 'Alice',
        posts: originalPosts,
        comments: const [],
      );

      final newPosts = [
        Post(
          id: 2,
          authorId: 42,
          title: 'Second',
          publishedAt: DateTime(2024, 2),
        ),
      ];

      final updated = author.copyWith(posts: newPosts);

      expect(updated.runtimeType, equals(Author));
      expect(updated.posts, same(newPosts));
      expect(updated.name, equals('Alice'));
    });
  });
}
