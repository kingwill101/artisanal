// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'settings.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$SettingIdField = FieldDefinition(
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

const FieldDefinition _$SettingPayloadField = FieldDefinition(
  name: 'payload',
  columnName: 'payload',
  dartType: 'Map<String, dynamic>',
  resolvedType: 'Map<String, dynamic>',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
  codecType: 'json',
);

Map<String, Object?> _encodeSettingUntracked(
  Object model,
  ValueCodecRegistry registry,
) {
  final m = model as Setting;
  return <String, Object?>{
    'id': registry.encodeField(_$SettingIdField, m.id),
    'payload': registry.encodeField(_$SettingPayloadField, m.payload),
  };
}

final ModelDefinition<$Setting> _$SettingDefinition = ModelDefinition(
  modelName: 'Setting',
  tableName: 'settings',
  fields: const [_$SettingIdField, _$SettingPayloadField],
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
    fieldOverrides: const {'payload': FieldAttributeMetadata(cast: 'json')},
    softDeletes: false,
    softDeleteColumn: 'deleted_at',
  ),
  untrackedToMap: _encodeSettingUntracked,
  codec: _$SettingCodec(),
);

// ignore: unused_element
final settingModelDefinitionRegistration =
    ModelFactoryRegistry.register<$Setting>(_$SettingDefinition);

extension SettingOrmDefinition on Setting {
  static ModelDefinition<$Setting> get definition => _$SettingDefinition;
}

class Settings {
  const Settings._();

  /// Starts building a query for [$Setting].
  ///
  /// {@macro ormed.query}
  static Query<$Setting> query([String? connection]) =>
      Model.query<$Setting>(connection: connection);

  static Future<$Setting?> find(Object id, {String? connection}) =>
      Model.find<$Setting>(id, connection: connection);

  static Future<$Setting> findOrFail(Object id, {String? connection}) =>
      Model.findOrFail<$Setting>(id, connection: connection);

  static Future<List<$Setting>> all({String? connection}) =>
      Model.all<$Setting>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<$Setting>(connection: connection);

  static Future<bool> anyExist({String? connection}) =>
      Model.anyExist<$Setting>(connection: connection);

  static Query<$Setting> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) => Model.where<$Setting>(column, operator, value, connection: connection);

  static Query<$Setting> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<$Setting>(column, values, connection: connection);

  static Query<$Setting> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<$Setting>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<$Setting> limit(int count, {String? connection}) =>
      Model.limit<$Setting>(count, connection: connection);

  /// Creates a [Repository] for [$Setting].
  ///
  /// {@macro ormed.repository}
  static Repository<$Setting> repo([String? connection]) =>
      Model.repository<$Setting>(connection: connection);

  /// Builds a tracked model from a column/value map.
  static $Setting fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$SettingDefinition.fromMap(data, registry: registry);

  /// Converts a tracked model to a column/value map.
  static Map<String, Object?> toMap(
    $Setting model, {
    ValueCodecRegistry? registry,
  }) => _$SettingDefinition.toMap(model, registry: registry);
}

class SettingModelFactory {
  const SettingModelFactory._();

  static ModelDefinition<$Setting> get definition => _$SettingDefinition;

  static ModelCodec<$Setting> get codec => definition.codec;

  static Setting fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    Setting model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model.toTracked(), registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<Setting> withConnection(QueryContext context) =>
      ModelFactoryConnection<Setting>(definition: definition, context: context);

  static ModelFactoryBuilder<Setting> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<Setting>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$SettingCodec extends ModelCodec<$Setting> {
  const _$SettingCodec();
  @override
  Map<String, Object?> encode($Setting model, ValueCodecRegistry registry) {
    return <String, Object?>{
      'id': registry.encodeField(_$SettingIdField, model.id),
      'payload': registry.encodeField(_$SettingPayloadField, model.payload),
    };
  }

  @override
  $Setting decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final int settingIdValue =
        registry.decodeField<int>(_$SettingIdField, data['id']) ?? 0;
    final Map<String, dynamic> settingPayloadValue =
        registry.decodeField<Map<String, dynamic>>(
          _$SettingPayloadField,
          data['payload'],
        ) ??
        (throw StateError('Field payload on Setting cannot be null.'));
    final model = $Setting(id: settingIdValue, payload: settingPayloadValue);
    model._attachOrmRuntimeMetadata({
      'id': settingIdValue,
      'payload': settingPayloadValue,
    });
    return model;
  }
}

/// Insert DTO for [Setting].
///
/// Auto-increment/DB-generated fields are omitted by default.
class SettingInsertDto implements InsertDto<$Setting> {
  const SettingInsertDto({this.payload});
  final Map<String, dynamic>? payload;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{if (payload != null) 'payload': payload};
  }

  static const _SettingInsertDtoCopyWithSentinel _copyWithSentinel =
      _SettingInsertDtoCopyWithSentinel();
  SettingInsertDto copyWith({Object? payload = _copyWithSentinel}) {
    return SettingInsertDto(
      payload: identical(payload, _copyWithSentinel)
          ? this.payload
          : payload as Map<String, dynamic>?,
    );
  }
}

class _SettingInsertDtoCopyWithSentinel {
  const _SettingInsertDtoCopyWithSentinel();
}

