import 'package:ormed/ormed.dart';
import 'package:ormed_sqlite/ormed_sqlite.dart';
import '../../orm_registry.g.dart';

// #region datasource-entrypoint
/// Creates a new DataSource instance using the project configuration.
DataSource createDataSource() {
  // Ensure the driver is registered
  ensureSqliteDriverRegistration();

  final config = loadOrmConfig();
  return DataSource.fromConfig(
    config,
    registry: bootstrapOrm(),
  );
}
// #endregion datasource-entrypoint
