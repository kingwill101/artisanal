// Relation loading examples for documentation
// ignore_for_file: unused_local_variable

import 'package:ormed/ormed.dart';

import '../models/post.dart';
import '../models/user.dart';

// #region eager-basic
Future<void> basicEagerLoading(DataSource dataSource) async {
  // Load a single relation
  final posts = await dataSource.query<$Post>().with_(['author']).get();

  for (final post in posts) {
    print(post.author?.name); // Already loaded, no additional query
  }
}
// #endregion eager-basic

// #region eager-multiple
Future<void> multipleRelationsLoading(DataSource dataSource) async {
  final posts = await dataSource.query<$Post>().with_([
    'author',
    'tags',
    'comments',
  ]).get();
}
// #endregion eager-multiple

// #region eager-nested
Future<void> nestedRelationsLoading(DataSource dataSource) async {
  // Load author's profile along with author
  final posts = await dataSource.query<$Post>().with_(['author.profile']).get();

  // Multiple levels
  final deepPosts = await dataSource.query<$Post>().with_([
    'author.profile',
    'comments.user.profile',
  ]).get();
}
// #endregion eager-nested

// #region lazy-load
Future<void> lazyLoading(DataSource dataSource) async {
  final post = await dataSource.query<$Post>().find(1);

  if (post != null) {
    // Load after fetching
    await post.load(['author', 'tags']);

    print(post.author?.name);
  }
}
// #endregion lazy-load

// #region lazy-load-missing
Future<void> loadMissingExample(DataSource dataSource) async {
  final post = await dataSource.query<$Post>().find(1);

  if (post != null) {
    // Only loads relations that haven't been loaded yet
    await post.loadMissing(['author', 'comments']);
  }
}
// #endregion lazy-load-missing

// #region check-loaded
Future<void> checkLoadedExample(DataSource dataSource) async {
  final post = await dataSource.query<$Post>().find(1);

  if (post != null) {
    if (post.relationLoaded('author')) {
      print(post.author?.name);
    } else {
      await post.load(['author']);
    }
  }
}
// #endregion check-loaded

// #region relation-access
Future<void> relationAccessExample(DataSource dataSource) async {
  final post = await dataSource.query<$Post>().with_([
    'author',
    'comments',
  ]).first();

  if (post != null) {
    // Returns the relation value (throws if not loaded)
    final author = post.getRelation<$User>('author');

    // For has-many relations
    final comments = post.getRelationList<$Comment>('comments');

    // Manually set a relation
    // post.setRelation('author', user);

    // Unset a relation
    post.unsetRelation('author');

    // Clear all loaded relations
    post.clearRelations();
  }
}
// #endregion relation-access

// #region relation-count
Future<void> countAggregateExample(DataSource dataSource) async {
  final user = await dataSource.query<$User>().first();

  if (user != null) {
    await user.loadCount(['posts', 'comments']);
    // Access via getAttribute
    print('Posts: ${user.getAttribute<int>('posts_count')}');
    print('Comments: ${user.getAttribute<int>('comments_count')}');
  }
}
// #endregion relation-count

// #region relation-sum
Future<void> sumAggregateExample(DataSource dataSource) async {
  final user = await dataSource.query<$User>().first();

  if (user != null) {
    await user.loadSum(['posts'], 'views');
    print('Total views: ${user.getAttribute<num>('posts_views_sum')}');
  }
}
// #endregion relation-sum

// #region relation-exists
Future<void> existsAggregateExample(DataSource dataSource) async {
  final user = await dataSource.query<$User>().first();

  if (user != null) {
    await user.loadExists(['posts']);
    if (user.getAttribute<bool>('posts_exists') ?? false) {
      print('User has posts');
    }
  }
}
// #endregion relation-exists

// #region relation-attach
Future<void> attachDetachExample(DataSource dataSource) async {
  final post = await dataSource.query<$Post>().first();

  if (post != null) {
    // Attach related models to a many-to-many relationship
    await post.attach('tags', [1, 2]);

    // With pivot data
    await post.attach('tags', [3], pivot: {'added_by': 1});

    // Detach related models
    await post.detach('tags', [1]);

    // Detach all
    await post.detach('tags');
  }
}
// #endregion relation-attach

// #region relation-sync
Future<void> syncToggleExample(DataSource dataSource) async {
  final post = await dataSource.query<$Post>().first();

  if (post != null) {
    // Sync: replaces all related models with these
    await post.sync('tags', [1, 2, 3]);

    // Toggle: add if not present, remove if present
    await post.toggle('tags', [1, 2]);
  }
}
// #endregion relation-sync

// #region relation-associate
Future<void> associateExample(DataSource dataSource) async {
  final postRepo = dataSource.repo<$Post>();
  final post = await dataSource.query<$Post>().first();
  final user = await dataSource.query<$User>().first();

  if (post != null && user != null) {
    // Set a belongs-to relationship
    post.associate('author', user);
    await postRepo.update(post);

    // Remove a belongs-to relationship
    post.dissociate('author');
    await postRepo.update(post);
  }
}
// #endregion relation-associate

// #region prevent-n-plus-one
void preventNPlusOneExample() {
  // Enable lazy loading prevention in development
  // void main() {
  //   if (kDebugMode) {
  //     Model.preventLazyLoading();
  //   }
  //   runApp(MyApp());
  // }
  //
  // This throws an exception when you try to access a relation
  // that hasn't been eager-loaded, helping catch N+1 issues.
}
// #endregion prevent-n-plus-one

// #region n-plus-one-bad
Future<void> nPlusOneBadExample(DataSource dataSource) async {
  // BAD: This causes N+1 queries
  final posts = await dataSource.query<$Post>().get();

  for (final post in posts) {
    // This throws LazyLoadingException in debug mode
    // because 'author' wasn't eager-loaded
    print(post.author?.name);
  }
}
// #endregion n-plus-one-bad

// #region n-plus-one-good
Future<void> nPlusOneGoodExample(DataSource dataSource) async {
  // GOOD: Eager load author
  final posts = await dataSource
      .query<$Post>()
      .with_(['author']) // Eager load author
      .get();

  for (final post in posts) {
    print(post.author?.name); // Works!
  }
}
// #endregion n-plus-one-good

// #region relation-other-aggregates
Future<void> otherAggregatesExample(DataSource dataSource) async {
  final user = await dataSource.query<$User>().first();

  if (user != null) {
    await user.loadAvg(['posts'], 'rating');
    await user.loadMax(['posts'], 'views');
    await user.loadMin(['posts'], 'views');
  }
}

// #endregion relation-other-aggregates
