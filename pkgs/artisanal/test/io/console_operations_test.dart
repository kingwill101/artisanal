import 'package:artisanal/src/io/component_theme.dart';
import 'package:artisanal/src/io/console_context.dart';
import 'package:artisanal/src/io/console_operations.dart';
import 'package:artisanal/src/io/console_prompts.dart';
import 'package:artisanal/src/io/operation_results.dart';
import 'package:artisanal/src/style/color.dart';
import 'package:artisanal/src/style/style.dart';
import 'package:artisanal/src/terminal/terminal.dart';
import 'package:artisanal/src/tui/bubbles/components/base.dart';
import 'package:artisanal/src/tui/bubbles/spinner.dart';
import 'package:test/test.dart';

final class _OperationHost implements ConsolePromptHost {
  _OperationHost({
    required this.interactive,
    bool supportsAnsi = true,
    Iterable<String?> input = const [],
  }) : promptTerminal = StringTerminal(ansiSupport: supportsAnsi),
       _input = input.iterator;

  @override
  final bool interactive;

  @override
  final StringTerminal promptTerminal;

  final output = StringBuffer();
  final errors = StringBuffer();
  final Iterator<String?> _input;

  @override
  ComponentTheme get componentTheme => ComponentTheme.dark;

  @override
  RenderConfig get renderConfig =>
      const RenderConfig(colorProfile: ColorProfile.ascii);

  @override
  Style? getStyle(String name) => null;

  @override
  String? readConsoleLine() => _input.moveNext() ? _input.current : null;

  @override
  String? readConfiguredSecret(String prompt, {String? fallback}) => null;

  @override
  void write(String text) => output.write(text);

  @override
  void writeln([String line = '']) => output.writeln(line);

  @override
  void writelnErr([String line = '']) => errors.writeln(line);

  @override
  void newLine([int count = 1]) {
    for (var index = 0; index < count; index++) {
      writeln();
    }
  }
}

void main() {
  group('ConsolePrompts', () {
    test('uses non-interactive numeric defaults', () async {
      final host = _OperationHost(interactive: false);

      final result = await ConsolePrompts(
        host,
      ).number('Port', defaultValue: 8080, min: 1);

      expect(result, 8080);
      expect(host.promptTerminal.operations, isEmpty);
    });

    test('uses a non-interactive secret fallback', () async {
      final host = _OperationHost(interactive: false);

      final result = await ConsolePrompts(
        host,
      ).secret('Token', fallback: 'configured');

      expect(result, 'configured');
      expect(host.promptTerminal.operations, isEmpty);
    });

    test('validates text through the shared input host', () {
      final host = _OperationHost(interactive: true, input: ['bad', 'good']);

      final result = ConsolePrompts(
        host,
      ).ask('Value', validator: (value) => value == 'good' ? null : 'invalid');

      expect(result, 'good');
      expect(host.errors.toString(), contains('Error: invalid'));
    });

    test('parses numbered multi-select choices', () {
      final host = _OperationHost(interactive: true, input: ['0, 2']);

      final result = ConsolePrompts(
        host,
      ).choice('Select', choices: ['zero', 'one', 'two'], multiSelect: true);

      expect(result, ['zero', 'two']);
    });
  });

  group('ConsoleOperations', () {
    test('progress iteration renders through the operation terminal', () {
      final host = _OperationHost(interactive: true);

      final values = ConsoleOperations(
        host,
      ).progressIterate([1, 2], clearOnDone: true).toList();

      expect(values, [1, 2]);
      expect(host.promptTerminal.operations, contains('hideCursor'));
      expect(host.promptTerminal.operations, contains('clearLine'));
      expect(host.promptTerminal.operations.last, 'showCursor');
    });

    test('countdown uses the plain fallback and invokes completion', () async {
      final host = _OperationHost(interactive: false);
      var completed = false;

      final result = await ConsoleOperations(host).countdown(
        'Starting in',
        seconds: 0,
        onComplete: () {
          completed = true;
        },
      );

      expect(result, isTrue);
      expect(completed, isTrue);
      expect(host.output.toString(), contains('Starting in 0 seconds...'));
      expect(host.promptTerminal.operations, isEmpty);
    });

    test('steps account for unrun plain operations as skipped', () async {
      final host = _OperationHost(interactive: false);
      var skippedOperationRan = false;

      final result = await ConsoleOperations(host).steps(
        title: 'Deploy',
        steps: [
          ('Build', () async {}),
          ('Test', () async => throw StateError('failed')),
          (
            'Publish',
            () async {
              skippedOperationRan = true;
            },
          ),
        ],
      );

      expect(result.completed, ['Build']);
      expect(result.failed.single.$1, 'Test');
      expect(result.skipped, ['Publish']);
      expect(skippedOperationRan, isFalse);
      expect(host.output.toString(), contains('[3/3] Publish'));
      expect(host.output.toString(), contains('1 failed, 1 skipped'));
    });

    test('steps restore the cursor after an interactive failure', () async {
      final host = _OperationHost(interactive: true);

      final result = await ConsoleOperations(
        host,
      ).steps(steps: [('Build', () async => throw StateError('failed'))]);

      expect(result.failed.single.$1, 'Build');
      expect(host.promptTerminal.output, contains('✗'));
      expect(host.promptTerminal.operations.last, 'showCursor');
    });

    test('task groups preserve failures and skipped operations', () async {
      final host = _OperationHost(interactive: false);
      var skippedOperationRan = false;

      final result = await ConsoleOperations(host).taskGroup(
        title: 'Deploy',
        tasks: [
          ('Build', () async {}),
          ('Test', () async => throw StateError('failed')),
          (
            'Publish',
            () async {
              skippedOperationRan = true;
            },
          ),
        ],
      );

      expect(result.completed, ['Build']);
      expect(result.failed.single.$1, 'Test');
      expect(result.skipped, ['Publish']);
      expect(skippedOperationRan, isFalse);
      expect(host.output.toString(), contains('1, failed 1, skipped 1'));
    });

    test('renders a plain task through the shared operation host', () async {
      final host = _OperationHost(interactive: false);

      final result = await ConsoleOperations(
        host,
      ).task('Build', run: () async => TaskResult.success);

      expect(result, TaskResult.success);
      expect(host.output.toString(), contains('Build'));
      expect(host.output.toString(), contains('DONE'));
    });

    test('restores the cursor when an interactive task fails', () async {
      final host = _OperationHost(interactive: true);

      await expectLater(
        ConsoleOperations(
          host,
        ).task('Build', run: () async => throw StateError('failed')),
        throwsStateError,
      );

      expect(host.promptTerminal.output, contains('FAIL'));
      expect(host.promptTerminal.operations.last, 'showCursor');
    });

    test('uses plain output when the host is non-interactive', () async {
      final host = _OperationHost(interactive: false);

      final result = await ConsoleOperations(
        host,
      ).spin('Loading', run: () async => 42, doneMessage: 'Loaded');

      expect(result, 42);
      expect(host.output.toString(), contains('Loading Loaded'));
      expect(host.promptTerminal.operations, isEmpty);
    });

    test('uses one inline lifecycle for an interactive spinner', () async {
      final host = _OperationHost(interactive: true);

      await ConsoleOperations(host).spin(
        'Loading',
        run: () async => 42,
        spinner: Spinners.line,
        doneMessage: 'Loaded',
      );

      expect(host.promptTerminal.output, contains('Loaded'));
      expect(host.promptTerminal.operations, contains('hideCursor'));
      expect(host.promptTerminal.operations.last, 'showCursor');
      expect(host.output.toString(), isEmpty);
    });
  });
}
