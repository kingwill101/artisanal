import 'dart:async';

import 'package:artisanal/plugins.dart' as plugins;
import 'package:test/test.dart';

void main() {
  test('channel decodes inbound lines into typed messages', () async {
    final received = <plugins.RemotePluginMessage>[];
    final channel = plugins.RemotePluginJsonChannel(sendLine: (_) {});
    final done = Completer<void>();

    channel.messages.listen((message) {
      received.add(message);
      if (received.length == 2 && !done.isCompleted) {
        done.complete();
      }
    });

    channel.bindLines(
      Stream<String>.fromIterable(<String>[
        plugins.RemotePluginJsonTransport.encodeLine(
          const plugins.RemotePluginHostHello(
            hostName: 'artisanal',
            hostVersion: '0.2.0',
          ),
        ),
        plugins.RemotePluginJsonTransport.encodeLine(
          const plugins.RemotePluginFocusInput(surfaceId: 'sidebar'),
        ),
      ]),
    );

    await done.future.timeout(const Duration(seconds: 1));

    expect(received, hasLength(2));
    expect(received.first, isA<plugins.RemotePluginHostHello>());
    expect(received.last, isA<plugins.RemotePluginFocusInput>());
    await channel.dispose();
  });

  test('channel forwards validated outbound lines', () async {
    final outbound = <String>[];
    final channel = plugins.RemotePluginJsonChannel(sendLine: outbound.add);

    await channel.send(const plugins.RemotePluginBlurInput(surfaceId: 'side'));

    expect(outbound, hasLength(1));
    expect(outbound.single, endsWith('\n'));
    await channel.dispose();
  });

  test('channel buffers inbound messages until the first listener', () async {
    final channel = plugins.RemotePluginJsonChannel(sendLine: (_) {});

    await channel.addLine(
      plugins.RemotePluginJsonTransport.encodeLine(
        const plugins.RemotePluginHello(
          pluginId: 'echo',
          pluginVersion: '0.1.0',
        ),
      ),
    );
    await channel.addLine(
      plugins.RemotePluginJsonTransport.encodeLine(
        const plugins.RemotePluginFocusInput(surfaceId: 'sidebar'),
      ),
    );

    final received = await channel.messages
        .take(2)
        .toList()
        .timeout(const Duration(seconds: 1));

    expect(received, hasLength(2));
    expect(received.first, isA<plugins.RemotePluginHello>());
    expect(received.last, isA<plugins.RemotePluginFocusInput>());
    await channel.dispose();
  });

  test('channel surfaces inbound validation failures as stream errors', () async {
    final channel = plugins.RemotePluginJsonChannel(sendLine: (_) {});
    final expectation = expectLater(
      channel.messages,
      emitsError(isA<plugins.RemotePluginProtocolValidationException>()),
    );

    channel.bindLines(
      Stream<String>.fromIterable(<String>[
        '{"protocol":"${plugins.remotePluginProtocolVersion}","type":"host.input.key","payload":{"surfaceId":"sidebar"}}\n',
      ]),
    );

    await expectation;
    await channel.dispose();
  });
}
