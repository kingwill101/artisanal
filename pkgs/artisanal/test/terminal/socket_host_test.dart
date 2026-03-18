import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:artisanal/tui.dart';
import 'package:test/test.dart';

void main() {
  group('SocketTerminalHostServer', () {
    test('resize control sequence uses the OSC 9999 protocol', () {
      expect(
        SocketTerminalHostServer.resizeControlSequence(width: 120, height: 40),
        '\x1b]9999;120;40\x07',
      );
      expect(
        utf8.decode(
          SocketTerminalHostServer.resizeControlBytes(width: 64, height: 20),
        ),
        '\x1b]9999;64;20\x07',
      );
    });

    test('bind accepts a socket session', () async {
      final connectedPort = Completer<int>();
      final server = await SocketTerminalHostServer.bind(
        port: 0,
        onSession: (socket) async {
          connectedPort.complete(socket.remotePort);
          socket.write('hello');
          await socket.flush();
        },
      );
      addTearDown(server.close);

      final client = await io.Socket.connect(
        io.InternetAddress.loopbackIPv4,
        server.server.port,
      );
      addTearDown(client.close);

      final output = await utf8.decoder
          .bind(client)
          .first
          .timeout(const Duration(seconds: 5));

      expect(await connectedPort.future, client.port);
      expect(output, contains('hello'));
    });

    test('serveProgram runs a TUI session over a raw socket', () async {
      final server = await SocketTerminalHostServer.serveProgram(
        port: 0,
        modelBuilder: () => const _SocketHostModel(),
        options: const ProgramOptions(
          altScreen: false,
          frameTick: false,
          signalHandlers: false,
        ),
      );
      addTearDown(server.close);

      final client = await io.Socket.connect(
        io.InternetAddress.loopbackIPv4,
        server.server.port,
      );
      addTearDown(client.close);

      final outputBuffer = StringBuffer();
      final initialOutputReady = Completer<void>();
      final resizedOutputReady = Completer<void>();
      final streamClosed = Completer<void>();
      late final StreamSubscription<String> outputSubscription;
      outputSubscription = utf8.decoder.bind(client).listen(
        (chunk) {
          outputBuffer.write(chunk);
          final output = outputBuffer.toString();
          if (!initialOutputReady.isCompleted &&
              output.contains('Socket Host Test Model')) {
            initialOutputReady.complete();
          }
          if (!resizedOutputReady.isCompleted &&
              output.contains('Viewport: 120x40')) {
            resizedOutputReady.complete();
          }
        },
        onDone: () {
          if (!streamClosed.isCompleted) {
            streamClosed.complete();
          }
        },
      );
      addTearDown(outputSubscription.cancel);

      await initialOutputReady.future.timeout(const Duration(seconds: 5));

      client.add(
        SocketTerminalHostServer.resizeControlBytes(width: 120, height: 40),
      );
      await client.flush();
      await resizedOutputReady.future.timeout(const Duration(seconds: 5));

      client.write('q');
      await client.flush();
      await streamClosed.future.timeout(const Duration(seconds: 5));
    });
  });
}

class _SocketHostModel implements Model {
  const _SocketHostModel({this.width = 80, this.height = 24});

  final int width;
  final int height;

  @override
  Cmd? init() => null;

  @override
  (Model, Cmd?) update(Msg msg) {
    return switch (msg) {
      WindowSizeMsg(width: final width, height: final height) => (
        _SocketHostModel(width: width, height: height),
        null,
      ),
      KeyMsg(key: Key(type: KeyType.runes, runes: [0x71])) ||
      InterruptMsg() => (this, Cmd.quit()),
      _ => (this, null),
    };
  }

  @override
  String view() => '''
Socket Host Test Model
======================

Viewport: ${width}x$height
Press q to close.
''';
}
