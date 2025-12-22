import 'package:ormed/ormed.dart';
import 'package:ormed_mysql/ormed_mysql.dart';

void main() async {
  // 1. Register the MySQL driver
  ensureMySqlDriverRegistration();

  // 2. Define configuration
  final config = OrmProjectConfig(
    activeConnectionName: 'default',
    connections: {
      'default': ConnectionDefinition(
        name: 'default',
        driver: DriverConfig(
          type: 'mysql',
          options: {
            'host': 'localhost',
            'port': 3306,
            'database': 'my_database',
            'username': 'root',
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

  print('MySQL DataSource created: ${ds.options.driver.metadata.name}');
}
