/// Ensures query and mutation observability hooks behave as expected.
///
/// Tests the observability flow:
/// - DataSource → OrmConnection → QueryContext → Driver
///
/// All observability features (listeners, query logging, duration handlers)
/// should work consistently whether accessed from DataSource, OrmConnection,
/// or QueryContext.
library;

import 'dart:async';
import 'dart:io';

import 'package:contextual/contextual.dart' as contextual;
import 'package:driver_tests/driver_tests.dart';
import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

void main() {
  ModelRegistry registry = bootstrapOrm();

  group('QueryContext observability', () {
    late InMemoryQueryExecutor driver;
    late QueryContext context;

    setUp(() {
      driver = InMemoryQueryExecutor();
      context = QueryContext(registry: registry, driver: driver);

      driver.register(AuthorOrmDefinition.definition, const [
        Author(id: 1, name: 'Alice', active: true),
        Author(id: 2, name: 'Bob', active: false),
      ]);
    });

    test('toSql delegates to the driver describe implementation', () {
      final preview = context.query<Author>().whereEquals('id', 1).toSql();
      expect(preview.sql, '<in-memory>');
    });

    test('emits query events with row counts', () async {
      final events = <QueryEvent>[];
      context.onQuery(events.add);

      final rows = await context.query<Author>().whereEquals('id', 1).rows();
      expect(rows, hasLength(1));

      expect(events, hasLength(1));
      final event = events.single;
      expect(event.rows, 1);
      expect(event.succeeded, isTrue);
      expect(event.preview.sql, '<in-memory>');
    });

    test('emits mutation events for repository inserts', () async {
      final events = <MutationEvent>[];
      context.onMutation(events.add);

      await context.repository<Author>().insert(
        const Author(id: 10, name: 'Test', active: true),
      );

      expect(events, hasLength(1));
      final event = events.single;
      expect(event.affectedRows, 1);
      expect(event.succeeded, isTrue);
      expect(event.preview.sql, '<in-memory>');
    });

    test('captures driver errors inside query events', () async {
      final failingContext = QueryContext(
        registry: registry,
        driver: _ThrowingDriver(),
      );
      final events = <QueryEvent>[];
      failingContext.onQuery(events.add);

      await expectLater(
        () => failingContext.query<Author>().get(),
        throwsStateError,
      );

      expect(events, hasLength(1));
      final event = events.single;
      expect(event.error, isA<StateError>());
      expect(event.succeeded, isFalse);
    });

    test('structured logger emits JSON-friendly maps', () async {
      final entries = <Map<String, Object?>>[];
      StructuredQueryLogger(
        onLog: entries.add,
        attributes: const {'env': 'test'},
      ).attach(context);

      await context.query<Author>().whereEquals('id', 1).first();
      await context.repository<Author>().insert(
        const Author(id: 99, name: 'Logger', active: true),
      );

      expect(entries, hasLength(2));
      final queryEntry = entries.firstWhere((e) => e['type'] == 'query');
      expect(queryEntry['model'], 'Author');
      expect(queryEntry['env'], 'test');
      final mutationEntry = entries.firstWhere((e) => e['type'] == 'mutation');
      expect(mutationEntry['operation'], 'insert');
      expect(mutationEntry['row_count'], 1);
      // Parameters may be omitted when the preview uses batched values.
      if (mutationEntry.containsKey('parameters')) {
        expect(mutationEntry['parameters'], isA<List<Object?>>());
      }
    });
  });

  group('OrmConnection observability', () {
    late InMemoryQueryExecutor driver;
    late OrmConnection connection;

    setUp(() {
      driver = InMemoryQueryExecutor()
        ..register(AuthorOrmDefinition.definition, const [
          Author(id: 1, name: 'Alice', active: true),
        ]);
      connection = OrmConnection(
        config: ConnectionConfig(name: 'test'),
        driver: driver,
        registry: registry,
      );
    });

    test('listen receives QueryExecuted events', () async {
      final events = <QueryExecuted>[];
      connection.listen(events.add);

      await connection.query<Author>().get();

      expect(events, hasLength(1));
      expect(events.first.sql, isNotEmpty);
      expect(events.first.time, greaterThanOrEqualTo(0));
      expect(events.first.connection, same(connection));
    });

    test('default contextual logger emits query logs', () async {
      final logger = contextual.Logger(defaultChannelEnabled: false);
      final entries = <contextual.LogEntry>[];
      final subscription = logger.onRecord.listen(entries.add);

      connection.attachDefaultContextualLogger(logger: logger);
      await connection.query<Author>().get();
      await Future<void>.delayed(const Duration(milliseconds: 1));

      expect(entries, hasLength(1));
      final entry = entries.single;
      expect(entry.record.message, contains('<in-memory>'));
      final context = entry.record.context.visible();
      expect(context['connection'], 'test');
      expect(context['duration_ms'], isNotNull);
      expect(context['succeeded'], isTrue);

      await subscription.cancel();
    });

    test(
      'default contextual logger uses a single channel for file logging',
      () async {
        final tempDir = await Directory.systemTemp.createTemp(
          'ormed-log-channel',
        );
        final printed = <String>[];

        await runZoned(
          () async {
            connection.attachDefaultContextualLogger(
              logFilePath: '${tempDir.path}/ormed',
            );
            await connection.query<Author>().get();
            await Future<void>.delayed(const Duration(milliseconds: 1));
          },
          zoneSpecification: ZoneSpecification(
            print: (self, parent, zone, line) => printed.add(line),
          ),
        );

        expect(printed, isEmpty);
        await tempDir.delete(recursive: true);
      },
    );

    test('enableQueryLog captures queries', () async {
      connection.enableQueryLog();

      await connection.query<Author>().get();
      await connection.repository<Author>().insert(
        const Author(id: 2, name: 'Bob', active: true),
      );

      expect(connection.queryLog, hasLength(2));
      expect(connection.queryLog[0].type, 'query');
      expect(connection.queryLog[1].type, 'mutation');
    });

    test('disableQueryLog stops capturing', () async {
      connection.enableQueryLog();
      await connection.query<Author>().get();
      expect(connection.queryLog, hasLength(1));

      connection.disableQueryLog();
      await connection.query<Author>().get();
      expect(connection.queryLog, hasLength(1)); // No new entries
    });

    test('flushQueryLog clears entries', () async {
      connection.enableQueryLog();
      await connection.query<Author>().get();
      expect(connection.queryLog, isNotEmpty);

      connection.flushQueryLog();
      expect(connection.queryLog, isEmpty);
    });

    test('totalQueryDuration accumulates', () async {
      expect(connection.totalQueryDuration(), 0);

      await connection.query<Author>().get();
      final duration1 = connection.totalQueryDuration();
      expect(duration1, greaterThanOrEqualTo(0));

      await connection.query<Author>().get();
      expect(connection.totalQueryDuration(), greaterThanOrEqualTo(duration1));
    });

    test('onEvent receives transaction events', () async {
      final beginEvents = <TransactionBeginning>[];
      final commitEvents = <TransactionCommitted>[];
      final rollbackEvents = <TransactionRolledBack>[];
      connection.onEvent<TransactionBeginning>(beginEvents.add);
      connection.onEvent<TransactionCommitted>(commitEvents.add);
      connection.onEvent<TransactionRolledBack>(rollbackEvents.add);

      await connection.transaction(() async {
        await connection.query<Author>().get();
      });

      expect(beginEvents, hasLength(1));
      expect(commitEvents, hasLength(1));
      expect(rollbackEvents, isEmpty);
      expect(beginEvents.first.connection, same(connection));
    });

    test('transaction rollback emits rollback event', () async {
      final rollbackEvents = <TransactionRolledBack>[];
      connection.onEvent<TransactionRolledBack>(rollbackEvents.add);

      await expectLater(
        connection.transaction(() async {
          throw StateError('fail');
        }),
        throwsA(isA<StateError>()),
      );

      expect(rollbackEvents, hasLength(1));
      expect(rollbackEvents.first.connection, same(connection));
    });

    test('transaction boundaries are logged', () async {
      connection.enableQueryLog();
      await connection.transaction(() async {
        await connection.query<Author>().get();
      });

      final sqls = connection.queryLog.map((entry) => entry.sql).toList();
      expect(sqls, contains('BEGIN'));
      expect(sqls, contains('COMMIT'));
    });

    test('nested transactions log savepoints', () async {
      connection.enableQueryLog();
      await connection.transaction(() async {
        await connection.transaction(() async {
          await connection.query<Author>().get();
        });
      });

      final sqls = connection.queryLog.map((entry) => entry.sql).toList();
      expect(sqls, contains('SAVEPOINT sp_2'));
      expect(sqls, contains('RELEASE SAVEPOINT sp_2'));
    });

    test('nested transaction rollback logs rollback to savepoint', () async {
      connection.enableQueryLog();
      await expectLater(
        connection.transaction(() async {
          await connection.transaction(() async {
            throw StateError('nested fail');
          });
        }),
        throwsA(isA<StateError>()),
      );

      final sqls = connection.queryLog.map((entry) => entry.sql).toList();
      expect(sqls, contains('ROLLBACK TO SAVEPOINT sp_2'));
    });
  });

  group('DataSource observability', () {
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

    test('listen flows from DataSource to OrmConnection', () async {
      dataSource = DataSource(
        DataSourceOptions(driver: driver, registry: registry),
      );
      await dataSource.init();

      final events = <QueryExecuted>[];
      dataSource.listen(events.add);

      await dataSource.query<Author>().get();

      expect(events, hasLength(1));
      expect(events.first.sql, isNotEmpty);
    });

    test('enableQueryLog flows from DataSource to OrmConnection', () async {
      dataSource = DataSource(
        DataSourceOptions(driver: driver, registry: registry),
      );
      await dataSource.init();

      dataSource.enableQueryLog();

      await dataSource.query<Author>().get();

      expect(dataSource.queryLog, hasLength(1));
      // Verify both return the same entries (same data)
      expect(
        dataSource.queryLog.first.preview.sql,
        dataSource.connection.queryLog.first.preview.sql,
      );
    });

    test('logging option in DataSourceOptions enables query log', () async {
      dataSource = DataSource(
        DataSourceOptions(driver: driver, registry: registry, logging: true),
      );
      await dataSource.init();

      // Query log should already be enabled
      expect(dataSource.connection.loggingQueries, isTrue);

      await dataSource.query<Author>().get();
      expect(dataSource.queryLog, hasLength(1));
    });

    test('logging option uses provided contextual logger', () async {
      final logger = contextual.Logger(defaultChannelEnabled: false);
      final entries = <contextual.LogEntry>[];
      final subscription = logger.onRecord.listen(entries.add);

      dataSource = DataSource(
        DataSourceOptions(
          driver: driver,
          registry: registry,
          logging: true,
          logger: logger,
        ),
      );
      await dataSource.init();

      await dataSource.query<Author>().get();
      await Future<void>.delayed(const Duration(milliseconds: 1));

      expect(entries, hasLength(1));
      expect(dataSource.logger, same(logger));
      expect(dataSource.connection.logger, same(logger));

      await subscription.cancel();
    });

    test(
      'contextual logger is not attached when logging is disabled',
      () async {
        final logger = contextual.Logger(defaultChannelEnabled: false);
        dataSource = DataSource(
          DataSourceOptions(
            driver: driver,
            registry: registry,
            logging: false,
            logger: logger,
          ),
        );
        await dataSource.init();

        expect(dataSource.logger, isNull);
        expect(dataSource.connection.logger, isNull);
      },
    );

    test('beforeExecuting flows from DataSource', () async {
      dataSource = DataSource(
        DataSourceOptions(driver: driver, registry: registry),
      );
      await dataSource.init();

      final statements = <ExecutingStatement>[];
      dataSource.beforeExecuting(statements.add);

      await dataSource.query<Author>().get();

      expect(statements, hasLength(1));
      expect(statements.first.type, ExecutingStatementType.query);
    });

    test('whenQueryingForLongerThan flows from DataSource', () async {
      final slowDriver =
          _DelayingDriver(delay: const Duration(milliseconds: 20))..register(
            AuthorOrmDefinition.definition,
            const [Author(id: 1, name: 'Alice', active: true)],
          );

      dataSource = DataSource(
        DataSourceOptions(driver: slowDriver, registry: registry),
      );
      await dataSource.init();

      QueryExecuted? capturedEvent;
      dataSource.whenQueryingForLongerThan(
        const Duration(milliseconds: 5),
        (conn, event) => capturedEvent = event,
      );

      await dataSource.query<Author>().get();

      expect(capturedEvent, isNotNull);
      expect(capturedEvent!.time, greaterThanOrEqualTo(5));
    });

    test('totalQueryDuration flows from DataSource', () async {
      dataSource = DataSource(
        DataSourceOptions(driver: driver, registry: registry),
      );
      await dataSource.init();

      expect(dataSource.totalQueryDuration(), 0);

      await dataSource.query<Author>().get();

      expect(dataSource.totalQueryDuration(), greaterThanOrEqualTo(0));
    });

    test('pretend captures SQL without executing', () async {
      dataSource = DataSource(
        DataSourceOptions(driver: driver, registry: registry),
      );
      await dataSource.init();

      final statements = await dataSource.pretend(() async {
        await dataSource.query<Author>().get();
        await dataSource.repo<Author>().insert(
          const Author(id: 1, name: 'Test', active: true),
        );
      });

      expect(statements, hasLength(2));
      // Verify no actual data was inserted
      final authors = await dataSource.query<Author>().get();
      expect(authors, isEmpty);
    });
  });

  group('Observability flow: DataSource → OrmConnection → QueryContext', () {
    late InMemoryQueryExecutor driver;
    late DataSource dataSource;

    setUp(() async {
      driver = InMemoryQueryExecutor()
        ..register(AuthorOrmDefinition.definition, const [
          Author(id: 1, name: 'Alice', active: true),
        ]);
      dataSource = DataSource(
        DataSourceOptions(driver: driver, registry: registry),
      );
      await dataSource.init();
    });

    tearDown(() async {
      await dataSource.dispose();
    });

    test(
      'listeners at DataSource receive events from QueryContext operations',
      () async {
        final dsEvents = <QueryExecuted>[];
        final connEvents = <QueryExecuted>[];

        dataSource.listen(dsEvents.add);
        dataSource.connection.listen(connEvents.add);

        // Execute query via DataSource
        await dataSource.query<Author>().get();

        // Both should receive the same event
        expect(dsEvents, hasLength(1));
        expect(connEvents, hasLength(1));
      },
    );

    test('query log entries contain connection metadata', () async {
      final customDs = DataSource(
        DataSourceOptions(
          driver: InMemoryQueryExecutor()
            ..register(AuthorOrmDefinition.definition, const <Author>[]),
          registry: registry,
          name: 'custom-connection',
          database: 'custom-db',
          tablePrefix: 'prefix_',
          logging: true,
        ),
      );
      await customDs.init();

      try {
        await customDs.query<Author>().get();

        expect(customDs.queryLog, hasLength(1));
        // Connection metadata should be available in events
        expect(customDs.connection.name, 'custom-connection');
        expect(customDs.connection.database, 'custom-db');
        expect(customDs.connection.tablePrefix, 'prefix_');
      } finally {
        await customDs.dispose();
      }
    });
  });
}

class _ThrowingDriver extends InMemoryQueryExecutor {
  @override
  Future<List<Map<String, Object?>>> execute(QueryPlan plan) async {
    throw StateError('boom');
  }
}

class _DelayingDriver extends InMemoryQueryExecutor {
  _DelayingDriver({required this.delay});

  final Duration delay;

  @override
  Future<List<Map<String, Object?>>> execute(QueryPlan plan) async {
    await Future.delayed(delay);
    return super.execute(plan);
  }

  @override
  Future<MutationResult> runMutation(MutationPlan plan) async {
    await Future.delayed(delay);
    return super.runMutation(plan);
  }
}
