// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'factory_user.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$FactoryUserIdField = FieldDefinition(
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

const FieldDefinition _$FactoryUserEmailField = FieldDefinition(
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

const FieldDefinition _$FactoryUserNameField = FieldDefinition(
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

Map<String, Object?> _encodeFactoryUserUntracked(
  Object model,
  ValueCodecRegistry registry,
) {
  final m = model as FactoryUser;
  return <String, Object?>{
    'id': registry.encodeField(_$FactoryUserIdField, m.id),
    'email': registry.encodeField(_$FactoryUserEmailField, m.email),
    'name': registry.encodeField(_$FactoryUserNameField, m.name),
  };
}

final ModelDefinition<$FactoryUser> _$FactoryUserDefinition = ModelDefinition(
  modelName: 'FactoryUser',
  tableName: 'users',
  fields: const [
    _$FactoryUserIdField,
    _$FactoryUserEmailField,
    _$FactoryUserNameField,
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
  untrackedToMap: _encodeFactoryUserUntracked,
  codec: _$FactoryUserCodec(),
);

// ignore: unused_element
final factoryuserModelDefinitionRegistration =
    ModelFactoryRegistry.register<$FactoryUser>(_$FactoryUserDefinition);

extension FactoryUserOrmDefinition on FactoryUser {
  static ModelDefinition<$FactoryUser> get definition =>
      _$FactoryUserDefinition;
}

class FactoryUsers {
  const FactoryUsers._();

  /// Starts building a query for [$FactoryUser].
  ///
  /// {@macro ormed.query}
  static Query<$FactoryUser> query([String? connection]) =>
      Model.query<$FactoryUser>(connection: connection);

  static Future<$FactoryUser?> find(Object id, {String? connection}) =>
      Model.find<$FactoryUser>(id, connection: connection);

  static Future<$FactoryUser> findOrFail(Object id, {String? connection}) =>
      Model.findOrFail<$FactoryUser>(id, connection: connection);

  static Future<List<$FactoryUser>> all({String? connection}) =>
      Model.all<$FactoryUser>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<$FactoryUser>(connection: connection);

  static Future<bool> anyExist({String? connection}) =>
      Model.anyExist<$FactoryUser>(connection: connection);

  static Query<$FactoryUser> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) => Model.where<$FactoryUser>(
    column,
    operator,
    value,
    connection: connection,
  );

  static Query<$FactoryUser> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<$FactoryUser>(column, values, connection: connection);

  static Query<$FactoryUser> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<$FactoryUser>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<$FactoryUser> limit(int count, {String? connection}) =>
      Model.limit<$FactoryUser>(count, connection: connection);

  /// Creates a [Repository] for [$FactoryUser].
  ///
  /// {@macro ormed.repository}
  static Repository<$FactoryUser> repo([String? connection]) =>
      Model.repository<$FactoryUser>(connection: connection);
}

class FactoryUserModelFactory {
  const FactoryUserModelFactory._();

  static ModelDefinition<$FactoryUser> get definition =>
      _$FactoryUserDefinition;

  static ModelCodec<$FactoryUser> get codec => definition.codec;

  static FactoryUser fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    FactoryUser model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model.toTracked(), registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<FactoryUser> withConnection(
    QueryContext context,
  ) => ModelFactoryConnection<FactoryUser>(
    definition: definition,
    context: context,
  );

  static ModelFactoryBuilder<FactoryUser> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<FactoryUser>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$FactoryUserCodec extends ModelCodec<$FactoryUser> {
  const _$FactoryUserCodec();
  @override
  Map<String, Object?> encode($FactoryUser model, ValueCodecRegistry registry) {
    return <String, Object?>{
      'id': registry.encodeField(_$FactoryUserIdField, model.id),
      'email': registry.encodeField(_$FactoryUserEmailField, model.email),
      'name': registry.encodeField(_$FactoryUserNameField, model.name),
    };
  }

  @override
  $FactoryUser decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final int factoryUserIdValue =
        registry.decodeField<int>(_$FactoryUserIdField, data['id']) ?? 0;
    final String factoryUserEmailValue =
        registry.decodeField<String>(_$FactoryUserEmailField, data['email']) ??
        (throw StateError('Field email on FactoryUser cannot be null.'));
    final String? factoryUserNameValue = registry.decodeField<String?>(
      _$FactoryUserNameField,
      data['name'],
    );
    final model = $FactoryUser(
      id: factoryUserIdValue,
      email: factoryUserEmailValue,
      name: factoryUserNameValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': factoryUserIdValue,
      'email': factoryUserEmailValue,
      'name': factoryUserNameValue,
    });
    return model;
  }
}

/// Insert DTO for [FactoryUser].
///
/// Auto-increment/DB-generated fields are omitted by default.
class FactoryUserInsertDto implements InsertDto<$FactoryUser> {
  const FactoryUserInsertDto({this.email, this.name});
  final String? email;
  final String? name;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (email != null) 'email': email,
      if (name != null) 'name': name,
    };
  }

  static const _FactoryUserInsertDtoCopyWithSentinel _copyWithSentinel =
      _FactoryUserInsertDtoCopyWithSentinel();
  FactoryUserInsertDto copyWith({
    Object? email = _copyWithSentinel,
    Object? name = _copyWithSentinel,
  }) {
    return FactoryUserInsertDto(
      email: identical(email, _copyWithSentinel)
          ? this.email
          : email as String?,
      name: identical(name, _copyWithSentinel) ? this.name : name as String?,
    );
  }
}

