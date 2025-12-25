// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'model_scopes.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$ScopedUserIdField = FieldDefinition(
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

const FieldDefinition _$ScopedUserEmailField = FieldDefinition(
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

const FieldDefinition _$ScopedUserActiveField = FieldDefinition(
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

const FieldDefinition _$ScopedUserRoleField = FieldDefinition(
  name: 'role',
  columnName: 'role',
  dartType: 'String',
  resolvedType: 'String?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

Map<String, Object?> _encodeScopedUserUntracked(
  Object model,
  ValueCodecRegistry registry,
) {
  final m = model as ScopedUser;
  return <String, Object?>{
    'id': registry.encodeField(_$ScopedUserIdField, m.id),
    'email': registry.encodeField(_$ScopedUserEmailField, m.email),
    'active': registry.encodeField(_$ScopedUserActiveField, m.active),
    'role': registry.encodeField(_$ScopedUserRoleField, m.role),
  };
}

final ModelDefinition<$ScopedUser> _$ScopedUserDefinition = ModelDefinition(
  modelName: 'ScopedUser',
  tableName: 'scoped_users',
  fields: const [
    _$ScopedUserIdField,
    _$ScopedUserEmailField,
    _$ScopedUserActiveField,
    _$ScopedUserRoleField,
  ],
  relations: const [],
  softDeleteColumn: 'deleted_at',
  metadata: ModelAttributesMetadata(
    hidden: const <String>[],
    visible: const <String>[],
    fillable: const <String>[],
    guarded: const <String>[],
    casts: const <String, String>{},
    softDeletes: false,
    softDeleteColumn: 'deleted_at',
  ),
  untrackedToMap: _encodeScopedUserUntracked,
  codec: _$ScopedUserCodec(),
);

extension ScopedUserOrmDefinition on ScopedUser {
  static ModelDefinition<$ScopedUser> get definition => _$ScopedUserDefinition;
}

class ScopedUsers {
  const ScopedUsers._();

  /// Starts building a query for [$ScopedUser].
  ///
  /// {@macro ormed.query}
  static Query<$ScopedUser> query([String? connection]) =>
      Model.query<$ScopedUser>(connection: connection);

  static Future<$ScopedUser?> find(Object id, {String? connection}) =>
      Model.find<$ScopedUser>(id, connection: connection);

  static Future<$ScopedUser> findOrFail(Object id, {String? connection}) =>
      Model.findOrFail<$ScopedUser>(id, connection: connection);

  static Future<List<$ScopedUser>> all({String? connection}) =>
      Model.all<$ScopedUser>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<$ScopedUser>(connection: connection);

  static Future<bool> anyExist({String? connection}) =>
      Model.anyExist<$ScopedUser>(connection: connection);

  static Query<$ScopedUser> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) =>
      Model.where<$ScopedUser>(column, operator, value, connection: connection);

  static Query<$ScopedUser> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<$ScopedUser>(column, values, connection: connection);

  static Query<$ScopedUser> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<$ScopedUser>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<$ScopedUser> limit(int count, {String? connection}) =>
      Model.limit<$ScopedUser>(count, connection: connection);

  /// Creates a [Repository] for [$ScopedUser].
  ///
  /// {@macro ormed.repository}
  static Repository<$ScopedUser> repo([String? connection]) =>
      Model.repository<$ScopedUser>(connection: connection);
}

class ScopedUserModelFactory {
  const ScopedUserModelFactory._();

  static ModelDefinition<$ScopedUser> get definition => _$ScopedUserDefinition;

  static ModelCodec<$ScopedUser> get codec => definition.codec;

  static ScopedUser fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    ScopedUser model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model.toTracked(), registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<ScopedUser> withConnection(
    QueryContext context,
  ) => ModelFactoryConnection<ScopedUser>(
    definition: definition,
    context: context,
  );

  static ModelFactoryBuilder<ScopedUser> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<ScopedUser>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$ScopedUserCodec extends ModelCodec<$ScopedUser> {
  const _$ScopedUserCodec();
  @override
  Map<String, Object?> encode($ScopedUser model, ValueCodecRegistry registry) {
    return <String, Object?>{
      'id': registry.encodeField(_$ScopedUserIdField, model.id),
      'email': registry.encodeField(_$ScopedUserEmailField, model.email),
      'active': registry.encodeField(_$ScopedUserActiveField, model.active),
      'role': registry.encodeField(_$ScopedUserRoleField, model.role),
    };
  }

  @override
  $ScopedUser decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final int scopedUserIdValue =
        registry.decodeField<int>(_$ScopedUserIdField, data['id']) ?? 0;
    final String scopedUserEmailValue =
        registry.decodeField<String>(_$ScopedUserEmailField, data['email']) ??
        (throw StateError('Field email on ScopedUser cannot be null.'));
    final bool scopedUserActiveValue =
        registry.decodeField<bool>(_$ScopedUserActiveField, data['active']) ??
        (throw StateError('Field active on ScopedUser cannot be null.'));
    final String? scopedUserRoleValue = registry.decodeField<String?>(
      _$ScopedUserRoleField,
      data['role'],
    );
    final model = $ScopedUser(
      id: scopedUserIdValue,
      email: scopedUserEmailValue,
      active: scopedUserActiveValue,
      role: scopedUserRoleValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': scopedUserIdValue,
      'email': scopedUserEmailValue,
      'active': scopedUserActiveValue,
      'role': scopedUserRoleValue,
    });
    return model;
  }
}

/// Insert DTO for [ScopedUser].
///
/// Auto-increment/DB-generated fields are omitted by default.
class ScopedUserInsertDto implements InsertDto<$ScopedUser> {
  const ScopedUserInsertDto({this.email, this.active, this.role});
  final String? email;
  final bool? active;
  final String? role;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (email != null) 'email': email,
      if (active != null) 'active': active,
      if (role != null) 'role': role,
    };
  }

  static const _ScopedUserInsertDtoCopyWithSentinel _copyWithSentinel =
      _ScopedUserInsertDtoCopyWithSentinel();
  ScopedUserInsertDto copyWith({
    Object? email = _copyWithSentinel,
    Object? active = _copyWithSentinel,
    Object? role = _copyWithSentinel,
  }) {
    return ScopedUserInsertDto(
      email: identical(email, _copyWithSentinel)
          ? this.email
          : email as String?,
      active: identical(active, _copyWithSentinel)
          ? this.active
          : active as bool?,
      role: identical(role, _copyWithSentinel) ? this.role : role as String?,
    );
  }
}

