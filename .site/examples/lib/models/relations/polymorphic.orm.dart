// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'polymorphic.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$MorphUserIdField = FieldDefinition(
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

const RelationDefinition _$MorphUserAvatarRelation = RelationDefinition(
  name: 'avatar',
  kind: RelationKind.morphOne,
  targetModel: 'MorphPhoto',
  foreignKey: 'imageable_id',
  morphType: 'imageable_type',
  morphClass: 'User',
);

Map<String, Object?> _encodeMorphUserUntracked(
  Object model,
  ValueCodecRegistry registry,
) {
  final m = model as MorphUser;
  return <String, Object?>{
    'id': registry.encodeField(_$MorphUserIdField, m.id),
  };
}

final ModelDefinition<$MorphUser> _$MorphUserDefinition = ModelDefinition(
  modelName: 'MorphUser',
  tableName: 'users',
  fields: const [_$MorphUserIdField],
  relations: const [_$MorphUserAvatarRelation],
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
  untrackedToMap: _encodeMorphUserUntracked,
  codec: _$MorphUserCodec(),
);

extension MorphUserOrmDefinition on MorphUser {
  static ModelDefinition<$MorphUser> get definition => _$MorphUserDefinition;
}

class MorphUsers {
  const MorphUsers._();

  /// Starts building a query for [$MorphUser].
  ///
  /// {@macro ormed.query}
  static Query<$MorphUser> query([String? connection]) =>
      Model.query<$MorphUser>(connection: connection);

  static Future<$MorphUser?> find(Object id, {String? connection}) =>
      Model.find<$MorphUser>(id, connection: connection);

  static Future<$MorphUser> findOrFail(Object id, {String? connection}) =>
      Model.findOrFail<$MorphUser>(id, connection: connection);

  static Future<List<$MorphUser>> all({String? connection}) =>
      Model.all<$MorphUser>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<$MorphUser>(connection: connection);

  static Future<bool> anyExist({String? connection}) =>
      Model.anyExist<$MorphUser>(connection: connection);

  static Query<$MorphUser> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) =>
      Model.where<$MorphUser>(column, operator, value, connection: connection);

  static Query<$MorphUser> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<$MorphUser>(column, values, connection: connection);

  static Query<$MorphUser> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<$MorphUser>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<$MorphUser> limit(int count, {String? connection}) =>
      Model.limit<$MorphUser>(count, connection: connection);

  /// Creates a [Repository] for [$MorphUser].
  ///
  /// {@macro ormed.repository}
  static Repository<$MorphUser> repo([String? connection]) =>
      Model.repository<$MorphUser>(connection: connection);
}

class MorphUserModelFactory {
  const MorphUserModelFactory._();

  static ModelDefinition<$MorphUser> get definition => _$MorphUserDefinition;

  static ModelCodec<$MorphUser> get codec => definition.codec;

  static MorphUser fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    MorphUser model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model.toTracked(), registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<MorphUser> withConnection(
    QueryContext context,
  ) => ModelFactoryConnection<MorphUser>(
    definition: definition,
    context: context,
  );

  static ModelFactoryBuilder<MorphUser> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<MorphUser>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$MorphUserCodec extends ModelCodec<$MorphUser> {
  const _$MorphUserCodec();
  @override
  Map<String, Object?> encode($MorphUser model, ValueCodecRegistry registry) {
    return <String, Object?>{
      'id': registry.encodeField(_$MorphUserIdField, model.id),
    };
  }

  @override
  $MorphUser decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final int morphUserIdValue =
        registry.decodeField<int>(_$MorphUserIdField, data['id']) ??
        (throw StateError('Field id on MorphUser cannot be null.'));
    final model = $MorphUser(id: morphUserIdValue);
    model._attachOrmRuntimeMetadata({'id': morphUserIdValue});
    return model;
  }
}

/// Insert DTO for [MorphUser].
///
/// Auto-increment/DB-generated fields are omitted by default.
class MorphUserInsertDto implements InsertDto<$MorphUser> {
  const MorphUserInsertDto({this.id});
  final int? id;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{if (id != null) 'id': id};
  }

  static const _MorphUserInsertDtoCopyWithSentinel _copyWithSentinel =
      _MorphUserInsertDtoCopyWithSentinel();
  MorphUserInsertDto copyWith({Object? id = _copyWithSentinel}) {
    return MorphUserInsertDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
    );
  }
}

class _MorphUserInsertDtoCopyWithSentinel {
  const _MorphUserInsertDtoCopyWithSentinel();
}

/// Update DTO for [MorphUser].
///
/// All fields are optional; only provided entries are used in SET clauses.
class MorphUserUpdateDto implements UpdateDto<$MorphUser> {
  const MorphUserUpdateDto({this.id});
  final int? id;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{if (id != null) 'id': id};
  }

  static const _MorphUserUpdateDtoCopyWithSentinel _copyWithSentinel =
      _MorphUserUpdateDtoCopyWithSentinel();
  MorphUserUpdateDto copyWith({Object? id = _copyWithSentinel}) {
    return MorphUserUpdateDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
    );
  }
}

class _MorphUserUpdateDtoCopyWithSentinel {
  const _MorphUserUpdateDtoCopyWithSentinel();
}

/// Partial projection for [MorphUser].
///
/// All fields are nullable; intended for subset SELECTs.
class MorphUserPartial implements PartialEntity<$MorphUser> {
  const MorphUserPartial({this.id});

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory MorphUserPartial.fromRow(Map<String, Object?> row) {
    return MorphUserPartial(id: row['id'] as int?);
  }

  final int? id;

  @override
  $MorphUser toEntity() {
    // Basic required-field check: non-nullable fields must be present.
    final int? idValue = id;
    if (idValue == null) {
      throw StateError('Missing required field: id');
    }
    return $MorphUser(id: idValue);
  }

  @override
  Map<String, Object?> toMap() {
    return {if (id != null) 'id': id};
  }

