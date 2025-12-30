// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'accessor_user.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$AccessorUserIdField = FieldDefinition(
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

const FieldDefinition _$AccessorUserFirstNameField = FieldDefinition(
  name: 'firstName',
  columnName: 'first_name',
  dartType: 'String',
  resolvedType: 'String',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$AccessorUserLastNameField = FieldDefinition(
  name: 'lastName',
  columnName: 'last_name',
  dartType: 'String',
  resolvedType: 'String',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$AccessorUserEmailField = FieldDefinition(
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

Map<String, Object?> _encodeAccessorUserUntracked(
  Object model,
  ValueCodecRegistry registry,
) {
  final m = model as AccessorUser;
  return <String, Object?>{
    'id': registry.encodeField(_$AccessorUserIdField, m.id),
    'first_name': registry.encodeField(
      _$AccessorUserFirstNameField,
      m.firstName,
    ),
    'last_name': registry.encodeField(_$AccessorUserLastNameField, m.lastName),
    'email': registry.encodeField(_$AccessorUserEmailField, m.email),
  };
}

final ModelDefinition<$AccessorUser> _$AccessorUserDefinition = ModelDefinition(
  modelName: 'AccessorUser',
  tableName: 'accessor_users',
  fields: const [
    _$AccessorUserIdField,
    _$AccessorUserFirstNameField,
    _$AccessorUserLastNameField,
    _$AccessorUserEmailField,
  ],
  relations: const [],
  softDeleteColumn: 'deleted_at',
  metadata: ModelAttributesMetadata(
    hidden: const <String>[],
    visible: const <String>[],
    fillable: const <String>[],
    guarded: const <String>[],
    casts: const <String, String>{},
    appends: const <String>['full_name', 'email_domain'],
    touches: const <String>[],
    timestamps: true,
    softDeletes: false,
    softDeleteColumn: 'deleted_at',
  ),
  accessors: {
    'full_name': (model, value) =>
        AccessorUser.fullName((model as AccessorUser), value),
    'email_domain': (model, value) =>
        AccessorUser.emailDomain((model as AccessorUser), value as String?),
  },
  mutators: {
    'email': (model, value) =>
        AccessorUser.normalizeEmail((model as AccessorUser), value as String?),
  },
  untrackedToMap: _encodeAccessorUserUntracked,
  codec: _$AccessorUserCodec(),
);

extension AccessorUserOrmDefinition on AccessorUser {
  static ModelDefinition<$AccessorUser> get definition =>
      _$AccessorUserDefinition;
}

class AccessorUsers {
  const AccessorUsers._();

  /// Starts building a query for [$AccessorUser].
  ///
  /// {@macro ormed.query}
  static Query<$AccessorUser> query([String? connection]) =>
      Model.query<$AccessorUser>(connection: connection);

  static Future<$AccessorUser?> find(Object id, {String? connection}) =>
      Model.find<$AccessorUser>(id, connection: connection);

  static Future<$AccessorUser> findOrFail(Object id, {String? connection}) =>
      Model.findOrFail<$AccessorUser>(id, connection: connection);

  static Future<List<$AccessorUser>> all({String? connection}) =>
      Model.all<$AccessorUser>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<$AccessorUser>(connection: connection);

  static Future<bool> anyExist({String? connection}) =>
      Model.anyExist<$AccessorUser>(connection: connection);

  static Query<$AccessorUser> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) => Model.where<$AccessorUser>(
    column,
    operator,
    value,
    connection: connection,
  );

  static Query<$AccessorUser> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<$AccessorUser>(column, values, connection: connection);

  static Query<$AccessorUser> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<$AccessorUser>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<$AccessorUser> limit(int count, {String? connection}) =>
      Model.limit<$AccessorUser>(count, connection: connection);

  /// Creates a [Repository] for [$AccessorUser].
  ///
  /// {@macro ormed.repository}
  static Repository<$AccessorUser> repo([String? connection]) =>
      Model.repository<$AccessorUser>(connection: connection);

  /// Builds a tracked model from a column/value map.
  static $AccessorUser fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$AccessorUserDefinition.fromMap(data, registry: registry);

  /// Converts a tracked model to a column/value map.
  static Map<String, Object?> toMap(
    $AccessorUser model, {
    ValueCodecRegistry? registry,
  }) => _$AccessorUserDefinition.toMap(model, registry: registry);
}

class AccessorUserModelFactory {
  const AccessorUserModelFactory._();

  static ModelDefinition<$AccessorUser> get definition =>
      _$AccessorUserDefinition;

  static ModelCodec<$AccessorUser> get codec => definition.codec;

  static AccessorUser fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    AccessorUser model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model.toTracked(), registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<AccessorUser> withConnection(
    QueryContext context,
  ) => ModelFactoryConnection<AccessorUser>(
    definition: definition,
    context: context,
  );

  static ModelFactoryBuilder<AccessorUser> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<AccessorUser>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$AccessorUserCodec extends ModelCodec<$AccessorUser> {
  const _$AccessorUserCodec();
  @override
  Map<String, Object?> encode(
    $AccessorUser model,
    ValueCodecRegistry registry,
  ) {
    return <String, Object?>{
      'id': registry.encodeField(_$AccessorUserIdField, model.id),
      'first_name': registry.encodeField(
        _$AccessorUserFirstNameField,
        model.firstName,
      ),
      'last_name': registry.encodeField(
        _$AccessorUserLastNameField,
        model.lastName,
      ),
      'email': registry.encodeField(_$AccessorUserEmailField, model.email),
    };
  }

  @override
  $AccessorUser decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final int accessorUserIdValue =
        registry.decodeField<int>(_$AccessorUserIdField, data['id']) ??
        (throw StateError('Field id on AccessorUser cannot be null.'));
    final String accessorUserFirstNameValue =
        registry.decodeField<String>(
          _$AccessorUserFirstNameField,
          data['first_name'],
        ) ??
        (throw StateError('Field firstName on AccessorUser cannot be null.'));
    final String accessorUserLastNameValue =
        registry.decodeField<String>(
          _$AccessorUserLastNameField,
          data['last_name'],
        ) ??
        (throw StateError('Field lastName on AccessorUser cannot be null.'));
    final String accessorUserEmailValue =
        registry.decodeField<String>(_$AccessorUserEmailField, data['email']) ??
        (throw StateError('Field email on AccessorUser cannot be null.'));
    final model = $AccessorUser(
      id: accessorUserIdValue,
      firstName: accessorUserFirstNameValue,
      lastName: accessorUserLastNameValue,
      email: accessorUserEmailValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': accessorUserIdValue,
      'first_name': accessorUserFirstNameValue,
      'last_name': accessorUserLastNameValue,
      'email': accessorUserEmailValue,
    });
    return model;
  }
}

/// Insert DTO for [AccessorUser].
///
/// Auto-increment/DB-generated fields are omitted by default.
class AccessorUserInsertDto implements InsertDto<$AccessorUser> {
  const AccessorUserInsertDto({
    this.id,
    this.firstName,
    this.lastName,
    this.email,
  });
  final int? id;
  final String? firstName;
  final String? lastName;
  final String? email;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (email != null) 'email': email,
    };
  }

  static const _AccessorUserInsertDtoCopyWithSentinel _copyWithSentinel =
      _AccessorUserInsertDtoCopyWithSentinel();
  AccessorUserInsertDto copyWith({
    Object? id = _copyWithSentinel,
    Object? firstName = _copyWithSentinel,
    Object? lastName = _copyWithSentinel,
    Object? email = _copyWithSentinel,
  }) {
    return AccessorUserInsertDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      firstName: identical(firstName, _copyWithSentinel)
          ? this.firstName
          : firstName as String?,
      lastName: identical(lastName, _copyWithSentinel)
          ? this.lastName
          : lastName as String?,
      email: identical(email, _copyWithSentinel)
          ? this.email
          : email as String?,
    );
  }
}

