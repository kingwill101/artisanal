import 'package:carbonized/carbonized.dart';

import 'model_attributes.dart';
import 'model_connection.dart';
import 'soft_deletes.dart';

/// Implementation mixin for soft-delete functionality.
///
/// This mixin is applied to generated tracked model classes (_$ModelName)
/// and provides the actual soft-delete functionality backed by the attribute store.
///
/// **Do not use this mixin directly in user-defined model classes.**
/// Use the marker [SoftDeletes] mixin instead, and the code generator will
/// apply this implementation to the generated tracked model class.
mixin SoftDeletesImpl on ModelAttributes, ModelConnection {
  String get _column => getSoftDeleteColumn() ?? SoftDeletes.defaultColumn;

  /// Timestamp describing when the row was soft deleted.
  ///
  /// Returns an immutable Carbon instance for fluent date manipulation.
  /// The returned instance is immutable to prevent accidental mutation.
  CarbonInterface? get deletedAt {
    final value = getAttribute<DateTime?>(_column);
    if (value == null) return null;
    return Carbon.fromDateTime(value).toImmutable();
  }

  set deletedAt(Object? value) {
    setAttribute(_column, switch (value) {
      null => null,
      CarbonInterface c => c.toDateTime(),
      DateTime d => d,
      _ => throw ArgumentError(
        'deletedAt must be DateTime or CarbonInterface, got ${value.runtimeType}',
      ),
    });
  }

  /// Whether the model currently has a deletion timestamp.
  bool get trashed => deletedAt != null;
}
