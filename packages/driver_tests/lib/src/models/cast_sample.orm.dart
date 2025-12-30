// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'cast_sample.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$CastSampleIdField = FieldDefinition(
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

const FieldDefinition _$CastSampleNameField = FieldDefinition(
  name: 'name',
  columnName: 'name',
  dartType: 'String',
  resolvedType: 'String',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
  codecType: 'string',
);

const FieldDefinition _$CastSampleIsActiveField = FieldDefinition(
  name: 'isActive',
  columnName: 'is_active',
  dartType: 'bool',
  resolvedType: 'bool',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
  codecType: 'boolean',
);

const FieldDefinition _$CastSampleVisitsField = FieldDefinition(
  name: 'visits',
  columnName: 'visits',
  dartType: 'int',
  resolvedType: 'int',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
  codecType: 'integer',
);

const FieldDefinition _$CastSampleRatioField = FieldDefinition(
  name: 'ratio',
  columnName: 'ratio',
  dartType: 'double',
  resolvedType: 'double',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
  codecType: 'float',
);

const FieldDefinition _$CastSampleStartedOnField = FieldDefinition(
  name: 'startedOn',
  columnName: 'started_on',
  dartType: 'DateTime',
  resolvedType: 'DateTime',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
  codecType: 'date',
);

const FieldDefinition _$CastSampleUpdatedAtField = FieldDefinition(
  name: 'updatedAt',
  columnName: 'updated_at',
  dartType: 'DateTime',
  resolvedType: 'DateTime',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
  codecType: 'datetime',
);

const FieldDefinition _$CastSampleAmountField = FieldDefinition(
  name: 'amount',
  columnName: 'amount',
  dartType: 'Decimal',
  resolvedType: 'Decimal',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
  codecType: 'decimal:2',
);

const FieldDefinition _$CastSampleStatusField = FieldDefinition(
  name: 'status',
  columnName: 'status',
  dartType: 'CastStatus',
  resolvedType: 'CastStatus',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
  codecType: 'enum',
  enumValues: CastStatus.values,
);

const FieldDefinition _$CastSampleSecretField = FieldDefinition(
  name: 'secret',
  columnName: 'secret',
  dartType: 'String',
  resolvedType: 'String',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
  codecType: 'encrypted',
);

Map<String, Object?> _encodeCastSampleUntracked(
  Object model,
  ValueCodecRegistry registry,
) {
  final m = model as CastSample;
  return <String, Object?>{
    'id': registry.encodeField(_$CastSampleIdField, m.id),
    'name': registry.encodeField(_$CastSampleNameField, m.name),
    'is_active': registry.encodeField(_$CastSampleIsActiveField, m.isActive),
    'visits': registry.encodeField(_$CastSampleVisitsField, m.visits),
    'ratio': registry.encodeField(_$CastSampleRatioField, m.ratio),
    'started_on': registry.encodeField(_$CastSampleStartedOnField, m.startedOn),
    'updated_at': registry.encodeField(_$CastSampleUpdatedAtField, m.updatedAt),
    'amount': registry.encodeField(_$CastSampleAmountField, m.amount),
    'status': registry.encodeField(_$CastSampleStatusField, m.status),
    'secret': registry.encodeField(_$CastSampleSecretField, m.secret),
  };
}

final ModelDefinition<$CastSample> _$CastSampleDefinition = ModelDefinition(
  modelName: 'CastSample',
  tableName: 'cast_samples',
  fields: const [
    _$CastSampleIdField,
    _$CastSampleNameField,
    _$CastSampleIsActiveField,
    _$CastSampleVisitsField,
    _$CastSampleRatioField,
    _$CastSampleStartedOnField,
    _$CastSampleUpdatedAtField,
    _$CastSampleAmountField,
    _$CastSampleStatusField,
    _$CastSampleSecretField,
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
    fieldOverrides: const {
      'name': FieldAttributeMetadata(cast: 'string'),
      'is_active': FieldAttributeMetadata(cast: 'boolean'),
      'visits': FieldAttributeMetadata(cast: 'integer'),
      'ratio': FieldAttributeMetadata(cast: 'float'),
      'started_on': FieldAttributeMetadata(cast: 'date'),
      'updated_at': FieldAttributeMetadata(cast: 'datetime'),
      'amount': FieldAttributeMetadata(cast: 'decimal:2'),
      'status': FieldAttributeMetadata(cast: 'enum'),
      'secret': FieldAttributeMetadata(cast: 'encrypted'),
    },
    softDeletes: false,
    softDeleteColumn: 'deleted_at',
  ),
  untrackedToMap: _encodeCastSampleUntracked,
  codec: _$CastSampleCodec(),
);

