// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'log_model.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$LogIdField = FieldDefinition(
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

const FieldDefinition _$LogMessageField = FieldDefinition(
  name: 'message',
  columnName: 'message',
  dartType: 'String',
  resolvedType: 'String',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$LogTimestampField = FieldDefinition(
  name: 'timestamp',
  columnName: 'timestamp',
  dartType: 'DateTime',
  resolvedType: 'DateTime?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

Map<String, Object?> _encodeLogUntracked(
  Object model,
  ValueCodecRegistry registry,
) {
  final m = model as Log;
  return <String, Object?>{
    'id': registry.encodeField(_$LogIdField, m.id),
    'message': registry.encodeField(_$LogMessageField, m.message),
    'timestamp': registry.encodeField(_$LogTimestampField, m.timestamp),
  };
}

final ModelDefinition<$Log> _$LogDefinition = ModelDefinition(
  modelName: 'Log',
  tableName: 'logs',
  fields: const [_$LogIdField, _$LogMessageField, _$LogTimestampField],
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
  untrackedToMap: _encodeLogUntracked,
  codec: _$LogCodec(),
);

extension LogOrmDefinition on Log {
  static ModelDefinition<$Log> get definition => _$LogDefinition;
}

class Logs {
  const Logs._();

  /// Starts building a query for [$Log].
  ///
  /// {@macro ormed.query}
  static Query<$Log> query([String? connection]) =>
      Model.query<$Log>(connection: connection);

  static Future<$Log?> find(Object id, {String? connection}) =>
      Model.find<$Log>(id, connection: connection);

  static Future<$Log> findOrFail(Object id, {String? connection}) =>
      Model.findOrFail<$Log>(id, connection: connection);

  static Future<List<$Log>> all({String? connection}) =>
      Model.all<$Log>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<$Log>(connection: connection);

  static Future<bool> anyExist({String? connection}) =>
      Model.anyExist<$Log>(connection: connection);

  static Query<$Log> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) => Model.where<$Log>(column, operator, value, connection: connection);

  static Query<$Log> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<$Log>(column, values, connection: connection);

  static Query<$Log> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) =>
      Model.orderBy<$Log>(column, direction: direction, connection: connection);

  static Query<$Log> limit(int count, {String? connection}) =>
      Model.limit<$Log>(count, connection: connection);

  /// Creates a [Repository] for [$Log].
  ///
  /// {@macro ormed.repository}
  static Repository<$Log> repo([String? connection]) =>
      Model.repository<$Log>(connection: connection);

  /// Builds a tracked model from a column/value map.
  static $Log fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$LogDefinition.fromMap(data, registry: registry);

  /// Converts a tracked model to a column/value map.
  static Map<String, Object?> toMap(
    $Log model, {
    ValueCodecRegistry? registry,
  }) => _$LogDefinition.toMap(model, registry: registry);
}

class LogModelFactory {
  const LogModelFactory._();

  static ModelDefinition<$Log> get definition => _$LogDefinition;

  static ModelCodec<$Log> get codec => definition.codec;

  static Log fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    Log model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model.toTracked(), registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<Log> withConnection(QueryContext context) =>
      ModelFactoryConnection<Log>(definition: definition, context: context);

  static ModelFactoryBuilder<Log> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<Log>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$LogCodec extends ModelCodec<$Log> {
  const _$LogCodec();
  @override
  Map<String, Object?> encode($Log model, ValueCodecRegistry registry) {
    return <String, Object?>{
      'id': registry.encodeField(_$LogIdField, model.id),
      'message': registry.encodeField(_$LogMessageField, model.message),
      'timestamp': registry.encodeField(_$LogTimestampField, model.timestamp),
    };
  }

  @override
  $Log decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final int logIdValue =
        registry.decodeField<int>(_$LogIdField, data['id']) ??
        (throw StateError('Field id on Log cannot be null.'));
    final String logMessageValue =
        registry.decodeField<String>(_$LogMessageField, data['message']) ??
        (throw StateError('Field message on Log cannot be null.'));
    final DateTime? logTimestampValue = registry.decodeField<DateTime?>(
      _$LogTimestampField,
      data['timestamp'],
    );
    final model = $Log(
      id: logIdValue,
      message: logMessageValue,
      timestamp: logTimestampValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': logIdValue,
      'message': logMessageValue,
      'timestamp': logTimestampValue,
    });
    return model;
  }
}

