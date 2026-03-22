import 'dart:io';

import 'package:artisanal/runtime.dart';
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
  });
}
