// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'belongs_to_many.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$PostWithTagsIdField = FieldDefinition(
  name: 'id',
  columnName: 'id',
  dartType: 'int',
  resolvedType: 'int',
  isPrimaryKey: true,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$PostWithTagsTagsField = FieldDefinition(
  name: 'tags',
  columnName: 'tags',
  dartType: 'List<Tag>',
  resolvedType: 'List<Tag>?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

Map<String, Object?> _encodePostWithTagsUntracked(
  Object model,
  ValueCodecRegistry registry,
) {
  final m = model as PostWithTags;
  return <String, Object?>{
    'id': registry.encodeField(_$PostWithTagsIdField, m.id),
    'tags': registry.encodeField(_$PostWithTagsTagsField, m.tags),
  };
}

final ModelDefinition<$PostWithTags> _$PostWithTagsDefinition = ModelDefinition(
  modelName: 'PostWithTags',
  tableName: 'posts',
  fields: const [_$PostWithTagsIdField, _$PostWithTagsTagsField],
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
  untrackedToMap: _encodePostWithTagsUntracked,
  codec: _$PostWithTagsCodec(),
);

extension PostWithTagsOrmDefinition on PostWithTags {
  static ModelDefinition<$PostWithTags> get definition =>
      _$PostWithTagsDefinition;
}

class PostWithTags {
  const PostWithTags._();

  /// Starts building a query for [$PostWithTags].
  ///
  /// {@macro ormed.query}
  static Query<$PostWithTags> query([String? connection]) =>
      Model.query<$PostWithTags>(connection: connection);

  static Future<$PostWithTags?> find(Object id, {String? connection}) =>
      Model.find<$PostWithTags>(id, connection: connection);

  static Future<$PostWithTags> findOrFail(Object id, {String? connection}) =>
      Model.findOrFail<$PostWithTags>(id, connection: connection);

  static Future<List<$PostWithTags>> all({String? connection}) =>
      Model.all<$PostWithTags>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<$PostWithTags>(connection: connection);

  static Future<bool> anyExist({String? connection}) =>
      Model.anyExist<$PostWithTags>(connection: connection);

  static Query<$PostWithTags> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) => Model.where<$PostWithTags>(
    column,
    operator,
    value,
    connection: connection,
  );

  static Query<$PostWithTags> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<$PostWithTags>(column, values, connection: connection);

  static Query<$PostWithTags> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<$PostWithTags>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<$PostWithTags> limit(int count, {String? connection}) =>
      Model.limit<$PostWithTags>(count, connection: connection);

  /// Creates a [Repository] for [$PostWithTags].
  ///
  /// {@macro ormed.repository}
  static Repository<$PostWithTags> repo([String? connection]) =>
      Model.repository<$PostWithTags>(connection: connection);
}

class PostWithTagsModelFactory {
  const PostWithTagsModelFactory._();

  static ModelDefinition<$PostWithTags> get definition =>
      _$PostWithTagsDefinition;

  static ModelCodec<$PostWithTags> get codec => definition.codec;

  static PostWithTags fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    PostWithTags model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model.toTracked(), registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<PostWithTags> withConnection(
    QueryContext context,
  ) => ModelFactoryConnection<PostWithTags>(
    definition: definition,
    context: context,
  );

  static ModelFactoryBuilder<PostWithTags> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<PostWithTags>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$PostWithTagsCodec extends ModelCodec<$PostWithTags> {
  const _$PostWithTagsCodec();
  @override
  Map<String, Object?> encode(
    $PostWithTags model,
    ValueCodecRegistry registry,
  ) {
    return <String, Object?>{
      'id': registry.encodeField(_$PostWithTagsIdField, model.id),
      'tags': registry.encodeField(_$PostWithTagsTagsField, model.tags),
    };
  }

  @override
  $PostWithTags decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final int postWithTagsIdValue =
        registry.decodeField<int>(_$PostWithTagsIdField, data['id']) ??
        (throw StateError('Field id on PostWithTags cannot be null.'));
    final List<Tag>? postWithTagsTagsValue = registry.decodeField<List<Tag>?>(
      _$PostWithTagsTagsField,
      data['tags'],
    );
    final model = $PostWithTags(
      id: postWithTagsIdValue,
      tags: postWithTagsTagsValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': postWithTagsIdValue,
      'tags': postWithTagsTagsValue,
    });
    return model;
  }
}

