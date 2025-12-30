// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'taggable.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$TaggableTagIdField = FieldDefinition(
  name: 'tagId',
  columnName: 'tag_id',
  dartType: 'int',
  resolvedType: 'int',
  isPrimaryKey: true,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$TaggableTaggableIdField = FieldDefinition(
  name: 'taggableId',
  columnName: 'taggable_id',
  dartType: 'int',
  resolvedType: 'int',
  isPrimaryKey: true,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$TaggableTaggableTypeField = FieldDefinition(
  name: 'taggableType',
  columnName: 'taggable_type',
  dartType: 'String',
  resolvedType: 'String',
  isPrimaryKey: true,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

Map<String, Object?> _encodeTaggableUntracked(
  Object model,
  ValueCodecRegistry registry,
) {
  final m = model as Taggable;
  return <String, Object?>{
    'tag_id': registry.encodeField(_$TaggableTagIdField, m.tagId),
    'taggable_id': registry.encodeField(
      _$TaggableTaggableIdField,
      m.taggableId,
    ),
    'taggable_type': registry.encodeField(
      _$TaggableTaggableTypeField,
      m.taggableType,
    ),
  };
}

final ModelDefinition<$Taggable> _$TaggableDefinition = ModelDefinition(
  modelName: 'Taggable',
  tableName: 'taggables',
  fields: const [
    _$TaggableTagIdField,
    _$TaggableTaggableIdField,
    _$TaggableTaggableTypeField,
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
  untrackedToMap: _encodeTaggableUntracked,
  codec: _$TaggableCodec(),
);

// ignore: unused_element
final taggableModelDefinitionRegistration =
    ModelFactoryRegistry.register<$Taggable>(_$TaggableDefinition);

extension TaggableOrmDefinition on Taggable {
  static ModelDefinition<$Taggable> get definition => _$TaggableDefinition;
}

class Taggables {
  const Taggables._();

  /// Starts building a query for [$Taggable].
  ///
  /// {@macro ormed.query}
  static Query<$Taggable> query([String? connection]) =>
      Model.query<$Taggable>(connection: connection);

  static Future<$Taggable?> find(Object id, {String? connection}) =>
      Model.find<$Taggable>(id, connection: connection);

  static Future<$Taggable> findOrFail(Object id, {String? connection}) =>
      Model.findOrFail<$Taggable>(id, connection: connection);

  static Future<List<$Taggable>> all({String? connection}) =>
      Model.all<$Taggable>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<$Taggable>(connection: connection);

  static Future<bool> anyExist({String? connection}) =>
      Model.anyExist<$Taggable>(connection: connection);

  static Query<$Taggable> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) => Model.where<$Taggable>(column, operator, value, connection: connection);

  static Query<$Taggable> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<$Taggable>(column, values, connection: connection);

  static Query<$Taggable> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<$Taggable>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<$Taggable> limit(int count, {String? connection}) =>
      Model.limit<$Taggable>(count, connection: connection);

  /// Creates a [Repository] for [$Taggable].
  ///
  /// {@macro ormed.repository}
  static Repository<$Taggable> repo([String? connection]) =>
      Model.repository<$Taggable>(connection: connection);

  /// Builds a tracked model from a column/value map.
  static $Taggable fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$TaggableDefinition.fromMap(data, registry: registry);

  /// Converts a tracked model to a column/value map.
  static Map<String, Object?> toMap(
    $Taggable model, {
    ValueCodecRegistry? registry,
  }) => _$TaggableDefinition.toMap(model, registry: registry);
}

class TaggableModelFactory {
  const TaggableModelFactory._();

  static ModelDefinition<$Taggable> get definition => _$TaggableDefinition;

  static ModelCodec<$Taggable> get codec => definition.codec;

  static Taggable fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    Taggable model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model.toTracked(), registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<Taggable> withConnection(
    QueryContext context,
  ) => ModelFactoryConnection<Taggable>(
    definition: definition,
    context: context,
  );

  static ModelFactoryBuilder<Taggable> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<Taggable>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$TaggableCodec extends ModelCodec<$Taggable> {
  const _$TaggableCodec();
  @override
  Map<String, Object?> encode($Taggable model, ValueCodecRegistry registry) {
    return <String, Object?>{
      'tag_id': registry.encodeField(_$TaggableTagIdField, model.tagId),
      'taggable_id': registry.encodeField(
        _$TaggableTaggableIdField,
        model.taggableId,
      ),
      'taggable_type': registry.encodeField(
        _$TaggableTaggableTypeField,
        model.taggableType,
      ),
    };
  }

  @override
  $Taggable decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final int taggableTagIdValue =
        registry.decodeField<int>(_$TaggableTagIdField, data['tag_id']) ??
        (throw StateError('Field tagId on Taggable cannot be null.'));
    final int taggableTaggableIdValue =
        registry.decodeField<int>(
          _$TaggableTaggableIdField,
          data['taggable_id'],
        ) ??
        (throw StateError('Field taggableId on Taggable cannot be null.'));
    final String taggableTaggableTypeValue =
        registry.decodeField<String>(
          _$TaggableTaggableTypeField,
          data['taggable_type'],
        ) ??
        (throw StateError('Field taggableType on Taggable cannot be null.'));
    final model = $Taggable(
      tagId: taggableTagIdValue,
      taggableId: taggableTaggableIdValue,
      taggableType: taggableTaggableTypeValue,
    );
    model._attachOrmRuntimeMetadata({
      'tag_id': taggableTagIdValue,
      'taggable_id': taggableTaggableIdValue,
      'taggable_type': taggableTaggableTypeValue,
    });
    return model;
  }
}

/// Insert DTO for [Taggable].
///
/// Auto-increment/DB-generated fields are omitted by default.
class TaggableInsertDto implements InsertDto<$Taggable> {
  const TaggableInsertDto({this.tagId, this.taggableId, this.taggableType});
  final int? tagId;
  final int? taggableId;
  final String? taggableType;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (tagId != null) 'tag_id': tagId,
      if (taggableId != null) 'taggable_id': taggableId,
      if (taggableType != null) 'taggable_type': taggableType,
    };
  }

  static const _TaggableInsertDtoCopyWithSentinel _copyWithSentinel =
      _TaggableInsertDtoCopyWithSentinel();
  TaggableInsertDto copyWith({
    Object? tagId = _copyWithSentinel,
    Object? taggableId = _copyWithSentinel,
    Object? taggableType = _copyWithSentinel,
  }) {
    return TaggableInsertDto(
      tagId: identical(tagId, _copyWithSentinel) ? this.tagId : tagId as int?,
      taggableId: identical(taggableId, _copyWithSentinel)
          ? this.taggableId
          : taggableId as int?,
      taggableType: identical(taggableType, _copyWithSentinel)
          ? this.taggableType
          : taggableType as String?,
    );
  }
}

