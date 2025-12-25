// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'article.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$ArticleIdField = FieldDefinition(
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

const FieldDefinition _$ArticleTitleField = FieldDefinition(
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

const FieldDefinition _$ArticleBodyField = FieldDefinition(
  name: 'body',
  columnName: 'body',
  dartType: 'String',
  resolvedType: 'String?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$ArticleStatusField = FieldDefinition(
  name: 'status',
  columnName: 'status',
  dartType: 'String',
  resolvedType: 'String',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$ArticleRatingField = FieldDefinition(
  name: 'rating',
  columnName: 'rating',
  dartType: 'double',
  resolvedType: 'double',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$ArticlePriorityField = FieldDefinition(
  name: 'priority',
  columnName: 'priority',
  dartType: 'int',
  resolvedType: 'int',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$ArticlePublishedAtField = FieldDefinition(
  name: 'publishedAt',
  columnName: 'published_at',
  dartType: 'DateTime',
  resolvedType: 'DateTime',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$ArticleReviewedAtField = FieldDefinition(
  name: 'reviewedAt',
  columnName: 'reviewed_at',
  dartType: 'DateTime',
  resolvedType: 'DateTime?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$ArticleCategoryIdField = FieldDefinition(
  name: 'categoryId',
  columnName: 'category_id',
  dartType: 'int',
  resolvedType: 'int',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

Map<String, Object?> _encodeArticleUntracked(
  Object model,
  ValueCodecRegistry registry,
) {
  final m = model as Article;
  return <String, Object?>{
    'id': registry.encodeField(_$ArticleIdField, m.id),
    'title': registry.encodeField(_$ArticleTitleField, m.title),
    'body': registry.encodeField(_$ArticleBodyField, m.body),
    'status': registry.encodeField(_$ArticleStatusField, m.status),
    'rating': registry.encodeField(_$ArticleRatingField, m.rating),
    'priority': registry.encodeField(_$ArticlePriorityField, m.priority),
    'published_at': registry.encodeField(
      _$ArticlePublishedAtField,
      m.publishedAt,
    ),
    'reviewed_at': registry.encodeField(_$ArticleReviewedAtField, m.reviewedAt),
    'category_id': registry.encodeField(_$ArticleCategoryIdField, m.categoryId),
  };
}

final ModelDefinition<$Article> _$ArticleDefinition = ModelDefinition(
  modelName: 'Article',
  tableName: 'articles',
  fields: const [
    _$ArticleIdField,
    _$ArticleTitleField,
    _$ArticleBodyField,
    _$ArticleStatusField,
    _$ArticleRatingField,
    _$ArticlePriorityField,
    _$ArticlePublishedAtField,
    _$ArticleReviewedAtField,
    _$ArticleCategoryIdField,
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
  untrackedToMap: _encodeArticleUntracked,
  codec: _$ArticleCodec(),
);

// ignore: unused_element
final articleModelDefinitionRegistration =
    ModelFactoryRegistry.register<$Article>(_$ArticleDefinition);

extension ArticleOrmDefinition on Article {
  static ModelDefinition<$Article> get definition => _$ArticleDefinition;
}

class Articles {
  const Articles._();

  /// Starts building a query for [$Article].
  ///
  /// {@macro ormed.query}
  static Query<$Article> query([String? connection]) =>
      Model.query<$Article>(connection: connection);

  static Future<$Article?> find(Object id, {String? connection}) =>
      Model.find<$Article>(id, connection: connection);

  static Future<$Article> findOrFail(Object id, {String? connection}) =>
      Model.findOrFail<$Article>(id, connection: connection);

  static Future<List<$Article>> all({String? connection}) =>
      Model.all<$Article>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<$Article>(connection: connection);

  static Future<bool> anyExist({String? connection}) =>
      Model.anyExist<$Article>(connection: connection);

  static Query<$Article> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) => Model.where<$Article>(column, operator, value, connection: connection);

  static Query<$Article> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<$Article>(column, values, connection: connection);

  static Query<$Article> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<$Article>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<$Article> limit(int count, {String? connection}) =>
      Model.limit<$Article>(count, connection: connection);

  /// Creates a [Repository] for [$Article].
  ///
  /// {@macro ormed.repository}
  static Repository<$Article> repo([String? connection]) =>
      Model.repository<$Article>(connection: connection);
}

class ArticleModelFactory {
  const ArticleModelFactory._();

  static ModelDefinition<$Article> get definition => _$ArticleDefinition;

  static ModelCodec<$Article> get codec => definition.codec;

  static Article fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    Article model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model.toTracked(), registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<Article> withConnection(QueryContext context) =>
      ModelFactoryConnection<Article>(definition: definition, context: context);

  static ModelFactoryBuilder<Article> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<Article>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$ArticleCodec extends ModelCodec<$Article> {
  const _$ArticleCodec();
  @override
  Map<String, Object?> encode($Article model, ValueCodecRegistry registry) {
    return <String, Object?>{
      'id': registry.encodeField(_$ArticleIdField, model.id),
      'title': registry.encodeField(_$ArticleTitleField, model.title),
      'body': registry.encodeField(_$ArticleBodyField, model.body),
      'status': registry.encodeField(_$ArticleStatusField, model.status),
      'rating': registry.encodeField(_$ArticleRatingField, model.rating),
      'priority': registry.encodeField(_$ArticlePriorityField, model.priority),
      'published_at': registry.encodeField(
        _$ArticlePublishedAtField,
        model.publishedAt,
      ),
      'reviewed_at': registry.encodeField(
        _$ArticleReviewedAtField,
        model.reviewedAt,
      ),
      'category_id': registry.encodeField(
        _$ArticleCategoryIdField,
        model.categoryId,
      ),
    };
  }

  @override
  $Article decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final int articleIdValue =
        registry.decodeField<int>(_$ArticleIdField, data['id']) ?? 0;
    final String articleTitleValue =
        registry.decodeField<String>(_$ArticleTitleField, data['title']) ??
        (throw StateError('Field title on Article cannot be null.'));
    final String? articleBodyValue = registry.decodeField<String?>(
      _$ArticleBodyField,
      data['body'],
    );
    final String articleStatusValue =
        registry.decodeField<String>(_$ArticleStatusField, data['status']) ??
        (throw StateError('Field status on Article cannot be null.'));
    final double articleRatingValue =
        registry.decodeField<double>(_$ArticleRatingField, data['rating']) ??
        (throw StateError('Field rating on Article cannot be null.'));
    final int articlePriorityValue =
        registry.decodeField<int>(_$ArticlePriorityField, data['priority']) ??
        (throw StateError('Field priority on Article cannot be null.'));
    final DateTime articlePublishedAtValue =
        registry.decodeField<DateTime>(
          _$ArticlePublishedAtField,
          data['published_at'],
        ) ??
        (throw StateError('Field publishedAt on Article cannot be null.'));
    final DateTime? articleReviewedAtValue = registry.decodeField<DateTime?>(
      _$ArticleReviewedAtField,
      data['reviewed_at'],
    );
    final int articleCategoryIdValue =
        registry.decodeField<int>(
          _$ArticleCategoryIdField,
          data['category_id'],
        ) ??
        (throw StateError('Field categoryId on Article cannot be null.'));
    final model = $Article(
      id: articleIdValue,
      title: articleTitleValue,
      body: articleBodyValue,
      status: articleStatusValue,
      rating: articleRatingValue,
      priority: articlePriorityValue,
      publishedAt: articlePublishedAtValue,
      reviewedAt: articleReviewedAtValue,
      categoryId: articleCategoryIdValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': articleIdValue,
      'title': articleTitleValue,
      'body': articleBodyValue,
      'status': articleStatusValue,
      'rating': articleRatingValue,
      'priority': articlePriorityValue,
      'published_at': articlePublishedAtValue,
      'reviewed_at': articleReviewedAtValue,
      'category_id': articleCategoryIdValue,
    });
    return model;
  }
}

/// Insert DTO for [Article].
///
/// Auto-increment/DB-generated fields are omitted by default.
class ArticleInsertDto implements InsertDto<$Article> {
  const ArticleInsertDto({
    this.title,
    this.body,
    this.status,
    this.rating,
    this.priority,
    this.publishedAt,
    this.reviewedAt,
    this.categoryId,
  });
  final String? title;
  final String? body;
  final String? status;
  final double? rating;
  final int? priority;
  final DateTime? publishedAt;
  final DateTime? reviewedAt;
  final int? categoryId;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (status != null) 'status': status,
      if (rating != null) 'rating': rating,
      if (priority != null) 'priority': priority,
      if (publishedAt != null) 'published_at': publishedAt,
      if (reviewedAt != null) 'reviewed_at': reviewedAt,
      if (categoryId != null) 'category_id': categoryId,
    };
  }

  static const _ArticleInsertDtoCopyWithSentinel _copyWithSentinel =
      _ArticleInsertDtoCopyWithSentinel();
  ArticleInsertDto copyWith({
    Object? title = _copyWithSentinel,
    Object? body = _copyWithSentinel,
    Object? status = _copyWithSentinel,
    Object? rating = _copyWithSentinel,
    Object? priority = _copyWithSentinel,
    Object? publishedAt = _copyWithSentinel,
    Object? reviewedAt = _copyWithSentinel,
    Object? categoryId = _copyWithSentinel,
  }) {
    return ArticleInsertDto(
      title: identical(title, _copyWithSentinel)
          ? this.title
          : title as String?,
      body: identical(body, _copyWithSentinel) ? this.body : body as String?,
      status: identical(status, _copyWithSentinel)
          ? this.status
          : status as String?,
      rating: identical(rating, _copyWithSentinel)
          ? this.rating
          : rating as double?,
      priority: identical(priority, _copyWithSentinel)
          ? this.priority
          : priority as int?,
      publishedAt: identical(publishedAt, _copyWithSentinel)
          ? this.publishedAt
          : publishedAt as DateTime?,
      reviewedAt: identical(reviewedAt, _copyWithSentinel)
          ? this.reviewedAt
          : reviewedAt as DateTime?,
      categoryId: identical(categoryId, _copyWithSentinel)
          ? this.categoryId
          : categoryId as int?,
    );
  }
}

class _ArticleInsertDtoCopyWithSentinel {
  const _ArticleInsertDtoCopyWithSentinel();
}

/// Update DTO for [Article].
///
/// All fields are optional; only provided entries are used in SET clauses.
class ArticleUpdateDto implements UpdateDto<$Article> {
  const ArticleUpdateDto({
    this.id,
    this.title,
    this.body,
    this.status,
    this.rating,
    this.priority,
    this.publishedAt,
    this.reviewedAt,
    this.categoryId,
  });
  final int? id;
  final String? title;
  final String? body;
  final String? status;
  final double? rating;
  final int? priority;
  final DateTime? publishedAt;
  final DateTime? reviewedAt;
  final int? categoryId;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (status != null) 'status': status,
      if (rating != null) 'rating': rating,
      if (priority != null) 'priority': priority,
      if (publishedAt != null) 'published_at': publishedAt,
      if (reviewedAt != null) 'reviewed_at': reviewedAt,
      if (categoryId != null) 'category_id': categoryId,
    };
  }

  static const _ArticleUpdateDtoCopyWithSentinel _copyWithSentinel =
      _ArticleUpdateDtoCopyWithSentinel();
  ArticleUpdateDto copyWith({
    Object? id = _copyWithSentinel,
    Object? title = _copyWithSentinel,
    Object? body = _copyWithSentinel,
    Object? status = _copyWithSentinel,
    Object? rating = _copyWithSentinel,
    Object? priority = _copyWithSentinel,
    Object? publishedAt = _copyWithSentinel,
    Object? reviewedAt = _copyWithSentinel,
    Object? categoryId = _copyWithSentinel,
  }) {
    return ArticleUpdateDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      title: identical(title, _copyWithSentinel)
          ? this.title
          : title as String?,
      body: identical(body, _copyWithSentinel) ? this.body : body as String?,
      status: identical(status, _copyWithSentinel)
          ? this.status
          : status as String?,
      rating: identical(rating, _copyWithSentinel)
          ? this.rating
          : rating as double?,
      priority: identical(priority, _copyWithSentinel)
          ? this.priority
          : priority as int?,
      publishedAt: identical(publishedAt, _copyWithSentinel)
          ? this.publishedAt
          : publishedAt as DateTime?,
      reviewedAt: identical(reviewedAt, _copyWithSentinel)
          ? this.reviewedAt
          : reviewedAt as DateTime?,
      categoryId: identical(categoryId, _copyWithSentinel)
          ? this.categoryId
          : categoryId as int?,
    );
  }
}