extension CastSampleOrmDefinition on CastSample {
  static ModelDefinition<$CastSample> get definition => _$CastSampleDefinition;
}

class CastSamples {
  const CastSamples._();

  /// Starts building a query for [$CastSample].
  ///
  /// {@macro ormed.query}
  static Query<$CastSample> query([String? connection]) =>
      Model.query<$CastSample>(connection: connection);

  static Future<$CastSample?> find(Object id, {String? connection}) =>
      Model.find<$CastSample>(id, connection: connection);

  static Future<$CastSample> findOrFail(Object id, {String? connection}) =>
      Model.findOrFail<$CastSample>(id, connection: connection);

  static Future<List<$CastSample>> all({String? connection}) =>
      Model.all<$CastSample>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<$CastSample>(connection: connection);

  static Future<bool> anyExist({String? connection}) =>
      Model.anyExist<$CastSample>(connection: connection);

  static Query<$CastSample> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) =>
      Model.where<$CastSample>(column, operator, value, connection: connection);

  static Query<$CastSample> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<$CastSample>(column, values, connection: connection);

  static Query<$CastSample> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<$CastSample>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<$CastSample> limit(int count, {String? connection}) =>
      Model.limit<$CastSample>(count, connection: connection);

  /// Creates a [Repository] for [$CastSample].
  ///
  /// {@macro ormed.repository}
  static Repository<$CastSample> repo([String? connection]) =>
      Model.repository<$CastSample>(connection: connection);

  /// Builds a tracked model from a column/value map.
  static $CastSample fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$CastSampleDefinition.fromMap(data, registry: registry);

  /// Converts a tracked model to a column/value map.
  static Map<String, Object?> toMap(
    $CastSample model, {
    ValueCodecRegistry? registry,
  }) => _$CastSampleDefinition.toMap(model, registry: registry);
}

class CastSampleModelFactory {
  const CastSampleModelFactory._();

  static ModelDefinition<$CastSample> get definition => _$CastSampleDefinition;

  static ModelCodec<$CastSample> get codec => definition.codec;

  static CastSample fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    CastSample model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model.toTracked(), registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<CastSample> withConnection(
    QueryContext context,
  ) => ModelFactoryConnection<CastSample>(
    definition: definition,
    context: context,
  );

