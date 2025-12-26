/// Test author model for driver integration.
library;

import 'package:ormed/ormed.dart';

import 'comment.dart';
import 'post.dart';

part 'author.orm.dart';

@OrmModel(table: 'authors')
class Author extends Model<Author> with ModelFactoryCapable, Timestamps {
  const Author({
    required this.id,
    required this.name,
    this.active = false,
    this.posts = const [],
    this.comments = const [],
  });

  @OrmField(isPrimaryKey: true, autoIncrement: true)
  final int id;

  final String name;

  final bool active;

  @OrmField(ignore: true)
  @OrmRelation(
    kind: RelationKind.hasMany,
    target: Post,
    foreignKey: 'author_id',
    localKey: 'id',
  )
  final List<Post> posts;

  @OrmField(ignore: true)
  @OrmRelation(
    kind: RelationKind.hasManyThrough,
    target: Comment,
    throughModel: Post,
    foreignKey: 'post_id',
    throughForeignKey: 'author_id',
    localKey: 'id',
  )
  final List<Comment> comments;
}
