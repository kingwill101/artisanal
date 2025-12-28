// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'timestamp_model.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$TimestampPostIdField = FieldDefinition(
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

const FieldDefinition _$TimestampPostTitleField = FieldDefinition(
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

const FieldDefinition _$TimestampPostCreatedAtField = FieldDefinition(
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

const FieldDefinition _$TimestampPostUpdatedAtField = FieldDefinition(
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

Map<String, Object?> _encodeTimestampPostUntracked(
  Object model,
  ValueCodecRegistry registry,
) {
  final m = model as TimestampPost;
  return <String, Object?>{
    'id': registry.encodeField(_$TimestampPostIdField, m.id),
    'title': registry.encodeField(_$TimestampPostTitleField, m.title),
  };
}

final ModelDefinition<$TimestampPost> _$TimestampPostDefinition =
    ModelDefinition(
      modelName: 'TimestampPost',
      tableName: 'posts',
      fields: const [
        _$TimestampPostIdField,
        _$TimestampPostTitleField,
        _$TimestampPostCreatedAtField,
        _$TimestampPostUpdatedAtField,
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
      untrackedToMap: _encodeTimestampPostUntracked,
      codec: _$TimestampPostCodec(),
    );

extension TimestampPostOrmDefinition on TimestampPost {
  static ModelDefinition<$TimestampPost> get definition =>
      _$TimestampPostDefinition;
}

class TimestampPosts {
  const TimestampPosts._();

  /// Starts building a query for [$TimestampPost].
  ///
  /// {@macro ormed.query}
  static Query<$TimestampPost> query([String? connection]) =>
      Model.query<$TimestampPost>(connection: connection);

  static Future<$TimestampPost?> find(Object id, {String? connection}) =>
      Model.find<$TimestampPost>(id, connection: connection);

  static Future<$TimestampPost> findOrFail(Object id, {String? connection}) =>
      Model.findOrFail<$TimestampPost>(id, connection: connection);

  static Future<List<$TimestampPost>> all({String? connection}) =>
      Model.all<$TimestampPost>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<$TimestampPost>(connection: connection);

  static Future<bool> anyExist({String? connection}) =>
      Model.anyExist<$TimestampPost>(connection: connection);

  static Query<$TimestampPost> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) => Model.where<$TimestampPost>(
    column,
    operator,
    value,
    connection: connection,
  );

  static Query<$TimestampPost> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<$TimestampPost>(column, values, connection: connection);

  static Query<$TimestampPost> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<$TimestampPost>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<$TimestampPost> limit(int count, {String? connection}) =>
      Model.limit<$TimestampPost>(count, connection: connection);

  /// Creates a [Repository] for [$TimestampPost].
  ///
  /// {@macro ormed.repository}
  static Repository<$TimestampPost> repo([String? connection]) =>
      Model.repository<$TimestampPost>(connection: connection);
}

class TimestampPostModelFactory {
  const TimestampPostModelFactory._();

  static ModelDefinition<$TimestampPost> get definition =>
      _$TimestampPostDefinition;

  static ModelCodec<$TimestampPost> get codec => definition.codec;

  static TimestampPost fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    TimestampPost model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model.toTracked(), registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<TimestampPost> withConnection(
    QueryContext context,
  ) => ModelFactoryConnection<TimestampPost>(
    definition: definition,
    context: context,
  );

  static ModelFactoryBuilder<TimestampPost> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<TimestampPost>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$TimestampPostCodec extends ModelCodec<$TimestampPost> {
  const _$TimestampPostCodec();
  @override
  Map<String, Object?> encode(
    $TimestampPost model,
    ValueCodecRegistry registry,
  ) {
    return <String, Object?>{
      'id': registry.encodeField(_$TimestampPostIdField, model.id),
      'title': registry.encodeField(_$TimestampPostTitleField, model.title),
      if (model.hasAttribute('created_at'))
        'created_at': registry.encodeField(
          _$TimestampPostCreatedAtField,
          model.getAttribute<DateTime?>('created_at'),
        ),
      if (model.hasAttribute('updated_at'))
        'updated_at': registry.encodeField(
          _$TimestampPostUpdatedAtField,
          model.getAttribute<DateTime?>('updated_at'),
        ),
    };
  }

  @override
  $TimestampPost decode(
    Map<String, Object?> data,
    ValueCodecRegistry registry,
  ) {
    final int timestampPostIdValue =
        registry.decodeField<int>(_$TimestampPostIdField, data['id']) ?? 0;
    final String timestampPostTitleValue =
        registry.decodeField<String>(
          _$TimestampPostTitleField,
          data['title'],
        ) ??
        (throw StateError('Field title on TimestampPost cannot be null.'));
    final DateTime? timestampPostCreatedAtValue = registry
        .decodeField<DateTime?>(
          _$TimestampPostCreatedAtField,
          data['created_at'],
        );
    final DateTime? timestampPostUpdatedAtValue = registry
        .decodeField<DateTime?>(
          _$TimestampPostUpdatedAtField,
          data['updated_at'],
        );
    final model = $TimestampPost(
      id: timestampPostIdValue,
      title: timestampPostTitleValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': timestampPostIdValue,
      'title': timestampPostTitleValue,
      if (data.containsKey('created_at'))
        'created_at': timestampPostCreatedAtValue,
      if (data.containsKey('updated_at'))
        'updated_at': timestampPostUpdatedAtValue,
    });
    return model;
  }
}

/// Insert DTO for [TimestampPost].
///
/// Auto-increment/DB-generated fields are omitted by default.
class TimestampPostInsertDto implements InsertDto<$TimestampPost> {
  const TimestampPostInsertDto({this.title});
  final String? title;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{if (title != null) 'title': title};
  }

  static const _TimestampPostInsertDtoCopyWithSentinel _copyWithSentinel =
      _TimestampPostInsertDtoCopyWithSentinel();
  TimestampPostInsertDto copyWith({Object? title = _copyWithSentinel}) {
    return TimestampPostInsertDto(
      title: identical(title, _copyWithSentinel)
          ? this.title
          : title as String?,
    );
  }
}

class _TimestampPostInsertDtoCopyWithSentinel {
  const _TimestampPostInsertDtoCopyWithSentinel();
}

/// Update DTO for [TimestampPost].
///
/// All fields are optional; only provided entries are used in SET clauses.
class TimestampPostUpdateDto implements UpdateDto<$TimestampPost> {
  const TimestampPostUpdateDto({this.id, this.title});
  final int? id;
  final String? title;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (title != null) 'title': title,
    };
  }

  static const _TimestampPostUpdateDtoCopyWithSentinel _copyWithSentinel =
      _TimestampPostUpdateDtoCopyWithSentinel();
  TimestampPostUpdateDto copyWith({
    Object? id = _copyWithSentinel,
    Object? title = _copyWithSentinel,
  }) {
    return TimestampPostUpdateDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      title: identical(title, _copyWithSentinel)
          ? this.title
          : title as String?,
    );
  }
}

