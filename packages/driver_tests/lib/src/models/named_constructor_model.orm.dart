// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'named_constructor_model.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$NamedConstructorModelIdField = FieldDefinition(
  name: 'id',
  columnName: 'id',
  dartType: 'int',
  resolvedType: 'int?',
  isPrimaryKey: true,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: true,
);

const FieldDefinition _$NamedConstructorModelNameField = FieldDefinition(
  name: 'name',
  columnName: 'name',
  dartType: 'String',
  resolvedType: 'String',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$NamedConstructorModelValueField = FieldDefinition(
  name: 'value',
  columnName: 'value',
  dartType: 'int',
  resolvedType: 'int',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

Map<String, Object?> _encodeNamedConstructorModelUntracked(
  Object model,
  ValueCodecRegistry registry,
) {
  final m = model as NamedConstructorModel;
  return <String, Object?>{
    'id': registry.encodeField(_$NamedConstructorModelIdField, m.id),
    'name': registry.encodeField(_$NamedConstructorModelNameField, m.name),
    'value': registry.encodeField(_$NamedConstructorModelValueField, m.value),
  };
}

final ModelDefinition<$NamedConstructorModel>
_$NamedConstructorModelDefinition = ModelDefinition(
  modelName: 'NamedConstructorModel',
  tableName: 'named_constructor_models',
  fields: const [
    _$NamedConstructorModelIdField,
    _$NamedConstructorModelNameField,
    _$NamedConstructorModelValueField,
  ],
  relations: const [],
  softDeleteColumn: 'deleted_at',
  metadata: ModelAttributesMetadata(
    hidden: const <String>[],
    visible: const <String>[],
    fillable: const <String>[],
    guarded: const <String>[],
    casts: const <String, String>{},
    softDeletes: false,
    softDeleteColumn: 'deleted_at',
  ),
  untrackedToMap: _encodeNamedConstructorModelUntracked,
  codec: _$NamedConstructorModelCodec(),
);

// ignore: unused_element
final namedconstructormodelModelDefinitionRegistration =
    ModelFactoryRegistry.register<$NamedConstructorModel>(
      _$NamedConstructorModelDefinition,
    );

extension NamedConstructorModelOrmDefinition on NamedConstructorModel {
  static ModelDefinition<$NamedConstructorModel> get definition =>
      _$NamedConstructorModelDefinition;
}

class NamedConstructorModels {
  const NamedConstructorModels._();

  /// Starts building a query for [$NamedConstructorModel].
  ///
  /// {@macro ormed.query}
  static Query<$NamedConstructorModel> query([String? connection]) =>
      Model.query<$NamedConstructorModel>(connection: connection);

  static Future<$NamedConstructorModel?> find(
    Object id, {
    String? connection,
  }) => Model.find<$NamedConstructorModel>(id, connection: connection);

  static Future<$NamedConstructorModel> findOrFail(
    Object id, {
    String? connection,
  }) => Model.findOrFail<$NamedConstructorModel>(id, connection: connection);

  static Future<List<$NamedConstructorModel>> all({String? connection}) =>
      Model.all<$NamedConstructorModel>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<$NamedConstructorModel>(connection: connection);

  static Future<bool> anyExist({String? connection}) =>
      Model.anyExist<$NamedConstructorModel>(connection: connection);

  static Query<$NamedConstructorModel> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) => Model.where<$NamedConstructorModel>(
    column,
    operator,
    value,
    connection: connection,
  );

  static Query<$NamedConstructorModel> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<$NamedConstructorModel>(
    column,
    values,
    connection: connection,
  );

  static Query<$NamedConstructorModel> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<$NamedConstructorModel>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<$NamedConstructorModel> limit(int count, {String? connection}) =>
      Model.limit<$NamedConstructorModel>(count, connection: connection);

  /// Creates a [Repository] for [$NamedConstructorModel].
  ///
  /// {@macro ormed.repository}
  static Repository<$NamedConstructorModel> repo([String? connection]) =>
      Model.repository<$NamedConstructorModel>(connection: connection);
}

class NamedConstructorModelFactory {
  const NamedConstructorModelFactory._();

  static ModelDefinition<$NamedConstructorModel> get definition =>
      _$NamedConstructorModelDefinition;

  static ModelCodec<$NamedConstructorModel> get codec => definition.codec;

  static NamedConstructorModel fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    NamedConstructorModel model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model.toTracked(), registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<NamedConstructorModel> withConnection(
    QueryContext context,
  ) => ModelFactoryConnection<NamedConstructorModel>(
    definition: definition,
    context: context,
  );

  static ModelFactoryBuilder<NamedConstructorModel> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<NamedConstructorModel>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$NamedConstructorModelCodec extends ModelCodec<$NamedConstructorModel> {
  const _$NamedConstructorModelCodec();
  @override
  Map<String, Object?> encode(
    $NamedConstructorModel model,
    ValueCodecRegistry registry,
  ) {
    return <String, Object?>{
      'id': registry.encodeField(_$NamedConstructorModelIdField, model.id),
      'name': registry.encodeField(
        _$NamedConstructorModelNameField,
        model.name,
      ),
      'value': registry.encodeField(
        _$NamedConstructorModelValueField,
        model.value,
      ),
    };
  }

  @override
  $NamedConstructorModel decode(
    Map<String, Object?> data,
    ValueCodecRegistry registry,
  ) {
    final int? namedConstructorModelIdValue = registry.decodeField<int?>(
      _$NamedConstructorModelIdField,
      data['id'],
    );
    final String namedConstructorModelNameValue =
        registry.decodeField<String>(
          _$NamedConstructorModelNameField,
          data['name'],
        ) ??
        (throw StateError(
          'Field name on NamedConstructorModel cannot be null.',
        ));
    final int namedConstructorModelValueValue =
        registry.decodeField<int>(
          _$NamedConstructorModelValueField,
          data['value'],
        ) ??
        (throw StateError(
          'Field value on NamedConstructorModel cannot be null.',
        ));
    final model = $NamedConstructorModel(
      id: namedConstructorModelIdValue,
      name: namedConstructorModelNameValue,
      value: namedConstructorModelValueValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': namedConstructorModelIdValue,
      'name': namedConstructorModelNameValue,
      'value': namedConstructorModelValueValue,
    });
    return model;
  }
}

/// Insert DTO for [NamedConstructorModel].
///
/// Auto-increment/DB-generated fields are omitted by default.
class NamedConstructorModelInsertDto
    implements InsertDto<$NamedConstructorModel> {
  const NamedConstructorModelInsertDto({this.name, this.value});
  final String? name;
  final int? value;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (name != null) 'name': name,
      if (value != null) 'value': value,
    };
  }

  static const _NamedConstructorModelInsertDtoCopyWithSentinel
  _copyWithSentinel = _NamedConstructorModelInsertDtoCopyWithSentinel();
  NamedConstructorModelInsertDto copyWith({
    Object? name = _copyWithSentinel,
    Object? value = _copyWithSentinel,
  }) {
    return NamedConstructorModelInsertDto(
      name: identical(name, _copyWithSentinel) ? this.name : name as String?,
      value: identical(value, _copyWithSentinel) ? this.value : value as int?,
    );
  }
}

