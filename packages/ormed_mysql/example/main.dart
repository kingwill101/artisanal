import 'package:ormed/ormed.dart';
import 'package:ormed_mysql/ormed_mysql.dart';

void main() async {
  // 1. Register the MySQL driver
  ensureMySqlDriverRegistration();

  // 2. Define configuration
  final config = OrmProjectConfig(
    connections: {
      'default': ConnectionDefinition(
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
      ),
    },
  );

  // 3. Create DataSource
  final ds = DataSource.fromConfig(config);

  // 4. Initialize (connects to DB)
  // await ds.init();

  print('MySQL DataSource created: ${ds.options.driver.metadata.name}');
}
