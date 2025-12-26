// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'factory_inheritance.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$BaseItemIdField = FieldDefinition(
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

const FieldDefinition _$BaseItemNameField = FieldDefinition(
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

Map<String, Object?> _encodeBaseItemUntracked(
  Object model,
  ValueCodecRegistry registry,
) {
  final m = model as BaseItem;
  return <String, Object?>{
    'id': registry.encodeField(_$BaseItemIdField, m.id),
    'name': registry.encodeField(_$BaseItemNameField, m.name),
  };
}

final ModelDefinition<$BaseItem> _$BaseItemDefinition = ModelDefinition(
  modelName: 'BaseItem',
  tableName: 'base_items',
  fields: const [_$BaseItemIdField, _$BaseItemNameField],
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
  untrackedToMap: _encodeBaseItemUntracked,
  codec: _$BaseItemCodec(),
);

// ignore: unused_element
final baseitemModelDefinitionRegistration =
    ModelFactoryRegistry.register<$BaseItem>(_$BaseItemDefinition);

extension BaseItemOrmDefinition on BaseItem {
  static ModelDefinition<$BaseItem> get definition => _$BaseItemDefinition;
}

class BaseItems {
  const BaseItems._();

  /// Starts building a query for [$BaseItem].
  ///
  /// {@macro ormed.query}
  static Query<$BaseItem> query([String? connection]) =>
      Model.query<$BaseItem>(connection: connection);

  static Future<$BaseItem?> find(Object id, {String? connection}) =>
      Model.find<$BaseItem>(id, connection: connection);

  static Future<$BaseItem> findOrFail(Object id, {String? connection}) =>
      Model.findOrFail<$BaseItem>(id, connection: connection);

  static Future<List<$BaseItem>> all({String? connection}) =>
      Model.all<$BaseItem>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<$BaseItem>(connection: connection);

  static Future<bool> anyExist({String? connection}) =>
      Model.anyExist<$BaseItem>(connection: connection);

  static Query<$BaseItem> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) => Model.where<$BaseItem>(column, operator, value, connection: connection);

  static Query<$BaseItem> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<$BaseItem>(column, values, connection: connection);

  static Query<$BaseItem> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<$BaseItem>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<$BaseItem> limit(int count, {String? connection}) =>
      Model.limit<$BaseItem>(count, connection: connection);

  /// Creates a [Repository] for [$BaseItem].
  ///
  /// {@macro ormed.repository}
  static Repository<$BaseItem> repo([String? connection]) =>
      Model.repository<$BaseItem>(connection: connection);
}

class BaseItemModelFactory {
  const BaseItemModelFactory._();

  static ModelDefinition<$BaseItem> get definition => _$BaseItemDefinition;

  static ModelCodec<$BaseItem> get codec => definition.codec;

  static BaseItem fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    BaseItem model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model.toTracked(), registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<BaseItem> withConnection(
    QueryContext context,
  ) => ModelFactoryConnection<BaseItem>(
    definition: definition,
    context: context,
  );

  static ModelFactoryBuilder<BaseItem> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<BaseItem>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$BaseItemCodec extends ModelCodec<$BaseItem> {
  const _$BaseItemCodec();
  @override
  Map<String, Object?> encode($BaseItem model, ValueCodecRegistry registry) {
    return <String, Object?>{
      'id': registry.encodeField(_$BaseItemIdField, model.id),
      'name': registry.encodeField(_$BaseItemNameField, model.name),
    };
  }

  @override
  $BaseItem decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final int baseItemIdValue =
        registry.decodeField<int>(_$BaseItemIdField, data['id']) ??
        (throw StateError('Field id on BaseItem cannot be null.'));
    final String? baseItemNameValue = registry.decodeField<String?>(
      _$BaseItemNameField,
      data['name'],
    );
    final model = $BaseItem(id: baseItemIdValue, name: baseItemNameValue);
    model._attachOrmRuntimeMetadata({
      'id': baseItemIdValue,
      'name': baseItemNameValue,
    });
    return model;
  }
}