class _NamedConstructorModelInsertDtoCopyWithSentinel {
  const _NamedConstructorModelInsertDtoCopyWithSentinel();
}

/// Update DTO for [NamedConstructorModel].
///
/// All fields are optional; only provided entries are used in SET clauses.
class NamedConstructorModelUpdateDto
    implements UpdateDto<$NamedConstructorModel> {
  const NamedConstructorModelUpdateDto({this.id, this.name, this.value});
  final int? id;
  final String? name;
  final int? value;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (value != null) 'value': value,
    };
  }

  static const _NamedConstructorModelUpdateDtoCopyWithSentinel
  _copyWithSentinel = _NamedConstructorModelUpdateDtoCopyWithSentinel();
  NamedConstructorModelUpdateDto copyWith({
    Object? id = _copyWithSentinel,
    Object? name = _copyWithSentinel,
    Object? value = _copyWithSentinel,
  }) {
    return NamedConstructorModelUpdateDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      name: identical(name, _copyWithSentinel) ? this.name : name as String?,
      value: identical(value, _copyWithSentinel) ? this.value : value as int?,
    );
  }
}

class _NamedConstructorModelUpdateDtoCopyWithSentinel {
  const _NamedConstructorModelUpdateDtoCopyWithSentinel();
}

/// Partial projection for [NamedConstructorModel].
///
/// All fields are nullable; intended for subset SELECTs.
class NamedConstructorModelPartial
    implements PartialEntity<$NamedConstructorModel> {
  const NamedConstructorModelPartial({this.id, this.name, this.value});

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory NamedConstructorModelPartial.fromRow(Map<String, Object?> row) {
    return NamedConstructorModelPartial(
      id: row['id'] as int?,
      name: row['name'] as String?,
      value: row['value'] as int?,
    );
  }

  final int? id;
  final String? name;
  final int? value;

  @override
  $NamedConstructorModel toEntity() {
    // Basic required-field check: non-nullable fields must be present.
    final String? nameValue = name;
    if (nameValue == null) {
      throw StateError('Missing required field: name');
    }
    final int? valueValue = value;
    if (valueValue == null) {
      throw StateError('Missing required field: value');
    }
    return $NamedConstructorModel(id: id, name: nameValue, value: valueValue);
  }

  @override
  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (value != null) 'value': value,
    };
  }

  static const _NamedConstructorModelPartialCopyWithSentinel _copyWithSentinel =
      _NamedConstructorModelPartialCopyWithSentinel();
  NamedConstructorModelPartial copyWith({
    Object? id = _copyWithSentinel,
    Object? name = _copyWithSentinel,
    Object? value = _copyWithSentinel,
  }) {
    return NamedConstructorModelPartial(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      name: identical(name, _copyWithSentinel) ? this.name : name as String?,
      value: identical(value, _copyWithSentinel) ? this.value : value as int?,
    );
  }
}

