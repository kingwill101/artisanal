// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'predicate_collision.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$PredicateCollisionIdField = FieldDefinition(
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

const FieldDefinition _$PredicateCollisionWhereField = FieldDefinition(
  name: 'where',
  columnName: 'where',
  dartType: 'String',
  resolvedType: 'String',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$PredicateCollisionOrWhereField = FieldDefinition(
  name: 'orWhere',
  columnName: 'or_where',
  dartType: 'String',
  resolvedType: 'String',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

Map<String, Object?> _encodePredicateCollisionUntracked(
  Object model,
  ValueCodecRegistry registry,
) {
  final m = model as PredicateCollision;
  return <String, Object?>{
    'id': registry.encodeField(_$PredicateCollisionIdField, m.id),
    'where': registry.encodeField(_$PredicateCollisionWhereField, m.where),
    'or_where': registry.encodeField(
      _$PredicateCollisionOrWhereField,
      m.orWhere,
    ),
  };
}

final ModelDefinition<$PredicateCollision> _$PredicateCollisionDefinition =
    ModelDefinition(
      modelName: 'PredicateCollision',
      tableName: 'predicate_collisions',
      fields: const [
        _$PredicateCollisionIdField,
        _$PredicateCollisionWhereField,
        _$PredicateCollisionOrWhereField,
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
      untrackedToMap: _encodePredicateCollisionUntracked,
      codec: _$PredicateCollisionCodec(),
    );

// ignore: unused_element
final predicatecollisionModelDefinitionRegistration =
    ModelFactoryRegistry.register<$PredicateCollision>(
      _$PredicateCollisionDefinition,
    );

extension PredicateCollisionOrmDefinition on PredicateCollision {
  static ModelDefinition<$PredicateCollision> get definition =>
      _$PredicateCollisionDefinition;
}

class PredicateCollisions {
  const PredicateCollisions._();

  /// Starts building a query for [$PredicateCollision].
  ///
  /// {@macro ormed.query}
  static Query<$PredicateCollision> query([String? connection]) =>
      Model.query<$PredicateCollision>(connection: connection);

  static Future<$PredicateCollision?> find(Object id, {String? connection}) =>
      Model.find<$PredicateCollision>(id, connection: connection);

  static Future<$PredicateCollision> findOrFail(
    Object id, {
    String? connection,
  }) => Model.findOrFail<$PredicateCollision>(id, connection: connection);

  static Future<List<$PredicateCollision>> all({String? connection}) =>
      Model.all<$PredicateCollision>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<$PredicateCollision>(connection: connection);

  static Future<bool> anyExist({String? connection}) =>
      Model.anyExist<$PredicateCollision>(connection: connection);

  static Query<$PredicateCollision> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) => Model.where<$PredicateCollision>(
    column,
    operator,
    value,
    connection: connection,
  );

  static Query<$PredicateCollision> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<$PredicateCollision>(
    column,
    values,
    connection: connection,
  );

  static Query<$PredicateCollision> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<$PredicateCollision>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<$PredicateCollision> limit(int count, {String? connection}) =>
      Model.limit<$PredicateCollision>(count, connection: connection);

  /// Creates a [Repository] for [$PredicateCollision].
  ///
  /// {@macro ormed.repository}
  static Repository<$PredicateCollision> repo([String? connection]) =>
      Model.repository<$PredicateCollision>(connection: connection);

  /// Builds a tracked model from a column/value map.
  static $PredicateCollision fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$PredicateCollisionDefinition.fromMap(data, registry: registry);

  /// Converts a tracked model to a column/value map.
  static Map<String, Object?> toMap(
    $PredicateCollision model, {
    ValueCodecRegistry? registry,
  }) => _$PredicateCollisionDefinition.toMap(model, registry: registry);
}

class PredicateCollisionModelFactory {
  const PredicateCollisionModelFactory._();

  static ModelDefinition<$PredicateCollision> get definition =>
      _$PredicateCollisionDefinition;

  static ModelCodec<$PredicateCollision> get codec => definition.codec;

  static PredicateCollision fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    PredicateCollision model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model.toTracked(), registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<PredicateCollision> withConnection(
    QueryContext context,
  ) => ModelFactoryConnection<PredicateCollision>(
    definition: definition,
    context: context,
  );

  static ModelFactoryBuilder<PredicateCollision> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<PredicateCollision>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$PredicateCollisionCodec extends ModelCodec<$PredicateCollision> {
  const _$PredicateCollisionCodec();
  @override
  Map<String, Object?> encode(
    $PredicateCollision model,
    ValueCodecRegistry registry,
  ) {
    return <String, Object?>{
      'id': registry.encodeField(_$PredicateCollisionIdField, model.id),
      'where': registry.encodeField(
        _$PredicateCollisionWhereField,
        model.where,
      ),
      'or_where': registry.encodeField(
        _$PredicateCollisionOrWhereField,
        model.orWhere,
      ),
    };
  }

  @override
  $PredicateCollision decode(
    Map<String, Object?> data,
    ValueCodecRegistry registry,
  ) {
    final int predicateCollisionIdValue =
        registry.decodeField<int>(_$PredicateCollisionIdField, data['id']) ?? 0;
    final String predicateCollisionWhereValue =
        registry.decodeField<String>(
          _$PredicateCollisionWhereField,
          data['where'],
        ) ??
        (throw StateError('Field where on PredicateCollision cannot be null.'));
    final String predicateCollisionOrWhereValue =
        registry.decodeField<String>(
          _$PredicateCollisionOrWhereField,
          data['or_where'],
        ) ??
        (throw StateError(
          'Field orWhere on PredicateCollision cannot be null.',
        ));
    final model = $PredicateCollision(
      id: predicateCollisionIdValue,
      where: predicateCollisionWhereValue,
      orWhere: predicateCollisionOrWhereValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': predicateCollisionIdValue,
      'where': predicateCollisionWhereValue,
      'or_where': predicateCollisionOrWhereValue,
    });
    return model;
  }
}

/// Insert DTO for [PredicateCollision].
///
/// Auto-increment/DB-generated fields are omitted by default.
class PredicateCollisionInsertDto implements InsertDto<$PredicateCollision> {
  const PredicateCollisionInsertDto({this.where, this.orWhere});
  final String? where;
  final String? orWhere;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (where != null) 'where': where,
      if (orWhere != null) 'or_where': orWhere,
    };
  }

  static const _PredicateCollisionInsertDtoCopyWithSentinel _copyWithSentinel =
      _PredicateCollisionInsertDtoCopyWithSentinel();
  PredicateCollisionInsertDto copyWith({
    Object? where = _copyWithSentinel,
    Object? orWhere = _copyWithSentinel,
  }) {
    return PredicateCollisionInsertDto(
      where: identical(where, _copyWithSentinel)
          ? this.where
          : where as String?,
      orWhere: identical(orWhere, _copyWithSentinel)
          ? this.orWhere
          : orWhere as String?,
    );
  }
}

