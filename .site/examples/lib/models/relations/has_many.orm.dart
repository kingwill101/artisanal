// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'has_many.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$UserWithPostsIdField = FieldDefinition(
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

const FieldDefinition _$UserWithPostsPostsField = FieldDefinition(
  name: 'posts',
  columnName: 'posts',
  dartType: 'List<UserPost>',
  resolvedType: 'List<UserPost>?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const RelationDefinition _$UserWithPostsPostsRelation = RelationDefinition(
  name: 'posts',
  kind: RelationKind.hasMany,
  targetModel: 'UserPost',
  foreignKey: 'author_id',
);

Map<String, Object?> _encodeUserWithPostsUntracked(
  Object model,
  ValueCodecRegistry registry,
) {
  final m = model as UserWithPosts;
  return <String, Object?>{
    'id': registry.encodeField(_$UserWithPostsIdField, m.id),
    'posts': registry.encodeField(_$UserWithPostsPostsField, m.posts),
  };
}

final ModelDefinition<$UserWithPosts> _$UserWithPostsDefinition =
    ModelDefinition(
      modelName: 'UserWithPosts',
      tableName: 'users',
      fields: const [_$UserWithPostsIdField, _$UserWithPostsPostsField],
      relations: const [_$UserWithPostsPostsRelation],
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
      untrackedToMap: _encodeUserWithPostsUntracked,
      codec: _$UserWithPostsCodec(),
    );

extension UserWithPostsOrmDefinition on UserWithPosts {
  static ModelDefinition<$UserWithPosts> get definition =>
      _$UserWithPostsDefinition;
}

class UserWithPosts {
  const UserWithPosts._();

  /// Starts building a query for [$UserWithPosts].
  ///
  /// {@macro ormed.query}
  static Query<$UserWithPosts> query([String? connection]) =>
      Model.query<$UserWithPosts>(connection: connection);

  static Future<$UserWithPosts?> find(Object id, {String? connection}) =>
      Model.find<$UserWithPosts>(id, connection: connection);

  static Future<$UserWithPosts> findOrFail(Object id, {String? connection}) =>
      Model.findOrFail<$UserWithPosts>(id, connection: connection);

  static Future<List<$UserWithPosts>> all({String? connection}) =>
      Model.all<$UserWithPosts>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<$UserWithPosts>(connection: connection);

  static Future<bool> anyExist({String? connection}) =>
      Model.anyExist<$UserWithPosts>(connection: connection);

  static Query<$UserWithPosts> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) => Model.where<$UserWithPosts>(
    column,
    operator,
    value,
    connection: connection,
  );

  static Query<$UserWithPosts> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<$UserWithPosts>(column, values, connection: connection);

  static Query<$UserWithPosts> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<$UserWithPosts>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<$UserWithPosts> limit(int count, {String? connection}) =>
      Model.limit<$UserWithPosts>(count, connection: connection);

  /// Creates a [Repository] for [$UserWithPosts].
  ///
  /// {@macro ormed.repository}
  static Repository<$UserWithPosts> repo([String? connection]) =>
      Model.repository<$UserWithPosts>(connection: connection);
}

class UserWithPostsModelFactory {
  const UserWithPostsModelFactory._();

  static ModelDefinition<$UserWithPosts> get definition =>
      _$UserWithPostsDefinition;

  static ModelCodec<$UserWithPosts> get codec => definition.codec;

  static UserWithPosts fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    UserWithPosts model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model.toTracked(), registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<UserWithPosts> withConnection(
    QueryContext context,
  ) => ModelFactoryConnection<UserWithPosts>(
    definition: definition,
    context: context,
  );

  static ModelFactoryBuilder<UserWithPosts> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<UserWithPosts>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$UserWithPostsCodec extends ModelCodec<$UserWithPosts> {
  const _$UserWithPostsCodec();
  @override
  Map<String, Object?> encode(
    $UserWithPosts model,
    ValueCodecRegistry registry,
  ) {
    return <String, Object?>{
      'id': registry.encodeField(_$UserWithPostsIdField, model.id),
      'posts': registry.encodeField(_$UserWithPostsPostsField, model.posts),
    };
  }

  @override
  $UserWithPosts decode(
    Map<String, Object?> data,
    ValueCodecRegistry registry,
  ) {
    final int userWithPostsIdValue =
        registry.decodeField<int>(_$UserWithPostsIdField, data['id']) ??
        (throw StateError('Field id on UserWithPosts cannot be null.'));
    final List<UserPost>? userWithPostsPostsValue = registry
        .decodeField<List<UserPost>?>(_$UserWithPostsPostsField, data['posts']);
    final model = $UserWithPosts(
      id: userWithPostsIdValue,
      posts: userWithPostsPostsValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': userWithPostsIdValue,
      'posts': userWithPostsPostsValue,
    });
    return model;
  }
}

