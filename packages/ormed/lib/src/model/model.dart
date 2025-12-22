library;

import 'dart:async';
import 'dart:convert';

import 'package:carbonized/carbonized.dart';
import 'package:ormed/src/annotations.dart';

import '../connection/connection.dart';
import '../contracts.dart';
import '../driver/driver.dart';
import '../mutation/mutation_input_helper.dart';
import '../query/query.dart';
import '../repository/repository.dart';
import '../value_codec.dart';
import 'model_definition.dart';
import 'model_factory.dart';
import 'model_mixins/model_mixins.dart';
import 'model_registry.dart';

export 'model_mixins/model_mixins.dart';
export 'model_companion.dart';
export 'model_definition.dart';
export 'model_events.dart';
export 'model_extensions.dart';
export 'model_factory.dart';
export 'model_factory_connection.dart';
export 'model_registry.dart';

/// Function that resolves a [ConnectionResolver] for a given connection name.
typedef ConnectionResolverFactory =
    ConnectionResolver Function(String connectionName);

/// Base class for Ormed models.
///
/// {@macro ormed.model.tracked_instances}
///
/// User-defined model classes are usually immutable value objects:
/// ```dart
/// @OrmModel(table: 'users')
/// class User extends Model<User> {
///   const User({this.id, required this.email});
///   final int? id;
///   final String email;
/// }
/// ```
///
/// {@macro ormed.model.connection_setup}
///
/// Many instance helpers (such as `save()`, `delete()`, and relation loaders)
/// require a tracked instance with an attached connection context.
abstract class Model<TModel extends Model<TModel>>
    with ModelConnection, ModelRelations
    implements OrmEntity {
  const Model();

  static ConnectionResolverFactory? _resolverFactory;
  static ConnectionManager? _connectionManager;
  static String _defaultConnectionName = 'default';
  static ConnectionRole _defaultConnectionRole = ConnectionRole.primary;

  static final Expando<bool> _modelExists = Expando<bool>('_modelExists');

  // ignore: unused_element
  bool get _exists => _modelExists[this] ?? false;

  set _exists(bool value) => _modelExists[this] = value;

  /// Whether this model has been persisted (loaded or saved).
  ///
  /// This flag is managed by Ormed when hydrating models from queries and when
  /// persisting via repositories/model helpers.
  bool get exists => _exists;

  /// Marks this model as existing in the database.
  ///
  /// This is used internally after hydration/persistence.
  void markAsExisting() {
    _exists = true;
  }

  // ============================================================================
  // Protected helpers to access mixin functionality
  // These are only available on tracked model instances (generated classes)
  // ============================================================================

  /// Whether this model instance is tracked (has ModelAttributes mixin).
  bool get _isTracked => this is ModelAttributes;

  /// Access to ModelAttributes mixin functionality.
  /// Only works on tracked instances (those with the mixin).
  /// Throws a descriptive error for untracked models.
  ModelAttributes get _asAttributes {
    if (this is ModelAttributes) {
      return this as ModelAttributes;
    }
    throw StateError(
      'Cannot access attribute tracking on untracked model instance. '
      'Use toTracked() to convert to a tracked model, or use repository methods '
      'like repository.insert() instead of model.save().',
    );
  }

  /// Access to ModelRelations mixin functionality.
  /// Only works on tracked instances (those with the mixin).
  ModelRelations get _asRelations => this as ModelRelations;

  /// Binds a global resolver factory so model helpers know how to persist.
  static void bindConnectionResolver({
    ConnectionResolverFactory? resolveConnection,
    ConnectionManager? connectionManager,
    String defaultConnection = 'default',
    ConnectionRole defaultRole = ConnectionRole.primary,
  }) {
    _resolverFactory = resolveConnection;
    _connectionManager = connectionManager;
    _defaultConnectionName = defaultConnection;
    _defaultConnectionRole = defaultRole;
  }

  /// Unbinds the global resolver factory (useful for tests).
  static void unbindConnectionResolver() {
    _resolverFactory = null;
    _connectionManager = null;
    _defaultConnectionName = 'default';
    _defaultConnectionRole = ConnectionRole.primary;
  }

  /// Starts a [Query] for [TModel], honoring the model's preferred connection.
  ///
  /// {@macro ormed.query}
  ///
  /// Model helpers require a bound resolver (see [bindConnectionResolver]) or a
  /// registered connection in [ConnectionManager]. In most apps, calling
  /// `DataSource.init()` is sufficient because it registers a default data
  /// source for you.
  static Query<TModel> query<TModel extends OrmEntity>({String? connection}) {
    // Try to resolve and get definition
    final initialResolver = _resolveBoundResolverFlexible<TModel>(connection);
    final definition = initialResolver.registry.expect<TModel>();

    // Determine the effective connection: explicit param > model's configured connection
    final effectiveConnection = connection ?? definition.metadata.connection;

    // If we need a different connection than what we initially resolved, re-resolve
    if (_shouldRebindResolver(connection, effectiveConnection)) {
      final resolver = _resolveBoundResolver(effectiveConnection);
      final context = _requireQueryContext(resolver);
      return context.queryFromDefinition(definition);
    }

    final context = _requireQueryContext(initialResolver);
    return context.queryFromDefinition(definition);
  }

  /// Creates a [Repository] for [TModel], honoring the model's preferred connection.
  ///
  /// {@macro ormed.repository}
  static Repository<TModel> repository<TModel extends OrmEntity>({
    String? connection,
  }) {
    // Try to resolve and get definition
    final initialResolver = _resolveBoundResolverFlexible<TModel>(connection);
    final definition = initialResolver.registry.expect<TModel>();

    // Determine the effective connection: explicit param > model's configured connection
    final effectiveConnection = connection ?? definition.metadata.connection;

    // If we need a different connection than what we initially resolved, re-resolve
    final resolver = _shouldRebindResolver(connection, effectiveConnection)
        ? _resolveBoundResolver(effectiveConnection)
        : initialResolver;

    return Repository<TModel>(
      definition: definition,
      driverName: resolver.driver.metadata.name,
      runMutation: resolver.runMutation,
      describeMutation: resolver.describeMutation,
      attachRuntimeMetadata: (model) {
        if (model is ModelConnection) {
          model.attachConnectionResolver(resolver);
        }
      },
      context: _requireQueryContext(resolver),
    );
  }

  /// Returns a factory builder that mirrors Laravel’s `Model::factory()` DSL.
  static ModelFactoryBuilder<TModel> factory<TModel extends Model<TModel>>({
    GeneratorProvider? generatorProvider,
  }) {
    final definition = ModelFactoryRegistry.definitionFor<TModel>();
    return ModelFactoryBuilder<TModel>(
      definition: definition,
      generatorProvider: generatorProvider,
    );
  }

  /// Convenience to fetch every model instance.
  static Future<List<TModel>> all<TModel extends OrmEntity>({
    String? connection,
  }) => query<TModel>(connection: connection).get();

  /// Creates and immediately persists a new model from attributes map.
  static Future<TModel> create<TModel extends Model<TModel>>(
    Map<String, dynamic> attributes, {
    String? connection,
  }) async {
    return query<TModel>(
      connection: connection,
    ).context.repository<TModel>().insert(attributes);
  }

  /// Inserts multiple records without returning model instances.
  static Future<void> insert<TModel extends OrmEntity>(
    List<Map<String, dynamic>> records, {
    String? connection,
  }) async {
    await query<TModel>(
      connection: connection,
    ).context.repository<TModel>().insertMany(records, returning: false);
  }

  /// Starts a query with a where clause.
  static Query<TModel> where<TModel extends OrmEntity>(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) => query<TModel>(connection: connection).where(column, operator, value);

  /// Starts a query with a whereIn clause.
  static Query<TModel> whereIn<TModel extends OrmEntity>(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => query<TModel>(connection: connection).whereIn(column, values);

  /// Starts a query with an orderBy clause.
  static Query<TModel> orderBy<TModel extends OrmEntity>(
    String column, {
    String direction = 'asc',
    String? connection,
  }) => query<TModel>(
    connection: connection,
  ).orderBy(column, descending: direction.toLowerCase() == 'desc');

  /// Starts a query with a limit clause.
  static Query<TModel> limit<TModel extends OrmEntity>(
    int count, {
    String? connection,
  }) => query<TModel>(connection: connection).limit(count);

  /// Find a model by its primary key, returns null if not found.
  static Future<TModel?> find<TModel extends OrmEntity>(
    Object id, {
    String? connection,
  }) => query<TModel>(connection: connection).find(id);

  /// Find a model by its primary key, throws if not found.
  static Future<TModel> findOrFail<TModel extends OrmEntity>(
    Object id, {
    String? connection,
  }) async {
    final result = await find<TModel>(id, connection: connection);
    if (result == null) {
      throw StateError('Model not found with id: $id');
    }
    return result;
  }

  /// Find multiple models by their primary keys.
  static Future<List<TModel>> findMany<TModel extends OrmEntity>(
    List<Object> ids, {
    String? connection,
  }) => query<TModel>(connection: connection).findMany(ids);

  /// Get the first model matching the query, or null.
  static Future<TModel?> first<TModel extends OrmEntity>({
    String? connection,
  }) => query<TModel>(connection: connection).first();

  /// Get the first model matching the query, or throw.
  static Future<TModel> firstOrFail<TModel extends OrmEntity>({
    String? connection,
  }) async {
    final result = await first<TModel>(connection: connection);
    if (result == null) {
      throw StateError('No model found');
    }
    return result;
  }

  /// Count the number of models.
  static Future<int> count<TModel extends OrmEntity>({String? connection}) =>
      query<TModel>(connection: connection).count();

  /// Check if any models exist in the database.
  ///
  /// Note: Renamed from `exists()` to avoid conflict with instance property.
  static Future<bool> anyExist<TModel extends OrmEntity>({
    String? connection,
  }) async => await count<TModel>(connection: connection) > 0;

  /// Check if no models exist in the database.
  ///
  /// Note: Renamed from `doesntExist()` for consistency.
  static Future<bool> noneExist<TModel extends OrmEntity>({
    String? connection,
  }) async => !await anyExist<TModel>(connection: connection);

  /// Delete all models matching a condition (dangerous!).
  static Future<int> destroy<TModel extends Model<TModel>>(
    List<Object> ids, {
    String? connection,
  }) async {
    final models = await findMany<TModel>(ids, connection: connection);
    for (final model in models) {
      await model.delete();
    }
    return models.length;
  }

  /// Get a single model and throw if zero or more than one result is found.
  static Future<TModel> sole<TModel extends OrmEntity>({String? connection}) =>
      query<TModel>(connection: connection).sole();

  /// Get first model or create new (but don't persist yet).
  ///
  /// Note: This is a placeholder - actual implementation requires codec access.
  /// Use the generated static helper on your model class instead.
  static Future<TModel> firstOrNew<TModel extends Model<TModel>>(
    Map<String, dynamic> attributes, {
    Map<String, dynamic> values = const {},
    String? connection,
  }) async {
    throw UnimplementedError(
      'Model.firstOrNew() requires code generation. Use YourModel.firstOrNew() instead.',
    );
  }

  /// Get first model or create and persist it.
  ///
  /// Note: This is a placeholder - actual implementation requires codec access.
  /// Use the generated static helper on your model class instead.
  static Future<TModel> firstOrCreate<TModel extends Model<TModel>>(
    Map<String, dynamic> attributes, {
    Map<String, dynamic> values = const {},
    String? connection,
  }) async {
    throw UnimplementedError(
      'Model.firstOrCreate() requires code generation. Use YourModel.firstOrCreate() instead.',
    );
  }

  /// Create a new model or get the first existing one.
  ///
  /// This is similar to [firstOrCreate] but with different argument order
  /// to match Laravel's API.
  ///
  /// Example:
  /// ```dart
  /// final user = await User.createOrFirst(
  ///   {'email': 'john@example.com'},
  ///   {'name': 'John Doe'},
  /// );
  /// ```
  ///
  /// Note: This is a placeholder - actual implementation requires codec access.
  /// Use the generated static helper on your model class instead.
  static Future<TModel> createOrFirst<TModel extends Model<TModel>>(
    Map<String, dynamic> attributes, {
    Map<String, dynamic> values = const {},
    String? connection,
  }) async {
    // This is essentially the same as firstOrCreate, just with different naming
    return firstOrCreate<TModel>(
      attributes,
      values: values,
      connection: connection,
    );
  }

  /// Update existing model or create new one.
  ///
  /// Note: This is a placeholder - actual implementation requires codec access.
  /// Use the generated static helper on your model class instead.
  static Future<TModel> updateOrCreate<TModel extends Model<TModel>>(
    Map<String, dynamic> attributes,
    Map<String, dynamic> values, {
    String? connection,
  }) async {
    throw UnimplementedError(
      'Model.updateOrCreate() requires code generation. Use YourModel.updateOrCreate() instead.',
    );
  }

  /// Upserts a single record (insert or update on conflict).
  ///
  /// If a record with the same unique key exists, it will be updated.
  /// Otherwise, a new record will be inserted.
  ///
  /// [attributes] are the values to upsert.
  /// [uniqueBy] specifies which fields make up the unique key (defaults to primary key).
  /// [updateColumns] specifies which columns to update on conflict (defaults to all).
  ///
  /// Example:
  /// ```dart
  /// final user = await Model.upsert<User>(
  ///   {'email': 'john@example.com', 'name': 'John Doe'},
  ///   uniqueBy: ['email'],
  /// );
  /// ```
  static Future<TModel> upsert<TModel extends Model<TModel>>(
    Map<String, dynamic> attributes, {
    List<String>? uniqueBy,
    List<String>? updateColumns,
    String? connection,
  }) => query<TModel>(
    connection: connection,
  ).upsert(attributes, uniqueBy: uniqueBy, updateColumns: updateColumns);

  /// Upserts multiple records (insert or update on conflict).
  ///
  /// If records with the same unique keys exist, they will be updated.
  /// Otherwise, new records will be inserted.
  ///
  /// [records] is a list of attribute maps to upsert.
  /// [uniqueBy] specifies which fields make up the unique key (defaults to primary key).
  /// [updateColumns] specifies which columns to update on conflict (defaults to all).
  ///
  /// Example:
  /// ```dart
  /// final users = await Model.upsertMany<User>([
  ///   {'email': 'john@example.com', 'name': 'John Doe'},
  ///   {'email': 'jane@example.com', 'name': 'Jane Smith'},
  /// ], uniqueBy: ['email']);
  /// ```
  static Future<List<TModel>> upsertMany<TModel extends Model<TModel>>(
    List<Map<String, dynamic>> records, {
    List<String>? uniqueBy,
    List<String>? updateColumns,
    String? connection,
  }) => query<TModel>(
    connection: connection,
  ).upsertMany(records, uniqueBy: uniqueBy, updateColumns: updateColumns);

  /// Typed accessor to the attached [ModelDefinition], when available.
  /// Returns null for untracked models (they don't have attached definitions).
  ModelDefinition<TModel>? get definition {
    if (!_isTracked) {
      return null;
    }
    return _asAttributes.modelDefinition as ModelDefinition<TModel>?;
  }

  /// Whether a [ModelDefinition] has been attached to this instance.
  /// Always false for untracked models.
  bool get hasDefinition {
    if (!_isTracked) {
      return false;
    }
    return definition != null;
  }

  /// Ensures the definition metadata is available, throwing when missing.
  ModelDefinition<TModel> expectDefinition() {
    final existing = definition;
    if (existing != null) {
      return existing;
    }
    final resolver = connectionResolver;
    if (resolver != null) {
      final def = resolver.registry.expect<TModel>();
      _attachDefinition(def);
      return def;
    }
    final fallback = _resolveBoundResolver(null);
    final def = fallback.registry.expect<TModel>();
    _attachDefinition(def);
    return def;
  }

  /// Serializes the model into a column map via its codec/definition.
  Map<String, Object?> toRecord({ValueCodecRegistry? registry}) {
    final def = expectDefinition();
    final codecs =
        registry ??
        connectionResolver?.codecRegistry ??
        ValueCodecRegistry.instance;
    return def.toMap(_self(), registry: codecs);
  }

  /// Alias for [toRecord] for ergonomics when bridging to JSON/Maps.
  Map<String, Object?> asMap({ValueCodecRegistry? registry}) =>
      toRecord(registry: registry);

  ValueCodecRegistry _effectiveCodecRegistry(ValueCodecRegistry? registry) =>
      registry ??
      connectionResolver?.codecRegistry ??
      ValueCodecRegistry.instance;

  /// Converts the model into a metadata-aware map, honoring hidden/visible lists.
  Map<String, Object?> toArray({
    ValueCodecRegistry? registry,
    bool includeHidden = false,
  }) => _asAttributes.serializableAttributes(
    includeHidden: includeHidden,
    registry: _effectiveCodecRegistry(registry),
  );

  /// Converts the model instance into JSON, applying the attribute metadata.
  String toJson({ValueCodecRegistry? registry, bool includeHidden = false}) {
    return jsonEncode(
      toArray(
        registry: _effectiveCodecRegistry(registry),
        includeHidden: includeHidden,
      ),
    );
  }

  /// Mass assigns [attributes], honoring fillable/guarded metadata.
  Model<TModel> fill(
    Map<String, Object?> attributes, {
    bool strict = false,
    ValueCodecRegistry? registry,
  }) {
    _asAttributes.fillAttributes(
      attributes,
      strict: strict,
      registry: _effectiveCodecRegistry(registry),
    );
    return _self();
  }

  /// Mass assigns only values that are currently absent.
  Model<TModel> fillIfAbsent(
    Map<String, Object?> attributes, {
    bool strict = false,
    ValueCodecRegistry? registry,
  }) {
    final pending = <String, Object?>{};
    final existing = _asAttributes.attributes;
    for (final entry in attributes.entries) {
      if (!existing.containsKey(entry.key) || existing[entry.key] == null) {
        pending[entry.key] = entry.value;
      }
    }
    _asAttributes.fillAttributes(
      pending,
      strict: strict,
      registry: _effectiveCodecRegistry(registry),
    );
    return _self();
  }

  /// Temporarily disables mass-assignment protection while [callback] runs.
  Model<TModel> forceFill(
    Map<String, Object?> attributes, {
    ValueCodecRegistry? registry,
  }) {
    return ModelAttributes.unguarded(
      () => fill(
        attributes,
        strict: false,
        registry: _effectiveCodecRegistry(registry),
      ),
    );
  }

  /// Queues a JSON update using Laravel-style selector syntax
  /// (`column->path`). Call [save] to persist the change.
  void jsonSet(String selector, Object? value) =>
      _asAttributes.setJsonAttributeValue(selector, value);

  /// Queues a JSON update by explicitly providing [path] relative to [column].
  void jsonSetPath(String column, String path, Object? value) =>
      _asAttributes.setJsonAttributeValue(column, value, pathOverride: path);

  /// Queues a JSON patch merge for [column] using the provided [delta] map.
  void jsonPatch(String column, Map<String, Object?> delta) =>
      _asAttributes.setJsonAttributePatch(column, delta);

  /// Clears any queued JSON mutations without persisting them.
  void clearQueuedJsonMutations() => _asAttributes.clearJsonAttributeUpdates();

  /// Persists the model using the active resolver and returns the stored copy.
  Future<TModel> save({bool returning = true}) async {
    final def = expectDefinition();
    final resolver = _resolveResolverFor(def);
    final repository = _repositoryFor(def, resolver);
    final pkValue = _primaryKeyValue(def);
    List<TModel> persisted;

    if (def.primaryKeyField == null || pkValue == null) {
      persisted = await repository.insertMany(<TModel>[_self()]);
    } else {
      persisted = await repository.upsertMany(<TModel>[_self()]);
    }

    final result = persisted.isNotEmpty ? persisted.first : _self();
    _syncFrom(result, def, resolver);
    return result;
  }

  /// Deletes the record. Soft-deletes when supported unless [force] is true.
  Future<void> delete({bool force = false}) async {
    final def = expectDefinition();
    final resolver = _resolveResolverFor(def);
    final pk = def.primaryKeyField;
    if (pk == null) {
      throw StateError(
        'Model ${def.modelName} must declare a primary key before deletion.',
      );
    }
    final key = _primaryKeyValue(def);
    if (key == null) {
      throw StateError(
        'Model ${def.modelName} is missing primary key ${pk.name}.',
      );
    }
    if (!force && def.usesSoftDeletes) {
      final column =
          def.softDeleteField?.columnName ?? def.metadata.softDeleteColumn;
      final timestamp = Carbon.now().toUtc().toDateTime();
      _asAttributes.setAttribute(column, timestamp);
      final plan = MutationPlan.update(
        definition: def,
        rows: [
          MutationRow(values: {column: timestamp}, keys: {pk.columnName: key}),
        ],
        driverName: resolver.driver.metadata.name,
      );
      await resolver.runMutation(plan);
      return;
    }
    final plan = MutationPlan.delete(
      definition: def,
      rows: [
        MutationRow(values: const {}, keys: {pk.columnName: key}),
      ],
      driverName: resolver.driver.metadata.name,
    );
    await resolver.runMutation(plan);
  }

  /// Hard-deletes the record, bypassing soft-delete flows entirely.
  Future<void> forceDelete() => delete(force: true);

  /// Restores a soft-deleted record.
  Future<void> restore() async {
    final def = expectDefinition();
    if (!def.usesSoftDeletes) {
      throw StateError(
        '${def.modelName} does not support soft deletes. Enable softDeletes.',
      );
    }
    final resolver = _resolveResolverFor(def);
    final pk = def.primaryKeyField;
    if (pk == null) {
      throw StateError(
        'Model ${def.modelName} must declare a primary key before restore.',
      );
    }
    final key = _primaryKeyValue(def);
    if (key == null) {
      throw StateError(
        'Model ${def.modelName} is missing primary key ${pk.name}.',
      );
    }
    final column =
        def.softDeleteField?.columnName ?? def.metadata.softDeleteColumn;
    final plan = MutationPlan.update(
      definition: def,
      rows: [
        MutationRow(values: {column: null}, keys: {pk.columnName: key}),
      ],
      driverName: resolver.driver.metadata.name,
    );
    await resolver.runMutation(plan);
    _asAttributes.setAttribute(column, null);
  }

  /// Returns a fresh instance of this model from the database.
  ///
  /// Unlike [refresh], this method returns a new model instance without
  /// modifying the current one. Useful when you need the latest database
  /// state but want to preserve the current instance.
  ///
  /// The [withRelations] parameter allows you to specify which relations
  /// should be eagerly loaded on the fresh instance.
  ///
  /// Example:
  /// ```dart
  /// final freshUser = await user.fresh(withRelations: ['posts']);
  /// print(user.name); // Still has old value
  /// print(freshUser.name); // Has latest value from database
  /// ```
  Future<TModel> fresh({
    bool withTrashed = false,
    Iterable<String>? withRelations,
  }) async {
    final def = expectDefinition();
    final resolver = _resolveResolverFor(def);
    final pk = def.primaryKeyField;
    if (pk == null) {
      throw StateError(
        'Model ${def.modelName} must declare a primary key to get fresh.',
      );
    }
    final key = _primaryKeyValue(def);
    if (key == null) {
      throw StateError(
        'Model ${def.modelName} is missing primary key ${pk.name}.',
      );
    }
    var builder = _requireQueryContext(resolver).queryFromDefinition(def);
    if (withTrashed && def.usesSoftDeletes) {
      builder = builder.withTrashed();
    }
    // Eager load relations if specified
    if (withRelations != null) {
      for (final relation in withRelations) {
        builder = builder.withRelation(relation);
      }
    }
    return await builder.whereEquals(pk.name, key).firstOrFail(key: key);
  }

  /// Reloads the latest row from the database, optionally including trashed.
  ///
  /// The [withRelations] parameter allows you to specify which relations
  /// should be eagerly loaded when refreshing the model.
  ///
  /// Example:
  /// ```dart
  /// await user.refresh(withRelations: ['posts', 'comments']);
  /// ```
  Future<TModel> refresh({
    bool withTrashed = false,
    Iterable<String>? withRelations,
  }) async {
    final def = expectDefinition();
    final resolver = _resolveResolverFor(def);
    final pk = def.primaryKeyField;
    if (pk == null) {
      throw StateError(
        'Model ${def.modelName} must declare a primary key to refresh.',
      );
    }
    final key = _primaryKeyValue(def);
    if (key == null) {
      throw StateError(
        'Model ${def.modelName} is missing primary key ${pk.name}.',
      );
    }
    var builder = _requireQueryContext(resolver).queryFromDefinition(def);
    if (withTrashed && def.usesSoftDeletes) {
      builder = builder.withTrashed();
    }
    // Eager load relations if specified
    if (withRelations != null) {
      for (final relation in withRelations) {
        builder = builder.withRelation(relation);
      }
    }
    final fresh = await builder.whereEquals(pk.name, key).firstOrFail(key: key);
    _syncFrom(fresh, def, resolver);
    // Sync relations from the fresh model if any were loaded
    if (withRelations != null && withRelations.isNotEmpty) {
      for (final relationName in withRelations) {
        final freshAsRelations = (fresh as Model<TModel>)._asRelations;
        if (freshAsRelations.relationLoaded(relationName)) {
          final value = freshAsRelations.loadedRelations[relationName];
          _asRelations.setRelation(relationName, value);
        }
      }
    }
    return _self();
  }

  /// Clone the model into a new, non-existing instance.
  ///
  /// Creates a copy of this model without:
  /// - Primary key
  /// - Timestamps (created_at, updated_at if they exist)
  /// - Unique identifiers
  ///
  /// The [except] parameter allows you to specify additional fields to exclude
  /// from the replication.
  ///
  /// Example:
  /// ```dart
  /// final user = await User.query().find(1);
  /// final duplicate = user.replicate(except: ['email']);
  /// duplicate.setAttribute('email', 'new@example.com');
  /// await duplicate.save();
  /// ```
  TModel replicate({List<String>? except}) {
    final def = expectDefinition();

    // Default fields to exclude
    final defaultExclude = <String>{
      if (def.primaryKeyField != null) def.primaryKeyField!.name,
      // Exclude common timestamp fields
      'created_at',
      'updated_at',
      'createdAt',
      'updatedAt',
    };

    // Merge with user-provided exclusions
    final excluded = except != null
        ? {...defaultExclude, ...except}
        : defaultExclude;

    // Get all current field values by serializing the model
    final currentAttributes = toRecord();

    // Copy current attributes and null out excluded fields
    final newAttributes = Map<String, Object?>.from(currentAttributes);
    for (final field in def.fields) {
      if (excluded.contains(field.name) ||
          excluded.contains(field.columnName)) {
        // Excluded fields are set to null (codec will handle validation/defaults)
        newAttributes[field.name] = null;
        newAttributes[field.columnName] = null;
      }
    }

    // Create and return new instance using codec
    // Use the connection resolver's codec registry to ensure driver-specific codecs are used
    final registry = connectionResolver?.codecRegistry;
    final instance = def.fromMap(newAttributes, registry: registry);

    // Mark as new (not yet persisted) using the Expando
    _modelExists[instance] = false;

    return instance;
  }

  /// Determine if two models represent the same database record.
  ///
  /// Compares:
  /// - Primary key values
  /// - Table names
  /// - Connection names (if available)
  ///
  /// Example:
  /// ```dart
  /// final user1 = await User.query().find(1);
  /// final user2 = await User.query().find(1);
  /// print(user1.isSameAs(user2)); // true
  ///
  /// final user3 = await User.query().find(2);
  /// print(user1.isSameAs(user3)); // false
  /// ```
  bool isSameAs(Model? other) {
    if (other == null) return false;

    final def1 = expectDefinition();
    final def2 = (other as Model<dynamic>).expectDefinition();

    // Compare primary keys
    final pk1 = _primaryKeyValue(def1);
    final pk2 = (other as Model<dynamic>)._primaryKeyValue(def2);

    if (pk1 == null || pk2 == null) return false;

    // Compare table names
    if (def1.tableName != def2.tableName) return false;

    // Compare connections if both are OrmConnections
    if (connection is OrmConnection && other.connection is OrmConnection) {
      // Type promotion works when checking directly on the property
      final thisName = (connection as OrmConnection).name;
      final otherName = (other.connection as OrmConnection).name;
      if (thisName != otherName) {
        return false;
      }
    }

    return pk1 == pk2;
  }

  /// Determine if two models are different.
  ///
  /// This is the inverse of [isSameAs].
  ///
  /// Example:
  /// ```dart
  /// if (user1.isDifferentFrom(user2)) {
  ///   print('Different users');
  /// }
  /// ```
  bool isDifferentFrom(Model? other) => !isSameAs(other);

  // ============================================================================
  // Change Tracking Methods
  // ============================================================================
  // Note: Change tracking methods (isDirty, syncOriginal, getOriginal, etc.)
  // are provided by the generated tracked model classes that include the
  // ModelAttributes mixin.

  TModel _self() => this as TModel;

  static bool _shouldRebindResolver(String? requested, String? metadata) {
    final normalizedMetadata = _normalizeConnectionNameOrNull(metadata);
    if (normalizedMetadata == null) {
      return false;
    }
    final normalizedRequested = _normalizeConnectionNameOrNull(requested);
    if (normalizedRequested == null) {
      final fallback = _normalizeConnectionNameOrNull(_defaultConnectionName);
      return fallback != normalizedMetadata;
    }
    return normalizedRequested != normalizedMetadata;
  }

  static QueryContext _requireQueryContext(ConnectionResolver resolver) {
    if (resolver is QueryContext) {
      return resolver;
    }
    if (resolver is OrmConnection) {
      return resolver.context;
    }
    throw StateError(
      'Model helpers require a QueryContext or OrmConnection. '
      'Call Model.bindConnectionResolver or register '
      'connections on ConnectionManager.',
    );
  }

  static ConnectionResolver _resolveBoundResolver(String? preferred) {
    final name = _effectiveConnectionName(preferred);
    final builder = _resolverFactory;
    if (builder != null) {
      return builder(name);
    }
    final manager = _connectionManager ?? ConnectionManager.defaultManager;
    if (!manager.isRegistered(name)) {
      throw StateError(
        'No ORM connection named $name registered. Register it on '
        'ConnectionManager or supply a custom resolver via '
        'Model.bindConnectionResolver(...) before using the helpers.',
      );
    }
    final connection = manager.connection(name, role: _defaultConnectionRole);
    return connection.context;
  }

  /// Flexible resolver that tries to find a connection with the model definition
  static ConnectionResolver _resolveBoundResolverFlexible<TModel>(
    String? preferred,
  ) {
    final manager = _connectionManager ?? ConnectionManager.defaultManager;
    final builder = _resolverFactory;

    // If custom resolver is set, use it
    if (builder != null) {
      final name = _effectiveConnectionName(preferred);
      return builder(name);
    }

    // Try preferred/default connection first
    final preferredName = _effectiveConnectionName(preferred);
    if (manager.isRegistered(preferredName)) {
      final connection = manager.connection(
        preferredName,
        role: _defaultConnectionRole,
      );
      if (connection.context.registry.contains<TModel>()) {
        return connection.context;
      }
    }

    // Search all registered connections for one that has this model
    for (final name in manager.registeredConnectionNames) {
      final connection = manager.connection(name, role: _defaultConnectionRole);
      if (connection.context.registry.contains<TModel>()) {
        return connection.context;
      }
    }

    throw StateError(
      'No ORM connection found with definition for $TModel. '
      'Register a DataSource containing this model on ConnectionManager.',
    );
  }

  static String _effectiveConnectionName(String? value) {
    final normalized = _normalizeConnectionNameOrNull(value);
    if (normalized != null) {
      return normalized;
    }
    final fallback = _normalizeConnectionNameOrNull(_defaultConnectionName);
    if (fallback != null) {
      return fallback;
    }
    throw StateError(
      'No default ORM connection configured. Call '
      'Model.bindConnectionResolver(...) or supply a connection name.',
    );
  }

  static String? _normalizeConnectionNameOrNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  ConnectionResolver _resolveResolverFor(ModelDefinition<TModel> definition) {
    final resolver = connectionResolver;
    if (resolver != null) {
      return resolver;
    }
    return _resolveBoundResolver(definition.metadata.connection);
  }

  Repository<TModel> _repositoryFor(
    ModelDefinition<TModel> definition,
    ConnectionResolver resolver,
  ) {
    if (resolver is! QueryContext) {
      throw StateError(
        'Repository requires a QueryContext. '
        'Bind a QueryContext-based ConnectionResolver or call Model.repository() '
        'with a registered connection.',
      );
    }

    return Repository<TModel>(
      definition: definition,
      driverName: resolver.driver.metadata.name,
      runMutation: resolver.runMutation,
      describeMutation: resolver.describeMutation,
      attachRuntimeMetadata: (model) {
        if (model is ModelConnection) {
          model.attachConnectionResolver(resolver);
        }
        resolver.attachRuntimeMetadata(model);
      },
      context: resolver,
    );
  }

  Object? _primaryKeyValue(ModelDefinition<TModel> definition) {
    final field = definition.primaryKeyField;
    if (field == null) {
      return null;
    }
    // For tracked models, try to get from attributes first
    if (_isTracked) {
      final keyed = _asAttributes.getAttribute<Object?>(field.columnName);
      if (keyed != null) {
        return keyed;
      }
    }
    // Fall back to extracting from the model via codec
    final codecs =
        connectionResolver?.codecRegistry ?? ValueCodecRegistry.instance;
    final values = definition.toMap(_self(), registry: codecs);
    return values[field.columnName];
  }

  void _syncFrom(
    TModel source,
    ModelDefinition<TModel> definition,
    ConnectionResolver resolver,
  ) {
    attachConnectionResolver(resolver);
    // Only sync attributes if both source and this are tracked
    if (!_isTracked) {
      return;
    }
    final sourceModel = source as Model<TModel>;
    if (!sourceModel._isTracked) {
      // Just attach the definition if source isn't tracked
      _attachDefinition(definition);
      return;
    }
    _attachDefinition(definition);
    final sourceAsAttributes = sourceModel._asAttributes;
    final values = Map<String, Object?>.from(sourceAsAttributes.attributes);
    _asAttributes.replaceAttributes(values);
    _exists = true;
  }

  void _attachDefinition(ModelDefinition<TModel> definition) {
    if (!_isTracked) {
      return;
    }
    _asAttributes.attachModelDefinition(definition);
    if (definition.usesSoftDeletes) {
      _asAttributes.attachSoftDeleteColumn(
        definition.metadata.softDeleteColumn,
      );
    }
  }

  /// Lazily loads a relation on this model instance.
  ///
  /// Similar to Laravel's `$model->load('relation')`.
  ///
  /// Supports nested relation paths using dot notation:
  /// ```dart
  /// await post.load('comments.author'); // Load comments, then their authors
  /// ```
  ///
  /// Example:
  /// ```dart
  /// final post = await Post.query().first();
  /// await post.load('author'); // Lazy load author
  /// print(post.author?.name);
  /// ```
  ///
  /// With constraint (applies to the final relation in nested paths):
  /// ```dart
  /// await post.load('comments', (q) => q.where('approved', true));
  /// ```
  ///
  /// Throws [LazyLoadingViolationException] if [ModelRelations.preventsLazyLoading] is true.
  Future<TModel> load(
    String relation, [
    PredicateCallback<OrmEntity>? constraint,
  ]) async {
    if (ModelRelations.preventsLazyLoading) {
      throw LazyLoadingViolationException(runtimeType, relation);
    }

    final def = expectDefinition();
    final resolver = _resolveResolverFor(def);
    final context = _requireQueryContext(resolver);

    // Check if this is a nested relation path
    if (relation.contains('.')) {
      await _loadNestedRelation(relation, constraint, def, context);
      return _self();
    }

    // Find the relation definition
    final relationDef = def.relations.cast<RelationDefinition?>().firstWhere(
      (r) => r?.name == relation,
      orElse: () => null,
    );

    if (relationDef == null) {
      throw ArgumentError('Relation "$relation" not found on ${def.modelName}');
    }

    // Convert constraint callback to QueryPredicate using RelationResolver
    final relationResolver = RelationResolver(context);
    final predicate = relationResolver.predicateFor(relationDef, constraint);

    // Create a synthetic QueryRow from current model
    final row = QueryRow<TModel>(
      model: _self(),
      row: def.toMap(_self(), registry: context.codecRegistry),
    );

    // Load the relation using RelationLoader
    final loader = RelationLoader(context);
    final relationLoad = RelationLoad(
      relation: relationDef,
      predicate: predicate,
    );

    await loader.attach(def, [row], [relationLoad]);

    // The relation should now be in row.relations and synced to model cache
    return _self();
  }

  /// Internal helper for loading nested relation paths.
  ///
  /// Splits the path and recursively loads each segment.
  Future<void> _loadNestedRelation(
    String path,
    PredicateCallback<OrmEntity>? constraint,
    ModelDefinition<TModel> def,
    QueryContext context,
  ) async {
    final parts = path.split('.');
    final firstRelation = parts.first;
    final remainingPath = parts.skip(1).join('.');

    // Load the first relation on this model (no constraint for intermediate relations)
    final relationDef = def.relations.cast<RelationDefinition?>().firstWhere(
      (r) => r?.name == firstRelation,
      orElse: () => null,
    );

    if (relationDef == null) {
      throw ArgumentError(
        'Relation "$firstRelation" not found on ${def.modelName}',
      );
    }

    // Load the first relation if not already loaded
    if (!_asRelations.relationLoaded(firstRelation)) {
      final row = QueryRow<TModel>(
        model: _self(),
        row: def.toMap(_self(), registry: context.codecRegistry),
      );

      final loader = RelationLoader(context);
      final relationLoad = RelationLoad(relation: relationDef);
      await loader.attach(def, [row], [relationLoad]);
    }

    // If there's more path to load, recurse into the loaded relations
    if (remainingPath.isNotEmpty) {
      final loadedValue = _asRelations.getRelation<dynamic>(firstRelation);

      if (loadedValue == null) {
        return; // Nothing to recurse into
      }

      // Determine the constraint to pass (only for the final segment)
      final isLastSegment = !remainingPath.contains('.');
      final nextConstraint = isLastSegment ? constraint : null;

      if (loadedValue is Model) {
        await loadedValue.load(remainingPath, nextConstraint);
        return;
      }

      if (loadedValue is List) {
        // Load nested relations on each item in the list
        for (final item in loadedValue) {
          if (item is Model) {
            await item.load(remainingPath, nextConstraint);
          }
        }
      }
    }
  }

  /// Lazily loads multiple relations that haven't been loaded yet.
  ///
  /// Similar to Laravel's `$model->loadMissing(['relation1', 'relation2'])`.
  ///
  /// Only loads relations that aren't already loaded.
  ///
  /// Example:
  /// ```dart
  /// await post.loadMissing(['author', 'tags', 'comments']);
  /// ```
  Future<TModel> loadMissing(Iterable<String> relations) async {
    for (final relation in relations) {
      if (!_asRelations.relationLoaded(relation)) {
        await load(relation);
      }
    }
    return _self();
  }

  /// Lazily loads multiple relations with optional constraints.
  ///
  /// Similar to Laravel's `$model->load(['relation1' => callback, ...])`.
  ///
  /// Example:
  /// ```dart
  /// await post.loadMany({
  ///   'author': null,
  ///   'comments': (q) => q.where('approved', true),
  ///   'tags': (q) => q.orderBy('name'),
  /// });
  /// ```
  Future<TModel> loadMany(
    Map<String, PredicateCallback<OrmEntity>?> relations,
  ) async {
    for (final entry in relations.entries) {
      await load(entry.key, entry.value);
    }
    return _self();
  }

  /// Lazily loads a relation on multiple models efficiently.
  ///
  /// This static method batches relation loading across multiple models,
  /// executing a single query per resolver group instead of N+1 queries.
  ///
  /// Similar to Laravel's collection-based `load()`.
  ///
  /// Example:
  /// ```dart
  /// final posts = await Post.query().get();
  /// await Model.loadRelations(posts, 'author');
  /// // All posts now have their authors loaded with a single query
  /// ```
  ///
  /// With constraint:
  /// ```dart
  /// await Model.loadRelations(posts, 'comments', (q) => q.where('approved', true));
  /// ```
  ///
  /// Throws [LazyLoadingViolationException] if [ModelRelations.preventsLazyLoading] is true.
  static Future<void> loadRelations<T extends Model<T>>(
    Iterable<T> models,
    String relation, [
    PredicateCallback<OrmEntity>? constraint,
  ]) async {
    if (ModelRelations.preventsLazyLoading) {
      if (models.isNotEmpty) {
        throw LazyLoadingViolationException(models.first.runtimeType, relation);
      }
      return;
    }

    final modelList = models.toList();
    if (modelList.isEmpty) return;

    // Group models by their connection resolver
    final groups = <ConnectionResolver, List<T>>{};
    for (final model in modelList) {
      final def = model.expectDefinition();
      final resolver = model._resolveResolverFor(def);
      groups.putIfAbsent(resolver, () => <T>[]).add(model);
    }

    // Load relations for each group
    for (final entry in groups.entries) {
      final resolver = entry.key;
      final groupModels = entry.value;

      if (groupModels.isEmpty) continue;

      final context = _requireQueryContext(resolver);
      final def = groupModels.first.expectDefinition();

      // Check for nested path
      if (relation.contains('.')) {
        // For nested paths, load on each model individually
        // (batch loading nested paths is complex and deferred)
        for (final model in groupModels) {
          await model.load(relation, constraint);
        }
        continue;
      }

      // Find the relation definition
      final relationDef = def.relations.cast<RelationDefinition?>().firstWhere(
        (r) => r?.name == relation,
        orElse: () => null,
      );

      if (relationDef == null) {
        throw ArgumentError(
          'Relation "$relation" not found on ${def.modelName}',
        );
      }

      // Convert constraint callback to QueryPredicate
      final relationResolver = RelationResolver(context);
      final predicate = relationResolver.predicateFor(relationDef, constraint);

      // Create synthetic QueryRows for all models in the group
      final rows = groupModels.map((model) {
        return QueryRow<T>(
          model: model,
          row: def.toMap(model, registry: context.codecRegistry),
        );
      }).toList();

      // Batch load the relation using RelationLoader
      final loader = RelationLoader(context);
      final relationLoad = RelationLoad(
        relation: relationDef,
        predicate: predicate,
      );

      await loader.attach(def, rows, [relationLoad]);
    }
  }

  /// Lazily loads multiple relations on multiple models efficiently.
  ///
  /// This is a convenience wrapper around [loadRelations] for loading
  /// multiple relations in sequence.
  ///
  /// Example:
  /// ```dart
  /// final posts = await Post.query().get();
  /// await Model.loadRelationsMany(posts, ['author', 'tags', 'comments']);
  /// ```
  static Future<void> loadRelationsMany<T extends Model<T>>(
    Iterable<T> models,
    Iterable<String> relations,
  ) async {
    for (final relation in relations) {
      await loadRelations(models, relation);
    }
  }

  /// Lazily loads relations on multiple models if not already loaded.
  ///
  /// Only loads relations that aren't already loaded on each model.
  ///
  /// Example:
  /// ```dart
  /// final posts = await Post.query().get();
  /// await Model.loadRelationsMissing(posts, ['author', 'tags']);
  /// ```
  static Future<void> loadRelationsMissing<T extends Model<T>>(
    Iterable<T> models,
    Iterable<String> relations,
  ) async {
    for (final relation in relations) {
      // Filter to models that don't have this relation loaded
      final needsLoading = models
          .where((m) => !(m as Model)._asRelations.relationLoaded(relation))
          .toList();
      if (needsLoading.isNotEmpty) {
        await loadRelations(needsLoading, relation);
      }
    }
  }

  /// Lazily loads the count of a relation.
  ///
  /// Stores the count as an attribute with the suffix `_count`.
  ///
  /// Example:
  /// ```dart
  /// await post.loadCount('comments');
  /// print(post.getAttribute<int>('comments_count')); // e.g., 5
  /// ```
  ///
  /// With custom alias:
  /// ```dart
  /// await post.loadCount('comments', alias: 'total_comments');
  /// print(post.getAttribute<int>('total_comments'));
  /// ```
  Future<TModel> loadCount(
    String relation, {
    String? alias,
    PredicateCallback<OrmEntity>? constraint,
  }) async {
    if (ModelRelations.preventsLazyLoading) {
      throw LazyLoadingViolationException(runtimeType, relation);
    }

    final def = expectDefinition();
    final resolver = _resolveResolverFor(def);
    final context = _requireQueryContext(resolver);

    // Find the relation definition
    final relationDef = def.relations.cast<RelationDefinition?>().firstWhere(
      (r) => r?.name == relation,
      orElse: () => null,
    );

    if (relationDef == null) {
      throw ArgumentError('Relation "$relation" not found on ${def.modelName}');
    }

    final countAlias = alias ?? '${relation}_count';

    // Build a query for this model with withCount
    final query = context.queryFromDefinition(def);

    // Get the primary key value
    final pkField = def.primaryKeyField;
    if (pkField == null) {
      throw StateError('Cannot load count on model without primary key');
    }

    final pkValue = _asAttributes.getAttribute(pkField.columnName);
    if (pkValue == null) {
      throw StateError('Cannot load count on model without primary key value');
    }

    // Query for this specific model with count
    query.where(pkField.columnName, pkValue);
    query.withCount(relation, alias: countAlias, constraint: constraint);

    final rows = await query.get();
    if (rows.isNotEmpty) {
      final result = rows.first;
      final count = result._asAttributes.getAttribute<int>(countAlias) ?? 0;
      _asAttributes.setAttribute(countAlias, count);
    }

    return _self();
  }

  /// Lazily loads the existence of a relation.
  ///
  /// Stores the boolean result as an attribute with the suffix `_exists`.
  ///
  /// Example:
  /// ```dart
  /// await post.loadExists('comments');
  /// if (post.getAttribute<bool>('comments_exists') == true) {
  ///   print('Post has comments');
  /// }
  /// ```
  Future<TModel> loadExists(
    String relation, {
    String? alias,
    PredicateCallback<OrmEntity>? constraint,
  }) async {
    if (ModelRelations.preventsLazyLoading) {
      throw LazyLoadingViolationException(runtimeType, relation);
    }

    final def = expectDefinition();
    final resolver = _resolveResolverFor(def);
    final context = _requireQueryContext(resolver);

    // Find the relation definition
    final relationDef = def.relations.cast<RelationDefinition?>().firstWhere(
      (r) => r?.name == relation,
      orElse: () => null,
    );

    if (relationDef == null) {
      throw ArgumentError('Relation "$relation" not found on ${def.modelName}');
    }

    final existsAlias = alias ?? '${relation}_exists';

    // Build a query for this model with withExists
    final query = context.queryFromDefinition(def);

    // Get the primary key value
    final pkField = def.primaryKeyField;
    if (pkField == null) {
      throw StateError('Cannot load exists on model without primary key');
    }

    final pkValue = _asAttributes.getAttribute(pkField.columnName);
    if (pkValue == null) {
      throw StateError('Cannot load exists on model without primary key value');
    }

    // Query for this specific model with exists
    final queryWithAggregate = query
        .where(pkField.columnName, pkValue)
        .withExists(relation, alias: existsAlias, constraint: constraint);

    final rows = await queryWithAggregate.get();
    if (rows.isNotEmpty) {
      final result = rows.first;
      // SQL returns 1/0 for EXISTS, convert to boolean
      final value = result._asAttributes.getAttribute(existsAlias);
      final exists = value == true || value == 1;
      _asAttributes.setAttribute(existsAlias, exists);
    }

    return _self();
  }

  /// Lazily loads the sum of a column in a relation.
  ///
  /// Stores the sum result as an attribute with the suffix `_sum_{column}`.
  ///
  /// Example:
  /// ```dart
  /// await post.loadSum('comments', 'likes');
  /// final totalLikes = post.getAttribute<num>('comments_sum_likes') ?? 0;
  /// ```
  Future<TModel> loadSum(
    String relation,
    String column, {
    String? alias,
    PredicateCallback<OrmEntity>? constraint,
  }) async {
    return _loadAggregate(
      RelationAggregateType.sum,
      relation,
      column,
      alias: alias,
      constraint: constraint,
    );
  }

  /// Lazily loads the average of a column in a relation.
  ///
  /// Stores the average result as an attribute with the suffix `_avg_{column}`.
  ///
  /// Example:
  /// ```dart
  /// await post.loadAvg('comments', 'rating');
  /// final avgRating = post.getAttribute<num>('comments_avg_rating') ?? 0;
  /// ```
  Future<TModel> loadAvg(
    String relation,
    String column, {
    String? alias,
    PredicateCallback<OrmEntity>? constraint,
  }) async {
    return _loadAggregate(
      RelationAggregateType.avg,
      relation,
      column,
      alias: alias,
      constraint: constraint,
    );
  }

  /// Lazily loads the maximum value of a column in a relation.
  ///
  /// Stores the max result as an attribute with the suffix `_max_{column}`.
  ///
  /// Example:
  /// ```dart
  /// await post.loadMax('comments', 'created_at');
  /// final latestComment = post.getAttribute('comments_max_created_at');
  /// ```
  Future<TModel> loadMax(
    String relation,
    String column, {
    String? alias,
    PredicateCallback<OrmEntity>? constraint,
  }) async {
    return _loadAggregate(
      RelationAggregateType.max,
      relation,
      column,
      alias: alias,
      constraint: constraint,
    );
  }

  /// Lazily loads the minimum value of a column in a relation.
  ///
  /// Stores the min result as an attribute with the suffix `_min_{column}`.
  ///
  /// Example:
  /// ```dart
  /// await post.loadMin('comments', 'created_at');
  /// final earliestComment = post.getAttribute('comments_min_created_at');
  /// ```
  Future<TModel> loadMin(
    String relation,
    String column, {
    String? alias,
    PredicateCallback<OrmEntity>? constraint,
  }) async {
    return _loadAggregate(
      RelationAggregateType.min,
      relation,
      column,
      alias: alias,
      constraint: constraint,
    );
  }

  /// Internal helper to load aggregates on relations.
  Future<TModel> _loadAggregate(
    RelationAggregateType type,
    String relation,
    String column, {
    String? alias,
    PredicateCallback<OrmEntity>? constraint,
  }) async {
    if (ModelRelations.preventsLazyLoading) {
      throw LazyLoadingViolationException(runtimeType, relation);
    }

    final def = expectDefinition();
    final resolver = _resolveResolverFor(def);
    final context = _requireQueryContext(resolver);

    // Find the relation definition
    final relationDef = def.relations.cast<RelationDefinition?>().firstWhere(
      (r) => r?.name == relation,
      orElse: () => null,
    );

    if (relationDef == null) {
      throw ArgumentError('Relation "$relation" not found on ${def.modelName}');
    }

    final aggregateAlias =
        alias ?? '${relation}_${type.name}_${column.replaceAll('.', '_')}';

    // Build a query for this model with the aggregate
    final query = context.queryFromDefinition(def);

    // Get the primary key value
    final pkField = def.primaryKeyField;
    if (pkField == null) {
      throw StateError('Cannot load ${type.name} on model without primary key');
    }

    final pkValue = _asAttributes.getAttribute(pkField.columnName);
    if (pkValue == null) {
      throw StateError(
        'Cannot load ${type.name} on model without primary key value',
      );
    }

    // Query for this specific model with aggregate
    final queryWithFilter = query.where(pkField.columnName, pkValue);

    final queryWithAggregate = switch (type) {
      RelationAggregateType.sum => queryWithFilter.withSum(
        relation,
        column,
        alias: aggregateAlias,
        constraint: constraint,
      ),
      RelationAggregateType.avg => queryWithFilter.withAvg(
        relation,
        column,
        alias: aggregateAlias,
        constraint: constraint,
      ),
      RelationAggregateType.max => queryWithFilter.withMax(
        relation,
        column,
        alias: aggregateAlias,
        constraint: constraint,
      ),
      RelationAggregateType.min => queryWithFilter.withMin(
        relation,
        column,
        alias: aggregateAlias,
        constraint: constraint,
      ),
      _ => throw ArgumentError('Unsupported aggregate type: ${type.name}'),
    };

    final rows = await queryWithAggregate.get();
    if (rows.isNotEmpty) {
      final result = rows.first;
      final value = result._asAttributes.getAttribute(aggregateAlias);
      _asAttributes.setAttribute(aggregateAlias, value);
    }

    return _self();
  }

  /// Associates a belongsTo parent model and updates the foreign key.
  ///
  /// This is a convenient helper that:
  /// 1. Updates the foreign key field to match the parent's primary key
  /// 2. Caches the parent model in the relation cache
  /// 3. Marks the relation as loaded
  ///
  /// Example:
  /// ```dart
  /// final post = Post(id: 1, title: 'Hello');
  /// final author = Author(id: 5, name: 'Alice');
  /// await post.associate('author', author);
  /// // post.authorId is now 5
  /// // post.author is now the Alice instance
  /// ```
  Future<TModel> associate(String relationName, Model parent) async {
    final def = expectDefinition();
    final relationDef = def.relations.cast<RelationDefinition?>().firstWhere(
      (r) => r?.name == relationName,
      orElse: () => null,
    );

    if (relationDef == null) {
      throw ArgumentError(
        'Relation "$relationName" not found on ${def.modelName}',
      );
    }

    if (relationDef.kind != RelationKind.belongsTo) {
      throw ArgumentError(
        'associate() can only be used with belongsTo relations. '
        'Relation "$relationName" is ${relationDef.kind}',
      );
    }

    // Get the parent's primary key value
    final resolver = _resolveResolverFor(def);
    final context = _requireQueryContext(resolver);
    final parentDef = context.registry.expectByName(relationDef.targetModel);
    final parentPk = parentDef.primaryKeyField;
    if (parentPk == null) {
      throw StateError(
        'Parent model ${parentDef.modelName} must have a primary key',
      );
    }

    final parentPkValue = parentDef.toMap(
      parent as dynamic,
      registry: context.codecRegistry,
    )[parentPk.columnName];

    if (parentPkValue == null) {
      throw StateError(
        'Parent model ${parentDef.modelName} primary key value is null',
      );
    }

    // Find the foreign key field in this model
    final foreignKeyName = relationDef.foreignKey;
    final field = def.fields.firstWhere(
      (f) => f.columnName == foreignKeyName || f.name == foreignKeyName,
    );

    // Update the foreign key attribute
    _asAttributes.setAttribute(field.columnName, parentPkValue);

    // Cache the parent in relations
    _asRelations.setRelation(relationName, parent);

    return _self();
  }

  /// Dissociates a belongsTo parent model and clears the foreign key.
  ///
  /// This is a convenient helper that:
  /// 1. Sets the foreign key field to null
  /// 2. Removes the parent from the relation cache
  /// 3. Marks the relation as not loaded
  ///
  /// Example:
  /// ```dart
  /// final post = Post(id: 1, authorId: 5, title: 'Hello');
  /// await post.dissociate('author');
  /// // post.authorId is now null
  /// // post.author is now null
  /// ```
  Future<TModel> dissociate(String relationName) async {
    final def = expectDefinition();
    final relationDef = def.relations.cast<RelationDefinition?>().firstWhere(
      (r) => r?.name == relationName,
      orElse: () => null,
    );

    if (relationDef == null) {
      throw ArgumentError(
        'Relation "$relationName" not found on ${def.modelName}',
      );
    }

    if (relationDef.kind != RelationKind.belongsTo) {
      throw ArgumentError(
        'dissociate() can only be used with belongsTo relations. '
        'Relation "$relationName" is ${relationDef.kind}',
      );
    }

    // Find the foreign key field and nullify it
    final foreignKeyName = relationDef.foreignKey;
    final field = def.fields.firstWhere(
      (f) => f.columnName == foreignKeyName || f.name == foreignKeyName,
    );

    _asAttributes.setAttribute(field.columnName, null);

    // Remove from relation cache
    _asRelations.unsetRelation(relationName);

    return _self();
  }

  /// Attaches related models in a manyToMany relationship.
  ///
  /// Inserts new pivot table records to establish the many-to-many relationship.
  /// Optionally accepts pivot data for additional columns on the pivot table.
  ///
  /// After attaching, the relation is reloaded to sync the cache.
  ///
  /// Example:
  /// ```dart
  /// final post = await Post.query().find(1);
  /// await post.attach('tags', [1, 2, 3]);
  /// // Pivot records created for tag IDs 1, 2, 3
  ///
  /// // With pivot data:
  /// await post.attach('tags', [4], pivotData: {'order': 1});
  /// ```
  Future<TModel> attach(
    String relationName,
    List<dynamic> ids, {
    Map<String, dynamic>? pivotData,
  }) async {
    final def = expectDefinition();
    final resolver = _resolveResolverFor(def);

    final relationDef = def.relations.cast<RelationDefinition?>().firstWhere(
      (r) => r?.name == relationName,
      orElse: () => null,
    );

    if (relationDef == null) {
      throw ArgumentError(
        'Relation "$relationName" not found on ${def.modelName}',
      );
    }

    if (relationDef.kind != RelationKind.manyToMany) {
      throw ArgumentError(
        'attach() can only be used with manyToMany relations. '
        'Relation "$relationName" is ${relationDef.kind}',
      );
    }

    if (ids.isEmpty) {
      return _self();
    }

    // Get this model's primary key value
    final pk = def.primaryKeyField;
    if (pk == null) {
      throw StateError('Model ${def.modelName} must have a primary key');
    }

    final pkValue = _primaryKeyValue(def);
    if (pkValue == null) {
      throw StateError('Model ${def.modelName} primary key value is null');
    }

    // Build pivot table rows
    final pivotTable = relationDef.through;
    if (pivotTable == null) {
      throw StateError(
        'Relation "$relationName" is missing pivot table name (through)',
      );
    }

    final pivotForeignKey = relationDef.pivotForeignKey!;
    final pivotRelatedKey = relationDef.pivotRelatedKey!;

    // Get the related model definition to determine column types
    final relatedModelName = relationDef.targetModel;
    final relatedDef = resolver.registry.expectByName(relatedModelName);

    final relatedPk = relatedDef.primaryKeyField;
    if (relatedPk == null) {
      throw StateError(
        'Related model $relatedModelName must have a primary key',
      );
    }

    final rows = ids.map((id) {
      final row = <String, dynamic>{
        pivotForeignKey: pkValue,
        pivotRelatedKey: id,
      };
      if (pivotData != null) {
        row.addAll(pivotData);
      }
      return row;
    }).toList();

    // Build pivot table definition with proper column types
    final pivotDef = _createPivotDefinition(pivotTable, def.schema, {
      pivotForeignKey: pk,
      pivotRelatedKey: relatedPk,
      ...?pivotData?.map((key, _) => MapEntry(key, null)),
    });

    final plan = MutationPlan.insert(definition: pivotDef, rows: rows);

    await resolver.runMutation(plan);

    // Reload the relation to sync cache
    await load(relationName);

    return _self();
  }

  /// Detaches related models in a manyToMany relationship.
  ///
  /// Deletes pivot table records. If no IDs are provided, detaches all.
  ///
  /// After detaching, the relation is reloaded to sync the cache.
  ///
  /// Example:
  /// ```dart
  /// final post = await Post.query().find(1);
  /// await post.detach('tags', [1, 2]); // Detach specific tags
  /// await post.detach('tags'); // Detach all tags
  /// ```
  Future<TModel> detach(String relationName, [List<dynamic>? ids]) async {
    final def = expectDefinition();
    final resolver = _resolveResolverFor(def);

    final relationDef = def.relations.cast<RelationDefinition?>().firstWhere(
      (r) => r?.name == relationName,
      orElse: () => null,
    );

    if (relationDef == null) {
      throw ArgumentError(
        'Relation "$relationName" not found on ${def.modelName}',
      );
    }

    if (relationDef.kind != RelationKind.manyToMany) {
      throw ArgumentError(
        'detach() can only be used with manyToMany relations. '
        'Relation "$relationName" is ${relationDef.kind}',
      );
    }

    // Get this model's primary key value
    final pk = def.primaryKeyField;
    if (pk == null) {
      throw StateError('Model ${def.modelName} must have a primary key');
    }

    final pkValue = _primaryKeyValue(def);
    if (pkValue == null) {
      throw StateError('Model ${def.modelName} primary key value is null');
    }

    final pivotTable = relationDef.through;
    if (pivotTable == null) {
      throw StateError(
        'Relation "$relationName" is missing pivot table name (through)',
      );
    }

    final pivotForeignKey = relationDef.pivotForeignKey!;
    final pivotRelatedKey = relationDef.pivotRelatedKey!;

    // Get the related model definition to determine column types
    final relatedModelName = relationDef.targetModel;
    final relatedDef = resolver.registry.expectByName(relatedModelName);

    final relatedPk = relatedDef.primaryKeyField;
    if (relatedPk == null) {
      throw StateError(
        'Related model $relatedModelName must have a primary key',
      );
    }

    // Build delete keys
    final List<Map<String, Object?>> deleteKeys;

    if (ids != null && ids.isNotEmpty) {
      // Detach specific IDs
      deleteKeys = ids
          .map((id) => {pivotForeignKey: pkValue, pivotRelatedKey: id})
          .toList();
    } else {
      // Detach all - query for existing pivot records first
      final pivotDef = _createPivotDefinition(pivotTable, def.schema, {
        pivotForeignKey: pk,
        pivotRelatedKey: relatedPk,
      });

      final selectPlan = QueryPlan(
        definition: pivotDef,
        filters: [
          FilterClause(
            field: pivotForeignKey,
            operator: FilterOperator.equals,
            value: pkValue,
          ),
        ],
      );

      final results = await resolver.runSelect(selectPlan);
      deleteKeys = results
          .map(
            (row) => {
              pivotForeignKey: row[pivotForeignKey],
              pivotRelatedKey: row[pivotRelatedKey],
            },
          )
          .toList();
    }

    if (deleteKeys.isNotEmpty) {
      final pivotDef = _createPivotDefinition(pivotTable, def.schema, {
        pivotForeignKey: pk,
        pivotRelatedKey: relatedPk,
      });

      final deleteRows = deleteKeys
          .map((keys) => MutationRow(values: const {}, keys: keys))
          .toList();

      final plan = MutationPlan.delete(definition: pivotDef, rows: deleteRows);

      await resolver.runMutation(plan);
    }

    // Reload the relation to sync cache
    await load(relationName);

    return _self();
  }

  /// Syncs a manyToMany relationship to match the given IDs exactly.
  ///
  /// This replaces all existing pivot records with new ones for the given IDs.
  /// Internally calls `detach()` (all) followed by `attach()`.
  ///
  /// Example:
  /// ```dart
  /// final post = await Post.query().find(1);
  /// // Currently has tags: [1, 2, 3]
  /// await post.sync('tags', [2, 3, 4]);
  /// // Now has tags: [2, 3, 4]
  /// ```
  Future<TModel> sync(
    String relationName,
    List<dynamic> ids, {
    Map<String, dynamic>? pivotData,
  }) async {
    // First detach all
    await detach(relationName);

    // Then attach the new IDs
    if (ids.isNotEmpty) {
      await attach(relationName, ids, pivotData: pivotData);
    }

    return _self();
  }

  /// Syncs a manyToMany relationship without detaching existing records.
  ///
  /// Unlike [sync], this method only attaches new IDs while keeping existing
  /// pivot records intact. Useful when you want to add new relations without
  /// removing existing ones.
  ///
  /// Example:
  /// ```dart
  /// final post = await Post.query().find(1);
  /// // Currently has tags: [1, 2]
  /// await post.syncWithoutDetaching('tags', [2, 3, 4]);
  /// // Now has tags: [1, 2, 3, 4] (1 kept, 2 kept, 3 and 4 added)
  /// ```
  Future<TModel> syncWithoutDetaching(
    String relationName,
    List<dynamic> ids, {
    Map<String, dynamic>? pivotData,
  }) async {
    final def = expectDefinition();
    final resolver = _resolveResolverFor(def);

    final relationDef = def.relations.cast<RelationDefinition?>().firstWhere(
      (r) => r?.name == relationName,
      orElse: () => null,
    );

    if (relationDef == null) {
      throw ArgumentError(
        'Relation "$relationName" not found on ${def.modelName}',
      );
    }

    if (relationDef.kind != RelationKind.manyToMany) {
      throw ArgumentError(
        'syncWithoutDetaching() can only be used with manyToMany relations. '
        'Relation "$relationName" is ${relationDef.kind}',
      );
    }

    if (ids.isEmpty) {
      return _self();
    }

    // Get existing attached IDs
    final existingIds = await _getPivotRelatedIds(
      relationDef,
      def,
      resolver,
    );

    // Filter out IDs that already exist
    final newIds = ids.where((id) => !existingIds.contains(id)).toList();

    // Only attach the new ones
    if (newIds.isNotEmpty) {
      await attach(relationName, newIds, pivotData: pivotData);
    } else {
      // Reload relation to sync cache even if nothing changed
      await load(relationName);
    }

    return _self();
  }

  /// Syncs a manyToMany relationship with the same pivot data for all records.
  ///
  /// This is like [sync] but applies the same pivot data to all attached records.
  ///
  /// Example:
  /// ```dart
  /// final post = await Post.query().find(1);
  /// await post.syncWithPivotValues('tags', [1, 2, 3], {'active': true});
  /// // All pivot records now have active=true
  /// ```
  Future<TModel> syncWithPivotValues(
    String relationName,
    List<dynamic> ids,
    Map<String, dynamic> pivotData,
  ) async {
    return sync(relationName, ids, pivotData: pivotData);
  }

  /// Toggles the attachment of related models in a manyToMany relationship.
  ///
  /// For each ID:
  /// - If currently attached → detach it
  /// - If not attached → attach it
  ///
  /// Example:
  /// ```dart
  /// final post = await Post.query().find(1);
  /// // Currently has tags: [1, 2]
  /// await post.toggle('tags', [2, 3]);
  /// // Now has tags: [1, 3] (2 was detached, 3 was attached)
  /// ```
  Future<TModel> toggle(
    String relationName,
    List<dynamic> ids, {
    Map<String, dynamic>? pivotData,
  }) async {
    final def = expectDefinition();
    final resolver = _resolveResolverFor(def);

    final relationDef = def.relations.cast<RelationDefinition?>().firstWhere(
      (r) => r?.name == relationName,
      orElse: () => null,
    );

    if (relationDef == null) {
      throw ArgumentError(
        'Relation "$relationName" not found on ${def.modelName}',
      );
    }

    if (relationDef.kind != RelationKind.manyToMany) {
      throw ArgumentError(
        'toggle() can only be used with manyToMany relations. '
        'Relation "$relationName" is ${relationDef.kind}',
      );
    }

    if (ids.isEmpty) {
      return _self();
    }

    // Get existing attached IDs
    final existingIds = await _getPivotRelatedIds(
      relationDef,
      def,
      resolver,
    );

    // Separate into IDs to attach and IDs to detach
    final toDetach = ids.where((id) => existingIds.contains(id)).toList();
    final toAttach = ids.where((id) => !existingIds.contains(id)).toList();

    // Detach existing ones
    if (toDetach.isNotEmpty) {
      await detach(relationName, toDetach);
    }

    // Attach new ones
    if (toAttach.isNotEmpty) {
      await attach(relationName, toAttach, pivotData: pivotData);
    }

    // If nothing changed, still reload to sync cache
    if (toDetach.isEmpty && toAttach.isEmpty) {
      await load(relationName);
    }

    return _self();
  }

  /// Updates pivot table attributes for an existing pivot record.
  ///
  /// Unlike [attach] with pivotData, this only updates the pivot attributes
  /// for an already attached related model.
  ///
  /// Example:
  /// ```dart
  /// final post = await Post.query().find(1);
  /// // Post has tag 5 attached with order=1
  /// await post.updateExistingPivot('tags', 5, {'order': 2, 'featured': true});
  /// // Pivot record updated
  /// ```
  Future<TModel> updateExistingPivot(
    String relationName,
    dynamic id,
    Map<String, dynamic> pivotData,
  ) async {
    final def = expectDefinition();
    final resolver = _resolveResolverFor(def);

    final relationDef = def.relations.cast<RelationDefinition?>().firstWhere(
      (r) => r?.name == relationName,
      orElse: () => null,
    );

    if (relationDef == null) {
      throw ArgumentError(
        'Relation "$relationName" not found on ${def.modelName}',
      );
    }

    if (relationDef.kind != RelationKind.manyToMany) {
      throw ArgumentError(
        'updateExistingPivot() can only be used with manyToMany relations. '
        'Relation "$relationName" is ${relationDef.kind}',
      );
    }

    // Get this model's primary key value
    final pk = def.primaryKeyField;
    if (pk == null) {
      throw StateError('Model ${def.modelName} must have a primary key');
    }

    final pkValue = _primaryKeyValue(def);
    if (pkValue == null) {
      throw StateError('Model ${def.modelName} primary key value is null');
    }

    final pivotTable = relationDef.through;
    if (pivotTable == null) {
      throw StateError(
        'Relation "$relationName" is missing pivot table name (through)',
      );
    }

    final pivotForeignKey = relationDef.pivotForeignKey!;
    final pivotRelatedKey = relationDef.pivotRelatedKey!;

    // Get the related model definition
    final relatedModelName = relationDef.targetModel;
    final relatedDef = resolver.registry.expectByName(relatedModelName);
    final relatedPk = relatedDef.primaryKeyField;
    if (relatedPk == null) {
      throw StateError(
        'Related model $relatedModelName must have a primary key',
      );
    }

    // Build pivot definition with all fields
    final pivotDef = _createPivotDefinition(pivotTable, def.schema, {
      pivotForeignKey: pk,
      pivotRelatedKey: relatedPk,
      ...pivotData.map((key, _) => MapEntry(key, null)),
    });

    // Update the pivot record
    final plan = MutationPlan.update(
      definition: pivotDef,
      rows: [
        MutationRow(
          values: pivotData,
          keys: {pivotForeignKey: pkValue, pivotRelatedKey: id},
        ),
      ],
    );

    await resolver.runMutation(plan);

    // Reload the relation to sync cache
    await load(relationName);

    return _self();
  }

  /// Helper to get currently attached related IDs in a manyToMany relationship.
  Future<List<dynamic>> _getPivotRelatedIds(
    RelationDefinition relationDef,
    ModelDefinition<TModel> def,
    ConnectionResolver resolver,
  ) async {
    final pk = def.primaryKeyField;
    if (pk == null) {
      throw StateError('Model ${def.modelName} must have a primary key');
    }

    final pkValue = _primaryKeyValue(def);
    if (pkValue == null) {
      throw StateError('Model ${def.modelName} primary key value is null');
    }

    final pivotTable = relationDef.through;
    if (pivotTable == null) {
      throw StateError(
        'Relation "${relationDef.name}" is missing pivot table name (through)',
      );
    }

    final pivotForeignKey = relationDef.pivotForeignKey!;
    final pivotRelatedKey = relationDef.pivotRelatedKey!;

    // Get the related model definition
    final relatedModelName = relationDef.targetModel;
    final relatedDef = resolver.registry.expectByName(relatedModelName);
    final relatedPk = relatedDef.primaryKeyField;
    if (relatedPk == null) {
      throw StateError(
        'Related model $relatedModelName must have a primary key',
      );
    }

    final pivotDef = _createPivotDefinition(pivotTable, def.schema, {
      pivotForeignKey: pk,
      pivotRelatedKey: relatedPk,
    });

    final selectPlan = QueryPlan(
      definition: pivotDef,
      filters: [
        FilterClause(
          field: pivotForeignKey,
          operator: FilterOperator.equals,
          value: pkValue,
        ),
      ],
    );

    final results = await resolver.runSelect(selectPlan);
    return results.map((row) => row[pivotRelatedKey]).toList();
  }

  // ==========================================================================
  // HasOne / HasMany relation mutation methods
  // ==========================================================================

  /// Saves a related model through a hasOne or hasMany relationship.
  ///
  /// This sets the foreign key on the related model to point to this model,
  /// then persists the related model.
  ///
  /// Example:
  /// ```dart
  /// final author = await Author.query().find(1);
  /// final post = Post(title: 'New Post', publishedAt: DateTime.now());
  /// await author.saveRelation('posts', post);
  /// // post.authorId is now author.id
  /// ```
  Future<TRelated> saveRelation<TRelated extends Model<TRelated>>(
    String relationName,
    TRelated related,
  ) async {
    final def = expectDefinition();
    final resolver = _resolveResolverFor(def);

    final relationDef = def.relations.cast<RelationDefinition?>().firstWhere(
      (r) => r?.name == relationName,
      orElse: () => null,
    );

    if (relationDef == null) {
      throw ArgumentError(
        'Relation "$relationName" not found on ${def.modelName}',
      );
    }

    if (relationDef.kind != RelationKind.hasOne &&
        relationDef.kind != RelationKind.hasMany) {
      throw ArgumentError(
        'saveRelation() can only be used with hasOne or hasMany relations. '
        'Relation "$relationName" is ${relationDef.kind}',
      );
    }

    // Get this model's primary key value (the local key for hasOne/hasMany)
    // Default to 'id' if localKey is not specified
    final localKey = relationDef.localKey ?? 'id';
    final localKeyValue = _getAttributeValue(localKey, def);
    if (localKeyValue == null) {
      throw StateError(
        'Model ${def.modelName} local key "$localKey" value is null',
      );
    }

    // Get related model definition
    final foreignKey = relationDef.foreignKey;
    final context = _requireQueryContext(resolver);
    final relatedDef =
        resolver.registry.expectByName(relationDef.targetModel)
            as ModelDefinition<TRelated>;
    final fkField = relatedDef.fields.firstWhere(
      (f) => f.columnName == foreignKey || f.name == foreignKey,
    );

    // Convert related model to map and add/override foreign key
    final relatedMap = relatedDef.toMap(
      related,
      registry: context.codecRegistry,
    );
    relatedMap[fkField.columnName] = localKeyValue;

    // Use upsert to save (handles both insert and update cases)
    final repo = context.repository<TRelated>();
    final saved = await repo.upsert(relatedMap);

    // Update relation cache
    if (relationDef.kind == RelationKind.hasOne) {
      _asRelations.setRelation(relationName, saved);
    } else {
      // For hasMany, add to the list
      final existing = _asRelations.getRelation<List<TRelated>>(relationName);
      if (existing != null) {
        _asRelations.setRelation(relationName, [...existing, saved]);
      } else {
        _asRelations.setRelation(relationName, [saved]);
      }
    }

    return saved;
  }

  /// Saves multiple related models through a hasMany relationship.
  ///
  /// This sets the foreign key on each related model to point to this model,
  /// then persists all related models.
  ///
  /// Example:
  /// ```dart
  /// final author = await Author.query().find(1);
  /// await author.saveManyRelation('posts', [
  ///   Post(title: 'Post 1', publishedAt: DateTime.now()),
  ///   Post(title: 'Post 2', publishedAt: DateTime.now()),
  /// ]);
  /// ```
  Future<List<TRelated>> saveManyRelation<TRelated extends Model<TRelated>>(
    String relationName,
    List<TRelated> related,
  ) async {
    final def = expectDefinition();

    final relationDef = def.relations.cast<RelationDefinition?>().firstWhere(
      (r) => r?.name == relationName,
      orElse: () => null,
    );

    if (relationDef == null) {
      throw ArgumentError(
        'Relation "$relationName" not found on ${def.modelName}',
      );
    }

    if (relationDef.kind != RelationKind.hasMany) {
      throw ArgumentError(
        'saveManyRelation() can only be used with hasMany relations. '
        'Relation "$relationName" is ${relationDef.kind}',
      );
    }

    final results = <TRelated>[];
    for (final model in related) {
      results.add(await saveRelation<TRelated>(relationName, model));
    }

    return results;
  }

  /// Creates a related model through a hasOne or hasMany relationship.
  ///
  /// This creates and persists a new related model with the foreign key
  /// automatically set to point to this model.
  ///
  /// The [attributes] parameter accepts:
  /// - A tracked model instance (`TRelated`).
  /// - An [InsertDto] or [UpdateDto] instance.
  /// - A `Map<String, Object?>` containing field/column values.
  ///
  /// Example:
  /// ```dart
  /// final author = await Author.query().find(1);
  /// final post = await author.createRelation<Post>('posts', {
  ///   'title': 'New Post',
  ///   'published_at': DateTime.now(),
  /// });
  /// // post.authorId is automatically set to author.id
  ///
  /// // Using a DTO:
  /// final post2 = await author.createRelation<Post>('posts',
  ///   PostInsertDto(title: 'DTO Post', publishedAt: DateTime.now()),
  /// );
  /// ```
  Future<TRelated> createRelation<TRelated extends Model<TRelated>>(
    String relationName,
    Object attributes,
  ) async {
    final def = expectDefinition();
    final resolver = _resolveResolverFor(def);

    final relationDef = def.relations.cast<RelationDefinition?>().firstWhere(
      (r) => r?.name == relationName,
      orElse: () => null,
    );

    if (relationDef == null) {
      throw ArgumentError(
        'Relation "$relationName" not found on ${def.modelName}',
      );
    }

    if (relationDef.kind != RelationKind.hasOne &&
        relationDef.kind != RelationKind.hasMany) {
      throw ArgumentError(
        'createRelation() can only be used with hasOne or hasMany relations. '
        'Relation "$relationName" is ${relationDef.kind}',
      );
    }

    // Get this model's local key value
    // Default to 'id' if localKey is not specified
    final localKey = relationDef.localKey ?? 'id';
    final localKeyValue = _getAttributeValue(localKey, def);
    if (localKeyValue == null) {
      throw StateError(
        'Model ${def.modelName} local key "$localKey" value is null',
      );
    }

    // Add foreign key to attributes
    final foreignKey = relationDef.foreignKey;
    final context = _requireQueryContext(resolver);
    final relatedDef =
        resolver.registry.expectByName(relationDef.targetModel)
            as ModelDefinition<TRelated>;
    final fkField = relatedDef.fields.firstWhere(
      (f) => f.columnName == foreignKey || f.name == foreignKey,
    );

    // Normalize the input to a map using MutationInputHelper
    final helper = MutationInputHelper<TRelated>(
      definition: relatedDef,
      codecs: context.codecRegistry,
    );
    final normalizedMap = helper.insertInputToMap(
      attributes,
      applySentinelFiltering: attributes is TRelated,
    );
    final attributesWithFk = {
      ...normalizedMap,
      fkField.columnName: localKeyValue,
    };

    // Create the related model using repository
    final repo = context.repository<TRelated>();
    final created = await repo.insert(attributesWithFk);

    // Update relation cache
    if (relationDef.kind == RelationKind.hasOne) {
      _asRelations.setRelation(relationName, created);
    } else {
      final existing = _asRelations.getRelation<List<TRelated>>(relationName);
      if (existing != null) {
        _asRelations.setRelation(relationName, [...existing, created]);
      } else {
        _asRelations.setRelation(relationName, [created]);
      }
    }

    return created;
  }

  /// Creates multiple related models through a hasMany relationship.
  ///
  /// Each item in [attributesList] accepts:
  /// - A tracked model instance (`TRelated`).
  /// - An [InsertDto] or [UpdateDto] instance.
  /// - A `Map<String, Object?>` containing field/column values.
  ///
  /// Example:
  /// ```dart
  /// final author = await Author.query().find(1);
  /// final posts = await author.createManyRelation<Post>('posts', [
  ///   {'title': 'Post 1', 'published_at': DateTime.now()},
  ///   {'title': 'Post 2', 'published_at': DateTime.now()},
  /// ]);
  ///
  /// // Using DTOs:
  /// final posts2 = await author.createManyRelation<Post>('posts', [
  ///   PostInsertDto(title: 'DTO 1', publishedAt: DateTime.now()),
  ///   PostInsertDto(title: 'DTO 2', publishedAt: DateTime.now()),
  /// ]);
  /// ```
  Future<List<TRelated>> createManyRelation<TRelated extends Model<TRelated>>(
    String relationName,
    List<Object> attributesList,
  ) async {
    final def = expectDefinition();

    final relationDef = def.relations.cast<RelationDefinition?>().firstWhere(
      (r) => r?.name == relationName,
      orElse: () => null,
    );

    if (relationDef == null) {
      throw ArgumentError(
        'Relation "$relationName" not found on ${def.modelName}',
      );
    }

    if (relationDef.kind != RelationKind.hasMany) {
      throw ArgumentError(
        'createManyRelation() can only be used with hasMany relations. '
        'Relation "$relationName" is ${relationDef.kind}',
      );
    }

    final results = <TRelated>[];
    for (final attributes in attributesList) {
      results.add(await createRelation<TRelated>(relationName, attributes));
    }

    return results;
  }

  /// Creates a related model without firing model events.
  ///
  /// Same as [createRelation] but bypasses model event dispatching.
  /// No creating/created/saving/saved events are fired during insertion.
  ///
  /// The [attributes] parameter accepts:
  /// - A tracked model instance (`TRelated`).
  /// - An [InsertDto] or [UpdateDto] instance.
  /// - A `Map<String, Object?>` containing field/column values.
  ///
  /// Example:
  /// ```dart
  /// final author = await Author.query().find(1);
  /// final post = await author.createQuietlyRelation<Post>('posts', {
  ///   'title': 'New Post',
  ///   'published_at': DateTime.now(),
  /// });
  ///
  /// // Using a DTO:
  /// final post2 = await author.createQuietlyRelation<Post>('posts',
  ///   PostInsertDto(title: 'DTO Post', publishedAt: DateTime.now()),
  /// );
  /// ```
  Future<TRelated> createQuietlyRelation<TRelated extends Model<TRelated>>(
    String relationName,
    Object attributes,
  ) async {
    final def = expectDefinition();
    final resolver = _resolveResolverFor(def);

    final relationDef = def.relations.cast<RelationDefinition?>().firstWhere(
      (r) => r?.name == relationName,
      orElse: () => null,
    );

    if (relationDef == null) {
      throw ArgumentError(
        'Relation "$relationName" not found on ${def.modelName}',
      );
    }

    if (relationDef.kind != RelationKind.hasOne &&
        relationDef.kind != RelationKind.hasMany) {
      throw ArgumentError(
        'createQuietlyRelation() can only be used with hasOne or hasMany relations. '
        'Relation "$relationName" is ${relationDef.kind}',
      );
    }

    // Get this model's local key value
    final localKey = relationDef.localKey ?? 'id';
    final localKeyValue = _getAttributeValue(localKey, def);
    if (localKeyValue == null) {
      throw StateError(
        'Model ${def.modelName} local key "$localKey" value is null',
      );
    }

    // Add foreign key to attributes
    final foreignKey = relationDef.foreignKey;
    final context = _requireQueryContext(resolver);
    final relatedDef =
        resolver.registry.expectByName(relationDef.targetModel)
            as ModelDefinition<TRelated>;
    final fkField = relatedDef.fields.firstWhere(
      (f) => f.columnName == foreignKey || f.name == foreignKey,
    );

    // Normalize the input to a map using MutationInputHelper
    final helper = MutationInputHelper<TRelated>(
      definition: relatedDef,
      codecs: context.codecRegistry,
    );
    final normalizedMap = helper.insertInputToMap(
      attributes,
      applySentinelFiltering: attributes is TRelated,
    );
    final attributesWithFk = {
      ...normalizedMap,
      fkField.columnName: localKeyValue,
    };

    // Create the related model using query with events suppressed
    final relatedQuery = Query<TRelated>(
      definition: relatedDef,
      context: context,
    );

    final results = await relatedQuery.withoutEvents().insertManyInputs([attributesWithFk]);
    final created = results.first;

    // Update relation cache
    if (relationDef.kind == RelationKind.hasOne) {
      _asRelations.setRelation(relationName, created);
    } else {
      final existing = _asRelations.getRelation<List<TRelated>>(relationName);
      if (existing != null) {
        _asRelations.setRelation(relationName, [...existing, created]);
      } else {
        _asRelations.setRelation(relationName, [created]);
      }
    }

    return created;
  }

  /// Creates multiple related models without firing model events.
  ///
  /// Same as [createManyRelation] but bypasses model event dispatching.
  /// No creating/created/saving/saved events are fired during insertion.
  ///
  /// Each item in [attributesList] accepts:
  /// - A tracked model instance (`TRelated`).
  /// - An [InsertDto] or [UpdateDto] instance.
  /// - A `Map<String, Object?>` containing field/column values.
  ///
  /// Example:
  /// ```dart
  /// final author = await Author.query().find(1);
  /// final posts = await author.createManyQuietlyRelation<Post>('posts', [
  ///   {'title': 'Post 1', 'published_at': DateTime.now()},
  ///   {'title': 'Post 2', 'published_at': DateTime.now()},
  /// ]);
  ///
  /// // Using DTOs:
  /// final posts2 = await author.createManyQuietlyRelation<Post>('posts', [
  ///   PostInsertDto(title: 'DTO 1', publishedAt: DateTime.now()),
  ///   PostInsertDto(title: 'DTO 2', publishedAt: DateTime.now()),
  /// ]);
  /// ```
  Future<List<TRelated>> createManyQuietlyRelation<TRelated extends Model<TRelated>>(
    String relationName,
    List<Object> attributesList,
  ) async {
    if (attributesList.isEmpty) return [];

    final results = <TRelated>[];
    for (final attributes in attributesList) {
      results.add(await createQuietlyRelation<TRelated>(relationName, attributes));
    }

    return results;
  }

  /// Helper to get an attribute value by field name or column name.
  Object? _getAttributeValue(String key, ModelDefinition<TModel> def) {
    // Try to find the field
    final field = def.fields.cast<FieldDefinition?>().firstWhere(
      (f) => f?.name == key || f?.columnName == key,
      orElse: () => null,
    );

    if (field != null) {
      return _asAttributes.getAttribute(field.columnName);
    }

    // Fallback to direct attribute access
    return _asAttributes.getAttribute(key);
  }

  /// Creates a minimal ModelDefinition for a pivot table.
  ///
  /// Uses 'int' as the type for all columns since pivot keys are typically integers.
  /// The codec handles conversion appropriately.
  static ModelDefinition<AdHocRow> _createPivotDefinition(
    String tableName,
    String? schema,
    Map<String, FieldDefinition?> columnFields,
  ) {
    final fields = columnFields.entries.map((entry) {
      final colName = entry.key;
      final fieldDef = entry.value;

      // Use the field definition's types if available, otherwise default to dynamic
      return FieldDefinition(
        name: colName,
        columnName: colName,
        dartType: fieldDef?.dartType ?? 'dynamic',
        resolvedType: fieldDef?.resolvedType ?? 'dynamic',
        isPrimaryKey: false,
        isNullable: true,
      );
    }).toList();

    return ModelDefinition<AdHocRow>(
      modelName: tableName,
      tableName: tableName,
      schema: schema,
      fields: fields,
      relations: const [],
      codec: const _PivotTableCodec(),
    );
  }
}

/// Simple codec for pivot table operations (raw maps).
class _PivotTableCodec extends ModelCodec<AdHocRow> {
  const _PivotTableCodec();

  @override
  Map<String, Object?> encode(AdHocRow model, ValueCodecRegistry registry) =>
      Map<String, Object?>.from(model);

  @override
  AdHocRow decode(Map<String, Object?> data, ValueCodecRegistry registry) =>
      AdHocRow(data);
}

extension ModelRegistryX on ModelRegistry {
  /// Fluent helper for registering definitions tied to [Model] subclasses.
  ModelRegistry registerModel<TModel extends Model<TModel>>(
    ModelDefinition<TModel> definition,
  ) {
    register(definition);
    return this;
  }
}
