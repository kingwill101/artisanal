// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'active_user.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$ActiveUserIdField = FieldDefinition(
  name: 'id',
  columnName: 'id',
  dartType: 'int',
  resolvedType: 'int?',
  isPrimaryKey: true,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: true,
);

const FieldDefinition _$ActiveUserEmailField = FieldDefinition(
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

const FieldDefinition _$ActiveUserNameField = FieldDefinition(
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

const FieldDefinition _$ActiveUserSettingsField = FieldDefinition(
  name: 'settings',
  columnName: 'settings',
  dartType: 'Map<String, Object?>',
  resolvedType: 'Map<String, Object?>',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
  columnType: 'json',
);

const FieldDefinition _$ActiveUserDeletedAtField = FieldDefinition(
  name: 'deletedAt',
  columnName: 'deleted_at',
  dartType: 'DateTime',
  resolvedType: 'DateTime?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

Map<String, Object?> _encodeActiveUserUntracked(
  Object model,
  ValueCodecRegistry registry,
) {
  final m = model as ActiveUser;
  return <String, Object?>{
    'id': registry.encodeField(_$ActiveUserIdField, m.id),
    'email': registry.encodeField(_$ActiveUserEmailField, m.email),
    'name': registry.encodeField(_$ActiveUserNameField, m.name),
    'settings': registry.encodeField(_$ActiveUserSettingsField, m.settings),
  };
}

final ModelDefinition<$ActiveUser> _$ActiveUserDefinition = ModelDefinition(
  modelName: 'ActiveUser',
  tableName: 'active_users',
  fields: const [
    _$ActiveUserIdField,
    _$ActiveUserEmailField,
    _$ActiveUserNameField,
    _$ActiveUserSettingsField,
    _$ActiveUserDeletedAtField,
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
    connection: 'analytics',
    softDeletes: true,
    softDeleteColumn: 'deleted_at',
  ),
  untrackedToMap: _encodeActiveUserUntracked,
  codec: _$ActiveUserCodec(),
);

// ignore: unused_element
final activeuserModelDefinitionRegistration =
    ModelFactoryRegistry.register<$ActiveUser>(_$ActiveUserDefinition);

extension ActiveUserOrmDefinition on ActiveUser {
  static ModelDefinition<$ActiveUser> get definition => _$ActiveUserDefinition;
}

class ActiveUsers {
  const ActiveUsers._();

  /// Starts building a query for [$ActiveUser].
  ///
  /// {@macro ormed.query}
  static Query<$ActiveUser> query([String? connection]) =>
      Model.query<$ActiveUser>(connection: connection);

  static Future<$ActiveUser?> find(Object id, {String? connection}) =>
      Model.find<$ActiveUser>(id, connection: connection);

  static Future<$ActiveUser> findOrFail(Object id, {String? connection}) =>
      Model.findOrFail<$ActiveUser>(id, connection: connection);

  static Future<List<$ActiveUser>> all({String? connection}) =>
      Model.all<$ActiveUser>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<$ActiveUser>(connection: connection);

  static Future<bool> anyExist({String? connection}) =>
      Model.anyExist<$ActiveUser>(connection: connection);

  static Query<$ActiveUser> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) =>
      Model.where<$ActiveUser>(column, operator, value, connection: connection);

  static Query<$ActiveUser> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<$ActiveUser>(column, values, connection: connection);

  static Query<$ActiveUser> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<$ActiveUser>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<$ActiveUser> limit(int count, {String? connection}) =>
      Model.limit<$ActiveUser>(count, connection: connection);

  /// Creates a [Repository] for [$ActiveUser].
  ///
  /// {@macro ormed.repository}
  static Repository<$ActiveUser> repo([String? connection]) =>
      Model.repository<$ActiveUser>(connection: connection);
}

class ActiveUserModelFactory {
  const ActiveUserModelFactory._();

  static ModelDefinition<$ActiveUser> get definition => _$ActiveUserDefinition;

  static ModelCodec<$ActiveUser> get codec => definition.codec;

  static ActiveUser fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    ActiveUser model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model.toTracked(), registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<ActiveUser> withConnection(
    QueryContext context,
  ) => ModelFactoryConnection<ActiveUser>(
    definition: definition,
    context: context,
  );

  static ModelFactoryBuilder<ActiveUser> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<ActiveUser>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$ActiveUserCodec extends ModelCodec<$ActiveUser> {
  const _$ActiveUserCodec();
  @override
  Map<String, Object?> encode($ActiveUser model, ValueCodecRegistry registry) {
    return <String, Object?>{
      'id': registry.encodeField(_$ActiveUserIdField, model.id),
      'email': registry.encodeField(_$ActiveUserEmailField, model.email),
      'name': registry.encodeField(_$ActiveUserNameField, model.name),
      'settings': registry.encodeField(
        _$ActiveUserSettingsField,
        model.settings,
      ),
      if (model.hasAttribute('deleted_at'))
        'deleted_at': registry.encodeField(
          _$ActiveUserDeletedAtField,
          model.getAttribute<DateTime?>('deleted_at'),
        ),
    };
  }

  @override
  $ActiveUser decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final int? activeUserIdValue = registry.decodeField<int?>(
      _$ActiveUserIdField,
      data['id'],
    );
    final String activeUserEmailValue =
        registry.decodeField<String>(_$ActiveUserEmailField, data['email']) ??
        (throw StateError('Field email on ActiveUser cannot be null.'));
    final String? activeUserNameValue = registry.decodeField<String?>(
      _$ActiveUserNameField,
      data['name'],
    );
    final Map<String, Object?> activeUserSettingsValue =
        registry.decodeField<Map<String, Object?>>(
          _$ActiveUserSettingsField,
          data['settings'],
        ) ??
        (throw StateError('Field settings on ActiveUser cannot be null.'));
    final DateTime? activeUserDeletedAtValue = registry.decodeField<DateTime?>(
      _$ActiveUserDeletedAtField,
      data['deleted_at'],
    );
    final model = $ActiveUser(
      id: activeUserIdValue,
      email: activeUserEmailValue,
      name: activeUserNameValue,
      settings: activeUserSettingsValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': activeUserIdValue,
      'email': activeUserEmailValue,
      'name': activeUserNameValue,
      'settings': activeUserSettingsValue,
      if (data.containsKey('deleted_at'))
        'deleted_at': activeUserDeletedAtValue,
    });
    return model;
  }
}

/// Insert DTO for [ActiveUser].
///
/// Auto-increment/DB-generated fields are omitted by default.
class ActiveUserInsertDto implements InsertDto<$ActiveUser> {
  const ActiveUserInsertDto({this.email, this.name, this.settings});
  final String? email;
  final String? name;
  final Map<String, Object?>? settings;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (email != null) 'email': email,
      if (name != null) 'name': name,
      if (settings != null) 'settings': settings,
    };
  }

  static const _ActiveUserInsertDtoCopyWithSentinel _copyWithSentinel =
      _ActiveUserInsertDtoCopyWithSentinel();
  ActiveUserInsertDto copyWith({
    Object? email = _copyWithSentinel,
    Object? name = _copyWithSentinel,
    Object? settings = _copyWithSentinel,
  }) {
    return ActiveUserInsertDto(
      email: identical(email, _copyWithSentinel)
          ? this.email
          : email as String?,
      name: identical(name, _copyWithSentinel) ? this.name : name as String?,
      settings: identical(settings, _copyWithSentinel)
          ? this.settings
          : settings as Map<String, Object?>?,
    );
  }
}

