/// Shared soft delete comment model for driver tests.
library;

import 'package:ormed/ormed.dart';

import 'post.dart';

part 'comment.orm.dart';

@OrmModel(table: 'comments')
class Comment extends Model<Comment> with ModelFactoryCapable, SoftDeletes {
  const Comment({required this.id, required this.body, this.postId})
    : post = null;

  @OrmField(isPrimaryKey: true, autoIncrement: true)
  final int id;

  final String body;

  @OrmField(columnName: 'post_id')
  final int? postId;

  @OrmField(ignore: true)
  @OrmRelation(
    kind: RelationKind.belongsTo,
    target: Post,
    foreignKey: 'post_id',
    localKey: 'id',
  )
  final Post? post;
}
