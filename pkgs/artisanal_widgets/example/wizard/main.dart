import 'dart:math' as math;

import 'package:artisanal/artisanal.dart' as artisanal;
import 'package:artisanal_widgets/app.dart' as app;
import 'package:artisanal/tui.dart' as runtime;
import 'package:artisanal/style.dart' show Style;
import 'package:artisanal/widgets.dart' as w;

void main() async {
  await artisanal.runWidgetApp(
    app.ArtisanalApp(title: 'Wizard Showcase', home: WizardShowcaseScreen()),
  );
}

class WizardShowcaseScreen extends w.StatefulWidget {
  WizardShowcaseScreen({super.key});

  @override
  w.State createState() => _WizardShowcaseState();
}

class _WizardShowcaseState extends w.State<WizardShowcaseScreen> {
  Map<String, dynamic>? _answers;
  bool _cancelled = false;

  @override
  w.Widget build(w.BuildContext context) {
    final media = w.MediaQuery.of(context);
    final width = math.min(76, math.max(44, media.size.width.toInt() - 4));

    return w.Center(
      child: w.SizedBox(
        width: width,
        child: w.Padding(
          padding: const w.EdgeInsets.all(1),
          child: _answers != null || _cancelled
              ? _buildSummary(context, width)
              : _buildWizard(width),
        ),
      ),
    );
  }

  w.Widget _buildWizard(int width) {
    return w.Wizard(
      width: width,
      title: 'Create New Project',
      steps: [
        w.WizardFormStep.textInput(
          key: 'name',
          prompt: 'Project name',
          placeholder: 'my_project',
          validate: (value) {
            if (value.trim().isEmpty) return 'Name is required.';
            if (!RegExp(r'^[a-z_][a-z0-9_]*$').hasMatch(value)) {
              return 'Use lowercase letters, digits, and underscores.';
            }
            return null;
          },
        ),
        w.WizardFormStep.select(
          key: 'template',
          prompt: 'Project template',
          options: const ['console', 'package', 'server', 'flutter'],
        ),
        w.WizardFormStep.confirm(
          key: 'git',
          prompt: 'Initialize a Git repository?',
          defaultValue: true,
        ),
        w.WizardFormStep.conditional(
          step: w.WizardFormStep.textInput(
            key: 'git_remote',
            prompt: 'Git remote URL',
            placeholder: 'https://github.com/you/repo.git',
          ),
          condition: (answers) => answers['git'] == true,
        ),
        w.WizardFormStep.multiSelect(
          key: 'features',
          prompt: 'Starter features',
          options: const ['Testing', 'CI', 'Docs', 'Docker'],
          defaultSelected: const [0, 2],
        ),
        w.WizardFormStep.group(
          key: 'author',
          title: 'Author',
          steps: [
            w.WizardFormStep.textInput(
              key: 'author_name',
              prompt: 'Author name',
              placeholder: 'Ada Lovelace',
            ),
            w.WizardFormStep.password(
              key: 'api_token',
              prompt: 'Private API token',
              placeholder: 'sk-live-...',
              validate: (value) {
                if (value.trim().length < 8) return 'Token is too short.';
                return null;
              },
            ),
          ],
        ),
      ],
      onCompleted: (answers) {
        setState(() {
          _answers = answers;
          _cancelled = false;
        });
        return null;
      },
      onCancelled: () {
        setState(() {
          _cancelled = true;
        });
        return null;
      },
      onExit: runtime.Cmd.quit,
    );
  }

  w.Widget _buildSummary(w.BuildContext context, int width) {
    final theme = w.ThemeScope.of(context);
    final headingStyle = theme.titleMedium.copy()..foreground(theme.onSurface);
    final labelStyle = theme.labelMedium.copy()..foreground(theme.muted);
    final valueStyle = theme.bodyMedium.copy()..foreground(theme.onSurface);

    return w.Column(
      gap: 1,
      crossAxisAlignment: w.CrossAxisAlignment.stretch,
      children: [
        w.Card(
          child: w.Column(
            gap: 1,
            crossAxisAlignment: w.CrossAxisAlignment.stretch,
            children: [
              w.Text(
                _cancelled ? 'Wizard cancelled' : 'Project ready',
                style: headingStyle,
              ),
              if (_answers != null) ...[
                _summaryRow(
                  'Name',
                  _answers!['name']?.toString() ?? '-',
                  labelStyle,
                  valueStyle,
                ),
                _summaryRow(
                  'Template',
                  _answers!['template']?.toString() ?? '-',
                  labelStyle,
                  valueStyle,
                ),
                _summaryRow(
                  'Git',
                  _answers!['git'] == true ? 'Yes' : 'No',
                  labelStyle,
                  valueStyle,
                ),
                _summaryRow(
                  'Remote',
                  _answers!['git_remote']?.toString() ?? '-',
                  labelStyle,
                  valueStyle,
                ),
                _summaryRow(
                  'Features',
                  (_answers!['features'] as List?)?.join(', ') ?? '-',
                  labelStyle,
                  valueStyle,
                ),
                _summaryRow(
                  'Author',
                  _answers!['author_name']?.toString() ?? '-',
                  labelStyle,
                  valueStyle,
                ),
              ],
            ],
          ),
        ),
        w.Row(
          mainAxisAlignment: w.MainAxisAlignment.end,
          children: [
            w.Button(
              label: 'Start again',
              onPressed: () {
                setState(() {
                  _answers = null;
                  _cancelled = false;
                });
                return null;
              },
            ),
          ],
        ),
        w.Text(
          'esc cancels, enter continues, arrow keys move selections',
          style: labelStyle,
        ),
      ],
    );
  }

  w.Widget _summaryRow(
    String label,
    String value,
    Style labelStyle,
    Style valueStyle,
  ) {
    return w.Row(
      gap: 2,
      children: [
        w.SizedBox(width: 10, child: w.Text(label, style: labelStyle)),
        w.Expanded(child: w.Text(value, style: valueStyle)),
      ],
    );
  }
}
