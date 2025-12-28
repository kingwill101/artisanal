// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'belongs_to.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$PostWithAuthorIdField = FieldDefinition(
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

const FieldDefinition _$PostWithAuthorAuthorIdField = FieldDefinition(
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

const FieldDefinition _$PostWithAuthorTitleField = FieldDefinition(
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

const FieldDefinition _$PostWithAuthorAuthorField = FieldDefinition(
  name: 'author',
  columnName: 'author',
  dartType: 'PostAuthor',
  resolvedType: 'PostAuthor?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const RelationDefinition _$PostWithAuthorAuthorRelation = RelationDefinition(
  name: 'author',
  kind: RelationKind.belongsTo,
  targetModel: 'PostAuthor',
  foreignKey: 'author_id',
);

Map<String, Object?> _encodePostWithAuthorUntracked(
  Object model,
  ValueCodecRegistry registry,
) {
  final m = model as PostWithAuthor;
  return <String, Object?>{
    'id': registry.encodeField(_$PostWithAuthorIdField, m.id),
    'author_id': registry.encodeField(
      _$PostWithAuthorAuthorIdField,
      m.authorId,
    ),
    'title': registry.encodeField(_$PostWithAuthorTitleField, m.title),
    'author': registry.encodeField(_$PostWithAuthorAuthorField, m.author),
  };
}

final ModelDefinition<$PostWithAuthor> _$PostWithAuthorDefinition =
    ModelDefinition(
      modelName: 'PostWithAuthor',
      tableName: 'posts',
      fields: const [
        _$PostWithAuthorIdField,
        _$PostWithAuthorAuthorIdField,
        _$PostWithAuthorTitleField,
        _$PostWithAuthorAuthorField,
      ],
      relations: const [_$PostWithAuthorAuthorRelation],
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
      untrackedToMap: _encodePostWithAuthorUntracked,
      codec: _$PostWithAuthorCodec(),
    );

extension PostWithAuthorOrmDefinition on PostWithAuthor {
  static ModelDefinition<$PostWithAuthor> get definition =>
      _$PostWithAuthorDefinition;
}

class PostWithAuthors {
  const PostWithAuthors._();

  /// Starts building a query for [$PostWithAuthor].
  ///
  /// {@macro ormed.query}
  static Query<$PostWithAuthor> query([String? connection]) =>
      Model.query<$PostWithAuthor>(connection: connection);

  static Future<$PostWithAuthor?> find(Object id, {String? connection}) =>
      Model.find<$PostWithAuthor>(id, connection: connection);

  static Future<$PostWithAuthor> findOrFail(Object id, {String? connection}) =>
      Model.findOrFail<$PostWithAuthor>(id, connection: connection);

  static Future<List<$PostWithAuthor>> all({String? connection}) =>
      Model.all<$PostWithAuthor>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<$PostWithAuthor>(connection: connection);

  static Future<bool> anyExist({String? connection}) =>
      Model.anyExist<$PostWithAuthor>(connection: connection);

  static Query<$PostWithAuthor> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) => Model.where<$PostWithAuthor>(
    column,
    operator,
    value,
    connection: connection,
  );

  static Query<$PostWithAuthor> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<$PostWithAuthor>(column, values, connection: connection);

  static Query<$PostWithAuthor> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<$PostWithAuthor>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<$PostWithAuthor> limit(int count, {String? connection}) =>
      Model.limit<$PostWithAuthor>(count, connection: connection);

  /// Creates a [Repository] for [$PostWithAuthor].
  ///
  /// {@macro ormed.repository}
  static Repository<$PostWithAuthor> repo([String? connection]) =>
      Model.repository<$PostWithAuthor>(connection: connection);

  /// Builds a tracked model from a column/value map.
  static $PostWithAuthor fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$PostWithAuthorDefinition.fromMap(data, registry: registry);

  /// Converts a tracked model to a column/value map.
  static Map<String, Object?> toMap(
    $PostWithAuthor model, {
    ValueCodecRegistry? registry,
  }) => _$PostWithAuthorDefinition.toMap(model, registry: registry);
}

class PostWithAuthorModelFactory {
  const PostWithAuthorModelFactory._();

  static ModelDefinition<$PostWithAuthor> get definition =>
      _$PostWithAuthorDefinition;

  static ModelCodec<$PostWithAuthor> get codec => definition.codec;

  static PostWithAuthor fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    PostWithAuthor model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model.toTracked(), registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<PostWithAuthor> withConnection(
    QueryContext context,
  ) => ModelFactoryConnection<PostWithAuthor>(
    definition: definition,
    context: context,
  );

  static ModelFactoryBuilder<PostWithAuthor> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<PostWithAuthor>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$PostWithAuthorCodec extends ModelCodec<$PostWithAuthor> {
  const _$PostWithAuthorCodec();
  @override
  Map<String, Object?> encode(
    $PostWithAuthor model,
    ValueCodecRegistry registry,
  ) {
    return <String, Object?>{
      'id': registry.encodeField(_$PostWithAuthorIdField, model.id),
      'author_id': registry.encodeField(
        _$PostWithAuthorAuthorIdField,
        model.authorId,
      ),
      'title': registry.encodeField(_$PostWithAuthorTitleField, model.title),
      'author': registry.encodeField(_$PostWithAuthorAuthorField, model.author),
    };
  }

  @override
  $PostWithAuthor decode(
    Map<String, Object?> data,
    ValueCodecRegistry registry,
  ) {
    final int postWithAuthorIdValue =
        registry.decodeField<int>(_$PostWithAuthorIdField, data['id']) ??
        (throw StateError('Field id on PostWithAuthor cannot be null.'));
    final int postWithAuthorAuthorIdValue =
        registry.decodeField<int>(
          _$PostWithAuthorAuthorIdField,
          data['author_id'],
        ) ??
        (throw StateError('Field authorId on PostWithAuthor cannot be null.'));
    final String postWithAuthorTitleValue =
        registry.decodeField<String>(
          _$PostWithAuthorTitleField,
          data['title'],
        ) ??
        (throw StateError('Field title on PostWithAuthor cannot be null.'));
    final PostAuthor? postWithAuthorAuthorValue = registry
        .decodeField<PostAuthor?>(_$PostWithAuthorAuthorField, data['author']);
    final model = $PostWithAuthor(
      id: postWithAuthorIdValue,
      authorId: postWithAuthorAuthorIdValue,
      title: postWithAuthorTitleValue,
      author: postWithAuthorAuthorValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': postWithAuthorIdValue,
      'author_id': postWithAuthorAuthorIdValue,
      'title': postWithAuthorTitleValue,
      'author': postWithAuthorAuthorValue,
    });
    return model;
  }
}

/// Insert DTO for [PostWithAuthor].
///
/// Auto-increment/DB-generated fields are omitted by default.
class PostWithAuthorInsertDto implements InsertDto<$PostWithAuthor> {
  const PostWithAuthorInsertDto({
    this.id,
    this.authorId,
    this.title,
    this.author,
  });
  final int? id;
  final int? authorId;
  final String? title;
  final PostAuthor? author;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (authorId != null) 'author_id': authorId,
      if (title != null) 'title': title,
      if (author != null) 'author': author,
    };
  }

  static const _PostWithAuthorInsertDtoCopyWithSentinel _copyWithSentinel =
      _PostWithAuthorInsertDtoCopyWithSentinel();
  PostWithAuthorInsertDto copyWith({
    Object? id = _copyWithSentinel,
    Object? authorId = _copyWithSentinel,
    Object? title = _copyWithSentinel,
    Object? author = _copyWithSentinel,
  }) {
    return PostWithAuthorInsertDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      authorId: identical(authorId, _copyWithSentinel)
          ? this.authorId
          : authorId as int?,
      title: identical(title, _copyWithSentinel)
          ? this.title
          : title as String?,
      author: identical(author, _copyWithSentinel)
          ? this.author
          : author as PostAuthor?,
    );
  }
}

