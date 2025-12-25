// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'casting_examples.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$SettingsIdField = FieldDefinition(
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

const FieldDefinition _$SettingsMetadataField = FieldDefinition(
  name: 'metadata',
  columnName: 'metadata',
  dartType: 'Map<String, Object?>',
  resolvedType: 'Map<String, Object?>?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
  codecType: 'json',
);

const FieldDefinition _$SettingsCreatedAtField = FieldDefinition(
  name: 'createdAt',
  columnName: 'created_at',
  dartType: 'DateTime',
  resolvedType: 'DateTime?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
  codecType: 'datetime',
);

Map<String, Object?> _encodeSettingsUntracked(
  Object model,
  ValueCodecRegistry registry,
) {
  final m = model as Settings;
  return <String, Object?>{
    'id': registry.encodeField(_$SettingsIdField, m.id),
    'metadata': registry.encodeField(_$SettingsMetadataField, m.metadata),
    'created_at': registry.encodeField(_$SettingsCreatedAtField, m.createdAt),
  };
}

final ModelDefinition<$Settings> _$SettingsDefinition = ModelDefinition(
  modelName: 'Settings',
  tableName: 'settings',
  fields: const [
    _$SettingsIdField,
    _$SettingsMetadataField,
    _$SettingsCreatedAtField,
  ],
  relations: const [],
  softDeleteColumn: 'deleted_at',
  metadata: ModelAttributesMetadata(
    hidden: const <String>[],
    visible: const <String>[],
    fillable: const <String>[],
    guarded: const <String>[],
    casts: const <String, String>{'metadata': 'json', 'createdAt': 'datetime'},
    softDeletes: false,
    softDeleteColumn: 'deleted_at',
  ),
  untrackedToMap: _encodeSettingsUntracked,
  codec: _$SettingsCodec(),
);

extension SettingsOrmDefinition on Settings {
  static ModelDefinition<$Settings> get definition => _$SettingsDefinition;
}

class Settings {
  const Settings._();

  /// Starts building a query for [$Settings].
  ///
  /// {@macro ormed.query}
  static Query<$Settings> query([String? connection]) =>
      Model.query<$Settings>(connection: connection);

  static Future<$Settings?> find(Object id, {String? connection}) =>
      Model.find<$Settings>(id, connection: connection);

  static Future<$Settings> findOrFail(Object id, {String? connection}) =>
      Model.findOrFail<$Settings>(id, connection: connection);

  static Future<List<$Settings>> all({String? connection}) =>
      Model.all<$Settings>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<$Settings>(connection: connection);

  static Future<bool> anyExist({String? connection}) =>
      Model.anyExist<$Settings>(connection: connection);

  static Query<$Settings> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) => Model.where<$Settings>(column, operator, value, connection: connection);

  static Query<$Settings> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<$Settings>(column, values, connection: connection);

  static Query<$Settings> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<$Settings>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<$Settings> limit(int count, {String? connection}) =>
      Model.limit<$Settings>(count, connection: connection);

  /// Creates a [Repository] for [$Settings].
  ///
  /// {@macro ormed.repository}
  static Repository<$Settings> repo([String? connection]) =>
      Model.repository<$Settings>(connection: connection);
}

class SettingsModelFactory {
  const SettingsModelFactory._();

  static ModelDefinition<$Settings> get definition => _$SettingsDefinition;

  static ModelCodec<$Settings> get codec => definition.codec;

  static Settings fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    Settings model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model.toTracked(), registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<Settings> withConnection(
    QueryContext context,
  ) => ModelFactoryConnection<Settings>(
    definition: definition,
    context: context,
  );

