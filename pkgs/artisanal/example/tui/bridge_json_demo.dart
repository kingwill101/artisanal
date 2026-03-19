import 'dart:async';
import 'dart:io' as io;

import 'package:artisanal/hosts.dart';
import 'package:artisanal/runtime.dart';

/// Demonstrates the JSON bridge protocol used by remote or browser hosts.
void main() async {
  final bridge = TerminalBridge(initialSize: (width: 72, height: 14));
  final channel = TerminalBridgeJsonChannel(bridge);
  final outputSub = channel.outboundMessages.listen(io.stdout.writeln);

  unawaited(() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    channel.addInboundJson(
      const TerminalBridgeMessage.inputText('+').encodeJson(),
    );
    await Future<void>.delayed(const Duration(milliseconds: 250));
    channel.addInboundJson(
      const TerminalBridgeMessage.inputText('q').encodeJson(),
    );
  }());

  try {
    await runProgram(
      const _JsonBridgeCounterModel(),
      options: const ProgramOptions(
        altScreen: false,
        frameTick: false,
        signalHandlers: false,
      ),
      host: ProgramHost.bridge(bridge),
    );
  } finally {
    await outputSub.cancel();
    await channel.dispose();
    bridge.dispose();
  }
}

class _JsonBridgeCounterModel implements Model {
  const _JsonBridgeCounterModel([this.count = 0]);

  final int count;

  @override
  Cmd? init() => null;

  @override
  (Model, Cmd?) update(Msg msg) {
    return switch (msg) {
      KeyMsg(key: Key(type: KeyType.runes, runes: [0x2b])) => (
        _JsonBridgeCounterModel(count + 1),
        null,
      ),
      KeyMsg(key: Key(type: KeyType.runes, runes: [0x71])) => (this, Cmd.quit()),
      _ => (this, null),
    };
  }

  @override
  String view() => '''
JSON Bridge Demo
================

Count: $count

The host is sending JSON messages:
  {"type":"input.text","data":"+"}
  {"type":"input.text","data":"q"}
''';
}
