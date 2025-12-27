// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'event_model.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$EventModelIdField = FieldDefinition(
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

const FieldDefinition _$EventModelNameField = FieldDefinition(
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

const FieldDefinition _$EventModelScoreField = FieldDefinition(
  name: 'score',
  columnName: 'score',
  dartType: 'int',
  resolvedType: 'int',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$EventModelDeletedAtField = FieldDefinition(
  name: 'deletedAt',
  columnName: 'deleted_at',
  dartType: 'DateTime',
  resolvedType: 'DateTime?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

Map<String, Object?> _encodeEventModelUntracked(
  Object model,
  ValueCodecRegistry registry,
) {
  final m = model as EventModel;
  return <String, Object?>{
    'id': registry.encodeField(_$EventModelIdField, m.id),
    'name': registry.encodeField(_$EventModelNameField, m.name),
    'score': registry.encodeField(_$EventModelScoreField, m.score),
  };
}

final ModelDefinition<$EventModel> _$EventModelDefinition = ModelDefinition(
  modelName: 'EventModel',
  tableName: 'event_models',
  fields: const [
    _$EventModelIdField,
    _$EventModelNameField,
    _$EventModelScoreField,
    _$EventModelDeletedAtField,
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
    touches: const <String>[],
    timestamps: true,
    softDeletes: true,
    softDeleteColumn: 'deleted_at',
  ),
  untrackedToMap: _encodeEventModelUntracked,
  codec: _$EventModelCodec(),
);

// ignore: unused_element
final eventmodelModelDefinitionRegistration =
    ModelFactoryRegistry.register<$EventModel>(_$EventModelDefinition);

extension EventModelOrmDefinition on EventModel {
  static ModelDefinition<$EventModel> get definition => _$EventModelDefinition;
}

class EventModels {
  const EventModels._();

  /// Starts building a query for [$EventModel].
  ///
  /// {@macro ormed.query}
  static Query<$EventModel> query([String? connection]) =>
      Model.query<$EventModel>(connection: connection);

  static Future<$EventModel?> find(Object id, {String? connection}) =>
      Model.find<$EventModel>(id, connection: connection);

  static Future<$EventModel> findOrFail(Object id, {String? connection}) =>
      Model.findOrFail<$EventModel>(id, connection: connection);

  static Future<List<$EventModel>> all({String? connection}) =>
      Model.all<$EventModel>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<$EventModel>(connection: connection);

  static Future<bool> anyExist({String? connection}) =>
      Model.anyExist<$EventModel>(connection: connection);

  static Query<$EventModel> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) =>
      Model.where<$EventModel>(column, operator, value, connection: connection);

  static Query<$EventModel> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<$EventModel>(column, values, connection: connection);

  static Query<$EventModel> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<$EventModel>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<$EventModel> limit(int count, {String? connection}) =>
      Model.limit<$EventModel>(count, connection: connection);

  /// Creates a [Repository] for [$EventModel].
  ///
  /// {@macro ormed.repository}
  static Repository<$EventModel> repo([String? connection]) =>
      Model.repository<$EventModel>(connection: connection);
}

class EventModelFactory {
  const EventModelFactory._();

  static ModelDefinition<$EventModel> get definition => _$EventModelDefinition;

  static ModelCodec<$EventModel> get codec => definition.codec;

  static EventModel fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    EventModel model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model.toTracked(), registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<EventModel> withConnection(
    QueryContext context,
  ) => ModelFactoryConnection<EventModel>(
    definition: definition,
    context: context,
  );

  static ModelFactoryBuilder<EventModel> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<EventModel>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$EventModelCodec extends ModelCodec<$EventModel> {
  const _$EventModelCodec();
  @override
  Map<String, Object?> encode($EventModel model, ValueCodecRegistry registry) {
    return <String, Object?>{
      'id': registry.encodeField(_$EventModelIdField, model.id),
      'name': registry.encodeField(_$EventModelNameField, model.name),
      'score': registry.encodeField(_$EventModelScoreField, model.score),
      if (model.hasAttribute('deleted_at'))
        'deleted_at': registry.encodeField(
          _$EventModelDeletedAtField,
          model.getAttribute<DateTime?>('deleted_at'),
        ),
    };
  }

  @override
  $EventModel decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final int eventModelIdValue =
        registry.decodeField<int>(_$EventModelIdField, data['id']) ?? 0;
    final String eventModelNameValue =
        registry.decodeField<String>(_$EventModelNameField, data['name']) ??
        (throw StateError('Field name on EventModel cannot be null.'));
    final int eventModelScoreValue =
        registry.decodeField<int>(_$EventModelScoreField, data['score']) ??
        (throw StateError('Field score on EventModel cannot be null.'));
    final DateTime? eventModelDeletedAtValue = registry.decodeField<DateTime?>(
      _$EventModelDeletedAtField,
      data['deleted_at'],
    );
    final model = $EventModel(
      id: eventModelIdValue,
      name: eventModelNameValue,
      score: eventModelScoreValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': eventModelIdValue,
      'name': eventModelNameValue,
      'score': eventModelScoreValue,
      if (data.containsKey('deleted_at'))
        'deleted_at': eventModelDeletedAtValue,
    });
    return model;
  }
}

/// Insert DTO for [EventModel].
///
/// Auto-increment/DB-generated fields are omitted by default.
class EventModelInsertDto implements InsertDto<$EventModel> {
  const EventModelInsertDto({this.name, this.score});
  final String? name;
  final int? score;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (name != null) 'name': name,
      if (score != null) 'score': score,
    };
  }

  static const _EventModelInsertDtoCopyWithSentinel _copyWithSentinel =
      _EventModelInsertDtoCopyWithSentinel();
  EventModelInsertDto copyWith({
    Object? name = _copyWithSentinel,
    Object? score = _copyWithSentinel,
  }) {
    return EventModelInsertDto(
      name: identical(name, _copyWithSentinel) ? this.name : name as String?,
      score: identical(score, _copyWithSentinel) ? this.score : score as int?,
    );
  }
}

