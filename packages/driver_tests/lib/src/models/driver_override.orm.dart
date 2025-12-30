// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'driver_override.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$DriverOverrideModelIdField = FieldDefinition(
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

const FieldDefinition _$DriverOverrideModelPayloadField = FieldDefinition(
  name: 'payload',
  columnName: 'payload',
  dartType: 'Map<String, Object?>',
  resolvedType: 'Map<String, Object?>',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
  columnType: 'TEXT',
  driverOverrides: {
    'postgres': FieldDriverOverride(
      columnType: 'jsonb',
      codecType: 'PostgresPayloadCodec',
    ),
    'sqlite': FieldDriverOverride(
      columnType: 'TEXT',
      codecType: 'SqlitePayloadCodec',
    ),
  },
);

Map<String, Object?> _encodeDriverOverrideModelUntracked(
  Object model,
  ValueCodecRegistry registry,
) {
  final m = model as DriverOverrideModel;
  return <String, Object?>{
    'id': registry.encodeField(_$DriverOverrideModelIdField, m.id),
    'payload': registry.encodeField(
      _$DriverOverrideModelPayloadField,
      m.payload,
    ),
  };
}

final ModelDefinition<$DriverOverrideModel> _$DriverOverrideModelDefinition =
    ModelDefinition(
      modelName: 'DriverOverrideModel',
      tableName: 'driver_overrides',
      fields: const [
        _$DriverOverrideModelIdField,
        _$DriverOverrideModelPayloadField,
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
      untrackedToMap: _encodeDriverOverrideModelUntracked,
      codec: _$DriverOverrideModelCodec(),
    );

extension DriverOverrideModelOrmDefinition on DriverOverrideModel {
  static ModelDefinition<$DriverOverrideModel> get definition =>
      _$DriverOverrideModelDefinition;
}

class DriverOverrideModels {
  const DriverOverrideModels._();

  /// Starts building a query for [$DriverOverrideModel].
  ///
  /// {@macro ormed.query}
  static Query<$DriverOverrideModel> query([String? connection]) =>
      Model.query<$DriverOverrideModel>(connection: connection);

  static Future<$DriverOverrideModel?> find(Object id, {String? connection}) =>
      Model.find<$DriverOverrideModel>(id, connection: connection);

  static Future<$DriverOverrideModel> findOrFail(
    Object id, {
    String? connection,
  }) => Model.findOrFail<$DriverOverrideModel>(id, connection: connection);

  static Future<List<$DriverOverrideModel>> all({String? connection}) =>
      Model.all<$DriverOverrideModel>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<$DriverOverrideModel>(connection: connection);

  static Future<bool> anyExist({String? connection}) =>
      Model.anyExist<$DriverOverrideModel>(connection: connection);

  static Query<$DriverOverrideModel> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) => Model.where<$DriverOverrideModel>(
    column,
    operator,
    value,
    connection: connection,
  );

  static Query<$DriverOverrideModel> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<$DriverOverrideModel>(
    column,
    values,
    connection: connection,
  );

  static Query<$DriverOverrideModel> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<$DriverOverrideModel>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<$DriverOverrideModel> limit(int count, {String? connection}) =>
      Model.limit<$DriverOverrideModel>(count, connection: connection);

  /// Creates a [Repository] for [$DriverOverrideModel].
  ///
  /// {@macro ormed.repository}
  static Repository<$DriverOverrideModel> repo([String? connection]) =>
      Model.repository<$DriverOverrideModel>(connection: connection);

  /// Builds a tracked model from a column/value map.
  static $DriverOverrideModel fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$DriverOverrideModelDefinition.fromMap(data, registry: registry);

  /// Converts a tracked model to a column/value map.
  static Map<String, Object?> toMap(
    $DriverOverrideModel model, {
    ValueCodecRegistry? registry,
  }) => _$DriverOverrideModelDefinition.toMap(model, registry: registry);
}

class DriverOverrideModelFactory {
  const DriverOverrideModelFactory._();

  static ModelDefinition<$DriverOverrideModel> get definition =>
      _$DriverOverrideModelDefinition;

  static ModelCodec<$DriverOverrideModel> get codec => definition.codec;

  static DriverOverrideModel fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    DriverOverrideModel model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model.toTracked(), registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<DriverOverrideModel> withConnection(
    QueryContext context,
  ) => ModelFactoryConnection<DriverOverrideModel>(
    definition: definition,
    context: context,
  );

