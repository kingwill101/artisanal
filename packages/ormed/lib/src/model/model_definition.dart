import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:ormed/ormed.dart';

/// Encodes a user-defined (untracked) model instance to a column/value map.
///
/// This is generated to support encoding base model types (e.g. `User`) when
/// the registry maps them to a generated tracked definition (e.g. `$User`) via
/// `ModelRegistry.registerTypeAlias<User>(...)`.
typedef UntrackedModelEncoder =
    Map<String, Object?> Function(Object model, ValueCodecRegistry registry);

/// Reads a model attribute value using a custom accessor.
typedef AttributeAccessor = Object? Function(OrmEntity model, Object? value);

/// Transforms a model attribute value using a custom mutator.
typedef AttributeMutator = Object? Function(OrmEntity model, Object? value);

/// Runtime description of a generated ORM model.
///
/// Generated code registers a [ModelDefinition] for each `@OrmModel()` type.
/// Queries and repositories use the definition to:
/// - Resolve table/schema metadata.
/// - Encode models into column maps for mutations.
/// - Decode result rows into tracked model instances.
///
/// Most applications never create definitions manually; they are emitted by the
/// code generator and stored in [ModelRegistry].
class ModelDefinition<TModel extends OrmEntity> {
  const ModelDefinition({
    required this.modelName,
    required this.tableName,
    required this.fields,
    required this.codec,
    this.untrackedToMap,
    this.schema,
    this.relations = const [],
    this.softDeleteColumn,
    this.metadata = const ModelAttributesMetadata(),
    this.accessors = const {},
    this.mutators = const {},
  });

  /// The name of the model class.
  final String modelName;

  /// The database table name for this model.
  final String tableName;

  /// Optional database schema name.
  final String? schema;

  /// List of all field definitions for this model.
  final List<FieldDefinition> fields;

  /// List of all relation definitions for this model.
  final List<RelationDefinition> relations;

  /// Codec for encoding/decoding model instances to/from maps.
  final ModelCodec<TModel> codec;

  /// Optional encoder for user-defined (untracked) model instances.
  ///
  /// When [TModel] is a user-defined model type (registered via
  /// `ModelRegistry.registerTypeAlias`) but [codec] targets the generated
  /// tracked type, this encoder provides a mirrors-free path for encoding the
  /// user model.
  final UntrackedModelEncoder? untrackedToMap;

  /// Column name used for soft deletes, if enabled.
  final String? softDeleteColumn;

  /// Metadata controlling attribute behavior (hidden, fillable, etc.).
  final ModelAttributesMetadata metadata;

  /// Attribute accessors keyed by column name.
  final Map<String, AttributeAccessor> accessors;

  /// Attribute mutators keyed by column name.
  final Map<String, AttributeMutator> mutators;

  /// Returns the runtime type of the model.
  Type get modelType => TModel;

  /// Finds a field by its Dart property name.
  FieldDefinition? fieldByName(String name) =>
      fields.firstWhereOrNull((field) => field.name == name);

  /// Finds a field by its database column name.
  FieldDefinition? fieldByColumn(String column) =>
      fields.firstWhereOrNull((field) => field.columnName == column);

  /// Returns the primary key field definition, if one exists.
  FieldDefinition? get primaryKeyField =>
      fields.firstWhereOrNull((field) => field.isPrimaryKey);

  /// Returns true if this model uses soft deletes.
  bool get usesSoftDeletes => softDeleteField != null;

  /// Returns the field definition for the soft delete column, if configured.
  FieldDefinition? get softDeleteField {
    if (softDeleteColumn == null) return null;
    return fields.firstWhereOrNull(
      (field) =>
          field.columnName == softDeleteColumn ||
          field.name == softDeleteColumn,
    );
  }

