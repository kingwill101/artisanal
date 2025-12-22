// Has Many relationship example
import 'package:ormed/ormed.dart';

part 'has_many.orm.dart';

// #region relation-has-many
@OrmModel(table: 'users')
class UserWithPosts extends Model<UserWithPosts> {
  const UserWithPosts({required this.id, this.posts});

  @OrmField(isPrimaryKey: true)
  final int id;

  @OrmRelation.hasMany(target: UserPost, foreignKey: 'author_id')
  final List<UserPost>? posts;
}

@OrmModel(table: 'posts')
class UserPost extends Model<UserPost> {
  const UserPost({
    required this.id,
    required this.authorId,
    required this.title,
  });

  @OrmField(isPrimaryKey: true)
  final int id;

  final int authorId;
  final String title;
}
// #endregion relation-has-many
