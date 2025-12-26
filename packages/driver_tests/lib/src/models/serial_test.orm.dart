// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'serial_test.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$SerialTestIdField = FieldDefinition(
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

const FieldDefinition _$SerialTestLabelField = FieldDefinition(
  name: 'label',
  columnName: 'label',
  dartType: 'String',
  resolvedType: 'String',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

Map<String, Object?> _encodeSerialTestUntracked(
  Object model,
  ValueCodecRegistry registry,
) {
  final m = model as SerialTest;
  return <String, Object?>{
    'id': registry.encodeField(_$SerialTestIdField, m.id),
    'label': registry.encodeField(_$SerialTestLabelField, m.label),
  };
}

final ModelDefinition<$SerialTest> _$SerialTestDefinition = ModelDefinition(
  modelName: 'SerialTest',
  tableName: 'serial_tests',
  fields: const [_$SerialTestIdField, _$SerialTestLabelField],
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
  untrackedToMap: _encodeSerialTestUntracked,
  codec: _$SerialTestCodec(),
);

// ignore: unused_element
final serialtestModelDefinitionRegistration =
    ModelFactoryRegistry.register<$SerialTest>(_$SerialTestDefinition);

extension SerialTestOrmDefinition on SerialTest {
  static ModelDefinition<$SerialTest> get definition => _$SerialTestDefinition;
}

class SerialTests {
  const SerialTests._();

  /// Starts building a query for [$SerialTest].
  ///
  /// {@macro ormed.query}
  static Query<$SerialTest> query([String? connection]) =>
      Model.query<$SerialTest>(connection: connection);

  static Future<$SerialTest?> find(Object id, {String? connection}) =>
      Model.find<$SerialTest>(id, connection: connection);

  static Future<$SerialTest> findOrFail(Object id, {String? connection}) =>
      Model.findOrFail<$SerialTest>(id, connection: connection);

  static Future<List<$SerialTest>> all({String? connection}) =>
      Model.all<$SerialTest>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<$SerialTest>(connection: connection);

  static Future<bool> anyExist({String? connection}) =>
      Model.anyExist<$SerialTest>(connection: connection);

  static Query<$SerialTest> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) =>
      Model.where<$SerialTest>(column, operator, value, connection: connection);

  static Query<$SerialTest> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<$SerialTest>(column, values, connection: connection);

  static Query<$SerialTest> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<$SerialTest>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<$SerialTest> limit(int count, {String? connection}) =>
      Model.limit<$SerialTest>(count, connection: connection);

  /// Creates a [Repository] for [$SerialTest].
  ///
  /// {@macro ormed.repository}
  static Repository<$SerialTest> repo([String? connection]) =>
      Model.repository<$SerialTest>(connection: connection);
}

class SerialTestModelFactory {
  const SerialTestModelFactory._();

  static ModelDefinition<$SerialTest> get definition => _$SerialTestDefinition;

  static ModelCodec<$SerialTest> get codec => definition.codec;

  static SerialTest fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    SerialTest model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model.toTracked(), registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<SerialTest> withConnection(
    QueryContext context,
  ) => ModelFactoryConnection<SerialTest>(
    definition: definition,
    context: context,
  );

  static ModelFactoryBuilder<SerialTest> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<SerialTest>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$SerialTestCodec extends ModelCodec<$SerialTest> {
  const _$SerialTestCodec();
  @override
  Map<String, Object?> encode($SerialTest model, ValueCodecRegistry registry) {
    return <String, Object?>{
      'id': registry.encodeField(_$SerialTestIdField, model.id),
      'label': registry.encodeField(_$SerialTestLabelField, model.label),
    };
  }

  @override
  $SerialTest decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final int serialTestIdValue =
        registry.decodeField<int>(_$SerialTestIdField, data['id']) ?? 0;
    final String serialTestLabelValue =
        registry.decodeField<String>(_$SerialTestLabelField, data['label']) ??
        (throw StateError('Field label on SerialTest cannot be null.'));
    final model = $SerialTest(
      id: serialTestIdValue,
      label: serialTestLabelValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': serialTestIdValue,
      'label': serialTestLabelValue,
    });
    return model;
  }
}

/// Insert DTO for [SerialTest].
///
/// Auto-increment/DB-generated fields are omitted by default.
class SerialTestInsertDto implements InsertDto<$SerialTest> {
  const SerialTestInsertDto({this.label});
  final String? label;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{if (label != null) 'label': label};
  }

  static const _SerialTestInsertDtoCopyWithSentinel _copyWithSentinel =
      _SerialTestInsertDtoCopyWithSentinel();
  SerialTestInsertDto copyWith({Object? label = _copyWithSentinel}) {
    return SerialTestInsertDto(
      label: identical(label, _copyWithSentinel)
          ? this.label
          : label as String?,
    );
  }
}

