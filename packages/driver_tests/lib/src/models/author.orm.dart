// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'author.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$AuthorIdField = FieldDefinition(
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

const FieldDefinition _$AuthorNameField = FieldDefinition(
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

const FieldDefinition _$AuthorActiveField = FieldDefinition(
  name: 'active',
  columnName: 'active',
  dartType: 'bool',
  resolvedType: 'bool',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$AuthorCreatedAtField = FieldDefinition(
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

const FieldDefinition _$AuthorUpdatedAtField = FieldDefinition(
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

const RelationDefinition _$AuthorPostsRelation = RelationDefinition(
  name: 'posts',
  kind: RelationKind.hasMany,
  targetModel: 'Post',
  foreignKey: 'author_id',
  localKey: 'id',
);

const RelationDefinition _$AuthorCommentsRelation = RelationDefinition(
  name: 'comments',
  kind: RelationKind.hasManyThrough,
  targetModel: 'Comment',
  foreignKey: 'post_id',
  localKey: 'id',
  throughModel: 'Post',
  throughForeignKey: 'author_id',
);

Map<String, Object?> _encodeAuthorUntracked(
  Object model,
  ValueCodecRegistry registry,
) {
  final m = model as Author;
  return <String, Object?>{
    'id': registry.encodeField(_$AuthorIdField, m.id),
    'name': registry.encodeField(_$AuthorNameField, m.name),
    'active': registry.encodeField(_$AuthorActiveField, m.active),
  };
}

final ModelDefinition<$Author> _$AuthorDefinition = ModelDefinition(
  modelName: 'Author',
  tableName: 'authors',
  fields: const [
    _$AuthorIdField,
    _$AuthorNameField,
    _$AuthorActiveField,
    _$AuthorCreatedAtField,
    _$AuthorUpdatedAtField,
  ],
  relations: const [_$AuthorPostsRelation, _$AuthorCommentsRelation],
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
  untrackedToMap: _encodeAuthorUntracked,
  codec: _$AuthorCodec(),
);

// ignore: unused_element
final authorModelDefinitionRegistration =
    ModelFactoryRegistry.register<$Author>(_$AuthorDefinition);

extension AuthorOrmDefinition on Author {
  static ModelDefinition<$Author> get definition => _$AuthorDefinition;
}

class Authors {
  const Authors._();

  /// Starts building a query for [$Author].
  ///
  /// {@macro ormed.query}
  static Query<$Author> query([String? connection]) =>
      Model.query<$Author>(connection: connection);

  static Future<$Author?> find(Object id, {String? connection}) =>
      Model.find<$Author>(id, connection: connection);

  static Future<$Author> findOrFail(Object id, {String? connection}) =>
      Model.findOrFail<$Author>(id, connection: connection);

  static Future<List<$Author>> all({String? connection}) =>
      Model.all<$Author>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<$Author>(connection: connection);

  static Future<bool> anyExist({String? connection}) =>
      Model.anyExist<$Author>(connection: connection);

  static Query<$Author> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) => Model.where<$Author>(column, operator, value, connection: connection);

  static Query<$Author> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<$Author>(column, values, connection: connection);

  static Query<$Author> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<$Author>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<$Author> limit(int count, {String? connection}) =>
      Model.limit<$Author>(count, connection: connection);

  /// Creates a [Repository] for [$Author].
  ///
  /// {@macro ormed.repository}
  static Repository<$Author> repo([String? connection]) =>
      Model.repository<$Author>(connection: connection);
}

class AuthorModelFactory {
  const AuthorModelFactory._();

  static ModelDefinition<$Author> get definition => _$AuthorDefinition;

  static ModelCodec<$Author> get codec => definition.codec;

  static Author fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    Author model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model.toTracked(), registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<Author> withConnection(QueryContext context) =>
      ModelFactoryConnection<Author>(definition: definition, context: context);

  static ModelFactoryBuilder<Author> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<Author>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$AuthorCodec extends ModelCodec<$Author> {
  const _$AuthorCodec();
  @override
  Map<String, Object?> encode($Author model, ValueCodecRegistry registry) {
    return <String, Object?>{
      'id': registry.encodeField(_$AuthorIdField, model.id),
      'name': registry.encodeField(_$AuthorNameField, model.name),
      'active': registry.encodeField(_$AuthorActiveField, model.active),
      if (model.hasAttribute('created_at'))
        'created_at': registry.encodeField(
          _$AuthorCreatedAtField,
          model.getAttribute<DateTime?>('created_at'),
        ),
      if (model.hasAttribute('updated_at'))
        'updated_at': registry.encodeField(
          _$AuthorUpdatedAtField,
          model.getAttribute<DateTime?>('updated_at'),
        ),
    };
  }

  @override
  $Author decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final int authorIdValue =
        registry.decodeField<int>(_$AuthorIdField, data['id']) ?? 0;
    final String authorNameValue =
        registry.decodeField<String>(_$AuthorNameField, data['name']) ??
        (throw StateError('Field name on Author cannot be null.'));
    final bool authorActiveValue =
        registry.decodeField<bool>(_$AuthorActiveField, data['active']) ??
        (throw StateError('Field active on Author cannot be null.'));
    final DateTime? authorCreatedAtValue = registry.decodeField<DateTime?>(
      _$AuthorCreatedAtField,
      data['created_at'],
    );
    final DateTime? authorUpdatedAtValue = registry.decodeField<DateTime?>(
      _$AuthorUpdatedAtField,
      data['updated_at'],
    );
    final model = $Author(
      id: authorIdValue,
      name: authorNameValue,
      active: authorActiveValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': authorIdValue,
      'name': authorNameValue,
      'active': authorActiveValue,
      if (data.containsKey('created_at')) 'created_at': authorCreatedAtValue,
      if (data.containsKey('updated_at')) 'updated_at': authorUpdatedAtValue,
    });
    return model;
  }
}

/// Insert DTO for [Author].
///
/// Auto-increment/DB-generated fields are omitted by default.
class AuthorInsertDto implements InsertDto<$Author> {
  const AuthorInsertDto({this.name, this.active});
  final String? name;
  final bool? active;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (name != null) 'name': name,
      if (active != null) 'active': active,
    };
  }

  static const _AuthorInsertDtoCopyWithSentinel _copyWithSentinel =
      _AuthorInsertDtoCopyWithSentinel();
  AuthorInsertDto copyWith({
    Object? name = _copyWithSentinel,
    Object? active = _copyWithSentinel,
  }) {
    return AuthorInsertDto(
      name: identical(name, _copyWithSentinel) ? this.name : name as String?,
      active: identical(active, _copyWithSentinel)
          ? this.active
          : active as bool?,
    );
  }
}

