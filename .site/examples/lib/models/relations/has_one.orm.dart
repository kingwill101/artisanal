// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'has_one.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$UserWithProfileIdField = FieldDefinition(
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

const FieldDefinition _$UserWithProfileProfileField = FieldDefinition(
  name: 'profile',
  columnName: 'profile',
  dartType: 'Profile',
  resolvedType: 'Profile?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const RelationDefinition _$UserWithProfileProfileRelation = RelationDefinition(
  name: 'profile',
  kind: RelationKind.hasOne,
  targetModel: 'Profile',
  foreignKey: 'user_id',
);

Map<String, Object?> _encodeUserWithProfileUntracked(
  Object model,
  ValueCodecRegistry registry,
) {
  final m = model as UserWithProfile;
  return <String, Object?>{
    'id': registry.encodeField(_$UserWithProfileIdField, m.id),
    'profile': registry.encodeField(_$UserWithProfileProfileField, m.profile),
  };
}

final ModelDefinition<$UserWithProfile> _$UserWithProfileDefinition =
    ModelDefinition(
      modelName: 'UserWithProfile',
      tableName: 'users',
      fields: const [_$UserWithProfileIdField, _$UserWithProfileProfileField],
      relations: const [_$UserWithProfileProfileRelation],
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
      untrackedToMap: _encodeUserWithProfileUntracked,
      codec: _$UserWithProfileCodec(),
    );

extension UserWithProfileOrmDefinition on UserWithProfile {
  static ModelDefinition<$UserWithProfile> get definition =>
      _$UserWithProfileDefinition;
}

class UserWithProfiles {
  const UserWithProfiles._();

  /// Starts building a query for [$UserWithProfile].
  ///
  /// {@macro ormed.query}
  static Query<$UserWithProfile> query([String? connection]) =>
      Model.query<$UserWithProfile>(connection: connection);

  static Future<$UserWithProfile?> find(Object id, {String? connection}) =>
      Model.find<$UserWithProfile>(id, connection: connection);

  static Future<$UserWithProfile> findOrFail(Object id, {String? connection}) =>
      Model.findOrFail<$UserWithProfile>(id, connection: connection);

  static Future<List<$UserWithProfile>> all({String? connection}) =>
      Model.all<$UserWithProfile>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<$UserWithProfile>(connection: connection);

  static Future<bool> anyExist({String? connection}) =>
      Model.anyExist<$UserWithProfile>(connection: connection);

  static Query<$UserWithProfile> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) => Model.where<$UserWithProfile>(
    column,
    operator,
    value,
    connection: connection,
  );

  static Query<$UserWithProfile> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<$UserWithProfile>(column, values, connection: connection);

  static Query<$UserWithProfile> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<$UserWithProfile>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<$UserWithProfile> limit(int count, {String? connection}) =>
      Model.limit<$UserWithProfile>(count, connection: connection);

  /// Creates a [Repository] for [$UserWithProfile].
  ///
  /// {@macro ormed.repository}
  static Repository<$UserWithProfile> repo([String? connection]) =>
      Model.repository<$UserWithProfile>(connection: connection);
}

class UserWithProfileModelFactory {
  const UserWithProfileModelFactory._();

  static ModelDefinition<$UserWithProfile> get definition =>
      _$UserWithProfileDefinition;

  static ModelCodec<$UserWithProfile> get codec => definition.codec;

  static UserWithProfile fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    UserWithProfile model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model.toTracked(), registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<UserWithProfile> withConnection(
    QueryContext context,
  ) => ModelFactoryConnection<UserWithProfile>(
    definition: definition,
    context: context,
  );

