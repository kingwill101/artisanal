// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'model_events.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$EventUserIdField = FieldDefinition(
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

const FieldDefinition _$EventUserEmailField = FieldDefinition(
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

const FieldDefinition _$EventUserActiveField = FieldDefinition(
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

const FieldDefinition _$EventUserNameField = FieldDefinition(
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

const FieldDefinition _$EventUserDeletedAtField = FieldDefinition(
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

Map<String, Object?> _encodeEventUserUntracked(
  Object model,
  ValueCodecRegistry registry,
) {
  final m = model as EventUser;
  return <String, Object?>{
    'id': registry.encodeField(_$EventUserIdField, m.id),
    'email': registry.encodeField(_$EventUserEmailField, m.email),
    'active': registry.encodeField(_$EventUserActiveField, m.active),
    'name': registry.encodeField(_$EventUserNameField, m.name),
  };
}

final ModelDefinition<$EventUser> _$EventUserDefinition = ModelDefinition(
  modelName: 'EventUser',
  tableName: 'event_users',
  fields: const [
    _$EventUserIdField,
    _$EventUserEmailField,
    _$EventUserActiveField,
    _$EventUserNameField,
    _$EventUserDeletedAtField,
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
    softDeletes: true,
    softDeleteColumn: 'deleted_at',
  ),
  untrackedToMap: _encodeEventUserUntracked,
  codec: _$EventUserCodec(),
);

extension EventUserOrmDefinition on EventUser {
  static ModelDefinition<$EventUser> get definition => _$EventUserDefinition;
}

class EventUsers {
  const EventUsers._();

  /// Starts building a query for [$EventUser].
  ///
  /// {@macro ormed.query}
  static Query<$EventUser> query([String? connection]) =>
      Model.query<$EventUser>(connection: connection);

  static Future<$EventUser?> find(Object id, {String? connection}) =>
      Model.find<$EventUser>(id, connection: connection);

  static Future<$EventUser> findOrFail(Object id, {String? connection}) =>
      Model.findOrFail<$EventUser>(id, connection: connection);

  static Future<List<$EventUser>> all({String? connection}) =>
      Model.all<$EventUser>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<$EventUser>(connection: connection);

  static Future<bool> anyExist({String? connection}) =>
      Model.anyExist<$EventUser>(connection: connection);

  static Query<$EventUser> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) =>
      Model.where<$EventUser>(column, operator, value, connection: connection);

  static Query<$EventUser> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<$EventUser>(column, values, connection: connection);

  static Query<$EventUser> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<$EventUser>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<$EventUser> limit(int count, {String? connection}) =>
      Model.limit<$EventUser>(count, connection: connection);

  /// Creates a [Repository] for [$EventUser].
  ///
  /// {@macro ormed.repository}
  static Repository<$EventUser> repo([String? connection]) =>
      Model.repository<$EventUser>(connection: connection);
}

class EventUserModelFactory {
  const EventUserModelFactory._();

  static ModelDefinition<$EventUser> get definition => _$EventUserDefinition;

  static ModelCodec<$EventUser> get codec => definition.codec;

  static EventUser fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    EventUser model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model.toTracked(), registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<EventUser> withConnection(
    QueryContext context,
  ) => ModelFactoryConnection<EventUser>(
    definition: definition,
    context: context,
  );

  static ModelFactoryBuilder<EventUser> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<EventUser>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$EventUserCodec extends ModelCodec<$EventUser> {
  const _$EventUserCodec();
  @override
  Map<String, Object?> encode($EventUser model, ValueCodecRegistry registry) {
    return <String, Object?>{
      'id': registry.encodeField(_$EventUserIdField, model.id),
      'email': registry.encodeField(_$EventUserEmailField, model.email),
      'active': registry.encodeField(_$EventUserActiveField, model.active),
      'name': registry.encodeField(_$EventUserNameField, model.name),
      if (model.hasAttribute('deleted_at'))
        'deleted_at': registry.encodeField(
          _$EventUserDeletedAtField,
          model.getAttribute<DateTime?>('deleted_at'),
        ),
    };
  }

  @override
  $EventUser decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final int eventUserIdValue =
        registry.decodeField<int>(_$EventUserIdField, data['id']) ?? 0;
    final String eventUserEmailValue =
        registry.decodeField<String>(_$EventUserEmailField, data['email']) ??
        (throw StateError('Field email on EventUser cannot be null.'));
    final bool eventUserActiveValue =
        registry.decodeField<bool>(_$EventUserActiveField, data['active']) ??
        (throw StateError('Field active on EventUser cannot be null.'));
    final String? eventUserNameValue = registry.decodeField<String?>(
      _$EventUserNameField,
      data['name'],
    );
    final DateTime? eventUserDeletedAtValue = registry.decodeField<DateTime?>(
      _$EventUserDeletedAtField,
      data['deleted_at'],
    );
    final model = $EventUser(
      id: eventUserIdValue,
      email: eventUserEmailValue,
      active: eventUserActiveValue,
      name: eventUserNameValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': eventUserIdValue,
      'email': eventUserEmailValue,
      'active': eventUserActiveValue,
      'name': eventUserNameValue,
      if (data.containsKey('deleted_at')) 'deleted_at': eventUserDeletedAtValue,
    });
    return model;
  }
}

/// Insert DTO for [EventUser].
///
/// Auto-increment/DB-generated fields are omitted by default.
class EventUserInsertDto implements InsertDto<$EventUser> {
  const EventUserInsertDto({this.email, this.active, this.name});
  final String? email;
  final bool? active;
  final String? name;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (email != null) 'email': email,
      if (active != null) 'active': active,
      if (name != null) 'name': name,
    };
  }

  static const _EventUserInsertDtoCopyWithSentinel _copyWithSentinel =
      _EventUserInsertDtoCopyWithSentinel();
  EventUserInsertDto copyWith({
    Object? email = _copyWithSentinel,
    Object? active = _copyWithSentinel,
    Object? name = _copyWithSentinel,
  }) {
    return EventUserInsertDto(
      email: identical(email, _copyWithSentinel)
          ? this.email
          : email as String?,
      active: identical(active, _copyWithSentinel)
          ? this.active
          : active as bool?,
      name: identical(name, _copyWithSentinel) ? this.name : name as String?,
    );
  }
}