  /// Encodes a model instance to a map using the model's codec.
  ///
  /// Accepts both user-defined models and generated tracked models.
  ///
  /// If [model] is a tracked instance (it mixes in [ModelAttributes]), encoding
  /// uses the generated codec and [registry] for type conversions.
  ///
  /// For ad-hoc queries where [model] is already a `Map<String, Object?>`, this
  /// returns the map directly.
  Map<String, Object?> toMap(
    covariant dynamic model, {
    ValueCodecRegistry? registry,
  }) {
    // Handle ad-hoc queries where model is already a Map
    if (model is Map<String, Object?>) {
      return Map<String, Object?>.from(model);
    }

    final reg = registry ?? ValueCodecRegistry.instance;

    // Tracked model: let the generated codec handle encoding (includes virtual
    // fields like timestamps and soft delete columns).
    if (model is ModelAttributes) {
      return codec.encode(model as dynamic, reg);
    }

    // Untracked model: require a generated encoder (no mirrors).
    final encoder = untrackedToMap;
    if (encoder == null) {
      throw StateError(
        'Cannot encode an untracked $modelName instance without a generated encoder. '
        'Re-run build_runner for $modelName, or pass a tracked instance / InsertDto / UpdateDto / Map instead.',
      );
    }
    return encoder(model, reg);
  }

  /// Decodes a map to a model instance using the model's codec.
  ///
  /// Automatically attaches model definition and soft delete metadata if the
  /// model implements [ModelAttributes].
  TModel fromMap(Map<String, Object?> data, {ValueCodecRegistry? registry}) {
    final model = codec.decode(data, registry ?? ValueCodecRegistry.instance);
    if (model is ModelAttributes) {
      final attributes = model as ModelAttributes;
      attributes.attachModelDefinition(this as ModelDefinition<OrmEntity>);
      if (usesSoftDeletes) {
        attributes.attachSoftDeleteColumn(metadata.softDeleteColumn);
      }
      attributes.syncOriginal();
    }
    return model;
  }

  /// Creates a copy of this definition with the specified fields replaced.
  ModelDefinition<TModel> copyWith({
    String? modelName,
    String? tableName,
    String? schema,
    List<FieldDefinition>? fields,
    List<RelationDefinition>? relations,
    ModelCodec<TModel>? codec,
    UntrackedModelEncoder? untrackedToMap,
    String? softDeleteColumn,
    ModelAttributesMetadata? metadata,
    Map<String, AttributeAccessor>? accessors,
    Map<String, AttributeMutator>? mutators,
  }) => ModelDefinition<TModel>(
    modelName: modelName ?? this.modelName,
    tableName: tableName ?? this.tableName,
    schema: schema ?? this.schema,
    fields: fields ?? this.fields,
    relations: relations ?? this.relations,
    codec: codec ?? this.codec,
    untrackedToMap: untrackedToMap ?? this.untrackedToMap,
    softDeleteColumn: softDeleteColumn ?? this.softDeleteColumn,
    metadata: metadata ?? this.metadata,
    accessors: accessors ?? this.accessors,
    mutators: mutators ?? this.mutators,
  );
}

/// Annotation-driven metadata for attribute behavior.
class ModelAttributesMetadata {
  const ModelAttributesMetadata({
    this.hidden = const <String>[],
    this.visible = const <String>[],
    this.fillable = const <String>[],
    this.guarded = const <String>[],
    this.casts = const <String, String>{},
    this.appends = const <String>[],
    this.touches = const <String>[],
    this.timestamps = true,
    this.fieldOverrides = const {},
    this.connection,
    this.softDeletes = false,
    this.softDeleteColumn = 'deleted_at',
    this.driverAnnotations = const <Object>[],
  });

  /// List of attribute names that should be hidden from serialization.
  final List<String> hidden;

  /// List of attribute names that should be visible in serialization (overrides hidden).
  final List<String> visible;

  /// List of attribute names that can be mass-assigned.
  final List<String> fillable;

  /// List of attribute names that cannot be mass-assigned.
  final List<String> guarded;

  /// Map of attribute names to their cast types.
  final Map<String, String> casts;

  /// Computed attributes to append when serializing.
  final List<String> appends;

  /// Relation names to touch when this model is saved.
  final List<String> touches;

  /// Whether automatic timestamps (created_at/updated_at) are enabled.
  final bool timestamps;

  /// Per-field metadata overrides.
  final Map<String, FieldAttributeMetadata> fieldOverrides;

  /// Connection name for this model.
  final String? connection;

  /// Whether soft deletes are enabled.
  final bool softDeletes;

  /// Name of the soft delete column.
  final String softDeleteColumn;

  /// Driver-specific annotations.
  final List<Object> driverAnnotations;

