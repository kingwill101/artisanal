import 'package:ormed/ormed.dart';
import 'package:ormed_sqlite/ormed_sqlite.dart';

void main() async {
  // 1. Register the SQLite driver
  ensureSqliteDriverRegistration();

  // 2. Define configuration
  final config = OrmProjectConfig(
    activeConnectionName: 'default',
    connections: {
      'default': ConnectionDefinition(
        name: 'default',
        driver: DriverConfig(
          type: 'sqlite',
          options: {'path': 'database.sqlite'},
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

  print('SQLite DataSource created: ${ds.options.driver.metadata.name}');
}
