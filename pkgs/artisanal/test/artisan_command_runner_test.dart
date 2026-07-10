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
  test('global usage groups namespaced commands', () {
    final runner =
        CommandRunner<void>(
            'orm',
            'Routed ORM CLI',
            ansi: false,
            out: (_) {},
            err: (_) {},
            setExitCode: (_) {},
          )
          ..addCommand(_NoopCommand('apply', 'Apply pending migrations.'))
          ..addCommand(_NoopCommand('schema:dump', 'Dump schema.'))
          ..addCommand(_NoopCommand('schema:describe', 'Describe schema.'));

    final usage = runner.formatGlobalUsage();

    expect(usage, contains('Available commands:'));
    expect(usage, contains('schema'));
    expect(usage, contains('  schema:dump'));
    expect(usage, contains('  schema:describe'));
  });

  test('global usage omits command section when no app commands exist', () {
    final runner =
        CommandRunner<void>(
            'github_cli',
            'GitHub CLI TUI',
            ansi: false,
            out: (_) {},
            err: (_) {},
            setExitCode: (_) {},
          )
          ..argParser.addOption(
            'repo',
            abbr: 'R',
            help: 'Repository to inspect.',
            valueHelp: 'owner/repo',
          );

    final usage = runner.formatGlobalUsage();

    expect(usage, contains('Usage:'));
    expect(usage, contains('--repo=<owner/repo>'));
    expect(usage, isNot(contains('Available commands:')));
    expect(usage, isNot(contains('Run "github_cli <command> --help"')));
  });

  test('explicit --ansi forces styled global usage output', () async {
    final out = StringBuffer();
    final err = StringBuffer();

    final runner = CommandRunner<void>(
      'github_cli',
      'GitHub CLI TUI',
      out: (line) => out.writeln(line),
      err: (line) => err.writeln(line),
      setExitCode: (_) {},
    );

    await runner.run(['--ansi', '--help']);

    expect(err.toString(), isEmpty);
    expect(out.toString(), contains('\x1b['));
    expect(out.toString(), contains('Usage:'));
  });

  test(
    'command --help prints sectioned output (Description/Usage/Options)',
    () async {
      final out = StringBuffer();
      final err = StringBuffer();

      final runner =
          CommandRunner<void>(
            'orm',
            'Routed ORM CLI',
            ansi: false,
            out: (line) => out.writeln(line),
            err: (line) => err.writeln(line),
            setExitCode: (_) {},
          )..addCommand(
            _NoopCommand(
              'schema:dump',
              'Dump the current database schema.',
              configure: () {
                // Add an option so Options section isn't empty.
              },
            )..argParser.addOption('path', help: 'Output path.'),
          );

      await runner.run(['schema:dump', '--help']);

      expect(err.toString(), isEmpty);
      final output = out.toString();
      expect(output, contains('Description:'));
      expect(output, contains('Usage:'));
      expect(output, contains('Options:'));
      expect(output, contains('--path'));
    },
  );

  test('namespace command shows subcommands without error', () async {
    final out = StringBuffer();
    final err = StringBuffer();
    var code = -1;

    final runner =
        CommandRunner<void>(
            'orm',
            'Routed ORM CLI',
            ansi: false,
            out: (line) => out.writeln(line),
            err: (line) => err.writeln(line),
            setExitCode: (value) => code = value,
          )
          ..addCommand(_NoopCommand('apply', 'Apply pending migrations.'))
          ..addCommand(_NoopCommand('schema:dump', 'Dump schema.'))
          ..addCommand(_NoopCommand('schema:describe', 'Describe schema.'));

    await runner.run(['schema']);

    expect(
      code,
      1,
      reason: 'should exit with code 1 (no command was executed)',
    );
    expect(err.toString(), isEmpty, reason: 'no error output');
    final output = out.toString();
    expect(output, contains('Available commands for the "schema" namespace:'));
    expect(output, contains('schema:dump'));
    expect(output, contains('schema:describe'));
    expect(output, contains('Run "orm schema:<subcommand> --help"'));
  });

  test(
    'namespace command with --help flag shows subcommands without error',
    () async {
      final out = StringBuffer();
      final err = StringBuffer();
      var code = -1;

      final runner =
          CommandRunner<void>(
              'orm',
              'Routed ORM CLI',
              ansi: false,
              out: (line) => out.writeln(line),
              err: (line) => err.writeln(line),
              setExitCode: (value) => code = value,
            )
            ..addCommand(_NoopCommand('apply', 'Apply pending migrations.'))
            ..addCommand(_NoopCommand('schema:dump', 'Dump schema.'))
            ..addCommand(_NoopCommand('schema:describe', 'Describe schema.'));

      await runner.run(['schema', '--help']);

      expect(
        code,
        1,
        reason: 'should exit with code 1 (no command was executed)',
      );
      expect(err.toString(), isEmpty, reason: 'no error output');
      final output = out.toString();
      expect(
        output,
        contains('Available commands for the "schema" namespace:'),
      );
      expect(output, contains('schema:dump'));
      expect(output, contains('schema:describe'));
      expect(output, contains('Run "orm schema:<subcommand> --help"'));
    },
  );

  test('getNamespaces returns all unique namespace prefixes', () {
    final runner =
        CommandRunner<void>(
            'orm',
            'Routed ORM CLI',
            ansi: false,
            out: (_) {},
            err: (_) {},
            setExitCode: (_) {},
          )
          ..addCommand(_NoopCommand('apply', 'Apply pending migrations.'))
          ..addCommand(_NoopCommand('schema:dump', 'Dump schema.'))
          ..addCommand(_NoopCommand('schema:describe', 'Describe schema.'))
          ..addCommand(_NoopCommand('cache:clear', 'Clear cache.'))
          ..addCommand(
            _NoopCommand('cache:foo:bar', 'Nested namespace command.'),
          );

    final namespaces = runner.getNamespaces();

    expect(namespaces, contains('schema'));
    expect(namespaces, contains('cache'));
    expect(namespaces, contains('cache:foo'));
    expect(namespaces, isNot(contains('apply')));
    expect(namespaces, isNot(contains('cache:foo:bar')));
  });

  test(
    'allCommandsInNamespace returns only commands in the given namespace',
    () {
      final runner =
          CommandRunner<void>(
              'orm',
              'Routed ORM CLI',
              ansi: false,
              out: (_) {},
              err: (_) {},
              setExitCode: (_) {},
            )
            ..addCommand(_NoopCommand('apply', 'Apply pending migrations.'))
            ..addCommand(_NoopCommand('schema:dump', 'Dump schema.'))
            ..addCommand(_NoopCommand('schema:describe', 'Describe schema.'))
            ..addCommand(_NoopCommand('cache:clear', 'Clear cache.'));

      final schemaCommands = runner.allCommandsInNamespace('schema');
      expect(schemaCommands.length, 2);
      expect(schemaCommands, containsPair('schema:dump', isNotNull));
      expect(schemaCommands, containsPair('schema:describe', isNotNull));

      final cacheCommands = runner.allCommandsInNamespace('cache');
      expect(cacheCommands.length, 1);
      expect(cacheCommands, containsPair('cache:clear', isNotNull));

      final applyCommands = runner.allCommandsInNamespace('apply');
      expect(applyCommands, isEmpty);
    },
  );

  test('namespace command handles nested namespaces', () async {
    final out = StringBuffer();
    final err = StringBuffer();
    var code = -1;

    final runner =
        CommandRunner<void>(
            'myapp',
            'My CLI',
            ansi: false,
            out: (line) => out.writeln(line),
            err: (line) => err.writeln(line),
            setExitCode: (value) => code = value,
          )
          ..addCommand(_NoopCommand('cache:clear', 'Clear cache.'))
          ..addCommand(
            _NoopCommand('cache:foo:bar', 'Nested namespace command.'),
          )
          ..addCommand(
            _NoopCommand('cache:foo:baz', 'Another nested command.'),
          );

    // Top-level namespace shows all cache:* commands
    await runner.run(['cache']);

    expect(code, 1);
    final output = out.toString();
    expect(output, contains('Available commands for the "cache" namespace:'));
    expect(output, contains('cache:clear'));
    expect(output, contains('cache:foo:bar'));
    expect(output, contains('cache:foo:baz'));
  });

  test(
    'unknown command shows error block on stderr and sets usage exit code',
    () async {
      final out = StringBuffer();
      final err = StringBuffer();
      var code = 0;

      final runner = CommandRunner<void>(
        'orm',
        'Routed ORM CLI',
        ansi: false,
        out: (line) => out.writeln(line),
        err: (line) => err.writeln(line),
        setExitCode: (value) => code = value,
      )..addCommand(_NoopCommand('status', 'Show migration status.'));

      await runner.run(['sttus']);

      expect(code, 64);
      // Error block goes to stderr (matching Symfony behavior).
      expect(
        err.toString(),
        contains('Could not find a command named "sttus".'),
      );
      expect(err.toString(), contains('Did you mean one of these?'));
      // Usage text is no longer printed to stdout (matching Symfony).
      expect(out.toString(), isEmpty);
    },
  );
}