  static ModelFactoryBuilder<Settings> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<Settings>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$SettingsCodec extends ModelCodec<$Settings> {
  const _$SettingsCodec();
  @override
  Map<String, Object?> encode($Settings model, ValueCodecRegistry registry) {
    return <String, Object?>{
      'id': registry.encodeField(_$SettingsIdField, model.id),
      'metadata': registry.encodeField(_$SettingsMetadataField, model.metadata),
      'created_at': registry.encodeField(
        _$SettingsCreatedAtField,
        model.createdAt,
      ),
    };
  }

  @override
  $Settings decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final int settingsIdValue =
        registry.decodeField<int>(_$SettingsIdField, data['id']) ?? 0;
    final Map<String, Object?>? settingsMetadataValue = registry
        .decodeField<Map<String, Object?>?>(
          _$SettingsMetadataField,
          data['metadata'],
        );
    final DateTime? settingsCreatedAtValue = registry.decodeField<DateTime?>(
      _$SettingsCreatedAtField,
      data['created_at'],
    );
    final model = $Settings(
      id: settingsIdValue,
      metadata: settingsMetadataValue,
      createdAt: settingsCreatedAtValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': settingsIdValue,
      'metadata': settingsMetadataValue,
      'created_at': settingsCreatedAtValue,
    });
    return model;
  }
}

/// Insert DTO for [Settings].
///
/// Auto-increment/DB-generated fields are omitted by default.
class SettingsInsertDto implements InsertDto<$Settings> {
  const SettingsInsertDto({this.metadata, this.createdAt});
  final Map<String, Object?>? metadata;
  final DateTime? createdAt;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (metadata != null) 'metadata': metadata,
      if (createdAt != null) 'created_at': createdAt,
    };
  }

  static const _SettingsInsertDtoCopyWithSentinel _copyWithSentinel =
      _SettingsInsertDtoCopyWithSentinel();
  SettingsInsertDto copyWith({
    Object? metadata = _copyWithSentinel,
    Object? createdAt = _copyWithSentinel,
  }) {
    return SettingsInsertDto(
      metadata: identical(metadata, _copyWithSentinel)
          ? this.metadata
          : metadata as Map<String, Object?>?,
      createdAt: identical(createdAt, _copyWithSentinel)
          ? this.createdAt
          : createdAt as DateTime?,
    );
  }
}

class _SettingsInsertDtoCopyWithSentinel {
  const _SettingsInsertDtoCopyWithSentinel();
}

/// Update DTO for [Settings].
///
/// All fields are optional; only provided entries are used in SET clauses.
class SettingsUpdateDto implements UpdateDto<$Settings> {
  const SettingsUpdateDto({this.id, this.metadata, this.createdAt});
  final int? id;
  final Map<String, Object?>? metadata;
  final DateTime? createdAt;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (metadata != null) 'metadata': metadata,
      if (createdAt != null) 'created_at': createdAt,
    };
  }

  static const _SettingsUpdateDtoCopyWithSentinel _copyWithSentinel =
      _SettingsUpdateDtoCopyWithSentinel();
  SettingsUpdateDto copyWith({
    Object? id = _copyWithSentinel,
    Object? metadata = _copyWithSentinel,
    Object? createdAt = _copyWithSentinel,
  }) {
    return SettingsUpdateDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      metadata: identical(metadata, _copyWithSentinel)
          ? this.metadata
          : metadata as Map<String, Object?>?,
      createdAt: identical(createdAt, _copyWithSentinel)
          ? this.createdAt
          : createdAt as DateTime?,
    );
  }
}

class _SettingsUpdateDtoCopyWithSentinel {
  const _SettingsUpdateDtoCopyWithSentinel();
}

/// Partial projection for [Settings].
///
/// All fields are nullable; intended for subset SELECTs.
class SettingsPartial implements PartialEntity<$Settings> {
  const SettingsPartial({this.id, this.metadata, this.createdAt});

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory SettingsPartial.fromRow(Map<String, Object?> row) {
    return SettingsPartial(
      id: row['id'] as int?,
      metadata: row['metadata'] as Map<String, Object?>?,
      createdAt: row['created_at'] as DateTime?,
    );
  }

