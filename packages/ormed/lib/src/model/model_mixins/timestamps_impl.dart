import 'package:carbonized/carbonized.dart';

import 'model_attributes.dart';
import 'timestamps.dart';

/// Implementation mixin for timestamp functionality (non-timezone aware).
///
/// This mixin is applied to generated tracked model classes (_$ModelName)
/// and provides the actual timestamp functionality backed by the attribute store.
///
/// **Do not use this mixin directly in user-defined model classes.**
/// Use the marker [Timestamps] mixin instead, and the code generator will
/// apply this implementation to the generated tracked model class.
mixin TimestampsImpl on ModelAttributes {
  String get _createdAtColumn => Timestamps.defaultCreatedAtColumn;

  String get _updatedAtColumn => Timestamps.defaultUpdatedAtColumn;

  /// Timestamp when the model was created.
  ///
  /// Returns an immutable Carbon instance for fluent date manipulation.
  /// The returned instance is immutable to prevent accidental mutation.
  CarbonInterface? get createdAt {
    final value = getAttribute<DateTime?>(_createdAtColumn);
    if (value == null) return null;
    return Carbon.fromDateTime(value).toImmutable();
  }

  set createdAt(Object? value) {
    setAttribute(_createdAtColumn, switch (value) {
      null => null,
      CarbonInterface c => c.toDateTime(),
      DateTime d => d,
      _ => throw ArgumentError(
        'createdAt must be DateTime or CarbonInterface, got ${value.runtimeType}',
      ),
    });
  }

  /// Timestamp when the model was last updated.
  ///
  /// Returns an immutable Carbon instance for fluent date manipulation.
  /// The returned instance is immutable to prevent accidental mutation.
  CarbonInterface? get updatedAt {
    final value = getAttribute<DateTime?>(_updatedAtColumn);
    if (value == null) return null;
    return Carbon.fromDateTime(value).toImmutable();
  }

  set updatedAt(Object? value) {
    setAttribute(_updatedAtColumn, switch (value) {
      null => null,
      CarbonInterface c => c.toDateTime(),
      DateTime d => d,
      _ => throw ArgumentError(
        'updatedAt must be DateTime or CarbonInterface, got ${value.runtimeType}',
      ),
    });
  }

  /// Updates the updatedAt timestamp to the current time.
  void touch() {
    var now = Carbon.now().toDateTime();
    final previous = getAttribute<DateTime?>(_updatedAtColumn);
    if (previous != null &&
        now.millisecondsSinceEpoch <= previous.millisecondsSinceEpoch) {
      now = DateTime.fromMillisecondsSinceEpoch(
        previous.millisecondsSinceEpoch + 1,
        isUtc: previous.isUtc,
      );
    }
    updatedAt = now;
  }
}

