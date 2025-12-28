// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'derived_for_factory.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$DerivedForFactoryLayerTwoFlagField = FieldDefinition(
  name: 'layerTwoFlag',
  columnName: 'layer_two_flag',
  dartType: 'bool',
  resolvedType: 'bool?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$DerivedForFactoryLayerOneNotesField = FieldDefinition(
  name: 'layerOneNotes',
  columnName: 'layer_one_notes',
  dartType: 'Map<String, Object?>',
  resolvedType: 'Map<String, Object?>?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
  codecType: 'json',
);

const FieldDefinition _$DerivedForFactoryIdField = FieldDefinition(
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

const FieldDefinition _$DerivedForFactoryBaseNameField = FieldDefinition(
  name: 'baseName',
  columnName: 'base_name',
  dartType: 'String',
  resolvedType: 'String?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

Map<String, Object?> _encodeDerivedForFactoryUntracked(
  Object model,
  ValueCodecRegistry registry,
) {
  final m = model as DerivedForFactory;
  return <String, Object?>{
    'layer_two_flag': registry.encodeField(
      _$DerivedForFactoryLayerTwoFlagField,
      m.layerTwoFlag,
    ),
    'layer_one_notes': registry.encodeField(
      _$DerivedForFactoryLayerOneNotesField,
      m.layerOneNotes,
    ),
    'id': registry.encodeField(_$DerivedForFactoryIdField, m.id),
    'base_name': registry.encodeField(
      _$DerivedForFactoryBaseNameField,
      m.baseName,
    ),
  };
}

final ModelDefinition<$DerivedForFactory> _$DerivedForFactoryDefinition =
    ModelDefinition(
      modelName: 'DerivedForFactory',
      tableName: 'derived_for_factories',
      fields: const [
        _$DerivedForFactoryLayerTwoFlagField,
        _$DerivedForFactoryLayerOneNotesField,
        _$DerivedForFactoryIdField,
        _$DerivedForFactoryBaseNameField,
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
          'layer_two_flag': FieldAttributeMetadata(guarded: true),
          'layer_one_notes': FieldAttributeMetadata(cast: 'json'),
          'id': FieldAttributeMetadata(hidden: true),
          'base_name': FieldAttributeMetadata(fillable: true),
        },
        softDeletes: false,
        softDeleteColumn: 'deleted_at',
      ),
      untrackedToMap: _encodeDerivedForFactoryUntracked,
      codec: _$DerivedForFactoryCodec(),
    );

// ignore: unused_element
final derivedforfactoryModelDefinitionRegistration =
    ModelFactoryRegistry.register<$DerivedForFactory>(
      _$DerivedForFactoryDefinition,
    );

extension DerivedForFactoryOrmDefinition on DerivedForFactory {
  static ModelDefinition<$DerivedForFactory> get definition =>
      _$DerivedForFactoryDefinition;
}

class DerivedForFactories {
  const DerivedForFactories._();

  /// Starts building a query for [$DerivedForFactory].
  ///
  /// {@macro ormed.query}
  static Query<$DerivedForFactory> query([String? connection]) =>
      Model.query<$DerivedForFactory>(connection: connection);

  static Future<$DerivedForFactory?> find(Object id, {String? connection}) =>
      Model.find<$DerivedForFactory>(id, connection: connection);

  static Future<$DerivedForFactory> findOrFail(
    Object id, {
    String? connection,
  }) => Model.findOrFail<$DerivedForFactory>(id, connection: connection);

  static Future<List<$DerivedForFactory>> all({String? connection}) =>
      Model.all<$DerivedForFactory>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<$DerivedForFactory>(connection: connection);

  static Future<bool> anyExist({String? connection}) =>
      Model.anyExist<$DerivedForFactory>(connection: connection);

  static Query<$DerivedForFactory> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) => Model.where<$DerivedForFactory>(
    column,
    operator,
    value,
    connection: connection,
  );

  static Query<$DerivedForFactory> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) =>
      Model.whereIn<$DerivedForFactory>(column, values, connection: connection);

  static Query<$DerivedForFactory> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<$DerivedForFactory>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<$DerivedForFactory> limit(int count, {String? connection}) =>
      Model.limit<$DerivedForFactory>(count, connection: connection);

  /// Creates a [Repository] for [$DerivedForFactory].
  ///
  /// {@macro ormed.repository}
  static Repository<$DerivedForFactory> repo([String? connection]) =>
      Model.repository<$DerivedForFactory>(connection: connection);
}

