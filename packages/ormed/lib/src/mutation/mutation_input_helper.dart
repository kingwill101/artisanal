import 'package:carbonized/carbonized.dart' show Carbon;
import 'package:carbonized/carbonized.dart';
import 'package:ormed/src/model/model.dart';

import '../core/monotonic_time.dart';
import '../contracts.dart';
import '../value_codec.dart';

/// Shared helper for normalizing mutation inputs (values/where) across
/// Repository and Query. Keeps field/column name handling consistent.
class MutationInputHelper<T extends OrmEntity> {
  MutationInputHelper({required this.definition, required this.codecs});

  final ModelDefinition<T> definition;
  final ValueCodecRegistry codecs;

  // ---------------------------------------------------------------------------
  // INSERT helpers
  // ---------------------------------------------------------------------------

  /// Converts an insert input into a column/value map.
  ///
  /// Supports tracked models, DTOs, or raw maps. Optionally applies legacy
  /// sentinel filtering for tracked models to skip non-insertable sentinel values.
  Map<String, Object?> insertInputToMap(
    Object input, {
    required bool applySentinelFiltering,
  }) {
    return switch (input) {
      T model => _modelToInsertMap(
        model,
        applySentinelFiltering: applySentinelFiltering,
      ),
      InsertDto<dynamic> dto => _normalizeColumnNames(dto.toMap()),
      UpdateDto<dynamic> dto => _normalizeColumnNames(dto.toMap()),
      Map<String, Object?> m => _normalizeColumnNames(m),
      _ => throw ArgumentError.value(
        input,
        'input',
        'Expected $T, InsertDto<$T>, UpdateDto<$T>, or Map<String, Object?>, got ${input.runtimeType}',
      ),
    };
  }

  Map<String, Object?> _modelToInsertMap(
    T model, {
    required bool applySentinelFiltering,
  }) {
    final map = definition.toMap(model, registry: codecs);
    if (!applySentinelFiltering) return map;

    final filtered = Map<String, Object?>.from(map);
    for (final field in definition.fields) {
      if (!field.isInsertable) {
        final value = map[field.columnName];
        if (_isLegacySentinelValue(value, field)) {
          filtered.remove(field.columnName);
        }
      }
    }
    return filtered;
  }

  /// Ensures timestamps (created_at/updated_at) are present in a values map.
  /// Only manages snake_case timestamp columns.
  void ensureTimestampsInMap(
    Map<String, Object?> values, {
    required bool isInsert,
  }) {
    if (!_timestampsEnabled) {
      return;
    }
    if (isInsert) {
      try {
        final createdAtField = definition.fields.firstWhere(
          (f) => f.columnName == 'created_at',
        );
        final columnName = createdAtField.columnName;
        if (!values.containsKey(columnName) ||
            _isNullValue(values[columnName])) {
          final now = _createTimestampValue(createdAtField);
          values[columnName] = codecs.encodeField(createdAtField, now);
        }
      } catch (_) {}
    }

    try {
      final updatedAtField = definition.fields.firstWhere(
        (f) => f.columnName == 'updated_at',
      );
      final columnName = updatedAtField.columnName;
      if (isInsert) {
        if (!values.containsKey(columnName) ||
            _isNullValue(values[columnName])) {
          final now = _createTimestampValue(updatedAtField);
          values[columnName] = codecs.encodeField(updatedAtField, now);
        }
      } else {
        if (!values.containsKey(columnName)) {
          final now = _createTimestampValue(updatedAtField);
          values[columnName] = codecs.encodeField(updatedAtField, now);
        }
      }
    } catch (_) {}
  }

  /// Applies timestamps on tracked models (snake_case only) for inserts.
  void applyInsertTimestampsToModel(T model) {
    if (model is! ModelAttributes) return;
    if (!_timestampsEnabled) return;
    final attrs = model as ModelAttributes;
    final now = monotonicNowUtc();

    try {
      final createdAtField = definition.fields.firstWhere(
        (f) => f.columnName == 'created_at',
      );
      final columnName = createdAtField.columnName;
      if (attrs.getAttribute<dynamic>(columnName) == null) {
        attrs.setAttribute(columnName, now);
      }
    } catch (_) {}

    try {
      final updatedAtField = definition.fields.firstWhere(
        (f) => f.columnName == 'updated_at',
      );
      final columnName = updatedAtField.columnName;
      if (attrs.getAttribute<dynamic>(columnName) == null) {
        attrs.setAttribute(columnName, now);
      }
    } catch (_) {}
  }

