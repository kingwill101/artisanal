// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'unique_user.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$UniqueUserIdField = FieldDefinition(
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

const FieldDefinition _$UniqueUserEmailField = FieldDefinition(
  name: 'email',
  columnName: 'email',
  dartType: 'String',
  resolvedType: 'String',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$UniqueUserActiveField = FieldDefinition(
  name: 'active',
  columnName: 'active',
  dartType: 'bool',
  resolvedType: 'bool',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

Map<String, Object?> _encodeUniqueUserUntracked(
  Object model,
  ValueCodecRegistry registry,
) {
  final m = model as UniqueUser;
  return <String, Object?>{
    'id': registry.encodeField(_$UniqueUserIdField, m.id),
    'email': registry.encodeField(_$UniqueUserEmailField, m.email),
    'active': registry.encodeField(_$UniqueUserActiveField, m.active),
  };
}

final ModelDefinition<$UniqueUser> _$UniqueUserDefinition = ModelDefinition(
  modelName: 'UniqueUser',
  tableName: 'unique_users',
  fields: const [
    _$UniqueUserIdField,
    _$UniqueUserEmailField,
    _$UniqueUserActiveField,
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
  untrackedToMap: _encodeUniqueUserUntracked,
  codec: _$UniqueUserCodec(),
);

// ignore: unused_element
final uniqueuserModelDefinitionRegistration =
    ModelFactoryRegistry.register<$UniqueUser>(_$UniqueUserDefinition);

extension UniqueUserOrmDefinition on UniqueUser {
  static ModelDefinition<$UniqueUser> get definition => _$UniqueUserDefinition;
}

class UniqueUsers {
  const UniqueUsers._();

  /// Starts building a query for [$UniqueUser].
  ///
  /// {@macro ormed.query}
  static Query<$UniqueUser> query([String? connection]) =>
      Model.query<$UniqueUser>(connection: connection);

  static Future<$UniqueUser?> find(Object id, {String? connection}) =>
      Model.find<$UniqueUser>(id, connection: connection);

  static Future<$UniqueUser> findOrFail(Object id, {String? connection}) =>
      Model.findOrFail<$UniqueUser>(id, connection: connection);

  static Future<List<$UniqueUser>> all({String? connection}) =>
      Model.all<$UniqueUser>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<$UniqueUser>(connection: connection);

  static Future<bool> anyExist({String? connection}) =>
      Model.anyExist<$UniqueUser>(connection: connection);

  static Query<$UniqueUser> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) =>
      Model.where<$UniqueUser>(column, operator, value, connection: connection);

  static Query<$UniqueUser> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<$UniqueUser>(column, values, connection: connection);

  static Query<$UniqueUser> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<$UniqueUser>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<$UniqueUser> limit(int count, {String? connection}) =>
      Model.limit<$UniqueUser>(count, connection: connection);

  /// Creates a [Repository] for [$UniqueUser].
  ///
  /// {@macro ormed.repository}
  static Repository<$UniqueUser> repo([String? connection]) =>
      Model.repository<$UniqueUser>(connection: connection);

  /// Builds a tracked model from a column/value map.
  static $UniqueUser fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$UniqueUserDefinition.fromMap(data, registry: registry);

  /// Converts a tracked model to a column/value map.
  static Map<String, Object?> toMap(
    $UniqueUser model, {
    ValueCodecRegistry? registry,
  }) => _$UniqueUserDefinition.toMap(model, registry: registry);
}

class UniqueUserModelFactory {
  const UniqueUserModelFactory._();

  static ModelDefinition<$UniqueUser> get definition => _$UniqueUserDefinition;

  static ModelCodec<$UniqueUser> get codec => definition.codec;

  static UniqueUser fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    UniqueUser model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model.toTracked(), registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<UniqueUser> withConnection(
    QueryContext context,
  ) => ModelFactoryConnection<UniqueUser>(
    definition: definition,
    context: context,
  );

  static ModelFactoryBuilder<UniqueUser> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<UniqueUser>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$UniqueUserCodec extends ModelCodec<$UniqueUser> {
  const _$UniqueUserCodec();
  @override
  Map<String, Object?> encode($UniqueUser model, ValueCodecRegistry registry) {
    return <String, Object?>{
      'id': registry.encodeField(_$UniqueUserIdField, model.id),
      'email': registry.encodeField(_$UniqueUserEmailField, model.email),
      'active': registry.encodeField(_$UniqueUserActiveField, model.active),
    };
  }

  @override
  $UniqueUser decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final int uniqueUserIdValue =
        registry.decodeField<int>(_$UniqueUserIdField, data['id']) ?? 0;
    final String uniqueUserEmailValue =
        registry.decodeField<String>(_$UniqueUserEmailField, data['email']) ??
        (throw StateError('Field email on UniqueUser cannot be null.'));
    final bool uniqueUserActiveValue =
        registry.decodeField<bool>(_$UniqueUserActiveField, data['active']) ??
        (throw StateError('Field active on UniqueUser cannot be null.'));
    final model = $UniqueUser(
      id: uniqueUserIdValue,
      email: uniqueUserEmailValue,
      active: uniqueUserActiveValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': uniqueUserIdValue,
      'email': uniqueUserEmailValue,
      'active': uniqueUserActiveValue,
    });
    return model;
  }
}

/// Insert DTO for [UniqueUser].
///
/// Auto-increment/DB-generated fields are omitted by default.
class UniqueUserInsertDto implements InsertDto<$UniqueUser> {
  const UniqueUserInsertDto({this.email, this.active});
  final String? email;
  final bool? active;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (email != null) 'email': email,
      if (active != null) 'active': active,
    };
  }

  static const _UniqueUserInsertDtoCopyWithSentinel _copyWithSentinel =
      _UniqueUserInsertDtoCopyWithSentinel();
  UniqueUserInsertDto copyWith({
    Object? email = _copyWithSentinel,
    Object? active = _copyWithSentinel,
  }) {
    return UniqueUserInsertDto(
      email: identical(email, _copyWithSentinel)
          ? this.email
          : email as String?,
      active: identical(active, _copyWithSentinel)
          ? this.active
          : active as bool?,
    );
  }
}

