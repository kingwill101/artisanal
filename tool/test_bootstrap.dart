import 'dart:io';
import 'package:path/path.dart' as p;

final testDir = 'orm_bootstrap_test';
final ormedRoot = Directory.current.path;

Future<void> main(List<String> args) async {
  final options = BootstrapOptions.fromArgs(args);
  print('--- Starting Bootstrap E2E Test (Dart) ---');

  try {
    await cleanup();
    await createProject();
    await addDependencies();
    await initOrm(options);
    await verifyAnalyzerConfig();
    if (options.multiDatasource) {
      await configureMultipleDatasources();
    }
    await createModel();
    await runBuildRunner();
    await createDartMigration();
    await createSqlMigration();
    await runMigrations();
    await createSeeder();
    await runSeeders();
    await analyzeProject();
    await verifyFiles();
    await runVerificationScript(options);

    print('\n[SUCCESS] All bootstrap tests passed!');
  } catch (e, st) {
    print('\n[FAILURE] Test failed: $e');
    print(st);
    exit(1);
  }
}

class BootstrapOptions {
  const BootstrapOptions({
    required this.multiDatasource,
    required this.verifyInitOnly,
  });

  final bool multiDatasource;
  final bool verifyInitOnly;

  factory BootstrapOptions.fromArgs(List<String> args) {
    var multiDatasource = false;
    var verifyInitOnly = false;

    for (final arg in args) {
      switch (arg) {
        case '--multi-datasource':
          multiDatasource = true;
          break;
        case '--verify-init-only':
          verifyInitOnly = true;
          break;
        case '--help':
        case '-h':
          _printUsage();
          exit(0);
      }
    }

    return BootstrapOptions(
      multiDatasource: multiDatasource,
      verifyInitOnly: verifyInitOnly,
    );
  }
}

void _printUsage() {
  print('Usage: dart tool/test_bootstrap.dart [options]');
  print('');
  print('Options:');
  print('  --multi-datasource   Configure and verify multiple datasources');
  print('  --verify-init-only   Validate init --only behavior');
  print('  -h, --help           Show this help message');
}

Future<void> cleanup() async {
  print('Cleaning up old test directory...');
  final dir = Directory(testDir);
  if (dir.existsSync()) {
    dir.deleteSync(recursive: true);
  }
}

Future<void> createProject() async {
  print('Creating new Dart app...');
  await run('dart', ['create', '-t', 'console', testDir]);
}

Future<void> addDependencies() async {
  print('Adding dependencies and overrides...');
  final pubspecFile = File(p.join(testDir, 'pubspec.yaml'));
  var content = pubspecFile.readAsStringSync();

  final overrides =
      '''
dependency_overrides:
  ormed: { path: "$ormedRoot/packages/ormed" }
  ormed_sqlite: { path: "$ormedRoot/packages/ormed_sqlite" }
  ormed_cli: { path: "$ormedRoot/packages/ormed_cli" }
  artisanal: { path: "$ormedRoot/packages/artisanal" }
  ormed_postgres: { path: "$ormedRoot/packages/ormed_postgres" }
  ormed_mysql: { path: "$ormedRoot/packages/ormed_mysql" }
''';

  pubspecFile.writeAsStringSync('$content\n$overrides');

  await run('dart', [
    'pub',
    'add',
    'ormed',
    'ormed_sqlite',
    'ormed_cli',
  ], workingDirectory: testDir);
  await run('dart', [
    'pub',
    'add',
    '--dev',
    'build_runner',
  ], workingDirectory: testDir);
}

Future<void> initOrm(BootstrapOptions options) async {
  print('Initializing ORM...');
  if (options.verifyInitOnly) {
    await run('dart', [
      'run',
      'ormed_cli:ormed',
      'init',
      '--no-interaction',
      '--only=config',
      '--only=datasource',
      '--with-analyzer',
    ], workingDirectory: testDir);
    await verifyInitOnlyArtifacts();
    await run('dart', [
      'run',
      'ormed_cli:ormed',
      'init',
      '--no-interaction',
      '--force',
      '--with-analyzer',
    ], workingDirectory: testDir);
    return;
  }

  await run('dart', [
    'run',
    'ormed_cli:ormed',
    'init',
    '--no-interaction',
    '--with-analyzer',
  ], workingDirectory: testDir);
}