  static ModelFactoryBuilder<UserWithProfile> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<UserWithProfile>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$UserWithProfileCodec extends ModelCodec<$UserWithProfile> {
  const _$UserWithProfileCodec();
  @override
  Map<String, Object?> encode(
    $UserWithProfile model,
    ValueCodecRegistry registry,
  ) {
    return <String, Object?>{
      'id': registry.encodeField(_$UserWithProfileIdField, model.id),
      'profile': registry.encodeField(
        _$UserWithProfileProfileField,
        model.profile,
      ),
    };
  }

  @override
  $UserWithProfile decode(
    Map<String, Object?> data,
    ValueCodecRegistry registry,
  ) {
    final int userWithProfileIdValue =
        registry.decodeField<int>(_$UserWithProfileIdField, data['id']) ??
        (throw StateError('Field id on UserWithProfile cannot be null.'));
    final Profile? userWithProfileProfileValue = registry.decodeField<Profile?>(
      _$UserWithProfileProfileField,
      data['profile'],
    );
    final model = $UserWithProfile(
      id: userWithProfileIdValue,
      profile: userWithProfileProfileValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': userWithProfileIdValue,
      'profile': userWithProfileProfileValue,
    });
    return model;
  }
}

/// Insert DTO for [UserWithProfile].
///
/// Auto-increment/DB-generated fields are omitted by default.
class UserWithProfileInsertDto implements InsertDto<$UserWithProfile> {
  const UserWithProfileInsertDto({this.id, this.profile});
  final int? id;
  final Profile? profile;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (profile != null) 'profile': profile,
    };
  }

  static const _UserWithProfileInsertDtoCopyWithSentinel _copyWithSentinel =
      _UserWithProfileInsertDtoCopyWithSentinel();
  UserWithProfileInsertDto copyWith({
    Object? id = _copyWithSentinel,
    Object? profile = _copyWithSentinel,
  }) {
    return UserWithProfileInsertDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      profile: identical(profile, _copyWithSentinel)
          ? this.profile
          : profile as Profile?,
    );
  }
}

class _UserWithProfileInsertDtoCopyWithSentinel {
  const _UserWithProfileInsertDtoCopyWithSentinel();
}

/// Update DTO for [UserWithProfile].
///
/// All fields are optional; only provided entries are used in SET clauses.
class UserWithProfileUpdateDto implements UpdateDto<$UserWithProfile> {
  const UserWithProfileUpdateDto({this.id, this.profile});
  final int? id;
  final Profile? profile;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (profile != null) 'profile': profile,
    };
  }

  static const _UserWithProfileUpdateDtoCopyWithSentinel _copyWithSentinel =
      _UserWithProfileUpdateDtoCopyWithSentinel();
  UserWithProfileUpdateDto copyWith({
    Object? id = _copyWithSentinel,
    Object? profile = _copyWithSentinel,
  }) {
    return UserWithProfileUpdateDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      profile: identical(profile, _copyWithSentinel)
          ? this.profile
          : profile as Profile?,
    );
  }
}

class _UserWithProfileUpdateDtoCopyWithSentinel {
  const _UserWithProfileUpdateDtoCopyWithSentinel();
}

/// Partial projection for [UserWithProfile].
///
/// All fields are nullable; intended for subset SELECTs.
class UserWithProfilePartial implements PartialEntity<$UserWithProfile> {
  const UserWithProfilePartial({this.id, this.profile});

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory UserWithProfilePartial.fromRow(Map<String, Object?> row) {
    return UserWithProfilePartial(
      id: row['id'] as int?,
      profile: row['profile'] as Profile?,
    );
  }

  final int? id;
  final Profile? profile;

  @override
  $UserWithProfile toEntity() {
    // Basic required-field check: non-nullable fields must be present.
    final int? idValue = id;
    if (idValue == null) {
      throw StateError('Missing required field: id');
    }
    return $UserWithProfile(id: idValue, profile: profile);
  }

  @override
  Map<String, Object?> toMap() {
    return {if (id != null) 'id': id, if (profile != null) 'profile': profile};
  }

