// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'mixed_constructor.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$MixedConstructorModelIdField = FieldDefinition(
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

const FieldDefinition _$MixedConstructorModelNameField = FieldDefinition(
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

const FieldDefinition _$MixedConstructorModelDescriptionField = FieldDefinition(
  name: 'description',
  columnName: 'description',
  dartType: 'String',
  resolvedType: 'String?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

Map<String, Object?> _encodeMixedConstructorModelUntracked(
  Object model,
  ValueCodecRegistry registry,
) {
  final m = model as MixedConstructorModel;
  return <String, Object?>{
    'id': registry.encodeField(_$MixedConstructorModelIdField, m.id),
    'name': registry.encodeField(_$MixedConstructorModelNameField, m.name),
    'description': registry.encodeField(
      _$MixedConstructorModelDescriptionField,
      m.description,
    ),
  };
}

final ModelDefinition<$MixedConstructorModel>
_$MixedConstructorModelDefinition = ModelDefinition(
  modelName: 'MixedConstructorModel',
  tableName: 'mixed_constructors',
  fields: const [
    _$MixedConstructorModelIdField,
    _$MixedConstructorModelNameField,
    _$MixedConstructorModelDescriptionField,
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
  untrackedToMap: _encodeMixedConstructorModelUntracked,
  codec: _$MixedConstructorModelCodec(),
);

extension MixedConstructorModelOrmDefinition on MixedConstructorModel {
  static ModelDefinition<$MixedConstructorModel> get definition =>
      _$MixedConstructorModelDefinition;
}

class MixedConstructorModels {
  const MixedConstructorModels._();

  /// Starts building a query for [$MixedConstructorModel].
  ///
  /// {@macro ormed.query}
  static Query<$MixedConstructorModel> query([String? connection]) =>
      Model.query<$MixedConstructorModel>(connection: connection);

  static Future<$MixedConstructorModel?> find(
    Object id, {
    String? connection,
  }) => Model.find<$MixedConstructorModel>(id, connection: connection);

  static Future<$MixedConstructorModel> findOrFail(
    Object id, {
    String? connection,
  }) => Model.findOrFail<$MixedConstructorModel>(id, connection: connection);

  static Future<List<$MixedConstructorModel>> all({String? connection}) =>
      Model.all<$MixedConstructorModel>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<$MixedConstructorModel>(connection: connection);

  static Future<bool> anyExist({String? connection}) =>
      Model.anyExist<$MixedConstructorModel>(connection: connection);

  static Query<$MixedConstructorModel> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) => Model.where<$MixedConstructorModel>(
    column,
    operator,
    value,
    connection: connection,
  );

  static Query<$MixedConstructorModel> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<$MixedConstructorModel>(
    column,
    values,
    connection: connection,
  );

  static Query<$MixedConstructorModel> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<$MixedConstructorModel>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<$MixedConstructorModel> limit(int count, {String? connection}) =>
      Model.limit<$MixedConstructorModel>(count, connection: connection);

  /// Creates a [Repository] for [$MixedConstructorModel].
  ///
  /// {@macro ormed.repository}
  static Repository<$MixedConstructorModel> repo([String? connection]) =>
      Model.repository<$MixedConstructorModel>(connection: connection);
}

class MixedConstructorModelFactory {
  const MixedConstructorModelFactory._();

  static ModelDefinition<$MixedConstructorModel> get definition =>
      _$MixedConstructorModelDefinition;

  static ModelCodec<$MixedConstructorModel> get codec => definition.codec;

  static MixedConstructorModel fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    MixedConstructorModel model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model.toTracked(), registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<MixedConstructorModel> withConnection(
    QueryContext context,
  ) => ModelFactoryConnection<MixedConstructorModel>(
    definition: definition,
    context: context,
  );

  static ModelFactoryBuilder<MixedConstructorModel> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<MixedConstructorModel>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$MixedConstructorModelCodec extends ModelCodec<$MixedConstructorModel> {
  const _$MixedConstructorModelCodec();
  @override
  Map<String, Object?> encode(
    $MixedConstructorModel model,
    ValueCodecRegistry registry,
  ) {
    return <String, Object?>{
      'id': registry.encodeField(_$MixedConstructorModelIdField, model.id),
      'name': registry.encodeField(
        _$MixedConstructorModelNameField,
        model.name,
      ),
      'description': registry.encodeField(
        _$MixedConstructorModelDescriptionField,
        model.description,
      ),
    };
  }

  @override
  $MixedConstructorModel decode(
    Map<String, Object?> data,
    ValueCodecRegistry registry,
  ) {
    final int mixedConstructorModelIdValue =
        registry.decodeField<int>(_$MixedConstructorModelIdField, data['id']) ??
        0;
    final String mixedConstructorModelNameValue =
        registry.decodeField<String>(
          _$MixedConstructorModelNameField,
          data['name'],
        ) ??
        (throw StateError(
          'Field name on MixedConstructorModel cannot be null.',
        ));
    final String? mixedConstructorModelDescriptionValue = registry
        .decodeField<String?>(
          _$MixedConstructorModelDescriptionField,
          data['description'],
        );
    final model = $MixedConstructorModel(
      id: mixedConstructorModelIdValue,
      name: mixedConstructorModelNameValue,
      description: mixedConstructorModelDescriptionValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': mixedConstructorModelIdValue,
      'name': mixedConstructorModelNameValue,
      'description': mixedConstructorModelDescriptionValue,
    });
    return model;
  }
}

/// Insert DTO for [MixedConstructorModel].
///
/// Auto-increment/DB-generated fields are omitted by default.
class MixedConstructorModelInsertDto
    implements InsertDto<$MixedConstructorModel> {
  const MixedConstructorModelInsertDto({this.name, this.description});
  final String? name;
  final String? description;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (name != null) 'name': name,
      if (description != null) 'description': description,
    };
  }

  static const _MixedConstructorModelInsertDtoCopyWithSentinel
  _copyWithSentinel = _MixedConstructorModelInsertDtoCopyWithSentinel();
  MixedConstructorModelInsertDto copyWith({
    Object? name = _copyWithSentinel,
    Object? description = _copyWithSentinel,
  }) {
    return MixedConstructorModelInsertDto(
      name: identical(name, _copyWithSentinel) ? this.name : name as String?,
      description: identical(description, _copyWithSentinel)
          ? this.description
          : description as String?,
    );
  }
}