  static const _MorphUserPartialCopyWithSentinel _copyWithSentinel =
      _MorphUserPartialCopyWithSentinel();
  MorphUserPartial copyWith({Object? id = _copyWithSentinel}) {
    return MorphUserPartial(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
    );
  }
}

class _MorphUserPartialCopyWithSentinel {
  const _MorphUserPartialCopyWithSentinel();
}

/// Generated tracked model class for [MorphUser].
///
/// This class extends the user-defined [MorphUser] model and adds
/// attribute tracking, change detection, and relationship management.
/// Instances of this class are returned by queries and repositories.
///
/// **Do not instantiate this class directly.** Use queries, repositories,
/// or model factories to create tracked model instances.
class $MorphUser extends MorphUser with ModelAttributes implements OrmEntity {
  /// Internal constructor for [$MorphUser].
  $MorphUser({required int id}) : super.new(id: id) {
    _attachOrmRuntimeMetadata({'id': id});
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $MorphUser.fromModel(MorphUser model) {
    return $MorphUser(id: model.id);
  }

  $MorphUser copyWith({int? id}) {
    return $MorphUser(id: id ?? this.id);
  }

  /// Tracked getter for [id].
  @override
  int get id => getAttribute<int>('id') ?? super.id;

  /// Tracked setter for [id].
  set id(int value) => setAttribute('id', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$MorphUserDefinition);
  }

  @override
  MorphPhoto? get avatar {
    if (relationLoaded('avatar')) {
      return getRelation<MorphPhoto>('avatar');
    }
    return super.avatar;
  }
}

extension MorphUserRelationQueries on MorphUser {
  Query<MorphPhoto> avatarQuery() {
    throw UnimplementedError(
      "Polymorphic relation query generation not yet supported",
    );
  }
}

extension MorphUserOrmExtension on MorphUser {
  /// The Type of the generated ORM-managed model class.
  /// Use this when you need to specify the tracked model type explicitly,
  /// for example in generic type parameters.
  static Type get trackedType => $MorphUser;

  /// Converts this immutable model to a tracked ORM-managed model.
  /// The tracked model supports attribute tracking, change detection,
  /// and persistence operations like save() and touch().
  $MorphUser toTracked() {
    return $MorphUser.fromModel(this);
  }
}

void registerMorphUserEventHandlers(EventBus bus) {
  // No event handlers registered for MorphUser.
}

const FieldDefinition _$MorphPostPhotosIdField = FieldDefinition(
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

const RelationDefinition _$MorphPostPhotosPhotosRelation = RelationDefinition(
  name: 'photos',
  kind: RelationKind.morphMany,
  targetModel: 'MorphPhoto',
  foreignKey: 'imageable_id',
  morphType: 'imageable_type',
  morphClass: 'Post',
);

Map<String, Object?> _encodeMorphPostPhotosUntracked(
  Object model,
  ValueCodecRegistry registry,
) {
  final m = model as MorphPostPhotos;
  return <String, Object?>{
    'id': registry.encodeField(_$MorphPostPhotosIdField, m.id),
  };
}

final ModelDefinition<$MorphPostPhotos> _$MorphPostPhotosDefinition =
    ModelDefinition(
      modelName: 'MorphPostPhotos',
      tableName: 'posts',
      fields: const [_$MorphPostPhotosIdField],
      relations: const [_$MorphPostPhotosPhotosRelation],
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
      untrackedToMap: _encodeMorphPostPhotosUntracked,
      codec: _$MorphPostPhotosCodec(),
    );

extension MorphPostPhotosOrmDefinition on MorphPostPhotos {
  static ModelDefinition<$MorphPostPhotos> get definition =>
      _$MorphPostPhotosDefinition;
}

class MorphPostPhotos {
  const MorphPostPhotos._();

  /// Starts building a query for [$MorphPostPhotos].
  ///
  /// {@macro ormed.query}
  static Query<$MorphPostPhotos> query([String? connection]) =>
      Model.query<$MorphPostPhotos>(connection: connection);

  static Future<$MorphPostPhotos?> find(Object id, {String? connection}) =>
      Model.find<$MorphPostPhotos>(id, connection: connection);

  static Future<$MorphPostPhotos> findOrFail(Object id, {String? connection}) =>
      Model.findOrFail<$MorphPostPhotos>(id, connection: connection);

  static Future<List<$MorphPostPhotos>> all({String? connection}) =>
      Model.all<$MorphPostPhotos>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<$MorphPostPhotos>(connection: connection);

  static Future<bool> anyExist({String? connection}) =>
      Model.anyExist<$MorphPostPhotos>(connection: connection);

  static Query<$MorphPostPhotos> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) => Model.where<$MorphPostPhotos>(
    column,
    operator,
    value,
    connection: connection,
  );

  static Query<$MorphPostPhotos> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<$MorphPostPhotos>(column, values, connection: connection);

  static Query<$MorphPostPhotos> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<$MorphPostPhotos>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<$MorphPostPhotos> limit(int count, {String? connection}) =>
      Model.limit<$MorphPostPhotos>(count, connection: connection);

  /// Creates a [Repository] for [$MorphPostPhotos].
  ///
  /// {@macro ormed.repository}
  static Repository<$MorphPostPhotos> repo([String? connection]) =>
      Model.repository<$MorphPostPhotos>(connection: connection);
}

class MorphPostPhotosModelFactory {
  const MorphPostPhotosModelFactory._();

  static ModelDefinition<$MorphPostPhotos> get definition =>
      _$MorphPostPhotosDefinition;

  static ModelCodec<$MorphPostPhotos> get codec => definition.codec;

  static MorphPostPhotos fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    MorphPostPhotos model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model.toTracked(), registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<MorphPostPhotos> withConnection(
    QueryContext context,
  ) => ModelFactoryConnection<MorphPostPhotos>(
    definition: definition,
    context: context,
  );

