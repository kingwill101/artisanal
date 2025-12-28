// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'field_examples.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$ItemWithIntPKIdField = FieldDefinition(
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

Map<String, Object?> _encodeItemWithIntPKUntracked(
  Object model,
  ValueCodecRegistry registry,
) {
  final m = model as ItemWithIntPK;
  return <String, Object?>{
    'id': registry.encodeField(_$ItemWithIntPKIdField, m.id),
  };
}

final ModelDefinition<$ItemWithIntPK> _$ItemWithIntPKDefinition =
    ModelDefinition(
      modelName: 'ItemWithIntPK',
      tableName: 'items',
      fields: const [_$ItemWithIntPKIdField],
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
      untrackedToMap: _encodeItemWithIntPKUntracked,
      codec: _$ItemWithIntPKCodec(),
    );

extension ItemWithIntPKOrmDefinition on ItemWithIntPK {
  static ModelDefinition<$ItemWithIntPK> get definition =>
      _$ItemWithIntPKDefinition;
}

class ItemWithIntPKs {
  const ItemWithIntPKs._();

  /// Starts building a query for [$ItemWithIntPK].
  ///
  /// {@macro ormed.query}
  static Query<$ItemWithIntPK> query([String? connection]) =>
      Model.query<$ItemWithIntPK>(connection: connection);

  static Future<$ItemWithIntPK?> find(Object id, {String? connection}) =>
      Model.find<$ItemWithIntPK>(id, connection: connection);

  static Future<$ItemWithIntPK> findOrFail(Object id, {String? connection}) =>
      Model.findOrFail<$ItemWithIntPK>(id, connection: connection);

  static Future<List<$ItemWithIntPK>> all({String? connection}) =>
      Model.all<$ItemWithIntPK>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<$ItemWithIntPK>(connection: connection);

  static Future<bool> anyExist({String? connection}) =>
      Model.anyExist<$ItemWithIntPK>(connection: connection);

  static Query<$ItemWithIntPK> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) => Model.where<$ItemWithIntPK>(
    column,
    operator,
    value,
    connection: connection,
  );

  static Query<$ItemWithIntPK> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<$ItemWithIntPK>(column, values, connection: connection);

  static Query<$ItemWithIntPK> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<$ItemWithIntPK>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<$ItemWithIntPK> limit(int count, {String? connection}) =>
      Model.limit<$ItemWithIntPK>(count, connection: connection);

  /// Creates a [Repository] for [$ItemWithIntPK].
  ///
  /// {@macro ormed.repository}
  static Repository<$ItemWithIntPK> repo([String? connection]) =>
      Model.repository<$ItemWithIntPK>(connection: connection);

  /// Builds a tracked model from a column/value map.
  static $ItemWithIntPK fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$ItemWithIntPKDefinition.fromMap(data, registry: registry);

  /// Converts a tracked model to a column/value map.
  static Map<String, Object?> toMap(
    $ItemWithIntPK model, {
    ValueCodecRegistry? registry,
  }) => _$ItemWithIntPKDefinition.toMap(model, registry: registry);
}

class ItemWithIntPKModelFactory {
  const ItemWithIntPKModelFactory._();

  static ModelDefinition<$ItemWithIntPK> get definition =>
      _$ItemWithIntPKDefinition;

  static ModelCodec<$ItemWithIntPK> get codec => definition.codec;

  static ItemWithIntPK fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    ItemWithIntPK model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model.toTracked(), registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<ItemWithIntPK> withConnection(
    QueryContext context,
  ) => ModelFactoryConnection<ItemWithIntPK>(
    definition: definition,
    context: context,
  );

  static ModelFactoryBuilder<ItemWithIntPK> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<ItemWithIntPK>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$ItemWithIntPKCodec extends ModelCodec<$ItemWithIntPK> {
  const _$ItemWithIntPKCodec();
  @override
  Map<String, Object?> encode(
    $ItemWithIntPK model,
    ValueCodecRegistry registry,
  ) {
    return <String, Object?>{
      'id': registry.encodeField(_$ItemWithIntPKIdField, model.id),
    };
  }

  @override
  $ItemWithIntPK decode(
    Map<String, Object?> data,
    ValueCodecRegistry registry,
  ) {
    final int itemWithIntPKIdValue =
        registry.decodeField<int>(_$ItemWithIntPKIdField, data['id']) ??
        (throw StateError('Field id on ItemWithIntPK cannot be null.'));
    final model = $ItemWithIntPK(id: itemWithIntPKIdValue);
    model._attachOrmRuntimeMetadata({'id': itemWithIntPKIdValue});
    return model;
  }
}

/// Insert DTO for [ItemWithIntPK].
///
/// Auto-increment/DB-generated fields are omitted by default.
class ItemWithIntPKInsertDto implements InsertDto<$ItemWithIntPK> {
  const ItemWithIntPKInsertDto({this.id});
  final int? id;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{if (id != null) 'id': id};
  }

  static const _ItemWithIntPKInsertDtoCopyWithSentinel _copyWithSentinel =
      _ItemWithIntPKInsertDtoCopyWithSentinel();
  ItemWithIntPKInsertDto copyWith({Object? id = _copyWithSentinel}) {
    return ItemWithIntPKInsertDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
    );
  }
}

class _ItemWithIntPKInsertDtoCopyWithSentinel {
  const _ItemWithIntPKInsertDtoCopyWithSentinel();
}

/// Update DTO for [ItemWithIntPK].
///
/// All fields are optional; only provided entries are used in SET clauses.
class ItemWithIntPKUpdateDto implements UpdateDto<$ItemWithIntPK> {
  const ItemWithIntPKUpdateDto({this.id});
  final int? id;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{if (id != null) 'id': id};
  }

  static const _ItemWithIntPKUpdateDtoCopyWithSentinel _copyWithSentinel =
      _ItemWithIntPKUpdateDtoCopyWithSentinel();
  ItemWithIntPKUpdateDto copyWith({Object? id = _copyWithSentinel}) {
    return ItemWithIntPKUpdateDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
    );
  }
}

