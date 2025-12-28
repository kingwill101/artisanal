// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'no_factory.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$NoFactoryIdField = FieldDefinition(
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

const FieldDefinition _$NoFactoryDeletedAtField = FieldDefinition(
  name: 'deletedAt',
  columnName: 'deleted_at',
  dartType: 'DateTime',
  resolvedType: 'DateTime?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

Map<String, Object?> _encodeNoFactoryUntracked(
  Object model,
  ValueCodecRegistry registry,
) {
  final m = model as NoFactory;
  return <String, Object?>{
    'id': registry.encodeField(_$NoFactoryIdField, m.id),
  };
}

final ModelDefinition<$NoFactory> _$NoFactoryDefinition = ModelDefinition(
  modelName: 'NoFactory',
  tableName: 'active_users',
  fields: const [_$NoFactoryIdField, _$NoFactoryDeletedAtField],
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
    connection: 'analytics',
    softDeletes: true,
    softDeleteColumn: 'deleted_at',
  ),
  untrackedToMap: _encodeNoFactoryUntracked,
  codec: _$NoFactoryCodec(),
);

extension NoFactoryOrmDefinition on NoFactory {
  static ModelDefinition<$NoFactory> get definition => _$NoFactoryDefinition;
}

class NoFactories {
  const NoFactories._();

  /// Starts building a query for [$NoFactory].
  ///
  /// {@macro ormed.query}
  static Query<$NoFactory> query([String? connection]) =>
      Model.query<$NoFactory>(connection: connection);

  static Future<$NoFactory?> find(Object id, {String? connection}) =>
      Model.find<$NoFactory>(id, connection: connection);

  static Future<$NoFactory> findOrFail(Object id, {String? connection}) =>
      Model.findOrFail<$NoFactory>(id, connection: connection);

  static Future<List<$NoFactory>> all({String? connection}) =>
      Model.all<$NoFactory>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<$NoFactory>(connection: connection);

  static Future<bool> anyExist({String? connection}) =>
      Model.anyExist<$NoFactory>(connection: connection);

  static Query<$NoFactory> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) =>
      Model.where<$NoFactory>(column, operator, value, connection: connection);

  static Query<$NoFactory> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<$NoFactory>(column, values, connection: connection);

  static Query<$NoFactory> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<$NoFactory>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<$NoFactory> limit(int count, {String? connection}) =>
      Model.limit<$NoFactory>(count, connection: connection);

  /// Creates a [Repository] for [$NoFactory].
  ///
  /// {@macro ormed.repository}
  static Repository<$NoFactory> repo([String? connection]) =>
      Model.repository<$NoFactory>(connection: connection);
}

class NoFactoryModelFactory {
  const NoFactoryModelFactory._();

  static ModelDefinition<$NoFactory> get definition => _$NoFactoryDefinition;

  static ModelCodec<$NoFactory> get codec => definition.codec;

  static NoFactory fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    NoFactory model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model.toTracked(), registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<NoFactory> withConnection(
    QueryContext context,
  ) => ModelFactoryConnection<NoFactory>(
    definition: definition,
    context: context,
  );

  static ModelFactoryBuilder<NoFactory> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<NoFactory>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$NoFactoryCodec extends ModelCodec<$NoFactory> {
  const _$NoFactoryCodec();
  @override
  Map<String, Object?> encode($NoFactory model, ValueCodecRegistry registry) {
    return <String, Object?>{
      'id': registry.encodeField(_$NoFactoryIdField, model.id),
      if (model.hasAttribute('deleted_at'))
        'deleted_at': registry.encodeField(
          _$NoFactoryDeletedAtField,
          model.getAttribute<DateTime?>('deleted_at'),
        ),
    };
  }

  @override
  $NoFactory decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final int? noFactoryIdValue = registry.decodeField<int?>(
      _$NoFactoryIdField,
      data['id'],
    );
    final DateTime? noFactoryDeletedAtValue = registry.decodeField<DateTime?>(
      _$NoFactoryDeletedAtField,
      data['deleted_at'],
    );
    final model = $NoFactory(id: noFactoryIdValue);
    model._attachOrmRuntimeMetadata({
      'id': noFactoryIdValue,
      if (data.containsKey('deleted_at')) 'deleted_at': noFactoryDeletedAtValue,
    });
    return model;
  }
}

