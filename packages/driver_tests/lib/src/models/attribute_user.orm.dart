// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'attribute_user.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$AttributeUserIdField = FieldDefinition(
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

const FieldDefinition _$AttributeUserEmailField = FieldDefinition(
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

const FieldDefinition _$AttributeUserSecretField = FieldDefinition(
  name: 'secret',
  columnName: 'secret',
  dartType: 'String',
  resolvedType: 'String',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$AttributeUserRoleField = FieldDefinition(
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

const FieldDefinition _$AttributeUserProfileField = FieldDefinition(
  name: 'profile',
  columnName: 'profile',
  dartType: 'Map<String, Object?>',
  resolvedType: 'Map<String, Object?>?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
  codecType: 'json',
);

Map<String, Object?> _encodeAttributeUserUntracked(
  Object model,
  ValueCodecRegistry registry,
) {
  final m = model as AttributeUser;
  return <String, Object?>{
    'id': registry.encodeField(_$AttributeUserIdField, m.id),
    'email': registry.encodeField(_$AttributeUserEmailField, m.email),
    'secret': registry.encodeField(_$AttributeUserSecretField, m.secret),
    'role': registry.encodeField(_$AttributeUserRoleField, m.role),
    'profile': registry.encodeField(_$AttributeUserProfileField, m.profile),
  };
}

final ModelDefinition<$AttributeUser> _$AttributeUserDefinition =
    ModelDefinition(
      modelName: 'AttributeUser',
      tableName: 'attribute_users',
      fields: const [
        _$AttributeUserIdField,
        _$AttributeUserEmailField,
        _$AttributeUserSecretField,
        _$AttributeUserRoleField,
        _$AttributeUserProfileField,
      ],
      relations: const [],
      softDeleteColumn: 'deleted_at',
      metadata: ModelAttributesMetadata(
        hidden: const <String>['secret'],
        visible: const <String>['secret'],
        fillable: const <String>['email', 'role', 'profile'],
        guarded: const <String>['id'],
        casts: const <String, String>{'profile': 'json'},
        appends: const <String>[],
        touches: const <String>[],
        timestamps: true,
        fieldOverrides: const {
          'secret': FieldAttributeMetadata(hidden: true),
          'role': FieldAttributeMetadata(fillable: true),
          'profile': FieldAttributeMetadata(cast: 'json'),
        },
        driverAnnotations: const [DriverModel('core')],
        softDeletes: false,
        softDeleteColumn: 'deleted_at',
      ),
      untrackedToMap: _encodeAttributeUserUntracked,
      codec: _$AttributeUserCodec(),
    );

// ignore: unused_element
final attributeuserModelDefinitionRegistration =
    ModelFactoryRegistry.register<$AttributeUser>(_$AttributeUserDefinition);

extension AttributeUserOrmDefinition on AttributeUser {
  static ModelDefinition<$AttributeUser> get definition =>
      _$AttributeUserDefinition;
}

class AttributeUsers {
  const AttributeUsers._();

  /// Starts building a query for [$AttributeUser].
  ///
  /// {@macro ormed.query}
  static Query<$AttributeUser> query([String? connection]) =>
      Model.query<$AttributeUser>(connection: connection);

  static Future<$AttributeUser?> find(Object id, {String? connection}) =>
      Model.find<$AttributeUser>(id, connection: connection);

  static Future<$AttributeUser> findOrFail(Object id, {String? connection}) =>
      Model.findOrFail<$AttributeUser>(id, connection: connection);

  static Future<List<$AttributeUser>> all({String? connection}) =>
      Model.all<$AttributeUser>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<$AttributeUser>(connection: connection);

  static Future<bool> anyExist({String? connection}) =>
      Model.anyExist<$AttributeUser>(connection: connection);

  static Query<$AttributeUser> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) => Model.where<$AttributeUser>(
    column,
    operator,
    value,
    connection: connection,
  );

  static Query<$AttributeUser> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<$AttributeUser>(column, values, connection: connection);

  static Query<$AttributeUser> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<$AttributeUser>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<$AttributeUser> limit(int count, {String? connection}) =>
      Model.limit<$AttributeUser>(count, connection: connection);

  /// Creates a [Repository] for [$AttributeUser].
  ///
  /// {@macro ormed.repository}
  static Repository<$AttributeUser> repo([String? connection]) =>
      Model.repository<$AttributeUser>(connection: connection);
}

class AttributeUserModelFactory {
  const AttributeUserModelFactory._();

  static ModelDefinition<$AttributeUser> get definition =>
      _$AttributeUserDefinition;

  static ModelCodec<$AttributeUser> get codec => definition.codec;

  static AttributeUser fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    AttributeUser model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model.toTracked(), registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<AttributeUser> withConnection(
    QueryContext context,
  ) => ModelFactoryConnection<AttributeUser>(
    definition: definition,
    context: context,
  );

  static ModelFactoryBuilder<AttributeUser> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<AttributeUser>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$AttributeUserCodec extends ModelCodec<$AttributeUser> {
  const _$AttributeUserCodec();
  @override
  Map<String, Object?> encode(
    $AttributeUser model,
    ValueCodecRegistry registry,
  ) {
    return <String, Object?>{
      'id': registry.encodeField(_$AttributeUserIdField, model.id),
      'email': registry.encodeField(_$AttributeUserEmailField, model.email),
      'secret': registry.encodeField(_$AttributeUserSecretField, model.secret),
      'role': registry.encodeField(_$AttributeUserRoleField, model.role),
      'profile': registry.encodeField(
        _$AttributeUserProfileField,
        model.profile,
      ),
    };
  }

  @override
  $AttributeUser decode(
    Map<String, Object?> data,
    ValueCodecRegistry registry,
  ) {
    final int attributeUserIdValue =
        registry.decodeField<int>(_$AttributeUserIdField, data['id']) ??
        (throw StateError('Field id on AttributeUser cannot be null.'));
    final String attributeUserEmailValue =
        registry.decodeField<String>(
          _$AttributeUserEmailField,
          data['email'],
        ) ??
        (throw StateError('Field email on AttributeUser cannot be null.'));
    final String attributeUserSecretValue =
        registry.decodeField<String>(
          _$AttributeUserSecretField,
          data['secret'],
        ) ??
        (throw StateError('Field secret on AttributeUser cannot be null.'));
    final String? attributeUserRoleValue = registry.decodeField<String?>(
      _$AttributeUserRoleField,
      data['role'],
    );
    final Map<String, Object?>? attributeUserProfileValue = registry
        .decodeField<Map<String, Object?>?>(
          _$AttributeUserProfileField,
          data['profile'],
        );
    final model = $AttributeUser(
      id: attributeUserIdValue,
      email: attributeUserEmailValue,
      secret: attributeUserSecretValue,
      role: attributeUserRoleValue,
      profile: attributeUserProfileValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': attributeUserIdValue,
      'email': attributeUserEmailValue,
      'secret': attributeUserSecretValue,
      'role': attributeUserRoleValue,
      'profile': attributeUserProfileValue,
    });
    return model;
  }
}

/// Insert DTO for [AttributeUser].
///
/// Auto-increment/DB-generated fields are omitted by default.
class AttributeUserInsertDto implements InsertDto<$AttributeUser> {
  const AttributeUserInsertDto({
    this.id,
    this.email,
    this.secret,
    this.role,
    this.profile,
  });
  final int? id;
  final String? email;
  final String? secret;
  final String? role;
  final Map<String, Object?>? profile;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (email != null) 'email': email,
      if (secret != null) 'secret': secret,
      if (role != null) 'role': role,
      if (profile != null) 'profile': profile,
    };
  }

  static const _AttributeUserInsertDtoCopyWithSentinel _copyWithSentinel =
      _AttributeUserInsertDtoCopyWithSentinel();
  AttributeUserInsertDto copyWith({
    Object? id = _copyWithSentinel,
    Object? email = _copyWithSentinel,
    Object? secret = _copyWithSentinel,
    Object? role = _copyWithSentinel,
    Object? profile = _copyWithSentinel,
  }) {
    return AttributeUserInsertDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      email: identical(email, _copyWithSentinel)
          ? this.email
          : email as String?,
      secret: identical(secret, _copyWithSentinel)
          ? this.secret
          : secret as String?,
      role: identical(role, _copyWithSentinel) ? this.role : role as String?,
      profile: identical(profile, _copyWithSentinel)
          ? this.profile
          : profile as Map<String, Object?>?,
    );
  }
}

