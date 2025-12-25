// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'soft_delete_model.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$SoftDeletePostIdField = FieldDefinition(
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

const FieldDefinition _$SoftDeletePostTitleField = FieldDefinition(
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

const FieldDefinition _$SoftDeletePostDeletedAtField = FieldDefinition(
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

Map<String, Object?> _encodeSoftDeletePostUntracked(
  Object model,
  ValueCodecRegistry registry,
) {
  final m = model as SoftDeletePost;
  return <String, Object?>{
    'id': registry.encodeField(_$SoftDeletePostIdField, m.id),
    'title': registry.encodeField(_$SoftDeletePostTitleField, m.title),
  };
}

final ModelDefinition<$SoftDeletePost> _$SoftDeletePostDefinition =
    ModelDefinition(
      modelName: 'SoftDeletePost',
      tableName: 'posts',
      fields: const [
        _$SoftDeletePostIdField,
        _$SoftDeletePostTitleField,
        _$SoftDeletePostDeletedAtField,
      ],
      relations: const [],
      softDeleteColumn: 'deleted_at',
      metadata: ModelAttributesMetadata(
        hidden: const <String>[],
        visible: const <String>[],
        fillable: const <String>[],
        guarded: const <String>[],
        casts: const <String, String>{},
        softDeletes: true,
        softDeleteColumn: 'deleted_at',
      ),
      untrackedToMap: _encodeSoftDeletePostUntracked,
      codec: _$SoftDeletePostCodec(),
    );

extension SoftDeletePostOrmDefinition on SoftDeletePost {
  static ModelDefinition<$SoftDeletePost> get definition =>
      _$SoftDeletePostDefinition;
}

class SoftDeletePosts {
  const SoftDeletePosts._();

  /// Starts building a query for [$SoftDeletePost].
  ///
  /// {@macro ormed.query}
  static Query<$SoftDeletePost> query([String? connection]) =>
      Model.query<$SoftDeletePost>(connection: connection);

  static Future<$SoftDeletePost?> find(Object id, {String? connection}) =>
      Model.find<$SoftDeletePost>(id, connection: connection);

  static Future<$SoftDeletePost> findOrFail(Object id, {String? connection}) =>
      Model.findOrFail<$SoftDeletePost>(id, connection: connection);

  static Future<List<$SoftDeletePost>> all({String? connection}) =>
      Model.all<$SoftDeletePost>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<$SoftDeletePost>(connection: connection);

  static Future<bool> anyExist({String? connection}) =>
      Model.anyExist<$SoftDeletePost>(connection: connection);

  static Query<$SoftDeletePost> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) => Model.where<$SoftDeletePost>(
    column,
    operator,
    value,
    connection: connection,
  );

  static Query<$SoftDeletePost> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<$SoftDeletePost>(column, values, connection: connection);

  static Query<$SoftDeletePost> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<$SoftDeletePost>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<$SoftDeletePost> limit(int count, {String? connection}) =>
      Model.limit<$SoftDeletePost>(count, connection: connection);

  /// Creates a [Repository] for [$SoftDeletePost].
  ///
  /// {@macro ormed.repository}
  static Repository<$SoftDeletePost> repo([String? connection]) =>
      Model.repository<$SoftDeletePost>(connection: connection);
}

class SoftDeletePostModelFactory {
  const SoftDeletePostModelFactory._();

  static ModelDefinition<$SoftDeletePost> get definition =>
      _$SoftDeletePostDefinition;

  static ModelCodec<$SoftDeletePost> get codec => definition.codec;

  static SoftDeletePost fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    SoftDeletePost model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model.toTracked(), registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<SoftDeletePost> withConnection(
    QueryContext context,
  ) => ModelFactoryConnection<SoftDeletePost>(
    definition: definition,
    context: context,
  );

  static ModelFactoryBuilder<SoftDeletePost> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<SoftDeletePost>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$SoftDeletePostCodec extends ModelCodec<$SoftDeletePost> {
  const _$SoftDeletePostCodec();
  @override
  Map<String, Object?> encode(
    $SoftDeletePost model,
    ValueCodecRegistry registry,
  ) {
    return <String, Object?>{
      'id': registry.encodeField(_$SoftDeletePostIdField, model.id),
      'title': registry.encodeField(_$SoftDeletePostTitleField, model.title),
      'deleted_at': registry.encodeField(
        _$SoftDeletePostDeletedAtField,
        model.getAttribute<DateTime?>('deleted_at'),
      ),
    };
  }

  @override
  $SoftDeletePost decode(
    Map<String, Object?> data,
    ValueCodecRegistry registry,
  ) {
    final int softDeletePostIdValue =
        registry.decodeField<int>(_$SoftDeletePostIdField, data['id']) ?? 0;
    final String softDeletePostTitleValue =
        registry.decodeField<String>(
          _$SoftDeletePostTitleField,
          data['title'],
        ) ??
        (throw StateError('Field title on SoftDeletePost cannot be null.'));
    final DateTime? softDeletePostDeletedAtValue = registry
        .decodeField<DateTime?>(
          _$SoftDeletePostDeletedAtField,
          data['deleted_at'],
        );
    final model = $SoftDeletePost(
      id: softDeletePostIdValue,
      title: softDeletePostTitleValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': softDeletePostIdValue,
      'title': softDeletePostTitleValue,
      'deleted_at': softDeletePostDeletedAtValue,
    });
    return model;
  }
}

/// Insert DTO for [SoftDeletePost].
///
/// Auto-increment/DB-generated fields are omitted by default.
class SoftDeletePostInsertDto implements InsertDto<$SoftDeletePost> {
  const SoftDeletePostInsertDto({this.title});
  final String? title;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{if (title != null) 'title': title};
  }

  static const _SoftDeletePostInsertDtoCopyWithSentinel _copyWithSentinel =
      _SoftDeletePostInsertDtoCopyWithSentinel();
  SoftDeletePostInsertDto copyWith({Object? title = _copyWithSentinel}) {
    return SoftDeletePostInsertDto(
      title: identical(title, _copyWithSentinel)
          ? this.title
          : title as String?,
    );
  }
}

