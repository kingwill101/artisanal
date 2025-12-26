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
  isPrimaryKey: false,
  isNullable: false,
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
  };
}

final ModelDefinition<$PostTag> _$PostTagDefinition = ModelDefinition(
  modelName: 'PostTag',
  tableName: 'post_tags',
  fields: const [_$PostTagPostIdField, _$PostTagTagIdField],
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
  untrackedToMap: _encodePostTagUntracked,
  codec: _$PostTagCodec(),
);

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
    final model = $PostTag(
      postId: postTagPostIdValue,
      tagId: postTagTagIdValue,
    );
    model._attachOrmRuntimeMetadata({
      'post_id': postTagPostIdValue,
      'tag_id': postTagTagIdValue,
    });
    return model;
  }
}

/// Insert DTO for [PostTag].
///
/// Auto-increment/DB-generated fields are omitted by default.
class PostTagInsertDto implements InsertDto<$PostTag> {
  const PostTagInsertDto({this.postId, this.tagId});
  final int? postId;
  final int? tagId;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (postId != null) 'post_id': postId,
      if (tagId != null) 'tag_id': tagId,
    };
  }

  static const _PostTagInsertDtoCopyWithSentinel _copyWithSentinel =
      _PostTagInsertDtoCopyWithSentinel();
  PostTagInsertDto copyWith({
    Object? postId = _copyWithSentinel,
    Object? tagId = _copyWithSentinel,
  }) {
    return PostTagInsertDto(
      postId: identical(postId, _copyWithSentinel)
          ? this.postId
          : postId as int?,
      tagId: identical(tagId, _copyWithSentinel) ? this.tagId : tagId as int?,
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
  const PostTagUpdateDto({this.postId, this.tagId});
  final int? postId;
  final int? tagId;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (postId != null) 'post_id': postId,
      if (tagId != null) 'tag_id': tagId,
    };
  }

  static const _PostTagUpdateDtoCopyWithSentinel _copyWithSentinel =
      _PostTagUpdateDtoCopyWithSentinel();
  PostTagUpdateDto copyWith({
    Object? postId = _copyWithSentinel,
    Object? tagId = _copyWithSentinel,
  }) {
    return PostTagUpdateDto(
      postId: identical(postId, _copyWithSentinel)
          ? this.postId
          : postId as int?,
      tagId: identical(tagId, _copyWithSentinel) ? this.tagId : tagId as int?,
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
  const PostTagPartial({this.postId, this.tagId});

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory PostTagPartial.fromRow(Map<String, Object?> row) {
    return PostTagPartial(
      postId: row['post_id'] as int?,
      tagId: row['tag_id'] as int?,
    );
  }

  final int? postId;
  final int? tagId;

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
    return $PostTag(postId: postIdValue, tagId: tagIdValue);
  }

  @override
  Map<String, Object?> toMap() {
    return {
      if (postId != null) 'post_id': postId,
      if (tagId != null) 'tag_id': tagId,
    };
  }

  static const _PostTagPartialCopyWithSentinel _copyWithSentinel =
      _PostTagPartialCopyWithSentinel();
  PostTagPartial copyWith({
    Object? postId = _copyWithSentinel,
    Object? tagId = _copyWithSentinel,
  }) {
    return PostTagPartial(
      postId: identical(postId, _copyWithSentinel)
          ? this.postId
          : postId as int?,
      tagId: identical(tagId, _copyWithSentinel) ? this.tagId : tagId as int?,
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
  $PostTag({required int postId, required int tagId})
    : super.new(postId: postId, tagId: tagId) {
    _attachOrmRuntimeMetadata({'post_id': postId, 'tag_id': tagId});
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $PostTag.fromModel(PostTag model) {
    return $PostTag(postId: model.postId, tagId: model.tagId);
  }

  $PostTag copyWith({int? postId, int? tagId}) {
    return $PostTag(postId: postId ?? this.postId, tagId: tagId ?? this.tagId);
  }

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

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$PostTagDefinition);
  }
}

extension PostTagOrmExtension on PostTag {
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

void registerPostTagEventHandlers(EventBus bus) {
  // No event handlers registered for PostTag.
}
