import 'package:ormed/ormed.dart';
import 'package:ormed_postgres/ormed_postgres.dart';

void main() async {
  // 1. Register the PostgreSQL driver
  ensurePostgresDriverRegistration();

  // 2. Define configuration
  final config = OrmProjectConfig(
    activeConnectionName: 'default',
    connections: {
      'default': ConnectionDefinition(
        name: 'default',
        driver: DriverConfig(
          type: 'postgres',
          options: {
            'host': 'localhost',
            'port': 5432,
            'database': 'my_database',
            'username': 'postgres',
            'password': 'password',
          },
        ),
        migrations: MigrationSection(
          directory: 'database/migrations',
          registry: 'database/migrations.dart',
          ledgerTable: 'orm_migrations',
          schemaDump: 'database/schema',
        ),
      ),
    },
  );

  // 3. Create DataSource
  final ds = DataSource.fromConfig(config);

  // 4. Initialize (connects to DB)
  // await ds.init();

  print('PostgreSQL DataSource created: ${ds.options.driver.metadata.name}');
}
