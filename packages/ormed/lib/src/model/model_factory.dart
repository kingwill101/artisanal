import 'dart:async';
import 'dart:math';

import 'package:carbonized/carbonized.dart';

import '../contracts.dart';
import '../query/query.dart';
import '../value_codec.dart';
import 'model.dart';

/// Model factories for generating test data and seed records.
///
/// Generated model helpers typically expose a `factory()` method that returns a
/// [ModelFactoryBuilder]. Use it to configure and build models with predictable
/// data.
///
/// ```dart
/// // Create an in-memory model instance.
/// final user = User.factory().make();
///
/// // Persist a model (requires a QueryContext).
/// final saved = await User.factory().create(context: ctx);
///
/// // Create multiple records with overrides.
/// final users = await User.factory()
///     .count(3)
///     .withField('is_active', true)
///     .createMany(context: ctx);
/// ```
///
/// {@macro ormed.model.connection_setup}
///
/// Signature for state transformation closures.
typedef StateTransformer<TModel extends OrmEntity> =
    Map<String, Object?> Function(Map<String, Object?> attributes);

/// Signature for sequence generators.
typedef SequenceGenerator = Map<String, Object?> Function(int index);

/// Context passed to generators while building factory output.
class ModelFactoryGenerationContext<TModel extends OrmEntity> {
  ModelFactoryGenerationContext({
    required this.definition,
    required this.random,
    required this.overrides,
    this.seed,
  });

  /// The model definition being generated.
  final ModelDefinition<TModel> definition;

  /// RNG used for this generation pass.
  final Random random;

  /// Canonicalized field overrides applied before generating defaults.
  final Map<String, Object?> overrides;

  /// Seed used for deterministic output, when set.
  final int? seed;
}

/// Signature used to generate a field value for a factory.
typedef FieldValueGenerator<TModel extends OrmEntity> =
    Object? Function(
      FieldDefinition field,
      ModelFactoryGenerationContext<TModel> context,
    );

/// Provides backend-aware fallbacks when no bespoke generator is supplied.
abstract class GeneratorProvider {
  const GeneratorProvider();

  /// Generates a default value for [field].
  ///
  /// Return `null` to omit a value (for example, to let the database apply a
  /// default).
  Object? generate<TModel extends OrmEntity>(
    FieldDefinition field,
    ModelFactoryGenerationContext<TModel> context,
  );
}

/// Default generator that returns simple primitives for common scalar fields.
///
/// This is used when no per-field generator is provided.
class DefaultFieldGeneratorProvider extends GeneratorProvider {
  const DefaultFieldGeneratorProvider();

  @override
  Object? generate<TModel extends OrmEntity>(
    FieldDefinition field,
    ModelFactoryGenerationContext<TModel> context,
  ) {
    if (field.isNullable && context.random.nextBool()) {
      return null;
    }
    final type = _stripNullability(field.resolvedType);
    if (type == 'int') {
      return context.random.nextInt(1000) + 1;
    }
    if (type == 'double' || type == 'num') {
      return context.random.nextDouble() * 1000;
    }
    if (type == 'bool') {
      return context.random.nextBool();
    }
    if (type == 'DateTime') {
      return DateTime.now().toUtc().add(
        Duration(seconds: context.random.nextInt(60 * 60 * 24)),
      );
    }
    if (type == 'Carbon' || type == 'CarbonInterface') {
      return Carbon.now().addSeconds(context.random.nextInt(60 * 60 * 24));
    }
    if (type == 'String') {
      final suffix = context.random.nextInt(10000).toString().padLeft(4, '0');
      return '${context.definition.modelName}_${field.name}_$suffix';
    }
    if (type.startsWith('Map<')) {
      return <String, Object?>{};
    }
    if (type.startsWith('List<')) {
      return <Object?>[];
    }
    return null;
  }

  static String _stripNullability(String type) {
    return type.endsWith('?') ? type.substring(0, type.length - 1) : type;
  }
}

/// Base class for defining external factory behavior.
///
/// Override [defaults], [states], and [configure] to customize model generation.
abstract class ModelFactoryDefinition<TModel extends OrmEntity> {
  const ModelFactoryDefinition();

  /// The model definition backing this factory.
  ModelDefinition<TModel> get definition =>
      ModelFactoryRegistry.definitionFor<TModel>();

  /// Optional generator provider to use when no override is supplied.
  GeneratorProvider? get generatorProvider => null;

  /// Base attributes applied to every factory instance.
  Map<String, Object?> defaults() => const {};

  /// Named state transformations that can be applied on demand.
  Map<String, StateTransformer<TModel>> get states =>
      <String, StateTransformer<TModel>>{};

  /// Hook for configuring the builder (sequences, callbacks, etc).
  void configure(ModelFactoryBuilder<TModel> builder) {}

