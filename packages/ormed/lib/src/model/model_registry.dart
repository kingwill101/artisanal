import 'dart:async';

import '../contracts.dart';
import '../exceptions.dart';
import 'model.dart';

/// Registry that stores [ModelDefinition] objects by model type and name.
///
/// A [ModelRegistry] is used by [QueryContext] and [DataSource] to resolve
/// model metadata at runtime.
///
/// Generated `.orm.dart` files typically register definitions on startup,
/// and [DataSource.init] registers the definitions provided in
/// [DataSourceOptions.entities].
///
/// ```dart
/// final registry = ModelRegistry();
/// registry.register<$User>($UserOrmDefinition.definition);
///
/// final userDef = registry.expect<$User>();
/// print(userDef.tableName);
/// ```
class ModelRegistry {
  final Map<Type, ModelDefinition<OrmEntity>> _definitions = {};
  final Map<String, ModelDefinition<OrmEntity>> _definitionsByName = {};
  final Map<String, ModelDefinition<OrmEntity>> _definitionsByTable = {};
  final Map<String, ModelDefinition<OrmEntity>> _morphDefinitions = {};
  final StreamController<ModelDefinition<OrmEntity>> _onRegistered =
      StreamController.broadcast();
  final List<void Function(ModelDefinition<OrmEntity>)> _onRegisteredCallbacks =
      [];

  /// Stream of definitions as they are registered.
  Stream<ModelDefinition<OrmEntity>> get onRegistered => _onRegistered.stream;

  /// Registers a callback that is invoked when a definition is registered.
  void addOnRegisteredCallback(
    void Function(ModelDefinition<OrmEntity>) callback,
  ) {
    _onRegisteredCallbacks.add(callback);
  }

  /// Registers [definition] for type [T].
  ///
  /// This is a no-op when a definition is already registered for the model type.
  void register<T extends OrmEntity>(ModelDefinition<T> definition) {
    if (_definitions.containsKey(definition.modelType)) {
      return; // Skip already registered types
    }
    _definitions[definition.modelType] = definition;
    _definitionsByName[definition.modelName] = definition;
    _definitionsByTable[definition.tableName] = definition;
    _onRegistered.add(definition);
    for (final callback in _onRegisteredCallbacks) {
      callback(definition);
    }
  }

  /// Registers many model definitions.
  ///
  /// Definitions are deduplicated by model type.
  void registerAll(Iterable<ModelDefinition<OrmEntity>> definitions) {
    for (final definition in definitions) {
      if (_definitions.containsKey(definition.modelType)) {
        continue; // Skip already registered types
      }
      _definitions[definition.modelType] = definition;
      _definitionsByName[definition.modelName] = definition;
      _definitionsByTable[definition.tableName] = definition;
      _onRegistered.add(definition);
      for (final callback in _onRegisteredCallbacks) {
        callback(definition);
      }
    }
  }

  /// Registers a type alias that points to an existing definition.
  ///
  /// This is useful when you have multiple Dart types that share the same
  /// runtime definition (for example, a base type and a generated tracked type).
  void registerTypeAlias<T extends OrmEntity>(
    ModelDefinition<OrmEntity> existingDefinition,
  ) {
    if (_definitions.containsKey(T)) {
      return; // Skip already registered types
    }
    _definitions[T] = existingDefinition;
  }

  /// Returns all registered model definitions, deduplicated by model name.
  List<ModelDefinition<OrmEntity>> get allDefinitions {
    final seen = <String>{};
    final result = <ModelDefinition<OrmEntity>>[];
    for (final def in _definitions.values) {
      if (seen.add(def.modelName)) {
        result.add(def);
      }
    }
    return result;
  }

  /// Creates and registers an alias definition for [base] under [aliasModelName].
  ///
  /// This does not change type registration; it adds a name-based alias used by
  /// lookups like [expectByName].
  ModelDefinition<T> registerAlias<T extends OrmEntity>(
    ModelDefinition<T> base, {
    required String aliasModelName,
    String? tableName,
    String? schema,
  }) {
    final aliased = base.copyWith(
      modelName: aliasModelName,
      tableName: tableName ?? base.tableName,
      schema: schema ?? base.schema,
    );
    _definitionsByName[aliasModelName] = aliased;
    return aliased;
  }

  /// Returns the registered [ModelDefinition] for [T] or throws.
  ModelDefinition<T> expect<T extends OrmEntity>() {
    final definition = _definitions[T];
    if (definition == null) {
      throw ModelNotRegistered(T);
    }
    return definition as ModelDefinition<T>;
  }

  /// Returns the registered [ModelDefinition] for a runtime [type] or throws.
  ModelDefinition<OrmEntity> expectByType(Type type) {
    final definition = _definitions[type];
    if (definition == null) {
      throw ModelNotRegistered(type);
    }
    return definition;
  }

  /// Returns the model definition registered under [name] or throws.
  ModelDefinition<OrmEntity> expectByName(String name) {
    final definition = _definitionsByName[name];
    if (definition == null) {
      throw ModelNotRegisteredByName(name);
    }
    return definition;
  }

  /// Returns the model definition for the given [tableName], or null if not found.
  ModelDefinition<OrmEntity>? findByTableName(String tableName) {
    return _definitionsByTable[tableName];
  }

  /// Returns the model definition for the given [tableName] or throws.
  ModelDefinition<OrmEntity> expectByTableName(String tableName) {
    final definition = _definitionsByTable[tableName];
    if (definition == null) {
      throw ModelNotRegisteredByTableName(tableName);
    }
    return definition;
  }

  /// Whether a definition is registered for [T].
  bool contains<T>() => _definitions.containsKey(T);

  /// Registers a morph type alias for a model type.
  void registerMorphAlias(String alias, Type modelType) {
    final definition = expectByType(modelType);
    _morphDefinitions[alias] = definition;
  }

  /// Registers a morph map of aliases to model types.
  void registerMorphMap(Map<String, Type> aliases) {
    for (final entry in aliases.entries) {
      registerMorphAlias(entry.key, entry.value);
    }
  }

  /// Resolves a morph alias or model name to a registered model definition.
  ModelDefinition<OrmEntity> resolveMorphDefinition(String aliasOrModelName) {
    final definition =
        _morphDefinitions[aliasOrModelName] ??
        _definitionsByName[aliasOrModelName];
    if (definition == null) {
      throw ModelNotRegisteredByName(aliasOrModelName);
    }
    return definition;
  }

  /// Iterable view of the registered definitions keyed by type.
  Iterable<ModelDefinition<OrmEntity>> get values => _definitions.values;
}