class _AuthorInsertDtoCopyWithSentinel {
  const _AuthorInsertDtoCopyWithSentinel();
}

/// Update DTO for [Author].
///
/// All fields are optional; only provided entries are used in SET clauses.
class AuthorUpdateDto implements UpdateDto<$Author> {
  const AuthorUpdateDto({this.id, this.name, this.active});
  final int? id;
  final String? name;
  final bool? active;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (active != null) 'active': active,
    };
  }

  static const _AuthorUpdateDtoCopyWithSentinel _copyWithSentinel =
      _AuthorUpdateDtoCopyWithSentinel();
  AuthorUpdateDto copyWith({
    Object? id = _copyWithSentinel,
    Object? name = _copyWithSentinel,
    Object? active = _copyWithSentinel,
  }) {
    return AuthorUpdateDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      name: identical(name, _copyWithSentinel) ? this.name : name as String?,
      active: identical(active, _copyWithSentinel)
          ? this.active
          : active as bool?,
    );
  }
}

class _AuthorUpdateDtoCopyWithSentinel {
  const _AuthorUpdateDtoCopyWithSentinel();
}

/// Partial projection for [Author].
///
/// All fields are nullable; intended for subset SELECTs.
class AuthorPartial implements PartialEntity<$Author> {
  const AuthorPartial({this.id, this.name, this.active});

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory AuthorPartial.fromRow(Map<String, Object?> row) {
    return AuthorPartial(
      id: row['id'] as int?,
      name: row['name'] as String?,
      active: row['active'] as bool?,
    );
  }

  final int? id;
  final String? name;
  final bool? active;

  @override
  $Author toEntity() {
    // Basic required-field check: non-nullable fields must be present.
    final int? idValue = id;
    if (idValue == null) {
      throw StateError('Missing required field: id');
    }
    final String? nameValue = name;
    if (nameValue == null) {
      throw StateError('Missing required field: name');
    }
    final bool? activeValue = active;
    if (activeValue == null) {
      throw StateError('Missing required field: active');
    }
    return $Author(id: idValue, name: nameValue, active: activeValue);
  }

