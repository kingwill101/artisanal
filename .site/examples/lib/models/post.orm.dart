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

const FieldDefinition _$PostAuthorIdField = FieldDefinition(
  name: 'authorId',
  columnName: 'author_id',
  dartType: 'int',
  resolvedType: 'int?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

Map<String, Object?> _encodePostUntracked(
  Object model,
  ValueCodecRegistry registry,
) {
  final m = model as Post;
  return <String, Object?>{
    'id': registry.encodeField(_$PostIdField, m.id),
    'title': registry.encodeField(_$PostTitleField, m.title),
    'content': registry.encodeField(_$PostContentField, m.content),
    'author_id': registry.encodeField(_$PostAuthorIdField, m.authorId),
  };
}

final ModelDefinition<$Post> _$PostDefinition = ModelDefinition(
  modelName: 'Post',
  tableName: 'posts',
  fields: const [
    _$PostIdField,
    _$PostTitleField,
    _$PostContentField,
    _$PostAuthorIdField,
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
      'title': registry.encodeField(_$PostTitleField, model.title),
      'content': registry.encodeField(_$PostContentField, model.content),
      'author_id': registry.encodeField(_$PostAuthorIdField, model.authorId),
    };
  }

  @override
  $Post decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final int postIdValue =
        registry.decodeField<int>(_$PostIdField, data['id']) ?? 0;
    final String postTitleValue =
        registry.decodeField<String>(_$PostTitleField, data['title']) ??
        (throw StateError('Field title on Post cannot be null.'));
    final String? postContentValue = registry.decodeField<String?>(
      _$PostContentField,
      data['content'],
    );
    final int? postAuthorIdValue = registry.decodeField<int?>(
      _$PostAuthorIdField,
      data['author_id'],
    );
    final model = $Post(
      id: postIdValue,
      title: postTitleValue,
      content: postContentValue,
      authorId: postAuthorIdValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': postIdValue,
      'title': postTitleValue,
      'content': postContentValue,
      'author_id': postAuthorIdValue,
    });
    return model;
  }
}

/// Insert DTO for [Post].
///
/// Auto-increment/DB-generated fields are omitted by default.
class PostInsertDto implements InsertDto<$Post> {
  const PostInsertDto({this.title, this.content, this.authorId});
  final String? title;
  final String? content;
  final int? authorId;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (authorId != null) 'author_id': authorId,
    };
  }

  static const _PostInsertDtoCopyWithSentinel _copyWithSentinel =
      _PostInsertDtoCopyWithSentinel();
  PostInsertDto copyWith({
    Object? title = _copyWithSentinel,
    Object? content = _copyWithSentinel,
    Object? authorId = _copyWithSentinel,
  }) {
    return PostInsertDto(
      title: identical(title, _copyWithSentinel)
          ? this.title
          : title as String?,
      content: identical(content, _copyWithSentinel)
          ? this.content
          : content as String?,
      authorId: identical(authorId, _copyWithSentinel)
          ? this.authorId
          : authorId as int?,
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
  const PostUpdateDto({this.id, this.title, this.content, this.authorId});
  final int? id;
  final String? title;
  final String? content;
  final int? authorId;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (authorId != null) 'author_id': authorId,
    };
  }

  static const _PostUpdateDtoCopyWithSentinel _copyWithSentinel =
      _PostUpdateDtoCopyWithSentinel();
  PostUpdateDto copyWith({
    Object? id = _copyWithSentinel,
    Object? title = _copyWithSentinel,
    Object? content = _copyWithSentinel,
    Object? authorId = _copyWithSentinel,
  }) {
    return PostUpdateDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      title: identical(title, _copyWithSentinel)
          ? this.title
          : title as String?,
      content: identical(content, _copyWithSentinel)
          ? this.content
          : content as String?,
      authorId: identical(authorId, _copyWithSentinel)
          ? this.authorId
          : authorId as int?,
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
  const PostPartial({this.id, this.title, this.content, this.authorId});

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory PostPartial.fromRow(Map<String, Object?> row) {
    return PostPartial(
      id: row['id'] as int?,
      title: row['title'] as String?,
      content: row['content'] as String?,
      authorId: row['author_id'] as int?,
    );
  }

  final int? id;
  final String? title;
  final String? content;
  final int? authorId;

  @override
  $Post toEntity() {
    // Basic required-field check: non-nullable fields must be present.
    final int? idValue = id;
    if (idValue == null) {
      throw StateError('Missing required field: id');
    }
    final String? titleValue = title;
    if (titleValue == null) {
      throw StateError('Missing required field: title');
    }
    return $Post(
      id: idValue,
      title: titleValue,
      content: content,
      authorId: authorId,
    );
  }

  @override
  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (authorId != null) 'author_id': authorId,
    };
  }

  static const _PostPartialCopyWithSentinel _copyWithSentinel =
      _PostPartialCopyWithSentinel();
  PostPartial copyWith({
    Object? id = _copyWithSentinel,
    Object? title = _copyWithSentinel,
    Object? content = _copyWithSentinel,
    Object? authorId = _copyWithSentinel,
  }) {
    return PostPartial(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      title: identical(title, _copyWithSentinel)
          ? this.title
          : title as String?,
      content: identical(content, _copyWithSentinel)
          ? this.content
          : content as String?,
      authorId: identical(authorId, _copyWithSentinel)
          ? this.authorId
          : authorId as int?,
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
  $Post({int id = 0, required String title, String? content, int? authorId})
    : super.new(id: id, title: title, content: content, authorId: authorId) {
    _attachOrmRuntimeMetadata({
      'id': id,
      'title': title,
      'content': content,
      'author_id': authorId,
    });
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $Post.fromModel(Post model) {
    return $Post(
      id: model.id,
      title: model.title,
      content: model.content,
      authorId: model.authorId,
    );
  }

  $Post copyWith({int? id, String? title, String? content, int? authorId}) {
    return $Post(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      authorId: authorId ?? this.authorId,
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
  int get id => getAttribute<int>('id') ?? super.id;

  /// Tracked setter for [id].
  set id(int value) => setAttribute('id', value);

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

  /// Tracked getter for [authorId].
  @override
  int? get authorId => getAttribute<int?>('author_id') ?? super.authorId;

  /// Tracked setter for [authorId].
  set authorId(int? value) => setAttribute('author_id', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$PostDefinition);
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
    Object? title = _copyWithSentinel,
    Object? content = _copyWithSentinel,
    Object? authorId = _copyWithSentinel,
  }) {
    return Post.new(
      id: identical(id, _copyWithSentinel) ? this.id : id as int,
      title: identical(title, _copyWithSentinel) ? this.title : title as String,
      content: identical(content, _copyWithSentinel)
          ? this.content
          : content as String?,
      authorId: identical(authorId, _copyWithSentinel)
          ? this.authorId
          : authorId as int?,
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
  PredicateField<Post, int> get id => PredicateField<Post, int>(this, 'id');
  PredicateField<Post, String> get title =>
      PredicateField<Post, String>(this, 'title');
  PredicateField<Post, String?> get content =>
      PredicateField<Post, String?>(this, 'content');
  PredicateField<Post, int?> get authorId =>
      PredicateField<Post, int?>(this, 'authorId');
}

void registerPostEventHandlers(EventBus bus) {
  // No event handlers registered for Post.
}
