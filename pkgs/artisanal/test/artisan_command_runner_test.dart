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

  test('unknown command does not throw and sets exit code', () async {
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
    expect(err.toString(), contains('Error:'));
    expect(out.toString(), contains('Available commands:'));
  });
}
