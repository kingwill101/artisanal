import 'dart:async';
import 'dart:io' as io;

import 'package:artisanal/tui.dart';

/// Demonstrates driving a TUI through [TerminalBridge] instead of stdio.
///
/// This is the shape a browser terminal, socket bridge, or GUI host would use:
/// - consume `bridge.output`
/// - forward host input with `bridge.addInputString(...)`
/// - report viewport changes with `bridge.resize(...)`
void main() async {
  final bridge = TerminalBridge(initialSize: (width: 80, height: 16));
  final outputSub = bridge.output.listen(io.stdout.write);

  // Scripted host input so the demo can run without interactive stdio wiring.
  unawaited(() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    bridge.addInputString('+');
    await Future<void>.delayed(const Duration(milliseconds: 250));
    bridge.addInputString('+');
    await Future<void>.delayed(const Duration(milliseconds: 250));
    bridge.addInputString('q');
  }());

  try {
    await runProgram(
      const _BridgeCounterModel(),
      options: const ProgramOptions(
        altScreen: false,
        frameTick: false,
        signalHandlers: false,
      ),
      host: ProgramHost.bridge(bridge),
    );
  } finally {
    await outputSub.cancel();
    bridge.dispose();
  }
}

class _BridgeCounterModel implements Model {
  const _BridgeCounterModel([this.count = 0]);

  final int count;

  @override
  Cmd? init() => null;

  @override
  (Model, Cmd?) update(Msg msg) {
    return switch (msg) {
      KeyMsg(key: Key(type: KeyType.runes, runes: [0x2b])) => (
        _BridgeCounterModel(count + 1),
        null,
      ),
      KeyMsg(key: Key(type: KeyType.runes, runes: [0x71])) => (
        this,
        Cmd.quit(),
      ),
      _ => (this, null),
    };
  }

  @override
  String view() =>
      '''
Bridge Host Demo
================

Count: $count

This program is not using stdio directly.
The host feeds input through TerminalBridge.

Scripted host actions:
  + increment
  + increment
  q quit
''';
}
