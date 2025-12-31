/// Defines the portable ORM project configuration used by the CLI and runtimes.
library;

import 'package:yaml/yaml.dart';

/// Default authoring format used by CLI migration generation.
enum MigrationFormat { dart, sql }

class DriverConfig {
  /// Creates a driver descriptor with a [type] (e.g., `sqlite`) and [options].
  DriverConfig({required this.type, required this.options});

  /// The driver identifier that `ormed_cli` and `ConnectionManager` consume.
  final String type;

  /// Arbitrary key/value pairs that flow into a `DatabaseConfig`.
  final Map<String, Object?> options;

  /// Retrieves a typed option value.
  String? option(String key) => options[key]?.toString();

  /// Builds a config from a decoded YAML map.
  factory DriverConfig.fromMap(Map<String, Object?> map) => DriverConfig(
    type: map['type']?.toString() ?? '',
    options: _normalizeOptions(map['options']),
  );

  /// Serializes the driver block back to a map for regeneration.
  Map<String, Object?> toMap() => {
    'type': type,
    'options': Map<String, Object?>.from(options),
  };

  /// Creates a copy with optional overrides.
  DriverConfig copyWith({String? type, Map<String, Object?>? options}) {
    return DriverConfig(
      type: type ?? this.type,
      options: options ?? Map<String, Object?>.from(this.options),
    );
  }
}

class MigrationSection {
  /// Describes migrations metadata used for registry generation.
  MigrationSection({
    required this.directory,
    required this.registry,
    required this.ledgerTable,
    required this.schemaDump,
    this.format = MigrationFormat.dart,
  });

  /// Directory where migration sources live.
  final String directory;

  /// Dart file that exports `buildMigrations()`.
  final String registry;

  /// Ledger table name used by `SqlMigrationLedger`.
  final String ledgerTable;

  /// Schema dump directory path for `schema_dump`. Files are named `<connection>-schema.sql`.
  final String schemaDump;

  /// Default authoring format used by CLI generators.
  final MigrationFormat format;

  /// Reconstructs the section from YAML.
  factory MigrationSection.fromMap(Map<String, Object?> map) =>
      MigrationSection(
        directory: map['directory']?.toString() ?? '',
        registry: map['registry']?.toString() ?? '',
        ledgerTable: map['ledger_table']?.toString() ?? 'orm_migrations',
        schemaDump: map['schema_dump']?.toString() ?? 'database/schema',
        format: _parseMigrationFormat(map['format']),
      );

  /// Serializes the section back to a map.
  Map<String, Object?> toMap() => {
    'directory': directory,
    'registry': registry,
    'ledger_table': ledgerTable,
    'schema_dump': schemaDump,
    if (format != MigrationFormat.dart) 'format': format.name,
  };

  /// Clones the section with optional overrides.
  MigrationSection copyWith({
    String? directory,
    String? registry,
    String? ledgerTable,
    String? schemaDump,
    MigrationFormat? format,
  }) {
    return MigrationSection(
      directory: directory ?? this.directory,
      registry: registry ?? this.registry,
      ledgerTable: ledgerTable ?? this.ledgerTable,
      schemaDump: schemaDump ?? this.schemaDump,
      format: format ?? this.format,
    );
  }
}

MigrationFormat _parseMigrationFormat(Object? value) {
  final normalized = value?.toString().trim().toLowerCase();
  switch (normalized) {
    case null:
    case '':
    case 'dart':
      return MigrationFormat.dart;
    case 'sql':
      return MigrationFormat.sql;
    default:
      throw StateError(
        'Invalid migrations.format "$value". Expected "dart" or "sql".',
      );
  }
}

class SeedSection {
  /// Declares where the seed registry lives.
  SeedSection({
    required this.directory,
    required this.registry,
    List<String>? seedNames,
  }) : seedNames = List.unmodifiable(seedNames ?? const []);

  /// Directory containing seeder libraries.
  final String directory;

  /// Registry file (e.g., `database/seeders.dart`).
  final String registry;

  /// Known seeders (populated at runtime/CLI when available).
  final List<String> seedNames;

