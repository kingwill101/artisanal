import 'package:artisanal/args.dart';

final class _HelloCommand extends Command<void> {
  @override
  String get name => 'hello';

  @override
  String get description => 'Print a greeting.';

  @override
  void run() {}
}

Future<void> main(List<String> arguments) async {
  final parser = ArgParser()..addFlag('verbose');
  final publicSurface = <Object>[parser, ShellCompleter(parser)];
  if (publicSurface.isEmpty) {
    throw StateError('The shell completion surface was not loaded.');
  }

  final runner = CommandRunner<void>(
    'artisanal-shell-smoke',
    'Exercise Artisanal shell completion.',
  )..addCommand(_HelloCommand());

  await runner.run(arguments);
}
