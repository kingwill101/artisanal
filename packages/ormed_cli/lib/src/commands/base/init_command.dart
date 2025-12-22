import 'dart:io';

import 'package:artisanal/artisanal.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import '../../config.dart';
import 'shared.dart';

class InitCommand extends Command<void> {
  InitCommand() {
    argParser
      ..addFlag(
        'force',
        abbr: 'f',
        negatable: false,
        help: 'Rebuild the scaffolding even if files already exist.',
      )
      ..addFlag(
        'paths',
        negatable: false,
        help: 'Print the canonical path for each scaffolded artifact.',
      )
      // New: populate existing migrations/seeders into registries if present
      ..addFlag(
        'populate-existing',
        abbr: 'p',
        negatable: true,
        help:
            'Scan existing migrations/seeders and populate registries accordingly.',
      )
      ..addFlag(
        'skip-build',
        negatable: false,
        hide: true,
        help: 'Skip running build_runner (for testing).',
      );
  }

  @override
  String get name => 'init';

  @override
  String get description =>
      'Initialize ormed.yaml and migration/seed registries.';

  @override
  Future<void> run() async {
    final force = argResults?['force'] == true;
    final showPaths = argResults?['paths'] == true;
    final populateExisting = argResults?['populate-existing'] == true;
    final skipBuild = argResults?['skip-build'] == true;
    final root = findProjectRoot();
    final tracker = _ArtifactTracker(root);

    // If config exists, offer re-initialize
    if (!force) {
      final configFile = File(p.join(root.path, 'ormed.yaml'));
      final legacyFile = File(p.join(root.path, 'ormed.yaml'));

      if (configFile.existsSync()) {
        cliIO.writeln(
          cliIO.style.info('Project already initialized (ormed.yaml exists).'),
        );
        if (!io.confirm('Do you want to re-initialize (overwrite files)?')) {
          if (!populateExisting) return;
        }
      } else if (legacyFile.existsSync()) {
        cliIO.writeln(cliIO.style.warning('Found legacy ormed.yaml.'));
        if (io.confirm('Do you want to rename it to ormed.yaml?')) {
          legacyFile.renameSync(configFile.path);
          cliIO.success('Renamed ormed.yaml to ormed.yaml');
        }
      }
    }

    final packageName = getPackageName(root);
    final configFile = File(p.join(root.path, 'ormed.yaml'));
    _writeFile(
      file: configFile,
      content: defaultOrmYaml(packageName),
      label: 'ormed.yaml',
      force: force,
      tracker: tracker,
      interactive: true,
    );

    // Load config
    final config = loadOrmProjectConfig(configFile);

    await _ensureDependencies(root, config: config, skipBuild: skipBuild);

    // Directories
    final migrationsDir = Directory(
      resolvePath(root, config.migrations.directory),
    );
    final hasExistingMigrations = _hasDartFiles(migrationsDir);
    _ensureDirectory(migrationsDir, 'migrations directory', tracker);

    final registry = File(resolvePath(root, config.migrations.registry));
    _writeFile(
      file: registry,
      content: initialRegistryTemplate,
      label: 'migrations registry',
      force: force,
      tracker: tracker,
      interactive: true,
    );

    final seedersDir = Directory(resolvePath(root, config.seeds!.directory));
    final hasExistingSeeders = _hasDartFiles(seedersDir);
    _ensureDirectory(seedersDir, 'seeders directory', tracker);

    final seedRegistry = File(resolvePath(root, config.seeds!.registry));
    _writeFile(
      file: seedRegistry,
      content: initialSeedRegistryTemplate.replaceAll(
        '{{package_name}}',
        packageName,
      ),
      label: 'seeders registry',
      force: force,
      tracker: tracker,
      interactive: true,
    );

    final defaultSeeder = File(p.join(seedersDir.path, 'database_seeder.dart'));
    _writeFile(
      file: defaultSeeder,
      content: _defaultSeederTemplate,
      label: 'database seeder',
      force: force,
      tracker: tracker,
      interactive: true,
    );

    final datasourceFile = File(
      p.join(root.path, 'lib', 'src', 'database', 'datasource.dart'),
    );

    final driverTypes = config.connections.values
        .map((c) => c.driver.type.toLowerCase())
        .toSet();
    final driverImports = driverTypes
        .map((type) => _driverPackageMapping[type])
        .where((pkg) => pkg != null)
        .map((pkg) => "import 'package:$pkg/$pkg.dart';")
        .join('\n');
    final driverRegistrations = driverTypes
        .map((type) => _driverRegistrationMapping[type])
        .where((fn) => fn != null)
        .map((fn) => "  $fn();")
        .join('\n');

    _writeFile(
      file: datasourceFile,
      content: _datasourceTemplate
          .replaceAll('{{package_name}}', packageName)
          .replaceAll('{{driver_imports}}', driverImports)
          .replaceAll('{{driver_registrations}}', driverRegistrations),
      label: 'DataSource entrypoint',
      force: force,
      tracker: tracker,
      interactive: true,
    );

    // Ensure schema dump parent directory exists
    final schemaDumpPath = resolvePath(root, config.migrations.schemaDump);
    final schemaDumpDir = Directory(p.dirname(schemaDumpPath));
    if (!schemaDumpDir.existsSync()) {
      schemaDumpDir.createSync(recursive: true);
      tracker.paths['schema_dir'] = schemaDumpDir.path;
    }
    final gitkeep = File(p.join(schemaDumpDir.path, '.gitkeep'));
    if (!gitkeep.existsSync()) {
      gitkeep.writeAsStringSync('');
    }

    // Populate existing artifacts into registries
    if (populateExisting) {
      await _populateExisting(
        io: cliIO,
        root: root,
        config: config,
        packageName: packageName,
        migrationsDir: migrationsDir,
        seedersDir: seedersDir,
        registryFile: registry,
        seedRegistryFile: seedRegistry,
      );
    } else {
      // If not explicitly requested, check whether dirs contain files and prompt
      if (hasExistingMigrations || hasExistingSeeders) {
        cliIO.section('Existing artifacts detected');
        if (hasExistingMigrations) {
          cliIO.writeln(
            '• Found existing migrations in ${tracker.relative(migrationsDir.path)}',
          );
        }
        if (hasExistingSeeders) {
          cliIO.writeln(
            '• Found existing seeders in ${tracker.relative(seedersDir.path)}',
          );
        }
        // When forcing scaffold recreation, do not auto-populate unless
        // explicitly requested via --populate-existing.
        final shouldPopulate = force
            ? false
            : io.confirm(
                'Do you want to populate registries from existing files?',
              );
        if (shouldPopulate) {
          await _populateExisting(
            io: cliIO,
            root: root,
            config: config,
            packageName: packageName,
            migrationsDir: migrationsDir,
            seedersDir: seedersDir,
            registryFile: registry,
            seedRegistryFile: seedRegistry,
          );
        }
      }
    }

    cliIO.newLine();
    cliIO.components.horizontalTable({
      'Ledger table': config.migrations.ledgerTable,
      'Schema dump directory': p.relative(schemaDumpDir.path, from: root.path),
    });

    if (showPaths) {
      cliIO.section('Scaffolded artifact paths');
      cliIO.components.horizontalTable(
        tracker.paths.map((k, v) => MapEntry(k, tracker.relative(v))),
      );
    }

    // Run build_runner to generate orm_registry.g.dart
    if (!skipBuild) {
      await _runBuildRunner(root);
    }

    cliIO.newLine();
    cliIO.success('Project initialized successfully.');
  }

