import 'dart:async';

import 'package:ormed/ormed.dart';
import 'package:postgres/postgres.dart';

import 'postgres_type_registry.dart';

/// Builds [Connection] instances for the Postgres connector.
typedef PostgresConnectionBuilder =
    Future<Connection> Function(PostgresConnectionSettings settings);

/// Connector implementation that opens PostgreSQL connections based on
/// [DatabaseConfig] metadata.
class PostgresConnector extends Connector<Connection> {
  PostgresConnector({PostgresConnectionBuilder? builder})
    : _builder = builder ?? _defaultBuilder;

  final PostgresConnectionBuilder _builder;

  @override
  Future<ConnectionHandle<Connection>> connect(
    DatabaseEndpoint endpoint,
    ConnectionRole role,
  ) async {
    final settings = PostgresConnectionSettings.fromEndpoint(endpoint);
    final connection = await _builder(settings);

    final sessionOptions = _sessionOptions(endpoint.options);
    final sessionAllowlist = _sessionAllowlist(endpoint.options);
    for (final entry in sessionOptions.entries) {
      final key = entry.key.toString().trim();
      if (key.isEmpty) {
        throw ArgumentError.value(
          key,
          'session',
          'Postgres session option keys cannot be empty.',
        );
      }
      _validateSessionKey(key, sessionAllowlist, driverName: 'postgres');
      await connection.execute('SET $key = ${_pgLiteral(entry.value)}');
    }

    final initStatements = _initStatements(endpoint.options);
    for (final statement in initStatements) {
      if (statement.trim().isEmpty) continue;
      await connection.execute(statement);
    }
    return ConnectionHandle<Connection>(
      client: connection,
      metadata: ConnectionMetadata(
        driver: 'postgres',
        role: role,
        description: settings.description,
      ),
      onClose: () async {
        await connection.close();
      },
    );
  }

  static Future<Connection> _defaultBuilder(
    PostgresConnectionSettings settings,
  ) {
    final endpoint = Endpoint(
      host: settings.host,
      port: settings.port,
      database: settings.database,
      username: settings.username,
      password: settings.password,
    );
    final connectionSettings = ConnectionSettings(
      applicationName: settings.applicationName,
      timeZone: settings.timezone,
      sslMode: settings.sslMode ?? SslMode.disable,
      connectTimeout: settings.connectTimeout,
      queryTimeout: settings.statementTimeout,
      typeRegistry: createOrmedPostgresTypeRegistry(),
    );
    return Connection.open(endpoint, settings: connectionSettings);
  }
}

/// Normalized connection settings derived from [DatabaseEndpoint] options.
class PostgresConnectionSettings {
  PostgresConnectionSettings({
    required this.host,
    required this.port,
    required this.database,
    required this.username,
    this.password,
    this.sslMode,
    this.connectTimeout,
    this.statementTimeout,
    this.timezone,
    this.applicationName,
  });

  factory PostgresConnectionSettings.fromEndpoint(DatabaseEndpoint endpoint) {
    final options = endpoint.options;
    final uriString =
        _stringOption(options, 'uri') ??
        _stringOption(options, 'url') ??
        _stringOption(options, 'dsn');

    if (uriString != null) {
      return PostgresConnectionSettings.fromUri(uriString, options: options);
    }

    final host = _stringOption(options, 'host') ?? 'localhost';
    final port = _intOption(options, 'port') ?? 5432;
    final database =
        _stringOption(options, 'database') ?? endpoint.name ?? 'postgres';
    final username = _stringOption(options, 'username') ?? 'postgres';
    final password = _stringOption(options, 'password');
    return PostgresConnectionSettings(
      host: host,
      port: port,
      database: database,
      username: username,
      password: password,
      sslMode: _sslMode(options),
      connectTimeout: _durationOption(options, 'connectTimeout'),
      statementTimeout: _durationOption(options, 'statementTimeout'),
      timezone: _stringOption(options, 'timezone') ?? 'UTC',
      applicationName: _stringOption(options, 'applicationName'),
    );
  }

