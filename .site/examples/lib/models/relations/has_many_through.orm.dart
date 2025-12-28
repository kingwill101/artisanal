// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'has_many_through.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$AuthorWithCommentsIdField = FieldDefinition(
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

const FieldDefinition _$AuthorWithCommentsCommentsField = FieldDefinition(
  name: 'comments',
  columnName: 'comments',
  dartType: 'List<PostComment>',
  resolvedType: 'List<PostComment>?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const RelationDefinition _$AuthorWithCommentsCommentsRelation =
    RelationDefinition(
      name: 'comments',
      kind: RelationKind.hasManyThrough,
      targetModel: 'PostComment',
      foreignKey: 'post_id',
      localKey: 'id',
      throughModel: 'AuthorPost',
      throughForeignKey: 'author_id',
    );

Map<String, Object?> _encodeAuthorWithCommentsUntracked(
  Object model,
  ValueCodecRegistry registry,
) {
  final m = model as AuthorWithComments;
  return <String, Object?>{
    'id': registry.encodeField(_$AuthorWithCommentsIdField, m.id),
    'comments': registry.encodeField(
      _$AuthorWithCommentsCommentsField,
      m.comments,
    ),
  };
}

final ModelDefinition<$AuthorWithComments> _$AuthorWithCommentsDefinition =
    ModelDefinition(
      modelName: 'AuthorWithComments',
      tableName: 'authors',
      fields: const [
        _$AuthorWithCommentsIdField,
        _$AuthorWithCommentsCommentsField,
      ],
      relations: const [_$AuthorWithCommentsCommentsRelation],
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
      untrackedToMap: _encodeAuthorWithCommentsUntracked,
      codec: _$AuthorWithCommentsCodec(),
    );

extension AuthorWithCommentsOrmDefinition on AuthorWithComments {
  static ModelDefinition<$AuthorWithComments> get definition =>
      _$AuthorWithCommentsDefinition;
}

class AuthorWithComments {
  const AuthorWithComments._();

  /// Starts building a query for [$AuthorWithComments].
  ///
  /// {@macro ormed.query}
  static Query<$AuthorWithComments> query([String? connection]) =>
      Model.query<$AuthorWithComments>(connection: connection);

  static Future<$AuthorWithComments?> find(Object id, {String? connection}) =>
      Model.find<$AuthorWithComments>(id, connection: connection);

  static Future<$AuthorWithComments> findOrFail(
    Object id, {
    String? connection,
  }) => Model.findOrFail<$AuthorWithComments>(id, connection: connection);

  static Future<List<$AuthorWithComments>> all({String? connection}) =>
      Model.all<$AuthorWithComments>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<$AuthorWithComments>(connection: connection);

  static Future<bool> anyExist({String? connection}) =>
      Model.anyExist<$AuthorWithComments>(connection: connection);

  static Query<$AuthorWithComments> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) => Model.where<$AuthorWithComments>(
    column,
    operator,
    value,
    connection: connection,
  );

  static Query<$AuthorWithComments> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<$AuthorWithComments>(
    column,
    values,
    connection: connection,
  );

  static Query<$AuthorWithComments> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<$AuthorWithComments>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<$AuthorWithComments> limit(int count, {String? connection}) =>
      Model.limit<$AuthorWithComments>(count, connection: connection);

  /// Creates a [Repository] for [$AuthorWithComments].
  ///
  /// {@macro ormed.repository}
  static Repository<$AuthorWithComments> repo([String? connection]) =>
      Model.repository<$AuthorWithComments>(connection: connection);
}

class AuthorWithCommentsModelFactory {
  const AuthorWithCommentsModelFactory._();

  static ModelDefinition<$AuthorWithComments> get definition =>
      _$AuthorWithCommentsDefinition;

  static ModelCodec<$AuthorWithComments> get codec => definition.codec;

  static AuthorWithComments fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    AuthorWithComments model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model.toTracked(), registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<AuthorWithComments> withConnection(
    QueryContext context,
  ) => ModelFactoryConnection<AuthorWithComments>(
    definition: definition,
    context: context,
  );

