// DecisionCard Showcase
//
// Demonstrates the DecisionCard widget with all 4 progressive-disclosure
// levels: traffic-light badge, plain-English explanation, evidence terms,
// and full quantitative details.
//
// Run with: dart run example/decision_card/main.dart

import 'package:artisanal/style.dart' hide Padding, Align;
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/widgets.dart' as w;

void main() async {
  final app = tui.WidgetApp(DecisionCardShowcase());
  await tui.runProgram(
    app,
    options: const tui.ProgramOptions(
      altScreen: true,
      mouse: true,
      mouseMode: tui.MouseMode.allMotion,
    ),
  );
}

class DecisionCardShowcase extends w.StatefulWidget {
  DecisionCardShowcase({super.key});

  @override
  w.State createState() => _DecisionCardShowcaseState();
}

class _DecisionCardShowcaseState extends w.State<DecisionCardShowcase> {
  final w.WidgetScrollController _scrollController = w.WidgetScrollController();

  @override
  w.Widget build(w.BuildContext context) {
    final theme = widget.theme;
    final label = theme.labelSmall.copy()..foreground(theme.onBackground);

    return w.Container(
      padding: const w.EdgeInsets.all(1),
      color: theme.background,
      child: w.Scrollbar(
        controller: _scrollController,
        thickness: 1,
        gap: 1,
        enableHover: true,
        trackChar: ' ',
        thumbChar: ' ',
        trackUsesBackground: true,
        thumbUsesBackground: true,
        trackGradient: w.ScrollbarGradient.background(
          start: w.hasDarkBackground
              ? const BasicColor('#2f363d')
              : const BasicColor('#e3e7eb'),
          end: w.hasDarkBackground
              ? const BasicColor('#1f252a')
              : const BasicColor('#d3d9e0'),
        ),
        thumbGradient: w.ScrollbarGradient.background(
          start: w.hasDarkBackground
              ? const BasicColor('#3fb2ff')
              : const BasicColor('#2f7df6'),
          end: w.hasDarkBackground
              ? const BasicColor('#7c5cff')
              : const BasicColor('#6e55f5'),
        ),
        hoverThumbGradient: w.ScrollbarGradient.background(
          start: w.hasDarkBackground
              ? const BasicColor('#79ddff')
              : const BasicColor('#4f93ff'),
          end: w.hasDarkBackground
              ? const BasicColor('#b18bff')
              : const BasicColor('#836bff'),
        ),
        hoverThumbChar: ' ',
        child: w.ScrollView(
          controller: _scrollController,
          handleKeys: true,
          child: w.Column(
            gap: 1,
            crossAxisAlignment: w.CrossAxisAlignment.stretch,
            children: [
              w.Text('DecisionCard Showcase', style: theme.titleLarge),
              w.Text(
                'Progressive-disclosure decision transparency. Press q to quit.',
                style: label,
              ),
              w.Divider(),

              // ── Level 0: Traffic Light ──
              w.Text('Level 0 — Traffic Light Only', style: theme.titleMedium),
              w.Row(
                gap: 2,
                crossAxisAlignment: w.CrossAxisAlignment.start,
                children: [
                  w.Expanded(
                    child: w.DecisionCard(
                      data: const w.DecisionData(
                        signal: w.DecisionSignal.green,
                        actionLabel: 'full_redraw',
                      ),
                    ),
                  ),
                  w.Expanded(
                    child: w.DecisionCard(
                      data: const w.DecisionData(
                        signal: w.DecisionSignal.yellow,
                        actionLabel: 'partial_update',
                      ),
                    ),
                  ),
                  w.Expanded(
                    child: w.DecisionCard(
                      data: const w.DecisionData(
                        signal: w.DecisionSignal.red,
                        actionLabel: 'abort_render',
                      ),
                    ),
                  ),
                ],
              ),
              w.Divider(),

              // ── Level 1: With Explanation ──
              w.Text('Level 1 — With Explanation', style: theme.titleMedium),
              w.DecisionCard(
                data: const w.DecisionData(
                  signal: w.DecisionSignal.green,
                  actionLabel: 'proceed',
                  level: w.DisclosureLevel.plainEnglish,
                  explanation:
                      'High confidence in rendering strategy based on stable frame history.',
                ),
              ),
              w.Divider(),

              // ── Level 2: With Evidence ──
              w.Text('Level 2 — With Evidence Terms', style: theme.titleMedium),
              w.DecisionCard(
                data: const w.DecisionData(
                  signal: w.DecisionSignal.yellow,
                  actionLabel: 'review_strategy',
                  level: w.DisclosureLevel.evidenceTerms,
                  explanation:
                      'Mixed signals suggest reviewing the current rendering approach.',
                  evidence: [
                    w.EvidenceTerm(
                      label: 'change_rate',
                      factor: 3.5,
                      direction: w.EvidenceDirection.supporting,
                    ),
                    w.EvidenceTerm(
                      label: 'frame_cost',
                      factor: 0.8,
                      direction: w.EvidenceDirection.opposing,
                    ),
                    w.EvidenceTerm(
                      label: 'stability',
                      factor: 1.0,
                      direction: w.EvidenceDirection.neutral,
                    ),
                    w.EvidenceTerm(
                      label: 'latency_trend',
                      factor: 2.1,
                      direction: w.EvidenceDirection.supporting,
                    ),
                  ],
                ),
              ),
              w.Divider(),

              // ── Level 3: Full Details ──
              w.Text(
                'Level 3 — Full Quantitative Details',
                style: theme.titleMedium,
              ),
              w.DecisionCard(
                data: const w.DecisionData(
                  signal: w.DecisionSignal.green,
                  actionLabel: 'full_redraw',
                  level: w.DisclosureLevel.fullDetails,
                  explanation:
                      'All evidence strongly supports full redraw strategy.',
                  evidence: [
                    w.EvidenceTerm(
                      label: 'change_rate',
                      factor: 4.2,
                      direction: w.EvidenceDirection.supporting,
                    ),
                    w.EvidenceTerm(
                      label: 'buffer_diff_cost',
                      factor: 1.1,
                      direction: w.EvidenceDirection.neutral,
                    ),
                    w.EvidenceTerm(
                      label: 'frame_budget',
                      factor: 3.8,
                      direction: w.EvidenceDirection.supporting,
                    ),
                  ],
                  details: w.DecisionDetails(
                    logPosterior: 2.847,
                    confidenceLow: 0.82,
                    confidenceHigh: 0.97,
                    expectedLoss: 0.0312,
                    lossAvoided: 0.1847,
                  ),
                ),
              ),
              w.Divider(),

              // ── Level 3 without lossAvoided ──
              w.Text('Level 3 — Without lossAvoided', style: theme.titleMedium),
              w.DecisionCard(
                data: const w.DecisionData(
                  signal: w.DecisionSignal.red,
                  actionLabel: 'fallback_mode',
                  level: w.DisclosureLevel.fullDetails,
                  explanation: 'Degraded performance requires fallback.',
                  evidence: [
                    w.EvidenceTerm(
                      label: 'frame_time_p99',
                      factor: 0.3,
                      direction: w.EvidenceDirection.opposing,
                    ),
                  ],
                  details: w.DecisionDetails(
                    logPosterior: -1.204,
                    confidenceLow: 0.15,
                    confidenceHigh: 0.45,
                    expectedLoss: 0.8200,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg is tui.KeyMsg && msg.key.char == 'q') return tui.Cmd.quit();
    return null;
  }
}
