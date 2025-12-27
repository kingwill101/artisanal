import 'package:carbonized/carbonized.dart';

import '../driver/mutation/mutation_plan.dart';
import '../driver/mutation/mutation_row.dart';
import '../value_codec.dart';
import 'model.dart';

/// Extensions on [Model] that provide convenient access to attribute and
/// relation tracking features.
///
/// These helpers are designed to be safe to call on any [Model] instance. For
/// APIs that depend on attribute tracking, methods return conservative defaults
/// (for example, `false` or `{}`) when called on an untracked model.
///
/// {@macro ormed.model.tracked_instances}
extension ModelAttributeExtensions<T extends Model<T>> on Model<T> {
  /// Returns `true` if an attribute exists in the attribute store.
  ///
  /// Returns `false` for untracked models.
  bool hasAttribute(String key) {
    if (this is ModelAttributes) {
      return (this as ModelAttributes).hasAttribute(key);
    }
    return false;
  }

  /// Returns an attribute value from the attribute store.
  ///
  /// Returns `null` for untracked models.
  TValue? getAttribute<TValue>(String key) {
    if (this is ModelAttributes) {
      return (this as ModelAttributes).getAttribute<TValue>(key);
    }
    return null;
  }

  /// Sets an attribute value in the attribute store.
  ///
  /// Does nothing for untracked models.
  void setAttribute(String key, Object? value) {
    if (this is ModelAttributes) {
      (this as ModelAttributes).setAttribute(key, value);
    }
  }

  /// Returns all tracked attributes as a map.
  ///
  /// Returns an empty map for untracked models.
  Map<String, Object?> getAttributes() {
    if (this is ModelAttributes) {
      return (this as ModelAttributes).getAttributes();
    }
    return {};
  }

  /// Sets multiple attributes at once.
  ///
  /// Does nothing for untracked models.
  void setAttributes(Map<String, Object?> attributes) {
    if (this is ModelAttributes) {
      (this as ModelAttributes).setAttributes(attributes);
    }
  }

  /// Returns `true` if this model has been modified since it was loaded.
  ///
  /// Returns `false` for untracked models.
  bool isDirty([String? key]) {
    if (this is ModelAttributes) {
      return (this as ModelAttributes).isDirty(key);
    }
    return false;
  }

  /// Returns the original (unmodified) value of an attribute.
  ///
  /// Returns `null` for untracked models.
  Object? getOriginal([String? key]) {
    if (this is ModelAttributes) {
      return (this as ModelAttributes).getOriginal(key);
    }
    return null;
  }

  /// Returns `true` if a specific attribute has been modified.
  ///
  /// Returns `false` for untracked models.
  bool wasChanged(String key) {
    if (this is ModelAttributes) {
      return (this as ModelAttributes).wasChanged(key);
    }
    return false;
  }

  /// Returns all changed attributes as a map.
  ///
  /// Returns an empty map for untracked models.
  Map<String, Object?> getDirty() {
    if (this is ModelAttributes) {
      return (this as ModelAttributes).getDirty();
    }
    return {};
  }

  /// Syncs the original state to match current attributes.
  ///
  /// Does nothing for untracked models.
  void syncOriginal() {
    if (this is ModelAttributes) {
      (this as ModelAttributes).syncOriginal();
    }
  }

  /// Returns the raw tracked attributes map.
  ///
  /// Returns an empty map for untracked models.
  Map<String, Object?> get attributes {
    if (this is ModelAttributes) {
      return (this as ModelAttributes).attributes;
    }
    return {};
  }

  /// Replaces all attributes with new values.
  ///
  /// Does nothing for untracked models.
  void replaceAttributes(Map<String, Object?> attributes) {
    if (this is ModelAttributes) {
      (this as ModelAttributes).replaceAttributes(attributes);
    }
  }

  /// Attaches a model definition to this model instance.
  ///
  /// Does nothing for untracked models.
  void attachModelDefinition(ModelDefinition<T> definition) {
    if (this is ModelAttributes) {
      (this as ModelAttributes).attachModelDefinition(definition);
    }
  }

  /// Returns all changed attributes with their new values (alias for [getDirty]).
  ///
  /// Returns an empty map for untracked models.
  Map<String, Object?> getChanges() {
    return getDirty();
  }