  /// Creates a copy of this metadata with the specified fields replaced.
  ModelAttributesMetadata copyWith({
    List<String>? hidden,
    List<String>? visible,
    List<String>? fillable,
    List<String>? guarded,
    Map<String, String>? casts,
    List<String>? appends,
    List<String>? touches,
    bool? timestamps,
    Map<String, FieldAttributeMetadata>? fieldOverrides,
    String? connection,
    bool? softDeletes,
    String? softDeleteColumn,
    List<Object>? driverAnnotations,
  }) => ModelAttributesMetadata(
    hidden: hidden ?? this.hidden,
    visible: visible ?? this.visible,
    fillable: fillable ?? this.fillable,
    guarded: guarded ?? this.guarded,
    casts: casts ?? this.casts,
    appends: appends ?? this.appends,
    touches: touches ?? this.touches,
    timestamps: timestamps ?? this.timestamps,
    fieldOverrides: fieldOverrides ?? this.fieldOverrides,
    connection: connection ?? this.connection,
    softDeletes: softDeletes ?? this.softDeletes,
    softDeleteColumn: softDeleteColumn ?? this.softDeleteColumn,
    driverAnnotations: driverAnnotations ?? this.driverAnnotations,
  );
}

/// Per-field metadata overrides for attribute behavior.
///
/// These override the model-level settings for a specific field.
class FieldAttributeMetadata {
  const FieldAttributeMetadata({
    this.fillable,
    this.guarded,
    this.hidden,
    this.visible,
    this.cast,
  });

  /// Whether this field is fillable (overrides model-level).
  final bool? fillable;

  /// Whether this field is guarded (overrides model-level).
  final bool? guarded;

  /// Whether this field is hidden (overrides model-level).
  final bool? hidden;

  /// Whether this field is visible (overrides model-level).
  final bool? visible;

  /// Cast type for this field (overrides model-level).
  final String? cast;
}

/// Metadata for a single model field/column.
class FieldDefinition {
  const FieldDefinition({
    required this.name,
    required this.columnName,
    required this.dartType,
    required this.resolvedType,
    this.isPrimaryKey = false,
    required this.isNullable,
    this.isUnique = false,
    this.isIndexed = false,
    this.autoIncrement = false,
    this.columnType,
    this.defaultValueSql,
    this.codecType,
    this.enumValues,
    this.driverOverrides = const {},
  });

  /// The Dart property name.
  final String name;

  /// The database column name.
  final String columnName;

  /// The Dart type as a string (e.g., 'String', 'int?').
  final String dartType;

  /// The resolved type after codec transformations.
  final String resolvedType;

  /// Whether this field is the primary key.
  final bool isPrimaryKey;

  /// Whether this field can be null.
  final bool isNullable;

  /// Whether this field has a unique constraint.
  final bool isUnique;

  /// Whether this field is indexed.
  final bool isIndexed;

  /// Whether this field auto-increments.
  final bool autoIncrement;

  /// SQL column type (e.g., 'VARCHAR(255)', 'INTEGER').
  final String? columnType;

  /// SQL default value expression.
  final String? defaultValueSql;

  /// Codec type for value transformations.
  final String? codecType;

  /// Enum values for enum-backed fields (used by enum casts).
  ///
  /// Stored as the enum's `values` list from generated code.
  final Object? enumValues;

  /// Driver-specific overrides for this field.
  final Map<String, FieldDriverOverride> driverOverrides;

  /// Returns whether this field should be included in INSERT statements.
  ///
  /// Auto-increment fields are excluded by default.
  bool get isInsertable => !autoIncrement;

  /// Returns whether this field should be included in UPDATE statements.
  ///
  /// Primary key fields are excluded by default.
  bool get isUpdatable => !isPrimaryKey;

  /// Returns the driver-specific override for this field, if any.
  FieldDriverOverride? overrideFor(String? driver) {
    if (driver == null) return null;
    final normalized = _normalizeDriver(driver);
    return driverOverrides[normalized];
  }

  /// Returns the column type for the specified driver, falling back to the default.
  String? columnTypeForDriver(String? driver) =>
      overrideFor(driver)?.columnType ?? columnType;

  /// Returns the default value SQL for the specified driver, falling back to the default.
  String? defaultValueSqlForDriver(String? driver) =>
      overrideFor(driver)?.defaultValueSql ?? defaultValueSql;

