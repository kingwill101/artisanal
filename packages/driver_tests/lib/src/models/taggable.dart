/// SQLite test taggable pivot model.
library;

import 'package:ormed/ormed.dart';

part 'taggable.orm.dart';

@OrmModel(
  table: 'taggables',
  primaryKey: ['tagId', 'taggableId', 'taggableType'],
)
class Taggable extends Model<Taggable> with ModelFactoryCapable {
  const Taggable({
    required this.tagId,
    required this.taggableId,
    required this.taggableType,
  });

  @OrmField(columnName: 'tag_id')
  final int tagId;

  @OrmField(columnName: 'taggable_id')
  final int taggableId;

  @OrmField(columnName: 'taggable_type')
  final String taggableType;
}