/// Insert DTO for [BaseItem].
///
/// Auto-increment/DB-generated fields are omitted by default.
class BaseItemInsertDto implements InsertDto<$BaseItem> {
  const BaseItemInsertDto({this.id, this.name});
  final int? id;
  final String? name;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (name != null) 'name': name,
    };
  }

  static const _BaseItemInsertDtoCopyWithSentinel _copyWithSentinel =
      _BaseItemInsertDtoCopyWithSentinel();
  BaseItemInsertDto copyWith({
    Object? id = _copyWithSentinel,
    Object? name = _copyWithSentinel,
  }) {
    return BaseItemInsertDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      name: identical(name, _copyWithSentinel) ? this.name : name as String?,
    );
  }
}

class _BaseItemInsertDtoCopyWithSentinel {
  const _BaseItemInsertDtoCopyWithSentinel();
}

/// Update DTO for [BaseItem].
///
/// All fields are optional; only provided entries are used in SET clauses.
class BaseItemUpdateDto implements UpdateDto<$BaseItem> {
  const BaseItemUpdateDto({this.id, this.name});
  final int? id;
  final String? name;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (name != null) 'name': name,
    };
  }

  static const _BaseItemUpdateDtoCopyWithSentinel _copyWithSentinel =
      _BaseItemUpdateDtoCopyWithSentinel();
  BaseItemUpdateDto copyWith({
    Object? id = _copyWithSentinel,
    Object? name = _copyWithSentinel,
  }) {
    return BaseItemUpdateDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      name: identical(name, _copyWithSentinel) ? this.name : name as String?,
    );
  }
}

class _BaseItemUpdateDtoCopyWithSentinel {
  const _BaseItemUpdateDtoCopyWithSentinel();
}

/// Partial projection for [BaseItem].
///
/// All fields are nullable; intended for subset SELECTs.
class BaseItemPartial implements PartialEntity<$BaseItem> {
  const BaseItemPartial({this.id, this.name});

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory BaseItemPartial.fromRow(Map<String, Object?> row) {
    return BaseItemPartial(id: row['id'] as int?, name: row['name'] as String?);
  }

  final int? id;
  final String? name;

  @override
  $BaseItem toEntity() {
    // Basic required-field check: non-nullable fields must be present.
    final int? idValue = id;
    if (idValue == null) {
      throw StateError('Missing required field: id');
    }
    return $BaseItem(id: idValue, name: name);
  }

  @override
  Map<String, Object?> toMap() {
    return {if (id != null) 'id': id, if (name != null) 'name': name};
  }

  static const _BaseItemPartialCopyWithSentinel _copyWithSentinel =
      _BaseItemPartialCopyWithSentinel();
  BaseItemPartial copyWith({
    Object? id = _copyWithSentinel,
    Object? name = _copyWithSentinel,
  }) {
    return BaseItemPartial(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      name: identical(name, _copyWithSentinel) ? this.name : name as String?,
    );
  }
}

class _BaseItemPartialCopyWithSentinel {
  const _BaseItemPartialCopyWithSentinel();
}

/// Generated tracked model class for [BaseItem].
///
/// This class extends the user-defined [BaseItem] model and adds
/// attribute tracking, change detection, and relationship management.
/// Instances of this class are returned by queries and repositories.
///
/// **Do not instantiate this class directly.** Use queries, repositories,
/// or model factories to create tracked model instances.
class $BaseItem extends BaseItem with ModelAttributes implements OrmEntity {
  /// Internal constructor for [$BaseItem].
  $BaseItem({required int id, String? name}) : super.new(id: id, name: name) {
    _attachOrmRuntimeMetadata({'id': id, 'name': name});
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $BaseItem.fromModel(BaseItem model) {
    return $BaseItem(id: model.id, name: model.name);
  }

  $BaseItem copyWith({int? id, String? name}) {
    return $BaseItem(id: id ?? this.id, name: name ?? this.name);
  }

  /// Tracked getter for [id].
  @override
  int get id => getAttribute<int>('id') ?? super.id;

  /// Tracked setter for [id].
  set id(int value) => setAttribute('id', value);

  /// Tracked getter for [name].
  @override
  String? get name => getAttribute<String?>('name') ?? super.name;

  /// Tracked setter for [name].
  set name(String? value) => setAttribute('name', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$BaseItemDefinition);
  }
}

