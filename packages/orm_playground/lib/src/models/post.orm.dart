// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'post.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$PostIdField = FieldDefinition(
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

const FieldDefinition _$PostUserIdField = FieldDefinition(
  name: 'userId',
  columnName: 'user_id',
  dartType: 'int',
  resolvedType: 'int',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$PostTitleField = FieldDefinition(
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

const FieldDefinition _$PostBodyField = FieldDefinition(
  name: 'body',
  columnName: 'body',
  dartType: 'String',
  resolvedType: 'String?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$PostPublishedField = FieldDefinition(
  name: 'published',
  columnName: 'published',
  dartType: 'bool',
  resolvedType: 'bool',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$PostPublishedAtField = FieldDefinition(
  name: 'publishedAt',
  columnName: 'published_at',
  dartType: 'DateTime',
  resolvedType: 'DateTime?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$PostCreatedAtField = FieldDefinition(
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

const FieldDefinition _$PostUpdatedAtField = FieldDefinition(
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

const RelationDefinition _$PostAuthorRelation = RelationDefinition(
  name: 'author',
  kind: RelationKind.belongsTo,
  targetModel: 'User',
  foreignKey: 'user_id',
  localKey: 'id',
);

const RelationDefinition _$PostTagsRelation = RelationDefinition(
  name: 'tags',
  kind: RelationKind.manyToMany,
  targetModel: 'Tag',
  through: 'post_tags',
  pivotForeignKey: 'post_id',
  pivotRelatedKey: 'tag_id',
);

const RelationDefinition _$PostCommentsRelation = RelationDefinition(
  name: 'comments',
  kind: RelationKind.hasMany,
  targetModel: 'Comment',
  foreignKey: 'post_id',
  localKey: 'id',
);

Map<String, Object?> _encodePostUntracked(
  Object model,
  ValueCodecRegistry registry,
) {
  final m = model as Post;
  return <String, Object?>{
    'id': registry.encodeField(_$PostIdField, m.id),
    'user_id': registry.encodeField(_$PostUserIdField, m.userId),
    'title': registry.encodeField(_$PostTitleField, m.title),
    'body': registry.encodeField(_$PostBodyField, m.body),
    'published': registry.encodeField(_$PostPublishedField, m.published),
    'published_at': registry.encodeField(_$PostPublishedAtField, m.publishedAt),
    'created_at': registry.encodeField(_$PostCreatedAtField, m.createdAt),
    'updated_at': registry.encodeField(_$PostUpdatedAtField, m.updatedAt),
  };
}

final ModelDefinition<$Post> _$PostDefinition = ModelDefinition(
  modelName: 'Post',
  tableName: 'posts',
  fields: const [
    _$PostIdField,
    _$PostUserIdField,
    _$PostTitleField,
    _$PostBodyField,
    _$PostPublishedField,
    _$PostPublishedAtField,
    _$PostCreatedAtField,
    _$PostUpdatedAtField,
  ],
  relations: const [
    _$PostAuthorRelation,
    _$PostTagsRelation,
    _$PostCommentsRelation,
  ],
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
  untrackedToMap: _encodePostUntracked,
  codec: _$PostCodec(),
);

extension PostOrmDefinition on Post {
  static ModelDefinition<$Post> get definition => _$PostDefinition;
}

class Posts {
  const Posts._();

  /// Starts building a query for [$Post].
  ///
  /// {@macro ormed.query}
  static Query<$Post> query([String? connection]) =>
      Model.query<$Post>(connection: connection);

  static Future<$Post?> find(Object id, {String? connection}) =>
      Model.find<$Post>(id, connection: connection);

  static Future<$Post> findOrFail(Object id, {String? connection}) =>
      Model.findOrFail<$Post>(id, connection: connection);

  static Future<List<$Post>> all({String? connection}) =>
      Model.all<$Post>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<$Post>(connection: connection);

  static Future<bool> anyExist({String? connection}) =>
      Model.anyExist<$Post>(connection: connection);

  static Query<$Post> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) => Model.where<$Post>(column, operator, value, connection: connection);

  static Query<$Post> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<$Post>(column, values, connection: connection);

  static Query<$Post> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<$Post>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<$Post> limit(int count, {String? connection}) =>
      Model.limit<$Post>(count, connection: connection);

  /// Creates a [Repository] for [$Post].
  ///
  /// {@macro ormed.repository}
  static Repository<$Post> repo([String? connection]) =>
      Model.repository<$Post>(connection: connection);

  /// Builds a tracked model from a column/value map.
  static $Post fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$PostDefinition.fromMap(data, registry: registry);

  /// Converts a tracked model to a column/value map.
  static Map<String, Object?> toMap(
    $Post model, {
    ValueCodecRegistry? registry,
  }) => _$PostDefinition.toMap(model, registry: registry);
}

class PostModelFactory {
  const PostModelFactory._();

  static ModelDefinition<$Post> get definition => _$PostDefinition;

  static ModelCodec<$Post> get codec => definition.codec;

  static Post fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    Post model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model.toTracked(), registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<Post> withConnection(QueryContext context) =>
      ModelFactoryConnection<Post>(definition: definition, context: context);

  static ModelFactoryBuilder<Post> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<Post>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$PostCodec extends ModelCodec<$Post> {
  const _$PostCodec();
  @override
  Map<String, Object?> encode($Post model, ValueCodecRegistry registry) {
    return <String, Object?>{
      'id': registry.encodeField(_$PostIdField, model.id),
      'user_id': registry.encodeField(_$PostUserIdField, model.userId),
      'title': registry.encodeField(_$PostTitleField, model.title),
      'body': registry.encodeField(_$PostBodyField, model.body),
      'published': registry.encodeField(_$PostPublishedField, model.published),
      'published_at': registry.encodeField(
        _$PostPublishedAtField,
        model.publishedAt,
      ),
      'created_at': registry.encodeField(_$PostCreatedAtField, model.createdAt),
      'updated_at': registry.encodeField(_$PostUpdatedAtField, model.updatedAt),
    };
  }

  @override
  $Post decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final int? postIdValue = registry.decodeField<int?>(
      _$PostIdField,
      data['id'],
    );
    final int postUserIdValue =
        registry.decodeField<int>(_$PostUserIdField, data['user_id']) ??
        (throw StateError('Field userId on Post cannot be null.'));
    final String postTitleValue =
        registry.decodeField<String>(_$PostTitleField, data['title']) ??
        (throw StateError('Field title on Post cannot be null.'));
    final String? postBodyValue = registry.decodeField<String?>(
      _$PostBodyField,
      data['body'],
    );
    final bool postPublishedValue =
        registry.decodeField<bool>(_$PostPublishedField, data['published']) ??
        (throw StateError('Field published on Post cannot be null.'));
    final DateTime? postPublishedAtValue = registry.decodeField<DateTime?>(
      _$PostPublishedAtField,
      data['published_at'],
    );
    final DateTime? postCreatedAtValue = registry.decodeField<DateTime?>(
      _$PostCreatedAtField,
      data['created_at'],
    );
    final DateTime? postUpdatedAtValue = registry.decodeField<DateTime?>(
      _$PostUpdatedAtField,
      data['updated_at'],
    );
    final model = $Post(
      id: postIdValue,
      userId: postUserIdValue,
      title: postTitleValue,
      body: postBodyValue,
      published: postPublishedValue,
      publishedAt: postPublishedAtValue,
      createdAt: postCreatedAtValue,
      updatedAt: postUpdatedAtValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': postIdValue,
      'user_id': postUserIdValue,
      'title': postTitleValue,
      'body': postBodyValue,
      'published': postPublishedValue,
      'published_at': postPublishedAtValue,
      'created_at': postCreatedAtValue,
      'updated_at': postUpdatedAtValue,
    });
    return model;
  }
}

/// Insert DTO for [Post].
///
/// Auto-increment/DB-generated fields are omitted by default.
class PostInsertDto implements InsertDto<$Post> {
  const PostInsertDto({
    this.id,
    this.userId,
    this.title,
    this.body,
    this.published,
    this.publishedAt,
    this.createdAt,
    this.updatedAt,
  });
  final int? id;
  final int? userId;
  final String? title;
  final String? body;
  final bool? published;
  final DateTime? publishedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (published != null) 'published': published,
      if (publishedAt != null) 'published_at': publishedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    };
  }

  static const _PostInsertDtoCopyWithSentinel _copyWithSentinel =
      _PostInsertDtoCopyWithSentinel();
  PostInsertDto copyWith({
    Object? id = _copyWithSentinel,
    Object? userId = _copyWithSentinel,
    Object? title = _copyWithSentinel,
    Object? body = _copyWithSentinel,
    Object? published = _copyWithSentinel,
    Object? publishedAt = _copyWithSentinel,
    Object? createdAt = _copyWithSentinel,
    Object? updatedAt = _copyWithSentinel,
  }) {
    return PostInsertDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      userId: identical(userId, _copyWithSentinel)
          ? this.userId
          : userId as int?,
      title: identical(title, _copyWithSentinel)
          ? this.title
          : title as String?,
      body: identical(body, _copyWithSentinel) ? this.body : body as String?,
      published: identical(published, _copyWithSentinel)
          ? this.published
          : published as bool?,
      publishedAt: identical(publishedAt, _copyWithSentinel)
          ? this.publishedAt
          : publishedAt as DateTime?,
      createdAt: identical(createdAt, _copyWithSentinel)
          ? this.createdAt
          : createdAt as DateTime?,
      updatedAt: identical(updatedAt, _copyWithSentinel)
          ? this.updatedAt
          : updatedAt as DateTime?,
    );
  }
}

