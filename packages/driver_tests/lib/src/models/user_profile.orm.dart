// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'user_profile.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$UserProfileIdField = FieldDefinition(
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

const FieldDefinition _$UserProfileUserIdField = FieldDefinition(
  name: 'userId',
  columnName: 'user_id',
  dartType: 'int',
  resolvedType: 'int',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$UserProfileBioField = FieldDefinition(
  name: 'bio',
  columnName: 'bio',
  dartType: 'String',
  resolvedType: 'String',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

Map<String, Object?> _encodeUserProfileUntracked(
  Object model,
  ValueCodecRegistry registry,
) {
  final m = model as UserProfile;
  return <String, Object?>{
    'id': registry.encodeField(_$UserProfileIdField, m.id),
    'user_id': registry.encodeField(_$UserProfileUserIdField, m.userId),
    'bio': registry.encodeField(_$UserProfileBioField, m.bio),
  };
}

final ModelDefinition<$UserProfile> _$UserProfileDefinition = ModelDefinition(
  modelName: 'UserProfile',
  tableName: 'user_profiles',
  fields: const [
    _$UserProfileIdField,
    _$UserProfileUserIdField,
    _$UserProfileBioField,
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
    softDeletes: false,
    softDeleteColumn: 'deleted_at',
  ),
  untrackedToMap: _encodeUserProfileUntracked,
  codec: _$UserProfileCodec(),
);

// ignore: unused_element
final userprofileModelDefinitionRegistration =
    ModelFactoryRegistry.register<$UserProfile>(_$UserProfileDefinition);

extension UserProfileOrmDefinition on UserProfile {
  static ModelDefinition<$UserProfile> get definition =>
      _$UserProfileDefinition;
}

class UserProfiles {
  const UserProfiles._();

  /// Starts building a query for [$UserProfile].
  ///
  /// {@macro ormed.query}
  static Query<$UserProfile> query([String? connection]) =>
      Model.query<$UserProfile>(connection: connection);

  static Future<$UserProfile?> find(Object id, {String? connection}) =>
      Model.find<$UserProfile>(id, connection: connection);

  static Future<$UserProfile> findOrFail(Object id, {String? connection}) =>
      Model.findOrFail<$UserProfile>(id, connection: connection);

  static Future<List<$UserProfile>> all({String? connection}) =>
      Model.all<$UserProfile>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<$UserProfile>(connection: connection);

  static Future<bool> anyExist({String? connection}) =>
      Model.anyExist<$UserProfile>(connection: connection);

  static Query<$UserProfile> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) => Model.where<$UserProfile>(
    column,
    operator,
    value,
    connection: connection,
  );

  static Query<$UserProfile> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<$UserProfile>(column, values, connection: connection);

  static Query<$UserProfile> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<$UserProfile>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<$UserProfile> limit(int count, {String? connection}) =>
      Model.limit<$UserProfile>(count, connection: connection);

  /// Creates a [Repository] for [$UserProfile].
  ///
  /// {@macro ormed.repository}
  static Repository<$UserProfile> repo([String? connection]) =>
      Model.repository<$UserProfile>(connection: connection);
}

class UserProfileModelFactory {
  const UserProfileModelFactory._();

  static ModelDefinition<$UserProfile> get definition =>
      _$UserProfileDefinition;

  static ModelCodec<$UserProfile> get codec => definition.codec;

  static UserProfile fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    UserProfile model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model.toTracked(), registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<UserProfile> withConnection(
    QueryContext context,
  ) => ModelFactoryConnection<UserProfile>(
    definition: definition,
    context: context,
  );

  static ModelFactoryBuilder<UserProfile> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<UserProfile>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$UserProfileCodec extends ModelCodec<$UserProfile> {
  const _$UserProfileCodec();
  @override
  Map<String, Object?> encode($UserProfile model, ValueCodecRegistry registry) {
    return <String, Object?>{
      'id': registry.encodeField(_$UserProfileIdField, model.id),
      'user_id': registry.encodeField(_$UserProfileUserIdField, model.userId),
      'bio': registry.encodeField(_$UserProfileBioField, model.bio),
    };
  }

  @override
  $UserProfile decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final int userProfileIdValue =
        registry.decodeField<int>(_$UserProfileIdField, data['id']) ?? 0;
    final int userProfileUserIdValue =
        registry.decodeField<int>(_$UserProfileUserIdField, data['user_id']) ??
        (throw StateError('Field userId on UserProfile cannot be null.'));
    final String userProfileBioValue =
        registry.decodeField<String>(_$UserProfileBioField, data['bio']) ??
        (throw StateError('Field bio on UserProfile cannot be null.'));
    final model = $UserProfile(
      id: userProfileIdValue,
      userId: userProfileUserIdValue,
      bio: userProfileBioValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': userProfileIdValue,
      'user_id': userProfileUserIdValue,
      'bio': userProfileBioValue,
    });
    return model;
  }
}

/// Insert DTO for [UserProfile].
///
/// Auto-increment/DB-generated fields are omitted by default.
class UserProfileInsertDto implements InsertDto<$UserProfile> {
  const UserProfileInsertDto({this.userId, this.bio});
  final int? userId;
  final String? bio;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (userId != null) 'user_id': userId,
      if (bio != null) 'bio': bio,
    };
  }

  static const _UserProfileInsertDtoCopyWithSentinel _copyWithSentinel =
      _UserProfileInsertDtoCopyWithSentinel();
  UserProfileInsertDto copyWith({
    Object? userId = _copyWithSentinel,
    Object? bio = _copyWithSentinel,
  }) {
    return UserProfileInsertDto(
      userId: identical(userId, _copyWithSentinel)
          ? this.userId
          : userId as int?,
      bio: identical(bio, _copyWithSentinel) ? this.bio : bio as String?,
    );
  }
}