extension BaseItemOrmExtension on BaseItem {
  /// The Type of the generated ORM-managed model class.
  /// Use this when you need to specify the tracked model type explicitly,
  /// for example in generic type parameters.
  static Type get trackedType => $BaseItem;

  /// Converts this immutable model to a tracked ORM-managed model.
  /// The tracked model supports attribute tracking, change detection,
  /// and persistence operations like save() and touch().
  $BaseItem toTracked() {
    return $BaseItem.fromModel(this);
  }
}

void registerBaseItemEventHandlers(EventBus bus) {
  // No event handlers registered for BaseItem.
}

const FieldDefinition _$SpecialItemTagsField = FieldDefinition(
  name: 'tags',
  columnName: 'tags',
  dartType: 'List<String>',
  resolvedType: 'List<String>?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$SpecialItemIdField = FieldDefinition(
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

const FieldDefinition _$SpecialItemNameField = FieldDefinition(
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

Map<String, Object?> _encodeSpecialItemUntracked(
  Object model,
  ValueCodecRegistry registry,
) {
  final m = model as SpecialItem;
  return <String, Object?>{
    'tags': registry.encodeField(_$SpecialItemTagsField, m.tags),
    'id': registry.encodeField(_$SpecialItemIdField, m.id),
    'name': registry.encodeField(_$SpecialItemNameField, m.name),
  };
}

final ModelDefinition<$SpecialItem> _$SpecialItemDefinition = ModelDefinition(
  modelName: 'SpecialItem',
  tableName: 'special_items',
  fields: const [
    _$SpecialItemTagsField,
    _$SpecialItemIdField,
    _$SpecialItemNameField,
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
    softDeletes: false,
    softDeleteColumn: 'deleted_at',
  ),
  untrackedToMap: _encodeSpecialItemUntracked,
  codec: _$SpecialItemCodec(),
);

// ignore: unused_element
final specialitemModelDefinitionRegistration =
    ModelFactoryRegistry.register<$SpecialItem>(_$SpecialItemDefinition);

extension SpecialItemOrmDefinition on SpecialItem {
  static ModelDefinition<$SpecialItem> get definition =>
      _$SpecialItemDefinition;
}

class SpecialItems {
  const SpecialItems._();

  /// Starts building a query for [$SpecialItem].
  ///
  /// {@macro ormed.query}
  static Query<$SpecialItem> query([String? connection]) =>
      Model.query<$SpecialItem>(connection: connection);

  static Future<$SpecialItem?> find(Object id, {String? connection}) =>
      Model.find<$SpecialItem>(id, connection: connection);

  static Future<$SpecialItem> findOrFail(Object id, {String? connection}) =>
      Model.findOrFail<$SpecialItem>(id, connection: connection);

  static Future<List<$SpecialItem>> all({String? connection}) =>
      Model.all<$SpecialItem>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<$SpecialItem>(connection: connection);

  static Future<bool> anyExist({String? connection}) =>
      Model.anyExist<$SpecialItem>(connection: connection);

  static Query<$SpecialItem> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) => Model.where<$SpecialItem>(
    column,
    operator,
    value,
    connection: connection,
  );

  static Query<$SpecialItem> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<$SpecialItem>(column, values, connection: connection);

  static Query<$SpecialItem> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<$SpecialItem>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<$SpecialItem> limit(int count, {String? connection}) =>
      Model.limit<$SpecialItem>(count, connection: connection);

  /// Creates a [Repository] for [$SpecialItem].
  ///
  /// {@macro ormed.repository}
  static Repository<$SpecialItem> repo([String? connection]) =>
      Model.repository<$SpecialItem>(connection: connection);
}

class SpecialItemModelFactory {
  const SpecialItemModelFactory._();

  static ModelDefinition<$SpecialItem> get definition =>
      _$SpecialItemDefinition;

  static ModelCodec<$SpecialItem> get codec => definition.codec;

  static SpecialItem fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    SpecialItem model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model.toTracked(), registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<SpecialItem> withConnection(
    QueryContext context,
  ) => ModelFactoryConnection<SpecialItem>(
    definition: definition,
    context: context,
  );

  static ModelFactoryBuilder<SpecialItem> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<SpecialItem>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$SpecialItemCodec extends ModelCodec<$SpecialItem> {
  const _$SpecialItemCodec();
  @override
  Map<String, Object?> encode($SpecialItem model, ValueCodecRegistry registry) {
    return <String, Object?>{
      'tags': registry.encodeField(_$SpecialItemTagsField, model.tags),
      'id': registry.encodeField(_$SpecialItemIdField, model.id),
      'name': registry.encodeField(_$SpecialItemNameField, model.name),
    };
  }

  @override
  $SpecialItem decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final List<String>? specialItemTagsValue = registry
        .decodeField<List<String>?>(_$SpecialItemTagsField, data['tags']);
    final int specialItemIdValue =
        registry.decodeField<int>(_$SpecialItemIdField, data['id']) ??
        (throw StateError('Field id on SpecialItem cannot be null.'));
    final String? specialItemNameValue = registry.decodeField<String?>(
      _$SpecialItemNameField,
      data['name'],
    );
    final model = $SpecialItem(
      id: specialItemIdValue,
      name: specialItemNameValue,
      tags: specialItemTagsValue,
    );
    model._attachOrmRuntimeMetadata({
      'tags': specialItemTagsValue,
      'id': specialItemIdValue,
      'name': specialItemNameValue,
    });
    return model;
  }
}

/// Insert DTO for [SpecialItem].
///
/// Auto-increment/DB-generated fields are omitted by default.
class SpecialItemInsertDto implements InsertDto<$SpecialItem> {
  const SpecialItemInsertDto({this.tags, this.id, this.name});
  final List<String>? tags;
  final int? id;
  final String? name;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (tags != null) 'tags': tags,
      if (id != null) 'id': id,
      if (name != null) 'name': name,
    };
  }

  static const _SpecialItemInsertDtoCopyWithSentinel _copyWithSentinel =
      _SpecialItemInsertDtoCopyWithSentinel();
  SpecialItemInsertDto copyWith({
    Object? tags = _copyWithSentinel,
    Object? id = _copyWithSentinel,
    Object? name = _copyWithSentinel,
  }) {
    return SpecialItemInsertDto(
      tags: identical(tags, _copyWithSentinel)
          ? this.tags
          : tags as List<String>?,
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      name: identical(name, _copyWithSentinel) ? this.name : name as String?,
    );
  }
}

