// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'genre.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$GenreIdField = FieldDefinition(
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

const FieldDefinition _$GenreNameField = FieldDefinition(
  name: 'name',
  columnName: 'name',
  dartType: 'String',
  resolvedType: 'String',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$GenreDescriptionField = FieldDefinition(
  name: 'description',
  columnName: 'description',
  dartType: 'String',
  resolvedType: 'String?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$GenreCreatedAtField = FieldDefinition(
  name: 'createdAt',
  columnName: 'created_at',
  dartType: 'DateTime',
  resolvedType: 'DateTime?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$GenreUpdatedAtField = FieldDefinition(
  name: 'updatedAt',
  columnName: 'updated_at',
  dartType: 'DateTime',
  resolvedType: 'DateTime?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

Map<String, Object?> _encodeGenreUntracked(
  Object model,
  ValueCodecRegistry registry,
) {
  final m = model as Genre;
  return <String, Object?>{
    'id': registry.encodeField(_$GenreIdField, m.id),
    'name': registry.encodeField(_$GenreNameField, m.name),
    'description': registry.encodeField(_$GenreDescriptionField, m.description),
    'created_at': registry.encodeField(_$GenreCreatedAtField, m.createdAt),
    'updated_at': registry.encodeField(_$GenreUpdatedAtField, m.updatedAt),
  };
}

final ModelDefinition<$Genre> _$GenreDefinition = ModelDefinition(
  modelName: 'Genre',
  tableName: 'genres',
  fields: const [
    _$GenreIdField,
    _$GenreNameField,
    _$GenreDescriptionField,
    _$GenreCreatedAtField,
    _$GenreUpdatedAtField,
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
  untrackedToMap: _encodeGenreUntracked,
  codec: _$GenreCodec(),
);

extension GenreOrmDefinition on Genre {
  static ModelDefinition<$Genre> get definition => _$GenreDefinition;
}

class Genres {
  const Genres._();

  /// Starts building a query for [$Genre].
  ///
  /// {@macro ormed.query}
  static Query<$Genre> query([String? connection]) =>
      Model.query<$Genre>(connection: connection);

  static Future<$Genre?> find(Object id, {String? connection}) =>
      Model.find<$Genre>(id, connection: connection);

  static Future<$Genre> findOrFail(Object id, {String? connection}) =>
      Model.findOrFail<$Genre>(id, connection: connection);

  static Future<List<$Genre>> all({String? connection}) =>
      Model.all<$Genre>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<$Genre>(connection: connection);

  static Future<bool> anyExist({String? connection}) =>
      Model.anyExist<$Genre>(connection: connection);

  static Query<$Genre> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) => Model.where<$Genre>(column, operator, value, connection: connection);

  static Query<$Genre> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<$Genre>(column, values, connection: connection);

  static Query<$Genre> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<$Genre>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<$Genre> limit(int count, {String? connection}) =>
      Model.limit<$Genre>(count, connection: connection);

  /// Creates a [Repository] for [$Genre].
  ///
  /// {@macro ormed.repository}
  static Repository<$Genre> repo([String? connection]) =>
      Model.repository<$Genre>(connection: connection);
}

class GenreModelFactory {
  const GenreModelFactory._();

  static ModelDefinition<$Genre> get definition => _$GenreDefinition;

  static ModelCodec<$Genre> get codec => definition.codec;

  static Genre fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    Genre model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model.toTracked(), registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<Genre> withConnection(QueryContext context) =>
      ModelFactoryConnection<Genre>(definition: definition, context: context);

  static ModelFactoryBuilder<Genre> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<Genre>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$GenreCodec extends ModelCodec<$Genre> {
  const _$GenreCodec();
  @override
  Map<String, Object?> encode($Genre model, ValueCodecRegistry registry) {
    return <String, Object?>{
      'id': registry.encodeField(_$GenreIdField, model.id),
      'name': registry.encodeField(_$GenreNameField, model.name),
      'description': registry.encodeField(
        _$GenreDescriptionField,
        model.description,
      ),
      'created_at': registry.encodeField(
        _$GenreCreatedAtField,
        model.createdAt,
      ),
      'updated_at': registry.encodeField(
        _$GenreUpdatedAtField,
        model.updatedAt,
      ),
    };
  }

  @override
  $Genre decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final int genreIdValue =
        registry.decodeField<int>(_$GenreIdField, data['id']) ?? 0;
    final String genreNameValue =
        registry.decodeField<String>(_$GenreNameField, data['name']) ??
        (throw StateError('Field name on Genre cannot be null.'));
    final String? genreDescriptionValue = registry.decodeField<String?>(
      _$GenreDescriptionField,
      data['description'],
    );
    final DateTime? genreCreatedAtValue = registry.decodeField<DateTime?>(
      _$GenreCreatedAtField,
      data['created_at'],
    );
    final DateTime? genreUpdatedAtValue = registry.decodeField<DateTime?>(
      _$GenreUpdatedAtField,
      data['updated_at'],
    );
    final model = $Genre(
      id: genreIdValue,
      name: genreNameValue,
      description: genreDescriptionValue,
      createdAt: genreCreatedAtValue,
      updatedAt: genreUpdatedAtValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': genreIdValue,
      'name': genreNameValue,
      'description': genreDescriptionValue,
      'created_at': genreCreatedAtValue,
      'updated_at': genreUpdatedAtValue,
    });
    return model;
  }
}

/// Insert DTO for [Genre].
///
/// Auto-increment/DB-generated fields are omitted by default.
class GenreInsertDto implements InsertDto<$Genre> {
  const GenreInsertDto({
    this.name,
    this.description,
    this.createdAt,
    this.updatedAt,
  });
  final String? name;
  final String? description;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    };
  }

  static const _GenreInsertDtoCopyWithSentinel _copyWithSentinel =
      _GenreInsertDtoCopyWithSentinel();
  GenreInsertDto copyWith({
    Object? name = _copyWithSentinel,
    Object? description = _copyWithSentinel,
    Object? createdAt = _copyWithSentinel,
    Object? updatedAt = _copyWithSentinel,
  }) {
    return GenreInsertDto(
      name: identical(name, _copyWithSentinel) ? this.name : name as String?,
      description: identical(description, _copyWithSentinel)
          ? this.description
          : description as String?,
      createdAt: identical(createdAt, _copyWithSentinel)
          ? this.createdAt
          : createdAt as DateTime?,
      updatedAt: identical(updatedAt, _copyWithSentinel)
          ? this.updatedAt
          : updatedAt as DateTime?,
    );
  }
}