/// Insert DTO for [UserWithPosts].
///
/// Auto-increment/DB-generated fields are omitted by default.
class UserWithPostsInsertDto implements InsertDto<$UserWithPosts> {
  const UserWithPostsInsertDto({this.id, this.posts});
  final int? id;
  final List<UserPost>? posts;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (posts != null) 'posts': posts,
    };
  }

  static const _UserWithPostsInsertDtoCopyWithSentinel _copyWithSentinel =
      _UserWithPostsInsertDtoCopyWithSentinel();
  UserWithPostsInsertDto copyWith({
    Object? id = _copyWithSentinel,
    Object? posts = _copyWithSentinel,
  }) {
    return UserWithPostsInsertDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      posts: identical(posts, _copyWithSentinel)
          ? this.posts
          : posts as List<UserPost>?,
    );
  }
}

class _UserWithPostsInsertDtoCopyWithSentinel {
  const _UserWithPostsInsertDtoCopyWithSentinel();
}

/// Update DTO for [UserWithPosts].
///
/// All fields are optional; only provided entries are used in SET clauses.
class UserWithPostsUpdateDto implements UpdateDto<$UserWithPosts> {
  const UserWithPostsUpdateDto({this.id, this.posts});
  final int? id;
  final List<UserPost>? posts;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (posts != null) 'posts': posts,
    };
  }

  static const _UserWithPostsUpdateDtoCopyWithSentinel _copyWithSentinel =
      _UserWithPostsUpdateDtoCopyWithSentinel();
  UserWithPostsUpdateDto copyWith({
    Object? id = _copyWithSentinel,
    Object? posts = _copyWithSentinel,
  }) {
    return UserWithPostsUpdateDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      posts: identical(posts, _copyWithSentinel)
          ? this.posts
          : posts as List<UserPost>?,
    );
  }
}

class _UserWithPostsUpdateDtoCopyWithSentinel {
  const _UserWithPostsUpdateDtoCopyWithSentinel();
}

/// Partial projection for [UserWithPosts].
///
/// All fields are nullable; intended for subset SELECTs.
class UserWithPostsPartial implements PartialEntity<$UserWithPosts> {
  const UserWithPostsPartial({this.id, this.posts});

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory UserWithPostsPartial.fromRow(Map<String, Object?> row) {
    return UserWithPostsPartial(
      id: row['id'] as int?,
      posts: row['posts'] as List<UserPost>?,
    );
  }

  final int? id;
  final List<UserPost>? posts;

  @override
  $UserWithPosts toEntity() {
    // Basic required-field check: non-nullable fields must be present.
    final int? idValue = id;
    if (idValue == null) {
      throw StateError('Missing required field: id');
    }
    return $UserWithPosts(id: idValue, posts: posts);
  }

  @override
  Map<String, Object?> toMap() {
    return {if (id != null) 'id': id, if (posts != null) 'posts': posts};
  }

  static const _UserWithPostsPartialCopyWithSentinel _copyWithSentinel =
      _UserWithPostsPartialCopyWithSentinel();
  UserWithPostsPartial copyWith({
    Object? id = _copyWithSentinel,
    Object? posts = _copyWithSentinel,
  }) {
    return UserWithPostsPartial(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      posts: identical(posts, _copyWithSentinel)
          ? this.posts
          : posts as List<UserPost>?,
    );
  }
}

class _UserWithPostsPartialCopyWithSentinel {
  const _UserWithPostsPartialCopyWithSentinel();
}

