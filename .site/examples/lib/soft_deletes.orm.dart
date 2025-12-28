// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'soft_deletes.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$CombinedPostIdField = FieldDefinition(
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

const FieldDefinition _$CombinedPostTitleField = FieldDefinition(
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

const FieldDefinition _$CombinedPostDeletedAtField = FieldDefinition(
  name: 'deletedAt',
  columnName: 'deleted_at',
  dartType: 'DateTime',
  resolvedType: 'DateTime?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$CombinedPostCreatedAtField = FieldDefinition(
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

const FieldDefinition _$CombinedPostUpdatedAtField = FieldDefinition(
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

Map<String, Object?> _encodeCombinedPostUntracked(
  Object model,
  ValueCodecRegistry registry,
) {
  final m = model as CombinedPost;
  return <String, Object?>{
    'id': registry.encodeField(_$CombinedPostIdField, m.id),
    'title': registry.encodeField(_$CombinedPostTitleField, m.title),
  };
}

final ModelDefinition<$CombinedPost> _$CombinedPostDefinition = ModelDefinition(
  modelName: 'CombinedPost',
  tableName: 'posts',
  fields: const [
    _$CombinedPostIdField,
    _$CombinedPostTitleField,
    _$CombinedPostDeletedAtField,
    _$CombinedPostCreatedAtField,
    _$CombinedPostUpdatedAtField,
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
    softDeletes: true,
    softDeleteColumn: 'deleted_at',
  ),
  untrackedToMap: _encodeCombinedPostUntracked,
  codec: _$CombinedPostCodec(),
);

extension CombinedPostOrmDefinition on CombinedPost {
  static ModelDefinition<$CombinedPost> get definition =>
      _$CombinedPostDefinition;
}

class CombinedPosts {
  const CombinedPosts._();

  /// Starts building a query for [$CombinedPost].
  ///
  /// {@macro ormed.query}
  static Query<$CombinedPost> query([String? connection]) =>
      Model.query<$CombinedPost>(connection: connection);

  static Future<$CombinedPost?> find(Object id, {String? connection}) =>
      Model.find<$CombinedPost>(id, connection: connection);

  static Future<$CombinedPost> findOrFail(Object id, {String? connection}) =>
      Model.findOrFail<$CombinedPost>(id, connection: connection);

  static Future<List<$CombinedPost>> all({String? connection}) =>
      Model.all<$CombinedPost>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<$CombinedPost>(connection: connection);

  static Future<bool> anyExist({String? connection}) =>
      Model.anyExist<$CombinedPost>(connection: connection);

  static Query<$CombinedPost> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) => Model.where<$CombinedPost>(
    column,
    operator,
    value,
    connection: connection,
  );

  static Query<$CombinedPost> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<$CombinedPost>(column, values, connection: connection);

  static Query<$CombinedPost> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<$CombinedPost>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<$CombinedPost> limit(int count, {String? connection}) =>
      Model.limit<$CombinedPost>(count, connection: connection);

  /// Creates a [Repository] for [$CombinedPost].
  ///
  /// {@macro ormed.repository}
  static Repository<$CombinedPost> repo([String? connection]) =>
      Model.repository<$CombinedPost>(connection: connection);

  /// Builds a tracked model from a column/value map.
  static $CombinedPost fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$CombinedPostDefinition.fromMap(data, registry: registry);

  /// Converts a tracked model to a column/value map.
  static Map<String, Object?> toMap(
    $CombinedPost model, {
    ValueCodecRegistry? registry,
  }) => _$CombinedPostDefinition.toMap(model, registry: registry);
}

class CombinedPostModelFactory {
  const CombinedPostModelFactory._();

  static ModelDefinition<$CombinedPost> get definition =>
      _$CombinedPostDefinition;

  static ModelCodec<$CombinedPost> get codec => definition.codec;

  static CombinedPost fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    CombinedPost model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model.toTracked(), registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<CombinedPost> withConnection(
    QueryContext context,
  ) => ModelFactoryConnection<CombinedPost>(
    definition: definition,
    context: context,
  );

  static ModelFactoryBuilder<CombinedPost> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<CombinedPost>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$CombinedPostCodec extends ModelCodec<$CombinedPost> {
  const _$CombinedPostCodec();
  @override
  Map<String, Object?> encode(
    $CombinedPost model,
    ValueCodecRegistry registry,
  ) {
    return <String, Object?>{
      'id': registry.encodeField(_$CombinedPostIdField, model.id),
      'title': registry.encodeField(_$CombinedPostTitleField, model.title),
      if (model.hasAttribute('deleted_at'))
        'deleted_at': registry.encodeField(
          _$CombinedPostDeletedAtField,
          model.getAttribute<DateTime?>('deleted_at'),
        ),
      if (model.hasAttribute('created_at'))
        'created_at': registry.encodeField(
          _$CombinedPostCreatedAtField,
          model.getAttribute<DateTime?>('created_at'),
        ),
      if (model.hasAttribute('updated_at'))
        'updated_at': registry.encodeField(
          _$CombinedPostUpdatedAtField,
          model.getAttribute<DateTime?>('updated_at'),
        ),
    };
  }

  @override
  $CombinedPost decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final int combinedPostIdValue =
        registry.decodeField<int>(_$CombinedPostIdField, data['id']) ?? 0;
    final String combinedPostTitleValue =
        registry.decodeField<String>(_$CombinedPostTitleField, data['title']) ??
        (throw StateError('Field title on CombinedPost cannot be null.'));
    final DateTime? combinedPostDeletedAtValue = registry
        .decodeField<DateTime?>(
          _$CombinedPostDeletedAtField,
          data['deleted_at'],
        );
    final DateTime? combinedPostCreatedAtValue = registry
        .decodeField<DateTime?>(
          _$CombinedPostCreatedAtField,
          data['created_at'],
        );
    final DateTime? combinedPostUpdatedAtValue = registry
        .decodeField<DateTime?>(
          _$CombinedPostUpdatedAtField,
          data['updated_at'],
        );
    final model = $CombinedPost(
      id: combinedPostIdValue,
      title: combinedPostTitleValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': combinedPostIdValue,
      'title': combinedPostTitleValue,
      if (data.containsKey('deleted_at'))
        'deleted_at': combinedPostDeletedAtValue,
      if (data.containsKey('created_at'))
        'created_at': combinedPostCreatedAtValue,
      if (data.containsKey('updated_at'))
        'updated_at': combinedPostUpdatedAtValue,
    });
    return model;
  }
}

/// Insert DTO for [CombinedPost].
///
/// Auto-increment/DB-generated fields are omitted by default.
class CombinedPostInsertDto implements InsertDto<$CombinedPost> {
  const CombinedPostInsertDto({this.title});
  final String? title;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{if (title != null) 'title': title};
  }

  static const _CombinedPostInsertDtoCopyWithSentinel _copyWithSentinel =
      _CombinedPostInsertDtoCopyWithSentinel();
  CombinedPostInsertDto copyWith({Object? title = _copyWithSentinel}) {
    return CombinedPostInsertDto(
      title: identical(title, _copyWithSentinel)
          ? this.title
          : title as String?,
    );
  }
}

