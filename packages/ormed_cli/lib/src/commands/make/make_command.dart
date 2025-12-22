import 'dart:io';

import 'package:args/command_runner.dart' show UsageException;
import 'package:artisanal/args.dart';
import 'package:path/path.dart' as p;

import '../../config.dart';
import '../base/shared.dart';

class MakeCommand extends Command<void> {
  MakeCommand() {
    argParser
      ..addOption('name', abbr: 'n', help: 'Slug for the migration/seeder.')
      ..addOption(
        'format',
        help:
            'Migration authoring format (dart|sql). Defaults from ormed.yaml.',
        allowed: const ['dart', 'sql'],
      )
      ..addOption(
        'table',
        help:
            'Table to modify or create (defaults to guesses when --create is used).',
      )
      ..addFlag(
        'create',
        negatable: false,
        help:
            'Indicates the migration will create a table (guesses name from slug).',
      )
      ..addOption(
        'path',
        help:
            'Override the migrations directory (relative to project root unless --realpath is set).',
      )
      ..addFlag(
        'realpath',
        negatable: false,
        help: 'Treat --path as an absolute file system path.',
      )
      ..addFlag(
        'fullpath',
        negatable: false,
        help:
            'Print the created migration file full path instead of relative path.',
      )
      ..addFlag(
        'seeder',
        negatable: false,
        help: 'Generate a seeder instead of a migration.',
      )
      ..addOption(
        'config',
        abbr: 'c',
        help: 'Path to ormed.yaml (defaults to project root).',
      );
  }

  @override
  String get name => 'make';

  @override
  String get description => 'Create a new migration file and register it.';

  @override
  Future<void> run() async {
    // Interactively ask for name if not provided
    var slug = (argResults?['name'] as String?)?.trim();
    if (slug == null || slug.isEmpty) {
      slug = io.ask(
        'What is the name of the migration/seeder?',
        validator: (value) {
          if (value.trim().isEmpty) return 'Name cannot be empty.';
          return null;
        },
      );
    }

    // Determine type (seeder or migration)
    var shouldCreateSeeder = argResults?['seeder'] == true;

    // If user provided no type flags and we're interactive, maybe ask?
    // Actually standard behavior is migration unless --seeder specified.
    // However, if the name ends in 'Seeder', we could guess?
    if (!shouldCreateSeeder && slug.toLowerCase().endsWith('seeder')) {
      if (io.confirm(
        'The name ends in "Seeder". Do you want to create a seeder?',
        defaultValue: true,
      )) {
        shouldCreateSeeder = true;
      }
    }

    final tableOption = (argResults?['table'] as String?)?.trim();
    final createFlag = argResults?['create'] == true;
    final formatOption = (argResults?['format'] as String?)?.trim();

    // If not a seeder, and we didn't specify table/create, ask intent
    // Or just rely on reasonable defaults (guess table from slug).

    final configArg = argResults?['config'] as String?;
    final context = resolveOrmProject(configPath: configArg);
    final root = context.root;
    final config = loadOrmProjectConfig(context.configFile);
    final migrationsDir = Directory(
      _resolveDirectory(
        root: root,
        overridePath: argResults?['path'] as String?,
        defaultPath: config.migrations.directory,
        useRealPath: argResults?['realpath'] == true,
      ),
    );

    if (!migrationsDir.existsSync()) {
      migrationsDir.createSync(recursive: true);
    }

    if (shouldCreateSeeder) {
      _createSeeder(slug: slug, root: root, config: config, usage: usage);
      return;
    }

    final migrationFormat = _resolveMigrationFormat(
      formatOption,
      config.migrations.format,
      usage: usage,
    );
    final tableName =
        tableOption ?? (createFlag ? _guessTableFromSlug(slug) : null);
    if (createFlag && tableName == null) {
      io.note(
        'Hint: add --table=<name> so the generated migration can scaffold columns for the right table.',
      );
    }

    _createMigration(
      root: root,
      slug: slug,
      migrationsDir: migrationsDir,
      config: config,
      tableName: tableName,
      createTable: createFlag,
      fullPath: argResults?['fullpath'] == true,
      format: migrationFormat,
      usage: usage,
    );
  }
}

/// Format timestamp as m_YYYYMMDDHHMMSS (new Dart-compliant format)
String _formatTimestamp(DateTime value) {
  final year = value.year.toString().padLeft(4, '0');
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  final second = value.second.toString().padLeft(2, '0');
  return 'm_$year$month$day$hour$minute$second';
}

String _toPascalCase(String slug) {
  return slug
      .split(RegExp('[-_ ]+'))
      .where((segment) => segment.isNotEmpty)
      .map(
        (segment) =>
            segment.substring(0, 1).toUpperCase() + segment.substring(1),
      )
      .join();
}

