import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/testing.dart';
import 'package:artisanal_widgets/widgets.dart';
import 'package:test/test.dart';

void main() {
  group('KeymapHubScope + ShortcutSurfaceScope', () {
    test('surface bindings resolve actions and show which-key', () async {
      final hub = tui.KeymapHub();
      final actions = <String>[];

      final tester = WidgetTester();
      addTearDown(tester.dispose);

      await tester.pumpWidget(
        ThemeScope(
          theme: Theme.dark(),
          child: KeymapHubScope(
            hub: hub,
            onAction: (id, surfaceId) {
              actions.add('$surfaceId:$id');
            },
            child: ShortcutSurfaceScope(
              surfaceId: 'session',
              bindings: [
                tui.ShortcutBinding.chord(
                  id: 'sidebar_toggle',
                  leader: 'ctrl+x',
                  key: 'b',
                  description: 'toggle sidebar',
                  group: 'session',
                ),
                tui.ShortcutBinding.chord(
                  id: 'model_list',
                  leader: 'ctrl+x',
                  key: 'm',
                  description: 'models',
                  group: 'session',
                ),
              ],
              child: Column(
                children: [
                  Expanded(child: Text('body')),
                  WhichKeySlot(),
                ],
              ),
            ),
          ),
        ),
        width: 80,
        height: 24,
      );

      expect(hub.surfaceIds, ['session']);
      expect(tester.find.text('which-key'), isFalse);

      // Drive hub as the program interceptor would.
      final prefix = hub.onSend(tui.KeyMsg(tui.Keys.ctrl('x')));
      expect(prefix, isA<tui.KeymapSequencePrefixMsg>());
      tester.sendMsg(prefix!);
      expect(tester.find.text('which-key'), isTrue, reason: tester.view);
      expect(tester.find.text('toggle sidebar'), isTrue);
      expect(tester.find.text('models'), isTrue);

      final action = hub.onSend(tui.KeyMsg(tui.Key.char('b')));
      expect(action, isA<tui.KeymapActionMsg>());
      tester.sendMsg(action!);
      expect(actions, ['session:sidebar_toggle']);
      expect(tester.find.text('which-key'), isFalse);
    });

    test('exclusive dialog surface blocks lower bindings', () async {
      final hub = tui.KeymapHub();
      final actions = <String>[];

      final tester = WidgetTester();
      addTearDown(tester.dispose);

      await tester.pumpWidget(
        ThemeScope(
          theme: Theme.dark(),
          child: KeymapHubScope(
            hub: hub,
            onAction: (id, surfaceId) => actions.add(id),
            child: ShortcutSurfaceScope(
              surfaceId: 'session',
              bindings: [
                tui.ShortcutBinding.single(
                  id: 'command_list',
                  key: 'ctrl+p',
                  description: 'commands',
                ),
              ],
              child: ShortcutSurfaceScope(
                surfaceId: 'dialog',
                exclusive: true,
                bindings: [
                  tui.ShortcutBinding.single(
                    id: 'confirm',
                    key: 'y',
                    description: 'confirm',
                  ),
                ],
                child: Text('dialog'),
              ),
            ),
          ),
        ),
      );

      expect(hub.surfaceIds, ['session', 'dialog']);
      expect(hub.onSend(tui.KeyMsg(tui.Keys.ctrl('p'))), isNull);

      final y = hub.onSend(tui.KeyMsg(tui.Key.char('y')));
      expect(y, isA<tui.KeymapActionMsg>());
      tester.sendMsg(y!);
      expect(actions, ['confirm']);
    });

    test('clearSurfaces removes registered surface', () async {
      final hub = tui.KeymapHub();
      final tester = WidgetTester();
      addTearDown(tester.dispose);

      await tester.pumpWidget(
        ThemeScope(
          theme: Theme.dark(),
          child: KeymapHubScope(
            hub: hub,
            child: ShortcutSurfaceScope(
              surfaceId: 'session',
              bindings: const [],
              child: Text('a'),
            ),
          ),
        ),
      );
      expect(hub.contains('session'), isTrue);

      // App shutdown / route teardown can clear surfaces explicitly.
      // (WidgetTester re-pump does not always unmount the prior element tree.)
      hub.clearSurfaces();
      expect(hub.contains('session'), isFalse);
    });
  });
}
