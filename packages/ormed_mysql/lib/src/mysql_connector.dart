import 'dart:async';
import 'dart:io';

import 'package:mysql_client_plus/mysql_client_plus.dart';
import 'package:ormed/ormed.dart';

import 'mysql_connection_info.dart';

typedef MySqlConnectionBuilder =
    Future<MySQLConnection> Function(MySqlConnectionSettings settings);

/// Connector that opens MySQL/MariaDB connections via `mysql_client_plus`.
class MySqlConnector extends Connector<MySQLConnection> {
  MySqlConnector({MySqlConnectionBuilder? builder})
    : _builder = builder ?? _defaultBuilder;

  final MySqlConnectionBuilder _builder;

  @override
  Future<ConnectionHandle<MySQLConnection>> connect(
    DatabaseEndpoint endpoint,
    ConnectionRole role,
  ) async {
    final settings = MySqlConnectionSettings.fromEndpoint(endpoint);
    final connection = await _builder(settings);
    return ConnectionHandle<MySQLConnection>(
      client: connection,
      metadata: ConnectionMetadata(
        driver: endpoint.driver,
        role: role,
        description: settings.description,
      ),
      onClose: connection.close,
    );
  }

  static Future<MySQLConnection> _defaultBuilder(
    MySqlConnectionSettings settings,
  ) async {
    Future<MySQLConnection> connectWithHost(String host) {
      return MySQLConnection.createConnection(
        host: host,
        port: settings.port,
        userName: settings.username,
        password: settings.password ?? '',
        databaseName: settings.database,
        secure: settings.secure,
        collation: settings.collation ?? 'utf8mb4_general_ci',
      );
    }

    late final MySQLConnection connection;
    try {
      connection = await connectWithHost(settings.host);
    } on SocketException catch (_) {
      // Some environments resolve `localhost` to IPv6 only, while docker port
      // bindings may only listen on IPv4. Retry with IPv4 loopback.
      if (settings.host == 'localhost') {
        connection = await connectWithHost('127.0.0.1');
      } else {
        rethrow;
      }
    }
    await connection.connect(timeoutMs: settings.timeout.inMilliseconds);

    if (settings.charset != null && settings.charset!.isNotEmpty) {
      final collation = settings.collation ?? 'utf8mb4_general_ci';
      await connection.execute(
        "SET NAMES ${_quote(settings.charset!)} COLLATE ${_quote(collation)}",
      );
    }

    if (settings.timezone != null && settings.timezone!.isNotEmpty) {
      await connection.execute("SET time_zone = ${_quote(settings.timezone!)}");
    }

    if (settings.sqlMode != null && settings.sqlMode!.isNotEmpty) {
      await connection.execute(
        "SET SESSION sql_mode = ${_quote(settings.sqlMode!)}",
      );
    }

    if (settings.sessionVariables.isNotEmpty) {
      final assignments = settings.sessionVariables.entries
          .map((entry) {
            return '@@${entry.key} = ${_literal(entry.value)}';
          })
          .join(', ');
      await connection.execute('SET $assignments');
    }

    for (final statement in settings.initStatements) {
      await connection.execute(statement);
    }

    return connection;
  }
}

class MySqlConnectionSettings {
  MySqlConnectionSettings({
    required this.host,
    required this.port,
    required this.database,
    required this.username,
    required this.secure,
    required this.timeout,
    this.password,
    this.collation,
    this.charset,
    this.timezone,
    this.sqlMode,
    Map<String, Object?>? sessionVariables,
    List<String>? initStatements,
  }) : sessionVariables = sessionVariables ?? const {},
       initStatements = initStatements ?? const [];

