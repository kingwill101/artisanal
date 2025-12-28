// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'mutation_target.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$MutationTargetIdField = FieldDefinition(
  name: 'id',
  columnName: '_id',
  dartType: 'String',
  resolvedType: 'String',
  isPrimaryKey: true,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$MutationTargetNameField = FieldDefinition(
  name: 'name',
  columnName: 'name',
  dartType: 'String',
  resolvedType: 'String?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$MutationTargetActiveField = FieldDefinition(
  name: 'active',
  columnName: 'active',
  dartType: 'bool',
  resolvedType: 'bool?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$MutationTargetCategoryField = FieldDefinition(
  name: 'category',
  columnName: 'category',
  dartType: 'String',
  resolvedType: 'String?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

Map<String, Object?> _encodeMutationTargetUntracked(
  Object model,
  ValueCodecRegistry registry,
) {
  final m = model as MutationTarget;
  return <String, Object?>{
    '_id': registry.encodeField(_$MutationTargetIdField, m.id),
    'name': registry.encodeField(_$MutationTargetNameField, m.name),
    'active': registry.encodeField(_$MutationTargetActiveField, m.active),
    'category': registry.encodeField(_$MutationTargetCategoryField, m.category),
  };
}

final ModelDefinition<$MutationTarget> _$MutationTargetDefinition =
    ModelDefinition(
      modelName: 'MutationTarget',
      tableName: 'mutation_targets',
      fields: const [
        _$MutationTargetIdField,
        _$MutationTargetNameField,
        _$MutationTargetActiveField,
        _$MutationTargetCategoryField,
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
      untrackedToMap: _encodeMutationTargetUntracked,
      codec: _$MutationTargetCodec(),
    );

// ignore: unused_element
final mutationtargetModelDefinitionRegistration =
    ModelFactoryRegistry.register<$MutationTarget>(_$MutationTargetDefinition);

extension MutationTargetOrmDefinition on MutationTarget {
  static ModelDefinition<$MutationTarget> get definition =>
      _$MutationTargetDefinition;
}

class MutationTargets {
  const MutationTargets._();

  /// Starts building a query for [$MutationTarget].
  ///
  /// {@macro ormed.query}
  static Query<$MutationTarget> query([String? connection]) =>
      Model.query<$MutationTarget>(connection: connection);

  static Future<$MutationTarget?> find(Object id, {String? connection}) =>
      Model.find<$MutationTarget>(id, connection: connection);

  static Future<$MutationTarget> findOrFail(Object id, {String? connection}) =>
      Model.findOrFail<$MutationTarget>(id, connection: connection);

  static Future<List<$MutationTarget>> all({String? connection}) =>
      Model.all<$MutationTarget>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<$MutationTarget>(connection: connection);

  static Future<bool> anyExist({String? connection}) =>
      Model.anyExist<$MutationTarget>(connection: connection);

  static Query<$MutationTarget> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) => Model.where<$MutationTarget>(
    column,
    operator,
    value,
    connection: connection,
  );

  static Query<$MutationTarget> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<$MutationTarget>(column, values, connection: connection);

  static Query<$MutationTarget> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<$MutationTarget>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<$MutationTarget> limit(int count, {String? connection}) =>
      Model.limit<$MutationTarget>(count, connection: connection);

  /// Creates a [Repository] for [$MutationTarget].
  ///
  /// {@macro ormed.repository}
  static Repository<$MutationTarget> repo([String? connection]) =>
      Model.repository<$MutationTarget>(connection: connection);

  /// Builds a tracked model from a column/value map.
  static $MutationTarget fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$MutationTargetDefinition.fromMap(data, registry: registry);

  /// Converts a tracked model to a column/value map.
  static Map<String, Object?> toMap(
    $MutationTarget model, {
    ValueCodecRegistry? registry,
  }) => _$MutationTargetDefinition.toMap(model, registry: registry);
}

class MutationTargetModelFactory {
  const MutationTargetModelFactory._();

  static ModelDefinition<$MutationTarget> get definition =>
      _$MutationTargetDefinition;

  static ModelCodec<$MutationTarget> get codec => definition.codec;

  static MutationTarget fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    MutationTarget model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model.toTracked(), registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<MutationTarget> withConnection(
    QueryContext context,
  ) => ModelFactoryConnection<MutationTarget>(
    definition: definition,
    context: context,
  );

  static ModelFactoryBuilder<MutationTarget> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<MutationTarget>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$MutationTargetCodec extends ModelCodec<$MutationTarget> {
  const _$MutationTargetCodec();
  @override
  Map<String, Object?> encode(
    $MutationTarget model,
    ValueCodecRegistry registry,
  ) {
    return <String, Object?>{
      '_id': registry.encodeField(_$MutationTargetIdField, model.id),
      'name': registry.encodeField(_$MutationTargetNameField, model.name),
      'active': registry.encodeField(_$MutationTargetActiveField, model.active),
      'category': registry.encodeField(
        _$MutationTargetCategoryField,
        model.category,
      ),
    };
  }

  @override
  $MutationTarget decode(
    Map<String, Object?> data,
    ValueCodecRegistry registry,
  ) {
    final String mutationTargetIdValue =
        registry.decodeField<String>(_$MutationTargetIdField, data['_id']) ??
        (throw StateError('Field id on MutationTarget cannot be null.'));
    final String? mutationTargetNameValue = registry.decodeField<String?>(
      _$MutationTargetNameField,
      data['name'],
    );
    final bool? mutationTargetActiveValue = registry.decodeField<bool?>(
      _$MutationTargetActiveField,
      data['active'],
    );
    final String? mutationTargetCategoryValue = registry.decodeField<String?>(
      _$MutationTargetCategoryField,
      data['category'],
    );
    final model = $MutationTarget(
      id: mutationTargetIdValue,
      name: mutationTargetNameValue,
      active: mutationTargetActiveValue,
      category: mutationTargetCategoryValue,
    );
    model._attachOrmRuntimeMetadata({
      '_id': mutationTargetIdValue,
      'name': mutationTargetNameValue,
      'active': mutationTargetActiveValue,
      'category': mutationTargetCategoryValue,
    });
    return model;
  }
}

/// Insert DTO for [MutationTarget].
///
/// Auto-increment/DB-generated fields are omitted by default.
class MutationTargetInsertDto implements InsertDto<$MutationTarget> {
  const MutationTargetInsertDto({
    this.id,
    this.name,
    this.active,
    this.category,
  });
  final String? id;
  final String? name;
  final bool? active;
  final String? category;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) '_id': id,
      if (name != null) 'name': name,
      if (active != null) 'active': active,
      if (category != null) 'category': category,
    };
  }

  static const _MutationTargetInsertDtoCopyWithSentinel _copyWithSentinel =
      _MutationTargetInsertDtoCopyWithSentinel();
  MutationTargetInsertDto copyWith({
    Object? id = _copyWithSentinel,
    Object? name = _copyWithSentinel,
    Object? active = _copyWithSentinel,
    Object? category = _copyWithSentinel,
  }) {
    return MutationTargetInsertDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as String?,
      name: identical(name, _copyWithSentinel) ? this.name : name as String?,
      active: identical(active, _copyWithSentinel)
          ? this.active
          : active as bool?,
      category: identical(category, _copyWithSentinel)
          ? this.category
          : category as String?,
    );
  }
}