  /// Returns the codec type for the specified driver, falling back to the default.
  String? codecTypeForDriver(String? driver) =>
      overrideFor(driver)?.codecType ?? codecType;
}

/// Driver-specific metadata for a field definition.
class FieldDriverOverride {
  const FieldDriverOverride({
    this.columnType,
    this.defaultValueSql,
    this.codecType,
  });

  /// Driver-specific column type override.
  final String? columnType;

  /// Driver-specific default value SQL override.
  final String? defaultValueSql;

  /// Driver-specific codec type override.
  final String? codecType;
}

String _normalizeDriver(String driver) => driver.trim().toLowerCase();

/// Map-backed row returned for ad-hoc table queries.
class AdHocRow extends MapBase<String, Object?> implements OrmEntity {
  AdHocRow([Map<String, Object?>? initial])
    : _data = Map<String, Object?>.from(initial ?? const {});

  final Map<String, Object?> _data;

  @override
  Object? operator [](Object? key) => _data[key];

  @override
  void operator []=(String key, Object? value) {
    _data[key] = value;
  }

  @override
  void clear() => _data.clear();

  @override
  Iterable<String> get keys => _data.keys;

  @override
  Object? remove(Object? key) => key is String ? _data.remove(key) : null;
}

/// Metadata for a relationship between two models.
class RelationDefinition {
  const RelationDefinition({
    required this.name,
    required this.kind,
    required this.targetModel,
    this.foreignKey,
    this.localKey,
    this.through,
    this.throughModel,
    this.throughForeignKey,
    this.throughLocalKey,
    this.pivotForeignKey,
    this.pivotRelatedKey,
    this.pivotColumns = const [],
    this.pivotTimestamps = false,
    this.pivotModel,
    this.morphType,
    this.morphClass,
  });

  /// The name of the relation property.
  final String name;

  /// The kind of relationship (hasMany, belongsTo, etc.).
  final RelationKind kind;

  /// The target model type name.
  final String targetModel;

  /// Foreign key column name.
  final String? foreignKey;

  /// Local key column name.
  final String? localKey;

  /// Through model for has-many-through relations.
  final String? through;

  /// Intermediate model for through relations.
  final String? throughModel;

  /// Foreign key on the through model pointing back to the parent.
  final String? throughForeignKey;

  /// Key on the through model referenced by the related model's foreign key.
  final String? throughLocalKey;

  /// Foreign key on the pivot table for many-to-many relations.
  final String? pivotForeignKey;

  /// Related key on the pivot table for many-to-many relations.
  final String? pivotRelatedKey;

  /// Additional pivot columns to select when eager loading.
  final List<String> pivotColumns;

  /// Whether to automatically manage pivot timestamps.
  final bool pivotTimestamps;

  /// Optional pivot model type name for many-to-many relations.
  final String? pivotModel;

  /// Type column name for polymorphic relations.
  final String? morphType;

  /// Class identifier for polymorphic relations.
  final String? morphClass;
}

/// Base contract for generated model codecs.
abstract class ModelCodec<TModel> {
  const ModelCodec();

  /// Encodes a model instance to a map.
  Map<String, Object?> encode(TModel model, ValueCodecRegistry registry);

  /// Decodes a map to a model instance.
  TModel decode(Map<String, Object?> data, ValueCodecRegistry registry);
}

/// A model definition for ad-hoc queries without a concrete model class.
///
/// Used internally for table queries and raw SQL results.
class AdHocModelDefinition extends ModelDefinition<AdHocRow> {
  AdHocModelDefinition({
    required super.tableName,
    super.schema,
    this.alias,
    List<AdHocColumn> columns = const [],
  }) : _fields = <String, FieldDefinition>{},
       super(
         modelName: 'AdHoc<$tableName>',
         fields: const [],
         codec: const _MapModelCodec(),
       ) {
    for (final column in columns) {
      registerColumn(column);
    }
  }

  /// Optional table alias.
  final String? alias;

  final Map<String, FieldDefinition> _fields;

  /// Returns a field definition for the given name, creating one if needed.
  FieldDefinition fieldFor(String name) {
    final existing = _fields[name];
    if (existing != null) {
      return existing;
    }
    final definition = FieldDefinition(
      name: name,
      columnName: name,
      dartType: 'Object?',
      resolvedType: 'Object?',
      isPrimaryKey: false,
      isNullable: true,
    );
    _registerField(definition, name);
    return definition;
  }

