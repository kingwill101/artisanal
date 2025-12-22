// Belongs To relationship example
import 'package:ormed/ormed.dart';

part 'belongs_to.orm.dart';

// #region relation-belongs-to
@OrmModel(table: 'posts')
// #region relation-belongs-to-post
class PostWithAuthor extends Model<PostWithAuthor> {
  const PostWithAuthor({
    required this.id,
    required this.authorId,
    required this.title,
    this.author,
  });

  @OrmField(isPrimaryKey: true)
  final int id;

  final int authorId;
  final String title;

  @OrmRelation.belongsTo(target: PostAuthor, foreignKey: 'author_id')
  final PostAuthor? author;
}
// #endregion relation-belongs-to-post

@OrmModel(table: 'users')
// #region relation-belongs-to-author
class PostAuthor extends Model<PostAuthor> {
  const PostAuthor({required this.id, required this.name});

  @OrmField(isPrimaryKey: true)
  final int id;

  final String name;
}

// #endregion relation-belongs-to-author
// #endregion relation-belongs-to
