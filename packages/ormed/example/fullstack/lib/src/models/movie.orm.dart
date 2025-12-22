// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'movie.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$MovieIdField = FieldDefinition(
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

const FieldDefinition _$MovieTitleField = FieldDefinition(
  name: 'title',
  columnName: 'title',
  dartType: 'String',
  resolvedType: 'String',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$MovieReleaseYearField = FieldDefinition(
  name: 'releaseYear',
  columnName: 'release_year',
  dartType: 'int',
  resolvedType: 'int',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$MovieSummaryField = FieldDefinition(
  name: 'summary',
  columnName: 'summary',
  dartType: 'String',
  resolvedType: 'String?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$MoviePosterPathField = FieldDefinition(
  name: 'posterPath',
  columnName: 'poster_path',
  dartType: 'String',
  resolvedType: 'String?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$MovieGenreIdField = FieldDefinition(
  name: 'genreId',
  columnName: 'genre_id',
  dartType: 'int',
  resolvedType: 'int?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$MovieCreatedAtField = FieldDefinition(
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

const FieldDefinition _$MovieUpdatedAtField = FieldDefinition(
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

const RelationDefinition _$MovieGenreRelation = RelationDefinition(
  name: 'genre',
  kind: RelationKind.belongsTo,
  targetModel: 'Genre',
  foreignKey: 'genre_id',
);

Map<String, Object?> _encodeMovieUntracked(
  Object model,
  ValueCodecRegistry registry,
) {
  final m = model as Movie;
  return <String, Object?>{
    'id': registry.encodeField(_$MovieIdField, m.id),
    'title': registry.encodeField(_$MovieTitleField, m.title),
    'release_year': registry.encodeField(
      _$MovieReleaseYearField,
      m.releaseYear,
    ),
    'summary': registry.encodeField(_$MovieSummaryField, m.summary),
    'poster_path': registry.encodeField(_$MoviePosterPathField, m.posterPath),
    'genre_id': registry.encodeField(_$MovieGenreIdField, m.genreId),
    'created_at': registry.encodeField(_$MovieCreatedAtField, m.createdAt),
    'updated_at': registry.encodeField(_$MovieUpdatedAtField, m.updatedAt),
  };
}

final ModelDefinition<$Movie> _$MovieDefinition = ModelDefinition(
  modelName: 'Movie',
  tableName: 'movies',
  fields: const [
    _$MovieIdField,
    _$MovieTitleField,
    _$MovieReleaseYearField,
    _$MovieSummaryField,
    _$MoviePosterPathField,
    _$MovieGenreIdField,
    _$MovieCreatedAtField,
    _$MovieUpdatedAtField,
  ],
  relations: const [_$MovieGenreRelation],
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
  untrackedToMap: _encodeMovieUntracked,
  codec: _$MovieCodec(),
);

extension MovieOrmDefinition on Movie {
  static ModelDefinition<$Movie> get definition => _$MovieDefinition;
}

class Movies {
  const Movies._();

  /// Starts building a query for [$Movie].
  ///
  /// {@macro ormed.query}
  static Query<$Movie> query([String? connection]) =>
      Model.query<$Movie>(connection: connection);

  static Future<$Movie?> find(Object id, {String? connection}) =>
      Model.find<$Movie>(id, connection: connection);

  static Future<$Movie> findOrFail(Object id, {String? connection}) =>
      Model.findOrFail<$Movie>(id, connection: connection);

  static Future<List<$Movie>> all({String? connection}) =>
      Model.all<$Movie>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<$Movie>(connection: connection);

  static Future<bool> anyExist({String? connection}) =>
      Model.anyExist<$Movie>(connection: connection);

  static Query<$Movie> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) => Model.where<$Movie>(column, operator, value, connection: connection);

  static Query<$Movie> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<$Movie>(column, values, connection: connection);

  static Query<$Movie> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<$Movie>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<$Movie> limit(int count, {String? connection}) =>
      Model.limit<$Movie>(count, connection: connection);

  /// Creates a [Repository] for [$Movie].
  ///
  /// {@macro ormed.repository}
  static Repository<$Movie> repo([String? connection]) =>
      Model.repository<$Movie>(connection: connection);
}

class MovieModelFactory {
  const MovieModelFactory._();

  static ModelDefinition<$Movie> get definition => _$MovieDefinition;

  static ModelCodec<$Movie> get codec => definition.codec;

  static Movie fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    Movie model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model.toTracked(), registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<Movie> withConnection(QueryContext context) =>
      ModelFactoryConnection<Movie>(definition: definition, context: context);

  static ModelFactoryBuilder<Movie> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<Movie>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$MovieCodec extends ModelCodec<$Movie> {
  const _$MovieCodec();
  @override
  Map<String, Object?> encode($Movie model, ValueCodecRegistry registry) {
    return <String, Object?>{
      'id': registry.encodeField(_$MovieIdField, model.id),
      'title': registry.encodeField(_$MovieTitleField, model.title),
      'release_year': registry.encodeField(
        _$MovieReleaseYearField,
        model.releaseYear,
      ),
      'summary': registry.encodeField(_$MovieSummaryField, model.summary),
      'poster_path': registry.encodeField(
        _$MoviePosterPathField,
        model.posterPath,
      ),
      'genre_id': registry.encodeField(_$MovieGenreIdField, model.genreId),
      'created_at': registry.encodeField(
        _$MovieCreatedAtField,
        model.createdAt,
      ),
      'updated_at': registry.encodeField(
        _$MovieUpdatedAtField,
        model.updatedAt,
      ),
    };
  }

  @override
  $Movie decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final int movieIdValue =
        registry.decodeField<int>(_$MovieIdField, data['id']) ?? 0;
    final String movieTitleValue =
        registry.decodeField<String>(_$MovieTitleField, data['title']) ??
        (throw StateError('Field title on Movie cannot be null.'));
    final int movieReleaseYearValue =
        registry.decodeField<int>(
          _$MovieReleaseYearField,
          data['release_year'],
        ) ??
        (throw StateError('Field releaseYear on Movie cannot be null.'));
    final String? movieSummaryValue = registry.decodeField<String?>(
      _$MovieSummaryField,
      data['summary'],
    );
    final String? moviePosterPathValue = registry.decodeField<String?>(
      _$MoviePosterPathField,
      data['poster_path'],
    );
    final int? movieGenreIdValue = registry.decodeField<int?>(
      _$MovieGenreIdField,
      data['genre_id'],
    );
    final DateTime? movieCreatedAtValue = registry.decodeField<DateTime?>(
      _$MovieCreatedAtField,
      data['created_at'],
    );
    final DateTime? movieUpdatedAtValue = registry.decodeField<DateTime?>(
      _$MovieUpdatedAtField,
      data['updated_at'],
    );
    final model = $Movie(
      id: movieIdValue,
      title: movieTitleValue,
      releaseYear: movieReleaseYearValue,
      summary: movieSummaryValue,
      posterPath: moviePosterPathValue,
      genreId: movieGenreIdValue,
      createdAt: movieCreatedAtValue,
      updatedAt: movieUpdatedAtValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': movieIdValue,
      'title': movieTitleValue,
      'release_year': movieReleaseYearValue,
      'summary': movieSummaryValue,
      'poster_path': moviePosterPathValue,
      'genre_id': movieGenreIdValue,
      'created_at': movieCreatedAtValue,
      'updated_at': movieUpdatedAtValue,
    });
    return model;
  }
}

/// Insert DTO for [Movie].
///
/// Auto-increment/DB-generated fields are omitted by default.
class MovieInsertDto implements InsertDto<$Movie> {
  const MovieInsertDto({
    this.title,
    this.releaseYear,
    this.summary,
    this.posterPath,
    this.genreId,
    this.createdAt,
    this.updatedAt,
  });
  final String? title;
  final int? releaseYear;
  final String? summary;
  final String? posterPath;
  final int? genreId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (title != null) 'title': title,
      if (releaseYear != null) 'release_year': releaseYear,
      if (summary != null) 'summary': summary,
      if (posterPath != null) 'poster_path': posterPath,
      if (genreId != null) 'genre_id': genreId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    };
  }

  static const _MovieInsertDtoCopyWithSentinel _copyWithSentinel =
      _MovieInsertDtoCopyWithSentinel();
  MovieInsertDto copyWith({
    Object? title = _copyWithSentinel,
    Object? releaseYear = _copyWithSentinel,
    Object? summary = _copyWithSentinel,
    Object? posterPath = _copyWithSentinel,
    Object? genreId = _copyWithSentinel,
    Object? createdAt = _copyWithSentinel,
    Object? updatedAt = _copyWithSentinel,
  }) {
    return MovieInsertDto(
      title: identical(title, _copyWithSentinel)
          ? this.title
          : title as String?,
      releaseYear: identical(releaseYear, _copyWithSentinel)
          ? this.releaseYear
          : releaseYear as int?,
      summary: identical(summary, _copyWithSentinel)
          ? this.summary
          : summary as String?,
      posterPath: identical(posterPath, _copyWithSentinel)
          ? this.posterPath
          : posterPath as String?,
      genreId: identical(genreId, _copyWithSentinel)
          ? this.genreId
          : genreId as int?,
      createdAt: identical(createdAt, _copyWithSentinel)
          ? this.createdAt
          : createdAt as DateTime?,
      updatedAt: identical(updatedAt, _copyWithSentinel)
          ? this.updatedAt
          : updatedAt as DateTime?,
    );
  }
}

