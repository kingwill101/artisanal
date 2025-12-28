// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'json_value_record.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$JsonValueRecordIdField = FieldDefinition(
  name: 'id',
  columnName: 'id',
  dartType: 'String',
  resolvedType: 'String',
  isPrimaryKey: true,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$JsonValueRecordObjectValueField = FieldDefinition(
  name: 'objectValue',
  columnName: 'object_value',
  dartType: 'Object',
  resolvedType: 'Object?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
  codecType: 'json',
);

const FieldDefinition _$JsonValueRecordStringValueField = FieldDefinition(
  name: 'stringValue',
  columnName: 'string_value',
  dartType: 'String',
  resolvedType: 'String?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
  codecType: 'json',
);

const FieldDefinition _$JsonValueRecordMapDynamicField = FieldDefinition(
  name: 'mapDynamic',
  columnName: 'map_dynamic',
  dartType: 'Map<String, dynamic>',
  resolvedType: 'Map<String, dynamic>?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
  codecType: 'json',
);

const FieldDefinition _$JsonValueRecordMapObjectField = FieldDefinition(
  name: 'mapObject',
  columnName: 'map_object',
  dartType: 'Map<String, Object?>',
  resolvedType: 'Map<String, Object?>?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
  codecType: 'json',
);

const FieldDefinition _$JsonValueRecordListDynamicField = FieldDefinition(
  name: 'listDynamic',
  columnName: 'list_dynamic',
  dartType: 'List<dynamic>',
  resolvedType: 'List<dynamic>?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
  codecType: 'json',
);

const FieldDefinition _$JsonValueRecordListObjectField = FieldDefinition(
  name: 'listObject',
  columnName: 'list_object',
  dartType: 'List<Object?>',
  resolvedType: 'List<Object?>?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
  codecType: 'json',
);

Map<String, Object?> _encodeJsonValueRecordUntracked(
  Object model,
  ValueCodecRegistry registry,
) {
  final m = model as JsonValueRecord;
  return <String, Object?>{
    'id': registry.encodeField(_$JsonValueRecordIdField, m.id),
    'object_value': registry.encodeField(
      _$JsonValueRecordObjectValueField,
      m.objectValue,
    ),
    'string_value': registry.encodeField(
      _$JsonValueRecordStringValueField,
      m.stringValue,
    ),
    'map_dynamic': registry.encodeField(
      _$JsonValueRecordMapDynamicField,
      m.mapDynamic,
    ),
    'map_object': registry.encodeField(
      _$JsonValueRecordMapObjectField,
      m.mapObject,
    ),
    'list_dynamic': registry.encodeField(
      _$JsonValueRecordListDynamicField,
      m.listDynamic,
    ),
    'list_object': registry.encodeField(
      _$JsonValueRecordListObjectField,
      m.listObject,
    ),
  };
}

final ModelDefinition<$JsonValueRecord> _$JsonValueRecordDefinition =
    ModelDefinition(
      modelName: 'JsonValueRecord',
      tableName: 'json_value_records',
      fields: const [
        _$JsonValueRecordIdField,
        _$JsonValueRecordObjectValueField,
        _$JsonValueRecordStringValueField,
        _$JsonValueRecordMapDynamicField,
        _$JsonValueRecordMapObjectField,
        _$JsonValueRecordListDynamicField,
        _$JsonValueRecordListObjectField,
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
          'object_value': FieldAttributeMetadata(cast: 'json'),
          'string_value': FieldAttributeMetadata(cast: 'json'),
          'map_dynamic': FieldAttributeMetadata(cast: 'json'),
          'map_object': FieldAttributeMetadata(cast: 'json'),
          'list_dynamic': FieldAttributeMetadata(cast: 'json'),
          'list_object': FieldAttributeMetadata(cast: 'json'),
        },
        softDeletes: false,
        softDeleteColumn: 'deleted_at',
      ),
      untrackedToMap: _encodeJsonValueRecordUntracked,
      codec: _$JsonValueRecordCodec(),
    );

// ignore: unused_element
final jsonvaluerecordModelDefinitionRegistration =
    ModelFactoryRegistry.register<$JsonValueRecord>(
      _$JsonValueRecordDefinition,
    );

