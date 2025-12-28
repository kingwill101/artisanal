// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'generated_code_usage.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$DocumentIdField = FieldDefinition(
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

const FieldDefinition _$DocumentMetadataField = FieldDefinition(
  name: 'metadata',
  columnName: 'metadata',
  dartType: 'Map<String, Object?>',
  resolvedType: 'Map<String, Object?>?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
  codecType: 'JsonMapCodec',
);

Map<String, Object?> _encodeDocumentUntracked(
  Object model,
  ValueCodecRegistry registry,
) {
  final m = model as Document;
  return <String, Object?>{
    'id': registry.encodeField(_$DocumentIdField, m.id),
    'metadata': registry.encodeField(_$DocumentMetadataField, m.metadata),
  };
}

final ModelDefinition<$Document> _$DocumentDefinition = ModelDefinition(
  modelName: 'Document',
  tableName: 'documents',
  fields: const [_$DocumentIdField, _$DocumentMetadataField],
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
    softDeletes: false,
    softDeleteColumn: 'deleted_at',
  ),
  untrackedToMap: _encodeDocumentUntracked,
  codec: _$DocumentCodec(),
);

extension DocumentOrmDefinition on Document {
  static ModelDefinition<$Document> get definition => _$DocumentDefinition;
}

class Documents {
  const Documents._();

  /// Starts building a query for [$Document].
  ///
  /// {@macro ormed.query}
  static Query<$Document> query([String? connection]) =>
      Model.query<$Document>(connection: connection);

  static Future<$Document?> find(Object id, {String? connection}) =>
      Model.find<$Document>(id, connection: connection);

  static Future<$Document> findOrFail(Object id, {String? connection}) =>
      Model.findOrFail<$Document>(id, connection: connection);

  static Future<List<$Document>> all({String? connection}) =>
      Model.all<$Document>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<$Document>(connection: connection);

  static Future<bool> anyExist({String? connection}) =>
      Model.anyExist<$Document>(connection: connection);

  static Query<$Document> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) => Model.where<$Document>(column, operator, value, connection: connection);

  static Query<$Document> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<$Document>(column, values, connection: connection);

  static Query<$Document> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<$Document>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<$Document> limit(int count, {String? connection}) =>
      Model.limit<$Document>(count, connection: connection);

  /// Creates a [Repository] for [$Document].
  ///
  /// {@macro ormed.repository}
  static Repository<$Document> repo([String? connection]) =>
      Model.repository<$Document>(connection: connection);
}

class DocumentModelFactory {
  const DocumentModelFactory._();

  static ModelDefinition<$Document> get definition => _$DocumentDefinition;

  static ModelCodec<$Document> get codec => definition.codec;

  static Document fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    Document model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model.toTracked(), registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<Document> withConnection(
    QueryContext context,
  ) => ModelFactoryConnection<Document>(
    definition: definition,
    context: context,
  );

  static ModelFactoryBuilder<Document> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<Document>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$DocumentCodec extends ModelCodec<$Document> {
  const _$DocumentCodec();
  @override
  Map<String, Object?> encode($Document model, ValueCodecRegistry registry) {
    return <String, Object?>{
      'id': registry.encodeField(_$DocumentIdField, model.id),
      'metadata': registry.encodeField(_$DocumentMetadataField, model.metadata),
    };
  }

  @override
  $Document decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final int documentIdValue =
        registry.decodeField<int>(_$DocumentIdField, data['id']) ?? 0;
    final Map<String, Object?>? documentMetadataValue = registry
        .decodeField<Map<String, Object?>?>(
          _$DocumentMetadataField,
          data['metadata'],
        );
    final model = $Document(
      id: documentIdValue,
      metadata: documentMetadataValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': documentIdValue,
      'metadata': documentMetadataValue,
    });
    return model;
  }
}

/// Insert DTO for [Document].
///
/// Auto-increment/DB-generated fields are omitted by default.
class DocumentInsertDto implements InsertDto<$Document> {
  const DocumentInsertDto({this.metadata});
  final Map<String, Object?>? metadata;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{if (metadata != null) 'metadata': metadata};
  }

  static const _DocumentInsertDtoCopyWithSentinel _copyWithSentinel =
      _DocumentInsertDtoCopyWithSentinel();
  DocumentInsertDto copyWith({Object? metadata = _copyWithSentinel}) {
    return DocumentInsertDto(
      metadata: identical(metadata, _copyWithSentinel)
          ? this.metadata
          : metadata as Map<String, Object?>?,
    );
  }
}

class _DocumentInsertDtoCopyWithSentinel {
  const _DocumentInsertDtoCopyWithSentinel();
}