  /// Creates a builder pre-configured with defaults and hooks.
  ModelFactoryBuilder<TModel> builder({GeneratorProvider? generatorProvider}) {
    final builder = ModelFactoryBuilder<TModel>(
      definition: definition,
      generatorProvider: generatorProvider ?? this.generatorProvider,
    );
    final defaultAttributes = defaults();
    if (defaultAttributes.isNotEmpty) {
      builder.state(defaultAttributes);
    }
    configure(builder);
    return builder;
  }

  /// Creates a builder with a named state applied.
  ModelFactoryBuilder<TModel> stateNamed(
    String name, {
    GeneratorProvider? generatorProvider,
  }) {
    final state = states[name];
    if (state == null) {
      throw StateError('No factory state named "$name" for $TModel.');
    }
    return builder(generatorProvider: generatorProvider).stateUsing(state);
  }
}

/// Builder used by generated factory helpers.
///
/// Configure the builder using [state], [sequence], and [withOverrides], then
/// call [make] / [makeMany] to instantiate models or [create] / [createMany] to
/// persist them.
///
/// {@macro ormed.model.connection_setup}
class ModelFactoryBuilder<TModel extends OrmEntity> {
  ModelFactoryBuilder({
    required this.definition,
    GeneratorProvider? generatorProvider,
  }) : _generatorProvider =
           generatorProvider ?? const DefaultFieldGeneratorProvider();

  final ModelDefinition<TModel> definition;
  final GeneratorProvider _generatorProvider;

  final Map<String, Object?> _overrides = {};
  final Map<String, FieldValueGenerator<TModel>> _fieldGenerators = {};
  final List<StateTransformer<TModel>> _stateTransformers = [];
  final List<void Function(TModel)> _afterMakingCallbacks = [];
  final List<FutureOr<void> Function(TModel)> _afterCreatingCallbacks = [];

  int? _seed;
  int? _count;
  List<Map<String, Object?>>? _sequence;
  SequenceGenerator? _sequenceGenerator;
  bool _trashed = false;
  DateTime? _trashedAt;
  Map<String, Object?>? _generatedValues;
  Random? _random;

  /// Clears generated values so the next call can pick new ones.
  ModelFactoryBuilder<TModel> reset() {
    _invalidate();
    return this;
  }

  /// Sets a deterministic seed for the factory output.
  ModelFactoryBuilder<TModel> seed(int seed) {
    _seed = seed;
    _invalidate();
    return this;
  }

  /// Sets the number of models to create.
  ///
  /// When count > 1, use [makeMany] or [createMany] to get a list.
  ModelFactoryBuilder<TModel> count(int count) {
    if (count < 1) {
      throw ArgumentError.value(count, 'count', 'Must be at least 1');
    }
    _count = count;
    return this;
  }

  /// Applies a state transformation using a map of attributes.
  ///
  /// Multiple states can be chained and will be applied in order.
  ModelFactoryBuilder<TModel> state(Map<String, Object?> attributes) {
    _stateTransformers.add((_) => attributes);
    _invalidate();
    return this;
  }

  /// Applies a state transformation using a closure.
  ///
  /// The closure receives the current attributes and returns modifications.
  ModelFactoryBuilder<TModel> stateUsing(StateTransformer<TModel> transformer) {
    _stateTransformers.add(transformer);
    _invalidate();
    return this;
  }

  /// Defines a sequence of attribute sets to cycle through when creating multiple models.
  ///
  /// Each model will use the next set in the sequence (wrapping around).
  ModelFactoryBuilder<TModel> sequence(List<Map<String, Object?>> states) {
    if (states.isEmpty) {
      throw ArgumentError.value(states, 'states', 'Must not be empty');
    }
    _sequence = states;
    _sequenceGenerator = null;
    return this;
  }

  /// Defines a sequence using a generator function.
  ///
  /// The function receives the index (0-based) and returns attributes.
  ModelFactoryBuilder<TModel> sequenceUsing(SequenceGenerator generator) {
    _sequenceGenerator = generator;
    _sequence = null;
    return this;
  }

  /// Registers a callback to run after each model is made (but not persisted).
  ModelFactoryBuilder<TModel> afterMaking(
    void Function(TModel model) callback,
  ) {
    _afterMakingCallbacks.add(callback);
    return this;
  }

  /// Registers a callback to run after each model is created and persisted.
  ModelFactoryBuilder<TModel> afterCreating(
    FutureOr<void> Function(TModel model) callback,
  ) {
    _afterCreatingCallbacks.add(callback);
    return this;
  }

  /// Marks the model as soft-deleted.
  ///
  /// Only works for models with soft delete support.
  ModelFactoryBuilder<TModel> trashed([DateTime? deletedAt]) {
    _trashed = true;
    _trashedAt = deletedAt;
    _invalidate();
    return this;
  }