class _PredicateCollisionInsertDtoCopyWithSentinel {
  const _PredicateCollisionInsertDtoCopyWithSentinel();
}

/// Update DTO for [PredicateCollision].
///
/// All fields are optional; only provided entries are used in SET clauses.
class PredicateCollisionUpdateDto implements UpdateDto<$PredicateCollision> {
  const PredicateCollisionUpdateDto({this.id, this.where, this.orWhere});
  final int? id;
  final String? where;
  final String? orWhere;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (where != null) 'where': where,
      if (orWhere != null) 'or_where': orWhere,
    };
  }

  static const _PredicateCollisionUpdateDtoCopyWithSentinel _copyWithSentinel =
      _PredicateCollisionUpdateDtoCopyWithSentinel();
  PredicateCollisionUpdateDto copyWith({
    Object? id = _copyWithSentinel,
    Object? where = _copyWithSentinel,
    Object? orWhere = _copyWithSentinel,
  }) {
    return PredicateCollisionUpdateDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      where: identical(where, _copyWithSentinel)
          ? this.where
          : where as String?,
      orWhere: identical(orWhere, _copyWithSentinel)
          ? this.orWhere
          : orWhere as String?,
    );
  }
}

class _PredicateCollisionUpdateDtoCopyWithSentinel {
  const _PredicateCollisionUpdateDtoCopyWithSentinel();
}

/// Partial projection for [PredicateCollision].
///
/// All fields are nullable; intended for subset SELECTs.
class PredicateCollisionPartial implements PartialEntity<$PredicateCollision> {
  const PredicateCollisionPartial({this.id, this.where, this.orWhere});

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory PredicateCollisionPartial.fromRow(Map<String, Object?> row) {
    return PredicateCollisionPartial(
      id: row['id'] as int?,
      where: row['where'] as String?,
      orWhere: row['or_where'] as String?,
    );
  }

  final int? id;
  final String? where;
  final String? orWhere;

  @override
  $PredicateCollision toEntity() {
    // Basic required-field check: non-nullable fields must be present.
    final int? idValue = id;
    if (idValue == null) {
      throw StateError('Missing required field: id');
    }
    final String? whereValue = where;
    if (whereValue == null) {
      throw StateError('Missing required field: where');
    }
    final String? orWhereValue = orWhere;
    if (orWhereValue == null) {
      throw StateError('Missing required field: orWhere');
    }
    return $PredicateCollision(
      id: idValue,
      where: whereValue,
      orWhere: orWhereValue,
    );
  }

