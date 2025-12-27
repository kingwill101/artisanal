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
  resolvedType: 'int?',
  isPrimaryKey: true,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$TagNameField = FieldDefinition(
  name: 'name',
  columnName: 'name',
  dartType: 'String',
  resolvedType: 'String',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$TagCreatedAtField = FieldDefinition(
  name: 'createdAt',
  columnName: 'created_at',
  dartType: 'DateTime',
  resolvedType: 'DateTime?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$TagUpdatedAtField = FieldDefinition(
  name: 'updatedAt',
  columnName: 'updated_at',
  dartType: 'DateTime',
  resolvedType: 'DateTime?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

Map<String, Object?> _encodeTagUntracked(
  Object model,
  ValueCodecRegistry registry,
) {
  final m = model as Tag;
  return <String, Object?>{
    'id': registry.encodeField(_$TagIdField, m.id),
    'name': registry.encodeField(_$TagNameField, m.name),
    'created_at': registry.encodeField(_$TagCreatedAtField, m.createdAt),
    'updated_at': registry.encodeField(_$TagUpdatedAtField, m.updatedAt),
  };
}

final ModelDefinition<$Tag> _$TagDefinition = ModelDefinition(
  modelName: 'Tag',
  tableName: 'tags',
  fields: const [
    _$TagIdField,
    _$TagNameField,
    _$TagCreatedAtField,
    _$TagUpdatedAtField,
  ],
  relations: const [],
  softDeleteColumn: 'deleted_at',
  metadata: ModelAttributesMetadata(
    hidden: const <String>[],
    visible: const <String>[],
    fillable: const <String>[],
    guarded: const <String>[],
    casts: const <String, String>{},
    appends: const <String>[],
    softDeletes: false,
    softDeleteColumn: 'deleted_at',
  ),
  untrackedToMap: _encodeTagUntracked,
  codec: _$TagCodec(),
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
      'name': registry.encodeField(_$TagNameField, model.name),
      'created_at': registry.encodeField(_$TagCreatedAtField, model.createdAt),
      'updated_at': registry.encodeField(_$TagUpdatedAtField, model.updatedAt),
    };
  }

  @override
  $Tag decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final int? tagIdValue = registry.decodeField<int?>(
      _$TagIdField,
      data['id'],
    );
    final String tagNameValue =
        registry.decodeField<String>(_$TagNameField, data['name']) ??
        (throw StateError('Field name on Tag cannot be null.'));
    final DateTime? tagCreatedAtValue = registry.decodeField<DateTime?>(
      _$TagCreatedAtField,
      data['created_at'],
    );
    final DateTime? tagUpdatedAtValue = registry.decodeField<DateTime?>(
      _$TagUpdatedAtField,
      data['updated_at'],
    );
    final model = $Tag(
      id: tagIdValue,
      name: tagNameValue,
      createdAt: tagCreatedAtValue,
      updatedAt: tagUpdatedAtValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': tagIdValue,
      'name': tagNameValue,
      'created_at': tagCreatedAtValue,
      'updated_at': tagUpdatedAtValue,
    });
    return model;
  }
}

/// Insert DTO for [Tag].
///
/// Auto-increment/DB-generated fields are omitted by default.
class TagInsertDto implements InsertDto<$Tag> {
  const TagInsertDto({this.id, this.name, this.createdAt, this.updatedAt});
  final int? id;
  final String? name;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    };
  }

  static const _TagInsertDtoCopyWithSentinel _copyWithSentinel =
      _TagInsertDtoCopyWithSentinel();
  TagInsertDto copyWith({
    Object? id = _copyWithSentinel,
    Object? name = _copyWithSentinel,
    Object? createdAt = _copyWithSentinel,
    Object? updatedAt = _copyWithSentinel,
  }) {
    return TagInsertDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      name: identical(name, _copyWithSentinel) ? this.name : name as String?,
      createdAt: identical(createdAt, _copyWithSentinel)
          ? this.createdAt
          : createdAt as DateTime?,
      updatedAt: identical(updatedAt, _copyWithSentinel)
          ? this.updatedAt
          : updatedAt as DateTime?,
    );
  }
}

class _TagInsertDtoCopyWithSentinel {
  const _TagInsertDtoCopyWithSentinel();
}