class _ItemWithIntPKUpdateDtoCopyWithSentinel {
  const _ItemWithIntPKUpdateDtoCopyWithSentinel();
}

/// Partial projection for [ItemWithIntPK].
///
/// All fields are nullable; intended for subset SELECTs.
class ItemWithIntPKPartial implements PartialEntity<$ItemWithIntPK> {
  const ItemWithIntPKPartial({this.id});

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory ItemWithIntPKPartial.fromRow(Map<String, Object?> row) {
    return ItemWithIntPKPartial(id: row['id'] as int?);
  }

  final int? id;

  @override
  $ItemWithIntPK toEntity() {
    // Basic required-field check: non-nullable fields must be present.
    final int? idValue = id;
    if (idValue == null) {
      throw StateError('Missing required field: id');
    }
    return $ItemWithIntPK(id: idValue);
  }

  @override
  Map<String, Object?> toMap() {
    return {if (id != null) 'id': id};
  }

  static const _ItemWithIntPKPartialCopyWithSentinel _copyWithSentinel =
      _ItemWithIntPKPartialCopyWithSentinel();
  ItemWithIntPKPartial copyWith({Object? id = _copyWithSentinel}) {
    return ItemWithIntPKPartial(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
    );
  }
}

class _ItemWithIntPKPartialCopyWithSentinel {
  const _ItemWithIntPKPartialCopyWithSentinel();
}

/// Generated tracked model class for [ItemWithIntPK].
///
/// This class extends the user-defined [ItemWithIntPK] model and adds
/// attribute tracking, change detection, and relationship management.
/// Instances of this class are returned by queries and repositories.
///
/// **Do not instantiate this class directly.** Use queries, repositories,
/// or model factories to create tracked model instances.
class $ItemWithIntPK extends ItemWithIntPK
    with ModelAttributes
    implements OrmEntity {
  /// Internal constructor for [$ItemWithIntPK].
  $ItemWithIntPK({required int id}) : super.new(id: id) {
    _attachOrmRuntimeMetadata({'id': id});
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $ItemWithIntPK.fromModel(ItemWithIntPK model) {
    return $ItemWithIntPK(id: model.id);
  }

  $ItemWithIntPK copyWith({int? id}) {
    return $ItemWithIntPK(id: id ?? this.id);
  }

  /// Builds a tracked model from a column/value map.
  static $ItemWithIntPK fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$ItemWithIntPKDefinition.fromMap(data, registry: registry);

  /// Converts this tracked model to a column/value map.
  Map<String, Object?> toMap({ValueCodecRegistry? registry}) =>
      _$ItemWithIntPKDefinition.toMap(this, registry: registry);

  /// Tracked getter for [id].
  @override
  int get id => getAttribute<int>('id') ?? super.id;

  /// Tracked setter for [id].
  set id(int value) => setAttribute('id', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$ItemWithIntPKDefinition);
  }
}

class _ItemWithIntPKCopyWithSentinel {
  const _ItemWithIntPKCopyWithSentinel();
}

extension ItemWithIntPKOrmExtension on ItemWithIntPK {
  static const _ItemWithIntPKCopyWithSentinel _copyWithSentinel =
      _ItemWithIntPKCopyWithSentinel();
  ItemWithIntPK copyWith({Object? id = _copyWithSentinel}) {
    return ItemWithIntPK.new(
      id: identical(id, _copyWithSentinel) ? this.id : id as int,
    );
  }

  /// Converts this model to a column/value map.
  Map<String, Object?> toMap({ValueCodecRegistry? registry}) =>
      _$ItemWithIntPKDefinition.toMap(this, registry: registry);

  /// Builds a model from a column/value map.
  static ItemWithIntPK fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$ItemWithIntPKDefinition.fromMap(data, registry: registry);

  /// The Type of the generated ORM-managed model class.
  /// Use this when you need to specify the tracked model type explicitly,
  /// for example in generic type parameters.
  static Type get trackedType => $ItemWithIntPK;

  /// Converts this immutable model to a tracked ORM-managed model.
  /// The tracked model supports attribute tracking, change detection,
  /// and persistence operations like save() and touch().
  $ItemWithIntPK toTracked() {
    return $ItemWithIntPK.fromModel(this);
  }
}

extension ItemWithIntPKPredicateFields on PredicateBuilder<ItemWithIntPK> {
  PredicateField<ItemWithIntPK, int> get id =>
      PredicateField<ItemWithIntPK, int>(this, 'id');
}

void registerItemWithIntPKEventHandlers(EventBus bus) {
  // No event handlers registered for ItemWithIntPK.
}