  /// Creates the section from a YAML map.
  factory SeedSection.fromMap(Map<String, Object?> map) => SeedSection(
    directory: map['directory']?.toString() ?? '',
    registry: map['registry']?.toString() ?? '',
    seedNames: (map['seed_names'] as List?)
        ?.map((entry) => entry.toString())
        .toList(),
  );

  /// Serializes the section back to plain data.
  Map<String, Object?> toMap() => {
    'directory': directory,
    'registry': registry,
    if (seedNames.isNotEmpty) 'seed_names': seedNames,
  };

  /// Clones the section with the provided overrides.
  SeedSection copyWith({
    String? directory,
    String? registry,
    List<String>? seedNames,
  }) {
    return SeedSection(
      directory: directory ?? this.directory,
      registry: registry ?? this.registry,
      seedNames: seedNames ?? this.seedNames,
    );
  }
}

class ConnectionDefinition {
  /// Describes a single named connection within `orm.yaml`.
  ConnectionDefinition({
    required this.name,
    required this.driver,
    required this.migrations,
    this.seeds,
  });

  /// Logical connection name.
  final String name;

  /// Driver block.
  final DriverConfig driver;

  /// Migrations metadata block.
  final MigrationSection migrations;

  /// Optional seeds block.
  final SeedSection? seeds;

  /// Creates a definition from a decoded map.
  factory ConnectionDefinition.fromMap(String name, Map<String, Object?> map) {
    final driverMap = map['driver'] as Map<String, Object?>?;
    if (driverMap == null) {
      throw StateError('Connection $name is missing a driver block.');
    }
    final migrationsMap = map['migrations'] as Map<String, Object?>?;
    if (migrationsMap == null) {
      throw StateError('Connection $name is missing a migrations block.');
    }

    final seedsBlock = map['seeds'] as Map<String, Object?>?;
    return ConnectionDefinition(
      name: name,
      driver: DriverConfig.fromMap(driverMap),
      migrations: MigrationSection.fromMap(migrationsMap),
      seeds: seedsBlock == null ? null : SeedSection.fromMap(seedsBlock),
    );
  }

  /// Converts the definition back to a map.
  Map<String, Object?> toMap() {
    final result = <String, Object?>{
      'driver': driver.toMap(),
      'migrations': migrations.toMap(),
    };
    if (seeds != null) {
      result['seeds'] = seeds!.toMap();
    }
    return result;
  }

  /// Clones with optional overrides.
  ConnectionDefinition copyWith({
    DriverConfig? driver,
    MigrationSection? migrations,
    SeedSection? seeds,
  }) {
    return ConnectionDefinition(
      name: name,
      driver: driver ?? this.driver,
      migrations: migrations ?? this.migrations,
      seeds: seeds ?? this.seeds,
    );
  }
}

class OrmProjectConfig {
  /// Represents the entire (multi-tenant aware) `orm.yaml`.
  OrmProjectConfig({
    required Map<String, ConnectionDefinition> connections,
    required this.activeConnectionName,
    this.defaultConnectionName,
  }) : _connections = Map.unmodifiable(connections),
       assert(connections.isNotEmpty),
       assert(
         connections.containsKey(activeConnectionName),
         'Active connection $activeConnectionName must exist in connections.',
       );

  final Map<String, ConnectionDefinition> _connections;
  final String activeConnectionName;
  final String? defaultConnectionName;

  /// All connection definitions declared in `orm.yaml`.
  Map<String, ConnectionDefinition> get connections => _connections;

  /// The currently selected connection entry.
  ConnectionDefinition get activeConnection =>
      _connections[activeConnectionName]!;

  /// Active connection name or the single entry fallback.
  String get connectionName => activeConnection.name;

  /// Driver block for the active connection.
  DriverConfig get driver => activeConnection.driver;

  /// Migrations metadata for the active connection.
  MigrationSection get migrations => activeConnection.migrations;

  /// Seeds metadata when provided.
  SeedSection? get seeds => activeConnection.seeds;