class DerivedForFactoryModelFactory {
  const DerivedForFactoryModelFactory._();

  static ModelDefinition<$DerivedForFactory> get definition =>
      _$DerivedForFactoryDefinition;

  static ModelCodec<$DerivedForFactory> get codec => definition.codec;

  static DerivedForFactory fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    DerivedForFactory model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model.toTracked(), registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<DerivedForFactory> withConnection(
    QueryContext context,
  ) => ModelFactoryConnection<DerivedForFactory>(
    definition: definition,
    context: context,
  );

  static ModelFactoryBuilder<DerivedForFactory> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<DerivedForFactory>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$DerivedForFactoryCodec extends ModelCodec<$DerivedForFactory> {
  const _$DerivedForFactoryCodec();
  @override
  Map<String, Object?> encode(
    $DerivedForFactory model,
    ValueCodecRegistry registry,
  ) {
    return <String, Object?>{
      'layer_two_flag': registry.encodeField(
        _$DerivedForFactoryLayerTwoFlagField,
        model.layerTwoFlag,
      ),
      'layer_one_notes': registry.encodeField(
        _$DerivedForFactoryLayerOneNotesField,
        model.layerOneNotes,
      ),
      'id': registry.encodeField(_$DerivedForFactoryIdField, model.id),
      'base_name': registry.encodeField(
        _$DerivedForFactoryBaseNameField,
        model.baseName,
      ),
    };
  }

  @override
  $DerivedForFactory decode(
    Map<String, Object?> data,
    ValueCodecRegistry registry,
  ) {
    final bool? derivedForFactoryLayerTwoFlagValue = registry
        .decodeField<bool?>(
          _$DerivedForFactoryLayerTwoFlagField,
          data['layer_two_flag'],
        );
    final Map<String, Object?>? derivedForFactoryLayerOneNotesValue = registry
        .decodeField<Map<String, Object?>?>(
          _$DerivedForFactoryLayerOneNotesField,
          data['layer_one_notes'],
        );
    final int derivedForFactoryIdValue =
        registry.decodeField<int>(_$DerivedForFactoryIdField, data['id']) ?? 0;
    final String? derivedForFactoryBaseNameValue = registry
        .decodeField<String?>(
          _$DerivedForFactoryBaseNameField,
          data['base_name'],
        );
    final model = $DerivedForFactory(
      id: derivedForFactoryIdValue,
      baseName: derivedForFactoryBaseNameValue,
      layerOneNotes: derivedForFactoryLayerOneNotesValue,
      layerTwoFlag: derivedForFactoryLayerTwoFlagValue,
    );
    model._attachOrmRuntimeMetadata({
      'layer_two_flag': derivedForFactoryLayerTwoFlagValue,
      'layer_one_notes': derivedForFactoryLayerOneNotesValue,
      'id': derivedForFactoryIdValue,
      'base_name': derivedForFactoryBaseNameValue,
    });
    return model;
  }
}

/// Insert DTO for [DerivedForFactory].
///
/// Auto-increment/DB-generated fields are omitted by default.
class DerivedForFactoryInsertDto implements InsertDto<$DerivedForFactory> {
  const DerivedForFactoryInsertDto({
    this.layerTwoFlag,
    this.layerOneNotes,
    this.baseName,
  });
  final bool? layerTwoFlag;
  final Map<String, Object?>? layerOneNotes;
  final String? baseName;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (layerTwoFlag != null) 'layer_two_flag': layerTwoFlag,
      if (layerOneNotes != null) 'layer_one_notes': layerOneNotes,
      if (baseName != null) 'base_name': baseName,
    };
  }

  static const _DerivedForFactoryInsertDtoCopyWithSentinel _copyWithSentinel =
      _DerivedForFactoryInsertDtoCopyWithSentinel();
  DerivedForFactoryInsertDto copyWith({
    Object? layerTwoFlag = _copyWithSentinel,
    Object? layerOneNotes = _copyWithSentinel,
    Object? baseName = _copyWithSentinel,
  }) {
    return DerivedForFactoryInsertDto(
      layerTwoFlag: identical(layerTwoFlag, _copyWithSentinel)
          ? this.layerTwoFlag
          : layerTwoFlag as bool?,
      layerOneNotes: identical(layerOneNotes, _copyWithSentinel)
          ? this.layerOneNotes
          : layerOneNotes as Map<String, Object?>?,
      baseName: identical(baseName, _copyWithSentinel)
          ? this.baseName
          : baseName as String?,
    );
  }
}

