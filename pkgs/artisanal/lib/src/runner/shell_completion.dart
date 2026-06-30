import 'package:args/args.dart' show ArgParser;
import 'package:completion/completion.dart' as completion;
// ignore: implementation_imports
import 'package:completion/src/get_args_completions.dart'
    show getArgsCompletions;

/// Bridges the [completion] package to an Artisanal [CommandRunner].
///
/// Use [ShellCompleter.generate] to produce a shell completion script
/// for your executable, and [shellCompleter] on [CommandRunner] to enable
/// automatic tab-completion at runtime.
class ShellCompleter {
  final ArgParser _parser;

  ShellCompleter(this._parser);

  List<String> complete(List<String> args, String compLine, int compPoint) {
    return getArgsCompletions(_parser, args, compLine, compPoint);
  }

  static String generate(String executableName) {
    return completion.generateCompletionScript([executableName]);
  }

  static String generateAll(List<String> executableNames) {
    return completion.generateCompletionScript(executableNames);
  }
}