class _UniqueUserInsertDtoCopyWithSentinel {
  const _UniqueUserInsertDtoCopyWithSentinel();
}

/// Update DTO for [UniqueUser].
///
/// All fields are optional; only provided entries are used in SET clauses.
class UniqueUserUpdateDto implements UpdateDto<$UniqueUser> {
  const UniqueUserUpdateDto({this.id, this.email, this.active});
  final int? id;
  final String? email;
  final bool? active;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (email != null) 'email': email,
      if (active != null) 'active': active,
    };
  }

  static const _UniqueUserUpdateDtoCopyWithSentinel _copyWithSentinel =
      _UniqueUserUpdateDtoCopyWithSentinel();
  UniqueUserUpdateDto copyWith({
    Object? id = _copyWithSentinel,
    Object? email = _copyWithSentinel,
    Object? active = _copyWithSentinel,
  }) {
    return UniqueUserUpdateDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      email: identical(email, _copyWithSentinel)
          ? this.email
          : email as String?,
      active: identical(active, _copyWithSentinel)
          ? this.active
          : active as bool?,
    );
  }
}

class _UniqueUserUpdateDtoCopyWithSentinel {
  const _UniqueUserUpdateDtoCopyWithSentinel();
}

/// Partial projection for [UniqueUser].
///
/// All fields are nullable; intended for subset SELECTs.
class UniqueUserPartial implements PartialEntity<$UniqueUser> {
  const UniqueUserPartial({this.id, this.email, this.active});

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory UniqueUserPartial.fromRow(Map<String, Object?> row) {
    return UniqueUserPartial(
      id: row['id'] as int?,
      email: row['email'] as String?,
      active: row['active'] as bool?,
    );
  }

  final int? id;
  final String? email;
  final bool? active;

  @override
  $UniqueUser toEntity() {
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
    return $UniqueUser(id: idValue, email: emailValue, active: activeValue);
  }

  @override
  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      if (email != null) 'email': email,
      if (active != null) 'active': active,
    };
  }

  static const _UniqueUserPartialCopyWithSentinel _copyWithSentinel =
      _UniqueUserPartialCopyWithSentinel();
  UniqueUserPartial copyWith({
    Object? id = _copyWithSentinel,
    Object? email = _copyWithSentinel,
    Object? active = _copyWithSentinel,
  }) {
    return UniqueUserPartial(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      email: identical(email, _copyWithSentinel)
          ? this.email
          : email as String?,
      active: identical(active, _copyWithSentinel)
          ? this.active
          : active as bool?,
    );
  }
}