class _EventModelInsertDtoCopyWithSentinel {
  const _EventModelInsertDtoCopyWithSentinel();
}

/// Update DTO for [EventModel].
///
/// All fields are optional; only provided entries are used in SET clauses.
class EventModelUpdateDto implements UpdateDto<$EventModel> {
  const EventModelUpdateDto({this.id, this.name, this.score});
  final int? id;
  final String? name;
  final int? score;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (score != null) 'score': score,
    };
  }

  static const _EventModelUpdateDtoCopyWithSentinel _copyWithSentinel =
      _EventModelUpdateDtoCopyWithSentinel();
  EventModelUpdateDto copyWith({
    Object? id = _copyWithSentinel,
    Object? name = _copyWithSentinel,
    Object? score = _copyWithSentinel,
  }) {
    return EventModelUpdateDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      name: identical(name, _copyWithSentinel) ? this.name : name as String?,
      score: identical(score, _copyWithSentinel) ? this.score : score as int?,
    );
  }
}

class _EventModelUpdateDtoCopyWithSentinel {
  const _EventModelUpdateDtoCopyWithSentinel();
}

/// Partial projection for [EventModel].
///
/// All fields are nullable; intended for subset SELECTs.
class EventModelPartial implements PartialEntity<$EventModel> {
  const EventModelPartial({this.id, this.name, this.score});

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory EventModelPartial.fromRow(Map<String, Object?> row) {
    return EventModelPartial(
      id: row['id'] as int?,
      name: row['name'] as String?,
      score: row['score'] as int?,
    );
  }

  final int? id;
  final String? name;
  final int? score;

  @override
  $EventModel toEntity() {
    // Basic required-field check: non-nullable fields must be present.
    final int? idValue = id;
    if (idValue == null) {
      throw StateError('Missing required field: id');
    }
    final String? nameValue = name;
    if (nameValue == null) {
      throw StateError('Missing required field: name');
    }
    final int? scoreValue = score;
    if (scoreValue == null) {
      throw StateError('Missing required field: score');
    }
    return $EventModel(id: idValue, name: nameValue, score: scoreValue);
  }

  @override
  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (score != null) 'score': score,
    };
  }

  static const _EventModelPartialCopyWithSentinel _copyWithSentinel =
      _EventModelPartialCopyWithSentinel();
  EventModelPartial copyWith({
    Object? id = _copyWithSentinel,
    Object? name = _copyWithSentinel,
    Object? score = _copyWithSentinel,
  }) {
    return EventModelPartial(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      name: identical(name, _copyWithSentinel) ? this.name : name as String?,
      score: identical(score, _copyWithSentinel) ? this.score : score as int?,
    );
  }
}

class _EventModelPartialCopyWithSentinel {
  const _EventModelPartialCopyWithSentinel();
}

