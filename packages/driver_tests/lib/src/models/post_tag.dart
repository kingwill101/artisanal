import 'package:ormed/ormed.dart';

part 'post_tag.orm.dart';

@OrmModel(
  table: 'post_tags',
  primaryKey: ['postId', 'tagId'], // Use the new primaryKey parameter
)
class PostTag extends Model<PostTag> with ModelFactoryCapable {
  const PostTag({
    required this.postId,
    required this.tagId,
    this.sortOrder,
    this.note,
  });

  @OrmField(columnName: 'post_id') // Remove isPrimaryKey: true
  final int postId;

  @OrmField(columnName: 'tag_id')
  final int tagId;

  @OrmField(columnName: 'sort_order')
  final int? sortOrder;

  final String? note;
}