class _SoftDeletePostInsertDtoCopyWithSentinel {
  const _SoftDeletePostInsertDtoCopyWithSentinel();
}

/// Update DTO for [SoftDeletePost].
///
/// All fields are optional; only provided entries are used in SET clauses.
class SoftDeletePostUpdateDto implements UpdateDto<$SoftDeletePost> {
  const SoftDeletePostUpdateDto({this.id, this.title});
  final int? id;
  final String? title;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (title != null) 'title': title,
    };
  }

  static const _SoftDeletePostUpdateDtoCopyWithSentinel _copyWithSentinel =
      _SoftDeletePostUpdateDtoCopyWithSentinel();
  SoftDeletePostUpdateDto copyWith({
    Object? id = _copyWithSentinel,
    Object? title = _copyWithSentinel,
  }) {
    return SoftDeletePostUpdateDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      title: identical(title, _copyWithSentinel)
          ? this.title
          : title as String?,
    );
  }
}

class _SoftDeletePostUpdateDtoCopyWithSentinel {
  const _SoftDeletePostUpdateDtoCopyWithSentinel();
}

/// Partial projection for [SoftDeletePost].
///
/// All fields are nullable; intended for subset SELECTs.
class SoftDeletePostPartial implements PartialEntity<$SoftDeletePost> {
  const SoftDeletePostPartial({this.id, this.title});

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory SoftDeletePostPartial.fromRow(Map<String, Object?> row) {
    return SoftDeletePostPartial(
      id: row['id'] as int?,
      title: row['title'] as String?,
    );
  }

  final int? id;
  final String? title;

  @override
  $SoftDeletePost toEntity() {
    // Basic required-field check: non-nullable fields must be present.
    final int? idValue = id;
    if (idValue == null) {
      throw StateError('Missing required field: id');
    }
    final String? titleValue = title;
    if (titleValue == null) {
      throw StateError('Missing required field: title');
    }
    return $SoftDeletePost(id: idValue, title: titleValue);
  }

  @override
  Map<String, Object?> toMap() {
    return {if (id != null) 'id': id, if (title != null) 'title': title};
  }

  static const _SoftDeletePostPartialCopyWithSentinel _copyWithSentinel =
      _SoftDeletePostPartialCopyWithSentinel();
  SoftDeletePostPartial copyWith({
    Object? id = _copyWithSentinel,
    Object? title = _copyWithSentinel,
  }) {
    return SoftDeletePostPartial(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      title: identical(title, _copyWithSentinel)
          ? this.title
          : title as String?,
    );
  }
}

class _SoftDeletePostPartialCopyWithSentinel {
  const _SoftDeletePostPartialCopyWithSentinel();
}