class _AttributeUserInsertDtoCopyWithSentinel {
  const _AttributeUserInsertDtoCopyWithSentinel();
}

/// Update DTO for [AttributeUser].
///
/// All fields are optional; only provided entries are used in SET clauses.
class AttributeUserUpdateDto implements UpdateDto<$AttributeUser> {
  const AttributeUserUpdateDto({
    this.id,
    this.email,
    this.secret,
    this.role,
    this.profile,
  });
  final int? id;
  final String? email;
  final String? secret;
  final String? role;
  final Map<String, Object?>? profile;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (email != null) 'email': email,
      if (secret != null) 'secret': secret,
      if (role != null) 'role': role,
      if (profile != null) 'profile': profile,
    };
  }

  static const _AttributeUserUpdateDtoCopyWithSentinel _copyWithSentinel =
      _AttributeUserUpdateDtoCopyWithSentinel();
  AttributeUserUpdateDto copyWith({
    Object? id = _copyWithSentinel,
    Object? email = _copyWithSentinel,
    Object? secret = _copyWithSentinel,
    Object? role = _copyWithSentinel,
    Object? profile = _copyWithSentinel,
  }) {
    return AttributeUserUpdateDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      email: identical(email, _copyWithSentinel)
          ? this.email
          : email as String?,
      secret: identical(secret, _copyWithSentinel)
          ? this.secret
          : secret as String?,
      role: identical(role, _copyWithSentinel) ? this.role : role as String?,
      profile: identical(profile, _copyWithSentinel)
          ? this.profile
          : profile as Map<String, Object?>?,
    );
  }
}

