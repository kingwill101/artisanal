part of '../query_builder.dart';

/// Extension providing soft delete functionality for models.
extension SoftDeleteExtension<T extends OrmEntity> on Query<T> {
  /// Includes soft-deleted models in the query results.
  ///
  /// This method effectively disables the soft-delete global scope if it's applied.
  ///
  /// Example:
  /// ```dart
  /// final allUsers = await context.query<User>()
  ///   .withTrashed()
  ///   .get();
  /// ```
  Query<T> withTrashed() {
    if (_softDeleteField == null) {
      return this;
    }
    return withoutGlobalScope(Query._softDeleteScope);
  }

  /// Retrieves only soft-deleted models.
  ///
  /// This method applies a condition to only select models where the soft-delete
  /// field is not null.
  ///
  /// Example:
  /// ```dart
  /// final deletedUsers = await context.query<User>()
  ///   .onlyTrashed()
  ///   .get();
  /// ```
  Query<T> onlyTrashed() {
    final field = _softDeleteField;
    if (field == null) {
      return this;
    }
    return withTrashed().whereNotNull(field.columnName);
  }

  /// Restores soft-deleted models that match the current query constraints.
  ///
  /// This sets the soft-delete field back to null.
  /// Throws [StateError] if the model does not support soft deletes.
  ///
  /// Example:
  /// ```dart
  /// final restoredCount = await context.query<User>()
  ///   .where('id', 1)
  ///   .restore();
  /// print('Restored $restoredCount users.');
  /// ```
  Future<int> restore() async {
    final field = _requireSoftDeleteSupport('restore');
    final targets = await _prepareDeletionTargets(
      softDeleteField: field,
      softDeleteValue: null,
      includeTrashed: true,
      restoring: true,
    );
    if (targets.rows.isEmpty) {
      return 0;
    }

    final plan = MutationPlan.update(
      definition: definition,
      rows: targets.rows,
      driverName: context.driver.metadata.name,
    );
    final result = await context.runMutation(plan);
    if (result.affectedRows > 0) {
      for (final model in targets.models) {
        _events.emit(
          ModelRestoredEvent(
            modelType: definition.modelType,
            tableName: definition.tableName,
            model: model,
          ),
        );
      }
    }
    return result.affectedRows;
  }

  /// Permanently deletes models that match the current query constraints,
  /// bypassing soft deletes.
  ///
  /// Throws [StateError] if the model does not define a primary key or
  /// the driver does not expose a row identifier for query updates.
  ///
  /// Example:
  /// ```dart
  /// final deletedCount = await context.query<User>()
  ///   .where('status', 'inactive')
  ///   .forceDelete();
  /// print('Force deleted $deletedCount inactive users.');
  /// ```
  Future<int> forceDelete() async {
    // If the driver supports query deletes, fall back to the query-level plan
    // for ad-hoc tables that don't declare a PK.
    if (_supportsQueryDeletes) {
      final driverMetadata = context.driver.metadata;
      final pk = definition.primaryKeyField;
      final fallbackIdentifier = driverMetadata.queryUpdateRowIdentifier;
      final identifier = pk?.columnName ?? fallbackIdentifier?.column;
      if (identifier != null && pk == null) {
        context.emitWarning(
          QueryWarning(
            message:
                'forceDelete uses fallback row identifier "${identifier}" '
                'for ${definition.modelName}; ensure the identifier is stable.',
            definition: definition,
            feature: 'forceDelete',
            driverName: driverMetadata.name,
          ),
        );
        final selection = withTrashed();
        final plan = MutationPlan.queryDelete(
          definition: definition,
          plan: selection._buildPlan(),
          primaryKey: identifier,
          driverName: driverMetadata.name,
        );
        final result = await context.runMutation(plan);
        return result.affectedRows;
      }
    }

    final targets = await _prepareDeletionTargets(
      softDeleteField: null,
      scopeSoftDeleteField: _softDeleteField,
      includeTrashed: true,
    );
    if (targets.rows.isEmpty) return 0;

    final mutation = MutationPlan.delete(
      definition: definition,
      rows: targets.rows,
      driverName: context.driver.metadata.name,
    );
    final result = await context.runMutation(mutation);
    if (result.affectedRows > 0) {
      _emitDeletedEventsForModels(targets.models, forceDelete: true);
    }
    return result.affectedRows;
  }
}
