/// SQLite test tag model.
library;

import 'package:ormed/ormed.dart';

import 'post.dart';

part 'tag.orm.dart';

@OrmModel(table: 'tags', touches: ['posts'])
class Tag extends Model<Tag> with ModelFactoryCapable, Timestamps {
  const Tag({required this.id, required this.label})
    : posts = const [],
      morphedPosts = const [];

  @OrmField(isPrimaryKey: true, autoIncrement: true)
  final int id;

  final String label;

  @OrmField(ignore: true)
  @OrmRelation(
    kind: RelationKind.manyToMany,
    target: Post,
    through: 'post_tags',
    pivotForeignKey: 'tag_id',
    pivotRelatedKey: 'post_id',
  )
  final List<Post> posts;

  @OrmField(ignore: true)
  @OrmRelation(
    kind: RelationKind.morphedByMany,
    target: Post,
    through: 'taggables',
    pivotForeignKey: 'tag_id',
    pivotRelatedKey: 'taggable_id',
    morphType: 'taggable_type',
    morphClass: 'Post',
  )
  final List<Post> morphedPosts;
}