class _MixedConstructorModelInsertDtoCopyWithSentinel {
  const _MixedConstructorModelInsertDtoCopyWithSentinel();
}

/// Update DTO for [MixedConstructorModel].
///
/// All fields are optional; only provided entries are used in SET clauses.
class MixedConstructorModelUpdateDto
    implements UpdateDto<$MixedConstructorModel> {
  const MixedConstructorModelUpdateDto({this.id, this.name, this.description});
  final int? id;
  final String? name;
  final String? description;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
    };
  }

  static const _MixedConstructorModelUpdateDtoCopyWithSentinel
  _copyWithSentinel = _MixedConstructorModelUpdateDtoCopyWithSentinel();
  MixedConstructorModelUpdateDto copyWith({
    Object? id = _copyWithSentinel,
    Object? name = _copyWithSentinel,
    Object? description = _copyWithSentinel,
  }) {
    return MixedConstructorModelUpdateDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      name: identical(name, _copyWithSentinel) ? this.name : name as String?,
      description: identical(description, _copyWithSentinel)
          ? this.description
          : description as String?,
    );
  }
}

class _MixedConstructorModelUpdateDtoCopyWithSentinel {
  const _MixedConstructorModelUpdateDtoCopyWithSentinel();
}

/// Partial projection for [MixedConstructorModel].
///
/// All fields are nullable; intended for subset SELECTs.
class MixedConstructorModelPartial
    implements PartialEntity<$MixedConstructorModel> {
  const MixedConstructorModelPartial({this.id, this.name, this.description});

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory MixedConstructorModelPartial.fromRow(Map<String, Object?> row) {
    return MixedConstructorModelPartial(
      id: row['id'] as int?,
      name: row['name'] as String?,
      description: row['description'] as String?,
    );
  }

  final int? id;
  final String? name;
  final String? description;

  @override
  $MixedConstructorModel toEntity() {
    // Basic required-field check: non-nullable fields must be present.
    final int? idValue = id;
    if (idValue == null) {
      throw StateError('Missing required field: id');
    }
    final String? nameValue = name;
    if (nameValue == null) {
      throw StateError('Missing required field: name');
    }
    return $MixedConstructorModel(
      id: idValue,
      name: nameValue,
      description: description,
    );
  }

  @override
  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
    };
  }

  static const _MixedConstructorModelPartialCopyWithSentinel _copyWithSentinel =
      _MixedConstructorModelPartialCopyWithSentinel();
  MixedConstructorModelPartial copyWith({
    Object? id = _copyWithSentinel,
    Object? name = _copyWithSentinel,
    Object? description = _copyWithSentinel,
  }) {
    return MixedConstructorModelPartial(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      name: identical(name, _copyWithSentinel) ? this.name : name as String?,
      description: identical(description, _copyWithSentinel)
          ? this.description
          : description as String?,
    );
  }
}

class _MixedConstructorModelPartialCopyWithSentinel {
  const _MixedConstructorModelPartialCopyWithSentinel();
}

/// Generated tracked model class for [MixedConstructorModel].
///
/// This class extends the user-defined [MixedConstructorModel] model and adds
/// attribute tracking, change detection, and relationship management.
/// Instances of this class are returned by queries and repositories.
///
/// **Do not instantiate this class directly.** Use queries, repositories,
/// or model factories to create tracked model instances.
class $MixedConstructorModel extends MixedConstructorModel
    with ModelAttributes
    implements OrmEntity {
  /// Internal constructor for [$MixedConstructorModel].
  $MixedConstructorModel({
    int id = 0,
    required String name,
    String? description,
  }) : super.new(id, name, description: description) {
    _attachOrmRuntimeMetadata({
      'id': id,
      'name': name,
      'description': description,
    });
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $MixedConstructorModel.fromModel(MixedConstructorModel model) {
    return $MixedConstructorModel(
      id: model.id,
      name: model.name,
      description: model.description,
    );
  }

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

  /// Tracked getter for [description].
  @override
  String? get description =>
      getAttribute<String?>('description') ?? super.description;

  /// Tracked setter for [description].
  set description(String? value) => setAttribute('description', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$MixedConstructorModelDefinition);
  }
}

extension MixedConstructorModelOrmExtension on MixedConstructorModel {
  /// The Type of the generated ORM-managed model class.
  /// Use this when you need to specify the tracked model type explicitly,
  /// for example in generic type parameters.
  static Type get trackedType => $MixedConstructorModel;

  /// Converts this immutable model to a tracked ORM-managed model.
  /// The tracked model supports attribute tracking, change detection,
  /// and persistence operations like save() and touch().
  $MixedConstructorModel toTracked() {
    return $MixedConstructorModel.fromModel(this);
  }
}

void registerMixedConstructorModelEventHandlers(EventBus bus) {
  // No event handlers registered for MixedConstructorModel.
}
