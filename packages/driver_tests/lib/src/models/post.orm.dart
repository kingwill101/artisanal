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
  resolvedType: 'int',
  isPrimaryKey: true,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: true,
);

const FieldDefinition _$PostAuthorIdField = FieldDefinition(
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

const FieldDefinition _$PostContentField = FieldDefinition(
  name: 'content',
  columnName: 'content',
  dartType: 'String',
  resolvedType: 'String?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$PostViewsField = FieldDefinition(
  name: 'views',
  columnName: 'views',
  dartType: 'int',
  resolvedType: 'int?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$PostPublishedAtField = FieldDefinition(
  name: 'publishedAt',
  columnName: 'published_at',
  dartType: 'DateTime',
  resolvedType: 'DateTime',
  isPrimaryKey: false,
  isNullable: false,
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
  targetModel: 'Author',
  foreignKey: 'author_id',
  localKey: 'id',
);

const RelationDefinition _$PostTagsRelation = RelationDefinition(
  name: 'tags',
  kind: RelationKind.manyToMany,
  targetModel: 'Tag',
  through: 'post_tags',
  pivotForeignKey: 'post_id',
  pivotRelatedKey: 'tag_id',
  pivotColumns: <String>['sort_order', 'note'],
  pivotTimestamps: true,
  pivotModel: 'PostTag',
);

const RelationDefinition _$PostMorphTagsRelation = RelationDefinition(
  name: 'morphTags',
  kind: RelationKind.morphToMany,
  targetModel: 'Tag',
  through: 'taggables',
  pivotForeignKey: 'taggable_id',
  pivotRelatedKey: 'tag_id',
  morphType: 'taggable_type',
  morphClass: 'Post',
);

const RelationDefinition _$PostPhotosRelation = RelationDefinition(
  name: 'photos',
  kind: RelationKind.morphMany,
  targetModel: 'Photo',
  foreignKey: 'imageable_id',
  morphType: 'imageable_type',
  morphClass: 'Post',
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
    'author_id': registry.encodeField(_$PostAuthorIdField, m.authorId),
    'title': registry.encodeField(_$PostTitleField, m.title),
    'content': registry.encodeField(_$PostContentField, m.content),
    'views': registry.encodeField(_$PostViewsField, m.views),
    'published_at': registry.encodeField(_$PostPublishedAtField, m.publishedAt),
  };
}

final ModelDefinition<$Post> _$PostDefinition = ModelDefinition(
  modelName: 'Post',
  tableName: 'posts',
  fields: const [
    _$PostIdField,
    _$PostAuthorIdField,
    _$PostTitleField,
    _$PostContentField,
    _$PostViewsField,
    _$PostPublishedAtField,
    _$PostCreatedAtField,
    _$PostUpdatedAtField,
  ],
  relations: const [
    _$PostAuthorRelation,
    _$PostTagsRelation,
    _$PostMorphTagsRelation,
    _$PostPhotosRelation,
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
    touches: const <String>['author', 'tags'],
    timestamps: true,
    softDeletes: false,
    softDeleteColumn: 'deleted_at',
  ),
  untrackedToMap: _encodePostUntracked,
  codec: _$PostCodec(),
);

