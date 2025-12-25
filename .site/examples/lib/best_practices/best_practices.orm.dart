// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'best_practices.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$ValidatedUserIdField = FieldDefinition(
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

const FieldDefinition _$ValidatedUserEmailField = FieldDefinition(
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

const FieldDefinition _$ValidatedUserAgeField = FieldDefinition(
  name: 'age',
  columnName: 'age',
  dartType: 'int',
  resolvedType: 'int',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

Map<String, Object?> _encodeValidatedUserUntracked(
  Object model,
  ValueCodecRegistry registry,
) {
  final m = model as ValidatedUser;
  return <String, Object?>{
    'id': registry.encodeField(_$ValidatedUserIdField, m.id),
    'email': registry.encodeField(_$ValidatedUserEmailField, m.email),
    'age': registry.encodeField(_$ValidatedUserAgeField, m.age),
  };
}

final ModelDefinition<$ValidatedUser> _$ValidatedUserDefinition =
    ModelDefinition(
      modelName: 'ValidatedUser',
      tableName: 'validated_users',
      fields: const [
        _$ValidatedUserIdField,
        _$ValidatedUserEmailField,
        _$ValidatedUserAgeField,
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
      untrackedToMap: _encodeValidatedUserUntracked,
      codec: _$ValidatedUserCodec(),
    );

extension ValidatedUserOrmDefinition on ValidatedUser {
  static ModelDefinition<$ValidatedUser> get definition =>
      _$ValidatedUserDefinition;
}

class ValidatedUsers {
  const ValidatedUsers._();

  /// Starts building a query for [$ValidatedUser].
  ///
  /// {@macro ormed.query}
  static Query<$ValidatedUser> query([String? connection]) =>
      Model.query<$ValidatedUser>(connection: connection);

  static Future<$ValidatedUser?> find(Object id, {String? connection}) =>
      Model.find<$ValidatedUser>(id, connection: connection);

  static Future<$ValidatedUser> findOrFail(Object id, {String? connection}) =>
      Model.findOrFail<$ValidatedUser>(id, connection: connection);

  static Future<List<$ValidatedUser>> all({String? connection}) =>
      Model.all<$ValidatedUser>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<$ValidatedUser>(connection: connection);

  static Future<bool> anyExist({String? connection}) =>
      Model.anyExist<$ValidatedUser>(connection: connection);

  static Query<$ValidatedUser> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) => Model.where<$ValidatedUser>(
    column,
    operator,
    value,
    connection: connection,
  );

  static Query<$ValidatedUser> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<$ValidatedUser>(column, values, connection: connection);

  static Query<$ValidatedUser> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<$ValidatedUser>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<$ValidatedUser> limit(int count, {String? connection}) =>
      Model.limit<$ValidatedUser>(count, connection: connection);

  /// Creates a [Repository] for [$ValidatedUser].
  ///
  /// {@macro ormed.repository}
  static Repository<$ValidatedUser> repo([String? connection]) =>
      Model.repository<$ValidatedUser>(connection: connection);
}

class ValidatedUserModelFactory {
  const ValidatedUserModelFactory._();

  static ModelDefinition<$ValidatedUser> get definition =>
      _$ValidatedUserDefinition;

  static ModelCodec<$ValidatedUser> get codec => definition.codec;

  static ValidatedUser fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    ValidatedUser model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model.toTracked(), registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<ValidatedUser> withConnection(
    QueryContext context,
  ) => ModelFactoryConnection<ValidatedUser>(
    definition: definition,
    context: context,
  );

  static ModelFactoryBuilder<ValidatedUser> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<ValidatedUser>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$ValidatedUserCodec extends ModelCodec<$ValidatedUser> {
  const _$ValidatedUserCodec();
  @override
  Map<String, Object?> encode(
    $ValidatedUser model,
    ValueCodecRegistry registry,
  ) {
    return <String, Object?>{
      'id': registry.encodeField(_$ValidatedUserIdField, model.id),
      'email': registry.encodeField(_$ValidatedUserEmailField, model.email),
      'age': registry.encodeField(_$ValidatedUserAgeField, model.age),
    };
  }

  @override
  $ValidatedUser decode(
    Map<String, Object?> data,
    ValueCodecRegistry registry,
  ) {
    final int validatedUserIdValue =
        registry.decodeField<int>(_$ValidatedUserIdField, data['id']) ?? 0;
    final String validatedUserEmailValue =
        registry.decodeField<String>(
          _$ValidatedUserEmailField,
          data['email'],
        ) ??
        (throw StateError('Field email on ValidatedUser cannot be null.'));
    final int validatedUserAgeValue =
        registry.decodeField<int>(_$ValidatedUserAgeField, data['age']) ??
        (throw StateError('Field age on ValidatedUser cannot be null.'));
    final model = $ValidatedUser(
      id: validatedUserIdValue,
      email: validatedUserEmailValue,
      age: validatedUserAgeValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': validatedUserIdValue,
      'email': validatedUserEmailValue,
      'age': validatedUserAgeValue,
    });
    return model;
  }
}

/// Insert DTO for [ValidatedUser].
///
/// Auto-increment/DB-generated fields are omitted by default.
class ValidatedUserInsertDto implements InsertDto<$ValidatedUser> {
  const ValidatedUserInsertDto({this.email, this.age});
  final String? email;
  final int? age;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (email != null) 'email': email,
      if (age != null) 'age': age,
    };
  }

  static const _ValidatedUserInsertDtoCopyWithSentinel _copyWithSentinel =
      _ValidatedUserInsertDtoCopyWithSentinel();
  ValidatedUserInsertDto copyWith({
    Object? email = _copyWithSentinel,
    Object? age = _copyWithSentinel,
  }) {
    return ValidatedUserInsertDto(
      email: identical(email, _copyWithSentinel)
          ? this.email
          : email as String?,
      age: identical(age, _copyWithSentinel) ? this.age : age as int?,
    );
  }
}

