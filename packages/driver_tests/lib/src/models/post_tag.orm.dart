// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'post_tag.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$PostTagPostIdField = FieldDefinition(
  name: 'postId',
  columnName: 'post_id',
  dartType: 'int',
  resolvedType: 'int',
  isPrimaryKey: true,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$PostTagTagIdField = FieldDefinition(
  name: 'tagId',
  columnName: 'tag_id',
  dartType: 'int',
  resolvedType: 'int',
  isPrimaryKey: true,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$PostTagSortOrderField = FieldDefinition(
  name: 'sortOrder',
  columnName: 'sort_order',
  dartType: 'int',
  resolvedType: 'int?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$PostTagNoteField = FieldDefinition(
  name: 'note',
  columnName: 'note',
  dartType: 'String',
  resolvedType: 'String?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$PostTagCreatedAtField = FieldDefinition(
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

const FieldDefinition _$PostTagUpdatedAtField = FieldDefinition(
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

Map<String, Object?> _encodePostTagUntracked(
  Object model,
  ValueCodecRegistry registry,
) {
  final m = model as PostTag;
  return <String, Object?>{
    'post_id': registry.encodeField(_$PostTagPostIdField, m.postId),
    'tag_id': registry.encodeField(_$PostTagTagIdField, m.tagId),
    'sort_order': registry.encodeField(_$PostTagSortOrderField, m.sortOrder),
    'note': registry.encodeField(_$PostTagNoteField, m.note),
    'created_at': registry.encodeField(_$PostTagCreatedAtField, m.createdAt),
    'updated_at': registry.encodeField(_$PostTagUpdatedAtField, m.updatedAt),
  };
}

final ModelDefinition<$PostTag> _$PostTagDefinition = ModelDefinition(
  modelName: 'PostTag',
  tableName: 'post_tags',
  fields: const [
    _$PostTagPostIdField,
    _$PostTagTagIdField,
    _$PostTagSortOrderField,
    _$PostTagNoteField,
    _$PostTagCreatedAtField,
    _$PostTagUpdatedAtField,
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
    touches: const <String>[],
    timestamps: true,
    softDeletes: false,
    softDeleteColumn: 'deleted_at',
  ),
  untrackedToMap: _encodePostTagUntracked,
  codec: _$PostTagCodec(),
);

// ignore: unused_element
final posttagModelDefinitionRegistration =
    ModelFactoryRegistry.register<$PostTag>(_$PostTagDefinition);

extension PostTagOrmDefinition on PostTag {
  static ModelDefinition<$PostTag> get definition => _$PostTagDefinition;
}

class PostTags {
  const PostTags._();

  /// Starts building a query for [$PostTag].
  ///
  /// {@macro ormed.query}
  static Query<$PostTag> query([String? connection]) =>
      Model.query<$PostTag>(connection: connection);

  static Future<$PostTag?> find(Object id, {String? connection}) =>
      Model.find<$PostTag>(id, connection: connection);

  static Future<$PostTag> findOrFail(Object id, {String? connection}) =>
      Model.findOrFail<$PostTag>(id, connection: connection);

  static Future<List<$PostTag>> all({String? connection}) =>
      Model.all<$PostTag>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<$PostTag>(connection: connection);

  static Future<bool> anyExist({String? connection}) =>
      Model.anyExist<$PostTag>(connection: connection);

  static Query<$PostTag> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) => Model.where<$PostTag>(column, operator, value, connection: connection);

  static Query<$PostTag> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<$PostTag>(column, values, connection: connection);

  static Query<$PostTag> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<$PostTag>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<$PostTag> limit(int count, {String? connection}) =>
      Model.limit<$PostTag>(count, connection: connection);

  /// Creates a [Repository] for [$PostTag].
  ///
  /// {@macro ormed.repository}
  static Repository<$PostTag> repo([String? connection]) =>
      Model.repository<$PostTag>(connection: connection);

  /// Builds a tracked model from a column/value map.
  static $PostTag fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$PostTagDefinition.fromMap(data, registry: registry);

  /// Converts a tracked model to a column/value map.
  static Map<String, Object?> toMap(
    $PostTag model, {
    ValueCodecRegistry? registry,
  }) => _$PostTagDefinition.toMap(model, registry: registry);
}

class PostTagModelFactory {
  const PostTagModelFactory._();

  static ModelDefinition<$PostTag> get definition => _$PostTagDefinition;

  static ModelCodec<$PostTag> get codec => definition.codec;

  static PostTag fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    PostTag model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model.toTracked(), registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<PostTag> withConnection(QueryContext context) =>
      ModelFactoryConnection<PostTag>(definition: definition, context: context);

  static ModelFactoryBuilder<PostTag> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<PostTag>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$PostTagCodec extends ModelCodec<$PostTag> {
  const _$PostTagCodec();
  @override
  Map<String, Object?> encode($PostTag model, ValueCodecRegistry registry) {
    return <String, Object?>{
      'post_id': registry.encodeField(_$PostTagPostIdField, model.postId),
      'tag_id': registry.encodeField(_$PostTagTagIdField, model.tagId),
      'sort_order': registry.encodeField(
        _$PostTagSortOrderField,
        model.sortOrder,
      ),
      'note': registry.encodeField(_$PostTagNoteField, model.note),
      'created_at': registry.encodeField(
        _$PostTagCreatedAtField,
        model.createdAt,
      ),
      'updated_at': registry.encodeField(
        _$PostTagUpdatedAtField,
        model.updatedAt,
      ),
    };
  }

  @override
  $PostTag decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final int postTagPostIdValue =
        registry.decodeField<int>(_$PostTagPostIdField, data['post_id']) ??
        (throw StateError('Field postId on PostTag cannot be null.'));
    final int postTagTagIdValue =
        registry.decodeField<int>(_$PostTagTagIdField, data['tag_id']) ??
        (throw StateError('Field tagId on PostTag cannot be null.'));
    final int? postTagSortOrderValue = registry.decodeField<int?>(
      _$PostTagSortOrderField,
      data['sort_order'],
    );
    final String? postTagNoteValue = registry.decodeField<String?>(
      _$PostTagNoteField,
      data['note'],
    );
    final DateTime? postTagCreatedAtValue = registry.decodeField<DateTime?>(
      _$PostTagCreatedAtField,
      data['created_at'],
    );
    final DateTime? postTagUpdatedAtValue = registry.decodeField<DateTime?>(
      _$PostTagUpdatedAtField,
      data['updated_at'],
    );
    final model = $PostTag(
      postId: postTagPostIdValue,
      tagId: postTagTagIdValue,
      sortOrder: postTagSortOrderValue,
      note: postTagNoteValue,
      createdAt: postTagCreatedAtValue,
      updatedAt: postTagUpdatedAtValue,
    );
    model._attachOrmRuntimeMetadata({
      'post_id': postTagPostIdValue,
      'tag_id': postTagTagIdValue,
      'sort_order': postTagSortOrderValue,
      'note': postTagNoteValue,
      'created_at': postTagCreatedAtValue,
      'updated_at': postTagUpdatedAtValue,
    });
    return model;
  }
}

/// Insert DTO for [PostTag].
///
/// Auto-increment/DB-generated fields are omitted by default.
class PostTagInsertDto implements InsertDto<$PostTag> {
  const PostTagInsertDto({
    this.postId,
    this.tagId,
    this.sortOrder,
    this.note,
    this.createdAt,
    this.updatedAt,
  });
  final int? postId;
  final int? tagId;
  final int? sortOrder;
  final String? note;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (postId != null) 'post_id': postId,
      if (tagId != null) 'tag_id': tagId,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    };
  }

  static const _PostTagInsertDtoCopyWithSentinel _copyWithSentinel =
      _PostTagInsertDtoCopyWithSentinel();
  PostTagInsertDto copyWith({
    Object? postId = _copyWithSentinel,
    Object? tagId = _copyWithSentinel,
    Object? sortOrder = _copyWithSentinel,
    Object? note = _copyWithSentinel,
    Object? createdAt = _copyWithSentinel,
    Object? updatedAt = _copyWithSentinel,
  }) {
    return PostTagInsertDto(
      postId: identical(postId, _copyWithSentinel)
          ? this.postId
          : postId as int?,
      tagId: identical(tagId, _copyWithSentinel) ? this.tagId : tagId as int?,
      sortOrder: identical(sortOrder, _copyWithSentinel)
          ? this.sortOrder
          : sortOrder as int?,
      note: identical(note, _copyWithSentinel) ? this.note : note as String?,
      createdAt: identical(createdAt, _copyWithSentinel)
          ? this.createdAt
          : createdAt as DateTime?,
      updatedAt: identical(updatedAt, _copyWithSentinel)
          ? this.updatedAt
          : updatedAt as DateTime?,
    );
  }
}