  final int? id;
  final Map<String, Object?>? metadata;
  final DateTime? createdAt;

  @override
  $Settings toEntity() {
    // Basic required-field check: non-nullable fields must be present.
    final int? idValue = id;
    if (idValue == null) {
      throw StateError('Missing required field: id');
    }
    return $Settings(id: idValue, metadata: metadata, createdAt: createdAt);
  }

  @override
  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      if (metadata != null) 'metadata': metadata,
      if (createdAt != null) 'created_at': createdAt,
    };
  }

  static const _SettingsPartialCopyWithSentinel _copyWithSentinel =
      _SettingsPartialCopyWithSentinel();
  SettingsPartial copyWith({
    Object? id = _copyWithSentinel,
    Object? metadata = _copyWithSentinel,
    Object? createdAt = _copyWithSentinel,
  }) {
    return SettingsPartial(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      metadata: identical(metadata, _copyWithSentinel)
          ? this.metadata
          : metadata as Map<String, Object?>?,
      createdAt: identical(createdAt, _copyWithSentinel)
          ? this.createdAt
          : createdAt as DateTime?,
    );
  }
}

class _SettingsPartialCopyWithSentinel {
  const _SettingsPartialCopyWithSentinel();
}

/// Generated tracked model class for [Settings].
///
/// This class extends the user-defined [Settings] model and adds
/// attribute tracking, change detection, and relationship management.
/// Instances of this class are returned by queries and repositories.
///
/// **Do not instantiate this class directly.** Use queries, repositories,
/// or model factories to create tracked model instances.
class $Settings extends Settings with ModelAttributes implements OrmEntity {
  /// Internal constructor for [$Settings].
  $Settings({int id = 0, Map<String, Object?>? metadata, DateTime? createdAt})
    : super.new(id: id, metadata: metadata, createdAt: createdAt) {
    _attachOrmRuntimeMetadata({
      'id': id,
      'metadata': metadata,
      'created_at': createdAt,
    });
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $Settings.fromModel(Settings model) {
    return $Settings(
      id: model.id,
      metadata: model.metadata,
      createdAt: model.createdAt,
    );
  }

  $Settings copyWith({
    int? id,
    Map<String, Object?>? metadata,
    DateTime? createdAt,
  }) {
    return $Settings(
      id: id ?? this.id,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Tracked getter for [id].
  @override
  int get id => getAttribute<int>('id') ?? super.id;

  /// Tracked setter for [id].
  set id(int value) => setAttribute('id', value);

  /// Tracked getter for [metadata].
  @override
  Map<String, Object?>? get metadata =>
      getAttribute<Map<String, Object?>?>('metadata') ?? super.metadata;

  /// Tracked setter for [metadata].
  set metadata(Map<String, Object?>? value) => setAttribute('metadata', value);

  /// Tracked getter for [createdAt].
  @override
  DateTime? get createdAt =>
      getAttribute<DateTime?>('created_at') ?? super.createdAt;

  /// Tracked setter for [createdAt].
  set createdAt(DateTime? value) => setAttribute('created_at', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$SettingsDefinition);
  }
}

extension SettingsOrmExtension on Settings {
  /// The Type of the generated ORM-managed model class.
  /// Use this when you need to specify the tracked model type explicitly,
  /// for example in generic type parameters.
  static Type get trackedType => $Settings;

  /// Converts this immutable model to a tracked ORM-managed model.
  /// The tracked model supports attribute tracking, change detection,
  /// and persistence operations like save() and touch().
  $Settings toTracked() {
    return $Settings.fromModel(this);
  }
}

void registerSettingsEventHandlers(EventBus bus) {
  // No event handlers registered for Settings.
}

const FieldDefinition _$FieldCastSettingsIdField = FieldDefinition(
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

const FieldDefinition _$FieldCastSettingsMetadataField = FieldDefinition(
  name: 'metadata',
  columnName: 'metadata',
  dartType: 'Map<String, Object?>',
  resolvedType: 'Map<String, Object?>?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
  codecType: 'json',
);

Map<String, Object?> _encodeFieldCastSettingsUntracked(
  Object model,
  ValueCodecRegistry registry,
) {
  final m = model as FieldCastSettings;
  return <String, Object?>{
    'id': registry.encodeField(_$FieldCastSettingsIdField, m.id),
    'metadata': registry.encodeField(
      _$FieldCastSettingsMetadataField,
      m.metadata,
    ),
  };
}

final ModelDefinition<$FieldCastSettings>
_$FieldCastSettingsDefinition = ModelDefinition(
  modelName: 'FieldCastSettings',
  tableName: 'field_cast_settings',
  fields: const [_$FieldCastSettingsIdField, _$FieldCastSettingsMetadataField],
  relations: const [],
  softDeleteColumn: 'deleted_at',
  metadata: ModelAttributesMetadata(
    hidden: const <String>[],
    visible: const <String>[],
    fillable: const <String>[],
    guarded: const <String>[],
    casts: const <String, String>{},
    fieldOverrides: const {'metadata': FieldAttributeMetadata(cast: 'json')},
    softDeletes: false,
    softDeleteColumn: 'deleted_at',
  ),
  untrackedToMap: _encodeFieldCastSettingsUntracked,
  codec: _$FieldCastSettingsCodec(),
);

extension FieldCastSettingsOrmDefinition on FieldCastSettings {
  static ModelDefinition<$FieldCastSettings> get definition =>
      _$FieldCastSettingsDefinition;
}

class FieldCastSettings {
  const FieldCastSettings._();

  /// Starts building a query for [$FieldCastSettings].
  ///
  /// {@macro ormed.query}
  static Query<$FieldCastSettings> query([String? connection]) =>
      Model.query<$FieldCastSettings>(connection: connection);

  static Future<$FieldCastSettings?> find(Object id, {String? connection}) =>
      Model.find<$FieldCastSettings>(id, connection: connection);

  static Future<$FieldCastSettings> findOrFail(
    Object id, {
    String? connection,
  }) => Model.findOrFail<$FieldCastSettings>(id, connection: connection);

  static Future<List<$FieldCastSettings>> all({String? connection}) =>
      Model.all<$FieldCastSettings>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<$FieldCastSettings>(connection: connection);

  static Future<bool> anyExist({String? connection}) =>
      Model.anyExist<$FieldCastSettings>(connection: connection);

  static Query<$FieldCastSettings> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) => Model.where<$FieldCastSettings>(
    column,
    operator,
    value,
    connection: connection,
  );

  static Query<$FieldCastSettings> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) =>
      Model.whereIn<$FieldCastSettings>(column, values, connection: connection);

  static Query<$FieldCastSettings> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<$FieldCastSettings>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<$FieldCastSettings> limit(int count, {String? connection}) =>
      Model.limit<$FieldCastSettings>(count, connection: connection);

  /// Creates a [Repository] for [$FieldCastSettings].
  ///
  /// {@macro ormed.repository}
  static Repository<$FieldCastSettings> repo([String? connection]) =>
      Model.repository<$FieldCastSettings>(connection: connection);
}

class FieldCastSettingsModelFactory {
  const FieldCastSettingsModelFactory._();

