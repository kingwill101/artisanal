import 'dart:async';
import 'dart:io' as io;

import 'package:artisanal/tui.dart';
import 'package:test/test.dart';

void main() {
  group('BrowserTerminalHostServer', () {
    test('defaultPageHtml wires the websocket path and browser terminal helpers', () {
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
      expect(html, contains('rgb:e6e6/eded/f3f3'));
      expect(html, contains('rgb:1010/1313/1818'));
      expect(html, contains('rgb:5858/a6a6/ffff'));
      expect(html, contains(r"const requestCursorPosition = '\x1b[6n';"));
      expect(
        html,
        contains(r"const requestExtendedCursorPosition = '\x1b[?6n';"),
      );
      expect(
        html,
        contains(r"const requestSecondaryDeviceAttributes = '\x1b[>c';"),
      );
      expect(html, contains(r"const requestTermcapPrefix = '\x1bP+q';"));
      expect(html, contains(r"const stringTerminator = '\x1b\\';"));
      expect(html, contains(r"const requestKittyKeyboard = '\x1b[?u';"));
      expect(html, contains(r"const requestWindowSize = '\x1b[18t';"));
      expect(html, contains(r"const requestWindowPixelSize = '\x1b[14t';"));
      expect(html, contains(r"const requestCellSize = '\x1b[16t';"));
      expect(html, contains(r"const reportedSecondaryDeviceAttributes = '\x1b[>0;0;0c';"));
      expect(html, contains(r"const reportedKittyKeyboard = '\x1b[?u';"));
      expect(html, contains('function terminalPixelSize()'));
      expect(html, contains('function terminalCellSize()'));
      expect(html, contains('function cursorPositionReport(extended)'));
      expect(html, contains('function decodeHexBytes(hex)'));
      expect(html, contains('function encodeHexBytes(text)'));
      expect(html, contains('function termcapResponsePayload(requestPayload)'));
      expect(html, contains('data: reportedSecondaryDeviceAttributes'));
      expect(html, contains(r"data: '\x1bP1+r' + responsePayload + '\x1b\\'"));
      expect(html, contains('data: reportedKittyKeyboard'));
      expect(html, contains("encodeHexBytes('TN') + '=' + encodeHexBytes('xterm.js')"));
      expect(html, contains("data: cursorPositionReport(false)"));
      expect(html, contains("data: cursorPositionReport(true)"));
      expect(html, contains(r"data: `\x1b[8;${term.rows};${term.cols}t`"));
      expect(
        html,
        contains(r"data: `\x1b[4;${pixels.height};${pixels.width}t`"),
      );
      expect(
        html,
        contains(r"data: `\x1b[6;${cell.height};${cell.width}t`"),
      );
      expect(html, contains("window.addEventListener('focus'"));
      expect(html, contains("window.addEventListener('blur'"));
      expect(html, contains("window.addEventListener('paste'"));
      expect(html, contains('focusReportingEnabled = true;'));
      expect(html, contains('bracketedPasteEnabled = true;'));
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