  /// Supplies field overrides by column name or attribute name.
  ModelFactoryBuilder<TModel> withOverrides(Map<String, Object?> overrides) {
    for (final entry in overrides.entries) {
      final column = _canonicalColumn(entry.key);
      _overrides[column] = entry.value;
    }
    _invalidate();
    return this;
  }

  /// Overrides a single field by column or attribute name.
  ModelFactoryBuilder<TModel> withField(String field, Object? value) {
    return withOverrides({field: value});
  }

  /// Replaces the generator used for a given field by column or attribute name.
  ModelFactoryBuilder<TModel> withGenerator(
    String field,
    FieldValueGenerator<TModel> generator,
  ) {
    final column = _canonicalColumn(field);
    _fieldGenerators[column] = generator;
    _invalidate();
    return this;
  }

  /// Builds the column map the factory would use for a new model.
  ///
  /// This returns the values for index 0 (first model) including all state
  /// transformations and trashed status.
  Map<String, Object?> values() {
    return _valuesForIndex(0);
  }

  /// Returns a single column value from the generated map.
  Object? value(String field) {
    final column = _canonicalColumn(field);
    return values()[column];
  }

  /// Instantiates a single model without persisting it.
  ///
  /// If [count] was set, this returns the first model only. Use [makeMany] to
  /// get all models when count > 1.
  TModel make({ValueCodecRegistry? registry}) {
    final payload = values();
    final model = definition.fromMap(payload, registry: registry);
    _runAfterMakingCallbacks(model);
    return model;
  }

  /// Instantiates multiple models without persisting them.
  ///
  /// Returns a list with [count] models (defaults to 1 if count not set).
  List<TModel> makeMany({ValueCodecRegistry? registry}) {
    final total = _count ?? 1;
    final models = <TModel>[];
    for (var i = 0; i < total; i++) {
      final payload = _valuesForIndex(i);
      final model = definition.fromMap(payload, registry: registry);
      _runAfterMakingCallbacks(model);
      models.add(model);
    }
    return models;
  }

  /// Persists a single generated model through the ORM.
  ///
  /// If [count] was set, this creates and returns only the first model. Use
  /// [createMany] to persist all models when count > 1.
  Future<TModel> create({
    QueryContext? context,
    bool returning = true,
    ValueCodecRegistry? registry,
  }) async {
    final model = make(registry: registry);
    if (context != null && model is Model) {
      model.attachConnectionResolver(context);
    }
    if (model is Model) {
      final saved = await model.save(returning: returning) as TModel;
      await _runAfterCreatingCallbacks(saved);
      return saved;
    }
    throw StateError(
      'Cannot persist $TModel because it does not extend Model.',
    );
  }

  /// Persists multiple generated models through the ORM.
  ///
  /// Returns a list with [count] persisted models (defaults to 1 if count not set).
  Future<List<TModel>> createMany({
    QueryContext? context,
    bool returning = true,
    ValueCodecRegistry? registry,
  }) async {
    final total = _count ?? 1;
    final models = <TModel>[];
    for (var i = 0; i < total; i++) {
      final payload = _valuesForIndex(i);
      final model = definition.fromMap(payload, registry: registry);
      _runAfterMakingCallbacks(model);

      if (context != null && model is Model) {
        model.attachConnectionResolver(context);
      }
      if (model is Model) {
        final saved = await model.save(returning: returning) as TModel;
        await _runAfterCreatingCallbacks(saved);
        models.add(saved);
      } else {
        throw StateError(
          'Cannot persist $TModel because it does not extend Model.',
        );
      }
    }
    return models;
  }

  void _runAfterMakingCallbacks(TModel model) {
    for (final callback in _afterMakingCallbacks) {
      callback(model);
    }
  }

  Future<void> _runAfterCreatingCallbacks(TModel model) async {
    for (final callback in _afterCreatingCallbacks) {
      await callback(model);
    }
  }

  /// Generates values for a specific index (used for sequences and batch creation).
  ///
  /// For index 0, uses cached values. For index > 0, generates fresh values.
  Map<String, Object?> _valuesForIndex(int index) {
    // For batch creation (index > 0), we need fresh random values
    // For index 0, we can use cached values for consistency
    if (index > 0) {
      _generatedValues = null;
      _random = null;
    }

    // Apply sequence overrides for this index
    Map<String, Object?>? sequenceOverrides;
    if (_sequence != null && _sequence!.isNotEmpty) {
      sequenceOverrides = _sequence![index % _sequence!.length];
    } else if (_sequenceGenerator != null) {
      sequenceOverrides = _sequenceGenerator!(index);
    }

    // Generate base values
    _ensureValues();
    var result = Map<String, Object?>.from(_generatedValues!);

    // Apply state transformers
    for (final transformer in _stateTransformers) {
      final stateOverrides = transformer(result);
      for (final entry in stateOverrides.entries) {
        final column = _canonicalColumn(entry.key);
        result[column] = entry.value;
      }
    }

    // Apply sequence overrides
    if (sequenceOverrides != null) {
      for (final entry in sequenceOverrides.entries) {
        final column = _canonicalColumn(entry.key);
        result[column] = entry.value;
      }
    }

    // Apply trashed state
    if (_trashed) {
      final softDeleteColumn = definition.softDeleteColumn;
      if (softDeleteColumn != null) {
        result[softDeleteColumn] = _trashedAt ?? DateTime.now().toUtc();
      }
    }

    return result;
  }