class _DerivedForFactoryInsertDtoCopyWithSentinel {
  const _DerivedForFactoryInsertDtoCopyWithSentinel();
}

/// Update DTO for [DerivedForFactory].
///
/// All fields are optional; only provided entries are used in SET clauses.
class DerivedForFactoryUpdateDto implements UpdateDto<$DerivedForFactory> {
  const DerivedForFactoryUpdateDto({
    this.layerTwoFlag,
    this.layerOneNotes,
    this.id,
    this.baseName,
  });
  final bool? layerTwoFlag;
  final Map<String, Object?>? layerOneNotes;
  final int? id;
  final String? baseName;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (layerTwoFlag != null) 'layer_two_flag': layerTwoFlag,
      if (layerOneNotes != null) 'layer_one_notes': layerOneNotes,
      if (id != null) 'id': id,
      if (baseName != null) 'base_name': baseName,
    };
  }

  static const _DerivedForFactoryUpdateDtoCopyWithSentinel _copyWithSentinel =
      _DerivedForFactoryUpdateDtoCopyWithSentinel();
  DerivedForFactoryUpdateDto copyWith({
    Object? layerTwoFlag = _copyWithSentinel,
    Object? layerOneNotes = _copyWithSentinel,
    Object? id = _copyWithSentinel,
    Object? baseName = _copyWithSentinel,
  }) {
    return DerivedForFactoryUpdateDto(
      layerTwoFlag: identical(layerTwoFlag, _copyWithSentinel)
          ? this.layerTwoFlag
          : layerTwoFlag as bool?,
      layerOneNotes: identical(layerOneNotes, _copyWithSentinel)
          ? this.layerOneNotes
          : layerOneNotes as Map<String, Object?>?,
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      baseName: identical(baseName, _copyWithSentinel)
          ? this.baseName
          : baseName as String?,
    );
  }
}

class _DerivedForFactoryUpdateDtoCopyWithSentinel {
  const _DerivedForFactoryUpdateDtoCopyWithSentinel();
}

/// Partial projection for [DerivedForFactory].
///
/// All fields are nullable; intended for subset SELECTs.
class DerivedForFactoryPartial implements PartialEntity<$DerivedForFactory> {
  const DerivedForFactoryPartial({
    this.layerTwoFlag,
    this.layerOneNotes,
    this.id,
    this.baseName,
  });

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory DerivedForFactoryPartial.fromRow(Map<String, Object?> row) {
    return DerivedForFactoryPartial(
      layerTwoFlag: row['layer_two_flag'] as bool?,
      layerOneNotes: row['layer_one_notes'] as Map<String, Object?>?,
      id: row['id'] as int?,
      baseName: row['base_name'] as String?,
    );
  }

  final bool? layerTwoFlag;
  final Map<String, Object?>? layerOneNotes;
  final int? id;
  final String? baseName;

  @override
  $DerivedForFactory toEntity() {
    // Basic required-field check: non-nullable fields must be present.
    final int? idValue = id;
    if (idValue == null) {
      throw StateError('Missing required field: id');
    }
    return $DerivedForFactory(
      layerTwoFlag: layerTwoFlag,
      layerOneNotes: layerOneNotes,
      id: idValue,
      baseName: baseName,
    );
  }

  @override
  Map<String, Object?> toMap() {
    return {
      if (layerTwoFlag != null) 'layer_two_flag': layerTwoFlag,
      if (layerOneNotes != null) 'layer_one_notes': layerOneNotes,
      if (id != null) 'id': id,
      if (baseName != null) 'base_name': baseName,
    };
  }

  static const _DerivedForFactoryPartialCopyWithSentinel _copyWithSentinel =
      _DerivedForFactoryPartialCopyWithSentinel();
  DerivedForFactoryPartial copyWith({
    Object? layerTwoFlag = _copyWithSentinel,
    Object? layerOneNotes = _copyWithSentinel,
    Object? id = _copyWithSentinel,
    Object? baseName = _copyWithSentinel,
  }) {
    return DerivedForFactoryPartial(
      layerTwoFlag: identical(layerTwoFlag, _copyWithSentinel)
          ? this.layerTwoFlag
          : layerTwoFlag as bool?,
      layerOneNotes: identical(layerOneNotes, _copyWithSentinel)
          ? this.layerOneNotes
          : layerOneNotes as Map<String, Object?>?,
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      baseName: identical(baseName, _copyWithSentinel)
          ? this.baseName
          : baseName as String?,
    );
  }
}

