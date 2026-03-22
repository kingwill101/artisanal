import 'dart:async';

import 'package:artisanal/runtime.dart';
import 'package:test/test.dart';

void main() {
  group('Program macro recorder', () {
    test('records timed key messages', () async {
      final terminal = StringTerminal(terminalWidth: 40, terminalHeight: 8);
      final program = Program<_MacroEchoModel>(
        const _MacroEchoModel(),
        options: const ProgramOptions(
          altScreen: false,
          hideCursor: false,
          frameTick: false,
          startupProbes: false,
          useUltravioletRenderer: false,
        ),
        terminal: terminal,
      );

      final runFuture = program.run();
      program.startMacroRecording();
      program.send(KeyMsg(const Key(KeyType.runes, runes: [0x61])));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      program.send(KeyMsg(const Key(KeyType.runes, runes: [0x62])));
      final macro = program.stopMacroRecording();
      program.send(const QuitMsg());
      await runFuture;

      expect(macro.steps, hasLength(2));
      expect(macro.steps.first.after, Duration.zero);
      expect(
        macro.steps.first.msg,
        const KeyMsg(Key(KeyType.runes, runes: [0x61])),
      );
      expect(
        macro.steps.last.msg,
        const KeyMsg(Key(KeyType.runes, runes: [0x62])),
      );
      expect(macro.steps.last.after, greaterThan(Duration.zero));
    });

    test('rejects nested recordings', () {
      final program = Program<_MacroEchoModel>(const _MacroEchoModel());

      program.startMacroRecording();

      expect(program.startMacroRecording, throwsStateError);
      final macro = program.stopMacroRecording();
      expect(macro.steps, isEmpty);
    });

    test('rejects recording during active macro playback', () async {
      final terminal = StringTerminal(terminalWidth: 40, terminalHeight: 8);
      final program = Program<_MacroCaptureModel>(
        _MacroCaptureModel(onKey: (_) {}),
        options: const ProgramOptions(
          altScreen: false,
          hideCursor: false,
          frameTick: false,
          startupProbes: false,
          useUltravioletRenderer: false,
        ),
        terminal: terminal,
      );
      final macro = ProgramMacro([
        ProgramReplayStep(
          after: const Duration(milliseconds: 25),
          msg: const KeyMsg(Key(KeyType.runes, runes: [0x61])),
        ),
        ProgramReplayStep(
          after: const Duration(milliseconds: 500),
          msg: const KeyMsg(Key(KeyType.runes, runes: [0x62])),
        ),
      ]);

      final runFuture = program.run();
      await _waitUntil(() => terminal.output.isNotEmpty);
      final subscription = program.playMacro(macro);
      await Future<void>.delayed(Duration.zero);
      expect(program.isMacroPlaying, isTrue);

      expect(program.startMacroRecording, throwsStateError);

      await subscription.cancel();
      program.send(const QuitMsg());
      await runFuture;
    });

    test('stopMacroPlayback is idempotent when replay is not active', () async {
      final terminal = StringTerminal(terminalWidth: 40, terminalHeight: 8);
      final program = Program<_MacroCaptureModel>(
        _MacroCaptureModel(onKey: (_) {}),
        options: const ProgramOptions(
          altScreen: false,
          hideCursor: false,
          frameTick: false,
          startupProbes: false,
          useUltravioletRenderer: false,
        ),
        terminal: terminal,
      );

      await program.stopMacroPlayback();
      expect(program.isMacroPlaying, isFalse);
      program.send(const QuitMsg());
    });

    test('plays back a recorded macro on a running program', () async {
      final terminal = StringTerminal(terminalWidth: 40, terminalHeight: 8);
      final played = Completer<void>();
      final macro = ProgramMacro([
        ProgramReplayStep(
          after: Duration.zero,
          msg: const KeyMsg(Key(KeyType.runes, runes: [0x61])),
        ),
        ProgramReplayStep(
          after: const Duration(milliseconds: 5),
          msg: const KeyMsg(Key(KeyType.runes, runes: [0x62])),
        ),
      ]);
      final program = Program<_ObservedMacroEchoModel>(
        _ObservedMacroEchoModel(
          onAb: () {
            if (!played.isCompleted) played.complete();
          },
        ),
        options: const ProgramOptions(
          altScreen: false,
          hideCursor: false,
          frameTick: false,
          startupProbes: false,
          useUltravioletRenderer: false,
        ),
        terminal: terminal,
      );

      final runFuture = program.run();
      await _waitUntil(() => terminal.output.isNotEmpty);
      final playback = program.playMacro(macro);
      await played.future.timeout(const Duration(milliseconds: 250));
      await playback.cancel();
      program.send(const QuitMsg());
      await runFuture;
    });

    test('does not record replayed messages while recording', () async {
      final terminal = StringTerminal(terminalWidth: 40, terminalHeight: 8);
      final keyEvents = <int>[];
      final program = Program<_MacroCaptureModel>(
        _MacroCaptureModel(onKey: keyEvents.add),
        options: const ProgramOptions(
          altScreen: false,
          hideCursor: false,
          frameTick: false,
          startupProbes: false,
          useUltravioletRenderer: false,
        ),
        terminal: terminal,
      );
      final replay = ProgramMacro([
        ProgramReplayStep(
          after: Duration.zero,
          msg: const KeyMsg(Key(KeyType.runes, runes: [0x61])),
        ),
      ]);

      final runFuture = program.run();
      await _waitUntil(() => terminal.output.isNotEmpty);
      program.startMacroRecording();
      final playback = program.playMacro(replay);
      await Future<void>.delayed(const Duration(milliseconds: 5));
      program.send(const KeyMsg(Key(KeyType.runes, runes: [0x62])));
      await Future<void>.delayed(const Duration(milliseconds: 25));
      final macro = program.stopMacroRecording();
      await playback.cancel();
      program.send(const QuitMsg());

      expect(macro.steps, hasLength(1));
      expect(
        macro.steps.single.msg,
        const KeyMsg(Key(KeyType.runes, runes: [0x62])),
      );
      await runFuture;

      expect(keyEvents, equals([0x61, 0x62]));
    });

    test('supports consecutive recording sessions', () async {
      final terminal = StringTerminal(terminalWidth: 40, terminalHeight: 8);
      final keyEvents = <int>[];
      final program = Program<_MacroCaptureModel>(
        _MacroCaptureModel(onKey: keyEvents.add),
        options: const ProgramOptions(
          altScreen: false,
          hideCursor: false,
          frameTick: false,
          startupProbes: false,
          useUltravioletRenderer: false,
        ),
        terminal: terminal,
      );

      final runFuture = program.run();
      await _waitUntil(() => terminal.output.isNotEmpty);

      program.startMacroRecording();
      program.send(const KeyMsg(Key(KeyType.runes, runes: [0x61])));
      final firstMacro = program.stopMacroRecording();
      expect(firstMacro.steps, hasLength(1));
      expect(
        firstMacro.steps.single.msg,
        const KeyMsg(Key(KeyType.runes, runes: [0x61])),
      );

      program.startMacroRecording();
      program.send(const KeyMsg(Key(KeyType.runes, runes: [0x62])));
      final secondMacro = program.stopMacroRecording();
      expect(secondMacro.steps, hasLength(1));
      expect(
        secondMacro.steps.single.msg,
        const KeyMsg(Key(KeyType.runes, runes: [0x62])),
      );

      program.send(const QuitMsg());
      await runFuture;
      expect(keyEvents, equals([0x61, 0x62]));
    });

    test('tracks macro playback state', () async {
      final terminal = StringTerminal(terminalWidth: 40, terminalHeight: 8);
      final keyEvents = <int>[];
      final program = Program<_MacroCaptureModel>(
        _MacroCaptureModel(onKey: keyEvents.add),
        options: const ProgramOptions(
          altScreen: false,
          hideCursor: false,
          frameTick: false,
          startupProbes: false,
          useUltravioletRenderer: false,
        ),
        terminal: terminal,
      );
      final macro = ProgramMacro([
        ProgramReplayStep(
          after: const Duration(milliseconds: 5),
          msg: const KeyMsg(Key(KeyType.runes, runes: [0x61])),
        ),
        ProgramReplayStep(
          after: const Duration(milliseconds: 25),
          msg: const KeyMsg(Key(KeyType.runes, runes: [0x62])),
        ),
      ]);

      final runFuture = program.run();
      await _waitUntil(() => terminal.output.isNotEmpty);

      final subscription = program.playMacro(macro);
      expect(program.isMacroPlaying, isTrue);
      await _waitUntil(() => keyEvents.length == 1);
      await program.stopMacroPlayback();
      await Future<void>.delayed(const Duration(milliseconds: 40));

      expect(program.isMacroPlaying, isFalse);
      expect(keyEvents, equals([0x61]));

      subscription.cancel();
      program.send(const QuitMsg());
      await runFuture;
    });

    test('loops macro playback and stops reliably', () async {
      final terminal = StringTerminal(terminalWidth: 40, terminalHeight: 8);
      final keyEvents = <int>[];
      final program = Program<_MacroCaptureModel>(
        _MacroCaptureModel(onKey: keyEvents.add),
        options: const ProgramOptions(
          altScreen: false,
          hideCursor: false,
          frameTick: false,
          startupProbes: false,
          useUltravioletRenderer: false,
        ),
        terminal: terminal,
      );
      final macro = ProgramMacro([
        ProgramReplayStep(
          after: const Duration(milliseconds: 5),
          msg: const KeyMsg(Key(KeyType.runes, runes: [0x61])),
        ),
        ProgramReplayStep(
          after: const Duration(milliseconds: 5),
          msg: const KeyMsg(Key(KeyType.runes, runes: [0x62])),
        ),
      ]);

      final runFuture = program.run();
      await _waitUntil(() => terminal.output.isNotEmpty);

      final subscription = program.playMacro(macro, loop: true);
      await _waitUntil(() => keyEvents.length >= 4);
      expect(keyEvents.length, greaterThanOrEqualTo(4));
      expect(
        keyEvents.where((value) => value == 0x61).length,
        greaterThanOrEqualTo(2),
      );

      await program.stopMacroPlayback();
      expect(program.isMacroPlaying, isFalse);

      await Future<void>.delayed(const Duration(milliseconds: 30));
      final afterStopCount = keyEvents.length;
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(keyEvents.length, equals(afterStopCount));

      subscription.cancel();
      program.send(const QuitMsg());
      await runFuture;
    });

    test('stops playback without affecting manual messages', () async {
      final terminal = StringTerminal(terminalWidth: 40, terminalHeight: 8);
      final keyEvents = <int>[];
      final program = Program<_MacroCaptureModel>(
        _MacroCaptureModel(onKey: keyEvents.add),
        options: const ProgramOptions(
          altScreen: false,
          hideCursor: false,
          frameTick: false,
          startupProbes: false,
          useUltravioletRenderer: false,
        ),
        terminal: terminal,
      );
      final macro = ProgramMacro([
        ProgramReplayStep(
          after: const Duration(milliseconds: 5),
          msg: const KeyMsg(Key(KeyType.runes, runes: [0x61])),
        ),
        ProgramReplayStep(
          after: const Duration(milliseconds: 30),
          msg: const KeyMsg(Key(KeyType.runes, runes: [0x62])),
        ),
      ]);

      final runFuture = program.run();
      await _waitUntil(() => terminal.output.isNotEmpty);

      final replay = program.playMacro(macro);
      await _waitUntil(() => keyEvents.length == 1);
      await program.stopMacroPlayback();
      expect(program.isMacroPlaying, isFalse);

      program.send(const KeyMsg(Key(KeyType.runes, runes: [0x63])));
      await Future<void>.delayed(const Duration(milliseconds: 40));
      program.send(const QuitMsg());
      await replay.cancel();
      await runFuture;

      expect(keyEvents, equals([0x61, 0x63]));
    });

    test('replays a recorded macro with equivalent behavior', () async {
      final expectedText = 'ab';
      final recordInputs = <int>[0x61, 0x62];
      final recordedTextHistory = <String>[];
      final replayedTextHistory = <String>[];

      String? recordedFinalOutput;
      String? replayedFinalOutput;

      final recordTerminal = StringTerminal(
        terminalWidth: 40,
        terminalHeight: 8,
      );
      final recorder = Program<_MacroTextModel>(
        _MacroTextModel(
          target: expectedText,
          onTextChange: recordedTextHistory.add,
          onDone: (value) {
            recordedFinalOutput = value;
          },
        ),
        options: const ProgramOptions(
          altScreen: false,
          hideCursor: false,
          frameTick: false,
          startupProbes: false,
          useUltravioletRenderer: false,
        ),
        terminal: recordTerminal,
      );

      final recordFuture = recorder.run();
      recorder.startMacroRecording();
      await _waitUntil(() => recordTerminal.output.isNotEmpty);
      for (final rune in recordInputs) {
        recorder.send(KeyMsg(Key(KeyType.runes, runes: [rune])));
        await Future<void>.delayed(const Duration(milliseconds: 8));
      }
      final macro = recorder.stopMacroRecording();
      await recordFuture;

      expect(recordedTextHistory, equals([expectedText[0], expectedText]));
      expect(recordedFinalOutput, expectedText);
      expect(macro.steps, hasLength(2));
      expect(macro.steps[0].after, Duration.zero);
      expect(macro.steps.last.after, greaterThan(Duration.zero));

      final replayTerminal = StringTerminal(
        terminalWidth: 40,
        terminalHeight: 8,
      );
      final replayer = Program<_MacroTextModel>(
        _MacroTextModel(
          target: expectedText,
          onTextChange: replayedTextHistory.add,
          onDone: (value) {
            replayedFinalOutput = value;
          },
        ),
        options: ProgramOptions(
          altScreen: false,
          hideCursor: false,
          frameTick: false,
          startupProbes: false,
          useUltravioletRenderer: false,
          replay: macro.toReplay(),
        ),
        terminal: replayTerminal,
      );

      await replayer.run();

      expect(replayedTextHistory, equals([expectedText[0], expectedText]));
      expect(replayedFinalOutput, expectedText);
      expect(replayedTextHistory, equals(recordedTextHistory));
      expect(replayedFinalOutput, equals(recordedFinalOutput));
    });

    test('preserves macro timing gaps during replay', () async {
      final recordIntervals = <int>[];
      final replayIntervals = <int>[];
      final stopwatch = Stopwatch()..start();

      String? recordedFinal;
      String? replayedFinal;

      final recordingTerminal = StringTerminal(
        terminalWidth: 40,
        terminalHeight: 8,
      );
      final recorder = Program<_MacroTimingModel>(
        _MacroTimingModel(
          target: 'ab',
          onKey: (elapsed) => recordIntervals.add(elapsed),
          onDone: (value) {
            recordedFinal = value;
          },
        ),
        options: ProgramOptions(
          altScreen: false,
          hideCursor: false,
          frameTick: false,
          startupProbes: false,
          useUltravioletRenderer: false,
        ),
        terminal: recordingTerminal,
      );

      final recordFuture = recorder.run();
      recorder.startMacroRecording();
      await _waitUntil(() => recordingTerminal.output.isNotEmpty);
      recorder.send(const KeyMsg(Key(KeyType.runes, runes: [0x61])));
      await Future<void>.delayed(const Duration(milliseconds: 12));
      recorder.send(const KeyMsg(Key(KeyType.runes, runes: [0x62])));
      final macro = recorder.stopMacroRecording();
      expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(10));
      expect(stopwatch.elapsedMilliseconds, lessThan(500));
      await recordFuture;

      expect(macro.steps, hasLength(2));
      expect(macro.steps[0].after, Duration.zero);
      expect(
        macro.steps[1].after,
        greaterThanOrEqualTo(const Duration(milliseconds: 10)),
      );
      expect(recordedFinal, 'ab');

      final replayer = Program<_MacroTimingModel>(
        _MacroTimingModel(
          target: 'ab',
          onKey: (elapsed) => replayIntervals.add(elapsed),
          onDone: (value) {
            replayedFinal = value;
          },
        ),
        options: ProgramOptions(
          altScreen: false,
          hideCursor: false,
          frameTick: false,
          startupProbes: false,
          useUltravioletRenderer: false,
          replay: macro.toReplay(),
        ),
        terminal: StringTerminal(terminalWidth: 40, terminalHeight: 8),
      );

      await replayer.run();

      expect(replayedFinal, 'ab');
      expect(replayIntervals, hasLength(2));
      expect(replayIntervals[0], lessThanOrEqualTo(replayIntervals[1]));
      expect(replayIntervals[1] - replayIntervals[0], greaterThanOrEqualTo(10));
      expect(recordedFinal, replayedFinal);
    });
  });
}

