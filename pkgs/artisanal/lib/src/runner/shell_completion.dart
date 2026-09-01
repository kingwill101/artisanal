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

  /// Creates a completer for [parser].
  ShellCompleter(this._parser);

  /// Returns completion candidates for the current shell input.
  List<String> complete(List<String> args, String compLine, int compPoint) {
    return getArgsCompletions(_parser, args, compLine, compPoint);
  }

  /// Generates a Bash and Zsh completion script for [executableName].
  static String generate(String executableName) {
    return _withZshCursorPoint(
      completion.generateCompletionScript([executableName]),
    );
  }

  /// Generates a Bash and Zsh completion script for [executableNames].
  static String generateAll(List<String> executableNames) {
    return _withZshCursorPoint(
      completion.generateCompletionScript(executableNames),
    );
  }

  // package:completion 1.0.2 hardcodes zero for Zsh, so every request is
  // evaluated at the start of BUFFER and produces no useful candidates.
  static String _withZshCursorPoint(String script) =>
      script.replaceAll('COMP_POINT=0 \\\n', 'COMP_POINT=\$CURSOR \\\n');
}