  static ModelFactoryBuilder<AuthorWithComments> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<AuthorWithComments>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$AuthorWithCommentsCodec extends ModelCodec<$AuthorWithComments> {
  const _$AuthorWithCommentsCodec();
  @override
  Map<String, Object?> encode(
    $AuthorWithComments model,
    ValueCodecRegistry registry,
  ) {
    return <String, Object?>{
      'id': registry.encodeField(_$AuthorWithCommentsIdField, model.id),
      'comments': registry.encodeField(
        _$AuthorWithCommentsCommentsField,
        model.comments,
      ),
    };
  }

  @override
  $AuthorWithComments decode(
    Map<String, Object?> data,
    ValueCodecRegistry registry,
  ) {
    final int authorWithCommentsIdValue =
        registry.decodeField<int>(_$AuthorWithCommentsIdField, data['id']) ??
        (throw StateError('Field id on AuthorWithComments cannot be null.'));
    final List<PostComment>? authorWithCommentsCommentsValue = registry
        .decodeField<List<PostComment>?>(
          _$AuthorWithCommentsCommentsField,
          data['comments'],
        );
    final model = $AuthorWithComments(
      id: authorWithCommentsIdValue,
      comments: authorWithCommentsCommentsValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': authorWithCommentsIdValue,
      'comments': authorWithCommentsCommentsValue,
    });
    return model;
  }
}

/// Insert DTO for [AuthorWithComments].
///
/// Auto-increment/DB-generated fields are omitted by default.
class AuthorWithCommentsInsertDto implements InsertDto<$AuthorWithComments> {
  const AuthorWithCommentsInsertDto({this.id, this.comments});
  final int? id;
  final List<PostComment>? comments;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (comments != null) 'comments': comments,
    };
  }

  static const _AuthorWithCommentsInsertDtoCopyWithSentinel _copyWithSentinel =
      _AuthorWithCommentsInsertDtoCopyWithSentinel();
  AuthorWithCommentsInsertDto copyWith({
    Object? id = _copyWithSentinel,
    Object? comments = _copyWithSentinel,
  }) {
    return AuthorWithCommentsInsertDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      comments: identical(comments, _copyWithSentinel)
          ? this.comments
          : comments as List<PostComment>?,
    );
  }
}

class _AuthorWithCommentsInsertDtoCopyWithSentinel {
  const _AuthorWithCommentsInsertDtoCopyWithSentinel();
}

/// Update DTO for [AuthorWithComments].
///
/// All fields are optional; only provided entries are used in SET clauses.
class AuthorWithCommentsUpdateDto implements UpdateDto<$AuthorWithComments> {
  const AuthorWithCommentsUpdateDto({this.id, this.comments});
  final int? id;
  final List<PostComment>? comments;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (comments != null) 'comments': comments,
    };
  }

  static const _AuthorWithCommentsUpdateDtoCopyWithSentinel _copyWithSentinel =
      _AuthorWithCommentsUpdateDtoCopyWithSentinel();
  AuthorWithCommentsUpdateDto copyWith({
    Object? id = _copyWithSentinel,
    Object? comments = _copyWithSentinel,
  }) {
    return AuthorWithCommentsUpdateDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      comments: identical(comments, _copyWithSentinel)
          ? this.comments
          : comments as List<PostComment>?,
    );
  }
}

class _AuthorWithCommentsUpdateDtoCopyWithSentinel {
  const _AuthorWithCommentsUpdateDtoCopyWithSentinel();
}

/// Partial projection for [AuthorWithComments].
///
/// All fields are nullable; intended for subset SELECTs.
class AuthorWithCommentsPartial implements PartialEntity<$AuthorWithComments> {
  const AuthorWithCommentsPartial({this.id, this.comments});

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory AuthorWithCommentsPartial.fromRow(Map<String, Object?> row) {
    return AuthorWithCommentsPartial(
      id: row['id'] as int?,
      comments: row['comments'] as List<PostComment>?,
    );
  }

  final int? id;
  final List<PostComment>? comments;

  @override
  $AuthorWithComments toEntity() {
    // Basic required-field check: non-nullable fields must be present.
    final int? idValue = id;
    if (idValue == null) {
      throw StateError('Missing required field: id');
    }
    return $AuthorWithComments(id: idValue, comments: comments);
  }

