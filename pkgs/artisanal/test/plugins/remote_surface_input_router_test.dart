import 'package:artisanal/artisanal.dart' as plugins;
import 'package:artisanal/tui.dart' as runtime;
import 'package:test/test.dart';

void main() {
  group('RemotePluginSurfaceInputRouter', () {
    test(
      'focusSurface blurs the previous surface before focusing the next',
      () async {
        final store = plugins.RemotePluginSurfaceStore();
        store.apply(
          const plugins.RemotePluginSurfaceOpen(
            surfaceId: 'overview.panel',
            kind: plugins.RemotePluginSurfaceKind.panel,
            width: 10,
            height: 3,
          ),
        );
        store.apply(
          const plugins.RemotePluginSurfaceOpen(
            surfaceId: 'activity.panel',
            kind: plugins.RemotePluginSurfaceKind.panel,
            width: 10,
            height: 3,
          ),
        );

        final overviewMessages = <plugins.RemotePluginMessage>[];
        final activityMessages = <plugins.RemotePluginMessage>[];
        final router = plugins.RemotePluginSurfaceInputRouter(
          surfaces: store,
          sendersBySurfaceId:
              <String, plugins.RemotePluginSurfaceMessageSender>{
                'overview.panel': (message) async =>
                    overviewMessages.add(message),
                'activity.panel': (message) async =>
                    activityMessages.add(message),
              },
        );

        await router.focusSurface('overview.panel');
        await router.focusSurface('activity.panel');

        expect(router.focusedSurfaceId, 'activity.panel');
        expect(overviewMessages, <Matcher>[
          isA<plugins.RemotePluginFocusInput>(),
          isA<plugins.RemotePluginBlurInput>(),
        ]);
        expect(activityMessages, <Matcher>[
          isA<plugins.RemotePluginFocusInput>(),
        ]);
      },
    );

    test(
      'sendMouse routes to the topmost hit surface with local coordinates',
      () async {
        final store = plugins.RemotePluginSurfaceStore();
        store.apply(
          const plugins.RemotePluginSurfaceOpen(
            surfaceId: 'panel',
            kind: plugins.RemotePluginSurfaceKind.panel,
            width: 8,
            height: 4,
          ),
        );
        store.apply(
          const plugins.RemotePluginSurfaceOpen(
            surfaceId: 'popup',
            kind: plugins.RemotePluginSurfaceKind.popup,
            width: 2,
            height: 1,
            parentSurfaceId: 'panel',
            anchor: plugins.RemotePluginAnchorRect(
              column: 2,
              row: 1,
              width: 2,
              height: 1,
            ),
          ),
        );

        final panelMessages = <plugins.RemotePluginMessage>[];
        final popupMessages = <plugins.RemotePluginMessage>[];
        final router = plugins.RemotePluginSurfaceInputRouter(
          surfaces: store,
          sendersBySurfaceId:
              <String, plugins.RemotePluginSurfaceMessageSender>{
                'panel': (message) async => panelMessages.add(message),
                'popup': (message) async => popupMessages.add(message),
              },
          placements: const <plugins.RemotePluginSurfacePlacement>[
            plugins.RemotePluginSurfacePlacement(
              surfaceId: 'panel',
              x: 10,
              y: 5,
              z: 4,
            ),
          ],
        );

        final hit = await router.sendMouse(
          action: plugins.RemotePluginMouseAction.press,
          button: plugins.RemotePluginMouseButton.left,
          column: 12,
          row: 6,
        );

        expect(hit, isNotNull);
        expect(hit!.surface.surfaceId, 'popup');
        expect(hit.column, 0);
        expect(hit.row, 0);
        expect(router.focusedSurfaceId, 'popup');
        expect(popupMessages, <Matcher>[
          isA<plugins.RemotePluginFocusInput>(),
          isA<plugins.RemotePluginMouseInput>()
              .having((message) => message.column, 'column', 0)
              .having((message) => message.row, 'row', 0),
        ]);
        expect(panelMessages, isEmpty);
      },
    );

    test('sendKey delivers to the currently focused surface only', () async {
      final store = plugins.RemotePluginSurfaceStore();
      store.apply(
        const plugins.RemotePluginSurfaceOpen(
          surfaceId: 'panel',
          kind: plugins.RemotePluginSurfaceKind.panel,
          width: 8,
          height: 4,
        ),
      );

      final panelMessages = <plugins.RemotePluginMessage>[];
      final router = plugins.RemotePluginSurfaceInputRouter(
        surfaces: store,
        sendersBySurfaceId: <String, plugins.RemotePluginSurfaceMessageSender>{
          'panel': (message) async => panelMessages.add(message),
        },
      );

      await router.sendKey(key: 'a');
      await router.focusSurface('panel');
      await router.sendKey(key: 'a', ctrl: true, code: 'KeyA');

      expect(panelMessages, <Matcher>[
        isA<plugins.RemotePluginFocusInput>(),
        isA<plugins.RemotePluginKeyInput>()
            .having((message) => message.key, 'key', 'a')
            .having((message) => message.ctrl, 'ctrl', isTrue)
            .having((message) => message.code, 'code', 'KeyA'),
      ]);
    });

    test('sendTuiMouse bridges supported runtime mouse events', () async {
      final store = plugins.RemotePluginSurfaceStore();
      store.apply(
        const plugins.RemotePluginSurfaceOpen(
          surfaceId: 'panel',
          kind: plugins.RemotePluginSurfaceKind.panel,
          width: 8,
          height: 4,
        ),
      );

      final panelMessages = <plugins.RemotePluginMessage>[];
      final router = plugins.RemotePluginSurfaceInputRouter(
        surfaces: store,
        sendersBySurfaceId: <String, plugins.RemotePluginSurfaceMessageSender>{
          'panel': (message) async => panelMessages.add(message),
        },
        placements: const <plugins.RemotePluginSurfacePlacement>[
          plugins.RemotePluginSurfacePlacement(surfaceId: 'panel', x: 4, y: 2),
        ],
      );

      final hit = await router.sendTuiMouse(
        const runtime.MouseMsg(
          action: runtime.MouseAction.press,
          button: runtime.MouseButton.left,
          x: 5,
          y: 3,
          ctrl: true,
        ),
      );

      expect(hit, isNotNull);
      expect(hit!.surface.surfaceId, 'panel');
      expect(panelMessages, <Matcher>[
        isA<plugins.RemotePluginFocusInput>(),
        isA<plugins.RemotePluginMouseInput>()
            .having((message) => message.column, 'column', 1)
            .having((message) => message.row, 'row', 1)
            .having((message) => message.ctrl, 'ctrl', isTrue),
      ]);
    });

    test('sendTuiMouse ignores unsupported runtime mouse buttons', () async {
      final store = plugins.RemotePluginSurfaceStore();
      store.apply(
        const plugins.RemotePluginSurfaceOpen(
          surfaceId: 'panel',
          kind: plugins.RemotePluginSurfaceKind.panel,
          width: 8,
          height: 4,
        ),
      );

      final panelMessages = <plugins.RemotePluginMessage>[];
      final router = plugins.RemotePluginSurfaceInputRouter(
        surfaces: store,
        sendersBySurfaceId: <String, plugins.RemotePluginSurfaceMessageSender>{
          'panel': (message) async => panelMessages.add(message),
        },
      );

      final hit = await router.sendTuiMouse(
        const runtime.MouseMsg(
          action: runtime.MouseAction.wheel,
          button: runtime.MouseButton.wheelLeft,
          x: 0,
          y: 0,
        ),
      );

      expect(hit, isNull);
      expect(panelMessages, isEmpty);
    });
  });
}