class _MacroEchoModel implements Model {
  const _MacroEchoModel({this.text = ''});

  final String text;

  @override
  Cmd? init() => null;

  @override
  (Model, Cmd?) update(Msg msg) {
    return switch (msg) {
      KeyMsg(:final key)
          when key.type == KeyType.runes && key.runes.isNotEmpty =>
        (
          _MacroEchoModel(text: '$text${String.fromCharCode(key.runes.first)}'),
          null,
        ),
      _ => (this, null),
    };
  }

  @override
  Object view() => View(content: text);
}

class _ObservedMacroEchoModel implements Model {
  _ObservedMacroEchoModel({required this.onAb, this.text = ''});

  final void Function() onAb;
  final String text;

  @override
  Cmd? init() => null;

  @override
  (Model, Cmd?) update(Msg msg) {
    return switch (msg) {
      KeyMsg(:final key)
          when key.type == KeyType.runes && key.runes.isNotEmpty =>
        () {
          final nextText = '$text${String.fromCharCode(key.runes.first)}';
          if (nextText == 'ab') onAb();
          return (_ObservedMacroEchoModel(onAb: onAb, text: nextText), null);
        }(),
      _ => (this, null),
    };
  }

  @override
  Object view() => View(content: text);
}

class _MacroCaptureModel implements Model {
  const _MacroCaptureModel({required this.onKey});

