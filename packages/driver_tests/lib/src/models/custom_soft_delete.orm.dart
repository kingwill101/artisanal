// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'custom_soft_delete.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$CustomSoftDeleteIdField = FieldDefinition(
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

const FieldDefinition _$CustomSoftDeleteTitleField = FieldDefinition(
  name: 'title',
  columnName: 'title',
  dartType: 'String',
  resolvedType: 'String',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$CustomSoftDeleteDeletedAtField = FieldDefinition(
  name: 'deletedAt',
  columnName: 'removed_on',
  dartType: 'DateTime',
  resolvedType: 'DateTime?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

Map<String, Object?> _encodeCustomSoftDeleteUntracked(
  Object model,
  ValueCodecRegistry registry,
) {
  final m = model as CustomSoftDelete;
  return <String, Object?>{
    'id': registry.encodeField(_$CustomSoftDeleteIdField, m.id),
    'title': registry.encodeField(_$CustomSoftDeleteTitleField, m.title),
  };
}

final ModelDefinition<$CustomSoftDelete> _$CustomSoftDeleteDefinition =
    ModelDefinition(
      modelName: 'CustomSoftDelete',
      tableName: 'custom_soft_delete_models',
      fields: const [
        _$CustomSoftDeleteIdField,
        _$CustomSoftDeleteTitleField,
        _$CustomSoftDeleteDeletedAtField,
      ],
      relations: const [],
      softDeleteColumn: 'removed_on',
      metadata: ModelAttributesMetadata(
        hidden: const <String>[],
        visible: const <String>[],
        fillable: const <String>[],
        guarded: const <String>[],
        casts: const <String, String>{},
        appends: const <String>[],
        touches: const <String>[],
        timestamps: true,
        softDeletes: true,
        softDeleteColumn: 'removed_on',
      ),
      untrackedToMap: _encodeCustomSoftDeleteUntracked,
      codec: _$CustomSoftDeleteCodec(),
    );

// ignore: unused_element
final customsoftdeleteModelDefinitionRegistration =
    ModelFactoryRegistry.register<$CustomSoftDelete>(
      _$CustomSoftDeleteDefinition,
    );

extension CustomSoftDeleteOrmDefinition on CustomSoftDelete {
  static ModelDefinition<$CustomSoftDelete> get definition =>
      _$CustomSoftDeleteDefinition;
}

class CustomSoftDeletes {
  const CustomSoftDeletes._();

  /// Starts building a query for [$CustomSoftDelete].
  ///
  /// {@macro ormed.query}
  static Query<$CustomSoftDelete> query([String? connection]) =>
      Model.query<$CustomSoftDelete>(connection: connection);

  static Future<$CustomSoftDelete?> find(Object id, {String? connection}) =>
      Model.find<$CustomSoftDelete>(id, connection: connection);

  static Future<$CustomSoftDelete> findOrFail(
    Object id, {
    String? connection,
  }) => Model.findOrFail<$CustomSoftDelete>(id, connection: connection);

  static Future<List<$CustomSoftDelete>> all({String? connection}) =>
      Model.all<$CustomSoftDelete>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<$CustomSoftDelete>(connection: connection);

  static Future<bool> anyExist({String? connection}) =>
      Model.anyExist<$CustomSoftDelete>(connection: connection);

  static Query<$CustomSoftDelete> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) => Model.where<$CustomSoftDelete>(
    column,
    operator,
    value,
    connection: connection,
  );

  static Query<$CustomSoftDelete> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) =>
      Model.whereIn<$CustomSoftDelete>(column, values, connection: connection);

  static Query<$CustomSoftDelete> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<$CustomSoftDelete>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<$CustomSoftDelete> limit(int count, {String? connection}) =>
      Model.limit<$CustomSoftDelete>(count, connection: connection);

  /// Creates a [Repository] for [$CustomSoftDelete].
  ///
  /// {@macro ormed.repository}
  static Repository<$CustomSoftDelete> repo([String? connection]) =>
      Model.repository<$CustomSoftDelete>(connection: connection);

  /// Builds a tracked model from a column/value map.
  static $CustomSoftDelete fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$CustomSoftDeleteDefinition.fromMap(data, registry: registry);

  /// Converts a tracked model to a column/value map.
  static Map<String, Object?> toMap(
    $CustomSoftDelete model, {
    ValueCodecRegistry? registry,
  }) => _$CustomSoftDeleteDefinition.toMap(model, registry: registry);
}

class CustomSoftDeleteModelFactory {
  const CustomSoftDeleteModelFactory._();

  static ModelDefinition<$CustomSoftDelete> get definition =>
      _$CustomSoftDeleteDefinition;

  static ModelCodec<$CustomSoftDelete> get codec => definition.codec;