/// Insert DTO for [NoFactory].
///
/// Auto-increment/DB-generated fields are omitted by default.
class NoFactoryInsertDto implements InsertDto<$NoFactory> {
  const NoFactoryInsertDto();

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{};
  }

  NoFactoryInsertDto copyWith() => this;
}

/// Update DTO for [NoFactory].
///
/// All fields are optional; only provided entries are used in SET clauses.
class NoFactoryUpdateDto implements UpdateDto<$NoFactory> {
  const NoFactoryUpdateDto({this.id});
  final int? id;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{if (id != null) 'id': id};
  }

  static const _NoFactoryUpdateDtoCopyWithSentinel _copyWithSentinel =
      _NoFactoryUpdateDtoCopyWithSentinel();
  NoFactoryUpdateDto copyWith({Object? id = _copyWithSentinel}) {
    return NoFactoryUpdateDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
    );
  }
}

class _NoFactoryUpdateDtoCopyWithSentinel {
  const _NoFactoryUpdateDtoCopyWithSentinel();
}

/// Partial projection for [NoFactory].
///
/// All fields are nullable; intended for subset SELECTs.
class NoFactoryPartial implements PartialEntity<$NoFactory> {
  const NoFactoryPartial({this.id});

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory NoFactoryPartial.fromRow(Map<String, Object?> row) {
    return NoFactoryPartial(id: row['id'] as int?);
  }

  final int? id;

  @override
  $NoFactory toEntity() {
    // Basic required-field check: non-nullable fields must be present.
    return $NoFactory(id: id);
  }

  @override
  Map<String, Object?> toMap() {
    return {if (id != null) 'id': id};
  }

  static const _NoFactoryPartialCopyWithSentinel _copyWithSentinel =
      _NoFactoryPartialCopyWithSentinel();
  NoFactoryPartial copyWith({Object? id = _copyWithSentinel}) {
    return NoFactoryPartial(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
    );
  }
}

class _NoFactoryPartialCopyWithSentinel {
  const _NoFactoryPartialCopyWithSentinel();
}

/// Generated tracked model class for [NoFactory].
///
/// This class extends the user-defined [NoFactory] model and adds
/// attribute tracking, change detection, and relationship management.
/// Instances of this class are returned by queries and repositories.
///
/// **Do not instantiate this class directly.** Use queries, repositories,
/// or model factories to create tracked model instances.
class $NoFactory extends NoFactory
    with ModelAttributes, SoftDeletesImpl
    implements OrmEntity {
  /// Internal constructor for [$NoFactory].
  $NoFactory({int? id}) : super.new(id: id) {
    _attachOrmRuntimeMetadata({'id': id});
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $NoFactory.fromModel(NoFactory model) {
    return $NoFactory(id: model.id);
  }

  $NoFactory copyWith({int? id}) {
    return $NoFactory(id: id ?? this.id);
  }

  /// Tracked getter for [id].
  @override
  int? get id => getAttribute<int?>('id') ?? super.id;

  /// Tracked setter for [id].
  set id(int? value) => setAttribute('id', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$NoFactoryDefinition);
    attachSoftDeleteColumn('deleted_at');
  }
}

extension NoFactoryOrmExtension on NoFactory {
  /// The Type of the generated ORM-managed model class.
  /// Use this when you need to specify the tracked model type explicitly,
  /// for example in generic type parameters.
  static Type get trackedType => $NoFactory;

  /// Converts this immutable model to a tracked ORM-managed model.
  /// The tracked model supports attribute tracking, change detection,
  /// and persistence operations like save() and touch().
  $NoFactory toTracked() {
    return $NoFactory.fromModel(this);
  }
}

extension NoFactoryPredicateFields on PredicateBuilder<NoFactory> {
  PredicateField<NoFactory, int?> get id =>
      PredicateField<NoFactory, int?>(this, 'id');
}

void registerNoFactoryEventHandlers(EventBus bus) {
  // No event handlers registered for NoFactory.
}
