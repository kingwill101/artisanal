// tui:allow-stdout
import 'dart:async';
import 'dart:io' as io;

import 'package:artisanal/hosts.dart';
import 'package:artisanal/runtime.dart';

void main(List<String> args) async {
  final port = _parsePort(args);
  final server = await SocketTerminalHostServer.serveProgram(
    port: port,
    modelBuilder: () => const _SocketDemoModel(),
    options: const ProgramOptions(
      altScreen: false,
      frameTick: false,
      signalHandlers: false,
      startupTitle: 'Artisanal Socket Host Demo',
    ),
  );

  io.stdout.writeln('Socket host demo listening on ${server.uri}');
  io.stdout.writeln('Connect from another terminal with:');
  io.stdout.writeln(
    '  nc ${server.server.address.address} ${server.server.port}',
  );
  io.stdout.writeln('');
  io.stdout.writeln('Clients can report viewport changes by sending:');
  io.stdout.writeln(
    '  ${SocketTerminalHostServer.resizeControlSequence(width: 120, height: 40)}',
  );
  io.stdout.writeln('Press Ctrl+C to stop the server.');

  final done = Completer<void>();
  late final StreamSubscription<io.ProcessSignal> sigintSubscription;
  sigintSubscription = io.ProcessSignal.sigint.watch().listen((_) async {
    await sigintSubscription.cancel();
    await server.close();
    if (!done.isCompleted) done.complete();
  });

  await done.future;
}

int _parsePort(List<String> args) {
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg == '--port' && i + 1 < args.length) {
      return int.tryParse(args[i + 1]) ?? 2323;
    }
    if (arg.startsWith('--port=')) {
      return int.tryParse(arg.substring('--port='.length)) ?? 2323;
    }
  }
  return 2323;
}

class _SocketDemoModel implements Model {
  const _SocketDemoModel({
    this.count = 0,
    this.width = 80,
    this.height = 24,
    this.lastInput = 'none',
  });

  final int count;
  final int width;
  final int height;
  final String lastInput;

  @override
  Cmd? init() => null;

  @override
  (Model, Cmd?) update(Msg msg) {
    return switch (msg) {
      WindowSizeMsg(width: final width, height: final height) => (
        _SocketDemoModel(
          count: count,
          width: width,
          height: height,
          lastInput: lastInput,
        ),
        null,
      ),
      KeyMsg(key: Key(type: KeyType.up)) ||
      KeyMsg(key: Key(type: KeyType.runes, runes: [0x2b])) => (
        _SocketDemoModel(
          count: count + 1,
          width: width,
          height: height,
          lastInput: '+ / up',
        ),
        null,
      ),
      KeyMsg(key: Key(type: KeyType.down)) ||
      KeyMsg(key: Key(type: KeyType.runes, runes: [0x2d])) => (
        _SocketDemoModel(
          count: count - 1,
          width: width,
          height: height,
          lastInput: '- / down',
        ),
        null,
      ),
      KeyMsg(key: Key(type: KeyType.runes, runes: [0x72])) => (
        _SocketDemoModel(
          count: 0,
          width: width,
          height: height,
          lastInput: 'r',
        ),
        null,
      ),
      KeyMsg(key: Key(type: KeyType.runes, runes: [0x71])) ||
      InterruptMsg() => (this, Cmd.quit()),
      KeyMsg(key: final key) => (
        _SocketDemoModel(
          count: count,
          width: width,
          height: height,
          lastInput: key.toString(),
        ),
        null,
      ),
      _ => (this, null),
    };
  }

  @override
  String view() =>
      '''
Artisanal Socket Host Demo
==========================

Count: $count
Viewport: ${width}x$height
Last input: $lastInput

Controls:
  + / Up     increment
  - / Down   decrement
  r          reset
  q          quit session

This session is running through SocketTerminalHostServer
and ProgramHost.socket(...).
''';
}