class _PostWithAuthorInsertDtoCopyWithSentinel {
  const _PostWithAuthorInsertDtoCopyWithSentinel();
}

/// Update DTO for [PostWithAuthor].
///
/// All fields are optional; only provided entries are used in SET clauses.
class PostWithAuthorUpdateDto implements UpdateDto<$PostWithAuthor> {
  const PostWithAuthorUpdateDto({
    this.id,
    this.authorId,
    this.title,
    this.author,
  });
  final int? id;
  final int? authorId;
  final String? title;
  final PostAuthor? author;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (authorId != null) 'author_id': authorId,
      if (title != null) 'title': title,
      if (author != null) 'author': author,
    };
  }

  static const _PostWithAuthorUpdateDtoCopyWithSentinel _copyWithSentinel =
      _PostWithAuthorUpdateDtoCopyWithSentinel();
  PostWithAuthorUpdateDto copyWith({
    Object? id = _copyWithSentinel,
    Object? authorId = _copyWithSentinel,
    Object? title = _copyWithSentinel,
    Object? author = _copyWithSentinel,
  }) {
    return PostWithAuthorUpdateDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      authorId: identical(authorId, _copyWithSentinel)
          ? this.authorId
          : authorId as int?,
      title: identical(title, _copyWithSentinel)
          ? this.title
          : title as String?,
      author: identical(author, _copyWithSentinel)
          ? this.author
          : author as PostAuthor?,
    );
  }
}

