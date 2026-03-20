import 'dart:async';

import 'package:artisanal/plugins.dart' as plugins;
import 'package:test/test.dart';

void main() {
  group('RemotePluginSession', () {
    test(
      'connect accepts an eager plugin hello and forwards later messages',
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
            pluginId: 'echo-plugin',
            pluginVersion: '0.0.1',
          ),
        );

        final hostInput = StreamIterator(pluginChannel.messages);
        addTearDown(hostInput.cancel);

        final session = await plugins.RemotePluginSession.connect(
          channel: hostChannel,
          hostHello: const plugins.RemotePluginHostHello(
            hostName: 'artisanal',
            hostVersion: '0.2.0',
          ),
        );
        addTearDown(session.dispose);

        expect(session.pluginHello.pluginId, 'echo-plugin');

        final sawHostHello = await hostInput.moveNext().timeout(
          const Duration(seconds: 1),
        );
        expect(sawHostHello, isTrue);
        expect(hostInput.current, isA<plugins.RemotePluginHostHello>());

        await pluginChannel.send(
          const plugins.RemotePluginFocusInput(surfaceId: 'sidebar'),
        );
        await pluginChannel.send(
          const plugins.RemotePluginBlurInput(surfaceId: 'sidebar'),
        );

        final forwarded = await session.messages
            .take(2)
            .toList()
            .timeout(
          const Duration(seconds: 1),
        );
        expect(forwarded, hasLength(2));
        expect(forwarded.first, isA<plugins.RemotePluginFocusInput>());
        expect(forwarded.last, isA<plugins.RemotePluginBlurInput>());
      },
    );

    test('connect rejects a non-hello message before handshake', () async {
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

      unawaited(
        pluginChannel.send(
          const plugins.RemotePluginFocusInput(surfaceId: 'sidebar'),
        ),
      );

      await expectLater(
        plugins.RemotePluginSession.connect(
          channel: hostChannel,
          hostHello: const plugins.RemotePluginHostHello(
            hostName: 'artisanal',
            hostVersion: '0.2.0',
          ),
          timeout: const Duration(milliseconds: 250),
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}
