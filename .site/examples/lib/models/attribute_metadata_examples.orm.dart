// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'attribute_metadata_examples.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$AccountIdField = FieldDefinition(
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

const FieldDefinition _$AccountEmailField = FieldDefinition(
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

const FieldDefinition _$AccountPasswordHashField = FieldDefinition(
  name: 'passwordHash',
  columnName: 'password_hash',
  dartType: 'String',
  resolvedType: 'String',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$AccountNameField = FieldDefinition(
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

const FieldDefinition _$AccountIsAdminField = FieldDefinition(
  name: 'isAdmin',
  columnName: 'is_admin',
  dartType: 'bool',
  resolvedType: 'bool',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

Map<String, Object?> _encodeAccountUntracked(
  Object model,
  ValueCodecRegistry registry,
) {
  final m = model as Account;
  return <String, Object?>{
    'id': registry.encodeField(_$AccountIdField, m.id),
    'email': registry.encodeField(_$AccountEmailField, m.email),
    'password_hash': registry.encodeField(
      _$AccountPasswordHashField,
      m.passwordHash,
    ),
    'name': registry.encodeField(_$AccountNameField, m.name),
    'is_admin': registry.encodeField(_$AccountIsAdminField, m.isAdmin),
  };
}

final ModelDefinition<$Account> _$AccountDefinition = ModelDefinition(
  modelName: 'Account',
  tableName: 'accounts',
  fields: const [
    _$AccountIdField,
    _$AccountEmailField,
    _$AccountPasswordHashField,
    _$AccountNameField,
    _$AccountIsAdminField,
  ],
  relations: const [],
  softDeleteColumn: 'deleted_at',
  metadata: ModelAttributesMetadata(
    hidden: const <String>['password_hash'],
    visible: const <String>['password_hash'],
    fillable: const <String>['email', 'name'],
    guarded: const <String>['is_admin'],
    casts: const <String, String>{},
    appends: const <String>['display_name'],
    touches: const <String>[],
    timestamps: true,
    fieldOverrides: const {'is_admin': FieldAttributeMetadata(guarded: true)},
    softDeletes: false,
    softDeleteColumn: 'deleted_at',
  ),
  accessors: {
    'display_name': (model, value) =>
        Account.displayName((model as Account), value),
  },
  mutators: {
    'email': (model, value) =>
        Account.normalizeEmail((model as Account), value as String?),
  },
  untrackedToMap: _encodeAccountUntracked,
  codec: _$AccountCodec(),
);

extension AccountOrmDefinition on Account {
  static ModelDefinition<$Account> get definition => _$AccountDefinition;
}

class Accounts {
  const Accounts._();

  /// Starts building a query for [$Account].
  ///
  /// {@macro ormed.query}
  static Query<$Account> query([String? connection]) =>
      Model.query<$Account>(connection: connection);

  static Future<$Account?> find(Object id, {String? connection}) =>
      Model.find<$Account>(id, connection: connection);

  static Future<$Account> findOrFail(Object id, {String? connection}) =>
      Model.findOrFail<$Account>(id, connection: connection);

  static Future<List<$Account>> all({String? connection}) =>
      Model.all<$Account>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<$Account>(connection: connection);

  static Future<bool> anyExist({String? connection}) =>
      Model.anyExist<$Account>(connection: connection);

  static Query<$Account> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) => Model.where<$Account>(column, operator, value, connection: connection);

  static Query<$Account> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<$Account>(column, values, connection: connection);

  static Query<$Account> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<$Account>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<$Account> limit(int count, {String? connection}) =>
      Model.limit<$Account>(count, connection: connection);

  /// Creates a [Repository] for [$Account].
  ///
  /// {@macro ormed.repository}
  static Repository<$Account> repo([String? connection]) =>
      Model.repository<$Account>(connection: connection);

  /// Builds a tracked model from a column/value map.
  static $Account fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$AccountDefinition.fromMap(data, registry: registry);

  /// Converts a tracked model to a column/value map.
  static Map<String, Object?> toMap(
    $Account model, {
    ValueCodecRegistry? registry,
  }) => _$AccountDefinition.toMap(model, registry: registry);
}

class AccountModelFactory {
  const AccountModelFactory._();

  static ModelDefinition<$Account> get definition => _$AccountDefinition;

  static ModelCodec<$Account> get codec => definition.codec;

  static Account fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    Account model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model.toTracked(), registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<Account> withConnection(QueryContext context) =>
      ModelFactoryConnection<Account>(definition: definition, context: context);

  static ModelFactoryBuilder<Account> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<Account>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$AccountCodec extends ModelCodec<$Account> {
  const _$AccountCodec();
  @override
  Map<String, Object?> encode($Account model, ValueCodecRegistry registry) {
    return <String, Object?>{
      'id': registry.encodeField(_$AccountIdField, model.id),
      'email': registry.encodeField(_$AccountEmailField, model.email),
      'password_hash': registry.encodeField(
        _$AccountPasswordHashField,
        model.passwordHash,
      ),
      'name': registry.encodeField(_$AccountNameField, model.name),
      'is_admin': registry.encodeField(_$AccountIsAdminField, model.isAdmin),
    };
  }

  @override
  $Account decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final int accountIdValue =
        registry.decodeField<int>(_$AccountIdField, data['id']) ?? 0;
    final String accountEmailValue =
        registry.decodeField<String>(_$AccountEmailField, data['email']) ??
        (throw StateError('Field email on Account cannot be null.'));
    final String accountPasswordHashValue =
        registry.decodeField<String>(
          _$AccountPasswordHashField,
          data['password_hash'],
        ) ??
        (throw StateError('Field passwordHash on Account cannot be null.'));
    final String? accountNameValue = registry.decodeField<String?>(
      _$AccountNameField,
      data['name'],
    );
    final bool accountIsAdminValue =
        registry.decodeField<bool>(_$AccountIsAdminField, data['is_admin']) ??
        (throw StateError('Field isAdmin on Account cannot be null.'));
    final model = $Account(
      id: accountIdValue,
      email: accountEmailValue,
      passwordHash: accountPasswordHashValue,
      name: accountNameValue,
      isAdmin: accountIsAdminValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': accountIdValue,
      'email': accountEmailValue,
      'password_hash': accountPasswordHashValue,
      'name': accountNameValue,
      'is_admin': accountIsAdminValue,
    });
    return model;
  }
}

/// Insert DTO for [Account].
///
/// Auto-increment/DB-generated fields are omitted by default.
class AccountInsertDto implements InsertDto<$Account> {
  const AccountInsertDto({
    this.email,
    this.passwordHash,
    this.name,
    this.isAdmin,
  });
  final String? email;
  final String? passwordHash;
  final String? name;
  final bool? isAdmin;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (email != null) 'email': email,
      if (passwordHash != null) 'password_hash': passwordHash,
      if (name != null) 'name': name,
      if (isAdmin != null) 'is_admin': isAdmin,
    };
  }

  static const _AccountInsertDtoCopyWithSentinel _copyWithSentinel =
      _AccountInsertDtoCopyWithSentinel();
  AccountInsertDto copyWith({
    Object? email = _copyWithSentinel,
    Object? passwordHash = _copyWithSentinel,
    Object? name = _copyWithSentinel,
    Object? isAdmin = _copyWithSentinel,
  }) {
    return AccountInsertDto(
      email: identical(email, _copyWithSentinel)
          ? this.email
          : email as String?,
      passwordHash: identical(passwordHash, _copyWithSentinel)
          ? this.passwordHash
          : passwordHash as String?,
      name: identical(name, _copyWithSentinel) ? this.name : name as String?,
      isAdmin: identical(isAdmin, _copyWithSentinel)
          ? this.isAdmin
          : isAdmin as bool?,
    );
  }
}