class _TaggableInsertDtoCopyWithSentinel {
  const _TaggableInsertDtoCopyWithSentinel();
}

/// Update DTO for [Taggable].
///
/// All fields are optional; only provided entries are used in SET clauses.
class TaggableUpdateDto implements UpdateDto<$Taggable> {
  const TaggableUpdateDto({this.tagId, this.taggableId, this.taggableType});
  final int? tagId;
  final int? taggableId;
  final String? taggableType;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (tagId != null) 'tag_id': tagId,
      if (taggableId != null) 'taggable_id': taggableId,
      if (taggableType != null) 'taggable_type': taggableType,
    };
  }

  static const _TaggableUpdateDtoCopyWithSentinel _copyWithSentinel =
      _TaggableUpdateDtoCopyWithSentinel();
  TaggableUpdateDto copyWith({
    Object? tagId = _copyWithSentinel,
    Object? taggableId = _copyWithSentinel,
    Object? taggableType = _copyWithSentinel,
  }) {
    return TaggableUpdateDto(
      tagId: identical(tagId, _copyWithSentinel) ? this.tagId : tagId as int?,
      taggableId: identical(taggableId, _copyWithSentinel)
          ? this.taggableId
          : taggableId as int?,
      taggableType: identical(taggableType, _copyWithSentinel)
          ? this.taggableType
          : taggableType as String?,
    );
  }
}

class _TaggableUpdateDtoCopyWithSentinel {
  const _TaggableUpdateDtoCopyWithSentinel();
}

/// Partial projection for [Taggable].
///
/// All fields are nullable; intended for subset SELECTs.
class TaggablePartial implements PartialEntity<$Taggable> {
  const TaggablePartial({this.tagId, this.taggableId, this.taggableType});

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory TaggablePartial.fromRow(Map<String, Object?> row) {
    return TaggablePartial(
      tagId: row['tag_id'] as int?,
      taggableId: row['taggable_id'] as int?,
      taggableType: row['taggable_type'] as String?,
    );
  }

  final int? tagId;
  final int? taggableId;
  final String? taggableType;

  @override
  $Taggable toEntity() {
    // Basic required-field check: non-nullable fields must be present.
    final int? tagIdValue = tagId;
    if (tagIdValue == null) {
      throw StateError('Missing required field: tagId');
    }
    final int? taggableIdValue = taggableId;
    if (taggableIdValue == null) {
      throw StateError('Missing required field: taggableId');
    }
    final String? taggableTypeValue = taggableType;
    if (taggableTypeValue == null) {
      throw StateError('Missing required field: taggableType');
    }
    return $Taggable(
      tagId: tagIdValue,
      taggableId: taggableIdValue,
      taggableType: taggableTypeValue,
    );
  }

  @override
  Map<String, Object?> toMap() {
    return {
      if (tagId != null) 'tag_id': tagId,
      if (taggableId != null) 'taggable_id': taggableId,
      if (taggableType != null) 'taggable_type': taggableType,
    };
  }

