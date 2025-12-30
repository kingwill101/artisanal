// DataSource examples for documentation
// ignore_for_file: unused_local_variable

import 'dart:convert';

import 'package:contextual/contextual.dart' as contextual;
import 'package:ormed/ormed.dart';
import 'package:ormed_sqlite/ormed_sqlite.dart';

import 'models/user.dart';
import 'models/user.orm.dart';
import 'models/post.dart';
import 'models/post.orm.dart';

// #region datasource-overview
Future<void> dataSourceOverview() async {
  final ds = DataSource(
    DataSourceOptions(
      driver: SqliteDriverAdapter.file('database.sqlite'),
      entities: [UserOrmDefinition.definition, PostOrmDefinition.definition],
    ),
  );

  await ds.init();

  // Use the ORM
  final users = await ds.query<$User>().get();

  await ds.dispose();
}
// #endregion datasource-overview

// #region datasource-options
DataSourceOptions createOptions(DriverAdapter driver) {
  final options = DataSourceOptions(
    driver: driver,
    entities: [UserOrmDefinition.definition, PostOrmDefinition.definition],
    name: 'primary',
    database: 'myapp',
    tablePrefix: 'app_',
    defaultSchema: 'public',
    logging: true,
  );
  return options;
}
// #endregion datasource-options

// #region datasource-init
Future<void> initializeDataSource(DataSource ds) async {
  await ds.init();
  // init() is idempotent - calling multiple times is safe
}
// #endregion datasource-init

// #region datasource-static-helpers
Future<void> staticHelpersExample() async {
  final ds = DataSource(
    DataSourceOptions(
      name: 'myapp',
      driver: SqliteDriverAdapter.file('database.sqlite'),
      entities: [UserOrmDefinition.definition],
    ),
  );

  await ds.init(); // Auto-registers and sets as default

  // Static helpers now work automatically!
  final users = await Users.query().get();
  final post = await Posts.find(1);
}
// #endregion datasource-static-helpers

// #region datasource-querying
Future<void> queryingExamples(DataSource ds) async {
  // Simple query
  final allUsers = await ds.query<$User>().get();

  // With filters
  final activeUsers = await ds
      .query<$User>()
      .whereEquals('active', true)
      .orderBy('createdAt', descending: true)
      .limit(10)
      .get();

  // With relations
  final posts = await ds.query<$Post>().with_(['author', 'comments']).get();
}
// #endregion datasource-querying

// #region datasource-repository
Future<void> repositoryExamples(DataSource ds) async {
  final userRepo = ds.repo<$User>();

  // Insert
  await userRepo.insert(
    $User(id: 0, email: 'new@example.com', name: 'New User'),
  );

  // Insert many
  await userRepo.insertMany([
    $User(id: 0, email: 'user1@example.com'),
    $User(id: 0, email: 'user2@example.com'),
  ]);

  // Update
  final user = await userRepo.find(1);
  if (user != null) {
    user.setAttribute('name', 'Updated');
    await userRepo.update(user);
  }

  // Delete
  await userRepo.delete({'id': 1});
}
// #endregion datasource-repository

// #region datasource-transactions
Future<void> transactionExamples(DataSource ds) async {
  await ds.transaction(() async {
    final user = await ds.repo<$User>().insert(
      $User(id: 0, email: 'alice@example.com', name: 'Alice'),
    );

    await ds.repo<$Post>().insert(
      $Post(id: 0, authorId: user.id, title: 'First Post'),
    );

    // If any operation fails, all changes are rolled back
  });

  // Transactions can return values
  final result = await ds.transaction(() async {
    final user = await ds.repo<$User>().insert(
      $User(id: 0, email: 'bob@example.com', name: 'Bob'),
    );
    return user;
  });
}
// #endregion datasource-transactions

// #region datasource-adhoc
Future<void> adhocTableExamples(DataSource ds) async {
  final logs = await ds
      .table('audit_logs')
      .whereEquals('action', 'login')
      .orderBy('timestamp', descending: true)
      .limit(100)
      .get();

  for (final log in logs) {
    print('${log['user_id']} logged in at ${log['timestamp']}');
  }
}
// #endregion datasource-adhoc

// #region datasource-logging
Future<void> loggingExamples(DataSource ds) async {
  // Enable logging
  ds.enableQueryLog(includeParameters: true);

  // Execute queries...
  await ds.query<$User>().get();

  // Review the log
  for (final entry in ds.queryLog) {
    print('SQL: ${entry.sql}');
    print('Bindings: ${entry.bindings}');
    print('Duration: ${entry.duration}');
  }

  // Clear when done
  ds.clearQueryLog();
  ds.disableQueryLog();
}
// #endregion datasource-logging