class _CombinedPostInsertDtoCopyWithSentinel {
  const _CombinedPostInsertDtoCopyWithSentinel();
}

/// Update DTO for [CombinedPost].
///
/// All fields are optional; only provided entries are used in SET clauses.
class CombinedPostUpdateDto implements UpdateDto<$CombinedPost> {
  const CombinedPostUpdateDto({this.id, this.title});
  final int? id;
  final String? title;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (title != null) 'title': title,
    };
  }

  static const _CombinedPostUpdateDtoCopyWithSentinel _copyWithSentinel =
      _CombinedPostUpdateDtoCopyWithSentinel();
  CombinedPostUpdateDto copyWith({
    Object? id = _copyWithSentinel,
    Object? title = _copyWithSentinel,
  }) {
    return CombinedPostUpdateDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      title: identical(title, _copyWithSentinel)
          ? this.title
          : title as String?,
    );
  }
}

class _CombinedPostUpdateDtoCopyWithSentinel {
  const _CombinedPostUpdateDtoCopyWithSentinel();
}

/// Partial projection for [CombinedPost].
///
/// All fields are nullable; intended for subset SELECTs.
class CombinedPostPartial implements PartialEntity<$CombinedPost> {
  const CombinedPostPartial({this.id, this.title});

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory CombinedPostPartial.fromRow(Map<String, Object?> row) {
    return CombinedPostPartial(
      id: row['id'] as int?,
      title: row['title'] as String?,
    );
  }

  final int? id;
  final String? title;