class _AccessorUserInsertDtoCopyWithSentinel {
  const _AccessorUserInsertDtoCopyWithSentinel();
}

/// Update DTO for [AccessorUser].
///
/// All fields are optional; only provided entries are used in SET clauses.
class AccessorUserUpdateDto implements UpdateDto<$AccessorUser> {
  const AccessorUserUpdateDto({
    this.id,
    this.firstName,
    this.lastName,
    this.email,
  });
  final int? id;
  final String? firstName;
  final String? lastName;
  final String? email;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (email != null) 'email': email,
    };
  }

  static const _AccessorUserUpdateDtoCopyWithSentinel _copyWithSentinel =
      _AccessorUserUpdateDtoCopyWithSentinel();
  AccessorUserUpdateDto copyWith({
    Object? id = _copyWithSentinel,
    Object? firstName = _copyWithSentinel,
    Object? lastName = _copyWithSentinel,
    Object? email = _copyWithSentinel,
  }) {
    return AccessorUserUpdateDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      firstName: identical(firstName, _copyWithSentinel)
          ? this.firstName
          : firstName as String?,
      lastName: identical(lastName, _copyWithSentinel)
          ? this.lastName
          : lastName as String?,
      email: identical(email, _copyWithSentinel)
          ? this.email
          : email as String?,
    );
  }
}

