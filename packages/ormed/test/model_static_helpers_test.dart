import 'package:ormed/ormed.dart';
import 'package:test/test.dart';
import 'package:driver_tests/driver_tests.dart';
import 'support/mock_driver.dart';

void main() {
  late DataSource dataSource;

  setUp(() async {
    dataSource = DataSource(
      DataSourceOptions(
        name: 'test_db',
        driver: MockDriver(),
        registry: buildOrmRegistry(),
      ),
    );
    await dataSource.init();
  });

  tearDown(() async {
    await dataSource.dispose();
    // Unregister after dispose
    if (ConnectionManager.instance.isRegistered('test_db')) {
      await ConnectionManager.instance.unregister('test_db');
    }
    // Clear default connection
    ConnectionManager.instance.clearDefault();
  });

  group('DataSource Static Helpers Setup', () {
    test('init() auto-sets first DataSource as default', () {
      // First DataSource is automatically set as default
      final defaultName = ConnectionManager.instance.defaultConnectionName;
      expect(defaultName, 'test_db');
      expect(ConnectionManager.instance.hasDefaultConnection, isTrue);
    });

    test('setAsDefault() sets default connection', () async {
      dataSource.setAsDefault();

      // Should be able to get default connection
      final defaultConn = ConnectionManager.instance.defaultConnection;
      expect(defaultConn, isNotNull);
      expect(defaultConn.config.name, 'test_db');
    });

    test('setAsDefault() sets default connection name', () async {
      dataSource.setAsDefault();

      final defaultName = ConnectionManager.instance.defaultConnectionName;
      expect(defaultName, 'test_db');
    });

    test('setDefaultConnection() requires registered connection', () {
      expect(
        () => ConnectionManager.instance.setDefaultConnection('nonexistent'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('setAsDefault() requires initialized datasource', () {
      final uninit = DataSource(
        DataSourceOptions(
          name: 'uninit',
          driver: MockDriver(),
          registry: buildOrmRegistry(),
        ),
      );

      expect(() => uninit.setAsDefault(), throwsA(isA<StateError>()));
    });

    test('can change default connection', () async {
      // Set first as default
      dataSource.setAsDefault();
      expect(ConnectionManager.instance.defaultConnectionName, 'test_db');

      // Create second datasource
      final ds2 = DataSource(
        DataSourceOptions(
          name: 'second',
          driver: MockDriver(),
          registry: buildOrmRegistry(),
        ),
      );
      await ds2.init();

      // Change default
      ds2.setAsDefault();
      expect(ConnectionManager.instance.defaultConnectionName, 'second');

      await ds2.dispose();
    });

    test('default connection persists across queries', () async {
      dataSource.setAsDefault();

      // Multiple calls should return same default
      final conn1 = ConnectionManager.instance.defaultConnection;
      final conn2 = ConnectionManager.instance.defaultConnection;

      expect(identical(conn1, conn2), isTrue);
    });
  });
}