class _DerivedForFactoryPartialCopyWithSentinel {
  const _DerivedForFactoryPartialCopyWithSentinel();
}

/// Generated tracked model class for [DerivedForFactory].
///
/// This class extends the user-defined [DerivedForFactory] model and adds
/// attribute tracking, change detection, and relationship management.
/// Instances of this class are returned by queries and repositories.
///
/// **Do not instantiate this class directly.** Use queries, repositories,
/// or model factories to create tracked model instances.
class $DerivedForFactory extends DerivedForFactory
    with ModelAttributes
    implements OrmEntity {
  /// Internal constructor for [$DerivedForFactory].
  $DerivedForFactory({
    int id = 0,
    String? baseName,
    Map<String, Object?>? layerOneNotes,
    bool? layerTwoFlag,
  }) : super.new(
         id: id,
         baseName: baseName,
         layerOneNotes: layerOneNotes,
         layerTwoFlag: layerTwoFlag,
       ) {
    _attachOrmRuntimeMetadata({
      'layer_two_flag': layerTwoFlag,
      'layer_one_notes': layerOneNotes,
      'id': id,
      'base_name': baseName,
    });
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $DerivedForFactory.fromModel(DerivedForFactory model) {
    return $DerivedForFactory(
      layerTwoFlag: model.layerTwoFlag,
      layerOneNotes: model.layerOneNotes,
      id: model.id,
      baseName: model.baseName,
    );
  }

  $DerivedForFactory copyWith({
    bool? layerTwoFlag,
    Map<String, Object?>? layerOneNotes,
    int? id,
    String? baseName,
  }) {
    return $DerivedForFactory(
      layerTwoFlag: layerTwoFlag ?? this.layerTwoFlag,
      layerOneNotes: layerOneNotes ?? this.layerOneNotes,
      id: id ?? this.id,
      baseName: baseName ?? this.baseName,
    );
  }

  /// Tracked getter for [layerTwoFlag].
  @override
  bool? get layerTwoFlag =>
      getAttribute<bool?>('layer_two_flag') ?? super.layerTwoFlag;

  /// Tracked setter for [layerTwoFlag].
  set layerTwoFlag(bool? value) => setAttribute('layer_two_flag', value);

  /// Tracked getter for [layerOneNotes].
  @override
  Map<String, Object?>? get layerOneNotes =>
      getAttribute<Map<String, Object?>?>('layer_one_notes') ??
      super.layerOneNotes;

  /// Tracked setter for [layerOneNotes].
  set layerOneNotes(Map<String, Object?>? value) =>
      setAttribute('layer_one_notes', value);

  /// Tracked getter for [id].
  @override
  int get id => getAttribute<int>('id') ?? super.id;

  /// Tracked setter for [id].
  set id(int value) => setAttribute('id', value);

  /// Tracked getter for [baseName].
  @override
  String? get baseName => getAttribute<String?>('base_name') ?? super.baseName;

  /// Tracked setter for [baseName].
  set baseName(String? value) => setAttribute('base_name', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$DerivedForFactoryDefinition);
  }
}

extension DerivedForFactoryOrmExtension on DerivedForFactory {
  /// The Type of the generated ORM-managed model class.
  /// Use this when you need to specify the tracked model type explicitly,
  /// for example in generic type parameters.
  static Type get trackedType => $DerivedForFactory;

  /// Converts this immutable model to a tracked ORM-managed model.
  /// The tracked model supports attribute tracking, change detection,
  /// and persistence operations like save() and touch().
  $DerivedForFactory toTracked() {
    return $DerivedForFactory.fromModel(this);
  }
}

extension DerivedForFactoryPredicateFields
    on PredicateBuilder<DerivedForFactory> {
  PredicateField<DerivedForFactory, bool?> get layerTwoFlag =>
      PredicateField<DerivedForFactory, bool?>(this, 'layerTwoFlag');
  PredicateField<DerivedForFactory, Map<String, Object?>?> get layerOneNotes =>
      PredicateField<DerivedForFactory, Map<String, Object?>?>(
        this,
        'layerOneNotes',
      );
  PredicateField<DerivedForFactory, int> get id =>
      PredicateField<DerivedForFactory, int>(this, 'id');
  PredicateField<DerivedForFactory, String?> get baseName =>
      PredicateField<DerivedForFactory, String?>(this, 'baseName');
}

void registerDerivedForFactoryEventHandlers(EventBus bus) {
  // No event handlers registered for DerivedForFactory.
}