// ignore: unused_element
final postModelDefinitionRegistration = ModelFactoryRegistry.register<$Post>(
  _$PostDefinition,
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
      'author_id': registry.encodeField(_$PostAuthorIdField, model.authorId),
      'title': registry.encodeField(_$PostTitleField, model.title),
      'content': registry.encodeField(_$PostContentField, model.content),
      'views': registry.encodeField(_$PostViewsField, model.views),
      'published_at': registry.encodeField(
        _$PostPublishedAtField,
        model.publishedAt,
      ),
      'created_at': registry.encodeField(
        _$PostCreatedAtField,
        model.getAttribute<DateTime?>('created_at'),
      ),
      'updated_at': registry.encodeField(
        _$PostUpdatedAtField,
        model.getAttribute<DateTime?>('updated_at'),
      ),
    };
  }

  @override
  $Post decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final int postIdValue =
        registry.decodeField<int>(_$PostIdField, data['id']) ?? 0;
    final int postAuthorIdValue =
        registry.decodeField<int>(_$PostAuthorIdField, data['author_id']) ??
        (throw StateError('Field authorId on Post cannot be null.'));
    final String postTitleValue =
        registry.decodeField<String>(_$PostTitleField, data['title']) ??
        (throw StateError('Field title on Post cannot be null.'));
    final String? postContentValue = registry.decodeField<String?>(
      _$PostContentField,
      data['content'],
    );
    final int? postViewsValue = registry.decodeField<int?>(
      _$PostViewsField,
      data['views'],
    );
    final DateTime postPublishedAtValue =
        registry.decodeField<DateTime>(
          _$PostPublishedAtField,
          data['published_at'],
        ) ??
        (throw StateError('Field publishedAt on Post cannot be null.'));
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
      authorId: postAuthorIdValue,
      title: postTitleValue,
      publishedAt: postPublishedAtValue,
      content: postContentValue,
      views: postViewsValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': postIdValue,
      'author_id': postAuthorIdValue,
      'title': postTitleValue,
      'content': postContentValue,
      'views': postViewsValue,
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
    this.authorId,
    this.title,
    this.content,
    this.views,
    this.publishedAt,
  });
  final int? authorId;
  final String? title;
  final String? content;
  final int? views;
  final DateTime? publishedAt;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (authorId != null) 'author_id': authorId,
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (views != null) 'views': views,
      if (publishedAt != null) 'published_at': publishedAt,
    };
  }

  static const _PostInsertDtoCopyWithSentinel _copyWithSentinel =
      _PostInsertDtoCopyWithSentinel();
  PostInsertDto copyWith({
    Object? authorId = _copyWithSentinel,
    Object? title = _copyWithSentinel,
    Object? content = _copyWithSentinel,
    Object? views = _copyWithSentinel,
    Object? publishedAt = _copyWithSentinel,
  }) {
    return PostInsertDto(
      authorId: identical(authorId, _copyWithSentinel)
          ? this.authorId
          : authorId as int?,
      title: identical(title, _copyWithSentinel)
          ? this.title
          : title as String?,
      content: identical(content, _copyWithSentinel)
          ? this.content
          : content as String?,
      views: identical(views, _copyWithSentinel) ? this.views : views as int?,
      publishedAt: identical(publishedAt, _copyWithSentinel)
          ? this.publishedAt
          : publishedAt as DateTime?,
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
    this.authorId,
    this.title,
    this.content,
    this.views,
    this.publishedAt,
  });
  final int? id;
  final int? authorId;
  final String? title;
  final String? content;
  final int? views;
  final DateTime? publishedAt;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (authorId != null) 'author_id': authorId,
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (views != null) 'views': views,
      if (publishedAt != null) 'published_at': publishedAt,
    };
  }

  static const _PostUpdateDtoCopyWithSentinel _copyWithSentinel =
      _PostUpdateDtoCopyWithSentinel();
  PostUpdateDto copyWith({
    Object? id = _copyWithSentinel,
    Object? authorId = _copyWithSentinel,
    Object? title = _copyWithSentinel,
    Object? content = _copyWithSentinel,
    Object? views = _copyWithSentinel,
    Object? publishedAt = _copyWithSentinel,
  }) {
    return PostUpdateDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      authorId: identical(authorId, _copyWithSentinel)
          ? this.authorId
          : authorId as int?,
      title: identical(title, _copyWithSentinel)
          ? this.title
          : title as String?,
      content: identical(content, _copyWithSentinel)
          ? this.content
          : content as String?,
      views: identical(views, _copyWithSentinel) ? this.views : views as int?,
      publishedAt: identical(publishedAt, _copyWithSentinel)
          ? this.publishedAt
          : publishedAt as DateTime?,
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
    this.authorId,
    this.title,
    this.content,
    this.views,
    this.publishedAt,
  });

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory PostPartial.fromRow(Map<String, Object?> row) {
    return PostPartial(
      id: row['id'] as int?,
      authorId: row['author_id'] as int?,
      title: row['title'] as String?,
      content: row['content'] as String?,
      views: row['views'] as int?,
      publishedAt: row['published_at'] as DateTime?,
    );
  }

  final int? id;
  final int? authorId;
  final String? title;
  final String? content;
  final int? views;
  final DateTime? publishedAt;

  @override
  $Post toEntity() {
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
    final DateTime? publishedAtValue = publishedAt;
    if (publishedAtValue == null) {
      throw StateError('Missing required field: publishedAt');
    }
    return $Post(
      id: idValue,
      authorId: authorIdValue,
      title: titleValue,
      content: content,
      views: views,
      publishedAt: publishedAtValue,
    );
  }

  @override
  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      if (authorId != null) 'author_id': authorId,
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (views != null) 'views': views,
      if (publishedAt != null) 'published_at': publishedAt,
    };
  }

  static const _PostPartialCopyWithSentinel _copyWithSentinel =
      _PostPartialCopyWithSentinel();
  PostPartial copyWith({
    Object? id = _copyWithSentinel,
    Object? authorId = _copyWithSentinel,
    Object? title = _copyWithSentinel,
    Object? content = _copyWithSentinel,
    Object? views = _copyWithSentinel,
    Object? publishedAt = _copyWithSentinel,
  }) {
    return PostPartial(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      authorId: identical(authorId, _copyWithSentinel)
          ? this.authorId
          : authorId as int?,
      title: identical(title, _copyWithSentinel)
          ? this.title
          : title as String?,
      content: identical(content, _copyWithSentinel)
          ? this.content
          : content as String?,
      views: identical(views, _copyWithSentinel) ? this.views : views as int?,
      publishedAt: identical(publishedAt, _copyWithSentinel)
          ? this.publishedAt
          : publishedAt as DateTime?,
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
class $Post extends Post
    with ModelAttributes, TimestampsTZImpl
    implements OrmEntity {
  /// Internal constructor for [$Post].
  $Post({
    int id = 0,
    required int authorId,
    required String title,
    required DateTime publishedAt,
    String? content,
    int? views,
  }) : super.new(
         id: id,
         authorId: authorId,
         title: title,
         publishedAt: publishedAt,
         content: content,
         views: views,
       ) {
    _attachOrmRuntimeMetadata({
      'id': id,
      'author_id': authorId,
      'title': title,
      'content': content,
      'views': views,
      'published_at': publishedAt,
    });
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $Post.fromModel(Post model) {
    return $Post(
      id: model.id,
      authorId: model.authorId,
      title: model.title,
      content: model.content,
      views: model.views,
      publishedAt: model.publishedAt,
    );
  }

  $Post copyWith({
    int? id,
    int? authorId,
    String? title,
    String? content,
    int? views,
    DateTime? publishedAt,
  }) {
    return $Post(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      title: title ?? this.title,
      content: content ?? this.content,
      views: views ?? this.views,
      publishedAt: publishedAt ?? this.publishedAt,
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

  /// Tracked getter for [content].
  @override
  String? get content => getAttribute<String?>('content') ?? super.content;

  /// Tracked setter for [content].
  set content(String? value) => setAttribute('content', value);

  /// Tracked getter for [views].
  @override
  int? get views => getAttribute<int?>('views') ?? super.views;

  /// Tracked setter for [views].
  set views(int? value) => setAttribute('views', value);

  /// Tracked getter for [publishedAt].
  @override
  DateTime get publishedAt =>
      getAttribute<DateTime>('published_at') ?? super.publishedAt;

  /// Tracked setter for [publishedAt].
  set publishedAt(DateTime value) => setAttribute('published_at', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$PostDefinition);
  }

  @override
  Author? get author {
    if (relationLoaded('author')) {
      return getRelation<Author>('author');
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
  List<Tag> get morphTags {
    if (relationLoaded('morphTags')) {
      return getRelationList<Tag>('morphTags');
    }
    return super.morphTags;
  }

  @override
  List<Photo> get photos {
    if (relationLoaded('photos')) {
      return getRelationList<Photo>('photos');
    }
    return super.photos;
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
  Query<Author> authorQuery() {
    return Model.query<Author>().where('id', authorId);
  }

  Query<Tag> tagsQuery() {
    final query = Model.query<Tag>();
    final targetTable = query.definition.tableName;
    final targetKey = query.definition.primaryKeyField?.columnName ?? 'id';
    return query
        .join('post_tags', '$targetTable.$targetKey', '=', 'post_tags.tag_id')
        .where('post_tags.post_id', id);
  }

  Query<Tag> morphTagsQuery() {
    throw UnimplementedError(
      "Polymorphic relation query generation not yet supported",
    );
  }

  Query<Photo> photosQuery() {
    throw UnimplementedError(
      "Polymorphic relation query generation not yet supported",
    );
  }

  Query<Comment> commentsQuery() {
    return Model.query<Comment>().where('post_id', id);
  }
}

extension PostOrmExtension on Post {
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

void registerPostEventHandlers(EventBus bus) {
  bus.on<ModelCreatedEvent>((event) {
    if (event.modelType != Post && event.modelType != $Post) {
      return;
    }
    Post.onCreated(event);
  });
}