  Future<void> _runBuildRunner(Directory root) async {
    // Check if build_runner is available by looking at pubspec.lock
    final pubspecLock = File(p.join(root.path, 'pubspec.lock'));
    if (!pubspecLock.existsSync()) {
      // No lock file means deps not installed - run pub get first
      cliIO.newLine();
      cliIO.section('Installing Dependencies');
      cliIO.writeln('Running dart pub get...');
      final pubGetResult = await Process.run('dart', [
        'pub',
        'get',
      ], workingDirectory: root.path);
      if (pubGetResult.exitCode != 0) {
        cliIO.writeln(
          cliIO.style.warning(
            'Failed to install dependencies. Run: dart pub get',
          ),
        );
        return;
      }
      cliIO.success('Dependencies installed.');
    }

    cliIO.newLine();
    cliIO.section('Code Generation');
    cliIO.writeln('Running build_runner to generate ORM registry...');

    final result = await Process.run('dart', [
      'run',
      'build_runner',
      'build',
      '--delete-conflicting-outputs',
    ], workingDirectory: root.path);

    if (result.exitCode == 0) {
      cliIO.success('Code generation completed.');
    } else {
      cliIO.writeln(
        cliIO.style.warning(
          'Code generation had issues (exit code ${result.exitCode}). '
          'You may need to run: dart run build_runner build',
        ),
      );
      if ((result.stderr as String).isNotEmpty) {
        cliIO.writeln(cliIO.style.muted(result.stderr.toString().trim()));
      }
    }
  }

