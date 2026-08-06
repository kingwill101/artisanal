/// Regression: opening/closing the help sheet must not remount Navigator.
library;

import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/testing.dart';
import 'package:artisanal_widgets/widgets.dart';
import 'package:test/test.dart';

void main() {
  test('help open/close preserves current navigator route', () async {
    final hub = tui.KeymapHub();
    final tester = WidgetTester();
    addTearDown(tester.dispose);

    await tester.pumpWidget(
      ThemeScope(
        theme: Theme.dark(),
        child: KeymapHubScope(
          hub: hub,
          child: _NavHost(hub: hub),
        ),
      ),
      width: 90,
      height: 28,
    );

    expect(tester.find.text('HOME_ROUTE'), isTrue);
    expect(hub.surfaceIds, contains('home'));

    // Go to session.
    final go = hub.onSend(tui.KeyMsg(tui.Key.char('s')));
    expect(go, isA<tui.KeymapActionMsg>());
    tester.sendMsg(go!);
    expect(tester.find.text('SESSION_ROUTE'), isTrue, reason: tester.view);
    expect(hub.top?.id, 'session');

    // Open help sheet (?).
    final help = hub.onSend(tui.KeyMsg(tui.Key.char('?')));
    expect(help, isA<tui.KeymapActionMsg>());
    tester.sendMsg(help!);
    expect(tester.find.text('Shortcuts'), isTrue, reason: tester.view);
    // Session must still be under the overlay.
    expect(tester.find.text('SESSION_ROUTE'), isTrue, reason: tester.view);

    // Close help.
    tester.sendMsg(tui.KeyMsg(tui.Keys.escape));
    expect(tester.find.text('Shortcuts'), isFalse, reason: tester.view);
    // Critical: still on session, not reset to home.
    expect(tester.find.text('SESSION_ROUTE'), isTrue, reason: tester.view);
    expect(tester.find.text('HOME_ROUTE'), isFalse, reason: tester.view);
    expect(hub.top?.id, 'session');
  });

  test('re-registering lower surface does not steal top', () {
    final hub = tui.KeymapHub();
    hub.push(
      tui.ShortcutSurface(
        id: 'home',
        bindings: [tui.ShortcutBinding.help()],
      ),
    );
    hub.push(
      tui.ShortcutSurface(
        id: 'session',
        bindings: [tui.ShortcutBinding.help()],
      ),
    );
    expect(hub.surfaceIds, ['home', 'session']);

    // In-place update of home (as Scope.replace would).
    hub.replace(
      tui.ShortcutSurface(
        id: 'home',
        bindings: [
          tui.ShortcutBinding.single(id: 'x', key: 'x', description: 'x'),
        ],
      ),
    );
    expect(hub.surfaceIds, ['home', 'session']);
    expect(hub.top?.id, 'session');

    // activate moves without dropping others.
    hub.activate('home');
    expect(hub.surfaceIds, ['session', 'home']);
    hub.activate('session');
    expect(hub.surfaceIds, ['home', 'session']);
    expect(hub.top?.id, 'session');
  });
}

class _NavHost extends StatefulWidget {
  _NavHost({required this.hub});
  final tui.KeymapHub hub;

  @override
  State createState() => _NavHostState();
}

class _NavHostState extends State<_NavHost> {
  NavigatorState? _nav;

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg is tui.KeymapActionMsg && msg.id == 'go_session') {
      _nav?.pushNamed('/session');
      return tui.Cmd.none();
    }
    return super.handleUpdate(msg);
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      initialRoute: '/',
      routes: {
        '/': (ctx) {
          _nav ??= Navigator.of(ctx);
          return ShortcutSurfaceScope(
            surfaceId: 'home',
            bindings: [
              tui.ShortcutBinding.single(
                id: 'go_session',
                key: 's',
                description: 'go session',
              ),
              tui.ShortcutBinding.help(),
            ],
            child: Text('HOME_ROUTE'),
          );
        },
        '/session': (ctx) => ShortcutSurfaceScope(
          surfaceId: 'session',
          bindings: [
            tui.ShortcutBinding.help(),
            tui.ShortcutBinding.chord(
              id: 'sidebar',
              leader: 'ctrl+x',
              key: 'b',
              description: 'sidebar',
            ),
          ],
          child: Text('SESSION_ROUTE'),
        ),
      },
    );
  }
}