  static const _UserWithProfilePartialCopyWithSentinel _copyWithSentinel =
      _UserWithProfilePartialCopyWithSentinel();
  UserWithProfilePartial copyWith({
    Object? id = _copyWithSentinel,
    Object? profile = _copyWithSentinel,
  }) {
    return UserWithProfilePartial(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      profile: identical(profile, _copyWithSentinel)
          ? this.profile
          : profile as Profile?,
    );
  }
}

class _UserWithProfilePartialCopyWithSentinel {
  const _UserWithProfilePartialCopyWithSentinel();
}

/// Generated tracked model class for [UserWithProfile].
///
/// This class extends the user-defined [UserWithProfile] model and adds
/// attribute tracking, change detection, and relationship management.
/// Instances of this class are returned by queries and repositories.
///
/// **Do not instantiate this class directly.** Use queries, repositories,
/// or model factories to create tracked model instances.
class $UserWithProfile extends UserWithProfile
    with ModelAttributes
    implements OrmEntity {
  /// Internal constructor for [$UserWithProfile].
  $UserWithProfile({required int id, Profile? profile})
    : super.new(id: id, profile: profile) {
    _attachOrmRuntimeMetadata({'id': id, 'profile': profile});
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $UserWithProfile.fromModel(UserWithProfile model) {
    return $UserWithProfile(id: model.id, profile: model.profile);
  }

  $UserWithProfile copyWith({int? id, Profile? profile}) {
    return $UserWithProfile(
      id: id ?? this.id,
      profile: profile ?? this.profile,
    );
  }

  /// Tracked getter for [id].
  @override
  int get id => getAttribute<int>('id') ?? super.id;

  /// Tracked setter for [id].
  set id(int value) => setAttribute('id', value);

  /// Tracked getter for [profile].
  @override
  Profile? get profile => getAttribute<Profile?>('profile') ?? super.profile;

  /// Tracked setter for [profile].
  set profile(Profile? value) => setAttribute('profile', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$UserWithProfileDefinition);
  }

  @override
  Profile? get profile {
    if (relationLoaded('profile')) {
      return getRelation<Profile>('profile');
    }
    return super.profile;
  }
}

extension UserWithProfileRelationQueries on UserWithProfile {
  Query<Profile> profileQuery() {
    return Model.query<Profile>().where('user_id', getAttribute("null"));
  }
}

extension UserWithProfileOrmExtension on UserWithProfile {
  /// The Type of the generated ORM-managed model class.
  /// Use this when you need to specify the tracked model type explicitly,
  /// for example in generic type parameters.
  static Type get trackedType => $UserWithProfile;

  /// Converts this immutable model to a tracked ORM-managed model.
  /// The tracked model supports attribute tracking, change detection,
  /// and persistence operations like save() and touch().
  $UserWithProfile toTracked() {
    return $UserWithProfile.fromModel(this);
  }
}

void registerUserWithProfileEventHandlers(EventBus bus) {
  // No event handlers registered for UserWithProfile.
}