class _EventUserInsertDtoCopyWithSentinel {
  const _EventUserInsertDtoCopyWithSentinel();
}

/// Update DTO for [EventUser].
///
/// All fields are optional; only provided entries are used in SET clauses.
class EventUserUpdateDto implements UpdateDto<$EventUser> {
  const EventUserUpdateDto({this.id, this.email, this.active, this.name});
  final int? id;
  final String? email;
  final bool? active;
  final String? name;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (email != null) 'email': email,
      if (active != null) 'active': active,
      if (name != null) 'name': name,
    };
  }

  static const _EventUserUpdateDtoCopyWithSentinel _copyWithSentinel =
      _EventUserUpdateDtoCopyWithSentinel();
  EventUserUpdateDto copyWith({
    Object? id = _copyWithSentinel,
    Object? email = _copyWithSentinel,
    Object? active = _copyWithSentinel,
    Object? name = _copyWithSentinel,
  }) {
    return EventUserUpdateDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      email: identical(email, _copyWithSentinel)
          ? this.email
          : email as String?,
      active: identical(active, _copyWithSentinel)
          ? this.active
          : active as bool?,
      name: identical(name, _copyWithSentinel) ? this.name : name as String?,
    );
  }
}

class _EventUserUpdateDtoCopyWithSentinel {
  const _EventUserUpdateDtoCopyWithSentinel();
}

/// Partial projection for [EventUser].
///
/// All fields are nullable; intended for subset SELECTs.
class EventUserPartial implements PartialEntity<$EventUser> {
  const EventUserPartial({this.id, this.email, this.active, this.name});

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory EventUserPartial.fromRow(Map<String, Object?> row) {
    return EventUserPartial(
      id: row['id'] as int?,
      email: row['email'] as String?,
      active: row['active'] as bool?,
      name: row['name'] as String?,
    );
  }

  final int? id;
  final String? email;
  final bool? active;
  final String? name;

  @override
  $EventUser toEntity() {
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
    return $EventUser(
      id: idValue,
      email: emailValue,
      active: activeValue,
      name: name,
    );
  }