Future<void> verifyInitOnlyArtifacts() async {
  print('Verifying init --only artifacts...');
  final ormYaml = File(p.join(testDir, 'ormed.yaml'));
  final datasourceFile = File(
    p.join(testDir, 'lib/src/database/datasource.dart'),
  );
  if (!ormYaml.existsSync()) {
    throw Exception('Expected ormed.yaml to be created by init --only');
  }
  if (!datasourceFile.existsSync()) {
    throw Exception('Expected datasource.dart to be created by init --only');
  }

  final migrationsReg = File(
    p.join(testDir, 'lib/src/database/migrations.dart'),
  );
  final seedersReg = File(p.join(testDir, 'lib/src/database/seeders.dart'));
  if (migrationsReg.existsSync() || seedersReg.existsSync()) {
    throw Exception(
      'init --only should not scaffold migrations/seeders registry files',
    );
  }
}

Future<void> configureMultipleDatasources() async {
  print('Configuring multiple datasources...');
  final configFile = File(p.join(testDir, 'ormed.yaml'));
  if (!configFile.existsSync()) {
    throw Exception('ormed.yaml not found for multi-datasource config');
  }

  final primaryDb = 'database/$testDir.sqlite';
  final analyticsDb = 'database/${testDir}_analytics.sqlite';
  configFile.writeAsStringSync('''
default_connection: primary
connections:
  primary:
    driver:
      type: sqlite
      options:
        database: $primaryDb
    migrations:
      directory: lib/src/database/migrations
      registry: lib/src/database/migrations.dart
      ledger_table: orm_migrations
      schema_dump: database/schema.sql
    seeds:
      directory: lib/src/database/seeders
      registry: lib/src/database/seeders.dart
  analytics:
    driver:
      type: sqlite
      options:
        database: $analyticsDb
    migrations:
      directory: lib/src/database/migrations
      registry: lib/src/database/migrations.dart
      ledger_table: orm_migrations
      schema_dump: database/schema.sql
    seeds:
      directory: lib/src/database/seeders
      registry: lib/src/database/seeders.dart
''');
}

Future<void> createModel() async {
  print('Creating a model...');
  await run('dart', [
    'run',
    'ormed_cli:ormed',
    'make:model',
    'User',
    '--table',
    'users',
  ], workingDirectory: testDir);

  final modelFile = File(p.join(testDir, 'lib/src/database/models/user.dart'));
  modelFile.writeAsStringSync('''
import 'package:ormed/ormed.dart';

part 'user.orm.dart';

@OrmModel(table: 'users')
class User extends Model<User> {
  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.emailAddress,
    this.bio,
  });

  @OrmField(isPrimaryKey: true, autoIncrement: true)
  final int id;

  final String name;
  final String email;
  final String emailAddress;
  final String? bio;
}
''');
}

Future<void> runBuildRunner() async {
  print('Running build_runner...');
  await run('dart', [
    'run',
    'build_runner',
    'build',
    '--delete-conflicting-outputs',
  ], workingDirectory: testDir);
}

Future<void> createDartMigration() async {
  print('Creating a Dart migration...');
  await run('dart', [
    'run',
    'ormed_cli:ormed',
    'make',
    '--name',
    'create_users_table',
    '--create',
    '--table',
    'users',
  ], workingDirectory: testDir);

  // Add columns to the migration
  final migrationsDir = Directory(
    p.join(testDir, 'lib/src/database/migrations'),
  );
  final migrationFile = migrationsDir.listSync().whereType<File>().firstWhere(
    (f) => f.path.contains('create_users_table'),
  );

  var content = migrationFile.readAsStringSync();
  content = content.replaceFirst(
    'table.timestamps();',
    "table.string('name');\n      table.string('email');\n      table.string('email_address');\n      table.timestamps();",
  );
  migrationFile.writeAsStringSync(content);
}