const FieldDefinition _$ProfileIdField = FieldDefinition(
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

const FieldDefinition _$ProfileUserIdField = FieldDefinition(
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

const FieldDefinition _$ProfileBioField = FieldDefinition(
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

Map<String, Object?> _encodeProfileUntracked(
  Object model,
  ValueCodecRegistry registry,
) {
  final m = model as Profile;
  return <String, Object?>{
    'id': registry.encodeField(_$ProfileIdField, m.id),
    'user_id': registry.encodeField(_$ProfileUserIdField, m.userId),
    'bio': registry.encodeField(_$ProfileBioField, m.bio),
  };
}

final ModelDefinition<$Profile> _$ProfileDefinition = ModelDefinition(
  modelName: 'Profile',
  tableName: 'profiles',
  fields: const [_$ProfileIdField, _$ProfileUserIdField, _$ProfileBioField],
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
  untrackedToMap: _encodeProfileUntracked,
  codec: _$ProfileCodec(),
);

extension ProfileOrmDefinition on Profile {
  static ModelDefinition<$Profile> get definition => _$ProfileDefinition;
}

class Profiles {
  const Profiles._();

  /// Starts building a query for [$Profile].
  ///
  /// {@macro ormed.query}
  static Query<$Profile> query([String? connection]) =>
      Model.query<$Profile>(connection: connection);

  static Future<$Profile?> find(Object id, {String? connection}) =>
      Model.find<$Profile>(id, connection: connection);

  static Future<$Profile> findOrFail(Object id, {String? connection}) =>
      Model.findOrFail<$Profile>(id, connection: connection);

  static Future<List<$Profile>> all({String? connection}) =>
      Model.all<$Profile>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<$Profile>(connection: connection);

  static Future<bool> anyExist({String? connection}) =>
      Model.anyExist<$Profile>(connection: connection);

  static Query<$Profile> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) => Model.where<$Profile>(column, operator, value, connection: connection);

  static Query<$Profile> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<$Profile>(column, values, connection: connection);

  static Query<$Profile> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<$Profile>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<$Profile> limit(int count, {String? connection}) =>
      Model.limit<$Profile>(count, connection: connection);

  /// Creates a [Repository] for [$Profile].
  ///
  /// {@macro ormed.repository}
  static Repository<$Profile> repo([String? connection]) =>
      Model.repository<$Profile>(connection: connection);
}

class ProfileModelFactory {
  const ProfileModelFactory._();

  static ModelDefinition<$Profile> get definition => _$ProfileDefinition;

  static ModelCodec<$Profile> get codec => definition.codec;

  static Profile fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    Profile model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model.toTracked(), registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<Profile> withConnection(QueryContext context) =>
      ModelFactoryConnection<Profile>(definition: definition, context: context);

  static ModelFactoryBuilder<Profile> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<Profile>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$ProfileCodec extends ModelCodec<$Profile> {
  const _$ProfileCodec();
  @override
  Map<String, Object?> encode($Profile model, ValueCodecRegistry registry) {
    return <String, Object?>{
      'id': registry.encodeField(_$ProfileIdField, model.id),
      'user_id': registry.encodeField(_$ProfileUserIdField, model.userId),
      'bio': registry.encodeField(_$ProfileBioField, model.bio),
    };
  }

  @override
  $Profile decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final int profileIdValue =
        registry.decodeField<int>(_$ProfileIdField, data['id']) ??
        (throw StateError('Field id on Profile cannot be null.'));
    final int profileUserIdValue =
        registry.decodeField<int>(_$ProfileUserIdField, data['user_id']) ??
        (throw StateError('Field userId on Profile cannot be null.'));
    final String profileBioValue =
        registry.decodeField<String>(_$ProfileBioField, data['bio']) ??
        (throw StateError('Field bio on Profile cannot be null.'));
    final model = $Profile(
      id: profileIdValue,
      userId: profileUserIdValue,
      bio: profileBioValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': profileIdValue,
      'user_id': profileUserIdValue,
      'bio': profileBioValue,
    });
    return model;
  }
}

/// Insert DTO for [Profile].
///
/// Auto-increment/DB-generated fields are omitted by default.
class ProfileInsertDto implements InsertDto<$Profile> {
  const ProfileInsertDto({this.id, this.userId, this.bio});
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

  static const _ProfileInsertDtoCopyWithSentinel _copyWithSentinel =
      _ProfileInsertDtoCopyWithSentinel();
  ProfileInsertDto copyWith({
    Object? id = _copyWithSentinel,
    Object? userId = _copyWithSentinel,
    Object? bio = _copyWithSentinel,
  }) {
    return ProfileInsertDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      userId: identical(userId, _copyWithSentinel)
          ? this.userId
          : userId as int?,
      bio: identical(bio, _copyWithSentinel) ? this.bio : bio as String?,
    );
  }
}