class _ArticleUpdateDtoCopyWithSentinel {
  const _ArticleUpdateDtoCopyWithSentinel();
}

/// Partial projection for [Article].
///
/// All fields are nullable; intended for subset SELECTs.
class ArticlePartial implements PartialEntity<$Article> {
  const ArticlePartial({
    this.id,
    this.title,
    this.body,
    this.status,
    this.rating,
    this.priority,
    this.publishedAt,
    this.reviewedAt,
    this.categoryId,
  });

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory ArticlePartial.fromRow(Map<String, Object?> row) {
    return ArticlePartial(
      id: row['id'] as int?,
      title: row['title'] as String?,
      body: row['body'] as String?,
      status: row['status'] as String?,
      rating: row['rating'] as double?,
      priority: row['priority'] as int?,
      publishedAt: row['published_at'] as DateTime?,
      reviewedAt: row['reviewed_at'] as DateTime?,
      categoryId: row['category_id'] as int?,
    );
  }

  final int? id;
  final String? title;
  final String? body;
  final String? status;
  final double? rating;
  final int? priority;
  final DateTime? publishedAt;
  final DateTime? reviewedAt;
  final int? categoryId;

  @override
  $Article toEntity() {
    // Basic required-field check: non-nullable fields must be present.
    final int? idValue = id;
    if (idValue == null) {
      throw StateError('Missing required field: id');
    }
    final String? titleValue = title;
    if (titleValue == null) {
      throw StateError('Missing required field: title');
    }
    final String? statusValue = status;
    if (statusValue == null) {
      throw StateError('Missing required field: status');
    }
    final double? ratingValue = rating;
    if (ratingValue == null) {
      throw StateError('Missing required field: rating');
    }
    final int? priorityValue = priority;
    if (priorityValue == null) {
      throw StateError('Missing required field: priority');
    }
    final DateTime? publishedAtValue = publishedAt;
    if (publishedAtValue == null) {
      throw StateError('Missing required field: publishedAt');
    }
    final int? categoryIdValue = categoryId;
    if (categoryIdValue == null) {
      throw StateError('Missing required field: categoryId');
    }
    return $Article(
      id: idValue,
      title: titleValue,
      body: body,
      status: statusValue,
      rating: ratingValue,
      priority: priorityValue,
      publishedAt: publishedAtValue,
      reviewedAt: reviewedAt,
      categoryId: categoryIdValue,
    );
  }