class _MovieInsertDtoCopyWithSentinel {
  const _MovieInsertDtoCopyWithSentinel();
}

/// Update DTO for [Movie].
///
/// All fields are optional; only provided entries are used in SET clauses.
class MovieUpdateDto implements UpdateDto<$Movie> {
  const MovieUpdateDto({
    this.id,
    this.title,
    this.releaseYear,
    this.summary,
    this.posterPath,
    this.genreId,
    this.createdAt,
    this.updatedAt,
  });
  final int? id;
  final String? title;
  final int? releaseYear;
  final String? summary;
  final String? posterPath;
  final int? genreId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (releaseYear != null) 'release_year': releaseYear,
      if (summary != null) 'summary': summary,
      if (posterPath != null) 'poster_path': posterPath,
      if (genreId != null) 'genre_id': genreId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    };
  }

  static const _MovieUpdateDtoCopyWithSentinel _copyWithSentinel =
      _MovieUpdateDtoCopyWithSentinel();
  MovieUpdateDto copyWith({
    Object? id = _copyWithSentinel,
    Object? title = _copyWithSentinel,
    Object? releaseYear = _copyWithSentinel,
    Object? summary = _copyWithSentinel,
    Object? posterPath = _copyWithSentinel,
    Object? genreId = _copyWithSentinel,
    Object? createdAt = _copyWithSentinel,
    Object? updatedAt = _copyWithSentinel,
  }) {
    return MovieUpdateDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      title: identical(title, _copyWithSentinel)
          ? this.title
          : title as String?,
      releaseYear: identical(releaseYear, _copyWithSentinel)
          ? this.releaseYear
          : releaseYear as int?,
      summary: identical(summary, _copyWithSentinel)
          ? this.summary
          : summary as String?,
      posterPath: identical(posterPath, _copyWithSentinel)
          ? this.posterPath
          : posterPath as String?,
      genreId: identical(genreId, _copyWithSentinel)
          ? this.genreId
          : genreId as int?,
      createdAt: identical(createdAt, _copyWithSentinel)
          ? this.createdAt
          : createdAt as DateTime?,
      updatedAt: identical(updatedAt, _copyWithSentinel)
          ? this.updatedAt
          : updatedAt as DateTime?,
    );
  }
}