class _PostInsertDtoCopyWithSentinel {
  const _PostInsertDtoCopyWithSentinel();
}

/// Update DTO for [Post].
///
/// All fields are optional; only provided entries are used in SET clauses.
class PostUpdateDto implements UpdateDto<$Post> {
  const PostUpdateDto({
    this.id,
    this.userId,
    this.title,
    this.body,
    this.published,
    this.publishedAt,
    this.createdAt,
    this.updatedAt,
  });
  final int? id;
  final int? userId;
  final String? title;
  final String? body;
  final bool? published;
  final DateTime? publishedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (published != null) 'published': published,
      if (publishedAt != null) 'published_at': publishedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    };
  }

  static const _PostUpdateDtoCopyWithSentinel _copyWithSentinel =
      _PostUpdateDtoCopyWithSentinel();
  PostUpdateDto copyWith({
    Object? id = _copyWithSentinel,
    Object? userId = _copyWithSentinel,
    Object? title = _copyWithSentinel,
    Object? body = _copyWithSentinel,
    Object? published = _copyWithSentinel,
    Object? publishedAt = _copyWithSentinel,
    Object? createdAt = _copyWithSentinel,
    Object? updatedAt = _copyWithSentinel,
  }) {
    return PostUpdateDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      userId: identical(userId, _copyWithSentinel)
          ? this.userId
          : userId as int?,
      title: identical(title, _copyWithSentinel)
          ? this.title
          : title as String?,
      body: identical(body, _copyWithSentinel) ? this.body : body as String?,
      published: identical(published, _copyWithSentinel)
          ? this.published
          : published as bool?,
      publishedAt: identical(publishedAt, _copyWithSentinel)
          ? this.publishedAt
          : publishedAt as DateTime?,
      createdAt: identical(createdAt, _copyWithSentinel)
          ? this.createdAt
          : createdAt as DateTime?,
      updatedAt: identical(updatedAt, _copyWithSentinel)
          ? this.updatedAt
          : updatedAt as DateTime?,
    );
  }
}