const FieldDefinition _$ItemWithAutoIncrementIdField = FieldDefinition(
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

Map<String, Object?> _encodeItemWithAutoIncrementUntracked(
  Object model,
  ValueCodecRegistry registry,
) {
  final m = model as ItemWithAutoIncrement;
  return <String, Object?>{
    'id': registry.encodeField(_$ItemWithAutoIncrementIdField, m.id),
  };
}

final ModelDefinition<$ItemWithAutoIncrement>
_$ItemWithAutoIncrementDefinition = ModelDefinition(
  modelName: 'ItemWithAutoIncrement',
  tableName: 'auto_items',
  fields: const [_$ItemWithAutoIncrementIdField],
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
  untrackedToMap: _encodeItemWithAutoIncrementUntracked,
  codec: _$ItemWithAutoIncrementCodec(),
);

extension ItemWithAutoIncrementOrmDefinition on ItemWithAutoIncrement {
  static ModelDefinition<$ItemWithAutoIncrement> get definition =>
      _$ItemWithAutoIncrementDefinition;
}

class ItemWithAutoIncrements {
  const ItemWithAutoIncrements._();

  /// Starts building a query for [$ItemWithAutoIncrement].
  ///
  /// {@macro ormed.query}
  static Query<$ItemWithAutoIncrement> query([String? connection]) =>
      Model.query<$ItemWithAutoIncrement>(connection: connection);

  static Future<$ItemWithAutoIncrement?> find(
    Object id, {
    String? connection,
  }) => Model.find<$ItemWithAutoIncrement>(id, connection: connection);

  static Future<$ItemWithAutoIncrement> findOrFail(
    Object id, {
    String? connection,
  }) => Model.findOrFail<$ItemWithAutoIncrement>(id, connection: connection);

  static Future<List<$ItemWithAutoIncrement>> all({String? connection}) =>
      Model.all<$ItemWithAutoIncrement>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<$ItemWithAutoIncrement>(connection: connection);

  static Future<bool> anyExist({String? connection}) =>
      Model.anyExist<$ItemWithAutoIncrement>(connection: connection);

  static Query<$ItemWithAutoIncrement> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) => Model.where<$ItemWithAutoIncrement>(
    column,
    operator,
    value,
    connection: connection,
  );

  static Query<$ItemWithAutoIncrement> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<$ItemWithAutoIncrement>(
    column,
    values,
    connection: connection,
  );

  static Query<$ItemWithAutoIncrement> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<$ItemWithAutoIncrement>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<$ItemWithAutoIncrement> limit(int count, {String? connection}) =>
      Model.limit<$ItemWithAutoIncrement>(count, connection: connection);

  /// Creates a [Repository] for [$ItemWithAutoIncrement].
  ///
  /// {@macro ormed.repository}
  static Repository<$ItemWithAutoIncrement> repo([String? connection]) =>
      Model.repository<$ItemWithAutoIncrement>(connection: connection);

  /// Builds a tracked model from a column/value map.
  static $ItemWithAutoIncrement fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$ItemWithAutoIncrementDefinition.fromMap(data, registry: registry);

  /// Converts a tracked model to a column/value map.
  static Map<String, Object?> toMap(
    $ItemWithAutoIncrement model, {
    ValueCodecRegistry? registry,
  }) => _$ItemWithAutoIncrementDefinition.toMap(model, registry: registry);
}

class ItemWithAutoIncrementModelFactory {
  const ItemWithAutoIncrementModelFactory._();

  static ModelDefinition<$ItemWithAutoIncrement> get definition =>
      _$ItemWithAutoIncrementDefinition;

  static ModelCodec<$ItemWithAutoIncrement> get codec => definition.codec;

  static ItemWithAutoIncrement fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    ItemWithAutoIncrement model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model.toTracked(), registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<ItemWithAutoIncrement> withConnection(
    QueryContext context,
  ) => ModelFactoryConnection<ItemWithAutoIncrement>(
    definition: definition,
    context: context,
  );

  static ModelFactoryBuilder<ItemWithAutoIncrement> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<ItemWithAutoIncrement>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$ItemWithAutoIncrementCodec extends ModelCodec<$ItemWithAutoIncrement> {
  const _$ItemWithAutoIncrementCodec();
  @override
  Map<String, Object?> encode(
    $ItemWithAutoIncrement model,
    ValueCodecRegistry registry,
  ) {
    return <String, Object?>{
      'id': registry.encodeField(_$ItemWithAutoIncrementIdField, model.id),
    };
  }

  @override
  $ItemWithAutoIncrement decode(
    Map<String, Object?> data,
    ValueCodecRegistry registry,
  ) {
    final int itemWithAutoIncrementIdValue =
        registry.decodeField<int>(_$ItemWithAutoIncrementIdField, data['id']) ??
        0;
    final model = $ItemWithAutoIncrement(id: itemWithAutoIncrementIdValue);
    model._attachOrmRuntimeMetadata({'id': itemWithAutoIncrementIdValue});
    return model;
  }
}

/// Insert DTO for [ItemWithAutoIncrement].
///
/// Auto-increment/DB-generated fields are omitted by default.
class ItemWithAutoIncrementInsertDto
    implements InsertDto<$ItemWithAutoIncrement> {
  const ItemWithAutoIncrementInsertDto();

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{};
  }

  ItemWithAutoIncrementInsertDto copyWith() => this;
}

/// Update DTO for [ItemWithAutoIncrement].
///
/// All fields are optional; only provided entries are used in SET clauses.
class ItemWithAutoIncrementUpdateDto
    implements UpdateDto<$ItemWithAutoIncrement> {
  const ItemWithAutoIncrementUpdateDto({this.id});
  final int? id;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{if (id != null) 'id': id};
  }

  static const _ItemWithAutoIncrementUpdateDtoCopyWithSentinel
  _copyWithSentinel = _ItemWithAutoIncrementUpdateDtoCopyWithSentinel();
  ItemWithAutoIncrementUpdateDto copyWith({Object? id = _copyWithSentinel}) {
    return ItemWithAutoIncrementUpdateDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
    );
  }
}

class _ItemWithAutoIncrementUpdateDtoCopyWithSentinel {
  const _ItemWithAutoIncrementUpdateDtoCopyWithSentinel();
}