class _AccessorUserUpdateDtoCopyWithSentinel {
  const _AccessorUserUpdateDtoCopyWithSentinel();
}

/// Partial projection for [AccessorUser].
///
/// All fields are nullable; intended for subset SELECTs.
class AccessorUserPartial implements PartialEntity<$AccessorUser> {
  const AccessorUserPartial({
    this.id,
    this.firstName,
    this.lastName,
    this.email,
  });

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory AccessorUserPartial.fromRow(Map<String, Object?> row) {
    return AccessorUserPartial(
      id: row['id'] as int?,
      firstName: row['first_name'] as String?,
      lastName: row['last_name'] as String?,
      email: row['email'] as String?,
    );
  }

  final int? id;
  final String? firstName;
  final String? lastName;
  final String? email;

  @override
  $AccessorUser toEntity() {
    // Basic required-field check: non-nullable fields must be present.
    final int? idValue = id;
    if (idValue == null) {
      throw StateError('Missing required field: id');
    }
    final String? firstNameValue = firstName;
    if (firstNameValue == null) {
      throw StateError('Missing required field: firstName');
    }
    final String? lastNameValue = lastName;
    if (lastNameValue == null) {
      throw StateError('Missing required field: lastName');
    }
    final String? emailValue = email;
    if (emailValue == null) {
      throw StateError('Missing required field: email');
    }
    return $AccessorUser(
      id: idValue,
      firstName: firstNameValue,
      lastName: lastNameValue,
      email: emailValue,
    );
  }

  @override
  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (email != null) 'email': email,
    };
  }

  static const _AccessorUserPartialCopyWithSentinel _copyWithSentinel =
      _AccessorUserPartialCopyWithSentinel();
  AccessorUserPartial copyWith({
    Object? id = _copyWithSentinel,
    Object? firstName = _copyWithSentinel,
    Object? lastName = _copyWithSentinel,
    Object? email = _copyWithSentinel,
  }) {
    return AccessorUserPartial(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      firstName: identical(firstName, _copyWithSentinel)
          ? this.firstName
          : firstName as String?,
      lastName: identical(lastName, _copyWithSentinel)
          ? this.lastName
          : lastName as String?,
      email: identical(email, _copyWithSentinel)
          ? this.email
          : email as String?,
    );
  }
}

class _AccessorUserPartialCopyWithSentinel {
  const _AccessorUserPartialCopyWithSentinel();
}

