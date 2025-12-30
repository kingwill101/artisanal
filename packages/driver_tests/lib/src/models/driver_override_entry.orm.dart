// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'driver_override_entry.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$DriverOverrideEntryIdField = FieldDefinition(
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

const FieldDefinition _$DriverOverrideEntryPayloadField = FieldDefinition(
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
    'mysql': FieldDriverOverride(
      columnType: 'JSON',
      codecType: 'MariaDbPayloadCodec',
    ),
    'mariadb': FieldDriverOverride(
      columnType: 'JSON',
      codecType: 'MariaDbPayloadCodec',
    ),
  },
);

Map<String, Object?> _encodeDriverOverrideEntryUntracked(
  Object model,
  ValueCodecRegistry registry,
) {
  final m = model as DriverOverrideEntry;
  return <String, Object?>{
    'id': registry.encodeField(_$DriverOverrideEntryIdField, m.id),
    'payload': registry.encodeField(
      _$DriverOverrideEntryPayloadField,
      m.payload,
    ),
  };
}

final ModelDefinition<$DriverOverrideEntry> _$DriverOverrideEntryDefinition =
    ModelDefinition(
      modelName: 'DriverOverrideEntry',
      tableName: 'driver_override_entries',
      fields: const [
        _$DriverOverrideEntryIdField,
        _$DriverOverrideEntryPayloadField,
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
      untrackedToMap: _encodeDriverOverrideEntryUntracked,
      codec: _$DriverOverrideEntryCodec(),
    );

// ignore: unused_element
final driveroverrideentryModelDefinitionRegistration =
    ModelFactoryRegistry.register<$DriverOverrideEntry>(
      _$DriverOverrideEntryDefinition,
    );

extension DriverOverrideEntryOrmDefinition on DriverOverrideEntry {
  static ModelDefinition<$DriverOverrideEntry> get definition =>
      _$DriverOverrideEntryDefinition;
}

class DriverOverrideEntries {
  const DriverOverrideEntries._();

  /// Starts building a query for [$DriverOverrideEntry].
  ///
  /// {@macro ormed.query}
  static Query<$DriverOverrideEntry> query([String? connection]) =>
      Model.query<$DriverOverrideEntry>(connection: connection);

  static Future<$DriverOverrideEntry?> find(Object id, {String? connection}) =>
      Model.find<$DriverOverrideEntry>(id, connection: connection);

  static Future<$DriverOverrideEntry> findOrFail(
    Object id, {
    String? connection,
  }) => Model.findOrFail<$DriverOverrideEntry>(id, connection: connection);

  static Future<List<$DriverOverrideEntry>> all({String? connection}) =>
      Model.all<$DriverOverrideEntry>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<$DriverOverrideEntry>(connection: connection);

  static Future<bool> anyExist({String? connection}) =>
      Model.anyExist<$DriverOverrideEntry>(connection: connection);

  static Query<$DriverOverrideEntry> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) => Model.where<$DriverOverrideEntry>(
    column,
    operator,
    value,
    connection: connection,
  );

  static Query<$DriverOverrideEntry> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<$DriverOverrideEntry>(
    column,
    values,
    connection: connection,
  );

  static Query<$DriverOverrideEntry> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<$DriverOverrideEntry>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<$DriverOverrideEntry> limit(int count, {String? connection}) =>
      Model.limit<$DriverOverrideEntry>(count, connection: connection);

  /// Creates a [Repository] for [$DriverOverrideEntry].
  ///
  /// {@macro ormed.repository}
  static Repository<$DriverOverrideEntry> repo([String? connection]) =>
      Model.repository<$DriverOverrideEntry>(connection: connection);

  /// Builds a tracked model from a column/value map.
  static $DriverOverrideEntry fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$DriverOverrideEntryDefinition.fromMap(data, registry: registry);

  /// Converts a tracked model to a column/value map.
  static Map<String, Object?> toMap(
    $DriverOverrideEntry model, {
    ValueCodecRegistry? registry,
  }) => _$DriverOverrideEntryDefinition.toMap(model, registry: registry);
}

class DriverOverrideEntryModelFactory {
  const DriverOverrideEntryModelFactory._();

  static ModelDefinition<$DriverOverrideEntry> get definition =>
      _$DriverOverrideEntryDefinition;

  static ModelCodec<$DriverOverrideEntry> get codec => definition.codec;

  static DriverOverrideEntry fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    DriverOverrideEntry model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model.toTracked(), registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<DriverOverrideEntry> withConnection(
    QueryContext context,
  ) => ModelFactoryConnection<DriverOverrideEntry>(
    definition: definition,
    context: context,
  );

