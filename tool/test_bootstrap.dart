import 'dart:io';
import 'package:path/path.dart' as p;

final testDir = 'orm_bootstrap_test';
final ormedRoot = Directory.current.path;

Future<void> main() async {
  print('--- Starting Bootstrap E2E Test (Dart) ---');

  try {
    await cleanup();
    await createProject();
    await addDependencies();
    await initOrm();
    await createModel();
    await runBuildRunner();
    await createDartMigration();
    await createSqlMigration();
    await runMigrations();
    await createSeeder();
    await runSeeders();
    await analyzeProject();
    await verifyFiles();
    await runVerificationScript();

    print('\n[SUCCESS] All bootstrap tests passed!');
  } catch (e, st) {
    print('\n[FAILURE] Test failed: $e');
    print(st);
    exit(1);
  }
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

  pubspecFile.writeAsStringSync(content + '\n' + overrides);

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

Future<void> initOrm() async {
  print('Initializing ORM...');
  await run('dart', [
    'run',
    'ormed_cli:ormed',
    'init',
    '--no-interaction',
  ], workingDirectory: testDir);
}

Future<void> createModel() async {
  print('Creating a model...');
  final modelDir = Directory(p.join(testDir, 'lib/src/models'));
  modelDir.createSync(recursive: true);

  final modelFile = File(p.join(modelDir.path, 'user.dart'));
  modelFile.writeAsStringSync('''
import 'package:ormed/ormed.dart';

part 'user.orm.dart';

@OrmModel()
class User extends Model<User> {
  final String name;
  final String email;
  final String emailAddress;
  final String? bio;

  User({required this.name, required this.email, required this.emailAddress, this.bio});
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
import 'package:orm_bootstrap_test/src/models/user.dart';

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
    'lib/src/models/user.orm.dart',
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

Future<void> runVerificationScript() async {
  print('Creating and running verification script...');
  final verifyFile = File(p.join(testDir, 'bin/verify_orm.dart'));
  verifyFile.writeAsStringSync('''
import 'dart:io';
import 'package:ormed/ormed.dart';
import 'package:ormed_sqlite/ormed_sqlite.dart';
import 'package:orm_bootstrap_test/src/models/user.dart';
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
  final ds = DataSource(DataSourceOptions(
    driver: SqliteDriverAdapter.file('database/orm_bootstrap_test.sqlite'),
    registry: registry,
  ));
  await ds.init();

  final connection = ds.connection;
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

  await ds.dispose();
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