  @override
  $CombinedPost toEntity() {
    // Basic required-field check: non-nullable fields must be present.
    final int? idValue = id;
    if (idValue == null) {
      throw StateError('Missing required field: id');
    }
    final String? titleValue = title;
    if (titleValue == null) {
      throw StateError('Missing required field: title');
    }
    return $CombinedPost(id: idValue, title: titleValue);
  }

  @override
  Map<String, Object?> toMap() {
    return {if (id != null) 'id': id, if (title != null) 'title': title};
  }

  static const _CombinedPostPartialCopyWithSentinel _copyWithSentinel =
      _CombinedPostPartialCopyWithSentinel();
  CombinedPostPartial copyWith({
    Object? id = _copyWithSentinel,
    Object? title = _copyWithSentinel,
  }) {
    return CombinedPostPartial(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      title: identical(title, _copyWithSentinel)
          ? this.title
          : title as String?,
    );
  }
}

class _CombinedPostPartialCopyWithSentinel {
  const _CombinedPostPartialCopyWithSentinel();
}

/// Generated tracked model class for [CombinedPost].
///
/// This class extends the user-defined [CombinedPost] model and adds
/// attribute tracking, change detection, and relationship management.
/// Instances of this class are returned by queries and repositories.
///
/// **Do not instantiate this class directly.** Use queries, repositories,
/// or model factories to create tracked model instances.
class $CombinedPost extends CombinedPost
    with ModelAttributes, TimestampsImpl, SoftDeletesImpl
    implements OrmEntity {
  /// Internal constructor for [$CombinedPost].
  $CombinedPost({int id = 0, required String title})
    : super.new(id: id, title: title) {
    _attachOrmRuntimeMetadata({'id': id, 'title': title});
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $CombinedPost.fromModel(CombinedPost model) {
    return $CombinedPost(id: model.id, title: model.title);
  }

  $CombinedPost copyWith({int? id, String? title}) {
    return $CombinedPost(id: id ?? this.id, title: title ?? this.title);
  }

  /// Builds a tracked model from a column/value map.
  static $CombinedPost fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$CombinedPostDefinition.fromMap(data, registry: registry);

  /// Converts this tracked model to a column/value map.
  Map<String, Object?> toMap({ValueCodecRegistry? registry}) =>
      _$CombinedPostDefinition.toMap(this, registry: registry);

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

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$CombinedPostDefinition);
    attachSoftDeleteColumn('deleted_at');
  }
}

class _CombinedPostCopyWithSentinel {
  const _CombinedPostCopyWithSentinel();
}

extension CombinedPostOrmExtension on CombinedPost {
  static const _CombinedPostCopyWithSentinel _copyWithSentinel =
      _CombinedPostCopyWithSentinel();
  CombinedPost copyWith({
    Object? id = _copyWithSentinel,
    Object? title = _copyWithSentinel,
  }) {
    return CombinedPost.new(
      id: identical(id, _copyWithSentinel) ? this.id : id as int,
      title: identical(title, _copyWithSentinel) ? this.title : title as String,
    );
  }

  /// Converts this model to a column/value map.
  Map<String, Object?> toMap({ValueCodecRegistry? registry}) =>
      _$CombinedPostDefinition.toMap(this, registry: registry);

  /// Builds a model from a column/value map.
  static CombinedPost fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$CombinedPostDefinition.fromMap(data, registry: registry);

  /// The Type of the generated ORM-managed model class.
  /// Use this when you need to specify the tracked model type explicitly,
  /// for example in generic type parameters.
  static Type get trackedType => $CombinedPost;

  /// Converts this immutable model to a tracked ORM-managed model.
  /// The tracked model supports attribute tracking, change detection,
  /// and persistence operations like save() and touch().
  $CombinedPost toTracked() {
    return $CombinedPost.fromModel(this);
  }
}

extension CombinedPostPredicateFields on PredicateBuilder<CombinedPost> {
  PredicateField<CombinedPost, int> get id =>
      PredicateField<CombinedPost, int>(this, 'id');
  PredicateField<CombinedPost, String> get title =>
      PredicateField<CombinedPost, String>(this, 'title');
}

void registerCombinedPostEventHandlers(EventBus bus) {
  // No event handlers registered for CombinedPost.
}