  static ModelFactoryBuilder<MorphPostPhotos> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<MorphPostPhotos>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$MorphPostPhotosCodec extends ModelCodec<$MorphPostPhotos> {
  const _$MorphPostPhotosCodec();
  @override
  Map<String, Object?> encode(
    $MorphPostPhotos model,
    ValueCodecRegistry registry,
  ) {
    return <String, Object?>{
      'id': registry.encodeField(_$MorphPostPhotosIdField, model.id),
    };
  }

  @override
  $MorphPostPhotos decode(
    Map<String, Object?> data,
    ValueCodecRegistry registry,
  ) {
    final int morphPostPhotosIdValue =
        registry.decodeField<int>(_$MorphPostPhotosIdField, data['id']) ??
        (throw StateError('Field id on MorphPostPhotos cannot be null.'));
    final model = $MorphPostPhotos(id: morphPostPhotosIdValue);
    model._attachOrmRuntimeMetadata({'id': morphPostPhotosIdValue});
    return model;
  }
}

/// Insert DTO for [MorphPostPhotos].
///
/// Auto-increment/DB-generated fields are omitted by default.
class MorphPostPhotosInsertDto implements InsertDto<$MorphPostPhotos> {
  const MorphPostPhotosInsertDto({this.id});
  final int? id;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{if (id != null) 'id': id};
  }

  static const _MorphPostPhotosInsertDtoCopyWithSentinel _copyWithSentinel =
      _MorphPostPhotosInsertDtoCopyWithSentinel();
  MorphPostPhotosInsertDto copyWith({Object? id = _copyWithSentinel}) {
    return MorphPostPhotosInsertDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
    );
  }
}

class _MorphPostPhotosInsertDtoCopyWithSentinel {
  const _MorphPostPhotosInsertDtoCopyWithSentinel();
}

/// Update DTO for [MorphPostPhotos].
///
/// All fields are optional; only provided entries are used in SET clauses.
class MorphPostPhotosUpdateDto implements UpdateDto<$MorphPostPhotos> {
  const MorphPostPhotosUpdateDto({this.id});
  final int? id;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{if (id != null) 'id': id};
  }

  static const _MorphPostPhotosUpdateDtoCopyWithSentinel _copyWithSentinel =
      _MorphPostPhotosUpdateDtoCopyWithSentinel();
  MorphPostPhotosUpdateDto copyWith({Object? id = _copyWithSentinel}) {
    return MorphPostPhotosUpdateDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
    );
  }
}

class _MorphPostPhotosUpdateDtoCopyWithSentinel {
  const _MorphPostPhotosUpdateDtoCopyWithSentinel();
}

/// Partial projection for [MorphPostPhotos].
///
/// All fields are nullable; intended for subset SELECTs.
class MorphPostPhotosPartial implements PartialEntity<$MorphPostPhotos> {
  const MorphPostPhotosPartial({this.id});

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory MorphPostPhotosPartial.fromRow(Map<String, Object?> row) {
    return MorphPostPhotosPartial(id: row['id'] as int?);
  }

  final int? id;

  @override
  $MorphPostPhotos toEntity() {
    // Basic required-field check: non-nullable fields must be present.
    final int? idValue = id;
    if (idValue == null) {
      throw StateError('Missing required field: id');
    }
    return $MorphPostPhotos(id: idValue);
  }

  @override
  Map<String, Object?> toMap() {
    return {if (id != null) 'id': id};
  }

  static const _MorphPostPhotosPartialCopyWithSentinel _copyWithSentinel =
      _MorphPostPhotosPartialCopyWithSentinel();
  MorphPostPhotosPartial copyWith({Object? id = _copyWithSentinel}) {
    return MorphPostPhotosPartial(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
    );
  }
}

class _MorphPostPhotosPartialCopyWithSentinel {
  const _MorphPostPhotosPartialCopyWithSentinel();
}

/// Generated tracked model class for [MorphPostPhotos].
///
/// This class extends the user-defined [MorphPostPhotos] model and adds
/// attribute tracking, change detection, and relationship management.
/// Instances of this class are returned by queries and repositories.
///
/// **Do not instantiate this class directly.** Use queries, repositories,
/// or model factories to create tracked model instances.
class $MorphPostPhotos extends MorphPostPhotos
    with ModelAttributes
    implements OrmEntity {
  /// Internal constructor for [$MorphPostPhotos].
  $MorphPostPhotos({required int id}) : super.new(id: id) {
    _attachOrmRuntimeMetadata({'id': id});
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $MorphPostPhotos.fromModel(MorphPostPhotos model) {
    return $MorphPostPhotos(id: model.id);
  }

  $MorphPostPhotos copyWith({int? id}) {
    return $MorphPostPhotos(id: id ?? this.id);
  }

  /// Tracked getter for [id].
  @override
  int get id => getAttribute<int>('id') ?? super.id;

  /// Tracked setter for [id].
  set id(int value) => setAttribute('id', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$MorphPostPhotosDefinition);
  }

  @override
  List<MorphPhoto> get photos {
    if (relationLoaded('photos')) {
      return getRelationList<MorphPhoto>('photos');
    }
    return super.photos;
  }
}

extension MorphPostPhotosRelationQueries on MorphPostPhotos {
  Query<MorphPhoto> photosQuery() {
    throw UnimplementedError(
      "Polymorphic relation query generation not yet supported",
    );
  }
}

extension MorphPostPhotosOrmExtension on MorphPostPhotos {
  /// The Type of the generated ORM-managed model class.
  /// Use this when you need to specify the tracked model type explicitly,
  /// for example in generic type parameters.
  static Type get trackedType => $MorphPostPhotos;

  /// Converts this immutable model to a tracked ORM-managed model.
  /// The tracked model supports attribute tracking, change detection,
  /// and persistence operations like save() and touch().
  $MorphPostPhotos toTracked() {
    return $MorphPostPhotos.fromModel(this);
  }
}

void registerMorphPostPhotosEventHandlers(EventBus bus) {
  // No event handlers registered for MorphPostPhotos.
}

