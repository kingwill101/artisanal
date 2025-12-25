// Polymorphic relationship examples
import 'package:ormed/ormed.dart';

part 'polymorphic.orm.dart';

// #region relation-morph-one
@OrmModel(table: 'users')
class MorphUser extends Model<MorphUser> {
  const MorphUser({required this.id, this.avatar});

  @OrmField(isPrimaryKey: true)
  final int id;

  @OrmField(ignore: true)
  @OrmRelation.morphOne(
    target: MorphPhoto,
    foreignKey: 'imageable_id',
    morphType: 'imageable_type',
    morphClass: 'User',
  )
  final MorphPhoto? avatar;
}
// #endregion relation-morph-one

// #region relation-morph-many
@OrmModel(table: 'posts')
class MorphPostPhotos extends Model<MorphPostPhotos> {
  const MorphPostPhotos({required this.id, this.photos = const []});

  @OrmField(isPrimaryKey: true)
  final int id;

  @OrmField(ignore: true)
  @OrmRelation.morphMany(
    target: MorphPhoto,
    foreignKey: 'imageable_id',
    morphType: 'imageable_type',
    morphClass: 'Post',
  )
  final List<MorphPhoto> photos;
}
// #endregion relation-morph-many

// #region relation-morph-to
@OrmModel(table: 'photos')
class MorphPhoto extends Model<MorphPhoto> {
  const MorphPhoto({
    required this.id,
    this.imageableId,
    this.imageableType,
    this.imageable,
  });

  @OrmField(isPrimaryKey: true)
  final int id;

  @OrmField(columnName: 'imageable_id')
  final int? imageableId;

  @OrmField(columnName: 'imageable_type')
  final String? imageableType;

  @OrmField(ignore: true)
  @OrmRelation.morphTo(
    foreignKey: 'imageable_id',
    morphType: 'imageable_type',
  )
  final OrmEntity? imageable;
}
// #endregion relation-morph-to

// #region relation-morph-to-many
@OrmModel(table: 'posts')
class MorphPostTags extends Model<MorphPostTags> {
  const MorphPostTags({required this.id, this.tags = const []});

  @OrmField(isPrimaryKey: true)
  final int id;

  @OrmField(ignore: true)
  @OrmRelation.morphToMany(
    target: MorphTag,
    through: 'taggables',
    pivotForeignKey: 'taggable_id',
    pivotRelatedKey: 'tag_id',
    morphType: 'taggable_type',
    morphClass: 'Post',
  )
  final List<MorphTag> tags;
}
// #endregion relation-morph-to-many

// #region relation-morphed-by-many
@OrmModel(table: 'tags')
class MorphTag extends Model<MorphTag> {
  const MorphTag({required this.id, this.posts = const []});

  @OrmField(isPrimaryKey: true)
  final int id;

  @OrmField(ignore: true)
  @OrmRelation.morphedByMany(
    target: MorphPostTags,
    through: 'taggables',
    pivotForeignKey: 'tag_id',
    pivotRelatedKey: 'taggable_id',
    morphType: 'taggable_type',
    morphClass: 'Post',
  )
  final List<MorphPostTags> posts;
}
// #endregion relation-morphed-by-many