  @override
  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      if (email != null) 'email': email,
      if (active != null) 'active': active,
      if (name != null) 'name': name,
    };
  }

  static const _EventUserPartialCopyWithSentinel _copyWithSentinel =
      _EventUserPartialCopyWithSentinel();
  EventUserPartial copyWith({
    Object? id = _copyWithSentinel,
    Object? email = _copyWithSentinel,
    Object? active = _copyWithSentinel,
    Object? name = _copyWithSentinel,
  }) {
    return EventUserPartial(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      email: identical(email, _copyWithSentinel)
          ? this.email
          : email as String?,
      active: identical(active, _copyWithSentinel)
          ? this.active
          : active as bool?,
      name: identical(name, _copyWithSentinel) ? this.name : name as String?,
    );
  }
}

class _EventUserPartialCopyWithSentinel {
  const _EventUserPartialCopyWithSentinel();
}

/// Generated tracked model class for [EventUser].
///
/// This class extends the user-defined [EventUser] model and adds
/// attribute tracking, change detection, and relationship management.
/// Instances of this class are returned by queries and repositories.
///
/// **Do not instantiate this class directly.** Use queries, repositories,
/// or model factories to create tracked model instances.
class $EventUser extends EventUser
    with ModelAttributes, SoftDeletesImpl
    implements OrmEntity {
  /// Internal constructor for [$EventUser].
  $EventUser({
    int id = 0,
    required String email,
    required bool active,
    String? name,
  }) : super.new(id: id, email: email, active: active, name: name) {
    _attachOrmRuntimeMetadata({
      'id': id,
      'email': email,
      'active': active,
      'name': name,
    });
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $EventUser.fromModel(EventUser model) {
    return $EventUser(
      id: model.id,
      email: model.email,
      active: model.active,
      name: model.name,
    );
  }

  $EventUser copyWith({int? id, String? email, bool? active, String? name}) {
    return $EventUser(
      id: id ?? this.id,
      email: email ?? this.email,
      active: active ?? this.active,
      name: name ?? this.name,
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

  /// Tracked getter for [name].
  @override
  String? get name => getAttribute<String?>('name') ?? super.name;

  /// Tracked setter for [name].
  set name(String? value) => setAttribute('name', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$EventUserDefinition);
    attachSoftDeleteColumn('deleted_at');
  }
}

extension EventUserOrmExtension on EventUser {
  /// The Type of the generated ORM-managed model class.
  /// Use this when you need to specify the tracked model type explicitly,
  /// for example in generic type parameters.
  static Type get trackedType => $EventUser;

  /// Converts this immutable model to a tracked ORM-managed model.
  /// The tracked model supports attribute tracking, change detection,
  /// and persistence operations like save() and touch().
  $EventUser toTracked() {
    return $EventUser.fromModel(this);
  }
}

extension EventUserPredicateFields on PredicateBuilder<EventUser> {
  PredicateField<EventUser, int> get id =>
      PredicateField<EventUser, int>(this, 'id');
  PredicateField<EventUser, String> get email =>
      PredicateField<EventUser, String>(this, 'email');
  PredicateField<EventUser, bool> get active =>
      PredicateField<EventUser, bool>(this, 'active');
  PredicateField<EventUser, String?> get name =>
      PredicateField<EventUser, String?>(this, 'name');
}

void registerEventUserEventHandlers(EventBus bus) {
  // No event handlers registered for EventUser.
}

const FieldDefinition _$AuditedUserIdField = FieldDefinition(
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

const FieldDefinition _$AuditedUserEmailField = FieldDefinition(
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

Map<String, Object?> _encodeAuditedUserUntracked(
  Object model,
  ValueCodecRegistry registry,
) {
  final m = model as AuditedUser;
  return <String, Object?>{
    'id': registry.encodeField(_$AuditedUserIdField, m.id),
    'email': registry.encodeField(_$AuditedUserEmailField, m.email),
  };
}

final ModelDefinition<$AuditedUser> _$AuditedUserDefinition = ModelDefinition(
  modelName: 'AuditedUser',
  tableName: 'audited_users',
  fields: const [_$AuditedUserIdField, _$AuditedUserEmailField],
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
  untrackedToMap: _encodeAuditedUserUntracked,
  codec: _$AuditedUserCodec(),
);

extension AuditedUserOrmDefinition on AuditedUser {
  static ModelDefinition<$AuditedUser> get definition =>
      _$AuditedUserDefinition;
}

class AuditedUsers {
  const AuditedUsers._();

  /// Starts building a query for [$AuditedUser].
  ///
  /// {@macro ormed.query}
  static Query<$AuditedUser> query([String? connection]) =>
      Model.query<$AuditedUser>(connection: connection);

  static Future<$AuditedUser?> find(Object id, {String? connection}) =>
      Model.find<$AuditedUser>(id, connection: connection);

  static Future<$AuditedUser> findOrFail(Object id, {String? connection}) =>
      Model.findOrFail<$AuditedUser>(id, connection: connection);

  static Future<List<$AuditedUser>> all({String? connection}) =>
      Model.all<$AuditedUser>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<$AuditedUser>(connection: connection);

  static Future<bool> anyExist({String? connection}) =>
      Model.anyExist<$AuditedUser>(connection: connection);

  static Query<$AuditedUser> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) => Model.where<$AuditedUser>(
    column,
    operator,
    value,
    connection: connection,
  );

  static Query<$AuditedUser> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<$AuditedUser>(column, values, connection: connection);

  static Query<$AuditedUser> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<$AuditedUser>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<$AuditedUser> limit(int count, {String? connection}) =>
      Model.limit<$AuditedUser>(count, connection: connection);

  /// Creates a [Repository] for [$AuditedUser].
  ///
  /// {@macro ormed.repository}
  static Repository<$AuditedUser> repo([String? connection]) =>
      Model.repository<$AuditedUser>(connection: connection);
}

class AuditedUserModelFactory {
  const AuditedUserModelFactory._();

  static ModelDefinition<$AuditedUser> get definition =>
      _$AuditedUserDefinition;

  static ModelCodec<$AuditedUser> get codec => definition.codec;

  static AuditedUser fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    AuditedUser model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model.toTracked(), registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<AuditedUser> withConnection(
    QueryContext context,
  ) => ModelFactoryConnection<AuditedUser>(
    definition: definition,
    context: context,
  );

  static ModelFactoryBuilder<AuditedUser> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<AuditedUser>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$AuditedUserCodec extends ModelCodec<$AuditedUser> {
  const _$AuditedUserCodec();
  @override
  Map<String, Object?> encode($AuditedUser model, ValueCodecRegistry registry) {
    return <String, Object?>{
      'id': registry.encodeField(_$AuditedUserIdField, model.id),
      'email': registry.encodeField(_$AuditedUserEmailField, model.email),
    };
  }

  @override
  $AuditedUser decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final int auditedUserIdValue =
        registry.decodeField<int>(_$AuditedUserIdField, data['id']) ?? 0;
    final String auditedUserEmailValue =
        registry.decodeField<String>(_$AuditedUserEmailField, data['email']) ??
        (throw StateError('Field email on AuditedUser cannot be null.'));
    final model = $AuditedUser(
      id: auditedUserIdValue,
      email: auditedUserEmailValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': auditedUserIdValue,
      'email': auditedUserEmailValue,
    });
    return model;
  }
}

/// Insert DTO for [AuditedUser].
///
/// Auto-increment/DB-generated fields are omitted by default.
class AuditedUserInsertDto implements InsertDto<$AuditedUser> {
  const AuditedUserInsertDto({this.email});
  final String? email;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{if (email != null) 'email': email};
  }

  static const _AuditedUserInsertDtoCopyWithSentinel _copyWithSentinel =
      _AuditedUserInsertDtoCopyWithSentinel();
  AuditedUserInsertDto copyWith({Object? email = _copyWithSentinel}) {
    return AuditedUserInsertDto(
      email: identical(email, _copyWithSentinel)
          ? this.email
          : email as String?,
    );
  }
}

class _AuditedUserInsertDtoCopyWithSentinel {
  const _AuditedUserInsertDtoCopyWithSentinel();
}

/// Update DTO for [AuditedUser].
///
/// All fields are optional; only provided entries are used in SET clauses.
class AuditedUserUpdateDto implements UpdateDto<$AuditedUser> {
  const AuditedUserUpdateDto({this.id, this.email});
  final int? id;
  final String? email;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (email != null) 'email': email,
    };
  }

  static const _AuditedUserUpdateDtoCopyWithSentinel _copyWithSentinel =
      _AuditedUserUpdateDtoCopyWithSentinel();
  AuditedUserUpdateDto copyWith({
    Object? id = _copyWithSentinel,
    Object? email = _copyWithSentinel,
  }) {
    return AuditedUserUpdateDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      email: identical(email, _copyWithSentinel)
          ? this.email
          : email as String?,
    );
  }
}