class _SpecialItemInsertDtoCopyWithSentinel {
  const _SpecialItemInsertDtoCopyWithSentinel();
}

/// Update DTO for [SpecialItem].
///
/// All fields are optional; only provided entries are used in SET clauses.
class SpecialItemUpdateDto implements UpdateDto<$SpecialItem> {
  const SpecialItemUpdateDto({this.tags, this.id, this.name});
  final List<String>? tags;
  final int? id;
  final String? name;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (tags != null) 'tags': tags,
      if (id != null) 'id': id,
      if (name != null) 'name': name,
    };
  }

  static const _SpecialItemUpdateDtoCopyWithSentinel _copyWithSentinel =
      _SpecialItemUpdateDtoCopyWithSentinel();
  SpecialItemUpdateDto copyWith({
    Object? tags = _copyWithSentinel,
    Object? id = _copyWithSentinel,
    Object? name = _copyWithSentinel,
  }) {
    return SpecialItemUpdateDto(
      tags: identical(tags, _copyWithSentinel)
          ? this.tags
          : tags as List<String>?,
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      name: identical(name, _copyWithSentinel) ? this.name : name as String?,
    );
  }
}

class _SpecialItemUpdateDtoCopyWithSentinel {
  const _SpecialItemUpdateDtoCopyWithSentinel();
}