class _PostWithAuthorUpdateDtoCopyWithSentinel {
  const _PostWithAuthorUpdateDtoCopyWithSentinel();
}

/// Partial projection for [PostWithAuthor].
///
/// All fields are nullable; intended for subset SELECTs.
class PostWithAuthorPartial implements PartialEntity<$PostWithAuthor> {
  const PostWithAuthorPartial({
    this.id,
    this.authorId,
    this.title,
    this.author,
  });

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory PostWithAuthorPartial.fromRow(Map<String, Object?> row) {
    return PostWithAuthorPartial(
      id: row['id'] as int?,
      authorId: row['author_id'] as int?,
      title: row['title'] as String?,
      author: row['author'] as PostAuthor?,
    );
  }

  final int? id;
  final int? authorId;
  final String? title;
  final PostAuthor? author;

  @override
  $PostWithAuthor toEntity() {
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
    return $PostWithAuthor(
      id: idValue,
      authorId: authorIdValue,
      title: titleValue,
      author: author,
    );
  }

  @override
  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      if (authorId != null) 'author_id': authorId,
      if (title != null) 'title': title,
      if (author != null) 'author': author,
    };
  }

  static const _PostWithAuthorPartialCopyWithSentinel _copyWithSentinel =
      _PostWithAuthorPartialCopyWithSentinel();
  PostWithAuthorPartial copyWith({
    Object? id = _copyWithSentinel,
    Object? authorId = _copyWithSentinel,
    Object? title = _copyWithSentinel,
    Object? author = _copyWithSentinel,
  }) {
    return PostWithAuthorPartial(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      authorId: identical(authorId, _copyWithSentinel)
          ? this.authorId
          : authorId as int?,
      title: identical(title, _copyWithSentinel)
          ? this.title
          : title as String?,
      author: identical(author, _copyWithSentinel)
          ? this.author
          : author as PostAuthor?,
    );
  }
}

class _PostWithAuthorPartialCopyWithSentinel {
  const _PostWithAuthorPartialCopyWithSentinel();
}

