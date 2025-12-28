// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'product.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$ProductIdField = FieldDefinition(
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

const FieldDefinition _$ProductSkuField = FieldDefinition(
  name: 'sku',
  columnName: 'sku',
  dartType: 'String',
  resolvedType: 'String',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$ProductActiveField = FieldDefinition(
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

const FieldDefinition _$ProductMetadataField = FieldDefinition(
  name: 'metadata',
  columnName: 'metadata',
  dartType: 'Map<String, Object?>',
  resolvedType: 'Map<String, Object?>?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
  codecType: 'JsonMapCodec',
);

Map<String, Object?> _encodeProductUntracked(
  Object model,
  ValueCodecRegistry registry,
) {
  final m = model as Product;
  return <String, Object?>{
    'id': registry.encodeField(_$ProductIdField, m.id),
    'sku': registry.encodeField(_$ProductSkuField, m.sku),
    'active': registry.encodeField(_$ProductActiveField, m.active),
    'metadata': registry.encodeField(_$ProductMetadataField, m.metadata),
  };
}

final ModelDefinition<$Product> _$ProductDefinition = ModelDefinition(
  modelName: 'Product',
  tableName: 'products',
  fields: const [
    _$ProductIdField,
    _$ProductSkuField,
    _$ProductActiveField,
    _$ProductMetadataField,
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
  untrackedToMap: _encodeProductUntracked,
  codec: _$ProductCodec(),
);

extension ProductOrmDefinition on Product {
  static ModelDefinition<$Product> get definition => _$ProductDefinition;
}

class Products {
  const Products._();

  /// Starts building a query for [$Product].
  ///
  /// {@macro ormed.query}
  static Query<$Product> query([String? connection]) =>
      Model.query<$Product>(connection: connection);

  static Future<$Product?> find(Object id, {String? connection}) =>
      Model.find<$Product>(id, connection: connection);

  static Future<$Product> findOrFail(Object id, {String? connection}) =>
      Model.findOrFail<$Product>(id, connection: connection);

  static Future<List<$Product>> all({String? connection}) =>
      Model.all<$Product>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<$Product>(connection: connection);

  static Future<bool> anyExist({String? connection}) =>
      Model.anyExist<$Product>(connection: connection);

  static Query<$Product> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) => Model.where<$Product>(column, operator, value, connection: connection);

  static Query<$Product> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<$Product>(column, values, connection: connection);

  static Query<$Product> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<$Product>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<$Product> limit(int count, {String? connection}) =>
      Model.limit<$Product>(count, connection: connection);

  /// Creates a [Repository] for [$Product].
  ///
  /// {@macro ormed.repository}
  static Repository<$Product> repo([String? connection]) =>
      Model.repository<$Product>(connection: connection);
}

class ProductModelFactory {
  const ProductModelFactory._();

  static ModelDefinition<$Product> get definition => _$ProductDefinition;

  static ModelCodec<$Product> get codec => definition.codec;

  static Product fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    Product model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model.toTracked(), registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<Product> withConnection(QueryContext context) =>
      ModelFactoryConnection<Product>(definition: definition, context: context);

  static ModelFactoryBuilder<Product> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<Product>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$ProductCodec extends ModelCodec<$Product> {
  const _$ProductCodec();
  @override
  Map<String, Object?> encode($Product model, ValueCodecRegistry registry) {
    return <String, Object?>{
      'id': registry.encodeField(_$ProductIdField, model.id),
      'sku': registry.encodeField(_$ProductSkuField, model.sku),
      'active': registry.encodeField(_$ProductActiveField, model.active),
      'metadata': registry.encodeField(_$ProductMetadataField, model.metadata),
    };
  }

  @override
  $Product decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final int productIdValue =
        registry.decodeField<int>(_$ProductIdField, data['id']) ?? 0;
    final String productSkuValue =
        registry.decodeField<String>(_$ProductSkuField, data['sku']) ??
        (throw StateError('Field sku on Product cannot be null.'));
    final bool productActiveValue =
        registry.decodeField<bool>(_$ProductActiveField, data['active']) ??
        false;
    final Map<String, Object?>? productMetadataValue = registry
        .decodeField<Map<String, Object?>?>(
          _$ProductMetadataField,
          data['metadata'],
        );
    final model = $Product(
      id: productIdValue,
      sku: productSkuValue,
      active: productActiveValue,
      metadata: productMetadataValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': productIdValue,
      'sku': productSkuValue,
      'active': productActiveValue,
      'metadata': productMetadataValue,
    });
    return model;
  }
}

/// Insert DTO for [Product].
///
/// Auto-increment/DB-generated fields are omitted by default.
class ProductInsertDto implements InsertDto<$Product> {
  const ProductInsertDto({this.sku, this.active, this.metadata});
  final String? sku;
  final bool? active;
  final Map<String, Object?>? metadata;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (sku != null) 'sku': sku,
      if (active != null) 'active': active,
      if (metadata != null) 'metadata': metadata,
    };
  }

  static const _ProductInsertDtoCopyWithSentinel _copyWithSentinel =
      _ProductInsertDtoCopyWithSentinel();
  ProductInsertDto copyWith({
    Object? sku = _copyWithSentinel,
    Object? active = _copyWithSentinel,
    Object? metadata = _copyWithSentinel,
  }) {
    return ProductInsertDto(
      sku: identical(sku, _copyWithSentinel) ? this.sku : sku as String?,
      active: identical(active, _copyWithSentinel)
          ? this.active
          : active as bool?,
      metadata: identical(metadata, _copyWithSentinel)
          ? this.metadata
          : metadata as Map<String, Object?>?,
    );
  }
}