/// Generated tracked model class for [UserWithPosts].
///
/// This class extends the user-defined [UserWithPosts] model and adds
/// attribute tracking, change detection, and relationship management.
/// Instances of this class are returned by queries and repositories.
///
/// **Do not instantiate this class directly.** Use queries, repositories,
/// or model factories to create tracked model instances.
class $UserWithPosts extends UserWithPosts
    with ModelAttributes
    implements OrmEntity {
  /// Internal constructor for [$UserWithPosts].
  $UserWithPosts({required int id, List<UserPost>? posts})
    : super.new(id: id, posts: posts) {
    _attachOrmRuntimeMetadata({'id': id, 'posts': posts});
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $UserWithPosts.fromModel(UserWithPosts model) {
    return $UserWithPosts(id: model.id, posts: model.posts);
  }

  $UserWithPosts copyWith({int? id, List<UserPost>? posts}) {
    return $UserWithPosts(id: id ?? this.id, posts: posts ?? this.posts);
  }

  /// Tracked getter for [id].
  @override
  int get id => getAttribute<int>('id') ?? super.id;

  /// Tracked setter for [id].
  set id(int value) => setAttribute('id', value);

  /// Tracked getter for [posts].
  @override
  List<UserPost>? get posts =>
      getAttribute<List<UserPost>?>('posts') ?? super.posts;

  /// Tracked setter for [posts].
  set posts(List<UserPost>? value) => setAttribute('posts', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$UserWithPostsDefinition);
  }

  @override
  List<UserPost> get posts {
    if (relationLoaded('posts')) {
      return getRelationList<UserPost>('posts');
    }
    return super.posts ?? const [];
  }
}

extension UserWithPostsRelationQueries on UserWithPosts {
  Query<UserPost> postsQuery() {
    return Model.query<UserPost>().where('author_id', getAttribute("null"));
  }
}

extension UserWithPostsOrmExtension on UserWithPosts {
  /// The Type of the generated ORM-managed model class.
  /// Use this when you need to specify the tracked model type explicitly,
  /// for example in generic type parameters.
  static Type get trackedType => $UserWithPosts;

  /// Converts this immutable model to a tracked ORM-managed model.
  /// The tracked model supports attribute tracking, change detection,
  /// and persistence operations like save() and touch().
  $UserWithPosts toTracked() {
    return $UserWithPosts.fromModel(this);
  }
}

extension UserWithPostsPredicateFields on PredicateBuilder<UserWithPosts> {
  PredicateField<UserWithPosts, int> get id =>
      PredicateField<UserWithPosts, int>(this, 'id');
  PredicateField<UserWithPosts, List<UserPost>?> get posts =>
      PredicateField<UserWithPosts, List<UserPost>?>(this, 'posts');
}

extension UserWithPostsTypedRelations on Query<UserWithPosts> {
  Query<UserWithPosts> withPosts([PredicateCallback<UserPost>? constraint]) =>
      withRelationTyped('posts', constraint);
  Query<UserWithPosts> whereHasPosts([
    PredicateCallback<UserPost>? constraint,
  ]) => whereHasTyped('posts', constraint);
  Query<UserWithPosts> orWhereHasPosts([
    PredicateCallback<UserPost>? constraint,
  ]) => orWhereHasTyped('posts', constraint);
}

void registerUserWithPostsEventHandlers(EventBus bus) {
  // No event handlers registered for UserWithPosts.
}

