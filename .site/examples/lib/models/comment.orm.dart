// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'comment.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$CommentIdField = FieldDefinition(
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

const FieldDefinition _$CommentBodyField = FieldDefinition(
  name: 'body',
  columnName: 'body',
  dartType: 'String',
  resolvedType: 'String',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$CommentPostIdField = FieldDefinition(
  name: 'postId',
  columnName: 'post_id',
  dartType: 'int',
  resolvedType: 'int?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

Map<String, Object?> _encodeCommentUntracked(
  Object model,
  ValueCodecRegistry registry,
) {
  final m = model as Comment;
  return <String, Object?>{
    'id': registry.encodeField(_$CommentIdField, m.id),
    'body': registry.encodeField(_$CommentBodyField, m.body),
    'post_id': registry.encodeField(_$CommentPostIdField, m.postId),
  };
}

final ModelDefinition<$Comment> _$CommentDefinition = ModelDefinition(
  modelName: 'Comment',
  tableName: 'comments',
  fields: const [_$CommentIdField, _$CommentBodyField, _$CommentPostIdField],
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
  untrackedToMap: _encodeCommentUntracked,
  codec: _$CommentCodec(),
);

extension CommentOrmDefinition on Comment {
  static ModelDefinition<$Comment> get definition => _$CommentDefinition;
}

class Comments {
  const Comments._();

  /// Starts building a query for [$Comment].
  ///
  /// {@macro ormed.query}
  static Query<$Comment> query([String? connection]) =>
      Model.query<$Comment>(connection: connection);

  static Future<$Comment?> find(Object id, {String? connection}) =>
      Model.find<$Comment>(id, connection: connection);

  static Future<$Comment> findOrFail(Object id, {String? connection}) =>
      Model.findOrFail<$Comment>(id, connection: connection);

  static Future<List<$Comment>> all({String? connection}) =>
      Model.all<$Comment>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<$Comment>(connection: connection);

  static Future<bool> anyExist({String? connection}) =>
      Model.anyExist<$Comment>(connection: connection);

  static Query<$Comment> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) => Model.where<$Comment>(column, operator, value, connection: connection);

  static Query<$Comment> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<$Comment>(column, values, connection: connection);

  static Query<$Comment> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<$Comment>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<$Comment> limit(int count, {String? connection}) =>
      Model.limit<$Comment>(count, connection: connection);

  /// Creates a [Repository] for [$Comment].
  ///
  /// {@macro ormed.repository}
  static Repository<$Comment> repo([String? connection]) =>
      Model.repository<$Comment>(connection: connection);
}

class CommentModelFactory {
  const CommentModelFactory._();

  static ModelDefinition<$Comment> get definition => _$CommentDefinition;

  static ModelCodec<$Comment> get codec => definition.codec;

  static Comment fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    Comment model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model.toTracked(), registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<Comment> withConnection(QueryContext context) =>
      ModelFactoryConnection<Comment>(definition: definition, context: context);

  static ModelFactoryBuilder<Comment> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<Comment>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$CommentCodec extends ModelCodec<$Comment> {
  const _$CommentCodec();
  @override
  Map<String, Object?> encode($Comment model, ValueCodecRegistry registry) {
    return <String, Object?>{
      'id': registry.encodeField(_$CommentIdField, model.id),
      'body': registry.encodeField(_$CommentBodyField, model.body),
      'post_id': registry.encodeField(_$CommentPostIdField, model.postId),
    };
  }

  @override
  $Comment decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final int commentIdValue =
        registry.decodeField<int>(_$CommentIdField, data['id']) ?? 0;
    final String commentBodyValue =
        registry.decodeField<String>(_$CommentBodyField, data['body']) ??
        (throw StateError('Field body on Comment cannot be null.'));
    final int? commentPostIdValue = registry.decodeField<int?>(
      _$CommentPostIdField,
      data['post_id'],
    );
    final model = $Comment(
      id: commentIdValue,
      body: commentBodyValue,
      postId: commentPostIdValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': commentIdValue,
      'body': commentBodyValue,
      'post_id': commentPostIdValue,
    });
    return model;
  }
}

/// Insert DTO for [Comment].
///
/// Auto-increment/DB-generated fields are omitted by default.
class CommentInsertDto implements InsertDto<$Comment> {
  const CommentInsertDto({this.body, this.postId});
  final String? body;
  final int? postId;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (body != null) 'body': body,
      if (postId != null) 'post_id': postId,
    };
  }

  static const _CommentInsertDtoCopyWithSentinel _copyWithSentinel =
      _CommentInsertDtoCopyWithSentinel();
  CommentInsertDto copyWith({
    Object? body = _copyWithSentinel,
    Object? postId = _copyWithSentinel,
  }) {
    return CommentInsertDto(
      body: identical(body, _copyWithSentinel) ? this.body : body as String?,
      postId: identical(postId, _copyWithSentinel)
          ? this.postId
          : postId as int?,
    );
  }
}

class _CommentInsertDtoCopyWithSentinel {
  const _CommentInsertDtoCopyWithSentinel();
}