class _MovieUpdateDtoCopyWithSentinel {
  const _MovieUpdateDtoCopyWithSentinel();
}

/// Partial projection for [Movie].
///
/// All fields are nullable; intended for subset SELECTs.
class MoviePartial implements PartialEntity<$Movie> {
  const MoviePartial({
    this.id,
    this.title,
    this.releaseYear,
    this.summary,
    this.posterPath,
    this.genreId,
    this.createdAt,
    this.updatedAt,
  });

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory MoviePartial.fromRow(Map<String, Object?> row) {
    return MoviePartial(
      id: row['id'] as int?,
      title: row['title'] as String?,
      releaseYear: row['release_year'] as int?,
      summary: row['summary'] as String?,
      posterPath: row['poster_path'] as String?,
      genreId: row['genre_id'] as int?,
      createdAt: row['created_at'] as DateTime?,
      updatedAt: row['updated_at'] as DateTime?,
    );
  }

  final int? id;
  final String? title;
  final int? releaseYear;
  final String? summary;
  final String? posterPath;
  final int? genreId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  @override
  $Movie toEntity() {
    // Basic required-field check: non-nullable fields must be present.
    final int? idValue = id;
    if (idValue == null) {
      throw StateError('Missing required field: id');
    }
    final String? titleValue = title;
    if (titleValue == null) {
      throw StateError('Missing required field: title');
    }
    final int? releaseYearValue = releaseYear;
    if (releaseYearValue == null) {
      throw StateError('Missing required field: releaseYear');
    }
    return $Movie(
      id: idValue,
      title: titleValue,
      releaseYear: releaseYearValue,
      summary: summary,
      posterPath: posterPath,
      genreId: genreId,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (releaseYear != null) 'release_year': releaseYear,
      if (summary != null) 'summary': summary,
      if (posterPath != null) 'poster_path': posterPath,
      if (genreId != null) 'genre_id': genreId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    };
  }

