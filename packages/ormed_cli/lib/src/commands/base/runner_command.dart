import 'dart:io' as system_io;

import 'package:artisanal/args.dart';
import 'package:ormed/ormed.dart';

import 'event_reporter.dart';
import 'shared.dart';

export 'event_reporter.dart';

abstract class RunnerCommand extends Command<void> {
  RunnerCommand() {
    argParser.addOption(
      'config',
      abbr: 'c',
      help: 'Path to ormed.yaml (defaults to project root).',
    );
    argParser.addFlag(
      'preview',
      negatable: false,
      help: 'Print schema diffs and SQL previews before applying.',
    );
    argParser.addOption(
      'path',
      help:
          'Override the migration registry file path (relative to project root unless --realpath is used).',
    );
    argParser.addFlag(
      'realpath',
      negatable: false,
      help: 'Treat --path as an absolute path.',
    );
    argParser.addOption(
      'database',
      abbr: 'd',
      help: 'Override the database connection used by this command.',
    );
    argParser.addOption(
      'connection',
      help:
          'Select a specific connection block defined in ormed.yaml (defaults to default_connection or the only entry).',
    );
  }

  Future<void> handle(
    OrmProjectContext project,
    OrmProjectConfig config,
    MigrationRunner runner,
    OrmConnection connection,
    SqlMigrationLedger ledger,
    CliEventReporter reporter,
  );

  @override
  Future<void> run() async {
    final configArg = argResults?['config'] as String?;
    final preview = argResults?['preview'] == true;
    final databaseOverride = argResults?['database'] as String?;
    final connectionOverride = argResults?['connection'] as String?;
    final pathOverride = argResults?['path'] as String?;
    final realPath = argResults?['realpath'] == true;
    final context = resolveOrmProject(configPath: configArg);
    final root = context.root;
    var config = loadOrmProjectConfig(context.configFile);
    if (connectionOverride != null && connectionOverride.trim().isNotEmpty) {
      config = config.withConnection(connectionOverride);
    }
    final effectiveConfig = databaseOverride == null
        ? config
        : config.updateActiveConnection(
            driver: config.driver.copyWith(
              options: {...config.driver.options, 'database': databaseOverride},
            ),
          );
    final registryPath = resolveRegistryFilePath(
      root,
      effectiveConfig,
      override: pathOverride,
      realPath: realPath,
    );
    final migrations = await loadMigrations(
      root,
      effectiveConfig,
      registryPath: registryPath,
    );
    if (migrations.isEmpty) {
      cliIO.warning('No migrations found in registry.');
      return;
    }
    final connectionHandle = await createConnection(root, effectiveConfig);
    final ledger = SqlMigrationLedger.managed(
      connectionName: connectionHandle.name,
      manager: connectionHandle.manager,
      tableName: effectiveConfig.migrations.ledgerTable,
    );
    final reporter = CliEventReporter(io: cliIO)
      ..listenToMigrations()
      ..listenToSeeders();
    try {
      await connectionHandle.use((connection) async {
        final driver = connection.driver;
        final schemaDriver = driver as SchemaDriver;
        MigrationPlanResolver? planResolver;
        if (preview) {
          planResolver = (descriptor, direction) async {
            final snapshot = await SchemaSnapshot.capture(schemaDriver);
            final plan = await buildRuntimePlan(
              root: root,
              config: effectiveConfig,
              id: descriptor.id,
              direction: direction,
              snapshot: snapshot,
              registryPath: registryPath,
            );
            final diff = SchemaDiffer().diff(plan: plan, snapshot: snapshot);
            final planPreview = schemaDriver.describeSchemaPlan(plan);
            printMigrationPlanPreview(
              descriptor: descriptor,
              direction: direction,
              diff: diff,
              preview: planPreview,
            );
            return plan;
          };
        }
        final runner = MigrationRunner(
          schemaDriver: schemaDriver,
          ledger: ledger,
          migrations: migrations,
          planResolver: planResolver,
        );
        await handle(
          context,
          effectiveConfig,
          runner,
          connection,
          ledger,
          reporter,
        );
      });
    } on OrmException catch (error) {
      cliIO.error(error.toString());
      if (error.hint != null && error.hint!.trim().isNotEmpty) {
        cliIO.note(error.hint!.trim());
      }
      system_io.exitCode = 1;
    } finally {
      reporter.dispose();
      await connectionHandle.dispose();
    }
  }
}