String _migrationFileTemplate(
  String className, {
  String? tableName,
  bool createTable = false,
}) {
  var up = '';
  var down = '';
  if (tableName != null) {
    if (createTable) {
      up =
          """
    schema.create('$tableName', (table) {
      table.id();
      table.timestamps();
    });""";
      down = "    schema.drop('$tableName');";
    } else {
      up =
          """
    schema.table('$tableName', (table) {
      //
    });""";
    }
  }

  return '''
import 'package:ormed/migrations.dart';

class $className extends Migration {
  const $className();

  @override
  void up(SchemaBuilder schema) {
$up
  }

  @override
  void down(SchemaBuilder schema) {
$down
  }
}
''';
}

String _seederFileTemplate(String className, String packageName) =>
    '''
import 'package:ormed/ormed.dart';
import 'package:$packageName/orm_registry.g.dart';

class $className extends DatabaseSeeder {
  $className(super.connection);

  @override
  Future<void> run() async {
    // TODO: add seed logic here
    // Examples:
    // await seed<User>([
    //   {'name': 'John Doe', 'email': 'john@example.com'},
    //   {'name': 'Jane Smith', 'email': 'jane@example.com'},
    // ]);
    //
    // Or use call() to run other seeders:
    // await call([UserSeeder.new, PostSeeder.new]);
  }
}
''';

String _toSnakeCase(String slug) => slug
    .trim()
    .replaceAllMapped(
      RegExp(r'([a-z0-9])([A-Z])'),
      (match) => '${match.group(1)}_${match.group(2)}',
    )
    .replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_')
    .replaceAll(RegExp(r'_+'), '_')
    .replaceAll(RegExp(r'^_+|_+$'), '')
    .toLowerCase();

String _resolveDirectory({
  required Directory root,
  required String defaultPath,
  String? overridePath,
  required bool useRealPath,
}) {
  final candidate = overridePath ?? defaultPath;
  if (useRealPath || p.isAbsolute(candidate)) {
    return p.normalize(candidate);
  }
  return resolvePath(root, candidate);
}

String? _guessTableFromSlug(String slug) {
  final match = RegExp(r'^create_(.+)_table$').firstMatch(slug);
  if (match != null) {
    return match.group(1);
  }
  final fallback = RegExp(r'^create_(.+)$').firstMatch(slug);
  return fallback?.group(1);
}

