library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:artisanal/artisanal.dart';
import 'package:meta/meta.dart';
import 'package:ormed/ormed.dart';

import 'src/commands/base/event_reporter.dart';
import 'src/commands/base/shared.dart';

export 'src/commands/base/shared.dart'
    show OrmProjectContext, resolveOrmProject, createConnection;
export 'src/config.dart'
    show
        OrmProjectConfig,
        DriverConfig,
        MigrationSection,
        SeedSection,
        loadOrmProjectConfig;

/// Run a list of registered seeders on the provided [connection].
///
/// If [names] is provided, only seeders with matching names will be run.
///
/// [pretend] can be set to true to log queries instead of executing them.
///
/// [beforeRun] is a callback invoked before execution (e.g. to bootstrap the registry).
Future<void> runSeedRegistryOnConnection(
  OrmConnection connection,
  List<SeederRegistration> seeds, {
  List<String>? names,
  bool pretend = false,
  void Function(OrmConnection connection)? beforeRun,
  void Function(String message)? log,
}) async {
  if (seeds.isEmpty) {
    throw StateError('No seeders registered.');
  }
  final logger = log ?? (String message) => stdout.writeln(message);
  final reporter = CliEventReporter(io: cliIO)..listenToSeeders();
  try {
    await SeederRunner().run(
      connection: connection,
      seeders: seeds,
      names: (names == null || names.isEmpty) ? null : names,
      pretend: pretend,
      beforeRun: beforeRun,
      log: null,
      // Preserve previous behavior (no default log output).
      onPretendQueries: pretend
          ? (entries) {
              for (final entry in entries) {
                logger('[pretend] ${formatPretendEntry(entry)}');
              }
            }
          : null,
    );
  } finally {
    reporter.dispose();
  }
}

/// Entrypoint for running seeders from a generated seed registry script.
///
/// Parses arguments to determine whether to run seeders or list available ones.
Future<void> runSeedRegistryEntrypoint({
  required List<String> args,
  required List<SeederRegistration> seeds,
  void Function(OrmConnection connection)? beforeRun,
}) async {
  if (seeds.isEmpty) {
    stdout.writeln(jsonEncode(const []));
    return;
  }

  // Build a small Artisan runner around `run` and `info` commands so we get
  // global flags, better help, and consistent IO.
  final runner =
      CommandRunner<void>(
          'seeds',
          'Seed registry entrypoint',
          ansi: stdout.supportsAnsiEscapes,
        )
        ..addCommand(
          _SeedRegistryRunCommand(seeds: seeds, beforeRun: beforeRun),
        )
        ..addCommand(_SeedRegistryInfoCommand(seeds: seeds));

  // - If --help is passed alone, show top-level help with both commands.
  // - If args are empty or start with other flags (e.g., --pretend), default to `run`.
  // - Otherwise, treat first arg as the subcommand (e.g., `info`).
  final forwarded =
      (args.isEmpty ||
          (args.first.startsWith('-') &&
              args.first != '--help' &&
              args.first != '-h'))
      ? ['run', ...args]
      : args;

  await runner.run(forwarded);
}

class _SeedRegistryRunCommand extends Command<void> {
  _SeedRegistryRunCommand({required this.seeds, this.beforeRun})
    : super(aliases: const ['r']) {
    // Configure options in constructor so they appear in help
    argParser
      ..addFlag(
        'pretend',
        negatable: false,
        help: 'Dump queries without executing any seeder.',
      )
      ..addOption('config', help: 'Path to orm.yaml to use for this run.')
      ..addOption(
        'database',
        help: 'Override database/file for the active connection.',
      )
      ..addOption(
        'connection',
        help: 'Override the active connection name from orm.yaml.',
      )
      ..addMultiOption(
        'run',
        splitCommas: true,
        help: 'Seeder class names to run (comma-separated or repeated).',
      );
  }

  final List<SeederRegistration> seeds;
  final void Function(OrmConnection connection)? beforeRun;

  @override
  String get name => 'run';

  @override
  String get description =>
      'Run one or more seeders from this registry. Defaults to the first if none specified.';