/// Partial projection for [ItemWithAutoIncrement].
///
/// All fields are nullable; intended for subset SELECTs.
class ItemWithAutoIncrementPartial
    implements PartialEntity<$ItemWithAutoIncrement> {
  const ItemWithAutoIncrementPartial({this.id});

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory ItemWithAutoIncrementPartial.fromRow(Map<String, Object?> row) {
    return ItemWithAutoIncrementPartial(id: row['id'] as int?);
  }

  final int? id;

  @override
  $ItemWithAutoIncrement toEntity() {
    // Basic required-field check: non-nullable fields must be present.
    final int? idValue = id;
    if (idValue == null) {
      throw StateError('Missing required field: id');
    }
    return $ItemWithAutoIncrement(id: idValue);
  }

  @override
  Map<String, Object?> toMap() {
    return {if (id != null) 'id': id};
  }

  static const _ItemWithAutoIncrementPartialCopyWithSentinel _copyWithSentinel =
      _ItemWithAutoIncrementPartialCopyWithSentinel();
  ItemWithAutoIncrementPartial copyWith({Object? id = _copyWithSentinel}) {
    return ItemWithAutoIncrementPartial(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
    );
  }
}

class _ItemWithAutoIncrementPartialCopyWithSentinel {
  const _ItemWithAutoIncrementPartialCopyWithSentinel();
}

/// Generated tracked model class for [ItemWithAutoIncrement].
///
/// This class extends the user-defined [ItemWithAutoIncrement] model and adds
/// attribute tracking, change detection, and relationship management.
/// Instances of this class are returned by queries and repositories.
///
/// **Do not instantiate this class directly.** Use queries, repositories,
/// or model factories to create tracked model instances.
class $ItemWithAutoIncrement extends ItemWithAutoIncrement
    with ModelAttributes
    implements OrmEntity {
  /// Internal constructor for [$ItemWithAutoIncrement].
  $ItemWithAutoIncrement({int id = 0}) : super.new(id: id) {
    _attachOrmRuntimeMetadata({'id': id});
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $ItemWithAutoIncrement.fromModel(ItemWithAutoIncrement model) {
    return $ItemWithAutoIncrement(id: model.id);
  }

  $ItemWithAutoIncrement copyWith({int? id}) {
    return $ItemWithAutoIncrement(id: id ?? this.id);
  }

  /// Builds a tracked model from a column/value map.
  static $ItemWithAutoIncrement fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$ItemWithAutoIncrementDefinition.fromMap(data, registry: registry);

  /// Converts this tracked model to a column/value map.
  Map<String, Object?> toMap({ValueCodecRegistry? registry}) =>
      _$ItemWithAutoIncrementDefinition.toMap(this, registry: registry);

  /// Tracked getter for [id].
  @override
  int get id => getAttribute<int>('id') ?? super.id;

  /// Tracked setter for [id].
  set id(int value) => setAttribute('id', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$ItemWithAutoIncrementDefinition);
  }
}

class _ItemWithAutoIncrementCopyWithSentinel {
  const _ItemWithAutoIncrementCopyWithSentinel();
}

extension ItemWithAutoIncrementOrmExtension on ItemWithAutoIncrement {
  static const _ItemWithAutoIncrementCopyWithSentinel _copyWithSentinel =
      _ItemWithAutoIncrementCopyWithSentinel();
  ItemWithAutoIncrement copyWith({Object? id = _copyWithSentinel}) {
    return ItemWithAutoIncrement.new(
      id: identical(id, _copyWithSentinel) ? this.id : id as int,
    );
  }

  /// Converts this model to a column/value map.
  Map<String, Object?> toMap({ValueCodecRegistry? registry}) =>
      _$ItemWithAutoIncrementDefinition.toMap(this, registry: registry);

  /// Builds a model from a column/value map.
  static ItemWithAutoIncrement fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$ItemWithAutoIncrementDefinition.fromMap(data, registry: registry);

  /// The Type of the generated ORM-managed model class.
  /// Use this when you need to specify the tracked model type explicitly,
  /// for example in generic type parameters.
  static Type get trackedType => $ItemWithAutoIncrement;

  /// Converts this immutable model to a tracked ORM-managed model.
  /// The tracked model supports attribute tracking, change detection,
  /// and persistence operations like save() and touch().
  $ItemWithAutoIncrement toTracked() {
    return $ItemWithAutoIncrement.fromModel(this);
  }
}

extension ItemWithAutoIncrementPredicateFields
    on PredicateBuilder<ItemWithAutoIncrement> {
  PredicateField<ItemWithAutoIncrement, int> get id =>
      PredicateField<ItemWithAutoIncrement, int>(this, 'id');
}

void registerItemWithAutoIncrementEventHandlers(EventBus bus) {
  // No event handlers registered for ItemWithAutoIncrement.
}

