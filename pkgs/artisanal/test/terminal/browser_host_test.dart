import 'dart:async';
import 'dart:io' as io;

import 'package:artisanal/tui.dart';
import 'package:test/test.dart';

void main() {
  group('BrowserTerminalHostServer', () {
    test('defaultPageHtml wires the websocket path', () {
      final html = BrowserTerminalHostServer.defaultPageHtml(
        title: 'Browser Test',
        webSocketPath: '/custom-ws',
      );

      expect(html, contains('Browser Test'));
      expect(html, contains('/custom-ws'));
      expect(html, contains('convertEol: true'));
      expect(html, contains('@xterm/xterm'));
    });

    test('bind serves the page and a 404 for unknown routes', () async {
      final server = await BrowserTerminalHostServer.bind(
        port: 0,
        title: 'Bind Test',
        onSession: (_) async {},
      );
      addTearDown(() => server.close(force: true));

      final client = io.HttpClient();
      addTearDown(() => client.close(force: true));

      final pageRequest = await client.getUrl(server.pageUri);
      final pageResponse = await pageRequest.close();
      final pageBody = await pageResponse.transform(io.systemEncoding.decoder).join();

      expect(pageResponse.statusCode, io.HttpStatus.ok);
      expect(pageBody, contains('Bind Test'));

      final notFoundRequest = await client.getUrl(
        server.pageUri.replace(path: '/missing'),
      );
      final notFoundResponse = await notFoundRequest.close();
      expect(notFoundResponse.statusCode, io.HttpStatus.notFound);
    });

    test('serveProgram runs a TUI session over websocket', () async {
      final server = await BrowserTerminalHostServer.serveProgram(
        port: 0,
        title: 'Browser Host Test',
        modelBuilder: () => const _BrowserHostModel(),
        options: const ProgramOptions(
          altScreen: false,
          frameTick: false,
          signalHandlers: false,
        ),
      );
      addTearDown(() => server.close(force: true));

      final socket = await io.WebSocket.connect(server.webSocketUri.toString());
      addTearDown(() => socket.close());

      final outputReady = Completer<void>();
      final outputBuffer = StringBuffer();
      late final StreamSubscription<dynamic> subscription;
      subscription = socket.listen((event) {
        final message = TerminalBridgeMessage.decodeJson(event as String);
        if (message.type == TerminalBridgeMessageType.output) {
          outputBuffer.write(message.data ?? '');
          if (!outputReady.isCompleted &&
              outputBuffer.toString().contains('Browser Host Test Model')) {
            outputReady.complete();
          }
        }
      });
      addTearDown(subscription.cancel);

      await outputReady.future.timeout(const Duration(seconds: 5));
      socket.add(const TerminalBridgeMessage.inputText('q').encodeJson());
      await socket.done.timeout(const Duration(seconds: 5));
    });
  });
}

class _BrowserHostModel implements Model {
  const _BrowserHostModel();

  @override
  Cmd? init() => null;

  @override
  (Model, Cmd?) update(Msg msg) {
    return switch (msg) {
      KeyMsg(key: Key(type: KeyType.runes, runes: [0x71])) => (this, Cmd.quit()),
      _ => (this, null),
    };
  }

  @override
  String view() => '''
Browser Host Test Model
=======================

Press q to close.
''';
}