  static CustomSoftDelete fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    CustomSoftDelete model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model.toTracked(), registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<CustomSoftDelete> withConnection(
    QueryContext context,
  ) => ModelFactoryConnection<CustomSoftDelete>(
    definition: definition,
    context: context,
  );

  static ModelFactoryBuilder<CustomSoftDelete> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<CustomSoftDelete>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$CustomSoftDeleteCodec extends ModelCodec<$CustomSoftDelete> {
  const _$CustomSoftDeleteCodec();
  @override
  Map<String, Object?> encode(
    $CustomSoftDelete model,
    ValueCodecRegistry registry,
  ) {
    return <String, Object?>{
      'id': registry.encodeField(_$CustomSoftDeleteIdField, model.id),
      'title': registry.encodeField(_$CustomSoftDeleteTitleField, model.title),
      if (model.hasAttribute('removed_on'))
        'removed_on': registry.encodeField(
          _$CustomSoftDeleteDeletedAtField,
          model.getAttribute<DateTime?>('removed_on'),
        ),
    };
  }

  @override
  $CustomSoftDelete decode(
    Map<String, Object?> data,
    ValueCodecRegistry registry,
  ) {
    final int customSoftDeleteIdValue =
        registry.decodeField<int>(_$CustomSoftDeleteIdField, data['id']) ??
        (throw StateError('Field id on CustomSoftDelete cannot be null.'));
    final String customSoftDeleteTitleValue =
        registry.decodeField<String>(
          _$CustomSoftDeleteTitleField,
          data['title'],
        ) ??
        (throw StateError('Field title on CustomSoftDelete cannot be null.'));
    final DateTime? customSoftDeleteDeletedAtValue = registry
        .decodeField<DateTime?>(
          _$CustomSoftDeleteDeletedAtField,
          data['removed_on'],
        );
    final model = $CustomSoftDelete(
      id: customSoftDeleteIdValue,
      title: customSoftDeleteTitleValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': customSoftDeleteIdValue,
      'title': customSoftDeleteTitleValue,
      if (data.containsKey('removed_on'))
        'removed_on': customSoftDeleteDeletedAtValue,
    });
    return model;
  }
}

/// Insert DTO for [CustomSoftDelete].
///
/// Auto-increment/DB-generated fields are omitted by default.
class CustomSoftDeleteInsertDto implements InsertDto<$CustomSoftDelete> {
  const CustomSoftDeleteInsertDto({this.id, this.title});
  final int? id;
  final String? title;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (title != null) 'title': title,
    };
  }

  static const _CustomSoftDeleteInsertDtoCopyWithSentinel _copyWithSentinel =
      _CustomSoftDeleteInsertDtoCopyWithSentinel();
  CustomSoftDeleteInsertDto copyWith({
    Object? id = _copyWithSentinel,
    Object? title = _copyWithSentinel,
  }) {
    return CustomSoftDeleteInsertDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      title: identical(title, _copyWithSentinel)
          ? this.title
          : title as String?,
    );
  }
}

class _CustomSoftDeleteInsertDtoCopyWithSentinel {
  const _CustomSoftDeleteInsertDtoCopyWithSentinel();
}

/// Update DTO for [CustomSoftDelete].
///
/// All fields are optional; only provided entries are used in SET clauses.
class CustomSoftDeleteUpdateDto implements UpdateDto<$CustomSoftDelete> {
  const CustomSoftDeleteUpdateDto({this.id, this.title});
  final int? id;
  final String? title;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (title != null) 'title': title,
    };
  }

  static const _CustomSoftDeleteUpdateDtoCopyWithSentinel _copyWithSentinel =
      _CustomSoftDeleteUpdateDtoCopyWithSentinel();
  CustomSoftDeleteUpdateDto copyWith({
    Object? id = _copyWithSentinel,
    Object? title = _copyWithSentinel,
  }) {
    return CustomSoftDeleteUpdateDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      title: identical(title, _copyWithSentinel)
          ? this.title
          : title as String?,
    );
  }
}

class _CustomSoftDeleteUpdateDtoCopyWithSentinel {
  const _CustomSoftDeleteUpdateDtoCopyWithSentinel();
}

/// Partial projection for [CustomSoftDelete].
///
/// All fields are nullable; intended for subset SELECTs.
class CustomSoftDeletePartial implements PartialEntity<$CustomSoftDelete> {
  const CustomSoftDeletePartial({this.id, this.title});

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory CustomSoftDeletePartial.fromRow(Map<String, Object?> row) {
    return CustomSoftDeletePartial(
      id: row['id'] as int?,
      title: row['title'] as String?,
    );
  }

  final int? id;
  final String? title;