  static ModelFactoryBuilder<DriverOverrideModel> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<DriverOverrideModel>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$DriverOverrideModelCodec extends ModelCodec<$DriverOverrideModel> {
  const _$DriverOverrideModelCodec();
  @override
  Map<String, Object?> encode(
    $DriverOverrideModel model,
    ValueCodecRegistry registry,
  ) {
    return <String, Object?>{
      'id': registry.encodeField(_$DriverOverrideModelIdField, model.id),
      'payload': registry.encodeField(
        _$DriverOverrideModelPayloadField,
        model.payload,
      ),
    };
  }

  @override
  $DriverOverrideModel decode(
    Map<String, Object?> data,
    ValueCodecRegistry registry,
  ) {
    final int driverOverrideModelIdValue =
        registry.decodeField<int>(_$DriverOverrideModelIdField, data['id']) ??
        (throw StateError('Field id on DriverOverrideModel cannot be null.'));
    final Map<String, Object?> driverOverrideModelPayloadValue =
        registry.decodeField<Map<String, Object?>>(
          _$DriverOverrideModelPayloadField,
          data['payload'],
        ) ??
        (throw StateError(
          'Field payload on DriverOverrideModel cannot be null.',
        ));
    final model = $DriverOverrideModel(
      id: driverOverrideModelIdValue,
      payload: driverOverrideModelPayloadValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': driverOverrideModelIdValue,
      'payload': driverOverrideModelPayloadValue,
    });
    return model;
  }
}

/// Insert DTO for [DriverOverrideModel].
///
/// Auto-increment/DB-generated fields are omitted by default.
class DriverOverrideModelInsertDto implements InsertDto<$DriverOverrideModel> {
  const DriverOverrideModelInsertDto({this.id, this.payload});
  final int? id;
  final Map<String, Object?>? payload;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (payload != null) 'payload': payload,
    };
  }

  static const _DriverOverrideModelInsertDtoCopyWithSentinel _copyWithSentinel =
      _DriverOverrideModelInsertDtoCopyWithSentinel();
  DriverOverrideModelInsertDto copyWith({
    Object? id = _copyWithSentinel,
    Object? payload = _copyWithSentinel,
  }) {
    return DriverOverrideModelInsertDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      payload: identical(payload, _copyWithSentinel)
          ? this.payload
          : payload as Map<String, Object?>?,
    );
  }
}

class _DriverOverrideModelInsertDtoCopyWithSentinel {
  const _DriverOverrideModelInsertDtoCopyWithSentinel();
}

/// Update DTO for [DriverOverrideModel].
///
/// All fields are optional; only provided entries are used in SET clauses.
class DriverOverrideModelUpdateDto implements UpdateDto<$DriverOverrideModel> {
  const DriverOverrideModelUpdateDto({this.id, this.payload});
  final int? id;
  final Map<String, Object?>? payload;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (payload != null) 'payload': payload,
    };
  }

  static const _DriverOverrideModelUpdateDtoCopyWithSentinel _copyWithSentinel =
      _DriverOverrideModelUpdateDtoCopyWithSentinel();
  DriverOverrideModelUpdateDto copyWith({
    Object? id = _copyWithSentinel,
    Object? payload = _copyWithSentinel,
  }) {
    return DriverOverrideModelUpdateDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      payload: identical(payload, _copyWithSentinel)
          ? this.payload
          : payload as Map<String, Object?>?,
    );
  }
}

class _DriverOverrideModelUpdateDtoCopyWithSentinel {
  const _DriverOverrideModelUpdateDtoCopyWithSentinel();
}

/// Partial projection for [DriverOverrideModel].
///
/// All fields are nullable; intended for subset SELECTs.
class DriverOverrideModelPartial
    implements PartialEntity<$DriverOverrideModel> {
  const DriverOverrideModelPartial({this.id, this.payload});

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory DriverOverrideModelPartial.fromRow(Map<String, Object?> row) {
    return DriverOverrideModelPartial(
      id: row['id'] as int?,
      payload: row['payload'] as Map<String, Object?>?,
    );
  }

  final int? id;
  final Map<String, Object?>? payload;

  @override
  $DriverOverrideModel toEntity() {
    // Basic required-field check: non-nullable fields must be present.
    final int? idValue = id;
    if (idValue == null) {
      throw StateError('Missing required field: id');
    }
    final Map<String, Object?>? payloadValue = payload;
    if (payloadValue == null) {
      throw StateError('Missing required field: payload');
    }
    return $DriverOverrideModel(id: idValue, payload: payloadValue);
  }

  @override
  Map<String, Object?> toMap() {
    return {if (id != null) 'id': id, if (payload != null) 'payload': payload};
  }

  static const _DriverOverrideModelPartialCopyWithSentinel _copyWithSentinel =
      _DriverOverrideModelPartialCopyWithSentinel();
  DriverOverrideModelPartial copyWith({
    Object? id = _copyWithSentinel,
    Object? payload = _copyWithSentinel,
  }) {
    return DriverOverrideModelPartial(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      payload: identical(payload, _copyWithSentinel)
          ? this.payload
          : payload as Map<String, Object?>?,
    );
  }
}

