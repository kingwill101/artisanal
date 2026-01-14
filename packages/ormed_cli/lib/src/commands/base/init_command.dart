import 'dart:io';

import 'package:artisanal/artisanal.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import '../../config.dart';
import 'shared.dart';

class InitCommand extends Command<void> {
  /// For internal testing: allows running from a specific directory without changing CWD.
  @visibleForTesting
  Directory? workingDirectory;

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
      ..addMultiOption(
        'only',
        help:
            'Only scaffold selected artifacts (config, migrations, seeders, datasource).',
        allowed: const ['config', 'migrations', 'seeders', 'datasource'],
        allowedHelp: const {
          'config': 'ormed.yaml configuration file',
          'migrations': 'Migrations directory + registry',
          'seeders': 'Seeders directory + registry',
          'datasource': 'DataSource entrypoint',
        },
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
      )
      ..addFlag(
        'with-analyzer',
        negatable: false,
        help: 'Add the Ormed analyzer plugin to analysis_options.yaml.',
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
    final withAnalyzer = argResults?['with-analyzer'] == true;
    final onlyTargets =
        (argResults?['only'] as List<String>? ?? const <String>[])
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .toSet();
    final restrictScaffold = onlyTargets.isNotEmpty;
    final includeConfig = !restrictScaffold || onlyTargets.contains('config');
    final includeMigrations =
        !restrictScaffold || onlyTargets.contains('migrations');
    final includeSeeders = !restrictScaffold || onlyTargets.contains('seeders');
    final includeDatasource =
        !restrictScaffold || onlyTargets.contains('datasource');
    final root = findProjectRoot(workingDirectory);
    final tracker = _ArtifactTracker(root);
    final configFile = File(p.join(root.path, 'ormed.yaml'));

    if (!includeConfig && !configFile.existsSync()) {
      usageException(
        'ormed.yaml is required when using --only without config. '
        'Run `ormed init` or include --only=config.',
      );
    }

    // If config exists, offer re-initialize
    if (includeConfig && !force) {
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
    if (includeConfig) {
      _writeFile(
        file: configFile,
        content: defaultOrmYaml(packageName),
        label: 'ormed.yaml',
        force: force,
        tracker: tracker,
        interactive: true,
      );
    }

    // Load config
    final config = loadOrmProjectConfig(configFile);

    if (!skipBuild &&
        (includeDatasource || includeMigrations || includeSeeders)) {
      await _ensureDependencies(root, config: config, skipBuild: skipBuild);
    }
    if (withAnalyzer) {
      _ensureAnalyzerPluginConfig(root: root, tracker: tracker);
    }

    // Directories
    Directory? migrationsDir;
    Directory? seedersDir;
    File? registry;
    File? seedRegistry;
    Directory? schemaDumpDir;
    var hasExistingMigrations = false;
    var hasExistingSeeders = false;

    if (includeMigrations) {
      migrationsDir = Directory(resolvePath(root, config.migrations.directory));
      hasExistingMigrations = _hasDartFiles(migrationsDir);
      _ensureDirectory(migrationsDir, 'migrations directory', tracker);

      registry = File(resolvePath(root, config.migrations.registry));
      _writeFile(
        file: registry,
        content: initialRegistryTemplate,
        label: 'migrations registry',
        force: force,
        tracker: tracker,
        interactive: true,
      );

      // Ensure schema dump parent directory exists
      final schemaDumpPath = resolvePath(root, config.migrations.schemaDump);
      schemaDumpDir = Directory(p.dirname(schemaDumpPath));
      if (!schemaDumpDir.existsSync()) {
        schemaDumpDir.createSync(recursive: true);
        tracker.paths['schema_dir'] = schemaDumpDir.path;
      }
      final gitkeep = File(p.join(schemaDumpDir.path, '.gitkeep'));
      if (!gitkeep.existsSync()) {
        gitkeep.writeAsStringSync('');
      }
    }

    if (includeSeeders) {
      final seeds = config.seeds;
      if (seeds == null) {
        cliIO.warning(
          'No seeds configuration found in ormed.yaml. Skipping seed scaffolding.',
        );
      } else {
        seedersDir = Directory(resolvePath(root, seeds.directory));
        hasExistingSeeders = _hasDartFiles(seedersDir);
        _ensureDirectory(seedersDir, 'seeders directory', tracker);

        seedRegistry = File(resolvePath(root, seeds.registry));
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

        final defaultSeeder = File(
          p.join(seedersDir.path, 'database_seeder.dart'),
        );
        _writeFile(
          file: defaultSeeder,
          content: _defaultSeederTemplate,
          label: 'database seeder',
          force: force,
          tracker: tracker,
          interactive: true,
        );
      }
    }

    if (includeDatasource) {
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
    }

    // Populate existing artifacts into registries
    if (populateExisting && (includeMigrations || includeSeeders)) {
      await _populateExisting(
        io: cliIO,
        root: root,
        config: config,
        packageName: packageName,
        migrationsDir: migrationsDir,
        seedersDir: seedersDir,
        registryFile: registry,
        seedRegistryFile: seedRegistry,
        includeMigrations: includeMigrations,
        includeSeeders: includeSeeders,
      );
    } else {
      // If not explicitly requested, check whether dirs contain files and prompt
      if (hasExistingMigrations || hasExistingSeeders) {
        cliIO.section('Existing artifacts detected');
        if (hasExistingMigrations && migrationsDir != null) {
          cliIO.writeln(
            '• Found existing migrations in ${tracker.relative(migrationsDir.path)}',
          );
        }
        if (hasExistingSeeders && seedersDir != null) {
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
            includeMigrations: includeMigrations,
            includeSeeders: includeSeeders,
          );
        }
      }
    }

    cliIO.newLine();
    if (includeMigrations && schemaDumpDir != null) {
      cliIO.components.horizontalTable({
        'Ledger table': config.migrations.ledgerTable,
        'Schema dump directory': p.relative(
          schemaDumpDir.path,
          from: root.path,
        ),
      });
    }

    if (showPaths) {
      cliIO.section('Scaffolded artifact paths');
      cliIO.components.horizontalTable(
        tracker.paths.map((k, v) => MapEntry(k, tracker.relative(v))),
      );
    }

    // Run build_runner to generate orm_registry.g.dart
    final shouldBuild =
        !skipBuild &&
        (includeDatasource || includeMigrations || includeSeeders);
    if (shouldBuild) {
      await _runBuildRunner(root);
    }

    cliIO.newLine();
    cliIO.success('Project initialized successfully.');
    _printNextSteps(withAnalyzer: withAnalyzer);
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
    final overrides = pubspec['dependency_overrides'] as YamlMap?;

    bool hasPackage(String name) =>
        (deps?.containsKey(name) ?? false) ||
        (devDeps?.containsKey(name) ?? false) ||
        (overrides?.containsKey(name) ?? false);

    final hasOrmed = hasPackage('ormed');
    final hasOrmedCli = hasPackage('ormed_cli');
    final hasBuildRunner = hasPackage('build_runner');

    final missingDrivers = <String>[];
    if (config != null) {
      final driverTypes = config.connections.values
          .map((c) => c.driver.type)
          .toSet();
      for (final type in driverTypes) {
        final pkg = _driverPackageMapping[type.toLowerCase()];
        if (pkg != null && !hasPackage(pkg)) {
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

void _printNextSteps({required bool withAnalyzer}) {
  cliIO.newLine();
  cliIO.section('Next steps');
  cliIO.writeln('• Add models and include `part \'<model>.orm.dart\';`');
  cliIO.writeln('• Run: dart run build_runner build');
  if (withAnalyzer) {
    cliIO.writeln('• Restart your analyzer to pick up the Ormed plugin');
  }
}

void _ensureAnalyzerPluginConfig({
  required Directory root,
  required _ArtifactTracker tracker,
}) {
  final file = File(p.join(root.path, 'analysis_options.yaml'));
  final pluginLine = '- ormed';
  if (!file.existsSync()) {
    file.writeAsStringSync('analyzer:\n  plugins:\n    $pluginLine\n');
    tracker.paths['analysis_options.yaml'] = file.path;
    return;
  }

  final lines = file.readAsLinesSync();
  if (lines.any((line) => line.trim() == pluginLine)) {
    return;
  }

  int analyzerIndex = -1;
  for (var i = 0; i < lines.length; i++) {
    if (lines[i].trim() == 'analyzer:') {
      analyzerIndex = i;
      break;
    }
  }

  if (analyzerIndex == -1) {
    lines.add('');
    lines.add('analyzer:');
    lines.add('  plugins:');
    lines.add('    $pluginLine');
    file.writeAsStringSync(lines.join('\n'));
    return;
  }

  int pluginsIndex = -1;
  for (var i = analyzerIndex + 1; i < lines.length; i++) {
    final trimmed = lines[i].trim();
    if (trimmed.isEmpty) continue;
    if (trimmed.endsWith(':') && !trimmed.startsWith('plugins:')) {
      break;
    }
    if (trimmed == 'plugins:') {
      pluginsIndex = i;
      break;
    }
  }

  if (pluginsIndex == -1) {
    lines.insert(analyzerIndex + 1, '  plugins:');
    lines.insert(analyzerIndex + 2, '    $pluginLine');
    file.writeAsStringSync(lines.join('\n'));
    return;
  }

  lines.insert(pluginsIndex + 1, '    $pluginLine');
  file.writeAsStringSync(lines.join('\n'));
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
  required Directory? migrationsDir,
  required Directory? seedersDir,
  required File? registryFile,
  required File? seedRegistryFile,
  required bool includeMigrations,
  required bool includeSeeders,
}) async {
  io.section('Populating registries from existing files');

  if (includeMigrations) {
    final migrationsDirResolved = migrationsDir;
    final registryFileResolved = registryFile;
    if (migrationsDirResolved == null || registryFileResolved == null) {
      throw StateError('Missing migrations registry context for population.');
    }

    // Migrations: gather files like migrations/m_*.dart and rebuild registry
    final migrationFiles =
        migrationsDirResolved
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))
            .where((f) => f.path != registryFileResolved.path)
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));

    // Build migration registry content skeleton by importing and registering
    final migrationImports = <String>[];
    final migrationEntries = <String>[];
    for (final f in migrationFiles) {
      final rel = p.relative(
        f.path,
        from: p.dirname(registryFileResolved.path),
      );
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
      registryFileResolved.writeAsStringSync(registryContent);
      io.success(
        'Populated migrations registry with ${migrationFiles.length} imports (manual entry TODOs left).',
      );
    } else {
      io.writeln(io.style.muted('No migration files found.'));
    }
  }

  if (includeSeeders) {
    final seedersDirResolved = seedersDir;
    final seedRegistryFileResolved = seedRegistryFile;
    if (seedersDirResolved == null || seedRegistryFileResolved == null) {
      throw StateError('Missing seed registry context for population.');
    }

    // Seeders: gather files in seeders dir
    final seederFiles =
        seedersDirResolved
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))
            .where((f) => p.basename(f.path) != 'database_seeder.dart')
            .where((f) => f.path != seedRegistryFileResolved.path)
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));

    // Build seed registry
    final seedImports = <String>[];
    final seedRegistrations = <String>[];
    for (final f in seederFiles) {
      final rel = p.relative(
        f.path,
        from: p.dirname(seedRegistryFileResolved.path),
      );
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
      seedRegistryFileResolved.writeAsStringSync(seedRegistryContent);
      io.success(
        'Populated seed registry with ${seederFiles.length} imports (manual registration TODOs left).',
      );
    } else {
      io.writeln(io.style.muted('No seeder files found.'));
    }
  }
}