  /// Registers a column definition for this ad-hoc model.
  void registerColumn(AdHocColumn column) {
    final definition = FieldDefinition(
      name: column.name,
      columnName: column.columnName ?? column.name,
      dartType: column.dartType ?? 'Object?',
      resolvedType: column.resolvedType ?? column.dartType ?? 'Object?',
      isPrimaryKey: column.isPrimaryKey,
      isNullable: column.isNullable,
      columnType: column.columnType,
      defaultValueSql: column.defaultValueSql,
    );
    _registerField(definition, column.name);
    if (column.columnName != null && column.columnName != column.name) {
      _fields[column.columnName!] = definition;
    }
  }

  void _registerField(FieldDefinition field, String key) {
    _fields[key] = field;
  }
}

/// Column definition for ad-hoc queries.
class AdHocColumn {
  const AdHocColumn({
    required this.name,
    this.columnName,
    this.dartType,
    this.resolvedType,
    this.columnType,
    this.defaultValueSql,
    this.isNullable = true,
    this.isPrimaryKey = false,
  });

  /// The column name or alias.
  final String name;

  /// The actual database column name if different from name.
  final String? columnName;

  /// Dart type hint.
  final String? dartType;

  /// Resolved type after transformations.
  final String? resolvedType;

  /// SQL column type.
  final String? columnType;

  /// SQL default value expression.
  final String? defaultValueSql;

  /// Whether this column can be null.
  final bool isNullable;

  /// Whether this column is a primary key.
  final bool isPrimaryKey;
}

class _MapModelCodec extends ModelCodec<AdHocRow> {
  const _MapModelCodec();

  @override
  Map<String, Object?> encode(AdHocRow model, ValueCodecRegistry registry) =>
      Map<String, Object?>.from(model);

  @override
  AdHocRow decode(Map<String, Object?> data, ValueCodecRegistry registry) =>
      AdHocRow(data);
}

/// A wrapper definition that uses an underlying registered model definition
/// but returns `Map<String, Object?>` for table() queries.
///
/// This allows `table("tableName")` to leverage the field metadata from
/// registered models while still returning untyped maps.
class TableQueryDefinition<T extends OrmEntity>
    extends ModelDefinition<AdHocRow> {
  TableQueryDefinition({required this.underlying, String? schema, this.alias})
    : super(
        modelName: 'TableQuery<${underlying.tableName}>',
        tableName: underlying.tableName,
        schema: schema ?? underlying.schema,
        fields: underlying.fields,
        relations: underlying.relations,
        softDeleteColumn: underlying.softDeleteColumn,
        metadata: underlying.metadata,
        codec: _TableQueryCodec<T>(underlying),
      );

  /// The underlying registered model definition.
  final ModelDefinition<T> underlying;

  /// Optional table alias.
  final String? alias;

  @override
  FieldDefinition? get primaryKeyField => underlying.primaryKeyField;
}

/// Codec for _TableQueryDefinition that encodes/decodes using the underlying
/// model's codec but returns [Map<String, Object?>].
class _TableQueryCodec<T extends OrmEntity> extends ModelCodec<AdHocRow> {
  const _TableQueryCodec(this.underlying);

  final ModelDefinition<T> underlying;

  @override
  Map<String, Object?> encode(AdHocRow model, ValueCodecRegistry registry) {
    // Encode using field definitions for proper value transformation
    final result = <String, Object?>{};
    for (final field in underlying.fields) {
      final key = field.columnName;
      if (model.containsKey(key)) {
        result[key] = registry.encodeField(field, model[key]);
      } else if (model.containsKey(field.name)) {
        // Also check by property name
        result[key] = registry.encodeField(field, model[field.name]);
      }
    }
    return result;
  }

  @override
  AdHocRow decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    // Decode using field definitions for proper value transformation
    final result = <String, Object?>{};
    for (final field in underlying.fields) {
      final key = field.columnName;
      if (data.containsKey(key)) {
        result[key] = registry.decodeField(field, data[key]);
      }
    }
    // Also include any extra columns not in the definition
    for (final entry in data.entries) {
      if (!result.containsKey(entry.key)) {
        result[entry.key] = entry.value;
      }
    }
    return AdHocRow(result);
  }
}
