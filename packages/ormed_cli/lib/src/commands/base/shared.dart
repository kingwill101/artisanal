import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:artisanal/artisanal.dart';
import 'package:ormed/ormed.dart';
// ignore: unused_import
import 'package:ormed_mysql/ormed_mysql.dart';
// ignore: unused_import
import 'package:ormed_postgres/ormed_postgres.dart';
import 'package:ormed_sqlite/ormed_sqlite.dart';
import 'package:path/path.dart' as p;
import 'package:meta/meta.dart';
import 'package:yaml/yaml.dart';

import '../../config.dart';

/// Interface for loading migration definitions from the project.
abstract class MigrationRegistryLoader {
  Future<List<MigrationDescriptor>> load(
    Directory root,
    OrmProjectConfig config, {
    String? registryPath,
  });

  Future<SchemaPlan> buildPlan({
    required Directory root,
    required OrmProjectConfig config,
    required MigrationId id,
    required MigrationDirection direction,
    required SchemaSnapshot snapshot,
    String? registryPath,
  });
}

/// Interface for running project seeders.
abstract class ProjectSeederRunner {
  Future<void> run({
    required OrmProjectContext project,
    required OrmProjectConfig config,
    required SeedSection seeds,
    List<String>? overrideClasses,
    bool pretend = false,
    String? databaseOverride,
    String? connection,
  });
}

class ProcessMigrationRegistryLoader implements MigrationRegistryLoader {
  const ProcessMigrationRegistryLoader();

  @override
  Future<List<MigrationDescriptor>> load(
    Directory root,
    OrmProjectConfig config, {
    String? registryPath,
  }) async {
    final path = registryPath ?? resolvePath(root, config.migrations.registry);
    final script = File(path);
    if (!script.existsSync()) {
      throw StateError('Migration registry ${script.path} not found.');
    }
    final result = await Process.run(
      'dart',
      ['run', p.relative(script.path, from: root.path), '--dump-json'],
      workingDirectory: root.path,
      runInShell: Platform.isWindows,
    );
    if (result.exitCode != 0) {
      throw StateError('Failed to load migrations:\n${result.stderr}');
    }
    final stdoutText = result.stdout as String;
    final payloadText = _extractJsonPayload(
      stdoutText,
      context: 'migration registry',
      expectArray: true,
    );
    final payload = jsonDecode(payloadText) as List;
    return payload
        .map(
          (entry) => MigrationDescriptor.fromJson(
            Map<String, Object?>.from(entry as Map),
          ),
        )
        .toList(growable: false);
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
    final path = registryPath ?? resolvePath(root, config.migrations.registry);
    final script = File(path);
    if (!script.existsSync()) {
      throw StateError('Migration registry ${script.path} not found.');
    }
    final snapshotPayload = jsonEncode(snapshot.toJson());
    final snapshotArg = base64.encode(utf8.encode(snapshotPayload));
    final result = await Process.run(
      'dart',
      [
        'run',
        p.relative(script.path, from: root.path),
        '--plan-json',
        id.toString(),
        '--direction',
        direction.name,
        '--schema-snapshot',
        snapshotArg,
      ],
      workingDirectory: root.path,
      runInShell: Platform.isWindows,
    );
    if (result.exitCode != 0) {
      throw StateError('Failed to build migration plan:\n${result.stderr}');
    }
    final stdoutText = (result.stdout as String).trim();
    if (stdoutText.isEmpty) {
      throw StateError(
        'Migration registry produced no plan output.\n${result.stderr}',
      );
    }
    final payloadText = _extractJsonPayload(
      stdoutText,
      context: 'migration plan',
      expectArray: false,
    );
    final payload = jsonDecode(payloadText) as Map<String, Object?>;
    return SchemaPlan.fromJson(payload);
  }
}

class ProcessProjectSeederRunner implements ProjectSeederRunner {
  const ProcessProjectSeederRunner();

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
    final scriptPath = resolvePath(project.root, seeds.registry);
    final script = File(scriptPath);
    if (!script.existsSync()) {
      throw StateError(
        'Seed registry ${script.path} not found. Run `ormed init`.',
      );
    }
    final relativeScript = p.relative(script.path, from: project.root.path);
    final args = <String>['run', relativeScript];
    final configPath = p.relative(
      project.configFile.path,
      from: project.root.path,
    );
    args
      ..add('--config')
      ..add(configPath);
    final targetClasses = (overrideClasses == null || overrideClasses.isEmpty)
        ? seeds.seedNames
        : overrideClasses;