extension JsonValueRecordOrmDefinition on JsonValueRecord {
  static ModelDefinition<$JsonValueRecord> get definition =>
      _$JsonValueRecordDefinition;
}

class JsonValueRecords {
  const JsonValueRecords._();

  /// Starts building a query for [$JsonValueRecord].
  ///
  /// {@macro ormed.query}
  static Query<$JsonValueRecord> query([String? connection]) =>
      Model.query<$JsonValueRecord>(connection: connection);

  static Future<$JsonValueRecord?> find(Object id, {String? connection}) =>
      Model.find<$JsonValueRecord>(id, connection: connection);

  static Future<$JsonValueRecord> findOrFail(Object id, {String? connection}) =>
      Model.findOrFail<$JsonValueRecord>(id, connection: connection);

  static Future<List<$JsonValueRecord>> all({String? connection}) =>
      Model.all<$JsonValueRecord>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<$JsonValueRecord>(connection: connection);

  static Future<bool> anyExist({String? connection}) =>
      Model.anyExist<$JsonValueRecord>(connection: connection);

  static Query<$JsonValueRecord> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) => Model.where<$JsonValueRecord>(
    column,
    operator,
    value,
    connection: connection,
  );

  static Query<$JsonValueRecord> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<$JsonValueRecord>(column, values, connection: connection);

  static Query<$JsonValueRecord> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<$JsonValueRecord>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<$JsonValueRecord> limit(int count, {String? connection}) =>
      Model.limit<$JsonValueRecord>(count, connection: connection);

  /// Creates a [Repository] for [$JsonValueRecord].
  ///
  /// {@macro ormed.repository}
  static Repository<$JsonValueRecord> repo([String? connection]) =>
      Model.repository<$JsonValueRecord>(connection: connection);
}

class JsonValueRecordModelFactory {
  const JsonValueRecordModelFactory._();

  static ModelDefinition<$JsonValueRecord> get definition =>
      _$JsonValueRecordDefinition;

  static ModelCodec<$JsonValueRecord> get codec => definition.codec;

  static JsonValueRecord fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    JsonValueRecord model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model.toTracked(), registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<JsonValueRecord> withConnection(
    QueryContext context,
  ) => ModelFactoryConnection<JsonValueRecord>(
    definition: definition,
    context: context,
  );

  static ModelFactoryBuilder<JsonValueRecord> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<JsonValueRecord>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$JsonValueRecordCodec extends ModelCodec<$JsonValueRecord> {
  const _$JsonValueRecordCodec();
  @override
  Map<String, Object?> encode(
    $JsonValueRecord model,
    ValueCodecRegistry registry,
  ) {
    return <String, Object?>{
      'id': registry.encodeField(_$JsonValueRecordIdField, model.id),
      'object_value': registry.encodeField(
        _$JsonValueRecordObjectValueField,
        model.objectValue,
      ),
      'string_value': registry.encodeField(
        _$JsonValueRecordStringValueField,
        model.stringValue,
      ),
      'map_dynamic': registry.encodeField(
        _$JsonValueRecordMapDynamicField,
        model.mapDynamic,
      ),
      'map_object': registry.encodeField(
        _$JsonValueRecordMapObjectField,
        model.mapObject,
      ),
      'list_dynamic': registry.encodeField(
        _$JsonValueRecordListDynamicField,
        model.listDynamic,
      ),
      'list_object': registry.encodeField(
        _$JsonValueRecordListObjectField,
        model.listObject,
      ),
    };
  }

  @override
  $JsonValueRecord decode(
    Map<String, Object?> data,
    ValueCodecRegistry registry,
  ) {
    final String jsonValueRecordIdValue =
        registry.decodeField<String>(_$JsonValueRecordIdField, data['id']) ??
        (throw StateError('Field id on JsonValueRecord cannot be null.'));
    final Object? jsonValueRecordObjectValueValue = registry
        .decodeField<Object?>(
          _$JsonValueRecordObjectValueField,
          data['object_value'],
        );
    final String? jsonValueRecordStringValueValue = registry
        .decodeField<String?>(
          _$JsonValueRecordStringValueField,
          data['string_value'],
        );
    final Map<String, dynamic>? jsonValueRecordMapDynamicValue = registry
        .decodeField<Map<String, dynamic>?>(
          _$JsonValueRecordMapDynamicField,
          data['map_dynamic'],
        );
    final Map<String, Object?>? jsonValueRecordMapObjectValue = registry
        .decodeField<Map<String, Object?>?>(
          _$JsonValueRecordMapObjectField,
          data['map_object'],
        );
    final List<dynamic>? jsonValueRecordListDynamicValue = registry
        .decodeField<List<dynamic>?>(
          _$JsonValueRecordListDynamicField,
          data['list_dynamic'],
        );
    final List<Object?>? jsonValueRecordListObjectValue = registry
        .decodeField<List<Object?>?>(
          _$JsonValueRecordListObjectField,
          data['list_object'],
        );
    final model = $JsonValueRecord(
      id: jsonValueRecordIdValue,
      objectValue: jsonValueRecordObjectValueValue,
      stringValue: jsonValueRecordStringValueValue,
      mapDynamic: jsonValueRecordMapDynamicValue,
      mapObject: jsonValueRecordMapObjectValue,
      listDynamic: jsonValueRecordListDynamicValue,
      listObject: jsonValueRecordListObjectValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': jsonValueRecordIdValue,
      'object_value': jsonValueRecordObjectValueValue,
      'string_value': jsonValueRecordStringValueValue,
      'map_dynamic': jsonValueRecordMapDynamicValue,
      'map_object': jsonValueRecordMapObjectValue,
      'list_dynamic': jsonValueRecordListDynamicValue,
      'list_object': jsonValueRecordListObjectValue,
    });
    return model;
  }
}

