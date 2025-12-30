// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'nullable_relations_test.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$NullableRelationsTestIdField = FieldDefinition(
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

const FieldDefinition _$NullableRelationsTestNameField = FieldDefinition(
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

const RelationDefinition _$NullableRelationsTestNullableFieldCommentsRelation =
    RelationDefinition(
      name: 'nullableFieldComments',
      kind: RelationKind.hasMany,
      targetModel: 'Comment',
      foreignKey: 'parent_id',
      localKey: 'id',
    );

const RelationDefinition
_$NullableRelationsTestNonNullableFieldCommentsRelation = RelationDefinition(
  name: 'nonNullableFieldComments',
  kind: RelationKind.hasMany,
  targetModel: 'Comment',
  foreignKey: 'other_parent_id',
  localKey: 'id',
);

Map<String, Object?> _encodeNullableRelationsTestUntracked(
  Object model,
  ValueCodecRegistry registry,
) {
  final m = model as NullableRelationsTest;
  return <String, Object?>{
    'id': registry.encodeField(_$NullableRelationsTestIdField, m.id),
    'name': registry.encodeField(_$NullableRelationsTestNameField, m.name),
  };
}

final ModelDefinition<$NullableRelationsTest>
_$NullableRelationsTestDefinition = ModelDefinition(
  modelName: 'NullableRelationsTest',
  tableName: 'nullable_relations_test',
  fields: const [
    _$NullableRelationsTestIdField,
    _$NullableRelationsTestNameField,
  ],
  relations: const [
    _$NullableRelationsTestNullableFieldCommentsRelation,
    _$NullableRelationsTestNonNullableFieldCommentsRelation,
  ],
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
  untrackedToMap: _encodeNullableRelationsTestUntracked,
  codec: _$NullableRelationsTestCodec(),
);

// ignore: unused_element
final nullablerelationstestModelDefinitionRegistration =
    ModelFactoryRegistry.register<$NullableRelationsTest>(
      _$NullableRelationsTestDefinition,
    );

extension NullableRelationsTestOrmDefinition on NullableRelationsTest {
  static ModelDefinition<$NullableRelationsTest> get definition =>
      _$NullableRelationsTestDefinition;
}

class NullableRelationsTests {
  const NullableRelationsTests._();

  /// Starts building a query for [$NullableRelationsTest].
  ///
  /// {@macro ormed.query}
  static Query<$NullableRelationsTest> query([String? connection]) =>
      Model.query<$NullableRelationsTest>(connection: connection);

  static Future<$NullableRelationsTest?> find(
    Object id, {
    String? connection,
  }) => Model.find<$NullableRelationsTest>(id, connection: connection);

  static Future<$NullableRelationsTest> findOrFail(
    Object id, {
    String? connection,
  }) => Model.findOrFail<$NullableRelationsTest>(id, connection: connection);

  static Future<List<$NullableRelationsTest>> all({String? connection}) =>
      Model.all<$NullableRelationsTest>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<$NullableRelationsTest>(connection: connection);

  static Future<bool> anyExist({String? connection}) =>
      Model.anyExist<$NullableRelationsTest>(connection: connection);

  static Query<$NullableRelationsTest> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) => Model.where<$NullableRelationsTest>(
    column,
    operator,
    value,
    connection: connection,
  );

  static Query<$NullableRelationsTest> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<$NullableRelationsTest>(
    column,
    values,
    connection: connection,
  );

  static Query<$NullableRelationsTest> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<$NullableRelationsTest>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<$NullableRelationsTest> limit(int count, {String? connection}) =>
      Model.limit<$NullableRelationsTest>(count, connection: connection);

  /// Creates a [Repository] for [$NullableRelationsTest].
  ///
  /// {@macro ormed.repository}
  static Repository<$NullableRelationsTest> repo([String? connection]) =>
      Model.repository<$NullableRelationsTest>(connection: connection);

  /// Builds a tracked model from a column/value map.
  static $NullableRelationsTest fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$NullableRelationsTestDefinition.fromMap(data, registry: registry);

  /// Converts a tracked model to a column/value map.
  static Map<String, Object?> toMap(
    $NullableRelationsTest model, {
    ValueCodecRegistry? registry,
  }) => _$NullableRelationsTestDefinition.toMap(model, registry: registry);
}

class NullableRelationsTestModelFactory {
  const NullableRelationsTestModelFactory._();

  static ModelDefinition<$NullableRelationsTest> get definition =>
      _$NullableRelationsTestDefinition;

  static ModelCodec<$NullableRelationsTest> get codec => definition.codec;

  static NullableRelationsTest fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    NullableRelationsTest model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model.toTracked(), registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<NullableRelationsTest> withConnection(
    QueryContext context,
  ) => ModelFactoryConnection<NullableRelationsTest>(
    definition: definition,
    context: context,
  );