class _PostUpdateDtoCopyWithSentinel {
  const _PostUpdateDtoCopyWithSentinel();
}

/// Partial projection for [Post].
///
/// All fields are nullable; intended for subset SELECTs.
class PostPartial implements PartialEntity<$Post> {
  const PostPartial({
    this.id,
    this.userId,
    this.title,
    this.body,
    this.published,
    this.publishedAt,
    this.createdAt,
    this.updatedAt,
  });

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory PostPartial.fromRow(Map<String, Object?> row) {
    return PostPartial(
      id: row['id'] as int?,
      userId: row['user_id'] as int?,
      title: row['title'] as String?,
      body: row['body'] as String?,
      published: row['published'] as bool?,
      publishedAt: row['published_at'] as DateTime?,
      createdAt: row['created_at'] as DateTime?,
      updatedAt: row['updated_at'] as DateTime?,
    );
  }

  final int? id;
  final int? userId;
  final String? title;
  final String? body;
  final bool? published;
  final DateTime? publishedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  @override
  $Post toEntity() {
    // Basic required-field check: non-nullable fields must be present.
    final int? userIdValue = userId;
    if (userIdValue == null) {
      throw StateError('Missing required field: userId');
    }
    final String? titleValue = title;
    if (titleValue == null) {
      throw StateError('Missing required field: title');
    }
    final bool? publishedValue = published;
    if (publishedValue == null) {
      throw StateError('Missing required field: published');
    }
    return $Post(
      id: id,
      userId: userIdValue,
      title: titleValue,
      body: body,
      published: publishedValue,
      publishedAt: publishedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (published != null) 'published': published,
      if (publishedAt != null) 'published_at': publishedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    };
  }