class _UniqueUserPartialCopyWithSentinel {
  const _UniqueUserPartialCopyWithSentinel();
}

/// Generated tracked model class for [UniqueUser].
///
/// This class extends the user-defined [UniqueUser] model and adds
/// attribute tracking, change detection, and relationship management.
/// Instances of this class are returned by queries and repositories.
///
/// **Do not instantiate this class directly.** Use queries, repositories,
/// or model factories to create tracked model instances.
class $UniqueUser extends UniqueUser with ModelAttributes implements OrmEntity {
  /// Internal constructor for [$UniqueUser].
  $UniqueUser({int id = 0, required String email, required bool active})
    : super.new(id: id, email: email, active: active) {
    _attachOrmRuntimeMetadata({'id': id, 'email': email, 'active': active});
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $UniqueUser.fromModel(UniqueUser model) {
    return $UniqueUser(id: model.id, email: model.email, active: model.active);
  }

  $UniqueUser copyWith({int? id, String? email, bool? active}) {
    return $UniqueUser(
      id: id ?? this.id,
      email: email ?? this.email,
      active: active ?? this.active,
    );
  }

  /// Builds a tracked model from a column/value map.
  static $UniqueUser fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$UniqueUserDefinition.fromMap(data, registry: registry);

  /// Converts this tracked model to a column/value map.
  Map<String, Object?> toMap({ValueCodecRegistry? registry}) =>
      _$UniqueUserDefinition.toMap(this, registry: registry);

  /// Tracked getter for [id].
  @override
  int get id => getAttribute<int>('id') ?? super.id;

  /// Tracked setter for [id].
  set id(int value) => setAttribute('id', value);

  /// Tracked getter for [email].
  @override
  String get email => getAttribute<String>('email') ?? super.email;

  /// Tracked setter for [email].
  set email(String value) => setAttribute('email', value);

  /// Tracked getter for [active].
  @override
  bool get active => getAttribute<bool>('active') ?? super.active;

  /// Tracked setter for [active].
  set active(bool value) => setAttribute('active', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$UniqueUserDefinition);
  }
}

class _UniqueUserCopyWithSentinel {
  const _UniqueUserCopyWithSentinel();
}

extension UniqueUserOrmExtension on UniqueUser {
  static const _UniqueUserCopyWithSentinel _copyWithSentinel =
      _UniqueUserCopyWithSentinel();
  UniqueUser copyWith({
    Object? id = _copyWithSentinel,
    Object? email = _copyWithSentinel,
    Object? active = _copyWithSentinel,
  }) {
    return UniqueUser.new(
      id: identical(id, _copyWithSentinel) ? this.id : id as int,
      email: identical(email, _copyWithSentinel) ? this.email : email as String,
      active: identical(active, _copyWithSentinel)
          ? this.active
          : active as bool,
    );
  }

  /// Converts this model to a column/value map.
  Map<String, Object?> toMap({ValueCodecRegistry? registry}) =>
      _$UniqueUserDefinition.toMap(this, registry: registry);

  /// Builds a model from a column/value map.
  static UniqueUser fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$UniqueUserDefinition.fromMap(data, registry: registry);

  /// The Type of the generated ORM-managed model class.
  /// Use this when you need to specify the tracked model type explicitly,
  /// for example in generic type parameters.
  static Type get trackedType => $UniqueUser;

  /// Converts this immutable model to a tracked ORM-managed model.
  /// The tracked model supports attribute tracking, change detection,
  /// and persistence operations like save() and touch().
  $UniqueUser toTracked() {
    return $UniqueUser.fromModel(this);
  }
}

extension UniqueUserPredicateFields on PredicateBuilder<UniqueUser> {
  PredicateField<UniqueUser, int> get id =>
      PredicateField<UniqueUser, int>(this, 'id');
  PredicateField<UniqueUser, String> get email =>
      PredicateField<UniqueUser, String>(this, 'email');
  PredicateField<UniqueUser, bool> get active =>
      PredicateField<UniqueUser, bool>(this, 'active');
}

void registerUniqueUserEventHandlers(EventBus bus) {
  // No event handlers registered for UniqueUser.
}