  /// Applies updated_at timestamp on tracked models (snake_case only) for updates.
  void applyUpdateTimestampsToModel(T model) {
    if (model is! ModelAttributes) return;
    if (!_timestampsEnabled) return;
    final attrs = model as ModelAttributes;
    final now = monotonicNowUtc();

    try {
      final updatedAtField = definition.fields.firstWhere(
        (f) => f.columnName == 'updated_at',
      );
      final columnName = updatedAtField.columnName;
      final hasOriginal = attrs.hasOriginalAttributes;
      final explicit = hasOriginal
          ? attrs.isDirty(columnName)
          : attrs.hasAttribute(columnName);
      if (!explicit) {
        attrs.setAttribute(columnName, now);
      }
    } catch (_) {}
  }

  /// Normalizes a where-like input into a column/value map.
  ///
  /// Supports:
  /// - tracked model [T]
  /// - [PartialEntity<T>]
  /// - [InsertDto<T>], [UpdateDto<T>]
  /// - [Map<String, Object?>]
  /// - null => null
  Map<String, Object?>? whereInputToMap(Object? input) {
    if (input == null) return null;

    return switch (input) {
      // Tracked model ($User) - extract all column values
      T model => definition.toMap(model, registry: codecs),
      // PartialEntity ($UserPartial) - use toMap()
      PartialEntity<dynamic> partial => _normalizeColumnNames(partial.toMap()),
      // InsertDto ($UserInsertDto) - use toMap()
      InsertDto<dynamic> dto => _normalizeColumnNames(dto.toMap()),
      // UpdateDto ($UserUpdateDto) - use toMap()
      UpdateDto<dynamic> dto => _normalizeColumnNames(dto.toMap()),
      // Raw Map - use as-is with column name normalization
      Map<String, Object?> m => _normalizeColumnNames(m),
      // Primitive PK values or anything else: map to primary key when available.
      _ when _isPrimaryKeyValue(input) => _normalizePrimaryKeyValue(input),
      // Unsupported types fall back to caller logic (e.g., extractPrimaryKey or pk fallback).
      _ => null,
    };
  }

  /// Converts a fill-style input to a column/value map.
  ///
  /// Supports:
  /// - tracked model instances (uses tracked attributes)
  /// - [PartialEntity<T>]
  /// - [InsertDto<T>], [UpdateDto<T>]
  /// - [Map<String, Object?>]
  Map<String, Object?> attributesInputToMap(Object input) {
    return switch (input) {
      ModelAttributes model => _normalizeColumnNames(model.attributes),
      PartialEntity<dynamic> partial => _normalizeColumnNames(partial.toMap()),
      InsertDto<dynamic> dto => _normalizeColumnNames(dto.toMap()),
      UpdateDto<dynamic> dto => _normalizeColumnNames(dto.toMap()),
      Map<String, Object?> m => _normalizeColumnNames(m),
      Map m => _normalizeColumnNames(_stringKeyMap(m)),
      _ => throw ArgumentError.value(
        input,
        'attributes',
        'Expected tracked model, PartialEntity, InsertDto, UpdateDto, or Map<String, Object?>, got ${input.runtimeType}',
      ),
    };
  }

  /// Extracts primary key from supported inputs.
  Object? extractPrimaryKey(Object input) {
    final pkField = definition.primaryKeyField;
    if (pkField == null) {
      throw StateError('Primary key required for ${definition.modelName}.');
    }

    if (input is T) {
      final map = definition.toMap(input, registry: codecs);
      return map[pkField.columnName];
    }

    if (input is InsertDto<T>) {
      final map = input.toMap();
      return map[pkField.columnName] ?? map[pkField.name];
    }

    if (input is UpdateDto<T>) {
      final map = input.toMap();
      return map[pkField.columnName] ?? map[pkField.name];
    }

    if (input is Map<String, Object?>) {
      return input[pkField.columnName] ?? input[pkField.name];
    }

    return null;
  }

