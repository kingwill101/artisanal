import 'dart:io';

import 'package:artisanal/runtime.dart';
import 'package:artisanal/uv.dart' show UvColor, UvStyle;
import 'package:test/test.dart';

void main() {
  group('TuiEvidence parser and logging', () {
    test('tryParseLine accepts only valid JSONL evidence records', () {
      final line =
          '{"v":1,"type":"runtime.decision","timestampUs":123,"decisionType":"render_budget","result":"degrade","factors":{"frameBudgetUs":16000,"renderDurationUs":20000}}';
      final parsed = TuiEvidence.tryParseLine(line);

      expect(parsed, isNotNull);
      expect(parsed!.version, 1);
      expect(parsed.type, 'runtime.decision');
      expect(parsed.decisionType, 'render_budget');
      expect(parsed.result, 'degrade');
      expect(parsed.factors['frameBudgetUs'], 16000);
      expect(parsed.factors['renderDurationUs'], 20000);
    });

    test('tryParseLine rejects malformed records', () {
      expect(TuiEvidence.tryParseLine(''), isNull);
      expect(TuiEvidence.tryParseLine('not jsonl'), isNull);
      expect(
        TuiEvidence.tryParseLine(
          '{"v":2,"type":"runtime.decision","timestampUs":123,"decisionType":"x","result":"y","factors":{}}',
        ),
        isNull,
      );
      expect(
        TuiEvidence.tryParseLine(
          '{"v":1,"type":"runtime.decision","timestampUs":"bad","decisionType":"x","result":"y","factors":{}}',
        ),
        isNull,
      );
      expect(
        TuiEvidence.tryParseLine(
          '{"v":1,"type":"runtime.decision","timestampUs":123,"decisionType":"x","result":"y"}',
        ),
        isNull,
      );
    });

    test('logs evidence when enabled and captures run id/factors', () async {
      final tempDir = await Directory.systemTemp.createTemp('tui-evidence-');
      final outputPath = '${tempDir.path}/evidence.jsonl';
      addTearDown(() async {
        await tempDir.delete(recursive: true);
      });

      TuiEvidence.configureForTest(
        enabled: true,
        path: outputPath,
        runId: 'e2e-run',
      );
      addTearDown(() {
        TuiEvidence.clearTestOverrides();
      });

      TuiEvidence.logDecision(
        decisionType: 'render_budget',
        result: 'hold',
        factors: <String, Object?>{
          'frameBudgetUs': 16000,
          'renderDurationUs': 20000,
        },
      );

      final content = await File(outputPath).readAsLines();
      expect(content, hasLength(1));
      final record = TuiEvidence.tryParseLine(content.single)!;
      expect(record.runId, 'e2e-run');
      expect(record.decisionType, 'render_budget');
      expect(record.result, 'hold');
      expect(record.factors['frameBudgetUs'], 16000);
      expect(record.factors['renderDurationUs'], 20000);
    });

    test('logs parsed render frames when frame capture is enabled', () async {
      final tempDir = await Directory.systemTemp.createTemp('tui-evidence-');
      final outputPath = '${tempDir.path}/evidence-frame.jsonl';
      addTearDown(() async {
        await tempDir.delete(recursive: true);
      });

      TuiEvidence.configureForTest(
        enabled: true,
        captureFrames: true,
        path: outputPath,
      );
      addTearDown(() {
        TuiEvidence.clearTestOverrides();
      });

      TuiEvidence.logRenderFrame(
        view: const View(content: '\x1b[31mred\ncarry'),
        renderGeneration: 3,
        degradationLevel: 'full',
        renderDurationUs: 1200,
        width: 80,
        height: 24,
      );

      final content = await File(outputPath).readAsLines();
      expect(content, hasLength(1));
      final record = TuiEvidence.tryParseLine(content.single)!;
      expect(record.type, 'runtime.render');
      expect(record.decisionType, 'render_frame');
      expect(record.result, 'captured');
      expect(record.factors['renderGeneration'], 3);
      expect(record.factors['degradationLevel'], 'full');
      expect(record.factors['renderDurationUs'], 1200);
      expect(record.factors['width'], 80);
      expect(record.factors['height'], 24);
      expect(record.factors['lineCount'], 2);
      expect(record.factors['plainText'], 'red\ncarry');

      final lines = record.factors['lines'] as List<Object?>;
      expect(lines, hasLength(2));
      final second = lines[1] as Map<Object?, Object?>;
      expect(second['plainText'], 'carry');
      expect(second['visibleWidth'], 5);
      expect(second['statePrefix'], contains('[31m'));
    });

    test('logs native span deltas when provided', () async {
      final tempDir = await Directory.systemTemp.createTemp('tui-evidence-');
      final outputPath = '${tempDir.path}/evidence-span.jsonl';
      addTearDown(() async {
        await tempDir.delete(recursive: true);
      });

      TuiEvidence.configureForTest(
        enabled: true,
        captureFrames: true,
        path: outputPath,
      );
      addTearDown(() {
        TuiEvidence.clearTestOverrides();
      });

      TuiEvidence.logRenderFrame(
        view: const View(content: 'xy'),
        nativeSpanDelta: <TerminalNativeSpanDelta>[
          TerminalNativeSpanDelta(
            index: 0,
            spans: <TerminalNativeSpan>[
              TerminalNativeSpan(
                lineIndex: 0,
                startColumn: 0,
                endColumn: 2,
                text: 'xy',
                style: TerminalNativeStyle.fromStyle(
                  const UvStyle(fg: UvColor.basic16(1), attrs: 1),
                ),
                link: TerminalNativeLink(
                  url: 'https://example.com',
                  params: '',
                ),
                hasDrawable: false,
              ),
            ],
          ),
        ],
      );

      final content = await File(outputPath).readAsLines();
      final record = TuiEvidence.tryParseLine(content.single)!;
      final spanLines = record.factors['nativeSpanDelta'] as List<Object?>;
      expect(spanLines, hasLength(1));
      final firstLine = spanLines.single as Map<Object?, Object?>;
      final spans = firstLine['spans'] as List<Object?>;
      final span = spans.single as Map<Object?, Object?>;
      expect(span['text'], 'xy');
      expect((span['style'] as Map<Object?, Object?>)['attrs'], 1);
      expect(
        (span['link'] as Map<Object?, Object?>)['url'],
        'https://example.com',
      );
      expect((span['fg'] as Map<Object?, Object?>)['index'], 1);
    });

    test('logs structured render capture payloads when provided', () async {
      final tempDir = await Directory.systemTemp.createTemp('tui-evidence-');
      final outputPath = '${tempDir.path}/evidence-capture.jsonl';
      addTearDown(() async {
        await tempDir.delete(recursive: true);
      });

      TuiEvidence.configureForTest(
        enabled: true,
        captureFrames: true,
        path: outputPath,
      );
      addTearDown(() {
        TuiEvidence.clearTestOverrides();
      });

      final capture = ProgramRenderCapture();
      capture.onRendered(
        renderGeneration: 2,
        view: const View(content: 'count: 1'),
        degradationLevel: DegradationLevel.full,
        renderDuration: const Duration(milliseconds: 1),
        width: 80,
        height: 24,
      );

      TuiEvidence.logRenderCapture(
        capture: capture,
        prefix: 'Capture',
        maxFrameLines: 1,
      );

      final content = await File(outputPath).readAsLines();
      expect(content, hasLength(1));
      final record = TuiEvidence.tryParseLine(content.single)!;
      expect(record.type, 'runtime.render');
      expect(record.decisionType, 'render_capture');
      expect(record.result, 'captured');

      final stats = record.factors['stats'] as Map<Object?, Object?>;
      expect(stats['totalRenders'], 1);

      final report = record.factors['report'] as Map<Object?, Object?>;
      expect(report['prefix'], 'Capture');
      expect(report['lastRenderGeneration'], 2);
      expect(report['frameLines'], <Object?>['count: 1']);

      final lastSnapshot =
          record.factors['lastSnapshot'] as Map<Object?, Object?>;
      expect(lastSnapshot['renderGeneration'], 2);

      final lastSnapshotSummary =
          record.factors['lastSnapshotSummary'] as Map<Object?, Object?>;
      expect(lastSnapshotSummary['frameLines'], <Object?>['count: 1']);
    });

    test('does not emit when disabled', () async {
      final tempDir = await Directory.systemTemp.createTemp('tui-evidence-');
      final outputPath = '${tempDir.path}/evidence-disabled.jsonl';
      addTearDown(() async {
        await tempDir.delete(recursive: true);
      });

      TuiEvidence.configureForTest(enabled: false, path: outputPath);
      addTearDown(() {
        TuiEvidence.clearTestOverrides();
      });

      TuiEvidence.logDecision(
        decisionType: 'render_budget',
        result: 'hold',
        factors: const {},
      );

      expect(await File(outputPath).exists(), isFalse);
    });

    test(
      'does not emit render frames when frame capture is disabled',
      () async {
        final tempDir = await Directory.systemTemp.createTemp('tui-evidence-');
        final outputPath = '${tempDir.path}/evidence-no-frame.jsonl';
        addTearDown(() async {
          await tempDir.delete(recursive: true);
        });

        TuiEvidence.configureForTest(enabled: true, path: outputPath);
        addTearDown(() {
          TuiEvidence.clearTestOverrides();
        });

        TuiEvidence.logRenderFrame(view: const View(content: 'frame'));

        expect(await File(outputPath).exists(), isFalse);
      },
    );

    test(
      'date-based evidence path can be driven by an injected clock',
      () async {
        final tempDir = await Directory.systemTemp.createTemp('tui-evidence-');
        addTearDown(() async {
          await tempDir.delete(recursive: true);
        });

        TuiEvidence.configureForTest(
          enabled: true,
          baseDirectory: tempDir.path,
          nowProvider: () => DateTime.utc(2026, 3, 29, 8, 9, 10, 123, 456),
        );
        addTearDown(() {
          TuiEvidence.clearTestOverrides();
        });

        TuiEvidence.logDecision(
          decisionType: 'render_budget',
          result: 'hold',
          factors: const <String, Object?>{},
        );

        final evidenceDir = Directory('${tempDir.path}/evidence');
        expect(await evidenceDir.exists(), isTrue);
        final files = <File>[];
        await for (final entity in evidenceDir.list()) {
          if (entity is File) {
            files.add(entity);
          }
        }
        expect(files, hasLength(1));
        expect(
          files.single.uri.pathSegments.last,
          equals('artisanal-456-2026-03-29T08-09-10.jsonl'),
        );
      },
    );
  });
}