class _SerialTestInsertDtoCopyWithSentinel {
  const _SerialTestInsertDtoCopyWithSentinel();
}

/// Update DTO for [SerialTest].
///
/// All fields are optional; only provided entries are used in SET clauses.
class SerialTestUpdateDto implements UpdateDto<$SerialTest> {
  const SerialTestUpdateDto({this.id, this.label});
  final int? id;
  final String? label;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (label != null) 'label': label,
    };
  }

  static const _SerialTestUpdateDtoCopyWithSentinel _copyWithSentinel =
      _SerialTestUpdateDtoCopyWithSentinel();
  SerialTestUpdateDto copyWith({
    Object? id = _copyWithSentinel,
    Object? label = _copyWithSentinel,
  }) {
    return SerialTestUpdateDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      label: identical(label, _copyWithSentinel)
          ? this.label
          : label as String?,
    );
  }
}

class _SerialTestUpdateDtoCopyWithSentinel {
  const _SerialTestUpdateDtoCopyWithSentinel();
}

/// Partial projection for [SerialTest].
///
/// All fields are nullable; intended for subset SELECTs.
class SerialTestPartial implements PartialEntity<$SerialTest> {
  const SerialTestPartial({this.id, this.label});

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory SerialTestPartial.fromRow(Map<String, Object?> row) {
    return SerialTestPartial(
      id: row['id'] as int?,
      label: row['label'] as String?,
    );
  }

  final int? id;
  final String? label;

  @override
  $SerialTest toEntity() {
    // Basic required-field check: non-nullable fields must be present.
    final int? idValue = id;
    if (idValue == null) {
      throw StateError('Missing required field: id');
    }
    final String? labelValue = label;
    if (labelValue == null) {
      throw StateError('Missing required field: label');
    }
    return $SerialTest(id: idValue, label: labelValue);
  }

  @override
  Map<String, Object?> toMap() {
    return {if (id != null) 'id': id, if (label != null) 'label': label};
  }

  static const _SerialTestPartialCopyWithSentinel _copyWithSentinel =
      _SerialTestPartialCopyWithSentinel();
  SerialTestPartial copyWith({
    Object? id = _copyWithSentinel,
    Object? label = _copyWithSentinel,
  }) {
    return SerialTestPartial(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      label: identical(label, _copyWithSentinel)
          ? this.label
          : label as String?,
    );
  }
}

class _SerialTestPartialCopyWithSentinel {
  const _SerialTestPartialCopyWithSentinel();
}

/// Generated tracked model class for [SerialTest].
///
/// This class extends the user-defined [SerialTest] model and adds
/// attribute tracking, change detection, and relationship management.
/// Instances of this class are returned by queries and repositories.
///
/// **Do not instantiate this class directly.** Use queries, repositories,
/// or model factories to create tracked model instances.
class $SerialTest extends SerialTest with ModelAttributes implements OrmEntity {
  /// Internal constructor for [$SerialTest].
  $SerialTest({int id = 0, required String label})
    : super.new(id: id, label: label) {
    _attachOrmRuntimeMetadata({'id': id, 'label': label});
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $SerialTest.fromModel(SerialTest model) {
    return $SerialTest(id: model.id, label: model.label);
  }

  $SerialTest copyWith({int? id, String? label}) {
    return $SerialTest(id: id ?? this.id, label: label ?? this.label);
  }

  /// Tracked getter for [id].
  @override
  int get id => getAttribute<int>('id') ?? super.id;

  /// Tracked setter for [id].
  set id(int value) => setAttribute('id', value);

  /// Tracked getter for [label].
  @override
  String get label => getAttribute<String>('label') ?? super.label;

  /// Tracked setter for [label].
  set label(String value) => setAttribute('label', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$SerialTestDefinition);
  }
}

extension SerialTestOrmExtension on SerialTest {
  /// The Type of the generated ORM-managed model class.
  /// Use this when you need to specify the tracked model type explicitly,
  /// for example in generic type parameters.
  static Type get trackedType => $SerialTest;

  /// Converts this immutable model to a tracked ORM-managed model.
  /// The tracked model supports attribute tracking, change detection,
  /// and persistence operations like save() and touch().
  $SerialTest toTracked() {
    return $SerialTest.fromModel(this);
  }
}

void registerSerialTestEventHandlers(EventBus bus) {
  // No event handlers registered for SerialTest.
}