class _ScopedUserInsertDtoCopyWithSentinel {
  const _ScopedUserInsertDtoCopyWithSentinel();
}

/// Update DTO for [ScopedUser].
///
/// All fields are optional; only provided entries are used in SET clauses.
class ScopedUserUpdateDto implements UpdateDto<$ScopedUser> {
  const ScopedUserUpdateDto({this.id, this.email, this.active, this.role});
  final int? id;
  final String? email;
  final bool? active;
  final String? role;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (email != null) 'email': email,
      if (active != null) 'active': active,
      if (role != null) 'role': role,
    };
  }

  static const _ScopedUserUpdateDtoCopyWithSentinel _copyWithSentinel =
      _ScopedUserUpdateDtoCopyWithSentinel();
  ScopedUserUpdateDto copyWith({
    Object? id = _copyWithSentinel,
    Object? email = _copyWithSentinel,
    Object? active = _copyWithSentinel,
    Object? role = _copyWithSentinel,
  }) {
    return ScopedUserUpdateDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      email: identical(email, _copyWithSentinel)
          ? this.email
          : email as String?,
      active: identical(active, _copyWithSentinel)
          ? this.active
          : active as bool?,
      role: identical(role, _copyWithSentinel) ? this.role : role as String?,
    );
  }
}

class _ScopedUserUpdateDtoCopyWithSentinel {
  const _ScopedUserUpdateDtoCopyWithSentinel();
}

/// Partial projection for [ScopedUser].
///
/// All fields are nullable; intended for subset SELECTs.
class ScopedUserPartial implements PartialEntity<$ScopedUser> {
  const ScopedUserPartial({this.id, this.email, this.active, this.role});

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory ScopedUserPartial.fromRow(Map<String, Object?> row) {
    return ScopedUserPartial(
      id: row['id'] as int?,
      email: row['email'] as String?,
      active: row['active'] as bool?,
      role: row['role'] as String?,
    );
  }