class _ProductInsertDtoCopyWithSentinel {
  const _ProductInsertDtoCopyWithSentinel();
}

/// Update DTO for [Product].
///
/// All fields are optional; only provided entries are used in SET clauses.
class ProductUpdateDto implements UpdateDto<$Product> {
  const ProductUpdateDto({this.id, this.sku, this.active, this.metadata});
  final int? id;
  final String? sku;
  final bool? active;
  final Map<String, Object?>? metadata;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (sku != null) 'sku': sku,
      if (active != null) 'active': active,
      if (metadata != null) 'metadata': metadata,
    };
  }

  static const _ProductUpdateDtoCopyWithSentinel _copyWithSentinel =
      _ProductUpdateDtoCopyWithSentinel();
  ProductUpdateDto copyWith({
    Object? id = _copyWithSentinel,
    Object? sku = _copyWithSentinel,
    Object? active = _copyWithSentinel,
    Object? metadata = _copyWithSentinel,
  }) {
    return ProductUpdateDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      sku: identical(sku, _copyWithSentinel) ? this.sku : sku as String?,
      active: identical(active, _copyWithSentinel)
          ? this.active
          : active as bool?,
      metadata: identical(metadata, _copyWithSentinel)
          ? this.metadata
          : metadata as Map<String, Object?>?,
    );
  }
}

class _ProductUpdateDtoCopyWithSentinel {
  const _ProductUpdateDtoCopyWithSentinel();
}

/// Partial projection for [Product].
///
/// All fields are nullable; intended for subset SELECTs.
class ProductPartial implements PartialEntity<$Product> {
  const ProductPartial({this.id, this.sku, this.active, this.metadata});

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory ProductPartial.fromRow(Map<String, Object?> row) {
    return ProductPartial(
      id: row['id'] as int?,
      sku: row['sku'] as String?,
      active: row['active'] as bool?,
      metadata: row['metadata'] as Map<String, Object?>?,
    );
  }

  final int? id;
  final String? sku;
  final bool? active;
  final Map<String, Object?>? metadata;

  @override
  $Product toEntity() {
    // Basic required-field check: non-nullable fields must be present.
    final int? idValue = id;
    if (idValue == null) {
      throw StateError('Missing required field: id');
    }
    final String? skuValue = sku;
    if (skuValue == null) {
      throw StateError('Missing required field: sku');
    }
    final bool? activeValue = active;
    if (activeValue == null) {
      throw StateError('Missing required field: active');
    }
    return $Product(
      id: idValue,
      sku: skuValue,
      active: activeValue,
      metadata: metadata,
    );
  }

