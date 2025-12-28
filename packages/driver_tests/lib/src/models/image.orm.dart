// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'image.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$ImageIdField = FieldDefinition(
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

const FieldDefinition _$ImageLabelField = FieldDefinition(
  name: 'label',
  columnName: 'label',
  dartType: 'String',
  resolvedType: 'String',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const RelationDefinition _$ImagePrimaryPhotoRelation = RelationDefinition(
  name: 'primaryPhoto',
  kind: RelationKind.morphOne,
  targetModel: 'Photo',
  foreignKey: 'imageable_id',
  morphType: 'imageable_type',
  morphClass: 'Image',
);

Map<String, Object?> _encodeImageUntracked(
  Object model,
  ValueCodecRegistry registry,
) {
  final m = model as Image;
  return <String, Object?>{
    'id': registry.encodeField(_$ImageIdField, m.id),
    'label': registry.encodeField(_$ImageLabelField, m.label),
  };
}

final ModelDefinition<$Image> _$ImageDefinition = ModelDefinition(
  modelName: 'Image',
  tableName: 'images',
  fields: const [_$ImageIdField, _$ImageLabelField],
  relations: const [_$ImagePrimaryPhotoRelation],
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
  untrackedToMap: _encodeImageUntracked,
  codec: _$ImageCodec(),
);

// ignore: unused_element
final imageModelDefinitionRegistration = ModelFactoryRegistry.register<$Image>(
  _$ImageDefinition,
);

extension ImageOrmDefinition on Image {
  static ModelDefinition<$Image> get definition => _$ImageDefinition;
}

class Images {
  const Images._();

  /// Starts building a query for [$Image].
  ///
  /// {@macro ormed.query}
  static Query<$Image> query([String? connection]) =>
      Model.query<$Image>(connection: connection);

  static Future<$Image?> find(Object id, {String? connection}) =>
      Model.find<$Image>(id, connection: connection);

  static Future<$Image> findOrFail(Object id, {String? connection}) =>
      Model.findOrFail<$Image>(id, connection: connection);

  static Future<List<$Image>> all({String? connection}) =>
      Model.all<$Image>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<$Image>(connection: connection);

  static Future<bool> anyExist({String? connection}) =>
      Model.anyExist<$Image>(connection: connection);

  static Query<$Image> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) => Model.where<$Image>(column, operator, value, connection: connection);

  static Query<$Image> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<$Image>(column, values, connection: connection);

  static Query<$Image> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<$Image>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<$Image> limit(int count, {String? connection}) =>
      Model.limit<$Image>(count, connection: connection);

  /// Creates a [Repository] for [$Image].
  ///
  /// {@macro ormed.repository}
  static Repository<$Image> repo([String? connection]) =>
      Model.repository<$Image>(connection: connection);

  /// Builds a tracked model from a column/value map.
  static $Image fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$ImageDefinition.fromMap(data, registry: registry);

  /// Converts a tracked model to a column/value map.
  static Map<String, Object?> toMap(
    $Image model, {
    ValueCodecRegistry? registry,
  }) => _$ImageDefinition.toMap(model, registry: registry);
}

class ImageModelFactory {
  const ImageModelFactory._();

  static ModelDefinition<$Image> get definition => _$ImageDefinition;

  static ModelCodec<$Image> get codec => definition.codec;

  static Image fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    Image model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model.toTracked(), registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<Image> withConnection(QueryContext context) =>
      ModelFactoryConnection<Image>(definition: definition, context: context);

  static ModelFactoryBuilder<Image> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<Image>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$ImageCodec extends ModelCodec<$Image> {
  const _$ImageCodec();
  @override
  Map<String, Object?> encode($Image model, ValueCodecRegistry registry) {
    return <String, Object?>{
      'id': registry.encodeField(_$ImageIdField, model.id),
      'label': registry.encodeField(_$ImageLabelField, model.label),
    };
  }

  @override
  $Image decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final int imageIdValue =
        registry.decodeField<int>(_$ImageIdField, data['id']) ?? 0;
    final String imageLabelValue =
        registry.decodeField<String>(_$ImageLabelField, data['label']) ??
        (throw StateError('Field label on Image cannot be null.'));
    final model = $Image(id: imageIdValue, label: imageLabelValue);
    model._attachOrmRuntimeMetadata({
      'id': imageIdValue,
      'label': imageLabelValue,
    });
    return model;
  }
}

/// Insert DTO for [Image].
///
/// Auto-increment/DB-generated fields are omitted by default.
class ImageInsertDto implements InsertDto<$Image> {
  const ImageInsertDto({this.label});
  final String? label;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{if (label != null) 'label': label};
  }

  static const _ImageInsertDtoCopyWithSentinel _copyWithSentinel =
      _ImageInsertDtoCopyWithSentinel();
  ImageInsertDto copyWith({Object? label = _copyWithSentinel}) {
    return ImageInsertDto(
      label: identical(label, _copyWithSentinel)
          ? this.label
          : label as String?,
    );
  }
}

class _ImageInsertDtoCopyWithSentinel {
  const _ImageInsertDtoCopyWithSentinel();
}

/// Update DTO for [Image].
///
/// All fields are optional; only provided entries are used in SET clauses.
class ImageUpdateDto implements UpdateDto<$Image> {
  const ImageUpdateDto({this.id, this.label});
  final int? id;
  final String? label;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (label != null) 'label': label,
    };
  }

  static const _ImageUpdateDtoCopyWithSentinel _copyWithSentinel =
      _ImageUpdateDtoCopyWithSentinel();
  ImageUpdateDto copyWith({
    Object? id = _copyWithSentinel,
    Object? label = _copyWithSentinel,
  }) {
    return ImageUpdateDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      label: identical(label, _copyWithSentinel)
          ? this.label
          : label as String?,
    );
  }
}