const FieldDefinition _$MorphPhotoIdField = FieldDefinition(
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

const FieldDefinition _$MorphPhotoImageableIdField = FieldDefinition(
  name: 'imageableId',
  columnName: 'imageable_id',
  dartType: 'int',
  resolvedType: 'int?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$MorphPhotoImageableTypeField = FieldDefinition(
  name: 'imageableType',
  columnName: 'imageable_type',
  dartType: 'String',
  resolvedType: 'String?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const RelationDefinition _$MorphPhotoImageableRelation = RelationDefinition(
  name: 'imageable',
  kind: RelationKind.morphTo,
  targetModel: 'OrmEntity',
  foreignKey: 'imageable_id',
  morphType: 'imageable_type',
);

Map<String, Object?> _encodeMorphPhotoUntracked(
  Object model,
  ValueCodecRegistry registry,
) {
  final m = model as MorphPhoto;
  return <String, Object?>{
    'id': registry.encodeField(_$MorphPhotoIdField, m.id),
    'imageable_id': registry.encodeField(
      _$MorphPhotoImageableIdField,
      m.imageableId,
    ),
    'imageable_type': registry.encodeField(
      _$MorphPhotoImageableTypeField,
      m.imageableType,
    ),
  };
}

final ModelDefinition<$MorphPhoto> _$MorphPhotoDefinition = ModelDefinition(
  modelName: 'MorphPhoto',
  tableName: 'photos',
  fields: const [
    _$MorphPhotoIdField,
    _$MorphPhotoImageableIdField,
    _$MorphPhotoImageableTypeField,
  ],
  relations: const [_$MorphPhotoImageableRelation],
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
  untrackedToMap: _encodeMorphPhotoUntracked,
  codec: _$MorphPhotoCodec(),
);

extension MorphPhotoOrmDefinition on MorphPhoto {
  static ModelDefinition<$MorphPhoto> get definition => _$MorphPhotoDefinition;
}

class MorphPhotos {
  const MorphPhotos._();

  /// Starts building a query for [$MorphPhoto].
  ///
  /// {@macro ormed.query}
  static Query<$MorphPhoto> query([String? connection]) =>
      Model.query<$MorphPhoto>(connection: connection);

  static Future<$MorphPhoto?> find(Object id, {String? connection}) =>
      Model.find<$MorphPhoto>(id, connection: connection);

  static Future<$MorphPhoto> findOrFail(Object id, {String? connection}) =>
      Model.findOrFail<$MorphPhoto>(id, connection: connection);

  static Future<List<$MorphPhoto>> all({String? connection}) =>
      Model.all<$MorphPhoto>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<$MorphPhoto>(connection: connection);

  static Future<bool> anyExist({String? connection}) =>
      Model.anyExist<$MorphPhoto>(connection: connection);

  static Query<$MorphPhoto> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) =>
      Model.where<$MorphPhoto>(column, operator, value, connection: connection);

  static Query<$MorphPhoto> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<$MorphPhoto>(column, values, connection: connection);

  static Query<$MorphPhoto> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<$MorphPhoto>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<$MorphPhoto> limit(int count, {String? connection}) =>
      Model.limit<$MorphPhoto>(count, connection: connection);

  /// Creates a [Repository] for [$MorphPhoto].
  ///
  /// {@macro ormed.repository}
  static Repository<$MorphPhoto> repo([String? connection]) =>
      Model.repository<$MorphPhoto>(connection: connection);
}

class MorphPhotoModelFactory {
  const MorphPhotoModelFactory._();

  static ModelDefinition<$MorphPhoto> get definition => _$MorphPhotoDefinition;

  static ModelCodec<$MorphPhoto> get codec => definition.codec;

  static MorphPhoto fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    MorphPhoto model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model.toTracked(), registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<MorphPhoto> withConnection(
    QueryContext context,
  ) => ModelFactoryConnection<MorphPhoto>(
    definition: definition,
    context: context,
  );

  static ModelFactoryBuilder<MorphPhoto> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<MorphPhoto>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$MorphPhotoCodec extends ModelCodec<$MorphPhoto> {
  const _$MorphPhotoCodec();
  @override
  Map<String, Object?> encode($MorphPhoto model, ValueCodecRegistry registry) {
    return <String, Object?>{
      'id': registry.encodeField(_$MorphPhotoIdField, model.id),
      'imageable_id': registry.encodeField(
        _$MorphPhotoImageableIdField,
        model.imageableId,
      ),
      'imageable_type': registry.encodeField(
        _$MorphPhotoImageableTypeField,
        model.imageableType,
      ),
    };
  }

  @override
  $MorphPhoto decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final int morphPhotoIdValue =
        registry.decodeField<int>(_$MorphPhotoIdField, data['id']) ??
        (throw StateError('Field id on MorphPhoto cannot be null.'));
    final int? morphPhotoImageableIdValue = registry.decodeField<int?>(
      _$MorphPhotoImageableIdField,
      data['imageable_id'],
    );
    final String? morphPhotoImageableTypeValue = registry.decodeField<String?>(
      _$MorphPhotoImageableTypeField,
      data['imageable_type'],
    );
    final model = $MorphPhoto(
      id: morphPhotoIdValue,
      imageableId: morphPhotoImageableIdValue,
      imageableType: morphPhotoImageableTypeValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': morphPhotoIdValue,
      'imageable_id': morphPhotoImageableIdValue,
      'imageable_type': morphPhotoImageableTypeValue,
    });
    return model;
  }
}

/// Insert DTO for [MorphPhoto].
///
/// Auto-increment/DB-generated fields are omitted by default.
class MorphPhotoInsertDto implements InsertDto<$MorphPhoto> {
  const MorphPhotoInsertDto({this.id, this.imageableId, this.imageableType});
  final int? id;
  final int? imageableId;
  final String? imageableType;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (imageableId != null) 'imageable_id': imageableId,
      if (imageableType != null) 'imageable_type': imageableType,
    };
  }

  static const _MorphPhotoInsertDtoCopyWithSentinel _copyWithSentinel =
      _MorphPhotoInsertDtoCopyWithSentinel();
  MorphPhotoInsertDto copyWith({
    Object? id = _copyWithSentinel,
    Object? imageableId = _copyWithSentinel,
    Object? imageableType = _copyWithSentinel,
  }) {
    return MorphPhotoInsertDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      imageableId: identical(imageableId, _copyWithSentinel)
          ? this.imageableId
          : imageableId as int?,
      imageableType: identical(imageableType, _copyWithSentinel)
          ? this.imageableType
          : imageableType as String?,
    );
  }
}