/// Generated tracked model class for [SoftDeletePost].
///
/// This class extends the user-defined [SoftDeletePost] model and adds
/// attribute tracking, change detection, and relationship management.
/// Instances of this class are returned by queries and repositories.
///
/// **Do not instantiate this class directly.** Use queries, repositories,
/// or model factories to create tracked model instances.
class $SoftDeletePost extends SoftDeletePost
    with ModelAttributes, SoftDeletesImpl
    implements OrmEntity {
  /// Internal constructor for [$SoftDeletePost].
  $SoftDeletePost({int id = 0, required String title})
    : super.new(id: id, title: title) {
    _attachOrmRuntimeMetadata({'id': id, 'title': title});
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $SoftDeletePost.fromModel(SoftDeletePost model) {
    return $SoftDeletePost(id: model.id, title: model.title);
  }

  $SoftDeletePost copyWith({int? id, String? title}) {
    return $SoftDeletePost(id: id ?? this.id, title: title ?? this.title);
  }

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
    attachModelDefinition(_$SoftDeletePostDefinition);
    attachSoftDeleteColumn('deleted_at');
  }
}

extension SoftDeletePostOrmExtension on SoftDeletePost {
  /// The Type of the generated ORM-managed model class.
  /// Use this when you need to specify the tracked model type explicitly,
  /// for example in generic type parameters.
  static Type get trackedType => $SoftDeletePost;

  /// Converts this immutable model to a tracked ORM-managed model.
  /// The tracked model supports attribute tracking, change detection,
  /// and persistence operations like save() and touch().
  $SoftDeletePost toTracked() {
    return $SoftDeletePost.fromModel(this);
  }
}

void registerSoftDeletePostEventHandlers(EventBus bus) {
  // No event handlers registered for SoftDeletePost.
}

