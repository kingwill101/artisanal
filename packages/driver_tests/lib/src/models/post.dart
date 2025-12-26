/// Test post model referencing authors.
library;

import 'package:ormed/ormed.dart';

import 'author.dart';
import 'comment.dart';
import 'tag.dart';
import 'photo.dart';

part 'post.orm.dart';

@OrmModel(table: 'posts')
class Post extends Model<Post> with ModelFactoryCapable, TimestampsTZ {
  const Post({
    required this.id,
    required this.authorId,
    required this.title,
    required this.publishedAt,
    this.content,
    this.views,
  }) : author = null,
       tags = const [],
       morphTags = const [],
       photos = const [],
       comments = const [];

  @OrmField(isPrimaryKey: true, autoIncrement: true)
  final int id;

  @OrmField(columnName: 'author_id')
  final int authorId;

  final String title;

  final String? content;

  final int? views;

  @OrmField(columnName: 'published_at')
  final DateTime publishedAt;

  @OrmField(ignore: true)
  @OrmRelation(
    kind: RelationKind.belongsTo,
    target: Author,
    foreignKey: 'author_id',
    localKey: 'id',
  )
  final Author? author;

  @OrmField(ignore: true)
  @OrmRelation(
    kind: RelationKind.manyToMany,
    target: Tag,
    through: 'post_tags',
    pivotForeignKey: 'post_id',
    pivotRelatedKey: 'tag_id',
    withPivot: ['sort_order', 'note'],
  )
  final List<Tag> tags;

  @OrmField(ignore: true)
  @OrmRelation(
    kind: RelationKind.morphToMany,
    target: Tag,
    through: 'taggables',
    pivotForeignKey: 'taggable_id',
    pivotRelatedKey: 'tag_id',
    morphType: 'taggable_type',
    morphClass: 'Post',
  )
  final List<Tag> morphTags;

  @OrmField(ignore: true)
  @OrmRelation(
    kind: RelationKind.morphMany,
    target: Photo,
    foreignKey: 'imageable_id',
    morphType: 'imageable_type',
    morphClass: 'Post',
  )
  final List<Photo> photos;

  @OrmField(ignore: true)
  @OrmRelation(
    kind: RelationKind.hasMany,
    target: Comment,
    foreignKey: 'post_id',
    localKey: 'id',
  )
  final List<Comment> comments;

  // Demo model-level event handler
  @OrmEvent(ModelCreatedEvent)
  static void onCreated(ModelCreatedEvent event) {
    if (event.model is! Post) return;
    // no-op: just proves registration works
  }
}