const FieldDefinition _$ItemWithUuidPKIdField = FieldDefinition(
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

Map<String, Object?> _encodeItemWithUuidPKUntracked(
  Object model,
  ValueCodecRegistry registry,
) {
  final m = model as ItemWithUuidPK;
  return <String, Object?>{
    'id': registry.encodeField(_$ItemWithUuidPKIdField, m.id),
  };
}

final ModelDefinition<$ItemWithUuidPK> _$ItemWithUuidPKDefinition =
    ModelDefinition(
      modelName: 'ItemWithUuidPK',
      tableName: 'uuid_items',
      fields: const [_$ItemWithUuidPKIdField],
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
      untrackedToMap: _encodeItemWithUuidPKUntracked,
      codec: _$ItemWithUuidPKCodec(),
    );

extension ItemWithUuidPKOrmDefinition on ItemWithUuidPK {
  static ModelDefinition<$ItemWithUuidPK> get definition =>
      _$ItemWithUuidPKDefinition;
}

class ItemWithUuidPKs {
  const ItemWithUuidPKs._();

  /// Starts building a query for [$ItemWithUuidPK].
  ///
  /// {@macro ormed.query}
  static Query<$ItemWithUuidPK> query([String? connection]) =>
      Model.query<$ItemWithUuidPK>(connection: connection);

  static Future<$ItemWithUuidPK?> find(Object id, {String? connection}) =>
      Model.find<$ItemWithUuidPK>(id, connection: connection);

  static Future<$ItemWithUuidPK> findOrFail(Object id, {String? connection}) =>
      Model.findOrFail<$ItemWithUuidPK>(id, connection: connection);

  static Future<List<$ItemWithUuidPK>> all({String? connection}) =>
      Model.all<$ItemWithUuidPK>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<$ItemWithUuidPK>(connection: connection);

  static Future<bool> anyExist({String? connection}) =>
      Model.anyExist<$ItemWithUuidPK>(connection: connection);

  static Query<$ItemWithUuidPK> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) => Model.where<$ItemWithUuidPK>(
    column,
    operator,
    value,
    connection: connection,
  );

  static Query<$ItemWithUuidPK> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<$ItemWithUuidPK>(column, values, connection: connection);

  static Query<$ItemWithUuidPK> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<$ItemWithUuidPK>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<$ItemWithUuidPK> limit(int count, {String? connection}) =>
      Model.limit<$ItemWithUuidPK>(count, connection: connection);

  /// Creates a [Repository] for [$ItemWithUuidPK].
  ///
  /// {@macro ormed.repository}
  static Repository<$ItemWithUuidPK> repo([String? connection]) =>
      Model.repository<$ItemWithUuidPK>(connection: connection);

  /// Builds a tracked model from a column/value map.
  static $ItemWithUuidPK fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$ItemWithUuidPKDefinition.fromMap(data, registry: registry);

  /// Converts a tracked model to a column/value map.
  static Map<String, Object?> toMap(
    $ItemWithUuidPK model, {
    ValueCodecRegistry? registry,
  }) => _$ItemWithUuidPKDefinition.toMap(model, registry: registry);
}

class ItemWithUuidPKModelFactory {
  const ItemWithUuidPKModelFactory._();

  static ModelDefinition<$ItemWithUuidPK> get definition =>
      _$ItemWithUuidPKDefinition;

  static ModelCodec<$ItemWithUuidPK> get codec => definition.codec;

  static ItemWithUuidPK fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    ItemWithUuidPK model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model.toTracked(), registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<ItemWithUuidPK> withConnection(
    QueryContext context,
  ) => ModelFactoryConnection<ItemWithUuidPK>(
    definition: definition,
    context: context,
  );

  static ModelFactoryBuilder<ItemWithUuidPK> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<ItemWithUuidPK>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$ItemWithUuidPKCodec extends ModelCodec<$ItemWithUuidPK> {
  const _$ItemWithUuidPKCodec();
  @override
  Map<String, Object?> encode(
    $ItemWithUuidPK model,
    ValueCodecRegistry registry,
  ) {
    return <String, Object?>{
      'id': registry.encodeField(_$ItemWithUuidPKIdField, model.id),
    };
  }

  @override
  $ItemWithUuidPK decode(
    Map<String, Object?> data,
    ValueCodecRegistry registry,
  ) {
    final String itemWithUuidPKIdValue =
        registry.decodeField<String>(_$ItemWithUuidPKIdField, data['id']) ??
        (throw StateError('Field id on ItemWithUuidPK cannot be null.'));
    final model = $ItemWithUuidPK(id: itemWithUuidPKIdValue);
    model._attachOrmRuntimeMetadata({'id': itemWithUuidPKIdValue});
    return model;
  }
}

/// Insert DTO for [ItemWithUuidPK].
///
/// Auto-increment/DB-generated fields are omitted by default.
class ItemWithUuidPKInsertDto implements InsertDto<$ItemWithUuidPK> {
  const ItemWithUuidPKInsertDto({this.id});
  final String? id;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{if (id != null) 'id': id};
  }

  static const _ItemWithUuidPKInsertDtoCopyWithSentinel _copyWithSentinel =
      _ItemWithUuidPKInsertDtoCopyWithSentinel();
  ItemWithUuidPKInsertDto copyWith({Object? id = _copyWithSentinel}) {
    return ItemWithUuidPKInsertDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as String?,
    );
  }
}

class _ItemWithUuidPKInsertDtoCopyWithSentinel {
  const _ItemWithUuidPKInsertDtoCopyWithSentinel();
}

/// Update DTO for [ItemWithUuidPK].
///
/// All fields are optional; only provided entries are used in SET clauses.
class ItemWithUuidPKUpdateDto implements UpdateDto<$ItemWithUuidPK> {
  const ItemWithUuidPKUpdateDto({this.id});
  final String? id;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{if (id != null) 'id': id};
  }

  static const _ItemWithUuidPKUpdateDtoCopyWithSentinel _copyWithSentinel =
      _ItemWithUuidPKUpdateDtoCopyWithSentinel();
  ItemWithUuidPKUpdateDto copyWith({Object? id = _copyWithSentinel}) {
    return ItemWithUuidPKUpdateDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as String?,
    );
  }
}

class _ItemWithUuidPKUpdateDtoCopyWithSentinel {
  const _ItemWithUuidPKUpdateDtoCopyWithSentinel();
}

/// Partial projection for [ItemWithUuidPK].
///
/// All fields are nullable; intended for subset SELECTs.
class ItemWithUuidPKPartial implements PartialEntity<$ItemWithUuidPK> {
  const ItemWithUuidPKPartial({this.id});

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory ItemWithUuidPKPartial.fromRow(Map<String, Object?> row) {
    return ItemWithUuidPKPartial(id: row['id'] as String?);
  }

  final String? id;

  @override
  $ItemWithUuidPK toEntity() {
    // Basic required-field check: non-nullable fields must be present.
    final String? idValue = id;
    if (idValue == null) {
      throw StateError('Missing required field: id');
    }
    return $ItemWithUuidPK(id: idValue);
  }