/// Generated tracked model class for [EventModel].
///
/// This class extends the user-defined [EventModel] model and adds
/// attribute tracking, change detection, and relationship management.
/// Instances of this class are returned by queries and repositories.
///
/// **Do not instantiate this class directly.** Use queries, repositories,
/// or model factories to create tracked model instances.
class $EventModel extends EventModel
    with ModelAttributes, SoftDeletesImpl
    implements OrmEntity {
  /// Internal constructor for [$EventModel].
  $EventModel({int id = 0, required String name, required int score})
    : super.new(id: id, name: name, score: score) {
    _attachOrmRuntimeMetadata({'id': id, 'name': name, 'score': score});
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $EventModel.fromModel(EventModel model) {
    return $EventModel(id: model.id, name: model.name, score: model.score);
  }

  $EventModel copyWith({int? id, String? name, int? score}) {
    return $EventModel(
      id: id ?? this.id,
      name: name ?? this.name,
      score: score ?? this.score,
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

  /// Tracked getter for [score].
  @override
  int get score => getAttribute<int>('score') ?? super.score;

  /// Tracked setter for [score].
  set score(int value) => setAttribute('score', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$EventModelDefinition);
    attachSoftDeleteColumn('deleted_at');
  }
}

extension EventModelOrmExtension on EventModel {
  /// The Type of the generated ORM-managed model class.
  /// Use this when you need to specify the tracked model type explicitly,
  /// for example in generic type parameters.
  static Type get trackedType => $EventModel;

  /// Converts this immutable model to a tracked ORM-managed model.
  /// The tracked model supports attribute tracking, change detection,
  /// and persistence operations like save() and touch().
  $EventModel toTracked() {
    return $EventModel.fromModel(this);
  }
}

void registerEventModelEventHandlers(EventBus bus) {
  bus.on<ModelSavingEvent>((event) {
    if (event.modelType != EventModel && event.modelType != $EventModel) {
      return;
    }
    EventModel.onSaving(event);
  });
  bus.on<ModelCreatingEvent>((event) {
    if (event.modelType != EventModel && event.modelType != $EventModel) {
      return;
    }
    EventModel.onCreating(event);
  });
  bus.on<ModelCreatedEvent>((event) {
    if (event.modelType != EventModel && event.modelType != $EventModel) {
      return;
    }
    EventModel.onCreated(event);
  });
  bus.on<ModelSavedEvent>((event) {
    if (event.modelType != EventModel && event.modelType != $EventModel) {
      return;
    }
    EventModel.onSaved(event);
  });
  bus.on<ModelUpdatingEvent>((event) {
    if (event.modelType != EventModel && event.modelType != $EventModel) {
      return;
    }
    EventModel.onUpdating(event);
  });
  bus.on<ModelUpdatedEvent>((event) {
    if (event.modelType != EventModel && event.modelType != $EventModel) {
      return;
    }
    EventModel.onUpdated(event);
  });
  bus.on<ModelDeletingEvent>((event) {
    if (event.modelType != EventModel && event.modelType != $EventModel) {
      return;
    }
    EventModel.onDeleting(event);
  });
  bus.on<ModelDeletedEvent>((event) {
    if (event.modelType != EventModel && event.modelType != $EventModel) {
      return;
    }
    EventModel.onDeleted(event);
  });
  bus.on<ModelRestoringEvent>((event) {
    if (event.modelType != EventModel && event.modelType != $EventModel) {
      return;
    }
    EventModel.onRestoring(event);
  });
  bus.on<ModelRestoredEvent>((event) {
    if (event.modelType != EventModel && event.modelType != $EventModel) {
      return;
    }
    EventModel.onRestored(event);
  });
  bus.on<ModelTrashedEvent>((event) {
    if (event.modelType != EventModel && event.modelType != $EventModel) {
      return;
    }
    EventModel.onTrashed(event);
  });
  bus.on<ModelForceDeletedEvent>((event) {
    if (event.modelType != EventModel && event.modelType != $EventModel) {
      return;
    }
    EventModel.onForceDeleted(event);
  });
  bus.on<ModelReplicatingEvent>((event) {
    if (event.modelType != EventModel && event.modelType != $EventModel) {
      return;
    }
    EventModel.onReplicating(event);
  });
  bus.on<ModelRetrievedEvent>((event) {
    if (event.modelType != EventModel && event.modelType != $EventModel) {
      return;
    }
    EventModel.onRetrieved(event);
  });
}