/// Insert DTO for [PostWithTags].
///
/// Auto-increment/DB-generated fields are omitted by default.
class PostWithTagsInsertDto implements InsertDto<$PostWithTags> {
  const PostWithTagsInsertDto({this.id, this.tags});
  final int? id;
  final List<Tag>? tags;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (tags != null) 'tags': tags,
    };
  }

  static const _PostWithTagsInsertDtoCopyWithSentinel _copyWithSentinel =
      _PostWithTagsInsertDtoCopyWithSentinel();
  PostWithTagsInsertDto copyWith({
    Object? id = _copyWithSentinel,
    Object? tags = _copyWithSentinel,
  }) {
    return PostWithTagsInsertDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      tags: identical(tags, _copyWithSentinel) ? this.tags : tags as List<Tag>?,
    );
  }
}

class _PostWithTagsInsertDtoCopyWithSentinel {
  const _PostWithTagsInsertDtoCopyWithSentinel();
}

/// Update DTO for [PostWithTags].
///
/// All fields are optional; only provided entries are used in SET clauses.
class PostWithTagsUpdateDto implements UpdateDto<$PostWithTags> {
  const PostWithTagsUpdateDto({this.id, this.tags});
  final int? id;
  final List<Tag>? tags;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (tags != null) 'tags': tags,
    };
  }

  static const _PostWithTagsUpdateDtoCopyWithSentinel _copyWithSentinel =
      _PostWithTagsUpdateDtoCopyWithSentinel();
  PostWithTagsUpdateDto copyWith({
    Object? id = _copyWithSentinel,
    Object? tags = _copyWithSentinel,
  }) {
    return PostWithTagsUpdateDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      tags: identical(tags, _copyWithSentinel) ? this.tags : tags as List<Tag>?,
    );
  }
}

class _PostWithTagsUpdateDtoCopyWithSentinel {
  const _PostWithTagsUpdateDtoCopyWithSentinel();
}

/// Partial projection for [PostWithTags].
///
/// All fields are nullable; intended for subset SELECTs.
class PostWithTagsPartial implements PartialEntity<$PostWithTags> {
  const PostWithTagsPartial({this.id, this.tags});

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory PostWithTagsPartial.fromRow(Map<String, Object?> row) {
    return PostWithTagsPartial(
      id: row['id'] as int?,
      tags: row['tags'] as List<Tag>?,
    );
  }

  final int? id;
  final List<Tag>? tags;

  @override
  $PostWithTags toEntity() {
    // Basic required-field check: non-nullable fields must be present.
    final int? idValue = id;
    if (idValue == null) {
      throw StateError('Missing required field: id');
    }
    return $PostWithTags(id: idValue, tags: tags);
  }

  @override
  Map<String, Object?> toMap() {
    return {if (id != null) 'id': id, if (tags != null) 'tags': tags};
  }

  static const _PostWithTagsPartialCopyWithSentinel _copyWithSentinel =
      _PostWithTagsPartialCopyWithSentinel();
  PostWithTagsPartial copyWith({
    Object? id = _copyWithSentinel,
    Object? tags = _copyWithSentinel,
  }) {
    return PostWithTagsPartial(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      tags: identical(tags, _copyWithSentinel) ? this.tags : tags as List<Tag>?,
    );
  }
}

class _PostWithTagsPartialCopyWithSentinel {
  const _PostWithTagsPartialCopyWithSentinel();
}

/// Generated tracked model class for [PostWithTags].
///
/// This class extends the user-defined [PostWithTags] model and adds
/// attribute tracking, change detection, and relationship management.
/// Instances of this class are returned by queries and repositories.
///
/// **Do not instantiate this class directly.** Use queries, repositories,
/// or model factories to create tracked model instances.
class $PostWithTags extends PostWithTags
    with ModelAttributes
    implements OrmEntity {
  /// Internal constructor for [$PostWithTags].
  $PostWithTags({required int id, List<Tag>? tags})
    : super.new(id: id, tags: tags) {
    _attachOrmRuntimeMetadata({'id': id, 'tags': tags});
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $PostWithTags.fromModel(PostWithTags model) {
    return $PostWithTags(id: model.id, tags: model.tags);
  }

  $PostWithTags copyWith({int? id, List<Tag>? tags}) {
    return $PostWithTags(id: id ?? this.id, tags: tags ?? this.tags);
  }

  /// Tracked getter for [id].
  @override
  int get id => getAttribute<int>('id') ?? super.id;

  /// Tracked setter for [id].
  set id(int value) => setAttribute('id', value);

  /// Tracked getter for [tags].
  @override
  List<Tag>? get tags => getAttribute<List<Tag>?>('tags') ?? super.tags;

  /// Tracked setter for [tags].
  set tags(List<Tag>? value) => setAttribute('tags', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$PostWithTagsDefinition);
  }
}

extension PostWithTagsOrmExtension on PostWithTags {
  /// The Type of the generated ORM-managed model class.
  /// Use this when you need to specify the tracked model type explicitly,
  /// for example in generic type parameters.
  static Type get trackedType => $PostWithTags;