class _AccountInsertDtoCopyWithSentinel {
  const _AccountInsertDtoCopyWithSentinel();
}

/// Update DTO for [Account].
///
/// All fields are optional; only provided entries are used in SET clauses.
class AccountUpdateDto implements UpdateDto<$Account> {
  const AccountUpdateDto({
    this.id,
    this.email,
    this.passwordHash,
    this.name,
    this.isAdmin,
  });
  final int? id;
  final String? email;
  final String? passwordHash;
  final String? name;
  final bool? isAdmin;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (email != null) 'email': email,
      if (passwordHash != null) 'password_hash': passwordHash,
      if (name != null) 'name': name,
      if (isAdmin != null) 'is_admin': isAdmin,
    };
  }

  static const _AccountUpdateDtoCopyWithSentinel _copyWithSentinel =
      _AccountUpdateDtoCopyWithSentinel();
  AccountUpdateDto copyWith({
    Object? id = _copyWithSentinel,
    Object? email = _copyWithSentinel,
    Object? passwordHash = _copyWithSentinel,
    Object? name = _copyWithSentinel,
    Object? isAdmin = _copyWithSentinel,
  }) {
    return AccountUpdateDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      email: identical(email, _copyWithSentinel)
          ? this.email
          : email as String?,
      passwordHash: identical(passwordHash, _copyWithSentinel)
          ? this.passwordHash
          : passwordHash as String?,
      name: identical(name, _copyWithSentinel) ? this.name : name as String?,
      isAdmin: identical(isAdmin, _copyWithSentinel)
          ? this.isAdmin
          : isAdmin as bool?,
    );
  }
}

