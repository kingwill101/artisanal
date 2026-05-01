/// Summarize JSONL evidence logs emitted by `TuiEvidence`.
// tui:allow-stdout — CLI tool, not a TUI program.
library;

import 'dart:io';

import 'package:artisanal/runtime.dart' show TuiEvidence;

void main(List<String> args) async {
  if (args.isEmpty) {
    print(
      'Usage: dart run .../summary.dart <path/to/evidence.jsonl> [decisionType]',
    );
    print('Example: dart run .../summary.dart build/evidence-logging.jsonl');
    print(
      'Example with filter: dart run .../summary.dart build/evidence-logging.jsonl example.evidence',
    );
    return;
  }

  final path = args.first;
  final filterDecisionType = args.length > 1 ? args[1] : null;

  final evidenceFile = File(path);
  if (!await evidenceFile.exists()) {
    print('No evidence file at "$path"');
    return;
  }

  final lines = await evidenceFile.readAsLines();
  final totalLines = lines.length;
  var parsed = 0;
  var skipped = 0;
  final decisionTypeCounts = <String, int>{};
  final decisionResultCounts = <String, int>{};
  final runIds = <String>{};

  for (final line in lines) {
    final record = TuiEvidence.tryParseLine(line);
    if (record == null) {
      skipped++;
      continue;
    }

    if (filterDecisionType != null &&
        record.decisionType != filterDecisionType) {
      continue;
    }

    parsed++;
    decisionTypeCounts.update(
      record.decisionType,
      (value) => value + 1,
      ifAbsent: () => 1,
    );

    final resultKey = '${record.decisionType}/${record.result}';
    decisionResultCounts.update(
      resultKey,
      (value) => value + 1,
      ifAbsent: () => 1,
    );

    if (record.runId != null) {
      runIds.add(record.runId!);
    }
  }

  final malformedPercent = totalLines == 0
      ? 0.0
      : (skipped / totalLines) * 100.0;

  print('Evidence summary for "$path"');
  if (filterDecisionType != null) {
    print('Filtered decisionType: $filterDecisionType');
  }
  print('Parsed records: $parsed');
  print('Skipped malformed lines: $skipped');
  print('Malformed ratio: ${malformedPercent.toStringAsFixed(1)}%');
  print('Unique run IDs: ${runIds.isEmpty ? "(none)" : runIds.join(", ")}');
  print('Decision type counts:');
  if (decisionTypeCounts.isEmpty) {
    print('  (none)');
  } else {
    final sortedDecisionTypes = decisionTypeCounts.keys.toList()..sort();
    for (final decisionType in sortedDecisionTypes) {
      print('  $decisionType: ${decisionTypeCounts[decisionType]}');
    }
  }

  print('Decision + result counts:');
  if (decisionResultCounts.isEmpty) {
    print('  (none)');
  } else {
    final sortedDecisionResult = decisionResultCounts.keys.toList()..sort();
    for (final key in sortedDecisionResult) {
      print('  $key: ${decisionResultCounts[key]}');
    }
  }
}