class _MutationTargetInsertDtoCopyWithSentinel {
  const _MutationTargetInsertDtoCopyWithSentinel();
}

/// Update DTO for [MutationTarget].
///
/// All fields are optional; only provided entries are used in SET clauses.
class MutationTargetUpdateDto implements UpdateDto<$MutationTarget> {
  const MutationTargetUpdateDto({
    this.id,
    this.name,
    this.active,
    this.category,
  });
  final String? id;
  final String? name;
  final bool? active;
  final String? category;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) '_id': id,
      if (name != null) 'name': name,
      if (active != null) 'active': active,
      if (category != null) 'category': category,
    };
  }

  static const _MutationTargetUpdateDtoCopyWithSentinel _copyWithSentinel =
      _MutationTargetUpdateDtoCopyWithSentinel();
  MutationTargetUpdateDto copyWith({
    Object? id = _copyWithSentinel,
    Object? name = _copyWithSentinel,
    Object? active = _copyWithSentinel,
    Object? category = _copyWithSentinel,
  }) {
    return MutationTargetUpdateDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as String?,
      name: identical(name, _copyWithSentinel) ? this.name : name as String?,
      active: identical(active, _copyWithSentinel)
          ? this.active
          : active as bool?,
      category: identical(category, _copyWithSentinel)
          ? this.category
          : category as String?,
    );
  }
}

