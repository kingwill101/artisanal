part of '../query_builder.dart';

/// {@template ormed.query.where_input}
/// The [where] parameter accepts:
/// - A primary key value (for example, `1` or `'uuid'`).
/// - `Map<String, Object?>` containing column/value pairs.
/// - A generated [PartialEntity] (for example, `$UserPartial`).
/// - An [InsertDto] or [UpdateDto] instance (for example, `$UserUpdateDto`).
/// - A tracked model instance (`T` / `$User`), which matches on mapped columns.
/// - A pre-built `Query<T>` (which must use the same [QueryContext]).
/// - A `Query<T> Function(Query<T>)` callback that builds a query.
///
/// When passing a callback, explicitly type its parameter (for example,
/// `(Query<$User> q) => q.whereEquals('email', 'john@example.com')`) so
/// extension methods are available.
/// {@endtemplate}
///
/// {@template ormed.query.insert_inputs}
/// Insert inputs may be:
/// - A tracked model instance (`T` / `$User`).
/// - An [InsertDto] or [UpdateDto] instance.
/// - A `Map<String, Object?>` containing field/column values.
///
/// Map keys may use either Dart field names or database column names. Ormed
/// normalizes them to column names using the model definition.
/// {@endtemplate}
///
/// {@template ormed.query.update_inputs}
/// Update inputs may be:
/// - A tracked model instance (`T` / `$User`).
/// - An [UpdateDto] or [InsertDto] instance.
/// - A `Map<String, Object?>` containing field/column values.
///
/// Map keys may use either Dart field names or database column names. Ormed
/// normalizes them to column names using the model definition.
/// {@endtemplate}
///
/// {@template ormed.query.upsert_options}
/// [uniqueBy] controls the conflict target (defaults to the primary key, when
/// available).
///
/// [updateColumns] controls which columns are updated on conflict. When
/// omitted, the driver chooses its default update set.
/// {@endtemplate}
///
/// {@template ormed.mutation.json_updates}
/// [jsonUpdates] defines JSON-path updates to apply alongside the regular
/// mutation values.
///
/// This callback is applied per tracked model input (`T` / `$User`). It is not
/// invoked for DTO/map inputs.
///
/// Tracked models may also accumulate JSON updates via runtime helpers; those
/// pending updates are automatically included.
///
/// ```dart
/// final updated = await context.query<$User>().updateInputs(
///   [user],
///   jsonUpdates: (u) => [
///     JsonUpdateDefinition.path('profile', r'$.settings.theme', 'dark'),
///     JsonUpdateDefinition.patch('profile', {'lastSeen': DateTime.now()}),
///   ],
/// );
/// ```
/// {@endtemplate}
///
/// {@template ormed.mutation.hydration}
/// When the driver returns row data (for example, via SQL `RETURNING`), Ormed
/// hydrates models by merging returned data with the original inputs.
///
/// Merge priority: returned data > original model data > input map data.
///
/// Some drivers only return generated keys (for example, a last-insert ID)
/// rather than full rows. In those cases, hydrated models may include a mix of
/// database-returned values and input-provided values.
/// {@endtemplate}
///
/// Private anchor for shared dartdoc templates.
final class _UpdateInputBuildResult<T extends OrmEntity> {
  _UpdateInputBuildResult({
    required this.rows,
    required this.originalModels,
    required this.inputMaps,
  });

  final List<MutationRow> rows;
  final List<T> originalModels;
  final List<Map<String, Object?>> inputMaps;
}

final class _InsertInputBuildResult<T extends OrmEntity> {
  _InsertInputBuildResult({
    required this.rows,
    required this.originalModels,
    required this.inputMaps,
  });

  final List<Map<String, Object?>> rows;
  final List<T> originalModels;
  final List<Map<String, Object?>> inputMaps;
}

extension CrudExtension<T extends OrmEntity> on Query<T> {
  // ========================================================================
  // CRUD Operations
  // ========================================================================

  /// Creates a single record from the given attributes map.
  /// Returns the created model instance with its generated ID.
  ///
  /// Example:
  /// ```dart
  /// final user = await User.query().create({
  ///   'name': 'John Doe',
  ///   'email': 'john@example.com',
  /// });
  /// ```
  Future<T> create(Map<String, dynamic> attributes) async {
    final results = await insertManyInputs([attributes]);
    if (results.isEmpty) {
      throw StateError('Failed to create record');
    }
    return results.first;
  }

  /// Creates multiple records from a list of attribute maps.
  /// Returns the created model instances with their generated IDs.
  ///
  /// Example:
  /// ```dart
  /// final users = await User.query().createMany([
  ///   {'name': 'John Doe', 'email': 'john@example.com'},
  ///   {'name': 'Jane Smith', 'email': 'jane@example.com'},
  /// ]);
  /// ```
  Future<List<T>> createMany(List<Map<String, dynamic>> records) async {
    return insertManyInputs(records);
  }

  /// Inserts flexible inputs and returns hydrated models.
  ///
  /// {@macro ormed.query.insert_inputs}
  /// {@macro ormed.mutation.hydration}
  Future<List<T>> insertManyInputs(
    List<Object> inputs, {
    bool ignoreConflicts = false,
    bool returning = true,
    bool fallbackToOriginalWhenNoReturn = true,
  }) async {
    final build = _buildInsertRows(inputs);
    if (build.rows.isEmpty) return const [];

    final entries = _zipInsertEntries(inputs, build);
    final ready = <_InsertEntry<T>>[];

    for (final entry in entries) {
      if (!_emitSavingEvent(entry.model, entry.inputMap)) continue;

      if (!_suppressEvents) {
        final creatingEvent = ModelCreatingEvent(
          modelType: definition.modelType,
          tableName: definition.tableName,
          attributes: Map<String, dynamic>.from(entry.inputMap),
        );
        _events.emit(creatingEvent);
        if (creatingEvent.isCancelled) continue;
      }
      ready.add(entry);
    }

    if (ready.isEmpty) return const [];

    final mutation = MutationPlan.insert(
      definition: definition,
      rows: ready.map((entry) => entry.row).toList(growable: false),
      driverName: context.driver.metadata.name,
      returning: returning,
      ignoreConflicts: ignoreConflicts,
    );

    final result = await context.runMutation(mutation);
    if (ignoreConflicts && result.affectedRows == 0) {
      return const [];
    }

    final originalModels = ready
        .map((entry) => entry.model)
        .whereType<T>()
        .toList(growable: false);
    final inputMaps = ready
        .map((entry) => entry.inputMap)
        .toList(growable: false);

    final models = _hydrateMutationResults(
      result,
      originalModels: originalModels,
      inputMaps: inputMaps,
      canCreateFromInputs: !ignoreConflicts,
      fallbackToOriginalWhenNoReturn: fallbackToOriginalWhenNoReturn,
    );

    _emitCreatedEvents(models, inputMaps);
    _emitSavedEvents(models, inputMaps);
    return models;
  }

  /// Inserts flexible inputs and returns the raw [MutationResult].
  ///
  /// Use when only affected row counts are needed (e.g., insertOrIgnore).
  ///
  /// {@macro ormed.query.insert_inputs}
  Future<MutationResult> insertManyInputsRaw(
    List<Object> inputs, {
    bool ignoreConflicts = false,
  }) async {
    final build = _buildInsertRows(inputs);
    if (build.rows.isEmpty) {
      return const MutationResult(affectedRows: 0);
    }

    final entries = _zipInsertEntries(inputs, build);
    final ready = <_InsertEntry<T>>[];

    for (final entry in entries) {
      if (!_emitSavingEvent(entry.model, entry.inputMap)) continue;

      if (!_suppressEvents) {
        final creatingEvent = ModelCreatingEvent(
          modelType: definition.modelType,
          tableName: definition.tableName,
          attributes: Map<String, dynamic>.from(entry.inputMap),
        );
        _events.emit(creatingEvent);
        if (creatingEvent.isCancelled) continue;
      }
      ready.add(entry);
    }

    if (ready.isEmpty) {
      return const MutationResult(affectedRows: 0);
    }

    final mutation = MutationPlan.insert(
      definition: definition,
      rows: ready.map((entry) => entry.row).toList(growable: false),
      driverName: context.driver.metadata.name,
      returning: false,
      ignoreConflicts: ignoreConflicts,
    );
    final result = await context.runMutation(mutation);
    if (ignoreConflicts && result.affectedRows == 0) {
      return result;
    }

    final originalModels = ready
        .map((entry) => entry.model)
        .whereType<T>()
        .toList(growable: false);
    final inputMaps = ready
        .map((entry) => entry.inputMap)
        .toList(growable: false);
    final hydrated = _hydrateMutationResults(
      result,
      originalModels: originalModels,
      inputMaps: inputMaps,
      canCreateFromInputs: !ignoreConflicts,
    );
    _emitCreatedEvents(hydrated, inputMaps);
    _emitSavedEvents(hydrated, inputMaps);
    return result;
  }

