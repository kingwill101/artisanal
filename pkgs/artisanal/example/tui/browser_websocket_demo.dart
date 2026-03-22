// tui:allow-stdout
import 'dart:async';
import 'dart:io' as io;

import 'package:artisanal/hosts.dart';
import 'package:artisanal/runtime.dart';

void main(List<String> args) async {
  final port = _parsePort(args);
  final server = await BrowserTerminalHostServer.serveProgram(
    port: port,
    title: 'Artisanal Browser Host Demo',
    modelBuilder: () => const _BrowserDemoModel(),
    options: const ProgramOptions(
      altScreen: false,
      frameTick: false,
      signalHandlers: false,
      startupTitle: 'Artisanal Browser Host Demo',
    ),
  );

  io.stdout.writeln('Browser websocket demo listening on ${server.pageUri}');
  io.stdout.writeln('Press Ctrl+C to stop the server.');

  final done = Completer<void>();
  late final StreamSubscription<io.ProcessSignal> sigintSubscription;
  sigintSubscription = io.ProcessSignal.sigint.watch().listen((_) async {
    await sigintSubscription.cancel();
    await server.close(force: true);
    if (!done.isCompleted) done.complete();
  });

  await done.future;
}

int _parsePort(List<String> args) {
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg == '--port' && i + 1 < args.length) {
      return int.tryParse(args[i + 1]) ?? 8080;
    }
    if (arg.startsWith('--port=')) {
      return int.tryParse(arg.substring('--port='.length)) ?? 8080;
    }
  }
  return 8080;
}

class _BrowserDemoModel implements Model {
  const _BrowserDemoModel({
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
        _BrowserDemoModel(
          count: count,
          width: width,
          height: height,
          lastInput: lastInput,
        ),
        null,
      ),
      KeyMsg(key: Key(type: KeyType.up)) ||
      KeyMsg(key: Key(type: KeyType.runes, runes: [0x2b])) => (
        _BrowserDemoModel(
          count: count + 1,
          width: width,
          height: height,
          lastInput: '+ / up',
        ),
        null,
      ),
      KeyMsg(key: Key(type: KeyType.down)) ||
      KeyMsg(key: Key(type: KeyType.runes, runes: [0x2d])) => (
        _BrowserDemoModel(
          count: count - 1,
          width: width,
          height: height,
          lastInput: '- / down',
        ),
        null,
      ),
      KeyMsg(key: Key(type: KeyType.runes, runes: [0x72])) => (
        _BrowserDemoModel(
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
        _BrowserDemoModel(
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
Artisanal Browser Host Demo
===========================

Count: $count
Viewport: ${width}x$height
Last input: $lastInput

Controls:
  + / Up     increment
  - / Down   decrement
  r          reset
  q          quit session

This session is running through BrowserTerminalHostServer
and ProgramHost.webSocket(...).
''';
}
