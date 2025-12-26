// Has Many Through relationship example
import 'package:ormed/ormed.dart';

part 'has_many_through.orm.dart';

// #region relation-has-many-through
@OrmModel(table: 'authors')
class AuthorWithComments extends Model<AuthorWithComments> {
  const AuthorWithComments({required this.id, this.comments});

  @OrmField(isPrimaryKey: true)
  final int id;

  @OrmRelation.hasManyThrough(
    target: PostComment,
    throughModel: AuthorPost,
    foreignKey: 'post_id',
    throughForeignKey: 'author_id',
    localKey: 'id',
  )
  final List<PostComment>? comments;
}
// #endregion relation-has-many-through

@OrmModel(table: 'posts')
class AuthorPost extends Model<AuthorPost> {
  const AuthorPost({required this.id, required this.authorId});

  @OrmField(isPrimaryKey: true)
  final int id;

  @OrmField(columnName: 'author_id')
  final int authorId;
}

@OrmModel(table: 'comments')
class PostComment extends Model<PostComment> {
  const PostComment({required this.id, required this.postId, required this.body});

  @OrmField(isPrimaryKey: true)
  final int id;

  @OrmField(columnName: 'post_id')
  final int postId;
  final String body;
}