  @override
  Map<String, Object?> toMap() {
    return {if (id != null) 'id': id};
  }

  static const _ItemWithUuidPKPartialCopyWithSentinel _copyWithSentinel =
      _ItemWithUuidPKPartialCopyWithSentinel();
  ItemWithUuidPKPartial copyWith({Object? id = _copyWithSentinel}) {
    return ItemWithUuidPKPartial(
      id: identical(id, _copyWithSentinel) ? this.id : id as String?,
    );
  }
}

class _ItemWithUuidPKPartialCopyWithSentinel {
  const _ItemWithUuidPKPartialCopyWithSentinel();
}

/// Generated tracked model class for [ItemWithUuidPK].
///
/// This class extends the user-defined [ItemWithUuidPK] model and adds
/// attribute tracking, change detection, and relationship management.
/// Instances of this class are returned by queries and repositories.
///
/// **Do not instantiate this class directly.** Use queries, repositories,
/// or model factories to create tracked model instances.
class $ItemWithUuidPK extends ItemWithUuidPK
    with ModelAttributes
    implements OrmEntity {
  /// Internal constructor for [$ItemWithUuidPK].
  $ItemWithUuidPK({required String id}) : super.new(id: id) {
    _attachOrmRuntimeMetadata({'id': id});
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $ItemWithUuidPK.fromModel(ItemWithUuidPK model) {
    return $ItemWithUuidPK(id: model.id);
  }

  $ItemWithUuidPK copyWith({String? id}) {
    return $ItemWithUuidPK(id: id ?? this.id);
  }

  /// Builds a tracked model from a column/value map.
  static $ItemWithUuidPK fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$ItemWithUuidPKDefinition.fromMap(data, registry: registry);

  /// Converts this tracked model to a column/value map.
  Map<String, Object?> toMap({ValueCodecRegistry? registry}) =>
      _$ItemWithUuidPKDefinition.toMap(this, registry: registry);

  /// Tracked getter for [id].
  @override
  String get id => getAttribute<String>('id') ?? super.id;

  /// Tracked setter for [id].
  set id(String value) => setAttribute('id', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$ItemWithUuidPKDefinition);
  }
}

class _ItemWithUuidPKCopyWithSentinel {
  const _ItemWithUuidPKCopyWithSentinel();
}

extension ItemWithUuidPKOrmExtension on ItemWithUuidPK {
  static const _ItemWithUuidPKCopyWithSentinel _copyWithSentinel =
      _ItemWithUuidPKCopyWithSentinel();
  ItemWithUuidPK copyWith({Object? id = _copyWithSentinel}) {
    return ItemWithUuidPK.new(
      id: identical(id, _copyWithSentinel) ? this.id : id as String,
    );
  }

  /// Converts this model to a column/value map.
  Map<String, Object?> toMap({ValueCodecRegistry? registry}) =>
      _$ItemWithUuidPKDefinition.toMap(this, registry: registry);

  /// Builds a model from a column/value map.
  static ItemWithUuidPK fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$ItemWithUuidPKDefinition.fromMap(data, registry: registry);

  /// The Type of the generated ORM-managed model class.
  /// Use this when you need to specify the tracked model type explicitly,
  /// for example in generic type parameters.
  static Type get trackedType => $ItemWithUuidPK;

  /// Converts this immutable model to a tracked ORM-managed model.
  /// The tracked model supports attribute tracking, change detection,
  /// and persistence operations like save() and touch().
  $ItemWithUuidPK toTracked() {
    return $ItemWithUuidPK.fromModel(this);
  }
}

extension ItemWithUuidPKPredicateFields on PredicateBuilder<ItemWithUuidPK> {
  PredicateField<ItemWithUuidPK, String> get id =>
      PredicateField<ItemWithUuidPK, String>(this, 'id');
}

void registerItemWithUuidPKEventHandlers(EventBus bus) {
  // No event handlers registered for ItemWithUuidPK.
}