  static const _TaggablePartialCopyWithSentinel _copyWithSentinel =
      _TaggablePartialCopyWithSentinel();
  TaggablePartial copyWith({
    Object? tagId = _copyWithSentinel,
    Object? taggableId = _copyWithSentinel,
    Object? taggableType = _copyWithSentinel,
  }) {
    return TaggablePartial(
      tagId: identical(tagId, _copyWithSentinel) ? this.tagId : tagId as int?,
      taggableId: identical(taggableId, _copyWithSentinel)
          ? this.taggableId
          : taggableId as int?,
      taggableType: identical(taggableType, _copyWithSentinel)
          ? this.taggableType
          : taggableType as String?,
    );
  }
}

class _TaggablePartialCopyWithSentinel {
  const _TaggablePartialCopyWithSentinel();
}

/// Generated tracked model class for [Taggable].
///
/// This class extends the user-defined [Taggable] model and adds
/// attribute tracking, change detection, and relationship management.
/// Instances of this class are returned by queries and repositories.
///
/// **Do not instantiate this class directly.** Use queries, repositories,
/// or model factories to create tracked model instances.
class $Taggable extends Taggable with ModelAttributes implements OrmEntity {
  /// Internal constructor for [$Taggable].
  $Taggable({
    required int tagId,
    required int taggableId,
    required String taggableType,
  }) : super.new(
         tagId: tagId,
         taggableId: taggableId,
         taggableType: taggableType,
       ) {
    _attachOrmRuntimeMetadata({
      'tag_id': tagId,
      'taggable_id': taggableId,
      'taggable_type': taggableType,
    });
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $Taggable.fromModel(Taggable model) {
    return $Taggable(
      tagId: model.tagId,
      taggableId: model.taggableId,
      taggableType: model.taggableType,
    );
  }

  $Taggable copyWith({int? tagId, int? taggableId, String? taggableType}) {
    return $Taggable(
      tagId: tagId ?? this.tagId,
      taggableId: taggableId ?? this.taggableId,
      taggableType: taggableType ?? this.taggableType,
    );
  }

  /// Builds a tracked model from a column/value map.
  static $Taggable fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$TaggableDefinition.fromMap(data, registry: registry);

  /// Converts this tracked model to a column/value map.
  Map<String, Object?> toMap({ValueCodecRegistry? registry}) =>
      _$TaggableDefinition.toMap(this, registry: registry);

  /// Tracked getter for [tagId].
  @override
  int get tagId => getAttribute<int>('tag_id') ?? super.tagId;

  /// Tracked setter for [tagId].
  set tagId(int value) => setAttribute('tag_id', value);

  /// Tracked getter for [taggableId].
  @override
  int get taggableId => getAttribute<int>('taggable_id') ?? super.taggableId;

  /// Tracked setter for [taggableId].
  set taggableId(int value) => setAttribute('taggable_id', value);

  /// Tracked getter for [taggableType].
  @override
  String get taggableType =>
      getAttribute<String>('taggable_type') ?? super.taggableType;

  /// Tracked setter for [taggableType].
  set taggableType(String value) => setAttribute('taggable_type', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$TaggableDefinition);
  }
}

class _TaggableCopyWithSentinel {
  const _TaggableCopyWithSentinel();
}

extension TaggableOrmExtension on Taggable {
  static const _TaggableCopyWithSentinel _copyWithSentinel =
      _TaggableCopyWithSentinel();
  Taggable copyWith({
    Object? tagId = _copyWithSentinel,
    Object? taggableId = _copyWithSentinel,
    Object? taggableType = _copyWithSentinel,
  }) {
    return Taggable(
      tagId: identical(tagId, _copyWithSentinel) ? this.tagId : tagId as int,
      taggableId: identical(taggableId, _copyWithSentinel)
          ? this.taggableId
          : taggableId as int,
      taggableType: identical(taggableType, _copyWithSentinel)
          ? this.taggableType
          : taggableType as String,
    );
  }

  /// Converts this model to a column/value map.
  Map<String, Object?> toMap({ValueCodecRegistry? registry}) =>
      _$TaggableDefinition.toMap(this, registry: registry);

  /// Builds a model from a column/value map.
  static Taggable fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$TaggableDefinition.fromMap(data, registry: registry);

  /// The Type of the generated ORM-managed model class.
  /// Use this when you need to specify the tracked model type explicitly,
  /// for example in generic type parameters.
  static Type get trackedType => $Taggable;

  /// Converts this immutable model to a tracked ORM-managed model.
  /// The tracked model supports attribute tracking, change detection,
  /// and persistence operations like save() and touch().
  $Taggable toTracked() {
    return $Taggable.fromModel(this);
  }
}

extension TaggablePredicateFields on PredicateBuilder<Taggable> {
  PredicateField<Taggable, int> get tagId =>
      PredicateField<Taggable, int>(this, 'tagId');
  PredicateField<Taggable, int> get taggableId =>
      PredicateField<Taggable, int>(this, 'taggableId');
  PredicateField<Taggable, String> get taggableType =>
      PredicateField<Taggable, String>(this, 'taggableType');
}

void registerTaggableEventHandlers(EventBus bus) {
  // No event handlers registered for Taggable.
}