/// Update DTO for [Comment].
///
/// All fields are optional; only provided entries are used in SET clauses.
class CommentUpdateDto implements UpdateDto<$Comment> {
  const CommentUpdateDto({this.id, this.body, this.postId});
  final int? id;
  final String? body;
  final int? postId;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (body != null) 'body': body,
      if (postId != null) 'post_id': postId,
    };
  }

  static const _CommentUpdateDtoCopyWithSentinel _copyWithSentinel =
      _CommentUpdateDtoCopyWithSentinel();
  CommentUpdateDto copyWith({
    Object? id = _copyWithSentinel,
    Object? body = _copyWithSentinel,
    Object? postId = _copyWithSentinel,
  }) {
    return CommentUpdateDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      body: identical(body, _copyWithSentinel) ? this.body : body as String?,
      postId: identical(postId, _copyWithSentinel)
          ? this.postId
          : postId as int?,
    );
  }
}

class _CommentUpdateDtoCopyWithSentinel {
  const _CommentUpdateDtoCopyWithSentinel();
}

/// Partial projection for [Comment].
///
/// All fields are nullable; intended for subset SELECTs.
class CommentPartial implements PartialEntity<$Comment> {
  const CommentPartial({this.id, this.body, this.postId});

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory CommentPartial.fromRow(Map<String, Object?> row) {
    return CommentPartial(
      id: row['id'] as int?,
      body: row['body'] as String?,
      postId: row['post_id'] as int?,
    );
  }

  final int? id;
  final String? body;
  final int? postId;

  @override
  $Comment toEntity() {
    // Basic required-field check: non-nullable fields must be present.
    final int? idValue = id;
    if (idValue == null) {
      throw StateError('Missing required field: id');
    }
    final String? bodyValue = body;
    if (bodyValue == null) {
      throw StateError('Missing required field: body');
    }
    return $Comment(id: idValue, body: bodyValue, postId: postId);
  }

  @override
  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      if (body != null) 'body': body,
      if (postId != null) 'post_id': postId,
    };
  }

  static const _CommentPartialCopyWithSentinel _copyWithSentinel =
      _CommentPartialCopyWithSentinel();
  CommentPartial copyWith({
    Object? id = _copyWithSentinel,
    Object? body = _copyWithSentinel,
    Object? postId = _copyWithSentinel,
  }) {
    return CommentPartial(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      body: identical(body, _copyWithSentinel) ? this.body : body as String?,
      postId: identical(postId, _copyWithSentinel)
          ? this.postId
          : postId as int?,
    );
  }
}

class _CommentPartialCopyWithSentinel {
  const _CommentPartialCopyWithSentinel();
}

/// Generated tracked model class for [Comment].
///
/// This class extends the user-defined [Comment] model and adds
/// attribute tracking, change detection, and relationship management.
/// Instances of this class are returned by queries and repositories.
///
/// **Do not instantiate this class directly.** Use queries, repositories,
/// or model factories to create tracked model instances.
class $Comment extends Comment with ModelAttributes implements OrmEntity {
  /// Internal constructor for [$Comment].
  $Comment({int id = 0, required String body, int? postId})
    : super.new(id: id, body: body, postId: postId) {
    _attachOrmRuntimeMetadata({'id': id, 'body': body, 'post_id': postId});
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $Comment.fromModel(Comment model) {
    return $Comment(id: model.id, body: model.body, postId: model.postId);
  }

  $Comment copyWith({int? id, String? body, int? postId}) {
    return $Comment(
      id: id ?? this.id,
      body: body ?? this.body,
      postId: postId ?? this.postId,
    );
  }

  /// Tracked getter for [id].
  @override
  int get id => getAttribute<int>('id') ?? super.id;

  /// Tracked setter for [id].
  set id(int value) => setAttribute('id', value);

  /// Tracked getter for [body].
  @override
  String get body => getAttribute<String>('body') ?? super.body;

  /// Tracked setter for [body].
  set body(String value) => setAttribute('body', value);

  /// Tracked getter for [postId].
  @override
  int? get postId => getAttribute<int?>('post_id') ?? super.postId;

  /// Tracked setter for [postId].
  set postId(int? value) => setAttribute('post_id', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$CommentDefinition);
  }
}

extension CommentOrmExtension on Comment {
  /// The Type of the generated ORM-managed model class.
  /// Use this when you need to specify the tracked model type explicitly,
  /// for example in generic type parameters.
  static Type get trackedType => $Comment;

  /// Converts this immutable model to a tracked ORM-managed model.
  /// The tracked model supports attribute tracking, change detection,
  /// and persistence operations like save() and touch().
  $Comment toTracked() {
    return $Comment.fromModel(this);
  }
}

extension CommentPredicateFields on PredicateBuilder<Comment> {
  PredicateField<Comment, int> get id =>
      PredicateField<Comment, int>(this, 'id');
  PredicateField<Comment, String> get body =>
      PredicateField<Comment, String>(this, 'body');
  PredicateField<Comment, int?> get postId =>
      PredicateField<Comment, int?>(this, 'postId');
}

void registerCommentEventHandlers(EventBus bus) {
  // No event handlers registered for Comment.
}