  static ModelFactoryBuilder<CastSample> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<CastSample>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$CastSampleCodec extends ModelCodec<$CastSample> {
  const _$CastSampleCodec();
  @override
  Map<String, Object?> encode($CastSample model, ValueCodecRegistry registry) {
    return <String, Object?>{
      'id': registry.encodeField(_$CastSampleIdField, model.id),
      'name': registry.encodeField(_$CastSampleNameField, model.name),
      'is_active': registry.encodeField(
        _$CastSampleIsActiveField,
        model.isActive,
      ),
      'visits': registry.encodeField(_$CastSampleVisitsField, model.visits),
      'ratio': registry.encodeField(_$CastSampleRatioField, model.ratio),
      'started_on': registry.encodeField(
        _$CastSampleStartedOnField,
        model.startedOn,
      ),
      'updated_at': registry.encodeField(
        _$CastSampleUpdatedAtField,
        model.updatedAt,
      ),
      'amount': registry.encodeField(_$CastSampleAmountField, model.amount),
      'status': registry.encodeField(_$CastSampleStatusField, model.status),
      'secret': registry.encodeField(_$CastSampleSecretField, model.secret),
    };
  }

  @override
  $CastSample decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final int castSampleIdValue =
        registry.decodeField<int>(_$CastSampleIdField, data['id']) ??
        (throw StateError('Field id on CastSample cannot be null.'));
    final String castSampleNameValue =
        registry.decodeField<String>(_$CastSampleNameField, data['name']) ??
        (throw StateError('Field name on CastSample cannot be null.'));
    final bool castSampleIsActiveValue =
        registry.decodeField<bool>(
          _$CastSampleIsActiveField,
          data['is_active'],
        ) ??
        (throw StateError('Field isActive on CastSample cannot be null.'));
    final int castSampleVisitsValue =
        registry.decodeField<int>(_$CastSampleVisitsField, data['visits']) ??
        (throw StateError('Field visits on CastSample cannot be null.'));
    final double castSampleRatioValue =
        registry.decodeField<double>(_$CastSampleRatioField, data['ratio']) ??
        (throw StateError('Field ratio on CastSample cannot be null.'));
    final DateTime castSampleStartedOnValue =
        registry.decodeField<DateTime>(
          _$CastSampleStartedOnField,
          data['started_on'],
        ) ??
        (throw StateError('Field startedOn on CastSample cannot be null.'));
    final DateTime castSampleUpdatedAtValue =
        registry.decodeField<DateTime>(
          _$CastSampleUpdatedAtField,
          data['updated_at'],
        ) ??
        (throw StateError('Field updatedAt on CastSample cannot be null.'));
    final Decimal castSampleAmountValue =
        registry.decodeField<Decimal>(
          _$CastSampleAmountField,
          data['amount'],
        ) ??
        (throw StateError('Field amount on CastSample cannot be null.'));
    final CastStatus castSampleStatusValue =
        registry.decodeField<CastStatus>(
          _$CastSampleStatusField,
          data['status'],
        ) ??
        (throw StateError('Field status on CastSample cannot be null.'));
    final String castSampleSecretValue =
        registry.decodeField<String>(_$CastSampleSecretField, data['secret']) ??
        (throw StateError('Field secret on CastSample cannot be null.'));
    final model = $CastSample(
      id: castSampleIdValue,
      name: castSampleNameValue,
      isActive: castSampleIsActiveValue,
      visits: castSampleVisitsValue,
      ratio: castSampleRatioValue,
      startedOn: castSampleStartedOnValue,
      updatedAt: castSampleUpdatedAtValue,
      amount: castSampleAmountValue,
      status: castSampleStatusValue,
      secret: castSampleSecretValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': castSampleIdValue,
      'name': castSampleNameValue,
      'is_active': castSampleIsActiveValue,
      'visits': castSampleVisitsValue,
      'ratio': castSampleRatioValue,
      'started_on': castSampleStartedOnValue,
      'updated_at': castSampleUpdatedAtValue,
      'amount': castSampleAmountValue,
      'status': castSampleStatusValue,
      'secret': castSampleSecretValue,
    });
    return model;
  }
}

/// Insert DTO for [CastSample].
///
/// Auto-increment/DB-generated fields are omitted by default.
class CastSampleInsertDto implements InsertDto<$CastSample> {
  const CastSampleInsertDto({
    this.id,
    this.name,
    this.isActive,
    this.visits,
    this.ratio,
    this.startedOn,
    this.updatedAt,
    this.amount,
    this.status,
    this.secret,
  });
  final int? id;
  final String? name;
  final bool? isActive;
  final int? visits;
  final double? ratio;
  final DateTime? startedOn;
  final DateTime? updatedAt;
  final Decimal? amount;
  final CastStatus? status;
  final String? secret;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (isActive != null) 'is_active': isActive,
      if (visits != null) 'visits': visits,
      if (ratio != null) 'ratio': ratio,
      if (startedOn != null) 'started_on': startedOn,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (amount != null) 'amount': amount,
      if (status != null) 'status': status,
      if (secret != null) 'secret': secret,
    };
  }

  static const _CastSampleInsertDtoCopyWithSentinel _copyWithSentinel =
      _CastSampleInsertDtoCopyWithSentinel();
  CastSampleInsertDto copyWith({
    Object? id = _copyWithSentinel,
    Object? name = _copyWithSentinel,
    Object? isActive = _copyWithSentinel,
    Object? visits = _copyWithSentinel,
    Object? ratio = _copyWithSentinel,
    Object? startedOn = _copyWithSentinel,
    Object? updatedAt = _copyWithSentinel,
    Object? amount = _copyWithSentinel,
    Object? status = _copyWithSentinel,
    Object? secret = _copyWithSentinel,
  }) {
    return CastSampleInsertDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      name: identical(name, _copyWithSentinel) ? this.name : name as String?,
      isActive: identical(isActive, _copyWithSentinel)
          ? this.isActive
          : isActive as bool?,
      visits: identical(visits, _copyWithSentinel)
          ? this.visits
          : visits as int?,
      ratio: identical(ratio, _copyWithSentinel)
          ? this.ratio
          : ratio as double?,
      startedOn: identical(startedOn, _copyWithSentinel)
          ? this.startedOn
          : startedOn as DateTime?,
      updatedAt: identical(updatedAt, _copyWithSentinel)
          ? this.updatedAt
          : updatedAt as DateTime?,
      amount: identical(amount, _copyWithSentinel)
          ? this.amount
          : amount as Decimal?,
      status: identical(status, _copyWithSentinel)
          ? this.status
          : status as CastStatus?,
      secret: identical(secret, _copyWithSentinel)
          ? this.secret
          : secret as String?,
    );
  }
}