class _TimestampPostUpdateDtoCopyWithSentinel {
  const _TimestampPostUpdateDtoCopyWithSentinel();
}

/// Partial projection for [TimestampPost].
///
/// All fields are nullable; intended for subset SELECTs.
class TimestampPostPartial implements PartialEntity<$TimestampPost> {
  const TimestampPostPartial({this.id, this.title});

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory TimestampPostPartial.fromRow(Map<String, Object?> row) {
    return TimestampPostPartial(
      id: row['id'] as int?,
      title: row['title'] as String?,
    );
  }

  final int? id;
  final String? title;

  @override
  $TimestampPost toEntity() {
    // Basic required-field check: non-nullable fields must be present.
    final int? idValue = id;
    if (idValue == null) {
      throw StateError('Missing required field: id');
    }
    final String? titleValue = title;
    if (titleValue == null) {
      throw StateError('Missing required field: title');
    }
    return $TimestampPost(id: idValue, title: titleValue);
  }

  @override
  Map<String, Object?> toMap() {
    return {if (id != null) 'id': id, if (title != null) 'title': title};
  }

  static const _TimestampPostPartialCopyWithSentinel _copyWithSentinel =
      _TimestampPostPartialCopyWithSentinel();
  TimestampPostPartial copyWith({
    Object? id = _copyWithSentinel,
    Object? title = _copyWithSentinel,
  }) {
    return TimestampPostPartial(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      title: identical(title, _copyWithSentinel)
          ? this.title
          : title as String?,
    );
  }
}

class _TimestampPostPartialCopyWithSentinel {
  const _TimestampPostPartialCopyWithSentinel();
}