    if (targetClasses.isNotEmpty) {
      for (final className in targetClasses) {
        args
          ..add('--run')
          ..add(className);
      }
    }
    if (pretend) {
      args.add('--pretend');
    }
    if (databaseOverride != null) {
      args
        ..add('--database')
        ..add(databaseOverride);
    }
    if (connection != null && connection.trim().isNotEmpty) {
      args
        ..add('--connection')
        ..add(connection);
    }

    final process = await Process.start(
      'dart',
      args,
      workingDirectory: project.root.path,
      runInShell: Platform.isWindows,
      mode: ProcessStartMode.inheritStdio,
    );
    final code = await process.exitCode;
    if (code != 0) {
      throw StateError('Seed registry exited with code $code.');
    }
  }
}

MigrationRegistryLoader migrationRegistryLoader =
    const ProcessMigrationRegistryLoader();

ProjectSeederRunner projectSeederRunner = const ProcessProjectSeederRunner();

const String importsMarkerStart = '// <ORM-MIGRATION-IMPORTS>';
const String importsMarkerEnd = '// </ORM-MIGRATION-IMPORTS>';
const String registryMarkerStart = '// <ORM-MIGRATION-REGISTRY>';
const String registryMarkerEnd = '// </ORM-MIGRATION-REGISTRY>';

const String initialRegistryTemplate =
    '''
import 'dart:convert';

import 'package:ormed/migrations.dart';

$importsMarkerStart
$importsMarkerEnd

final List<MigrationEntry> _entries = [
  $registryMarkerStart
  $registryMarkerEnd
];

/// Build migration descriptors sorted by timestamp.
List<MigrationDescriptor> buildMigrations() =>
    MigrationEntry.buildDescriptors(_entries);

MigrationEntry? _findEntry(String rawId) {
  for (final entry in _entries) {
    if (entry.id.toString() == rawId) return entry;
  }
  return null;
}

void main(List<String> args) {
  if (args.contains('--dump-json')) {
    final payload = buildMigrations().map((m) => m.toJson()).toList();
    print(jsonEncode(payload));
    return;
  }

  final planIndex = args.indexOf('--plan-json');
  if (planIndex != -1) {
    final id = args[planIndex + 1];
    final entry = _findEntry(id);
    if (entry == null) {
      throw StateError('Unknown migration id \$id.');
    }
    final directionName = args[args.indexOf('--direction') + 1];
    final direction = MigrationDirection.values.byName(directionName);
    final snapshotIndex = args.indexOf('--schema-snapshot');
    SchemaSnapshot? snapshot;
    if (snapshotIndex != -1) {
      final decoded =
          utf8.decode(base64.decode(args[snapshotIndex + 1]));
      final payload = jsonDecode(decoded) as Map<String, Object?>;
      snapshot = SchemaSnapshot.fromJson(payload);
    }
    final plan = entry.migration.plan(direction, snapshot: snapshot);
    print(jsonEncode(plan.toJson()));
    return;
  }
}
''';

/// Generate the default ormed.yaml content with the project-specific database path.
String defaultOrmYaml(String packageName) => '''
driver:
  type: sqlite
  options:
    database: database/$packageName.sqlite
migrations:
  directory: lib/src/database/migrations
  registry: lib/src/database/migrations.dart
  ledger_table: orm_migrations
  schema_dump: database/schema.sql
seeds:
  directory: lib/src/database/seeders
  registry: lib/src/database/seeders.dart
''';

const String seedImportsMarkerStart = '// <ORM-SEED-IMPORTS>';
const String seedImportsMarkerEnd = '// </ORM-SEED-IMPORTS>';
const String seedRegistryMarkerStart = '// <ORM-SEED-REGISTRY>';
const String seedRegistryMarkerEnd = '// </ORM-SEED-REGISTRY>';