Future<void> createSqlMigration() async {
  print('Creating a SQL migration...');
  await run('dart', [
    'run',
    'ormed_cli:ormed',
    'make',
    '--name',
    'add_bio_to_users',
    '--format',
    'sql',
  ], workingDirectory: testDir);

  final migrationsDir = Directory(
    p.join(testDir, 'lib/src/database/migrations'),
  );
  final sqlDir = migrationsDir.listSync().whereType<Directory>().firstWhere(
    (d) => d.path.contains('add_bio_to_users'),
  );

  final upSql = File(p.join(sqlDir.path, 'up.sql'));
  final downSql = File(p.join(sqlDir.path, 'down.sql'));

  upSql.writeAsStringSync('ALTER TABLE users ADD COLUMN bio TEXT;');
  downSql.writeAsStringSync('ALTER TABLE users DROP COLUMN bio;');
}

Future<void> runMigrations() async {
  print('Running migrations...');
  await run('dart', [
    'run',
    'ormed_cli:ormed',
    'migrate',
  ], workingDirectory: testDir);
}

Future<void> createSeeder() async {
  print('Creating a seeder...');
  await run('dart', [
    'run',
    'ormed_cli:ormed',
    'make',
    '--name',
    'UserSeeder',
    '--seeder',
  ], workingDirectory: testDir);

  final seederFile = File(
    p.join(testDir, 'lib/src/database/seeders/user_seeder.dart'),
  );
  seederFile.writeAsStringSync('''
import 'package:ormed/ormed.dart';
import 'package:orm_bootstrap_test/src/database/models/user.dart';

class UserSeeder extends DatabaseSeeder {
  UserSeeder(super.connection);

  @override
  Future<void> run() async {
    await seed<User>([
      {
        'name': 'Test User',
        'email': 'test@example.com',
        'emailAddress': 'camel@example.com',
        'bio': 'Hello from SQL migration!'
      },
    ]);
  }
}
''');

  final dbSeederFile = File(
    p.join(testDir, 'lib/src/database/seeders/database_seeder.dart'),
  );
  dbSeederFile.writeAsStringSync('''
import 'package:ormed/ormed.dart';
import 'user_seeder.dart';

class AppDatabaseSeeder extends DatabaseSeeder {
  AppDatabaseSeeder(super.connection);

  @override
  Future<void> run() async {
    await call([UserSeeder.new]);
  }
}
''');
}

Future<void> runSeeders() async {
  print('Running seeders...');
  await run('dart', [
    'run',
    'ormed_cli:ormed',
    'seed',
  ], workingDirectory: testDir);
}

Future<void> analyzeProject() async {
  print('Analyzing project...');
  await run('dart', ['analyze'], workingDirectory: testDir);
}

Future<void> verifyFiles() async {
  print('Verifying generated files...');
  final files = [
    'lib/src/database/models/user.orm.dart',
    'lib/orm_registry.g.dart',
    'database/$testDir.sqlite',
  ];

  for (final f in files) {
    final file = File(p.join(testDir, f));
    if (!file.existsSync()) {
      throw Exception('Required file missing: \$f');
    }
  }
}

Future<void> verifyAnalyzerConfig() async {
  print('Verifying analyzer plugin config...');
  final options = File(p.join(testDir, 'analysis_options.yaml'));
  if (!options.existsSync()) {
    throw Exception('analysis_options.yaml was not created.');
  }
  final text = options.readAsStringSync();
  if (!text.contains('- ormed')) {
    throw Exception(
      'analysis_options.yaml is missing the Ormed analyzer plugin.',
    );
  }
}