class _ImageUpdateDtoCopyWithSentinel {
  const _ImageUpdateDtoCopyWithSentinel();
}

/// Partial projection for [Image].
///
/// All fields are nullable; intended for subset SELECTs.
class ImagePartial implements PartialEntity<$Image> {
  const ImagePartial({this.id, this.label});

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory ImagePartial.fromRow(Map<String, Object?> row) {
    return ImagePartial(id: row['id'] as int?, label: row['label'] as String?);
  }

  final int? id;
  final String? label;

  @override
  $Image toEntity() {
    // Basic required-field check: non-nullable fields must be present.
    final int? idValue = id;
    if (idValue == null) {
      throw StateError('Missing required field: id');
    }
    final String? labelValue = label;
    if (labelValue == null) {
      throw StateError('Missing required field: label');
    }
    return $Image(id: idValue, label: labelValue);
  }

  @override
  Map<String, Object?> toMap() {
    return {if (id != null) 'id': id, if (label != null) 'label': label};
  }

  static const _ImagePartialCopyWithSentinel _copyWithSentinel =
      _ImagePartialCopyWithSentinel();
  ImagePartial copyWith({
    Object? id = _copyWithSentinel,
    Object? label = _copyWithSentinel,
  }) {
    return ImagePartial(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      label: identical(label, _copyWithSentinel)
          ? this.label
          : label as String?,
    );
  }
}

class _ImagePartialCopyWithSentinel {
  const _ImagePartialCopyWithSentinel();
}

/// Generated tracked model class for [Image].
///
/// This class extends the user-defined [Image] model and adds
/// attribute tracking, change detection, and relationship management.
/// Instances of this class are returned by queries and repositories.
///
/// **Do not instantiate this class directly.** Use queries, repositories,
/// or model factories to create tracked model instances.
class $Image extends Image with ModelAttributes implements OrmEntity {
  /// Internal constructor for [$Image].
  $Image({int id = 0, required String label})
    : super.new(id: id, label: label) {
    _attachOrmRuntimeMetadata({'id': id, 'label': label});
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $Image.fromModel(Image model) {
    return $Image(id: model.id, label: model.label);
  }

  $Image copyWith({int? id, String? label}) {
    return $Image(id: id ?? this.id, label: label ?? this.label);
  }

  /// Builds a tracked model from a column/value map.
  static $Image fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$ImageDefinition.fromMap(data, registry: registry);

  /// Converts this tracked model to a column/value map.
  Map<String, Object?> toMap({ValueCodecRegistry? registry}) =>
      _$ImageDefinition.toMap(this, registry: registry);

  /// Tracked getter for [id].
  @override
  int get id => getAttribute<int>('id') ?? super.id;

  /// Tracked setter for [id].
  set id(int value) => setAttribute('id', value);

  /// Tracked getter for [label].
  @override
  String get label => getAttribute<String>('label') ?? super.label;

  /// Tracked setter for [label].
  set label(String value) => setAttribute('label', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$ImageDefinition);
  }

  @override
  Photo? get primaryPhoto {
    if (relationLoaded('primaryPhoto')) {
      return getRelation<Photo>('primaryPhoto');
    }
    return super.primaryPhoto;
  }
}

extension ImageRelationQueries on Image {
  Query<Photo> primaryPhotoQuery() {
    throw UnimplementedError(
      "Polymorphic relation query generation not yet supported",
    );
  }
}

class _ImageCopyWithSentinel {
  const _ImageCopyWithSentinel();
}

extension ImageOrmExtension on Image {
  static const _ImageCopyWithSentinel _copyWithSentinel =
      _ImageCopyWithSentinel();
  Image copyWith({
    Object? id = _copyWithSentinel,
    Object? label = _copyWithSentinel,
  }) {
    return Image.new(
      id: identical(id, _copyWithSentinel) ? this.id : id as int,
      label: identical(label, _copyWithSentinel) ? this.label : label as String,
    );
  }

  /// Converts this model to a column/value map.
  Map<String, Object?> toMap({ValueCodecRegistry? registry}) =>
      _$ImageDefinition.toMap(this, registry: registry);

  /// Builds a model from a column/value map.
  static Image fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$ImageDefinition.fromMap(data, registry: registry);

  /// The Type of the generated ORM-managed model class.
  /// Use this when you need to specify the tracked model type explicitly,
  /// for example in generic type parameters.
  static Type get trackedType => $Image;

  /// Converts this immutable model to a tracked ORM-managed model.
  /// The tracked model supports attribute tracking, change detection,
  /// and persistence operations like save() and touch().
  $Image toTracked() {
    return $Image.fromModel(this);
  }
}

extension ImagePredicateFields on PredicateBuilder<Image> {
  PredicateField<Image, int> get id => PredicateField<Image, int>(this, 'id');
  PredicateField<Image, String> get label =>
      PredicateField<Image, String>(this, 'label');
}

extension ImageTypedRelations on Query<Image> {
  Query<Image> withPrimaryPhoto([PredicateCallback<Photo>? constraint]) =>
      withRelationTyped('primaryPhoto', constraint);
  Query<Image> whereHasPrimaryPhoto([PredicateCallback<Photo>? constraint]) =>
      whereHasTyped('primaryPhoto', constraint);
  Query<Image> orWhereHasPrimaryPhoto([PredicateCallback<Photo>? constraint]) =>
      orWhereHasTyped('primaryPhoto', constraint);
}

void registerImageEventHandlers(EventBus bus) {
  // No event handlers registered for Image.
}