/// Generated tracked model class for [PostWithAuthor].
///
/// This class extends the user-defined [PostWithAuthor] model and adds
/// attribute tracking, change detection, and relationship management.
/// Instances of this class are returned by queries and repositories.
///
/// **Do not instantiate this class directly.** Use queries, repositories,
/// or model factories to create tracked model instances.
class $PostWithAuthor extends PostWithAuthor
    with ModelAttributes
    implements OrmEntity {
  /// Internal constructor for [$PostWithAuthor].
  $PostWithAuthor({
    required int id,
    required int authorId,
    required String title,
    PostAuthor? author,
  }) : super.new(id: id, authorId: authorId, title: title, author: author) {
    _attachOrmRuntimeMetadata({
      'id': id,
      'author_id': authorId,
      'title': title,
      'author': author,
    });
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $PostWithAuthor.fromModel(PostWithAuthor model) {
    return $PostWithAuthor(
      id: model.id,
      authorId: model.authorId,
      title: model.title,
      author: model.author,
    );
  }

  $PostWithAuthor copyWith({
    int? id,
    int? authorId,
    String? title,
    PostAuthor? author,
  }) {
    return $PostWithAuthor(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      title: title ?? this.title,
      author: author ?? this.author,
    );
  }

  /// Builds a tracked model from a column/value map.
  static $PostWithAuthor fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$PostWithAuthorDefinition.fromMap(data, registry: registry);

  /// Converts this tracked model to a column/value map.
  Map<String, Object?> toMap({ValueCodecRegistry? registry}) =>
      _$PostWithAuthorDefinition.toMap(this, registry: registry);

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

  /// Tracked getter for [author].
  @override
  PostAuthor? get author => getAttribute<PostAuthor?>('author') ?? super.author;

  /// Tracked setter for [author].
  set author(PostAuthor? value) => setAttribute('author', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$PostWithAuthorDefinition);
  }

  @override
  PostAuthor? get author {
    if (relationLoaded('author')) {
      return getRelation<PostAuthor>('author');
    }
    return super.author;
  }
}

extension PostWithAuthorRelationQueries on PostWithAuthor {
  Query<PostAuthor> authorQuery() {
    return Model.query<PostAuthor>().where('null', authorId);
  }
}

class _PostWithAuthorCopyWithSentinel {
  const _PostWithAuthorCopyWithSentinel();
}

extension PostWithAuthorOrmExtension on PostWithAuthor {
  static const _PostWithAuthorCopyWithSentinel _copyWithSentinel =
      _PostWithAuthorCopyWithSentinel();
  PostWithAuthor copyWith({
    Object? id = _copyWithSentinel,
    Object? authorId = _copyWithSentinel,
    Object? title = _copyWithSentinel,
    Object? author = _copyWithSentinel,
  }) {
    return PostWithAuthor.new(
      id: identical(id, _copyWithSentinel) ? this.id : id as int,
      authorId: identical(authorId, _copyWithSentinel)
          ? this.authorId
          : authorId as int,
      title: identical(title, _copyWithSentinel) ? this.title : title as String,
      author: identical(author, _copyWithSentinel)
          ? this.author
          : author as PostAuthor?,
    );
  }

  /// Converts this model to a column/value map.
  Map<String, Object?> toMap({ValueCodecRegistry? registry}) =>
      _$PostWithAuthorDefinition.toMap(this, registry: registry);

  /// Builds a model from a column/value map.
  static PostWithAuthor fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$PostWithAuthorDefinition.fromMap(data, registry: registry);

  /// The Type of the generated ORM-managed model class.
  /// Use this when you need to specify the tracked model type explicitly,
  /// for example in generic type parameters.
  static Type get trackedType => $PostWithAuthor;

  /// Converts this immutable model to a tracked ORM-managed model.
  /// The tracked model supports attribute tracking, change detection,
  /// and persistence operations like save() and touch().
  $PostWithAuthor toTracked() {
    return $PostWithAuthor.fromModel(this);
  }
}

