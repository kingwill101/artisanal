import 'dart:convert';

import 'package:artisanal/plugins.dart' as plugins;
import 'package:test/test.dart';

void main() {
  test('encodeLine emits newline-delimited JSON', () {
    const message = plugins.RemotePluginFocusInput(surfaceId: 'sidebar');

    final encoded = plugins.RemotePluginJsonTransport.encodeLine(message);

    expect(encoded, endsWith('\n'));
    expect(
      jsonDecode(encoded.trim()) as Map<String, dynamic>,
      containsPair(
        'type',
        plugins.RemotePluginMessageType.hostInputFocus.wireName,
      ),
    );
  });

  test('decodeLines skips blanks and yields typed messages', () async {
    final lines = Stream<String>.fromIterable(<String>[
      '',
      plugins.RemotePluginJsonTransport.encodeLine(
        const plugins.RemotePluginHello(
          pluginId: 'clock',
          pluginVersion: '1.0.0',
        ),
      ),
      '   ',
      plugins.RemotePluginJsonTransport.encodeLine(
        const plugins.RemotePluginBlurInput(surfaceId: 'sidebar'),
      ),
    ]);

    final decoded = await plugins.RemotePluginJsonTransport.decodeLines(
      lines,
    ).toList();

    expect(decoded, hasLength(2));
    expect(decoded.first, isA<plugins.RemotePluginHello>());
    expect(decoded.last, isA<plugins.RemotePluginBlurInput>());
  });

  test('decodeBytes handles UTF-8 line streams', () async {
    final encoded = plugins.RemotePluginJsonTransport.encodeLine(
      const plugins.RemotePluginMouseInput(
        surfaceId: 'sidebar',
        action: plugins.RemotePluginMouseAction.motion,
        button: plugins.RemotePluginMouseButton.none,
        column: 4,
        row: 2,
      ),
    );

    final decoded = await plugins.RemotePluginJsonTransport.decodeBytes(
      Stream<List<int>>.fromIterable(<List<int>>[utf8.encode(encoded)]),
    ).single;

    expect(decoded, isA<plugins.RemotePluginMouseInput>());
  });

  test('decodeLines surfaces schema validation failures', () async {
    final lines = Stream<String>.fromIterable(<String>[
      '{"protocol":"${plugins.remotePluginProtocolVersion}","type":"host.input.mouse","payload":{"surfaceId":"sidebar"}}\n',
    ]);

    expect(
      plugins.RemotePluginJsonTransport.decodeLines(lines).drain<void>(),
      throwsA(isA<plugins.RemotePluginProtocolValidationException>()),
    );
  });
}