  @override
  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      if (comments != null) 'comments': comments,
    };
  }

  static const _AuthorWithCommentsPartialCopyWithSentinel _copyWithSentinel =
      _AuthorWithCommentsPartialCopyWithSentinel();
  AuthorWithCommentsPartial copyWith({
    Object? id = _copyWithSentinel,
    Object? comments = _copyWithSentinel,
  }) {
    return AuthorWithCommentsPartial(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      comments: identical(comments, _copyWithSentinel)
          ? this.comments
          : comments as List<PostComment>?,
    );
  }
}

class _AuthorWithCommentsPartialCopyWithSentinel {
  const _AuthorWithCommentsPartialCopyWithSentinel();
}

/// Generated tracked model class for [AuthorWithComments].
///
/// This class extends the user-defined [AuthorWithComments] model and adds
/// attribute tracking, change detection, and relationship management.
/// Instances of this class are returned by queries and repositories.
///
/// **Do not instantiate this class directly.** Use queries, repositories,
/// or model factories to create tracked model instances.
class $AuthorWithComments extends AuthorWithComments
    with ModelAttributes
    implements OrmEntity {
  /// Internal constructor for [$AuthorWithComments].
  $AuthorWithComments({required int id, List<PostComment>? comments})
    : super.new(id: id, comments: comments) {
    _attachOrmRuntimeMetadata({'id': id, 'comments': comments});
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $AuthorWithComments.fromModel(AuthorWithComments model) {
    return $AuthorWithComments(id: model.id, comments: model.comments);
  }

  $AuthorWithComments copyWith({int? id, List<PostComment>? comments}) {
    return $AuthorWithComments(
      id: id ?? this.id,
      comments: comments ?? this.comments,
    );
  }

  /// Tracked getter for [id].
  @override
  int get id => getAttribute<int>('id') ?? super.id;

  /// Tracked setter for [id].
  set id(int value) => setAttribute('id', value);

  /// Tracked getter for [comments].
  @override
  List<PostComment>? get comments =>
      getAttribute<List<PostComment>?>('comments') ?? super.comments;

  /// Tracked setter for [comments].
  set comments(List<PostComment>? value) => setAttribute('comments', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$AuthorWithCommentsDefinition);
  }

  @override
  List<PostComment> get comments {
    if (relationLoaded('comments')) {
      return getRelationList<PostComment>('comments');
    }
    return super.comments ?? const [];
  }
}

extension AuthorWithCommentsRelationQueries on AuthorWithComments {
  Query<PostComment> commentsQuery() {
    throw UnimplementedError(
      "Relation query generation not supported for RelationKind.hasManyThrough",
    );
  }
}

extension AuthorWithCommentsOrmExtension on AuthorWithComments {
  /// The Type of the generated ORM-managed model class.
  /// Use this when you need to specify the tracked model type explicitly,
  /// for example in generic type parameters.
  static Type get trackedType => $AuthorWithComments;

  /// Converts this immutable model to a tracked ORM-managed model.
  /// The tracked model supports attribute tracking, change detection,
  /// and persistence operations like save() and touch().
  $AuthorWithComments toTracked() {
    return $AuthorWithComments.fromModel(this);
  }
}

extension AuthorWithCommentsPredicateFields
    on PredicateBuilder<AuthorWithComments> {
  PredicateField<AuthorWithComments, int> get id =>
      PredicateField<AuthorWithComments, int>(this, 'id');
  PredicateField<AuthorWithComments, List<PostComment>?> get comments =>
      PredicateField<AuthorWithComments, List<PostComment>?>(this, 'comments');
}

extension AuthorWithCommentsTypedRelations on Query<AuthorWithComments> {
  Query<AuthorWithComments> withComments([
    PredicateCallback<PostComment>? constraint,
  ]) => withRelationTyped('comments', constraint);
  Query<AuthorWithComments> whereHasComments([
    PredicateCallback<PostComment>? constraint,
  ]) => whereHasTyped('comments', constraint);
  Query<AuthorWithComments> orWhereHasComments([
    PredicateCallback<PostComment>? constraint,
  ]) => orWhereHasTyped('comments', constraint);
}