class _NamedConstructorModelPartialCopyWithSentinel {
  const _NamedConstructorModelPartialCopyWithSentinel();
}

/// Generated tracked model class for [NamedConstructorModel].
///
/// This class extends the user-defined [NamedConstructorModel] model and adds
/// attribute tracking, change detection, and relationship management.
/// Instances of this class are returned by queries and repositories.
///
/// **Do not instantiate this class directly.** Use queries, repositories,
/// or model factories to create tracked model instances.
class $NamedConstructorModel extends NamedConstructorModel
    with ModelAttributes
    implements OrmEntity {
  $NamedConstructorModel({
    required int? id,
    required String name,
    required int value,
  }) : super.fromDatabase(id: id, name: name, value: value) {
    _attachOrmRuntimeMetadata({'id': id, 'name': name, 'value': value});
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $NamedConstructorModel.fromModel(NamedConstructorModel model) {
    return $NamedConstructorModel(
      id: model.id,
      name: model.name,
      value: model.value,
    );
  }

  $NamedConstructorModel copyWith({int? id, String? name, int? value}) {
    return $NamedConstructorModel(
      id: id ?? this.id,
      name: name ?? this.name,
      value: value ?? this.value,
    );
  }

  @override
  int? get id => getAttribute<int?>('id') ?? super.id;

  set id(int? value) => setAttribute('id', value);

  @override
  String get name => getAttribute<String>('name') ?? super.name;

  set name(String value) => setAttribute('name', value);

  @override
  int get value => getAttribute<int>('value') ?? super.value;

  set value(int value) => setAttribute('value', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$NamedConstructorModelDefinition);
  }
}

extension NamedConstructorModelOrmExtension on NamedConstructorModel {
  /// The Type of the generated ORM-managed model class.
  /// Use this when you need to specify the tracked model type explicitly,
  /// for example in generic type parameters.
  static Type get trackedType => $NamedConstructorModel;

  /// Converts this immutable model to a tracked ORM-managed model.
  /// The tracked model supports attribute tracking, change detection,
  /// and persistence operations like save() and touch().
  $NamedConstructorModel toTracked() {
    return $NamedConstructorModel.fromModel(this);
  }
}

void registerNamedConstructorModelEventHandlers(EventBus bus) {
  // No event handlers registered for NamedConstructorModel.
}