  final void Function(int) onKey;

  @override
  Cmd? init() => null;

  @override
  (Model, Cmd?) update(Msg msg) {
    return switch (msg) {
      KeyMsg(:final key)
          when key.type == KeyType.runes && key.runes.isNotEmpty =>
        (() {
          onKey(key.runes.first);
          return (this, null);
        }()),
      _ => (this, null),
    };
  }

  @override
  Object view() => const View(content: '');
}

class _MacroTimingModel implements Model {
  _MacroTimingModel({
    required this.target,
    required this.onKey,
    required this.onDone,
    Stopwatch? stopwatch,
    this.text = '',
  }) : stopwatch = stopwatch ?? Stopwatch()
         ..start();

  final String target;
  final void Function(int) onKey;
  final void Function(String) onDone;
  final String text;

  final Stopwatch stopwatch;

  @override
  Cmd? init() {
    if (!stopwatch.isRunning) {
      stopwatch.start();
    }
    return null;
  }

  @override
  (Model, Cmd?) update(Msg msg) {
    return switch (msg) {
      KeyMsg(:final key)
          when key.type == KeyType.runes && key.runes.isNotEmpty =>
        () {
          final nextText = '$text${String.fromCharCode(key.runes.first)}';
          onKey(stopwatch.elapsedMilliseconds);
          if (nextText == target) {
            onDone(nextText);
            return (
              _MacroTimingModel(
                target: target,
                onKey: onKey,
                onDone: onDone,
                stopwatch: stopwatch,
                text: nextText,
              ),
              Cmd.quit(),
            );
          }

          return (
            _MacroTimingModel(
              target: target,
              onKey: onKey,
              onDone: onDone,
              stopwatch: stopwatch,
              text: nextText,
            ),
            null,
          );
        }(),
      _ => (this, null),
    };
  }

