// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'driver_overrides_examples.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$DriverOverrideExampleIdField = FieldDefinition(
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

const FieldDefinition _$DriverOverrideExamplePayloadField = FieldDefinition(
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

Map<String, Object?> _encodeDriverOverrideExampleUntracked(
  Object model,
  ValueCodecRegistry registry,
) {
  final m = model as DriverOverrideExample;
  return <String, Object?>{
    'id': registry.encodeField(_$DriverOverrideExampleIdField, m.id),
    'payload': registry.encodeField(
      _$DriverOverrideExamplePayloadField,
      m.payload,
    ),
  };
}

final ModelDefinition<$DriverOverrideExample>
_$DriverOverrideExampleDefinition = ModelDefinition(
  modelName: 'DriverOverrideExample',
  tableName: 'driver_override_examples',
  fields: const [
    _$DriverOverrideExampleIdField,
    _$DriverOverrideExamplePayloadField,
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
    softDeletes: false,
    softDeleteColumn: 'deleted_at',
  ),
  untrackedToMap: _encodeDriverOverrideExampleUntracked,
  codec: _$DriverOverrideExampleCodec(),
);

extension DriverOverrideExampleOrmDefinition on DriverOverrideExample {
  static ModelDefinition<$DriverOverrideExample> get definition =>
      _$DriverOverrideExampleDefinition;
}

class DriverOverrideExamples {
  const DriverOverrideExamples._();

  /// Starts building a query for [$DriverOverrideExample].
  ///
  /// {@macro ormed.query}
  static Query<$DriverOverrideExample> query([String? connection]) =>
      Model.query<$DriverOverrideExample>(connection: connection);

  static Future<$DriverOverrideExample?> find(
    Object id, {
    String? connection,
  }) => Model.find<$DriverOverrideExample>(id, connection: connection);

  static Future<$DriverOverrideExample> findOrFail(
    Object id, {
    String? connection,
  }) => Model.findOrFail<$DriverOverrideExample>(id, connection: connection);

  static Future<List<$DriverOverrideExample>> all({String? connection}) =>
      Model.all<$DriverOverrideExample>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<$DriverOverrideExample>(connection: connection);

  static Future<bool> anyExist({String? connection}) =>
      Model.anyExist<$DriverOverrideExample>(connection: connection);

  static Query<$DriverOverrideExample> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) => Model.where<$DriverOverrideExample>(
    column,
    operator,
    value,
    connection: connection,
  );

  static Query<$DriverOverrideExample> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<$DriverOverrideExample>(
    column,
    values,
    connection: connection,
  );

  static Query<$DriverOverrideExample> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<$DriverOverrideExample>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<$DriverOverrideExample> limit(int count, {String? connection}) =>
      Model.limit<$DriverOverrideExample>(count, connection: connection);

  /// Creates a [Repository] for [$DriverOverrideExample].
  ///
  /// {@macro ormed.repository}
  static Repository<$DriverOverrideExample> repo([String? connection]) =>
      Model.repository<$DriverOverrideExample>(connection: connection);
}

class DriverOverrideExampleModelFactory {
  const DriverOverrideExampleModelFactory._();

  static ModelDefinition<$DriverOverrideExample> get definition =>
      _$DriverOverrideExampleDefinition;

  static ModelCodec<$DriverOverrideExample> get codec => definition.codec;

  static DriverOverrideExample fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    DriverOverrideExample model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model.toTracked(), registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<DriverOverrideExample> withConnection(
    QueryContext context,
  ) => ModelFactoryConnection<DriverOverrideExample>(
    definition: definition,
    context: context,
  );

