// Belongs To Many relationship example
import 'package:ormed/ormed.dart';

part 'belongs_to_many.orm.dart';

// #region relation-belongs-to-many
@OrmModel(table: 'posts')
// #region relation-belongs-to-many-post
class PostWithTags extends Model<PostWithTags> {
  const PostWithTags({required this.id, this.tags});

  @OrmField(isPrimaryKey: true)
  final int id;

// #region relation-belongs-to-many-pivot
  @OrmRelation.belongsToMany(
    Tag,
    pivotTable: 'post_tags',
    foreignKey: 'post_id',
    relatedKey: 'tag_id',
    withPivot: ['sort_order', 'note'],
  )
  final List<Tag>? tags;
// #endregion relation-belongs-to-many-pivot
}
// #endregion relation-belongs-to-many-post

@OrmModel(table: 'tags')
// #region relation-belongs-to-many-tag
class Tag extends Model<Tag> {
  const Tag({required this.id, required this.name});

  @OrmField(isPrimaryKey: true)
  final int id;

  final String name;
}

// #endregion relation-belongs-to-many-tag
// #endregion relation-belongs-to-many