class _CastSampleInsertDtoCopyWithSentinel {
  const _CastSampleInsertDtoCopyWithSentinel();
}

/// Update DTO for [CastSample].
///
/// All fields are optional; only provided entries are used in SET clauses.
class CastSampleUpdateDto implements UpdateDto<$CastSample> {
  const CastSampleUpdateDto({
    this.id,
    this.name,
    this.isActive,
    this.visits,
    this.ratio,
    this.startedOn,
    this.updatedAt,
    this.amount,
    this.status,
    this.secret,
  });
  final int? id;
  final String? name;
  final bool? isActive;
  final int? visits;
  final double? ratio;
  final DateTime? startedOn;
  final DateTime? updatedAt;
  final Decimal? amount;
  final CastStatus? status;
  final String? secret;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (isActive != null) 'is_active': isActive,
      if (visits != null) 'visits': visits,
      if (ratio != null) 'ratio': ratio,
      if (startedOn != null) 'started_on': startedOn,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (amount != null) 'amount': amount,
      if (status != null) 'status': status,
      if (secret != null) 'secret': secret,
    };
  }

  static const _CastSampleUpdateDtoCopyWithSentinel _copyWithSentinel =
      _CastSampleUpdateDtoCopyWithSentinel();
  CastSampleUpdateDto copyWith({
    Object? id = _copyWithSentinel,
    Object? name = _copyWithSentinel,
    Object? isActive = _copyWithSentinel,
    Object? visits = _copyWithSentinel,
    Object? ratio = _copyWithSentinel,
    Object? startedOn = _copyWithSentinel,
    Object? updatedAt = _copyWithSentinel,
    Object? amount = _copyWithSentinel,
    Object? status = _copyWithSentinel,
    Object? secret = _copyWithSentinel,
  }) {
    return CastSampleUpdateDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      name: identical(name, _copyWithSentinel) ? this.name : name as String?,
      isActive: identical(isActive, _copyWithSentinel)
          ? this.isActive
          : isActive as bool?,
      visits: identical(visits, _copyWithSentinel)
          ? this.visits
          : visits as int?,
      ratio: identical(ratio, _copyWithSentinel)
          ? this.ratio
          : ratio as double?,
      startedOn: identical(startedOn, _copyWithSentinel)
          ? this.startedOn
          : startedOn as DateTime?,
      updatedAt: identical(updatedAt, _copyWithSentinel)
          ? this.updatedAt
          : updatedAt as DateTime?,
      amount: identical(amount, _copyWithSentinel)
          ? this.amount
          : amount as Decimal?,
      status: identical(status, _copyWithSentinel)
          ? this.status
          : status as CastStatus?,
      secret: identical(secret, _copyWithSentinel)
          ? this.secret
          : secret as String?,
    );
  }
}

class _CastSampleUpdateDtoCopyWithSentinel {
  const _CastSampleUpdateDtoCopyWithSentinel();
}