const FieldDefinition _$UserPostIdField = FieldDefinition(
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

const FieldDefinition _$UserPostAuthorIdField = FieldDefinition(
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

const FieldDefinition _$UserPostTitleField = FieldDefinition(
  name: 'title',
  columnName: 'title',
  dartType: 'String',
  resolvedType: 'String',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

Map<String, Object?> _encodeUserPostUntracked(
  Object model,
  ValueCodecRegistry registry,
) {
  final m = model as UserPost;
  return <String, Object?>{
    'id': registry.encodeField(_$UserPostIdField, m.id),
    'author_id': registry.encodeField(_$UserPostAuthorIdField, m.authorId),
    'title': registry.encodeField(_$UserPostTitleField, m.title),
  };
}

final ModelDefinition<$UserPost> _$UserPostDefinition = ModelDefinition(
  modelName: 'UserPost',
  tableName: 'posts',
  fields: const [
    _$UserPostIdField,
    _$UserPostAuthorIdField,
    _$UserPostTitleField,
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
  untrackedToMap: _encodeUserPostUntracked,
  codec: _$UserPostCodec(),
);

extension UserPostOrmDefinition on UserPost {
  static ModelDefinition<$UserPost> get definition => _$UserPostDefinition;
}

class UserPosts {
  const UserPosts._();

  /// Starts building a query for [$UserPost].
  ///
  /// {@macro ormed.query}
  static Query<$UserPost> query([String? connection]) =>
      Model.query<$UserPost>(connection: connection);

  static Future<$UserPost?> find(Object id, {String? connection}) =>
      Model.find<$UserPost>(id, connection: connection);

  static Future<$UserPost> findOrFail(Object id, {String? connection}) =>
      Model.findOrFail<$UserPost>(id, connection: connection);

  static Future<List<$UserPost>> all({String? connection}) =>
      Model.all<$UserPost>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<$UserPost>(connection: connection);

  static Future<bool> anyExist({String? connection}) =>
      Model.anyExist<$UserPost>(connection: connection);

  static Query<$UserPost> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) => Model.where<$UserPost>(column, operator, value, connection: connection);

  static Query<$UserPost> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<$UserPost>(column, values, connection: connection);

  static Query<$UserPost> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<$UserPost>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<$UserPost> limit(int count, {String? connection}) =>
      Model.limit<$UserPost>(count, connection: connection);

  /// Creates a [Repository] for [$UserPost].
  ///
  /// {@macro ormed.repository}
  static Repository<$UserPost> repo([String? connection]) =>
      Model.repository<$UserPost>(connection: connection);
}

class UserPostModelFactory {
  const UserPostModelFactory._();

  static ModelDefinition<$UserPost> get definition => _$UserPostDefinition;

  static ModelCodec<$UserPost> get codec => definition.codec;

  static UserPost fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    UserPost model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model.toTracked(), registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<UserPost> withConnection(
    QueryContext context,
  ) => ModelFactoryConnection<UserPost>(
    definition: definition,
    context: context,
  );

  static ModelFactoryBuilder<UserPost> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<UserPost>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$UserPostCodec extends ModelCodec<$UserPost> {
  const _$UserPostCodec();
  @override
  Map<String, Object?> encode($UserPost model, ValueCodecRegistry registry) {
    return <String, Object?>{
      'id': registry.encodeField(_$UserPostIdField, model.id),
      'author_id': registry.encodeField(
        _$UserPostAuthorIdField,
        model.authorId,
      ),
      'title': registry.encodeField(_$UserPostTitleField, model.title),
    };
  }

  @override
  $UserPost decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final int userPostIdValue =
        registry.decodeField<int>(_$UserPostIdField, data['id']) ??
        (throw StateError('Field id on UserPost cannot be null.'));
    final int userPostAuthorIdValue =
        registry.decodeField<int>(_$UserPostAuthorIdField, data['author_id']) ??
        (throw StateError('Field authorId on UserPost cannot be null.'));
    final String userPostTitleValue =
        registry.decodeField<String>(_$UserPostTitleField, data['title']) ??
        (throw StateError('Field title on UserPost cannot be null.'));
    final model = $UserPost(
      id: userPostIdValue,
      authorId: userPostAuthorIdValue,
      title: userPostTitleValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': userPostIdValue,
      'author_id': userPostAuthorIdValue,
      'title': userPostTitleValue,
    });
    return model;
  }
}

/// Insert DTO for [UserPost].
///
/// Auto-increment/DB-generated fields are omitted by default.
class UserPostInsertDto implements InsertDto<$UserPost> {
  const UserPostInsertDto({this.id, this.authorId, this.title});
  final int? id;
  final int? authorId;
  final String? title;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (authorId != null) 'author_id': authorId,
      if (title != null) 'title': title,
    };
  }

  static const _UserPostInsertDtoCopyWithSentinel _copyWithSentinel =
      _UserPostInsertDtoCopyWithSentinel();
  UserPostInsertDto copyWith({
    Object? id = _copyWithSentinel,
    Object? authorId = _copyWithSentinel,
    Object? title = _copyWithSentinel,
  }) {
    return UserPostInsertDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      authorId: identical(authorId, _copyWithSentinel)
          ? this.authorId
          : authorId as int?,
      title: identical(title, _copyWithSentinel)
          ? this.title
          : title as String?,
    );
  }
}

class _UserPostInsertDtoCopyWithSentinel {
  const _UserPostInsertDtoCopyWithSentinel();
}

/// Update DTO for [UserPost].
///
/// All fields are optional; only provided entries are used in SET clauses.
class UserPostUpdateDto implements UpdateDto<$UserPost> {
  const UserPostUpdateDto({this.id, this.authorId, this.title});
  final int? id;
  final int? authorId;
  final String? title;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (authorId != null) 'author_id': authorId,
      if (title != null) 'title': title,
    };
  }

  static const _UserPostUpdateDtoCopyWithSentinel _copyWithSentinel =
      _UserPostUpdateDtoCopyWithSentinel();
  UserPostUpdateDto copyWith({
    Object? id = _copyWithSentinel,
    Object? authorId = _copyWithSentinel,
    Object? title = _copyWithSentinel,
  }) {
    return UserPostUpdateDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      authorId: identical(authorId, _copyWithSentinel)
          ? this.authorId
          : authorId as int?,
      title: identical(title, _copyWithSentinel)
          ? this.title
          : title as String?,
    );
  }
}