/// Insert DTO for [Log].
///
/// Auto-increment/DB-generated fields are omitted by default.
class LogInsertDto implements InsertDto<$Log> {
  const LogInsertDto({this.id, this.message, this.timestamp});
  final int? id;
  final String? message;
  final DateTime? timestamp;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (message != null) 'message': message,
      if (timestamp != null) 'timestamp': timestamp,
    };
  }

  static const _LogInsertDtoCopyWithSentinel _copyWithSentinel =
      _LogInsertDtoCopyWithSentinel();
  LogInsertDto copyWith({
    Object? id = _copyWithSentinel,
    Object? message = _copyWithSentinel,
    Object? timestamp = _copyWithSentinel,
  }) {
    return LogInsertDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      message: identical(message, _copyWithSentinel)
          ? this.message
          : message as String?,
      timestamp: identical(timestamp, _copyWithSentinel)
          ? this.timestamp
          : timestamp as DateTime?,
    );
  }
}

class _LogInsertDtoCopyWithSentinel {
  const _LogInsertDtoCopyWithSentinel();
}

/// Update DTO for [Log].
///
/// All fields are optional; only provided entries are used in SET clauses.
class LogUpdateDto implements UpdateDto<$Log> {
  const LogUpdateDto({this.id, this.message, this.timestamp});
  final int? id;
  final String? message;
  final DateTime? timestamp;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (message != null) 'message': message,
      if (timestamp != null) 'timestamp': timestamp,
    };
  }

  static const _LogUpdateDtoCopyWithSentinel _copyWithSentinel =
      _LogUpdateDtoCopyWithSentinel();
  LogUpdateDto copyWith({
    Object? id = _copyWithSentinel,
    Object? message = _copyWithSentinel,
    Object? timestamp = _copyWithSentinel,
  }) {
    return LogUpdateDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      message: identical(message, _copyWithSentinel)
          ? this.message
          : message as String?,
      timestamp: identical(timestamp, _copyWithSentinel)
          ? this.timestamp
          : timestamp as DateTime?,
    );
  }
}

class _LogUpdateDtoCopyWithSentinel {
  const _LogUpdateDtoCopyWithSentinel();
}

/// Partial projection for [Log].
///
/// All fields are nullable; intended for subset SELECTs.
class LogPartial implements PartialEntity<$Log> {
  const LogPartial({this.id, this.message, this.timestamp});

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory LogPartial.fromRow(Map<String, Object?> row) {
    return LogPartial(
      id: row['id'] as int?,
      message: row['message'] as String?,
      timestamp: row['timestamp'] as DateTime?,
    );
  }

  final int? id;
  final String? message;
  final DateTime? timestamp;

  @override
  $Log toEntity() {
    // Basic required-field check: non-nullable fields must be present.
    final int? idValue = id;
    if (idValue == null) {
      throw StateError('Missing required field: id');
    }
    final String? messageValue = message;
    if (messageValue == null) {
      throw StateError('Missing required field: message');
    }
    return $Log(id: idValue, message: messageValue, timestamp: timestamp);
  }

  @override
  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      if (message != null) 'message': message,
      if (timestamp != null) 'timestamp': timestamp,
    };
  }

  static const _LogPartialCopyWithSentinel _copyWithSentinel =
      _LogPartialCopyWithSentinel();
  LogPartial copyWith({
    Object? id = _copyWithSentinel,
    Object? message = _copyWithSentinel,
    Object? timestamp = _copyWithSentinel,
  }) {
    return LogPartial(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      message: identical(message, _copyWithSentinel)
          ? this.message
          : message as String?,
      timestamp: identical(timestamp, _copyWithSentinel)
          ? this.timestamp
          : timestamp as DateTime?,
    );
  }
}