/// Partial projection for [CastSample].
///
/// All fields are nullable; intended for subset SELECTs.
class CastSamplePartial implements PartialEntity<$CastSample> {
  const CastSamplePartial({
    this.id,
    this.name,
    this.isActive,
    this.visits,
    this.ratio,
    this.startedOn,
    this.updatedAt,
    this.amount,
    this.status,
    this.secret,
  });

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory CastSamplePartial.fromRow(Map<String, Object?> row) {
    return CastSamplePartial(
      id: row['id'] as int?,
      name: row['name'] as String?,
      isActive: row['is_active'] as bool?,
      visits: row['visits'] as int?,
      ratio: row['ratio'] as double?,
      startedOn: row['started_on'] as DateTime?,
      updatedAt: row['updated_at'] as DateTime?,
      amount: row['amount'] as Decimal?,
      status: row['status'] as CastStatus?,
      secret: row['secret'] as String?,
    );
  }

  final int? id;
  final String? name;
  final bool? isActive;
  final int? visits;
  final double? ratio;
  final DateTime? startedOn;
  final DateTime? updatedAt;
  final Decimal? amount;
  final CastStatus? status;
  final String? secret;

  @override
  $CastSample toEntity() {
    // Basic required-field check: non-nullable fields must be present.
    final int? idValue = id;
    if (idValue == null) {
      throw StateError('Missing required field: id');
    }
    final String? nameValue = name;
    if (nameValue == null) {
      throw StateError('Missing required field: name');
    }
    final bool? isActiveValue = isActive;
    if (isActiveValue == null) {
      throw StateError('Missing required field: isActive');
    }
    final int? visitsValue = visits;
    if (visitsValue == null) {
      throw StateError('Missing required field: visits');
    }
    final double? ratioValue = ratio;
    if (ratioValue == null) {
      throw StateError('Missing required field: ratio');
    }
    final DateTime? startedOnValue = startedOn;
    if (startedOnValue == null) {
      throw StateError('Missing required field: startedOn');
    }
    final DateTime? updatedAtValue = updatedAt;
    if (updatedAtValue == null) {
      throw StateError('Missing required field: updatedAt');
    }
    final Decimal? amountValue = amount;
    if (amountValue == null) {
      throw StateError('Missing required field: amount');
    }
    final CastStatus? statusValue = status;
    if (statusValue == null) {
      throw StateError('Missing required field: status');
    }
    final String? secretValue = secret;
    if (secretValue == null) {
      throw StateError('Missing required field: secret');
    }
    return $CastSample(
      id: idValue,
      name: nameValue,
      isActive: isActiveValue,
      visits: visitsValue,
      ratio: ratioValue,
      startedOn: startedOnValue,
      updatedAt: updatedAtValue,
      amount: amountValue,
      status: statusValue,
      secret: secretValue,
    );
  }

  @override
  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (isActive != null) 'is_active': isActive,
      if (visits != null) 'visits': visits,
      if (ratio != null) 'ratio': ratio,
      if (startedOn != null) 'started_on': startedOn,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (amount != null) 'amount': amount,
      if (status != null) 'status': status,
      if (secret != null) 'secret': secret,
    };
  }

  static const _CastSamplePartialCopyWithSentinel _copyWithSentinel =
      _CastSamplePartialCopyWithSentinel();
  CastSamplePartial copyWith({
    Object? id = _copyWithSentinel,
    Object? name = _copyWithSentinel,
    Object? isActive = _copyWithSentinel,
    Object? visits = _copyWithSentinel,
    Object? ratio = _copyWithSentinel,
    Object? startedOn = _copyWithSentinel,
    Object? updatedAt = _copyWithSentinel,
    Object? amount = _copyWithSentinel,
    Object? status = _copyWithSentinel,
    Object? secret = _copyWithSentinel,
  }) {
    return CastSamplePartial(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      name: identical(name, _copyWithSentinel) ? this.name : name as String?,
      isActive: identical(isActive, _copyWithSentinel)
          ? this.isActive
          : isActive as bool?,
      visits: identical(visits, _copyWithSentinel)
          ? this.visits
          : visits as int?,
      ratio: identical(ratio, _copyWithSentinel)
          ? this.ratio
          : ratio as double?,
      startedOn: identical(startedOn, _copyWithSentinel)
          ? this.startedOn
          : startedOn as DateTime?,
      updatedAt: identical(updatedAt, _copyWithSentinel)
          ? this.updatedAt
          : updatedAt as DateTime?,
      amount: identical(amount, _copyWithSentinel)
          ? this.amount
          : amount as Decimal?,
      status: identical(status, _copyWithSentinel)
          ? this.status
          : status as CastStatus?,
      secret: identical(secret, _copyWithSentinel)
          ? this.secret
          : secret as String?,
    );
  }
}