Future<void> runVerificationScript(BootstrapOptions options) async {
  print('Creating and running verification script...');
  final verifyFile = File(p.join(testDir, 'bin/verify_orm.dart'));
  final multiDatasource = options.multiDatasource;
  final analyticsDb = 'database/${testDir}_analytics.sqlite';
  verifyFile.writeAsStringSync('''
import 'dart:io';
import 'package:ormed/ormed.dart';
import 'package:ormed_sqlite/ormed_sqlite.dart';
import 'package:orm_bootstrap_test/src/database/models/user.dart';
import 'package:orm_bootstrap_test/orm_registry.g.dart';

void main() async {
  print('Bootstrapping ORM...');
  final registry = bootstrapOrm();
  
  final userDef = registry.expect<User>();
  print('Model Name: \${userDef.modelName}');
  print('Table Name: \${userDef.tableName}');
  
  if (userDef.tableName != 'users') {
    print('Error: Table name should be "users"');
    exit(1);
  }

  print('Verifying database content...');
  ${multiDatasource ? "ensureSqliteDriverRegistration();" : ""}
  ${multiDatasource ? "final config = loadOrmConfig();" : ""}
  ${multiDatasource ? "final sources = <String, DataSource>{};" : ""}
  ${multiDatasource ? "for (final name in config.connections.keys) {" : ""}
  ${multiDatasource ? "  final ds = DataSource.fromConfig(config.withConnection(name), registry: registry);" : ""}
  ${multiDatasource ? "  await ds.init();" : ""}
  ${multiDatasource ? "  sources[name] = ds;" : ""}
  ${multiDatasource ? "}" : ""}
  ${multiDatasource ? "if (sources.length < 2) {" : ""}
  ${multiDatasource ? "  print('Error: Expected multiple datasources to be configured.');" : ""}
  ${multiDatasource ? "  exit(1);" : ""}
  ${multiDatasource ? "}" : ""}
  ${multiDatasource ? "final primary = sources[config.activeConnectionName] ?? sources.values.first;" : ""}
  ${multiDatasource ? "final analytics = sources['analytics'];" : ""}
  ${multiDatasource ? "if (analytics != null) {" : ""}
  ${multiDatasource ? "  await analytics.connection.driver.executeRaw('SELECT 1');" : ""}
  ${multiDatasource ? "}" : ""}
  ${multiDatasource ? "final connection = primary.connection;" : "final ds = DataSource(DataSourceOptions(driver: SqliteDriverAdapter.file('database/orm_bootstrap_test.sqlite'), registry: registry,)); await ds.init(); final connection = ds.connection;"}
  final users = await connection.table('users').get();
  
  print('Found \${users.length} users');
  if (users.isEmpty) {
    print('Error: No users found in database.');
    exit(1);
  }

  final user = users.first;
  print('First User: \${user['name']} (\${user['email']})');
  print('Email Address (snake_case): \${user['email_address']}');
  print('Bio: \${user['bio']}');
  
  if (user['name'] != 'Test User') {
    print('Error: Unexpected user name: \${user['name']}');
    exit(1);
  }

  if (user['email_address'] != 'camel@example.com') {
    print('Error: camelCase field "emailAddress" did not map to "email_address" or value is wrong: \${user['email_address']}');
    exit(1);
  }

  if (user['bio'] != 'Hello from SQL migration!') {
    print('Error: SQL migration column "bio" not populated correctly');
    exit(1);
  }

  ${multiDatasource ? "final analyticsFile = File('$analyticsDb');" : ""}
  ${multiDatasource ? "if (!analyticsFile.existsSync()) {" : ""}
  ${multiDatasource ? "  print('Error: Analytics database was not created.');" : ""}
  ${multiDatasource ? "  exit(1);" : ""}
  ${multiDatasource ? "}" : ""}
  ${multiDatasource ? "for (final source in sources.values) { await source.dispose(); }" : "await ds.dispose();"}
  print('Success: Bootstrap verification passed!');
}
''');

  await run('dart', ['run', 'bin/verify_orm.dart'], workingDirectory: testDir);
}

Future<void> run(
  String command,
  List<String> args, {
  String? workingDirectory,
}) async {
  final process = await Process.start(
    command,
    args,
    workingDirectory: workingDirectory,
    mode: ProcessStartMode.inheritStdio,
  );

  final exitCode = await process.exitCode;
  if (exitCode != 0) {
    throw Exception(
      'Command $command ${args.join(' ')} exited with code $exitCode',
    );
  }
}