  @override
  Object view() => View(content: text);
}

class _MacroTextModel implements Model {
  const _MacroTextModel({
    required this.target,
    required this.onTextChange,
    required this.onDone,
    this.text = '',
  });

  final String target;
  final void Function(String) onTextChange;
  final void Function(String) onDone;
  final String text;

  @override
  Cmd? init() => null;

  @override
  (Model, Cmd?) update(Msg msg) {
    return switch (msg) {
      KeyMsg(:final key)
          when key.type == KeyType.runes && key.runes.isNotEmpty =>
        () {
          final nextText = '$text${String.fromCharCode(key.runes.first)}';
          onTextChange(nextText);
          if (nextText == target) {
            onDone(nextText);
            return (
              _MacroTextModel(
                target: target,
                onTextChange: onTextChange,
                onDone: onDone,
                text: nextText,
              ),
              Cmd.quit(),
            );
          }
          return (
            _MacroTextModel(
              target: target,
              onTextChange: onTextChange,
              onDone: onDone,
              text: nextText,
            ),
            null,
          );
        }(),
      _ => (this, null),
    };
  }

  @override
  Object view() => View(content: text);
}

Future<void> _waitUntil(
  bool Function() condition, {
  Duration timeout = const Duration(milliseconds: 250),
  Duration poll = const Duration(milliseconds: 5),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('Timed out waiting for test condition');
    }
    await Future<void>.delayed(poll);
  }
}
