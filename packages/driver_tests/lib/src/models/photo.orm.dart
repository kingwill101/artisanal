// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'photo.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$PhotoIdField = FieldDefinition(
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

const FieldDefinition _$PhotoImageableIdField = FieldDefinition(
  name: 'imageableId',
  columnName: 'imageable_id',
  dartType: 'int',
  resolvedType: 'int',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$PhotoImageableTypeField = FieldDefinition(
  name: 'imageableType',
  columnName: 'imageable_type',
  dartType: 'String',
  resolvedType: 'String',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$PhotoPathField = FieldDefinition(
  name: 'path',
  columnName: 'path',
  dartType: 'String',
  resolvedType: 'String',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const RelationDefinition _$PhotoImageableRelation = RelationDefinition(
  name: 'imageable',
  kind: RelationKind.morphTo,
  targetModel: 'OrmEntity',
  foreignKey: 'imageable_id',
  morphType: 'imageable_type',
);

Map<String, Object?> _encodePhotoUntracked(
  Object model,
  ValueCodecRegistry registry,
) {
  final m = model as Photo;
  return <String, Object?>{
    'id': registry.encodeField(_$PhotoIdField, m.id),
    'imageable_id': registry.encodeField(
      _$PhotoImageableIdField,
      m.imageableId,
    ),
    'imageable_type': registry.encodeField(
      _$PhotoImageableTypeField,
      m.imageableType,
    ),
    'path': registry.encodeField(_$PhotoPathField, m.path),
  };
}

final ModelDefinition<$Photo> _$PhotoDefinition = ModelDefinition(
  modelName: 'Photo',
  tableName: 'photos',
  fields: const [
    _$PhotoIdField,
    _$PhotoImageableIdField,
    _$PhotoImageableTypeField,
    _$PhotoPathField,
  ],
  relations: const [_$PhotoImageableRelation],
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
  untrackedToMap: _encodePhotoUntracked,
  codec: _$PhotoCodec(),
);

// ignore: unused_element
final photoModelDefinitionRegistration = ModelFactoryRegistry.register<$Photo>(
  _$PhotoDefinition,
);

extension PhotoOrmDefinition on Photo {
  static ModelDefinition<$Photo> get definition => _$PhotoDefinition;
}

class Photos {
  const Photos._();

  /// Starts building a query for [$Photo].
  ///
  /// {@macro ormed.query}
  static Query<$Photo> query([String? connection]) =>
      Model.query<$Photo>(connection: connection);

  static Future<$Photo?> find(Object id, {String? connection}) =>
      Model.find<$Photo>(id, connection: connection);

  static Future<$Photo> findOrFail(Object id, {String? connection}) =>
      Model.findOrFail<$Photo>(id, connection: connection);

  static Future<List<$Photo>> all({String? connection}) =>
      Model.all<$Photo>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<$Photo>(connection: connection);

  static Future<bool> anyExist({String? connection}) =>
      Model.anyExist<$Photo>(connection: connection);

  static Query<$Photo> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) => Model.where<$Photo>(column, operator, value, connection: connection);

  static Query<$Photo> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<$Photo>(column, values, connection: connection);

  static Query<$Photo> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<$Photo>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<$Photo> limit(int count, {String? connection}) =>
      Model.limit<$Photo>(count, connection: connection);

  /// Creates a [Repository] for [$Photo].
  ///
  /// {@macro ormed.repository}
  static Repository<$Photo> repo([String? connection]) =>
      Model.repository<$Photo>(connection: connection);

  /// Builds a tracked model from a column/value map.
  static $Photo fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$PhotoDefinition.fromMap(data, registry: registry);

  /// Converts a tracked model to a column/value map.
  static Map<String, Object?> toMap(
    $Photo model, {
    ValueCodecRegistry? registry,
  }) => _$PhotoDefinition.toMap(model, registry: registry);
}

class PhotoModelFactory {
  const PhotoModelFactory._();

  static ModelDefinition<$Photo> get definition => _$PhotoDefinition;

  static ModelCodec<$Photo> get codec => definition.codec;

  static Photo fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    Photo model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model.toTracked(), registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<Photo> withConnection(QueryContext context) =>
      ModelFactoryConnection<Photo>(definition: definition, context: context);

  static ModelFactoryBuilder<Photo> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<Photo>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$PhotoCodec extends ModelCodec<$Photo> {
  const _$PhotoCodec();
  @override
  Map<String, Object?> encode($Photo model, ValueCodecRegistry registry) {
    return <String, Object?>{
      'id': registry.encodeField(_$PhotoIdField, model.id),
      'imageable_id': registry.encodeField(
        _$PhotoImageableIdField,
        model.imageableId,
      ),
      'imageable_type': registry.encodeField(
        _$PhotoImageableTypeField,
        model.imageableType,
      ),
      'path': registry.encodeField(_$PhotoPathField, model.path),
    };
  }

  @override
  $Photo decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final int photoIdValue =
        registry.decodeField<int>(_$PhotoIdField, data['id']) ?? 0;
    final int photoImageableIdValue =
        registry.decodeField<int>(
          _$PhotoImageableIdField,
          data['imageable_id'],
        ) ??
        (throw StateError('Field imageableId on Photo cannot be null.'));
    final String photoImageableTypeValue =
        registry.decodeField<String>(
          _$PhotoImageableTypeField,
          data['imageable_type'],
        ) ??
        (throw StateError('Field imageableType on Photo cannot be null.'));
    final String photoPathValue =
        registry.decodeField<String>(_$PhotoPathField, data['path']) ??
        (throw StateError('Field path on Photo cannot be null.'));
    final model = $Photo(
      id: photoIdValue,
      imageableId: photoImageableIdValue,
      imageableType: photoImageableTypeValue,
      path: photoPathValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': photoIdValue,
      'imageable_id': photoImageableIdValue,
      'imageable_type': photoImageableTypeValue,
      'path': photoPathValue,
    });
    return model;
  }
}

/// Insert DTO for [Photo].
///
/// Auto-increment/DB-generated fields are omitted by default.
class PhotoInsertDto implements InsertDto<$Photo> {
  const PhotoInsertDto({this.imageableId, this.imageableType, this.path});
  final int? imageableId;
  final String? imageableType;
  final String? path;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (imageableId != null) 'imageable_id': imageableId,
      if (imageableType != null) 'imageable_type': imageableType,
      if (path != null) 'path': path,
    };
  }

  static const _PhotoInsertDtoCopyWithSentinel _copyWithSentinel =
      _PhotoInsertDtoCopyWithSentinel();
  PhotoInsertDto copyWith({
    Object? imageableId = _copyWithSentinel,
    Object? imageableType = _copyWithSentinel,
    Object? path = _copyWithSentinel,
  }) {
    return PhotoInsertDto(
      imageableId: identical(imageableId, _copyWithSentinel)
          ? this.imageableId
          : imageableId as int?,
      imageableType: identical(imageableType, _copyWithSentinel)
          ? this.imageableType
          : imageableType as String?,
      path: identical(path, _copyWithSentinel) ? this.path : path as String?,
    );
  }
}