class _MorphPhotoInsertDtoCopyWithSentinel {
  const _MorphPhotoInsertDtoCopyWithSentinel();
}

/// Update DTO for [MorphPhoto].
///
/// All fields are optional; only provided entries are used in SET clauses.
class MorphPhotoUpdateDto implements UpdateDto<$MorphPhoto> {
  const MorphPhotoUpdateDto({this.id, this.imageableId, this.imageableType});
  final int? id;
  final int? imageableId;
  final String? imageableType;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (imageableId != null) 'imageable_id': imageableId,
      if (imageableType != null) 'imageable_type': imageableType,
    };
  }

  static const _MorphPhotoUpdateDtoCopyWithSentinel _copyWithSentinel =
      _MorphPhotoUpdateDtoCopyWithSentinel();
  MorphPhotoUpdateDto copyWith({
    Object? id = _copyWithSentinel,
    Object? imageableId = _copyWithSentinel,
    Object? imageableType = _copyWithSentinel,
  }) {
    return MorphPhotoUpdateDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      imageableId: identical(imageableId, _copyWithSentinel)
          ? this.imageableId
          : imageableId as int?,
      imageableType: identical(imageableType, _copyWithSentinel)
          ? this.imageableType
          : imageableType as String?,
    );
  }
}

class _MorphPhotoUpdateDtoCopyWithSentinel {
  const _MorphPhotoUpdateDtoCopyWithSentinel();
}

/// Partial projection for [MorphPhoto].
///
/// All fields are nullable; intended for subset SELECTs.
class MorphPhotoPartial implements PartialEntity<$MorphPhoto> {
  const MorphPhotoPartial({this.id, this.imageableId, this.imageableType});

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory MorphPhotoPartial.fromRow(Map<String, Object?> row) {
    return MorphPhotoPartial(
      id: row['id'] as int?,
      imageableId: row['imageable_id'] as int?,
      imageableType: row['imageable_type'] as String?,
    );
  }

  final int? id;
  final int? imageableId;
  final String? imageableType;

  @override
  $MorphPhoto toEntity() {
    // Basic required-field check: non-nullable fields must be present.
    final int? idValue = id;
    if (idValue == null) {
      throw StateError('Missing required field: id');
    }
    return $MorphPhoto(
      id: idValue,
      imageableId: imageableId,
      imageableType: imageableType,
    );
  }

  @override
  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      if (imageableId != null) 'imageable_id': imageableId,
      if (imageableType != null) 'imageable_type': imageableType,
    };
  }

  static const _MorphPhotoPartialCopyWithSentinel _copyWithSentinel =
      _MorphPhotoPartialCopyWithSentinel();
  MorphPhotoPartial copyWith({
    Object? id = _copyWithSentinel,
    Object? imageableId = _copyWithSentinel,
    Object? imageableType = _copyWithSentinel,
  }) {
    return MorphPhotoPartial(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      imageableId: identical(imageableId, _copyWithSentinel)
          ? this.imageableId
          : imageableId as int?,
      imageableType: identical(imageableType, _copyWithSentinel)
          ? this.imageableType
          : imageableType as String?,
    );
  }
}

class _MorphPhotoPartialCopyWithSentinel {
  const _MorphPhotoPartialCopyWithSentinel();
}

/// Generated tracked model class for [MorphPhoto].
///
/// This class extends the user-defined [MorphPhoto] model and adds
/// attribute tracking, change detection, and relationship management.
/// Instances of this class are returned by queries and repositories.
///
/// **Do not instantiate this class directly.** Use queries, repositories,
/// or model factories to create tracked model instances.
class $MorphPhoto extends MorphPhoto with ModelAttributes implements OrmEntity {
  /// Internal constructor for [$MorphPhoto].
  $MorphPhoto({required int id, int? imageableId, String? imageableType})
    : super.new(
        id: id,
        imageableId: imageableId,
        imageableType: imageableType,
      ) {
    _attachOrmRuntimeMetadata({
      'id': id,
      'imageable_id': imageableId,
      'imageable_type': imageableType,
    });
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $MorphPhoto.fromModel(MorphPhoto model) {
    return $MorphPhoto(
      id: model.id,
      imageableId: model.imageableId,
      imageableType: model.imageableType,
    );
  }

  $MorphPhoto copyWith({int? id, int? imageableId, String? imageableType}) {
    return $MorphPhoto(
      id: id ?? this.id,
      imageableId: imageableId ?? this.imageableId,
      imageableType: imageableType ?? this.imageableType,
    );
  }

  /// Tracked getter for [id].
  @override
  int get id => getAttribute<int>('id') ?? super.id;

  /// Tracked setter for [id].
  set id(int value) => setAttribute('id', value);

  /// Tracked getter for [imageableId].
  @override
  int? get imageableId =>
      getAttribute<int?>('imageable_id') ?? super.imageableId;

  /// Tracked setter for [imageableId].
  set imageableId(int? value) => setAttribute('imageable_id', value);

  /// Tracked getter for [imageableType].
  @override
  String? get imageableType =>
      getAttribute<String?>('imageable_type') ?? super.imageableType;

  /// Tracked setter for [imageableType].
  set imageableType(String? value) => setAttribute('imageable_type', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$MorphPhotoDefinition);
  }

  @override
  OrmEntity? get imageable {
    if (relationLoaded('imageable')) {
      return getRelation<OrmEntity>('imageable');
    }
    return super.imageable;
  }
}

extension MorphPhotoRelationQueries on MorphPhoto {
  Query<OrmEntity> imageableQuery() {
    throw UnimplementedError(
      "Polymorphic relation query generation not yet supported",
    );
  }
}