  static ModelDefinition<$FieldCastSettings> get definition =>
      _$FieldCastSettingsDefinition;

  static ModelCodec<$FieldCastSettings> get codec => definition.codec;

  static FieldCastSettings fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    FieldCastSettings model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model.toTracked(), registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<FieldCastSettings> withConnection(
    QueryContext context,
  ) => ModelFactoryConnection<FieldCastSettings>(
    definition: definition,
    context: context,
  );

  static ModelFactoryBuilder<FieldCastSettings> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<FieldCastSettings>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$FieldCastSettingsCodec extends ModelCodec<$FieldCastSettings> {
  const _$FieldCastSettingsCodec();
  @override
  Map<String, Object?> encode(
    $FieldCastSettings model,
    ValueCodecRegistry registry,
  ) {
    return <String, Object?>{
      'id': registry.encodeField(_$FieldCastSettingsIdField, model.id),
      'metadata': registry.encodeField(
        _$FieldCastSettingsMetadataField,
        model.metadata,
      ),
    };
  }

  @override
  $FieldCastSettings decode(
    Map<String, Object?> data,
    ValueCodecRegistry registry,
  ) {
    final int fieldCastSettingsIdValue =
        registry.decodeField<int>(_$FieldCastSettingsIdField, data['id']) ?? 0;
    final Map<String, Object?>? fieldCastSettingsMetadataValue = registry
        .decodeField<Map<String, Object?>?>(
          _$FieldCastSettingsMetadataField,
          data['metadata'],
        );
    final model = $FieldCastSettings(
      id: fieldCastSettingsIdValue,
      metadata: fieldCastSettingsMetadataValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': fieldCastSettingsIdValue,
      'metadata': fieldCastSettingsMetadataValue,
    });
    return model;
  }
}

/// Insert DTO for [FieldCastSettings].
///
/// Auto-increment/DB-generated fields are omitted by default.
class FieldCastSettingsInsertDto implements InsertDto<$FieldCastSettings> {
  const FieldCastSettingsInsertDto({this.metadata});
  final Map<String, Object?>? metadata;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{if (metadata != null) 'metadata': metadata};
  }

