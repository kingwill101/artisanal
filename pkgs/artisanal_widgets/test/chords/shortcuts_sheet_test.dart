import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/testing.dart';
import 'package:artisanal_widgets/widgets.dart';
import 'package:test/test.dart';

void main() {
  group('keyMapFromShortcutBindings', () {
    test('groups by binding group and formats sequences', () {
      final map = tui.keyMapFromShortcutBindings([
        tui.ShortcutBinding.chord(
          id: 'sidebar_toggle',
          leader: 'ctrl+x',
          key: 'b',
          description: 'toggle sidebar',
          group: 'session',
        ),
        tui.ShortcutBinding.single(
          id: 'command_list',
          key: 'ctrl+p',
          description: 'commands',
          group: 'Preferences',
        ),
        tui.ShortcutBinding.help(),
      ]);

      expect(map.shortHelp, isNotEmpty);
      expect(
        map.shortHelp.any((b) => b.help.key.contains('ctrl+x')),
        isTrue,
      );
      expect(map.fullHelp.length, greaterThanOrEqualTo(2));
    });
  });

  group('KeymapHub.activeShortcuts', () {
    test('top only by default; includeReachable merges lower', () {
      final hub = tui.KeymapHub();
      hub.push(
        tui.ShortcutSurface(
          id: 'session',
          bindings: [
            tui.ShortcutBinding.single(id: 'command_list', key: 'ctrl+p'),
          ],
        ),
      );
      hub.push(
        tui.ShortcutSurface(
          id: 'overlay',
          exclusive: false,
          bindings: [
            tui.ShortcutBinding.single(id: 'close', key: 'esc'),
          ],
        ),
      );

      expect(hub.activeShortcuts().map((b) => b.id), ['close']);
      expect(
        hub.activeShortcuts(includeReachable: true).map((b) => b.id),
        containsAll(['close', 'command_list']),
      );
    });

    test('exclusive top stops reachable walk', () {
      final hub = tui.KeymapHub();
      hub.push(
        tui.ShortcutSurface(
          id: 'session',
          bindings: [
            tui.ShortcutBinding.single(id: 'command_list', key: 'ctrl+p'),
          ],
        ),
      );
      hub.push(
        tui.ShortcutSurface(
          id: 'dialog',
          exclusive: true,
          bindings: [
            tui.ShortcutBinding.single(id: 'confirm', key: 'y'),
          ],
        ),
      );

      expect(
        hub.activeShortcuts(includeReachable: true).map((b) => b.id),
        ['confirm'],
      );
    });
  });

  group('ShortcutsSheet + help action', () {
    test('? opens sheet listing surface bindings', () async {
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
              bindings: [
                tui.ShortcutBinding.chord(
                  id: 'sidebar_toggle',
                  leader: 'ctrl+x',
                  key: 'b',
                  description: 'toggle sidebar',
                  group: 'session',
                ),
                tui.ShortcutBinding.help(),
              ],
              child: Text('body'),
            ),
          ),
        ),
        width: 80,
        height: 30,
      );

      expect(tester.find.text('Shortcuts'), isFalse);

      final help = hub.onSend(tui.KeyMsg(tui.Key.char('?')));
      expect(help, isA<tui.KeymapActionMsg>());
      expect((help as tui.KeymapActionMsg).id, tui.shortcutHelpActionId);
      tester.sendMsg(help);

      expect(tester.find.text('Shortcuts'), isTrue, reason: tester.view);
      expect(tester.find.text('toggle sidebar'), isTrue, reason: tester.view);
      expect(tester.view.contains('ctrl+x b') || tester.view.contains('ctrl+x'),
          isTrue,
          reason: tester.view);

      // Esc closes.
      tester.sendMsg(tui.KeyMsg(tui.Keys.escape));
      expect(tester.find.text('Shortcuts'), isFalse, reason: tester.view);
    });

    test('ShortcutsSheet.forHub renders empty state', () async {
      final hub = tui.KeymapHub();
      final tester = WidgetTester();
      addTearDown(tester.dispose);

      await tester.pumpWidget(
        ThemeScope(
          theme: Theme.dark(),
          child: ShortcutsSheet.forHub(hub),
        ),
        width: 60,
        height: 16,
      );

      expect(tester.find.text('No shortcuts for this view'), isTrue);
    });
  });
}