extension MorphPhotoOrmExtension on MorphPhoto {
  /// The Type of the generated ORM-managed model class.
  /// Use this when you need to specify the tracked model type explicitly,
  /// for example in generic type parameters.
  static Type get trackedType => $MorphPhoto;

  /// Converts this immutable model to a tracked ORM-managed model.
  /// The tracked model supports attribute tracking, change detection,
  /// and persistence operations like save() and touch().
  $MorphPhoto toTracked() {
    return $MorphPhoto.fromModel(this);
  }
}

void registerMorphPhotoEventHandlers(EventBus bus) {
  // No event handlers registered for MorphPhoto.
}

const FieldDefinition _$MorphPostTagsIdField = FieldDefinition(
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

const RelationDefinition _$MorphPostTagsTagsRelation = RelationDefinition(
  name: 'tags',
  kind: RelationKind.morphToMany,
  targetModel: 'MorphTag',
  through: 'taggables',
  pivotForeignKey: 'taggable_id',
  pivotRelatedKey: 'tag_id',
  morphType: 'taggable_type',
  morphClass: 'Post',
);

Map<String, Object?> _encodeMorphPostTagsUntracked(
  Object model,
  ValueCodecRegistry registry,
) {
  final m = model as MorphPostTags;
  return <String, Object?>{
    'id': registry.encodeField(_$MorphPostTagsIdField, m.id),
  };
}

final ModelDefinition<$MorphPostTags> _$MorphPostTagsDefinition =
    ModelDefinition(
      modelName: 'MorphPostTags',
      tableName: 'posts',
      fields: const [_$MorphPostTagsIdField],
      relations: const [_$MorphPostTagsTagsRelation],
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
      untrackedToMap: _encodeMorphPostTagsUntracked,
      codec: _$MorphPostTagsCodec(),
    );

extension MorphPostTagsOrmDefinition on MorphPostTags {
  static ModelDefinition<$MorphPostTags> get definition =>
      _$MorphPostTagsDefinition;
}

class MorphPostTags {
  const MorphPostTags._();

  /// Starts building a query for [$MorphPostTags].
  ///
  /// {@macro ormed.query}
  static Query<$MorphPostTags> query([String? connection]) =>
      Model.query<$MorphPostTags>(connection: connection);

  static Future<$MorphPostTags?> find(Object id, {String? connection}) =>
      Model.find<$MorphPostTags>(id, connection: connection);

  static Future<$MorphPostTags> findOrFail(Object id, {String? connection}) =>
      Model.findOrFail<$MorphPostTags>(id, connection: connection);

  static Future<List<$MorphPostTags>> all({String? connection}) =>
      Model.all<$MorphPostTags>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<$MorphPostTags>(connection: connection);

  static Future<bool> anyExist({String? connection}) =>
      Model.anyExist<$MorphPostTags>(connection: connection);

  static Query<$MorphPostTags> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) => Model.where<$MorphPostTags>(
    column,
    operator,
    value,
    connection: connection,
  );

  static Query<$MorphPostTags> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<$MorphPostTags>(column, values, connection: connection);

  static Query<$MorphPostTags> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<$MorphPostTags>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<$MorphPostTags> limit(int count, {String? connection}) =>
      Model.limit<$MorphPostTags>(count, connection: connection);

  /// Creates a [Repository] for [$MorphPostTags].
  ///
  /// {@macro ormed.repository}
  static Repository<$MorphPostTags> repo([String? connection]) =>
      Model.repository<$MorphPostTags>(connection: connection);
}

class MorphPostTagsModelFactory {
  const MorphPostTagsModelFactory._();

  static ModelDefinition<$MorphPostTags> get definition =>
      _$MorphPostTagsDefinition;

  static ModelCodec<$MorphPostTags> get codec => definition.codec;

  static MorphPostTags fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    MorphPostTags model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model.toTracked(), registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<MorphPostTags> withConnection(
    QueryContext context,
  ) => ModelFactoryConnection<MorphPostTags>(
    definition: definition,
    context: context,
  );

  static ModelFactoryBuilder<MorphPostTags> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<MorphPostTags>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$MorphPostTagsCodec extends ModelCodec<$MorphPostTags> {
  const _$MorphPostTagsCodec();
  @override
  Map<String, Object?> encode(
    $MorphPostTags model,
    ValueCodecRegistry registry,
  ) {
    return <String, Object?>{
      'id': registry.encodeField(_$MorphPostTagsIdField, model.id),
    };
  }

  @override
  $MorphPostTags decode(
    Map<String, Object?> data,
    ValueCodecRegistry registry,
  ) {
    final int morphPostTagsIdValue =
        registry.decodeField<int>(_$MorphPostTagsIdField, data['id']) ??
        (throw StateError('Field id on MorphPostTags cannot be null.'));
    final model = $MorphPostTags(id: morphPostTagsIdValue);
    model._attachOrmRuntimeMetadata({'id': morphPostTagsIdValue});
    return model;
  }
}

/// Insert DTO for [MorphPostTags].
///
/// Auto-increment/DB-generated fields are omitted by default.
class MorphPostTagsInsertDto implements InsertDto<$MorphPostTags> {
  const MorphPostTagsInsertDto({this.id});
  final int? id;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{if (id != null) 'id': id};
  }

  static const _MorphPostTagsInsertDtoCopyWithSentinel _copyWithSentinel =
      _MorphPostTagsInsertDtoCopyWithSentinel();
  MorphPostTagsInsertDto copyWith({Object? id = _copyWithSentinel}) {
    return MorphPostTagsInsertDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
    );
  }
}

class _MorphPostTagsInsertDtoCopyWithSentinel {
  const _MorphPostTagsInsertDtoCopyWithSentinel();
}