  @override
  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (active != null) 'active': active,
    };
  }

  static const _AuthorPartialCopyWithSentinel _copyWithSentinel =
      _AuthorPartialCopyWithSentinel();
  AuthorPartial copyWith({
    Object? id = _copyWithSentinel,
    Object? name = _copyWithSentinel,
    Object? active = _copyWithSentinel,
  }) {
    return AuthorPartial(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      name: identical(name, _copyWithSentinel) ? this.name : name as String?,
      active: identical(active, _copyWithSentinel)
          ? this.active
          : active as bool?,
    );
  }
}

class _AuthorPartialCopyWithSentinel {
  const _AuthorPartialCopyWithSentinel();
}

/// Generated tracked model class for [Author].
///
/// This class extends the user-defined [Author] model and adds
/// attribute tracking, change detection, and relationship management.
/// Instances of this class are returned by queries and repositories.
///
/// **Do not instantiate this class directly.** Use queries, repositories,
/// or model factories to create tracked model instances.
class $Author extends Author
    with ModelAttributes, TimestampsImpl
    implements OrmEntity {
  /// Internal constructor for [$Author].
  $Author({int id = 0, required String name, required bool active})
    : super.new(id: id, name: name, active: active) {
    _attachOrmRuntimeMetadata({'id': id, 'name': name, 'active': active});
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $Author.fromModel(Author model) {
    return $Author(id: model.id, name: model.name, active: model.active);
  }

  $Author copyWith({int? id, String? name, bool? active}) {
    return $Author(
      id: id ?? this.id,
      name: name ?? this.name,
      active: active ?? this.active,
    );
  }

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

  /// Tracked getter for [active].
  @override
  bool get active => getAttribute<bool>('active') ?? super.active;

  /// Tracked setter for [active].
  set active(bool value) => setAttribute('active', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$AuthorDefinition);
  }

  @override
  List<Post> get posts {
    if (relationLoaded('posts')) {
      return getRelationList<Post>('posts');
    }
    return super.posts;
  }

  @override
  List<Comment> get comments {
    if (relationLoaded('comments')) {
      return getRelationList<Comment>('comments');
    }
    return super.comments;
  }
}

extension AuthorRelationQueries on Author {
  Query<Post> postsQuery() {
    return Model.query<Post>().where('author_id', id);
  }

  Query<Comment> commentsQuery() {
    throw UnimplementedError(
      "Relation query generation not supported for RelationKind.hasManyThrough",
    );
  }
}

extension AuthorOrmExtension on Author {
  /// The Type of the generated ORM-managed model class.
  /// Use this when you need to specify the tracked model type explicitly,
  /// for example in generic type parameters.
  static Type get trackedType => $Author;

  /// Converts this immutable model to a tracked ORM-managed model.
  /// The tracked model supports attribute tracking, change detection,
  /// and persistence operations like save() and touch().
  $Author toTracked() {
    return $Author.fromModel(this);
  }
}

extension AuthorPredicateFields on PredicateBuilder<Author> {
  PredicateField<Author, int> get id => PredicateField<Author, int>(this, 'id');
  PredicateField<Author, String> get name =>
      PredicateField<Author, String>(this, 'name');
  PredicateField<Author, bool> get active =>
      PredicateField<Author, bool>(this, 'active');
}

extension AuthorTypedRelations on Query<Author> {
  Query<Author> withPosts([PredicateCallback<Post>? constraint]) =>
      withRelationTyped('posts', constraint);
  Query<Author> whereHasPosts([PredicateCallback<Post>? constraint]) =>
      whereHasTyped('posts', constraint);
  Query<Author> orWhereHasPosts([PredicateCallback<Post>? constraint]) =>
      orWhereHasTyped('posts', constraint);
  Query<Author> withComments([PredicateCallback<Comment>? constraint]) =>
      withRelationTyped('comments', constraint);
  Query<Author> whereHasComments([PredicateCallback<Comment>? constraint]) =>
      whereHasTyped('comments', constraint);
  Query<Author> orWhereHasComments([PredicateCallback<Comment>? constraint]) =>
      orWhereHasTyped('comments', constraint);
}

void registerAuthorEventHandlers(EventBus bus) {
  // No event handlers registered for Author.
}