class _PhotoInsertDtoCopyWithSentinel {
  const _PhotoInsertDtoCopyWithSentinel();
}

/// Update DTO for [Photo].
///
/// All fields are optional; only provided entries are used in SET clauses.
class PhotoUpdateDto implements UpdateDto<$Photo> {
  const PhotoUpdateDto({
    this.id,
    this.imageableId,
    this.imageableType,
    this.path,
  });
  final int? id;
  final int? imageableId;
  final String? imageableType;
  final String? path;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (imageableId != null) 'imageable_id': imageableId,
      if (imageableType != null) 'imageable_type': imageableType,
      if (path != null) 'path': path,
    };
  }

  static const _PhotoUpdateDtoCopyWithSentinel _copyWithSentinel =
      _PhotoUpdateDtoCopyWithSentinel();
  PhotoUpdateDto copyWith({
    Object? id = _copyWithSentinel,
    Object? imageableId = _copyWithSentinel,
    Object? imageableType = _copyWithSentinel,
    Object? path = _copyWithSentinel,
  }) {
    return PhotoUpdateDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      imageableId: identical(imageableId, _copyWithSentinel)
          ? this.imageableId
          : imageableId as int?,
      imageableType: identical(imageableType, _copyWithSentinel)
          ? this.imageableType
          : imageableType as String?,
      path: identical(path, _copyWithSentinel) ? this.path : path as String?,
    );
  }
}

