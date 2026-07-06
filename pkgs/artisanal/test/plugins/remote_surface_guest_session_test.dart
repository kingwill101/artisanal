import 'dart:async';
import 'dart:convert';

import 'package:artisanal/artisanal.dart' as plugins;
import 'package:json_schema_builder/json_schema_builder.dart' as jsb;
import 'package:test/test.dart';

void main() {
  group('RemotePluginGuestSession', () {
    test(
      'connect accepts an eager host hello and forwards later messages',
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

        await hostChannel.send(
          const plugins.RemotePluginHostHello(
            hostName: 'artisanal',
            hostVersion: '0.2.0',
          ),
        );

        final pluginInput = StreamIterator(hostChannel.messages);
        addTearDown(pluginInput.cancel);

        final session = await plugins.RemotePluginGuestSession.connect(
          channel: pluginChannel,
          pluginHello: const plugins.RemotePluginHello(
            pluginId: 'echo-plugin',
            pluginVersion: '0.0.1',
          ),
        );
        addTearDown(session.dispose);

        expect(session.hostHello.hostName, 'artisanal');

        final sawPluginHello = await pluginInput.moveNext().timeout(
          const Duration(seconds: 1),
        );
        expect(sawPluginHello, isTrue);
        expect(pluginInput.current, isA<plugins.RemotePluginHello>());

        await hostChannel.send(
          const plugins.RemotePluginFocusInput(surfaceId: 'sidebar'),
        );
        await hostChannel.send(
          const plugins.RemotePluginBlurInput(surfaceId: 'sidebar'),
        );

        final forwarded = await session.messages
            .take(2)
            .toList()
            .timeout(const Duration(seconds: 1));
        expect(forwarded, hasLength(2));
        expect(forwarded.first, isA<plugins.RemotePluginFocusInput>());
        expect(forwarded.last, isA<plugins.RemotePluginBlurInput>());
      },
    );

    test('bindStdio wires byte input and line output together', () async {
      final inbound = StreamController<List<int>>();
      final outbound = <String>[];

      final sessionFuture = plugins.RemotePluginGuestSession.bindStdio(
        pluginHello: const plugins.RemotePluginHello(
          pluginId: 'echo-plugin',
          pluginVersion: '0.0.1',
        ),
        input: inbound.stream,
        sendLine: outbound.add,
      );

      inbound.add(
        utf8.encode(
          plugins.RemotePluginJsonTransport.encodeLine(
            const plugins.RemotePluginHostHello(
              hostName: 'artisanal',
              hostVersion: '0.2.0',
            ),
          ),
        ),
      );

      final session = await sessionFuture;
      addTearDown(session.dispose);
      addTearDown(inbound.close);

      expect(session.hostHello.hostName, 'artisanal');
      expect(outbound, hasLength(1));
      final decoded = await plugins.RemotePluginMessage.decodeJson(
        outbound.single.trim(),
      );
      expect(decoded, isA<plugins.RemotePluginHello>());
    });

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

      await hostChannel.send(
        const plugins.RemotePluginFocusInput(surfaceId: 'sidebar'),
      );

      await expectLater(
        plugins.RemotePluginGuestSession.connect(
          channel: pluginChannel,
          pluginHello: const plugins.RemotePluginHello(
            pluginId: 'echo-plugin',
            pluginVersion: '0.0.1',
          ),
          timeout: const Duration(milliseconds: 250),
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('guest services read clipboard and send matching request', () async {
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

      await hostChannel.send(
        const plugins.RemotePluginHostHello(
          hostName: 'artisanal',
          hostVersion: '0.2.0',
        ),
      );

      final session = await plugins.RemotePluginGuestSession.connect(
        channel: pluginChannel,
        pluginHello: const plugins.RemotePluginHello(
          pluginId: 'service-plugin',
          pluginVersion: '0.0.1',
        ),
      );
      addTearDown(session.dispose);

      final hostMessages = StreamIterator(hostChannel.messages.skip(1));
      addTearDown(hostMessages.cancel);

      final readFuture = session.services.readClipboard();

      final sawRequest = await hostMessages.moveNext().timeout(
        const Duration(seconds: 1),
      );
      expect(sawRequest, isTrue);
      final request = hostMessages.current;
      expect(request, isA<plugins.RemotePluginClipboardReadRequest>());

      await hostChannel.send(
        plugins.RemotePluginClipboardReadResponse(
          requestId:
              (request as plugins.RemotePluginClipboardReadRequest).requestId,
          text: 'host-value',
        ),
      );

      expect(await readFuture, 'host-value');
    });

    test(
      'guest services prefer the generic envelope for clipboard when available',
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

        await hostChannel.send(
          plugins.RemotePluginHostHello(
            hostName: 'artisanal',
            hostVersion: '0.2.0',
            capabilities: <String>['services'],
            services:
                (plugins.RemotePluginGenericServiceCatalog()
                      ..registerClipboard(readClipboard: (_) => 'unused'))
                    .serviceDescriptors,
          ),
        );

        final session = await plugins.RemotePluginGuestSession.connect(
          channel: pluginChannel,
          pluginHello: const plugins.RemotePluginHello(
            pluginId: 'service-plugin',
            pluginVersion: '0.0.1',
          ),
        );
        addTearDown(session.dispose);

        final hostMessages = StreamIterator(hostChannel.messages.skip(1));
        addTearDown(hostMessages.cancel);

        final readFuture = session.services.readClipboard();

        final sawRequest = await hostMessages.moveNext().timeout(
          const Duration(seconds: 1),
        );
        expect(sawRequest, isTrue);
        final request = hostMessages.current;
        expect(
          request,
          isA<plugins.RemotePluginServiceRequest>()
              .having((m) => m.service, 'service', 'clipboard')
              .having((m) => m.method, 'method', 'read')
              .having((m) => m.params, 'params', <String, Object?>{
                'selection': 'c',
              }),
        );

        await hostChannel.send(
          plugins.RemotePluginServiceResponse(
            requestId:
                (request as plugins.RemotePluginServiceRequest).requestId,
            service: request.service,
            method: request.method,
            result: const <String, Object?>{'text': 'host-value'},
          ),
        );

        expect(await readFuture, 'host-value');
        expect(session.services.supports('clipboard', 'read'), isTrue);
        expect(session.services.supports('clipboard', 'write'), isFalse);
        expect(
          session.services.descriptorFor('clipboard', 'read')?.description,
          isNotEmpty,
        );
      },
    );

    test(
      'generic service catalogs can register the built-in host services together',
      () {
        final catalog = plugins.RemotePluginGenericServiceCatalog.builtIns(
          readClipboard: (_) => 'unused',
          writeClipboard: (_, _) {},
          openUrl: (_) {},
          notify: (_) {},
          pickPaths: (_) => const <String>['/tmp/demo.txt'],
        );

        expect(
          catalog.serviceDescriptors,
          containsAll(<Matcher>[
            isA<plugins.RemotePluginServiceDescriptor>()
                .having((d) => d.service, 'service', 'clipboard')
                .having((d) => d.method, 'method', 'read'),
            isA<plugins.RemotePluginServiceDescriptor>()
                .having((d) => d.service, 'service', 'clipboard')
                .having((d) => d.method, 'method', 'write'),
            isA<plugins.RemotePluginServiceDescriptor>()
                .having((d) => d.service, 'service', 'url')
                .having((d) => d.method, 'method', 'open'),
            isA<plugins.RemotePluginServiceDescriptor>()
                .having((d) => d.service, 'service', 'notify')
                .having((d) => d.method, 'method', 'show'),
            isA<plugins.RemotePluginServiceDescriptor>()
                .having((d) => d.service, 'service', 'filePicker')
                .having((d) => d.method, 'method', 'open'),
          ]),
        );
      },
    );

    test(
      'guest services open urls and notifications as awaitable RPCs',
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

        await hostChannel.send(
          const plugins.RemotePluginHostHello(
            hostName: 'artisanal',
            hostVersion: '0.2.0',
          ),
        );

        final session = await plugins.RemotePluginGuestSession.connect(
          channel: pluginChannel,
          pluginHello: const plugins.RemotePluginHello(
            pluginId: 'service-plugin',
            pluginVersion: '0.0.1',
          ),
        );
        addTearDown(session.dispose);

        final hostMessages = StreamIterator(hostChannel.messages.skip(1));
        addTearDown(hostMessages.cancel);

        final openUrlFuture = session.services.openUrl('https://example.com');
        await hostMessages.moveNext().timeout(const Duration(seconds: 1));
        final openUrlRequest = hostMessages.current;
        expect(openUrlRequest, isA<plugins.RemotePluginOpenUrlRequest>());
        await hostChannel.send(
          plugins.RemotePluginOpenUrlResponse(
            requestId: (openUrlRequest as plugins.RemotePluginOpenUrlRequest)
                .requestId,
          ),
        );
        await openUrlFuture;

        final notifyFuture = session.services.notify(
          'Task finished',
          title: 'Plugin demo',
          level: plugins.RemotePluginNotificationLevel.success,
        );
        await hostMessages.moveNext().timeout(const Duration(seconds: 1));
        final notifyRequest = hostMessages.current;
        expect(notifyRequest, isA<plugins.RemotePluginNotificationRequest>());
        await hostChannel.send(
          plugins.RemotePluginNotificationResponse(
            requestId:
                (notifyRequest as plugins.RemotePluginNotificationRequest)
                    .requestId,
          ),
        );
        await notifyFuture;
      },
    );

    test(
      'guest services prefer the generic envelope for URL opening when available',
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

        await hostChannel.send(
          const plugins.RemotePluginHostHello(
            hostName: 'artisanal',
            hostVersion: '0.2.0',
            capabilities: <String>['services'],
          ),
        );

        final session = await plugins.RemotePluginGuestSession.connect(
          channel: pluginChannel,
          pluginHello: const plugins.RemotePluginHello(
            pluginId: 'service-plugin',
            pluginVersion: '0.0.1',
          ),
        );
        addTearDown(session.dispose);

        final hostMessages = StreamIterator(hostChannel.messages.skip(1));
        addTearDown(hostMessages.cancel);

        final openUrlFuture = session.services.openUrl('https://example.com');

        final sawRequest = await hostMessages.moveNext().timeout(
          const Duration(seconds: 1),
        );
        expect(sawRequest, isTrue);
        final request = hostMessages.current;
        expect(
          request,
          isA<plugins.RemotePluginServiceRequest>()
              .having((m) => m.service, 'service', 'url')
              .having((m) => m.method, 'method', 'open')
              .having((m) => m.params, 'params', <String, Object?>{
                'url': 'https://example.com',
              }),
        );

        await hostChannel.send(
          plugins.RemotePluginServiceResponse(
            requestId:
                (request as plugins.RemotePluginServiceRequest).requestId,
            service: request.service,
            method: request.method,
            result: const <String, Object?>{},
          ),
        );

        await openUrlFuture;
      },
    );

    test(
      'guest services prefer the generic envelope for notifications when available',
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

        await hostChannel.send(
          const plugins.RemotePluginHostHello(
            hostName: 'artisanal',
            hostVersion: '0.2.0',
            capabilities: <String>['services'],
          ),
        );

        final session = await plugins.RemotePluginGuestSession.connect(
          channel: pluginChannel,
          pluginHello: const plugins.RemotePluginHello(
            pluginId: 'service-plugin',
            pluginVersion: '0.0.1',
          ),
        );
        addTearDown(session.dispose);

        final hostMessages = StreamIterator(hostChannel.messages.skip(1));
        addTearDown(hostMessages.cancel);

        final notifyFuture = session.services.notify(
          'Task finished',
          title: 'Plugin demo',
          level: plugins.RemotePluginNotificationLevel.success,
        );

        final sawRequest = await hostMessages.moveNext().timeout(
          const Duration(seconds: 1),
        );
        expect(sawRequest, isTrue);
        final request = hostMessages.current;
        expect(
          request,
          isA<plugins.RemotePluginServiceRequest>()
              .having((m) => m.service, 'service', 'notify')
              .having((m) => m.method, 'method', 'show')
              .having((m) => m.params, 'params', <String, Object?>{
                'message': 'Task finished',
                'title': 'Plugin demo',
                'level': 'success',
              }),
        );

        await hostChannel.send(
          plugins.RemotePluginServiceResponse(
            requestId:
                (request as plugins.RemotePluginServiceRequest).requestId,
            service: request.service,
            method: request.method,
            result: const <String, Object?>{},
          ),
        );

        await notifyFuture;
      },
    );

    test('guest services request file picker results', () async {
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

      await hostChannel.send(
        const plugins.RemotePluginHostHello(
          hostName: 'artisanal',
          hostVersion: '0.2.0',
        ),
      );

      final session = await plugins.RemotePluginGuestSession.connect(
        channel: pluginChannel,
        pluginHello: const plugins.RemotePluginHello(
          pluginId: 'service-plugin',
          pluginVersion: '0.0.1',
        ),
      );
      addTearDown(session.dispose);

      final hostMessages = StreamIterator(hostChannel.messages.skip(1));
      addTearDown(hostMessages.cancel);

      final pickerFuture = session.services.pickPaths(
        title: 'Pick demo file',
        initialPath: '/tmp',
      );
      await hostMessages.moveNext().timeout(const Duration(seconds: 1));
      final pickerRequest = hostMessages.current;
      expect(pickerRequest, isA<plugins.RemotePluginFilePickerRequest>());
      await hostChannel.send(
        plugins.RemotePluginFilePickerResponse(
          requestId: (pickerRequest as plugins.RemotePluginFilePickerRequest)
              .requestId,
          paths: const <String>['/tmp/demo.txt'],
        ),
      );
      expect(await pickerFuture, const <String>['/tmp/demo.txt']);
    });

    test(
      'guest services prefer the generic envelope for file picker when available',
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

        await hostChannel.send(
          const plugins.RemotePluginHostHello(
            hostName: 'artisanal',
            hostVersion: '0.2.0',
            capabilities: <String>['services'],
          ),
        );

        final session = await plugins.RemotePluginGuestSession.connect(
          channel: pluginChannel,
          pluginHello: const plugins.RemotePluginHello(
            pluginId: 'service-plugin',
            pluginVersion: '0.0.1',
          ),
        );
        addTearDown(session.dispose);

        final hostMessages = StreamIterator(hostChannel.messages.skip(1));
        addTearDown(hostMessages.cancel);

        final pickerFuture = session.services.pickPaths(
          title: 'Pick demo file',
          initialPath: '/tmp',
        );

        final sawRequest = await hostMessages.moveNext().timeout(
          const Duration(seconds: 1),
        );
        expect(sawRequest, isTrue);
        final request = hostMessages.current;
        expect(
          request,
          isA<plugins.RemotePluginServiceRequest>()
              .having((m) => m.service, 'service', 'filePicker')
              .having((m) => m.method, 'method', 'open')
              .having((m) => m.params, 'params', <String, Object?>{
                'kind': 'file',
                'allowMultiple': false,
                'title': 'Pick demo file',
                'initialPath': '/tmp',
              }),
        );

        await hostChannel.send(
          plugins.RemotePluginServiceResponse(
            requestId:
                (request as plugins.RemotePluginServiceRequest).requestId,
            service: request.service,
            method: request.method,
            result: const <String, Object?>{
              'paths': <String>['/tmp/demo.txt'],
              'canceled': false,
            },
          ),
        );

        expect(await pickerFuture, const <String>['/tmp/demo.txt']);
      },
    );

    test('guest services support generic service calls', () async {
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

      await hostChannel.send(
        const plugins.RemotePluginHostHello(
          hostName: 'artisanal',
          hostVersion: '0.2.0',
        ),
      );

      final session = await plugins.RemotePluginGuestSession.connect(
        channel: pluginChannel,
        pluginHello: const plugins.RemotePluginHello(
          pluginId: 'service-plugin',
          pluginVersion: '0.0.1',
        ),
      );
      addTearDown(session.dispose);

      final hostMessages = StreamIterator(hostChannel.messages.skip(1));
      addTearDown(hostMessages.cancel);

      final callFuture = session.services.call(
        'clipboard',
        'read',
        params: const <String, Object?>{'selection': 'c'},
      );

      await hostMessages.moveNext().timeout(const Duration(seconds: 1));
      final request = hostMessages.current;
      expect(request, isA<plugins.RemotePluginServiceRequest>());

      await hostChannel.send(
        plugins.RemotePluginServiceResponse(
          requestId: (request as plugins.RemotePluginServiceRequest).requestId,
          service: request.service,
          method: request.method,
          result: const <String, Object?>{'text': 'host-value'},
        ),
      );

      expect(await callFuture, <String, Object?>{'text': 'host-value'});
    });

    test('guest services validate generic service results', () async {
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

      await hostChannel.send(
        const plugins.RemotePluginHostHello(
          hostName: 'artisanal',
          hostVersion: '0.2.0',
        ),
      );

      final session = await plugins.RemotePluginGuestSession.connect(
        channel: pluginChannel,
        pluginHello: const plugins.RemotePluginHello(
          pluginId: 'service-plugin',
          pluginVersion: '0.0.1',
        ),
      );
      addTearDown(session.dispose);

      final hostMessages = StreamIterator(hostChannel.messages.skip(1));
      addTearDown(hostMessages.cancel);

      final callFuture = session.services.call(
        'host',
        'ping',
        params: const <String, Object?>{'value': 'demo'},
        resultSchema: jsb.S.object(
          required: const <String>['reply'],
          properties: <String, jsb.Schema>{'reply': jsb.S.integer()},
          additionalProperties: false,
        ),
      );

      await hostMessages.moveNext().timeout(const Duration(seconds: 1));
      final request = hostMessages.current;
      expect(request, isA<plugins.RemotePluginServiceRequest>());

      await hostChannel.send(
        plugins.RemotePluginServiceResponse(
          requestId: (request as plugins.RemotePluginServiceRequest).requestId,
          service: request.service,
          method: request.method,
          result: const <String, Object?>{'reply': 'pong'},
        ),
      );

      await expectLater(
        callFuture,
        throwsA(
          isA<plugins.RemotePluginServiceException>().having(
            (error) => error.message,
            'message',
            contains('Invalid result for host.ping'),
          ),
        ),
      );
    });
  });
}