void registerAuthorWithCommentsEventHandlers(EventBus bus) {
  // No event handlers registered for AuthorWithComments.
}

const FieldDefinition _$AuthorPostIdField = FieldDefinition(
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

const FieldDefinition _$AuthorPostAuthorIdField = FieldDefinition(
  name: 'authorId',
  columnName: 'author_id',
  dartType: 'int',
  resolvedType: 'int',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

Map<String, Object?> _encodeAuthorPostUntracked(
  Object model,
  ValueCodecRegistry registry,
) {
  final m = model as AuthorPost;
  return <String, Object?>{
    'id': registry.encodeField(_$AuthorPostIdField, m.id),
    'author_id': registry.encodeField(_$AuthorPostAuthorIdField, m.authorId),
  };
}

final ModelDefinition<$AuthorPost> _$AuthorPostDefinition = ModelDefinition(
  modelName: 'AuthorPost',
  tableName: 'posts',
  fields: const [_$AuthorPostIdField, _$AuthorPostAuthorIdField],
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
  untrackedToMap: _encodeAuthorPostUntracked,
  codec: _$AuthorPostCodec(),
);

extension AuthorPostOrmDefinition on AuthorPost {
  static ModelDefinition<$AuthorPost> get definition => _$AuthorPostDefinition;
}

class AuthorPosts {
  const AuthorPosts._();

  /// Starts building a query for [$AuthorPost].
  ///
  /// {@macro ormed.query}
  static Query<$AuthorPost> query([String? connection]) =>
      Model.query<$AuthorPost>(connection: connection);

  static Future<$AuthorPost?> find(Object id, {String? connection}) =>
      Model.find<$AuthorPost>(id, connection: connection);

  static Future<$AuthorPost> findOrFail(Object id, {String? connection}) =>
      Model.findOrFail<$AuthorPost>(id, connection: connection);

  static Future<List<$AuthorPost>> all({String? connection}) =>
      Model.all<$AuthorPost>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<$AuthorPost>(connection: connection);

  static Future<bool> anyExist({String? connection}) =>
      Model.anyExist<$AuthorPost>(connection: connection);

  static Query<$AuthorPost> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) =>
      Model.where<$AuthorPost>(column, operator, value, connection: connection);

  static Query<$AuthorPost> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<$AuthorPost>(column, values, connection: connection);

  static Query<$AuthorPost> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<$AuthorPost>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<$AuthorPost> limit(int count, {String? connection}) =>
      Model.limit<$AuthorPost>(count, connection: connection);

  /// Creates a [Repository] for [$AuthorPost].
  ///
  /// {@macro ormed.repository}
  static Repository<$AuthorPost> repo([String? connection]) =>
      Model.repository<$AuthorPost>(connection: connection);
}

class AuthorPostModelFactory {
  const AuthorPostModelFactory._();

  static ModelDefinition<$AuthorPost> get definition => _$AuthorPostDefinition;

  static ModelCodec<$AuthorPost> get codec => definition.codec;

  static AuthorPost fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    AuthorPost model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model.toTracked(), registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<AuthorPost> withConnection(
    QueryContext context,
  ) => ModelFactoryConnection<AuthorPost>(
    definition: definition,
    context: context,
  );

  static ModelFactoryBuilder<AuthorPost> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<AuthorPost>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$AuthorPostCodec extends ModelCodec<$AuthorPost> {
  const _$AuthorPostCodec();
  @override
  Map<String, Object?> encode($AuthorPost model, ValueCodecRegistry registry) {
    return <String, Object?>{
      'id': registry.encodeField(_$AuthorPostIdField, model.id),
      'author_id': registry.encodeField(
        _$AuthorPostAuthorIdField,
        model.authorId,
      ),
    };
  }

  @override
  $AuthorPost decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final int authorPostIdValue =
        registry.decodeField<int>(_$AuthorPostIdField, data['id']) ??
        (throw StateError('Field id on AuthorPost cannot be null.'));
    final int authorPostAuthorIdValue =
        registry.decodeField<int>(
          _$AuthorPostAuthorIdField,
          data['author_id'],
        ) ??
        (throw StateError('Field authorId on AuthorPost cannot be null.'));
    final model = $AuthorPost(
      id: authorPostIdValue,
      authorId: authorPostAuthorIdValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': authorPostIdValue,
      'author_id': authorPostAuthorIdValue,
    });
    return model;
  }
}

