import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:artisanal/src/terminal/terminal.dart';
import 'package:test/test.dart';

void main() {
  group('TerminalBridgeMessage', () {
    test('output round-trips through JSON', () {
      const message = TerminalBridgeMessage.output('\u001b[31mhello');
      final decoded = TerminalBridgeMessage.decodeJson(message.encodeJson());

      expect(decoded.type, TerminalBridgeMessageType.output);
      expect(decoded.data, '\u001b[31mhello');
    });

    test('binary input round-trips through JSON', () {
      final message = TerminalBridgeMessage.inputBytes(const [0, 3, 27, 255]);
      final decoded = TerminalBridgeMessage.decodeJson(message.encodeJson());

      expect(decoded.type, TerminalBridgeMessageType.inputBytes);
      expect(decoded.decodeBytes(), const [0, 3, 27, 255]);
    });

    test('resize round-trips through JSON', () {
      const message = TerminalBridgeMessage.resize(width: 132, height: 40);
      final decoded = TerminalBridgeMessage.decodeJson(message.encodeJson());

      expect(decoded.type, TerminalBridgeMessageType.resize);
      expect(decoded.width, 132);
      expect(decoded.height, 40);
    });
  });

  group('TerminalBridgeJsonChannel', () {
    test('encodes bridge output as outbound JSON messages', () async {
      final bridge = TerminalBridge();
      final channel = TerminalBridgeJsonChannel(bridge);
      final outboundFuture = channel.outboundMessages.first;

      bridge.terminal.setTitle('Protocol');
      final outbound = TerminalBridgeMessage.decodeJson(await outboundFuture);

      expect(outbound.type, TerminalBridgeMessageType.output);
      expect(outbound.data, contains('Protocol'));

      await channel.dispose();
      bridge.dispose();
    });

    test('applies inbound text, resize, and shutdown messages', () async {
      final bridge = TerminalBridge();
      final channel = TerminalBridgeJsonChannel(bridge);
      final inputFuture = bridge.backend.inputStream!.first;
      final resizeFuture = bridge.backend.resizeStream!.first;
      final shutdownFuture = bridge.backend.shutdownStream!.first;

      channel.addInboundJson(
        const TerminalBridgeMessage.inputText('abc').encodeJson(),
      );
      channel.addInboundJson(
        const TerminalBridgeMessage.resize(width: 120, height: 50).encodeJson(),
      );
      channel.addInboundJson(
        const TerminalBridgeMessage.shutdown().encodeJson(),
      );

      expect(utf8.decode(await inputFuture), 'abc');
      expect(await resizeFuture, (width: 120, height: 50));
      await shutdownFuture;

      await channel.dispose();
      bridge.dispose();
    });

    test('bindInbound wires a stream of JSON host messages', () async {
      final bridge = TerminalBridge();
      final channel = TerminalBridgeJsonChannel(bridge);
      final inputFuture = bridge.backend.inputStream!.first;
      final controller = StreamController<String>();

      channel.bindInbound(controller.stream);
      controller.add(const TerminalBridgeMessage.inputText('q').encodeJson());
      await controller.close();

      expect(utf8.decode(await inputFuture), 'q');

      await channel.dispose();
      bridge.dispose();
    });

    test(
      'rejects outbound messages sent back as inbound host messages',
      () async {
        final bridge = TerminalBridge();
        final channel = TerminalBridgeJsonChannel(bridge);

        expect(
          () => channel.addInboundJson(
            const TerminalBridgeMessage.output('bad').encodeJson(),
          ),
          throwsA(isA<ArgumentError>()),
        );
        final doneExpectation = expectLater(
          channel.outboundMessages,
          emitsDone,
        );
        await channel.dispose();
        bridge.dispose();
        await doneExpectation;
      },
    );
  });

  group('JsonTerminalBackend', () {
    test('encodes runtime output and decodes inbound messages', () async {
      final sentMessages = <String>[];
      final inbound = StreamController<Object?>();
      final backend = JsonTerminalBackend(
        sendMessage: sentMessages.add,
        inboundMessages: inbound.stream,
      );
      final terminal = BackendTerminal(backend);

      final inputFuture = backend.inputStream!.first;
      final resizeFuture = backend.resizeStream!.first;
      final shutdownFuture = backend.shutdownStream!.first;

      terminal.setTitle('JSON backend');
      inbound.add(const TerminalBridgeMessage.inputText('abc').encodeJson());
      inbound.add(
        utf8.encode(
          const TerminalBridgeMessage.resize(
            width: 101,
            height: 28,
          ).encodeJson(),
        ),
      );
      inbound.add(const TerminalBridgeMessage.shutdown().encodeJson());

      final outbound = TerminalBridgeMessage.decodeJson(sentMessages.single);
      expect(outbound.type, TerminalBridgeMessageType.output);
      expect(outbound.data, contains('JSON backend'));
      expect(utf8.decode(await inputFuture), 'abc');
      expect(await resizeFuture, (width: 101, height: 28));
      await shutdownFuture;

      terminal.dispose();
      await inbound.close();
    });

    test('routes protocol misuse into the input error stream', () async {
      final inbound = StreamController<Object?>();
      final backend = JsonTerminalBackend(
        sendMessage: (_) {},
        inboundMessages: inbound.stream,
      );
      final errorFuture = expectLater(
        backend.inputStream!,
        emitsError(isA<ArgumentError>()),
      );
      inbound.add(const TerminalBridgeMessage.output('bad').encodeJson());
      await errorFuture;

      backend.dispose();
      await inbound.close();
    });

    test('closeTransport is invoked on dispose', () async {
      var closed = false;
      final inbound = StreamController<Object?>();
      final backend = JsonTerminalBackend(
        sendMessage: (_) {},
        inboundMessages: inbound.stream,
        closeTransport: () async {
          closed = true;
        },
      );

      backend.dispose();
      await Future<void>.delayed(Duration.zero);

      expect(closed, isTrue);
      await inbound.close();
    });

    test(
      'ignores late output writes after the transport sink closes',
      () async {
        final inbound = StreamController<Object?>();
        var writes = 0;
        final backend = JsonTerminalBackend(
          sendMessage: (_) {
            writes++;
            throw StateError('closed');
          },
          inboundMessages: inbound.stream,
        );
        final terminal = BackendTerminal(backend);

        expect(() => terminal.setTitle('late write'), returnsNormally);
        expect(writes, 1);

        terminal.dispose();
        await inbound.close();
      },
    );

    test('closing inbound transport emits shutdown', () async {
      final inbound = StreamController<Object?>();
      final backend = JsonTerminalBackend(
        sendMessage: (_) {},
        inboundMessages: inbound.stream,
      );

      final shutdownFuture = backend.shutdownStream!.first;
      await inbound.close();
      await shutdownFuture;

      backend.dispose();
    });
  });

  group('WebSocketTerminalBackend', () {
    test(
      'bridges websocket JSON messages into runtime input and output',
      () async {
        final server = await io.HttpServer.bind(
          io.InternetAddress.loopbackIPv4,
          0,
        );
        final acceptedSocket = server
            .transform(io.WebSocketTransformer())
            .first;
        final client = await io.WebSocket.connect(
          'ws://${server.address.address}:${server.port}',
        );
        final serverSocket = await acceptedSocket;

        final backend = WebSocketTerminalBackend(serverSocket);
        final terminal = BackendTerminal(backend);
        final outputFuture = client.first;
        final inputFuture = backend.inputStream!.first;

        terminal.setTitle('ws');
        client.add(const TerminalBridgeMessage.inputText('q').encodeJson());

        final outbound = TerminalBridgeMessage.decodeJson(
          await outputFuture as String,
        );
        expect(outbound.type, TerminalBridgeMessageType.output);
        expect(outbound.data, contains('ws'));
        expect(utf8.decode(await inputFuture), 'q');

        terminal.dispose();
        await client.close();
        await server.close(force: true);
      },
    );
  });
}