  static ModelFactoryBuilder<NullableRelationsTest> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<NullableRelationsTest>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$NullableRelationsTestCodec extends ModelCodec<$NullableRelationsTest> {
  const _$NullableRelationsTestCodec();
  @override
  Map<String, Object?> encode(
    $NullableRelationsTest model,
    ValueCodecRegistry registry,
  ) {
    return <String, Object?>{
      'id': registry.encodeField(_$NullableRelationsTestIdField, model.id),
      'name': registry.encodeField(
        _$NullableRelationsTestNameField,
        model.name,
      ),
    };
  }

  @override
  $NullableRelationsTest decode(
    Map<String, Object?> data,
    ValueCodecRegistry registry,
  ) {
    final int nullableRelationsTestIdValue =
        registry.decodeField<int>(_$NullableRelationsTestIdField, data['id']) ??
        0;
    final String nullableRelationsTestNameValue =
        registry.decodeField<String>(
          _$NullableRelationsTestNameField,
          data['name'],
        ) ??
        (throw StateError(
          'Field name on NullableRelationsTest cannot be null.',
        ));
    final model = $NullableRelationsTest(
      id: nullableRelationsTestIdValue,
      name: nullableRelationsTestNameValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': nullableRelationsTestIdValue,
      'name': nullableRelationsTestNameValue,
    });
    return model;
  }
}

/// Insert DTO for [NullableRelationsTest].
///
/// Auto-increment/DB-generated fields are omitted by default.
class NullableRelationsTestInsertDto
    implements InsertDto<$NullableRelationsTest> {
  const NullableRelationsTestInsertDto({this.name});
  final String? name;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{if (name != null) 'name': name};
  }

  static const _NullableRelationsTestInsertDtoCopyWithSentinel
  _copyWithSentinel = _NullableRelationsTestInsertDtoCopyWithSentinel();
  NullableRelationsTestInsertDto copyWith({Object? name = _copyWithSentinel}) {
    return NullableRelationsTestInsertDto(
      name: identical(name, _copyWithSentinel) ? this.name : name as String?,
    );
  }
}

class _NullableRelationsTestInsertDtoCopyWithSentinel {
  const _NullableRelationsTestInsertDtoCopyWithSentinel();
}

/// Update DTO for [NullableRelationsTest].
///
/// All fields are optional; only provided entries are used in SET clauses.
class NullableRelationsTestUpdateDto
    implements UpdateDto<$NullableRelationsTest> {
  const NullableRelationsTestUpdateDto({this.id, this.name});
  final int? id;
  final String? name;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (name != null) 'name': name,
    };
  }

  static const _NullableRelationsTestUpdateDtoCopyWithSentinel
  _copyWithSentinel = _NullableRelationsTestUpdateDtoCopyWithSentinel();
  NullableRelationsTestUpdateDto copyWith({
    Object? id = _copyWithSentinel,
    Object? name = _copyWithSentinel,
  }) {
    return NullableRelationsTestUpdateDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      name: identical(name, _copyWithSentinel) ? this.name : name as String?,
    );
  }
}

class _NullableRelationsTestUpdateDtoCopyWithSentinel {
  const _NullableRelationsTestUpdateDtoCopyWithSentinel();
}

/// Partial projection for [NullableRelationsTest].
///
/// All fields are nullable; intended for subset SELECTs.
class NullableRelationsTestPartial
    implements PartialEntity<$NullableRelationsTest> {
  const NullableRelationsTestPartial({this.id, this.name});

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory NullableRelationsTestPartial.fromRow(Map<String, Object?> row) {
    return NullableRelationsTestPartial(
      id: row['id'] as int?,
      name: row['name'] as String?,
    );
  }

  final int? id;
  final String? name;

  @override
  $NullableRelationsTest toEntity() {
    // Basic required-field check: non-nullable fields must be present.
    final int? idValue = id;
    if (idValue == null) {
      throw StateError('Missing required field: id');
    }
    final String? nameValue = name;
    if (nameValue == null) {
      throw StateError('Missing required field: name');
    }
    return $NullableRelationsTest(id: idValue, name: nameValue);
  }

  @override
  Map<String, Object?> toMap() {
    return {if (id != null) 'id': id, if (name != null) 'name': name};
  }

  static const _NullableRelationsTestPartialCopyWithSentinel _copyWithSentinel =
      _NullableRelationsTestPartialCopyWithSentinel();
  NullableRelationsTestPartial copyWith({
    Object? id = _copyWithSentinel,
    Object? name = _copyWithSentinel,
  }) {
    return NullableRelationsTestPartial(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      name: identical(name, _copyWithSentinel) ? this.name : name as String?,
    );
  }
}

class _NullableRelationsTestPartialCopyWithSentinel {
  const _NullableRelationsTestPartialCopyWithSentinel();
}