  @override
  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      if (where != null) 'where': where,
      if (orWhere != null) 'or_where': orWhere,
    };
  }

  static const _PredicateCollisionPartialCopyWithSentinel _copyWithSentinel =
      _PredicateCollisionPartialCopyWithSentinel();
  PredicateCollisionPartial copyWith({
    Object? id = _copyWithSentinel,
    Object? where = _copyWithSentinel,
    Object? orWhere = _copyWithSentinel,
  }) {
    return PredicateCollisionPartial(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      where: identical(where, _copyWithSentinel)
          ? this.where
          : where as String?,
      orWhere: identical(orWhere, _copyWithSentinel)
          ? this.orWhere
          : orWhere as String?,
    );
  }
}

class _PredicateCollisionPartialCopyWithSentinel {
  const _PredicateCollisionPartialCopyWithSentinel();
}

/// Generated tracked model class for [PredicateCollision].
///
/// This class extends the user-defined [PredicateCollision] model and adds
/// attribute tracking, change detection, and relationship management.
/// Instances of this class are returned by queries and repositories.
///
/// **Do not instantiate this class directly.** Use queries, repositories,
/// or model factories to create tracked model instances.
class $PredicateCollision extends PredicateCollision
    with ModelAttributes
    implements OrmEntity {
  /// Internal constructor for [$PredicateCollision].
  $PredicateCollision({
    int id = 0,
    required String where,
    required String orWhere,
  }) : super.new(id: id, where: where, orWhere: orWhere) {
    _attachOrmRuntimeMetadata({'id': id, 'where': where, 'or_where': orWhere});
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $PredicateCollision.fromModel(PredicateCollision model) {
    return $PredicateCollision(
      id: model.id,
      where: model.where,
      orWhere: model.orWhere,
    );
  }

  $PredicateCollision copyWith({int? id, String? where, String? orWhere}) {
    return $PredicateCollision(
      id: id ?? this.id,
      where: where ?? this.where,
      orWhere: orWhere ?? this.orWhere,
    );
  }

  /// Builds a tracked model from a column/value map.
  static $PredicateCollision fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$PredicateCollisionDefinition.fromMap(data, registry: registry);

  /// Converts this tracked model to a column/value map.
  Map<String, Object?> toMap({ValueCodecRegistry? registry}) =>
      _$PredicateCollisionDefinition.toMap(this, registry: registry);

  /// Tracked getter for [id].
  @override
  int get id => getAttribute<int>('id') ?? super.id;

  /// Tracked setter for [id].
  set id(int value) => setAttribute('id', value);

  /// Tracked getter for [where].
  @override
  String get where => getAttribute<String>('where') ?? super.where;

  /// Tracked setter for [where].
  set where(String value) => setAttribute('where', value);

  /// Tracked getter for [orWhere].
  @override
  String get orWhere => getAttribute<String>('or_where') ?? super.orWhere;

  /// Tracked setter for [orWhere].
  set orWhere(String value) => setAttribute('or_where', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$PredicateCollisionDefinition);
  }
}

class _PredicateCollisionCopyWithSentinel {
  const _PredicateCollisionCopyWithSentinel();
}

extension PredicateCollisionOrmExtension on PredicateCollision {
  static const _PredicateCollisionCopyWithSentinel _copyWithSentinel =
      _PredicateCollisionCopyWithSentinel();
  PredicateCollision copyWith({
    Object? id = _copyWithSentinel,
    Object? where = _copyWithSentinel,
    Object? orWhere = _copyWithSentinel,
  }) {
    return PredicateCollision(
      id: identical(id, _copyWithSentinel) ? this.id : id as int,
      where: identical(where, _copyWithSentinel) ? this.where : where as String,
      orWhere: identical(orWhere, _copyWithSentinel)
          ? this.orWhere
          : orWhere as String,
    );
  }

  /// Converts this model to a column/value map.
  Map<String, Object?> toMap({ValueCodecRegistry? registry}) =>
      _$PredicateCollisionDefinition.toMap(this, registry: registry);

  /// Builds a model from a column/value map.
  static PredicateCollision fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$PredicateCollisionDefinition.fromMap(data, registry: registry);

  /// The Type of the generated ORM-managed model class.
  /// Use this when you need to specify the tracked model type explicitly,
  /// for example in generic type parameters.
  static Type get trackedType => $PredicateCollision;

  /// Converts this immutable model to a tracked ORM-managed model.
  /// The tracked model supports attribute tracking, change detection,
  /// and persistence operations like save() and touch().
  $PredicateCollision toTracked() {
    return $PredicateCollision.fromModel(this);
  }
}

extension PredicateCollisionPredicateFields
    on PredicateBuilder<PredicateCollision> {
  PredicateField<PredicateCollision, int> get id =>
      PredicateField<PredicateCollision, int>(this, 'id');
}

void registerPredicateCollisionEventHandlers(EventBus bus) {
  // No event handlers registered for PredicateCollision.
}
