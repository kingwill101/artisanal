import 'dart:async';

import 'package:artisanal/artisanal.dart' as plugins;
import 'package:test/test.dart';

void main() {
  group('RemotePluginSurfaceController', () {
    test(
      'applies surface messages into store and forwards non-surface messages',
      () async {
        final hostToPlugin = StreamController<String>();
        final pluginToHost = StreamController<String>();

        final hostChannel = plugins.RemotePluginJsonChannel(
          sendLine: hostToPlugin.add,
        );
        final pluginChannel = plugins.RemotePluginJsonChannel(
          sendLine: pluginToHost.add,
        );

        hostChannel.bindLines(pluginToHost.stream);
        pluginChannel.bindLines(hostToPlugin.stream);

        addTearDown(() async {
          await hostChannel.dispose();
          await pluginChannel.dispose();
          await hostToPlugin.close();
          await pluginToHost.close();
        });

        await pluginChannel.send(
          const plugins.RemotePluginHello(
            pluginId: 'controller-test-plugin',
            pluginVersion: '0.0.1',
          ),
        );

        final session = await plugins.RemotePluginSession.connect(
          channel: hostChannel,
          hostHello: const plugins.RemotePluginHostHello(
            hostName: 'artisanal',
            hostVersion: '0.2.0',
          ),
        );
        addTearDown(session.dispose);

        final controller = plugins.RemotePluginSurfaceController.bind(session);
        addTearDown(controller.dispose);

        final surfaceMessages = controller.surfaceMessages.take(2).toList();
        final otherMessages = controller.otherMessages.take(1).toList();

        await pluginChannel.send(
          const plugins.RemotePluginSurfaceOpen(
            surfaceId: 'panel',
            kind: plugins.RemotePluginSurfaceKind.panel,
            width: 4,
            height: 2,
            title: 'Panel',
          ),
        );
        await pluginChannel.send(
          const plugins.RemotePluginFrame(
            surfaceId: 'panel',
            width: 4,
            height: 2,
            cells: <plugins.RemotePluginFrameCell>[
              plugins.RemotePluginFrameCell(
                column: 0,
                row: 0,
                symbol: 'H',
                foreground: '#7dd3fc',
              ),
            ],
            cursor: plugins.RemotePluginCursor(column: 1, row: 0),
          ),
        );
        await pluginChannel.send(
          const plugins.RemotePluginFocusInput(surfaceId: 'panel'),
        );

        final appliedSurfaceMessages = await surfaceMessages.timeout(
          const Duration(seconds: 1),
        );
        final forwardedMessages = await otherMessages.timeout(
          const Duration(seconds: 1),
        );

        final surface = controller.surfaces['panel'];
        expect(surface, isNotNull);
        expect(
          appliedSurfaceMessages.map((message) => message.messageType).toList(),
          <plugins.RemotePluginMessageType>[
            plugins.RemotePluginMessageType.pluginSurfaceOpen,
            plugins.RemotePluginMessageType.pluginSurfaceFrame,
          ],
        );
        expect(forwardedMessages.single, isA<plugins.RemotePluginFocusInput>());
        expect(surface!.kind, plugins.RemotePluginSurfaceKind.panel);
        expect(surface.title, 'Panel');
        expect(surface.cellAt(0, 0).symbol, 'H');
        expect(surface.cellAt(0, 0).foreground, '#7dd3fc');
        expect(surface.cursor?.column, 1);
        expect(surface.cursor?.row, 0);
      },
    );

    test('removes surfaces when plugin close messages arrive', () async {
      final hostToPlugin = StreamController<String>();
      final pluginToHost = StreamController<String>();

      final hostChannel = plugins.RemotePluginJsonChannel(
        sendLine: hostToPlugin.add,
      );
      final pluginChannel = plugins.RemotePluginJsonChannel(
        sendLine: pluginToHost.add,
      );

      hostChannel.bindLines(pluginToHost.stream);
      pluginChannel.bindLines(hostToPlugin.stream);

      addTearDown(() async {
        await hostChannel.dispose();
        await pluginChannel.dispose();
        await hostToPlugin.close();
        await pluginToHost.close();
      });

      await pluginChannel.send(
        const plugins.RemotePluginHello(
          pluginId: 'controller-test-plugin',
          pluginVersion: '0.0.1',
        ),
      );

      final session = await plugins.RemotePluginSession.connect(
        channel: hostChannel,
        hostHello: const plugins.RemotePluginHostHello(
          hostName: 'artisanal',
          hostVersion: '0.2.0',
        ),
      );
      addTearDown(session.dispose);

      final controller = plugins.RemotePluginSurfaceController.bind(session);
      addTearDown(controller.dispose);

      final surfaceMessages = controller.surfaceMessages.take(2).toList();

      await pluginChannel.send(
        const plugins.RemotePluginSurfaceOpen(
          surfaceId: 'panel',
          kind: plugins.RemotePluginSurfaceKind.panel,
          width: 4,
          height: 2,
        ),
      );
      await pluginChannel.send(
        const plugins.RemotePluginSurfaceClose(surfaceId: 'panel'),
      );

      final appliedSurfaceMessages = await surfaceMessages.timeout(
        const Duration(seconds: 1),
      );

      expect(
        appliedSurfaceMessages.map((message) => message.messageType).toList(),
        <plugins.RemotePluginMessageType>[
          plugins.RemotePluginMessageType.pluginSurfaceOpen,
          plugins.RemotePluginMessageType.pluginSurfaceClose,
        ],
      );
      expect(controller.surfaces['panel'], isNull);
      expect(controller.surfaces.surfaces, isEmpty);
    });

    test(
      'buffers early non-surface messages until a host listener attaches',
      () async {
        final hostToPlugin = StreamController<String>();
        final pluginToHost = StreamController<String>();

        final hostChannel = plugins.RemotePluginJsonChannel(
          sendLine: hostToPlugin.add,
        );
        final pluginChannel = plugins.RemotePluginJsonChannel(
          sendLine: pluginToHost.add,
        );

        hostChannel.bindLines(pluginToHost.stream);
        pluginChannel.bindLines(hostToPlugin.stream);

        addTearDown(() async {
          await hostChannel.dispose();
          await pluginChannel.dispose();
          await hostToPlugin.close();
          await pluginToHost.close();
        });

        await pluginChannel.send(
          const plugins.RemotePluginHello(
            pluginId: 'controller-test-plugin',
            pluginVersion: '0.0.1',
          ),
        );

        final session = await plugins.RemotePluginSession.connect(
          channel: hostChannel,
          hostHello: const plugins.RemotePluginHostHello(
            hostName: 'artisanal',
            hostVersion: '0.2.0',
          ),
        );
        addTearDown(session.dispose);

        final controller = plugins.RemotePluginSurfaceController.bind(session);
        addTearDown(controller.dispose);

        await pluginChannel.send(
          const plugins.RemotePluginClipboardReadRequest(requestId: 'req-1'),
        );

        final forwarded = await controller.otherMessages
            .take(1)
            .toList()
            .timeout(const Duration(seconds: 1));

        expect(
          forwarded.single,
          isA<plugins.RemotePluginClipboardReadRequest>(),
        );
      },
    );
  });
}
