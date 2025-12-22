/// SQLite adapter for the routed ORM driver interface.
library;

import 'dart:io';

import 'package:ormed/ormed.dart';
import 'package:path/path.dart' as p;

import 'src/sqlite_adapter.dart';
export 'src/sqlite_grammar.dart';
export 'src/sqlite_adapter.dart';
export 'src/sqlite_connector.dart';
export 'src/sqlite_codecs.dart';

final _sqliteDriverRegistration = (() {
  DriverAdapterRegistry.register('sqlite', (config) {
    final database = config.option('database') ?? 'database.sqlite';
    return SqliteDriverAdapter.file(database);
  });

  DriverRegistry.registerDriver('sqlite', ({
    required Directory root,
    required ConnectionManager manager,
    required ModelRegistry registry,
    required String connectionName,
    required ConnectionDefinition definition,
  }) {
    final database = definition.driver.option('database') ?? 'database.sqlite';
    final resolved = p.normalize(p.join(root.path, database));
    return registerSqliteOrmConnection(
      name: connectionName,
      database: DatabaseConfig(driver: 'sqlite', options: {'path': resolved}),
      registry: registry,
      connection: ConnectionConfig(
        name: connectionName,
        database: resolved,
        options: Map<String, Object?>.from(definition.driver.options),
      ),
      manager: manager,
      singleton: true,
    );
  });
  return null;
})();

/// Ensures sqlite driver registers with [DriverRegistry].
void ensureSqliteDriverRegistration() => _sqliteDriverRegistration;

OrmConnectionHandle registerSqliteOrmConnection({
  required String name,
  required DatabaseConfig database,
  required ModelRegistry registry,
  ConnectionConfig? connection,
  ConnectionManager? manager,
  bool singleton = true,
}) {
  // Ensure SQLite codecs are registered
  SqliteDriverAdapter.registerCodecs();

  final factory = OrmConnectionFactory(manager: manager);
  final connectionConfig = connection ?? ConnectionConfig(name: name);
  return factory.register(
    name: name,
    connection: connectionConfig,
    singleton: singleton,
    builder: (_) {
      final adapter = SqliteDriverAdapter.custom(config: database);
      final context = QueryContext(registry: registry, driver: adapter);
      return OrmConnection(
        config: connectionConfig,
        driver: adapter,
        registry: registry,
        context: context,
      );
    },
    onRelease: singleton
        ? null
        : (connection) async {
            await connection.driver.close();
          },
  );
}
