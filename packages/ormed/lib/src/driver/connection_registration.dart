/// Utilities to register `OrmProjectConfig` entries with `ConnectionManager`.
library;

import 'dart:async';
import 'dart:io';

import '../connection/connection_handle.dart';
import '../connection/connection_manager.dart';
import '../model/model_registry.dart';
import '../orm_project_config.dart';
import 'driver_registry.dart';

String _connectionNameForDefinition(
  Directory root,
  ConnectionDefinition definition,
) {
  final driverType = definition.driver.type.toLowerCase();
  final normalized = _normalizeOptions(definition.driver.options);

  // We include the root path in the fingerprint to ensure that relative paths
  // (like in SQLite) or identical configs in different projects don't clash
  // in the global ConnectionManager.
  return _connectionName(
    driverType,
    _stableFingerprint({'root': root.path, 'options': normalized}),
  );
}

/// Returns the canonical `ConnectionManager` name for the active [config].
String connectionNameForConfig(Directory root, OrmProjectConfig config) =>
    _connectionNameForDefinition(root, config.activeConnection);

/// Registers every entry from [config] with [ConnectionManager.defaultManager].
///
/// Returns the handle for [targetConnection] after the matching driver callback
/// registers the tenant.
Future<OrmConnectionHandle> registerConnectionsFromConfig({
  required Directory root,
  required OrmProjectConfig config,
  ConnectionManager? manager,
  ModelRegistry? registry,
  String? targetConnection,
}) async {
  final connectionManager = manager ?? ConnectionManager.defaultManager;
  final modelRegistry = registry ?? ModelRegistry();
  final selectedTarget = (targetConnection ?? config.connectionName).trim();
  OrmConnectionHandle? targetHandle;

  for (final entry in config.connections.entries) {
    final connectionName = _connectionNameForDefinition(root, entry.value);
    if (connectionManager.isRegistered(connectionName)) {
      if (entry.key != selectedTarget) continue;
      await connectionManager.unregister(connectionName);
    }

    final handler = DriverRegistry.driver(entry.value.driver.type);
    final handle = await handler(
      root: root,
      manager: connectionManager,
      registry: modelRegistry,
      connectionName: connectionName,
      definition: entry.value,
    );

    if (entry.key == selectedTarget) {
      targetHandle = handle;
    }
  }

  return targetHandle ??
      (throw StateError('Connection $selectedTarget was not registered.'));
}

/// Registers [config] and returns the handle for [targetConnection].
Future<OrmConnectionHandle> createConnection(
  Directory root,
  OrmProjectConfig config, {
  String? targetConnection,
}) => registerConnectionsFromConfig(
  root: root,
  config: config,
  targetConnection: targetConnection ?? config.connectionName,
);

Map<String, Object?> _normalizeOptions(Map<String, Object?> raw) {
  final normalized = <String, Object?>{};
  raw.forEach((key, value) {
    normalized[key] = _normalizeOptionValue(value);
  });
  return normalized;
}

Object? _normalizeOptionValue(Object? value) {
  if (value is Map) {
    final map = <String, Object?>{};
    value.forEach((key, nested) {
      map[key.toString()] = _normalizeOptionValue(nested);
    });
    return map;
  }
  if (value is Iterable) {
    return value.map(_normalizeOptionValue).toList();
  }
  return value;
}

String _connectionName(String driver, Object salt) =>
    'ormed_cli.$driver.${salt.hashCode}';

String _stableFingerprint(Map<String, Object?> options) {
  if (options.isEmpty) return 'default';
  return _stringifyValue(_sortLikeJson(options));
}

Object? _sortLikeJson(Object? value) {
  if (value is Map) {
    final sortedKeys = value.keys.map((key) => key.toString()).toList()..sort();
    return {for (final key in sortedKeys) key: _sortLikeJson(value[key])};
  }
  if (value is List) {
    return value.map(_sortLikeJson).toList();
  }
  return value;
}

String _stringifyValue(Object? value) {
  if (value is Map) {
    final buffer = StringBuffer('{');
    var index = 0;
    value.forEach((key, nested) {
      if (index++ > 0) buffer.write(',');
      buffer
        ..write(key)
        ..write(':')
        ..write(_stringifyValue(nested));
    });
    buffer.write('}');
    return buffer.toString();
  }
  if (value is List) {
    final buffer = StringBuffer('[');
    for (var i = 0; i < value.length; i++) {
      if (i > 0) buffer.write(',');
      buffer.write(_stringifyValue(value[i]));
    }
    buffer.write(']');
    return buffer.toString();
  }
  return value.toString();
}