class _AuditedUserUpdateDtoCopyWithSentinel {
  const _AuditedUserUpdateDtoCopyWithSentinel();
}

/// Partial projection for [AuditedUser].
///
/// All fields are nullable; intended for subset SELECTs.
class AuditedUserPartial implements PartialEntity<$AuditedUser> {
  const AuditedUserPartial({this.id, this.email});

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory AuditedUserPartial.fromRow(Map<String, Object?> row) {
    return AuditedUserPartial(
      id: row['id'] as int?,
      email: row['email'] as String?,
    );
  }

  final int? id;
  final String? email;

  @override
  $AuditedUser toEntity() {
    // Basic required-field check: non-nullable fields must be present.
    final int? idValue = id;
    if (idValue == null) {
      throw StateError('Missing required field: id');
    }
    final String? emailValue = email;
    if (emailValue == null) {
      throw StateError('Missing required field: email');
    }
    return $AuditedUser(id: idValue, email: emailValue);
  }

  @override
  Map<String, Object?> toMap() {
    return {if (id != null) 'id': id, if (email != null) 'email': email};
  }

  static const _AuditedUserPartialCopyWithSentinel _copyWithSentinel =
      _AuditedUserPartialCopyWithSentinel();
  AuditedUserPartial copyWith({
    Object? id = _copyWithSentinel,
    Object? email = _copyWithSentinel,
  }) {
    return AuditedUserPartial(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      email: identical(email, _copyWithSentinel)
          ? this.email
          : email as String?,
    );
  }
}