class _ProfileInsertDtoCopyWithSentinel {
  const _ProfileInsertDtoCopyWithSentinel();
}

/// Update DTO for [Profile].
///
/// All fields are optional; only provided entries are used in SET clauses.
class ProfileUpdateDto implements UpdateDto<$Profile> {
  const ProfileUpdateDto({this.id, this.userId, this.bio});
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

  static const _ProfileUpdateDtoCopyWithSentinel _copyWithSentinel =
      _ProfileUpdateDtoCopyWithSentinel();
  ProfileUpdateDto copyWith({
    Object? id = _copyWithSentinel,
    Object? userId = _copyWithSentinel,
    Object? bio = _copyWithSentinel,
  }) {
    return ProfileUpdateDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      userId: identical(userId, _copyWithSentinel)
          ? this.userId
          : userId as int?,
      bio: identical(bio, _copyWithSentinel) ? this.bio : bio as String?,
    );
  }
}

class _ProfileUpdateDtoCopyWithSentinel {
  const _ProfileUpdateDtoCopyWithSentinel();
}

/// Partial projection for [Profile].
///
/// All fields are nullable; intended for subset SELECTs.
class ProfilePartial implements PartialEntity<$Profile> {
  const ProfilePartial({this.id, this.userId, this.bio});

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory ProfilePartial.fromRow(Map<String, Object?> row) {
    return ProfilePartial(
      id: row['id'] as int?,
      userId: row['user_id'] as int?,
      bio: row['bio'] as String?,
    );
  }

  final int? id;
  final int? userId;
  final String? bio;

  @override
  $Profile toEntity() {
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
    return $Profile(id: idValue, userId: userIdValue, bio: bioValue);
  }

  @override
  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (bio != null) 'bio': bio,
    };
  }

  static const _ProfilePartialCopyWithSentinel _copyWithSentinel =
      _ProfilePartialCopyWithSentinel();
  ProfilePartial copyWith({
    Object? id = _copyWithSentinel,
    Object? userId = _copyWithSentinel,
    Object? bio = _copyWithSentinel,
  }) {
    return ProfilePartial(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      userId: identical(userId, _copyWithSentinel)
          ? this.userId
          : userId as int?,
      bio: identical(bio, _copyWithSentinel) ? this.bio : bio as String?,
    );
  }
}

class _ProfilePartialCopyWithSentinel {
  const _ProfilePartialCopyWithSentinel();
}

/// Generated tracked model class for [Profile].
///
/// This class extends the user-defined [Profile] model and adds
/// attribute tracking, change detection, and relationship management.
/// Instances of this class are returned by queries and repositories.
///
/// **Do not instantiate this class directly.** Use queries, repositories,
/// or model factories to create tracked model instances.
class $Profile extends Profile with ModelAttributes implements OrmEntity {
  /// Internal constructor for [$Profile].
  $Profile({required int id, required int userId, required String bio})
    : super.new(id: id, userId: userId, bio: bio) {
    _attachOrmRuntimeMetadata({'id': id, 'user_id': userId, 'bio': bio});
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $Profile.fromModel(Profile model) {
    return $Profile(id: model.id, userId: model.userId, bio: model.bio);
  }

  $Profile copyWith({int? id, int? userId, String? bio}) {
    return $Profile(
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
    attachModelDefinition(_$ProfileDefinition);
  }
}

extension ProfileOrmExtension on Profile {
  /// The Type of the generated ORM-managed model class.
  /// Use this when you need to specify the tracked model type explicitly,
  /// for example in generic type parameters.
  static Type get trackedType => $Profile;

  /// Converts this immutable model to a tracked ORM-managed model.
  /// The tracked model supports attribute tracking, change detection,
  /// and persistence operations like save() and touch().
  $Profile toTracked() {
    return $Profile.fromModel(this);
  }
}

void registerProfileEventHandlers(EventBus bus) {
  // No event handlers registered for Profile.
}
