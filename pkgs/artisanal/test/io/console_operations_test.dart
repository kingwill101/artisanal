import 'package:artisanal/src/io/component_theme.dart';
import 'package:artisanal/src/io/console_context.dart';
import 'package:artisanal/src/io/console_operations.dart';
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
}

void main() {
  group('ConsoleOperations', () {
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