class _UserPostUpdateDtoCopyWithSentinel {
  const _UserPostUpdateDtoCopyWithSentinel();
}

/// Partial projection for [UserPost].
///
/// All fields are nullable; intended for subset SELECTs.
class UserPostPartial implements PartialEntity<$UserPost> {
  const UserPostPartial({this.id, this.authorId, this.title});

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory UserPostPartial.fromRow(Map<String, Object?> row) {
    return UserPostPartial(
      id: row['id'] as int?,
      authorId: row['author_id'] as int?,
      title: row['title'] as String?,
    );
  }

  final int? id;
  final int? authorId;
  final String? title;

  @override
  $UserPost toEntity() {
    // Basic required-field check: non-nullable fields must be present.
    final int? idValue = id;
    if (idValue == null) {
      throw StateError('Missing required field: id');
    }
    final int? authorIdValue = authorId;
    if (authorIdValue == null) {
      throw StateError('Missing required field: authorId');
    }
    final String? titleValue = title;
    if (titleValue == null) {
      throw StateError('Missing required field: title');
    }
    return $UserPost(id: idValue, authorId: authorIdValue, title: titleValue);
  }

  @override
  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      if (authorId != null) 'author_id': authorId,
      if (title != null) 'title': title,
    };
  }

  static const _UserPostPartialCopyWithSentinel _copyWithSentinel =
      _UserPostPartialCopyWithSentinel();
  UserPostPartial copyWith({
    Object? id = _copyWithSentinel,
    Object? authorId = _copyWithSentinel,
    Object? title = _copyWithSentinel,
  }) {
    return UserPostPartial(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      authorId: identical(authorId, _copyWithSentinel)
          ? this.authorId
          : authorId as int?,
      title: identical(title, _copyWithSentinel)
          ? this.title
          : title as String?,
    );
  }
}

class _UserPostPartialCopyWithSentinel {
  const _UserPostPartialCopyWithSentinel();
}

/// Generated tracked model class for [UserPost].
///
/// This class extends the user-defined [UserPost] model and adds
/// attribute tracking, change detection, and relationship management.
/// Instances of this class are returned by queries and repositories.
///
/// **Do not instantiate this class directly.** Use queries, repositories,
/// or model factories to create tracked model instances.
class $UserPost extends UserPost with ModelAttributes implements OrmEntity {
  /// Internal constructor for [$UserPost].
  $UserPost({required int id, required int authorId, required String title})
    : super.new(id: id, authorId: authorId, title: title) {
    _attachOrmRuntimeMetadata({
      'id': id,
      'author_id': authorId,
      'title': title,
    });
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $UserPost.fromModel(UserPost model) {
    return $UserPost(
      id: model.id,
      authorId: model.authorId,
      title: model.title,
    );
  }

  $UserPost copyWith({int? id, int? authorId, String? title}) {
    return $UserPost(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      title: title ?? this.title,
    );
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

  /// Tracked getter for [title].
  @override
  String get title => getAttribute<String>('title') ?? super.title;

  /// Tracked setter for [title].
  set title(String value) => setAttribute('title', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$UserPostDefinition);
  }
}

extension UserPostOrmExtension on UserPost {
  /// The Type of the generated ORM-managed model class.
  /// Use this when you need to specify the tracked model type explicitly,
  /// for example in generic type parameters.
  static Type get trackedType => $UserPost;

  /// Converts this immutable model to a tracked ORM-managed model.
  /// The tracked model supports attribute tracking, change detection,
  /// and persistence operations like save() and touch().
  $UserPost toTracked() {
    return $UserPost.fromModel(this);
  }
}

extension UserPostPredicateFields on PredicateBuilder<UserPost> {
  PredicateField<UserPost, int> get id =>
      PredicateField<UserPost, int>(this, 'id');
  PredicateField<UserPost, int> get authorId =>
      PredicateField<UserPost, int>(this, 'authorId');
  PredicateField<UserPost, String> get title =>
      PredicateField<UserPost, String>(this, 'title');
}

void registerUserPostEventHandlers(EventBus bus) {
  // No event handlers registered for UserPost.
}