  static ModelFactoryBuilder<DriverOverrideExample> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<DriverOverrideExample>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$DriverOverrideExampleCodec extends ModelCodec<$DriverOverrideExample> {
  const _$DriverOverrideExampleCodec();
  @override
  Map<String, Object?> encode(
    $DriverOverrideExample model,
    ValueCodecRegistry registry,
  ) {
    return <String, Object?>{
      'id': registry.encodeField(_$DriverOverrideExampleIdField, model.id),
      'payload': registry.encodeField(
        _$DriverOverrideExamplePayloadField,
        model.payload,
      ),
    };
  }

  @override
  $DriverOverrideExample decode(
    Map<String, Object?> data,
    ValueCodecRegistry registry,
  ) {
    final int driverOverrideExampleIdValue =
        registry.decodeField<int>(_$DriverOverrideExampleIdField, data['id']) ??
        (throw StateError('Field id on DriverOverrideExample cannot be null.'));
    final Map<String, Object?> driverOverrideExamplePayloadValue =
        registry.decodeField<Map<String, Object?>>(
          _$DriverOverrideExamplePayloadField,
          data['payload'],
        ) ??
        (throw StateError(
          'Field payload on DriverOverrideExample cannot be null.',
        ));
    final model = $DriverOverrideExample(
      id: driverOverrideExampleIdValue,
      payload: driverOverrideExamplePayloadValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': driverOverrideExampleIdValue,
      'payload': driverOverrideExamplePayloadValue,
    });
    return model;
  }
}

/// Insert DTO for [DriverOverrideExample].
///
/// Auto-increment/DB-generated fields are omitted by default.
class DriverOverrideExampleInsertDto
    implements InsertDto<$DriverOverrideExample> {
  const DriverOverrideExampleInsertDto({this.id, this.payload});
  final int? id;
  final Map<String, Object?>? payload;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (payload != null) 'payload': payload,
    };
  }

  static const _DriverOverrideExampleInsertDtoCopyWithSentinel
  _copyWithSentinel = _DriverOverrideExampleInsertDtoCopyWithSentinel();
  DriverOverrideExampleInsertDto copyWith({
    Object? id = _copyWithSentinel,
    Object? payload = _copyWithSentinel,
  }) {
    return DriverOverrideExampleInsertDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      payload: identical(payload, _copyWithSentinel)
          ? this.payload
          : payload as Map<String, Object?>?,
    );
  }
}

class _DriverOverrideExampleInsertDtoCopyWithSentinel {
  const _DriverOverrideExampleInsertDtoCopyWithSentinel();
}

/// Update DTO for [DriverOverrideExample].
///
/// All fields are optional; only provided entries are used in SET clauses.
class DriverOverrideExampleUpdateDto
    implements UpdateDto<$DriverOverrideExample> {
  const DriverOverrideExampleUpdateDto({this.id, this.payload});
  final int? id;
  final Map<String, Object?>? payload;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (payload != null) 'payload': payload,
    };
  }

  static const _DriverOverrideExampleUpdateDtoCopyWithSentinel
  _copyWithSentinel = _DriverOverrideExampleUpdateDtoCopyWithSentinel();
  DriverOverrideExampleUpdateDto copyWith({
    Object? id = _copyWithSentinel,
    Object? payload = _copyWithSentinel,
  }) {
    return DriverOverrideExampleUpdateDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      payload: identical(payload, _copyWithSentinel)
          ? this.payload
          : payload as Map<String, Object?>?,
    );
  }
}

class _DriverOverrideExampleUpdateDtoCopyWithSentinel {
  const _DriverOverrideExampleUpdateDtoCopyWithSentinel();
}

/// Partial projection for [DriverOverrideExample].
///
/// All fields are nullable; intended for subset SELECTs.
class DriverOverrideExamplePartial
    implements PartialEntity<$DriverOverrideExample> {
  const DriverOverrideExamplePartial({this.id, this.payload});

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory DriverOverrideExamplePartial.fromRow(Map<String, Object?> row) {
    return DriverOverrideExamplePartial(
      id: row['id'] as int?,
      payload: row['payload'] as Map<String, Object?>?,
    );
  }

  final int? id;
  final Map<String, Object?>? payload;

  @override
  $DriverOverrideExample toEntity() {
    // Basic required-field check: non-nullable fields must be present.
    final int? idValue = id;
    if (idValue == null) {
      throw StateError('Missing required field: id');
    }
    final Map<String, Object?>? payloadValue = payload;
    if (payloadValue == null) {
      throw StateError('Missing required field: payload');
    }
    return $DriverOverrideExample(id: idValue, payload: payloadValue);
  }

  @override
  Map<String, Object?> toMap() {
    return {if (id != null) 'id': id, if (payload != null) 'payload': payload};
  }

  static const _DriverOverrideExamplePartialCopyWithSentinel _copyWithSentinel =
      _DriverOverrideExamplePartialCopyWithSentinel();
  DriverOverrideExamplePartial copyWith({
    Object? id = _copyWithSentinel,
    Object? payload = _copyWithSentinel,
  }) {
    return DriverOverrideExamplePartial(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      payload: identical(payload, _copyWithSentinel)
          ? this.payload
          : payload as Map<String, Object?>?,
    );
  }
}