const String initialSeedRegistryTemplate =
    '''
import 'package:ormed_cli/runtime.dart';
import 'package:ormed/ormed.dart';
import 'package:{{package_name}}/orm_registry.g.dart';

import 'seeders/database_seeder.dart';
$seedImportsMarkerStart
$seedImportsMarkerEnd

/// Registered seeders for this project.
/// 
/// Used by `ormed seed` command and can be imported for programmatic seeding.
final List<SeederRegistration> seeders = <SeederRegistration>[
$seedRegistryMarkerStart
  SeederRegistration(
    name: 'AppDatabaseSeeder',
    factory: (connection) => AppDatabaseSeeder(connection),
  ),
$seedRegistryMarkerEnd
];

/// Run project seeders on the given connection.
/// 
/// Example:
/// ```dart
/// await runProjectSeeds(connection);
/// await runProjectSeeds(connection, names: ['UserSeeder']);
/// ```
Future<void> runProjectSeeds(
  OrmConnection connection, {
  List<String>? names,
  bool pretend = false,
}) async {
  bootstrapOrm(registry: connection.context.registry);
  await SeederRunner().run(
    connection: connection,
    seeders: seeders,
    names: names,
    pretend: pretend,
  );
}

Future<void> main(List<String> args) => runSeedRegistryEntrypoint(
      args: args,
      seeds: seeders,
      beforeRun: (connection) =>
          bootstrapOrm(registry: connection.context.registry),
    );
''';

class OrmProjectContext {
  OrmProjectContext({required this.root, required this.configFile});

  final Directory root;
  final File configFile;
}

Directory findProjectRoot([Directory? start]) {
  var dir = start ?? Directory.current;
  while (true) {
    final pubspec = File(p.join(dir.path, 'pubspec.yaml'));
    if (pubspec.existsSync()) return dir;
    final parent = dir.parent;
    if (parent.path == dir.path) {
      throw StateError('Unable to locate pubspec.yaml.');
    }
    dir = parent;
  }
}

String getPackageName(Directory root) {
  final pubspecFile = File(p.join(root.path, 'pubspec.yaml'));
  if (!pubspecFile.existsSync()) {
    throw StateError('pubspec.yaml not found in ${root.path}');
  }
  final pubspec = loadYaml(pubspecFile.readAsStringSync()) as YamlMap;
  return pubspec['name'] as String;
}

OrmProjectContext resolveOrmProject({String? configPath}) {
  if (configPath != null && configPath.trim().isNotEmpty) {
    final normalized = p.normalize(
      p.isAbsolute(configPath)
          ? configPath
          : p.join(Directory.current.path, configPath),
    );
    final file = File(normalized);
    if (!file.existsSync()) {
      throw StateError('Config file $normalized not found.');
    }
    final root = findProjectRoot(file.parent);
    return OrmProjectContext(root: root, configFile: file);
  }

  final nearest = _findNearestOrmProjectConfig(Directory.current);
  if (nearest != null) {
    final root = findProjectRoot(nearest.parent);
    return OrmProjectContext(root: root, configFile: nearest);
  }

  final root = findProjectRoot();
  final fallback = File(p.join(root.path, 'ormed.yaml'));
  if (!fallback.existsSync()) {
    final legacy = File(p.join(root.path, 'ormed.yaml'));
    if (legacy.existsSync()) return OrmProjectContext(root: root, configFile: legacy);
    throw StateError(
      'Missing ormed.yaml. Run `ormed init` or provide --config path.',
    );
  }
  return OrmProjectContext(root: root, configFile: fallback);
}

File? _findNearestOrmProjectConfig(Directory start) {
  var dir = start;
  while (true) {
    final candidate = File(p.join(dir.path, 'ormed.yaml'));
    if (candidate.existsSync()) {
      return candidate;
    }
    final legacy = File(p.join(dir.path, 'ormed.yaml'));
    if (legacy.existsSync()) {
      return legacy;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) {
      return null;
    }
    dir = parent;
  }
}

SchemaState? resolveSchemaState(
  DriverAdapter driver,
  OrmConnection connection,
  String ledgerTable,
) {
  if (driver is SchemaStateProvider) {
    final provider = driver as SchemaStateProvider;
    return provider.createSchemaState(
      connection: connection,
      ledgerTable: ledgerTable,
    );
  }
  return null;
}

Future<List<MigrationDescriptor>> loadMigrations(
  Directory root,
  OrmProjectConfig config, {
  String? registryPath,
}) => migrationRegistryLoader.load(root, config, registryPath: registryPath);

