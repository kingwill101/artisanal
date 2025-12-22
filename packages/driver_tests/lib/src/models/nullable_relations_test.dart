/// Test model for nullable list relations.
library;

import 'package:ormed/ormed.dart';

import 'comment.dart';

part 'nullable_relations_test.orm.dart';

/// Test model with various relation configurations to verify
/// code generation handles all cases correctly.
@OrmModel(table: 'nullable_relations_test')
class NullableRelationsTest extends Model<NullableRelationsTest>
    with ModelFactoryCapable {
  const NullableRelationsTest({required this.id, required this.name})
    : nullableFieldComments = null,
      nonNullableFieldComments = const [];

  @OrmField(isPrimaryKey: true, autoIncrement: true)
  final int id;

  final String name;

  /// A relation with nullable field type in base class.
  /// Generated override should return `List<Comment>` (non-nullable)
  /// and use `super.nullableFieldComments ?? const []` to coalesce.
  @OrmField(ignore: true)
  @OrmRelation(
    kind: RelationKind.hasMany,
    target: Comment,
    foreignKey: 'parent_id',
    localKey: 'id',
  )
  final List<Comment>? nullableFieldComments;

  /// A relation with non-nullable field type in base class.
  /// Generated override should return `List<Comment>` (non-nullable)
  /// and use `super.nonNullableFieldComments` directly (no coalescing needed).
  @OrmField(ignore: true)
  @OrmRelation(
    kind: RelationKind.hasMany,
    target: Comment,
    foreignKey: 'other_parent_id',
    localKey: 'id',
  )
  final List<Comment> nonNullableFieldComments;
}