  static const _PostPartialCopyWithSentinel _copyWithSentinel =
      _PostPartialCopyWithSentinel();
  PostPartial copyWith({
    Object? id = _copyWithSentinel,
    Object? userId = _copyWithSentinel,
    Object? title = _copyWithSentinel,
    Object? body = _copyWithSentinel,
    Object? published = _copyWithSentinel,
    Object? publishedAt = _copyWithSentinel,
    Object? createdAt = _copyWithSentinel,
    Object? updatedAt = _copyWithSentinel,
  }) {
    return PostPartial(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      userId: identical(userId, _copyWithSentinel)
          ? this.userId
          : userId as int?,
      title: identical(title, _copyWithSentinel)
          ? this.title
          : title as String?,
      body: identical(body, _copyWithSentinel) ? this.body : body as String?,
      published: identical(published, _copyWithSentinel)
          ? this.published
          : published as bool?,
      publishedAt: identical(publishedAt, _copyWithSentinel)
          ? this.publishedAt
          : publishedAt as DateTime?,
      createdAt: identical(createdAt, _copyWithSentinel)
          ? this.createdAt
          : createdAt as DateTime?,
      updatedAt: identical(updatedAt, _copyWithSentinel)
          ? this.updatedAt
          : updatedAt as DateTime?,
    );
  }
}

class _PostPartialCopyWithSentinel {
  const _PostPartialCopyWithSentinel();
}