  static const _MoviePartialCopyWithSentinel _copyWithSentinel =
      _MoviePartialCopyWithSentinel();
  MoviePartial copyWith({
    Object? id = _copyWithSentinel,
    Object? title = _copyWithSentinel,
    Object? releaseYear = _copyWithSentinel,
    Object? summary = _copyWithSentinel,
    Object? posterPath = _copyWithSentinel,
    Object? genreId = _copyWithSentinel,
    Object? createdAt = _copyWithSentinel,
    Object? updatedAt = _copyWithSentinel,
  }) {
    return MoviePartial(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      title: identical(title, _copyWithSentinel)
          ? this.title
          : title as String?,
      releaseYear: identical(releaseYear, _copyWithSentinel)
          ? this.releaseYear
          : releaseYear as int?,
      summary: identical(summary, _copyWithSentinel)
          ? this.summary
          : summary as String?,
      posterPath: identical(posterPath, _copyWithSentinel)
          ? this.posterPath
          : posterPath as String?,
      genreId: identical(genreId, _copyWithSentinel)
          ? this.genreId
          : genreId as int?,
      createdAt: identical(createdAt, _copyWithSentinel)
          ? this.createdAt
          : createdAt as DateTime?,
      updatedAt: identical(updatedAt, _copyWithSentinel)
          ? this.updatedAt
          : updatedAt as DateTime?,
    );
  }
}

class _MoviePartialCopyWithSentinel {
  const _MoviePartialCopyWithSentinel();
}

/// Generated tracked model class for [Movie].
///
/// This class extends the user-defined [Movie] model and adds
/// attribute tracking, change detection, and relationship management.
/// Instances of this class are returned by queries and repositories.
///
/// **Do not instantiate this class directly.** Use queries, repositories,
/// or model factories to create tracked model instances.
class $Movie extends Movie with ModelAttributes implements OrmEntity {
  /// Internal constructor for [$Movie].
  $Movie({
    int id = 0,
    required String title,
    required int releaseYear,
    String? summary,
    String? posterPath,
    int? genreId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : super.new(
         id: id,
         title: title,
         releaseYear: releaseYear,
         summary: summary,
         posterPath: posterPath,
         genreId: genreId,
         createdAt: createdAt,
         updatedAt: updatedAt,
       ) {
    _attachOrmRuntimeMetadata({
      'id': id,
      'title': title,
      'release_year': releaseYear,
      'summary': summary,
      'poster_path': posterPath,
      'genre_id': genreId,
      'created_at': createdAt,
      'updated_at': updatedAt,
    });
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $Movie.fromModel(Movie model) {
    return $Movie(
      id: model.id,
      title: model.title,
      releaseYear: model.releaseYear,
      summary: model.summary,
      posterPath: model.posterPath,
      genreId: model.genreId,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );
  }

  $Movie copyWith({
    int? id,
    String? title,
    int? releaseYear,
    String? summary,
    String? posterPath,
    int? genreId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return $Movie(
      id: id ?? this.id,
      title: title ?? this.title,
      releaseYear: releaseYear ?? this.releaseYear,
      summary: summary ?? this.summary,
      posterPath: posterPath ?? this.posterPath,
      genreId: genreId ?? this.genreId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Tracked getter for [id].
  @override
  int get id => getAttribute<int>('id') ?? super.id;

  /// Tracked setter for [id].
  set id(int value) => setAttribute('id', value);

  /// Tracked getter for [title].
  @override
  String get title => getAttribute<String>('title') ?? super.title;

  /// Tracked setter for [title].
  set title(String value) => setAttribute('title', value);

  /// Tracked getter for [releaseYear].
  @override
  int get releaseYear => getAttribute<int>('release_year') ?? super.releaseYear;

  /// Tracked setter for [releaseYear].
  set releaseYear(int value) => setAttribute('release_year', value);

  /// Tracked getter for [summary].
  @override
  String? get summary => getAttribute<String?>('summary') ?? super.summary;

  /// Tracked setter for [summary].
  set summary(String? value) => setAttribute('summary', value);

  /// Tracked getter for [posterPath].
  @override
  String? get posterPath =>
      getAttribute<String?>('poster_path') ?? super.posterPath;

  /// Tracked setter for [posterPath].
  set posterPath(String? value) => setAttribute('poster_path', value);

  /// Tracked getter for [genreId].
  @override
  int? get genreId => getAttribute<int?>('genre_id') ?? super.genreId;

  /// Tracked setter for [genreId].
  set genreId(int? value) => setAttribute('genre_id', value);

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
    attachModelDefinition(_$MovieDefinition);
  }

  @override
  Genre? get genre {
    if (relationLoaded('genre')) {
      return getRelation<Genre>('genre');
    }
    return super.genre;
  }
}

extension MovieRelationQueries on Movie {
  Query<Genre> genreQuery() {
    return Model.query<Genre>().where('null', genreId);
  }
}

extension MovieOrmExtension on Movie {
  /// The Type of the generated ORM-managed model class.
  /// Use this when you need to specify the tracked model type explicitly,
  /// for example in generic type parameters.
  static Type get trackedType => $Movie;

  /// Converts this immutable model to a tracked ORM-managed model.
  /// The tracked model supports attribute tracking, change detection,
  /// and persistence operations like save() and touch().
  $Movie toTracked() {
    return $Movie.fromModel(this);
  }
}

void registerMovieEventHandlers(EventBus bus) {
  // No event handlers registered for Movie.
}