  factory MySqlConnectionSettings.fromEndpoint(DatabaseEndpoint endpoint) {
    final options = endpoint.options;
    final uriString =
        _stringOption(options, 'uri') ??
        _stringOption(options, 'url') ??
        _stringOption(options, 'dsn');

    String host = '127.0.0.1';
    int port = 3306;
    String database = endpoint.name ?? 'test';
    String username = 'root';
    String? password;
    bool secure = _boolOption(options, 'ssl') ?? false;
    String? charset = _stringOption(options, 'charset') ?? 'utf8mb4';
    String? collation = _stringOption(options, 'collation');
    String? timezone = _stringOption(options, 'timezone') ?? '+00:00';
    String? sqlMode =
        _stringOption(options, 'sqlMode') ?? _stringOption(options, 'sql_mode');
    Duration timeout =
        _durationOption(options, 'timeoutMs') ??
        _durationOption(options, 'connectTimeout') ??
        const Duration(seconds: 10);

    if (uriString != null && uriString.isNotEmpty) {
      final uri = Uri.parse(uriString);
      final info = MySqlConnectionInfo.fromUrl(
        uriString,
        secureByDefault: secure,
      );

      host = info.host;
      port = info.port;
      database = info.database;
      username = info.username ?? username;
      password = info.password ?? password;
      secure = info.secure;

      charset = uri.queryParameters['charset'] ?? charset;
      collation = uri.queryParameters['collation'] ?? collation;
      timezone = uri.queryParameters['timezone'] ?? timezone;
      sqlMode =
          uri.queryParameters['sql_mode'] ??
          uri.queryParameters['sqlMode'] ??
          sqlMode;
      final timeoutQuery =
          uri.queryParameters['timeoutMs'] ??
          uri.queryParameters['connectTimeout'];
      if (timeoutQuery != null) {
        final parsed = int.tryParse(timeoutQuery);
        if (parsed != null) {
          timeout = Duration(milliseconds: parsed);
        }
      }
      if (uri.queryParameters.containsKey('password') && password == null) {
        password = uri.queryParameters['password'];
      }
    } else {
      host = _stringOption(options, 'host') ?? host;
      port = _intOption(options, 'port') ?? port;
      database = _stringOption(options, 'database') ?? database;
      username = _stringOption(options, 'username') ?? username;
      password = _stringOption(options, 'password') ?? password;
    }

    final sessionVariables =
        _mapOption(options, 'session') ?? const <String, Object?>{};
    final initStatements = _stringListOption(options, 'init');

    return MySqlConnectionSettings(
      host: host,
      port: port,
      database: database,
      username: username,
      password: password,
      secure: secure,
      timeout: timeout,
      charset: charset,
      collation: collation,
      timezone: timezone,
      sqlMode: sqlMode,
      sessionVariables: sessionVariables,
      initStatements: initStatements,
    );
  }

  final String host;
  final int port;
  final String database;
  final String username;
  final String? password;
  final bool secure;
  final Duration timeout;
  final String? collation;
  final String? charset;
  final String? timezone;
  final String? sqlMode;
  final Map<String, Object?> sessionVariables;
  final List<String> initStatements;

  String get description => '$host:$port/$database';
}

String _quote(String value) => '\'${value.replaceAll('\'', "''")}\'';

String _literal(Object? value) {
  if (value == null) return 'NULL';
  if (value is num) return value.toString();
  if (value is bool) return value ? 'TRUE' : 'FALSE';
  return _quote(value.toString());
}

String? _stringOption(Map<String, Object?> source, String key) {
  final value = source[key];
  if (value == null) return null;
  if (value is String && value.isNotEmpty) return value;
  return value.toString();
}

int? _intOption(Map<String, Object?> source, String key) {
  final value = source[key];
  if (value == null) return null;
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  return null;
}

bool? _boolOption(Map<String, Object?> source, String key) {
  final value = source[key];
  if (value == null) return null;
  if (value is bool) return value;
  if (value is String) {
    final normalized = value.toLowerCase();
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;
  }
  return null;
}

Duration? _durationOption(Map<String, Object?> source, String key) {
  final value = source[key];
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

Map<String, Object?>? _mapOption(Map<String, Object?> source, String key) {
  final value = source[key];
  if (value == null) return null;
  if (value is Map<String, Object?>) {
    return Map<String, Object?>.from(value);
  }
  if (value is Map) {
    return value.map((k, dynamic v) => MapEntry(k.toString(), v));
  }
  return null;
}

List<String> _stringListOption(Map<String, Object?> source, String key) {
  final value = source[key];
  if (value == null) return const [];
  if (value is List<String>) return List<String>.from(value);
  if (value is List) {
    return value.map((e) => e.toString()).toList();
  }
  if (value is String && value.isNotEmpty) {
    return [value];
  }
  return const [];
}
