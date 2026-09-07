import 'package:artisanal/src/io/console_context.dart';
import 'package:artisanal/src/terminal/terminal.dart';
import 'package:test/test.dart';

void main() {
  group('supportsInteractiveConsole', () {
    test('requires both interactivity and ANSI support', () {
      expect(
        supportsInteractiveConsole(
          true,
          () => StringTerminal(ansiSupport: true),
        ),
        isTrue,
      );
      expect(
        supportsInteractiveConsole(
          true,
          () => StringTerminal(ansiSupport: false),
        ),
        isFalse,
      );
      expect(
        supportsInteractiveConsole(
          false,
          () => StringTerminal(ansiSupport: true),
        ),
        isFalse,
      );
    });

    test('does not resolve a terminal for a non-interactive console', () {
      var resolved = false;

      final supported = supportsInteractiveConsole(false, () {
        resolved = true;
        return StringTerminal();
      });

      expect(supported, isFalse);
      expect(resolved, isFalse);
    });
  });
}