/// Update DTO for [MorphPostTags].
///
/// All fields are optional; only provided entries are used in SET clauses.
class MorphPostTagsUpdateDto implements UpdateDto<$MorphPostTags> {
  const MorphPostTagsUpdateDto({this.id});
  final int? id;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{if (id != null) 'id': id};
  }

  static const _MorphPostTagsUpdateDtoCopyWithSentinel _copyWithSentinel =
      _MorphPostTagsUpdateDtoCopyWithSentinel();
  MorphPostTagsUpdateDto copyWith({Object? id = _copyWithSentinel}) {
    return MorphPostTagsUpdateDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
    );
  }
}

class _MorphPostTagsUpdateDtoCopyWithSentinel {
  const _MorphPostTagsUpdateDtoCopyWithSentinel();
}

/// Partial projection for [MorphPostTags].
///
/// All fields are nullable; intended for subset SELECTs.
class MorphPostTagsPartial implements PartialEntity<$MorphPostTags> {
  const MorphPostTagsPartial({this.id});

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory MorphPostTagsPartial.fromRow(Map<String, Object?> row) {
    return MorphPostTagsPartial(id: row['id'] as int?);
  }

  final int? id;

  @override
  $MorphPostTags toEntity() {
    // Basic required-field check: non-nullable fields must be present.
    final int? idValue = id;
    if (idValue == null) {
      throw StateError('Missing required field: id');
    }
    return $MorphPostTags(id: idValue);
  }

  @override
  Map<String, Object?> toMap() {
    return {if (id != null) 'id': id};
  }

  static const _MorphPostTagsPartialCopyWithSentinel _copyWithSentinel =
      _MorphPostTagsPartialCopyWithSentinel();
  MorphPostTagsPartial copyWith({Object? id = _copyWithSentinel}) {
    return MorphPostTagsPartial(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
    );
  }
}

class _MorphPostTagsPartialCopyWithSentinel {
  const _MorphPostTagsPartialCopyWithSentinel();
}

/// Generated tracked model class for [MorphPostTags].
///
/// This class extends the user-defined [MorphPostTags] model and adds
/// attribute tracking, change detection, and relationship management.
/// Instances of this class are returned by queries and repositories.
///
/// **Do not instantiate this class directly.** Use queries, repositories,
/// or model factories to create tracked model instances.
class $MorphPostTags extends MorphPostTags
    with ModelAttributes
    implements OrmEntity {
  /// Internal constructor for [$MorphPostTags].
  $MorphPostTags({required int id}) : super.new(id: id) {
    _attachOrmRuntimeMetadata({'id': id});
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $MorphPostTags.fromModel(MorphPostTags model) {
    return $MorphPostTags(id: model.id);
  }

  $MorphPostTags copyWith({int? id}) {
    return $MorphPostTags(id: id ?? this.id);
  }

  /// Tracked getter for [id].
  @override
  int get id => getAttribute<int>('id') ?? super.id;

  /// Tracked setter for [id].
  set id(int value) => setAttribute('id', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$MorphPostTagsDefinition);
  }

  @override
  List<MorphTag> get tags {
    if (relationLoaded('tags')) {
      return getRelationList<MorphTag>('tags');
    }
    return super.tags;
  }
}

extension MorphPostTagsRelationQueries on MorphPostTags {
  Query<MorphTag> tagsQuery() {
    throw UnimplementedError(
      "Polymorphic relation query generation not yet supported",
    );
  }
}

extension MorphPostTagsOrmExtension on MorphPostTags {
  /// The Type of the generated ORM-managed model class.
  /// Use this when you need to specify the tracked model type explicitly,
  /// for example in generic type parameters.
  static Type get trackedType => $MorphPostTags;

  /// Converts this immutable model to a tracked ORM-managed model.
  /// The tracked model supports attribute tracking, change detection,
  /// and persistence operations like save() and touch().
  $MorphPostTags toTracked() {
    return $MorphPostTags.fromModel(this);
  }
}

void registerMorphPostTagsEventHandlers(EventBus bus) {
  // No event handlers registered for MorphPostTags.
}

const FieldDefinition _$MorphTagIdField = FieldDefinition(
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

const RelationDefinition _$MorphTagPostsRelation = RelationDefinition(
  name: 'posts',
  kind: RelationKind.morphedByMany,
  targetModel: 'MorphPostTags',
  through: 'taggables',
  pivotForeignKey: 'tag_id',
  pivotRelatedKey: 'taggable_id',
  morphType: 'taggable_type',
  morphClass: 'Post',
);

Map<String, Object?> _encodeMorphTagUntracked(
  Object model,
  ValueCodecRegistry registry,
) {
  final m = model as MorphTag;
  return <String, Object?>{'id': registry.encodeField(_$MorphTagIdField, m.id)};
}

final ModelDefinition<$MorphTag> _$MorphTagDefinition = ModelDefinition(
  modelName: 'MorphTag',
  tableName: 'tags',
  fields: const [_$MorphTagIdField],
  relations: const [_$MorphTagPostsRelation],
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
  untrackedToMap: _encodeMorphTagUntracked,
  codec: _$MorphTagCodec(),
);

extension MorphTagOrmDefinition on MorphTag {
  static ModelDefinition<$MorphTag> get definition => _$MorphTagDefinition;
}

class MorphTags {
  const MorphTags._();

  /// Starts building a query for [$MorphTag].
  ///
  /// {@macro ormed.query}
  static Query<$MorphTag> query([String? connection]) =>
      Model.query<$MorphTag>(connection: connection);

  static Future<$MorphTag?> find(Object id, {String? connection}) =>
      Model.find<$MorphTag>(id, connection: connection);

  static Future<$MorphTag> findOrFail(Object id, {String? connection}) =>
      Model.findOrFail<$MorphTag>(id, connection: connection);

  static Future<List<$MorphTag>> all({String? connection}) =>
      Model.all<$MorphTag>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<$MorphTag>(connection: connection);

  static Future<bool> anyExist({String? connection}) =>
      Model.anyExist<$MorphTag>(connection: connection);

  static Query<$MorphTag> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) => Model.where<$MorphTag>(column, operator, value, connection: connection);

  static Query<$MorphTag> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<$MorphTag>(column, values, connection: connection);

  static Query<$MorphTag> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<$MorphTag>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<$MorphTag> limit(int count, {String? connection}) =>
      Model.limit<$MorphTag>(count, connection: connection);

  /// Creates a [Repository] for [$MorphTag].
  ///
  /// {@macro ormed.repository}
  static Repository<$MorphTag> repo([String? connection]) =>
      Model.repository<$MorphTag>(connection: connection);
}