void _createSeeder({
  required String slug,
  required Directory root,
  required OrmProjectConfig config,
  required String usage,
}) {
  final seeds = config.seeds;
  if (seeds == null) {
    throw UsageException(
      'ormed.yaml missing seeds configuration. Update ormed.yaml to include a seeds block.',
      usage,
    );
  }

  final seedersDir = Directory(resolvePath(root, seeds.directory));
  if (!seedersDir.existsSync()) {
    seedersDir.createSync(recursive: true);
  }

  final snake = _toSnakeCase(slug);
  final className = _toPascalCase(slug);
  final file = File(p.join(seedersDir.path, '$snake.dart'));
  if (file.existsSync()) {
    throw UsageException('Seeder file ${file.path} already exists.', usage);
  }
  final packageName = getPackageName(root);
  file.writeAsStringSync(_seederFileTemplate(className, packageName));
  cliIO.success('Created seeder');
  cliIO.components.horizontalTable({
    'File': p.relative(file.path, from: root.path),
    'Class': className,
  });

  final registryPath = resolvePath(root, seeds.registry);
  final registry = File(registryPath);
  if (!registry.existsSync()) {
    throw StateError(
      'Seeder registry $registryPath not found. Run `ormed init`.',
    );
  }
  var content = registry.readAsStringSync();

  // Calculate relative import path from registry to seeder file
  final registryDir = p.dirname(registryPath);
  final relativeImportPath = p
      .relative(file.path, from: registryDir)
      .replaceAll(r'\', '/'); // Normalize for Dart imports

  final importLine = "import '$relativeImportPath';";
  if (!content.contains(importLine)) {
    content = insertBetweenMarkers(
      content,
      seedImportsMarkerStart,
      seedImportsMarkerEnd,
      importLine,
      indent: '',
    );
  }
  final entry =
      '''  SeederRegistration(
    name: '$className',
    factory: $className.new,
  ),''';
  if (!content.contains("name: '$className'")) {
    content = insertBetweenMarkers(
      content,
      seedRegistryMarkerStart,
      seedRegistryMarkerEnd,
      entry,
      indent: '',
    );
  }
  registry.writeAsStringSync(content);
  cliIO.success('Registered seeder $className');
}

void _createMigration({
  required Directory root,
  required String slug,
  required Directory migrationsDir,
  required OrmProjectConfig config,
  String? tableName,
  required bool createTable,
  required bool fullPath,
  required MigrationFormat format,
  required String usage,
}) {
  final timestamp = _formatTimestamp(DateTime.now().toUtc());
  final migrationId = '${timestamp}_$slug';
  final className = _toPascalCase(slug);

  final conflict = migrationsDir
      .listSync()
      .map((entry) => p.basename(entry.path))
      .any((name) {
        if (name.endsWith('_$slug.dart')) return true;
        if (name.endsWith('_$slug') &&
            Directory(p.join(migrationsDir.path, name)).existsSync()) {
          return true;
        }
        return false;
      });
  if (conflict) {
    throw UsageException('Migration with slug $slug already exists.', usage);
  }

  String? createdDisplayPath;
  if (format == MigrationFormat.dart) {
    final fileName = '$migrationId.dart';
    final file = File(p.join(migrationsDir.path, fileName));
    if (file.existsSync()) {
      throw UsageException('Migration file $fileName already exists.', usage);
    }
    file.writeAsStringSync(
      _migrationFileTemplate(
        className,
        tableName: tableName,
        createTable: createTable,
      ),
    );
    createdDisplayPath = fullPath
        ? file.path
        : p.relative(file.path, from: root.path);
    cliIO.success('Created migration');
    cliIO.components.horizontalTable({
      'File': createdDisplayPath,
      'Class': className,
      if (createTable || tableName != null)
        'Table': tableName ?? 'guessing from slug',
    });
  } else {
    final dir = Directory(p.join(migrationsDir.path, migrationId));
    if (dir.existsSync()) {
      throw UsageException(
        'Migration directory $migrationId already exists.',
        usage,
      );
    }
    dir.createSync(recursive: true);
    File(p.join(dir.path, 'up.sql')).writeAsStringSync('');
    File(p.join(dir.path, 'down.sql')).writeAsStringSync('');
    createdDisplayPath = fullPath
        ? dir.path
        : p.relative(dir.path, from: root.path);
    cliIO.success('Created SQL migration');
    cliIO.components.horizontalTable({
      'Directory': createdDisplayPath,
      'Files': 'up.sql, down.sql',
      if (createTable || tableName != null)
        'Table': tableName ?? 'guessing from slug',
    });
  }

  final registryPath = resolvePath(root, config.migrations.registry);
  final registry = File(registryPath);
  if (!registry.existsSync()) {
    throw StateError(
      'Registry file $registryPath not found. Run `ormed init`.',
    );
  }
  var content = registry.readAsStringSync();

  final registryDir = p.dirname(registryPath);
  if (format == MigrationFormat.dart) {
    final filePath = p.join(migrationsDir.path, '$migrationId.dart');
    final relativeImportPath = p
        .relative(filePath, from: registryDir)
        .replaceAll(r'\', '/'); // Normalize for Dart imports

    final importLine = "import '$relativeImportPath';";
    content = insertBetweenMarkers(
      content,
      importsMarkerStart,
      importsMarkerEnd,
      importLine,
      indent: '',
    );
  }

  final entry = format == MigrationFormat.dart
      ? '''MigrationEntry(
    id: MigrationId.parse('${timestamp}_$slug'),
    migration: const $className(),
  ),'''
      : (() {
          final sqlDirPath = p.join(migrationsDir.path, migrationId);
          final relativeDir = p
              .relative(sqlDirPath, from: registryDir)
              .replaceAll(r'\', '/');
          return '''MigrationEntry(
    id: MigrationId.parse('${timestamp}_$slug'),
    migration: SqlFileMigration(
      upPath: '$relativeDir/up.sql',
      downPath: '$relativeDir/down.sql',
    ),
  ),''';
        })();

  content = insertBetweenMarkers(
    content,
    registryMarkerStart,
    registryMarkerEnd,
    entry,
    indent: '  ',
  );
  registry.writeAsStringSync(content);
  cliIO.success('Registered migration ${timestamp}_$slug');
}

MigrationFormat _resolveMigrationFormat(
  String? optionValue,
  MigrationFormat defaultFormat, {
  required String usage,
}) {
  final normalized = optionValue?.toLowerCase();
  switch (normalized) {
    case null:
    case '':
      return defaultFormat;
    case 'dart':
      return MigrationFormat.dart;
    case 'sql':
      return MigrationFormat.sql;
    default:
      throw UsageException(
        'Invalid --format "$optionValue". Expected "dart" or "sql".',
        usage,
      );
  }
}
