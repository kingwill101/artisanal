import 'package:ormed/ormed.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

class SqliteConnector extends Connector<sqlite.Database> {
  SqliteConnector();

  @override
  Future<ConnectionHandle<sqlite.Database>> connect(
    DatabaseEndpoint endpoint,
    ConnectionRole role,
  ) async {
    final options = endpoint.options;
    final inMemory = options['memory'] == true;
    final path = options['path'] as String? ?? options['database'] as String?;
    late final sqlite.Database database;
    if (inMemory) {
      database = sqlite.sqlite3.openInMemory();
    } else if (path != null && path.isNotEmpty) {
      database = sqlite.sqlite3.open(path);
    } else {
      database = sqlite.sqlite3.open(':memory:');
    }

    final sessionOptions = _sessionOptions(options);
    for (final entry in sessionOptions.entries) {
      final key = entry.key.toString().trim();
      if (key.isEmpty) continue;
      database.execute('PRAGMA $key = ${_pragmaValue(entry.value)}');
    }

    final initStatements = _initStatements(options);
    for (final statement in initStatements) {
      if (statement.trim().isEmpty) continue;
      database.execute(statement);
    }

    return ConnectionHandle<sqlite.Database>(
      client: database,
      metadata: ConnectionMetadata(
        driver: endpoint.driver,
        role: role,
        description: inMemory ? ':memory:' : path,
      ),
      onClose: () async {
        database.close();
      },
    );
  }
}

Map<String, Object?> _sessionOptions(Map<String, Object?> options) {
  return _mapFrom(options['session']);
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

String _pragmaValue(Object? value) {
  if (value == null) return 'NULL';
  if (value is bool) return value ? 'ON' : 'OFF';
  if (value is num) return value.toString();
  return _quote(value.toString());
}

String _quote(String value) => '\'${value.replaceAll('\'', "''")}\'';