/// Insert DTO for [AuthorPost].
///
/// Auto-increment/DB-generated fields are omitted by default.
class AuthorPostInsertDto implements InsertDto<$AuthorPost> {
  const AuthorPostInsertDto({this.id, this.authorId});
  final int? id;
  final int? authorId;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (authorId != null) 'author_id': authorId,
    };
  }

  static const _AuthorPostInsertDtoCopyWithSentinel _copyWithSentinel =
      _AuthorPostInsertDtoCopyWithSentinel();
  AuthorPostInsertDto copyWith({
    Object? id = _copyWithSentinel,
    Object? authorId = _copyWithSentinel,
  }) {
    return AuthorPostInsertDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      authorId: identical(authorId, _copyWithSentinel)
          ? this.authorId
          : authorId as int?,
    );
  }
}

class _AuthorPostInsertDtoCopyWithSentinel {
  const _AuthorPostInsertDtoCopyWithSentinel();
}

/// Update DTO for [AuthorPost].
///
/// All fields are optional; only provided entries are used in SET clauses.
class AuthorPostUpdateDto implements UpdateDto<$AuthorPost> {
  const AuthorPostUpdateDto({this.id, this.authorId});
  final int? id;
  final int? authorId;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (authorId != null) 'author_id': authorId,
    };
  }

  static const _AuthorPostUpdateDtoCopyWithSentinel _copyWithSentinel =
      _AuthorPostUpdateDtoCopyWithSentinel();
  AuthorPostUpdateDto copyWith({
    Object? id = _copyWithSentinel,
    Object? authorId = _copyWithSentinel,
  }) {
    return AuthorPostUpdateDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      authorId: identical(authorId, _copyWithSentinel)
          ? this.authorId
          : authorId as int?,
    );
  }
}

class _AuthorPostUpdateDtoCopyWithSentinel {
  const _AuthorPostUpdateDtoCopyWithSentinel();
}

/// Partial projection for [AuthorPost].
///
/// All fields are nullable; intended for subset SELECTs.
class AuthorPostPartial implements PartialEntity<$AuthorPost> {
  const AuthorPostPartial({this.id, this.authorId});

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory AuthorPostPartial.fromRow(Map<String, Object?> row) {
    return AuthorPostPartial(
      id: row['id'] as int?,
      authorId: row['author_id'] as int?,
    );
  }

  final int? id;
  final int? authorId;

  @override
  $AuthorPost toEntity() {
    // Basic required-field check: non-nullable fields must be present.
    final int? idValue = id;
    if (idValue == null) {
      throw StateError('Missing required field: id');
    }
    final int? authorIdValue = authorId;
    if (authorIdValue == null) {
      throw StateError('Missing required field: authorId');
    }
    return $AuthorPost(id: idValue, authorId: authorIdValue);
  }

  @override
  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      if (authorId != null) 'author_id': authorId,
    };
  }

  static const _AuthorPostPartialCopyWithSentinel _copyWithSentinel =
      _AuthorPostPartialCopyWithSentinel();
  AuthorPostPartial copyWith({
    Object? id = _copyWithSentinel,
    Object? authorId = _copyWithSentinel,
  }) {
    return AuthorPostPartial(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      authorId: identical(authorId, _copyWithSentinel)
          ? this.authorId
          : authorId as int?,
    );
  }
}

class _AuthorPostPartialCopyWithSentinel {
  const _AuthorPostPartialCopyWithSentinel();
}

