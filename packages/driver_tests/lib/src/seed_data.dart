import 'dart:math';

import 'package:ormed/ormed.dart';

import '../models.dart';

final _random = Random();

List<User> buildDefaultUsers({String? suffix}) {
  suffix ??= _random
      .nextInt(1000000)
      .toString(); // Generate random suffix if not provided
  return [
    User(id: 1, email: 'alice$suffix@example.com', active: true),
    User(id: 2, email: 'bob$suffix@example.com', active: true),
    User(id: 3, email: 'carol$suffix@example.com', active: false),
  ];
}

const defaultAuthors = [
  Author(id: 1, name: 'Alice'),
  Author(id: 2, name: 'Bob'),
];

const defaultTags = [Tag(id: 1, label: 'featured'), Tag(id: 2, label: 'draft')];

const defaultPostTags = [
  PostTag(postId: 1, tagId: 1),
  PostTag(postId: 1, tagId: 2),
  PostTag(postId: 2, tagId: 2),
  PostTag(postId: 3, tagId: 1),
];

const defaultImages = [
  Image(id: 101, label: 'Landing'),
  Image(id: 102, label: 'Archive'),
];

const defaultPhotos = [
  Photo(id: 1, imageableId: 1, imageableType: 'Post', path: 'hero.jpg'),
  Photo(id: 2, imageableId: 1, imageableType: 'Post', path: 'thumb.jpg'),
  Photo(id: 3, imageableId: 3, imageableType: 'Post', path: 'header.jpg'),
  Photo(id: 4, imageableId: 101, imageableType: 'Image', path: 'cover.jpg'),
  Photo(id: 5, imageableId: 102, imageableType: 'Image', path: 'alt.jpg'),
];

final defaultComments = <Map<String, dynamic>>[
  {'id': 1, 'body': 'Visible', 'post_id': 1},
  {'id': 2, 'body': 'Hidden', 'deleted_at': DateTime.utc(2024, 4, 1)},
];

final sampleArticles = [
  Article(
    id: 1,
    title: 'Alpha Release',
    body: null,
    status: 'draft',
    rating: 4.8,
    priority: 5,
    publishedAt: DateTime.utc(2024, 1, 1),
    reviewedAt: null,
    categoryId: 1,
  ),
  Article(
    id: 2,
    title: 'Beta Update',
    body: 'Detailed beta notes',
    status: 'review',
    rating: 3.7,
    priority: 3,
    publishedAt: DateTime.utc(2024, 2, 1),
    reviewedAt: DateTime.utc(2024, 2, 1),
    categoryId: 1,
  ),
  Article(
    id: 3,
    title: 'Gamma Insights',
    body: 'Use cases',
    status: 'published',
    rating: 2.9,
    priority: 2,
    publishedAt: DateTime.utc(2024, 3, 1),
    reviewedAt: DateTime.utc(2024, 3, 5),
    categoryId: 2,
  ),
  Article(
    id: 4,
    title: 'delta case study',
    body: null,
    status: 'published',
    rating: 4.2,
    priority: 4,
    publishedAt: DateTime.utc(2024, 4, 1),
    reviewedAt: DateTime.utc(2024, 4, 10),
    categoryId: 2,
  ),
];

List<Post> buildDefaultPosts() => [
  Post(
    id: 1,
    authorId: 1,
    title: 'Welcome',
    publishedAt: DateTime.utc(2024, 1, 1, 0, 0, 0),
  ),
  Post(
    id: 2,
    authorId: 1,
    title: 'Second',
    publishedAt: DateTime.utc(2024, 2, 5, 8, 30, 0),
  ),
  Post(
    id: 3,
    authorId: 2,
    title: 'Intro',
    publishedAt: DateTime.utc(2024, 3, 12, 12, 45, 0),
  ),
];

/// Seeds the full test data graph into a DataSource.
Future<void> seedGraph(DataSource dataSource, {List<User>? users}) async {
  await dataSource.repo<User>().insertMany(
    users ?? buildDefaultUsers(),
  ); // Use provided users or generate new ones
  await dataSource.repo<Author>().insertMany(defaultAuthors.toList());
  await dataSource.repo<Post>().insertMany(buildDefaultPosts());
  await dataSource.repo<Tag>().insertMany(defaultTags.toList());
  await dataSource.repo<PostTag>().insertMany(defaultPostTags.toList());
  await dataSource.repo<Image>().insertMany(defaultImages.toList());
  await dataSource.repo<Photo>().insertMany(defaultPhotos.toList());
  await dataSource.context.query<Comment>().createMany(defaultComments);
}
