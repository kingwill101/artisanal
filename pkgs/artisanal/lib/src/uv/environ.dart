/// Environment variable access and snapshotting.
///
/// Provides the [Environ] class for managing a snapshot of environment
/// variables, allowing for consistent lookups across the UV subsystem.
///
/// {@category Ultraviolet}
/// {@subCategory Utilities}
library;

/// An environment snapshot represented as `KEY=value` strings.
///
/// Like the Go implementation, lookups walk **backwards** so the last entry
/// wins if there are duplicates.
final class Environ {
  const Environ(this.values);

  final List<String> values;

  /// Returns the value of [key], or `''` if missing.
  String getenv(String key) => lookupEnv(key).value ?? '';

  /// Looks up [key] and returns `(value, found)`.
  ({String? value, bool found}) lookupEnv(String key) {
    final prefix = '$key=';
    for (var i = values.length - 1; i >= 0; i--) {
      final entry = values[i];
      if (entry.startsWith(prefix)) {
        return (value: entry.substring(prefix.length), found: true);
      }
    }
    return (value: null, found: false);
  }
}