class _CastSamplePartialCopyWithSentinel {
  const _CastSamplePartialCopyWithSentinel();
}

/// Generated tracked model class for [CastSample].
///
/// This class extends the user-defined [CastSample] model and adds
/// attribute tracking, change detection, and relationship management.
/// Instances of this class are returned by queries and repositories.
///
/// **Do not instantiate this class directly.** Use queries, repositories,
/// or model factories to create tracked model instances.
class $CastSample extends CastSample with ModelAttributes implements OrmEntity {
  /// Internal constructor for [$CastSample].
  $CastSample({
    required int id,
    required String name,
    required bool isActive,
    required int visits,
    required double ratio,
    required DateTime startedOn,
    required DateTime updatedAt,
    required Decimal amount,
    required CastStatus status,
    required String secret,
  }) : super(
         id: id,
         name: name,
         isActive: isActive,
         visits: visits,
         ratio: ratio,
         startedOn: startedOn,
         updatedAt: updatedAt,
         amount: amount,
         status: status,
         secret: secret,
       ) {
    _attachOrmRuntimeMetadata({
      'id': id,
      'name': name,
      'is_active': isActive,
      'visits': visits,
      'ratio': ratio,
      'started_on': startedOn,
      'updated_at': updatedAt,
      'amount': amount,
      'status': status,
      'secret': secret,
    });
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $CastSample.fromModel(CastSample model) {
    return $CastSample(
      id: model.id,
      name: model.name,
      isActive: model.isActive,
      visits: model.visits,
      ratio: model.ratio,
      startedOn: model.startedOn,
      updatedAt: model.updatedAt,
      amount: model.amount,
      status: model.status,
      secret: model.secret,
    );
  }

  $CastSample copyWith({
    int? id,
    String? name,
    bool? isActive,
    int? visits,
    double? ratio,
    DateTime? startedOn,
    DateTime? updatedAt,
    Decimal? amount,
    CastStatus? status,
    String? secret,
  }) {
    return $CastSample(
      id: id ?? this.id,
      name: name ?? this.name,
      isActive: isActive ?? this.isActive,
      visits: visits ?? this.visits,
      ratio: ratio ?? this.ratio,
      startedOn: startedOn ?? this.startedOn,
      updatedAt: updatedAt ?? this.updatedAt,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      secret: secret ?? this.secret,
    );
  }

  /// Builds a tracked model from a column/value map.
  static $CastSample fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$CastSampleDefinition.fromMap(data, registry: registry);

  /// Converts this tracked model to a column/value map.
  Map<String, Object?> toMap({ValueCodecRegistry? registry}) =>
      _$CastSampleDefinition.toMap(this, registry: registry);

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

  /// Tracked getter for [isActive].
  @override
  bool get isActive => getAttribute<bool>('is_active') ?? super.isActive;

  /// Tracked setter for [isActive].
  set isActive(bool value) => setAttribute('is_active', value);

  /// Tracked getter for [visits].
  @override
  int get visits => getAttribute<int>('visits') ?? super.visits;

  /// Tracked setter for [visits].
  set visits(int value) => setAttribute('visits', value);

  /// Tracked getter for [ratio].
  @override
  double get ratio => getAttribute<double>('ratio') ?? super.ratio;

  /// Tracked setter for [ratio].
  set ratio(double value) => setAttribute('ratio', value);

  /// Tracked getter for [startedOn].
  @override
  DateTime get startedOn =>
      getAttribute<DateTime>('started_on') ?? super.startedOn;

  /// Tracked setter for [startedOn].
  set startedOn(DateTime value) => setAttribute('started_on', value);

  /// Tracked getter for [updatedAt].
  @override
  DateTime get updatedAt =>
      getAttribute<DateTime>('updated_at') ?? super.updatedAt;

  /// Tracked setter for [updatedAt].
  set updatedAt(DateTime value) => setAttribute('updated_at', value);

  /// Tracked getter for [amount].
  @override
  Decimal get amount => getAttribute<Decimal>('amount') ?? super.amount;

  /// Tracked setter for [amount].
  set amount(Decimal value) => setAttribute('amount', value);

  /// Tracked getter for [status].
  @override
  CastStatus get status => getAttribute<CastStatus>('status') ?? super.status;

  /// Tracked setter for [status].
  set status(CastStatus value) => setAttribute('status', value);

  /// Tracked getter for [secret].
  @override
  String get secret => getAttribute<String>('secret') ?? super.secret;

  /// Tracked setter for [secret].
  set secret(String value) => setAttribute('secret', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$CastSampleDefinition);
  }
}