Future<SchemaPlan> buildRuntimePlan({
  required Directory root,
  required OrmProjectConfig config,
  required MigrationId id,
  required MigrationDirection direction,
  required SchemaSnapshot snapshot,
  String? registryPath,
}) => migrationRegistryLoader.buildPlan(
  root: root,
  config: config,
  id: id,
  direction: direction,
  snapshot: snapshot,
  registryPath: registryPath,
);

Future<void> runSeedRegistry({
  required OrmProjectContext project,
  required OrmProjectConfig config,
  required SeedSection seeds,
  List<String>? overrideClasses,
  bool pretend = false,
  String? databaseOverride,
  String? connection,
}) => projectSeederRunner.run(
  project: project,
  config: config,
  seeds: seeds,
  overrideClasses: overrideClasses,
  pretend: pretend,
  databaseOverride: databaseOverride,
  connection: connection,
);

/// Registers [config]’s tenants and returns the handle for [targetConnection].
Future<OrmConnectionHandle> createConnection(
  Directory root,
  OrmProjectConfig config, {
  String? targetConnection,
}) {
  _bootstrapCliDrivers();
  return registerConnectionsFromConfig(
    root: root,
    config: config,
    targetConnection: targetConnection ?? config.connectionName,
  );
}

var _cliDriversBootstrapped = false;

void _bootstrapCliDrivers() {
  if (_cliDriversBootstrapped) return;
  _cliDriversBootstrapped = true;
  ensureSqliteDriverRegistration();
  ensureMySqlDriverRegistration();
  ensurePostgresDriverRegistration();
}

/// Shared Console instance for CLI output.
Console get cliIO => _cliIO ??= Console(
  renderer: TerminalRenderer(),
  out: stdout.writeln,
  err: stderr.writeln,
);
Console? _cliIO;

void printMigrationPlanPreview({
  required MigrationDescriptor descriptor,
  required MigrationDirection direction,
  required SchemaDiff diff,
  required SchemaPreview preview,
  bool includeStatements = false,
}) {
  final io = cliIO;

  io.newLine();
  io.section('Migration ${descriptor.id} (${direction.name})');

  if (diff.isEmpty) {
    io.info('No schema changes detected');
  } else {
    for (final entry in diff.entries) {
      // Color-code based on entry type
      final symbol = entry.symbol;
      String styledEntry;
      if (symbol == '+') {
        styledEntry = io.style
            .foreground(Colors.success)
            .render('  $symbol ${entry.description}');
      } else if (symbol == '-') {
        styledEntry = io.style
            .foreground(Colors.error)
            .render('  $symbol ${entry.description}');
      } else {
        styledEntry = io.style
            .foreground(Colors.warning)
            .render('  $symbol ${entry.description}');
      }
      io.writeln(styledEntry);

      for (final note in entry.notes) {
        io.writeln(io.style.foreground(Colors.muted).render('      - $note'));
      }
    }
  }

  io.twoColumnDetail('SQL statements', '${preview.statements.length}');

  if (includeStatements && preview.statements.isNotEmpty) {
    io.newLine();
    for (final statement in preview.statements) {
      io.writeln(
        io.style.foreground(Colors.muted).render('    ${statement.sql}'),
      );
    }
  }
}

bool confirmToProceed({bool force = false, String action = 'proceed'}) {
  if (force) return true;
  if (!_isProductionEnvironment()) return true;

  return cliIO.confirm(
    'Application is running in production. Continue to $action?',
    defaultValue: false,
  );
}

bool _isProductionEnvironment() {
  const envVars = ['ORM_ENV', 'DART_ENV', 'FLUTTER_ENV', 'ENV'];
  for (final key in envVars) {
    final value = Platform.environment[key];
    if (value != null && value.toLowerCase() == 'production') {
      return true;
    }
  }
  return false;
}

String resolveRegistryFilePath(
  Directory root,
  OrmProjectConfig config, {
  String? override,
  bool realPath = false,
}) {
  if (override == null) {
    return resolvePath(root, config.migrations.registry);
  }
  if (realPath || p.isAbsolute(override)) {
    return p.normalize(override);
  }
  return resolvePath(root, override);
}

