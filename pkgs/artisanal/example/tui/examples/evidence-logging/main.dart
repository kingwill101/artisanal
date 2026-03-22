/// Evidence logging example for artisanal.
library;

import 'dart:io';

import 'package:artisanal/runtime.dart' as tui;

const _evidencePath = 'build/evidence-logging.jsonl';
const _maxTicks = 5;

/// Message emitted by the recurring timer.
class EvidenceTickMsg extends tui.Msg {
  const EvidenceTickMsg(this.tick);

  final int tick;
}

class EvidenceLoggerModel implements tui.Model {
  const EvidenceLoggerModel({
    required this.tick,
    required this.maxTicks,
    this.quitting = false,
  });

  final int tick;
  final int maxTicks;
  final bool quitting;

  @override
  tui.Cmd? init() {
    tui.TuiEvidence.logDecision(
      decisionType: 'example.evidence',
      result: 'start',
      factors: <String, Object?>{'maxTicks': maxTicks},
    );
    return tui.Cmd.tick(
      const Duration(milliseconds: 500),
      (_) => const EvidenceTickMsg(1),
    );
  }

  @override
  (tui.Model, tui.Cmd?) update(tui.Msg msg) {
    switch (msg) {
      case tui.KeyMsg():
        return (
          EvidenceLoggerModel(tick: tick, maxTicks: maxTicks, quitting: true),
          tui.Cmd.quit(),
        );

      case EvidenceTickMsg(:final tick):
        final isFinal = tick >= maxTicks;
        tui.TuiEvidence.logDecision(
          decisionType: 'example.evidence',
          result: isFinal ? 'done' : 'tick',
          factors: <String, Object?>{
            'tick': tick,
            'maxTicks': maxTicks,
            'remainingTicks': (maxTicks - tick).clamp(0, maxTicks),
          },
        );
        if (isFinal) {
          return (
            EvidenceLoggerModel(tick: tick, maxTicks: maxTicks, quitting: true),
            tui.Cmd.quit(),
          );
        }
        return (
          EvidenceLoggerModel(tick: tick + 1, maxTicks: maxTicks),
          tui.Cmd.tick(
            const Duration(milliseconds: 500),
            (_) => EvidenceTickMsg(tick + 1),
          ),
        );

      default:
        return (this, null);
    }
  }

  @override
  String view() {
    if (quitting) {
      return '''
Done! Evidence is logged to:
$_evidencePath

Exiting.
''';
    }

    final remaining = maxTicks - tick;
    return '''
Evidence logging demo running ($tick/$maxTicks).
Remaining ticks: $remaining

TuiEvidence is recording decision records on each tick.
Press any key to stop early.
''';
  }
}

Future<void> main() async {
  final evidenceFile = File(_evidencePath);
  if (await evidenceFile.exists()) {
    await evidenceFile.delete();
  }

  tui.TuiEvidence.configureForTest(
    enabled: true,
    path: _evidencePath,
    runId: 'evidence-logging-example',
  );
  try {
    await tui.runProgram(
      const EvidenceLoggerModel(tick: 1, maxTicks: _maxTicks),
      options: const tui.ProgramOptions(
        altScreen: false,
        hideCursor: false,
        frameTick: false,
      ),
    );
  } finally {
    tui.TuiEvidence.clearTestOverrides();
  }
}
