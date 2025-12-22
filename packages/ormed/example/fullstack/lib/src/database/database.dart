import 'package:ormed/ormed.dart';
import 'package:ormed_sqlite/ormed_sqlite.dart';

import '../../orm_registry.g.dart';

// #region database-init
class AppDatabase {
  AppDatabase({required this.driver}) : _ownsDataSource = true;

  AppDatabase.fromDataSource(this.dataSource)
    : driver = dataSource.options.driver,
      _ownsDataSource = false;

  final DriverAdapter driver;
  late final DataSource dataSource;
  final bool _ownsDataSource;

  static DriverAdapter sqliteFile(String path) =>
      SqliteDriverAdapter.file(path);

  static DriverAdapter sqliteMemory() => SqliteDriverAdapter.inMemory();

  Future<void> init() async {
    final registry = bootstrapOrm();
    dataSource = DataSource(DataSourceOptions(
      driver: driver,
      registry: registry,
    ));
    await dataSource.init();
  }

  OrmConnection get connection => dataSource.connection;

  Future<void> dispose() {
    if (_ownsDataSource) {
      return dataSource.dispose();
    }
    return Future.value();
  }
}
// #endregion database-init