/// Implementation mixin for timezone-aware timestamp functionality.
///
/// This mixin is applied to generated tracked model classes (_$ModelName)
/// and provides timezone-aware timestamp functionality. All timestamps are
/// stored and retrieved in UTC using Carbon for fluent date manipulation.
///
/// **Do not use this mixin directly in user-defined model classes.**
/// Use the marker [TimestampsTZ] mixin instead, and the code generator will
/// apply this implementation to the generated tracked model class.
mixin TimestampsTZImpl on ModelAttributes {
  String get _createdAtColumn => TimestampsTZ.defaultCreatedAtColumn;

  String get _updatedAtColumn => TimestampsTZ.defaultUpdatedAtColumn;

  /// Timestamp when the model was created (UTC).
  ///
  /// Returns an immutable Carbon instance in UTC timezone for fluent date manipulation.
  /// The returned instance is immutable to prevent accidental mutation.
  CarbonInterface? get createdAt {
    final value = getAttribute<DateTime?>(_createdAtColumn);
    if (value == null) return null;
    // Ensure the DateTime is UTC, then create Carbon with explicit UTC timezone
    // Return immutable to prevent accidental mutation of the timestamp
    final utcDateTime = value.isUtc ? value : value.toUtc();
    return Carbon.fromDateTime(utcDateTime).tz('UTC').toImmutable();
  }

  set createdAt(Object? value) {
    setAttribute(_createdAtColumn, switch (value) {
      null => null,
      CarbonInterface c => c.toUtc().toDateTime(),
      DateTime d => d.isUtc ? d : d.toUtc(),
      _ => throw ArgumentError(
        'createdAt must be DateTime or CarbonInterface, got ${value.runtimeType}',
      ),
    });
  }

  /// Timestamp when the model was last updated (UTC).
  ///
  /// Returns an immutable Carbon instance in UTC timezone for fluent date manipulation.
  /// The returned instance is immutable to prevent accidental mutation.
  CarbonInterface? get updatedAt {
    final value = getAttribute<DateTime?>(_updatedAtColumn);
    if (value == null) return null;
    // Ensure the DateTime is UTC, then create Carbon with explicit UTC timezone
    // Return immutable to prevent accidental mutation of the timestamp
    final utcDateTime = value.isUtc ? value : value.toUtc();
    return Carbon.fromDateTime(utcDateTime).tz('UTC').toImmutable();
  }

  set updatedAt(Object? value) {
    setAttribute(_updatedAtColumn, switch (value) {
      null => null,
      CarbonInterface c => c.toUtc().toDateTime(),
      DateTime d => d.isUtc ? d : d.toUtc(),
      _ => throw ArgumentError(
        'updatedAt must be DateTime or CarbonInterface, got ${value.runtimeType}',
      ),
    });
  }

  /// Updates the updatedAt timestamp to the current time in UTC.
  void touch() {
    var now = Carbon.now().toUtc().toDateTime();
    final previous = getAttribute<DateTime?>(_updatedAtColumn);
    if (previous != null &&
        now.millisecondsSinceEpoch <= previous.millisecondsSinceEpoch) {
      now = DateTime.fromMillisecondsSinceEpoch(
        previous.millisecondsSinceEpoch + 1,
        isUtc: true,
      );
    }
    updatedAt = now;
  }
}

/// Implementation mixin for timezone-aware soft-delete functionality.
///
/// This mixin is applied to generated tracked model classes (_$ModelName)
/// and provides timezone-aware soft-delete functionality. The deletion
/// timestamp is stored in UTC using Carbon for fluent date manipulation.
///
/// **Do not use this mixin directly in user-defined model classes.**
/// Use the marker [SoftDeletesTZ] mixin instead, and the code generator will
/// apply this implementation to the generated tracked model class.
mixin SoftDeletesTZImpl on ModelAttributes {
  String get _column => getSoftDeleteColumn() ?? SoftDeletesTZ.defaultColumn;

  /// Timestamp describing when the row was soft deleted (UTC).
  ///
  /// Returns an immutable Carbon instance in UTC timezone for fluent date manipulation.
  /// The returned instance is immutable to prevent accidental mutation.
  CarbonInterface? get deletedAt {
    final value = getAttribute<DateTime?>(_column);
    return value != null
        ? Carbon.fromDateTime(value).toUtc().toImmutable()
        : null;
  }

  set deletedAt(Object? value) {
    setAttribute(_column, switch (value) {
      null => null,
      CarbonInterface c => c.toUtc().toDateTime(),
      DateTime d => d.isUtc ? d : d.toUtc(),
      _ => throw ArgumentError(
        'deletedAt must be DateTime or CarbonInterface, got ${value.runtimeType}',
      ),
    });
  }

  /// Whether the model currently has a deletion timestamp.
  bool get trashed => getAttribute<DateTime?>(_column) != null;

  /// Soft deletes the model by setting deletedAt to the current UTC time.
  void trash() {
    deletedAt = Carbon.now().toUtc().toDateTime();
  }

  /// Restores a soft-deleted model by clearing the deletedAt timestamp.
  void untrash() {
    deletedAt = null;
  }
}