class _UserProfileInsertDtoCopyWithSentinel {
  const _UserProfileInsertDtoCopyWithSentinel();
}

/// Update DTO for [UserProfile].
///
/// All fields are optional; only provided entries are used in SET clauses.
class UserProfileUpdateDto implements UpdateDto<$UserProfile> {
  const UserProfileUpdateDto({this.id, this.userId, this.bio});
  final int? id;
  final int? userId;
  final String? bio;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (bio != null) 'bio': bio,
    };
  }

  static const _UserProfileUpdateDtoCopyWithSentinel _copyWithSentinel =
      _UserProfileUpdateDtoCopyWithSentinel();
  UserProfileUpdateDto copyWith({
    Object? id = _copyWithSentinel,
    Object? userId = _copyWithSentinel,
    Object? bio = _copyWithSentinel,
  }) {
    return UserProfileUpdateDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      userId: identical(userId, _copyWithSentinel)
          ? this.userId
          : userId as int?,
      bio: identical(bio, _copyWithSentinel) ? this.bio : bio as String?,
    );
  }
}

class _UserProfileUpdateDtoCopyWithSentinel {
  const _UserProfileUpdateDtoCopyWithSentinel();
}

/// Partial projection for [UserProfile].
///
/// All fields are nullable; intended for subset SELECTs.
class UserProfilePartial implements PartialEntity<$UserProfile> {
  const UserProfilePartial({this.id, this.userId, this.bio});

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory UserProfilePartial.fromRow(Map<String, Object?> row) {
    return UserProfilePartial(
      id: row['id'] as int?,
      userId: row['user_id'] as int?,
      bio: row['bio'] as String?,
    );
  }

  final int? id;
  final int? userId;
  final String? bio;

  @override
  $UserProfile toEntity() {
    // Basic required-field check: non-nullable fields must be present.
    final int? idValue = id;
    if (idValue == null) {
      throw StateError('Missing required field: id');
    }
    final int? userIdValue = userId;
    if (userIdValue == null) {
      throw StateError('Missing required field: userId');
    }
    final String? bioValue = bio;
    if (bioValue == null) {
      throw StateError('Missing required field: bio');
    }
    return $UserProfile(id: idValue, userId: userIdValue, bio: bioValue);
  }

  @override
  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (bio != null) 'bio': bio,
    };
  }

  static const _UserProfilePartialCopyWithSentinel _copyWithSentinel =
      _UserProfilePartialCopyWithSentinel();
  UserProfilePartial copyWith({
    Object? id = _copyWithSentinel,
    Object? userId = _copyWithSentinel,
    Object? bio = _copyWithSentinel,
  }) {
    return UserProfilePartial(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      userId: identical(userId, _copyWithSentinel)
          ? this.userId
          : userId as int?,
      bio: identical(bio, _copyWithSentinel) ? this.bio : bio as String?,
    );
  }
}

class _UserProfilePartialCopyWithSentinel {
  const _UserProfilePartialCopyWithSentinel();
}

/// Generated tracked model class for [UserProfile].
///
/// This class extends the user-defined [UserProfile] model and adds
/// attribute tracking, change detection, and relationship management.
/// Instances of this class are returned by queries and repositories.
///
/// **Do not instantiate this class directly.** Use queries, repositories,
/// or model factories to create tracked model instances.
class $UserProfile extends UserProfile
    with ModelAttributes
    implements OrmEntity {
  /// Internal constructor for [$UserProfile].
  $UserProfile({int id = 0, required int userId, required String bio})
    : super.new(id: id, userId: userId, bio: bio) {
    _attachOrmRuntimeMetadata({'id': id, 'user_id': userId, 'bio': bio});
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $UserProfile.fromModel(UserProfile model) {
    return $UserProfile(id: model.id, userId: model.userId, bio: model.bio);
  }

  $UserProfile copyWith({int? id, int? userId, String? bio}) {
    return $UserProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      bio: bio ?? this.bio,
    );
  }

  /// Tracked getter for [id].
  @override
  int get id => getAttribute<int>('id') ?? super.id;

  /// Tracked setter for [id].
  set id(int value) => setAttribute('id', value);

  /// Tracked getter for [userId].
  @override
  int get userId => getAttribute<int>('user_id') ?? super.userId;

  /// Tracked setter for [userId].
  set userId(int value) => setAttribute('user_id', value);

  /// Tracked getter for [bio].
  @override
  String get bio => getAttribute<String>('bio') ?? super.bio;

  /// Tracked setter for [bio].
  set bio(String value) => setAttribute('bio', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$UserProfileDefinition);
  }
}

extension UserProfileOrmExtension on UserProfile {
  /// The Type of the generated ORM-managed model class.
  /// Use this when you need to specify the tracked model type explicitly,
  /// for example in generic type parameters.
  static Type get trackedType => $UserProfile;

  /// Converts this immutable model to a tracked ORM-managed model.
  /// The tracked model supports attribute tracking, change detection,
  /// and persistence operations like save() and touch().
  $UserProfile toTracked() {
    return $UserProfile.fromModel(this);
  }
}

void registerUserProfileEventHandlers(EventBus bus) {
  // No event handlers registered for UserProfile.
}