/// Generated tracked model class for [AuthorPost].
///
/// This class extends the user-defined [AuthorPost] model and adds
/// attribute tracking, change detection, and relationship management.
/// Instances of this class are returned by queries and repositories.
///
/// **Do not instantiate this class directly.** Use queries, repositories,
/// or model factories to create tracked model instances.
class $AuthorPost extends AuthorPost with ModelAttributes implements OrmEntity {
  /// Internal constructor for [$AuthorPost].
  $AuthorPost({required int id, required int authorId})
    : super.new(id: id, authorId: authorId) {
    _attachOrmRuntimeMetadata({'id': id, 'author_id': authorId});
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $AuthorPost.fromModel(AuthorPost model) {
    return $AuthorPost(id: model.id, authorId: model.authorId);
  }

  $AuthorPost copyWith({int? id, int? authorId}) {
    return $AuthorPost(id: id ?? this.id, authorId: authorId ?? this.authorId);
  }

  /// Tracked getter for [id].
  @override
  int get id => getAttribute<int>('id') ?? super.id;

  /// Tracked setter for [id].
  set id(int value) => setAttribute('id', value);

  /// Tracked getter for [authorId].
  @override
  int get authorId => getAttribute<int>('author_id') ?? super.authorId;

  /// Tracked setter for [authorId].
  set authorId(int value) => setAttribute('author_id', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$AuthorPostDefinition);
  }
}

extension AuthorPostOrmExtension on AuthorPost {
  /// The Type of the generated ORM-managed model class.
  /// Use this when you need to specify the tracked model type explicitly,
  /// for example in generic type parameters.
  static Type get trackedType => $AuthorPost;

  /// Converts this immutable model to a tracked ORM-managed model.
  /// The tracked model supports attribute tracking, change detection,
  /// and persistence operations like save() and touch().
  $AuthorPost toTracked() {
    return $AuthorPost.fromModel(this);
  }
}

extension AuthorPostPredicateFields on PredicateBuilder<AuthorPost> {
  PredicateField<AuthorPost, int> get id =>
      PredicateField<AuthorPost, int>(this, 'id');
  PredicateField<AuthorPost, int> get authorId =>
      PredicateField<AuthorPost, int>(this, 'authorId');
}

void registerAuthorPostEventHandlers(EventBus bus) {
  // No event handlers registered for AuthorPost.
}

