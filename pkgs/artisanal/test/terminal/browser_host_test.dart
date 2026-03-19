import 'dart:async';
import 'dart:io' as io;

import 'package:artisanal/tui.dart';
import 'package:test/test.dart';

void main() {
  group('BrowserTerminalHostServer', () {
    test('defaultPageHtml wires the websocket path and query helpers', () {
      final html = BrowserTerminalHostServer.defaultPageHtml(
        title: 'Browser Test',
        webSocketPath: '/custom-ws',
      );

      expect(html, contains('Browser Test'));
      expect(html, contains('/custom-ws'));
      expect(html, contains('convertEol: true'));
      expect(html, contains('@xterm/xterm'));
      expect(html, contains('stripAndReplyTerminalQueries'));
      expect(html, contains('xterm.js browser host'));
      expect(html, contains('const reportedColorScheme = 1;'));
    });

    test('defaultPageHtml derives a light color scheme from a light background', () {
      final html = BrowserTerminalHostServer.defaultPageHtml(
        title: 'Light Browser Test',
        webSocketPath: '/ws',
        background: '#f8fafc',
      );

      expect(html, contains('const reportedColorScheme = 2;'));
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

    test('failed websocket upgrades return bad request and keep the host alive', () async {
      final server = await BrowserTerminalHostServer.bind(
        port: 0,
        title: 'Bad Upgrade Test',
        onSession: (_) async {},
      );
      addTearDown(() => server.close(force: true));

      final client = io.HttpClient();
      addTearDown(() => client.close(force: true));

      final badUpgradeRequest = await client.getUrl(
        server.pageUri.replace(path: server.webSocketPath),
      );
      final badUpgradeResponse = await badUpgradeRequest.close();
      await badUpgradeResponse.drain<void>();
      expect(badUpgradeResponse.statusCode, io.HttpStatus.badRequest);

      final pageRequest = await client.getUrl(server.pageUri);
      final pageResponse = await pageRequest.close();
      final pageBody = await pageResponse.transform(io.systemEncoding.decoder).join();

      expect(pageResponse.statusCode, io.HttpStatus.ok);
      expect(pageBody, contains('Bad Upgrade Test'));
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

    test(
      'websocket disconnect delivers InterruptMsg to the hosted program',
      () async {
        final interrupted = Completer<void>();
        final server = await BrowserTerminalHostServer.serveProgram(
          port: 0,
          title: 'Disconnect Test',
          modelBuilder: () => _BrowserDisconnectAwareModel(interrupted),
          options: const ProgramOptions(
            altScreen: false,
            frameTick: false,
            signalHandlers: false,
          ),
        );
        addTearDown(() => server.close(force: true));

        final socket = await io.WebSocket.connect(server.webSocketUri.toString());
        final outputReady = Completer<void>();
        late final StreamSubscription<dynamic> subscription;
        subscription = socket.listen((event) {
          final message = TerminalBridgeMessage.decodeJson(event as String);
          if (message.type == TerminalBridgeMessageType.output &&
              (message.data ?? '').contains('Browser Disconnect Model') &&
              !outputReady.isCompleted) {
            outputReady.complete();
          }
        });
        addTearDown(subscription.cancel);

        await outputReady.future.timeout(const Duration(seconds: 5));
        await socket.close();
        await interrupted.future.timeout(const Duration(seconds: 5));
      },
    );

    test('close(force: true) tears down active websocket sessions', () async {
      final sessionStarted = Completer<void>();
      final sessionDone = Completer<void>();
      final server = await BrowserTerminalHostServer.bind(
        port: 0,
        title: 'Force Close Test',
        onSession: (socket) async {
          if (!sessionStarted.isCompleted) {
            sessionStarted.complete();
          }
          try {
            await socket.done;
          } finally {
            if (!sessionDone.isCompleted) {
              sessionDone.complete();
            }
          }
        },
      );

      final socket = await io.WebSocket.connect(server.webSocketUri.toString());
      final socketClosed = Completer<void>();
      final subscription = socket.listen(
        (_) {},
        onDone: () {
          if (!socketClosed.isCompleted) {
            socketClosed.complete();
          }
        },
      );
      addTearDown(subscription.cancel);
      await sessionStarted.future.timeout(const Duration(seconds: 5));
      await server.close(force: true);
      await sessionDone.future.timeout(const Duration(seconds: 5));
      await socketClosed.future.timeout(const Duration(seconds: 5));
    });

    test('close(force: true) waits for websocket session cleanup', () async {
      final sessionStarted = Completer<void>();
      final cleanupStarted = Completer<void>();
      final allowCleanup = Completer<void>();
      final cleanupFinished = Completer<void>();
      final server = await BrowserTerminalHostServer.bind(
        port: 0,
        title: 'Force Close Wait Test',
        onSession: (socket) async {
          if (!sessionStarted.isCompleted) {
            sessionStarted.complete();
          }
          await socket.done;
          if (!cleanupStarted.isCompleted) {
            cleanupStarted.complete();
          }
          await allowCleanup.future;
          if (!cleanupFinished.isCompleted) {
            cleanupFinished.complete();
          }
        },
      );

      final socket = await io.WebSocket.connect(server.webSocketUri.toString());
      addTearDown(socket.close);

      await sessionStarted.future.timeout(const Duration(seconds: 5));
      var closeCompleted = false;
      final closeFuture = server.close(force: true).then((_) {
        closeCompleted = true;
      });

      await cleanupStarted.future.timeout(const Duration(seconds: 5));
      await Future<void>.delayed(Duration.zero);
      expect(closeCompleted, isFalse);

      allowCleanup.complete();
      await closeFuture.timeout(const Duration(seconds: 5));
      await cleanupFinished.future.timeout(const Duration(seconds: 5));
    });

    test('close is idempotent after serving requests', () async {
      final server = await BrowserTerminalHostServer.bind(
        port: 0,
        title: 'Idempotent Close Test',
        onSession: (_) async {},
      );

      final client = io.HttpClient();
      addTearDown(() => client.close(force: true));
      final request = await client.getUrl(server.pageUri);
      final response = await request.close();
      await response.drain<void>();

      await server.close();
      await server.close(force: true);
    });

    test('synchronous session handler errors still clean up websockets', () async {
      var accepted = 0;
      final server = await BrowserTerminalHostServer.bind(
        port: 0,
        title: 'Sync Error Test',
        onSession: (socket) {
          accepted++;
          throw StateError('boom');
        },
      );
      addTearDown(() => server.close(force: true));

      Future<void> expectDisconnect() async {
        final socket = await io.WebSocket.connect(server.webSocketUri.toString());
        final closed = Completer<void>();
        final subscription = socket.listen(
          (_) {},
          onDone: () {
            if (!closed.isCompleted) {
              closed.complete();
            }
          },
        );
        addTearDown(subscription.cancel);
        addTearDown(socket.close);
        await closed.future.timeout(const Duration(seconds: 5));
      }

      await expectDisconnect();
      await expectDisconnect();
      expect(accepted, 2);
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

class _BrowserDisconnectAwareModel implements Model {
  const _BrowserDisconnectAwareModel(this.interrupted);

  final Completer<void> interrupted;

  @override
  Cmd? init() => null;

  @override
  (Model, Cmd?) update(Msg msg) {
    return switch (msg) {
      InterruptMsg() => (
        this,
        Cmd(() async {
          if (!interrupted.isCompleted) {
            interrupted.complete();
          }
          return QuitMsg();
        }),
      ),
      _ => (this, null),
    };
  }

  @override
  String view() => 'Browser Disconnect Model';
}