  Map<String, Object?> _normalizeColumnNames(Map<String, Object?> input) {
    final result = <String, Object?>{};
    for (final entry in input.entries) {
      final columnName = _fieldToColumnName(entry.key);
      result[columnName] = entry.value;
    }
    return result;
  }

  Map<String, Object?> _stringKeyMap(Map input) {
    final result = <String, Object?>{};
    for (final entry in input.entries) {
      final key = entry.key;
      if (key is! String) {
        throw ArgumentError.value(
          key,
          'attributes',
          'Expected string keys in attribute maps.',
        );
      }
      result[key] = entry.value;
    }
    return result;
  }

  String _fieldToColumnName(String fieldOrColumn) {
    // First check if it's already a column name
    for (final field in definition.fields) {
      if (field.columnName == fieldOrColumn) {
        return fieldOrColumn;
      }
    }
    // Try to find by field name
    for (final field in definition.fields) {
      if (field.name == fieldOrColumn) {
        return field.columnName;
      }
    }
    // Return as-is if not found (could be custom column)
    return fieldOrColumn;
  }

  bool isTrackedModel(Object input) => input is ModelAttributes;

  bool _isLegacySentinelValue(Object? value, FieldDefinition field) {
    if (value == null) return true;
    if (field.autoIncrement) {
      if (value == 0 || value == -1) return true;
    }
    if (value == '') return true;
    return false;
  }

  bool _isNullValue(Object? value) => value == null;

  bool _isPrimaryKeyValue(Object? value) =>
      value is num || value is String || value is bool;

  FieldDefinition? _primaryKeyFieldOrNull() => definition.primaryKeyField;

  Map<String, Object?>? _normalizePrimaryKeyValue(Object input) {
    final pk = _primaryKeyFieldOrNull();
    if (pk == null) return null;
    // Leave type validation to codecs/drivers; just map the value.
    return {pk.columnName: input};
  }

  Object _createTimestampValue(FieldDefinition field) {
    final nowUtc = monotonicNowUtc();
    final type = field.dartType;
    if (type == 'Carbon' ||
        type == 'Carbon?' ||
        type == 'CarbonInterface' ||
        type == 'CarbonInterface?') {
      return Carbon.fromDateTime(nowUtc);
    }
    return nowUtc;
  }

  bool get _timestampsEnabled {
    if (!definition.metadata.timestamps) return false;
    if (Model.isIgnoringTimestamps(
      definition.modelType,
      modelName: definition.modelName,
    )) {
      return false;
    }
    return true;
  }

  /// Converts an update input to a map suitable for updates.
  ///
  /// Supports:
  /// - tracked model T (filters non-updatable fields)
  /// - [UpdateDto<T>]
  /// - [InsertDto<T>]
  /// - [Map<String, Object?>]
  Map<String, Object?> updateInputToMap(Object input) {
    return switch (input) {
      T model => _modelToUpdateMap(model),
      UpdateDto<dynamic> dto => _normalizeColumnNames(dto.toMap()),
      InsertDto<dynamic> dto => _normalizeColumnNames(dto.toMap()),
      Map<String, Object?> m => _normalizeColumnNames(m),
      _ => throw ArgumentError.value(
        input,
        'values',
        'Expected $T, UpdateDto<$T>, InsertDto<$T>, or Map<String, Object?>, got ${input.runtimeType}',
      ),
    };
  }

  Map<String, Object?> _modelToUpdateMap(T model) {
    final allValues = definition.toMap(model, registry: codecs);

    // Filter out non-updatable fields
    final values = <String, Object?>{};
    for (final field in definition.fields) {
      if (field.isUpdatable && allValues.containsKey(field.columnName)) {
        values[field.columnName] = allValues[field.columnName];
      }
    }
    return values;
  }
}
