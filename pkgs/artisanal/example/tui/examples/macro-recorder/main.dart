/// Macro recorder/player example for the runtime macro APIs.
library;

import 'dart:async';

import 'package:artisanal/runtime.dart' as tui;

const _delayBetweenInputs = Duration(milliseconds: 25);

/// Captures incoming key runes and forwards them to [onInput].
class _MacroCaptureModel implements tui.Model {
  const _MacroCaptureModel({required this.onInput});

  final void Function(int) onInput;

  @override
  tui.Cmd? init() => null;

  @override
  (tui.Model, tui.Cmd?) update(tui.Msg msg) {
    if (msg is tui.KeyMsg) {
      final rune = _primaryRune(msg.key);
      if (rune != null) {
        onInput(rune);
      }
    }
    return (this, null);
  }

  @override
  String view() => 'Waiting for programmatic key traffic...';
}

/// Replays keys and quits after [target] inputs are observed.
class _MacroReplayModel implements tui.Model {
  const _MacroReplayModel({
    required this.target,
    required this.onInput,
    this.count = 0,
  });

  final int target;
  final int count;
  final void Function(int) onInput;

  @override
  tui.Cmd? init() => null;

  @override
  (tui.Model, tui.Cmd?) update(tui.Msg msg) {
    if (msg is tui.KeyMsg) {
      final rune = _primaryRune(msg.key);
      if (rune != null) {
        onInput(rune);
        final nextCount = count + 1;
        if (nextCount >= target) {
          return (
            _MacroReplayModel(
              target: target,
              onInput: onInput,
              count: nextCount,
            ),
            tui.Cmd.quit(),
          );
        }
        return (
          _MacroReplayModel(target: target, onInput: onInput, count: nextCount),
          null,
        );
      }
    }
    return (this, null);
  }

  @override
  String view() => 'Replaying macro input...';
}

int? _primaryRune(tui.Key key) => key.runes.isNotEmpty ? key.runes.first : null;

void main() async {
  final runtimeOptions = const tui.ProgramOptions(
    altScreen: false,
    hideCursor: false,
    frameTick: false,
    startupProbes: false,
    useUltravioletRenderer: false,
  );

  final captured = <int>[];
  final recorder = tui.Program<_MacroCaptureModel>(
    _MacroCaptureModel(onInput: captured.add),
    options: runtimeOptions,
  );
  final recordFuture = recorder.run();

  await Future<void>.delayed(Duration.zero);
  recorder.startMacroRecording();

  recorder.send(const tui.KeyMsg(tui.Key(tui.KeyType.runes, runes: [0x61])));
  await Future<void>.delayed(_delayBetweenInputs);
  recorder.send(const tui.KeyMsg(tui.Key(tui.KeyType.runes, runes: [0x62])));
  await Future<void>.delayed(_delayBetweenInputs);
  recorder.send(const tui.KeyMsg(tui.Key(tui.KeyType.runes, runes: [0x63])));

  final macro = recorder.stopMacroRecording();
  recorder.send(const tui.QuitMsg());
  await recordFuture;

  print('Recorded ${macro.steps.length} macro steps.');
  print('Captured input: ${String.fromCharCodes(captured)}');
  for (var i = 0; i < macro.steps.length; i++) {
    final step = macro.steps[i];
    final msg = step.msg;
    final rune = msg is tui.KeyMsg ? msg.key.runes.first : 63;
    print(
      'step ${i + 1}: rune=${String.fromCharCode(rune)}'
      ' delay=${step.after.inMilliseconds}ms',
    );
  }

  final replayed = <int>[];
  final replay = tui.Program<_MacroReplayModel>(
    _MacroReplayModel(target: macro.steps.length, onInput: replayed.add),
    options: tui.ProgramOptions(
      altScreen: false,
      hideCursor: false,
      frameTick: false,
      startupProbes: false,
      useUltravioletRenderer: false,
      replay: macro.toReplay(),
    ),
  );
  await replay.run();
  print('Replay output: ${String.fromCharCodes(replayed)}');

  final looping = <int>[];
  final loopProgram = tui.Program<_MacroCaptureModel>(
    _MacroCaptureModel(onInput: looping.add),
    options: runtimeOptions,
  );
  final loopFuture = loopProgram.run();

  await Future<void>.delayed(Duration.zero);
  final subscription = loopProgram.playMacro(macro, loop: true);
  await Future<void>.delayed(const Duration(milliseconds: 60));
  print('Loop playback active before stop: ${loopProgram.isMacroPlaying}');
  await loopProgram.stopMacroPlayback();
  print('Loop playback active after stop: ${loopProgram.isMacroPlaying}');
  await Future<void>.delayed(const Duration(milliseconds: 20));
  final eventsAfterStop = looping.length;
  await Future<void>.delayed(const Duration(milliseconds: 20));
  final eventsAfterWait = looping.length;
  print('Looped events captured before stop: $eventsAfterStop');
  print('Looped events still stable after stop: $eventsAfterWait');

  loopProgram.send(const tui.QuitMsg());
  await loopFuture;
  await subscription.cancel();
}
