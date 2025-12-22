// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'tag.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$TagIdField = FieldDefinition(
  name: 'id',
  columnName: 'id',
  dartType: 'int',
  resolvedType: 'int',
  isPrimaryKey: true,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: true,
);

const FieldDefinition _$TagLabelField = FieldDefinition(
  name: 'label',
  columnName: 'label',
  dartType: 'String',
  resolvedType: 'String',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const RelationDefinition _$TagPostsRelation = RelationDefinition(
  name: 'posts',
  kind: RelationKind.manyToMany,
  targetModel: 'Post',
  through: 'post_tags',
  pivotForeignKey: 'tag_id',
  pivotRelatedKey: 'post_id',
);

Map<String, Object?> _encodeTagUntracked(
  Object model,
  ValueCodecRegistry registry,
) {
  final m = model as Tag;
  return <String, Object?>{
    'id': registry.encodeField(_$TagIdField, m.id),
    'label': registry.encodeField(_$TagLabelField, m.label),
  };
}

final ModelDefinition<$Tag> _$TagDefinition = ModelDefinition(
  modelName: 'Tag',
  tableName: 'tags',
  fields: const [_$TagIdField, _$TagLabelField],
  relations: const [_$TagPostsRelation],
  softDeleteColumn: 'deleted_at',
  metadata: ModelAttributesMetadata(
    hidden: const <String>[],
    visible: const <String>[],
    fillable: const <String>[],
    guarded: const <String>[],
    casts: const <String, String>{},
    softDeletes: false,
    softDeleteColumn: 'deleted_at',
  ),
  untrackedToMap: _encodeTagUntracked,
  codec: _$TagCodec(),
);

// ignore: unused_element
final tagModelDefinitionRegistration = ModelFactoryRegistry.register<$Tag>(
  _$TagDefinition,
);

extension TagOrmDefinition on Tag {
  static ModelDefinition<$Tag> get definition => _$TagDefinition;
}

class Tags {
  const Tags._();

  /// Starts building a query for [$Tag].
  ///
  /// {@macro ormed.query}
  static Query<$Tag> query([String? connection]) =>
      Model.query<$Tag>(connection: connection);

  static Future<$Tag?> find(Object id, {String? connection}) =>
      Model.find<$Tag>(id, connection: connection);

  static Future<$Tag> findOrFail(Object id, {String? connection}) =>
      Model.findOrFail<$Tag>(id, connection: connection);

  static Future<List<$Tag>> all({String? connection}) =>
      Model.all<$Tag>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<$Tag>(connection: connection);

  static Future<bool> anyExist({String? connection}) =>
      Model.anyExist<$Tag>(connection: connection);

  static Query<$Tag> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) => Model.where<$Tag>(column, operator, value, connection: connection);

  static Query<$Tag> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<$Tag>(column, values, connection: connection);

  static Query<$Tag> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) =>
      Model.orderBy<$Tag>(column, direction: direction, connection: connection);

  static Query<$Tag> limit(int count, {String? connection}) =>
      Model.limit<$Tag>(count, connection: connection);

  /// Creates a [Repository] for [$Tag].
  ///
  /// {@macro ormed.repository}
  static Repository<$Tag> repo([String? connection]) =>
      Model.repository<$Tag>(connection: connection);
}

class TagModelFactory {
  const TagModelFactory._();

  static ModelDefinition<$Tag> get definition => _$TagDefinition;

  static ModelCodec<$Tag> get codec => definition.codec;

  static Tag fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    Tag model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model.toTracked(), registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<Tag> withConnection(QueryContext context) =>
      ModelFactoryConnection<Tag>(definition: definition, context: context);

