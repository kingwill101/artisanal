/// Toggle evidence logging on/off from an example entrypoint.
// tui:allow-stdout — CLI tool, not a TUI program.
library;

import 'dart:io';

import 'package:artisanal/runtime.dart' as tui;

Future<void> main(List<String> args) async {
  final mode = args.isEmpty ? 'enabled' : args.first.toLowerCase();
  if (mode != 'enabled' && mode != 'disabled') {
    print('Usage: dart run .../toggle.dart [enabled|disabled]');
    print('  enabled   enable logging and emit example evidence (default)');
    print('  disabled  disable logging and verify no file is written');
    return;
  }

  final evidencePath = 'build/evidence-logging-toggle-$mode.jsonl';
  final evidenceFile = File(evidencePath);
  if (await evidenceFile.exists()) {
    await evidenceFile.delete();
  }

  tui.TuiEvidence.configureForTest(
    enabled: mode == 'enabled',
    path: evidencePath,
    runId: 'evidence-logging-toggle',
  );

  try {
    for (var index = 0; index < 3; index++) {
      tui.TuiEvidence.logDecision(
        decisionType: 'example.toggle',
        result: switch (index) {
          0 => 'start',
          1 => 'intermediate',
          _ => 'done',
        },
        factors: <String, Object?>{'step': index, 'mode': mode},
      );
    }
  } finally {
    tui.TuiEvidence.clearTestOverrides();
  }

  final hasFile = await evidenceFile.exists();
  if (!hasFile) {
    print('No evidence file at "$evidencePath". Evidence logging is disabled.');
    return;
  }

  final lines = await evidenceFile.readAsLines();
  print('Evidence mode: $mode');
  print('Evidence file: $evidencePath');
  print('Evidence lines: ${lines.length}');
  for (final line in lines) {
    print(line);
  }
}
