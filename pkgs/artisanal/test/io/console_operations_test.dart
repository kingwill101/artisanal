import 'package:artisanal/src/io/component_theme.dart';
import 'package:artisanal/src/io/console_context.dart';
import 'package:artisanal/src/io/console_operations.dart';
import 'package:artisanal/src/io/operation_results.dart';
import 'package:artisanal/src/style/color.dart';
import 'package:artisanal/src/style/style.dart';
import 'package:artisanal/src/terminal/terminal.dart';
import 'package:artisanal/src/tui/bubbles/components/base.dart';
import 'package:artisanal/src/tui/bubbles/spinner.dart';
import 'package:test/test.dart';

final class _OperationHost implements ConsoleOperationHost {
  _OperationHost({required this.interactive, bool supportsAnsi = true})
    : promptTerminal = StringTerminal(ansiSupport: supportsAnsi);

  @override
  final bool interactive;

  @override
  final StringTerminal promptTerminal;

  final output = StringBuffer();

  @override
  ComponentTheme get componentTheme => ComponentTheme.dark;

  @override
  RenderConfig get renderConfig =>
      const RenderConfig(colorProfile: ColorProfile.ascii);

  @override
  Style? getStyle(String name) => null;

  @override
  void write(String text) => output.write(text);

  @override
  void writeln([String line = '']) => output.writeln(line);

  @override
  void newLine([int count = 1]) {
    for (var index = 0; index < count; index++) {
      writeln();
    }
  }
}

void main() {
  group('ConsoleOperations', () {
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