  @override
  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (status != null) 'status': status,
      if (rating != null) 'rating': rating,
      if (priority != null) 'priority': priority,
      if (publishedAt != null) 'published_at': publishedAt,
      if (reviewedAt != null) 'reviewed_at': reviewedAt,
      if (categoryId != null) 'category_id': categoryId,
    };
  }

  static const _ArticlePartialCopyWithSentinel _copyWithSentinel =
      _ArticlePartialCopyWithSentinel();
  ArticlePartial copyWith({
    Object? id = _copyWithSentinel,
    Object? title = _copyWithSentinel,
    Object? body = _copyWithSentinel,
    Object? status = _copyWithSentinel,
    Object? rating = _copyWithSentinel,
    Object? priority = _copyWithSentinel,
    Object? publishedAt = _copyWithSentinel,
    Object? reviewedAt = _copyWithSentinel,
    Object? categoryId = _copyWithSentinel,
  }) {
    return ArticlePartial(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      title: identical(title, _copyWithSentinel)
          ? this.title
          : title as String?,
      body: identical(body, _copyWithSentinel) ? this.body : body as String?,
      status: identical(status, _copyWithSentinel)
          ? this.status
          : status as String?,
      rating: identical(rating, _copyWithSentinel)
          ? this.rating
          : rating as double?,
      priority: identical(priority, _copyWithSentinel)
          ? this.priority
          : priority as int?,
      publishedAt: identical(publishedAt, _copyWithSentinel)
          ? this.publishedAt
          : publishedAt as DateTime?,
      reviewedAt: identical(reviewedAt, _copyWithSentinel)
          ? this.reviewedAt
          : reviewedAt as DateTime?,
      categoryId: identical(categoryId, _copyWithSentinel)
          ? this.categoryId
          : categoryId as int?,
    );
  }
}

