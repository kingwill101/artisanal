import 'package:ormed/ormed.dart';

import 'datasource.dart';

// #region database-init
class AppDatabase {
  AppDatabase() : _ownsDataSource = true;

  AppDatabase.fromDataSource(this.dataSource) : _ownsDataSource = false;

  late final DataSource dataSource;
  final bool _ownsDataSource;

  Future<void> init() async {
    if (_ownsDataSource) {
      dataSource = createDataSource();
    }
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