class _AccountUpdateDtoCopyWithSentinel {
  const _AccountUpdateDtoCopyWithSentinel();
}

/// Partial projection for [Account].
///
/// All fields are nullable; intended for subset SELECTs.
class AccountPartial implements PartialEntity<$Account> {
  const AccountPartial({
    this.id,
    this.email,
    this.passwordHash,
    this.name,
    this.isAdmin,
  });

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory AccountPartial.fromRow(Map<String, Object?> row) {
    return AccountPartial(
      id: row['id'] as int?,
      email: row['email'] as String?,
      passwordHash: row['password_hash'] as String?,
      name: row['name'] as String?,
      isAdmin: row['is_admin'] as bool?,
    );
  }

  final int? id;
  final String? email;
  final String? passwordHash;
  final String? name;
  final bool? isAdmin;

  @override
  $Account toEntity() {
    // Basic required-field check: non-nullable fields must be present.
    final int? idValue = id;
    if (idValue == null) {
      throw StateError('Missing required field: id');
    }
    final String? emailValue = email;
    if (emailValue == null) {
      throw StateError('Missing required field: email');
    }
    final String? passwordHashValue = passwordHash;
    if (passwordHashValue == null) {
      throw StateError('Missing required field: passwordHash');
    }
    final bool? isAdminValue = isAdmin;
    if (isAdminValue == null) {
      throw StateError('Missing required field: isAdmin');
    }
    return $Account(
      id: idValue,
      email: emailValue,
      passwordHash: passwordHashValue,
      name: name,
      isAdmin: isAdminValue,
    );
  }

  @override
  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      if (email != null) 'email': email,
      if (passwordHash != null) 'password_hash': passwordHash,
      if (name != null) 'name': name,
      if (isAdmin != null) 'is_admin': isAdmin,
    };
  }

  static const _AccountPartialCopyWithSentinel _copyWithSentinel =
      _AccountPartialCopyWithSentinel();
  AccountPartial copyWith({
    Object? id = _copyWithSentinel,
    Object? email = _copyWithSentinel,
    Object? passwordHash = _copyWithSentinel,
    Object? name = _copyWithSentinel,
    Object? isAdmin = _copyWithSentinel,
  }) {
    return AccountPartial(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      email: identical(email, _copyWithSentinel)
          ? this.email
          : email as String?,
      passwordHash: identical(passwordHash, _copyWithSentinel)
          ? this.passwordHash
          : passwordHash as String?,
      name: identical(name, _copyWithSentinel) ? this.name : name as String?,
      isAdmin: identical(isAdmin, _copyWithSentinel)
          ? this.isAdmin
          : isAdmin as bool?,
    );
  }
}

class _AccountPartialCopyWithSentinel {
  const _AccountPartialCopyWithSentinel();
}