  @override
  Future<void> run() async {
    // Parse args from the underlying CommandRunner context.
    final args = argResults!;
    final pretend = args['pretend'] == true;
    final configArg = args['config'] as String?;
    final databaseArg = args['database'] as String?;
    final connectionArg = args['connection'] as String?;
    final requestedClasses =
        (args['run'] as List?)?.cast<String>() ?? const <String>[];

    final project = resolveOrmProject(configPath: configArg);
    var config = loadOrmProjectConfig(project.configFile);
    if (connectionArg != null && connectionArg.trim().isNotEmpty) {
      config = config.withConnection(connectionArg);
    }
    final effectiveConfig = databaseArg == null
        ? config
        : config.updateActiveConnection(
            driver: config.driver.copyWith(
              options: {...config.driver.options, 'database': databaseArg},
            ),
          );

    final handle = await createConnection(project.root, effectiveConfig);
    try {
      await handle.use((connection) async {
        await runSeedRegistryOnConnection(
          connection,
          seeds,
          names: requestedClasses.isEmpty
              ? <String>[seeds.first.name]
              : requestedClasses,
          pretend: pretend,
          beforeRun: beforeRun,
        );
      });
    } finally {
      await handle.dispose();
    }
  }
}

class _SeedRegistryInfoCommand extends Command<void> {
  _SeedRegistryInfoCommand({required this.seeds}) {
    // Configure options in constructor so they appear in help
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Output seeders as JSON for tooling.',
    );
  }

  final List<SeederRegistration> seeds;

  @override
  String get name => 'info';

  @override
  List<String> get aliases => const ['i', 'list'];

  @override
  String get description => 'List available seeders in this registry.';

  @override
  Future<void> run() async {
    final jsonOut = argResults!['json'] == true;

    if (jsonOut) {
      final payload = [
        for (final s in seeds) {'name': s.name},
      ];
      stdout.writeln(jsonEncode(payload));
      return;
    }

    // Human-friendly output
    io.title('Seeders');
    if (seeds.isEmpty) {
      io.info('No seeders registered.');
      return;
    }
    io.table(
      headers: const ['Name'],
      rows: [
        for (final s in seeds) [s.name],
      ],
    );
    io.note('Run with "seeds run --run=<Name>" to execute a specific seeder.');
  }
}

/// Run migration registry as an Artisan command-line tool.
///
/// Provides `info` and `run` commands for listing and executing migrations.
/// This is the entrypoint function called from generated migration registry files.
Future<void> runMigrationRegistryEntrypoint({
  required List<String> args,
  required List<MigrationDescriptor> Function() buildMigrations,
  required Future<SchemaPlan> Function({
    required MigrationId id,
    required MigrationDirection direction,
    required SchemaSnapshot snapshot,
  })
  buildPlan,
}) async {
  final migrations = buildMigrations();

  if (migrations.isEmpty) {
    stdout.writeln(jsonEncode(const []));
    return;
  }

  final runner =
      CommandRunner<void>(
          'migrations',
          'Migration registry entrypoint',
          ansi: stdout.supportsAnsiEscapes,
        )
        ..addCommand(_MigrationRegistryInfoCommand(migrations: migrations))
        ..addCommand(
          _MigrationRegistryRunCommand(
            migrations: migrations,
            buildPlan: buildPlan,
          ),
        );

  // For compatibility with existing entrypoints:
  // - If --help is passed alone, show top-level help.
  // - If args start with --dump-json or --plan-json (legacy), route to appropriate handler.
  // - If args are empty or start with other flags, default to `info`.
  // - Otherwise, treat first arg as the subcommand.

  if (args.contains('--dump-json')) {
    // Legacy: output JSON directly
    final payload = migrations.map((m) => m.toJson()).toList();
    stdout.writeln(jsonEncode(payload));
    return;
  }

  if (args.contains('--plan-json')) {
    // Legacy: build and output a specific migration plan
    final planIndex = args.indexOf('--plan-json');
    final id = MigrationId.parse(args[planIndex + 1]);
    final directionName = args[args.indexOf('--direction') + 1];
    final direction = MigrationDirection.values.byName(directionName);
    final snapshotIndex = args.indexOf('--schema-snapshot');
    SchemaSnapshot? snapshot;
    if (snapshotIndex != -1) {
      final decoded = utf8.decode(base64.decode(args[snapshotIndex + 1]));
      final payload = jsonDecode(decoded) as Map<String, Object?>;
      snapshot = SchemaSnapshot.fromJson(payload);
    }
    final plan = await buildPlan(
      id: id,
      direction: direction,
      snapshot: snapshot ?? _emptySnapshot(),
    );
    stdout.writeln(jsonEncode(plan.toJson()));
    return;
  }

  final forwarded =
      (args.isEmpty ||
          (args.first.startsWith('-') &&
              args.first != '--help' &&
              args.first != '-h'))
      ? ['info', ...args]
      : args;

  await runner.run(forwarded);
}