  /// Builds but does not execute an insert plan (useful for previews).
  MutationPlan previewInsertPlan(
    List<Object> inputs, {
    bool ignoreConflicts = false,
    bool returning = false,
  }) => _buildInsertPlanFromInputs(
    inputs,
    returning: returning,
    ignoreConflicts: ignoreConflicts,
  );

  Future<T> insertInput(Object input, {bool ignoreConflicts = false}) async {
    final results = await insertManyInputs([
      input,
    ], ignoreConflicts: ignoreConflicts);
    if (results.isEmpty) {
      throw StateError('Failed to create record');
    }
    return results.first;
  }

  /// Finds the first record matching the attributes, or creates it if not found.
  ///
  /// The [attributes] map is used for searching.
  /// The [values] map provides additional attributes for creation if needed.
  ///
  /// Example:
  /// ```dart
  /// final user = await User.query().firstOrCreate(
  ///   {'email': 'john@example.com'},
  ///   {'name': 'John Doe'},
  /// });
  /// ```
  Future<T> firstOrCreate(
    Map<String, dynamic> attributes, [
    Map<String, dynamic> values = const {},
  ]) async {
    // Try to find existing
    var query = this;
    for (final entry in attributes.entries) {
      query = query.where(entry.key, entry.value, .equals);
    }

    final existing = await query.first();
    if (existing != null) {
      return existing;
    }

    // Create new record
    final combined = {...attributes, ...values};
    return await create(combined);
  }

  /// Updates the first record matching the attributes, or creates it if not found.
  ///
  /// The [attributes] map is used for searching.
  /// The [values] map provides the data to update or create with.
  ///
  /// Example:
  /// ```dart
  /// final user = await User.query().updateOrCreate(
  ///   {'email': 'john@example.com'},
  ///   {'name': 'John Updated'},
  /// );
  /// ```
  Future<T> updateOrCreate(
    Map<String, dynamic> attributes,
    Map<String, dynamic> values,
  ) async {
    // Try to find existing
    var query = this;
    for (final entry in attributes.entries) {
      query = query.where(entry.key, entry.value, PredicateOperator.equals);
    }

    final existing = await query.first();
    if (existing != null) {
      // Update existing
      await query.update(values);
      // Reload to get updated values
      return await query.first() ?? existing;
    }

    // Create new record
    final combined = {...attributes, ...values};
    return await create(combined);
  }

  /// Deletes records by their primary key(s).
  /// Accepts a single ID or a list of IDs.
  /// Returns the number of deleted rows.
  ///
  /// Example:
  /// ```dart
  /// await User.query().destroy(1);
  /// await User.query().destroy([1, 2, 3]);
  /// ```
  Future<int> destroy(dynamic ids) async {
    final pkField = definition.primaryKeyField;
    if (pkField == null) {
      throw StateError('Cannot destroy records without a primary key');
    }

    final idList = ids is List ? ids : [ids];
    if (idList.isEmpty) {
      return 0;
    }

    return await whereIn(pkField.name, idList).delete();
  }

  /// Executes the query and returns hydrated [QueryRow] objects.
  ///
  /// Each [QueryRow] contains the materialized model and its raw data.
  ///
  /// Example:
  /// ```dart
  /// final userRows = await context.query<User>().rows();
  /// for (final row in userRows) {
  ///   print('User ID: ${row.model.id}, Raw data: ${row.row}');
  /// }
  /// ```
  Future<List<QueryRow<T>>> rows() async {
    final plan = _buildPlan();
    final rows = await context.runSelect(plan);
    final queryRows = rows
        .map((row) => _hydrateRow(row, plan))
        .toList(growable: true);
    await _applyRelationHookBatch(plan, queryRows);
    return queryRows;
  }

  /// Returns only the models without the surrounding [QueryRow] metadata.
  ///
  /// Example:
  /// ```dart
  /// final users = await context.query<User>().get();
  /// for (final user in users) {
  ///   print('User name: ${user.name}');
  /// }
  /// ```
  Future<List<T>> get() async =>
      (await rows()).map((row) => row.model).toList(growable: false);

  /// Updates matching records using flexible inputs.
  ///
  /// {@macro ormed.query.update_inputs}
  ///
  /// This overload matches Repository ergonomics.
  Future<int> updateValues(Object values) async {
    final helper = MutationInputHelper<T>(
      definition: definition,
      codecs: context.codecRegistry,
    );
    final normalized = helper.updateInputToMap(values);
    return update(normalized);
  }

  /// Returns results hydrated into partial entities.
  ///
  /// Use this when you only need a subset of columns and want the
  /// type safety of the generated partial class.
  ///
  /// The [factory] parameter is the `fromRow` factory from the generated
  /// partial class (e.g., `UserPartial.fromRow`).
  ///
  /// Example:
  /// ```dart
  /// final partials = await context.query<User>()
  ///   .select(['id', 'email'])
  ///   .getPartial(UserPartial.fromRow);
  ///
  /// for (final partial in partials) {
  ///   print('User email: ${partial.email}');
  ///   // partial.toEntity() will throw if required fields are missing
  /// }
  /// ```
  Future<List<P>> getPartial<P extends PartialEntity<T>>(
    P Function(Map<String, Object?>) factory,
  ) async {
    final plan = _buildPlan();
    final rows = await context.runSelect(plan);
    return rows.map(factory).toList(growable: false);
  }

  /// Returns the first result as a partial entity or `null` if none exist.
  ///
  /// Use this when you only need a subset of columns from the first row.
  ///
  /// Example:
  /// ```dart
  /// final partial = await context.query<User>()
  ///   .where('id', 1)
  ///   .select(['id', 'email'])
  ///   .firstPartial(UserPartial.fromRow);
  ///
  /// if (partial != null) {
  ///   print('User email: ${partial.email}');
  /// }
  /// ```
  Future<P?> firstPartial<P extends PartialEntity<T>>(
    P Function(Map<String, Object?>) factory,
  ) async {
    final results = await limit(1).getPartial(factory);
    return results.isEmpty ? null : results.first;
  }

  /// Returns the first matching row or `null` if none exist.
  ///
  /// Example:
  /// ```dart
  /// final firstUserRow = await context.query<User>()
  ///   .orderBy('createdAt')
  ///   .firstRow();
  /// if (firstUserRow != null) {
  ///   print('First user: ${firstUserRow.model.name}');
  /// }
  /// ```
  Future<QueryRow<T>?> firstRow() async {
    final rows = await limit(1).rows();
    return rows.isEmpty ? null : rows.first;
  }

  /// Returns the first model instance or `null` when no rows exist.
  ///
  /// Example:
  /// ```dart
  /// final firstUser = await context.query<User>()
  ///   .orderBy('createdAt')
  ///   .first();
  /// if (firstUser != null) {
  ///   print('First user: ${firstUser.name}');
  /// }
  /// ```
  Future<T?> first() async => (await firstRow())?.model;

  /// Alias for [first] to match Laravel naming.
  Future<T?> firstOrNull() async => first();

  /// Returns the first model or throws when no records exist.
  ///
  /// Throws [ModelNotFoundException] if no record is found.
  ///
  /// Example:
  /// ```dart
  /// try {
  ///   final user = await context.query<User>().where('id', 1).firstOrFail();
  ///   print('Found user: ${user.name}');
  /// } on ModelNotFoundException {
  ///   print('User with ID 1 not found.');
  /// }
  /// ```
  Future<T> firstOrFail({Object? key}) async {
    final model = await first();
    if (model != null) {
      return model;
    }
    throw ModelNotFoundException(definition.modelName, key: key);
  }

  /// Ensures there is exactly one record and returns it.
  ///
  /// Throws [ModelNotFoundException] if no record is found.
  /// Throws [MultipleRecordsFoundException] if more than one record is found.
  ///
  /// Example:
  /// ```dart
  /// try {
  ///   final uniqueUser = await context.query<User>().where('email', 'unique@example.com').sole();
  ///   print('Found unique user: ${uniqueUser.name}');
  /// } on ModelNotFoundException {
  ///   print('No user found with that email.');
  /// } on MultipleRecordsFoundException {
  ///   print('Multiple users found with that email.');
  /// }
  /// ```
  Future<T> sole() async {
    final rows = await limit(2).rows();
    if (rows.isEmpty) {
      throw ModelNotFoundException(definition.modelName);
    }
    if (rows.length > 1) {
      throw MultipleRecordsFoundException(definition.modelName, rows.length);
    }
    return rows.first.model;
  }

  /// Finds a model by its primary key.
  ///
  /// Returns `null` if no model is found.
  /// Throws [StateError] if the model does not define a primary key.
  ///
  /// Example:
  /// ```dart
  /// final user = await context.query<User>().find(1);
  /// if (user != null) {
  ///   print('User found: ${user.name}');
  /// }
  /// ```
  Future<T?> find(Object key) async {
    final primaryKey = definition.primaryKeyField;
    if (primaryKey == null) {
      throw StateError(
        'Model ${definition.modelName} does not define a primary key.',
      );
    }
    return whereEquals(primaryKey.name, key).firstOrNull();
  }