  @override
  $CustomSoftDelete toEntity() {
    // Basic required-field check: non-nullable fields must be present.
    final int? idValue = id;
    if (idValue == null) {
      throw StateError('Missing required field: id');
    }
    final String? titleValue = title;
    if (titleValue == null) {
      throw StateError('Missing required field: title');
    }
    return $CustomSoftDelete(id: idValue, title: titleValue);
  }

  @override
  Map<String, Object?> toMap() {
    return {if (id != null) 'id': id, if (title != null) 'title': title};
  }

  static const _CustomSoftDeletePartialCopyWithSentinel _copyWithSentinel =
      _CustomSoftDeletePartialCopyWithSentinel();
  CustomSoftDeletePartial copyWith({
    Object? id = _copyWithSentinel,
    Object? title = _copyWithSentinel,
  }) {
    return CustomSoftDeletePartial(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      title: identical(title, _copyWithSentinel)
          ? this.title
          : title as String?,
    );
  }
}

class _CustomSoftDeletePartialCopyWithSentinel {
  const _CustomSoftDeletePartialCopyWithSentinel();
}

/// Generated tracked model class for [CustomSoftDelete].
///
/// This class extends the user-defined [CustomSoftDelete] model and adds
/// attribute tracking, change detection, and relationship management.
/// Instances of this class are returned by queries and repositories.
///
/// **Do not instantiate this class directly.** Use queries, repositories,
/// or model factories to create tracked model instances.
class $CustomSoftDelete extends CustomSoftDelete
    with ModelAttributes, SoftDeletesImpl
    implements OrmEntity {
  /// Internal constructor for [$CustomSoftDelete].
  $CustomSoftDelete({required int id, required String title})
    : super.new(id: id, title: title) {
    _attachOrmRuntimeMetadata({'id': id, 'title': title});
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $CustomSoftDelete.fromModel(CustomSoftDelete model) {
    return $CustomSoftDelete(id: model.id, title: model.title);
  }

  $CustomSoftDelete copyWith({int? id, String? title}) {
    return $CustomSoftDelete(id: id ?? this.id, title: title ?? this.title);
  }

  /// Builds a tracked model from a column/value map.
  static $CustomSoftDelete fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$CustomSoftDeleteDefinition.fromMap(data, registry: registry);

  /// Converts this tracked model to a column/value map.
  Map<String, Object?> toMap({ValueCodecRegistry? registry}) =>
      _$CustomSoftDeleteDefinition.toMap(this, registry: registry);

  /// Tracked getter for [id].
  @override
  int get id => getAttribute<int>('id') ?? super.id;

  /// Tracked setter for [id].
  set id(int value) => setAttribute('id', value);

  /// Tracked getter for [title].
  @override
  String get title => getAttribute<String>('title') ?? super.title;

  /// Tracked setter for [title].
  set title(String value) => setAttribute('title', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$CustomSoftDeleteDefinition);
    attachSoftDeleteColumn('removed_on');
  }
}

class _CustomSoftDeleteCopyWithSentinel {
  const _CustomSoftDeleteCopyWithSentinel();
}

extension CustomSoftDeleteOrmExtension on CustomSoftDelete {
  static const _CustomSoftDeleteCopyWithSentinel _copyWithSentinel =
      _CustomSoftDeleteCopyWithSentinel();
  CustomSoftDelete copyWith({
    Object? id = _copyWithSentinel,
    Object? title = _copyWithSentinel,
  }) {
    return CustomSoftDelete(
      id: identical(id, _copyWithSentinel) ? this.id : id as int,
      title: identical(title, _copyWithSentinel) ? this.title : title as String,
    );
  }

  /// Converts this model to a column/value map.
  Map<String, Object?> toMap({ValueCodecRegistry? registry}) =>
      _$CustomSoftDeleteDefinition.toMap(this, registry: registry);

  /// Builds a model from a column/value map.
  static CustomSoftDelete fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$CustomSoftDeleteDefinition.fromMap(data, registry: registry);

  /// The Type of the generated ORM-managed model class.
  /// Use this when you need to specify the tracked model type explicitly,
  /// for example in generic type parameters.
  static Type get trackedType => $CustomSoftDelete;

  /// Converts this immutable model to a tracked ORM-managed model.
  /// The tracked model supports attribute tracking, change detection,
  /// and persistence operations like save() and touch().
  $CustomSoftDelete toTracked() {
    return $CustomSoftDelete.fromModel(this);
  }
}

extension CustomSoftDeletePredicateFields
    on PredicateBuilder<CustomSoftDelete> {
  PredicateField<CustomSoftDelete, int> get id =>
      PredicateField<CustomSoftDelete, int>(this, 'id');
  PredicateField<CustomSoftDelete, String> get title =>
      PredicateField<CustomSoftDelete, String>(this, 'title');
}

void registerCustomSoftDeleteEventHandlers(EventBus bus) {
  // No event handlers registered for CustomSoftDelete.
}