const FieldDefinition _$SoftDeleteArticleTzIdField = FieldDefinition(
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

const FieldDefinition _$SoftDeleteArticleTzTitleField = FieldDefinition(
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

const FieldDefinition _$SoftDeleteArticleTzDeletedAtField = FieldDefinition(
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

Map<String, Object?> _encodeSoftDeleteArticleTzUntracked(
  Object model,
  ValueCodecRegistry registry,
) {
  final m = model as SoftDeleteArticleTz;
  return <String, Object?>{
    'id': registry.encodeField(_$SoftDeleteArticleTzIdField, m.id),
    'title': registry.encodeField(_$SoftDeleteArticleTzTitleField, m.title),
  };
}

final ModelDefinition<$SoftDeleteArticleTz> _$SoftDeleteArticleTzDefinition =
    ModelDefinition(
      modelName: 'SoftDeleteArticleTz',
      tableName: 'articles',
      fields: const [
        _$SoftDeleteArticleTzIdField,
        _$SoftDeleteArticleTzTitleField,
        _$SoftDeleteArticleTzDeletedAtField,
      ],
      relations: const [],
      softDeleteColumn: 'deleted_at',
      metadata: ModelAttributesMetadata(
        hidden: const <String>[],
        visible: const <String>[],
        fillable: const <String>[],
        guarded: const <String>[],
        casts: const <String, String>{},
        softDeletes: false,
        softDeleteColumn: 'deleted_at',
      ),
      untrackedToMap: _encodeSoftDeleteArticleTzUntracked,
      codec: _$SoftDeleteArticleTzCodec(),
    );

extension SoftDeleteArticleTzOrmDefinition on SoftDeleteArticleTz {
  static ModelDefinition<$SoftDeleteArticleTz> get definition =>
      _$SoftDeleteArticleTzDefinition;
}

class SoftDeleteArticleTzs {
  const SoftDeleteArticleTzs._();

  /// Starts building a query for [$SoftDeleteArticleTz].
  ///
  /// {@macro ormed.query}
  static Query<$SoftDeleteArticleTz> query([String? connection]) =>
      Model.query<$SoftDeleteArticleTz>(connection: connection);

  static Future<$SoftDeleteArticleTz?> find(Object id, {String? connection}) =>
      Model.find<$SoftDeleteArticleTz>(id, connection: connection);

  static Future<$SoftDeleteArticleTz> findOrFail(
    Object id, {
    String? connection,
  }) => Model.findOrFail<$SoftDeleteArticleTz>(id, connection: connection);

  static Future<List<$SoftDeleteArticleTz>> all({String? connection}) =>
      Model.all<$SoftDeleteArticleTz>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<$SoftDeleteArticleTz>(connection: connection);

  static Future<bool> anyExist({String? connection}) =>
      Model.anyExist<$SoftDeleteArticleTz>(connection: connection);

  static Query<$SoftDeleteArticleTz> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) => Model.where<$SoftDeleteArticleTz>(
    column,
    operator,
    value,
    connection: connection,
  );

  static Query<$SoftDeleteArticleTz> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<$SoftDeleteArticleTz>(
    column,
    values,
    connection: connection,
  );

  static Query<$SoftDeleteArticleTz> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<$SoftDeleteArticleTz>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<$SoftDeleteArticleTz> limit(int count, {String? connection}) =>
      Model.limit<$SoftDeleteArticleTz>(count, connection: connection);

  /// Creates a [Repository] for [$SoftDeleteArticleTz].
  ///
  /// {@macro ormed.repository}
  static Repository<$SoftDeleteArticleTz> repo([String? connection]) =>
      Model.repository<$SoftDeleteArticleTz>(connection: connection);
}

class SoftDeleteArticleTzModelFactory {
  const SoftDeleteArticleTzModelFactory._();

  static ModelDefinition<$SoftDeleteArticleTz> get definition =>
      _$SoftDeleteArticleTzDefinition;

  static ModelCodec<$SoftDeleteArticleTz> get codec => definition.codec;

  static SoftDeleteArticleTz fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    SoftDeleteArticleTz model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model.toTracked(), registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<SoftDeleteArticleTz> withConnection(
    QueryContext context,
  ) => ModelFactoryConnection<SoftDeleteArticleTz>(
    definition: definition,
    context: context,
  );

  static ModelFactoryBuilder<SoftDeleteArticleTz> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<SoftDeleteArticleTz>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$SoftDeleteArticleTzCodec extends ModelCodec<$SoftDeleteArticleTz> {
  const _$SoftDeleteArticleTzCodec();
  @override
  Map<String, Object?> encode(
    $SoftDeleteArticleTz model,
    ValueCodecRegistry registry,
  ) {
    return <String, Object?>{
      'id': registry.encodeField(_$SoftDeleteArticleTzIdField, model.id),
      'title': registry.encodeField(
        _$SoftDeleteArticleTzTitleField,
        model.title,
      ),
      'deleted_at': registry.encodeField(
        _$SoftDeleteArticleTzDeletedAtField,
        model.getAttribute<DateTime?>('deleted_at'),
      ),
    };
  }

  @override
  $SoftDeleteArticleTz decode(
    Map<String, Object?> data,
    ValueCodecRegistry registry,
  ) {
    final int softDeleteArticleTzIdValue =
        registry.decodeField<int>(_$SoftDeleteArticleTzIdField, data['id']) ??
        0;
    final String softDeleteArticleTzTitleValue =
        registry.decodeField<String>(
          _$SoftDeleteArticleTzTitleField,
          data['title'],
        ) ??
        (throw StateError(
          'Field title on SoftDeleteArticleTz cannot be null.',
        ));
    final DateTime? softDeleteArticleTzDeletedAtValue = registry
        .decodeField<DateTime?>(
          _$SoftDeleteArticleTzDeletedAtField,
          data['deleted_at'],
        );
    final model = $SoftDeleteArticleTz(
      id: softDeleteArticleTzIdValue,
      title: softDeleteArticleTzTitleValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': softDeleteArticleTzIdValue,
      'title': softDeleteArticleTzTitleValue,
      'deleted_at': softDeleteArticleTzDeletedAtValue,
    });
    return model;
  }
}

/// Insert DTO for [SoftDeleteArticleTz].
///
/// Auto-increment/DB-generated fields are omitted by default.
class SoftDeleteArticleTzInsertDto implements InsertDto<$SoftDeleteArticleTz> {
  const SoftDeleteArticleTzInsertDto({this.title});
  final String? title;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{if (title != null) 'title': title};
  }

  static const _SoftDeleteArticleTzInsertDtoCopyWithSentinel _copyWithSentinel =
      _SoftDeleteArticleTzInsertDtoCopyWithSentinel();
  SoftDeleteArticleTzInsertDto copyWith({Object? title = _copyWithSentinel}) {
    return SoftDeleteArticleTzInsertDto(
      title: identical(title, _copyWithSentinel)
          ? this.title
          : title as String?,
    );
  }
}

class _SoftDeleteArticleTzInsertDtoCopyWithSentinel {
  const _SoftDeleteArticleTzInsertDtoCopyWithSentinel();
}

/// Update DTO for [SoftDeleteArticleTz].
///
/// All fields are optional; only provided entries are used in SET clauses.
class SoftDeleteArticleTzUpdateDto implements UpdateDto<$SoftDeleteArticleTz> {
  const SoftDeleteArticleTzUpdateDto({this.id, this.title});
  final int? id;
  final String? title;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (title != null) 'title': title,
    };
  }

  static const _SoftDeleteArticleTzUpdateDtoCopyWithSentinel _copyWithSentinel =
      _SoftDeleteArticleTzUpdateDtoCopyWithSentinel();
  SoftDeleteArticleTzUpdateDto copyWith({
    Object? id = _copyWithSentinel,
    Object? title = _copyWithSentinel,
  }) {
    return SoftDeleteArticleTzUpdateDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      title: identical(title, _copyWithSentinel)
          ? this.title
          : title as String?,
    );
  }
}