  /// Finds multiple models by their primary keys.
  ///
  /// Returns an empty list if no models are found or [keys] is empty.
  /// Throws [StateError] if the model does not define a primary key.
  ///
  /// Example:
  /// ```dart
  /// final users = await context.query<User>().findMany([1, 2, 3]);
  /// print('Found ${users.length} users.');
  /// ```
  Future<List<T>> findMany(Iterable<Object> keys) async {
    final primaryKey = definition.primaryKeyField;
    if (primaryKey == null) {
      throw StateError(
        'Model ${definition.modelName} does not define a primary key.',
      );
    }
    final values = keys.toList(growable: false);
    if (values.isEmpty) return const [];
    return whereIn(primaryKey.name, values).get();
  }

  /// Finds a model by primary key or throws when missing.
  ///
  /// Throws [ModelNotFoundException] if no model is found.
  /// Throws [StateError] if the model does not define a primary key.
  ///
  /// Example:
  /// ```dart
  /// try {
  ///   final user = await context.query<User>().findOrFail(1);
  ///   print('Found user: ${user.name}');
  /// } on ModelNotFoundException {
  ///   print('User with ID 1 not found.');
  /// }
  /// ```
  Future<T> findOrFail(Object key) async {
    final primaryKey = definition.primaryKeyField;
    if (primaryKey == null) {
      throw StateError(
        'Model ${definition.modelName} does not define a primary key.',
      );
    }
    return whereEquals(primaryKey.name, key).firstOrFail(key: key);
  }

  /// Returns a list of values from [field].
  ///
  /// This is useful for retrieving a list of scalar values from a column.
  ///
  /// Example:
  /// ```dart
  /// final userNames = await context.query<User>()
  ///   .pluck<String>('name');
  /// print('All user names: $userNames');
  /// ```
  Future<List<R>> pluck<R>(String field) async {
    final column = _ensureField(field).columnName;
    final rows = await select(<String>[field]).rows();
    return rows.map((row) => row.row[column] as R).toList(growable: false);
  }

  /// Updates rows that match the current query constraints.
  ///
  /// [values] is a map where keys are column names and values are the new values.
  ///
  /// Example:
  /// ```dart
  /// final updatedCount = await context.query<User>()
  ///   .where('id', 1)
  ///   .update({'name': 'New Name', 'email': 'new@example.com'});
  /// print('Updated $updatedCount users.');
  /// ```
  Future<int> update(Map<String, Object?> values) async {
    if (values.isEmpty) {
      return 0;
    }

    // Add automatic timestamp management for updated_at
    final valuesWithTimestamp = _addUpdateTimestamp(values);

    final payload = _normalizeUpdateValues(valuesWithTimestamp);
    if (payload.isEmpty) {
      return 0;
    }
    final mutation = _buildQueryUpdateMutation(
      values: payload.values,
      jsonUpdates: payload.jsonUpdates,
      feature: 'update',
    );
    final result = await context.runMutation(mutation);
    return result.affectedRows;
  }

  /// Updates rows and returns hydrated models using driver RETURNING when available.
  ///
  /// {@macro ormed.query.update_inputs}
  ///
  /// {@macro ormed.mutation.hydration}
  Future<List<T>> updateReturning(Object values) async {
    final helper = MutationInputHelper<T>(
      definition: definition,
      codecs: context.codecRegistry,
    );
    final map = helper.updateInputToMap(values);
    if (map.isEmpty) return const [];

    final withTimestamp = _addUpdateTimestamp(map);
    final payload = _normalizeUpdateValues(withTimestamp);
    if (payload.isEmpty) return const [];

    final mutation = _buildQueryUpdateMutation(
      values: payload.values,
      jsonUpdates: payload.jsonUpdates,
      feature: 'updateReturning',
      returning: true,
    );
    final result = await context.runMutation(mutation);
    return _hydrateMutationResults(result, canCreateFromInputs: false);
  }

  /// Updates rows using flexible inputs.
  ///
  /// {@macro ormed.query.update_inputs}
  ///
  /// Matches repository semantics: keys are inferred from tracked models,
  /// explicit `where` input, or primary key values embedded in DTO/map data.
  /// Returns hydrated models when the driver supports RETURNING.
  ///
  /// {@macro ormed.query.where_input}
  /// {@macro ormed.mutation.json_updates}
  Future<List<T>> updateInputs(
    List<Object> inputs, {
    Object? where,
    JsonUpdateBuilder<T>? jsonUpdates,
  }) async {
    final whereQuery = _resolveWhereQuery(where, 'updateInputs');
    if (whereQuery != null) {
      return _updateInputsAgainstQuery(
        whereQuery,
        inputs,
        jsonUpdates: jsonUpdates,
      );
    }

    final build = _buildUpdateRows(
      inputs,
      where: where,
      jsonUpdates: jsonUpdates,
    );
    if (build.rows.isEmpty) return const [];

    final entries = _zipUpdateEntries(inputs, build);
    final ready = <_UpdateEntry<T>>[];

    for (final entry in entries) {
      if (!_emitSavingEvent(entry.model, entry.inputMap)) continue;

      if (!_suppressEvents &&
          entry.model != null &&
          entry.originalAttributes != null) {
        final updatingEvent = ModelUpdatingEvent(
          modelType: definition.modelType,
          tableName: definition.tableName,
          model: entry.model,
          originalAttributes: Map<String, dynamic>.from(
            entry.originalAttributes!,
          ),
          dirtyAttributes: Map<String, dynamic>.from(entry.dirtyAttributes),
        );
        _events.emit(updatingEvent);
        if (updatingEvent.isCancelled) continue;
      }
      ready.add(entry);
    }

    if (ready.isEmpty) return const [];

    final mutation = MutationPlan.update(
      definition: definition,
      rows: ready.map((entry) => entry.row).toList(growable: false),
      driverName: context.driver.metadata.name,
      returning: true,
    );
    final result = await context.runMutation(mutation);

    final originalModels = ready
        .map((entry) => entry.model)
        .whereType<T>()
        .toList();
    final inputMaps = ready
        .map((entry) => entry.inputMap)
        .toList(growable: false);

    final models = _hydrateMutationResults(
      result,
      originalModels: originalModels,
      inputMaps: inputMaps,
      canCreateFromInputs: false,
    );
    _emitUpdatedEvents(models, ready);
    _emitSavedEvents(models, inputMaps);
    return models;
  }

  /// Updates rows using flexible inputs and returns the raw [MutationResult].
  ///
  /// Mirrors [updateInputs] but skips hydration when RETURNING is unsupported
  /// or unnecessary.
  ///
  /// {@macro ormed.query.update_inputs}
  /// {@macro ormed.query.where_input}
  /// {@macro ormed.mutation.json_updates}
  Future<MutationResult> updateInputsRaw(
    List<Object> inputs, {
    Object? where,
    JsonUpdateBuilder<T>? jsonUpdates,
  }) async {
    final whereQuery = _resolveWhereQuery(where, 'updateInputsRaw');
    if (whereQuery != null) {
      return _updateInputsAgainstQueryRaw(
        whereQuery,
        inputs,
        jsonUpdates: jsonUpdates,
      );
    }

    final build = _buildUpdateRows(
      inputs,
      where: where,
      jsonUpdates: jsonUpdates,
    );
    if (build.rows.isEmpty) {
      return const MutationResult(affectedRows: 0);
    }

    final entries = _zipUpdateEntries(inputs, build);
    final ready = <_UpdateEntry<T>>[];

    for (final entry in entries) {
      if (!_emitSavingEvent(entry.model, entry.inputMap)) continue;

      if (!_suppressEvents &&
          entry.model != null &&
          entry.originalAttributes != null) {
        final updatingEvent = ModelUpdatingEvent(
          modelType: definition.modelType,
          tableName: definition.tableName,
          model: entry.model,
          originalAttributes: Map<String, dynamic>.from(
            entry.originalAttributes!,
          ),
          dirtyAttributes: Map<String, dynamic>.from(entry.dirtyAttributes),
        );
        _events.emit(updatingEvent);
        if (updatingEvent.isCancelled) continue;
      }
      ready.add(entry);
    }

    if (ready.isEmpty) {
      return const MutationResult(affectedRows: 0);
    }

    final mutation = MutationPlan.update(
      definition: definition,
      rows: ready.map((entry) => entry.row).toList(growable: false),
      driverName: context.driver.metadata.name,
    );
    return context.runMutation(mutation);
  }

  /// Builds but does not execute an update plan (useful for previews).
  MutationPlan previewUpdatePlan(
    List<Object> inputs, {
    Object? where,
    JsonUpdateBuilder<T>? jsonUpdates,
    bool returning = false,
  }) => _buildUpdatePlanFromInputs(
    inputs,
    where: where,
    jsonUpdates: jsonUpdates,
    returning: returning,
  );