  Future<void> _ensureDependencies(
    Directory root, {
    OrmProjectConfig? config,
    bool skipBuild = false,
  }) async {
    final pubspecFile = File(p.join(root.path, 'pubspec.yaml'));
    if (!pubspecFile.existsSync()) return;

    final pubspec = loadYaml(pubspecFile.readAsStringSync()) as YamlMap;
    final deps = pubspec['dependencies'] as YamlMap?;
    final devDeps = pubspec['dev_dependencies'] as YamlMap?;

    final hasOrmed = deps?.containsKey('ormed') ?? false;
    final hasOrmedCli =
        (deps?.containsKey('ormed_cli') ?? false) ||
        (devDeps?.containsKey('ormed_cli') ?? false);
    final hasBuildRunner = devDeps?.containsKey('build_runner') ?? false;

    final missingDrivers = <String>[];
    if (config != null) {
      final driverTypes = config.connections.values
          .map((c) => c.driver.type)
          .toSet();
      for (final type in driverTypes) {
        final pkg = _driverPackageMapping[type.toLowerCase()];
        if (pkg != null && !(deps?.containsKey(pkg) ?? false)) {
          missingDrivers.add(pkg);
        }
      }
    }

    if (!hasOrmed ||
        !hasOrmedCli ||
        !hasBuildRunner ||
        missingDrivers.isNotEmpty) {
      cliIO.newLine();
      cliIO.section('Dependencies');
      if (io.confirm(
        'Do you want to add missing ormed dependencies to pubspec.yaml?',
      )) {
        if (!hasOrmed) {
          cliIO.writeln('• Adding ormed to dependencies...');
          await Process.run('dart', [
            'pub',
            'add',
            'ormed',
          ], workingDirectory: root.path);
        }

        for (final pkg in missingDrivers) {
          cliIO.writeln('• Adding $pkg to dependencies...');
          await Process.run('dart', [
            'pub',
            'add',
            pkg,
          ], workingDirectory: root.path);
        }

        final devToAdd = <String>[];
        if (!hasOrmedCli) devToAdd.add('ormed_cli');
        if (!hasBuildRunner) devToAdd.add('build_runner');

        if (devToAdd.isNotEmpty) {
          cliIO.writeln(
            '• Adding ${devToAdd.join(', ')} to dev_dependencies...',
          );
          await Process.run('dart', [
            'pub',
            'add',
            '--dev',
            ...devToAdd,
          ], workingDirectory: root.path);
        }
        cliIO.success('Dependencies updated.');
      }
    }
  }
}

const String _datasourceTemplate = r'''
import 'package:ormed/ormed.dart';
import 'package:{{package_name}}/orm_registry.g.dart';
{{driver_imports}}

/// Creates a new DataSource instance using the project configuration.
DataSource createDataSource() {
{{driver_registrations}}

  final config = loadOrmConfig();
  return DataSource.fromConfig(
    config,
    registry: bootstrapOrm(),
  );
}
''';

const Map<String, String> _driverPackageMapping = {
  'sqlite': 'ormed_sqlite',
  'mysql': 'ormed_mysql',
  'mariadb': 'ormed_mysql',
  'postgres': 'ormed_postgres',
  'postgresql': 'ormed_postgres',
};