/// Partial projection for [SpecialItem].
///
/// All fields are nullable; intended for subset SELECTs.
class SpecialItemPartial implements PartialEntity<$SpecialItem> {
  const SpecialItemPartial({this.tags, this.id, this.name});

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory SpecialItemPartial.fromRow(Map<String, Object?> row) {
    return SpecialItemPartial(
      tags: row['tags'] as List<String>?,
      id: row['id'] as int?,
      name: row['name'] as String?,
    );
  }

  final List<String>? tags;
  final int? id;
  final String? name;

  @override
  $SpecialItem toEntity() {
    // Basic required-field check: non-nullable fields must be present.
    final int? idValue = id;
    if (idValue == null) {
      throw StateError('Missing required field: id');
    }
    return $SpecialItem(tags: tags, id: idValue, name: name);
  }

  @override
  Map<String, Object?> toMap() {
    return {
      if (tags != null) 'tags': tags,
      if (id != null) 'id': id,
      if (name != null) 'name': name,
    };
  }

  static const _SpecialItemPartialCopyWithSentinel _copyWithSentinel =
      _SpecialItemPartialCopyWithSentinel();
  SpecialItemPartial copyWith({
    Object? tags = _copyWithSentinel,
    Object? id = _copyWithSentinel,
    Object? name = _copyWithSentinel,
  }) {
    return SpecialItemPartial(
      tags: identical(tags, _copyWithSentinel)
          ? this.tags
          : tags as List<String>?,
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      name: identical(name, _copyWithSentinel) ? this.name : name as String?,
    );
  }
}

class _SpecialItemPartialCopyWithSentinel {
  const _SpecialItemPartialCopyWithSentinel();
}

/// Generated tracked model class for [SpecialItem].
///
/// This class extends the user-defined [SpecialItem] model and adds
/// attribute tracking, change detection, and relationship management.
/// Instances of this class are returned by queries and repositories.
///
/// **Do not instantiate this class directly.** Use queries, repositories,
/// or model factories to create tracked model instances.
class $SpecialItem extends SpecialItem
    with ModelAttributes
    implements OrmEntity {
  /// Internal constructor for [$SpecialItem].
  $SpecialItem({required int id, String? name, List<String>? tags})
    : super.new(id: id, name: name, tags: tags) {
    _attachOrmRuntimeMetadata({'tags': tags, 'id': id, 'name': name});
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $SpecialItem.fromModel(SpecialItem model) {
    return $SpecialItem(tags: model.tags, id: model.id, name: model.name);
  }

  $SpecialItem copyWith({List<String>? tags, int? id, String? name}) {
    return $SpecialItem(
      tags: tags ?? this.tags,
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }

  /// Tracked getter for [tags].
  @override
  List<String>? get tags => getAttribute<List<String>?>('tags') ?? super.tags;

  /// Tracked setter for [tags].
  set tags(List<String>? value) => setAttribute('tags', value);

  /// Tracked getter for [id].
  @override
  int get id => getAttribute<int>('id') ?? super.id;

  /// Tracked setter for [id].
  set id(int value) => setAttribute('id', value);

  /// Tracked getter for [name].
  @override
  String? get name => getAttribute<String?>('name') ?? super.name;

  /// Tracked setter for [name].
  set name(String? value) => setAttribute('name', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$SpecialItemDefinition);
  }
}

extension SpecialItemOrmExtension on SpecialItem {
  /// The Type of the generated ORM-managed model class.
  /// Use this when you need to specify the tracked model type explicitly,
  /// for example in generic type parameters.
  static Type get trackedType => $SpecialItem;

  /// Converts this immutable model to a tracked ORM-managed model.
  /// The tracked model supports attribute tracking, change detection,
  /// and persistence operations like save() and touch().
  $SpecialItem toTracked() {
    return $SpecialItem.fromModel(this);
  }
}

void registerSpecialItemEventHandlers(EventBus bus) {
  // No event handlers registered for SpecialItem.
}