  static const _FieldCastSettingsInsertDtoCopyWithSentinel _copyWithSentinel =
      _FieldCastSettingsInsertDtoCopyWithSentinel();
  FieldCastSettingsInsertDto copyWith({Object? metadata = _copyWithSentinel}) {
    return FieldCastSettingsInsertDto(
      metadata: identical(metadata, _copyWithSentinel)
          ? this.metadata
          : metadata as Map<String, Object?>?,
    );
  }
}

class _FieldCastSettingsInsertDtoCopyWithSentinel {
  const _FieldCastSettingsInsertDtoCopyWithSentinel();
}

/// Update DTO for [FieldCastSettings].
///
/// All fields are optional; only provided entries are used in SET clauses.
class FieldCastSettingsUpdateDto implements UpdateDto<$FieldCastSettings> {
  const FieldCastSettingsUpdateDto({this.id, this.metadata});
  final int? id;
  final Map<String, Object?>? metadata;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (metadata != null) 'metadata': metadata,
    };
  }

  static const _FieldCastSettingsUpdateDtoCopyWithSentinel _copyWithSentinel =
      _FieldCastSettingsUpdateDtoCopyWithSentinel();
  FieldCastSettingsUpdateDto copyWith({
    Object? id = _copyWithSentinel,
    Object? metadata = _copyWithSentinel,
  }) {
    return FieldCastSettingsUpdateDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      metadata: identical(metadata, _copyWithSentinel)
          ? this.metadata
          : metadata as Map<String, Object?>?,
    );
  }
}

class _FieldCastSettingsUpdateDtoCopyWithSentinel {
  const _FieldCastSettingsUpdateDtoCopyWithSentinel();
}

/// Partial projection for [FieldCastSettings].
///
/// All fields are nullable; intended for subset SELECTs.
class FieldCastSettingsPartial implements PartialEntity<$FieldCastSettings> {
  const FieldCastSettingsPartial({this.id, this.metadata});

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory FieldCastSettingsPartial.fromRow(Map<String, Object?> row) {
    return FieldCastSettingsPartial(
      id: row['id'] as int?,
      metadata: row['metadata'] as Map<String, Object?>?,
    );
  }

  final int? id;
  final Map<String, Object?>? metadata;

