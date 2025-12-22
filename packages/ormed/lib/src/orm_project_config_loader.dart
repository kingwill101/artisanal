/// Loads `ormed.yaml` into portable project configuration metadata.
library;

import 'dart:io';

import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:meta/meta.dart';
import 'package:yaml/yaml.dart';

import 'orm_project_config.dart';

/// Finds the `ormed.yaml` file by searching from [startDirectory] up to the
/// filesystem root.
///
/// Returns `null` if no `ormed.yaml` is found.
File? findOrmConfigFile([Directory? startDirectory]) {
  var current = startDirectory ?? Directory.current;
  while (true) {
    final candidate = File('${current.path}/ormed.yaml');
    if (candidate.existsSync()) {
      return candidate;
    }
    final parent = current.parent;
    if (parent.path == current.path) {
      // Reached filesystem root
      return null;
    }
    current = parent;
  }
}

/// Loads [OrmProjectConfig] by finding `ormed.yaml` in the current directory
/// or any parent directory.
///
/// This is a convenience wrapper around [loadOrmProjectConfig] that
/// automatically locates the config file.
///
/// Throws [StateError] if no `ormed.yaml` is found.
///
/// Example:
/// ```dart
/// import 'package:ormed/ormed.dart';
///
/// void main() async {
///   final config = loadOrmConfig();
///   print('Database: ${config.driver.option("database")}');
///   print('Driver type: ${config.driver.type}');
/// }
/// ```
OrmProjectConfig loadOrmConfig([Directory? startDirectory]) {
  final file = findOrmConfigFile(startDirectory);
  if (file == null) {
    throw StateError(
      'Could not find ormed.yaml. Run `ormed init` first or ensure you are '
      'running from within a project directory.',
    );
  }
  return loadOrmProjectConfig(file);
}

/// Loads [OrmProjectConfig] from [file].
///
/// Throws when the file is missing so callers can instruct users to run
/// `ormed init`.
OrmProjectConfig loadOrmProjectConfig(File file) {
  if (!file.existsSync()) {
    throw StateError('Missing ormed.yaml at ${file.path}. Run `ormed init` first.');
  }
  final parsed = loadYaml(file.readAsStringSync());
  final env = _loadEnv(file.parent);
  final expanded = _expandEnv(parsed, env);
  return OrmProjectConfig.fromMap(expanded as Map<String, Object?>);
}

/// Recursively expand `${VAR}` or `${VAR:-default}` placeholders inside a YAML
/// structure using [environment]. Strings without placeholders are returned
/// unchanged.
@visibleForTesting
Object? expandEnv(Object? value, Map<String, String> environment) =>
    _expandEnv(value, environment);

Map<String, String> _loadEnv(Directory directory) {
  final env = dotenv.DotEnv(includePlatformEnvironment: true, quiet: true);
  final candidate = File('${directory.path}/.env');
  env.load(candidate.existsSync() ? [candidate.path] : const <String>[]);
  // DotEnv exposes the merged map; ignore visibility lint because this is the
  // supported way to read loaded values.
  // ignore: invalid_use_of_visible_for_testing_member
  return Map<String, String>.from(env.map);
}

Object? _expandEnv(Object? value, Map<String, String> environment) {
  if (value is Map) {
    return {
      for (final entry in value.entries)
        entry.key.toString(): _expandEnv(entry.value, environment),
    };
  }
  if (value is Iterable) {
    return value.map((item) => _expandEnv(item, environment)).toList();
  }
  if (value is String) {
    return _expandString(value, environment);
  }
  return value;
}

final RegExp _envPattern = RegExp(r'\$\{([^}:]+)(:-([^}]*))?\}');

String _expandString(String input, Map<String, String> environment) {
  return input.replaceAllMapped(_envPattern, (match) {
    final key = match.group(1)!;
    final fallback = match.group(3);
    return environment[key] ?? (fallback ?? '');
  });
}