class _DriverOverrideExamplePartialCopyWithSentinel {
  const _DriverOverrideExamplePartialCopyWithSentinel();
}

/// Generated tracked model class for [DriverOverrideExample].
///
/// This class extends the user-defined [DriverOverrideExample] model and adds
/// attribute tracking, change detection, and relationship management.
/// Instances of this class are returned by queries and repositories.
///
/// **Do not instantiate this class directly.** Use queries, repositories,
/// or model factories to create tracked model instances.
class $DriverOverrideExample extends DriverOverrideExample
    with ModelAttributes
    implements OrmEntity {
  /// Internal constructor for [$DriverOverrideExample].
  $DriverOverrideExample({
    required int id,
    required Map<String, Object?> payload,
  }) : super.new(id: id, payload: payload) {
    _attachOrmRuntimeMetadata({'id': id, 'payload': payload});
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $DriverOverrideExample.fromModel(DriverOverrideExample model) {
    return $DriverOverrideExample(id: model.id, payload: model.payload);
  }

  $DriverOverrideExample copyWith({int? id, Map<String, Object?>? payload}) {
    return $DriverOverrideExample(
      id: id ?? this.id,
      payload: payload ?? this.payload,
    );
  }

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
    attachModelDefinition(_$DriverOverrideExampleDefinition);
  }
}

extension DriverOverrideExampleOrmExtension on DriverOverrideExample {
  /// The Type of the generated ORM-managed model class.
  /// Use this when you need to specify the tracked model type explicitly,
  /// for example in generic type parameters.
  static Type get trackedType => $DriverOverrideExample;

  /// Converts this immutable model to a tracked ORM-managed model.
  /// The tracked model supports attribute tracking, change detection,
  /// and persistence operations like save() and touch().
  $DriverOverrideExample toTracked() {
    return $DriverOverrideExample.fromModel(this);
  }
}

void registerDriverOverrideExampleEventHandlers(EventBus bus) {
  // No event handlers registered for DriverOverrideExample.
}