class _AttributeUserUpdateDtoCopyWithSentinel {
  const _AttributeUserUpdateDtoCopyWithSentinel();
}

/// Partial projection for [AttributeUser].
///
/// All fields are nullable; intended for subset SELECTs.
class AttributeUserPartial implements PartialEntity<$AttributeUser> {
  const AttributeUserPartial({
    this.id,
    this.email,
    this.secret,
    this.role,
    this.profile,
  });

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory AttributeUserPartial.fromRow(Map<String, Object?> row) {
    return AttributeUserPartial(
      id: row['id'] as int?,
      email: row['email'] as String?,
      secret: row['secret'] as String?,
      role: row['role'] as String?,
      profile: row['profile'] as Map<String, Object?>?,
    );
  }

  final int? id;
  final String? email;
  final String? secret;
  final String? role;
  final Map<String, Object?>? profile;

  @override
  $AttributeUser toEntity() {
    // Basic required-field check: non-nullable fields must be present.
    final int? idValue = id;
    if (idValue == null) {
      throw StateError('Missing required field: id');
    }
    final String? emailValue = email;
    if (emailValue == null) {
      throw StateError('Missing required field: email');
    }
    final String? secretValue = secret;
    if (secretValue == null) {
      throw StateError('Missing required field: secret');
    }
    return $AttributeUser(
      id: idValue,
      email: emailValue,
      secret: secretValue,
      role: role,
      profile: profile,
    );
  }