  /// Returns a copy targeting the named connection.
  OrmProjectConfig withConnection(String name) {
    final normalized = name.trim();
    if (!_connections.containsKey(normalized)) {
      throw StateError('Connection $normalized is not defined.');
    }
    return OrmProjectConfig(
      connections: _connections,
      activeConnectionName: normalized,
      defaultConnectionName: defaultConnectionName,
    );
  }

  /// Updates the active connection block.
  OrmProjectConfig updateActiveConnection({
    DriverConfig? driver,
    MigrationSection? migrations,
    SeedSection? seeds,
  }) {
    final current = activeConnection;
    final updated = current.copyWith(
      driver: driver,
      migrations: migrations,
      seeds: seeds,
    );
    final entries = Map<String, ConnectionDefinition>.from(_connections);
    entries[activeConnectionName] = updated;
    return OrmProjectConfig(
      connections: entries,
      activeConnectionName: activeConnectionName,
      defaultConnectionName: defaultConnectionName,
    );
  }

  /// Rebuilds the config tree from decoded YAML.
  factory OrmProjectConfig.fromMap(Map<String, Object?> data) {
    final defaultConnection = (data['default_connection'] as String?)
        ?.trim()
        .notEmptyOrNull;
    final definitions = <String, ConnectionDefinition>{};

    final connectionsBlock = data['connections'];
    if (connectionsBlock is Map) {
      for (final entry in connectionsBlock.entries) {
        final key = entry.key?.toString().trim();
        if (key == null || key.isEmpty) continue;
        final block = _flatten(entry.value);
        definitions[key] = ConnectionDefinition.fromMap(key, block);
      }
    }

    if (definitions.isEmpty) {
      definitions['default'] = ConnectionDefinition.fromMap('default', data);
    }

    final effectiveDefault =
        defaultConnection ??
        (definitions.length == 1 ? definitions.keys.first : null);
    if (effectiveDefault == null) {
      throw StateError(
        'Multiple connections configured but default_connection is missing.',
      );
    }
    if (!definitions.containsKey(effectiveDefault)) {
      throw StateError(
        'default_connection "$effectiveDefault" is not defined.',
      );
    }

    return OrmProjectConfig(
      connections: definitions,
      activeConnectionName: effectiveDefault,
      defaultConnectionName: defaultConnection,
    );
  }

  /// Builds a configuration map suitable for serialization/reuse.
  Map<String, Object?> toMap() {
    final result = <String, Object?>{};
    if (defaultConnectionName != null) {
      result['default_connection'] = defaultConnectionName;
    }
    if (connections.length > 1) {
      final map = <String, Object?>{};
      for (final entry in connections.entries) {
        map[entry.key] = entry.value.toMap();
      }
      result['connections'] = map;
    } else {
      final only = connections.values.first;
      result.addAll(only.toMap());
    }
    return result;
  }

  /// Creates a config directly from parsed YAML.
  factory OrmProjectConfig.fromYaml(YamlMap yaml) =>
      OrmProjectConfig.fromMap(_flatten(yaml));
}

Map<String, Object?> _flatten(Object? value) {
  if (value is YamlMap) {
    return Map<String, Object?>.fromEntries(
      value.entries.map(
        (entry) => MapEntry(entry.key.toString(), _convert(entry.value)),
      ),
    );
  }
  if (value is Map) {
    return Map<String, Object?>.fromEntries(
      value.entries.map(
        (entry) => MapEntry(entry.key.toString(), _convert(entry.value)),
      ),
    );
  }
  return const {};
}

Object? _convert(Object? value) {
  if (value is YamlMap) return _flatten(value);
  if (value is YamlList) return value.map(_convert).toList();
  return value;
}

Map<String, Object?> _normalizeOptions(Object? options) {
  if (options is YamlMap) {
    return Map<String, Object?>.fromEntries(
      options.entries.map(
        (entry) => MapEntry(entry.key.toString(), _convert(entry.value)),
      ),
    );
  }
  if (options is Map) {
    return Map<String, Object?>.fromEntries(
      options.entries.map(
        (entry) => MapEntry(entry.key.toString(), _convert(entry.value)),
      ),
    );
  }
  return const {};
}

extension on String? {
  /// Returns the trimmed string, or `null` if empty.
  String? get notEmptyOrNull {
    final value = this;
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