/// Generated tracked model class for [TimestampPost].
///
/// This class extends the user-defined [TimestampPost] model and adds
/// attribute tracking, change detection, and relationship management.
/// Instances of this class are returned by queries and repositories.
///
/// **Do not instantiate this class directly.** Use queries, repositories,
/// or model factories to create tracked model instances.
class $TimestampPost extends TimestampPost
    with ModelAttributes, TimestampsImpl
    implements OrmEntity {
  /// Internal constructor for [$TimestampPost].
  $TimestampPost({int id = 0, required String title})
    : super.new(id: id, title: title) {
    _attachOrmRuntimeMetadata({'id': id, 'title': title});
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $TimestampPost.fromModel(TimestampPost model) {
    return $TimestampPost(id: model.id, title: model.title);
  }

  $TimestampPost copyWith({int? id, String? title}) {
    return $TimestampPost(id: id ?? this.id, title: title ?? this.title);
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
    attachModelDefinition(_$TimestampPostDefinition);
  }
}

extension TimestampPostOrmExtension on TimestampPost {
  /// The Type of the generated ORM-managed model class.
  /// Use this when you need to specify the tracked model type explicitly,
  /// for example in generic type parameters.
  static Type get trackedType => $TimestampPost;

  /// Converts this immutable model to a tracked ORM-managed model.
  /// The tracked model supports attribute tracking, change detection,
  /// and persistence operations like save() and touch().
  $TimestampPost toTracked() {
    return $TimestampPost.fromModel(this);
  }
}

extension TimestampPostPredicateFields on PredicateBuilder<TimestampPost> {
  PredicateField<TimestampPost, int> get id =>
      PredicateField<TimestampPost, int>(this, 'id');
  PredicateField<TimestampPost, String> get title =>
      PredicateField<TimestampPost, String>(this, 'title');
}

void registerTimestampPostEventHandlers(EventBus bus) {
  // No event handlers registered for TimestampPost.
}

const FieldDefinition _$TimestampArticleTzIdField = FieldDefinition(
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

const FieldDefinition _$TimestampArticleTzTitleField = FieldDefinition(
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

const FieldDefinition _$TimestampArticleTzCreatedAtField = FieldDefinition(
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

const FieldDefinition _$TimestampArticleTzUpdatedAtField = FieldDefinition(
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

Map<String, Object?> _encodeTimestampArticleTzUntracked(
  Object model,
  ValueCodecRegistry registry,
) {
  final m = model as TimestampArticleTz;
  return <String, Object?>{
    'id': registry.encodeField(_$TimestampArticleTzIdField, m.id),
    'title': registry.encodeField(_$TimestampArticleTzTitleField, m.title),
  };
}

final ModelDefinition<$TimestampArticleTz> _$TimestampArticleTzDefinition =
    ModelDefinition(
      modelName: 'TimestampArticleTz',
      tableName: 'articles',
      fields: const [
        _$TimestampArticleTzIdField,
        _$TimestampArticleTzTitleField,
        _$TimestampArticleTzCreatedAtField,
        _$TimestampArticleTzUpdatedAtField,
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
      untrackedToMap: _encodeTimestampArticleTzUntracked,
      codec: _$TimestampArticleTzCodec(),
    );

extension TimestampArticleTzOrmDefinition on TimestampArticleTz {
  static ModelDefinition<$TimestampArticleTz> get definition =>
      _$TimestampArticleTzDefinition;
}

class TimestampArticleTzs {
  const TimestampArticleTzs._();

  /// Starts building a query for [$TimestampArticleTz].
  ///
  /// {@macro ormed.query}
  static Query<$TimestampArticleTz> query([String? connection]) =>
      Model.query<$TimestampArticleTz>(connection: connection);

  static Future<$TimestampArticleTz?> find(Object id, {String? connection}) =>
      Model.find<$TimestampArticleTz>(id, connection: connection);

  static Future<$TimestampArticleTz> findOrFail(
    Object id, {
    String? connection,
  }) => Model.findOrFail<$TimestampArticleTz>(id, connection: connection);

  static Future<List<$TimestampArticleTz>> all({String? connection}) =>
      Model.all<$TimestampArticleTz>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<$TimestampArticleTz>(connection: connection);

  static Future<bool> anyExist({String? connection}) =>
      Model.anyExist<$TimestampArticleTz>(connection: connection);

  static Query<$TimestampArticleTz> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) => Model.where<$TimestampArticleTz>(
    column,
    operator,
    value,
    connection: connection,
  );

  static Query<$TimestampArticleTz> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<$TimestampArticleTz>(
    column,
    values,
    connection: connection,
  );

  static Query<$TimestampArticleTz> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<$TimestampArticleTz>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<$TimestampArticleTz> limit(int count, {String? connection}) =>
      Model.limit<$TimestampArticleTz>(count, connection: connection);

  /// Creates a [Repository] for [$TimestampArticleTz].
  ///
  /// {@macro ormed.repository}
  static Repository<$TimestampArticleTz> repo([String? connection]) =>
      Model.repository<$TimestampArticleTz>(connection: connection);
}

class TimestampArticleTzModelFactory {
  const TimestampArticleTzModelFactory._();

  static ModelDefinition<$TimestampArticleTz> get definition =>
      _$TimestampArticleTzDefinition;

  static ModelCodec<$TimestampArticleTz> get codec => definition.codec;

  static TimestampArticleTz fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    TimestampArticleTz model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model.toTracked(), registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<TimestampArticleTz> withConnection(
    QueryContext context,
  ) => ModelFactoryConnection<TimestampArticleTz>(
    definition: definition,
    context: context,
  );

  static ModelFactoryBuilder<TimestampArticleTz> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<TimestampArticleTz>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$TimestampArticleTzCodec extends ModelCodec<$TimestampArticleTz> {
  const _$TimestampArticleTzCodec();
  @override
  Map<String, Object?> encode(
    $TimestampArticleTz model,
    ValueCodecRegistry registry,
  ) {
    return <String, Object?>{
      'id': registry.encodeField(_$TimestampArticleTzIdField, model.id),
      'title': registry.encodeField(
        _$TimestampArticleTzTitleField,
        model.title,
      ),
      if (model.hasAttribute('created_at'))
        'created_at': registry.encodeField(
          _$TimestampArticleTzCreatedAtField,
          model.getAttribute<DateTime?>('created_at'),
        ),
      if (model.hasAttribute('updated_at'))
        'updated_at': registry.encodeField(
          _$TimestampArticleTzUpdatedAtField,
          model.getAttribute<DateTime?>('updated_at'),
        ),
    };
  }

  @override
  $TimestampArticleTz decode(
    Map<String, Object?> data,
    ValueCodecRegistry registry,
  ) {
    final int timestampArticleTzIdValue =
        registry.decodeField<int>(_$TimestampArticleTzIdField, data['id']) ?? 0;
    final String timestampArticleTzTitleValue =
        registry.decodeField<String>(
          _$TimestampArticleTzTitleField,
          data['title'],
        ) ??
        (throw StateError('Field title on TimestampArticleTz cannot be null.'));
    final DateTime? timestampArticleTzCreatedAtValue = registry
        .decodeField<DateTime?>(
          _$TimestampArticleTzCreatedAtField,
          data['created_at'],
        );
    final DateTime? timestampArticleTzUpdatedAtValue = registry
        .decodeField<DateTime?>(
          _$TimestampArticleTzUpdatedAtField,
          data['updated_at'],
        );
    final model = $TimestampArticleTz(
      id: timestampArticleTzIdValue,
      title: timestampArticleTzTitleValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': timestampArticleTzIdValue,
      'title': timestampArticleTzTitleValue,
      if (data.containsKey('created_at'))
        'created_at': timestampArticleTzCreatedAtValue,
      if (data.containsKey('updated_at'))
        'updated_at': timestampArticleTzUpdatedAtValue,
    });
    return model;
  }
}

/// Insert DTO for [TimestampArticleTz].
///
/// Auto-increment/DB-generated fields are omitted by default.
class TimestampArticleTzInsertDto implements InsertDto<$TimestampArticleTz> {
  const TimestampArticleTzInsertDto({this.title});
  final String? title;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{if (title != null) 'title': title};
  }

  static const _TimestampArticleTzInsertDtoCopyWithSentinel _copyWithSentinel =
      _TimestampArticleTzInsertDtoCopyWithSentinel();
  TimestampArticleTzInsertDto copyWith({Object? title = _copyWithSentinel}) {
    return TimestampArticleTzInsertDto(
      title: identical(title, _copyWithSentinel)
          ? this.title
          : title as String?,
    );
  }
}

class _TimestampArticleTzInsertDtoCopyWithSentinel {
  const _TimestampArticleTzInsertDtoCopyWithSentinel();
}

/// Update DTO for [TimestampArticleTz].
///
/// All fields are optional; only provided entries are used in SET clauses.
class TimestampArticleTzUpdateDto implements UpdateDto<$TimestampArticleTz> {
  const TimestampArticleTzUpdateDto({this.id, this.title});
  final int? id;
  final String? title;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (title != null) 'title': title,
    };
  }

  static const _TimestampArticleTzUpdateDtoCopyWithSentinel _copyWithSentinel =
      _TimestampArticleTzUpdateDtoCopyWithSentinel();
  TimestampArticleTzUpdateDto copyWith({
    Object? id = _copyWithSentinel,
    Object? title = _copyWithSentinel,
  }) {
    return TimestampArticleTzUpdateDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      title: identical(title, _copyWithSentinel)
          ? this.title
          : title as String?,
    );
  }
}

class _TimestampArticleTzUpdateDtoCopyWithSentinel {
  const _TimestampArticleTzUpdateDtoCopyWithSentinel();
}

/// Partial projection for [TimestampArticleTz].
///
/// All fields are nullable; intended for subset SELECTs.
class TimestampArticleTzPartial implements PartialEntity<$TimestampArticleTz> {
  const TimestampArticleTzPartial({this.id, this.title});

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory TimestampArticleTzPartial.fromRow(Map<String, Object?> row) {
    return TimestampArticleTzPartial(
      id: row['id'] as int?,
      title: row['title'] as String?,
    );
  }

  final int? id;
  final String? title;

  @override
  $TimestampArticleTz toEntity() {
    // Basic required-field check: non-nullable fields must be present.
    final int? idValue = id;
    if (idValue == null) {
      throw StateError('Missing required field: id');
    }
    final String? titleValue = title;
    if (titleValue == null) {
      throw StateError('Missing required field: title');
    }
    return $TimestampArticleTz(id: idValue, title: titleValue);
  }

  @override
  Map<String, Object?> toMap() {
    return {if (id != null) 'id': id, if (title != null) 'title': title};
  }

  static const _TimestampArticleTzPartialCopyWithSentinel _copyWithSentinel =
      _TimestampArticleTzPartialCopyWithSentinel();
  TimestampArticleTzPartial copyWith({
    Object? id = _copyWithSentinel,
    Object? title = _copyWithSentinel,
  }) {
    return TimestampArticleTzPartial(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      title: identical(title, _copyWithSentinel)
          ? this.title
          : title as String?,
    );
  }
}

class _TimestampArticleTzPartialCopyWithSentinel {
  const _TimestampArticleTzPartialCopyWithSentinel();
}

/// Generated tracked model class for [TimestampArticleTz].
///
/// This class extends the user-defined [TimestampArticleTz] model and adds
/// attribute tracking, change detection, and relationship management.
/// Instances of this class are returned by queries and repositories.
///
/// **Do not instantiate this class directly.** Use queries, repositories,
/// or model factories to create tracked model instances.
class $TimestampArticleTz extends TimestampArticleTz
    with ModelAttributes, TimestampsTZImpl
    implements OrmEntity {
  /// Internal constructor for [$TimestampArticleTz].
  $TimestampArticleTz({int id = 0, required String title})
    : super.new(id: id, title: title) {
    _attachOrmRuntimeMetadata({'id': id, 'title': title});
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $TimestampArticleTz.fromModel(TimestampArticleTz model) {
    return $TimestampArticleTz(id: model.id, title: model.title);
  }

  $TimestampArticleTz copyWith({int? id, String? title}) {
    return $TimestampArticleTz(id: id ?? this.id, title: title ?? this.title);
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
    attachModelDefinition(_$TimestampArticleTzDefinition);
  }
}

extension TimestampArticleTzOrmExtension on TimestampArticleTz {
  /// The Type of the generated ORM-managed model class.
  /// Use this when you need to specify the tracked model type explicitly,
  /// for example in generic type parameters.
  static Type get trackedType => $TimestampArticleTz;

  /// Converts this immutable model to a tracked ORM-managed model.
  /// The tracked model supports attribute tracking, change detection,
  /// and persistence operations like save() and touch().
  $TimestampArticleTz toTracked() {
    return $TimestampArticleTz.fromModel(this);
  }
}

extension TimestampArticleTzPredicateFields
    on PredicateBuilder<TimestampArticleTz> {
  PredicateField<TimestampArticleTz, int> get id =>
      PredicateField<TimestampArticleTz, int>(this, 'id');
  PredicateField<TimestampArticleTz, String> get title =>
      PredicateField<TimestampArticleTz, String>(this, 'title');
}

void registerTimestampArticleTzEventHandlers(EventBus bus) {
  // No event handlers registered for TimestampArticleTz.
}
