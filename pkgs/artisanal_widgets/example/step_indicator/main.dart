// StepIndicator Showcase
//
// Demonstrates StepIndicator with all step statuses (pending, active,
// completed, error, skipped), descriptions, and dynamic step progression.
//
// Run with: dart run example/step_indicator/main.dart

import 'package:artisanal/style.dart' hide Padding, Align;
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/widgets.dart' as w;

void main() async {
  final app = tui.WidgetApp(StepIndicatorShowcase());
  await tui.runProgram(
    app,
    options: const tui.ProgramOptions(
      altScreen: true,
      mouse: true,
      mouseMode: tui.MouseMode.allMotion,
    ),
  );
}

class StepIndicatorShowcase extends w.StatefulWidget {
  StepIndicatorShowcase({super.key});

  @override
  w.State createState() => _StepIndicatorShowcaseState();
}

class _StepIndicatorShowcaseState extends w.State<StepIndicatorShowcase> {
  final w.WidgetScrollController _scrollController = w.WidgetScrollController();
  int _currentStep = 1;

  static const _totalSteps = 5;

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
        child: w.ScrollView(
          controller: _scrollController,
          handleKeys: true,
          child: w.Column(
            gap: 1,
            children: [
              w.Text('StepIndicator Showcase', style: theme.titleLarge),
              w.Text('Right/Left: move step  q: quit', style: label),
              w.Text(
                'Current step: ${_currentStep + 1} / $_totalSteps',
                style: label,
              ),
              w.Divider(width: 60),

              // -- Dynamic step progression --
              w.Text('Deployment Pipeline (dynamic)', style: theme.titleMedium),
              w.Frame(
                border: Border.rounded,
                borderColor: theme.border,
                padding: const w.EdgeInsets.symmetric(
                  horizontal: 2,
                  vertical: 1,
                ),
                child: w.StepIndicator(
                  current: _currentStep,
                  steps: [
                    w.StepItem(
                      label: 'Checkout',
                      description: 'Clone repository and fetch dependencies',
                    ),
                    w.StepItem(
                      label: 'Build',
                      description: 'Compile source and generate artifacts',
                    ),
                    w.StepItem(
                      label: 'Test',
                      description: 'Run unit and integration tests',
                    ),
                    w.StepItem(
                      label: 'Stage',
                      description: 'Deploy to staging environment',
                    ),
                    w.StepItem(
                      label: 'Production',
                      description: 'Roll out to production servers',
                    ),
                  ],
                ),
              ),
              w.Divider(width: 60),

              // -- All statuses shown explicitly --
              w.Text('All Step Statuses', style: theme.titleMedium),
              w.StepIndicator(
                steps: [
                  w.StepItem(
                    label: 'Completed',
                    status: w.StepStatus.completed,
                    description: 'This step finished successfully',
                  ),
                  w.StepItem(
                    label: 'Active',
                    status: w.StepStatus.active,
                    description: 'This step is currently running',
                  ),
                  w.StepItem(
                    label: 'Error',
                    status: w.StepStatus.error,
                    description: 'This step encountered a failure',
                  ),
                  w.StepItem(
                    label: 'Skipped',
                    status: w.StepStatus.skipped,
                    description: 'This step was skipped',
                  ),
                  w.StepItem(
                    label: 'Pending',
                    status: w.StepStatus.pending,
                    description: 'This step has not started',
                  ),
                ],
              ),
              w.Divider(width: 60),

              // -- Minimal (no descriptions) --
              w.Text(
                'Minimal Steps (no descriptions)',
                style: theme.titleMedium,
              ),
              w.StepIndicator(
                steps: [
                  w.StepItem(label: 'Download', status: w.StepStatus.completed),
                  w.StepItem(label: 'Install', status: w.StepStatus.completed),
                  w.StepItem(label: 'Configure', status: w.StepStatus.active),
                  w.StepItem(label: 'Verify', status: w.StepStatus.pending),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg is tui.KeyMsg) {
      final key = msg.key;
      if (key.char == 'q') return tui.Cmd.quit();
      if (key.type == tui.KeyType.right) {
        setState(() {
          _currentStep = (_currentStep + 1).clamp(0, _totalSteps - 1);
        });
      }
      if (key.type == tui.KeyType.left) {
        setState(() {
          _currentStep = (_currentStep - 1).clamp(0, _totalSteps - 1);
        });
      }
    }
    return null;
  }
}