extension PostWithAuthorPredicateFields on PredicateBuilder<PostWithAuthor> {
  PredicateField<PostWithAuthor, int> get id =>
      PredicateField<PostWithAuthor, int>(this, 'id');
  PredicateField<PostWithAuthor, int> get authorId =>
      PredicateField<PostWithAuthor, int>(this, 'authorId');
  PredicateField<PostWithAuthor, String> get title =>
      PredicateField<PostWithAuthor, String>(this, 'title');
  PredicateField<PostWithAuthor, PostAuthor?> get author =>
      PredicateField<PostWithAuthor, PostAuthor?>(this, 'author');
}

extension PostWithAuthorTypedRelations on Query<PostWithAuthor> {
  Query<PostWithAuthor> withAuthor([
    PredicateCallback<PostAuthor>? constraint,
  ]) => withRelationTyped('author', constraint);
  Query<PostWithAuthor> whereHasAuthor([
    PredicateCallback<PostAuthor>? constraint,
  ]) => whereHasTyped('author', constraint);
  Query<PostWithAuthor> orWhereHasAuthor([
    PredicateCallback<PostAuthor>? constraint,
  ]) => orWhereHasTyped('author', constraint);
}

void registerPostWithAuthorEventHandlers(EventBus bus) {
  // No event handlers registered for PostWithAuthor.
}

const FieldDefinition _$PostAuthorIdField = FieldDefinition(
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

const FieldDefinition _$PostAuthorNameField = FieldDefinition(
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

Map<String, Object?> _encodePostAuthorUntracked(
  Object model,
  ValueCodecRegistry registry,
) {
  final m = model as PostAuthor;
  return <String, Object?>{
    'id': registry.encodeField(_$PostAuthorIdField, m.id),
    'name': registry.encodeField(_$PostAuthorNameField, m.name),
  };
}

final ModelDefinition<$PostAuthor> _$PostAuthorDefinition = ModelDefinition(
  modelName: 'PostAuthor',
  tableName: 'users',
  fields: const [_$PostAuthorIdField, _$PostAuthorNameField],
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
  untrackedToMap: _encodePostAuthorUntracked,
  codec: _$PostAuthorCodec(),
);

extension PostAuthorOrmDefinition on PostAuthor {
  static ModelDefinition<$PostAuthor> get definition => _$PostAuthorDefinition;
}

class PostAuthors {
  const PostAuthors._();

  /// Starts building a query for [$PostAuthor].
  ///
  /// {@macro ormed.query}
  static Query<$PostAuthor> query([String? connection]) =>
      Model.query<$PostAuthor>(connection: connection);

  static Future<$PostAuthor?> find(Object id, {String? connection}) =>
      Model.find<$PostAuthor>(id, connection: connection);

  static Future<$PostAuthor> findOrFail(Object id, {String? connection}) =>
      Model.findOrFail<$PostAuthor>(id, connection: connection);

  static Future<List<$PostAuthor>> all({String? connection}) =>
      Model.all<$PostAuthor>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<$PostAuthor>(connection: connection);

  static Future<bool> anyExist({String? connection}) =>
      Model.anyExist<$PostAuthor>(connection: connection);

  static Query<$PostAuthor> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) =>
      Model.where<$PostAuthor>(column, operator, value, connection: connection);

  static Query<$PostAuthor> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<$PostAuthor>(column, values, connection: connection);

  static Query<$PostAuthor> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<$PostAuthor>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<$PostAuthor> limit(int count, {String? connection}) =>
      Model.limit<$PostAuthor>(count, connection: connection);

  /// Creates a [Repository] for [$PostAuthor].
  ///
  /// {@macro ormed.repository}
  static Repository<$PostAuthor> repo([String? connection]) =>
      Model.repository<$PostAuthor>(connection: connection);

  /// Builds a tracked model from a column/value map.
  static $PostAuthor fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$PostAuthorDefinition.fromMap(data, registry: registry);

  /// Converts a tracked model to a column/value map.
  static Map<String, Object?> toMap(
    $PostAuthor model, {
    ValueCodecRegistry? registry,
  }) => _$PostAuthorDefinition.toMap(model, registry: registry);
}

class PostAuthorModelFactory {
  const PostAuthorModelFactory._();

  static ModelDefinition<$PostAuthor> get definition => _$PostAuthorDefinition;

  static ModelCodec<$PostAuthor> get codec => definition.codec;

  static PostAuthor fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    PostAuthor model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model.toTracked(), registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<PostAuthor> withConnection(
    QueryContext context,
  ) => ModelFactoryConnection<PostAuthor>(
    definition: definition,
    context: context,
  );

  static ModelFactoryBuilder<PostAuthor> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<PostAuthor>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$PostAuthorCodec extends ModelCodec<$PostAuthor> {
  const _$PostAuthorCodec();
  @override
  Map<String, Object?> encode($PostAuthor model, ValueCodecRegistry registry) {
    return <String, Object?>{
      'id': registry.encodeField(_$PostAuthorIdField, model.id),
      'name': registry.encodeField(_$PostAuthorNameField, model.name),
    };
  }

  @override
  $PostAuthor decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final int postAuthorIdValue =
        registry.decodeField<int>(_$PostAuthorIdField, data['id']) ??
        (throw StateError('Field id on PostAuthor cannot be null.'));
    final String postAuthorNameValue =
        registry.decodeField<String>(_$PostAuthorNameField, data['name']) ??
        (throw StateError('Field name on PostAuthor cannot be null.'));
    final model = $PostAuthor(id: postAuthorIdValue, name: postAuthorNameValue);
    model._attachOrmRuntimeMetadata({
      'id': postAuthorIdValue,
      'name': postAuthorNameValue,
    });
    return model;
  }
}

/// Insert DTO for [PostAuthor].
///
/// Auto-increment/DB-generated fields are omitted by default.
class PostAuthorInsertDto implements InsertDto<$PostAuthor> {
  const PostAuthorInsertDto({this.id, this.name});
  final int? id;
  final String? name;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (name != null) 'name': name,
    };
  }

  static const _PostAuthorInsertDtoCopyWithSentinel _copyWithSentinel =
      _PostAuthorInsertDtoCopyWithSentinel();
  PostAuthorInsertDto copyWith({
    Object? id = _copyWithSentinel,
    Object? name = _copyWithSentinel,
  }) {
    return PostAuthorInsertDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      name: identical(name, _copyWithSentinel) ? this.name : name as String?,
    );
  }
}