/// Generated tracked model class for [Post].
///
/// This class extends the user-defined [Post] model and adds
/// attribute tracking, change detection, and relationship management.
/// Instances of this class are returned by queries and repositories.
///
/// **Do not instantiate this class directly.** Use queries, repositories,
/// or model factories to create tracked model instances.
class $Post extends Post with ModelAttributes implements OrmEntity {
  /// Internal constructor for [$Post].
  $Post({
    int? id,
    required int userId,
    required String title,
    String? body,
    required bool published,
    DateTime? publishedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : super.new(
         id: id,
         userId: userId,
         title: title,
         body: body,
         published: published,
         publishedAt: publishedAt,
         createdAt: createdAt,
         updatedAt: updatedAt,
       ) {
    _attachOrmRuntimeMetadata({
      'id': id,
      'user_id': userId,
      'title': title,
      'body': body,
      'published': published,
      'published_at': publishedAt,
      'created_at': createdAt,
      'updated_at': updatedAt,
    });
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $Post.fromModel(Post model) {
    return $Post(
      id: model.id,
      userId: model.userId,
      title: model.title,
      body: model.body,
      published: model.published,
      publishedAt: model.publishedAt,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );
  }

  $Post copyWith({
    int? id,
    int? userId,
    String? title,
    String? body,
    bool? published,
    DateTime? publishedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return $Post(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      published: published ?? this.published,
      publishedAt: publishedAt ?? this.publishedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Builds a tracked model from a column/value map.
  static $Post fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$PostDefinition.fromMap(data, registry: registry);

  /// Converts this tracked model to a column/value map.
  Map<String, Object?> toMap({ValueCodecRegistry? registry}) =>
      _$PostDefinition.toMap(this, registry: registry);

  /// Tracked getter for [id].
  @override
  int? get id => getAttribute<int?>('id') ?? super.id;

  /// Tracked setter for [id].
  set id(int? value) => setAttribute('id', value);

  /// Tracked getter for [userId].
  @override
  int get userId => getAttribute<int>('user_id') ?? super.userId;

  /// Tracked setter for [userId].
  set userId(int value) => setAttribute('user_id', value);

  /// Tracked getter for [title].
  @override
  String get title => getAttribute<String>('title') ?? super.title;

  /// Tracked setter for [title].
  set title(String value) => setAttribute('title', value);

  /// Tracked getter for [body].
  @override
  String? get body => getAttribute<String?>('body') ?? super.body;

  /// Tracked setter for [body].
  set body(String? value) => setAttribute('body', value);

  /// Tracked getter for [published].
  @override
  bool get published => getAttribute<bool>('published') ?? super.published;

  /// Tracked setter for [published].
  set published(bool value) => setAttribute('published', value);

  /// Tracked getter for [publishedAt].
  @override
  DateTime? get publishedAt =>
      getAttribute<DateTime?>('published_at') ?? super.publishedAt;

  /// Tracked setter for [publishedAt].
  set publishedAt(DateTime? value) => setAttribute('published_at', value);

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
    attachModelDefinition(_$PostDefinition);
  }

  @override
  User? get author {
    if (relationLoaded('author')) {
      return getRelation<User>('author');
    }
    return super.author;
  }

  @override
  List<Tag> get tags {
    if (relationLoaded('tags')) {
      return getRelationList<Tag>('tags');
    }
    return super.tags;
  }

  @override
  List<Comment> get comments {
    if (relationLoaded('comments')) {
      return getRelationList<Comment>('comments');
    }
    return super.comments;
  }
}

extension PostRelationQueries on Post {
  Query<User> authorQuery() {
    return Model.query<User>().where('id', userId);
  }

  Query<Tag> tagsQuery() {
    final query = Model.query<Tag>();
    final targetTable = query.definition.tableName;
    final targetKey = query.definition.primaryKeyField?.columnName ?? 'id';
    return query
        .join('post_tags', '$targetTable.$targetKey', '=', 'post_tags.tag_id')
        .where('post_tags.post_id', id);
  }

  Query<Comment> commentsQuery() {
    return Model.query<Comment>().where('post_id', id);
  }
}

class _PostCopyWithSentinel {
  const _PostCopyWithSentinel();
}

extension PostOrmExtension on Post {
  static const _PostCopyWithSentinel _copyWithSentinel =
      _PostCopyWithSentinel();
  Post copyWith({
    Object? id = _copyWithSentinel,
    Object? userId = _copyWithSentinel,
    Object? title = _copyWithSentinel,
    Object? body = _copyWithSentinel,
    Object? published = _copyWithSentinel,
    Object? publishedAt = _copyWithSentinel,
    Object? createdAt = _copyWithSentinel,
    Object? updatedAt = _copyWithSentinel,
  }) {
    return Post.new(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      userId: identical(userId, _copyWithSentinel)
          ? this.userId
          : userId as int,
      title: identical(title, _copyWithSentinel) ? this.title : title as String,
      body: identical(body, _copyWithSentinel) ? this.body : body as String?,
      published: identical(published, _copyWithSentinel)
          ? this.published
          : published as bool,
      publishedAt: identical(publishedAt, _copyWithSentinel)
          ? this.publishedAt
          : publishedAt as DateTime?,
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
      _$PostDefinition.toMap(this, registry: registry);

  /// Builds a model from a column/value map.
  static Post fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$PostDefinition.fromMap(data, registry: registry);

  /// The Type of the generated ORM-managed model class.
  /// Use this when you need to specify the tracked model type explicitly,
  /// for example in generic type parameters.
  static Type get trackedType => $Post;

  /// Converts this immutable model to a tracked ORM-managed model.
  /// The tracked model supports attribute tracking, change detection,
  /// and persistence operations like save() and touch().
  $Post toTracked() {
    return $Post.fromModel(this);
  }
}

extension PostPredicateFields on PredicateBuilder<Post> {
  PredicateField<Post, int?> get id => PredicateField<Post, int?>(this, 'id');
  PredicateField<Post, int> get userId =>
      PredicateField<Post, int>(this, 'userId');
  PredicateField<Post, String> get title =>
      PredicateField<Post, String>(this, 'title');
  PredicateField<Post, String?> get body =>
      PredicateField<Post, String?>(this, 'body');
  PredicateField<Post, bool> get published =>
      PredicateField<Post, bool>(this, 'published');
  PredicateField<Post, DateTime?> get publishedAt =>
      PredicateField<Post, DateTime?>(this, 'publishedAt');
  PredicateField<Post, DateTime?> get createdAt =>
      PredicateField<Post, DateTime?>(this, 'createdAt');
  PredicateField<Post, DateTime?> get updatedAt =>
      PredicateField<Post, DateTime?>(this, 'updatedAt');
}

extension PostTypedRelations on Query<Post> {
  Query<Post> withAuthor([PredicateCallback<User>? constraint]) =>
      withRelationTyped('author', constraint);
  Query<Post> whereHasAuthor([PredicateCallback<User>? constraint]) =>
      whereHasTyped('author', constraint);
  Query<Post> orWhereHasAuthor([PredicateCallback<User>? constraint]) =>
      orWhereHasTyped('author', constraint);
  Query<Post> withTags([PredicateCallback<Tag>? constraint]) =>
      withRelationTyped('tags', constraint);
  Query<Post> whereHasTags([PredicateCallback<Tag>? constraint]) =>
      whereHasTyped('tags', constraint);
  Query<Post> orWhereHasTags([PredicateCallback<Tag>? constraint]) =>
      orWhereHasTyped('tags', constraint);
  Query<Post> withComments([PredicateCallback<Comment>? constraint]) =>
      withRelationTyped('comments', constraint);
  Query<Post> whereHasComments([PredicateCallback<Comment>? constraint]) =>
      whereHasTyped('comments', constraint);
  Query<Post> orWhereHasComments([PredicateCallback<Comment>? constraint]) =>
      orWhereHasTyped('comments', constraint);
}

void registerPostEventHandlers(EventBus bus) {
  // No event handlers registered for Post.
}