  static ModelFactoryBuilder<DriverOverrideEntry> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<DriverOverrideEntry>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$DriverOverrideEntryCodec extends ModelCodec<$DriverOverrideEntry> {
  const _$DriverOverrideEntryCodec();
  @override
  Map<String, Object?> encode(
    $DriverOverrideEntry model,
    ValueCodecRegistry registry,
  ) {
    return <String, Object?>{
      'id': registry.encodeField(_$DriverOverrideEntryIdField, model.id),
      'payload': registry.encodeField(
        _$DriverOverrideEntryPayloadField,
        model.payload,
      ),
    };
  }

  @override
  $DriverOverrideEntry decode(
    Map<String, Object?> data,
    ValueCodecRegistry registry,
  ) {
    final int driverOverrideEntryIdValue =
        registry.decodeField<int>(_$DriverOverrideEntryIdField, data['id']) ??
        0;
    final Map<String, Object?> driverOverrideEntryPayloadValue =
        registry.decodeField<Map<String, Object?>>(
          _$DriverOverrideEntryPayloadField,
          data['payload'],
        ) ??
        (throw StateError(
          'Field payload on DriverOverrideEntry cannot be null.',
        ));
    final model = $DriverOverrideEntry(
      id: driverOverrideEntryIdValue,
      payload: driverOverrideEntryPayloadValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': driverOverrideEntryIdValue,
      'payload': driverOverrideEntryPayloadValue,
    });
    return model;
  }
}

/// Insert DTO for [DriverOverrideEntry].
///
/// Auto-increment/DB-generated fields are omitted by default.
class DriverOverrideEntryInsertDto implements InsertDto<$DriverOverrideEntry> {
  const DriverOverrideEntryInsertDto({this.payload});
  final Map<String, Object?>? payload;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{if (payload != null) 'payload': payload};
  }

  static const _DriverOverrideEntryInsertDtoCopyWithSentinel _copyWithSentinel =
      _DriverOverrideEntryInsertDtoCopyWithSentinel();
  DriverOverrideEntryInsertDto copyWith({Object? payload = _copyWithSentinel}) {
    return DriverOverrideEntryInsertDto(
      payload: identical(payload, _copyWithSentinel)
          ? this.payload
          : payload as Map<String, Object?>?,
    );
  }
}

class _DriverOverrideEntryInsertDtoCopyWithSentinel {
  const _DriverOverrideEntryInsertDtoCopyWithSentinel();
}

/// Update DTO for [DriverOverrideEntry].
///
/// All fields are optional; only provided entries are used in SET clauses.
class DriverOverrideEntryUpdateDto implements UpdateDto<$DriverOverrideEntry> {
  const DriverOverrideEntryUpdateDto({this.id, this.payload});
  final int? id;
  final Map<String, Object?>? payload;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (payload != null) 'payload': payload,
    };
  }

  static const _DriverOverrideEntryUpdateDtoCopyWithSentinel _copyWithSentinel =
      _DriverOverrideEntryUpdateDtoCopyWithSentinel();
  DriverOverrideEntryUpdateDto copyWith({
    Object? id = _copyWithSentinel,
    Object? payload = _copyWithSentinel,
  }) {
    return DriverOverrideEntryUpdateDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      payload: identical(payload, _copyWithSentinel)
          ? this.payload
          : payload as Map<String, Object?>?,
    );
  }
}

class _DriverOverrideEntryUpdateDtoCopyWithSentinel {
  const _DriverOverrideEntryUpdateDtoCopyWithSentinel();
}

/// Partial projection for [DriverOverrideEntry].
///
/// All fields are nullable; intended for subset SELECTs.
class DriverOverrideEntryPartial
    implements PartialEntity<$DriverOverrideEntry> {
  const DriverOverrideEntryPartial({this.id, this.payload});

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory DriverOverrideEntryPartial.fromRow(Map<String, Object?> row) {
    return DriverOverrideEntryPartial(
      id: row['id'] as int?,
      payload: row['payload'] as Map<String, Object?>?,
    );
  }

  final int? id;
  final Map<String, Object?>? payload;

  @override
  $DriverOverrideEntry toEntity() {
    // Basic required-field check: non-nullable fields must be present.
    final int? idValue = id;
    if (idValue == null) {
      throw StateError('Missing required field: id');
    }
    final Map<String, Object?>? payloadValue = payload;
    if (payloadValue == null) {
      throw StateError('Missing required field: payload');
    }
    return $DriverOverrideEntry(id: idValue, payload: payloadValue);
  }

  @override
  Map<String, Object?> toMap() {
    return {if (id != null) 'id': id, if (payload != null) 'payload': payload};
  }

  static const _DriverOverrideEntryPartialCopyWithSentinel _copyWithSentinel =
      _DriverOverrideEntryPartialCopyWithSentinel();
  DriverOverrideEntryPartial copyWith({
    Object? id = _copyWithSentinel,
    Object? payload = _copyWithSentinel,
  }) {
    return DriverOverrideEntryPartial(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      payload: identical(payload, _copyWithSentinel)
          ? this.payload
          : payload as Map<String, Object?>?,
    );
  }
}

