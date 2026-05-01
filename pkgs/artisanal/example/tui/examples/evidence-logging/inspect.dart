/// Parse and print artifacts from a JSONL evidence log.
// tui:allow-stdout — CLI tool, not a TUI program.
library;

import 'dart:io';

import 'package:artisanal/runtime.dart' show TuiEvidence;

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    print(
      'Usage: dart run .../inspect.dart <path/to/evidence.jsonl> [decisionType]',
    );
    print(
      'Example: dart run .../inspect.dart build/evidence-logging.jsonl example.evidence',
    );
    return;
  }

  final filterDecisionType = args.length > 1 ? args[1] : null;

  final evidenceFile = File(args.first);
  if (!await evidenceFile.exists()) {
    print('No evidence file at "${args.first}"');
    return;
  }

  final lines = await evidenceFile.readAsLines();
  var parsed = 0;
  var skipped = 0;
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
    print('${record.timestampUs}: ${record.decisionType}/${record.result}');
    for (final entry in record.factors.entries) {
      print('  ${entry.key}: ${entry.value}');
    }
  }

  print('Parsed $parsed records, skipped $skipped lines.');
}
