/// Provides helpers to filter raw payloads through model metadata.
library;

import 'package:collection/collection.dart';

import '../../exceptions.dart';
import '../../value_codec.dart';
import '../model.dart';

/// Extensions for applying model attribute metadata to a raw map.
extension ModelAttributeMapExtensions on Map<String, Object?> {
  /// Returns a new map containing only inputs accepted by [metadata].
  ///
  /// {@macro ormed.model.mass_assignment}
  ///
  /// [fields] should come from the model definition so casting and column
  /// detection can be applied.
  ///
  /// When [unguarded] is `true`, mass-assignment guards are bypassed.
  /// When [strict] is `true`, guarded keys throw [MassAssignmentException].
  ///
  /// Values are decoded using [registry] (or [ValueCodecRegistry.instance]).
  ///
  /// Keys are matched against known field column names; unknown keys are
  /// included as-is when allowed.
  Map<String, Object?> filteredByAttributes(
    ModelAttributesMetadata metadata,
    Iterable<FieldDefinition> fields, {
    bool strict = true,
    bool unguarded = false,
    ValueCodecRegistry? registry,
  }) {
    final inspector = AttributeInspector(metadata: metadata, fields: fields);
    final codecs = registry ?? ValueCodecRegistry.instance;
    final filtered = <String, Object?>{};
    final discarded = <String>[];

    for (final entry in entries) {
      if (unguarded || inspector.isFillable(entry.key)) {
        filtered[entry.key] = _decodeEntry(
          column: entry.key,
          value: entry.value,
          inspector: inspector,
          fields: fields,
          codecs: codecs,
        );
      } else {
        discarded.add(entry.key);
      }
    }

    if (strict && discarded.isNotEmpty) {
      throw MassAssignmentException(
        'Mass assignment rejected for attributes: ${discarded.join(', ')}',
      );
    }

    return filtered;
  }

  Object? _decodeEntry({
    required String column,
    required Object? value,
    required AttributeInspector inspector,
    required Iterable<FieldDefinition> fields,
    required ValueCodecRegistry codecs,
  }) {
    final cast = inspector.castFor(column);
    if (cast != null) {
      final field = fields.firstWhereOrNull(
        (entry) => entry.columnName == column,
      );
      return codecs.decodeCast(
        cast,
        value,
        field: field,
        operation: CastOperation.assign,
      );
    }
    final field = fields.firstWhereOrNull(
      (entry) => entry.columnName == column,
    );
    if (field != null) {
      return codecs.decodeField(field, value);
    }
    return value;
  }
}
