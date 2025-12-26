/// Provides per-instance attribute storage for ORM models.
///
/// {@macro ormed.model.tracked_instances}
///
/// {@macro ormed.model.mass_assignment}
///
/// {@macro ormed.model.json_attribute_updates}
///
/// User-defined model classes should be immutable with `final` fields. The
/// generated `_$ModelName` classes extend user models and use this mixin to
/// provide attribute tracking, change detection, and relationship management.
///
/// Attributes are guarded/encoded through the decorators defined on the
/// attached [ModelDefinition].
library;

import 'dart:collection';

import '../../../ormed.dart';
import '../../query/json_path.dart' as json_path;

/// Attribute storage and change tracking for a model instance.
///
/// This mixin is applied to generated tracked models (the `$Model` types).
/// It is not intended for user-defined model classes.
mixin ModelAttributes {
  static int _unguardedCount = 0;

  /// Runs [callback] while temporarily bypassing mass assignment guards.
  static T unguarded<T>(T Function() callback) {
    _unguardedCount++;
    try {
      return callback();
    } finally {
      _unguardedCount--;
    }
  }

  static final Expando<Map<String, Object?>> _store =
      Expando<Map<String, Object?>>('_ormAttributes');
  static final Expando<ModelDefinition<OrmEntity>> _definitions =
      Expando<ModelDefinition<OrmEntity>>('_ormModelDefinition');
  static final Expando<String> _softDeleteColumns = Expando<String>(
    '_ormSoftDeleteColumn',
  );
  static final Expando<List<JsonAttributeUpdate>> _jsonUpdates =
      Expando<List<JsonAttributeUpdate>>('_ormJsonUpdates');
  static final Expando<Map<String, Object?>> _originalAttributes =
      Expando<Map<String, Object?>>('_ormOriginalAttributes');

  Map<String, Object?> _ensureAttributes() =>
      _store[this] ??= <String, Object?>{};

  List<JsonAttributeUpdate> _ensureJsonUpdates() =>
      _jsonUpdates[this] ??= <JsonAttributeUpdate>[];

  Map<String, Object?>? _getOriginalAttributes() => _originalAttributes[this];

  /// Snapshot of the current attribute map.
  Map<String, Object?> get attributes =>
      UnmodifiableMapView(_ensureAttributes());

  /// Convenience method to get all attributes as a map.
  ///
  /// This is equivalent to the [attributes] getter but provided as a method
  /// for API consistency.
  ///
  /// Returns an unmodifiable view of the attribute map.
  ///
  /// Note: This only returns tracked attributes. On plain model instances
  /// (not ORM-managed), this may return an empty map.
  Map<String, Object?> getAttributes() => attributes;

  /// Reads an attribute by column name.
  T? getAttribute<T>(String column) {
    final value = _ensureAttributes()[column];
    final accessor = _accessorFor(column);
    if (accessor == null) {
      return value as T?;
    }
    return accessor(this as OrmEntity, value) as T?;
  }

  /// Reads an attribute value without applying accessors.
  Object? getRawAttribute(String column) => _ensureAttributes()[column];

  /// Upserts an attribute value.
  void setAttribute(String column, Object? value) {
    final mutator = _mutatorFor(column);
    final nextValue =
        mutator == null ? value : mutator(this as OrmEntity, value);
    _ensureAttributes()[column] = nextValue;
  }

  /// Stores an attribute value without applying mutators.
  ///
  /// Intended for generated code that already applied mutators.
  void setRawAttribute(String column, Object? value) {
    _ensureAttributes()[column] = value;
  }

  /// Replaces the entire attribute map.
  void replaceAttributes(Map<String, Object?> values) {
    _store[this] = Map<String, Object?>.from(values);
  }

  /// Checks if an attribute exists in the attribute map.
  ///
  /// Returns true if the attribute has been set, even if its value is null.
  /// Returns false if the attribute has never been set or if attribute tracking
  /// is not initialized (e.g., on plain model instances not managed by the ORM).
  ///
  /// Note: This only works on ORM-managed model instances (those created by
  /// queries or with attribute tracking properly initialized).
  ///
  /// Example:
  /// ```dart
  /// final user = await Users.query().where('id', 1).first();
  /// print(user.hasAttribute('email')); // true
  /// print(user.hasAttribute('nonexistent')); // false
  /// ```
  bool hasAttribute(String column) {
    final attrs = _store[this];
    return attrs != null && attrs.containsKey(column);
  }

  /// Associates the generated model definition with this instance.
  void attachModelDefinition(ModelDefinition<OrmEntity> definition) {
    _definitions[this] = definition;
  }

  /// Definition metadata attached to this model, when available.
  ModelDefinition<OrmEntity>? get modelDefinition => _definitions[this];

  /// Stores the effective soft delete column for this instance.
  void attachSoftDeleteColumn(String column) {
    _softDeleteColumns[this] = column;
  }

  /// Returns the soft delete column name if the model supports it.
  String? getSoftDeleteColumn() {
    return _softDeleteColumns[this] ?? modelDefinition?.softDeleteColumn;
  }

  /// Queues a JSON update for [columnOrSelector].
  ///
  /// When [pathOverride] is null, [columnOrSelector] may include `->`/`->>`
  /// syntax.
  void setJsonAttributeValue(
    String columnOrSelector,
    Object? value, {
    String? pathOverride,
    bool patch = false,
  }) {
    final parsed = _parseJsonSelector(columnOrSelector, pathOverride);
    _ensureJsonUpdates().add(
      JsonAttributeUpdate(
        fieldOrColumn: parsed.column,
        path: parsed.path,
        value: value,
        patch: patch,
      ),
    );
  }

  /// Queues a JSON patch merge for [column] with the provided delta map.
  void setJsonAttributePatch(String column, Map<String, Object?> delta) {
    setJsonAttributeValue(column, delta, pathOverride: r'$', patch: true);
  }

  /// Returns and clears any pending JSON attribute updates.
  List<JsonAttributeUpdate> takeJsonAttributeUpdates() {
    final pending = _jsonUpdates[this];
    if (pending == null || pending.isEmpty) {
      return const <JsonAttributeUpdate>[];
    }
    _jsonUpdates[this] = <JsonAttributeUpdate>[];
    return List<JsonAttributeUpdate>.from(pending);
  }

  /// Clears any pending JSON attribute updates without applying them.
  void clearJsonAttributeUpdates() {
    _jsonUpdates[this]?.clear();
  }

  _ParsedJsonSelector _parseJsonSelector(
    String columnOrSelector,
    String? overridePath,
  ) {
    final trimmed = columnOrSelector.trim();
    if (overridePath != null && overridePath.trim().isNotEmpty) {
      return _ParsedJsonSelector(
        column: trimmed,
        path: json_path.normalizeJsonPath(overridePath),
      );
    }
    final selector = json_path.parseJsonSelectorExpression(trimmed);
    if (selector != null) {
      return _ParsedJsonSelector(column: selector.column, path: selector.path);
    }
    return _ParsedJsonSelector(column: trimmed, path: r'$');
  }

  bool get _isUngarded => _unguardedCount > 0;

  AttributeInspector _attributeInspector() => AttributeInspector(
    metadata: _metadata,
    fields: modelDefinition?.fields ?? const <FieldDefinition>[],
  );

  ModelAttributesMetadata get _metadata =>
      modelDefinition?.metadata ?? const ModelAttributesMetadata();

  ModelDefinition<OrmEntity>? get _definition => modelDefinition;

  AttributeAccessor? _accessorFor(String column) =>
      modelDefinition?.accessors[column];

  AttributeMutator? _mutatorFor(String column) =>
      modelDefinition?.mutators[column];

  /// Fills attributes from [payload], respecting fillable/guarded metadata.
  ///
  /// Returns a map containing the values that were accepted. When [strict]
  /// is `true`, guarded properties produce a [MassAssignmentException].
  Map<String, Object?> fillAttributes(
    Map<String, Object?> payload, {
    bool strict = true,
    ValueCodecRegistry? registry,
  }) {
    final inspector = _attributeInspector();
    final codecs = registry ?? ValueCodecRegistry.instance;
    final filled = <String, Object?>{};
    final discarded = <String>[];
    for (final entry in payload.entries) {
      if (_isUngarded || inspector.isFillable(entry.key)) {
        final decoded = _decodeAttribute(
          column: entry.key,
          value: entry.value,
          registry: codecs,
          definition: _definition,
          inspector: inspector,
        );
        setAttribute(entry.key, decoded);
        filled[entry.key] = decoded;
      } else {
        discarded.add(entry.key);
      }
    }
    if (strict && discarded.isNotEmpty) {
      throw MassAssignmentException(
        'Mass assignment rejected for attributes: ${discarded.join(', ')}',
      );
    }
    return filled;
  }

  /// Serializes the attribute map, applying casts and filtering hidden fields.
  Map<String, Object?> serializableAttributes({
    bool includeHidden = false,
    ValueCodecRegistry? registry,
  }) {
    final inspector = _attributeInspector();
    final codecs = registry ?? ValueCodecRegistry.instance;
    final result = <String, Object?>{};
    final definition = _definition;
    final accessors = definition?.accessors ?? const <String, AttributeAccessor>{};
    final attrs = _ensureAttributes();
    for (final entry in attrs.entries) {
      if (!_shouldSerializeColumn(entry.key, includeHidden, inspector)) {
        continue;
      }
      final accessor = accessors[entry.key];
      final value = accessor == null
          ? entry.value
          : accessor(this as OrmEntity, entry.value);
      result[entry.key] =
          accessor == null
              ? _encodeAttribute(
                column: entry.key,
                value: value,
                registry: codecs,
                definition: definition,
                inspector: inspector,
              )
              : codecs.encodeValue(value);
    }

    final appends = _metadata.appends;
    if (appends.isNotEmpty) {
      for (final attribute in appends) {
        if (result.containsKey(attribute)) {
          continue;
        }
        if (!_shouldSerializeColumn(attribute, includeHidden, inspector)) {
          continue;
        }
        final accessor = accessors[attribute];
        if (accessor != null) {
          result[attribute] = codecs.encodeValue(
            accessor(this as OrmEntity, attrs[attribute]),
          );
          continue;
        }
        if (!attrs.containsKey(attribute)) {
          continue;
        }
        result[attribute] = _encodeAttribute(
          column: attribute,
          value: attrs[attribute],
          registry: codecs,
          definition: definition,
          inspector: inspector,
        );
      }
    }
    return result;
  }

  bool _shouldSerializeColumn(
    String column,
    bool includeHidden,
    AttributeInspector inspector,
  ) {
    if (!inspector.isHidden(column)) return true;
    if (!includeHidden) return false;
    return inspector.isVisible(column);
  }

  Object? _decodeAttribute({
    required String column,
    required Object? value,
    required ValueCodecRegistry registry,
    required ModelDefinition<OrmEntity>? definition,
    required AttributeInspector inspector,
  }) {
    final cast = inspector.castFor(column);
    if (cast != null) {
      final field = definition?.fieldByColumn(column);
      return registry.decodeCast(
        cast,
        value,
        field: field,
        operation: CastOperation.assign,
      );
    }
    if (definition == null) {
      return value;
    }
    final field = definition.fieldByColumn(column);
    if (field == null) {
      return value;
    }
    return registry.decodeField(field, value);
  }

  Object? _encodeAttribute({
    required String column,
    required Object? value,
    required ValueCodecRegistry registry,
    required ModelDefinition<OrmEntity>? definition,
    required AttributeInspector inspector,
  }) {
    final cast = inspector.castFor(column);
    if (cast != null) {
      final field = definition?.fieldByColumn(column);
      return registry.encodeCast(
        cast,
        value,
        field: field,
        operation: CastOperation.serialize,
      );
    }
    if (definition == null) {
      return value;
    }
    final field = definition.fieldByColumn(column);
    if (field == null) {
      return value;
    }
    return registry.encodeField(field, value);
  }

  /// Convenience method to fill attributes from a map, respecting fillable/guarded rules.
  ///
  /// This is a wrapper around [fillAttributes] that makes the API more intuitive.
  /// Only attributes marked as fillable (or not guarded) will be set.
  ///
  /// Example:
  /// ```dart
  /// final user = await Users.query().where('id', 1).first();
  /// user.fill({
  ///   'name': 'New Name',
  ///   'email': 'new@example.com',
  /// });
  /// ```
  ///
  /// Note: This only works properly on ORM-managed model instances.

  // NOTE: fill() and forceFill() methods have been moved to the Model class
  // to avoid return type conflicts. The Model class methods return Model<TModel>
  // for method chaining, while calling this mixin's fillAttributes() internally.

  /// Convenience method to set multiple attributes at once without guards.
  ///
  /// Unlike [fill] and [forceFill], this directly sets attributes without
  /// going through the fillable/guarded logic. It's the most permissive way
  /// to bulk-set attributes.
  ///
  /// Example:
  /// ```dart
  /// final user = await Users.query().where('id', 1).first();
  /// user.setAttributes({
  ///   'name': 'New Name',
  ///   'email': 'new@example.com',
  ///   'active': true,
  /// });
  /// ```
  ///
  /// Note: This only works properly on ORM-managed model instances.
  void setAttributes(Map<String, Object?> attributes) {
    for (final entry in attributes.entries) {
      setAttribute(entry.key, entry.value);
    }
  }

  /// Syncs the current attributes as the "original" state for change tracking.
  ///
  /// After calling this, [isDirty] will return false until attributes are modified.
  /// This is typically called automatically when a model is loaded from the database.
  ///
  /// Example:
  /// ```dart
  /// final user = await Users.query().where('id', 1).first();
  /// user.setAttribute('name', 'Changed');
  /// print(user.isDirty()); // true
  /// user.syncOriginal();
  /// print(user.isDirty()); // false
  /// ```
  void syncOriginal() {
    _originalAttributes[this] = Map<String, Object?>.from(_ensureAttributes());
  }

  /// Checks if any attributes have been modified since the last sync.
  ///
  /// When [attributes] is provided, checks if those specific attributes are dirty.
  /// - If a single String is provided, checks that one attribute
  /// - If a [List<String>] is provided, checks if any of those attributes are dirty
  /// When [attributes] is null, checks if any attribute is dirty.
  ///
  /// Returns false if no original state is tracked (e.g., on new unsaved models).
  ///
  /// Example:
  /// ```dart
  /// final user = await Users.query().where('id', 1).first();
  /// print(user.isDirty()); // false
  /// user.setAttribute('name', 'New Name');
  /// print(user.isDirty()); // true
  /// print(user.isDirty('name')); // true
  /// print(user.isDirty(['name', 'email'])); // true (name is dirty)
  /// print(user.isDirty('email')); // false
  /// ```
  bool isDirty([Object? attributes]) {
    final original = _getOriginalAttributes();
    if (original == null) {
      return false; // No original state tracked
    }

    final current = _ensureAttributes();

    if (attributes == null) {
      // Check if any attribute is dirty
      final allKeys = {...original.keys, ...current.keys};
      for (final key in allKeys) {
        if (original[key] != current[key]) {
          return true;
        }
      }
      return false;
    }

    // Handle both String and List<String>
    final List<String> attrsToCheck;
    if (attributes is String) {
      attrsToCheck = [attributes];
    } else if (attributes is List<String>) {
      attrsToCheck = attributes;
    } else {
      throw ArgumentError(
        'attributes must be a String or List<String>, got ${attributes.runtimeType}',
      );
    }

    // Check specific attributes
    for (final attr in attrsToCheck) {
      if (original[attr] != current[attr]) {
        return true;
      }
    }
    return false;
  }

  /// Checks if attributes have NOT been modified since the last sync.
  ///
  /// This is the inverse of [isDirty].
  ///
  /// When [attributes] is provided, checks if those specific attributes are clean.
  /// - If a single String is provided, checks that one attribute
  /// - If a [List<String>] is provided, checks if all those attributes are clean
  /// When [attributes] is null, checks if all attributes are clean.
  ///
  /// Example:
  /// ```dart
  /// final user = await Users.query().where('id', 1).first();
  /// print(user.isClean()); // true
  /// user.setAttribute('name', 'New Name');
  /// print(user.isClean()); // false
  /// print(user.isClean('email')); // true
  /// print(user.isClean(['email'])); // true
  /// ```
  bool isClean([Object? attributes]) => !isDirty(attributes);

  /// Gets the original value(s) before modifications.
  ///
  /// When [attribute] is provided, returns the original value for that specific attribute.
  /// When [attribute] is null, returns a map of all original attributes.
  ///
  /// If no original state is tracked, returns the current value(s).
  ///
  /// Example:
  /// ```dart
  /// final user = await Users.query().where('id', 1).first();
  /// user.setAttribute('name', 'New Name');
  /// print(user.getOriginal('name')); // Original name
  /// print(user.getAttribute('name')); // 'New Name'
  /// ```
  Object? getOriginal([String? attribute]) {
    final original = _getOriginalAttributes();

    if (original == null) {
      // No original tracked, return current state
      if (attribute == null) {
        return Map<String, Object?>.from(_ensureAttributes());
      }
      return _ensureAttributes()[attribute];
    }

    if (attribute == null) {
      return Map<String, Object?>.from(original);
    }

    return original[attribute];
  }

  /// Gets only the attributes that have been modified.
  ///
  /// Returns a map containing only the changed attributes with their new values.
  /// Returns an empty map if nothing has changed or no original state is tracked.
  ///
  /// Example:
  /// ```dart
  /// final user = await Users.query().where('id', 1).first();
  /// user.setAttribute('name', 'New Name');
  /// user.setAttribute('email', 'new@example.com');
  /// print(user.getDirty()); // {'name': 'New Name', 'email': 'new@example.com'}
  /// ```
  Map<String, Object?> getDirty() {
    final original = _getOriginalAttributes();
    if (original == null) {
      return const {};
    }

    final current = _ensureAttributes();
    final dirty = <String, Object?>{};

    for (final entry in current.entries) {
      if (original[entry.key] != entry.value) {
        dirty[entry.key] = entry.value;
      }
    }

    return dirty;
  }

  /// Checks if a specific attribute was modified.
  ///
  /// This is a convenience method equivalent to `isDirty(attribute)`.
  ///
  /// Example:
  /// ```dart
  /// final user = await Users.query().where('id', 1).first();
  /// user.setAttribute('name', 'New Name');
  /// print(user.wasChanged('name')); // true
  /// print(user.wasChanged('email')); // false
  /// ```
  bool wasChanged(String attribute) => isDirty(attribute);
}

/// Represents a queued JSON attribute operation.
class JsonAttributeUpdate {
  const JsonAttributeUpdate({
    required this.fieldOrColumn,
    required this.path,
    required this.value,
    this.patch = false,
  });

  /// The column or field being patched.
  final String fieldOrColumn;

  /// JSON path describing where within the structure to apply the update.
  final String path;

  /// Value to assign or merge into the JSON column.
  final Object? value;

  /// Whether the update should merge the existing JSON value.
  final bool patch;
}

class _ParsedJsonSelector {
  _ParsedJsonSelector({required this.column, required this.path});

  final String column;
  final String path;
}
