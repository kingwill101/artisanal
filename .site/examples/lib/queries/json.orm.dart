// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'json.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$UserIdField = FieldDefinition(
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

const FieldDefinition _$UserEmailField = FieldDefinition(
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

const FieldDefinition _$UserMetadataField = FieldDefinition(
  name: 'metadata',
  columnName: 'metadata',
  dartType: 'Map<String, Object?>',
  resolvedType: 'Map<String, Object?>?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
  codecType: 'json',
);

Map<String, Object?> _encodeUserUntracked(
  Object model,
  ValueCodecRegistry registry,
) {
  final m = model as User;
  return <String, Object?>{
    'id': registry.encodeField(_$UserIdField, m.id),
    'email': registry.encodeField(_$UserEmailField, m.email),
    'metadata': registry.encodeField(_$UserMetadataField, m.metadata),
  };
}

final ModelDefinition<$User> _$UserDefinition = ModelDefinition(
  modelName: 'User',
  tableName: 'users',
  fields: const [_$UserIdField, _$UserEmailField, _$UserMetadataField],
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
    fieldOverrides: const {'metadata': FieldAttributeMetadata(cast: 'json')},
    softDeletes: false,
    softDeleteColumn: 'deleted_at',
  ),
  untrackedToMap: _encodeUserUntracked,
  codec: _$UserCodec(),
);

extension UserOrmDefinition on User {
  static ModelDefinition<$User> get definition => _$UserDefinition;
}

class Users {
  const Users._();

  /// Starts building a query for [$User].
  ///
  /// {@macro ormed.query}
  static Query<$User> query([String? connection]) =>
      Model.query<$User>(connection: connection);

  static Future<$User?> find(Object id, {String? connection}) =>
      Model.find<$User>(id, connection: connection);

  static Future<$User> findOrFail(Object id, {String? connection}) =>
      Model.findOrFail<$User>(id, connection: connection);

  static Future<List<$User>> all({String? connection}) =>
      Model.all<$User>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<$User>(connection: connection);

  static Future<bool> anyExist({String? connection}) =>
      Model.anyExist<$User>(connection: connection);

  static Query<$User> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) => Model.where<$User>(column, operator, value, connection: connection);

  static Query<$User> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<$User>(column, values, connection: connection);

  static Query<$User> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<$User>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<$User> limit(int count, {String? connection}) =>
      Model.limit<$User>(count, connection: connection);

  /// Creates a [Repository] for [$User].
  ///
  /// {@macro ormed.repository}
  static Repository<$User> repo([String? connection]) =>
      Model.repository<$User>(connection: connection);

  /// Builds a tracked model from a column/value map.
  static $User fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$UserDefinition.fromMap(data, registry: registry);

  /// Converts a tracked model to a column/value map.
  static Map<String, Object?> toMap(
    $User model, {
    ValueCodecRegistry? registry,
  }) => _$UserDefinition.toMap(model, registry: registry);
}

class UserModelFactory {
  const UserModelFactory._();

  static ModelDefinition<$User> get definition => _$UserDefinition;

  static ModelCodec<$User> get codec => definition.codec;

  static User fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    User model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model.toTracked(), registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<User> withConnection(QueryContext context) =>
      ModelFactoryConnection<User>(definition: definition, context: context);

  static ModelFactoryBuilder<User> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<User>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$UserCodec extends ModelCodec<$User> {
  const _$UserCodec();
  @override
  Map<String, Object?> encode($User model, ValueCodecRegistry registry) {
    return <String, Object?>{
      'id': registry.encodeField(_$UserIdField, model.id),
      'email': registry.encodeField(_$UserEmailField, model.email),
      'metadata': registry.encodeField(_$UserMetadataField, model.metadata),
    };
  }

  @override
  $User decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final int userIdValue =
        registry.decodeField<int>(_$UserIdField, data['id']) ?? 0;
    final String userEmailValue =
        registry.decodeField<String>(_$UserEmailField, data['email']) ??
        (throw StateError('Field email on User cannot be null.'));
    final Map<String, Object?>? userMetadataValue = registry
        .decodeField<Map<String, Object?>?>(
          _$UserMetadataField,
          data['metadata'],
        );
    final model = $User(
      id: userIdValue,
      email: userEmailValue,
      metadata: userMetadataValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': userIdValue,
      'email': userEmailValue,
      'metadata': userMetadataValue,
    });
    return model;
  }
}

/// Insert DTO for [User].
///
/// Auto-increment/DB-generated fields are omitted by default.
class UserInsertDto implements InsertDto<$User> {
  const UserInsertDto({this.email, this.metadata});
  final String? email;
  final Map<String, Object?>? metadata;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (email != null) 'email': email,
      if (metadata != null) 'metadata': metadata,
    };
  }

  static const _UserInsertDtoCopyWithSentinel _copyWithSentinel =
      _UserInsertDtoCopyWithSentinel();
  UserInsertDto copyWith({
    Object? email = _copyWithSentinel,
    Object? metadata = _copyWithSentinel,
  }) {
    return UserInsertDto(
      email: identical(email, _copyWithSentinel)
          ? this.email
          : email as String?,
      metadata: identical(metadata, _copyWithSentinel)
          ? this.metadata
          : metadata as Map<String, Object?>?,
    );
  }
}

class _UserInsertDtoCopyWithSentinel {
  const _UserInsertDtoCopyWithSentinel();
}

