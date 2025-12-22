/// MySQL/MariaDB adapter for the routed ORM driver interface.
library;

import 'dart:async';
import 'dart:io';

import 'package:ormed/ormed.dart';

import 'src/mysql_adapter.dart';

export 'src/mysql_adapter.dart';
export 'src/mysql_codecs.dart';
export 'src/mysql_connection_info.dart';
export 'src/mysql_connector.dart';
export 'src/mysql_grammar.dart';
export 'src/mysql_schema_dialect.dart';
export 'src/mysql_type_mapper.dart';
export 'src/mysql_value_types.dart';

final _mysqlDriverRegistration = (() {
  DriverAdapterRegistry.register('mysql', (config) {
    return MySqlDriverAdapter.custom(config: config);
  });

  DriverRegistry.registerDriver('mysql', ({
    required Directory root,
    required ConnectionManager manager,
    required ModelRegistry registry,
    required String connectionName,
    required ConnectionDefinition definition,
  }) {
    return registerMySqlOrmConnection(
      name: connectionName,
      database: DatabaseConfig(
        driver: 'mysql',
        options: Map<String, Object?>.from(definition.driver.options),
      ),
      registry: registry,
      manager: manager,
      singleton: true,
    );
  });
  return null;
})();

/// Ensures MySQL driver registers with [DriverRegistry] and [DriverAdapterRegistry].
void ensureMySqlDriverRegistration() => _mysqlDriverRegistration;

/// Registers a MySQL ORM connection with the [manager].
OrmConnectionHandle registerMySqlOrmConnection({
  required String name,
  required DatabaseConfig database,
  required ModelRegistry registry,
  ConnectionConfig? connection,
  ConnectionManager? manager,
  bool singleton = true,
}) {
  // Ensure MySQL codecs are registered
  MySqlDriverAdapter.registerCodecs();

  final factory = OrmConnectionFactory(manager: manager);
  final connectionConfig = connection ?? ConnectionConfig(name: name);
  return factory.register(
    name: name,
    connection: connectionConfig,
    singleton: singleton,
    builder: (_) {
      final adapter = MySqlDriverAdapter.custom(config: database);
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

final _mysqlDriverRegistration = (() {
  DriverAdapter createAdapter(DriverConfig config) {
    return MySqlDriverAdapter.custom(
      config: DatabaseConfig(
        driver: 'mysql',
        options: Map<String, Object?>.from(config.options),
      ),
    );
  }

  DriverAdapterRegistry.register('mysql', createAdapter);
  DriverAdapterRegistry.register('mariadb', createAdapter);

  FutureOr<OrmConnectionHandle> register({
    required Directory root,
    required ConnectionManager manager,
    required ModelRegistry registry,
    required String connectionName,
    required ConnectionDefinition definition,
  }) {
    final options = Map<String, Object?>.from(definition.driver.options);
    final databaseConfig = DatabaseConfig(driver: 'mysql', options: options);
    return registerMySqlOrmConnection(
      name: connectionName,
      database: databaseConfig,
      registry: registry,
      connection: ConnectionConfig(
        name: connectionName,
        options: options,
        defaultSchema: options['schema']?.toString(),
      ),
      manager: manager,
      singleton: true,
    );
  }

  DriverRegistry.registerDriver('mysql', register);
  DriverRegistry.registerDriver('mariadb', register);
  return null;
})();

/// Ensures the mysql/mariadb drivers register with [DriverRegistry].
void ensureMySqlDriverRegistration() => _mysqlDriverRegistration;