  static ModelFactoryBuilder<Tag> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<Tag>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$TagCodec extends ModelCodec<$Tag> {
  const _$TagCodec();
  @override
  Map<String, Object?> encode($Tag model, ValueCodecRegistry registry) {
    return <String, Object?>{
      'id': registry.encodeField(_$TagIdField, model.id),
      'label': registry.encodeField(_$TagLabelField, model.label),
    };
  }

  @override
  $Tag decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final int tagIdValue =
        registry.decodeField<int>(_$TagIdField, data['id']) ?? 0;
    final String tagLabelValue =
        registry.decodeField<String>(_$TagLabelField, data['label']) ??
        (throw StateError('Field label on Tag cannot be null.'));
    final model = $Tag(id: tagIdValue, label: tagLabelValue);
    model._attachOrmRuntimeMetadata({'id': tagIdValue, 'label': tagLabelValue});
    return model;
  }
}

/// Insert DTO for [Tag].
///
/// Auto-increment/DB-generated fields are omitted by default.
class TagInsertDto implements InsertDto<$Tag> {
  const TagInsertDto({this.label});
  final String? label;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{if (label != null) 'label': label};
  }
}

/// Update DTO for [Tag].
///
/// All fields are optional; only provided entries are used in SET clauses.
class TagUpdateDto implements UpdateDto<$Tag> {
  const TagUpdateDto({this.id, this.label});
  final int? id;
  final String? label;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (label != null) 'label': label,
    };
  }
}

/// Partial projection for [Tag].
///
/// All fields are nullable; intended for subset SELECTs.
class TagPartial implements PartialEntity<$Tag> {
  const TagPartial({this.id, this.label});

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory TagPartial.fromRow(Map<String, Object?> row) {
    return TagPartial(id: row['id'] as int?, label: row['label'] as String?);
  }

  final int? id;
  final String? label;

  @override
  $Tag toEntity() {
    // Basic required-field check: non-nullable fields must be present.
    final int? idValue = id;
    if (idValue == null) {
      throw StateError('Missing required field: id');
    }
    final String? labelValue = label;
    if (labelValue == null) {
      throw StateError('Missing required field: label');
    }
    return $Tag(id: idValue, label: labelValue);
  }

  @override
  Map<String, Object?> toMap() {
    return {if (id != null) 'id': id, if (label != null) 'label': label};
  }
}

/// Generated tracked model class for [Tag].
///
/// This class extends the user-defined [Tag] model and adds
/// attribute tracking, change detection, and relationship management.
/// Instances of this class are returned by queries and repositories.
///
/// **Do not instantiate this class directly.** Use queries, repositories,
/// or model factories to create tracked model instances.
class $Tag extends Tag with ModelAttributes implements OrmEntity {
  $Tag({int id = 0, required String label}) : super.new(id: id, label: label) {
    _attachOrmRuntimeMetadata({'id': id, 'label': label});
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $Tag.fromModel(Tag model) {
    return $Tag(id: model.id, label: model.label);
  }

  $Tag copyWith({int? id, String? label}) {
    return $Tag(id: id ?? this.id, label: label ?? this.label);
  }

  @override
  int get id => getAttribute<int>('id') ?? super.id;

  set id(int value) => setAttribute('id', value);

  @override
  String get label => getAttribute<String>('label') ?? super.label;

  set label(String value) => setAttribute('label', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$TagDefinition);
  }

  @override
  List<Post> get posts {
    if (relationLoaded('posts')) {
      return getRelationList<Post>('posts');
    }
    return super.posts;
  }
}

extension TagRelationQueries on Tag {
  Query<Post> postsQuery() {
    final query = Model.query<Post>();
    final targetTable = query.definition.tableName;
    final targetKey = query.definition.primaryKeyField?.columnName ?? 'id';
    return query
        .join('post_tags', '$targetTable.$targetKey', '=', 'post_tags.post_id')
        .where('post_tags.tag_id', id);
  }
}

extension TagOrmExtension on Tag {
  /// The Type of the generated ORM-managed model class.
  /// Use this when you need to specify the tracked model type explicitly,
  /// for example in generic type parameters.
  static Type get trackedType => $Tag;

  /// Converts this immutable model to a tracked ORM-managed model.
  /// The tracked model supports attribute tracking, change detection,
  /// and persistence operations like save() and touch().
  $Tag toTracked() {
    return $Tag.fromModel(this);
  }
}

void registerTagEventHandlers(EventBus bus) {
  // No event handlers registered for Tag.
}