  /// Fills attributes from [payload], respecting fillable/guarded metadata.
  ///
  /// {@macro ormed.model.mass_assignment}
  ///
  /// Returns a map of filled attributes. Returns an empty map for untracked models.
  Map<String, Object?> fillAttributes(
    Map<String, Object?> payload, {
    bool strict = true,
    ValueCodecRegistry? registry,
  }) {
    if (this is ModelAttributes) {
      return (this as ModelAttributes).fillAttributes(
        payload,
        strict: strict,
        registry: registry,
      );
    }
    return {};
  }

  /// Returns `true` if a relation has been loaded in this instance.
  ///
  /// Relations are cached on the instance and may be populated by eager loading
  /// or manual calls to [setRelation].
  bool relationLoaded(String relation) {
    return (this as ModelRelations).relationLoaded(relation);
  }

  /// Returns a loaded relation value.
  ///
  /// Returns `null` if the relation hasn't been loaded or is explicitly null.
  TRelation? getRelation<TRelation>(String relation) {
    return (this as ModelRelations).getRelation<TRelation>(relation);
  }

  /// Returns a loaded relation list.
  ///
  /// Returns an empty list if the relation hasn't been loaded.
  List<TRelation> getRelationList<TRelation>(String relation) {
    return (this as ModelRelations).getRelationList<TRelation>(relation);
  }

  /// Sets a relation value and marks it as loaded.
  ///
  /// This is commonly used internally when eager loading results.
  void setRelation(String relation, dynamic value) {
    (this as ModelRelations).setRelation(relation, value);
  }

  /// Unloads a relation.
  ///
  /// This removes any cached value and marks it as not loaded.
  void unsetRelation(String relation) {
    (this as ModelRelations).unsetRelation(relation);
  }

  /// Returns all loaded relations as a map.
  ///
  /// The returned map is a snapshot; modifying it won't affect the cache.
  Map<String, dynamic> getLoadedRelations() {
    return (this as ModelRelations).loadedRelations;
  }

  /// Returns all loaded relations as a map (shorthand for [getLoadedRelations]).
  ///
  /// The returned map is a snapshot; modifying it won't affect the cache.
  Map<String, dynamic> get relations {
    return (this as ModelRelations).loadedRelations;
  }

  /// Returns names of all loaded relations.
  ///
  /// This can be used to inspect eager-loaded state.
  Set<String> get loadedRelationNames {
    return (this as ModelRelations).loadedRelationNames;
  }

  /// Returns all loaded relations as a map (property alias).
  ///
  /// The returned map is a snapshot; modifying it won't affect the cache.
  Map<String, dynamic> get loadedRelations {
    return (this as ModelRelations).loadedRelations;
  }

  /// Sets multiple relations at once.
  ///
  /// This marks each relation as loaded.
  void setRelations(Map<String, dynamic> relations) {
    (this as ModelRelations).setRelations(relations);
  }

  /// Clears all loaded relations.
  ///
  /// This removes cached relation values and loaded markers.
  void clearRelations() {
    (this as ModelRelations).clearRelations();
  }

  /// Syncs relations from a query row map.
  ///
  /// This is used internally to hydrate eager-loaded relations.
  void syncRelationsFromQueryRow(Map<String, dynamic> row) {
    (this as ModelRelations).syncRelationsFromQueryRow(row);
  }
}

/// Extensions for timestamp functionality on models.
///
/// These extensions provide safe access to timestamp methods when working
/// with models that may or may not have timestamp support.
///
/// All timestamp getters return Carbon instances for fluent date manipulation.
extension ModelTimestampExtensions<T extends Model<T>> on Model<T> {
  /// Get the creation timestamp as a Carbon instance.
  ///
  /// Returns null for directly instantiated models without timestamp tracking.
  /// For fluent date manipulation:
  /// ```dart
  /// final post = await Post.query().find(1);
  /// print(post.createdAt?.diffForHumans()); // "2 hours ago"
  /// print(post.createdAt?.format('Y-m-d H:i:s'));
  /// ```
  CarbonInterface? get createdAt {
    return switch (this) {
      TimestampsImpl t => t.createdAt,
      TimestampsTZImpl t => t.createdAt,
      _ => null,
    };
  }

  /// Sets the creation timestamp.
  ///
  /// Accepts [DateTime] or [CarbonInterface]. Only works when the model mixes in
  /// a timestamp implementation.
  set createdAt(Object? value) {
    switch (this) {
      case TimestampsImpl t:
        t.createdAt = value;
      case TimestampsTZImpl t:
        t.createdAt = value;
    }
  }

