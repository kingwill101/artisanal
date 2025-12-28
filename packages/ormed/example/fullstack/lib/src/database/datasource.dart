import 'package:ormed/ormed.dart';
import 'package:ormed_fullstack_example/orm_registry.g.dart';
import 'package:ormed_sqlite/ormed_sqlite.dart';

// #region datasource-helper
/// Creates a new DataSource instance using the project configuration.
DataSource createDataSource() {
  ensureSqliteDriverRegistration();

  final config = loadOrmConfig();
  return DataSource.fromConfig(config, registry: bootstrapOrm());
}

// #endregion datasource-helper
