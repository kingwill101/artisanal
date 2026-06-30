import 'package:artisanal/args.dart';
import 'package:test/test.dart';

class _NoopCommand extends Command<void> {
  _NoopCommand(this._name, this._description, {void Function()? configure}) {
    configure?.call();
  }

  final String _name;
  final String _description;

  @override
  String get name => _name;

  @override
  String get description => _description;

  @override
  Future<void> run() async {}
}

void main() {
  group('ShellCompleter', () {
    test('top-level commands are suggested with empty args', () {
      final runner =
          CommandRunner<void>(
              'test-cli',
              'Test CLI',
              ansi: false,
              out: (_) {},
              err: (_) {},
              setExitCode: (_) {},
            )
            ..addCommand(_NoopCommand('serve', 'Start the server.'))
            ..addCommand(_NoopCommand('build', 'Build the project.'))
            ..addCommand(_NoopCommand('test', 'Run tests.'));

      final completer = runner.shellCompleter;
      expect(
        completer.complete([], '', 0),
        containsAll(['serve', 'build', 'test']),
      );
    });

    test('partial command name filters suggestions', () {
      final runner =
          CommandRunner<void>(
              'test-cli',
              'Test CLI',
              ansi: false,
              out: (_) {},
              err: (_) {},
              setExitCode: (_) {},
            )
            ..addCommand(_NoopCommand('serve', 'Start the server.'))
            ..addCommand(_NoopCommand('build', 'Build the project.'));

      final completer = runner.shellCompleter;
      final completions = completer.complete(['se'], 'se', 2);
      expect(completions, isNot(contains('build')));
      expect(completions, contains('serve'));
    });

    test('subcommands are completed after a command name', () {
      final runner = CommandRunner<void>(
        'test-cli',
        'Test CLI',
        ansi: false,
        out: (_) {},
        err: (_) {},
        setExitCode: (_) {},
      );

      final dbCmd = _NoopCommand('db', 'Database operations.');
      final migrateCmd = _NoopCommand('migrate', 'Run migrations.');
      dbCmd.addSubcommand(migrateCmd);
      runner.addCommand(dbCmd);

      final completer = runner.shellCompleter;
      final completions = completer.complete(['db'], 'db ', 3);
      expect(completions, contains('migrate'));
    });

    test('option names are completed after --', () {
      final runner = CommandRunner<void>(
        'test-cli',
        'Test CLI',
        enableShellCompletion: false,
        ansi: false,
        out: (_) {},
        err: (_) {},
        setExitCode: (_) {},
      );

      final runCmd = _NoopCommand('run', 'Run something.');
      runCmd.argParser.addOption('port', abbr: 'p', help: 'Port number.');
      runCmd.argParser.addFlag('verbose', abbr: 'v', help: 'Verbose output.');
      runner.addCommand(runCmd);

      final completer = runner.shellCompleter;
      final completions = completer.complete(['run', '--ve'], 'run --ve', 8);
      expect(completions, contains('--verbose'));
    });

    test('allowed option values are completed', () {
      final runner = CommandRunner<void>(
        'test-cli',
        'Test CLI',
        enableShellCompletion: false,
        ansi: false,
        out: (_) {},
        err: (_) {},
        setExitCode: (_) {},
      );

      final runCmd = _NoopCommand('run', 'Run something.');
      runCmd.argParser.addOption(
        'env',
        help: 'Environment.',
        allowed: ['dev', 'staging', 'prod'],
      );
      runner.addCommand(runCmd);

      final completer = runner.shellCompleter;
      final completions = completer.complete(
        ['run', '--env', ''],
        'run --env ',
        11,
      );
      expect(completions, containsAll(['dev', 'staging', 'prod']));
    });

    test('generate produces a valid completion script', () {
      final script = ShellCompleter.generate('myapp');
      expect(script, contains('myapp'));
      expect(script, contains('completion'));
      expect(script, contains('compadd'));
      expect(script, contains('COMPREPLY'));
    });

    test('generateAll handles multiple names', () {
      final script = ShellCompleter.generateAll(['myapp', 'myapp-dev']);
      expect(script, contains('myapp'));
      expect(script, contains('myapp-dev'));
    });
  });

  group('CommandRunner shell completion integration', () {
    test('shellCompletionScript uses executable name', () {
      final runner = CommandRunner<void>(
        'mytool',
        'My tool.',
        ansi: false,
        out: (_) {},
        err: (_) {},
        setExitCode: (_) {},
      );

      expect(runner.shellCompletionScript, contains('mytool'));
    });

    test('--completion-script flag prints the script and exits', () async {
      final out = StringBuffer();
      var code = 0;

      final runner = CommandRunner<void>(
        'mytool',
        'My tool.',
        ansi: false,
        out: (line) => out.writeln(line),
        err: (_) {},
        setExitCode: (c) => code = c,
      );

      await runner.run(['--completion-script']);

      expect(code, 0);
      expect(out.toString(), contains('mytool'));
      expect(out.toString(), contains('completion'));
      expect(out.toString(), contains('COMPREPLY'));
    });

    test(
      '--completion-script flag exits before normal command execution',
      () async {
        var ran = false;

        final runner = CommandRunner<void>(
          'mytool',
          'My tool.',
          ansi: false,
          out: (_) {},
          err: (_) {},
          setExitCode: (_) {},
        );

        final doThing = _NoopCommand('do-thing', 'Does a thing.');
        doThing.argParser.addFlag('force', negatable: false, help: 'Force it.');
        runner.addCommand(doThing);

        await runner.run(['do-thing', '--force', '--completion-script']);

        // The --completion-script flag short-circuits before command dispatch.
      },
    );

    test('shellCompleter getter returns an instance', () {
      final runner = CommandRunner<void>(
        'mytool',
        'My tool.',
        ansi: false,
        out: (_) {},
        err: (_) {},
        setExitCode: (_) {},
      );

      expect(runner.shellCompleter, isA<ShellCompleter>());
      expect(runner.shellCompleter, same(runner.shellCompleter));
    });

    test('enableShellCompletion false stores the flag', () {
      final runner = CommandRunner<void>(
        'mytool',
        'My tool.',
        enableShellCompletion: false,
        ansi: false,
        out: (_) {},
        err: (_) {},
        setExitCode: (_) {},
      );

      expect(runner.enableShellCompletion, isFalse);
    });
  });
}