const Map<String, String> _driverRegistrationMapping = {
  'sqlite': 'ensureSqliteDriverRegistration',
  'mysql': 'ensureMySqlDriverRegistration',
  'mariadb': 'ensureMySqlDriverRegistration',
  'postgres': 'ensurePostgresDriverRegistration',
  'postgresql': 'ensurePostgresDriverRegistration',
};

const String _defaultSeederTemplate = '''
import 'package:ormed/ormed.dart';

/// Root seeder executed by `orm seed` and `orm migrate --seed`.
class AppDatabaseSeeder extends DatabaseSeeder {
  AppDatabaseSeeder(super.connection);

  @override
  Future<void> run() async {
    // TODO: add seed logic here
    // Examples:
    // await seed<User>([
    //   {'name': 'Admin User', 'email': 'admin@example.com'},
    // ]);
    //
    // Or call other seeders:
    // await call([UserSeeder.new, PostSeeder.new]);
  }
}
''';

void _writeFile({
  required File file,
  required String content,
  required String label,
  required bool force,
  required _ArtifactTracker tracker,
  bool interactive = false,
}) {
  tracker.note(label, file.path);
  file.parent.createSync(recursive: true);
  if (file.existsSync()) {
    if (force) {
      file.writeAsStringSync(content);
      cliIO.writeln(
        '${cliIO.style.foreground(Colors.warning).render('↻')} Recreated $label at ${tracker.relative(file.path)}',
      );
    } else {
      cliIO.writeln(
        '${cliIO.style.foreground(Colors.muted).render('○')} $label already exists ${cliIO.style.foreground(Colors.muted).render('(skipped)')}',
      );
    }
    return;
  }
  file.writeAsStringSync(content);
  cliIO.writeln(
    '${cliIO.style.foreground(Colors.success).render('✓')} Created $label at ${tracker.relative(file.path)}',
  );
}

void _ensureDirectory(Directory dir, String label, _ArtifactTracker tracker) {
  tracker.note(label, dir.path);
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
    cliIO.writeln(
      '${cliIO.style.foreground(Colors.success).render('✓')} Created $label at ${tracker.relative(dir.path)}',
    );
  } else {
    cliIO.writeln(
      '${cliIO.style.foreground(Colors.muted).render('○')} $label already exists',
    );
  }
}

class _ArtifactTracker {
  _ArtifactTracker(this.root);

  final Directory root;
  final Map<String, String> paths = <String, String>{};

  void note(String label, String path) {
    paths[label] = path;
  }

  String relative(String path) => p.relative(path, from: root.path);
}

// --- Helpers for populating existing migrations/seeders ---

bool _hasDartFiles(Directory dir) {
  if (!dir.existsSync()) return false;
  return dir
      .listSync(recursive: true)
      .whereType<File>()
      .any((f) => f.path.endsWith('.dart'));
}