const FieldDefinition _$AuditedEventIdField = FieldDefinition(
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

const FieldDefinition _$AuditedEventActionField = FieldDefinition(
  name: 'action',
  columnName: 'action',
  dartType: 'String',
  resolvedType: 'String',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

Map<String, Object?> _encodeAuditedEventUntracked(
  Object model,
  ValueCodecRegistry registry,
) {
  final m = model as AuditedEvent;
  return <String, Object?>{
    'id': registry.encodeField(_$AuditedEventIdField, m.id),
    'action': registry.encodeField(_$AuditedEventActionField, m.action),
  };
}

final ModelDefinition<$AuditedEvent> _$AuditedEventDefinition = ModelDefinition(
  modelName: 'AuditedEvent',
  tableName: 'audited_events',
  fields: const [_$AuditedEventIdField, _$AuditedEventActionField],
  relations: const [],
  softDeleteColumn: 'deleted_at',
  metadata: ModelAttributesMetadata(
    hidden: const <String>[],
    visible: const <String>[],
    fillable: const <String>[],
    guarded: const <String>[],
    casts: const <String, String>{},
    appends: const <String>[],
    driverAnnotations: const [DriverModel('audited')],
    softDeletes: false,
    softDeleteColumn: 'deleted_at',
  ),
  untrackedToMap: _encodeAuditedEventUntracked,
  codec: _$AuditedEventCodec(),
);

extension AuditedEventOrmDefinition on AuditedEvent {
  static ModelDefinition<$AuditedEvent> get definition =>
      _$AuditedEventDefinition;
}

class AuditedEvents {
  const AuditedEvents._();

  /// Starts building a query for [$AuditedEvent].
  ///
  /// {@macro ormed.query}
  static Query<$AuditedEvent> query([String? connection]) =>
      Model.query<$AuditedEvent>(connection: connection);

  static Future<$AuditedEvent?> find(Object id, {String? connection}) =>
      Model.find<$AuditedEvent>(id, connection: connection);

  static Future<$AuditedEvent> findOrFail(Object id, {String? connection}) =>
      Model.findOrFail<$AuditedEvent>(id, connection: connection);

  static Future<List<$AuditedEvent>> all({String? connection}) =>
      Model.all<$AuditedEvent>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<$AuditedEvent>(connection: connection);

  static Future<bool> anyExist({String? connection}) =>
      Model.anyExist<$AuditedEvent>(connection: connection);

  static Query<$AuditedEvent> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) => Model.where<$AuditedEvent>(
    column,
    operator,
    value,
    connection: connection,
  );

  static Query<$AuditedEvent> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<$AuditedEvent>(column, values, connection: connection);

  static Query<$AuditedEvent> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<$AuditedEvent>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<$AuditedEvent> limit(int count, {String? connection}) =>
      Model.limit<$AuditedEvent>(count, connection: connection);

  /// Creates a [Repository] for [$AuditedEvent].
  ///
  /// {@macro ormed.repository}
  static Repository<$AuditedEvent> repo([String? connection]) =>
      Model.repository<$AuditedEvent>(connection: connection);
}

class AuditedEventModelFactory {
  const AuditedEventModelFactory._();

  static ModelDefinition<$AuditedEvent> get definition =>
      _$AuditedEventDefinition;

  static ModelCodec<$AuditedEvent> get codec => definition.codec;

  static AuditedEvent fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    AuditedEvent model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model.toTracked(), registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<AuditedEvent> withConnection(
    QueryContext context,
  ) => ModelFactoryConnection<AuditedEvent>(
    definition: definition,
    context: context,
  );

  static ModelFactoryBuilder<AuditedEvent> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<AuditedEvent>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$AuditedEventCodec extends ModelCodec<$AuditedEvent> {
  const _$AuditedEventCodec();
  @override
  Map<String, Object?> encode(
    $AuditedEvent model,
    ValueCodecRegistry registry,
  ) {
    return <String, Object?>{
      'id': registry.encodeField(_$AuditedEventIdField, model.id),
      'action': registry.encodeField(_$AuditedEventActionField, model.action),
    };
  }

  @override
  $AuditedEvent decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final int auditedEventIdValue =
        registry.decodeField<int>(_$AuditedEventIdField, data['id']) ??
        (throw StateError('Field id on AuditedEvent cannot be null.'));
    final String auditedEventActionValue =
        registry.decodeField<String>(
          _$AuditedEventActionField,
          data['action'],
        ) ??
        (throw StateError('Field action on AuditedEvent cannot be null.'));
    final model = $AuditedEvent(
      id: auditedEventIdValue,
      action: auditedEventActionValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': auditedEventIdValue,
      'action': auditedEventActionValue,
    });
    return model;
  }
}

/// Insert DTO for [AuditedEvent].
///
/// Auto-increment/DB-generated fields are omitted by default.
class AuditedEventInsertDto implements InsertDto<$AuditedEvent> {
  const AuditedEventInsertDto({this.id, this.action});
  final int? id;
  final String? action;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (action != null) 'action': action,
    };
  }

  static const _AuditedEventInsertDtoCopyWithSentinel _copyWithSentinel =
      _AuditedEventInsertDtoCopyWithSentinel();
  AuditedEventInsertDto copyWith({
    Object? id = _copyWithSentinel,
    Object? action = _copyWithSentinel,
  }) {
    return AuditedEventInsertDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      action: identical(action, _copyWithSentinel)
          ? this.action
          : action as String?,
    );
  }
}

class _AuditedEventInsertDtoCopyWithSentinel {
  const _AuditedEventInsertDtoCopyWithSentinel();
}