/// Generated tracked model class for [NullableRelationsTest].
///
/// This class extends the user-defined [NullableRelationsTest] model and adds
/// attribute tracking, change detection, and relationship management.
/// Instances of this class are returned by queries and repositories.
///
/// **Do not instantiate this class directly.** Use queries, repositories,
/// or model factories to create tracked model instances.
class $NullableRelationsTest extends NullableRelationsTest
    with ModelAttributes
    implements OrmEntity {
  /// Internal constructor for [$NullableRelationsTest].
  $NullableRelationsTest({int id = 0, required String name})
    : super.new(id: id, name: name) {
    _attachOrmRuntimeMetadata({'id': id, 'name': name});
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $NullableRelationsTest.fromModel(NullableRelationsTest model) {
    return $NullableRelationsTest(id: model.id, name: model.name);
  }

  $NullableRelationsTest copyWith({int? id, String? name}) {
    return $NullableRelationsTest(id: id ?? this.id, name: name ?? this.name);
  }

  /// Builds a tracked model from a column/value map.
  static $NullableRelationsTest fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$NullableRelationsTestDefinition.fromMap(data, registry: registry);

  /// Converts this tracked model to a column/value map.
  Map<String, Object?> toMap({ValueCodecRegistry? registry}) =>
      _$NullableRelationsTestDefinition.toMap(this, registry: registry);

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

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$NullableRelationsTestDefinition);
  }

  @override
  List<Comment> get nullableFieldComments {
    if (relationLoaded('nullableFieldComments')) {
      return getRelationList<Comment>('nullableFieldComments');
    }
    return super.nullableFieldComments ?? const [];
  }

  @override
  List<Comment> get nonNullableFieldComments {
    if (relationLoaded('nonNullableFieldComments')) {
      return getRelationList<Comment>('nonNullableFieldComments');
    }
    return super.nonNullableFieldComments;
  }
}

extension NullableRelationsTestRelationQueries on NullableRelationsTest {
  Query<Comment> nullableFieldCommentsQuery() {
    return Model.query<Comment>().where('parent_id', id);
  }

  Query<Comment> nonNullableFieldCommentsQuery() {
    return Model.query<Comment>().where('other_parent_id', id);
  }
}

class _NullableRelationsTestCopyWithSentinel {
  const _NullableRelationsTestCopyWithSentinel();
}

extension NullableRelationsTestOrmExtension on NullableRelationsTest {
  static const _NullableRelationsTestCopyWithSentinel _copyWithSentinel =
      _NullableRelationsTestCopyWithSentinel();
  NullableRelationsTest copyWith({
    Object? id = _copyWithSentinel,
    Object? name = _copyWithSentinel,
  }) {
    return NullableRelationsTest.new(
      id: identical(id, _copyWithSentinel) ? this.id : id as int,
      name: identical(name, _copyWithSentinel) ? this.name : name as String,
    );
  }

  /// Converts this model to a column/value map.
  Map<String, Object?> toMap({ValueCodecRegistry? registry}) =>
      _$NullableRelationsTestDefinition.toMap(this, registry: registry);

  /// Builds a model from a column/value map.
  static NullableRelationsTest fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$NullableRelationsTestDefinition.fromMap(data, registry: registry);

  /// The Type of the generated ORM-managed model class.
  /// Use this when you need to specify the tracked model type explicitly,
  /// for example in generic type parameters.
  static Type get trackedType => $NullableRelationsTest;

  /// Converts this immutable model to a tracked ORM-managed model.
  /// The tracked model supports attribute tracking, change detection,
  /// and persistence operations like save() and touch().
  $NullableRelationsTest toTracked() {
    return $NullableRelationsTest.fromModel(this);
  }
}

extension NullableRelationsTestPredicateFields
    on PredicateBuilder<NullableRelationsTest> {
  PredicateField<NullableRelationsTest, int> get id =>
      PredicateField<NullableRelationsTest, int>(this, 'id');
  PredicateField<NullableRelationsTest, String> get name =>
      PredicateField<NullableRelationsTest, String>(this, 'name');
}

extension NullableRelationsTestTypedRelations on Query<NullableRelationsTest> {
  Query<NullableRelationsTest> withNullableFieldComments([
    PredicateCallback<Comment>? constraint,
  ]) => withRelationTyped('nullableFieldComments', constraint);
  Query<NullableRelationsTest> whereHasNullableFieldComments([
    PredicateCallback<Comment>? constraint,
  ]) => whereHasTyped('nullableFieldComments', constraint);
  Query<NullableRelationsTest> orWhereHasNullableFieldComments([
    PredicateCallback<Comment>? constraint,
  ]) => orWhereHasTyped('nullableFieldComments', constraint);
  Query<NullableRelationsTest> withNonNullableFieldComments([
    PredicateCallback<Comment>? constraint,
  ]) => withRelationTyped('nonNullableFieldComments', constraint);
  Query<NullableRelationsTest> whereHasNonNullableFieldComments([
    PredicateCallback<Comment>? constraint,
  ]) => whereHasTyped('nonNullableFieldComments', constraint);
  Query<NullableRelationsTest> orWhereHasNonNullableFieldComments([
    PredicateCallback<Comment>? constraint,
  ]) => orWhereHasTyped('nonNullableFieldComments', constraint);
}

void registerNullableRelationsTestEventHandlers(EventBus bus) {
  // No event handlers registered for NullableRelationsTest.
}