class _PhotoUpdateDtoCopyWithSentinel {
  const _PhotoUpdateDtoCopyWithSentinel();
}

/// Partial projection for [Photo].
///
/// All fields are nullable; intended for subset SELECTs.
class PhotoPartial implements PartialEntity<$Photo> {
  const PhotoPartial({
    this.id,
    this.imageableId,
    this.imageableType,
    this.path,
  });

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory PhotoPartial.fromRow(Map<String, Object?> row) {
    return PhotoPartial(
      id: row['id'] as int?,
      imageableId: row['imageable_id'] as int?,
      imageableType: row['imageable_type'] as String?,
      path: row['path'] as String?,
    );
  }

  final int? id;
  final int? imageableId;
  final String? imageableType;
  final String? path;

  @override
  $Photo toEntity() {
    // Basic required-field check: non-nullable fields must be present.
    final int? idValue = id;
    if (idValue == null) {
      throw StateError('Missing required field: id');
    }
    final int? imageableIdValue = imageableId;
    if (imageableIdValue == null) {
      throw StateError('Missing required field: imageableId');
    }
    final String? imageableTypeValue = imageableType;
    if (imageableTypeValue == null) {
      throw StateError('Missing required field: imageableType');
    }
    final String? pathValue = path;
    if (pathValue == null) {
      throw StateError('Missing required field: path');
    }
    return $Photo(
      id: idValue,
      imageableId: imageableIdValue,
      imageableType: imageableTypeValue,
      path: pathValue,
    );
  }

  @override
  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      if (imageableId != null) 'imageable_id': imageableId,
      if (imageableType != null) 'imageable_type': imageableType,
      if (path != null) 'path': path,
    };
  }

  static const _PhotoPartialCopyWithSentinel _copyWithSentinel =
      _PhotoPartialCopyWithSentinel();
  PhotoPartial copyWith({
    Object? id = _copyWithSentinel,
    Object? imageableId = _copyWithSentinel,
    Object? imageableType = _copyWithSentinel,
    Object? path = _copyWithSentinel,
  }) {
    return PhotoPartial(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      imageableId: identical(imageableId, _copyWithSentinel)
          ? this.imageableId
          : imageableId as int?,
      imageableType: identical(imageableType, _copyWithSentinel)
          ? this.imageableType
          : imageableType as String?,
      path: identical(path, _copyWithSentinel) ? this.path : path as String?,
    );
  }
}

class _PhotoPartialCopyWithSentinel {
  const _PhotoPartialCopyWithSentinel();
}

/// Generated tracked model class for [Photo].
///
/// This class extends the user-defined [Photo] model and adds
/// attribute tracking, change detection, and relationship management.
/// Instances of this class are returned by queries and repositories.
///
/// **Do not instantiate this class directly.** Use queries, repositories,
/// or model factories to create tracked model instances.
class $Photo extends Photo with ModelAttributes implements OrmEntity {
  /// Internal constructor for [$Photo].
  $Photo({
    int id = 0,
    required int imageableId,
    required String imageableType,
    required String path,
  }) : super(
         id: id,
         imageableId: imageableId,
         imageableType: imageableType,
         path: path,
       ) {
    _attachOrmRuntimeMetadata({
      'id': id,
      'imageable_id': imageableId,
      'imageable_type': imageableType,
      'path': path,
    });
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $Photo.fromModel(Photo model) {
    return $Photo(
      id: model.id,
      imageableId: model.imageableId,
      imageableType: model.imageableType,
      path: model.path,
    );
  }

  $Photo copyWith({
    int? id,
    int? imageableId,
    String? imageableType,
    String? path,
  }) {
    return $Photo(
      id: id ?? this.id,
      imageableId: imageableId ?? this.imageableId,
      imageableType: imageableType ?? this.imageableType,
      path: path ?? this.path,
    );
  }

  /// Builds a tracked model from a column/value map.
  static $Photo fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$PhotoDefinition.fromMap(data, registry: registry);

  /// Converts this tracked model to a column/value map.
  Map<String, Object?> toMap({ValueCodecRegistry? registry}) =>
      _$PhotoDefinition.toMap(this, registry: registry);

  /// Tracked getter for [id].
  @override
  int get id => getAttribute<int>('id') ?? super.id;

  /// Tracked setter for [id].
  set id(int value) => setAttribute('id', value);

  /// Tracked getter for [imageableId].
  @override
  int get imageableId => getAttribute<int>('imageable_id') ?? super.imageableId;

  /// Tracked setter for [imageableId].
  set imageableId(int value) => setAttribute('imageable_id', value);

  /// Tracked getter for [imageableType].
  @override
  String get imageableType =>
      getAttribute<String>('imageable_type') ?? super.imageableType;

  /// Tracked setter for [imageableType].
  set imageableType(String value) => setAttribute('imageable_type', value);

  /// Tracked getter for [path].
  @override
  String get path => getAttribute<String>('path') ?? super.path;

  /// Tracked setter for [path].
  set path(String value) => setAttribute('path', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$PhotoDefinition);
  }