class _ValidatedUserInsertDtoCopyWithSentinel {
  const _ValidatedUserInsertDtoCopyWithSentinel();
}

/// Update DTO for [ValidatedUser].
///
/// All fields are optional; only provided entries are used in SET clauses.
class ValidatedUserUpdateDto implements UpdateDto<$ValidatedUser> {
  const ValidatedUserUpdateDto({this.id, this.email, this.age});
  final int? id;
  final String? email;
  final int? age;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (email != null) 'email': email,
      if (age != null) 'age': age,
    };
  }

  static const _ValidatedUserUpdateDtoCopyWithSentinel _copyWithSentinel =
      _ValidatedUserUpdateDtoCopyWithSentinel();
  ValidatedUserUpdateDto copyWith({
    Object? id = _copyWithSentinel,
    Object? email = _copyWithSentinel,
    Object? age = _copyWithSentinel,
  }) {
    return ValidatedUserUpdateDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      email: identical(email, _copyWithSentinel)
          ? this.email
          : email as String?,
      age: identical(age, _copyWithSentinel) ? this.age : age as int?,
    );
  }
}

class _ValidatedUserUpdateDtoCopyWithSentinel {
  const _ValidatedUserUpdateDtoCopyWithSentinel();
}

/// Partial projection for [ValidatedUser].
///
/// All fields are nullable; intended for subset SELECTs.
class ValidatedUserPartial implements PartialEntity<$ValidatedUser> {
  const ValidatedUserPartial({this.id, this.email, this.age});

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory ValidatedUserPartial.fromRow(Map<String, Object?> row) {
    return ValidatedUserPartial(
      id: row['id'] as int?,
      email: row['email'] as String?,
      age: row['age'] as int?,
    );
  }

  final int? id;
  final String? email;
  final int? age;

  @override
  $ValidatedUser toEntity() {
    // Basic required-field check: non-nullable fields must be present.
    final int? idValue = id;
    if (idValue == null) {
      throw StateError('Missing required field: id');
    }
    final String? emailValue = email;
    if (emailValue == null) {
      throw StateError('Missing required field: email');
    }
    final int? ageValue = age;
    if (ageValue == null) {
      throw StateError('Missing required field: age');
    }
    return $ValidatedUser(id: idValue, email: emailValue, age: ageValue);
  }

  @override
  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      if (email != null) 'email': email,
      if (age != null) 'age': age,
    };
  }

  static const _ValidatedUserPartialCopyWithSentinel _copyWithSentinel =
      _ValidatedUserPartialCopyWithSentinel();
  ValidatedUserPartial copyWith({
    Object? id = _copyWithSentinel,
    Object? email = _copyWithSentinel,
    Object? age = _copyWithSentinel,
  }) {
    return ValidatedUserPartial(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      email: identical(email, _copyWithSentinel)
          ? this.email
          : email as String?,
      age: identical(age, _copyWithSentinel) ? this.age : age as int?,
    );
  }
}

class _ValidatedUserPartialCopyWithSentinel {
  const _ValidatedUserPartialCopyWithSentinel();
}

/// Generated tracked model class for [ValidatedUser].
///
/// This class extends the user-defined [ValidatedUser] model and adds
/// attribute tracking, change detection, and relationship management.
/// Instances of this class are returned by queries and repositories.
///
/// **Do not instantiate this class directly.** Use queries, repositories,
/// or model factories to create tracked model instances.
class $ValidatedUser extends ValidatedUser
    with ModelAttributes
    implements OrmEntity {
  /// Internal constructor for [$ValidatedUser].
  $ValidatedUser({int id = 0, required String email, required int age})
    : super.new(id: id, email: email, age: age) {
    _attachOrmRuntimeMetadata({'id': id, 'email': email, 'age': age});
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $ValidatedUser.fromModel(ValidatedUser model) {
    return $ValidatedUser(id: model.id, email: model.email, age: model.age);
  }

  $ValidatedUser copyWith({int? id, String? email, int? age}) {
    return $ValidatedUser(
      id: id ?? this.id,
      email: email ?? this.email,
      age: age ?? this.age,
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

  /// Tracked getter for [age].
  @override
  int get age => getAttribute<int>('age') ?? super.age;

  /// Tracked setter for [age].
  set age(int value) => setAttribute('age', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$ValidatedUserDefinition);
  }
}

extension ValidatedUserOrmExtension on ValidatedUser {
  /// The Type of the generated ORM-managed model class.
  /// Use this when you need to specify the tracked model type explicitly,
  /// for example in generic type parameters.
  static Type get trackedType => $ValidatedUser;

  /// Converts this immutable model to a tracked ORM-managed model.
  /// The tracked model supports attribute tracking, change detection,
  /// and persistence operations like save() and touch().
  $ValidatedUser toTracked() {
    return $ValidatedUser.fromModel(this);
  }
}

void registerValidatedUserEventHandlers(EventBus bus) {
  // No event handlers registered for ValidatedUser.
}