class _DriverOverrideEntryPartialCopyWithSentinel {
  const _DriverOverrideEntryPartialCopyWithSentinel();
}

/// Generated tracked model class for [DriverOverrideEntry].
///
/// This class extends the user-defined [DriverOverrideEntry] model and adds
/// attribute tracking, change detection, and relationship management.
/// Instances of this class are returned by queries and repositories.
///
/// **Do not instantiate this class directly.** Use queries, repositories,
/// or model factories to create tracked model instances.
class $DriverOverrideEntry extends DriverOverrideEntry
    with ModelAttributes
    implements OrmEntity {
  /// Internal constructor for [$DriverOverrideEntry].
  $DriverOverrideEntry({int id = 0, required Map<String, Object?> payload})
    : super.new(id: id, payload: payload) {
    _attachOrmRuntimeMetadata({'id': id, 'payload': payload});
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $DriverOverrideEntry.fromModel(DriverOverrideEntry model) {
    return $DriverOverrideEntry(id: model.id, payload: model.payload);
  }

  $DriverOverrideEntry copyWith({int? id, Map<String, Object?>? payload}) {
    return $DriverOverrideEntry(
      id: id ?? this.id,
      payload: payload ?? this.payload,
    );
  }

  /// Builds a tracked model from a column/value map.
  static $DriverOverrideEntry fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$DriverOverrideEntryDefinition.fromMap(data, registry: registry);

  /// Converts this tracked model to a column/value map.
  Map<String, Object?> toMap({ValueCodecRegistry? registry}) =>
      _$DriverOverrideEntryDefinition.toMap(this, registry: registry);

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
    attachModelDefinition(_$DriverOverrideEntryDefinition);
  }
}

class _DriverOverrideEntryCopyWithSentinel {
  const _DriverOverrideEntryCopyWithSentinel();
}

extension DriverOverrideEntryOrmExtension on DriverOverrideEntry {
  static const _DriverOverrideEntryCopyWithSentinel _copyWithSentinel =
      _DriverOverrideEntryCopyWithSentinel();
  DriverOverrideEntry copyWith({
    Object? id = _copyWithSentinel,
    Object? payload = _copyWithSentinel,
  }) {
    return DriverOverrideEntry(
      id: identical(id, _copyWithSentinel) ? this.id : id as int,
      payload: identical(payload, _copyWithSentinel)
          ? this.payload
          : payload as Map<String, Object?>,
    );
  }

  /// Converts this model to a column/value map.
  Map<String, Object?> toMap({ValueCodecRegistry? registry}) =>
      _$DriverOverrideEntryDefinition.toMap(this, registry: registry);

  /// Builds a model from a column/value map.
  static DriverOverrideEntry fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$DriverOverrideEntryDefinition.fromMap(data, registry: registry);

  /// The Type of the generated ORM-managed model class.
  /// Use this when you need to specify the tracked model type explicitly,
  /// for example in generic type parameters.
  static Type get trackedType => $DriverOverrideEntry;

  /// Converts this immutable model to a tracked ORM-managed model.
  /// The tracked model supports attribute tracking, change detection,
  /// and persistence operations like save() and touch().
  $DriverOverrideEntry toTracked() {
    return $DriverOverrideEntry.fromModel(this);
  }
}

extension DriverOverrideEntryPredicateFields
    on PredicateBuilder<DriverOverrideEntry> {
  PredicateField<DriverOverrideEntry, int> get id =>
      PredicateField<DriverOverrideEntry, int>(this, 'id');
  PredicateField<DriverOverrideEntry, Map<String, Object?>> get payload =>
      PredicateField<DriverOverrideEntry, Map<String, Object?>>(
        this,
        'payload',
      );
}

void registerDriverOverrideEntryEventHandlers(EventBus bus) {
  // No event handlers registered for DriverOverrideEntry.
}
