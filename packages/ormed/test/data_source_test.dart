import 'package:driver_tests/driver_tests.dart';
import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

void main() {
  ModelRegistry registry = bootstrapOrm();
  group('DataSource', () {
    late InMemoryQueryExecutor driver;
    late DataSource dataSource;

    setUp(() {
      driver = InMemoryQueryExecutor();
    });

    tearDown(() async {
      if (dataSource.isInitialized) {
        await dataSource.dispose();
      }
    });

    test('creates with DataSourceOptions', () {
      final options = DataSourceOptions(
        driver: driver,
        registry: registry,
        name: 'test',
      );

      dataSource = DataSource(options);

      expect(dataSource.name, 'test');
      expect(dataSource.isInitialized, isFalse);
    });

    test('creates from OrmProjectConfig', () {
      final config = OrmProjectConfig(
        connections: {
          'test-conn': ConnectionDefinition(
            name: 'test-conn',
            driver: DriverConfig(
              type: 'mock',
              options: {
                'database': 'test-db',
                'table_prefix': 'pfx_',
                'logging': true,
              },
            ),
            migrations: MigrationSection(
              directory: 'migrations',
              registry: 'registry',
              ledgerTable: 'ledger',
              schemaDump: 'dump',
            ),
          ),
        },
        activeConnectionName: 'test-conn',
      );

      DriverAdapterRegistry.register('mock', (config) => driver);

      dataSource = DataSource.fromConfig(config, registry: registry);

      expect(dataSource.name, 'test-conn');
      expect(dataSource.options.database, 'test-db');
      expect(dataSource.options.tablePrefix, 'pfx_');
      expect(dataSource.options.logging, isTrue);
      expect(dataSource.options.driver, driver);
    });

    test('init registers entities and creates connection', () async {
      dataSource = DataSource(
        DataSourceOptions(driver: driver, registry: registry),
      );

      await dataSource.init();

      expect(dataSource.isInitialized, isTrue);
      expect(dataSource.registry.contains<ActiveUser>(), isTrue);
    });

    test('init is idempotent', () async {
      dataSource = DataSource(
        DataSourceOptions(driver: driver, registry: registry),
      );

      await dataSource.init();
      await dataSource.init(); // Should not throw

      expect(dataSource.isInitialized, isTrue);
    });

    test('query throws when not initialized', () {
      dataSource = DataSource(
        DataSourceOptions(driver: driver, registry: registry),
      );

      expect(() => dataSource.query<ActiveUser>(), throwsA(isA<StateError>()));
    });

    test('repo throws when not initialized', () {
      dataSource = DataSource(
        DataSourceOptions(driver: driver, registry: registry),
      );

      expect(() => dataSource.repo<ActiveUser>(), throwsA(isA<StateError>()));
    });

    test('transaction throws when not initialized', () {
      dataSource = DataSource(
        DataSourceOptions(driver: driver, registry: registry),
      );

      expect(
        () => dataSource.transaction(() async {}),
        throwsA(isA<StateError>()),
      );
    });

    test('query returns typed query builder', () async {
      dataSource = DataSource(
        DataSourceOptions(driver: driver, registry: registry),
      );
      await dataSource.init();

      final query = dataSource.query<ActiveUser>();

      expect(query, isA<Query<ActiveUser>>());
    });

    test('repo returns typed repository', () async {
      dataSource = DataSource(
        DataSourceOptions(driver: driver, registry: registry),
      );
      await dataSource.init();

      final repo = dataSource.repo<ActiveUser>();

      expect(repo, isA<Repository<ActiveUser>>());
    });

    test('can insert and query models', () async {
      dataSource = DataSource(
        DataSourceOptions(driver: driver, registry: registry),
      );
      await dataSource.init();

      await dataSource.repo<ActiveUser>().insert(
        const ActiveUser(email: 'test@example.com', name: 'Test User'),
      );

      final users = await dataSource.query<ActiveUser>().get();

      expect(users, hasLength(1));
      expect(users.first.email, 'test@example.com');
      expect(users.first.name, 'Test User');
    });

    test('table returns ad-hoc query builder', () async {
      dataSource = DataSource(
        DataSourceOptions(driver: driver, registry: registry),
      );
      await dataSource.init();

      final query = dataSource.table('some_table');

      expect(query, isA<Query<AdHocRow>>());
    });

    test('dispose closes the connection', () async {
      dataSource = DataSource(
        DataSourceOptions(driver: driver, registry: registry),
      );
      await dataSource.init();
      expect(dataSource.isInitialized, isTrue);

      await dataSource.dispose();

      expect(dataSource.isInitialized, isFalse);
    });

    test('dispose clears default registration', () async {
      DataSource.clearDefault();
      ConnectionManager.instance.clearDefault();
      Model.unbindConnectionResolver();

      dataSource = DataSource(
        DataSourceOptions(driver: driver, registry: registry, name: 'default'),
      );
      await dataSource.init();
      dataSource.setAsDefault();

      await dataSource.dispose();

      expect(DataSource.getDefault(), isNull);
      expect(ConnectionManager.instance.hasDefaultConnection, isFalse);
      expect(() => Model.query<ActiveUser>(), throwsStateError);
    });

    test('dispose is idempotent', () async {
      dataSource = DataSource(
        DataSourceOptions(driver: driver, registry: registry),
      );
      await dataSource.init();

      await dataSource.dispose();
      await dataSource.dispose(); // Should not throw

      expect(dataSource.isInitialized, isFalse);
    });

    test('can reinitialize after dispose', () async {
      dataSource = DataSource(
        DataSourceOptions(driver: driver, registry: registry),
      );
      await dataSource.init();
      await dataSource.dispose();

      // Create new driver since old one was closed
      driver = InMemoryQueryExecutor();
      dataSource = DataSource(
        DataSourceOptions(driver: driver, registry: registry),
      );
      await dataSource.init();

      expect(dataSource.isInitialized, isTrue);
    });

    test('logging option enables query log', () async {
      dataSource = DataSource(
        DataSourceOptions(driver: driver, registry: registry, logging: true),
      );
      await dataSource.init();

      expect(dataSource.connection.loggingQueries, isTrue);
    });

    test('custom codecs are registered', () async {
      final customCodec = _TestCodec();

      dataSource = DataSource(
        DataSourceOptions(
          driver: driver,
          registry: registry,
          codecs: {'CustomType': customCodec},
        ),
      );
      await dataSource.init();

      final encoded = dataSource.codecRegistry.encodeByKey(
        'CustomType',
        'test',
      );
      expect(encoded, 'encoded:test');
    });

    test('connection exposes underlying OrmConnection', () async {
      dataSource = DataSource(
        DataSourceOptions(
          driver: driver,
          registry: registry,
          name: 'my-connection',
          database: 'my-database',
          tablePrefix: 'prefix_',
        ),
      );
      await dataSource.init();

      final conn = dataSource.connection;

      expect(conn.name, 'my-connection');
      expect(conn.database, 'my-database');
      expect(conn.tablePrefix, 'prefix_');
    });

    test('context exposes underlying QueryContext', () async {
      dataSource = DataSource(
        DataSourceOptions(driver: driver, registry: registry),
      );
      await dataSource.init();

      final context = dataSource.context;

      expect(context, isA<QueryContext>());
      expect(context, same(dataSource.connection.context));
    });

    test('pretend captures SQL without executing', () async {
      dataSource = DataSource(
        DataSourceOptions(driver: driver, registry: registry),
      );
      await dataSource.init();

      final statements = await dataSource.pretend(() async {
        await dataSource.repo<ActiveUser>().insert(
          const ActiveUser(email: 'pretend@example.com'),
        );
      });

      expect(statements, isNotEmpty);
      // Verify no actual insert happened
      final users = await dataSource.query<ActiveUser>().get();
      expect(users, isEmpty);
    });

    test('beforeExecuting registers callback', () async {
      dataSource = DataSource(
        DataSourceOptions(driver: driver, registry: registry),
      );
      await dataSource.init();

      final capturedStatements = <String>[];
      dataSource.beforeExecuting((statement) {
        capturedStatements.add(statement.sql);
      });

      await dataSource.repo<ActiveUser>().insert(
        const ActiveUser(email: 'callback@example.com'),
      );

      expect(capturedStatements, isNotEmpty);
    });

    test('enableQueryLog and flushQueryLog work correctly', () async {
      dataSource = DataSource(
        DataSourceOptions(driver: driver, registry: registry),
      );
      await dataSource.init();

      dataSource.enableQueryLog();

      await dataSource.query<ActiveUser>().get();

      expect(dataSource.queryLog, isNotEmpty);

      dataSource.flushQueryLog();

      expect(dataSource.queryLog, isEmpty);
    });

    test('disableQueryLog stops logging', () async {
      dataSource = DataSource(
        DataSourceOptions(driver: driver, registry: registry, logging: true),
      );
      await dataSource.init();

      dataSource.disableQueryLog(clear: true);

      await dataSource.query<ActiveUser>().get();

      expect(dataSource.queryLog, isEmpty);
    });
  });

  group('DataSourceOptions', () {
    test('has sensible defaults', () {
      final driver = InMemoryQueryExecutor();
      final options = DataSourceOptions(driver: driver, registry: registry);

      expect(options.name, 'default');
      expect(options.database, isNull);
      expect(options.tablePrefix, '');
      expect(options.defaultSchema, isNull);
      expect(options.codecs, isEmpty);
      expect(options.logging, isFalse);
    });

    test('copyWith preserves values', () {
      final driver = InMemoryQueryExecutor();
      final original = DataSourceOptions(
        driver: driver,
        registry: registry,
        name: 'original',
        database: 'db',
        tablePrefix: 'pre_',
        logging: true,
      );

      final copied = original.copyWith(name: 'copied');

      expect(copied.name, 'copied');
      expect(copied.database, 'db');
      expect(copied.tablePrefix, 'pre_');
      expect(copied.logging, isTrue);
      expect(copied.entities, same(original.entities));
    });

    test('copyWith can override all fields', () {
      final driver1 = InMemoryQueryExecutor();
      final driver2 = InMemoryQueryExecutor();
      final original = DataSourceOptions(
        driver: driver1,
        registry: registry,
        name: 'original',
      );

      final copied = original.copyWith(
        driver: driver2,
        registry: registry,
        name: 'new-name',
        database: 'new-db',
        tablePrefix: 'new_',
        defaultSchema: 'public',
        logging: true,
      );

      expect(copied.driver, same(driver2));
      expect(copied.entities, equals(registry.allDefinitions));
      expect(copied.name, 'new-name');
      expect(copied.database, 'new-db');
      expect(copied.tablePrefix, 'new_');
      expect(copied.defaultSchema, 'public');
      expect(copied.logging, isTrue);
    });
  });

  group('Multiple DataSources', () {
    test('can operate independently', () async {
      final driver1 = InMemoryQueryExecutor();
      final driver2 = InMemoryQueryExecutor();

      final ds1 = DataSource(
        DataSourceOptions(driver: driver1, registry: registry, name: 'ds1'),
      );

      final ds2 = DataSource(
        DataSourceOptions(driver: driver2, registry: registry, name: 'ds2'),
      );

      await ds1.init();
      await ds2.init();

      try {
        // Insert into ds1
        await ds1.repo<ActiveUser>().insert(
          const ActiveUser(email: 'ds1@example.com'),
        );

        // Insert into ds2
        await ds2.repo<ActiveUser>().insert(
          const ActiveUser(email: 'ds2@example.com'),
        );

        // Verify isolation
        final ds1Users = await ds1.query<ActiveUser>().get();
        final ds2Users = await ds2.query<ActiveUser>().get();

        expect(ds1Users, hasLength(1));
        expect(ds1Users.first.email, 'ds1@example.com');

        expect(ds2Users, hasLength(1));
        expect(ds2Users.first.email, 'ds2@example.com');
      } finally {
        await ds1.dispose();
        await ds2.dispose();
      }
    });
  });
}

class _TestCodec extends ValueCodec<String> {
  @override
  Object? encode(String? value) => value != null ? 'encoded:$value' : null;

  @override
  String? decode(Object? value) =>
      value is String ? value.replaceFirst('encoded:', '') : null;
}
