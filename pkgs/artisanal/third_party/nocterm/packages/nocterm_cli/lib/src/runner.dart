import 'package:args/command_runner.dart';
import 'package:nocterm_cli/src/commands/logs_command.dart';
import 'package:nocterm_cli/src/commands/run_command.dart';
import 'package:nocterm_cli/src/commands/shell_command.dart';
import 'package:nocterm_cli/src/deps/log.dart';

class Runner extends CommandRunner<int> {
  Runner() : super('nocterm', 'CLI - Tools for nocterm TUI framework') {
    addCommand(ShellCommand());
    addCommand(LogsCommand());
    addCommand(RunCommand());
  }

  @override
  Future<int> run(Iterable<String> args) async {
    try {
      if (args.isEmpty) {
        log(usage);
        return 1;
      }
    } on FormatException catch (e) {
      log('Error: ${e.message}');
      log('');
      log(usage);
      return 1;
    }

    return (await super.run(args)) ?? 0;
  }
}
