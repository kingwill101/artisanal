import 'package:artisanal/tui.dart';
import 'package:test/test.dart';

void main() {
  group('ProgramDevToolsController', () {
    test('uses F12 as the default toggle and consumes it', () {
      final controller = ProgramDevToolsController(ProgramDiagnosticsOptions());
      controller.handle(const WindowSizeMsg(80, 24));

      expect(controller.handle(const KeyMsg(Key(KeyType.f12))), isTrue);

      final rendered = controller.compose('application');
      expect(rendered.toString(), contains('Artisanal DevTools'));
      expect(rendered.toString(), contains('application'));
    });

    test('supports a custom toggle binding', () {
      final controller = ProgramDevToolsController(
        ProgramDiagnosticsOptions(
          toggleBinding: KeyBinding(keys: const ['ctrl+d']),
        ),
      );
      controller.handle(const WindowSizeMsg(80, 24));

      expect(
        controller.handle(
          const KeyMsg(Key(KeyType.runes, runes: [0x64], ctrl: true)),
        ),
        isTrue,
      );
      expect(controller.compose('content').toString(), contains('[metrics]'));
    });

    test('uses tabs and consumes scrolling while visible', () {
      final controller = ProgramDevToolsController(
        ProgramDiagnosticsOptions(
          initiallyVisible: true,
          keyboardNavigation: true,
        ),
      );
      controller.handle(const WindowSizeMsg(80, 24));

      expect(controller.handle(const KeyMsg(Key(KeyType.tab))), isTrue);
      expect(controller.compose('content').toString(), contains('[messages]'));
      expect(controller.handle(const KeyMsg(Key(KeyType.pageDown))), isTrue);
    });

    test('does not consume application keyboard input by default', () {
      final controller = ProgramDevToolsController(
        ProgramDiagnosticsOptions(initiallyVisible: true),
      );
      controller.handle(const WindowSizeMsg(80, 24));

      for (final key in [
        const Key(KeyType.tab),
        const Key(KeyType.tab, shift: true),
        const Key(KeyType.up),
        const Key(KeyType.down),
        const Key(KeyType.left),
        const Key(KeyType.right),
        const Key(KeyType.pageUp),
        const Key(KeyType.pageDown),
        const Key(KeyType.home),
        const Key(KeyType.end),
      ]) {
        expect(
          controller.handle(KeyMsg(key)),
          isFalse,
          reason: '$key should remain available to the application',
        );
      }
      expect(
        controller.handle(const KeyMsg(Key(KeyType.runes, runes: [0x61]))),
        isFalse,
      );
    });

    test('opt-in keyboard navigation consumes overlay controls', () {
      final controller = ProgramDevToolsController(
        ProgramDiagnosticsOptions(
          initiallyVisible: true,
          keyboardNavigation: true,
        ),
      );
      controller.handle(const WindowSizeMsg(80, 24));

      expect(controller.handle(const KeyMsg(Key(KeyType.tab))), isTrue);
      expect(controller.compose('content').toString(), contains('[messages]'));
      expect(controller.handle(const KeyMsg(Key(KeyType.pageDown))), isTrue);
    });

    test('shared custom metrics appear in the overlay', () {
      addTearDown(ProgramDiagnosticsMetrics.clear);
      final controller = ProgramDevToolsController(
        ProgramDiagnosticsOptions(initiallyVisible: true),
      );
      controller.handle(const WindowSizeMsg(80, 24));

      ProgramDiagnosticsMetrics.setMetric('Jobs', 7);
      controller.updateCustomMetrics(ProgramDiagnosticsMetrics.values);

      expect(controller.compose('content').toString(), contains('Jobs'));
      expect(controller.compose('content').toString(), contains('7'));
    });
  });
}