String insertBetweenMarkers(
  String content,
  String startMarker,
  String endMarker,
  String snippet, {
  required String indent,
}) {
  final start = content.indexOf(startMarker);
  final end = content.indexOf(endMarker);
  if (start == -1 || end == -1 || end < start) {
    throw StateError(
      'Missing markers $startMarker / $endMarker in migrations.dart',
    );
  }
  final before = content.substring(0, start + startMarker.length);
  final between = content.substring(start + startMarker.length, end).trim();
  final after = content.substring(end);
  final newBetween = between.isEmpty ? snippet : '$between\n$indent$snippet';
  return '$before\n$indent$newBetween$after';
}

String _extractJsonPayload(
  String stdoutText, {
  required String context,
  required bool expectArray,
}) {
  final sanitized = _cleanProcessStdout(stdoutText);
  final trimmed = sanitized.trim();
  final startChar = expectArray ? '[' : '{';
  final endChar = expectArray ? ']' : '}';
  final start = trimmed.indexOf(startChar);
  final end = trimmed.lastIndexOf(endChar);
  if (start == -1 || end == -1 || end < start) {
    throw StateError(
      'Failed to parse $context output as JSON. Received:\n$stdoutText',
    );
  }
  return trimmed.substring(start, end + 1);
}

@visibleForTesting
String extractJsonPayloadForTest(
  String stdoutText, {
  required String context,
  required bool expectArray,
}) =>
    _extractJsonPayload(stdoutText, context: context, expectArray: expectArray);

String _cleanProcessStdout(String stdoutText) {
  if (stdoutText.isEmpty) {
    return stdoutText;
  }
  final withoutOsc = stdoutText.replaceAll(_oscControlPattern, '');
  final withoutAnsi = withoutOsc.replaceAll(_ansiEscapePattern, '');
  return withoutAnsi.replaceAll('\r', '\n');
}

final RegExp _ansiEscapePattern = RegExp('\x1B\\[[0-9;?]*[ -/]*[@-~]');
final RegExp _oscControlPattern = RegExp('\x1B\\][^\x07]*\x07');

Future<void> previewRollbacks({
  required Directory root,
  required OrmProjectConfig config,
  required MigrationRunner runner,
  required SchemaDriver schemaDriver,
  required int steps,
  required String registryPath,
}) async {
  final statuses = await runner.status();
  final applied = statuses.where((status) => status.applied).toList();
  if (applied.isEmpty) {
    stdout.writeln('No applied migrations to preview.');
    return;
  }
  final count = steps > applied.length ? applied.length : steps;
  final snapshot = await SchemaSnapshot.capture(schemaDriver);
  final targets = applied.reversed.take(count).toList();
  for (final status in targets) {
    final descriptor = status.descriptor;
    final plan = await buildRuntimePlan(
      root: root,
      config: config,
      id: descriptor.id,
      direction: MigrationDirection.down,
      snapshot: snapshot,
      registryPath: registryPath,
    );
    final diff = SchemaDiffer().diff(plan: plan, snapshot: snapshot);
    final preview = schemaDriver.describeSchemaPlan(plan);
    printMigrationPlanPreview(
      descriptor: descriptor,
      direction: MigrationDirection.down,
      diff: diff,
      preview: preview,
      includeStatements: true,
    );
  }
}

Future<void> previewMigrations({
  required Directory root,
  required OrmProjectConfig config,
  required MigrationRunner runner,
  required SchemaDriver schemaDriver,
  int? limit,
  required String registryPath,
}) async {
  final statuses = await runner.status();
  final pending = statuses.where((status) => !status.applied).toList();
  if (pending.isEmpty) {
    stdout.writeln('No pending migrations.');
    return;
  }
  final snapshot = await SchemaSnapshot.capture(schemaDriver);
  final count = limit == null || limit > pending.length
      ? pending.length
      : limit;
  for (var i = 0; i < count; i++) {
    final descriptor = pending[i].descriptor;
    final plan = await buildRuntimePlan(
      root: root,
      config: config,
      id: descriptor.id,
      direction: MigrationDirection.up,
      snapshot: snapshot,
      registryPath: registryPath,
    );
    final diff = SchemaDiffer().diff(plan: plan, snapshot: snapshot);
    final preview = schemaDriver.describeSchemaPlan(plan);
    printMigrationPlanPreview(
      descriptor: descriptor,
      direction: MigrationDirection.up,
      diff: diff,
      preview: preview,
      includeStatements: true,
    );
  }
}
