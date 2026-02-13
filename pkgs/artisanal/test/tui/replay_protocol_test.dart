import 'dart:io';

import 'package:artisanal/tui.dart';
import 'package:test/test.dart';

void main() {
  group('TuiTrace structured events', () {
    test('parses strict @event line', () {
      final line =
          '[+123us] [input] @event {"v":1,"type":"input.batch","messages":[]}';
      final parsed = TuiTrace.tryParseEventLine(line);
      expect(parsed, isNotNull);
      expect(parsed!.timestampUs, 123);
      expect(parsed.tag, TraceTag.input);
      expect(parsed.type, TraceEventType.inputBatch);
      expect(parsed.fields['messages'], isA<List<dynamic>>());
    });

    test('ignores malformed event version', () {
      final line =
          '[+123us] [input] @event {"v":2,"type":"input.batch","messages":[]}';
      final parsed = TuiTrace.tryParseEventLine(line);
      expect(parsed, isNull);
    });
  });

  group('ReplayTraceConverter', () {
    test('converts structured trace events into replay actions', () async {
      final tracePath = await _writeTrace(<String>[
        '# trace start: 2026-02-13T00:00:00.000000',
        '[+10us] [input] @event {"v":1,"type":"window.size","width":120,"height":40}',
        '[+20us] [input] @event {"v":1,"type":"input.batch","parser":"uv","flush":false,"messages":[{"kind":"mouse","action":"press","button":"left","x":10,"y":5},{"kind":"mouse","action":"release","button":"left","x":10,"y":5}]}',
        '[+60000us] [input] @event {"v":1,"type":"input.batch","parser":"uv","flush":false,"messages":[{"kind":"key","keyType":"runes","runes":[113]}]}',
      ]);
      addTearDown(() async {
        await File(tracePath).delete();
      });

      final conversion = await ReplayTraceConverter.convertFile(tracePath);
      expect(conversion.inferredScreenWidth, 120);
      expect(conversion.inferredScreenHeight, 40);
      expect(conversion.eventCount, 3);
      expect(conversion.scenario.actions, hasLength(3));
      expect(conversion.scenario.actions[0].type, 'tap');
      expect(conversion.scenario.actions[1].type, 'sleep');
      expect(conversion.scenario.actions[2].type, 'text');
      expect(conversion.scenario.actions[2].value, 'q');
    });

    test('throws when trace lacks structured input events', () async {
      final tracePath = await _writeTrace(<String>[
        '# trace start: 2026-02-13T00:00:00.000000',
        '[+342us] [input] parsed uv: MouseMsg(MouseAction.motion MouseButton.none @ 10,5)',
      ]);
      addTearDown(() async {
        await File(tracePath).delete();
      });

      await expectLater(
        () => ReplayTraceConverter.convertFile(tracePath),
        throwsA(isA<FormatException>()),
      );
    });
  });
}

Future<String> _writeTrace(List<String> lines) async {
  final dir = await Directory.systemTemp.createTemp('tui-replay-protocol-');
  final file = File('${dir.path}/trace.log');
  await file.writeAsString('${lines.join('\n')}\n');
  return file.path;
}