  @override
  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      if (email != null) 'email': email,
      if (secret != null) 'secret': secret,
      if (role != null) 'role': role,
      if (profile != null) 'profile': profile,
    };
  }

  static const _AttributeUserPartialCopyWithSentinel _copyWithSentinel =
      _AttributeUserPartialCopyWithSentinel();
  AttributeUserPartial copyWith({
    Object? id = _copyWithSentinel,
    Object? email = _copyWithSentinel,
    Object? secret = _copyWithSentinel,
    Object? role = _copyWithSentinel,
    Object? profile = _copyWithSentinel,
  }) {
    return AttributeUserPartial(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      email: identical(email, _copyWithSentinel)
          ? this.email
          : email as String?,
      secret: identical(secret, _copyWithSentinel)
          ? this.secret
          : secret as String?,
      role: identical(role, _copyWithSentinel) ? this.role : role as String?,
      profile: identical(profile, _copyWithSentinel)
          ? this.profile
          : profile as Map<String, Object?>?,
    );
  }
}

class _AttributeUserPartialCopyWithSentinel {
  const _AttributeUserPartialCopyWithSentinel();
}

/// Generated tracked model class for [AttributeUser].
///
/// This class extends the user-defined [AttributeUser] model and adds
/// attribute tracking, change detection, and relationship management.
/// Instances of this class are returned by queries and repositories.
///
/// **Do not instantiate this class directly.** Use queries, repositories,
/// or model factories to create tracked model instances.
class $AttributeUser extends AttributeUser
    with ModelAttributes
    implements OrmEntity {
  /// Internal constructor for [$AttributeUser].
  $AttributeUser({
    required int id,
    required String email,
    required String secret,
    String? role,
    Map<String, Object?>? profile,
  }) : super.new(
         id: id,
         email: email,
         secret: secret,
         role: role,
         profile: profile,
       ) {
    _attachOrmRuntimeMetadata({
      'id': id,
      'email': email,
      'secret': secret,
      'role': role,
      'profile': profile,
    });
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $AttributeUser.fromModel(AttributeUser model) {
    return $AttributeUser(
      id: model.id,
      email: model.email,
      secret: model.secret,
      role: model.role,
      profile: model.profile,
    );
  }

  $AttributeUser copyWith({
    int? id,
    String? email,
    String? secret,
    String? role,
    Map<String, Object?>? profile,
  }) {
    return $AttributeUser(
      id: id ?? this.id,
      email: email ?? this.email,
      secret: secret ?? this.secret,
      role: role ?? this.role,
      profile: profile ?? this.profile,
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

  /// Tracked getter for [secret].
  @override
  String get secret => getAttribute<String>('secret') ?? super.secret;

  /// Tracked setter for [secret].
  set secret(String value) => setAttribute('secret', value);

  /// Tracked getter for [role].
  @override
  String? get role => getAttribute<String?>('role') ?? super.role;

  /// Tracked setter for [role].
  set role(String? value) => setAttribute('role', value);

  /// Tracked getter for [profile].
  @override
  Map<String, Object?>? get profile =>
      getAttribute<Map<String, Object?>?>('profile') ?? super.profile;

  /// Tracked setter for [profile].
  set profile(Map<String, Object?>? value) => setAttribute('profile', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$AttributeUserDefinition);
  }
}

extension AttributeUserOrmExtension on AttributeUser {
  /// The Type of the generated ORM-managed model class.
  /// Use this when you need to specify the tracked model type explicitly,
  /// for example in generic type parameters.
  static Type get trackedType => $AttributeUser;

  /// Converts this immutable model to a tracked ORM-managed model.
  /// The tracked model supports attribute tracking, change detection,
  /// and persistence operations like save() and touch().
  $AttributeUser toTracked() {
    return $AttributeUser.fromModel(this);
  }
}

void registerAttributeUserEventHandlers(EventBus bus) {
  // No event handlers registered for AttributeUser.
}
