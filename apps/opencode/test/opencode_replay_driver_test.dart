import 'dart:convert';
import 'dart:io';

import 'package:artisanal/tui.dart' as tui;
import 'package:test/test.dart';

import 'package:opencode/src/opencode/replay_driver.dart';
import 'package:opencode/src/opencode/theme.dart';
import 'package:opencode/src/opencode/generated/builtin_assets.dart';

void main() {
  group('OpenCode replay driver', () {
    test('central parser accepts documented options and theme', () {
      final options = parseOpenCodeCliOptions([
        '--theme=aurora',
        '--replay-trace',
        'trace.log',
        '--replay-speed=1.5',
        '--replay-trace-screen-width',
        '120',
        '--replay-loop',
        '--help',
      ]);

      expect(options.theme, 'aurora');
      expect(options.help, isTrue);
    });

    test('central parser rejects unknown options', () {
      expect(
        () => parseOpenCodeCliOptions(['--replay-scenari', 'demo']),
        throwsA(isA<FormatException>()),
      );
    });

    test('central parser rejects missing and malformed values', () {
      expect(
        () => parseOpenCodeCliOptions(['--theme']),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => parseOpenCodeCliOptions(['--replay-speed', 'fast']),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => parseOpenCodeCliOptions(['--replay-trace-screen-width', 'wide']),
        throwsA(isA<FormatException>()),
      );
    });

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

    test(
      'resolves bundled scenario from an unrelated working directory',
      () async {
        final original = Directory.current;
        final unrelated = await Directory.systemTemp.createTemp(
          'opencode-unrelated-cwd-',
        );
        addTearDown(() async {
          Directory.current = original;
          if (await unrelated.exists()) await unrelated.delete(recursive: true);
        });
        Directory.current = unrelated;

        final plan = await loadOpenCodeReplayPlanFromArgs([
          '--replay-scenario',
          'baseline_scroll',
          '--replay-keep-open',
        ]);

        expect(plan, isNotNull);
        expect(plan!.path, 'builtin:baseline_scroll');
        expect(plan.actionCount, greaterThan(0));
      },
    );

    test('loads a bundled theme from an unrelated working directory', () async {
      final original = Directory.current;
      final unrelated = await Directory.systemTemp.createTemp(
        'opencode-unrelated-theme-cwd-',
      );
      addTearDown(() async {
        Directory.current = original;
        if (await unrelated.exists()) await unrelated.delete(recursive: true);
        resetOpenCodeThemeToDefault();
      });
      Directory.current = unrelated;

      await loadOpenCodeThemeAtLaunch(themeName: 'tokyonight');

      expect(currentOpenCodeThemeName(), 'tokyonight');
    });

    test('generated asset map contains parseable built-ins', () {
      expect(
        openCodeBuiltinAssets.keys.where((key) => key.startsWith('themes/')),
        hasLength(greaterThan(0)),
      );
      expect(
        openCodeBuiltinAssets.keys.where((key) => key.startsWith('scenarios/')),
        hasLength(greaterThan(0)),
      );
      for (final source in openCodeBuiltinAssets.values) {
        expect(jsonDecode(source), isA<Map<String, dynamic>>());
      }
    });

    test('asset generator is reproducible', () async {
      final generated = File(
        'apps/opencode/lib/src/opencode/generated/builtin_assets.dart',
      );
      final before = await generated.readAsBytes();
      final result = await Process.run(Platform.resolvedExecutable, [
        'run',
        'apps/opencode/tool/generate_assets.dart',
      ]);
      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
      expect(await generated.readAsBytes(), orderedEquals(before));
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

    test('converts structured trace via --replay-trace', () async {
      final traceFile = await _writeTraceFile([
        '# trace start: 2026-02-13T00:00:00.000000',
        '[+10us] [input] @event {"v":1,"type":"window.size","width":120,"height":40}',
        '[+20us] [input] @event {"v":1,"type":"input.batch","messages":[{"kind":"mouse","action":"press","button":"left","x":40,"y":10},{"kind":"mouse","action":"release","button":"left","x":40,"y":10}]}',
      ]);
      addTearDown(() async {
        if (await traceFile.exists()) await traceFile.delete();
      });

      final plan = await loadOpenCodeReplayPlanFromArgs([
        '--replay-trace',
        traceFile.path,
        '--replay-keep-open',
      ]);

      expect(plan, isNotNull);
      expect(plan!.traceConversion, isNotNull);
      expect(plan.actionCount, 1);
      final first = await plan.replay.toStream().first;
      final translated = plan.interceptor.onSend(first);
      expect(translated, isA<tui.MouseMsg>());
    });

    test('writes converted scenario with --replay-trace-out', () async {
      final traceFile = await _writeTraceFile([
        '# trace start: 2026-02-13T00:00:00.000000',
        '[+10us] [input] @event {"v":1,"type":"window.size","width":120,"height":40}',
        '[+20us] [input] @event {"v":1,"type":"input.batch","messages":[{"kind":"key","keyType":"runes","runes":[120]}]}',
      ]);
      final outDir = await Directory.systemTemp.createTemp(
        'opencode-replay-out-',
      );
      final outPath = '${outDir.path}/converted.json';
      addTearDown(() async {
        if (await traceFile.exists()) await traceFile.delete();
        if (await File(outPath).exists()) await File(outPath).delete();
        if (await outDir.exists()) await outDir.delete(recursive: true);
      });

      final plan = await loadOpenCodeReplayPlanFromArgs([
        '--replay-trace',
        traceFile.path,
        '--replay-trace-out',
        outPath,
        '--replay-convert-only',
      ]);

      expect(plan, isNotNull);
      expect(plan!.convertOnly, isTrue);
      expect(await File(outPath).exists(), isTrue);
    });
  });
}

Future<File> _writeScenarioFile(Map<String, Object?> json) async {
  final dir = await Directory.systemTemp.createTemp('opencode-replay-test-');
  final file = File('${dir.path}/scenario.json');
  await file.writeAsString('${jsonEncode(json)}\n');
  return file;
}

Future<File> _writeTraceFile(List<String> lines) async {
  final dir = await Directory.systemTemp.createTemp(
    'opencode-replay-trace-test-',
  );
  final file = File('${dir.path}/trace.log');
  await file.writeAsString('${lines.join('\n')}\n');
  return file;
}