class _DriverOverrideModelPartialCopyWithSentinel {
  const _DriverOverrideModelPartialCopyWithSentinel();
}

/// Generated tracked model class for [DriverOverrideModel].
///
/// This class extends the user-defined [DriverOverrideModel] model and adds
/// attribute tracking, change detection, and relationship management.
/// Instances of this class are returned by queries and repositories.
///
/// **Do not instantiate this class directly.** Use queries, repositories,
/// or model factories to create tracked model instances.
class $DriverOverrideModel extends DriverOverrideModel
    with ModelAttributes
    implements OrmEntity {
  /// Internal constructor for [$DriverOverrideModel].
  $DriverOverrideModel({required int id, required Map<String, Object?> payload})
    : super.new(id: id, payload: payload) {
    _attachOrmRuntimeMetadata({'id': id, 'payload': payload});
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $DriverOverrideModel.fromModel(DriverOverrideModel model) {
    return $DriverOverrideModel(id: model.id, payload: model.payload);
  }

  $DriverOverrideModel copyWith({int? id, Map<String, Object?>? payload}) {
    return $DriverOverrideModel(
      id: id ?? this.id,
      payload: payload ?? this.payload,
    );
  }

  /// Builds a tracked model from a column/value map.
  static $DriverOverrideModel fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$DriverOverrideModelDefinition.fromMap(data, registry: registry);

  /// Converts this tracked model to a column/value map.
  Map<String, Object?> toMap({ValueCodecRegistry? registry}) =>
      _$DriverOverrideModelDefinition.toMap(this, registry: registry);

  /// Tracked getter for [id].
  @override
  int get id => getAttribute<int>('id') ?? super.id;

  /// Tracked setter for [id].
  set id(int value) => setAttribute('id', value);

  /// Tracked getter for [payload].
  @override
  Map<String, Object?> get payload =>
      getAttribute<Map<String, Object?>>('payload') ?? super.payload;

  /// Tracked setter for [payload].
  set payload(Map<String, Object?> value) => setAttribute('payload', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$DriverOverrideModelDefinition);
  }
}

class _DriverOverrideModelCopyWithSentinel {
  const _DriverOverrideModelCopyWithSentinel();
}

extension DriverOverrideModelOrmExtension on DriverOverrideModel {
  static const _DriverOverrideModelCopyWithSentinel _copyWithSentinel =
      _DriverOverrideModelCopyWithSentinel();
  DriverOverrideModel copyWith({
    Object? id = _copyWithSentinel,
    Object? payload = _copyWithSentinel,
  }) {
    return DriverOverrideModel(
      id: identical(id, _copyWithSentinel) ? this.id : id as int,
      payload: identical(payload, _copyWithSentinel)
          ? this.payload
          : payload as Map<String, Object?>,
    );
  }

  /// Converts this model to a column/value map.
  Map<String, Object?> toMap({ValueCodecRegistry? registry}) =>
      _$DriverOverrideModelDefinition.toMap(this, registry: registry);

  /// Builds a model from a column/value map.
  static DriverOverrideModel fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$DriverOverrideModelDefinition.fromMap(data, registry: registry);

  /// The Type of the generated ORM-managed model class.
  /// Use this when you need to specify the tracked model type explicitly,
  /// for example in generic type parameters.
  static Type get trackedType => $DriverOverrideModel;

  /// Converts this immutable model to a tracked ORM-managed model.
  /// The tracked model supports attribute tracking, change detection,
  /// and persistence operations like save() and touch().
  $DriverOverrideModel toTracked() {
    return $DriverOverrideModel.fromModel(this);
  }
}

extension DriverOverrideModelPredicateFields
    on PredicateBuilder<DriverOverrideModel> {
  PredicateField<DriverOverrideModel, int> get id =>
      PredicateField<DriverOverrideModel, int>(this, 'id');
  PredicateField<DriverOverrideModel, Map<String, Object?>> get payload =>
      PredicateField<DriverOverrideModel, Map<String, Object?>>(
        this,
        'payload',
      );
}

void registerDriverOverrideModelEventHandlers(EventBus bus) {
  // No event handlers registered for DriverOverrideModel.
}