  _UpdateInputBuildResult<T> _buildUpdateRows(
    List<Object> inputs, {
    Object? where,
    JsonUpdateBuilder<T>? jsonUpdates,
  }) {
    if (inputs.isEmpty) {
      return _UpdateInputBuildResult(
        rows: const [],
        originalModels: const [],
        inputMaps: const [],
      );
    }

    final helper = MutationInputHelper<T>(
      definition: definition,
      codecs: context.codecRegistry,
    );
    final jsonSupport = JsonUpdateSupport<T>(definition);
    final whereMap = helper.whereInputToMap(where);
    final pkField = definition.primaryKeyField;

    final rows = <MutationRow>[];
    final originalModels = <T>[];
    final inputMaps = <Map<String, Object?>>[];

    for (final input in inputs) {
      if (input is T) {
        helper.applyUpdateTimestampsToModel(input);
        originalModels.add(input);
      }

      final values = helper.updateInputToMap(input);

      if (input is! ModelAttributes) {
        helper.ensureTimestampsInMap(values, isInsert: false);
      }

      Map<String, Object?> keys;
      if (input is T) {
        final pk =
            pkField ??
            (throw StateError(
              'Primary key required for updates on ${definition.modelName}.',
            ));
        final allValues = definition.toMap(
          input,
          registry: context.codecRegistry,
        );
        final pkValue = allValues[pk.columnName];
        if (pkValue == null) {
          throw StateError('Primary key cannot be null for update.');
        }
        keys = {pk.columnName: pkValue};
      } else if (whereMap != null) {
        keys = whereMap;
      } else {
        final pk = helper.extractPrimaryKey(input);
        final pkColumn = pkField?.columnName;
        if (pk == null || pkColumn == null) {
          throw ArgumentError(
            'Update with DTO or Map requires a "where" clause or PK in the data.',
          );
        }
        keys = {pkColumn: pk};
      }

      final jsonClauses = input is T
          ? jsonSupport.buildJsonUpdates(input, jsonUpdates)
          : const <JsonUpdateClause>[];

      rows.add(
        MutationRow(values: values, keys: keys, jsonUpdates: jsonClauses),
      );
      inputMaps.add({...values, ...keys});
    }

    return _UpdateInputBuildResult(
      rows: rows,
      originalModels: originalModels,
      inputMaps: inputMaps,
    );
  }

  MutationPlan _buildUpdatePlanFromInputs(
    List<Object> inputs, {
    Object? where,
    JsonUpdateBuilder<T>? jsonUpdates,
    bool returning = false,
  }) {
    final build = _buildUpdateRows(
      inputs,
      where: where,
      jsonUpdates: jsonUpdates,
    );
    return MutationPlan.update(
      definition: definition,
      rows: build.rows,
      driverName: context.driver.metadata.name,
      returning: returning,
    );
  }

  Future<List<T>> _updateInputsAgainstQuery(
    Query<T> target,
    List<Object> inputs, {
    JsonUpdateBuilder<T>? jsonUpdates,
  }) async {
    if (inputs.isEmpty) return const [];
    if (inputs.length != 1) {
      throw ArgumentError(
        'updateInputs with a Query where requires exactly one input; '
        'received ${inputs.length}.',
      );
    }

    final input = inputs.single;
    final helper = MutationInputHelper<T>(
      definition: definition,
      codecs: context.codecRegistry,
    );
    final jsonSupport = JsonUpdateSupport<T>(definition);

    Map<String, Object?>? originalAttributes;
    Map<String, Object?> dirtyAttributes = const {};

    if (input is T) {
      helper.applyUpdateTimestampsToModel(input);
      if (input is ModelAttributes) {
        final attrs = input as ModelAttributes;
        final originalMap = attrs.getOriginal();
        if (originalMap is Map<String, Object?>) {
          originalAttributes = Map<String, Object?>.from(originalMap);
        }
        dirtyAttributes = Map<String, Object?>.from(attrs.getDirty());
      } else {
        originalAttributes = definition.toMap(
          input,
          registry: context.codecRegistry,
        );
      }
    }

    final baseValues = helper.updateInputToMap(input);
    if (input is! ModelAttributes) {
      helper.ensureTimestampsInMap(baseValues, isInsert: false);
    }

    final payload = _normalizeUpdateValues(_addUpdateTimestamp(baseValues));
    final jsonClauses = input is T
        ? jsonSupport.buildJsonUpdates(input, jsonUpdates)
        : const <JsonUpdateClause>[];

    if (payload.values.isEmpty &&
        payload.jsonUpdates.isEmpty &&
        jsonClauses.isEmpty) {
      return const [];
    }

    if (input is T && originalAttributes != null) {
      if (!_emitSavingEvent(input, baseValues)) {
        return const [];
      }

      if (!_suppressEvents) {
        final updatingEvent = ModelUpdatingEvent(
          modelType: definition.modelType,
          tableName: definition.tableName,
          model: input,
          originalAttributes: Map<String, dynamic>.from(originalAttributes),
          dirtyAttributes: Map<String, dynamic>.from(dirtyAttributes),
        );
        target._events.emit(updatingEvent);
        if (updatingEvent.isCancelled) {
          return const [];
        }
      }
    } else {
      if (!_emitSavingEvent(null, baseValues)) {
        return const [];
      }
    }

    final mutation = target._buildQueryUpdateMutation(
      values: payload.values,
      jsonUpdates: [...payload.jsonUpdates, ...jsonClauses],
      feature: 'updateInputs.queryWhere',
      returning: true,
    );

    final result = await target.context.runMutation(mutation);
    final models = _hydrateMutationResults(
      result,
      originalModels: input is T ? <T>[input] : const [],
      inputMaps: <Map<String, Object?>>[baseValues],
      canCreateFromInputs: false,
    );
    _emitUpdatedEvents(models, [
      _UpdateEntry<T>(
        row: MutationRow(
          values: payload.values,
          keys: const {},
          jsonUpdates: [...payload.jsonUpdates, ...jsonClauses],
        ),
        inputMap: baseValues,
        model: input is T ? input : null,
        originalAttributes: originalAttributes,
        dirtyAttributes: dirtyAttributes,
      ),
    ]);
    _emitSavedEvents(models, [baseValues]);
    return models;
  }

  Future<MutationResult> _updateInputsAgainstQueryRaw(
    Query<T> target,
    List<Object> inputs, {
    JsonUpdateBuilder<T>? jsonUpdates,
  }) async {
    if (inputs.isEmpty) {
      return const MutationResult(affectedRows: 0);
    }
    if (inputs.length != 1) {
      throw ArgumentError(
        'updateInputsRaw with a Query where requires exactly one input; '
        'received ${inputs.length}.',
      );
    }

    final input = inputs.single;
    final helper = MutationInputHelper<T>(
      definition: definition,
      codecs: context.codecRegistry,
    );
    final jsonSupport = JsonUpdateSupport<T>(definition);

    Map<String, Object?>? originalAttributes;
    Map<String, Object?> dirtyAttributes = const {};

    if (input is T) {
      helper.applyUpdateTimestampsToModel(input);
      if (input is ModelAttributes) {
        final attrs = input as ModelAttributes;
        final originalMap = attrs.getOriginal();
        if (originalMap is Map<String, Object?>) {
          originalAttributes = Map<String, Object?>.from(originalMap);
        }
        dirtyAttributes = Map<String, Object?>.from(attrs.getDirty());
      } else {
        originalAttributes = definition.toMap(
          input,
          registry: context.codecRegistry,
        );
      }
    }

    final baseValues = helper.updateInputToMap(input);
    if (input is! ModelAttributes) {
      helper.ensureTimestampsInMap(baseValues, isInsert: false);
    }

    final payload = _normalizeUpdateValues(_addUpdateTimestamp(baseValues));
    final jsonClauses = input is T
        ? jsonSupport.buildJsonUpdates(input, jsonUpdates)
        : const <JsonUpdateClause>[];

    if (payload.values.isEmpty &&
        payload.jsonUpdates.isEmpty &&
        jsonClauses.isEmpty) {
      return const MutationResult(affectedRows: 0);
    }

    if (input is T && originalAttributes != null) {
      if (!_emitSavingEvent(input, baseValues)) {
        return const MutationResult(affectedRows: 0);
      }

      if (!_suppressEvents) {
        final updatingEvent = ModelUpdatingEvent(
          modelType: definition.modelType,
          tableName: definition.tableName,
          model: input,
          originalAttributes: Map<String, dynamic>.from(originalAttributes),
          dirtyAttributes: Map<String, dynamic>.from(dirtyAttributes),
        );
        target._events.emit(updatingEvent);
        if (updatingEvent.isCancelled) {
          return const MutationResult(affectedRows: 0);
        }
      }
    } else {
      if (!_emitSavingEvent(null, baseValues)) {
        return const MutationResult(affectedRows: 0);
      }
    }

    final mutation = target._buildQueryUpdateMutation(
      values: payload.values,
      jsonUpdates: [...payload.jsonUpdates, ...jsonClauses],
      feature: 'updateInputsRaw.queryWhere',
      returning: false,
    );
    return target.context.runMutation(mutation);
  }

