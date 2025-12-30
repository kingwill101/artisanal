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
  resolvedType: 'int?',
  isPrimaryKey: true,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$CommentPostIdField = FieldDefinition(
  name: 'postId',
  columnName: 'post_id',
  dartType: 'int',
  resolvedType: 'int',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$CommentUserIdField = FieldDefinition(
  name: 'userId',
  columnName: 'user_id',
  dartType: 'int',
  resolvedType: 'int?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
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

const FieldDefinition _$CommentCreatedAtField = FieldDefinition(
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

const FieldDefinition _$CommentUpdatedAtField = FieldDefinition(
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

const RelationDefinition _$CommentAuthorRelation = RelationDefinition(
  name: 'author',
  kind: RelationKind.belongsTo,
  targetModel: 'User',
  foreignKey: 'user_id',
  localKey: 'id',
);

Map<String, Object?> _encodeCommentUntracked(
  Object model,
  ValueCodecRegistry registry,
) {
  final m = model as Comment;
  return <String, Object?>{
    'id': registry.encodeField(_$CommentIdField, m.id),
    'post_id': registry.encodeField(_$CommentPostIdField, m.postId),
    'user_id': registry.encodeField(_$CommentUserIdField, m.userId),
    'body': registry.encodeField(_$CommentBodyField, m.body),
    'created_at': registry.encodeField(_$CommentCreatedAtField, m.createdAt),
    'updated_at': registry.encodeField(_$CommentUpdatedAtField, m.updatedAt),
  };
}

final ModelDefinition<$Comment> _$CommentDefinition = ModelDefinition(
  modelName: 'Comment',
  tableName: 'comments',
  fields: const [
    _$CommentIdField,
    _$CommentPostIdField,
    _$CommentUserIdField,
    _$CommentBodyField,
    _$CommentCreatedAtField,
    _$CommentUpdatedAtField,
  ],
  relations: const [_$CommentAuthorRelation],
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

  /// Builds a tracked model from a column/value map.
  static $Comment fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$CommentDefinition.fromMap(data, registry: registry);

  /// Converts a tracked model to a column/value map.
  static Map<String, Object?> toMap(
    $Comment model, {
    ValueCodecRegistry? registry,
  }) => _$CommentDefinition.toMap(model, registry: registry);
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
      'post_id': registry.encodeField(_$CommentPostIdField, model.postId),
      'user_id': registry.encodeField(_$CommentUserIdField, model.userId),
      'body': registry.encodeField(_$CommentBodyField, model.body),
      'created_at': registry.encodeField(
        _$CommentCreatedAtField,
        model.createdAt,
      ),
      'updated_at': registry.encodeField(
        _$CommentUpdatedAtField,
        model.updatedAt,
      ),
    };
  }

  @override
  $Comment decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final int? commentIdValue = registry.decodeField<int?>(
      _$CommentIdField,
      data['id'],
    );
    final int commentPostIdValue =
        registry.decodeField<int>(_$CommentPostIdField, data['post_id']) ??
        (throw StateError('Field postId on Comment cannot be null.'));
    final int? commentUserIdValue = registry.decodeField<int?>(
      _$CommentUserIdField,
      data['user_id'],
    );
    final String commentBodyValue =
        registry.decodeField<String>(_$CommentBodyField, data['body']) ??
        (throw StateError('Field body on Comment cannot be null.'));
    final DateTime? commentCreatedAtValue = registry.decodeField<DateTime?>(
      _$CommentCreatedAtField,
      data['created_at'],
    );
    final DateTime? commentUpdatedAtValue = registry.decodeField<DateTime?>(
      _$CommentUpdatedAtField,
      data['updated_at'],
    );
    final model = $Comment(
      id: commentIdValue,
      postId: commentPostIdValue,
      userId: commentUserIdValue,
      body: commentBodyValue,
      createdAt: commentCreatedAtValue,
      updatedAt: commentUpdatedAtValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': commentIdValue,
      'post_id': commentPostIdValue,
      'user_id': commentUserIdValue,
      'body': commentBodyValue,
      'created_at': commentCreatedAtValue,
      'updated_at': commentUpdatedAtValue,
    });
    return model;
  }
}