/// Insert DTO for [JsonValueRecord].
///
/// Auto-increment/DB-generated fields are omitted by default.
class JsonValueRecordInsertDto implements InsertDto<$JsonValueRecord> {
  const JsonValueRecordInsertDto({
    this.id,
    this.objectValue,
    this.stringValue,
    this.mapDynamic,
    this.mapObject,
    this.listDynamic,
    this.listObject,
  });
  final String? id;
  final Object? objectValue;
  final String? stringValue;
  final Map<String, dynamic>? mapDynamic;
  final Map<String, Object?>? mapObject;
  final List<dynamic>? listDynamic;
  final List<Object?>? listObject;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (objectValue != null) 'object_value': objectValue,
      if (stringValue != null) 'string_value': stringValue,
      if (mapDynamic != null) 'map_dynamic': mapDynamic,
      if (mapObject != null) 'map_object': mapObject,
      if (listDynamic != null) 'list_dynamic': listDynamic,
      if (listObject != null) 'list_object': listObject,
    };
  }

  static const _JsonValueRecordInsertDtoCopyWithSentinel _copyWithSentinel =
      _JsonValueRecordInsertDtoCopyWithSentinel();
  JsonValueRecordInsertDto copyWith({
    Object? id = _copyWithSentinel,
    Object? objectValue = _copyWithSentinel,
    Object? stringValue = _copyWithSentinel,
    Object? mapDynamic = _copyWithSentinel,
    Object? mapObject = _copyWithSentinel,
    Object? listDynamic = _copyWithSentinel,
    Object? listObject = _copyWithSentinel,
  }) {
    return JsonValueRecordInsertDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as String?,
      objectValue: identical(objectValue, _copyWithSentinel)
          ? this.objectValue
          : objectValue as Object?,
      stringValue: identical(stringValue, _copyWithSentinel)
          ? this.stringValue
          : stringValue as String?,
      mapDynamic: identical(mapDynamic, _copyWithSentinel)
          ? this.mapDynamic
          : mapDynamic as Map<String, dynamic>?,
      mapObject: identical(mapObject, _copyWithSentinel)
          ? this.mapObject
          : mapObject as Map<String, Object?>?,
      listDynamic: identical(listDynamic, _copyWithSentinel)
          ? this.listDynamic
          : listDynamic as List<dynamic>?,
      listObject: identical(listObject, _copyWithSentinel)
          ? this.listObject
          : listObject as List<Object?>?,
    );
  }
}

class _JsonValueRecordInsertDtoCopyWithSentinel {
  const _JsonValueRecordInsertDtoCopyWithSentinel();
}

