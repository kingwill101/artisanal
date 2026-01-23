import 'package:artisanal/artisanal.dart';
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
  group('usage snapshots', () {
    test('global usage (ansi off)', () {
      final runner =
          CommandRunner<void>(
              'orm',
              'Routed ORM CLI',
              ansi: false,
              // Ensure the help output is deterministic and does not depend on the
              // ambient terminal.
              renderer: StringRenderer(colorProfile: ColorProfile.ascii),
              out: (_) {},
              err: (_) {},
              setExitCode: (_) {},
              usageLineLength: 80,
            )
            ..addCommand(_NoopCommand('apply', 'Apply pending migrations.'))
            ..addCommand(_NoopCommand('schema:dump', 'Dump schema.'))
            ..addCommand(_NoopCommand('schema:describe', 'Describe schema.'));

      expect(
        runner.formatGlobalUsage(),
        equals(
          [
            'Routed ORM CLI',
            '',
            'Usage:',
            '  orm <command> [arguments]',
            '',
            'Options:',
            '  -h, --help              Print this usage information.',
            '      --[no-]ansi         Force (or disable with --no-ansi) ANSI output.',
            '  -q, --quiet             Do not output any message.',
            '      --silent            Alias for --quiet.',
            '  -n, --no-interaction    Do not ask any interactive question.',
            '  -v, --verbose           Increase verbosity of messages: 1 for normal output, 2',
            '                          for more verbose output and 3 for debug.',
            '',
            'Available commands:',
            '  apply            Apply pending migrations.',
            '',
            'schema',
            '  schema:describe  Describe schema.',
            '  schema:dump      Dump schema.',
            '',
            'Run "orm <command> --help" for more information about a command.',
          ].join('\n'),
        ),
      );
    });

    test('global usage (ansi on)', () {
      final runner =
          CommandRunner<void>(
              'orm',
              'Routed ORM CLI',
              ansi: true,
              renderer: StringRenderer(colorProfile: ColorProfile.ansi),
              out: (_) {},
              err: (_) {},
              setExitCode: (_) {},
              usageLineLength: 80,
            )
            ..addCommand(_NoopCommand('apply', 'Apply pending migrations.'))
            ..addCommand(_NoopCommand('schema:dump', 'Dump schema.'))
            ..addCommand(_NoopCommand('schema:describe', 'Describe schema.'));

      expect(
        runner.formatGlobalUsage(),
        equals(
          [
            'Routed ORM CLI',
            '',
            // Headings are bold + yellow when ANSI is enabled.
            '\x1b[1m\x1b[93mUsage:\x1b[22m\x1b[m',
            '  orm <command> [arguments]',
            '',
            '\x1b[1m\x1b[93mOptions:\x1b[22m\x1b[m',
            '  \x1b[92m-h, --help\x1b[m              Print this usage information.',
            '      \x1b[92m--[no-]ansi\x1b[m         Force (or disable with --no-ansi) ANSI output.',
            '  \x1b[92m-q, --quiet\x1b[m             Do not output any message.',
            '      \x1b[92m--silent\x1b[m            Alias for --quiet.',
            '  \x1b[92m-n, --no-interaction\x1b[m    Do not ask any interactive question.',
            '  \x1b[92m-v, --verbose\x1b[m           Increase verbosity of messages: 1 for normal output, 2',
            '                          for more verbose output and 3 for debug.',
            '',
            '\x1b[1m\x1b[93mAvailable commands:\x1b[22m\x1b[m',
            '  \x1b[92mapply\x1b[m            Apply pending migrations.',
            '',
            '\x1b[1m\x1b[93mschema\x1b[22m\x1b[m',
            '  \x1b[92mschema:describe\x1b[m  Describe schema.',
            '  \x1b[92mschema:dump\x1b[m      Dump schema.',
            '',
            'Run \x1b[1m"orm <command> --help"\x1b[22m\x1b[m for more information about a command.',
          ].join('\n'),
        ),
      );
    });
  });
}