class _PostTagInsertDtoCopyWithSentinel {
  const _PostTagInsertDtoCopyWithSentinel();
}

/// Update DTO for [PostTag].
///
/// All fields are optional; only provided entries are used in SET clauses.
class PostTagUpdateDto implements UpdateDto<$PostTag> {
  const PostTagUpdateDto({
    this.postId,
    this.tagId,
    this.sortOrder,
    this.note,
    this.createdAt,
    this.updatedAt,
  });
  final int? postId;
  final int? tagId;
  final int? sortOrder;
  final String? note;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (postId != null) 'post_id': postId,
      if (tagId != null) 'tag_id': tagId,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    };
  }

  static const _PostTagUpdateDtoCopyWithSentinel _copyWithSentinel =
      _PostTagUpdateDtoCopyWithSentinel();
  PostTagUpdateDto copyWith({
    Object? postId = _copyWithSentinel,
    Object? tagId = _copyWithSentinel,
    Object? sortOrder = _copyWithSentinel,
    Object? note = _copyWithSentinel,
    Object? createdAt = _copyWithSentinel,
    Object? updatedAt = _copyWithSentinel,
  }) {
    return PostTagUpdateDto(
      postId: identical(postId, _copyWithSentinel)
          ? this.postId
          : postId as int?,
      tagId: identical(tagId, _copyWithSentinel) ? this.tagId : tagId as int?,
      sortOrder: identical(sortOrder, _copyWithSentinel)
          ? this.sortOrder
          : sortOrder as int?,
      note: identical(note, _copyWithSentinel) ? this.note : note as String?,
      createdAt: identical(createdAt, _copyWithSentinel)
          ? this.createdAt
          : createdAt as DateTime?,
      updatedAt: identical(updatedAt, _copyWithSentinel)
          ? this.updatedAt
          : updatedAt as DateTime?,
    );
  }
}