class MorphTagModelFactory {
  const MorphTagModelFactory._();

  static ModelDefinition<$MorphTag> get definition => _$MorphTagDefinition;

  static ModelCodec<$MorphTag> get codec => definition.codec;

  static MorphTag fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    MorphTag model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model.toTracked(), registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<MorphTag> withConnection(
    QueryContext context,
  ) => ModelFactoryConnection<MorphTag>(
    definition: definition,
    context: context,
  );

  static ModelFactoryBuilder<MorphTag> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<MorphTag>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$MorphTagCodec extends ModelCodec<$MorphTag> {
  const _$MorphTagCodec();
  @override
  Map<String, Object?> encode($MorphTag model, ValueCodecRegistry registry) {
    return <String, Object?>{
      'id': registry.encodeField(_$MorphTagIdField, model.id),
    };
  }

  @override
  $MorphTag decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final int morphTagIdValue =
        registry.decodeField<int>(_$MorphTagIdField, data['id']) ??
        (throw StateError('Field id on MorphTag cannot be null.'));
    final model = $MorphTag(id: morphTagIdValue);
    model._attachOrmRuntimeMetadata({'id': morphTagIdValue});
    return model;
  }
}

/// Insert DTO for [MorphTag].
///
/// Auto-increment/DB-generated fields are omitted by default.
class MorphTagInsertDto implements InsertDto<$MorphTag> {
  const MorphTagInsertDto({this.id});
  final int? id;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{if (id != null) 'id': id};
  }

  static const _MorphTagInsertDtoCopyWithSentinel _copyWithSentinel =
      _MorphTagInsertDtoCopyWithSentinel();
  MorphTagInsertDto copyWith({Object? id = _copyWithSentinel}) {
    return MorphTagInsertDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
    );
  }
}

class _MorphTagInsertDtoCopyWithSentinel {
  const _MorphTagInsertDtoCopyWithSentinel();
}

/// Update DTO for [MorphTag].
///
/// All fields are optional; only provided entries are used in SET clauses.
class MorphTagUpdateDto implements UpdateDto<$MorphTag> {
  const MorphTagUpdateDto({this.id});
  final int? id;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{if (id != null) 'id': id};
  }

  static const _MorphTagUpdateDtoCopyWithSentinel _copyWithSentinel =
      _MorphTagUpdateDtoCopyWithSentinel();
  MorphTagUpdateDto copyWith({Object? id = _copyWithSentinel}) {
    return MorphTagUpdateDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
    );
  }
}

class _MorphTagUpdateDtoCopyWithSentinel {
  const _MorphTagUpdateDtoCopyWithSentinel();
}

/// Partial projection for [MorphTag].
///
/// All fields are nullable; intended for subset SELECTs.
class MorphTagPartial implements PartialEntity<$MorphTag> {
  const MorphTagPartial({this.id});

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory MorphTagPartial.fromRow(Map<String, Object?> row) {
    return MorphTagPartial(id: row['id'] as int?);
  }

  final int? id;

  @override
  $MorphTag toEntity() {
    // Basic required-field check: non-nullable fields must be present.
    final int? idValue = id;
    if (idValue == null) {
      throw StateError('Missing required field: id');
    }
    return $MorphTag(id: idValue);
  }

  @override
  Map<String, Object?> toMap() {
    return {if (id != null) 'id': id};
  }

  static const _MorphTagPartialCopyWithSentinel _copyWithSentinel =
      _MorphTagPartialCopyWithSentinel();
  MorphTagPartial copyWith({Object? id = _copyWithSentinel}) {
    return MorphTagPartial(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
    );
  }
}

class _MorphTagPartialCopyWithSentinel {
  const _MorphTagPartialCopyWithSentinel();
}

/// Generated tracked model class for [MorphTag].
///
/// This class extends the user-defined [MorphTag] model and adds
/// attribute tracking, change detection, and relationship management.
/// Instances of this class are returned by queries and repositories.
///
/// **Do not instantiate this class directly.** Use queries, repositories,
/// or model factories to create tracked model instances.
class $MorphTag extends MorphTag with ModelAttributes implements OrmEntity {
  /// Internal constructor for [$MorphTag].
  $MorphTag({required int id}) : super.new(id: id) {
    _attachOrmRuntimeMetadata({'id': id});
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $MorphTag.fromModel(MorphTag model) {
    return $MorphTag(id: model.id);
  }

  $MorphTag copyWith({int? id}) {
    return $MorphTag(id: id ?? this.id);
  }

  /// Tracked getter for [id].
  @override
  int get id => getAttribute<int>('id') ?? super.id;

  /// Tracked setter for [id].
  set id(int value) => setAttribute('id', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$MorphTagDefinition);
  }

  @override
  List<MorphPostTags> get posts {
    if (relationLoaded('posts')) {
      return getRelationList<MorphPostTags>('posts');
    }
    return super.posts;
  }
}

extension MorphTagRelationQueries on MorphTag {
  Query<MorphPostTags> postsQuery() {
    throw UnimplementedError(
      "Polymorphic relation query generation not yet supported",
    );
  }
}

extension MorphTagOrmExtension on MorphTag {
  /// The Type of the generated ORM-managed model class.
  /// Use this when you need to specify the tracked model type explicitly,
  /// for example in generic type parameters.
  static Type get trackedType => $MorphTag;

  /// Converts this immutable model to a tracked ORM-managed model.
  /// The tracked model supports attribute tracking, change detection,
  /// and persistence operations like save() and touch().
  $MorphTag toTracked() {
    return $MorphTag.fromModel(this);
  }
}

void registerMorphTagEventHandlers(EventBus bus) {
  // No event handlers registered for MorphTag.
}