// #region datasource-logging-options
DataSource createDataSourceWithLogging(DriverAdapter driver) {
  final ds = DataSource(
    DataSourceOptions(
      driver: driver,
      entities: [UserOrmDefinition.definition],
      logging: true,
    ),
  );

  // Or enable at runtime
  ds.enableQueryLog(includeParameters: true);
  ds.disableQueryLog();

  return ds;
}
// #endregion datasource-logging-options

// #region datasource-logging-logger
DataSource createDataSourceWithLogger(DriverAdapter driver) {
  final logger = contextual.Logger(defaultChannelEnabled: false);
  return DataSource(
    DataSourceOptions(
      driver: driver,
      entities: [UserOrmDefinition.definition],
      logging: true,
      logger: logger,
    ),
  );
}
// #endregion datasource-logging-logger

// #region datasource-query-log-access
void accessQueryLog(DataSource ds) {
  for (final entry in ds.queryLog) {
    print('SQL: ${entry.sql}');
    print('Bindings: ${entry.bindings}');
    print('Duration: ${entry.duration}');
  }

  ds.clearQueryLog();
}
// #endregion datasource-query-log-access

// #region datasource-pretend-mode
Future<void> pretendModeExample(DataSource ds) async {
  final statements = await ds.pretend(() async {
    await ds.repo<$User>().insert($User(id: 0, email: 'test@example.com'));
  });

  for (final entry in statements) {
    print('Would execute: ${entry.sql}');
  }
  // No actual database changes occurred
}
// #endregion datasource-pretend-mode

// #region datasource-execution-hooks
void executionHooksExample(DataSource ds) {
  final unregister = ds.beforeExecuting((statement) {
    print('[SQL] ${statement.sqlWithBindings}');
  });

  // Later, unregister
  unregister();
}
// #endregion datasource-execution-hooks

// #region datasource-multiple
Future<void> multipleDataSourcesExample() async {
  // #region datasource-multiple-setup
  final mainDs = DataSource(
    DataSourceOptions(
      name: 'main',
      driver: SqliteDriverAdapter.inMemory(),
      entities: [UserOrmDefinition.definition],
    ),
  );

  final analyticsDs = DataSource(
    DataSourceOptions(
      name: 'analytics',
      driver: SqliteDriverAdapter.inMemory(),
      entities: [PostOrmDefinition.definition],
    ),
  );

  await mainDs.init();
  await analyticsDs.init();
  // #endregion datasource-multiple-setup

  // #region datasource-multiple-default
  // Set main as default
  mainDs.setAsDefault();
  // #endregion datasource-multiple-default

  // #region datasource-multiple-query
  // Query specific databases
  final users = await mainDs.query<$User>().get();
  final events = await analyticsDs.query<$Post>().get();

  // Use static helpers with connection parameter
  final analyticsUsers = await Users.query('analytics').get();
  // #endregion datasource-multiple-query
}
// #endregion datasource-multiple

// #region datasource-lifecycle
Future<void> lifecycleExample(DataSource ds) async {
  // Check initialization state
  if (!ds.isInitialized) {
    await ds.init();
  }

  // Cleanup
  await ds.dispose();

  // Re-initialize if needed
  await ds.init();
}
// #endregion datasource-lifecycle

// #region datasource-underlying
void accessUnderlyingComponents(DataSource ds) {
  final conn = ds.connection; // ORM connection
  final ctx = ds.context; // Query context
  final registry = ds.registry; // Model registry
  final codecs = ds.codecRegistry; // Codec registry
}
// #endregion datasource-underlying

// #region datasource-custom-codecs
class JsonCodec extends ValueCodec<Map<String, dynamic>> {
  @override
  Object? encode(Map<String, dynamic>? value) =>
      value != null ? jsonEncode(value) : null;

  @override
  Map<String, dynamic>? decode(Object? value) =>
      value is String ? jsonDecode(value) : null;
}

DataSource createDataSourceWithCodecs(DriverAdapter driver) {
  final ds = DataSource(
    DataSourceOptions(
      driver: driver,
      entities: [UserOrmDefinition.definition],
      codecs: {'JsonMap': JsonCodec()},
    ),
  );
  return ds;
}

// #endregion datasource-custom-codecs