  @override
  $FieldCastSettings toEntity() {
    // Basic required-field check: non-nullable fields must be present.
    final int? idValue = id;
    if (idValue == null) {
      throw StateError('Missing required field: id');
    }
    return $FieldCastSettings(id: idValue, metadata: metadata);
  }

  @override
  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      if (metadata != null) 'metadata': metadata,
    };
  }

  static const _FieldCastSettingsPartialCopyWithSentinel _copyWithSentinel =
      _FieldCastSettingsPartialCopyWithSentinel();
  FieldCastSettingsPartial copyWith({
    Object? id = _copyWithSentinel,
    Object? metadata = _copyWithSentinel,
  }) {
    return FieldCastSettingsPartial(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      metadata: identical(metadata, _copyWithSentinel)
          ? this.metadata
          : metadata as Map<String, Object?>?,
    );
  }
}

class _FieldCastSettingsPartialCopyWithSentinel {
  const _FieldCastSettingsPartialCopyWithSentinel();
}

/// Generated tracked model class for [FieldCastSettings].
///
/// This class extends the user-defined [FieldCastSettings] model and adds
/// attribute tracking, change detection, and relationship management.
/// Instances of this class are returned by queries and repositories.
///
/// **Do not instantiate this class directly.** Use queries, repositories,
/// or model factories to create tracked model instances.
class $FieldCastSettings extends FieldCastSettings
    with ModelAttributes
    implements OrmEntity {
  /// Internal constructor for [$FieldCastSettings].
  $FieldCastSettings({int id = 0, Map<String, Object?>? metadata})
    : super.new(id: id, metadata: metadata) {
    _attachOrmRuntimeMetadata({'id': id, 'metadata': metadata});
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $FieldCastSettings.fromModel(FieldCastSettings model) {
    return $FieldCastSettings(id: model.id, metadata: model.metadata);
  }

  $FieldCastSettings copyWith({int? id, Map<String, Object?>? metadata}) {
    return $FieldCastSettings(
      id: id ?? this.id,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Tracked getter for [id].
  @override
  int get id => getAttribute<int>('id') ?? super.id;

  /// Tracked setter for [id].
  set id(int value) => setAttribute('id', value);

  /// Tracked getter for [metadata].
  @override
  Map<String, Object?>? get metadata =>
      getAttribute<Map<String, Object?>?>('metadata') ?? super.metadata;

  /// Tracked setter for [metadata].
  set metadata(Map<String, Object?>? value) => setAttribute('metadata', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$FieldCastSettingsDefinition);
  }
}

extension FieldCastSettingsOrmExtension on FieldCastSettings {
  /// The Type of the generated ORM-managed model class.
  /// Use this when you need to specify the tracked model type explicitly,
  /// for example in generic type parameters.
  static Type get trackedType => $FieldCastSettings;

  /// Converts this immutable model to a tracked ORM-managed model.
  /// The tracked model supports attribute tracking, change detection,
  /// and persistence operations like save() and touch().
  $FieldCastSettings toTracked() {
    return $FieldCastSettings.fromModel(this);
  }
}

void registerFieldCastSettingsEventHandlers(EventBus bus) {
  // No event handlers registered for FieldCastSettings.
}

const FieldDefinition _$LinkIdField = FieldDefinition(
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

const FieldDefinition _$LinkWebsiteField = FieldDefinition(
  name: 'website',
  columnName: 'website',
  dartType: 'Uri',
  resolvedType: 'Uri?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
  codecType: 'uri',
);

Map<String, Object?> _encodeLinkUntracked(
  Object model,
  ValueCodecRegistry registry,
) {
  final m = model as Link;
  return <String, Object?>{
    'id': registry.encodeField(_$LinkIdField, m.id),
    'website': registry.encodeField(_$LinkWebsiteField, m.website),
  };
}

final ModelDefinition<$Link> _$LinkDefinition = ModelDefinition(
  modelName: 'Link',
  tableName: 'links',
  fields: const [_$LinkIdField, _$LinkWebsiteField],
  relations: const [],
  softDeleteColumn: 'deleted_at',
  metadata: ModelAttributesMetadata(
    hidden: const <String>[],
    visible: const <String>[],
    fillable: const <String>[],
    guarded: const <String>[],
    casts: const <String, String>{'website': 'uri'},
    softDeletes: false,
    softDeleteColumn: 'deleted_at',
  ),
  untrackedToMap: _encodeLinkUntracked,
  codec: _$LinkCodec(),
);

extension LinkOrmDefinition on Link {
  static ModelDefinition<$Link> get definition => _$LinkDefinition;
}

class Links {
  const Links._();

  /// Starts building a query for [$Link].
  ///
  /// {@macro ormed.query}
  static Query<$Link> query([String? connection]) =>
      Model.query<$Link>(connection: connection);

  static Future<$Link?> find(Object id, {String? connection}) =>
      Model.find<$Link>(id, connection: connection);

  static Future<$Link> findOrFail(Object id, {String? connection}) =>
      Model.findOrFail<$Link>(id, connection: connection);

  static Future<List<$Link>> all({String? connection}) =>
      Model.all<$Link>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<$Link>(connection: connection);

  static Future<bool> anyExist({String? connection}) =>
      Model.anyExist<$Link>(connection: connection);

  static Query<$Link> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) => Model.where<$Link>(column, operator, value, connection: connection);

  static Query<$Link> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<$Link>(column, values, connection: connection);

  static Query<$Link> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<$Link>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<$Link> limit(int count, {String? connection}) =>
      Model.limit<$Link>(count, connection: connection);

  /// Creates a [Repository] for [$Link].
  ///
  /// {@macro ormed.repository}
  static Repository<$Link> repo([String? connection]) =>
      Model.repository<$Link>(connection: connection);
}

class LinkModelFactory {
  const LinkModelFactory._();

  static ModelDefinition<$Link> get definition => _$LinkDefinition;

  static ModelCodec<$Link> get codec => definition.codec;

  static Link fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    Link model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model.toTracked(), registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<Link> withConnection(QueryContext context) =>
      ModelFactoryConnection<Link>(definition: definition, context: context);

  static ModelFactoryBuilder<Link> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<Link>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$LinkCodec extends ModelCodec<$Link> {
  const _$LinkCodec();
  @override
  Map<String, Object?> encode($Link model, ValueCodecRegistry registry) {
    return <String, Object?>{
      'id': registry.encodeField(_$LinkIdField, model.id),
      'website': registry.encodeField(_$LinkWebsiteField, model.website),
    };
  }

  @override
  $Link decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final int linkIdValue =
        registry.decodeField<int>(_$LinkIdField, data['id']) ?? 0;
    final Uri? linkWebsiteValue = registry.decodeField<Uri?>(
      _$LinkWebsiteField,
      data['website'],
    );
    final model = $Link(id: linkIdValue, website: linkWebsiteValue);
    model._attachOrmRuntimeMetadata({
      'id': linkIdValue,
      'website': linkWebsiteValue,
    });
    return model;
  }
}

/// Insert DTO for [Link].
///
/// Auto-increment/DB-generated fields are omitted by default.
class LinkInsertDto implements InsertDto<$Link> {
  const LinkInsertDto({this.website});
  final Uri? website;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{if (website != null) 'website': website};
  }

  static const _LinkInsertDtoCopyWithSentinel _copyWithSentinel =
      _LinkInsertDtoCopyWithSentinel();
  LinkInsertDto copyWith({Object? website = _copyWithSentinel}) {
    return LinkInsertDto(
      website: identical(website, _copyWithSentinel)
          ? this.website
          : website as Uri?,
    );
  }
}

class _LinkInsertDtoCopyWithSentinel {
  const _LinkInsertDtoCopyWithSentinel();
}

/// Update DTO for [Link].
///
/// All fields are optional; only provided entries are used in SET clauses.
class LinkUpdateDto implements UpdateDto<$Link> {
  const LinkUpdateDto({this.id, this.website});
  final int? id;
  final Uri? website;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (website != null) 'website': website,
    };
  }

  static const _LinkUpdateDtoCopyWithSentinel _copyWithSentinel =
      _LinkUpdateDtoCopyWithSentinel();
  LinkUpdateDto copyWith({
    Object? id = _copyWithSentinel,
    Object? website = _copyWithSentinel,
  }) {
    return LinkUpdateDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      website: identical(website, _copyWithSentinel)
          ? this.website
          : website as Uri?,
    );
  }
}

