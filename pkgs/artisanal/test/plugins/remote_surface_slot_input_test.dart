import 'package:artisanal/artisanal.dart' as plugins;
import 'package:test/test.dart';

void main() {
  group('RemotePluginSlotInputRouter', () {
    test('hitTest resolves the topmost slot entry in region-local space', () {
      final store = plugins.RemotePluginSurfaceStore();
      store.applyAll([
        const plugins.RemotePluginSurfaceOpen(
          surfaceId: 'panel',
          kind: plugins.RemotePluginSurfaceKind.panel,
          width: 8,
          height: 4,
          slot: 'main',
        ),
        const plugins.RemotePluginSurfaceOpen(
          surfaceId: 'popup',
          kind: plugins.RemotePluginSurfaceKind.popup,
          width: 2,
          height: 1,
          slot: 'main',
        ),
      ]);

      final entries = plugins.resolveRemotePluginSlotEntries(
        store,
        placements: const [
          plugins.RemotePluginSurfacePlacement(
            surfaceId: 'panel',
            x: 20,
            y: 10,
            z: 0,
          ),
          plugins.RemotePluginSurfacePlacement(
            surfaceId: 'popup',
            x: 22,
            y: 11,
            z: 10,
          ),
        ],
      );
      final router = plugins.RemotePluginSlotInputRouter(
        router: plugins.RemotePluginSurfaceInputRouter(
          surfaces: store,
          sendersBySurfaceId: const {},
        ),
        entries: entries,
        originX: 20,
        originY: 10,
      );

      final hit = router.hitTest(2, 1);

      expect(hit, isNotNull);
      expect(hit!.surfaceId, 'popup');
      expect(hit.column, 0);
      expect(hit.row, 0);
      expect(hit.hostColumn, 22);
      expect(hit.hostRow, 11);
    });

    test(
      'sendMouse focuses and dispatches to the locally hit surface',
      () async {
        final store = plugins.RemotePluginSurfaceStore();
        store.applyAll([
          const plugins.RemotePluginSurfaceOpen(
            surfaceId: 'panel',
            kind: plugins.RemotePluginSurfaceKind.panel,
            width: 8,
            height: 4,
            slot: 'main',
          ),
          const plugins.RemotePluginSurfaceOpen(
            surfaceId: 'popup',
            kind: plugins.RemotePluginSurfaceKind.popup,
            width: 2,
            height: 1,
            slot: 'main',
          ),
        ]);

        final panelMessages = <plugins.RemotePluginMessage>[];
        final popupMessages = <plugins.RemotePluginMessage>[];
        final globalRouter = plugins.RemotePluginSurfaceInputRouter(
          surfaces: store,
          sendersBySurfaceId:
              <String, plugins.RemotePluginSurfaceMessageSender>{
                'panel': (message) async => panelMessages.add(message),
                'popup': (message) async => popupMessages.add(message),
              },
        );
        final localRouter = plugins.RemotePluginSlotInputRouter(
          router: globalRouter,
          entries: plugins.resolveRemotePluginSlotEntries(
            store,
            placements: const [
              plugins.RemotePluginSurfacePlacement(
                surfaceId: 'panel',
                x: 20,
                y: 10,
                z: 0,
              ),
              plugins.RemotePluginSurfacePlacement(
                surfaceId: 'popup',
                x: 22,
                y: 11,
                z: 10,
              ),
            ],
          ),
          originX: 20,
          originY: 10,
        );

        final hit = await localRouter.sendMouse(
          action: plugins.RemotePluginMouseAction.press,
          button: plugins.RemotePluginMouseButton.left,
          column: 2,
          row: 1,
        );

        expect(hit, isNotNull);
        expect(globalRouter.focusedSurfaceId, 'popup');
        expect(panelMessages, isEmpty);
        expect(popupMessages, <Matcher>[
          isA<plugins.RemotePluginFocusInput>(),
          isA<plugins.RemotePluginMouseInput>()
              .having((message) => message.column, 'column', 0)
              .having((message) => message.row, 'row', 0),
        ]);
      },
    );

    test(
      'sendKey targets the focused slot surface through the shared router',
      () async {
        final store = plugins.RemotePluginSurfaceStore();
        store.apply(
          const plugins.RemotePluginSurfaceOpen(
            surfaceId: 'panel',
            kind: plugins.RemotePluginSurfaceKind.panel,
            width: 8,
            height: 4,
            slot: 'main',
          ),
        );

        final messages = <plugins.RemotePluginMessage>[];
        final globalRouter = plugins.RemotePluginSurfaceInputRouter(
          surfaces: store,
          sendersBySurfaceId:
              <String, plugins.RemotePluginSurfaceMessageSender>{
                'panel': (message) async => messages.add(message),
              },
        );
        final localRouter = plugins.RemotePluginSlotInputRouter(
          router: globalRouter,
          entries: plugins.resolveRemotePluginSlotEntries(
            store,
            placements: const [
              plugins.RemotePluginSurfacePlacement(
                surfaceId: 'panel',
                x: 3,
                y: 4,
              ),
            ],
          ),
          originX: 3,
          originY: 4,
        );

        await localRouter.focusTopmost();
        await localRouter.sendKey(key: 'x', ctrl: true, code: 'KeyX');

        expect(messages, <Matcher>[
          isA<plugins.RemotePluginFocusInput>(),
          isA<plugins.RemotePluginKeyInput>()
              .having((message) => message.key, 'key', 'x')
              .having((message) => message.ctrl, 'ctrl', isTrue)
              .having((message) => message.code, 'code', 'KeyX'),
        ]);
      },
    );
  });
}