Future<void> _populateExisting({
  required Console io,
  required Directory root,
  required OrmProjectConfig config,
  required String packageName,
  required Directory migrationsDir,
  required Directory seedersDir,
  required File registryFile,
  required File seedRegistryFile,
}) async {
  io.section('Populating registries from existing files');

  // Migrations: gather files like migrations/m_*.dart and rebuild registry
  final migrationFiles =
      migrationsDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .where((f) => f.path != registryFile.path)
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  // Seeders: gather files in seeders dir
  final seederFiles =
      seedersDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .where((f) => p.basename(f.path) != 'database_seeder.dart')
          .where((f) => f.path != seedRegistryFile.path)
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  // Build migration registry content skeleton by importing and registering
  final migrationImports = <String>[];
  final migrationEntries = <String>[];
  for (final f in migrationFiles) {
    final rel = p.relative(f.path, from: p.dirname(registryFile.path));
    final importPath = rel.replaceAll('\\', '/');
    // Guess class name from filename, keep a conservative fallback
    final base = p.basenameWithoutExtension(f.path);
    // Expected pattern: m_YYYY..._name.dart => class CreateUsersTable or similar
    // We cannot reliably infer class – we import and leave a TODO entry
    migrationImports.add("import '$importPath';");
    migrationEntries.add("  // TODO: Add entry for $base (imported above)");
  }

  final registryContent = [
    "import 'dart:convert';",
    "",
    "import 'package:ormed/migrations.dart';",
    "",
    ...migrationImports,
    "",
    "final List<MigrationEntry> _entries = [",
    ...migrationEntries,
    "];",
    "",
    "/// Build migration descriptors sorted by timestamp.",
    "List<MigrationDescriptor> buildMigrations() =>",
    "    MigrationEntry.buildDescriptors(_entries);",
    "",
    "MigrationEntry? _findEntry(String rawId) {",
    "  for (final entry in _entries) {",
    "    if (entry.id.toString() == rawId) return entry;",
    "  }",
    "  return null;",
    "}",
    "",
    "void main(List<String> args) {",
    "  if (args.contains('--dump-json')) {",
    "    final payload = buildMigrations().map((m) => m.toJson()).toList();",
    "    print(jsonEncode(payload));",
    "    return;",
    "  }",
    "",
    "  final planIndex = args.indexOf('--plan-json');",
    "  if (planIndex != -1) {",
    "    final id = args[planIndex + 1];",
    "    final entry = _findEntry(id);",
    "    if (entry == null) {",
    "      throw StateError('Unknown migration id ' + id + '.');",
    "    }",
    "    final directionName = args[args.indexOf('--direction') + 1];",
    "    final direction = MigrationDirection.values.byName(directionName);",
    "    final snapshotIndex = args.indexOf('--schema-snapshot');",
    "    SchemaSnapshot? snapshot;",
    "    if (snapshotIndex != -1) {",
    "      final decoded = utf8.decode(base64.decode(args[snapshotIndex + 1]));",
    "      final payload = jsonDecode(decoded) as Map<String, Object?>;",
    "      snapshot = SchemaSnapshot.fromJson(payload);",
    "    }",
    "    final plan = entry.migration.plan(direction, snapshot: snapshot);",
    "    print(jsonEncode(plan.toJson()));",
    "  }",
    "}",
  ].join('\n');

  if (migrationFiles.isNotEmpty) {
    registryFile.writeAsStringSync(registryContent);
    io.success(
      'Populated migrations registry with ${migrationFiles.length} imports (manual entry TODOs left).',
    );
  } else {
    io.writeln(io.style.muted('No migration files found.'));
  }

  // Build seed registry
  final seedImports = <String>[];
  final seedRegistrations = <String>[];
  for (final f in seederFiles) {
    final rel = p.relative(f.path, from: p.dirname(seedRegistryFile.path));
    final importPath = rel.replaceAll('\\', '/');
    final base = p.basenameWithoutExtension(f.path);
    seedImports.add("import '$importPath';");
    seedRegistrations.add("  // TODO: Register seeder for $base");
  }

  final seedRegistryContent = [
    "import 'package:ormed_cli/runtime.dart';",
    "import 'package:ormed/ormed.dart';",
    "import 'package:$packageName/orm_registry.g.dart' as g;",
    "",
    ...seedImports,
    "",
    "/// Registered seeders for this project.",
    "final List<SeederRegistration> seeders = <SeederRegistration>[",
    ...seedRegistrations,
    "];",
    "",
    "/// Run project seeders on the given connection.",
    "Future<void> runProjectSeeds(",
    "  OrmConnection connection, {",
    "  List<String>? names,",
    "  bool pretend = false,",
    "}) async {",
    "  g.bootstrapOrm(registry: connection.context.registry);",
    "  await SeederRunner().run(",
    "    connection: connection,",
    "    seeders: seeders,",
    "    names: names,",
    "    pretend: pretend,",
    "  );",
    "}",
    "",
    "Future<void> main(List<String> args) => runSeedRegistryEntrypoint(",
    "      args: args,",
    "      seeds: seeders,",
    "      beforeRun: (connection) =>",
    "          g.bootstrapOrm(registry: connection.context.registry),",
    "    );",
  ].join('\n');

  if (seederFiles.isNotEmpty) {
    seedRegistryFile.writeAsStringSync(seedRegistryContent);
    io.success(
      'Populated seed registry with ${seederFiles.length} imports (manual registration TODOs left).',
    );
  } else {
    io.writeln(io.style.muted('No seeder files found.'));
  }
}