/// Update DTO for [AuditedEvent].
///
/// All fields are optional; only provided entries are used in SET clauses.
class AuditedEventUpdateDto implements UpdateDto<$AuditedEvent> {
  const AuditedEventUpdateDto({this.id, this.action});
  final int? id;
  final String? action;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (action != null) 'action': action,
    };
  }

  static const _AuditedEventUpdateDtoCopyWithSentinel _copyWithSentinel =
      _AuditedEventUpdateDtoCopyWithSentinel();
  AuditedEventUpdateDto copyWith({
    Object? id = _copyWithSentinel,
    Object? action = _copyWithSentinel,
  }) {
    return AuditedEventUpdateDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      action: identical(action, _copyWithSentinel)
          ? this.action
          : action as String?,
    );
  }
}

class _AuditedEventUpdateDtoCopyWithSentinel {
  const _AuditedEventUpdateDtoCopyWithSentinel();
}

/// Partial projection for [AuditedEvent].
///
/// All fields are nullable; intended for subset SELECTs.
class AuditedEventPartial implements PartialEntity<$AuditedEvent> {
  const AuditedEventPartial({this.id, this.action});

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory AuditedEventPartial.fromRow(Map<String, Object?> row) {
    return AuditedEventPartial(
      id: row['id'] as int?,
      action: row['action'] as String?,
    );
  }

  final int? id;
  final String? action;

  @override
  $AuditedEvent toEntity() {
    // Basic required-field check: non-nullable fields must be present.
    final int? idValue = id;
    if (idValue == null) {
      throw StateError('Missing required field: id');
    }
    final String? actionValue = action;
    if (actionValue == null) {
      throw StateError('Missing required field: action');
    }
    return $AuditedEvent(id: idValue, action: actionValue);
  }

  @override
  Map<String, Object?> toMap() {
    return {if (id != null) 'id': id, if (action != null) 'action': action};
  }

  static const _AuditedEventPartialCopyWithSentinel _copyWithSentinel =
      _AuditedEventPartialCopyWithSentinel();
  AuditedEventPartial copyWith({
    Object? id = _copyWithSentinel,
    Object? action = _copyWithSentinel,
  }) {
    return AuditedEventPartial(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      action: identical(action, _copyWithSentinel)
          ? this.action
          : action as String?,
    );
  }
}

class _AuditedEventPartialCopyWithSentinel {
  const _AuditedEventPartialCopyWithSentinel();
}

/// Generated tracked model class for [AuditedEvent].
///
/// This class extends the user-defined [AuditedEvent] model and adds
/// attribute tracking, change detection, and relationship management.
/// Instances of this class are returned by queries and repositories.
///
/// **Do not instantiate this class directly.** Use queries, repositories,
/// or model factories to create tracked model instances.
class $AuditedEvent extends AuditedEvent
    with ModelAttributes
    implements OrmEntity {
  /// Internal constructor for [$AuditedEvent].
  $AuditedEvent({required int id, required String action})
    : super.new(id: id, action: action) {
    _attachOrmRuntimeMetadata({'id': id, 'action': action});
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $AuditedEvent.fromModel(AuditedEvent model) {
    return $AuditedEvent(id: model.id, action: model.action);
  }

  $AuditedEvent copyWith({int? id, String? action}) {
    return $AuditedEvent(id: id ?? this.id, action: action ?? this.action);
  }

  /// Tracked getter for [id].
  @override
  int get id => getAttribute<int>('id') ?? super.id;

  /// Tracked setter for [id].
  set id(int value) => setAttribute('id', value);

  /// Tracked getter for [action].
  @override
  String get action => getAttribute<String>('action') ?? super.action;

  /// Tracked setter for [action].
  set action(String value) => setAttribute('action', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$AuditedEventDefinition);
  }
}

extension AuditedEventOrmExtension on AuditedEvent {
  /// The Type of the generated ORM-managed model class.
  /// Use this when you need to specify the tracked model type explicitly,
  /// for example in generic type parameters.
  static Type get trackedType => $AuditedEvent;

  /// Converts this immutable model to a tracked ORM-managed model.
  /// The tracked model supports attribute tracking, change detection,
  /// and persistence operations like save() and touch().
  $AuditedEvent toTracked() {
    return $AuditedEvent.fromModel(this);
  }
}

void registerAuditedEventEventHandlers(EventBus bus) {
  // No event handlers registered for AuditedEvent.
}