/// Generated tracked model class for [AccessorUser].
///
/// This class extends the user-defined [AccessorUser] model and adds
/// attribute tracking, change detection, and relationship management.
/// Instances of this class are returned by queries and repositories.
///
/// **Do not instantiate this class directly.** Use queries, repositories,
/// or model factories to create tracked model instances.
class $AccessorUser extends AccessorUser
    with ModelAttributes
    implements OrmEntity {
  /// Internal constructor for [$AccessorUser].
  $AccessorUser({
    required int id,
    required String firstName,
    required String lastName,
    required String email,
  }) : super.new(
         id: id,
         firstName: firstName,
         lastName: lastName,
         email: email,
       ) {
    _attachOrmRuntimeMetadata({
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
    });
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $AccessorUser.fromModel(AccessorUser model) {
    return $AccessorUser(
      id: model.id,
      firstName: model.firstName,
      lastName: model.lastName,
      email: model.email,
    );
  }

  $AccessorUser copyWith({
    int? id,
    String? firstName,
    String? lastName,
    String? email,
  }) {
    return $AccessorUser(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
    );
  }

  /// Builds a tracked model from a column/value map.
  static $AccessorUser fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$AccessorUserDefinition.fromMap(data, registry: registry);

  /// Converts this tracked model to a column/value map.
  Map<String, Object?> toMap({ValueCodecRegistry? registry}) =>
      _$AccessorUserDefinition.toMap(this, registry: registry);

  /// Tracked getter for [id].
  @override
  int get id => getAttribute<int>('id') ?? super.id;

  /// Tracked setter for [id].
  set id(int value) => setAttribute('id', value);

  /// Tracked getter for [firstName].
  @override
  String get firstName => getAttribute<String>('first_name') ?? super.firstName;

  /// Tracked setter for [firstName].
  set firstName(String value) => setAttribute('first_name', value);

  /// Tracked getter for [lastName].
  @override
  String get lastName => getAttribute<String>('last_name') ?? super.lastName;

  /// Tracked setter for [lastName].
  set lastName(String value) => setAttribute('last_name', value);

  /// Tracked getter for [email].
  @override
  String get email => getAttribute<String>('email') ?? super.email;

  /// Tracked setter for [email].
  set email(String value) => setAttribute('email', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$AccessorUserDefinition);
  }
}

class _AccessorUserCopyWithSentinel {
  const _AccessorUserCopyWithSentinel();
}

extension AccessorUserOrmExtension on AccessorUser {
  static const _AccessorUserCopyWithSentinel _copyWithSentinel =
      _AccessorUserCopyWithSentinel();
  AccessorUser copyWith({
    Object? id = _copyWithSentinel,
    Object? firstName = _copyWithSentinel,
    Object? lastName = _copyWithSentinel,
    Object? email = _copyWithSentinel,
  }) {
    return AccessorUser(
      id: identical(id, _copyWithSentinel) ? this.id : id as int,
      firstName: identical(firstName, _copyWithSentinel)
          ? this.firstName
          : firstName as String,
      lastName: identical(lastName, _copyWithSentinel)
          ? this.lastName
          : lastName as String,
      email: identical(email, _copyWithSentinel) ? this.email : email as String,
    );
  }

  /// Converts this model to a column/value map.
  Map<String, Object?> toMap({ValueCodecRegistry? registry}) =>
      _$AccessorUserDefinition.toMap(this, registry: registry);

  /// Builds a model from a column/value map.
  static AccessorUser fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$AccessorUserDefinition.fromMap(data, registry: registry);

  /// The Type of the generated ORM-managed model class.
  /// Use this when you need to specify the tracked model type explicitly,
  /// for example in generic type parameters.
  static Type get trackedType => $AccessorUser;

  /// Converts this immutable model to a tracked ORM-managed model.
  /// The tracked model supports attribute tracking, change detection,
  /// and persistence operations like save() and touch().
  $AccessorUser toTracked() {
    return $AccessorUser.fromModel(this);
  }
}

extension $AccessorUserAccessors on $AccessorUser {
  String get fullName {
    return AccessorUser.fullName(this, getRawAttribute('full_name'));
  }

  String get emailDomain {
    return AccessorUser.emailDomain(
      this,
      getRawAttribute('email_domain') as String?,
    );
  }

  String normalizeEmail(String? value) {
    final result = AccessorUser.normalizeEmail(this, value);
    setRawAttribute('email', result);
    return result;
  }
}

extension AccessorUserPredicateFields on PredicateBuilder<AccessorUser> {
  PredicateField<AccessorUser, int> get id =>
      PredicateField<AccessorUser, int>(this, 'id');
  PredicateField<AccessorUser, String> get firstName =>
      PredicateField<AccessorUser, String>(this, 'firstName');
  PredicateField<AccessorUser, String> get lastName =>
      PredicateField<AccessorUser, String>(this, 'lastName');
  PredicateField<AccessorUser, String> get email =>
      PredicateField<AccessorUser, String>(this, 'email');
}

void registerAccessorUserEventHandlers(EventBus bus) {
  // No event handlers registered for AccessorUser.
}
