library;

import 'package:artisanal/plugins.dart' as plugins;
import 'package:artisanal/tui.dart' show Key, KeyMsg, KeyType;
import 'package:artisanal_widgets/testing.dart';
import 'package:artisanal_widgets/widgets.dart' as w;
import 'package:test/test.dart';

enum _DemoSlot { main }

void main() {
  group('SlotRegion', () {
    test(
      'renders remote slot surfaces with the default surface view',
      () async {
        final tester = WidgetTester();
        addTearDown(() => tester.dispose());

        final store = plugins.RemotePluginSurfaceStore();
        store.apply(
          const plugins.RemotePluginSurfaceOpen(
            surfaceId: 'activity',
            kind: plugins.RemotePluginSurfaceKind.panel,
            width: 2,
            height: 1,
            slot: 'main',
          ),
        );
        store.apply(
          const plugins.RemotePluginFrame(
            surfaceId: 'activity',
            width: 2,
            height: 1,
            cells: <plugins.RemotePluginFrameCell>[
              plugins.RemotePluginFrameCell(column: 0, row: 0, symbol: 'H'),
              plugins.RemotePluginFrameCell(column: 1, row: 0, symbol: 'I'),
            ],
          ),
        );

        final entries = plugins.resolveRemotePluginSlotEntries(store);

        await tester.pumpWidget(
          w.SlotScope<String, String>(
            registry: w.SlotRegistry<String, String>(),
            child: w.SlotRegion<String, String>(
              slot: 'main',
              data: 'unused',
              remoteEntries: entries,
            ),
          ),
        );

        expect(tester.find.text('HI'), isTrue);
      },
    );

    test('composes local slot content with remote overlays', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final store = plugins.RemotePluginSurfaceStore();
      store.apply(
        const plugins.RemotePluginSurfaceOpen(
          surfaceId: 'status',
          kind: plugins.RemotePluginSurfaceKind.popup,
          width: 4,
          height: 1,
          slot: 'main',
        ),
      );
      store.apply(
        const plugins.RemotePluginFrame(
          surfaceId: 'status',
          width: 4,
          height: 1,
          cells: <plugins.RemotePluginFrameCell>[
            plugins.RemotePluginFrameCell(column: 0, row: 0, symbol: 'R'),
            plugins.RemotePluginFrameCell(column: 1, row: 0, symbol: 'E'),
            plugins.RemotePluginFrameCell(column: 2, row: 0, symbol: 'M'),
            plugins.RemotePluginFrameCell(column: 3, row: 0, symbol: 'O'),
          ],
        ),
      );

      final registry = w.SlotRegistry<String, String>();
      registry.register(
        pluginId: 'shell',
        slot: 'main',
        builder: (_, data) => w.Text('local:$data'),
      );

      final entries = plugins.resolveRemotePluginSlotEntries(
        store,
        placements: const [
          plugins.RemotePluginSurfacePlacement(surfaceId: 'status', x: 0, y: 1),
        ],
      );

      await tester.pumpWidget(
        w.SlotScope<String, String>(
          registry: registry,
          child: w.SlotRegion<String, String>(
            slot: 'main',
            data: 'demo',
            remoteEntries: entries,
          ),
        ),
      );

      expect(tester.find.text('local:demo'), isTrue);
      expect(tester.find.text('REMO'), isTrue);
    });

    test(
      'matches remote entries through explicit remoteSlot mapping',
      () async {
        final tester = WidgetTester();
        addTearDown(() => tester.dispose());

        final store = plugins.RemotePluginSurfaceStore();
        store.apply(
          const plugins.RemotePluginSurfaceOpen(
            surfaceId: 'inspector',
            kind: plugins.RemotePluginSurfaceKind.panel,
            width: 3,
            height: 1,
            slot: 'main',
          ),
        );
        store.apply(
          const plugins.RemotePluginFrame(
            surfaceId: 'inspector',
            width: 3,
            height: 1,
            cells: <plugins.RemotePluginFrameCell>[
              plugins.RemotePluginFrameCell(column: 0, row: 0, symbol: 'M'),
              plugins.RemotePluginFrameCell(column: 1, row: 0, symbol: 'A'),
              plugins.RemotePluginFrameCell(column: 2, row: 0, symbol: 'P'),
            ],
          ),
        );

        await tester.pumpWidget(
          w.SlotScope<_DemoSlot, String>(
            registry: w.SlotRegistry<_DemoSlot, String>(),
            child: w.SlotRegion<_DemoSlot, String>(
              slot: _DemoSlot.main,
              remoteSlot: 'main',
              data: 'unused',
              remoteEntries: plugins.resolveRemotePluginSlotEntries(store),
            ),
          ),
        );

        expect(tester.find.text('MAP'), isTrue);
      },
    );

    test('allows custom remote entry widgets', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final store = plugins.RemotePluginSurfaceStore();
      store.apply(
        const plugins.RemotePluginSurfaceOpen(
          surfaceId: 'alerts',
          kind: plugins.RemotePluginSurfaceKind.overlay,
          width: 5,
          height: 1,
          slot: 'main',
        ),
      );

      await tester.pumpWidget(
        w.SlotScope<String, String>(
          registry: w.SlotRegistry<String, String>(),
          child: w.SlotRegion<String, String>(
            slot: 'main',
            data: 'unused',
            remoteEntries: plugins.resolveRemotePluginSlotEntries(store),
            remoteEntryBuilder: (_, entry) =>
                w.Text('id:${entry.surfaceId.substring(0, 2)}'),
          ),
        ),
      );

      expect(tester.find.text('id:al'), isTrue);
    });

    test(
      'InteractiveSlotRegion forwards mouse and key input to remote surfaces',
      () async {
        final tester = WidgetTester();
        addTearDown(() => tester.dispose());

        final store = plugins.RemotePluginSurfaceStore();
        store.apply(
          const plugins.RemotePluginSurfaceOpen(
            surfaceId: 'panel',
            kind: plugins.RemotePluginSurfaceKind.panel,
            width: 1,
            height: 1,
            slot: 'main',
          ),
        );
        store.apply(
          const plugins.RemotePluginFrame(
            surfaceId: 'panel',
            width: 1,
            height: 1,
            cells: <plugins.RemotePluginFrameCell>[
              plugins.RemotePluginFrameCell(column: 0, row: 0, symbol: 'A'),
            ],
          ),
        );

        final messages = <plugins.RemotePluginMessage>[];
        final entries = plugins.resolveRemotePluginSlotEntries(
          store,
          placements: const [
            plugins.RemotePluginSurfacePlacement(
              surfaceId: 'panel',
              x: 0,
              y: 0,
            ),
          ],
        );
        final inputRouter = plugins.RemotePluginSlotInputRouter(
          router: plugins.RemotePluginSurfaceInputRouter(
            surfaces: store,
            sendersBySurfaceId:
                <String, plugins.RemotePluginSurfaceMessageSender>{
                  'panel': (message) async => messages.add(message),
                },
          ),
          entries: entries,
        );

        await tester.pumpWidget(
          w.SlotScope<String, String>(
            registry: w.SlotRegistry<String, String>(),
            child: w.InteractiveSlotRegion<String, String>(
              slot: 'main',
              data: 'unused',
              remoteEntries: entries,
              remoteInputRouter: inputRouter,
            ),
          ),
        );

        tester.tapAt(0, 0);
        tester.sendKey('x');

        expect(messages, <Matcher>[
          isA<plugins.RemotePluginFocusInput>(),
          isA<plugins.RemotePluginMouseInput>()
              .having((message) => message.column, 'column', 0)
              .having((message) => message.row, 'row', 0),
          isA<plugins.RemotePluginKeyInput>()
              .having((message) => message.key, 'key', 'x')
              .having((message) => message.code, 'code', 'KeyX'),
        ]);
      },
    );

    test(
      'InteractiveSlotRegion forwards function keys and modifiers',
      () async {
        final tester = WidgetTester();
        addTearDown(() => tester.dispose());

        final store = plugins.RemotePluginSurfaceStore();
        store.apply(
          const plugins.RemotePluginSurfaceOpen(
            surfaceId: 'panel',
            kind: plugins.RemotePluginSurfaceKind.panel,
            width: 1,
            height: 1,
            slot: 'main',
          ),
        );
        store.apply(
          const plugins.RemotePluginFrame(
            surfaceId: 'panel',
            width: 1,
            height: 1,
            cells: <plugins.RemotePluginFrameCell>[
              plugins.RemotePluginFrameCell(column: 0, row: 0, symbol: 'A'),
            ],
          ),
        );

        final messages = <plugins.RemotePluginMessage>[];
        final entries = plugins.resolveRemotePluginSlotEntries(
          store,
          placements: const [
            plugins.RemotePluginSurfacePlacement(
              surfaceId: 'panel',
              x: 0,
              y: 0,
            ),
          ],
        );
        final inputRouter = plugins.RemotePluginSlotInputRouter(
          router: plugins.RemotePluginSurfaceInputRouter(
            surfaces: store,
            sendersBySurfaceId:
                <String, plugins.RemotePluginSurfaceMessageSender>{
                  'panel': (message) async => messages.add(message),
                },
          ),
          entries: entries,
        );

        await tester.pumpWidget(
          w.SlotScope<String, String>(
            registry: w.SlotRegistry<String, String>(),
            child: w.InteractiveSlotRegion<String, String>(
              slot: 'main',
              data: 'unused',
              remoteEntries: entries,
              remoteInputRouter: inputRouter,
            ),
          ),
        );

        tester.tapAt(0, 0);
        tester.sendMsg(const KeyMsg(Key(KeyType.f8, ctrl: true, shift: true)));

        expect(messages, <Matcher>[
          isA<plugins.RemotePluginFocusInput>(),
          isA<plugins.RemotePluginMouseInput>(),
          isA<plugins.RemotePluginKeyInput>()
              .having((message) => message.key, 'key', 'F8')
              .having((message) => message.code, 'code', 'F8')
              .having((message) => message.ctrl, 'ctrl', isTrue)
              .having((message) => message.shift, 'shift', isTrue)
              .having((message) => message.alt, 'alt', isFalse)
              .having((message) => message.meta, 'meta', isFalse),
        ]);
      },
    );

    test('InteractiveSlotRegion forwards extended special keys', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final store = plugins.RemotePluginSurfaceStore();
      store.apply(
        const plugins.RemotePluginSurfaceOpen(
          surfaceId: 'panel',
          kind: plugins.RemotePluginSurfaceKind.panel,
          width: 1,
          height: 1,
          slot: 'main',
        ),
      );
      store.apply(
        const plugins.RemotePluginFrame(
          surfaceId: 'panel',
          width: 1,
          height: 1,
          cells: <plugins.RemotePluginFrameCell>[
            plugins.RemotePluginFrameCell(column: 0, row: 0, symbol: 'A'),
          ],
        ),
      );

      final messages = <plugins.RemotePluginMessage>[];
      final entries = plugins.resolveRemotePluginSlotEntries(
        store,
        placements: const [
          plugins.RemotePluginSurfacePlacement(surfaceId: 'panel', x: 0, y: 0),
        ],
      );
      final inputRouter = plugins.RemotePluginSlotInputRouter(
        router: plugins.RemotePluginSurfaceInputRouter(
          surfaces: store,
          sendersBySurfaceId:
              <String, plugins.RemotePluginSurfaceMessageSender>{
                'panel': (message) async => messages.add(message),
              },
        ),
        entries: entries,
      );

      await tester.pumpWidget(
        w.SlotScope<String, String>(
          registry: w.SlotRegistry<String, String>(),
          child: w.InteractiveSlotRegion<String, String>(
            slot: 'main',
            data: 'unused',
            remoteEntries: entries,
            remoteInputRouter: inputRouter,
          ),
        ),
      );

      tester.tapAt(0, 0);
      tester.sendMsg(const KeyMsg(Key(KeyType.capsLock)));
      tester.sendMsg(const KeyMsg(Key(KeyType.mediaNext)));
      tester.sendMsg(const KeyMsg(Key(KeyType.volumeUp)));
      tester.sendMsg(const KeyMsg(Key(KeyType.leftShift)));

      expect(messages, <Matcher>[
        isA<plugins.RemotePluginFocusInput>(),
        isA<plugins.RemotePluginMouseInput>(),
        isA<plugins.RemotePluginKeyInput>()
            .having((message) => message.key, 'key', 'CapsLock')
            .having((message) => message.code, 'code', 'CapsLock'),
        isA<plugins.RemotePluginKeyInput>()
            .having((message) => message.key, 'key', 'MediaTrackNext')
            .having((message) => message.code, 'code', 'MediaTrackNext'),
        isA<plugins.RemotePluginKeyInput>()
            .having((message) => message.key, 'key', 'AudioVolumeUp')
            .having((message) => message.code, 'code', 'AudioVolumeUp'),
        isA<plugins.RemotePluginKeyInput>()
            .having((message) => message.key, 'key', 'Shift')
            .having((message) => message.code, 'code', 'ShiftLeft'),
      ]);
    });

    test(
      'InteractiveSlotRegion targets the topmost overlapping surface',
      () async {
        final tester = WidgetTester();
        addTearDown(() => tester.dispose());

        final store = plugins.RemotePluginSurfaceStore();
        store.applyAll([
          const plugins.RemotePluginSurfaceOpen(
            surfaceId: 'panel',
            kind: plugins.RemotePluginSurfaceKind.panel,
            width: 4,
            height: 2,
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
        final entries = plugins.resolveRemotePluginSlotEntries(
          store,
          placements: const [
            plugins.RemotePluginSurfacePlacement(
              surfaceId: 'panel',
              x: 0,
              y: 0,
              z: 0,
            ),
            plugins.RemotePluginSurfacePlacement(
              surfaceId: 'popup',
              x: 1,
              y: 0,
              z: 10,
            ),
          ],
        );
        final inputRouter = plugins.RemotePluginSlotInputRouter(
          router: plugins.RemotePluginSurfaceInputRouter(
            surfaces: store,
            sendersBySurfaceId:
                <String, plugins.RemotePluginSurfaceMessageSender>{
                  'panel': (message) async => panelMessages.add(message),
                  'popup': (message) async => popupMessages.add(message),
                },
          ),
          entries: entries,
        );

        await tester.pumpWidget(
          w.SlotScope<String, String>(
            registry: w.SlotRegistry<String, String>(),
            child: w.InteractiveSlotRegion<String, String>(
              slot: 'main',
              data: 'unused',
              remoteEntries: entries,
              remoteInputRouter: inputRouter,
            ),
          ),
        );

        tester.tapAt(1, 0);
        tester.sendMsg(const KeyMsg(Key(KeyType.f2)));

        expect(panelMessages, isEmpty);
        expect(popupMessages, <Matcher>[
          isA<plugins.RemotePluginFocusInput>(),
          isA<plugins.RemotePluginMouseInput>()
              .having((message) => message.column, 'column', 0)
              .having((message) => message.row, 'row', 0),
          isA<plugins.RemotePluginKeyInput>()
              .having((message) => message.key, 'key', 'F2')
              .having((message) => message.code, 'code', 'F2'),
        ]);
      },
    );

    test(
      'InteractiveSlotRegion forwards hover motion without changing focus',
      () async {
        final tester = WidgetTester();
        addTearDown(() => tester.dispose());

        final store = plugins.RemotePluginSurfaceStore();
        store.apply(
          const plugins.RemotePluginSurfaceOpen(
            surfaceId: 'panel',
            kind: plugins.RemotePluginSurfaceKind.panel,
            width: 4,
            height: 2,
            slot: 'main',
          ),
        );

        final messages = <plugins.RemotePluginMessage>[];
        final entries = plugins.resolveRemotePluginSlotEntries(
          store,
          placements: const [
            plugins.RemotePluginSurfacePlacement(
              surfaceId: 'panel',
              x: 0,
              y: 0,
            ),
          ],
        );
        final inputRouter = plugins.RemotePluginSlotInputRouter(
          router: plugins.RemotePluginSurfaceInputRouter(
            surfaces: store,
            sendersBySurfaceId:
                <String, plugins.RemotePluginSurfaceMessageSender>{
                  'panel': (message) async => messages.add(message),
                },
          ),
          entries: entries,
        );

        await tester.pumpWidget(
          w.SlotScope<String, String>(
            registry: w.SlotRegistry<String, String>(),
            child: w.InteractiveSlotRegion<String, String>(
              slot: 'main',
              data: 'unused',
              remoteEntries: entries,
              remoteInputRouter: inputRouter,
            ),
          ),
        );

        tester.mouseMove(2, 1);

        expect(messages, <Matcher>[
          isA<plugins.RemotePluginMouseInput>()
              .having(
                (message) => message.action,
                'action',
                plugins.RemotePluginMouseAction.motion,
              )
              .having(
                (message) => message.button,
                'button',
                plugins.RemotePluginMouseButton.none,
              )
              .having((message) => message.column, 'column', 2)
              .having((message) => message.row, 'row', 1),
        ]);
      },
    );

    test(
      'InteractiveSlotRegion forwards hover motion to the topmost overlapping surface',
      () async {
        final tester = WidgetTester();
        addTearDown(() => tester.dispose());

        final store = plugins.RemotePluginSurfaceStore();
        store.applyAll([
          const plugins.RemotePluginSurfaceOpen(
            surfaceId: 'panel',
            kind: plugins.RemotePluginSurfaceKind.panel,
            width: 4,
            height: 2,
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
        final entries = plugins.resolveRemotePluginSlotEntries(
          store,
          placements: const [
            plugins.RemotePluginSurfacePlacement(
              surfaceId: 'panel',
              x: 0,
              y: 0,
              z: 0,
            ),
            plugins.RemotePluginSurfacePlacement(
              surfaceId: 'popup',
              x: 1,
              y: 0,
              z: 10,
            ),
          ],
        );
        final inputRouter = plugins.RemotePluginSlotInputRouter(
          router: plugins.RemotePluginSurfaceInputRouter(
            surfaces: store,
            sendersBySurfaceId:
                <String, plugins.RemotePluginSurfaceMessageSender>{
                  'panel': (message) async => panelMessages.add(message),
                  'popup': (message) async => popupMessages.add(message),
                },
          ),
          entries: entries,
        );

        await tester.pumpWidget(
          w.SlotScope<String, String>(
            registry: w.SlotRegistry<String, String>(),
            child: w.InteractiveSlotRegion<String, String>(
              slot: 'main',
              data: 'unused',
              remoteEntries: entries,
              remoteInputRouter: inputRouter,
            ),
          ),
        );

        tester.mouseMove(1, 0);

        expect(panelMessages, isEmpty);
        expect(popupMessages, <Matcher>[
          isA<plugins.RemotePluginMouseInput>()
              .having(
                (message) => message.action,
                'action',
                plugins.RemotePluginMouseAction.motion,
              )
              .having(
                (message) => message.button,
                'button',
                plugins.RemotePluginMouseButton.none,
              )
              .having((message) => message.column, 'column', 0)
              .having((message) => message.row, 'row', 0),
        ]);
      },
    );

    test(
      'InteractiveSlotRegion forwards drag motion to remote surfaces',
      () async {
        final tester = WidgetTester();
        addTearDown(() => tester.dispose());

        final store = plugins.RemotePluginSurfaceStore();
        store.apply(
          const plugins.RemotePluginSurfaceOpen(
            surfaceId: 'panel',
            kind: plugins.RemotePluginSurfaceKind.panel,
            width: 4,
            height: 1,
            slot: 'main',
          ),
        );
        store.apply(
          const plugins.RemotePluginFrame(
            surfaceId: 'panel',
            width: 4,
            height: 1,
            cells: <plugins.RemotePluginFrameCell>[
              plugins.RemotePluginFrameCell(column: 0, row: 0, symbol: 'D'),
            ],
          ),
        );

        final messages = <plugins.RemotePluginMessage>[];
        final entries = plugins.resolveRemotePluginSlotEntries(
          store,
          placements: const [
            plugins.RemotePluginSurfacePlacement(
              surfaceId: 'panel',
              x: 0,
              y: 0,
            ),
          ],
        );
        final inputRouter = plugins.RemotePluginSlotInputRouter(
          router: plugins.RemotePluginSurfaceInputRouter(
            surfaces: store,
            sendersBySurfaceId:
                <String, plugins.RemotePluginSurfaceMessageSender>{
                  'panel': (message) async => messages.add(message),
                },
          ),
          entries: entries,
        );

        await tester.pumpWidget(
          w.SlotScope<String, String>(
            registry: w.SlotRegistry<String, String>(),
            child: w.InteractiveSlotRegion<String, String>(
              slot: 'main',
              data: 'unused',
              remoteEntries: entries,
              remoteInputRouter: inputRouter,
            ),
          ),
        );

        tester.mouseDown(0, 0);
        tester.mouseMove(2, 0);
        tester.mouseUp(2, 0);

        expect(messages, <Matcher>[
          isA<plugins.RemotePluginFocusInput>(),
          isA<plugins.RemotePluginMouseInput>()
              .having(
                (message) => message.action,
                'action',
                plugins.RemotePluginMouseAction.press,
              )
              .having((message) => message.column, 'column', 0),
          isA<plugins.RemotePluginMouseInput>()
              .having(
                (message) => message.action,
                'action',
                plugins.RemotePluginMouseAction.motion,
              )
              .having((message) => message.column, 'column', 2),
          isA<plugins.RemotePluginMouseInput>()
              .having(
                (message) => message.action,
                'action',
                plugins.RemotePluginMouseAction.release,
              )
              .having((message) => message.column, 'column', 2),
        ]);
      },
    );

    test(
      'InteractiveSlotRegion keeps drag capture on the pressed surface',
      () async {
        final tester = WidgetTester();
        addTearDown(() => tester.dispose());

        final store = plugins.RemotePluginSurfaceStore();
        store.applyAll([
          const plugins.RemotePluginSurfaceOpen(
            surfaceId: 'panel',
            kind: plugins.RemotePluginSurfaceKind.panel,
            width: 5,
            height: 2,
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
        final entries = plugins.resolveRemotePluginSlotEntries(
          store,
          placements: const [
            plugins.RemotePluginSurfacePlacement(
              surfaceId: 'panel',
              x: 0,
              y: 0,
              z: 0,
            ),
            plugins.RemotePluginSurfacePlacement(
              surfaceId: 'popup',
              x: 0,
              y: 0,
              z: 10,
            ),
          ],
        );
        final inputRouter = plugins.RemotePluginSlotInputRouter(
          router: plugins.RemotePluginSurfaceInputRouter(
            surfaces: store,
            sendersBySurfaceId:
                <String, plugins.RemotePluginSurfaceMessageSender>{
                  'panel': (message) async => panelMessages.add(message),
                  'popup': (message) async => popupMessages.add(message),
                },
          ),
          entries: entries,
        );

        await tester.pumpWidget(
          w.SlotScope<String, String>(
            registry: w.SlotRegistry<String, String>(),
            child: w.InteractiveSlotRegion<String, String>(
              slot: 'main',
              data: 'unused',
              remoteEntries: entries,
              remoteInputRouter: inputRouter,
            ),
          ),
        );

        tester.mouseDown(0, 0);
        tester.mouseMove(3, 0);
        tester.mouseUp(3, 0);

        expect(panelMessages, isEmpty);
        expect(popupMessages, <Matcher>[
          isA<plugins.RemotePluginFocusInput>(),
          isA<plugins.RemotePluginMouseInput>()
              .having(
                (message) => message.action,
                'action',
                plugins.RemotePluginMouseAction.press,
              )
              .having((message) => message.column, 'column', 0)
              .having((message) => message.row, 'row', 0),
          isA<plugins.RemotePluginMouseInput>()
              .having(
                (message) => message.action,
                'action',
                plugins.RemotePluginMouseAction.motion,
              )
              .having((message) => message.column, 'column', 3)
              .having((message) => message.row, 'row', 0),
          isA<plugins.RemotePluginMouseInput>()
              .having(
                (message) => message.action,
                'action',
                plugins.RemotePluginMouseAction.release,
              )
              .having((message) => message.column, 'column', 3)
              .having((message) => message.row, 'row', 0),
        ]);
      },
    );
  });
}