/// Insert DTO for [Comment].
///
/// Auto-increment/DB-generated fields are omitted by default.
class CommentInsertDto implements InsertDto<$Comment> {
  const CommentInsertDto({
    this.id,
    this.postId,
    this.userId,
    this.body,
    this.createdAt,
    this.updatedAt,
  });
  final int? id;
  final int? postId;
  final int? userId;
  final String? body;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (postId != null) 'post_id': postId,
      if (userId != null) 'user_id': userId,
      if (body != null) 'body': body,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    };
  }

  static const _CommentInsertDtoCopyWithSentinel _copyWithSentinel =
      _CommentInsertDtoCopyWithSentinel();
  CommentInsertDto copyWith({
    Object? id = _copyWithSentinel,
    Object? postId = _copyWithSentinel,
    Object? userId = _copyWithSentinel,
    Object? body = _copyWithSentinel,
    Object? createdAt = _copyWithSentinel,
    Object? updatedAt = _copyWithSentinel,
  }) {
    return CommentInsertDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      postId: identical(postId, _copyWithSentinel)
          ? this.postId
          : postId as int?,
      userId: identical(userId, _copyWithSentinel)
          ? this.userId
          : userId as int?,
      body: identical(body, _copyWithSentinel) ? this.body : body as String?,
      createdAt: identical(createdAt, _copyWithSentinel)
          ? this.createdAt
          : createdAt as DateTime?,
      updatedAt: identical(updatedAt, _copyWithSentinel)
          ? this.updatedAt
          : updatedAt as DateTime?,
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
  const CommentUpdateDto({
    this.id,
    this.postId,
    this.userId,
    this.body,
    this.createdAt,
    this.updatedAt,
  });
  final int? id;
  final int? postId;
  final int? userId;
  final String? body;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (postId != null) 'post_id': postId,
      if (userId != null) 'user_id': userId,
      if (body != null) 'body': body,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    };
  }

  static const _CommentUpdateDtoCopyWithSentinel _copyWithSentinel =
      _CommentUpdateDtoCopyWithSentinel();
  CommentUpdateDto copyWith({
    Object? id = _copyWithSentinel,
    Object? postId = _copyWithSentinel,
    Object? userId = _copyWithSentinel,
    Object? body = _copyWithSentinel,
    Object? createdAt = _copyWithSentinel,
    Object? updatedAt = _copyWithSentinel,
  }) {
    return CommentUpdateDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      postId: identical(postId, _copyWithSentinel)
          ? this.postId
          : postId as int?,
      userId: identical(userId, _copyWithSentinel)
          ? this.userId
          : userId as int?,
      body: identical(body, _copyWithSentinel) ? this.body : body as String?,
      createdAt: identical(createdAt, _copyWithSentinel)
          ? this.createdAt
          : createdAt as DateTime?,
      updatedAt: identical(updatedAt, _copyWithSentinel)
          ? this.updatedAt
          : updatedAt as DateTime?,
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
  const CommentPartial({
    this.id,
    this.postId,
    this.userId,
    this.body,
    this.createdAt,
    this.updatedAt,
  });

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory CommentPartial.fromRow(Map<String, Object?> row) {
    return CommentPartial(
      id: row['id'] as int?,
      postId: row['post_id'] as int?,
      userId: row['user_id'] as int?,
      body: row['body'] as String?,
      createdAt: row['created_at'] as DateTime?,
      updatedAt: row['updated_at'] as DateTime?,
    );
  }

  final int? id;
  final int? postId;
  final int? userId;
  final String? body;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  @override
  $Comment toEntity() {
    // Basic required-field check: non-nullable fields must be present.
    final int? postIdValue = postId;
    if (postIdValue == null) {
      throw StateError('Missing required field: postId');
    }
    final String? bodyValue = body;
    if (bodyValue == null) {
      throw StateError('Missing required field: body');
    }
    return $Comment(
      id: id,
      postId: postIdValue,
      userId: userId,
      body: bodyValue,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      if (postId != null) 'post_id': postId,
      if (userId != null) 'user_id': userId,
      if (body != null) 'body': body,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    };
  }

  static const _CommentPartialCopyWithSentinel _copyWithSentinel =
      _CommentPartialCopyWithSentinel();
  CommentPartial copyWith({
    Object? id = _copyWithSentinel,
    Object? postId = _copyWithSentinel,
    Object? userId = _copyWithSentinel,
    Object? body = _copyWithSentinel,
    Object? createdAt = _copyWithSentinel,
    Object? updatedAt = _copyWithSentinel,
  }) {
    return CommentPartial(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      postId: identical(postId, _copyWithSentinel)
          ? this.postId
          : postId as int?,
      userId: identical(userId, _copyWithSentinel)
          ? this.userId
          : userId as int?,
      body: identical(body, _copyWithSentinel) ? this.body : body as String?,
      createdAt: identical(createdAt, _copyWithSentinel)
          ? this.createdAt
          : createdAt as DateTime?,
      updatedAt: identical(updatedAt, _copyWithSentinel)
          ? this.updatedAt
          : updatedAt as DateTime?,
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
  $Comment({
    int? id,
    required int postId,
    int? userId,
    required String body,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : super.new(
         id: id,
         postId: postId,
         userId: userId,
         body: body,
         createdAt: createdAt,
         updatedAt: updatedAt,
       ) {
    _attachOrmRuntimeMetadata({
      'id': id,
      'post_id': postId,
      'user_id': userId,
      'body': body,
      'created_at': createdAt,
      'updated_at': updatedAt,
    });
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $Comment.fromModel(Comment model) {
    return $Comment(
      id: model.id,
      postId: model.postId,
      userId: model.userId,
      body: model.body,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );
  }

  $Comment copyWith({
    int? id,
    int? postId,
    int? userId,
    String? body,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return $Comment(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      userId: userId ?? this.userId,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Builds a tracked model from a column/value map.
  static $Comment fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$CommentDefinition.fromMap(data, registry: registry);

  /// Converts this tracked model to a column/value map.
  Map<String, Object?> toMap({ValueCodecRegistry? registry}) =>
      _$CommentDefinition.toMap(this, registry: registry);

  /// Tracked getter for [id].
  @override
  int? get id => getAttribute<int?>('id') ?? super.id;

  /// Tracked setter for [id].
  set id(int? value) => setAttribute('id', value);

  /// Tracked getter for [postId].
  @override
  int get postId => getAttribute<int>('post_id') ?? super.postId;

  /// Tracked setter for [postId].
  set postId(int value) => setAttribute('post_id', value);

  /// Tracked getter for [userId].
  @override
  int? get userId => getAttribute<int?>('user_id') ?? super.userId;

  /// Tracked setter for [userId].
  set userId(int? value) => setAttribute('user_id', value);

  /// Tracked getter for [body].
  @override
  String get body => getAttribute<String>('body') ?? super.body;

  /// Tracked setter for [body].
  set body(String value) => setAttribute('body', value);

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
    attachModelDefinition(_$CommentDefinition);
  }

  @override
  User? get author {
    if (relationLoaded('author')) {
      return getRelation<User>('author');
    }
    return super.author;
  }
}

extension CommentRelationQueries on Comment {
  Query<User> authorQuery() {
    return Model.query<User>().where('id', userId);
  }
}

class _CommentCopyWithSentinel {
  const _CommentCopyWithSentinel();
}

extension CommentOrmExtension on Comment {
  static const _CommentCopyWithSentinel _copyWithSentinel =
      _CommentCopyWithSentinel();
  Comment copyWith({
    Object? id = _copyWithSentinel,
    Object? postId = _copyWithSentinel,
    Object? userId = _copyWithSentinel,
    Object? body = _copyWithSentinel,
    Object? createdAt = _copyWithSentinel,
    Object? updatedAt = _copyWithSentinel,
  }) {
    return Comment.new(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      postId: identical(postId, _copyWithSentinel)
          ? this.postId
          : postId as int,
      userId: identical(userId, _copyWithSentinel)
          ? this.userId
          : userId as int?,
      body: identical(body, _copyWithSentinel) ? this.body : body as String,
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
      _$CommentDefinition.toMap(this, registry: registry);

  /// Builds a model from a column/value map.
  static Comment fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$CommentDefinition.fromMap(data, registry: registry);

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
  PredicateField<Comment, int?> get id =>
      PredicateField<Comment, int?>(this, 'id');
  PredicateField<Comment, int> get postId =>
      PredicateField<Comment, int>(this, 'postId');
  PredicateField<Comment, int?> get userId =>
      PredicateField<Comment, int?>(this, 'userId');
  PredicateField<Comment, String> get body =>
      PredicateField<Comment, String>(this, 'body');
  PredicateField<Comment, DateTime?> get createdAt =>
      PredicateField<Comment, DateTime?>(this, 'createdAt');
  PredicateField<Comment, DateTime?> get updatedAt =>
      PredicateField<Comment, DateTime?>(this, 'updatedAt');
}

extension CommentTypedRelations on Query<Comment> {
  Query<Comment> withAuthor([PredicateCallback<User>? constraint]) =>
      withRelationTyped('author', constraint);
  Query<Comment> whereHasAuthor([PredicateCallback<User>? constraint]) =>
      whereHasTyped('author', constraint);
  Query<Comment> orWhereHasAuthor([PredicateCallback<User>? constraint]) =>
      orWhereHasTyped('author', constraint);
}

void registerCommentEventHandlers(EventBus bus) {
  // No event handlers registered for Comment.
}