/// Update DTO for [Setting].
///
/// All fields are optional; only provided entries are used in SET clauses.
class SettingUpdateDto implements UpdateDto<$Setting> {
  const SettingUpdateDto({this.id, this.payload});
  final int? id;
  final Map<String, dynamic>? payload;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (payload != null) 'payload': payload,
    };
  }

  static const _SettingUpdateDtoCopyWithSentinel _copyWithSentinel =
      _SettingUpdateDtoCopyWithSentinel();
  SettingUpdateDto copyWith({
    Object? id = _copyWithSentinel,
    Object? payload = _copyWithSentinel,
  }) {
    return SettingUpdateDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      payload: identical(payload, _copyWithSentinel)
          ? this.payload
          : payload as Map<String, dynamic>?,
    );
  }
}

class _SettingUpdateDtoCopyWithSentinel {
  const _SettingUpdateDtoCopyWithSentinel();
}

/// Partial projection for [Setting].
///
/// All fields are nullable; intended for subset SELECTs.
class SettingPartial implements PartialEntity<$Setting> {
  const SettingPartial({this.id, this.payload});

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory SettingPartial.fromRow(Map<String, Object?> row) {
    return SettingPartial(
      id: row['id'] as int?,
      payload: row['payload'] as Map<String, dynamic>?,
    );
  }

  final int? id;
  final Map<String, dynamic>? payload;

  @override
  $Setting toEntity() {
    // Basic required-field check: non-nullable fields must be present.
    final int? idValue = id;
    if (idValue == null) {
      throw StateError('Missing required field: id');
    }
    final Map<String, dynamic>? payloadValue = payload;
    if (payloadValue == null) {
      throw StateError('Missing required field: payload');
    }
    return $Setting(id: idValue, payload: payloadValue);
  }

  @override
  Map<String, Object?> toMap() {
    return {if (id != null) 'id': id, if (payload != null) 'payload': payload};
  }

  static const _SettingPartialCopyWithSentinel _copyWithSentinel =
      _SettingPartialCopyWithSentinel();
  SettingPartial copyWith({
    Object? id = _copyWithSentinel,
    Object? payload = _copyWithSentinel,
  }) {
    return SettingPartial(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      payload: identical(payload, _copyWithSentinel)
          ? this.payload
          : payload as Map<String, dynamic>?,
    );
  }
}

class _SettingPartialCopyWithSentinel {
  const _SettingPartialCopyWithSentinel();
}

/// Generated tracked model class for [Setting].
///
/// This class extends the user-defined [Setting] model and adds
/// attribute tracking, change detection, and relationship management.
/// Instances of this class are returned by queries and repositories.
///
/// **Do not instantiate this class directly.** Use queries, repositories,
/// or model factories to create tracked model instances.
class $Setting extends Setting with ModelAttributes implements OrmEntity {
  /// Internal constructor for [$Setting].
  $Setting({int id = 0, required Map<String, dynamic> payload})
    : super.new(id: id, payload: payload) {
    _attachOrmRuntimeMetadata({'id': id, 'payload': payload});
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $Setting.fromModel(Setting model) {
    return $Setting(id: model.id, payload: model.payload);
  }

  $Setting copyWith({int? id, Map<String, dynamic>? payload}) {
    return $Setting(id: id ?? this.id, payload: payload ?? this.payload);
  }

  /// Builds a tracked model from a column/value map.
  static $Setting fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$SettingDefinition.fromMap(data, registry: registry);

  /// Converts this tracked model to a column/value map.
  Map<String, Object?> toMap({ValueCodecRegistry? registry}) =>
      _$SettingDefinition.toMap(this, registry: registry);

  /// Tracked getter for [id].
  @override
  int get id => getAttribute<int>('id') ?? super.id;

  /// Tracked setter for [id].
  set id(int value) => setAttribute('id', value);

  /// Tracked getter for [payload].
  @override
  Map<String, dynamic> get payload =>
      getAttribute<Map<String, dynamic>>('payload') ?? super.payload;

  /// Tracked setter for [payload].
  set payload(Map<String, dynamic> value) => setAttribute('payload', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$SettingDefinition);
  }
}

class _SettingCopyWithSentinel {
  const _SettingCopyWithSentinel();
}

extension SettingOrmExtension on Setting {
  static const _SettingCopyWithSentinel _copyWithSentinel =
      _SettingCopyWithSentinel();
  Setting copyWith({
    Object? id = _copyWithSentinel,
    Object? payload = _copyWithSentinel,
  }) {
    return Setting(
      id: identical(id, _copyWithSentinel) ? this.id : id as int,
      payload: identical(payload, _copyWithSentinel)
          ? this.payload
          : payload as Map<String, dynamic>,
    );
  }

  /// Converts this model to a column/value map.
  Map<String, Object?> toMap({ValueCodecRegistry? registry}) =>
      _$SettingDefinition.toMap(this, registry: registry);

  /// Builds a model from a column/value map.
  static Setting fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$SettingDefinition.fromMap(data, registry: registry);

  /// The Type of the generated ORM-managed model class.
  /// Use this when you need to specify the tracked model type explicitly,
  /// for example in generic type parameters.
  static Type get trackedType => $Setting;

  /// Converts this immutable model to a tracked ORM-managed model.
  /// The tracked model supports attribute tracking, change detection,
  /// and persistence operations like save() and touch().
  $Setting toTracked() {
    return $Setting.fromModel(this);
  }
}

extension SettingPredicateFields on PredicateBuilder<Setting> {
  PredicateField<Setting, int> get id =>
      PredicateField<Setting, int>(this, 'id');
  PredicateField<Setting, Map<String, dynamic>> get payload =>
      PredicateField<Setting, Map<String, dynamic>>(this, 'payload');
}

void registerSettingEventHandlers(EventBus bus) {
  // No event handlers registered for Setting.
}