/// Update DTO for [Tag].
///
/// All fields are optional; only provided entries are used in SET clauses.
class TagUpdateDto implements UpdateDto<$Tag> {
  const TagUpdateDto({this.id, this.name, this.createdAt, this.updatedAt});
  final int? id;
  final String? name;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    };
  }

  static const _TagUpdateDtoCopyWithSentinel _copyWithSentinel =
      _TagUpdateDtoCopyWithSentinel();
  TagUpdateDto copyWith({
    Object? id = _copyWithSentinel,
    Object? name = _copyWithSentinel,
    Object? createdAt = _copyWithSentinel,
    Object? updatedAt = _copyWithSentinel,
  }) {
    return TagUpdateDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      name: identical(name, _copyWithSentinel) ? this.name : name as String?,
      createdAt: identical(createdAt, _copyWithSentinel)
          ? this.createdAt
          : createdAt as DateTime?,
      updatedAt: identical(updatedAt, _copyWithSentinel)
          ? this.updatedAt
          : updatedAt as DateTime?,
    );
  }
}

class _TagUpdateDtoCopyWithSentinel {
  const _TagUpdateDtoCopyWithSentinel();
}

/// Partial projection for [Tag].
///
/// All fields are nullable; intended for subset SELECTs.
class TagPartial implements PartialEntity<$Tag> {
  const TagPartial({this.id, this.name, this.createdAt, this.updatedAt});

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory TagPartial.fromRow(Map<String, Object?> row) {
    return TagPartial(
      id: row['id'] as int?,
      name: row['name'] as String?,
      createdAt: row['created_at'] as DateTime?,
      updatedAt: row['updated_at'] as DateTime?,
    );
  }

  final int? id;
  final String? name;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  @override
  $Tag toEntity() {
    // Basic required-field check: non-nullable fields must be present.
    final String? nameValue = name;
    if (nameValue == null) {
      throw StateError('Missing required field: name');
    }
    return $Tag(
      id: id,
      name: nameValue,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    };
  }

  static const _TagPartialCopyWithSentinel _copyWithSentinel =
      _TagPartialCopyWithSentinel();
  TagPartial copyWith({
    Object? id = _copyWithSentinel,
    Object? name = _copyWithSentinel,
    Object? createdAt = _copyWithSentinel,
    Object? updatedAt = _copyWithSentinel,
  }) {
    return TagPartial(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      name: identical(name, _copyWithSentinel) ? this.name : name as String?,
      createdAt: identical(createdAt, _copyWithSentinel)
          ? this.createdAt
          : createdAt as DateTime?,
      updatedAt: identical(updatedAt, _copyWithSentinel)
          ? this.updatedAt
          : updatedAt as DateTime?,
    );
  }
}

class _TagPartialCopyWithSentinel {
  const _TagPartialCopyWithSentinel();
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
  /// Internal constructor for [$Tag].
  $Tag({
    int? id,
    required String name,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : super.new(
         id: id,
         name: name,
         createdAt: createdAt,
         updatedAt: updatedAt,
       ) {
    _attachOrmRuntimeMetadata({
      'id': id,
      'name': name,
      'created_at': createdAt,
      'updated_at': updatedAt,
    });
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $Tag.fromModel(Tag model) {
    return $Tag(
      id: model.id,
      name: model.name,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );
  }

  $Tag copyWith({
    int? id,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return $Tag(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Tracked getter for [id].
  @override
  int? get id => getAttribute<int?>('id') ?? super.id;

  /// Tracked setter for [id].
  set id(int? value) => setAttribute('id', value);

  /// Tracked getter for [name].
  @override
  String get name => getAttribute<String>('name') ?? super.name;

  /// Tracked setter for [name].
  set name(String value) => setAttribute('name', value);

  /// Tracked getter for [createdAt].
  @override
  DateTime? get createdAt =>
      getAttribute<DateTime?>('created_at') ?? super.createdAt;

  /// Tracked setter for [createdAt].
  set createdAt(DateTime? value) => setAttribute('created_at', value);

  /// Tracked getter for [updatedAt].
  @override
  DateTime? get updatedAt =>
      getAttribute<DateTime?>('updated_at') ?? super.updatedAt;

  /// Tracked setter for [updatedAt].
  set updatedAt(DateTime? value) => setAttribute('updated_at', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$TagDefinition);
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
