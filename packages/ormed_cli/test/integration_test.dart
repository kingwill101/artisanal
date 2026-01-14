import 'dart:async';
import 'dart:io';

import 'package:artisanal/args.dart';
import 'package:ormed/ormed.dart';
import 'package:ormed_cli/src/commands/base/shared.dart';
import 'package:ormed_cli/src/commands/migrate/migrate_command.dart';
import 'package:ormed_cli/src/commands/migrate/status_command.dart';
import 'package:ormed_cli/src/commands/migrate/rollback_command.dart';
import 'package:ormed_cli/src/commands/schema/schema_command.dart';
import 'package:ormed_cli/src/commands/db/seed_command.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'models/cli_user.dart';

// Test pair class
class TestMigrationEntry {
  final MigrationId id;
  final Migration migration;
  TestMigrationEntry(this.id, this.migration);
}

// Test implementation of MigrationLoader
class TestMigrationRegistryLoader implements MigrationRegistryLoader {
  List<TestMigrationEntry> entries = [];

  @override
  Future<List<MigrationDescriptor>> load(
    Directory root,
    OrmProjectConfig config, {
    String? registryPath,
  }) async {
    return entries
        .map(
          (e) => MigrationDescriptor.fromMigration(
            id: e.id,
            migration: e.migration,
          ),
        )
        .toList();
  }

  @override
  Future<SchemaPlan> buildPlan({
    required Directory root,
    required OrmProjectConfig config,
    required MigrationId id,
    required MigrationDirection direction,
    required SchemaSnapshot snapshot,
    String? registryPath,
  }) async {
    final entry = entries.firstWhere((e) => e.id == id);
    return entry.migration.plan(direction, snapshot: snapshot);
  }
}

// Test implementation of SeederRunner
class TestProjectSeederRunner implements ProjectSeederRunner {
  List<String> executedSeeders = [];
  String? receivedConnection;

  @override
  Future<void> run({
    required OrmProjectContext project,
    required OrmProjectConfig config,
    required SeedSection seeds,
    List<String>? overrideClasses,
    bool pretend = false,
    String? databaseOverride,
    String? connection,
  }) async {
    receivedConnection = connection ?? config.connectionName;
    final targetSeeders = (overrideClasses == null || overrideClasses.isEmpty)
        ? (seeds.seedNames.isNotEmpty
              ? seeds.seedNames
              : const ['AppDatabaseSeeder'])
        : overrideClasses;
    executedSeeders.addAll(targetSeeders);
    final handle = await createConnection(project.root, config);
    try {
      if (targetSeeders.contains('AppDatabaseSeeder')) {
        await handle.use((conn) async {
          _registerCliModels(conn);
          final logFile = File(p.join(project.root.path, 'seed.log'));
          logFile.writeAsStringSync(
            'AppDatabaseSeeder\n',
            mode: FileMode.append,
          );
        });
      }
    } finally {
      await handle.dispose();
    }
  }
}

