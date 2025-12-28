/// Model used to verify predicate-field name collisions.
library;

import 'package:ormed/ormed.dart';

part 'predicate_collision.orm.dart';

@OrmModel(table: 'predicate_collisions')
class PredicateCollision extends Model<PredicateCollision>
    with ModelFactoryCapable {
  const PredicateCollision({
    required this.id,
    required this.where,
    required this.orWhere,
  });

  @OrmField(isPrimaryKey: true, autoIncrement: true)
  final int id;

  final String where;

  final String orWhere;
}
