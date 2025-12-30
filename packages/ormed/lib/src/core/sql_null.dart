/// Helpers for detecting SQL null wrapper values from database drivers.
///
/// Some drivers represent SQL NULL with wrapper objects instead of Dart null.
/// Those wrappers typically expose an `isSqlNull` boolean flag.
library;

/// Returns true when [value] represents a SQL NULL wrapper.
bool isSqlNullValue(Object? value) {
  if (value == null) return false;
  try {
    final dynamic dynamicValue = value;
    return dynamicValue.isSqlNull == true;
  } catch (_) {
    return false;
  }
}

/// Returns true when [value] is null or a SQL NULL wrapper.
bool isEffectivelyNull(Object? value) => value == null || isSqlNullValue(value);