class _PostAuthorInsertDtoCopyWithSentinel {
  const _PostAuthorInsertDtoCopyWithSentinel();
}

/// Update DTO for [PostAuthor].
///
/// All fields are optional; only provided entries are used in SET clauses.
class PostAuthorUpdateDto implements UpdateDto<$PostAuthor> {
  const PostAuthorUpdateDto({this.id, this.name});
  final int? id;
  final String? name;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (name != null) 'name': name,
    };
  }

  static const _PostAuthorUpdateDtoCopyWithSentinel _copyWithSentinel =
      _PostAuthorUpdateDtoCopyWithSentinel();
  PostAuthorUpdateDto copyWith({
    Object? id = _copyWithSentinel,
    Object? name = _copyWithSentinel,
  }) {
    return PostAuthorUpdateDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      name: identical(name, _copyWithSentinel) ? this.name : name as String?,
    );
  }
}

class _PostAuthorUpdateDtoCopyWithSentinel {
  const _PostAuthorUpdateDtoCopyWithSentinel();
}

/// Partial projection for [PostAuthor].
///
/// All fields are nullable; intended for subset SELECTs.
class PostAuthorPartial implements PartialEntity<$PostAuthor> {
  const PostAuthorPartial({this.id, this.name});

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory PostAuthorPartial.fromRow(Map<String, Object?> row) {
    return PostAuthorPartial(
      id: row['id'] as int?,
      name: row['name'] as String?,
    );
  }

  final int? id;
  final String? name;

  @override
  $PostAuthor toEntity() {
    // Basic required-field check: non-nullable fields must be present.
    final int? idValue = id;
    if (idValue == null) {
      throw StateError('Missing required field: id');
    }
    final String? nameValue = name;
    if (nameValue == null) {
      throw StateError('Missing required field: name');
    }
    return $PostAuthor(id: idValue, name: nameValue);
  }