/// Update DTO for [JsonValueRecord].
///
/// All fields are optional; only provided entries are used in SET clauses.
class JsonValueRecordUpdateDto implements UpdateDto<$JsonValueRecord> {
  const JsonValueRecordUpdateDto({
    this.id,
    this.objectValue,
    this.stringValue,
    this.mapDynamic,
    this.mapObject,
    this.listDynamic,
    this.listObject,
  });
  final String? id;
  final Object? objectValue;
  final String? stringValue;
  final Map<String, dynamic>? mapDynamic;
  final Map<String, Object?>? mapObject;
  final List<dynamic>? listDynamic;
  final List<Object?>? listObject;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (objectValue != null) 'object_value': objectValue,
      if (stringValue != null) 'string_value': stringValue,
      if (mapDynamic != null) 'map_dynamic': mapDynamic,
      if (mapObject != null) 'map_object': mapObject,
      if (listDynamic != null) 'list_dynamic': listDynamic,
      if (listObject != null) 'list_object': listObject,
    };
  }

  static const _JsonValueRecordUpdateDtoCopyWithSentinel _copyWithSentinel =
      _JsonValueRecordUpdateDtoCopyWithSentinel();
  JsonValueRecordUpdateDto copyWith({
    Object? id = _copyWithSentinel,
    Object? objectValue = _copyWithSentinel,
    Object? stringValue = _copyWithSentinel,
    Object? mapDynamic = _copyWithSentinel,
    Object? mapObject = _copyWithSentinel,
    Object? listDynamic = _copyWithSentinel,
    Object? listObject = _copyWithSentinel,
  }) {
    return JsonValueRecordUpdateDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as String?,
      objectValue: identical(objectValue, _copyWithSentinel)
          ? this.objectValue
          : objectValue as Object?,
      stringValue: identical(stringValue, _copyWithSentinel)
          ? this.stringValue
          : stringValue as String?,
      mapDynamic: identical(mapDynamic, _copyWithSentinel)
          ? this.mapDynamic
          : mapDynamic as Map<String, dynamic>?,
      mapObject: identical(mapObject, _copyWithSentinel)
          ? this.mapObject
          : mapObject as Map<String, Object?>?,
      listDynamic: identical(listDynamic, _copyWithSentinel)
          ? this.listDynamic
          : listDynamic as List<dynamic>?,
      listObject: identical(listObject, _copyWithSentinel)
          ? this.listObject
          : listObject as List<Object?>?,
    );
  }
}

class _JsonValueRecordUpdateDtoCopyWithSentinel {
  const _JsonValueRecordUpdateDtoCopyWithSentinel();
}

/// Partial projection for [JsonValueRecord].
///
/// All fields are nullable; intended for subset SELECTs.
class JsonValueRecordPartial implements PartialEntity<$JsonValueRecord> {
  const JsonValueRecordPartial({
    this.id,
    this.objectValue,
    this.stringValue,
    this.mapDynamic,
    this.mapObject,
    this.listDynamic,
    this.listObject,
  });

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory JsonValueRecordPartial.fromRow(Map<String, Object?> row) {
    return JsonValueRecordPartial(
      id: row['id'] as String?,
      objectValue: row['object_value'] as Object?,
      stringValue: row['string_value'] as String?,
      mapDynamic: row['map_dynamic'] as Map<String, dynamic>?,
      mapObject: row['map_object'] as Map<String, Object?>?,
      listDynamic: row['list_dynamic'] as List<dynamic>?,
      listObject: row['list_object'] as List<Object?>?,
    );
  }

  final String? id;
  final Object? objectValue;
  final String? stringValue;
  final Map<String, dynamic>? mapDynamic;
  final Map<String, Object?>? mapObject;
  final List<dynamic>? listDynamic;
  final List<Object?>? listObject;

  @override
  $JsonValueRecord toEntity() {
    // Basic required-field check: non-nullable fields must be present.
    final String? idValue = id;
    if (idValue == null) {
      throw StateError('Missing required field: id');
    }
    return $JsonValueRecord(
      id: idValue,
      objectValue: objectValue,
      stringValue: stringValue,
      mapDynamic: mapDynamic,
      mapObject: mapObject,
      listDynamic: listDynamic,
      listObject: listObject,
    );
  }