  /// Get the last update timestamp as a Carbon instance.
  ///
  /// Returns null for directly instantiated models without timestamp tracking.
  /// For fluent date manipulation:
  /// ```dart
  /// final post = await Post.query().find(1);
  /// print(post.updatedAt?.isToday()); // true/false
  /// print(post.updatedAt?.addDays(5).format('Y-m-d'));
  /// ```
  CarbonInterface? get updatedAt {
    return switch (this) {
      TimestampsImpl t => t.updatedAt,
      TimestampsTZImpl t => t.updatedAt,
      _ => null,
    };
  }

  /// Sets the last update timestamp.
  ///
  /// Accepts [DateTime] or [CarbonInterface]. Only works when the model mixes in
  /// a timestamp implementation.
  set updatedAt(Object? value) {
    switch (this) {
      case TimestampsImpl t:
        t.updatedAt = value;
      case TimestampsTZImpl t:
        t.updatedAt = value;
    }
  }

  /// Updates the updatedAt timestamp and persists it.
  ///
  /// For TimestampsTZ models, uses UTC time.
  /// Returns `false` when timestamping is disabled.
  Future<bool> touch() {
    return (this as Model).touch();
  }

  /// Saves the current model instance to the database.
  ///
  /// Deprecated: prefer `Model.save(...)`. This helper remains for older code
  /// that explicitly applies [ModelTimestampExtensions].
  @Deprecated('Use Model.save(...) instead.')
  Future<void> save() async {
    final conn = this as ModelConnection;
    if (!conn.hasConnection) {
      throw StateError(
        'Cannot save: No connection resolver attached to $runtimeType. '
        'Ensure the model was hydrated via a QueryContext or Repository.',
      );
    }

    if (this is! ModelAttributes) {
      throw StateError(
        'Cannot save: $runtimeType does not have ModelAttributes mixin.',
      );
    }

    final attrs = this as ModelAttributes;
    final dirty = attrs.getDirty();

    if (dirty.isEmpty) {
      return; // Nothing to save
    }

    // Get the model definition from the registry
    final resolver = conn.connectionResolver!;
    final definition = resolver.registry.expect<T>();

    // Get the primary key field
    final pkField = definition.primaryKeyField;
    if (pkField == null) {
      throw StateError(
        'Cannot save: Model $runtimeType does not have a primary key defined.',
      );
    }

    // Get the primary key value
    final pkValue = getAttribute(pkField.columnName);
    if (pkValue == null) {
      throw StateError('Cannot save: Model does not have a primary key value.');
    }

    // Build and execute update mutation
    final plan = MutationPlan.update(
      definition: definition,
      rows: [
        MutationRow(values: dirty, keys: {pkField.columnName: pkValue}),
      ],
      driverName: resolver.driver.metadata.name,
    );

    await conn.runMutation(plan);

    // Sync original attributes with current state
    attrs.syncOriginal();
  }
}

/// Extensions for soft delete functionality on models.
///
/// These extensions provide safe access to soft delete methods when working
/// with models that may or may not have soft delete support.
extension ModelSoftDeleteExtensions<T extends Model<T>> on Model<T> {
  /// Check if the model has been soft deleted.
  ///
  /// Returns true only if this is a tracked model instance with soft delete
  /// support and the model has been soft deleted. Returns false otherwise.
  bool get trashed {
    return switch (this) {
      SoftDeletesImpl s => s.trashed,
      SoftDeletesTZImpl s => s.trashed,
      _ => false,
    };
  }

  /// Get the soft delete timestamp as a Carbon instance.
  ///
  /// Returns the deletion timestamp if this is a tracked model instance with
  /// soft delete support and has been deleted. Returns null otherwise.
  /// For fluent date manipulation:
  /// ```dart
  /// final user = await User.query().withTrashed().find(1);
  /// print(user.deletedAt?.diffForHumans()); // "3 days ago"
  /// ```
  CarbonInterface? get deletedAt {
    return switch (this) {
      SoftDeletesImpl s => s.deletedAt,
      SoftDeletesTZImpl s => s.deletedAt,
      _ => null,
    };
  }

  /// Set the soft delete timestamp.
  ///
  /// Only works if this is a tracked model instance with soft delete support.
  /// For SoftDeletesTZ models, the timestamp is automatically converted to UTC.
  set deletedAt(Object? value) {
    switch (this) {
      case SoftDeletesImpl s:
        s.deletedAt = value;
      case SoftDeletesTZImpl s:
        s.deletedAt = value;
    }
  }
}