/// Update DTO for [User].
///
/// All fields are optional; only provided entries are used in SET clauses.
class UserUpdateDto implements UpdateDto<$User> {
  const UserUpdateDto({this.id, this.email, this.metadata});
  final int? id;
  final String? email;
  final Map<String, Object?>? metadata;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (email != null) 'email': email,
      if (metadata != null) 'metadata': metadata,
    };
  }

  static const _UserUpdateDtoCopyWithSentinel _copyWithSentinel =
      _UserUpdateDtoCopyWithSentinel();
  UserUpdateDto copyWith({
    Object? id = _copyWithSentinel,
    Object? email = _copyWithSentinel,
    Object? metadata = _copyWithSentinel,
  }) {
    return UserUpdateDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      email: identical(email, _copyWithSentinel)
          ? this.email
          : email as String?,
      metadata: identical(metadata, _copyWithSentinel)
          ? this.metadata
          : metadata as Map<String, Object?>?,
    );
  }
}

class _UserUpdateDtoCopyWithSentinel {
  const _UserUpdateDtoCopyWithSentinel();
}

/// Partial projection for [User].
///
/// All fields are nullable; intended for subset SELECTs.
class UserPartial implements PartialEntity<$User> {
  const UserPartial({this.id, this.email, this.metadata});

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory UserPartial.fromRow(Map<String, Object?> row) {
    return UserPartial(
      id: row['id'] as int?,
      email: row['email'] as String?,
      metadata: row['metadata'] as Map<String, Object?>?,
    );
  }

  final int? id;
  final String? email;
  final Map<String, Object?>? metadata;

  @override
  $User toEntity() {
    // Basic required-field check: non-nullable fields must be present.
    final int? idValue = id;
    if (idValue == null) {
      throw StateError('Missing required field: id');
    }
    final String? emailValue = email;
    if (emailValue == null) {
      throw StateError('Missing required field: email');
    }
    return $User(id: idValue, email: emailValue, metadata: metadata);
  }

  @override
  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      if (email != null) 'email': email,
      if (metadata != null) 'metadata': metadata,
    };
  }

  static const _UserPartialCopyWithSentinel _copyWithSentinel =
      _UserPartialCopyWithSentinel();
  UserPartial copyWith({
    Object? id = _copyWithSentinel,
    Object? email = _copyWithSentinel,
    Object? metadata = _copyWithSentinel,
  }) {
    return UserPartial(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      email: identical(email, _copyWithSentinel)
          ? this.email
          : email as String?,
      metadata: identical(metadata, _copyWithSentinel)
          ? this.metadata
          : metadata as Map<String, Object?>?,
    );
  }
}

class _UserPartialCopyWithSentinel {
  const _UserPartialCopyWithSentinel();
}

/// Generated tracked model class for [User].
///
/// This class extends the user-defined [User] model and adds
/// attribute tracking, change detection, and relationship management.
/// Instances of this class are returned by queries and repositories.
///
/// **Do not instantiate this class directly.** Use queries, repositories,
/// or model factories to create tracked model instances.
class $User extends User with ModelAttributes implements OrmEntity {
  /// Internal constructor for [$User].
  $User({int id = 0, required String email, Map<String, Object?>? metadata})
    : super.new(id: id, email: email, metadata: metadata) {
    _attachOrmRuntimeMetadata({'id': id, 'email': email, 'metadata': metadata});
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $User.fromModel(User model) {
    return $User(id: model.id, email: model.email, metadata: model.metadata);
  }

  $User copyWith({int? id, String? email, Map<String, Object?>? metadata}) {
    return $User(
      id: id ?? this.id,
      email: email ?? this.email,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Builds a tracked model from a column/value map.
  static $User fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$UserDefinition.fromMap(data, registry: registry);

  /// Converts this tracked model to a column/value map.
  Map<String, Object?> toMap({ValueCodecRegistry? registry}) =>
      _$UserDefinition.toMap(this, registry: registry);

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

  /// Tracked getter for [metadata].
  @override
  Map<String, Object?>? get metadata =>
      getAttribute<Map<String, Object?>?>('metadata') ?? super.metadata;

  /// Tracked setter for [metadata].
  set metadata(Map<String, Object?>? value) => setAttribute('metadata', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$UserDefinition);
  }
}

class _UserCopyWithSentinel {
  const _UserCopyWithSentinel();
}

extension UserOrmExtension on User {
  static const _UserCopyWithSentinel _copyWithSentinel =
      _UserCopyWithSentinel();
  User copyWith({
    Object? id = _copyWithSentinel,
    Object? email = _copyWithSentinel,
    Object? metadata = _copyWithSentinel,
  }) {
    return User.new(
      id: identical(id, _copyWithSentinel) ? this.id : id as int,
      email: identical(email, _copyWithSentinel) ? this.email : email as String,
      metadata: identical(metadata, _copyWithSentinel)
          ? this.metadata
          : metadata as Map<String, Object?>?,
    );
  }

  /// Converts this model to a column/value map.
  Map<String, Object?> toMap({ValueCodecRegistry? registry}) =>
      _$UserDefinition.toMap(this, registry: registry);

  /// Builds a model from a column/value map.
  static User fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$UserDefinition.fromMap(data, registry: registry);

  /// The Type of the generated ORM-managed model class.
  /// Use this when you need to specify the tracked model type explicitly,
  /// for example in generic type parameters.
  static Type get trackedType => $User;

  /// Converts this immutable model to a tracked ORM-managed model.
  /// The tracked model supports attribute tracking, change detection,
  /// and persistence operations like save() and touch().
  $User toTracked() {
    return $User.fromModel(this);
  }
}

extension UserPredicateFields on PredicateBuilder<User> {
  PredicateField<User, int> get id => PredicateField<User, int>(this, 'id');
  PredicateField<User, String> get email =>
      PredicateField<User, String>(this, 'email');
  PredicateField<User, Map<String, Object?>?> get metadata =>
      PredicateField<User, Map<String, Object?>?>(this, 'metadata');
}

void registerUserEventHandlers(EventBus bus) {
  // No event handlers registered for User.
}
