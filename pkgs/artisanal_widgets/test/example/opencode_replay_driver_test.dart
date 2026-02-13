import 'dart:convert';
import 'dart:io';

import 'package:artisanal/tui.dart' as tui;
import 'package:test/test.dart';

import '../../example/opencode/replay_driver.dart';

void main() {
  group('OpenCode replay driver', () {
    test('resolves bundled scenario by short name', () async {
      final plan = await loadOpenCodeReplayPlanFromArgs([
        '--replay-scenario',
        'baseline_scroll',
        '--replay-keep-open',
      ]);

      expect(plan, isNotNull);
      expect(plan!.path, contains('baseline_scroll.json'));
      final firstRaw = await plan.replay.toStream().first;
      final first = plan.interceptor.onSend(firstRaw);
      expect(first, isA<tui.MouseMsg>());
    });

    test('loads scenario and appends QuitMsg by default', () async {
      final file = await _writeScenarioFile({
        'name': 'unit-basic',
        'actions': [
          {'type': 'text', 'value': 'ab'},
        ],
      });
      addTearDown(() async {
        if (await file.exists()) await file.delete();
      });

      final plan = await loadOpenCodeReplayPlanFromArgs([
        '--replay-scenario',
        file.path,
      ]);

      expect(plan, isNotNull);
      final events = await plan!.replay.toStream().toList();
      expect(events, hasLength(3));
      expect(events[0], isA<tui.KeyMsg>());
      expect((events[0] as tui.KeyMsg).key.runes, [0x61]);
      expect(events[1], isA<tui.KeyMsg>());
      expect((events[1] as tui.KeyMsg).key.runes, [0x62]);
      expect(events[2], isA<tui.QuitMsg>());
    });

    test('supports drag action and keep-open mode', () async {
      final file = await _writeScenarioFile({
        'name': 'unit-drag',
        'actions': [
          {'type': 'drag', 'x': 10, 'y': 5, 'x2': 10, 'y2': 9, 'steps': 2},
        ],
      });
      addTearDown(() async {
        if (await file.exists()) await file.delete();
      });

      final plan = await loadOpenCodeReplayPlanFromArgs([
        '--replay-scenario',
        file.path,
        '--replay-keep-open',
      ]);

      expect(plan, isNotNull);
      final rawEvents = await plan!.replay.toStream().toList();
      final events = rawEvents
          .map((event) => plan.interceptor.onSend(event) ?? event)
          .toList(growable: false);
      expect(events.last, isNot(isA<tui.QuitMsg>()));
      expect(events.first, isA<tui.MouseMsg>());
      final press = events.first as tui.MouseMsg;
      expect(press.action, tui.MouseAction.press);
      expect(press.button, tui.MouseButton.left);

      final release = events.last as tui.MouseMsg;
      expect(release.action, tui.MouseAction.release);
      expect(release.button, tui.MouseButton.left);
      expect(release.y, 9);
    });

    test('scales replay mouse coordinates to current terminal size', () async {
      final file = await _writeScenarioFile({
        'name': 'unit-scale',
        'screen': {'width': 120, 'height': 40},
        'actions': [
          {'type': 'tap', 'x': 119, 'y': 39},
        ],
      });
      addTearDown(() async {
        if (await file.exists()) await file.delete();
      });

      final plan = await loadOpenCodeReplayPlanFromArgs([
        '--replay-scenario',
        file.path,
        '--replay-keep-open',
      ]);

      expect(plan, isNotNull);
      final rawFirst = await plan!.replay.toStream().first;
      plan.interceptor.onProcessed(
        const tui.WindowSizeMsg(80, 24),
        Duration.zero,
      );
      final translated = plan.interceptor.onSend(rawFirst);
      expect(translated, isA<tui.MouseMsg>());
      final mouse = translated as tui.MouseMsg;
      expect(mouse.x, 79);
      expect(mouse.y, 23);
    });

    test('preserves fixed right pane while scaling replay X', () async {
      final file = await _writeScenarioFile({
        'name': 'unit-scale-fixed-right',
        'screen': {'width': 176, 'height': 39, 'fixedRightWidth': 42},
        'actions': [
          {'type': 'tap', 'x': 133, 'y': 28},
        ],
      });
      addTearDown(() async {
        if (await file.exists()) await file.delete();
      });

      final plan = await loadOpenCodeReplayPlanFromArgs([
        '--replay-scenario',
        file.path,
        '--replay-keep-open',
      ]);

      expect(plan, isNotNull);
      final rawFirst = await plan!.replay.toStream().first;
      plan.interceptor.onProcessed(
        const tui.WindowSizeMsg(80, 24),
        Duration.zero,
      );
      final translated = plan.interceptor.onSend(rawFirst);
      expect(translated, isA<tui.MouseMsg>());
      final mouse = translated as tui.MouseMsg;
      expect(mouse.x, 37);
      expect(mouse.y, 17);
    });

    test('parses replay block-input flag', () async {
      final file = await _writeScenarioFile({
        'name': 'unit-block-input',
        'actions': [
          {'type': 'text', 'value': 'x'},
        ],
      });
      addTearDown(() async {
        if (await file.exists()) await file.delete();
      });

      final plan = await loadOpenCodeReplayPlanFromArgs([
        '--replay-scenario',
        file.path,
        '--replay-block-input',
      ]);

      expect(plan, isNotNull);
      expect(plan!.blockInput, isTrue);
    });

    test('loop mode repeats stream events', () async {
      final file = await _writeScenarioFile({
        'name': 'unit-loop',
        'actions': [
          {'type': 'text', 'value': 'x'},
        ],
      });
      addTearDown(() async {
        if (await file.exists()) await file.delete();
      });

      final plan = await loadOpenCodeReplayPlanFromArgs([
        '--replay-scenario',
        file.path,
        '--replay-loop',
        '--replay-keep-open',
      ]);

      expect(plan, isNotNull);
      final events = await plan!.replay.toStream().take(3).toList();
      expect(events, hasLength(3));
      expect(events.every((e) => e is tui.KeyMsg), isTrue);
    });

    test('invalid replay speed throws FormatException', () async {
      final file = await _writeScenarioFile({
        'name': 'unit-speed',
        'actions': [
          {'type': 'text', 'value': 'z'},
        ],
      });
      addTearDown(() async {
        if (await file.exists()) await file.delete();
      });

      await expectLater(
        () async => loadOpenCodeReplayPlanFromArgs([
          '--replay-scenario',
          file.path,
          '--replay-speed',
          '0',
        ]),
        throwsA(isA<FormatException>()),
      );
    });
  });
}

Future<File> _writeScenarioFile(Map<String, Object?> json) async {
  final dir = await Directory.systemTemp.createTemp('opencode-replay-test-');
  final file = File('${dir.path}/scenario.json');
  await file.writeAsString('${jsonEncode(json)}\n');
  return file;
}