  factory PostgresConnectionSettings.fromUri(
    String value, {
    Map<String, Object?> options = const {},
  }) {
    final uri = Uri.parse(value);
    final username = uri.userInfo.isNotEmpty
        ? uri.userInfo.split(':').first
        : (_stringOption(options, 'username') ?? 'postgres');
    final password = uri.userInfo.contains(':')
        ? uri.userInfo.split(':').last
        : (_stringOption(options, 'password'));
    final database =
        uri.pathSegments.isNotEmpty && uri.pathSegments.first.isNotEmpty
        ? uri.pathSegments.first
        : (_stringOption(options, 'database') ?? 'postgres');
    final sslMode =
        uri.queryParameters['sslmode'] ?? _stringOption(options, 'sslmode');

    return PostgresConnectionSettings(
      host: uri.host.isNotEmpty ? uri.host : 'localhost',
      port: uri.hasPort ? uri.port : 5432,
      database: database,
      username: username,
      password: password,
      sslMode: _sslMode({'sslmode': sslMode}),
      connectTimeout: _durationOption(options, 'connectTimeout'),
      statementTimeout: _durationOption(options, 'statementTimeout'),
      timezone:
          uri.queryParameters['timezone'] ??
          _stringOption(options, 'timezone') ??
          'UTC',
      applicationName:
          uri.queryParameters['application_name'] ??
          _stringOption(options, 'applicationName'),
    );
  }

  final String host;
  final int port;
  final String database;
  final String username;
  final String? password;
  final SslMode? sslMode;
  final Duration? connectTimeout;
  final Duration? statementTimeout;
  final String? timezone;
  final String? applicationName;

  String get description => '$host:$port/$database';
}

SslMode? _sslMode(Map<String, Object?> options) {
  final mode = _stringOption(options, 'sslmode')?.toLowerCase();
  switch (mode) {
    case 'require':
      return SslMode.require;
    case 'verify-full':
    case 'verifyfull':
      return SslMode.verifyFull;
    case 'disable':
      return SslMode.disable;
    default:
      return null;
  }
}

String? _stringOption(Map<String, Object?> options, String key) {
  final value = options[key];
  if (value == null) return null;
  if (value is String && value.isNotEmpty) return value;
  return null;
}

int? _intOption(Map<String, Object?> options, String key) {
  final value = options[key];
  if (value == null) return null;
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  return null;
}

Duration? _durationOption(Map<String, Object?> options, String key) {
  final value = options[key];
  if (value == null) return null;
  if (value is Duration) return value;
  if (value is int) return Duration(milliseconds: value);
  if (value is String) {
    final parsed = int.tryParse(value);
    if (parsed != null) {
      return Duration(milliseconds: parsed);
    }
  }
  return null;
}

Map<String, Object?> _sessionOptions(Map<String, Object?> options) {
  return _mapFrom(options['session']);
}

Set<String> _sessionAllowlist(Map<String, Object?> options) {
  final raw =
      options['sessionAllowlist'] ?? options['session_allowlist'] ?? options['sessionAllowList'];
  return _stringListFrom(raw)
      .map((entry) => entry.trim())
      .where((entry) => entry.isNotEmpty)
      .toSet();
}

List<String> _initStatements(Map<String, Object?> options) {
  return _stringListFrom(options['init']);
}

Map<String, Object?> _mapFrom(Object? value) {
  if (value == null) return const {};
  if (value is Map<String, Object?>) {
    return Map<String, Object?>.from(value);
  }
  if (value is Map) {
    return value.map((key, dynamic v) => MapEntry(key.toString(), v));
  }
  return const {};
}

List<String> _stringListFrom(Object? value) {
  if (value == null) return const [];
  if (value is List<String>) return List<String>.from(value);
  if (value is List) {
    return value.map((entry) => entry.toString()).toList();
  }
  if (value is String && value.isNotEmpty) {
    return [value];
  }
  return const [];
}

final RegExp _sessionKeyPattern = RegExp(
  r'^[A-Za-z_][A-Za-z0-9_]*(\.[A-Za-z_][A-Za-z0-9_]*)*$',
);

void _validateSessionKey(
  String key,
  Set<String> allowlist, {
  required String driverName,
}) {
  if (!_sessionKeyPattern.hasMatch(key)) {
    throw ArgumentError.value(
      key,
      'session',
      'Invalid $driverName session option key.',
    );
  }
  if (allowlist.isNotEmpty && !allowlist.contains(key)) {
    throw ArgumentError.value(
      key,
      'session',
      'Session option "$key" is not allowlisted for $driverName.',
    );
  }
}

String _pgLiteral(Object? value) {
  if (value == null) return 'NULL';
  if (value is bool) return value ? 'TRUE' : 'FALSE';
  if (value is num) return value.toString();
  return _quote(value.toString());
}

String _quote(String value) => '\'${value.replaceAll('\'', "''")}\'';