class _GenreInsertDtoCopyWithSentinel {
  const _GenreInsertDtoCopyWithSentinel();
}

/// Update DTO for [Genre].
///
/// All fields are optional; only provided entries are used in SET clauses.
class GenreUpdateDto implements UpdateDto<$Genre> {
  const GenreUpdateDto({
    this.id,
    this.name,
    this.description,
    this.createdAt,
    this.updatedAt,
  });
  final int? id;
  final String? name;
  final String? description;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    };
  }

  static const _GenreUpdateDtoCopyWithSentinel _copyWithSentinel =
      _GenreUpdateDtoCopyWithSentinel();
  GenreUpdateDto copyWith({
    Object? id = _copyWithSentinel,
    Object? name = _copyWithSentinel,
    Object? description = _copyWithSentinel,
    Object? createdAt = _copyWithSentinel,
    Object? updatedAt = _copyWithSentinel,
  }) {
    return GenreUpdateDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      name: identical(name, _copyWithSentinel) ? this.name : name as String?,
      description: identical(description, _copyWithSentinel)
          ? this.description
          : description as String?,
      createdAt: identical(createdAt, _copyWithSentinel)
          ? this.createdAt
          : createdAt as DateTime?,
      updatedAt: identical(updatedAt, _copyWithSentinel)
          ? this.updatedAt
          : updatedAt as DateTime?,
    );
  }
}

class _GenreUpdateDtoCopyWithSentinel {
  const _GenreUpdateDtoCopyWithSentinel();
}

/// Partial projection for [Genre].
///
/// All fields are nullable; intended for subset SELECTs.
class GenrePartial implements PartialEntity<$Genre> {
  const GenrePartial({
    this.id,
    this.name,
    this.description,
    this.createdAt,
    this.updatedAt,
  });

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory GenrePartial.fromRow(Map<String, Object?> row) {
    return GenrePartial(
      id: row['id'] as int?,
      name: row['name'] as String?,
      description: row['description'] as String?,
      createdAt: row['created_at'] as DateTime?,
      updatedAt: row['updated_at'] as DateTime?,
    );
  }