class _ActiveUserInsertDtoCopyWithSentinel {
  const _ActiveUserInsertDtoCopyWithSentinel();
}

/// Update DTO for [ActiveUser].
///
/// All fields are optional; only provided entries are used in SET clauses.
class ActiveUserUpdateDto implements UpdateDto<$ActiveUser> {
  const ActiveUserUpdateDto({this.id, this.email, this.name, this.settings});
  final int? id;
  final String? email;
  final String? name;
  final Map<String, Object?>? settings;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (email != null) 'email': email,
      if (name != null) 'name': name,
      if (settings != null) 'settings': settings,
    };
  }

  static const _ActiveUserUpdateDtoCopyWithSentinel _copyWithSentinel =
      _ActiveUserUpdateDtoCopyWithSentinel();
  ActiveUserUpdateDto copyWith({
    Object? id = _copyWithSentinel,
    Object? email = _copyWithSentinel,
    Object? name = _copyWithSentinel,
    Object? settings = _copyWithSentinel,
  }) {
    return ActiveUserUpdateDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      email: identical(email, _copyWithSentinel)
          ? this.email
          : email as String?,
      name: identical(name, _copyWithSentinel) ? this.name : name as String?,
      settings: identical(settings, _copyWithSentinel)
          ? this.settings
          : settings as Map<String, Object?>?,
    );
  }
}

class _ActiveUserUpdateDtoCopyWithSentinel {
  const _ActiveUserUpdateDtoCopyWithSentinel();
}

/// Partial projection for [ActiveUser].
///
/// All fields are nullable; intended for subset SELECTs.
class ActiveUserPartial implements PartialEntity<$ActiveUser> {
  const ActiveUserPartial({this.id, this.email, this.name, this.settings});

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory ActiveUserPartial.fromRow(Map<String, Object?> row) {
    return ActiveUserPartial(
      id: row['id'] as int?,
      email: row['email'] as String?,
      name: row['name'] as String?,
      settings: row['settings'] as Map<String, Object?>?,
    );
  }

  final int? id;
  final String? email;
  final String? name;
  final Map<String, Object?>? settings;