const FieldDefinition _$PostCommentIdField = FieldDefinition(
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

const FieldDefinition _$PostCommentPostIdField = FieldDefinition(
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

const FieldDefinition _$PostCommentBodyField = FieldDefinition(
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

Map<String, Object?> _encodePostCommentUntracked(
  Object model,
  ValueCodecRegistry registry,
) {
  final m = model as PostComment;
  return <String, Object?>{
    'id': registry.encodeField(_$PostCommentIdField, m.id),
    'post_id': registry.encodeField(_$PostCommentPostIdField, m.postId),
    'body': registry.encodeField(_$PostCommentBodyField, m.body),
  };
}

final ModelDefinition<$PostComment> _$PostCommentDefinition = ModelDefinition(
  modelName: 'PostComment',
  tableName: 'comments',
  fields: const [
    _$PostCommentIdField,
    _$PostCommentPostIdField,
    _$PostCommentBodyField,
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
  untrackedToMap: _encodePostCommentUntracked,
  codec: _$PostCommentCodec(),
);

extension PostCommentOrmDefinition on PostComment {
  static ModelDefinition<$PostComment> get definition =>
      _$PostCommentDefinition;
}

class PostComments {
  const PostComments._();

  /// Starts building a query for [$PostComment].
  ///
  /// {@macro ormed.query}
  static Query<$PostComment> query([String? connection]) =>
      Model.query<$PostComment>(connection: connection);

  static Future<$PostComment?> find(Object id, {String? connection}) =>
      Model.find<$PostComment>(id, connection: connection);

  static Future<$PostComment> findOrFail(Object id, {String? connection}) =>
      Model.findOrFail<$PostComment>(id, connection: connection);

  static Future<List<$PostComment>> all({String? connection}) =>
      Model.all<$PostComment>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<$PostComment>(connection: connection);

  static Future<bool> anyExist({String? connection}) =>
      Model.anyExist<$PostComment>(connection: connection);

  static Query<$PostComment> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) => Model.where<$PostComment>(
    column,
    operator,
    value,
    connection: connection,
  );

  static Query<$PostComment> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<$PostComment>(column, values, connection: connection);

  static Query<$PostComment> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<$PostComment>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<$PostComment> limit(int count, {String? connection}) =>
      Model.limit<$PostComment>(count, connection: connection);

  /// Creates a [Repository] for [$PostComment].
  ///
  /// {@macro ormed.repository}
  static Repository<$PostComment> repo([String? connection]) =>
      Model.repository<$PostComment>(connection: connection);
}

class PostCommentModelFactory {
  const PostCommentModelFactory._();

  static ModelDefinition<$PostComment> get definition =>
      _$PostCommentDefinition;

  static ModelCodec<$PostComment> get codec => definition.codec;

  static PostComment fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    PostComment model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model.toTracked(), registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<PostComment> withConnection(
    QueryContext context,
  ) => ModelFactoryConnection<PostComment>(
    definition: definition,
    context: context,
  );

  static ModelFactoryBuilder<PostComment> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<PostComment>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$PostCommentCodec extends ModelCodec<$PostComment> {
  const _$PostCommentCodec();
  @override
  Map<String, Object?> encode($PostComment model, ValueCodecRegistry registry) {
    return <String, Object?>{
      'id': registry.encodeField(_$PostCommentIdField, model.id),
      'post_id': registry.encodeField(_$PostCommentPostIdField, model.postId),
      'body': registry.encodeField(_$PostCommentBodyField, model.body),
    };
  }

  @override
  $PostComment decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final int postCommentIdValue =
        registry.decodeField<int>(_$PostCommentIdField, data['id']) ??
        (throw StateError('Field id on PostComment cannot be null.'));
    final int postCommentPostIdValue =
        registry.decodeField<int>(_$PostCommentPostIdField, data['post_id']) ??
        (throw StateError('Field postId on PostComment cannot be null.'));
    final String postCommentBodyValue =
        registry.decodeField<String>(_$PostCommentBodyField, data['body']) ??
        (throw StateError('Field body on PostComment cannot be null.'));
    final model = $PostComment(
      id: postCommentIdValue,
      postId: postCommentPostIdValue,
      body: postCommentBodyValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': postCommentIdValue,
      'post_id': postCommentPostIdValue,
      'body': postCommentBodyValue,
    });
    return model;
  }
}

/// Insert DTO for [PostComment].
///
/// Auto-increment/DB-generated fields are omitted by default.
class PostCommentInsertDto implements InsertDto<$PostComment> {
  const PostCommentInsertDto({this.id, this.postId, this.body});
  final int? id;
  final int? postId;
  final String? body;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (postId != null) 'post_id': postId,
      if (body != null) 'body': body,
    };
  }

  static const _PostCommentInsertDtoCopyWithSentinel _copyWithSentinel =
      _PostCommentInsertDtoCopyWithSentinel();
  PostCommentInsertDto copyWith({
    Object? id = _copyWithSentinel,
    Object? postId = _copyWithSentinel,
    Object? body = _copyWithSentinel,
  }) {
    return PostCommentInsertDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      postId: identical(postId, _copyWithSentinel)
          ? this.postId
          : postId as int?,
      body: identical(body, _copyWithSentinel) ? this.body : body as String?,
    );
  }
}

class _PostCommentInsertDtoCopyWithSentinel {
  const _PostCommentInsertDtoCopyWithSentinel();
}

/// Update DTO for [PostComment].
///
/// All fields are optional; only provided entries are used in SET clauses.
class PostCommentUpdateDto implements UpdateDto<$PostComment> {
  const PostCommentUpdateDto({this.id, this.postId, this.body});
  final int? id;
  final int? postId;
  final String? body;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (postId != null) 'post_id': postId,
      if (body != null) 'body': body,
    };
  }

  static const _PostCommentUpdateDtoCopyWithSentinel _copyWithSentinel =
      _PostCommentUpdateDtoCopyWithSentinel();
  PostCommentUpdateDto copyWith({
    Object? id = _copyWithSentinel,
    Object? postId = _copyWithSentinel,
    Object? body = _copyWithSentinel,
  }) {
    return PostCommentUpdateDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      postId: identical(postId, _copyWithSentinel)
          ? this.postId
          : postId as int?,
      body: identical(body, _copyWithSentinel) ? this.body : body as String?,
    );
  }
}

class _PostCommentUpdateDtoCopyWithSentinel {
  const _PostCommentUpdateDtoCopyWithSentinel();
}