const FieldDefinition _$ContactIdField = FieldDefinition(
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

const FieldDefinition _$ContactEmailField = FieldDefinition(
  name: 'email',
  columnName: 'user_email',
  dartType: 'String',
  resolvedType: 'String',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$ContactActiveField = FieldDefinition(
  name: 'active',
  columnName: 'active',
  dartType: 'bool',
  resolvedType: 'bool',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
  defaultValueSql: '1',
);

const FieldDefinition _$ContactNameField = FieldDefinition(
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

Map<String, Object?> _encodeContactUntracked(
  Object model,
  ValueCodecRegistry registry,
) {
  final m = model as Contact;
  return <String, Object?>{
    'id': registry.encodeField(_$ContactIdField, m.id),
    'user_email': registry.encodeField(_$ContactEmailField, m.email),
    'active': registry.encodeField(_$ContactActiveField, m.active),
    'name': registry.encodeField(_$ContactNameField, m.name),
  };
}

final ModelDefinition<$Contact> _$ContactDefinition = ModelDefinition(
  modelName: 'Contact',
  tableName: 'contacts',
  fields: const [
    _$ContactIdField,
    _$ContactEmailField,
    _$ContactActiveField,
    _$ContactNameField,
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
  untrackedToMap: _encodeContactUntracked,
  codec: _$ContactCodec(),
);

extension ContactOrmDefinition on Contact {
  static ModelDefinition<$Contact> get definition => _$ContactDefinition;
}

class Contacts {
  const Contacts._();

  /// Starts building a query for [$Contact].
  ///
  /// {@macro ormed.query}
  static Query<$Contact> query([String? connection]) =>
      Model.query<$Contact>(connection: connection);

  static Future<$Contact?> find(Object id, {String? connection}) =>
      Model.find<$Contact>(id, connection: connection);

  static Future<$Contact> findOrFail(Object id, {String? connection}) =>
      Model.findOrFail<$Contact>(id, connection: connection);

  static Future<List<$Contact>> all({String? connection}) =>
      Model.all<$Contact>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<$Contact>(connection: connection);

  static Future<bool> anyExist({String? connection}) =>
      Model.anyExist<$Contact>(connection: connection);

  static Query<$Contact> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) => Model.where<$Contact>(column, operator, value, connection: connection);

  static Query<$Contact> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<$Contact>(column, values, connection: connection);

  static Query<$Contact> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<$Contact>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<$Contact> limit(int count, {String? connection}) =>
      Model.limit<$Contact>(count, connection: connection);

  /// Creates a [Repository] for [$Contact].
  ///
  /// {@macro ormed.repository}
  static Repository<$Contact> repo([String? connection]) =>
      Model.repository<$Contact>(connection: connection);

  /// Builds a tracked model from a column/value map.
  static $Contact fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$ContactDefinition.fromMap(data, registry: registry);

  /// Converts a tracked model to a column/value map.
  static Map<String, Object?> toMap(
    $Contact model, {
    ValueCodecRegistry? registry,
  }) => _$ContactDefinition.toMap(model, registry: registry);
}

class ContactModelFactory {
  const ContactModelFactory._();

  static ModelDefinition<$Contact> get definition => _$ContactDefinition;

  static ModelCodec<$Contact> get codec => definition.codec;

  static Contact fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    Contact model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model.toTracked(), registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<Contact> withConnection(QueryContext context) =>
      ModelFactoryConnection<Contact>(definition: definition, context: context);

  static ModelFactoryBuilder<Contact> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<Contact>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$ContactCodec extends ModelCodec<$Contact> {
  const _$ContactCodec();
  @override
  Map<String, Object?> encode($Contact model, ValueCodecRegistry registry) {
    return <String, Object?>{
      'id': registry.encodeField(_$ContactIdField, model.id),
      'user_email': registry.encodeField(_$ContactEmailField, model.email),
      'active': registry.encodeField(_$ContactActiveField, model.active),
      'name': registry.encodeField(_$ContactNameField, model.name),
    };
  }

  @override
  $Contact decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final int contactIdValue =
        registry.decodeField<int>(_$ContactIdField, data['id']) ?? 0;
    final String contactEmailValue =
        registry.decodeField<String>(_$ContactEmailField, data['user_email']) ??
        (throw StateError('Field email on Contact cannot be null.'));
    final bool contactActiveValue =
        registry.decodeField<bool>(_$ContactActiveField, data['active']) ??
        false;
    final String? contactNameValue = registry.decodeField<String?>(
      _$ContactNameField,
      data['name'],
    );
    final model = $Contact(
      id: contactIdValue,
      email: contactEmailValue,
      active: contactActiveValue,
      name: contactNameValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': contactIdValue,
      'user_email': contactEmailValue,
      'active': contactActiveValue,
      'name': contactNameValue,
    });
    return model;
  }
}

/// Insert DTO for [Contact].
///
/// Auto-increment/DB-generated fields are omitted by default.
class ContactInsertDto implements InsertDto<$Contact> {
  const ContactInsertDto({this.email, this.active, this.name});
  final String? email;
  final bool? active;
  final String? name;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (email != null) 'user_email': email,
      if (active != null) 'active': active,
      if (name != null) 'name': name,
    };
  }

  static const _ContactInsertDtoCopyWithSentinel _copyWithSentinel =
      _ContactInsertDtoCopyWithSentinel();
  ContactInsertDto copyWith({
    Object? email = _copyWithSentinel,
    Object? active = _copyWithSentinel,
    Object? name = _copyWithSentinel,
  }) {
    return ContactInsertDto(
      email: identical(email, _copyWithSentinel)
          ? this.email
          : email as String?,
      active: identical(active, _copyWithSentinel)
          ? this.active
          : active as bool?,
      name: identical(name, _copyWithSentinel) ? this.name : name as String?,
    );
  }
}

class _ContactInsertDtoCopyWithSentinel {
  const _ContactInsertDtoCopyWithSentinel();
}

/// Update DTO for [Contact].
///
/// All fields are optional; only provided entries are used in SET clauses.
class ContactUpdateDto implements UpdateDto<$Contact> {
  const ContactUpdateDto({this.id, this.email, this.active, this.name});
  final int? id;
  final String? email;
  final bool? active;
  final String? name;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (email != null) 'user_email': email,
      if (active != null) 'active': active,
      if (name != null) 'name': name,
    };
  }

  static const _ContactUpdateDtoCopyWithSentinel _copyWithSentinel =
      _ContactUpdateDtoCopyWithSentinel();
  ContactUpdateDto copyWith({
    Object? id = _copyWithSentinel,
    Object? email = _copyWithSentinel,
    Object? active = _copyWithSentinel,
    Object? name = _copyWithSentinel,
  }) {
    return ContactUpdateDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      email: identical(email, _copyWithSentinel)
          ? this.email
          : email as String?,
      active: identical(active, _copyWithSentinel)
          ? this.active
          : active as bool?,
      name: identical(name, _copyWithSentinel) ? this.name : name as String?,
    );
  }
}

class _ContactUpdateDtoCopyWithSentinel {
  const _ContactUpdateDtoCopyWithSentinel();
}

/// Partial projection for [Contact].
///
/// All fields are nullable; intended for subset SELECTs.
class ContactPartial implements PartialEntity<$Contact> {
  const ContactPartial({this.id, this.email, this.active, this.name});

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory ContactPartial.fromRow(Map<String, Object?> row) {
    return ContactPartial(
      id: row['id'] as int?,
      email: row['user_email'] as String?,
      active: row['active'] as bool?,
      name: row['name'] as String?,
    );
  }