  @override
  $ActiveUser toEntity() {
    // Basic required-field check: non-nullable fields must be present.
    final String? emailValue = email;
    if (emailValue == null) {
      throw StateError('Missing required field: email');
    }
    final Map<String, Object?>? settingsValue = settings;
    if (settingsValue == null) {
      throw StateError('Missing required field: settings');
    }
    return $ActiveUser(
      id: id,
      email: emailValue,
      name: name,
      settings: settingsValue,
    );
  }

  @override
  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      if (email != null) 'email': email,
      if (name != null) 'name': name,
      if (settings != null) 'settings': settings,
    };
  }

  static const _ActiveUserPartialCopyWithSentinel _copyWithSentinel =
      _ActiveUserPartialCopyWithSentinel();
  ActiveUserPartial copyWith({
    Object? id = _copyWithSentinel,
    Object? email = _copyWithSentinel,
    Object? name = _copyWithSentinel,
    Object? settings = _copyWithSentinel,
  }) {
    return ActiveUserPartial(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      email: identical(email, _copyWithSentinel)
          ? this.email
          : email as String?,
      name: identical(name, _copyWithSentinel) ? this.name : name as String?,
      settings: identical(settings, _copyWithSentinel)
          ? this.settings
          : settings as Map<String, Object?>?,
    );
  }
}

class _ActiveUserPartialCopyWithSentinel {
  const _ActiveUserPartialCopyWithSentinel();
}

/// Generated tracked model class for [ActiveUser].
///
/// This class extends the user-defined [ActiveUser] model and adds
/// attribute tracking, change detection, and relationship management.
/// Instances of this class are returned by queries and repositories.
///
/// **Do not instantiate this class directly.** Use queries, repositories,
/// or model factories to create tracked model instances.
class $ActiveUser extends ActiveUser
    with ModelAttributes, SoftDeletesImpl
    implements OrmEntity {
  /// Internal constructor for [$ActiveUser].
  $ActiveUser({
    int? id,
    required String email,
    String? name,
    required Map<String, Object?> settings,
  }) : super.new(id: id, email: email, name: name, settings: settings) {
    _attachOrmRuntimeMetadata({
      'id': id,
      'email': email,
      'name': name,
      'settings': settings,
    });
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $ActiveUser.fromModel(ActiveUser model) {
    return $ActiveUser(
      id: model.id,
      email: model.email,
      name: model.name,
      settings: model.settings,
    );
  }

  $ActiveUser copyWith({
    int? id,
    String? email,
    String? name,
    Map<String, Object?>? settings,
  }) {
    return $ActiveUser(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      settings: settings ?? this.settings,
    );
  }

  /// Tracked getter for [id].
  @override
  int? get id => getAttribute<int?>('id') ?? super.id;

  /// Tracked setter for [id].
  set id(int? value) => setAttribute('id', value);

  /// Tracked getter for [email].
  @override
  String get email => getAttribute<String>('email') ?? super.email;

  /// Tracked setter for [email].
  set email(String value) => setAttribute('email', value);

  /// Tracked getter for [name].
  @override
  String? get name => getAttribute<String?>('name') ?? super.name;

  /// Tracked setter for [name].
  set name(String? value) => setAttribute('name', value);

  /// Tracked getter for [settings].
  @override
  Map<String, Object?> get settings =>
      getAttribute<Map<String, Object?>>('settings') ?? super.settings;

  /// Tracked setter for [settings].
  set settings(Map<String, Object?> value) => setAttribute('settings', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$ActiveUserDefinition);
    attachSoftDeleteColumn('deleted_at');
  }
}

extension ActiveUserOrmExtension on ActiveUser {
  /// The Type of the generated ORM-managed model class.
  /// Use this when you need to specify the tracked model type explicitly,
  /// for example in generic type parameters.
  static Type get trackedType => $ActiveUser;

  /// Converts this immutable model to a tracked ORM-managed model.
  /// The tracked model supports attribute tracking, change detection,
  /// and persistence operations like save() and touch().
  $ActiveUser toTracked() {
    return $ActiveUser.fromModel(this);
  }
}

extension ActiveUserPredicateFields on PredicateBuilder<ActiveUser> {
  PredicateField<ActiveUser, int?> get id =>
      PredicateField<ActiveUser, int?>(this, 'id');
  PredicateField<ActiveUser, String> get email =>
      PredicateField<ActiveUser, String>(this, 'email');
  PredicateField<ActiveUser, String?> get name =>
      PredicateField<ActiveUser, String?>(this, 'name');
  PredicateField<ActiveUser, Map<String, Object?>> get settings =>
      PredicateField<ActiveUser, Map<String, Object?>>(this, 'settings');
}

void registerActiveUserEventHandlers(EventBus bus) {
  // No event handlers registered for ActiveUser.
}