class _MutationTargetUpdateDtoCopyWithSentinel {
  const _MutationTargetUpdateDtoCopyWithSentinel();
}

/// Partial projection for [MutationTarget].
///
/// All fields are nullable; intended for subset SELECTs.
class MutationTargetPartial implements PartialEntity<$MutationTarget> {
  const MutationTargetPartial({this.id, this.name, this.active, this.category});

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory MutationTargetPartial.fromRow(Map<String, Object?> row) {
    return MutationTargetPartial(
      id: row['_id'] as String?,
      name: row['name'] as String?,
      active: row['active'] as bool?,
      category: row['category'] as String?,
    );
  }

  final String? id;
  final String? name;
  final bool? active;
  final String? category;

  @override
  $MutationTarget toEntity() {
    // Basic required-field check: non-nullable fields must be present.
    final String? idValue = id;
    if (idValue == null) {
      throw StateError('Missing required field: id');
    }
    return $MutationTarget(
      id: idValue,
      name: name,
      active: active,
      category: category,
    );
  }

  @override
  Map<String, Object?> toMap() {
    return {
      if (id != null) '_id': id,
      if (name != null) 'name': name,
      if (active != null) 'active': active,
      if (category != null) 'category': category,
    };
  }

  static const _MutationTargetPartialCopyWithSentinel _copyWithSentinel =
      _MutationTargetPartialCopyWithSentinel();
  MutationTargetPartial copyWith({
    Object? id = _copyWithSentinel,
    Object? name = _copyWithSentinel,
    Object? active = _copyWithSentinel,
    Object? category = _copyWithSentinel,
  }) {
    return MutationTargetPartial(
      id: identical(id, _copyWithSentinel) ? this.id : id as String?,
      name: identical(name, _copyWithSentinel) ? this.name : name as String?,
      active: identical(active, _copyWithSentinel)
          ? this.active
          : active as bool?,
      category: identical(category, _copyWithSentinel)
          ? this.category
          : category as String?,
    );
  }
}

class _MutationTargetPartialCopyWithSentinel {
  const _MutationTargetPartialCopyWithSentinel();
}

