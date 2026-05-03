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

    test('preserves initial delay before first replay action', () async {
      final tracePath = await _writeTrace(<String>[
        '# trace start: 2026-02-13T00:00:00.000000',
        '[+10us] [input] @event {"v":1,"type":"window.size","width":120,"height":40}',
        '[+3500000us] [input] @event {"v":1,"type":"input.batch","parser":"uv","flush":false,"messages":[{"kind":"key","keyType":"runes","runes":[50]}]}',
      ]);
      addTearDown(() async {
        await File(tracePath).delete();
      });

      final conversion = await ReplayTraceConverter.convertFile(tracePath);

      expect(conversion.scenario.actions, hasLength(2));
      expect(conversion.scenario.actions[0].type, 'sleep');
      expect(conversion.scenario.actions[0].ms, 3500);
      expect(conversion.scenario.actions[1].type, 'text');
      expect(conversion.scenario.actions[1].value, '2');
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

    test('preserves custom structured events as replay event actions', () async {
      final tracePath = await _writeTrace(<String>[
        '# trace start: 2026-02-13T00:00:00.000000',
        '[+10us] [input] @event {"v":1,"type":"window.size","width":120,"height":40}',
        '[+20us] [input] @event {"v":1,"type":"input.batch","parser":"uv","flush":false,"messages":[{"kind":"key","keyType":"runes","runes":[97]}]}',
        '[+45000us] [cmd] @event {"v":1,"type":"ui.sidebar.toggle","open":true,"source":"shortcut"}',
      ]);
      addTearDown(() async {
        await File(tracePath).delete();
      });

      final conversion = await ReplayTraceConverter.convertFile(tracePath);
      final eventAction = conversion.scenario.actions.firstWhere(
        (action) => action.type == 'event',
      );
      expect(eventAction.eventType, 'ui.sidebar.toggle');
      expect(eventAction.eventFields['open'], isTrue);
      expect(eventAction.eventFields['source'], 'shortcut');
    });

    test(
      'converts evidence render-frame records into replay event actions',
      () async {
        final tracePath = await _writeTrace(<String>[
          '{"v":1,"type":"runtime.render","timestampUs":250,"decisionType":"render_frame","result":"captured","factors":{"width":90,"height":30,"lineCount":2,"plainText":"hello\\nworld","lines":[{"raw":"hello","statePrefix":"","plainText":"hello","visibleWidth":5},{"raw":"world","statePrefix":"\\u001b[31m","plainText":"world","visibleWidth":5}],"nativeSpanDelta":[{"index":1,"spans":[{"lineIndex":1,"startColumn":0,"endColumn":5,"text":"world","style":{"attrs":1,"fg":{"kind":"basic16","index":1,"bright":false}},"link":{"url":"https://example.com","params":""},"hasDrawable":false}]}]}}',
        ]);
        addTearDown(() async {
          await File(tracePath).delete();
        });

        final conversion = await ReplayTraceConverter.convertFile(tracePath);
        expect(conversion.inferredScreenWidth, 90);
        expect(conversion.inferredScreenHeight, 30);
        expect(conversion.scenario.actions, hasLength(1));

        final eventAction = conversion.scenario.actions.single;
        expect(eventAction.type, 'event');
        expect(eventAction.eventType, 'runtime.render_frame');
        expect(eventAction.eventFields['source'], 'evidence');
        expect(eventAction.eventFields['recordType'], 'runtime.render');
        expect(eventAction.eventFields['decisionType'], 'render_frame');
        expect(eventAction.eventFields['result'], 'captured');
        expect(eventAction.eventFields['plainText'], 'hello\nworld');

        final lines = eventAction.eventFields['lines'] as List<Object?>;
        expect(lines, hasLength(2));
        final second = lines[1] as Map<Object?, Object?>;
        expect(second['plainText'], 'world');
        expect(second['statePrefix'], contains('[31m'));

        final spanLines =
            eventAction.eventFields['nativeSpanDelta'] as List<Object?>;
        expect(spanLines, hasLength(1));
        final firstSpanLine = spanLines.single as Map<Object?, Object?>;
        final spans = firstSpanLine['spans'] as List<Object?>;
        final span = spans.single as Map<Object?, Object?>;
        expect(span['text'], 'world');
        expect((span['style'] as Map<Object?, Object?>)['attrs'], 1);
        expect(
          (span['link'] as Map<Object?, Object?>)['url'],
          'https://example.com',
        );
      },
    );

    test(
      'converts evidence render-capture records into replay event actions',
      () async {
        final tracePath = await _writeTrace(<String>[
          '{"v":1,"type":"runtime.render","timestampUs":500,"decisionType":"render_capture","result":"captured","factors":{"stats":{"totalRenders":2,"changedRenders":1,"averageRenderDurationUs":800,"totalChangedCells":4,"totalChangedSpans":2,"peakDirtyLines":1,"peakChangedCells":4,"peakChangedSpans":2,"lastChangeSummary":{"hasChanges":true,"dirtyLineCount":1,"changedLineCount":1,"changedCellCount":4,"changedSpanCount":2}},"report":{"prefix":"Capture","lastRenderGeneration":2,"lastWidth":100,"lastHeight":32,"frameLines":["count: 1"],"lastChangeSummary":{"hasChanges":true,"dirtyLineCount":1,"changedLineCount":1,"changedCellCount":4,"changedSpanCount":2},"metricEntries":{"Capture renders":"2","Capture changed":"1"}},"lastSnapshot":{"sequence":1,"renderGeneration":2,"degradationLevel":"full","renderDurationUs":800,"width":100,"height":32,"lines":["count: 1"],"changeSummary":{"hasChanges":true,"dirtyLineCount":1,"changedLineCount":1,"changedCellCount":4,"changedSpanCount":2}},"lastSnapshotSummary":{"sequence":1,"renderGeneration":2,"degradationLevel":"full","renderDurationUs":800,"width":100,"height":32,"frameLines":["count: 1"],"changeSummary":{"hasChanges":true,"dirtyLineCount":1,"changedLineCount":1,"changedCellCount":4,"changedSpanCount":2}}}}',
        ]);
        addTearDown(() async {
          await File(tracePath).delete();
        });

        final conversion = await ReplayTraceConverter.convertFile(tracePath);
        expect(conversion.inferredScreenWidth, 100);
        expect(conversion.inferredScreenHeight, 32);
        expect(conversion.scenario.actions, hasLength(1));

        final eventAction = conversion.scenario.actions.single;
        expect(eventAction.type, 'event');
        expect(eventAction.eventType, 'runtime.render_capture');
        expect(eventAction.eventFields['source'], 'evidence');
        expect(eventAction.eventFields['recordType'], 'runtime.render');
        expect(eventAction.eventFields['decisionType'], 'render_capture');

        final stats = eventAction.eventFields['stats'] as Map<Object?, Object?>;
        expect(stats['totalRenders'], 2);
        final report =
            eventAction.eventFields['report'] as Map<Object?, Object?>;
        expect(report['lastWidth'], 100);
        expect(report['lastHeight'], 32);
        final summary =
            eventAction.eventFields['lastSnapshotSummary']
                as Map<Object?, Object?>;
        expect(summary['frameLines'], <Object?>['count: 1']);

        final decoded = eventAction.customEvent!.renderCapturePayload;
        expect(decoded, isNotNull);
        expect(decoded!.stats.totalRenders, 2);
        expect(decoded.report.lastWidth, 100);
        expect(decoded.lastSnapshot, isNotNull);
        expect(decoded.lastSnapshot!.renderGeneration, 2);
        expect(decoded.lastSnapshotSummary, isNotNull);
        expect(decoded.lastSnapshotSummary!.frameLines, <String>['count: 1']);

        final typedEvent = eventAction.customEvent!.renderCapture;
        expect(typedEvent, isNotNull);
        expect(typedEvent!.recordType, 'runtime.render');
        expect(typedEvent.decisionType, 'render_capture');
        expect(typedEvent.result, 'captured');
        final presentation = eventAction.customEvent!.presentation;
        expect(
          presentation.summary,
          'render capture g2 100x32 cells 4 spans 2',
        );
        expect(presentation.statusHint, '/replay g2 100x32 c4 s2');
        expect(presentation.fields['renderGeneration'], 2);
        expect(presentation.detailLines, isNotEmpty);
        final lines = typedEvent.toLines();
        expect(lines.first, 'Capture event: runtime.render_capture');
        expect(
          lines[1],
          'Capture source: runtime.render / render_capture / captured',
        );
        expect(
          lines.any(
            (line) => line.contains('Capture last: generation 2 (100x32)'),
          ),
          isTrue,
        );
      },
    );
  });

  group('replay custom event hooks', () {
    test(
      'default replay behavior emits ReplayEventMsg when no hook provided',
      () async {
        final messages = await replayScenarioStream(
          const [
            ReplayAction(
              type: 'event',
              eventType: 'ui.sidebar.toggle',
              eventFields: {'open': true},
            ),
          ],
          loop: false,
          keepOpen: true,
          speed: 1.0,
        ).toList();

        expect(messages, hasLength(1));
        expect(messages.single, isA<ReplayEventMsg>());
        final event = (messages.single as ReplayEventMsg).event;
        expect(event.type, 'ui.sidebar.toggle');
        expect(event.fields['open'], isTrue);
        expect(event.presentation.summary, 'replay event -> ui.sidebar.toggle');
        expect(event.presentation.statusHint, '/replay ui.sidebar.toggle');
      },
    );

    test('async event hook can emit messages and quit replay', () async {
      final messages = await replayScenarioStream(
        const [
          ReplayAction(
            type: 'event',
            eventType: 'test.custom',
            eventFields: {'x': 1},
          ),
        ],
        loop: false,
        keepOpen: true,
        speed: 1.0,
        eventHook: (event) async {
          await Future<void>.delayed(Duration.zero);
          expect(event.type, 'test.custom');
          return ReplayEventDirective.quit(
            messages: [const _ReplayProbeMsg('handled')],
          );
        },
      ).toList();

      expect(messages, hasLength(2));
      expect(messages.first, const _ReplayProbeMsg('handled'));
      expect(messages.last, const QuitMsg());
    });
  });
}

final class _ReplayProbeMsg extends Msg {
  const _ReplayProbeMsg(this.value);

  final String value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _ReplayProbeMsg &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;
}

Future<String> _writeTrace(List<String> lines) async {
  final dir = await Directory.systemTemp.createTemp('tui-replay-protocol-');
  final file = File('${dir.path}/trace.log');
  await file.writeAsString('${lines.join('\n')}\n');
  return file.path;
}