  @override
  OrmEntity? get imageable {
    if (relationLoaded('imageable')) {
      return getRelation<OrmEntity>('imageable');
    }
    return super.imageable;
  }
}

extension PhotoRelationQueries on Photo {
  Query<OrmEntity> imageableQuery() {
    throw UnimplementedError(
      "Polymorphic relation query generation not yet supported",
    );
  }
}

class _PhotoCopyWithSentinel {
  const _PhotoCopyWithSentinel();
}

extension PhotoOrmExtension on Photo {
  static const _PhotoCopyWithSentinel _copyWithSentinel =
      _PhotoCopyWithSentinel();
  Photo copyWith({
    Object? id = _copyWithSentinel,
    Object? imageableId = _copyWithSentinel,
    Object? imageableType = _copyWithSentinel,
    Object? path = _copyWithSentinel,
  }) {
    return Photo(
      id: identical(id, _copyWithSentinel) ? this.id : id as int,
      imageableId: identical(imageableId, _copyWithSentinel)
          ? this.imageableId
          : imageableId as int,
      imageableType: identical(imageableType, _copyWithSentinel)
          ? this.imageableType
          : imageableType as String,
      path: identical(path, _copyWithSentinel) ? this.path : path as String,
    );
  }

  /// Converts this model to a column/value map.
  Map<String, Object?> toMap({ValueCodecRegistry? registry}) =>
      _$PhotoDefinition.toMap(this, registry: registry);

  /// Builds a model from a column/value map.
  static Photo fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$PhotoDefinition.fromMap(data, registry: registry);

  /// The Type of the generated ORM-managed model class.
  /// Use this when you need to specify the tracked model type explicitly,
  /// for example in generic type parameters.
  static Type get trackedType => $Photo;

  /// Converts this immutable model to a tracked ORM-managed model.
  /// The tracked model supports attribute tracking, change detection,
  /// and persistence operations like save() and touch().
  $Photo toTracked() {
    return $Photo.fromModel(this);
  }
}

extension PhotoPredicateFields on PredicateBuilder<Photo> {
  PredicateField<Photo, int> get id => PredicateField<Photo, int>(this, 'id');
  PredicateField<Photo, int> get imageableId =>
      PredicateField<Photo, int>(this, 'imageableId');
  PredicateField<Photo, String> get imageableType =>
      PredicateField<Photo, String>(this, 'imageableType');
  PredicateField<Photo, String> get path =>
      PredicateField<Photo, String>(this, 'path');
}

extension PhotoTypedRelations on Query<Photo> {
  Query<Photo> withImageable([PredicateCallback<OrmEntity>? constraint]) =>
      withRelationTyped('imageable', constraint);
  Query<Photo> whereHasImageable([PredicateCallback<OrmEntity>? constraint]) =>
      whereHasTyped('imageable', constraint);
  Query<Photo> orWhereHasImageable([
    PredicateCallback<OrmEntity>? constraint,
  ]) => orWhereHasTyped('imageable', constraint);
}

void registerPhotoEventHandlers(EventBus bus) {
  // No event handlers registered for Photo.
}