class _AuditedUserPartialCopyWithSentinel {
  const _AuditedUserPartialCopyWithSentinel();
}

/// Generated tracked model class for [AuditedUser].
///
/// This class extends the user-defined [AuditedUser] model and adds
/// attribute tracking, change detection, and relationship management.
/// Instances of this class are returned by queries and repositories.
///
/// **Do not instantiate this class directly.** Use queries, repositories,
/// or model factories to create tracked model instances.
class $AuditedUser extends AuditedUser
    with ModelAttributes
    implements OrmEntity {
  /// Internal constructor for [$AuditedUser].
  $AuditedUser({int id = 0, required String email})
    : super.new(id: id, email: email) {
    _attachOrmRuntimeMetadata({'id': id, 'email': email});
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $AuditedUser.fromModel(AuditedUser model) {
    return $AuditedUser(id: model.id, email: model.email);
  }

  $AuditedUser copyWith({int? id, String? email}) {
    return $AuditedUser(id: id ?? this.id, email: email ?? this.email);
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

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$AuditedUserDefinition);
  }
}

extension AuditedUserOrmExtension on AuditedUser {
  /// The Type of the generated ORM-managed model class.
  /// Use this when you need to specify the tracked model type explicitly,
  /// for example in generic type parameters.
  static Type get trackedType => $AuditedUser;

  /// Converts this immutable model to a tracked ORM-managed model.
  /// The tracked model supports attribute tracking, change detection,
  /// and persistence operations like save() and touch().
  $AuditedUser toTracked() {
    return $AuditedUser.fromModel(this);
  }
}

extension AuditedUserPredicateFields on PredicateBuilder<AuditedUser> {
  PredicateField<AuditedUser, int> get id =>
      PredicateField<AuditedUser, int>(this, 'id');
  PredicateField<AuditedUser, String> get email =>
      PredicateField<AuditedUser, String>(this, 'email');
}

void registerAuditedUserEventHandlers(EventBus bus) {
  bus.on<ModelSavingEvent>((event) {
    if (event.modelType != AuditedUser && event.modelType != $AuditedUser) {
      return;
    }
    AuditedUser.onSaving(event);
  });
  bus.on<ModelCreatedEvent>((event) {
    if (event.modelType != AuditedUser && event.modelType != $AuditedUser) {
      return;
    }
    AuditedUser.onCreated(event);
  });
  bus.on<ModelForceDeletedEvent>((event) {
    if (event.modelType != AuditedUser && event.modelType != $AuditedUser) {
      return;
    }
    AuditedUser.onForceDeleted(event);
  });
}
