import 'package:ormed/ormed.dart';

enum TestStatus { active, inactive }

@OrmModel()
class DefaultValueModel extends Model<DefaultValueModel> {
  const DefaultValueModel({
    required this.id,
    this.status = TestStatus.active,
    this.metadata = const {},
    this.tags = const [],
  });

  @OrmField(isPrimaryKey: true)
  final String id;

  @OrmField(defaultValueSql: "'active'")
  final TestStatus status;

  @OrmField(columnType: 'jsonb', defaultValueSql: "'{}'::jsonb")
  final Map<String, String> metadata;

  @OrmField(columnType: 'jsonb', defaultValueSql: "'[]'::jsonb")
  final List<String> tags;
}

@OrmModel()
class RelationModel extends Model<RelationModel> {
  const RelationModel({required this.id, this.owner});

  @OrmField(isPrimaryKey: true)
  final String id;

  @OrmRelation.belongsTo(
    target: Owner,
    foreignKey: 'owner_id',
    localKey: 'id',
  )
  final Owner? owner;
}

@OrmModel()
class Owner extends Model<Owner> {
  const Owner({required this.id});

  @OrmField(isPrimaryKey: true)
  final String id;
}