class _SoftDeleteArticleTzUpdateDtoCopyWithSentinel {
  const _SoftDeleteArticleTzUpdateDtoCopyWithSentinel();
}

/// Partial projection for [SoftDeleteArticleTz].
///
/// All fields are nullable; intended for subset SELECTs.
class SoftDeleteArticleTzPartial
    implements PartialEntity<$SoftDeleteArticleTz> {
  const SoftDeleteArticleTzPartial({this.id, this.title});

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory SoftDeleteArticleTzPartial.fromRow(Map<String, Object?> row) {
    return SoftDeleteArticleTzPartial(
      id: row['id'] as int?,
      title: row['title'] as String?,
    );
  }

  final int? id;
  final String? title;

  @override
  $SoftDeleteArticleTz toEntity() {
    // Basic required-field check: non-nullable fields must be present.
    final int? idValue = id;
    if (idValue == null) {
      throw StateError('Missing required field: id');
    }
    final String? titleValue = title;
    if (titleValue == null) {
      throw StateError('Missing required field: title');
    }
    return $SoftDeleteArticleTz(id: idValue, title: titleValue);
  }

  @override
  Map<String, Object?> toMap() {
    return {if (id != null) 'id': id, if (title != null) 'title': title};
  }

  static const _SoftDeleteArticleTzPartialCopyWithSentinel _copyWithSentinel =
      _SoftDeleteArticleTzPartialCopyWithSentinel();
  SoftDeleteArticleTzPartial copyWith({
    Object? id = _copyWithSentinel,
    Object? title = _copyWithSentinel,
  }) {
    return SoftDeleteArticleTzPartial(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      title: identical(title, _copyWithSentinel)
          ? this.title
          : title as String?,
    );
  }
}

class _SoftDeleteArticleTzPartialCopyWithSentinel {
  const _SoftDeleteArticleTzPartialCopyWithSentinel();
}

/// Generated tracked model class for [SoftDeleteArticleTz].
///
/// This class extends the user-defined [SoftDeleteArticleTz] model and adds
/// attribute tracking, change detection, and relationship management.
/// Instances of this class are returned by queries and repositories.
///
/// **Do not instantiate this class directly.** Use queries, repositories,
/// or model factories to create tracked model instances.
class $SoftDeleteArticleTz extends SoftDeleteArticleTz
    with ModelAttributes, SoftDeletesTZImpl
    implements OrmEntity {
  /// Internal constructor for [$SoftDeleteArticleTz].
  $SoftDeleteArticleTz({int id = 0, required String title})
    : super.new(id: id, title: title) {
    _attachOrmRuntimeMetadata({'id': id, 'title': title});
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $SoftDeleteArticleTz.fromModel(SoftDeleteArticleTz model) {
    return $SoftDeleteArticleTz(id: model.id, title: model.title);
  }

  $SoftDeleteArticleTz copyWith({int? id, String? title}) {
    return $SoftDeleteArticleTz(id: id ?? this.id, title: title ?? this.title);
  }

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
    attachModelDefinition(_$SoftDeleteArticleTzDefinition);
  }
}

extension SoftDeleteArticleTzOrmExtension on SoftDeleteArticleTz {
  /// The Type of the generated ORM-managed model class.
  /// Use this when you need to specify the tracked model type explicitly,
  /// for example in generic type parameters.
  static Type get trackedType => $SoftDeleteArticleTz;

  /// Converts this immutable model to a tracked ORM-managed model.
  /// The tracked model supports attribute tracking, change detection,
  /// and persistence operations like save() and touch().
  $SoftDeleteArticleTz toTracked() {
    return $SoftDeleteArticleTz.fromModel(this);
  }
}

void registerSoftDeleteArticleTzEventHandlers(EventBus bus) {
  // No event handlers registered for SoftDeleteArticleTz.
}