class _PostTagUpdateDtoCopyWithSentinel {
  const _PostTagUpdateDtoCopyWithSentinel();
}

/// Partial projection for [PostTag].
///
/// All fields are nullable; intended for subset SELECTs.
class PostTagPartial implements PartialEntity<$PostTag> {
  const PostTagPartial({
    this.postId,
    this.tagId,
    this.sortOrder,
    this.note,
    this.createdAt,
    this.updatedAt,
  });

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory PostTagPartial.fromRow(Map<String, Object?> row) {
    return PostTagPartial(
      postId: row['post_id'] as int?,
      tagId: row['tag_id'] as int?,
      sortOrder: row['sort_order'] as int?,
      note: row['note'] as String?,
      createdAt: row['created_at'] as DateTime?,
      updatedAt: row['updated_at'] as DateTime?,
    );
  }

  final int? postId;
  final int? tagId;
  final int? sortOrder;
  final String? note;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  @override
  $PostTag toEntity() {
    // Basic required-field check: non-nullable fields must be present.
    final int? postIdValue = postId;
    if (postIdValue == null) {
      throw StateError('Missing required field: postId');
    }
    final int? tagIdValue = tagId;
    if (tagIdValue == null) {
      throw StateError('Missing required field: tagId');
    }
    return $PostTag(
      postId: postIdValue,
      tagId: tagIdValue,
      sortOrder: sortOrder,
      note: note,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  Map<String, Object?> toMap() {
    return {
      if (postId != null) 'post_id': postId,
      if (tagId != null) 'tag_id': tagId,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    };
  }

  static const _PostTagPartialCopyWithSentinel _copyWithSentinel =
      _PostTagPartialCopyWithSentinel();
  PostTagPartial copyWith({
    Object? postId = _copyWithSentinel,
    Object? tagId = _copyWithSentinel,
    Object? sortOrder = _copyWithSentinel,
    Object? note = _copyWithSentinel,
    Object? createdAt = _copyWithSentinel,
    Object? updatedAt = _copyWithSentinel,
  }) {
    return PostTagPartial(
      postId: identical(postId, _copyWithSentinel)
          ? this.postId
          : postId as int?,
      tagId: identical(tagId, _copyWithSentinel) ? this.tagId : tagId as int?,
      sortOrder: identical(sortOrder, _copyWithSentinel)
          ? this.sortOrder
          : sortOrder as int?,
      note: identical(note, _copyWithSentinel) ? this.note : note as String?,
      createdAt: identical(createdAt, _copyWithSentinel)
          ? this.createdAt
          : createdAt as DateTime?,
      updatedAt: identical(updatedAt, _copyWithSentinel)
          ? this.updatedAt
          : updatedAt as DateTime?,
    );
  }
}

class _PostTagPartialCopyWithSentinel {
  const _PostTagPartialCopyWithSentinel();
}

/// Generated tracked model class for [PostTag].
///
/// This class extends the user-defined [PostTag] model and adds
/// attribute tracking, change detection, and relationship management.
/// Instances of this class are returned by queries and repositories.
///
/// **Do not instantiate this class directly.** Use queries, repositories,
/// or model factories to create tracked model instances.
class $PostTag extends PostTag with ModelAttributes implements OrmEntity {
  /// Internal constructor for [$PostTag].
  $PostTag({
    required int postId,
    required int tagId,
    int? sortOrder,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : super.new(
         postId: postId,
         tagId: tagId,
         sortOrder: sortOrder,
         note: note,
         createdAt: createdAt,
         updatedAt: updatedAt,
       ) {
    _attachOrmRuntimeMetadata({
      'post_id': postId,
      'tag_id': tagId,
      'sort_order': sortOrder,
      'note': note,
      'created_at': createdAt,
      'updated_at': updatedAt,
    });
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $PostTag.fromModel(PostTag model) {
    return $PostTag(
      postId: model.postId,
      tagId: model.tagId,
      sortOrder: model.sortOrder,
      note: model.note,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );
  }

  $PostTag copyWith({
    int? postId,
    int? tagId,
    int? sortOrder,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return $PostTag(
      postId: postId ?? this.postId,
      tagId: tagId ?? this.tagId,
      sortOrder: sortOrder ?? this.sortOrder,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Builds a tracked model from a column/value map.
  static $PostTag fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$PostTagDefinition.fromMap(data, registry: registry);

  /// Converts this tracked model to a column/value map.
  Map<String, Object?> toMap({ValueCodecRegistry? registry}) =>
      _$PostTagDefinition.toMap(this, registry: registry);

  /// Tracked getter for [postId].
  @override
  int get postId => getAttribute<int>('post_id') ?? super.postId;

  /// Tracked setter for [postId].
  set postId(int value) => setAttribute('post_id', value);

  /// Tracked getter for [tagId].
  @override
  int get tagId => getAttribute<int>('tag_id') ?? super.tagId;

  /// Tracked setter for [tagId].
  set tagId(int value) => setAttribute('tag_id', value);

  /// Tracked getter for [sortOrder].
  @override
  int? get sortOrder => getAttribute<int?>('sort_order') ?? super.sortOrder;

  /// Tracked setter for [sortOrder].
  set sortOrder(int? value) => setAttribute('sort_order', value);

  /// Tracked getter for [note].
  @override
  String? get note => getAttribute<String?>('note') ?? super.note;

  /// Tracked setter for [note].
  set note(String? value) => setAttribute('note', value);

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
    attachModelDefinition(_$PostTagDefinition);
  }
}

class _PostTagCopyWithSentinel {
  const _PostTagCopyWithSentinel();
}

extension PostTagOrmExtension on PostTag {
  static const _PostTagCopyWithSentinel _copyWithSentinel =
      _PostTagCopyWithSentinel();
  PostTag copyWith({
    Object? postId = _copyWithSentinel,
    Object? tagId = _copyWithSentinel,
    Object? sortOrder = _copyWithSentinel,
    Object? note = _copyWithSentinel,
    Object? createdAt = _copyWithSentinel,
    Object? updatedAt = _copyWithSentinel,
  }) {
    return PostTag(
      postId: identical(postId, _copyWithSentinel)
          ? this.postId
          : postId as int,
      tagId: identical(tagId, _copyWithSentinel) ? this.tagId : tagId as int,
      sortOrder: identical(sortOrder, _copyWithSentinel)
          ? this.sortOrder
          : sortOrder as int?,
      note: identical(note, _copyWithSentinel) ? this.note : note as String?,
      createdAt: identical(createdAt, _copyWithSentinel)
          ? this.createdAt
          : createdAt as DateTime?,
      updatedAt: identical(updatedAt, _copyWithSentinel)
          ? this.updatedAt
          : updatedAt as DateTime?,
    );
  }

  /// Converts this model to a column/value map.
  Map<String, Object?> toMap({ValueCodecRegistry? registry}) =>
      _$PostTagDefinition.toMap(this, registry: registry);

  /// Builds a model from a column/value map.
  static PostTag fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$PostTagDefinition.fromMap(data, registry: registry);

  /// The Type of the generated ORM-managed model class.
  /// Use this when you need to specify the tracked model type explicitly,
  /// for example in generic type parameters.
  static Type get trackedType => $PostTag;

  /// Converts this immutable model to a tracked ORM-managed model.
  /// The tracked model supports attribute tracking, change detection,
  /// and persistence operations like save() and touch().
  $PostTag toTracked() {
    return $PostTag.fromModel(this);
  }
}

extension PostTagPredicateFields on PredicateBuilder<PostTag> {
  PredicateField<PostTag, int> get postId =>
      PredicateField<PostTag, int>(this, 'postId');
  PredicateField<PostTag, int> get tagId =>
      PredicateField<PostTag, int>(this, 'tagId');
  PredicateField<PostTag, int?> get sortOrder =>
      PredicateField<PostTag, int?>(this, 'sortOrder');
  PredicateField<PostTag, String?> get note =>
      PredicateField<PostTag, String?>(this, 'note');
  PredicateField<PostTag, DateTime?> get createdAt =>
      PredicateField<PostTag, DateTime?>(this, 'createdAt');
  PredicateField<PostTag, DateTime?> get updatedAt =>
      PredicateField<PostTag, DateTime?>(this, 'updatedAt');
}

void registerPostTagEventHandlers(EventBus bus) {
  // No event handlers registered for PostTag.
}