/// Update DTO for [Document].
///
/// All fields are optional; only provided entries are used in SET clauses.
class DocumentUpdateDto implements UpdateDto<$Document> {
  const DocumentUpdateDto({this.id, this.metadata});
  final int? id;
  final Map<String, Object?>? metadata;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (metadata != null) 'metadata': metadata,
    };
  }

  static const _DocumentUpdateDtoCopyWithSentinel _copyWithSentinel =
      _DocumentUpdateDtoCopyWithSentinel();
  DocumentUpdateDto copyWith({
    Object? id = _copyWithSentinel,
    Object? metadata = _copyWithSentinel,
  }) {
    return DocumentUpdateDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      metadata: identical(metadata, _copyWithSentinel)
          ? this.metadata
          : metadata as Map<String, Object?>?,
    );
  }
}

class _DocumentUpdateDtoCopyWithSentinel {
  const _DocumentUpdateDtoCopyWithSentinel();
}

/// Partial projection for [Document].
///
/// All fields are nullable; intended for subset SELECTs.
class DocumentPartial implements PartialEntity<$Document> {
  const DocumentPartial({this.id, this.metadata});

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory DocumentPartial.fromRow(Map<String, Object?> row) {
    return DocumentPartial(
      id: row['id'] as int?,
      metadata: row['metadata'] as Map<String, Object?>?,
    );
  }

  final int? id;
  final Map<String, Object?>? metadata;

  @override
  $Document toEntity() {
    // Basic required-field check: non-nullable fields must be present.
    final int? idValue = id;
    if (idValue == null) {
      throw StateError('Missing required field: id');
    }
    return $Document(id: idValue, metadata: metadata);
  }

  @override
  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      if (metadata != null) 'metadata': metadata,
    };
  }

  static const _DocumentPartialCopyWithSentinel _copyWithSentinel =
      _DocumentPartialCopyWithSentinel();
  DocumentPartial copyWith({
    Object? id = _copyWithSentinel,
    Object? metadata = _copyWithSentinel,
  }) {
    return DocumentPartial(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      metadata: identical(metadata, _copyWithSentinel)
          ? this.metadata
          : metadata as Map<String, Object?>?,
    );
  }
}

class _DocumentPartialCopyWithSentinel {
  const _DocumentPartialCopyWithSentinel();
}

/// Generated tracked model class for [Document].
///
/// This class extends the user-defined [Document] model and adds
/// attribute tracking, change detection, and relationship management.
/// Instances of this class are returned by queries and repositories.
///
/// **Do not instantiate this class directly.** Use queries, repositories,
/// or model factories to create tracked model instances.
class $Document extends Document with ModelAttributes implements OrmEntity {
  /// Internal constructor for [$Document].
  $Document({int id = 0, Map<String, Object?>? metadata})
    : super.new(id: id, metadata: metadata) {
    _attachOrmRuntimeMetadata({'id': id, 'metadata': metadata});
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $Document.fromModel(Document model) {
    return $Document(id: model.id, metadata: model.metadata);
  }

  $Document copyWith({int? id, Map<String, Object?>? metadata}) {
    return $Document(id: id ?? this.id, metadata: metadata ?? this.metadata);
  }

  /// Tracked getter for [id].
  @override
  int get id => getAttribute<int>('id') ?? super.id;

  /// Tracked setter for [id].
  set id(int value) => setAttribute('id', value);

  /// Tracked getter for [metadata].
  @override
  Map<String, Object?>? get metadata =>
      getAttribute<Map<String, Object?>?>('metadata') ?? super.metadata;

  /// Tracked setter for [metadata].
  set metadata(Map<String, Object?>? value) => setAttribute('metadata', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$DocumentDefinition);
  }
}

extension DocumentOrmExtension on Document {
  /// The Type of the generated ORM-managed model class.
  /// Use this when you need to specify the tracked model type explicitly,
  /// for example in generic type parameters.
  static Type get trackedType => $Document;

  /// Converts this immutable model to a tracked ORM-managed model.
  /// The tracked model supports attribute tracking, change detection,
  /// and persistence operations like save() and touch().
  $Document toTracked() {
    return $Document.fromModel(this);
  }
}

extension DocumentPredicateFields on PredicateBuilder<Document> {
  PredicateField<Document, int> get id =>
      PredicateField<Document, int>(this, 'id');
  PredicateField<Document, Map<String, Object?>?> get metadata =>
      PredicateField<Document, Map<String, Object?>?>(this, 'metadata');
}

void registerDocumentEventHandlers(EventBus bus) {
  // No event handlers registered for Document.
}