  final int? id;
  final String? email;
  final bool? active;
  final String? role;

  @override
  $ScopedUser toEntity() {
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
    return $ScopedUser(
      id: idValue,
      email: emailValue,
      active: activeValue,
      role: role,
    );
  }

  @override
  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      if (email != null) 'email': email,
      if (active != null) 'active': active,
      if (role != null) 'role': role,
    };
  }

  static const _ScopedUserPartialCopyWithSentinel _copyWithSentinel =
      _ScopedUserPartialCopyWithSentinel();
  ScopedUserPartial copyWith({
    Object? id = _copyWithSentinel,
    Object? email = _copyWithSentinel,
    Object? active = _copyWithSentinel,
    Object? role = _copyWithSentinel,
  }) {
    return ScopedUserPartial(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      email: identical(email, _copyWithSentinel)
          ? this.email
          : email as String?,
      active: identical(active, _copyWithSentinel)
          ? this.active
          : active as bool?,
      role: identical(role, _copyWithSentinel) ? this.role : role as String?,
    );
  }
}

class _ScopedUserPartialCopyWithSentinel {
  const _ScopedUserPartialCopyWithSentinel();
}

/// Generated tracked model class for [ScopedUser].
///
/// This class extends the user-defined [ScopedUser] model and adds
/// attribute tracking, change detection, and relationship management.
/// Instances of this class are returned by queries and repositories.
///
/// **Do not instantiate this class directly.** Use queries, repositories,
/// or model factories to create tracked model instances.
class $ScopedUser extends ScopedUser with ModelAttributes implements OrmEntity {
  /// Internal constructor for [$ScopedUser].
  $ScopedUser({
    int id = 0,
    required String email,
    required bool active,
    String? role,
  }) : super.new(id: id, email: email, active: active, role: role) {
    _attachOrmRuntimeMetadata({
      'id': id,
      'email': email,
      'active': active,
      'role': role,
    });
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $ScopedUser.fromModel(ScopedUser model) {
    return $ScopedUser(
      id: model.id,
      email: model.email,
      active: model.active,
      role: model.role,
    );
  }

  $ScopedUser copyWith({int? id, String? email, bool? active, String? role}) {
    return $ScopedUser(
      id: id ?? this.id,
      email: email ?? this.email,
      active: active ?? this.active,
      role: role ?? this.role,
    );
  }

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

  /// Tracked getter for [role].
  @override
  String? get role => getAttribute<String?>('role') ?? super.role;

  /// Tracked setter for [role].
  set role(String? value) => setAttribute('role', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$ScopedUserDefinition);
  }
}

extension ScopedUserOrmExtension on ScopedUser {
  /// The Type of the generated ORM-managed model class.
  /// Use this when you need to specify the tracked model type explicitly,
  /// for example in generic type parameters.
  static Type get trackedType => $ScopedUser;

  /// Converts this immutable model to a tracked ORM-managed model.
  /// The tracked model supports attribute tracking, change detection,
  /// and persistence operations like save() and touch().
  $ScopedUser toTracked() {
    return $ScopedUser.fromModel(this);
  }
}

extension $ScopedUserScopes on Query<$ScopedUser> {
  Query<$ScopedUser> activeOnly() => ScopedUser.activeOnly(this);
  Query<$ScopedUser> withDomain(String domain) =>
      ScopedUser.withDomain(this, domain);
  Query<$ScopedUser> roleIs({required String role}) =>
      ScopedUser.roleIs(this, role: role);
}

void registerScopedUserScopes(ScopeRegistry registry) {
  registry.addGlobalScope<$ScopedUser>(
    'activeOnly',
    (query) => query.activeOnly(),
  );
  registry.addLocalScope<$ScopedUser>('withDomain', (query, args) {
    return query.withDomain(args[0] as String);
  });
  registry.addLocalScope<$ScopedUser>('roleIs', (query, args) {
    return query.roleIs(role: args[0] as String);
  });
}

void registerScopedUserEventHandlers(EventBus bus) {
  // No event handlers registered for ScopedUser.
}