  @override
  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      if (objectValue != null) 'object_value': objectValue,
      if (stringValue != null) 'string_value': stringValue,
      if (mapDynamic != null) 'map_dynamic': mapDynamic,
      if (mapObject != null) 'map_object': mapObject,
      if (listDynamic != null) 'list_dynamic': listDynamic,
      if (listObject != null) 'list_object': listObject,
    };
  }

  static const _JsonValueRecordPartialCopyWithSentinel _copyWithSentinel =
      _JsonValueRecordPartialCopyWithSentinel();
  JsonValueRecordPartial copyWith({
    Object? id = _copyWithSentinel,
    Object? objectValue = _copyWithSentinel,
    Object? stringValue = _copyWithSentinel,
    Object? mapDynamic = _copyWithSentinel,
    Object? mapObject = _copyWithSentinel,
    Object? listDynamic = _copyWithSentinel,
    Object? listObject = _copyWithSentinel,
  }) {
    return JsonValueRecordPartial(
      id: identical(id, _copyWithSentinel) ? this.id : id as String?,
      objectValue: identical(objectValue, _copyWithSentinel)
          ? this.objectValue
          : objectValue as Object?,
      stringValue: identical(stringValue, _copyWithSentinel)
          ? this.stringValue
          : stringValue as String?,
      mapDynamic: identical(mapDynamic, _copyWithSentinel)
          ? this.mapDynamic
          : mapDynamic as Map<String, dynamic>?,
      mapObject: identical(mapObject, _copyWithSentinel)
          ? this.mapObject
          : mapObject as Map<String, Object?>?,
      listDynamic: identical(listDynamic, _copyWithSentinel)
          ? this.listDynamic
          : listDynamic as List<dynamic>?,
      listObject: identical(listObject, _copyWithSentinel)
          ? this.listObject
          : listObject as List<Object?>?,
    );
  }
}

class _JsonValueRecordPartialCopyWithSentinel {
  const _JsonValueRecordPartialCopyWithSentinel();
}