  _InsertInputBuildResult<T> _buildInsertRows(List<Object> inputs) {
    if (inputs.isEmpty) {
      return _InsertInputBuildResult(
        rows: const [],
        originalModels: const [],
        inputMaps: const [],
      );
    }

    final helper = MutationInputHelper<T>(
      definition: definition,
      codecs: context.codecRegistry,
    );

    final rows = <Map<String, Object?>>[];
    final originalModels = <T>[];
    final inputMaps = <Map<String, Object?>>[];

    for (final input in inputs) {
      if (input is T) {
        helper.applyInsertTimestampsToModel(input);
        originalModels.add(input);

        final map = helper.insertInputToMap(
          input,
          applySentinelFiltering: true,
        );
        if (input is! ModelAttributes) {
          helper.ensureTimestampsInMap(map, isInsert: true);
        }
        final normalized = _normalizeAttributeKeys(map);
        rows.add(normalized);
        inputMaps.add(normalized);
        continue;
      }

      final baseMap = helper.insertInputToMap(
        input,
        applySentinelFiltering: helper.isTrackedModel(input),
      );
      final normalized = _normalizeAttributeKeys(baseMap);

      // Decode to model to apply default values, then re-encode for insertion.
      final model = definition.codec.decode(normalized, context.codecRegistry);
      final encoded = definition.toMap(model, registry: context.codecRegistry);

      // If caller didn't supply the primary key, drop auto/default PK values.
      final pkField = definition.primaryKeyField;
      if (pkField != null &&
          !baseMap.containsKey(pkField.columnName) &&
          !baseMap.containsKey(pkField.name)) {
        encoded.remove(pkField.columnName);
      }

      // If caller omitted a column and its encoded value is null, let DB defaults apply.
      for (final field in definition.fields) {
        final provided =
            baseMap.containsKey(field.columnName) ||
            baseMap.containsKey(field.name);
        if (!provided && isEffectivelyNull(encoded[field.columnName])) {
          encoded.remove(field.columnName);
        }
      }

      helper.ensureTimestampsInMap(encoded, isInsert: true);
      rows.add(encoded);
      inputMaps.add(encoded);
    }

    return _InsertInputBuildResult(
      rows: rows,
      originalModels: originalModels,
      inputMaps: inputMaps,
    );
  }