  final int? id;
  final String? name;
  final String? description;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  @override
  $Genre toEntity() {
    // Basic required-field check: non-nullable fields must be present.
    final int? idValue = id;
    if (idValue == null) {
      throw StateError('Missing required field: id');
    }
    final String? nameValue = name;
    if (nameValue == null) {
      throw StateError('Missing required field: name');
    }
    return $Genre(
      id: idValue,
      name: nameValue,
      description: description,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    };
  }

  static const _GenrePartialCopyWithSentinel _copyWithSentinel =
      _GenrePartialCopyWithSentinel();
  GenrePartial copyWith({
    Object? id = _copyWithSentinel,
    Object? name = _copyWithSentinel,
    Object? description = _copyWithSentinel,
    Object? createdAt = _copyWithSentinel,
    Object? updatedAt = _copyWithSentinel,
  }) {
    return GenrePartial(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      name: identical(name, _copyWithSentinel) ? this.name : name as String?,
      description: identical(description, _copyWithSentinel)
          ? this.description
          : description as String?,
      createdAt: identical(createdAt, _copyWithSentinel)
          ? this.createdAt
          : createdAt as DateTime?,
      updatedAt: identical(updatedAt, _copyWithSentinel)
          ? this.updatedAt
          : updatedAt as DateTime?,
    );
  }
}

class _GenrePartialCopyWithSentinel {
  const _GenrePartialCopyWithSentinel();
}

/// Generated tracked model class for [Genre].
///
/// This class extends the user-defined [Genre] model and adds
/// attribute tracking, change detection, and relationship management.
/// Instances of this class are returned by queries and repositories.
///
/// **Do not instantiate this class directly.** Use queries, repositories,
/// or model factories to create tracked model instances.
class $Genre extends Genre with ModelAttributes implements OrmEntity {
  /// Internal constructor for [$Genre].
  $Genre({
    int id = 0,
    required String name,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : super.new(
         id: id,
         name: name,
         description: description,
         createdAt: createdAt,
         updatedAt: updatedAt,
       ) {
    _attachOrmRuntimeMetadata({
      'id': id,
      'name': name,
      'description': description,
      'created_at': createdAt,
      'updated_at': updatedAt,
    });
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $Genre.fromModel(Genre model) {
    return $Genre(
      id: model.id,
      name: model.name,
      description: model.description,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );
  }

  $Genre copyWith({
    int? id,
    String? name,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return $Genre(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Tracked getter for [id].
  @override
  int get id => getAttribute<int>('id') ?? super.id;

  /// Tracked setter for [id].
  set id(int value) => setAttribute('id', value);

  /// Tracked getter for [name].
  @override
  String get name => getAttribute<String>('name') ?? super.name;

  /// Tracked setter for [name].
  set name(String value) => setAttribute('name', value);

  /// Tracked getter for [description].
  @override
  String? get description =>
      getAttribute<String?>('description') ?? super.description;

  /// Tracked setter for [description].
  set description(String? value) => setAttribute('description', value);

  /// Tracked getter for [createdAt].
  @override
  DateTime? get createdAt =>
      getAttribute<DateTime?>('created_at') ?? super.createdAt;

  /// Tracked setter for [createdAt].
  set createdAt(DateTime? value) => setAttribute('created_at', value);

  /// Tracked getter for [updatedAt].
  @override
  DateTime? get updatedAt =>
      getAttribute<DateTime?>('updated_at') ?? super.updatedAt;

  /// Tracked setter for [updatedAt].
  set updatedAt(DateTime? value) => setAttribute('updated_at', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$GenreDefinition);
  }
}

extension GenreOrmExtension on Genre {
  /// The Type of the generated ORM-managed model class.
  /// Use this when you need to specify the tracked model type explicitly,
  /// for example in generic type parameters.
  static Type get trackedType => $Genre;

  /// Converts this immutable model to a tracked ORM-managed model.
  /// The tracked model supports attribute tracking, change detection,
  /// and persistence operations like save() and touch().
  $Genre toTracked() {
    return $Genre.fromModel(this);
  }
}

void registerGenreEventHandlers(EventBus bus) {
  // No event handlers registered for Genre.
}