const FieldDefinition _$CombinedPostTzIdField = FieldDefinition(
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

const FieldDefinition _$CombinedPostTzTitleField = FieldDefinition(
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

const FieldDefinition _$CombinedPostTzDeletedAtField = FieldDefinition(
  name: 'deletedAt',
  columnName: 'deleted_at',
  dartType: 'DateTime',
  resolvedType: 'DateTime?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$CombinedPostTzCreatedAtField = FieldDefinition(
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

const FieldDefinition _$CombinedPostTzUpdatedAtField = FieldDefinition(
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

Map<String, Object?> _encodeCombinedPostTzUntracked(
  Object model,
  ValueCodecRegistry registry,
) {
  final m = model as CombinedPostTz;
  return <String, Object?>{
    'id': registry.encodeField(_$CombinedPostTzIdField, m.id),
    'title': registry.encodeField(_$CombinedPostTzTitleField, m.title),
  };
}

final ModelDefinition<$CombinedPostTz> _$CombinedPostTzDefinition =
    ModelDefinition(
      modelName: 'CombinedPostTz',
      tableName: 'tz_posts',
      fields: const [
        _$CombinedPostTzIdField,
        _$CombinedPostTzTitleField,
        _$CombinedPostTzDeletedAtField,
        _$CombinedPostTzCreatedAtField,
        _$CombinedPostTzUpdatedAtField,
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
      untrackedToMap: _encodeCombinedPostTzUntracked,
      codec: _$CombinedPostTzCodec(),
    );

extension CombinedPostTzOrmDefinition on CombinedPostTz {
  static ModelDefinition<$CombinedPostTz> get definition =>
      _$CombinedPostTzDefinition;
}

class CombinedPostTzs {
  const CombinedPostTzs._();

  /// Starts building a query for [$CombinedPostTz].
  ///
  /// {@macro ormed.query}
  static Query<$CombinedPostTz> query([String? connection]) =>
      Model.query<$CombinedPostTz>(connection: connection);

  static Future<$CombinedPostTz?> find(Object id, {String? connection}) =>
      Model.find<$CombinedPostTz>(id, connection: connection);

  static Future<$CombinedPostTz> findOrFail(Object id, {String? connection}) =>
      Model.findOrFail<$CombinedPostTz>(id, connection: connection);

  static Future<List<$CombinedPostTz>> all({String? connection}) =>
      Model.all<$CombinedPostTz>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<$CombinedPostTz>(connection: connection);

  static Future<bool> anyExist({String? connection}) =>
      Model.anyExist<$CombinedPostTz>(connection: connection);

  static Query<$CombinedPostTz> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) => Model.where<$CombinedPostTz>(
    column,
    operator,
    value,
    connection: connection,
  );

  static Query<$CombinedPostTz> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<$CombinedPostTz>(column, values, connection: connection);

  static Query<$CombinedPostTz> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<$CombinedPostTz>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<$CombinedPostTz> limit(int count, {String? connection}) =>
      Model.limit<$CombinedPostTz>(count, connection: connection);

  /// Creates a [Repository] for [$CombinedPostTz].
  ///
  /// {@macro ormed.repository}
  static Repository<$CombinedPostTz> repo([String? connection]) =>
      Model.repository<$CombinedPostTz>(connection: connection);

  /// Builds a tracked model from a column/value map.
  static $CombinedPostTz fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$CombinedPostTzDefinition.fromMap(data, registry: registry);

  /// Converts a tracked model to a column/value map.
  static Map<String, Object?> toMap(
    $CombinedPostTz model, {
    ValueCodecRegistry? registry,
  }) => _$CombinedPostTzDefinition.toMap(model, registry: registry);
}

class CombinedPostTzModelFactory {
  const CombinedPostTzModelFactory._();

  static ModelDefinition<$CombinedPostTz> get definition =>
      _$CombinedPostTzDefinition;

  static ModelCodec<$CombinedPostTz> get codec => definition.codec;

  static CombinedPostTz fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    CombinedPostTz model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model.toTracked(), registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<CombinedPostTz> withConnection(
    QueryContext context,
  ) => ModelFactoryConnection<CombinedPostTz>(
    definition: definition,
    context: context,
  );

  static ModelFactoryBuilder<CombinedPostTz> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<CombinedPostTz>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$CombinedPostTzCodec extends ModelCodec<$CombinedPostTz> {
  const _$CombinedPostTzCodec();
  @override
  Map<String, Object?> encode(
    $CombinedPostTz model,
    ValueCodecRegistry registry,
  ) {
    return <String, Object?>{
      'id': registry.encodeField(_$CombinedPostTzIdField, model.id),
      'title': registry.encodeField(_$CombinedPostTzTitleField, model.title),
      if (model.hasAttribute('deleted_at'))
        'deleted_at': registry.encodeField(
          _$CombinedPostTzDeletedAtField,
          model.getAttribute<DateTime?>('deleted_at'),
        ),
      if (model.hasAttribute('created_at'))
        'created_at': registry.encodeField(
          _$CombinedPostTzCreatedAtField,
          model.getAttribute<DateTime?>('created_at'),
        ),
      if (model.hasAttribute('updated_at'))
        'updated_at': registry.encodeField(
          _$CombinedPostTzUpdatedAtField,
          model.getAttribute<DateTime?>('updated_at'),
        ),
    };
  }

  @override
  $CombinedPostTz decode(
    Map<String, Object?> data,
    ValueCodecRegistry registry,
  ) {
    final int combinedPostTzIdValue =
        registry.decodeField<int>(_$CombinedPostTzIdField, data['id']) ?? 0;
    final String combinedPostTzTitleValue =
        registry.decodeField<String>(
          _$CombinedPostTzTitleField,
          data['title'],
        ) ??
        (throw StateError('Field title on CombinedPostTz cannot be null.'));
    final DateTime? combinedPostTzDeletedAtValue = registry
        .decodeField<DateTime?>(
          _$CombinedPostTzDeletedAtField,
          data['deleted_at'],
        );
    final DateTime? combinedPostTzCreatedAtValue = registry
        .decodeField<DateTime?>(
          _$CombinedPostTzCreatedAtField,
          data['created_at'],
        );
    final DateTime? combinedPostTzUpdatedAtValue = registry
        .decodeField<DateTime?>(
          _$CombinedPostTzUpdatedAtField,
          data['updated_at'],
        );
    final model = $CombinedPostTz(
      id: combinedPostTzIdValue,
      title: combinedPostTzTitleValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': combinedPostTzIdValue,
      'title': combinedPostTzTitleValue,
      if (data.containsKey('deleted_at'))
        'deleted_at': combinedPostTzDeletedAtValue,
      if (data.containsKey('created_at'))
        'created_at': combinedPostTzCreatedAtValue,
      if (data.containsKey('updated_at'))
        'updated_at': combinedPostTzUpdatedAtValue,
    });
    return model;
  }
}

/// Insert DTO for [CombinedPostTz].
///
/// Auto-increment/DB-generated fields are omitted by default.
class CombinedPostTzInsertDto implements InsertDto<$CombinedPostTz> {
  const CombinedPostTzInsertDto({this.title});
  final String? title;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{if (title != null) 'title': title};
  }

  static const _CombinedPostTzInsertDtoCopyWithSentinel _copyWithSentinel =
      _CombinedPostTzInsertDtoCopyWithSentinel();
  CombinedPostTzInsertDto copyWith({Object? title = _copyWithSentinel}) {
    return CombinedPostTzInsertDto(
      title: identical(title, _copyWithSentinel)
          ? this.title
          : title as String?,
    );
  }
}

class _CombinedPostTzInsertDtoCopyWithSentinel {
  const _CombinedPostTzInsertDtoCopyWithSentinel();
}

/// Update DTO for [CombinedPostTz].
///
/// All fields are optional; only provided entries are used in SET clauses.
class CombinedPostTzUpdateDto implements UpdateDto<$CombinedPostTz> {
  const CombinedPostTzUpdateDto({this.id, this.title});
  final int? id;
  final String? title;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (title != null) 'title': title,
    };
  }

  static const _CombinedPostTzUpdateDtoCopyWithSentinel _copyWithSentinel =
      _CombinedPostTzUpdateDtoCopyWithSentinel();
  CombinedPostTzUpdateDto copyWith({
    Object? id = _copyWithSentinel,
    Object? title = _copyWithSentinel,
  }) {
    return CombinedPostTzUpdateDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      title: identical(title, _copyWithSentinel)
          ? this.title
          : title as String?,
    );
  }
}

