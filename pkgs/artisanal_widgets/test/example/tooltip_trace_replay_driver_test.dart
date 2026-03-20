import 'dart:convert';
import 'dart:io';

import 'package:artisanal/runtime.dart' as runtime;
import 'package:test/test.dart';

import '../../example/tooltip_trace/replay_driver.dart';

void main() {
  group('Tooltip trace replay driver', () {
    test('loads scenario and appends QuitMsg by default', () async {
      final file = await _writeScenarioFile(<String, Object?>{
        'name': 'tooltip-basic',
        'actions': [
          {'type': 'move', 'x': 12, 'y': 7},
        ],
      });
      addTearDown(() async {
        if (await file.exists()) await file.delete();
      });

      final plan = await loadTooltipTraceReplayPlanFromArgs([
        '--replay-scenario',
        file.path,
      ]);

      expect(plan, isNotNull);
      final events = await plan!.replay.toStream().toList();
      expect(events, hasLength(2));
      expect(events.first, isA<runtime.MouseMsg>());
      expect(events.last, isA<runtime.QuitMsg>());
    });

    test('converts trace and includes hover motion by default', () async {
      final traceFile = await _writeTraceFile([
        '# trace start: 2026-03-20T00:00:00.000000',
        '[+10us] [input] @event {"v":1,"type":"window.size","width":80,"height":24}',
        '[+20us] [input] @event {"v":1,"type":"input.batch","messages":[{"kind":"mouse","action":"motion","button":"none","x":20,"y":8}]}',
      ]);
      addTearDown(() async {
        if (await traceFile.exists()) await traceFile.delete();
      });

      final plan = await loadTooltipTraceReplayPlanFromArgs([
        '--replay-trace',
        traceFile.path,
        '--replay-keep-open',
      ]);

      expect(plan, isNotNull);
      expect(plan!.traceConversion, isNotNull);
      final first = await plan.replay.toStream().first;
      final translated = plan.interceptor.onSend(first);
      expect(translated, isA<runtime.MouseMsg>());
      final mouse = translated as runtime.MouseMsg;
      expect(mouse.action, runtime.MouseAction.motion);
      expect(mouse.x, 20);
      expect(mouse.y, 8);
    });

    test('convert-only requires replay-trace-out', () async {
      await expectLater(
        () => loadTooltipTraceReplayPlanFromArgs([
          '--replay-trace',
          '/tmp/missing.log',
          '--replay-convert-only',
        ]),
        throwsA(isA<FormatException>()),
      );
    });
  });
}

Future<File> _writeScenarioFile(Map<String, Object?> json) async {
  final dir = await Directory.systemTemp.createTemp('tooltip-trace-scenario-');
  final file = File('${dir.path}/scenario.json');
  await file.writeAsString('${jsonEncode(json)}\n');
  return file;
}

Future<File> _writeTraceFile(List<String> lines) async {
  final dir = await Directory.systemTemp.createTemp('tooltip-trace-log-');
  final file = File('${dir.path}/trace.log');
  await file.writeAsString('${lines.join('\n')}\n');
  return file;
}