  void _ensureValues() {
    if (_generatedValues != null) return;
    _random ??= _seed != null ? Random(_seed!) : Random();
    final context = ModelFactoryGenerationContext<TModel>(
      definition: definition,
      random: _random!,
      overrides: Map<String, Object?>.unmodifiable(_overrides),
      seed: _seed,
    );
    final values = <String, Object?>{};
    values.addAll(_overrides);
    for (final field in definition.fields) {
      final column = field.columnName;
      if (values.containsKey(column)) {
        continue;
      }
      if (!_shouldGenerateField(field)) {
        continue;
      }
      final generator =
          _fieldGenerators[column] ?? _fieldGenerators[field.name];
      final value = generator != null
          ? generator(field, context)
          : _generatorProvider.generate(field, context);
      values[column] = value;
    }
    _generatedValues = values;
  }

  bool _shouldGenerateField(FieldDefinition field) {
    if (field.autoIncrement && !_overrides.containsKey(field.columnName)) {
      return false;
    }
    if (field.defaultValueSql != null &&
        !_overrides.containsKey(field.columnName)) {
      return false;
    }
    if (field.codecType != null && !_overrides.containsKey(field.columnName)) {
      return false;
    }
    return true;
  }

  String _canonicalColumn(String key) {
    final fieldByName = definition.fieldByName(key);
    if (fieldByName != null) {
      return fieldByName.columnName;
    }
    final fieldByColumn = definition.fieldByColumn(key);
    if (fieldByColumn != null) {
      return fieldByColumn.columnName;
    }
    return key;
  }

  void _invalidate() {
    _generatedValues = null;
    _random = null;
  }
}

/// Internal registry that associates models with their generated definitions.
class ModelFactoryRegistry {
  ModelFactoryRegistry._();

  static final Map<Type, ModelDefinition<OrmEntity>> _definitions = {};
  static final Map<Type, ModelFactoryDefinition<OrmEntity>> _externalFactories =
      {};

  /// Registers [definition] for `TModel`.
  ///
  /// Generated code calls this during initialization.
  static ModelDefinition<TModel> register<TModel extends OrmEntity>(
    ModelDefinition<TModel> definition,
  ) {
    _definitions[TModel] = definition;
    return definition;
  }

  /// Registers a definition only if one is not already registered for the type.
  /// Returns the existing or newly registered definition.
  static ModelDefinition<TModel> registerIfAbsent<TModel extends OrmEntity>(
    ModelDefinition<TModel> definition,
  ) {
    return _definitions.putIfAbsent(TModel, () => definition)
        as ModelDefinition<TModel>;
  }

  /// Registers an external factory definition for `TModel`.
  static ModelFactoryDefinition<TModel> registerFactory<
    TModel extends OrmEntity
  >(
    ModelFactoryDefinition<TModel> factory,
  ) {
    _externalFactories[TModel] = factory;
    return factory;
  }

  /// Returns the registered external factory for `TModel`, if any.
  static ModelFactoryDefinition<TModel>? externalFactoryFor<
    TModel extends OrmEntity
  >() {
    final factory = _externalFactories[TModel];
    if (factory == null) return null;
    return factory as ModelFactoryDefinition<TModel>;
  }

  /// Returns a factory builder for `TModel`, preferring external factories.
  static ModelFactoryBuilder<TModel> factoryFor<TModel extends OrmEntity>({
    GeneratorProvider? generatorProvider,
  }) {
    final external = externalFactoryFor<TModel>();
    if (external != null) {
      return external.builder(generatorProvider: generatorProvider);
    }
    final definition = definitionFor<TModel>();
    return ModelFactoryBuilder<TModel>(
      definition: definition,
      generatorProvider: generatorProvider,
    );
  }

  /// Returns the registered definition for `TModel`.
  ///
  /// Throws a [StateError] if the factory definition has not been registered.
  static ModelDefinition<TModel> definitionFor<TModel extends OrmEntity>() {
    final definition = _definitions[TModel];
    if (definition == null) {
      throw StateError(
        'No definition registered for $TModel. Ensure the generated '
        'ORM helper is imported so it can register itself.',
      );
    }
    return definition as ModelDefinition<TModel>;
  }
}