class _CombinedPostTzUpdateDtoCopyWithSentinel {
  const _CombinedPostTzUpdateDtoCopyWithSentinel();
}

/// Partial projection for [CombinedPostTz].
///
/// All fields are nullable; intended for subset SELECTs.
class CombinedPostTzPartial implements PartialEntity<$CombinedPostTz> {
  const CombinedPostTzPartial({this.id, this.title});

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory CombinedPostTzPartial.fromRow(Map<String, Object?> row) {
    return CombinedPostTzPartial(
      id: row['id'] as int?,
      title: row['title'] as String?,
    );
  }

  final int? id;
  final String? title;

  @override
  $CombinedPostTz toEntity() {
    // Basic required-field check: non-nullable fields must be present.
    final int? idValue = id;
    if (idValue == null) {
      throw StateError('Missing required field: id');
    }
    final String? titleValue = title;
    if (titleValue == null) {
      throw StateError('Missing required field: title');
    }
    return $CombinedPostTz(id: idValue, title: titleValue);
  }

  @override
  Map<String, Object?> toMap() {
    return {if (id != null) 'id': id, if (title != null) 'title': title};
  }

  static const _CombinedPostTzPartialCopyWithSentinel _copyWithSentinel =
      _CombinedPostTzPartialCopyWithSentinel();
  CombinedPostTzPartial copyWith({
    Object? id = _copyWithSentinel,
    Object? title = _copyWithSentinel,
  }) {
    return CombinedPostTzPartial(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      title: identical(title, _copyWithSentinel)
          ? this.title
          : title as String?,
    );
  }
}