class _CastSampleCopyWithSentinel {
  const _CastSampleCopyWithSentinel();
}

extension CastSampleOrmExtension on CastSample {
  static const _CastSampleCopyWithSentinel _copyWithSentinel =
      _CastSampleCopyWithSentinel();
  CastSample copyWith({
    Object? id = _copyWithSentinel,
    Object? name = _copyWithSentinel,
    Object? isActive = _copyWithSentinel,
    Object? visits = _copyWithSentinel,
    Object? ratio = _copyWithSentinel,
    Object? startedOn = _copyWithSentinel,
    Object? updatedAt = _copyWithSentinel,
    Object? amount = _copyWithSentinel,
    Object? status = _copyWithSentinel,
    Object? secret = _copyWithSentinel,
  }) {
    return CastSample(
      id: identical(id, _copyWithSentinel) ? this.id : id as int,
      name: identical(name, _copyWithSentinel) ? this.name : name as String,
      isActive: identical(isActive, _copyWithSentinel)
          ? this.isActive
          : isActive as bool,
      visits: identical(visits, _copyWithSentinel)
          ? this.visits
          : visits as int,
      ratio: identical(ratio, _copyWithSentinel) ? this.ratio : ratio as double,
      startedOn: identical(startedOn, _copyWithSentinel)
          ? this.startedOn
          : startedOn as DateTime,
      updatedAt: identical(updatedAt, _copyWithSentinel)
          ? this.updatedAt
          : updatedAt as DateTime,
      amount: identical(amount, _copyWithSentinel)
          ? this.amount
          : amount as Decimal,
      status: identical(status, _copyWithSentinel)
          ? this.status
          : status as CastStatus,
      secret: identical(secret, _copyWithSentinel)
          ? this.secret
          : secret as String,
    );
  }

  /// Converts this model to a column/value map.
  Map<String, Object?> toMap({ValueCodecRegistry? registry}) =>
      _$CastSampleDefinition.toMap(this, registry: registry);

  /// Builds a model from a column/value map.
  static CastSample fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$CastSampleDefinition.fromMap(data, registry: registry);

  /// The Type of the generated ORM-managed model class.
  /// Use this when you need to specify the tracked model type explicitly,
  /// for example in generic type parameters.
  static Type get trackedType => $CastSample;

  /// Converts this immutable model to a tracked ORM-managed model.
  /// The tracked model supports attribute tracking, change detection,
  /// and persistence operations like save() and touch().
  $CastSample toTracked() {
    return $CastSample.fromModel(this);
  }
}

extension CastSamplePredicateFields on PredicateBuilder<CastSample> {
  PredicateField<CastSample, int> get id =>
      PredicateField<CastSample, int>(this, 'id');
  PredicateField<CastSample, String> get name =>
      PredicateField<CastSample, String>(this, 'name');
  PredicateField<CastSample, bool> get isActive =>
      PredicateField<CastSample, bool>(this, 'isActive');
  PredicateField<CastSample, int> get visits =>
      PredicateField<CastSample, int>(this, 'visits');
  PredicateField<CastSample, double> get ratio =>
      PredicateField<CastSample, double>(this, 'ratio');
  PredicateField<CastSample, DateTime> get startedOn =>
      PredicateField<CastSample, DateTime>(this, 'startedOn');
  PredicateField<CastSample, DateTime> get updatedAt =>
      PredicateField<CastSample, DateTime>(this, 'updatedAt');
  PredicateField<CastSample, Decimal> get amount =>
      PredicateField<CastSample, Decimal>(this, 'amount');
  PredicateField<CastSample, CastStatus> get status =>
      PredicateField<CastSample, CastStatus>(this, 'status');
  PredicateField<CastSample, String> get secret =>
      PredicateField<CastSample, String>(this, 'secret');
}

void registerCastSampleEventHandlers(EventBus bus) {
  // No event handlers registered for CastSample.
}
