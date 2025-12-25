/// Shared polymorphic photo model for SQLite integration tests.
library;

import 'package:ormed/ormed.dart';

part 'photo.orm.dart';

@OrmModel(table: 'photos')
class Photo extends Model<Photo> with ModelFactoryCapable {
  const Photo({
    required this.id,
    required this.imageableId,
    required this.imageableType,
    required this.path,
  }) : imageable = null;

  @OrmField(isPrimaryKey: true, autoIncrement: true)
  final int id;

  @OrmField(columnName: 'imageable_id')
  final int imageableId;

  @OrmField(columnName: 'imageable_type')
  final String imageableType;

  final String path;

  @OrmField(ignore: true)
  @OrmRelation(
    kind: RelationKind.morphTo,
    foreignKey: 'imageable_id',
    morphType: 'imageable_type',
  )
  final OrmEntity? imageable;
}