class _LinkUpdateDtoCopyWithSentinel {
  const _LinkUpdateDtoCopyWithSentinel();
}

/// Partial projection for [Link].
///
/// All fields are nullable; intended for subset SELECTs.
class LinkPartial implements PartialEntity<$Link> {
  const LinkPartial({this.id, this.website});

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory LinkPartial.fromRow(Map<String, Object?> row) {
    return LinkPartial(id: row['id'] as int?, website: row['website'] as Uri?);
  }

  final int? id;
  final Uri? website;

  @override
  $Link toEntity() {
    // Basic required-field check: non-nullable fields must be present.
    final int? idValue = id;
    if (idValue == null) {
      throw StateError('Missing required field: id');
    }
    return $Link(id: idValue, website: website);
  }

  @override
  Map<String, Object?> toMap() {
    return {if (id != null) 'id': id, if (website != null) 'website': website};
  }

  static const _LinkPartialCopyWithSentinel _copyWithSentinel =
      _LinkPartialCopyWithSentinel();
  LinkPartial copyWith({
    Object? id = _copyWithSentinel,
    Object? website = _copyWithSentinel,
  }) {
    return LinkPartial(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      website: identical(website, _copyWithSentinel)
          ? this.website
          : website as Uri?,
    );
  }
}

class _LinkPartialCopyWithSentinel {
  const _LinkPartialCopyWithSentinel();
}