class _FactoryUserInsertDtoCopyWithSentinel {
  const _FactoryUserInsertDtoCopyWithSentinel();
}

/// Update DTO for [FactoryUser].
///
/// All fields are optional; only provided entries are used in SET clauses.
class FactoryUserUpdateDto implements UpdateDto<$FactoryUser> {
  const FactoryUserUpdateDto({this.id, this.email, this.name});
  final int? id;
  final String? email;
  final String? name;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (email != null) 'email': email,
      if (name != null) 'name': name,
    };
  }

  static const _FactoryUserUpdateDtoCopyWithSentinel _copyWithSentinel =
      _FactoryUserUpdateDtoCopyWithSentinel();
  FactoryUserUpdateDto copyWith({
    Object? id = _copyWithSentinel,
    Object? email = _copyWithSentinel,
    Object? name = _copyWithSentinel,
  }) {
    return FactoryUserUpdateDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      email: identical(email, _copyWithSentinel)
          ? this.email
          : email as String?,
      name: identical(name, _copyWithSentinel) ? this.name : name as String?,
    );
  }
}

class _FactoryUserUpdateDtoCopyWithSentinel {
  const _FactoryUserUpdateDtoCopyWithSentinel();
}

/// Partial projection for [FactoryUser].
///
/// All fields are nullable; intended for subset SELECTs.
class FactoryUserPartial implements PartialEntity<$FactoryUser> {
  const FactoryUserPartial({this.id, this.email, this.name});

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory FactoryUserPartial.fromRow(Map<String, Object?> row) {
    return FactoryUserPartial(
      id: row['id'] as int?,
      email: row['email'] as String?,
      name: row['name'] as String?,
    );
  }

  final int? id;
  final String? email;
  final String? name;

  @override
  $FactoryUser toEntity() {
    // Basic required-field check: non-nullable fields must be present.
    final int? idValue = id;
    if (idValue == null) {
      throw StateError('Missing required field: id');
    }
    final String? emailValue = email;
    if (emailValue == null) {
      throw StateError('Missing required field: email');
    }
    return $FactoryUser(id: idValue, email: emailValue, name: name);
  }

  @override
  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      if (email != null) 'email': email,
      if (name != null) 'name': name,
    };
  }

  static const _FactoryUserPartialCopyWithSentinel _copyWithSentinel =
      _FactoryUserPartialCopyWithSentinel();
  FactoryUserPartial copyWith({
    Object? id = _copyWithSentinel,
    Object? email = _copyWithSentinel,
    Object? name = _copyWithSentinel,
  }) {
    return FactoryUserPartial(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      email: identical(email, _copyWithSentinel)
          ? this.email
          : email as String?,
      name: identical(name, _copyWithSentinel) ? this.name : name as String?,
    );
  }
}

class _FactoryUserPartialCopyWithSentinel {
  const _FactoryUserPartialCopyWithSentinel();
}

/// Generated tracked model class for [FactoryUser].
///
/// This class extends the user-defined [FactoryUser] model and adds
/// attribute tracking, change detection, and relationship management.
/// Instances of this class are returned by queries and repositories.
///
/// **Do not instantiate this class directly.** Use queries, repositories,
/// or model factories to create tracked model instances.
class $FactoryUser extends FactoryUser
    with ModelAttributes
    implements OrmEntity {
  /// Internal constructor for [$FactoryUser].
  $FactoryUser({int id = 0, required String email, String? name})
    : super.new(id: id, email: email, name: name) {
    _attachOrmRuntimeMetadata({'id': id, 'email': email, 'name': name});
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $FactoryUser.fromModel(FactoryUser model) {
    return $FactoryUser(id: model.id, email: model.email, name: model.name);
  }

  $FactoryUser copyWith({int? id, String? email, String? name}) {
    return $FactoryUser(
      id: id ?? this.id,
      email: email ?? this.email,
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

  /// Tracked getter for [name].
  @override
  String? get name => getAttribute<String?>('name') ?? super.name;

  /// Tracked setter for [name].
  set name(String? value) => setAttribute('name', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$FactoryUserDefinition);
  }
}

extension FactoryUserOrmExtension on FactoryUser {
  /// The Type of the generated ORM-managed model class.
  /// Use this when you need to specify the tracked model type explicitly,
  /// for example in generic type parameters.
  static Type get trackedType => $FactoryUser;

  /// Converts this immutable model to a tracked ORM-managed model.
  /// The tracked model supports attribute tracking, change detection,
  /// and persistence operations like save() and touch().
  $FactoryUser toTracked() {
    return $FactoryUser.fromModel(this);
  }
}

void registerFactoryUserEventHandlers(EventBus bus) {
  // No event handlers registered for FactoryUser.
}