class _LogPartialCopyWithSentinel {
  const _LogPartialCopyWithSentinel();
}

/// Generated tracked model class for [Log].
///
/// This class extends the user-defined [Log] model and adds
/// attribute tracking, change detection, and relationship management.
/// Instances of this class are returned by queries and repositories.
///
/// **Do not instantiate this class directly.** Use queries, repositories,
/// or model factories to create tracked model instances.
class $Log extends Log with ModelAttributes implements OrmEntity {
  /// Internal constructor for [$Log].
  $Log({required int id, required String message, DateTime? timestamp})
    : super.new(id: id, message: message, timestamp: timestamp) {
    _attachOrmRuntimeMetadata({
      'id': id,
      'message': message,
      'timestamp': timestamp,
    });
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $Log.fromModel(Log model) {
    return $Log(
      id: model.id,
      message: model.message,
      timestamp: model.timestamp,
    );
  }

  $Log copyWith({int? id, String? message, DateTime? timestamp}) {
    return $Log(
      id: id ?? this.id,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  /// Builds a tracked model from a column/value map.
  static $Log fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$LogDefinition.fromMap(data, registry: registry);

  /// Converts this tracked model to a column/value map.
  Map<String, Object?> toMap({ValueCodecRegistry? registry}) =>
      _$LogDefinition.toMap(this, registry: registry);

  /// Tracked getter for [id].
  @override
  int get id => getAttribute<int>('id') ?? super.id;

  /// Tracked setter for [id].
  set id(int value) => setAttribute('id', value);

  /// Tracked getter for [message].
  @override
  String get message => getAttribute<String>('message') ?? super.message;

  /// Tracked setter for [message].
  set message(String value) => setAttribute('message', value);

  /// Tracked getter for [timestamp].
  @override
  DateTime? get timestamp =>
      getAttribute<DateTime?>('timestamp') ?? super.timestamp;

  /// Tracked setter for [timestamp].
  set timestamp(DateTime? value) => setAttribute('timestamp', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$LogDefinition);
  }
}

class _LogCopyWithSentinel {
  const _LogCopyWithSentinel();
}

extension LogOrmExtension on Log {
  static const _LogCopyWithSentinel _copyWithSentinel = _LogCopyWithSentinel();
  Log copyWith({
    Object? id = _copyWithSentinel,
    Object? message = _copyWithSentinel,
    Object? timestamp = _copyWithSentinel,
  }) {
    return Log.new(
      id: identical(id, _copyWithSentinel) ? this.id : id as int,
      message: identical(message, _copyWithSentinel)
          ? this.message
          : message as String,
      timestamp: identical(timestamp, _copyWithSentinel)
          ? this.timestamp
          : timestamp as DateTime?,
    );
  }

  /// Converts this model to a column/value map.
  Map<String, Object?> toMap({ValueCodecRegistry? registry}) =>
      _$LogDefinition.toMap(this, registry: registry);

  /// Builds a model from a column/value map.
  static Log fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$LogDefinition.fromMap(data, registry: registry);

  /// The Type of the generated ORM-managed model class.
  /// Use this when you need to specify the tracked model type explicitly,
  /// for example in generic type parameters.
  static Type get trackedType => $Log;

  /// Converts this immutable model to a tracked ORM-managed model.
  /// The tracked model supports attribute tracking, change detection,
  /// and persistence operations like save() and touch().
  $Log toTracked() {
    return $Log.fromModel(this);
  }
}

extension LogPredicateFields on PredicateBuilder<Log> {
  PredicateField<Log, int> get id => PredicateField<Log, int>(this, 'id');
  PredicateField<Log, String> get message =>
      PredicateField<Log, String>(this, 'message');
  PredicateField<Log, DateTime?> get timestamp =>
      PredicateField<Log, DateTime?>(this, 'timestamp');
}

void registerLogEventHandlers(EventBus bus) {
  // No event handlers registered for Log.
}