class _CombinedPostTzPartialCopyWithSentinel {
  const _CombinedPostTzPartialCopyWithSentinel();
}

/// Generated tracked model class for [CombinedPostTz].
///
/// This class extends the user-defined [CombinedPostTz] model and adds
/// attribute tracking, change detection, and relationship management.
/// Instances of this class are returned by queries and repositories.
///
/// **Do not instantiate this class directly.** Use queries, repositories,
/// or model factories to create tracked model instances.
class $CombinedPostTz extends CombinedPostTz
    with ModelAttributes, TimestampsTZImpl, SoftDeletesTZImpl
    implements OrmEntity {
  /// Internal constructor for [$CombinedPostTz].
  $CombinedPostTz({int id = 0, required String title})
    : super.new(id: id, title: title) {
    _attachOrmRuntimeMetadata({'id': id, 'title': title});
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $CombinedPostTz.fromModel(CombinedPostTz model) {
    return $CombinedPostTz(id: model.id, title: model.title);
  }

  $CombinedPostTz copyWith({int? id, String? title}) {
    return $CombinedPostTz(id: id ?? this.id, title: title ?? this.title);
  }

  /// Builds a tracked model from a column/value map.
  static $CombinedPostTz fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$CombinedPostTzDefinition.fromMap(data, registry: registry);

  /// Converts this tracked model to a column/value map.
  Map<String, Object?> toMap({ValueCodecRegistry? registry}) =>
      _$CombinedPostTzDefinition.toMap(this, registry: registry);

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

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$CombinedPostTzDefinition);
  }
}

class _CombinedPostTzCopyWithSentinel {
  const _CombinedPostTzCopyWithSentinel();
}

extension CombinedPostTzOrmExtension on CombinedPostTz {
  static const _CombinedPostTzCopyWithSentinel _copyWithSentinel =
      _CombinedPostTzCopyWithSentinel();
  CombinedPostTz copyWith({
    Object? id = _copyWithSentinel,
    Object? title = _copyWithSentinel,
  }) {
    return CombinedPostTz.new(
      id: identical(id, _copyWithSentinel) ? this.id : id as int,
      title: identical(title, _copyWithSentinel) ? this.title : title as String,
    );
  }

  /// Converts this model to a column/value map.
  Map<String, Object?> toMap({ValueCodecRegistry? registry}) =>
      _$CombinedPostTzDefinition.toMap(this, registry: registry);

  /// Builds a model from a column/value map.
  static CombinedPostTz fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$CombinedPostTzDefinition.fromMap(data, registry: registry);

  /// The Type of the generated ORM-managed model class.
  /// Use this when you need to specify the tracked model type explicitly,
  /// for example in generic type parameters.
  static Type get trackedType => $CombinedPostTz;

  /// Converts this immutable model to a tracked ORM-managed model.
  /// The tracked model supports attribute tracking, change detection,
  /// and persistence operations like save() and touch().
  $CombinedPostTz toTracked() {
    return $CombinedPostTz.fromModel(this);
  }
}

extension CombinedPostTzPredicateFields on PredicateBuilder<CombinedPostTz> {
  PredicateField<CombinedPostTz, int> get id =>
      PredicateField<CombinedPostTz, int>(this, 'id');
  PredicateField<CombinedPostTz, String> get title =>
      PredicateField<CombinedPostTz, String>(this, 'title');
}

void registerCombinedPostTzEventHandlers(EventBus bus) {
  // No event handlers registered for CombinedPostTz.
}