/// Generated tracked model class for [JsonValueRecord].
///
/// This class extends the user-defined [JsonValueRecord] model and adds
/// attribute tracking, change detection, and relationship management.
/// Instances of this class are returned by queries and repositories.
///
/// **Do not instantiate this class directly.** Use queries, repositories,
/// or model factories to create tracked model instances.
class $JsonValueRecord extends JsonValueRecord
    with ModelAttributes
    implements OrmEntity {
  /// Internal constructor for [$JsonValueRecord].
  $JsonValueRecord({
    required String id,
    Object? objectValue,
    String? stringValue,
    Map<String, dynamic>? mapDynamic,
    Map<String, Object?>? mapObject,
    List<dynamic>? listDynamic,
    List<Object?>? listObject,
  }) : super.new(
         id: id,
         objectValue: objectValue,
         stringValue: stringValue,
         mapDynamic: mapDynamic,
         mapObject: mapObject,
         listDynamic: listDynamic,
         listObject: listObject,
       ) {
    _attachOrmRuntimeMetadata({
      'id': id,
      'object_value': objectValue,
      'string_value': stringValue,
      'map_dynamic': mapDynamic,
      'map_object': mapObject,
      'list_dynamic': listDynamic,
      'list_object': listObject,
    });
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $JsonValueRecord.fromModel(JsonValueRecord model) {
    return $JsonValueRecord(
      id: model.id,
      objectValue: model.objectValue,
      stringValue: model.stringValue,
      mapDynamic: model.mapDynamic,
      mapObject: model.mapObject,
      listDynamic: model.listDynamic,
      listObject: model.listObject,
    );
  }

  $JsonValueRecord copyWith({
    String? id,
    Object? objectValue,
    String? stringValue,
    Map<String, dynamic>? mapDynamic,
    Map<String, Object?>? mapObject,
    List<dynamic>? listDynamic,
    List<Object?>? listObject,
  }) {
    return $JsonValueRecord(
      id: id ?? this.id,
      objectValue: objectValue ?? this.objectValue,
      stringValue: stringValue ?? this.stringValue,
      mapDynamic: mapDynamic ?? this.mapDynamic,
      mapObject: mapObject ?? this.mapObject,
      listDynamic: listDynamic ?? this.listDynamic,
      listObject: listObject ?? this.listObject,
    );
  }

  /// Tracked getter for [id].
  @override
  String get id => getAttribute<String>('id') ?? super.id;

  /// Tracked setter for [id].
  set id(String value) => setAttribute('id', value);

  /// Tracked getter for [objectValue].
  @override
  Object? get objectValue =>
      getAttribute<Object?>('object_value') ?? super.objectValue;

  /// Tracked setter for [objectValue].
  set objectValue(Object? value) => setAttribute('object_value', value);

  /// Tracked getter for [stringValue].
  @override
  String? get stringValue =>
      getAttribute<String?>('string_value') ?? super.stringValue;

  /// Tracked setter for [stringValue].
  set stringValue(String? value) => setAttribute('string_value', value);

  /// Tracked getter for [mapDynamic].
  @override
  Map<String, dynamic>? get mapDynamic =>
      getAttribute<Map<String, dynamic>?>('map_dynamic') ?? super.mapDynamic;

  /// Tracked setter for [mapDynamic].
  set mapDynamic(Map<String, dynamic>? value) =>
      setAttribute('map_dynamic', value);

  /// Tracked getter for [mapObject].
  @override
  Map<String, Object?>? get mapObject =>
      getAttribute<Map<String, Object?>?>('map_object') ?? super.mapObject;

  /// Tracked setter for [mapObject].
  set mapObject(Map<String, Object?>? value) =>
      setAttribute('map_object', value);

  /// Tracked getter for [listDynamic].
  @override
  List<dynamic>? get listDynamic =>
      getAttribute<List<dynamic>?>('list_dynamic') ?? super.listDynamic;

  /// Tracked setter for [listDynamic].
  set listDynamic(List<dynamic>? value) => setAttribute('list_dynamic', value);

  /// Tracked getter for [listObject].
  @override
  List<Object?>? get listObject =>
      getAttribute<List<Object?>?>('list_object') ?? super.listObject;

  /// Tracked setter for [listObject].
  set listObject(List<Object?>? value) => setAttribute('list_object', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$JsonValueRecordDefinition);
  }
}

extension JsonValueRecordOrmExtension on JsonValueRecord {
  /// The Type of the generated ORM-managed model class.
  /// Use this when you need to specify the tracked model type explicitly,
  /// for example in generic type parameters.
  static Type get trackedType => $JsonValueRecord;

  /// Converts this immutable model to a tracked ORM-managed model.
  /// The tracked model supports attribute tracking, change detection,
  /// and persistence operations like save() and touch().
  $JsonValueRecord toTracked() {
    return $JsonValueRecord.fromModel(this);
  }
}

extension JsonValueRecordPredicateFields on PredicateBuilder<JsonValueRecord> {
  PredicateField<JsonValueRecord, String> get id =>
      PredicateField<JsonValueRecord, String>(this, 'id');
  PredicateField<JsonValueRecord, Object?> get objectValue =>
      PredicateField<JsonValueRecord, Object?>(this, 'objectValue');
  PredicateField<JsonValueRecord, String?> get stringValue =>
      PredicateField<JsonValueRecord, String?>(this, 'stringValue');
  PredicateField<JsonValueRecord, Map<String, dynamic>?> get mapDynamic =>
      PredicateField<JsonValueRecord, Map<String, dynamic>?>(
        this,
        'mapDynamic',
      );
  PredicateField<JsonValueRecord, Map<String, Object?>?> get mapObject =>
      PredicateField<JsonValueRecord, Map<String, Object?>?>(this, 'mapObject');
  PredicateField<JsonValueRecord, List<dynamic>?> get listDynamic =>
      PredicateField<JsonValueRecord, List<dynamic>?>(this, 'listDynamic');
  PredicateField<JsonValueRecord, List<Object?>?> get listObject =>
      PredicateField<JsonValueRecord, List<Object?>?>(this, 'listObject');
}

void registerJsonValueRecordEventHandlers(EventBus bus) {
  // No event handlers registered for JsonValueRecord.
}