/// Partial projection for [PostComment].
///
/// All fields are nullable; intended for subset SELECTs.
class PostCommentPartial implements PartialEntity<$PostComment> {
  const PostCommentPartial({this.id, this.postId, this.body});

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory PostCommentPartial.fromRow(Map<String, Object?> row) {
    return PostCommentPartial(
      id: row['id'] as int?,
      postId: row['post_id'] as int?,
      body: row['body'] as String?,
    );
  }

  final int? id;
  final int? postId;
  final String? body;

  @override
  $PostComment toEntity() {
    // Basic required-field check: non-nullable fields must be present.
    final int? idValue = id;
    if (idValue == null) {
      throw StateError('Missing required field: id');
    }
    final int? postIdValue = postId;
    if (postIdValue == null) {
      throw StateError('Missing required field: postId');
    }
    final String? bodyValue = body;
    if (bodyValue == null) {
      throw StateError('Missing required field: body');
    }
    return $PostComment(id: idValue, postId: postIdValue, body: bodyValue);
  }

  @override
  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      if (postId != null) 'post_id': postId,
      if (body != null) 'body': body,
    };
  }

  static const _PostCommentPartialCopyWithSentinel _copyWithSentinel =
      _PostCommentPartialCopyWithSentinel();
  PostCommentPartial copyWith({
    Object? id = _copyWithSentinel,
    Object? postId = _copyWithSentinel,
    Object? body = _copyWithSentinel,
  }) {
    return PostCommentPartial(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      postId: identical(postId, _copyWithSentinel)
          ? this.postId
          : postId as int?,
      body: identical(body, _copyWithSentinel) ? this.body : body as String?,
    );
  }
}

class _PostCommentPartialCopyWithSentinel {
  const _PostCommentPartialCopyWithSentinel();
}

/// Generated tracked model class for [PostComment].
///
/// This class extends the user-defined [PostComment] model and adds
/// attribute tracking, change detection, and relationship management.
/// Instances of this class are returned by queries and repositories.
///
/// **Do not instantiate this class directly.** Use queries, repositories,
/// or model factories to create tracked model instances.
class $PostComment extends PostComment
    with ModelAttributes
    implements OrmEntity {
  /// Internal constructor for [$PostComment].
  $PostComment({required int id, required int postId, required String body})
    : super.new(id: id, postId: postId, body: body) {
    _attachOrmRuntimeMetadata({'id': id, 'post_id': postId, 'body': body});
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $PostComment.fromModel(PostComment model) {
    return $PostComment(id: model.id, postId: model.postId, body: model.body);
  }

  $PostComment copyWith({int? id, int? postId, String? body}) {
    return $PostComment(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      body: body ?? this.body,
    );
  }

  /// Tracked getter for [id].
  @override
  int get id => getAttribute<int>('id') ?? super.id;

  /// Tracked setter for [id].
  set id(int value) => setAttribute('id', value);

  /// Tracked getter for [postId].
  @override
  int get postId => getAttribute<int>('post_id') ?? super.postId;

  /// Tracked setter for [postId].
  set postId(int value) => setAttribute('post_id', value);

  /// Tracked getter for [body].
  @override
  String get body => getAttribute<String>('body') ?? super.body;

  /// Tracked setter for [body].
  set body(String value) => setAttribute('body', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$PostCommentDefinition);
  }
}

extension PostCommentOrmExtension on PostComment {
  /// The Type of the generated ORM-managed model class.
  /// Use this when you need to specify the tracked model type explicitly,
  /// for example in generic type parameters.
  static Type get trackedType => $PostComment;

  /// Converts this immutable model to a tracked ORM-managed model.
  /// The tracked model supports attribute tracking, change detection,
  /// and persistence operations like save() and touch().
  $PostComment toTracked() {
    return $PostComment.fromModel(this);
  }
}

extension PostCommentPredicateFields on PredicateBuilder<PostComment> {
  PredicateField<PostComment, int> get id =>
      PredicateField<PostComment, int>(this, 'id');
  PredicateField<PostComment, int> get postId =>
      PredicateField<PostComment, int>(this, 'postId');
  PredicateField<PostComment, String> get body =>
      PredicateField<PostComment, String>(this, 'body');
}

void registerPostCommentEventHandlers(EventBus bus) {
  // No event handlers registered for PostComment.
}
