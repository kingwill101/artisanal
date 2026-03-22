/// Render-budget evidence logging example for artisanal.
library;

import 'dart:io';

import 'package:artisanal/runtime.dart' as tui;

const _evidencePath = 'build/evidence-logging-budget.jsonl';
const _maxTicks = 6;

class _BudgetTickMsg extends tui.Msg {
  const _BudgetTickMsg(this.tick);

  final int tick;
}

class _RenderBudgetEvidenceModel implements tui.Model {
  const _RenderBudgetEvidenceModel({
    required this.tick,
    required this.maxTicks,
    this.degradation = tui.DegradationLevel.full,
    this.quitting = false,
  });

  final int tick;
  final int maxTicks;
  final tui.DegradationLevel degradation;
  final bool quitting;

  @override
  tui.Cmd? init() {
    return tui.Cmd.tick(
      const Duration(milliseconds: 500),
      (_) => _BudgetTickMsg(1),
    );
  }

  @override
  (tui.Model, tui.Cmd?) update(tui.Msg msg) {
    return switch (msg) {
      tui.KeyMsg() => (
        const _RenderBudgetEvidenceModel(
          tick: 0,
          maxTicks: _maxTicks,
          quitting: true,
        ),
        tui.Cmd.quit(),
      ),
      tui.RenderBudgetMsg(:final state) => (
        _RenderBudgetEvidenceModel(
          tick: tick,
          maxTicks: maxTicks,
          degradation: state.level,
          quitting: quitting,
        ),
        null,
      ),
      _BudgetTickMsg(:final tick) => _advance(tick),
      _ => (this, null),
    };
  }

  @override
  String view() {
    if (quitting) {
      return '''
Render-budget evidence demo complete.
Evidence is logged to:
$_evidencePath

Exiting.
''';
    }

    final remaining = maxTicks - tick;
    return '''
Render-budget evidence demo (tick $tick/$maxTicks).
Observed degradation: $degradation.
Remaining ticks: $remaining

This model intentionally does CPU work so some frames exceed the configured
budget and emit `render_budget` decisions.

Press any key to stop early.
''';
  }

  (tui.Model, tui.Cmd?) _advance(int tickValue) {
    final isFinal = tickValue >= maxTicks;
    if (isFinal) {
      return (
        _RenderBudgetEvidenceModel(
          tick: tickValue,
          maxTicks: maxTicks,
          degradation: degradation,
          quitting: true,
        ),
        tui.Cmd.quit(),
      );
    }
    final _ = _simulateWork();
    return (
      _RenderBudgetEvidenceModel(
        tick: tickValue,
        maxTicks: maxTicks,
        degradation: degradation,
      ),
      tui.Cmd.tick(
        const Duration(milliseconds: 500),
        (_) => _BudgetTickMsg(tickValue + 1),
      ),
    );
  }

  int _simulateWork() {
    var total = 0;
    for (var i = 0; i < 50000; i++) {
      total = (total + i + 17) % 13;
    }
    return total;
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
    runId: 'evidence-logging-budget',
  );
  try {
    await tui.runProgram(
      _RenderBudgetEvidenceModel(tick: 1, maxTicks: _maxTicks),
      options: const tui.ProgramOptions(
        altScreen: false,
        hideCursor: false,
        fps: 60,
        frameTick: false,
        renderBudget: tui.RenderBudgetOptions(
          enabled: true,
          frameBudget: Duration(microseconds: 300),
          overBudgetFrames: 1,
          recoveryFrames: 4,
          maxLevel: tui.DegradationLevel.noStyling,
        ),
      ),
    );
  } finally {
    tui.TuiEvidence.clearTestOverrides();
  }
}