/// Generated tracked model class for [Account].
///
/// This class extends the user-defined [Account] model and adds
/// attribute tracking, change detection, and relationship management.
/// Instances of this class are returned by queries and repositories.
///
/// **Do not instantiate this class directly.** Use queries, repositories,
/// or model factories to create tracked model instances.
class $Account extends Account with ModelAttributes implements OrmEntity {
  /// Internal constructor for [$Account].
  $Account({
    int id = 0,
    required String email,
    required String passwordHash,
    String? name,
    required bool isAdmin,
  }) : super.new(
         id: id,
         email: email,
         passwordHash: passwordHash,
         name: name,
         isAdmin: isAdmin,
       ) {
    _attachOrmRuntimeMetadata({
      'id': id,
      'email': email,
      'password_hash': passwordHash,
      'name': name,
      'is_admin': isAdmin,
    });
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $Account.fromModel(Account model) {
    return $Account(
      id: model.id,
      email: model.email,
      passwordHash: model.passwordHash,
      name: model.name,
      isAdmin: model.isAdmin,
    );
  }

  $Account copyWith({
    int? id,
    String? email,
    String? passwordHash,
    String? name,
    bool? isAdmin,
  }) {
    return $Account(
      id: id ?? this.id,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      name: name ?? this.name,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }

  /// Builds a tracked model from a column/value map.
  static $Account fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$AccountDefinition.fromMap(data, registry: registry);

  /// Converts this tracked model to a column/value map.
  Map<String, Object?> toMap({ValueCodecRegistry? registry}) =>
      _$AccountDefinition.toMap(this, registry: registry);

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

  /// Tracked getter for [passwordHash].
  @override
  String get passwordHash =>
      getAttribute<String>('password_hash') ?? super.passwordHash;

  /// Tracked setter for [passwordHash].
  set passwordHash(String value) => setAttribute('password_hash', value);

  /// Tracked getter for [name].
  @override
  String? get name => getAttribute<String?>('name') ?? super.name;

  /// Tracked setter for [name].
  set name(String? value) => setAttribute('name', value);

  /// Tracked getter for [isAdmin].
  @override
  bool get isAdmin => getAttribute<bool>('is_admin') ?? super.isAdmin;

  /// Tracked setter for [isAdmin].
  set isAdmin(bool value) => setAttribute('is_admin', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$AccountDefinition);
  }
}

class _AccountCopyWithSentinel {
  const _AccountCopyWithSentinel();
}

extension AccountOrmExtension on Account {
  static const _AccountCopyWithSentinel _copyWithSentinel =
      _AccountCopyWithSentinel();
  Account copyWith({
    Object? id = _copyWithSentinel,
    Object? email = _copyWithSentinel,
    Object? passwordHash = _copyWithSentinel,
    Object? name = _copyWithSentinel,
    Object? isAdmin = _copyWithSentinel,
  }) {
    return Account.new(
      id: identical(id, _copyWithSentinel) ? this.id : id as int,
      email: identical(email, _copyWithSentinel) ? this.email : email as String,
      passwordHash: identical(passwordHash, _copyWithSentinel)
          ? this.passwordHash
          : passwordHash as String,
      name: identical(name, _copyWithSentinel) ? this.name : name as String?,
      isAdmin: identical(isAdmin, _copyWithSentinel)
          ? this.isAdmin
          : isAdmin as bool,
    );
  }

  /// Converts this model to a column/value map.
  Map<String, Object?> toMap({ValueCodecRegistry? registry}) =>
      _$AccountDefinition.toMap(this, registry: registry);

  /// Builds a model from a column/value map.
  static Account fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$AccountDefinition.fromMap(data, registry: registry);

  /// The Type of the generated ORM-managed model class.
  /// Use this when you need to specify the tracked model type explicitly,
  /// for example in generic type parameters.
  static Type get trackedType => $Account;

  /// Converts this immutable model to a tracked ORM-managed model.
  /// The tracked model supports attribute tracking, change detection,
  /// and persistence operations like save() and touch().
  $Account toTracked() {
    return $Account.fromModel(this);
  }
}

extension $AccountAccessors on $Account {
  String get displayName {
    return Account.displayName(this, getRawAttribute('display_name'));
  }

  String normalizeEmail(String? value) {
    final result = Account.normalizeEmail(this, value as String?);
    setRawAttribute('email', result);
    return result;
  }
}

extension AccountPredicateFields on PredicateBuilder<Account> {
  PredicateField<Account, int> get id =>
      PredicateField<Account, int>(this, 'id');
  PredicateField<Account, String> get email =>
      PredicateField<Account, String>(this, 'email');
  PredicateField<Account, String> get passwordHash =>
      PredicateField<Account, String>(this, 'passwordHash');
  PredicateField<Account, String?> get name =>
      PredicateField<Account, String?>(this, 'name');
  PredicateField<Account, bool> get isAdmin =>
      PredicateField<Account, bool>(this, 'isAdmin');
}

void registerAccountEventHandlers(EventBus bus) {
  // No event handlers registered for Account.
}