/// Generated tracked model class for [MutationTarget].
///
/// This class extends the user-defined [MutationTarget] model and adds
/// attribute tracking, change detection, and relationship management.
/// Instances of this class are returned by queries and repositories.
///
/// **Do not instantiate this class directly.** Use queries, repositories,
/// or model factories to create tracked model instances.
class $MutationTarget extends MutationTarget
    with ModelAttributes
    implements OrmEntity {
  /// Internal constructor for [$MutationTarget].
  $MutationTarget({
    required String id,
    String? name,
    bool? active,
    String? category,
  }) : super.new(id: id, name: name, active: active, category: category) {
    _attachOrmRuntimeMetadata({
      '_id': id,
      'name': name,
      'active': active,
      'category': category,
    });
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $MutationTarget.fromModel(MutationTarget model) {
    return $MutationTarget(
      id: model.id,
      name: model.name,
      active: model.active,
      category: model.category,
    );
  }

  $MutationTarget copyWith({
    String? id,
    String? name,
    bool? active,
    String? category,
  }) {
    return $MutationTarget(
      id: id ?? this.id,
      name: name ?? this.name,
      active: active ?? this.active,
      category: category ?? this.category,
    );
  }

  /// Builds a tracked model from a column/value map.
  static $MutationTarget fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$MutationTargetDefinition.fromMap(data, registry: registry);

  /// Converts this tracked model to a column/value map.
  Map<String, Object?> toMap({ValueCodecRegistry? registry}) =>
      _$MutationTargetDefinition.toMap(this, registry: registry);

  /// Tracked getter for [id].
  @override
  String get id => getAttribute<String>('_id') ?? super.id;

  /// Tracked setter for [id].
  set id(String value) => setAttribute('_id', value);

  /// Tracked getter for [name].
  @override
  String? get name => getAttribute<String?>('name') ?? super.name;

  /// Tracked setter for [name].
  set name(String? value) => setAttribute('name', value);

  /// Tracked getter for [active].
  @override
  bool? get active => getAttribute<bool?>('active') ?? super.active;

  /// Tracked setter for [active].
  set active(bool? value) => setAttribute('active', value);

  /// Tracked getter for [category].
  @override
  String? get category => getAttribute<String?>('category') ?? super.category;

  /// Tracked setter for [category].
  set category(String? value) => setAttribute('category', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$MutationTargetDefinition);
  }
}

class _MutationTargetCopyWithSentinel {
  const _MutationTargetCopyWithSentinel();
}

extension MutationTargetOrmExtension on MutationTarget {
  static const _MutationTargetCopyWithSentinel _copyWithSentinel =
      _MutationTargetCopyWithSentinel();
  MutationTarget copyWith({
    Object? id = _copyWithSentinel,
    Object? name = _copyWithSentinel,
    Object? active = _copyWithSentinel,
    Object? category = _copyWithSentinel,
  }) {
    return MutationTarget.new(
      id: identical(id, _copyWithSentinel) ? this.id : id as String,
      name: identical(name, _copyWithSentinel) ? this.name : name as String?,
      active: identical(active, _copyWithSentinel)
          ? this.active
          : active as bool?,
      category: identical(category, _copyWithSentinel)
          ? this.category
          : category as String?,
    );
  }

  /// Converts this model to a column/value map.
  Map<String, Object?> toMap({ValueCodecRegistry? registry}) =>
      _$MutationTargetDefinition.toMap(this, registry: registry);

  /// Builds a model from a column/value map.
  static MutationTarget fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$MutationTargetDefinition.fromMap(data, registry: registry);

  /// The Type of the generated ORM-managed model class.
  /// Use this when you need to specify the tracked model type explicitly,
  /// for example in generic type parameters.
  static Type get trackedType => $MutationTarget;

  /// Converts this immutable model to a tracked ORM-managed model.
  /// The tracked model supports attribute tracking, change detection,
  /// and persistence operations like save() and touch().
  $MutationTarget toTracked() {
    return $MutationTarget.fromModel(this);
  }
}

extension MutationTargetPredicateFields on PredicateBuilder<MutationTarget> {
  PredicateField<MutationTarget, String> get id =>
      PredicateField<MutationTarget, String>(this, 'id');
  PredicateField<MutationTarget, String?> get name =>
      PredicateField<MutationTarget, String?>(this, 'name');
  PredicateField<MutationTarget, bool?> get active =>
      PredicateField<MutationTarget, bool?>(this, 'active');
  PredicateField<MutationTarget, String?> get category =>
      PredicateField<MutationTarget, String?>(this, 'category');
}

void registerMutationTargetEventHandlers(EventBus bus) {
  // No event handlers registered for MutationTarget.
}