SchemaSnapshot _emptySnapshot() => SchemaSnapshot(
  schemas: const [],
  tables: const [],
  views: const [],
  columns: const [],
  indexes: const [],
  foreignKeys: const [],
);

class _MigrationRegistryInfoCommand extends Command<void> {
  _MigrationRegistryInfoCommand({required this.migrations}) {
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Output migrations as JSON for tooling.',
    );
  }

  final List<MigrationDescriptor> migrations;

  @override
  String get name => 'info';

  @override
  List<String> get aliases => const ['i', 'list'];

  @override
  String get description => 'List available migrations in this registry.';

  @override
  Future<void> run() async {
    final jsonOut = argResults!['json'] == true;

    if (jsonOut) {
      final payload = [
        for (final m in migrations)
          {'id': m.id.toString(), 'checksum': m.checksum},
      ];
      stdout.writeln(jsonEncode(payload));
      return;
    }

    // Human-friendly output
    io.title('Migrations');
    if (migrations.isEmpty) {
      io.info('No migrations registered.');
      return;
    }
    io.table(
      headers: const ['ID', 'Checksum'],
      rows: [
        for (final m in migrations)
          [m.id.toString(), m.checksum.substring(0, 12)],
      ],
    );
    io.note('These migrations are available for the CLI migration commands.');
  }
}

class _MigrationRegistryRunCommand extends Command<void> {
  _MigrationRegistryRunCommand({
    required this.migrations,
    required this.buildPlan,
  }) {
    argParser
      ..addOption(
        'id',
        help: 'Migration ID to inspect or plan.',
        mandatory: true,
      )
      ..addOption(
        'direction',
        help: 'Direction: up or down.',
        allowed: ['up', 'down'],
        defaultsTo: 'up',
      )
      ..addOption(
        'snapshot',
        help: 'Base64-encoded schema snapshot for planning.',
      )
      ..addFlag('json', negatable: false, help: 'Output the plan as JSON.');
  }

  final List<MigrationDescriptor> migrations;
  final Future<SchemaPlan> Function({
    required MigrationId id,
    required MigrationDirection direction,
    required SchemaSnapshot snapshot,
  })
  buildPlan;

  @override
  String get name => 'run';

  @override
  List<String> get aliases => const ['r', 'plan'];

  @override
  String get description =>
      'Generate and display a migration plan for a specific migration.';

  @override
  Future<void> run() async {
    final args = argResults!;
    final idStr = args['id'] as String;
    final directionStr = args['direction'] as String;
    final snapshotArg = args['snapshot'] as String?;
    final jsonOut = args['json'] == true;

    final id = MigrationId.parse(idStr);
    final direction = MigrationDirection.values.byName(directionStr);

    SchemaSnapshot? snapshot;
    if (snapshotArg != null) {
      final decoded = utf8.decode(base64.decode(snapshotArg));
      final payload = jsonDecode(decoded) as Map<String, Object?>;
      snapshot = SchemaSnapshot.fromJson(payload);
    }

    final plan = await buildPlan(
      id: id,
      direction: direction,
      snapshot: snapshot ?? _emptySnapshot(),
    );

    if (jsonOut) {
      stdout.writeln(jsonEncode(plan.toJson()));
      return;
    }

    // Human-friendly output
    io.title('Migration Plan: $id ($directionStr)');
    if (plan.mutations.isEmpty) {
      io.info('No schema changes detected.');
      return;
    }

    io.writeln('Mutations:');
    for (var i = 0; i < plan.mutations.length; i++) {
      final mutation = plan.mutations[i];
      final tableInfo = mutation.table != null ? ' (${mutation.table})' : '';
      io.writeln('  ${i + 1}. ${mutation.operation.name}$tableInfo');
    }
  }
}

@visibleForTesting
String formatPretendEntry(QueryLogEntry entry) => _formatPretendEntry(entry);

String _formatPretendEntry(QueryLogEntry entry) {
  final normalized = entry.preview.normalized;
  final logEntry = <String, Object?>{
    'type': normalized.type,
    'command': normalized.command,
    if (normalized.arguments.isNotEmpty) 'arguments': normalized.arguments,
    if (normalized.parameters.isNotEmpty) 'parameters': normalized.parameters,
    if (normalized.metadata.isNotEmpty) 'metadata': normalized.metadata,
    'duration_ms': entry.duration.inMicroseconds / 1000,
    'success': entry.success,
    if (entry.model != null) 'model': entry.model,
    if (entry.table != null) 'table': entry.table,
    if (entry.rowCount != null) 'row_count': entry.rowCount,
  };
  return const JsonEncoder.withIndent('  ').convert(logEntry);
}