  final int? id;
  final String? email;
  final bool? active;
  final String? name;

  @override
  $Contact toEntity() {
    // Basic required-field check: non-nullable fields must be present.
    final int? idValue = id;
    if (idValue == null) {
      throw StateError('Missing required field: id');
    }
    final String? emailValue = email;
    if (emailValue == null) {
      throw StateError('Missing required field: email');
    }
    final bool? activeValue = active;
    if (activeValue == null) {
      throw StateError('Missing required field: active');
    }
    return $Contact(
      id: idValue,
      email: emailValue,
      active: activeValue,
      name: name,
    );
  }

  @override
  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      if (email != null) 'user_email': email,
      if (active != null) 'active': active,
      if (name != null) 'name': name,
    };
  }

  static const _ContactPartialCopyWithSentinel _copyWithSentinel =
      _ContactPartialCopyWithSentinel();
  ContactPartial copyWith({
    Object? id = _copyWithSentinel,
    Object? email = _copyWithSentinel,
    Object? active = _copyWithSentinel,
    Object? name = _copyWithSentinel,
  }) {
    return ContactPartial(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      email: identical(email, _copyWithSentinel)
          ? this.email
          : email as String?,
      active: identical(active, _copyWithSentinel)
          ? this.active
          : active as bool?,
      name: identical(name, _copyWithSentinel) ? this.name : name as String?,
    );
  }
}

class _ContactPartialCopyWithSentinel {
  const _ContactPartialCopyWithSentinel();
}

/// Generated tracked model class for [Contact].
///
/// This class extends the user-defined [Contact] model and adds
/// attribute tracking, change detection, and relationship management.
/// Instances of this class are returned by queries and repositories.
///
/// **Do not instantiate this class directly.** Use queries, repositories,
/// or model factories to create tracked model instances.
class $Contact extends Contact with ModelAttributes implements OrmEntity {
  /// Internal constructor for [$Contact].
  $Contact({
    int id = 0,
    required String email,
    required bool active,
    String? name,
  }) : super.new(id: id, email: email, active: active, name: name) {
    _attachOrmRuntimeMetadata({
      'id': id,
      'user_email': email,
      'active': active,
      'name': name,
    });
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $Contact.fromModel(Contact model) {
    return $Contact(
      id: model.id,
      email: model.email,
      active: model.active,
      name: model.name,
    );
  }

  $Contact copyWith({int? id, String? email, bool? active, String? name}) {
    return $Contact(
      id: id ?? this.id,
      email: email ?? this.email,
      active: active ?? this.active,
      name: name ?? this.name,
    );
  }

  /// Builds a tracked model from a column/value map.
  static $Contact fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$ContactDefinition.fromMap(data, registry: registry);

  /// Converts this tracked model to a column/value map.
  Map<String, Object?> toMap({ValueCodecRegistry? registry}) =>
      _$ContactDefinition.toMap(this, registry: registry);

  /// Tracked getter for [id].
  @override
  int get id => getAttribute<int>('id') ?? super.id;

  /// Tracked setter for [id].
  set id(int value) => setAttribute('id', value);

  /// Tracked getter for [email].
  @override
  String get email => getAttribute<String>('user_email') ?? super.email;

  /// Tracked setter for [email].
  set email(String value) => setAttribute('user_email', value);

  /// Tracked getter for [active].
  @override
  bool get active => getAttribute<bool>('active') ?? super.active;

  /// Tracked setter for [active].
  set active(bool value) => setAttribute('active', value);

  /// Tracked getter for [name].
  @override
  String? get name => getAttribute<String?>('name') ?? super.name;

  /// Tracked setter for [name].
  set name(String? value) => setAttribute('name', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$ContactDefinition);
  }
}

class _ContactCopyWithSentinel {
  const _ContactCopyWithSentinel();
}

extension ContactOrmExtension on Contact {
  static const _ContactCopyWithSentinel _copyWithSentinel =
      _ContactCopyWithSentinel();
  Contact copyWith({
    Object? id = _copyWithSentinel,
    Object? email = _copyWithSentinel,
    Object? active = _copyWithSentinel,
    Object? name = _copyWithSentinel,
  }) {
    return Contact.new(
      id: identical(id, _copyWithSentinel) ? this.id : id as int,
      email: identical(email, _copyWithSentinel) ? this.email : email as String,
      active: identical(active, _copyWithSentinel)
          ? this.active
          : active as bool,
      name: identical(name, _copyWithSentinel) ? this.name : name as String?,
    );
  }

  /// Converts this model to a column/value map.
  Map<String, Object?> toMap({ValueCodecRegistry? registry}) =>
      _$ContactDefinition.toMap(this, registry: registry);

  /// Builds a model from a column/value map.
  static Contact fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$ContactDefinition.fromMap(data, registry: registry);

  /// The Type of the generated ORM-managed model class.
  /// Use this when you need to specify the tracked model type explicitly,
  /// for example in generic type parameters.
  static Type get trackedType => $Contact;

  /// Converts this immutable model to a tracked ORM-managed model.
  /// The tracked model supports attribute tracking, change detection,
  /// and persistence operations like save() and touch().
  $Contact toTracked() {
    return $Contact.fromModel(this);
  }
}

extension ContactPredicateFields on PredicateBuilder<Contact> {
  PredicateField<Contact, int> get id =>
      PredicateField<Contact, int>(this, 'id');
  PredicateField<Contact, String> get email =>
      PredicateField<Contact, String>(this, 'email');
  PredicateField<Contact, bool> get active =>
      PredicateField<Contact, bool>(this, 'active');
  PredicateField<Contact, String?> get name =>
      PredicateField<Contact, String?>(this, 'name');
}

void registerContactEventHandlers(EventBus bus) {
  // No event handlers registered for Contact.
}