  @override
  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      if (sku != null) 'sku': sku,
      if (active != null) 'active': active,
      if (metadata != null) 'metadata': metadata,
    };
  }

  static const _ProductPartialCopyWithSentinel _copyWithSentinel =
      _ProductPartialCopyWithSentinel();
  ProductPartial copyWith({
    Object? id = _copyWithSentinel,
    Object? sku = _copyWithSentinel,
    Object? active = _copyWithSentinel,
    Object? metadata = _copyWithSentinel,
  }) {
    return ProductPartial(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      sku: identical(sku, _copyWithSentinel) ? this.sku : sku as String?,
      active: identical(active, _copyWithSentinel)
          ? this.active
          : active as bool?,
      metadata: identical(metadata, _copyWithSentinel)
          ? this.metadata
          : metadata as Map<String, Object?>?,
    );
  }
}

class _ProductPartialCopyWithSentinel {
  const _ProductPartialCopyWithSentinel();
}

/// Generated tracked model class for [Product].
///
/// This class extends the user-defined [Product] model and adds
/// attribute tracking, change detection, and relationship management.
/// Instances of this class are returned by queries and repositories.
///
/// **Do not instantiate this class directly.** Use queries, repositories,
/// or model factories to create tracked model instances.
class $Product extends Product with ModelAttributes implements OrmEntity {
  /// Internal constructor for [$Product].
  $Product({
    int id = 0,
    required String sku,
    required bool active,
    Map<String, Object?>? metadata,
  }) : super.new(id: id, sku: sku, active: active, metadata: metadata) {
    _attachOrmRuntimeMetadata({
      'id': id,
      'sku': sku,
      'active': active,
      'metadata': metadata,
    });
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $Product.fromModel(Product model) {
    return $Product(
      id: model.id,
      sku: model.sku,
      active: model.active,
      metadata: model.metadata,
    );
  }

  $Product copyWith({
    int? id,
    String? sku,
    bool? active,
    Map<String, Object?>? metadata,
  }) {
    return $Product(
      id: id ?? this.id,
      sku: sku ?? this.sku,
      active: active ?? this.active,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Tracked getter for [id].
  @override
  int get id => getAttribute<int>('id') ?? super.id;

  /// Tracked setter for [id].
  set id(int value) => setAttribute('id', value);

  /// Tracked getter for [sku].
  @override
  String get sku => getAttribute<String>('sku') ?? super.sku;

  /// Tracked setter for [sku].
  set sku(String value) => setAttribute('sku', value);

  /// Tracked getter for [active].
  @override
  bool get active => getAttribute<bool>('active') ?? super.active;

  /// Tracked setter for [active].
  set active(bool value) => setAttribute('active', value);

  /// Tracked getter for [metadata].
  @override
  Map<String, Object?>? get metadata =>
      getAttribute<Map<String, Object?>?>('metadata') ?? super.metadata;

  /// Tracked setter for [metadata].
  set metadata(Map<String, Object?>? value) => setAttribute('metadata', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$ProductDefinition);
  }
}

extension ProductOrmExtension on Product {
  /// The Type of the generated ORM-managed model class.
  /// Use this when you need to specify the tracked model type explicitly,
  /// for example in generic type parameters.
  static Type get trackedType => $Product;

  /// Converts this immutable model to a tracked ORM-managed model.
  /// The tracked model supports attribute tracking, change detection,
  /// and persistence operations like save() and touch().
  $Product toTracked() {
    return $Product.fromModel(this);
  }
}

extension ProductPredicateFields on PredicateBuilder<Product> {
  PredicateField<Product, int> get id =>
      PredicateField<Product, int>(this, 'id');
  PredicateField<Product, String> get sku =>
      PredicateField<Product, String>(this, 'sku');
  PredicateField<Product, bool> get active =>
      PredicateField<Product, bool>(this, 'active');
  PredicateField<Product, Map<String, Object?>?> get metadata =>
      PredicateField<Product, Map<String, Object?>?>(this, 'metadata');
}

void registerProductEventHandlers(EventBus bus) {
  // No event handlers registered for Product.
}
