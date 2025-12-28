import 'dart:io';

import 'package:artisanal/artisanal.dart';
import 'package:ormed_fullstack_example/src/server/server.dart';

// #region cli-runner
Future<void> main(List<String> args) async {
  final runner =
      CommandRunner(
          'movie-catalog',
          'CLI for the Ormed + Shelf movie catalog example.',
        )
        ..addCommand(ServeCommand())
        ..addCommand(MigrateCommand())
        ..addCommand(SeedCommand());

  await runner.run(args);
}
// #endregion cli-runner

abstract class BaseCommand extends Command<void> {
  BaseCommand() : io = Console();

  @override
  final Console io;

  Future<int> runProcess(List<String> args) async {
    final process = await Process.start('dart', [
      'run',
      'ormed_cli:ormed',
      ...args,
    ], mode: ProcessStartMode.inheritStdio);
    return process.exitCode;
  }
}

class ServeCommand extends BaseCommand {
  // #region cli-serve
  @override
  String get name => 'serve';

  @override
  String get description => 'Start the Shelf server.';

  @override
  Future<void> run() async {
    final host = argResults?['host'] as String? ?? '0.0.0.0';
    final port = int.parse(argResults?['port'] as String? ?? '8080');

    io.title('Movie Catalog Server');
    io.note(Style().hyperlink('Starting on $host:$port').render());

    await runServer(host: host, port: port);
  }

  ServeCommand() {
    argParser
      ..addOption('host', defaultsTo: '0.0.0.0')
      ..addOption('port', defaultsTo: '8080');
  }
  // #endregion cli-serve
}

class MigrateCommand extends BaseCommand {
  // #region cli-migrate
  @override
  String get name => 'migrate';

  @override
  String get description => 'Run database migrations.';

  @override
  Future<void> run() async {
    io.section('Running migrations');
    final exitCode = await runProcess(['migrate']);
    if (exitCode == 0) {
      io.success('Migrations complete.');
    } else {
      io.error('Migration failed with code $exitCode.');
    }
  }

  // #endregion cli-migrate
}

class SeedCommand extends BaseCommand {
  // #region cli-seed
  @override
  String get name => 'seed';

  @override
  String get description => 'Run database seeders.';

  @override
  Future<void> run() async {
    io.section('Seeding data');
    final exitCode = await runProcess(['seed']);
    if (exitCode == 0) {
      io.success('Seed complete.');
    } else {
      io.error('Seed failed with code $exitCode.');
    }
  }

  // #endregion cli-seed
}