  MutationPlan _buildInsertPlanFromInputs(
    List<Object> inputs, {
    bool returning = true,
    bool ignoreConflicts = false,
  }) {
    final build = _buildInsertRows(inputs);
    return MutationPlan.insert(
      definition: definition,
      rows: build.rows,
      driverName: context.driver.metadata.name,
      returning: returning,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Resolves a [where] parameter that may be a `Query` or query-builder callback.
  ///
  /// Returns the resolved `Query<T>` if [where] is:
  /// - A `Query<T>` instance
  /// - A `Query<T> Function(Query<T>)` callback
  /// - A `Query Function(Query)` callback (with runtime type check)
  ///
  /// Returns `null` if [where] is not a query type, allowing the caller to
  /// fall back to other input handling (maps, DTOs, etc.).
  ///
  /// **Note**: Untyped callbacks like `(q) => q.where(...)` are not supported
  /// because Dart extension methods are not accessible when the parameter is
  /// typed as `dynamic`. Users must explicitly type their callback parameters.
  Query<T>? _resolveWhereQuery(Object? where, String feature) {
    if (where is Query<T>) {
      _ensureSharedContext(where, feature);
      return where;
    }
    if (where is Query<T> Function(Query<T>)) {
      final built = where(this);
      _ensureSharedContext(built, feature);
      return built;
    }
    if (where is Query Function(Query)) {
      final built = where(this);
      if (built is! Query<T>) {
        throw ArgumentError(
          '$feature callback must return Query<$T>, got ${built.runtimeType}.',
        );
      }
      _ensureSharedContext(built, feature);
      return built;
    }
    // Handle untyped functions (e.g., (q) => q.where(...))
    // We cannot use dynamic Function(dynamic) because extension methods
    // don't work with dynamic receivers. Instead, reject untyped functions
    // and require users to type their lambda parameters.
    return null;
  }

  List<MutationRow> _buildUpsertRows(
    List<Object> inputs, {
    JsonUpdateBuilder<T>? jsonUpdates,
  }) {
    final helper = MutationInputHelper<T>(
      definition: definition,
      codecs: context.codecRegistry,
    );
    final jsonSupport = JsonUpdateSupport<T>(definition);

    return inputs
        .map((input) {
          if (input is T) {
            helper.applyInsertTimestampsToModel(input);
          }
          final baseValues = helper.insertInputToMap(
            input,
            applySentinelFiltering: helper.isTrackedModel(input),
          );
          final normalized = _normalizeAttributeKeys(baseValues);

          Map<String, Object?> values;
          final List<JsonUpdateClause> jsonClauses = input is T
              ? jsonSupport.buildJsonUpdates(input, jsonUpdates)
              : const <JsonUpdateClause>[];

          if (input is T) {
            values = normalized;
            if (input is! ModelAttributes) {
              helper.ensureTimestampsInMap(values, isInsert: true);
            }
          } else {
            final model = definition.codec.decode(
              normalized,
              context.codecRegistry,
            );
            values = definition.toMap(model, registry: context.codecRegistry);

            final pkField = definition.primaryKeyField;
            if (pkField != null &&
                !baseValues.containsKey(pkField.columnName) &&
                !baseValues.containsKey(pkField.name)) {
              values.remove(pkField.columnName);
            }

            for (final field in definition.fields) {
              final provided =
                  baseValues.containsKey(field.columnName) ||
                  baseValues.containsKey(field.name);
              if (!provided && values[field.columnName] == null) {
                values.remove(field.columnName);
              }
            }
          }

          if (input is! ModelAttributes) {
            helper.ensureTimestampsInMap(values, isInsert: true);
          }
          return MutationRow(
            values: values,
            keys: const {},
            jsonUpdates: jsonClauses,
          );
        })
        .toList(growable: false);
  }

  MutationPlan _buildUpsertPlan(
    List<MutationRow> rows, {
    List<String>? uniqueBy,
    List<String>? updateColumns,
    required bool returning,
  }) {
    // Default to primary key if uniqueBy not specified
    List<String>? resolvedUniqueBy;
    if (uniqueBy != null) {
      resolvedUniqueBy = uniqueBy
          .map(_ensureField)
          .map((f) => f.columnName)
          .toList();
    } else {
      final pk = definition.primaryKeyField;
      if (pk != null) {
        resolvedUniqueBy = [pk.columnName];
      }
    }

    return MutationPlan.upsert(
      definition: definition,
      rows: rows,
      driverName: context.driver.metadata.name,
      returning: returning,
      uniqueBy: resolvedUniqueBy,
      updateColumns: updateColumns
          ?.map(_ensureField)
          .map((f) => f.columnName)
          .toList(),
    );
  }

  /// Adds updated_at timestamp to update values if the model has a timestamp field.
  /// Only adds if not already present in values and field exists with snake_case name.
  /// Returns the raw value (DateTime or Carbon) based on field type - not encoded since _normalizeUpdateValues will handle encoding.
  Map<String, Object?> _addUpdateTimestamp(Map<String, Object?> values) {
    if (!definition.metadata.timestamps ||
        Model.isIgnoringTimestamps(
          definition.modelType,
          modelName: definition.modelName,
        )) {
      return values;
    }
    // Check if model has updated_at field (snake_case only)
    try {
      final updatedAtField = definition.fields.firstWhere(
        (f) => f.columnName == 'updated_at',
      );

      final columnName = updatedAtField.columnName;
      final fieldName = updatedAtField.name;

      // Only set if not already provided by user
      if (!values.containsKey(columnName) && !values.containsKey(fieldName)) {
        // Use Carbon for Carbon/CarbonInterface fields, DateTime for DateTime fields
        final nowUtc = monotonicNowUtc();
        final fieldType = updatedAtField.dartType;

        if (fieldType == 'Carbon' ||
            fieldType == 'Carbon?' ||
            fieldType == 'CarbonInterface' ||
            fieldType == 'CarbonInterface?') {
          return {...values, columnName: Carbon.fromDateTime(nowUtc)};
        } else {
          // Convert to DateTime for DateTime fields
          return {...values, columnName: nowUtc};
        }
      }
    } catch (_) {
      // Field doesn't exist, return values as-is
    }

    return values;
  }

  /// Increments the value of a numeric [column] by [amount].
  ///
  /// [amount] defaults to 1.
  /// Throws [StateError] if the driver does not support increment operations.
  ///
  /// Example:
  /// ```dart
  /// final updatedCount = await context.query<Product>()
  ///   .where('id', 1)
  ///   .increment('stock', 5);
  /// print('Incremented stock for $updatedCount products.');
  /// ```
  Future<int> increment(String column, [num amount = 1]) {
    return _applyIncrement(column, amount, 'increment');
  }

  /// Decrements the value of a numeric [column] by [amount].
  ///
  /// [amount] defaults to 1.
  /// Throws [StateError] if the driver does not support decrement operations.
  ///
  /// Example:
  /// ```dart
  /// final updatedCount = await context.query<Product>()
  ///   .where('id', 1)
  ///   .decrement('stock', 2);
  /// print('Decremented stock for $updatedCount products.');
  /// ```
  Future<int> decrement(String column, [num amount = 1]) {
    return _applyIncrement(column, -amount.abs(), 'decrement');
  }

  /// Deletes all records matching the query conditions.
  ///
  /// Returns the number of affected rows.
  ///
  /// Example:
  /// ```dart
  /// final deletedCount = await context.query<User>()
  ///   .where('active', equals: false)
  ///   .delete();
  /// print('Deleted $deletedCount inactive users.');
  /// ```
  Future<int> delete() async {
    final softDeleteField = _softDeleteField;
    final now = Carbon.now().toUtc().toDateTime();
    final targets = await _prepareDeletionTargets(
      softDeleteField: softDeleteField,
      softDeleteValue: now,
    );
    if (targets.rows.isEmpty) return 0;

    final mutation = softDeleteField != null
        ? MutationPlan.update(
            definition: definition,
            rows: targets.rows,
            driverName: context.driver.metadata.name,
          )
        : MutationPlan.delete(
            definition: definition,
            rows: targets.rows,
            driverName: context.driver.metadata.name,
          );
    final result = await context.runMutation(mutation);
    if (result.affectedRows > 0) {
      _emitDeletedEventsForModels(
        targets.models,
        forceDelete: softDeleteField == null,
      );
    }
    return result.affectedRows;
  }

  /// Deletes matching rows and returns hydrated models when the driver supports RETURNING.
  ///
  /// For soft-delete models, this returns the rows after the soft delete update.
  Future<List<T>> deleteReturning() async {
    final softDeleteField = _softDeleteField;
    final now = Carbon.now().toUtc().toDateTime();
    final targets = await _prepareDeletionTargets(
      softDeleteField: softDeleteField,
      softDeleteValue: softDeleteField != null ? now : null,
    );
    if (targets.rows.isEmpty) return const [];

    final mutation = softDeleteField != null
        ? MutationPlan.update(
            definition: definition,
            rows: targets.rows,
            driverName: context.driver.metadata.name,
            returning: true,
          )
        : MutationPlan.delete(
            definition: definition,
            rows: targets.rows,
            driverName: context.driver.metadata.name,
            returning: true,
          );
    final result = await context.runMutation(mutation);
    var models = _hydrateMutationResults(result);
    if (models.isEmpty &&
        result.affectedRows > 0 &&
        targets.models.isNotEmpty) {
      // Some drivers (e.g., MySQL/MariaDB) don't support RETURNING for deletes.
      // Fall back to the models we collected prior to the mutation.
      models = targets.models;
    }
    _emitDeletedEventsForModels(models, forceDelete: softDeleteField == null);
    return models;
  }

  /// Deletes records matching a flexible where input (PK, map, DTO, partial, tracked model).
  ///
  /// This provides the same input ergonomics as Repository.delete().
  ///
  /// {@macro ormed.query.where_input}
  Future<int> deleteWhere(Object where) => deleteWhereMany([where]);

  /// Deletes multiple records using flexible where inputs.
  ///
  /// Each entry in [wheres] can be any supported where input (see [deleteWhere]).
  ///
  /// When a `Query` or callback is provided, it is executed separately from
  /// other inputs, allowing mixed input types in the same call.
  ///
  /// Example:
  /// ```dart
  /// final affected = await query.deleteWhereMany([
  ///   (Query<$User> q) => q.whereEquals('role', 'guest'),
  ///   {'id': 42},
  ///   somePartial,
  /// ]);
  /// ```
  Future<int> deleteWhereMany(List<Object> wheres) async {
    if (wheres.isEmpty) return 0;

    final forceDelete = _softDeleteField == null;
    final deleteFilter = _filterDeleteWheres(wheres, forceDelete: forceDelete);
    if (deleteFilter.wheres.isEmpty) return 0;

    final split = _splitWhereInputs(deleteFilter.wheres, 'deleteWhereMany');
    var affected = 0;

    for (final query in split.queries) {
      affected += await query.delete();
    }

    if (split.inputs.isEmpty) {
      return affected;
    }

    final mutation = _buildDeleteWherePlan(split.inputs, returning: false);
    final result = await context.runMutation(mutation);
    final total = affected + result.affectedRows;

    if (total > 0 && deleteFilter.contexts.isNotEmpty) {
      _emitDeletedEvents(deleteFilter.contexts);
    }

    return total;
  }

  /// Deletes records using flexible where inputs and returns hydrated models.
  Future<List<T>> deleteWhereReturning(Object where) =>
      deleteWhereManyReturning([where]);

  /// Deletes multiple records using flexible where inputs and returns hydrated models.
  Future<List<T>> deleteWhereManyReturning(List<Object> wheres) async {
    if (wheres.isEmpty) return const [];

    final forceDelete = _softDeleteField == null;
    final deleteFilter = _filterDeleteWheres(wheres, forceDelete: forceDelete);
    if (deleteFilter.wheres.isEmpty) return const [];

    final split = _splitWhereInputs(
      deleteFilter.wheres,
      'deleteWhereManyReturning',
    );
    final models = <T>[];

    for (final query in split.queries) {
      final returned = await query.deleteReturning();
      models.addAll(returned);
    }

    if (split.inputs.isNotEmpty) {
      final mutation = _buildDeleteWherePlan(split.inputs, returning: true);
      final result = await context.runMutation(mutation);
      final hydrated = _hydrateMutationResults(result);
      if (hydrated.isNotEmpty) {
        _emitDeletedEventsForModels(hydrated, forceDelete: forceDelete);
        models.addAll(hydrated);
      } else if (result.affectedRows > 0 && deleteFilter.contexts.isNotEmpty) {
        _emitDeletedEvents(deleteFilter.contexts);
      }
    }
    return models;
  }

  /// Builds but does not execute a delete plan for flexible inputs (useful for previews).
  MutationPlan previewDeleteWherePlan(
    List<Object> wheres, {
    bool returning = false,
  }) => _buildDeleteWherePlan(wheres, returning: returning);

  MutationPlan _buildDeleteWherePlan(
    List<Object> wheres, {
    required bool returning,
  }) {
    final helper = MutationInputHelper<T>(
      definition: definition,
      codecs: context.codecRegistry,
    );
    final pkField =
        definition.primaryKeyField ??
        (throw StateError(
          'deleteWhere requires ${definition.modelName} to declare a primary key.',
        ));

    final keys = wheres
        .map((input) {
          if (input is T) {
            final map = helper.whereInputToMap(input)!;
            final pkValue = map[pkField.columnName];
            if (pkValue == null) {
              throw StateError('Primary key cannot be null for delete().');
            }
            return {pkField.columnName: pkValue};
          }
          try {
            final map = helper.whereInputToMap(input);
            if (map != null && map.isNotEmpty) return map;
          } catch (_) {}

          final pk = helper.extractPrimaryKey(input);
          if (pk != null) return {pkField.columnName: pk};

          return {pkField.columnName: input};
        })
        .toList(growable: false);

    final softDeleteField = _softDeleteField;
    if (softDeleteField != null) {
      final now = Carbon.now().toUtc().toDateTime();
      final rows = keys
          .map(
            (key) => MutationRow(
              values: {softDeleteField.columnName: now},
              keys: key,
            ),
          )
          .toList();
      return MutationPlan.update(
        definition: definition,
        rows: rows,
        driverName: context.driver.metadata.name,
        returning: returning,
      );
    }

    final rows = keys
        .map((conditions) => MutationRow(values: const {}, keys: conditions))
        .toList(growable: false);
    return MutationPlan.delete(
      definition: definition,
      rows: rows,
      driverName: context.driver.metadata.name,
      returning: returning,
    );
  }

  _WhereSplit<T> _splitWhereInputs(List<Object> wheres, String feature) {
    final queries = <Query<T>>[];
    final inputs = <Object>[];

    for (final where in wheres) {
      final query = _resolveWhereQuery(where, feature);
      if (query != null) {
        queries.add(query);
        continue;
      }
      inputs.add(where);
    }

    return _WhereSplit<T>(queries: queries, inputs: inputs);
  }

  /// Upserts (insert or update) a single record.
  ///
  /// If a record with the same unique key exists, it will be updated.
  /// Otherwise, a new record will be inserted.
  ///
  /// [attributes] contains the data to insert/update.
  /// [uniqueBy] specifies which fields make up the unique key (defaults to primary key).
  /// [updateColumns] specifies which columns to update on conflict (defaults to all non-unique columns).
  ///
  /// Returns the upserted model instance.
  ///
  /// Example:
  /// ```dart
  /// final user = await User.query().upsert(
  ///   {'email': 'john@example.com', 'name': 'John Doe', 'age': 30},
  ///   uniqueBy: ['email'],
  /// );
  /// ```
  Future<T> upsert(
    Map<String, dynamic> attributes, {
    List<String>? uniqueBy,
    List<String>? updateColumns,
  }) async {
    final results = await upsertInputs(
      [attributes],
      uniqueBy: uniqueBy,
      updateColumns: updateColumns,
    );
    if (results.isEmpty) {
      throw StateError('Failed to upsert record');
    }
    return results.first;
  }

  /// Upserts (inserts or updates) multiple records.
  ///
  /// If records with the same unique keys exist, they will be updated.
  /// Otherwise, new records will be inserted.
  ///
  /// [records] is a list of attribute maps to upsert.
  /// [uniqueBy] specifies which fields make up the unique key (defaults to primary key).
  /// [updateColumns] specifies which columns to update on conflict (defaults to all non-unique columns).
  ///
  /// Returns the list of upserted model instances.
  ///
  /// Example:
  /// ```dart
  /// final users = await User.query().upsertMany([
  ///   {'email': 'john@example.com', 'name': 'John Doe'},
  ///   {'email': 'jane@example.com', 'name': 'Jane Smith'},
  /// ], uniqueBy: ['email']);
  /// ```
  Future<List<T>> upsertMany(
    List<Map<String, dynamic>> records, {
    List<String>? uniqueBy,
    List<String>? updateColumns,
  }) async {
    return upsertInputs(
      records,
      uniqueBy: uniqueBy,
      updateColumns: updateColumns,
    );
  }

  /// Upserts flexible inputs and returns hydrated models.
  ///
  /// {@macro ormed.query.insert_inputs}
  /// {@macro ormed.query.upsert_options}
  /// {@macro ormed.mutation.json_updates}
  Future<List<T>> upsertInputs(
    List<Object> inputs, {
    List<String>? uniqueBy,
    List<String>? updateColumns,
    JsonUpdateBuilder<T>? jsonUpdates,
  }) async {
    if (inputs.isEmpty) return const [];

    final rows = _buildUpsertRows(inputs, jsonUpdates: jsonUpdates);
    final readyRows = <MutationRow>[];
    final filteredInputMaps = <Map<String, Object?>>[];
    final filteredOriginalModels = <T>[];

    for (var i = 0; i < rows.length && i < inputs.length; i++) {
      final inputMap = rows[i].values;
      final input = inputs[i];
      if (!_emitSavingEvent(input is T ? input : null, inputMap)) {
        continue;
      }

      if (!_suppressEvents) {
        final creatingEvent = ModelCreatingEvent(
          modelType: definition.modelType,
          tableName: definition.tableName,
          attributes: Map<String, dynamic>.from(inputMap),
        );
        _events.emit(creatingEvent);
        if (creatingEvent.isCancelled) continue;
      }
      readyRows.add(rows[i]);
      filteredInputMaps.add(inputMap);
      if (input is T) {
        filteredOriginalModels.add(input);
      }
    }

    if (readyRows.isEmpty) return const [];

    final mutation = _buildUpsertPlan(
      readyRows,
      uniqueBy: uniqueBy,
      updateColumns: updateColumns,
      returning: true,
    );

    final result = await context.runMutation(mutation);
    final models = _hydrateMutationResults(
      result,
      originalModels: filteredOriginalModels,
      inputMaps: filteredInputMaps,
      canCreateFromInputs: true,
    );
    _emitCreatedEvents(models, filteredInputMaps);
    _emitSavedEvents(models, filteredInputMaps);
    return models;
  }

  /// Builds but does not execute an upsert plan (useful for previews).
  MutationPlan previewUpsertPlan(
    List<Object> inputs, {
    List<String>? uniqueBy,
    List<String>? updateColumns,
    JsonUpdateBuilder<T>? jsonUpdates,
    bool returning = false,
  }) {
    final rows = _buildUpsertRows(inputs, jsonUpdates: jsonUpdates);
    return _buildUpsertPlan(
      rows,
      uniqueBy: uniqueBy,
      updateColumns: updateColumns,
      returning: returning,
    );
  }

  /// Normalizes attribute keys to use column names.
  /// Accepts both Dart property names (camelCase) and database column names (snake_case).
  Map<String, dynamic> _normalizeAttributeKeys(
    Map<String, dynamic> attributes,
  ) {
    final normalized = <String, dynamic>{};

    for (final entry in attributes.entries) {
      final key = entry.key;
      final value = entry.value;

      // Try to find field by property name first
      final fieldByName = definition.fieldByName(key);
      if (fieldByName != null) {
        normalized[fieldByName.columnName] = value;
        continue;
      }

      // Try to find by column name
      final fieldByColumn = definition.fieldByColumn(key);
      if (fieldByColumn != null) {
        normalized[key] = value;
        continue;
      }

      // If no field found, keep the original key (might be a virtual field or attribute)
      normalized[key] = value;
    }

    return normalized;
  }

  /// Hydrates mutation results keeping merge semantics consistent
  /// (returned > original model > input map) without depending on Repository.
  List<T> _hydrateMutationResults(
    MutationResult result, {
    List<T> originalModels = const [],
    List<Map<String, Object?>> inputMaps = const [],
    bool canCreateFromInputs = true,
    bool fallbackToOriginalWhenNoReturn = true,
  }) {
    if (result.returnedRows != null && result.returnedRows!.isNotEmpty) {
      final returned = <T>[];
      for (int i = 0; i < result.returnedRows!.length; i++) {
        final returnedRow = result.returnedRows![i];
        final originalModel = i < originalModels.length
            ? originalModels[i]
            : null;
        final inputMap = i < inputMaps.length ? inputMaps[i] : null;

        final Map<String, Object?> mergedData;
        if (originalModel != null) {
          final originalData = definition.toMap(
            originalModel,
            registry: context.codecRegistry,
          );
          mergedData = {...originalData, ...returnedRow};
        } else if (inputMap != null) {
          mergedData = {...inputMap, ...returnedRow};
        } else {
          mergedData = returnedRow;
        }

        final model = definition.fromMap(
          mergedData,
          registry: context.codecRegistry,
        );
        if (model is ModelConnection) {
          (model as ModelConnection).attachConnectionResolver(context);
        }
        if (model is ModelAttributes) {
          (model as ModelAttributes).syncOriginal();
        }
        returned.add(model);
      }
      return returned;
    }

    if (fallbackToOriginalWhenNoReturn && originalModels.isNotEmpty) {
      return originalModels;
    }

    if (canCreateFromInputs && inputMaps.isNotEmpty) {
      return inputMaps.map((map) {
        final model = definition.fromMap(map, registry: context.codecRegistry);
        if (model is ModelConnection) {
          (model as ModelConnection).attachConnectionResolver(context);
        }
        if (model is ModelAttributes) {
          (model as ModelAttributes).syncOriginal();
        }
        return model;
      }).toList();
    }

    return const [];
  }

  /// Updates existing record or inserts if it doesn't exist.
  ///
  /// [attributes] are used to find the record, [values] are the data to update/insert.
  ///
  /// Example:
  /// ```dart
  /// await context.query<User>()
  ///   .updateOrInsert(
  ///     {'email': 'john@example.com'},
  ///     {'name': 'John', 'age': 30},
  ///   );
  /// ```
  Future<bool> updateOrInsert(
    Map<String, Object?> attributes,
    Map<String, Object?> values,
  ) async {
    // Try to find existing record
    Query<T> query = this;
    for (final entry in attributes.entries) {
      query = query.where(entry.key, entry.value);
    }

    final existing = await query.first();
    if (existing != null) {
      // Update existing
      final updated = await query.update(values);
      return updated > 0;
    } else {
      // Insert new - this requires codec which we don't have here
      // This is a placeholder - actual implementation needs repository
      throw UnimplementedError(
        'updateOrInsert requires repository access for insertion. '
        'Use Model.updateOrCreate() instead.',
      );
    }
  }

  List<_InsertEntry<T>> _zipInsertEntries(
    List<Object> inputs,
    _InsertInputBuildResult<T> build,
  ) {
    final entries = <_InsertEntry<T>>[];
    final count = build.rows.length;
    for (var i = 0; i < count && i < inputs.length; i++) {
      entries.add(
        _InsertEntry<T>(
          row: build.rows[i],
          inputMap: i < build.inputMaps.length ? build.inputMaps[i] : const {},
          model: inputs[i] is T ? inputs[i] as T : null,
        ),
      );
    }
    return entries;
  }

  List<_UpdateEntry<T>> _zipUpdateEntries(
    List<Object> inputs,
    _UpdateInputBuildResult<T> build,
  ) {
    final entries = <_UpdateEntry<T>>[];
    final count = build.rows.length;

    for (var i = 0; i < count && i < inputs.length; i++) {
      final input = inputs[i];
      final model = input is T ? input : null;

      Map<String, Object?>? original;
      Map<String, Object?> dirty = const {};
      if (model is ModelAttributes) {
        final attrs = model as ModelAttributes;
        final originalMap = attrs.getOriginal();
        if (originalMap is Map<String, Object?>) {
          original = Map<String, Object?>.from(originalMap);
        }
        final dirtyMap = attrs.getDirty();
        dirty = Map<String, Object?>.from(dirtyMap);
      } else if (model != null) {
        original = definition.toMap(model, registry: context.codecRegistry);
      }

      entries.add(
        _UpdateEntry<T>(
          row: build.rows[i],
          inputMap: i < build.inputMaps.length ? build.inputMaps[i] : const {},
          model: model,
          originalAttributes: original,
          dirtyAttributes: dirty,
        ),
      );
    }

    return entries;
  }

  void _emitCreatedEvents(
    List<T> models,
    List<Map<String, Object?>> inputMaps,
  ) {
    if (_suppressEvents) return;
    for (var i = 0; i < models.length; i++) {
      final model = models[i];
      final attributes = i < inputMaps.length ? inputMaps[i] : const {};
      _events.emit(
        ModelCreatedEvent(
          modelType: definition.modelType,
          tableName: definition.tableName,
          model: model,
          attributes: Map<String, dynamic>.from(attributes),
        ),
      );
    }
  }

  void _emitSavedEvents(List<T> models, List<Map<String, Object?>> inputMaps) {
    if (_suppressEvents) return;
    for (var i = 0; i < models.length; i++) {
      final model = models[i];
      final attributes = i < inputMaps.length ? inputMaps[i] : const {};
      _events.emit(
        ModelSavedEvent(
          modelType: definition.modelType,
          tableName: definition.tableName,
          model: model,
          attributes: Map<String, dynamic>.from(attributes),
        ),
      );
    }
  }

  void _emitUpdatedEvents(List<T> models, List<_UpdateEntry<T>> entries) {
    if (_suppressEvents) return;
    final limit = models.length < entries.length
        ? models.length
        : entries.length;
    for (var i = 0; i < limit; i++) {
      final entry = entries[i];
      final original = entry.originalAttributes;
      if (original == null) continue;

      final model = models[i];
      final updated = definition.toMap(model, registry: context.codecRegistry);
      final changed = _diffAttributes(original, updated);

      _events.emit(
        ModelUpdatedEvent(
          modelType: definition.modelType,
          tableName: definition.tableName,
          model: model,
          originalAttributes: Map<String, dynamic>.from(original),
          changedAttributes: Map<String, dynamic>.from(changed),
        ),
      );
    }
  }

  bool _emitSavingEvent(T? model, Map<String, Object?> attributes) {
    if (_suppressEvents) return true;
    final savingEvent = ModelSavingEvent(
      modelType: definition.modelType,
      tableName: definition.tableName,
      model: model,
      attributes: Map<String, dynamic>.from(attributes),
    );
    _events.emit(savingEvent);
    return !savingEvent.isCancelled;
  }

  Map<String, Object?> _diffAttributes(
    Map<String, Object?> original,
    Map<String, Object?> updated,
  ) {
    final changed = <String, Object?>{};
    final keys = {...original.keys, ...updated.keys};
    for (final key in keys) {
      if (original[key] != updated[key]) {
        changed[key] = updated[key];
      }
    }
    return changed;
  }

  _DeleteFilter<T> _filterDeleteWheres(
    List<Object> wheres, {
    required bool forceDelete,
  }) {
    final filtered = <Object>[];
    final contexts = <_DeleteEventContext<T>>[];

    for (final where in wheres) {
      if (where is T) {
        if (!_suppressEvents) {
          final deleting = ModelDeletingEvent(
            modelType: definition.modelType,
            tableName: definition.tableName,
            model: where,
            forceDelete: forceDelete,
          );
          _events.emit(deleting);
          if (deleting.isCancelled) {
            continue;
          }
        }
        contexts.add(
          _DeleteEventContext<T>(model: where, forceDelete: forceDelete),
        );
      }
      filtered.add(where);
    }

    return _DeleteFilter<T>(wheres: filtered, contexts: contexts);
  }

  void _emitDeletedEvents(List<_DeleteEventContext<T>> contexts) {
    if (_suppressEvents) return;
    for (final context in contexts) {
      _events.emit(
        ModelDeletedEvent(
          modelType: definition.modelType,
          tableName: definition.tableName,
          model: context.model,
          forceDelete: context.forceDelete,
        ),
      );
      if (context.forceDelete) {
        _events.emit(
          ModelForceDeletedEvent(
            modelType: definition.modelType,
            tableName: definition.tableName,
            model: context.model,
          ),
        );
      } else {
        _events.emit(
          ModelTrashedEvent(
            modelType: definition.modelType,
            tableName: definition.tableName,
            model: context.model,
          ),
        );
      }
    }
  }

  Future<_DeletionTargets<T>> _prepareDeletionTargets({
    FieldDefinition? softDeleteField,
    Object? softDeleteValue,
    bool includeTrashed = false,
    bool restoring = false,
    FieldDefinition? scopeSoftDeleteField,
  }) async {
    final scopeField = scopeSoftDeleteField ?? softDeleteField;
    final pkField = definition.primaryKeyField;
    if (pkField == null) {
      throw StateError(
        'delete requires ${definition.modelName} to declare a primary key.',
      );
    }

    Query<T> target = this;
    if (includeTrashed && scopeField != null) {
      target = restoring ? onlyTrashed() : withTrashed();
    }

    final queryRows = await target.rows();
    final rows = <MutationRow>[];
    final models = <T>[];

    for (final queryRow in queryRows) {
      final model = queryRow.model;
      final pkValue = queryRow.row[pkField.columnName];
      if (pkValue == null) continue;

      if (!_suppressEvents) {
        if (restoring) {
          final restoringEvent = ModelRestoringEvent(
            modelType: definition.modelType,
            tableName: definition.tableName,
            model: model,
          );
          _events.emit(restoringEvent);
          if (restoringEvent.isCancelled) {
            continue;
          }
        } else {
          final deletingEvent = ModelDeletingEvent(
            modelType: definition.modelType,
            tableName: definition.tableName,
            model: model,
            forceDelete: softDeleteField == null,
          );
          _events.emit(deletingEvent);
          if (deletingEvent.isCancelled) {
            continue;
          }
        }
      }

      rows.add(
        MutationRow(
          values: softDeleteField != null
              ? {softDeleteField.columnName: softDeleteValue}
              : const {},
          keys: {pkField.columnName: pkValue},
        ),
      );
      models.add(model);
    }

    return _DeletionTargets<T>(rows: rows, models: models);
  }

  void _emitDeletedEventsForModels(
    List<T> models, {
    required bool forceDelete,
  }) {
    if (_suppressEvents) return;
    for (final model in models) {
      _events.emit(
        ModelDeletedEvent(
          modelType: definition.modelType,
          tableName: definition.tableName,
          model: model,
          forceDelete: forceDelete,
        ),
      );
      if (forceDelete) {
        _events.emit(
          ModelForceDeletedEvent(
            modelType: definition.modelType,
            tableName: definition.tableName,
            model: model,
          ),
        );
      } else {
        _events.emit(
          ModelTrashedEvent(
            modelType: definition.modelType,
            tableName: definition.tableName,
            model: model,
          ),
        );
      }
    }
  }
}

class _WhereSplit<T extends OrmEntity> {
  _WhereSplit({required this.queries, required this.inputs});

  final List<Query<T>> queries;
  final List<Object> inputs;
}

final class _InsertEntry<T extends OrmEntity> {
  _InsertEntry({required this.row, required this.inputMap, this.model});

  final Map<String, Object?> row;
  final Map<String, Object?> inputMap;
  final T? model;
}

final class _UpdateEntry<T extends OrmEntity> {
  _UpdateEntry({
    required this.row,
    required this.inputMap,
    this.model,
    this.originalAttributes,
    Map<String, Object?>? dirtyAttributes,
  }) : dirtyAttributes = dirtyAttributes ?? const {};

  final MutationRow row;
  final Map<String, Object?> inputMap;
  final T? model;
  final Map<String, Object?>? originalAttributes;
  final Map<String, Object?> dirtyAttributes;
}

final class _DeleteEventContext<T extends OrmEntity> {
  _DeleteEventContext({required this.model, required this.forceDelete});

  final T model;
  final bool forceDelete;
}

final class _DeleteFilter<T extends OrmEntity> {
  _DeleteFilter({required this.wheres, required this.contexts});

  final List<Object> wheres;
  final List<_DeleteEventContext<T>> contexts;
}

final class _DeletionTargets<T extends OrmEntity> {
  _DeletionTargets({required this.rows, required this.models});

  final List<MutationRow> rows;
  final List<T> models;
}