  /// Converts this immutable model to a tracked ORM-managed model.
  /// The tracked model supports attribute tracking, change detection,
  /// and persistence operations like save() and touch().
  $PostWithTags toTracked() {
    return $PostWithTags.fromModel(this);
  }
}

void registerPostWithTagsEventHandlers(EventBus bus) {
  // No event handlers registered for PostWithTags.
}

const FieldDefinition _$TagIdField = FieldDefinition(
  name: 'id',
  columnName: 'id',
  dartType: 'int',
  resolvedType: 'int',
  isPrimaryKey: true,
  isNullable: false,
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

Map<String, Object?> _encodeTagUntracked(
  Object model,
  ValueCodecRegistry registry,
) {
  final m = model as Tag;
  return <String, Object?>{
    'id': registry.encodeField(_$TagIdField, m.id),
    'name': registry.encodeField(_$TagNameField, m.name),
  };
}

final ModelDefinition<$Tag> _$TagDefinition = ModelDefinition(
  modelName: 'Tag',
  tableName: 'tags',
  fields: const [_$TagIdField, _$TagNameField],
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
    };
  }

  @override
  $Tag decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final int tagIdValue =
        registry.decodeField<int>(_$TagIdField, data['id']) ??
        (throw StateError('Field id on Tag cannot be null.'));
    final String tagNameValue =
        registry.decodeField<String>(_$TagNameField, data['name']) ??
        (throw StateError('Field name on Tag cannot be null.'));
    final model = $Tag(id: tagIdValue, name: tagNameValue);
    model._attachOrmRuntimeMetadata({'id': tagIdValue, 'name': tagNameValue});
    return model;
  }
}

/// Insert DTO for [Tag].
///
/// Auto-increment/DB-generated fields are omitted by default.
class TagInsertDto implements InsertDto<$Tag> {
  const TagInsertDto({this.id, this.name});
  final int? id;
  final String? name;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (name != null) 'name': name,
    };
  }

  static const _TagInsertDtoCopyWithSentinel _copyWithSentinel =
      _TagInsertDtoCopyWithSentinel();
  TagInsertDto copyWith({
    Object? id = _copyWithSentinel,
    Object? name = _copyWithSentinel,
  }) {
    return TagInsertDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      name: identical(name, _copyWithSentinel) ? this.name : name as String?,
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
  const TagUpdateDto({this.id, this.name});
  final int? id;
  final String? name;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (name != null) 'name': name,
    };
  }

  static const _TagUpdateDtoCopyWithSentinel _copyWithSentinel =
      _TagUpdateDtoCopyWithSentinel();
  TagUpdateDto copyWith({
    Object? id = _copyWithSentinel,
    Object? name = _copyWithSentinel,
  }) {
    return TagUpdateDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      name: identical(name, _copyWithSentinel) ? this.name : name as String?,
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
  const TagPartial({this.id, this.name});

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory TagPartial.fromRow(Map<String, Object?> row) {
    return TagPartial(id: row['id'] as int?, name: row['name'] as String?);
  }

  final int? id;
  final String? name;

  @override
  $Tag toEntity() {
    // Basic required-field check: non-nullable fields must be present.
    final int? idValue = id;
    if (idValue == null) {
      throw StateError('Missing required field: id');
    }
    final String? nameValue = name;
    if (nameValue == null) {
      throw StateError('Missing required field: name');
    }
    return $Tag(id: idValue, name: nameValue);
  }

  @override
  Map<String, Object?> toMap() {
    return {if (id != null) 'id': id, if (name != null) 'name': name};
  }

  static const _TagPartialCopyWithSentinel _copyWithSentinel =
      _TagPartialCopyWithSentinel();
  TagPartial copyWith({
    Object? id = _copyWithSentinel,
    Object? name = _copyWithSentinel,
  }) {
    return TagPartial(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      name: identical(name, _copyWithSentinel) ? this.name : name as String?,
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
  $Tag({required int id, required String name})
    : super.new(id: id, name: name) {
    _attachOrmRuntimeMetadata({'id': id, 'name': name});
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $Tag.fromModel(Tag model) {
    return $Tag(id: model.id, name: model.name);
  }

  $Tag copyWith({int? id, String? name}) {
    return $Tag(id: id ?? this.id, name: name ?? this.name);
  }

  /// Tracked getter for [id].
  @override
  int get id => getAttribute<int>('id') ?? super.id;

  /// Tracked setter for [id].
  set id(int value) => setAttribute('id', value);

  /// Tracked getter for [name].
  @override
  String get name => getAttribute<String>('name') ?? super.name;

  /// Tracked setter for [name].
  set name(String value) => setAttribute('name', value);

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