class _ArticlePartialCopyWithSentinel {
  const _ArticlePartialCopyWithSentinel();
}

/// Generated tracked model class for [Article].
///
/// This class extends the user-defined [Article] model and adds
/// attribute tracking, change detection, and relationship management.
/// Instances of this class are returned by queries and repositories.
///
/// **Do not instantiate this class directly.** Use queries, repositories,
/// or model factories to create tracked model instances.
class $Article extends Article with ModelAttributes implements OrmEntity {
  /// Internal constructor for [$Article].
  $Article({
    int id = 0,
    required String title,
    String? body,
    required String status,
    required double rating,
    required int priority,
    required DateTime publishedAt,
    DateTime? reviewedAt,
    required int categoryId,
  }) : super.new(
         id: id,
         title: title,
         body: body,
         status: status,
         rating: rating,
         priority: priority,
         publishedAt: publishedAt,
         reviewedAt: reviewedAt,
         categoryId: categoryId,
       ) {
    _attachOrmRuntimeMetadata({
      'id': id,
      'title': title,
      'body': body,
      'status': status,
      'rating': rating,
      'priority': priority,
      'published_at': publishedAt,
      'reviewed_at': reviewedAt,
      'category_id': categoryId,
    });
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $Article.fromModel(Article model) {
    return $Article(
      id: model.id,
      title: model.title,
      body: model.body,
      status: model.status,
      rating: model.rating,
      priority: model.priority,
      publishedAt: model.publishedAt,
      reviewedAt: model.reviewedAt,
      categoryId: model.categoryId,
    );
  }

  $Article copyWith({
    int? id,
    String? title,
    String? body,
    String? status,
    double? rating,
    int? priority,
    DateTime? publishedAt,
    DateTime? reviewedAt,
    int? categoryId,
  }) {
    return $Article(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      status: status ?? this.status,
      rating: rating ?? this.rating,
      priority: priority ?? this.priority,
      publishedAt: publishedAt ?? this.publishedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      categoryId: categoryId ?? this.categoryId,
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

  /// Tracked getter for [body].
  @override
  String? get body => getAttribute<String?>('body') ?? super.body;

  /// Tracked setter for [body].
  set body(String? value) => setAttribute('body', value);

  /// Tracked getter for [status].
  @override
  String get status => getAttribute<String>('status') ?? super.status;

  /// Tracked setter for [status].
  set status(String value) => setAttribute('status', value);

  /// Tracked getter for [rating].
  @override
  double get rating => getAttribute<double>('rating') ?? super.rating;

  /// Tracked setter for [rating].
  set rating(double value) => setAttribute('rating', value);

  /// Tracked getter for [priority].
  @override
  int get priority => getAttribute<int>('priority') ?? super.priority;

  /// Tracked setter for [priority].
  set priority(int value) => setAttribute('priority', value);

  /// Tracked getter for [publishedAt].
  @override
  DateTime get publishedAt =>
      getAttribute<DateTime>('published_at') ?? super.publishedAt;

  /// Tracked setter for [publishedAt].
  set publishedAt(DateTime value) => setAttribute('published_at', value);

  /// Tracked getter for [reviewedAt].
  @override
  DateTime? get reviewedAt =>
      getAttribute<DateTime?>('reviewed_at') ?? super.reviewedAt;

  /// Tracked setter for [reviewedAt].
  set reviewedAt(DateTime? value) => setAttribute('reviewed_at', value);

  /// Tracked getter for [categoryId].
  @override
  int get categoryId => getAttribute<int>('category_id') ?? super.categoryId;

  /// Tracked setter for [categoryId].
  set categoryId(int value) => setAttribute('category_id', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$ArticleDefinition);
  }
}

extension ArticleOrmExtension on Article {
  /// The Type of the generated ORM-managed model class.
  /// Use this when you need to specify the tracked model type explicitly,
  /// for example in generic type parameters.
  static Type get trackedType => $Article;

  /// Converts this immutable model to a tracked ORM-managed model.
  /// The tracked model supports attribute tracking, change detection,
  /// and persistence operations like save() and touch().
  $Article toTracked() {
    return $Article.fromModel(this);
  }
}

void registerArticleEventHandlers(EventBus bus) {
  // No event handlers registered for Article.
}