void main() {
  group('integration tests (in-process)', () {
    late Directory repoRoot;
    late Directory scratchDir;
    late String dbPath;
    late File ormConfig;
    late CommandRunner runner;
    late TestMigrationRegistryLoader testMigrationLoader;
    late TestProjectSeederRunner testSeederRunner;

    setUp(() async {
      repoRoot = Directory.current;

      final scratchParent = Directory(
        p.join(repoRoot.path, '.dart_tool', 'ormed_cli_tests'),
      );
      if (!scratchParent.existsSync()) {
        scratchParent.createSync(recursive: true);
      }
      scratchDir = Directory(
        p.join(
          scratchParent.path,
          'case_${DateTime.now().microsecondsSinceEpoch}',
        ),
      )..createSync(recursive: true);

      dbPath = p.join(scratchDir.path, 'test.sqlite');

      ormConfig = File(p.join(scratchDir.path, 'ormed.yaml'))
        ..writeAsStringSync(
          _ormYaml(
            databasePath: p.relative(dbPath, from: scratchDir.path),
            migrationsDir: 'migrations',
            registryPath: 'migrations.dart',
            seedsDir: 'seeds',
            seedsRegistry: 'seeders.dart',
          ),
        );

      File(p.join(scratchDir.path, 'pubspec.yaml')).writeAsStringSync('''
name: test_project
environment:
  sdk: ">=3.0.0 <4.0.0"
dependencies:
  ormed: any
  ormed_sqlite: any
dev_dependencies:
  ormed_cli: any
  build_runner: any
''');

      testMigrationLoader = TestMigrationRegistryLoader();
      testMigrationLoader.entries = [
        TestMigrationEntry(
          MigrationId.parse('2024_01_01_000000_create_users_table'),
          const CreateUsersTable(),
        ),
      ];
      migrationRegistryLoader = testMigrationLoader;

      testSeederRunner = TestProjectSeederRunner();
      projectSeederRunner = testSeederRunner;

      runner = CommandRunner('ormed', 'ORM CLI')
        ..addCommand(ApplyCommand())
        ..addCommand(StatusCommand())
        ..addCommand(RollbackCommand())
        ..addCommand(
          SchemaDumpCommand(),
        ) // Add commands directly matching bin/orm.dart
        ..addCommand(SchemaDescribeCommand())
        ..addCommand(SeedCommand());
    });

    tearDown(() async {
      final manager = ConnectionManager.instance;
      for (final name in manager.registeredConnectionNames) {
        await manager.unregister(name);
      }

      if (ormConfig.existsSync()) {
        ormConfig.deleteSync();
      }
      if (scratchDir.existsSync()) {
        scratchDir.deleteSync(recursive: true);
      }
      final dbFile = File(dbPath);
      if (dbFile.existsSync()) {
        dbFile.deleteSync();
      }
    });

    Future<void> runOrm(List<String> args) async {
      await runner.run([
        ...args,
        '--config',
        p.relative(ormConfig.path, from: Directory.current.path),
      ]);
    }

    test('migrate, migrate:status, migrate:rollback end-to-end', () async {
      await runOrm(['migrate']);
      await _expectTableExists(scratchDir, ormConfig, 'users');

      await runOrm(['migrate:status']);

      await runOrm(['migrate:rollback']);
      await _expectTableAbsent(scratchDir, ormConfig, 'users');
    });

    test('seed command execution', () async {
      await runOrm(['seed']);
      expect(testSeederRunner.executedSeeders, contains('AppDatabaseSeeder'));

      final logFile = File(p.join(scratchDir.path, 'seed.log'));
      expect(logFile.existsSync(), isTrue);
      expect(logFile.readAsStringSync(), contains('AppDatabaseSeeder'));
      expect(testSeederRunner.receivedConnection, isNotNull);
    });

    test('seed command accepts --connection override', () async {
      await runOrm(['seed', '--connection', 'default']);
      expect(testSeederRunner.receivedConnection, 'default');
    });

    test('migrate --seed executes seeder', () async {
      await runOrm(['migrate', '--seed']);
      expect(testSeederRunner.executedSeeders, contains('AppDatabaseSeeder'));
    });

    test('migrate --pretend', () async {
      await runOrm(['migrate', '--pretend']);
      await _expectTableAbsent(scratchDir, ormConfig, 'users');
    });
  });
}

// ... HELPERS ...

String _ormYaml({
  required String databasePath,
  required String migrationsDir,
  required String registryPath,
  required String seedsDir,
  required String seedsRegistry,
  String schemaDumpPath = 'database/schema.sql',
}) =>
    '''
driver:
  type: sqlite
  options:
    database: $databasePath
migrations:
  directory: $migrationsDir
  registry: $registryPath
  schema_dump: $schemaDumpPath
  ledger_table: orm_migrations
seeds:
  directory: $seedsDir
  registry: $seedsRegistry
''';

Future<void> _expectTableExists(
  Directory rootDir,
  File ormConfig,
  String table,
) async {
  final config = loadOrmProjectConfig(ormConfig);
  final handle = await createConnection(rootDir, config);
  try {
    await handle.use((connection) async {
      final driver = connection.driver;
      if (driver is SchemaDriver) {
        final snapshot = await SchemaSnapshot.capture(driver as SchemaDriver);
        final exists = snapshot.tables.any((t) => t.name == table);
        expect(exists, isTrue, reason: 'Expected table $table to exist.');
      }
    });
  } finally {
    await handle.dispose();
  }
}

Future<void> _expectTableAbsent(
  Directory rootDir,
  File ormConfig,
  String table,
) async {
  final config = loadOrmProjectConfig(ormConfig);
  final handle = await createConnection(rootDir, config);
  try {
    await handle.use((connection) async {
      final driver = connection.driver;
      if (driver is SchemaDriver) {
        final snapshot = await SchemaSnapshot.capture(driver as SchemaDriver);
        final exists = snapshot.tables.any((t) => t.name == table);
        expect(exists, isFalse, reason: 'Expected table $table to be dropped.');
      }
    });
  } finally {
    await handle.dispose();
  }
}

void _registerCliModels(OrmConnection connection) {
  connection.context.registry.register(CliUserOrmDefinition.definition);
}

// ... MIGRATION CLASS ...
class CreateUsersTable extends Migration {
  const CreateUsersTable();

  @override
  void up(SchemaBuilder schema) {
    schema.create('users', (table) {
      table.increments('id');
      table.string('email');
      table.boolean('active').defaultValue(true);
    });
  }

  @override
  void down(SchemaBuilder schema) {
    schema.drop('users', ifExists: true);
  }
}