/// Generated tracked model class for [Link].
///
/// This class extends the user-defined [Link] model and adds
/// attribute tracking, change detection, and relationship management.
/// Instances of this class are returned by queries and repositories.
///
/// **Do not instantiate this class directly.** Use queries, repositories,
/// or model factories to create tracked model instances.
class $Link extends Link with ModelAttributes implements OrmEntity {
  /// Internal constructor for [$Link].
  $Link({int id = 0, Uri? website}) : super.new(id: id, website: website) {
    _attachOrmRuntimeMetadata({'id': id, 'website': website});
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $Link.fromModel(Link model) {
    return $Link(id: model.id, website: model.website);
  }

  $Link copyWith({int? id, Uri? website}) {
    return $Link(id: id ?? this.id, website: website ?? this.website);
  }

  /// Tracked getter for [id].
  @override
  int get id => getAttribute<int>('id') ?? super.id;

  /// Tracked setter for [id].
  set id(int value) => setAttribute('id', value);

  /// Tracked getter for [website].
  @override
  Uri? get website => getAttribute<Uri?>('website') ?? super.website;

  /// Tracked setter for [website].
  set website(Uri? value) => setAttribute('website', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$LinkDefinition);
  }
}

extension LinkOrmExtension on Link {
  /// The Type of the generated ORM-managed model class.
  /// Use this when you need to specify the tracked model type explicitly,
  /// for example in generic type parameters.
  static Type get trackedType => $Link;

  /// Converts this immutable model to a tracked ORM-managed model.
  /// The tracked model supports attribute tracking, change detection,
  /// and persistence operations like save() and touch().
  $Link toTracked() {
    return $Link.fromModel(this);
  }
}

void registerLinkEventHandlers(EventBus bus) {
  // No event handlers registered for Link.
}