  @override
  Map<String, Object?> toMap() {
    return {if (id != null) 'id': id, if (name != null) 'name': name};
  }

  static const _PostAuthorPartialCopyWithSentinel _copyWithSentinel =
      _PostAuthorPartialCopyWithSentinel();
  PostAuthorPartial copyWith({
    Object? id = _copyWithSentinel,
    Object? name = _copyWithSentinel,
  }) {
    return PostAuthorPartial(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      name: identical(name, _copyWithSentinel) ? this.name : name as String?,
    );
  }
}

class _PostAuthorPartialCopyWithSentinel {
  const _PostAuthorPartialCopyWithSentinel();
}

/// Generated tracked model class for [PostAuthor].
///
/// This class extends the user-defined [PostAuthor] model and adds
/// attribute tracking, change detection, and relationship management.
/// Instances of this class are returned by queries and repositories.
///
/// **Do not instantiate this class directly.** Use queries, repositories,
/// or model factories to create tracked model instances.
class $PostAuthor extends PostAuthor with ModelAttributes implements OrmEntity {
  /// Internal constructor for [$PostAuthor].
  $PostAuthor({required int id, required String name})
    : super.new(id: id, name: name) {
    _attachOrmRuntimeMetadata({'id': id, 'name': name});
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $PostAuthor.fromModel(PostAuthor model) {
    return $PostAuthor(id: model.id, name: model.name);
  }

  $PostAuthor copyWith({int? id, String? name}) {
    return $PostAuthor(id: id ?? this.id, name: name ?? this.name);
  }

  /// Builds a tracked model from a column/value map.
  static $PostAuthor fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$PostAuthorDefinition.fromMap(data, registry: registry);

  /// Converts this tracked model to a column/value map.
  Map<String, Object?> toMap({ValueCodecRegistry? registry}) =>
      _$PostAuthorDefinition.toMap(this, registry: registry);

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
    attachModelDefinition(_$PostAuthorDefinition);
  }
}

class _PostAuthorCopyWithSentinel {
  const _PostAuthorCopyWithSentinel();
}

extension PostAuthorOrmExtension on PostAuthor {
  static const _PostAuthorCopyWithSentinel _copyWithSentinel =
      _PostAuthorCopyWithSentinel();
  PostAuthor copyWith({
    Object? id = _copyWithSentinel,
    Object? name = _copyWithSentinel,
  }) {
    return PostAuthor.new(
      id: identical(id, _copyWithSentinel) ? this.id : id as int,
      name: identical(name, _copyWithSentinel) ? this.name : name as String,
    );
  }

  /// Converts this model to a column/value map.
  Map<String, Object?> toMap({ValueCodecRegistry? registry}) =>
      _$PostAuthorDefinition.toMap(this, registry: registry);

  /// Builds a model from a column/value map.
  static PostAuthor fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$PostAuthorDefinition.fromMap(data, registry: registry);

  /// The Type of the generated ORM-managed model class.
  /// Use this when you need to specify the tracked model type explicitly,
  /// for example in generic type parameters.
  static Type get trackedType => $PostAuthor;

  /// Converts this immutable model to a tracked ORM-managed model.
  /// The tracked model supports attribute tracking, change detection,
  /// and persistence operations like save() and touch().
  $PostAuthor toTracked() {
    return $PostAuthor.fromModel(this);
  }
}

extension PostAuthorPredicateFields on PredicateBuilder<PostAuthor> {
  PredicateField<PostAuthor, int> get id =>
      PredicateField<PostAuthor, int>(this, 'id');
  PredicateField<PostAuthor, String> get name =>
      PredicateField<PostAuthor, String>(this, 'name');
}

void registerPostAuthorEventHandlers(EventBus bus) {
  // No event handlers registered for PostAuthor.
}
